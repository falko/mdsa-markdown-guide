--[[
docx2md.lua: converts the DMN Word source into the Markdown clause files of this
repository, written the way the repository's guide asks for (see README.md):

- one file per clause from Clause 7 on, headings without numbers
- figures as ![Caption](Images/name.svg), tables as pipe tables with a
  "###### Table: Caption" heading
- references to clauses, figures and tables as ordinary links whose text is the
  title or caption, so that the PDF shows the generated numbers
- no HTML, no attributes, no sub- and superscript syntax, no lettered lists

Run through tools/convert.sh, which also writes the images. Environment:
  OUT       directory for the Markdown files (default: .)
  MANIFEST  file for the list of images to write (default: OUT/images.tsv)
  LOG       file for conversion notes (default: OUT/convert.log)
]]

local stringify = pandoc.utils.stringify
local List = pandoc.List

local OUT = os.getenv('OUT') or '.'
local MANIFEST = os.getenv('MANIFEST') or (OUT .. '/images.tsv')
local LOGFILE = os.getenv('LOG') or (OUT .. '/convert.log')

local logf = io.open(LOGFILE, 'w')
local function log(...)
  logf:write(table.concat({...}, ' '), '\n')
end

------------------------------------------------------------------------------
-- Clause files
------------------------------------------------------------------------------

-- DMN clause number (from the Word document) -> file. DMN has no clauses for
-- terms and symbols, which the OMG template always has (Clauses 4 and 5), so
-- DMN Clause 5 and later move up by two.
-- DMN keeps its own clause structure (see Specification_Template.tex): the file
-- of each clause is named after its number and title. Clause 3, References,
-- is generated from specification.bib.
local function clause_file(n, title)
  if n == 3 then return nil end
  local name = title:gsub('%b()', function(s) return s:sub(2, -2) end)
  name = name:gsub('[^%w%s%-]', ''):gsub('%s+', '_'):gsub('_+$', '')
  name = name:sub(1, 1):upper() .. name:sub(2)
  return string.format('%02d_%s', n, name)
end

-- Files whose clause heading comes from the template (none for DMN)
local strip_headings = {}

------------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------------

local function trim(s) return (s:gsub('^%s+', ''):gsub('%s+$', '')) end

local function slug(s, maxlen)
  s = s:lower():gsub('[^%w]+', '-'):gsub('^%-+', ''):gsub('%-+$', '')
  maxlen = maxlen or 60
  if #s > maxlen then
    s = s:sub(1, maxlen):gsub('%-[^%-]*$', '')
  end
  return s
end

-- All identifiers (bookmarks, heading identifiers) in an element
local function ids_in(el)
  local ids = List()
  local function add(id) if id and id ~= '' then ids:insert(id) end end
  if el.identifier then add(el.identifier) end
  if el.attr and el.attr.identifier then add(el.attr.identifier) end
  local ok = pcall(function()
    el:walk{
      Span = function(s) add(s.identifier) end,
      Header = function(h) add(h.identifier) end,
      Div = function(d) add(d.identifier) end,
      Image = function(i) add(i.identifier) end,
    }
  end)
  return ids
end

-- Remove leading/trailing spaces and line breaks from an inline list
local function trim_inlines(inls)
  inls = List(inls)
  while #inls > 0 and (inls[1].t == 'Space' or inls[1].t == 'LineBreak' or inls[1].t == 'SoftBreak'
      or (inls[1].t == 'Str' and inls[1].text == '')) do inls:remove(1) end
  while #inls > 0 and (inls[#inls].t == 'Space' or inls[#inls].t == 'LineBreak' or inls[#inls].t == 'SoftBreak'
      or (inls[#inls].t == 'Str' and inls[#inls].text == '')) do inls:remove(#inls) end
  return inls
end

-- Remove anchors (empty spans) and unwrap spans, so that captions and
-- headings are plain inlines
local function clean_inlines(inls)
  local doc = pandoc.Pandoc({ pandoc.Plain(inls) })
  doc = doc:walk{
    Span = function(s) return s.content end,
    LineBreak = function() return pandoc.Space() end,
    SoftBreak = function() return pandoc.Space() end,
  }
  local out = List()
  for _, b in ipairs(doc.blocks) do out:extend(b.content) end
  -- merge doubled spaces
  local res = List()
  for _, i in ipairs(out) do
    if i.t == 'Space' and #res > 0 and res[#res].t == 'Space' then
    else res:insert(i) end
  end
  return trim_inlines(res)
end

-- Strip a caption label such as "Figure 6-1: " or "Table 12: " from the start
-- of a caption. Returns kind ('Figure'/'Table'), label number, rest inlines.
local function split_caption(inls)
  inls = clean_inlines(inls)
  inls = pandoc.Pandoc({ pandoc.Plain(inls) }):walk{
    Strong = function(x) return x.content end,
    Emph = function(x) return x.content end,
  }.blocks[1].content
  local text = stringify(inls)
  local kind, num = text:match('^%s*(Figure)%s+([%dA-Z]+%s*[%-%.]%s*%d+)%s*:')
  if not kind then kind, num = text:match('^%s*(Table)%s+(%d+)%s*:') end
  if not kind then return nil, nil, inls end
  -- drop inlines up to and including the first ':'
  local rest = List()
  local found = false
  for _, i in ipairs(inls) do
    if found then rest:insert(i)
    elseif i.t == 'Str' and i.text:find(':') then
      found = true
      local after = i.text:match(':(.*)$')
      if after and after ~= '' then rest:insert(pandoc.Str(after)) end
    end
  end
  num = num:gsub('%s', ''):gsub('%.', '-')
  return kind, num, trim_inlines(rest)
end

local function caption_text(inls)
  return trim(stringify(inls):gsub('%s+', ' '))
end

------------------------------------------------------------------------------
-- Sub- and superscripts: Unicode characters (GitHub shows them; the PDF maps
-- them with \newunicodechar in _Specification_AuthorSettings.tex)
------------------------------------------------------------------------------

local SUB = { ['0']='₀', ['1']='₁', ['2']='₂', ['3']='₃', ['4']='₄', ['5']='₅', ['6']='₆',
  ['7']='₇', ['8']='₈', ['9']='₉', ['-']='₋', ['+']='₊', ['=']='₌', ['(']='₍', [')']='₎',
  a='ₐ', e='ₑ', h='ₕ', i='ᵢ', j='ⱼ', k='ₖ', l='ₗ', m='ₘ', n='ₙ', o='ₒ', p='ₚ', r='ᵣ',
  s='ₛ', t='ₜ', u='ᵤ', v='ᵥ', x='ₓ' }
local SUP = { ['0']='⁰', ['1']='¹', ['2']='²', ['3']='³', ['4']='⁴', ['5']='⁵', ['6']='⁶',
  ['7']='⁷', ['8']='⁸', ['9']='⁹', ['-']='⁻', ['+']='⁺', ['=']='⁼', ['(']='⁽', [')']='⁾',
  i='ⁱ', n='ⁿ', s='ˢ' }

local function map_chars(text, map)
  local out = {}
  for _, c in utf8.codes(text) do
    local ch = utf8.char(c)
    if ch:match('%s') then
    elseif map[ch] then out[#out + 1] = map[ch]
    else return nil end
  end
  return table.concat(out)
end

local function script_filter(el, map, kind)
  local text = stringify(el.content)
  if trim(text) == '' then return el.content end
  if kind == 'sup' then
    if text == '®' or text == 'TM' or text == '™' then return pandoc.Str(text == 'TM' and '™' or text) end
    if text:match('^%s*[snrt][tdh]%s*$') then return pandoc.Str(trim(text)) end  -- ordinals
  end
  -- whole words set as subscript by mistake
  if text == 'Some' or text == 'Quantified' or text == 'schema' then return pandoc.Str(text) end
  local mapped = map_chars(text, map)
  if mapped then return pandoc.Str(mapped) end
  -- No Unicode equivalent: written as plain text, e.g. "value_dtd"
  log('script-fallback', kind, text)
  return pandoc.Str((kind == 'sub' and '_' or '^') .. trim(text))
end

------------------------------------------------------------------------------
-- Images
------------------------------------------------------------------------------

local manifest_entries = List()
local used_names = {}

local function unique_name(base)
  base = base ~= '' and base or 'image'
  local name = base
  local n = 1
  while used_names[name] do n = n + 1; name = base .. '-' .. n end
  used_names[name] = true
  return 'Images/' .. name .. '.svg'
end

-- Image from the document: written by convert.sh from the docx media
local function image_target(img, base)
  local dest = unique_name(base)
  local w = img.attributes.width or ''
  local h = img.attributes.height or ''
  local e = { 'media', img.src, dest, w, h, '' }
  manifest_entries:insert(e)
  return dest, e
end

-- Figure that is a Word table: cut from the reference PDF by convert.sh
-- mode 'in': the figure starts with text; 'after': it follows the text
local function crop_target(label, base, text, mode, caption)
  local dest = unique_name(base)
  manifest_entries:insert({ 'crop', label, dest, mode or 'in', caption or '', ((text or ''):gsub('%s+', ' ')) })
  return dest
end

------------------------------------------------------------------------------
-- Cross-reference targets
------------------------------------------------------------------------------

-- id -> target: { kind = 'sec'|'fig'|'tbl', file, src, title (inlines), level }
local targets = {}
-- Headers are copied when blocks are walked, so targets find their header by a key
local hkey = 0
local function keyed(h, target)
  hkey = hkey + 1
  h.attributes['key'] = tostring(hkey)
  target.key = tostring(hkey)
  return h
end
local numbers = { sec = {}, fig = {}, tbl = {} }   -- DMN numbers -> target
-- "Table 111" -> target, per file: the Word source has duplicate numbers and
-- bookmarks, and a reference means the figure or table of its own clause
local local_labels = {}
local function label_target(kind, num, target)
  local_labels[target.file] = local_labels[target.file] or {}
  local_labels[target.file][kind .. ' ' .. num] = target
end

local function register(ids, target)
  for _, id in ipairs(ids) do
    if not targets[id] then targets[id] = target end
  end
end

------------------------------------------------------------------------------
-- Tables
------------------------------------------------------------------------------

-- Inline content of a table cell, in one line: the lines of the cell
-- (paragraphs and line breaks) are joined with spaces, and with semicolons
-- between lines that are both FEEL examples ("... = ..."); list items are
-- marked with bullets; images are kept
local function cell_inlines(blocks)
  local units = List()   -- lines of the cell, each a list of inlines
  local function add_inlines(inls, prefix)
    local cur = List()
    if prefix then cur:insert(pandoc.Str(prefix)); cur:insert(pandoc.Space()) end
    for _, i in ipairs(inls) do
      if i.t == 'LineBreak' then
        units:insert(cur); cur = List()
      else
        cur:insert(i)
      end
    end
    units:insert(cur)
  end
  local function add(bs, bullet)
    for _, b in ipairs(bs) do
      if b.t == 'Para' or b.t == 'Plain' then
        add_inlines(b.content, bullet); bullet = nil
      elseif b.t == 'LineBlock' then
        for _, l in ipairs(b.content) do add_inlines(l) end
      elseif b.t == 'CodeBlock' then
        units:insert(List({ pandoc.Code((b.text:gsub('\n', ' '))) }))
      elseif b.t == 'BlockQuote' or b.t == 'Div' then
        add(b.content, bullet); bullet = nil
      elseif b.t == 'BulletList' then
        for _, item in ipairs(b.content) do add(item, '•') end
      elseif b.t == 'OrderedList' then
        local n = b.listAttributes.start or 1
        for _, item in ipairs(b.content) do add(item, tostring(n) .. '.'); n = n + 1 end
      elseif b.t == 'Header' then
        add_inlines(b.content)
      elseif b.t == 'Figure' then
        b:walk{ Image = function(i) units:insert(List({ i })) end }
      elseif b.t == 'HorizontalRule' then
      else
        log('cell-block', b.t)
        units:insert(List({ pandoc.Str(stringify(b)) }))
      end
    end
  end
  -- line breaks inside emphasis end the emphasis: *a↵b* -> *a*↵*b*
  local function split_breaks(el)
    local parts, cur = List(), List()
    for _, i in ipairs(el.content) do
      if i.t == 'LineBreak' then parts:insert(cur); cur = List() else cur:insert(i) end
    end
    parts:insert(cur)
    if #parts == 1 then return nil end
    local res = List()
    for k, p in ipairs(parts) do
      if k > 1 then res:insert(pandoc.LineBreak()) end
      if #p > 0 then
        local e = el:clone(); e.content = p; res:insert(e)
      end
    end
    return res
  end
  blocks = pandoc.Pandoc(blocks):walk{ Emph = split_breaks, Strong = split_breaks, Span = split_breaks }.blocks
  add(blocks)
  local out = List()
  local prevtext
  for _, u in ipairs(units) do
    u = trim_inlines(u)
    if #u > 0 then
      local text = stringify(u)
      if prevtext then
        if prevtext:find('=') and text:find('=') and not prevtext:match('[%.;,]$') then
          out:insert(pandoc.Str(';'))
        end
        out:insert(pandoc.Space())
      end
      out:extend(u)
      prevtext = text
    end
  end
  out = pandoc.Pandoc({ pandoc.Plain(out) }):walk{
    LineBreak = function() return pandoc.Space() end,
    SoftBreak = function() return pandoc.Space() end,
  }.blocks[1].content
  local res = List()
  for _, i in ipairs(out) do
    if not (i.t == 'Space' and #res > 0 and res[#res].t == 'Space') then res:insert(i) end
  end
  return trim_inlines(res)
end

-- Expand row and column spans into a plain grid: a spanned cell keeps its
-- content in its first row and column, the others are empty.
local function grid(rows, ncols)
  local out = {}
  local pending = {}  -- column -> remaining rows covered by a row span
  for r, row in ipairs(rows) do
    local cells = {}
    local col = 1
    local ci = 1
    while col <= ncols do
      if pending[col] and pending[col] > 0 then
        cells[col] = List()
        pending[col] = pending[col] - 1
        col = col + 1
      else
        local c = row.cells[ci]
        ci = ci + 1
        if not c then
          cells[col] = List(); col = col + 1
        else
          cells[col] = cell_inlines(c.contents)
          for k = 1, c.col_span do
            if k > 1 then cells[col + k - 1] = List() end
            if c.row_span > 1 then pending[col + k - 1] = c.row_span - 1 end
          end
          col = col + c.col_span
        end
      end
    end
    out[#out + 1] = cells
  end
  return out
end

local function simple_table(t)
  local ncols = #t.colspecs
  local rows = List()
  for _, r in ipairs(t.head.rows) do rows:insert(r) end
  local nhead = #t.head.rows
  for _, b in ipairs(t.bodies) do
    for _, r in ipairs(b.head) do rows:insert(r) end
    for _, r in ipairs(b.body) do rows:insert(r) end
  end
  for _, r in ipairs(t.foot.rows) do rows:insert(r) end
  local g = grid(rows, ncols)
  -- images in a row are named after the row: its shortest text cell
  for _, cells in ipairs(g) do
    local label
    for c = 1, ncols do
      local t = trim(stringify(cells[c] or {}))
      if t ~= '' and (not label or #t < #label) then label = t end
    end
    for c = 1, ncols do
      for _, x in ipairs(cells[c] or {}) do
        if x.t == 'Image' and not x.src:match('^Images/') then
          x.src = image_target(x, slug((label or current.heading) .. ' symbol'))
          x.caption = {}
          x.attributes = {}
        end
      end
    end
  end
  -- Pipe tables have exactly one header row: without a header, the first row
  -- becomes it; several header rows are joined into one.
  local header
  local start
  if nhead == 0 then
    header = g[1]; start = 2
  else
    header = g[1]
    for k = 2, nhead do
      for c = 1, ncols do
        if #g[k][c] > 0 then
          if #header[c] > 0 then header[c]:insert(pandoc.Space()) end
          header[c]:extend(g[k][c])
        end
      end
    end
    start = nhead + 1
  end
  local function mkrow(cells)
    local cs = List()
    for c = 1, ncols do cs:insert(pandoc.Cell({ pandoc.Plain(cells[c] or List()) })) end
    return pandoc.Row(cs)
  end
  local body = List()
  for k = start, #g do
    -- drop rows that are completely empty
    local empty = true
    for c = 1, ncols do if #(g[k][c] or {}) > 0 then empty = false end end
    if not empty then body:insert(mkrow(g[k])) end
  end
  local colspecs = List()
  local total = 0
  for _, cs in ipairs(t.colspecs) do total = total + (tonumber(cs[2]) or 0) end
  for _, cs in ipairs(t.colspecs) do
    local w = tonumber(cs[2])
    colspecs:insert({ pandoc.AlignDefault, (w and total > 0) and w / total or nil })
  end
  local res = pandoc.Table(
    { long = {}, short = nil },
    colspecs,
    pandoc.TableHead({ mkrow(header) }),
    { { attr = {}, body = body, head = {}, row_head_columns = 0 } },
    pandoc.TableFoot()
  )
  return res
end

------------------------------------------------------------------------------
-- Grammar lists (EBNF rules with lettered alternatives) become code blocks
------------------------------------------------------------------------------

local function to_ascii(s)
  return (s:gsub('[“”]', '"'):gsub('[‘’]', "'"):gsub('[–—]', '-'):gsub('…', '...')
    :gsub('\u{00A0}', ' '))
end

local function is_grammar(list)
  local first = list.content[1] and list.content[1][1]
  if not first then return false end
  local text = stringify(first)
  return text:match('^[%a][%a%s]* =') ~= nil
end

local function letter(n, upper)
  local s = string.char(string.byte('a') + n - 1)
  return upper and s:upper() or s
end

local function grammar_lines(list, indent, lines)
  local n = list.listAttributes.start or 1
  local style = list.listAttributes.style
  for _, item in ipairs(list.content) do
    local label
    if style == 'LowerAlpha' then label = letter(n) .. '.'
    elseif style == 'UpperAlpha' then label = letter(n, true) .. '.'
    else label = tostring(n) .. '.' end
    local first = true
    for _, b in ipairs(item) do
      if b.t == 'OrderedList' or b.t == 'BulletList' then
        if b.t == 'BulletList' then
          b = pandoc.OrderedList(b.content, { 1, 'LowerAlpha', 'Period' })
        end
        grammar_lines(b, indent .. string.rep(' ', #label + 1), lines)
      else
        local text = to_ascii(stringify(b):gsub('%s+', ' '))
        if first then
          lines:insert(indent .. label .. ' ' .. text)
          first = false
        else
          lines:insert(indent .. string.rep(' ', #label + 1) .. text)
        end
      end
    end
    n = n + 1
  end
end

------------------------------------------------------------------------------
-- Block processing: figures, tables, lists, code
------------------------------------------------------------------------------

local current = { file = nil, heading = '' }
local figure_count = 0

local function is_caption_div(b)
  return b and b.t == 'Div' and b.attributes['custom-style'] == 'caption'
end

-- A paragraph that is a caption: a caption div, or a paragraph starting with
-- "Figure N-N:" or "Table N:" (often bold)
local function caption_of(b)
  if not b then return nil end
  local inls
  if is_caption_div(b) then
    inls = List()
    for _, x in ipairs(b.content) do
      if x.content then
        if #inls > 0 then inls:insert(pandoc.Space()) end
        inls:extend(x.content)
      end
    end
  elseif b.t == 'Para' or b.t == 'Plain' then
    inls = b.content
  elseif b.t == 'BlockQuote' and #b.content == 1 and (b.content[1].t == 'Para' or b.content[1].t == 'Plain') then
    inls = b.content[1].content
  else
    return nil
  end
  local kind, num, rest = split_caption(inls)
  if not kind then return nil end
  -- a caption is short; a sentence such as "Figure 6-1 shows ..." is not one
  if not stringify(inls):match('^%s*%a+%s+[%dA-Z]+%s*[%-%.]?%s*%d*%s*:') then return nil end
  return { kind = kind, num = num, inlines = rest, ids = ids_in(b) }
end

local function only_image(b)
  if not b or (b.t ~= 'Para' and b.t ~= 'Plain') then return nil end
  local img
  for _, i in ipairs(b.content) do
    if i.t == 'Image' then
      if img then return nil end
      img = i
    elseif i.t == 'Space' or i.t == 'LineBreak' or i.t == 'SoftBreak' then
    elseif i.t == 'Span' and stringify(i) == '' then
    elseif i.t == 'Str' and trim(i.text) == '' then
    else return nil end
  end
  return img
end

local entries_by_src = {}

local function make_figure(img, cap, ids)
  figure_count = figure_count + 1
  local inls = cap and cap.inlines or List()
  local text = caption_text(inls)
  local base = text ~= '' and slug(text) or slug(current.heading .. '-figure')
  local src, entry = image_target(img, base)
  local target = { kind = 'fig', file = current.file, src = src, title = List({ pandoc.Str(text) }) }
  if cap then
    register(cap.ids, target)
    numbers.fig[cap.num] = target
    label_target(cap.kind, cap.num, target)
    log('figure', cap.num, text)
  end
  entries_by_src[src] = entry
  register(ids, target)
  if text == '' then
    log('figure-without-caption', current.file, src)
    return pandoc.Para({ pandoc.Image({}, src) })
  end
  -- caption as plain text, so that the alt text (= caption) has no markup
  return pandoc.Para({ pandoc.Image({ pandoc.Str(text) }, src) })
end

local function make_crop_figure(t, cap, ids)
  local text = caption_text(cap.inlines)
  -- first text of the table (or other block), to find it in the reference PDF
  local first = ''
  local mode = 'in'
  if t.t == 'Table' then
    local rows = List()
    rows:extend(t.head.rows)
    for _, b in ipairs(t.bodies) do rows:extend(b.body) end
    for _, r in ipairs(rows) do
      for _, c in ipairs(r.cells) do
        if first == '' then first = trim(stringify(c.contents)) end
      end
    end
  elseif t.t == 'CodeBlock' then
    first = t.text
  elseif t.t == 'Para' and #stringify(t) > 80 then
    -- a drawing that the conversion does not see follows this paragraph
    first = stringify(t):sub(-40)
    mode = 'after'
  else
    first = stringify(t)
  end
  log('figure', cap.num, text)
  local src = crop_target('Figure ' .. cap.num, slug(text), mode == 'in' and first:sub(1, 40) or first, mode, text)
  local target = { kind = 'fig', file = current.file, src = src, title = List({ pandoc.Str(text) }) }
  register(cap.ids, target)
  register(ids, target)
  numbers.fig[cap.num] = target
  log('table-as-figure', current.file, 'Figure ' .. cap.num, text)
  return pandoc.Para({ pandoc.Image({ pandoc.Str(text) }, src) })
end

-- The glossary (Annex B) is a table of terms, grouped by letter: it becomes a
-- definition list, with the letters as bold paragraphs
local function is_glossary(t)
  if #t.colspecs ~= 2 then return false end
  local first = t.head.rows[1] and t.head.rows[1].cells[1]
  return first and trim(stringify(first.contents)):match('^%u$') ~= nil
end

local function glossary(t)
  local out = List()
  local items = List()
  local function flush()
    if #items > 0 then out:insert(pandoc.DefinitionList(items)); items = List() end
  end
  local rows = List()
  rows:extend(t.head.rows)
  for _, b in ipairs(t.bodies) do rows:extend(b.body) end
  for _, r in ipairs(rows) do
    local term = cell_inlines(r.cells[1] and r.cells[1].contents or {})
    local def = r.cells[2] and r.cells[2].col_span == 1 and cell_inlines(r.cells[2].contents) or List()
    local letter = stringify(term)
    if #def == 0 and trim(letter):match('^%u$') then
      flush()
      out:insert(pandoc.Para({ pandoc.Strong({ pandoc.Str(trim(letter)) }) }))
    elseif #term > 0 then
      local plain = pandoc.Pandoc({ pandoc.Plain(term) }):walk{ Strong = function(x) return x.content end }.blocks[1].content
      items:insert({ plain, { { pandoc.Para(def) } } })
    end
  end
  flush()
  log('glossary', #rows)
  return out
end

local function make_table(t, cap, ids)
  if not cap and is_glossary(t) then return glossary(t) end
  local out = List()
  local res = simple_table(t)
  if cap then
    local text = caption_text(cap.inlines)
    local h = pandoc.Header(6, List({ pandoc.Str('Table:'), pandoc.Space() }) .. List({ pandoc.Str(text) }))
    local target = { kind = 'tbl', file = current.file, header = h, title = List({ pandoc.Str(text) }) }
    keyed(h, target)
    register(cap.ids, target)
    register(ids, target)
    numbers.tbl[cap.num] = target
    log('table', cap.num, text)
    out:insert(h)
  else
    log('table-without-caption', current.file, stringify(t):sub(1, 60))
  end
  out:insert(res)
  return out
end

local process

local function lettered_paras(list)
  local out = List()
  local n = list.listAttributes.start or 1
  local style, delim = list.listAttributes.style, list.listAttributes.delimiter
  for _, item in ipairs(list.content) do
    local l = letter(n, style == 'UpperAlpha')
    local label = delim == 'TwoParens' and ('(' .. l .. ')') or (delim == 'OneParen' and (l .. ')') or (l .. '.'))
    local blocks = process(item)
    if blocks[1] and (blocks[1].t == 'Para' or blocks[1].t == 'Plain') then
      blocks[1] = pandoc.Para(List({ pandoc.Str(label), pandoc.Space() }) .. blocks[1].content)
    else
      blocks:insert(1, pandoc.Para({ pandoc.Str(label) }))
    end
    out:extend(blocks)
    n = n + 1
  end
  return out
end

local function is_blank_page(b)
  return (b.t == 'Para' or b.t == 'Plain') and stringify(b):match('^%s*Th[ei]s? page intentionally left blank%.?%s*$')
end

process = function(blocks)
  blocks = List(blocks)
  local out = List()
  local i = 1
  -- caption waiting for the next table or image
  while i <= #blocks do
    local b = blocks[i]
    local nextb = blocks[i + 1]
    if is_blank_page(b) then
      i = i + 1
    elseif b.t == 'Figure' then
      local img
      b:walk{ Image = function(x) img = img or x end }
      local kind, num, rest = split_caption(pandoc.utils.blocks_to_inlines(b.caption.long))
      local cap
      if kind then cap = { kind = kind, num = num, inlines = rest, ids = ids_in(b) } end
      if not cap then
        -- caption may follow as a separate paragraph
        local c = caption_of(nextb)
        if c and c.kind == 'Figure' then cap = c; i = i + 1 end
      end
      if img then out:insert(make_figure(img, cap, ids_in(b))) end
      i = i + 1
    elseif only_image(b) then
      local img = only_image(b)
      local cap = caption_of(nextb)
      local prevcap = nil
      local nextcap = nextb and nextb.t == 'Figure' and split_caption(pandoc.utils.blocks_to_inlines(nextb.caption.long))
      if cap and cap.kind == 'Figure' then
        out:insert(make_figure(img, cap, ids_in(b))); i = i + 2
      elseif nextcap == 'Figure' and caption_of(blocks[i + 2]) and caption_of(blocks[i + 2]).kind == 'Figure' then
        -- the captions are shifted by one image: the caption of the next
        -- figure belongs to this image, the caption after it to the next one
        log('shifted-captions', current.file)
        local kind, num, rest = split_caption(pandoc.utils.blocks_to_inlines(nextb.caption.long))
        out:insert(make_figure(img, { kind = kind, num = num, inlines = rest, ids = ids_in(nextb) }, ids_in(b)))
        local img2
        nextb:walk{ Image = function(x) img2 = img2 or x end }
        out:insert(make_figure(img2, caption_of(blocks[i + 2]), List()))
        i = i + 3
      else
        -- an image without caption that Word places next to the captioned
        -- figure after it: one figure with both images side by side
        local fig2, cap2
        if nextb and nextb.t == 'Figure' then
          local kind, num, rest = split_caption(pandoc.utils.blocks_to_inlines(nextb.caption.long))
          if kind == 'Figure' then
            nextb:walk{ Image = function(x) fig2 = fig2 or x end }
            cap2 = { kind = kind, num = num, inlines = rest, ids = ids_in(nextb) }
          end
        end
        local function inch(x) return tonumber((x or ''):match('^([%d.]+)in$')) end
        -- (an image that Word floats has no size in the document)
        if fig2 and inch(fig2.attributes.width)
            and (inch(img.attributes.width) or 0) + inch(fig2.attributes.width) <= 6.8 then
          log('side-by-side', current.file, caption_text(cap2.inlines))
          local para = make_figure(fig2, cap2, ids_in(nextb))
          local src = para.content[1].src
          local entry = entries_by_src[src]
          entry[1] = 'combine'
          entry[6] = img.src .. '|' .. (img.attributes.width or '') .. '|' .. (img.attributes.height or '')
          out:insert(para)
          i = i + 2
        else
          out:insert(make_figure(img, nil, ids_in(b))); i = i + 1
        end
      end
    elseif b.t == 'Table' then
      local kind, num, rest = split_caption(pandoc.utils.blocks_to_inlines(b.caption.long))
      local cap
      if kind then cap = { kind = kind, num = num, inlines = rest, ids = ids_in(pandoc.Div(b.caption.long)) } end
      if not cap then
        local c = caption_of(nextb)
        if c then cap = c; i = i + 1 end
      end
      if not cap and out[#out] and out[#out]._caption then
        cap = out[#out]._caption
        out:remove(#out)
      end
      if cap and cap.kind == 'Figure' then
        out:insert(make_crop_figure(b, cap, ids_in(b)))
      else
        out:extend(make_table(b, cap, List()))
      end
      i = i + 1
    elseif caption_of(b) and nextb and (nextb.t == 'Table' or only_image(nextb)) then
      local cap = caption_of(b)
      if nextb.t == 'Table' then
        local kind = split_caption(pandoc.utils.blocks_to_inlines(nextb.caption.long))
        if not kind then
          local c = caption_of(b)
          if c.kind == 'Figure' then
            out:insert(make_crop_figure(nextb, c, List()))
          else
            out:extend(make_table(nextb, c, List()))
          end
          i = i + 2
        else
          log('caption-before-captioned-table', stringify(b))
          out:insert(b); i = i + 1
        end
      else
        -- caption above an image (e.g. an image of a table)
        log('caption-above-image', current.file, stringify(b))
        if cap.kind == 'Table' then
          -- a table shown as an image: a table whose one cell is the image
          local img = only_image(nextb)
          local text = caption_text(cap.inlines)
          local src = image_target(img, slug(text))
          local t = pandoc.Table({ long = {}, short = nil }, { { pandoc.AlignDefault, nil } },
            pandoc.TableHead({ pandoc.Row({ pandoc.Cell({ pandoc.Plain({ pandoc.Image({}, src) }) }) }) }),
            { { attr = {}, body = {}, head = {}, row_head_columns = 0 } }, pandoc.TableFoot())
          local h = pandoc.Header(6, { pandoc.Str('Table:'), pandoc.Space(), pandoc.Str(text) })
          local target = { kind = 'tbl', file = current.file, header = h, title = List({ pandoc.Str(text) }) }
          keyed(h, target)
          register(cap.ids, target)
          label_target('Table', cap.num, target)
          log('table', cap.num, text)
          out:insert(h)
          out:insert(t)
        else
          out:insert(make_figure(only_image(nextb), cap, ids_in(nextb)))
        end
        i = i + 2
      end
    elseif is_caption_div(b) or caption_of(b) then
      -- caption after an already converted table or image without caption
      local cap = caption_of(b)
      local last = out[#out]
      if cap and cap.kind == 'Table' and last and last.t == 'Table' and not (out[#out - 1] and out[#out - 1].t == 'Header' and out[#out - 1].level == 6) then
        local text = caption_text(cap.inlines)
        local h = pandoc.Header(6, { pandoc.Str('Table:'), pandoc.Space(), pandoc.Str(text) })
        local target = { kind = 'tbl', file = current.file, header = h, title = List({ pandoc.Str(text) }) }
        keyed(h, target)
        register(cap.ids, target)
        numbers.tbl[cap.num] = target
        log('table', cap.num, text)
        out:insert(#out, h)
      elseif cap and cap.kind == 'Figure' and last and (last.t == 'BlockQuote' or last.t == 'CodeBlock' or last.t == 'Table' or last.t == 'Para') and not (last.t == 'Para' and last.content[1] and last.content[1].t == 'Image') then
        -- a figure drawn with text (a boxed expression): cut from the PDF
        local fig = make_crop_figure(last, cap, List())
        if not (last.t == 'Para' and #stringify(last) > 80) then
          out:remove(#out)
          if last.t == 'Table' and out[#out] and out[#out].t == 'Header' and out[#out].level == 6 then out:remove(#out) end
        end
        out:insert(fig)
      elseif cap and cap.kind == 'Figure' and last and last.t == 'Para' and #last.content == 1 and last.content[1].t == 'Image' and #last.content[1].caption == 0 then
        log('late-figure-caption', current.file, stringify(b))
        local text = caption_text(cap.inlines)
        last.content[1].caption = { pandoc.Str(text) }
        local entry = entries_by_src[last.content[1].src]
        if entry then
          entry[3] = unique_name(slug(text))
          last.content[1].src = entry[3]
        end
        log('figure', cap.num, text)
        local target = { kind = 'fig', file = current.file, src = last.content[1].src, title = List({ pandoc.Str(text) }) }
        register(cap.ids, target)
        numbers.fig[cap.num] = target
      else
        log('stray-caption', current.file, stringify(b))
        if is_caption_div(b) then out:extend(process(b.content)) else out:insert(b) end
      end
      i = i + 1
    elseif b.t == 'Div' and b.attributes['custom-style'] == 'Code' then
      local lines = List()
      while blocks[i] and blocks[i].t == 'Div' and blocks[i].attributes['custom-style'] == 'Code' do
        for _, x in ipairs(blocks[i].content) do
          local t = x:walk{ LineBreak = function() return pandoc.Str('\n') end, SoftBreak = function() return pandoc.Space() end }
          lines:insert(to_ascii(stringify(t)))
        end
        i = i + 1
      end
      out:insert(pandoc.CodeBlock(table.concat(lines, '\n')))
    elseif b.t == 'Div' then
      out:extend(process(b.content)); i = i + 1
    elseif b.t == 'OrderedList' then
      if is_grammar(b) then
        local lines = List()
        grammar_lines(b, '', lines)
        out:insert(pandoc.CodeBlock(table.concat(lines, '\n')))
      elseif b.listAttributes.style == 'LowerAlpha' or b.listAttributes.style == 'UpperAlpha' then
        out:extend(lettered_paras(b))
      else
        local items = List()
        for _, item in ipairs(b.content) do items:insert(process(item)) end
        out:insert(pandoc.OrderedList(items, { b.listAttributes.start, 'Decimal', 'Period' }))
      end
      i = i + 1
    elseif b.t == 'BulletList' then
      local items = List()
      for _, item in ipairs(b.content) do items:insert(process(item)) end
      out:insert(pandoc.BulletList(items)); i = i + 1
    elseif b.t == 'BlockQuote' then
      local inner = process(b.content)
      -- a quote that only holds a figure, table or code is just indented
      if #inner == 1 and (inner[1].t == 'Table' or inner[1].t == 'CodeBlock' or (inner[1].t == 'Para' and #inner[1].content == 1 and inner[1].content[1].t == 'Image')) then
        out:extend(inner)
      elseif #inner > 0 then
        out:insert(pandoc.BlockQuote(inner))
      end
      i = i + 1
    elseif (b.t == 'Para' or b.t == 'Plain') and #trim_inlines(clean_inlines(b.content)) == 0 and #ids_in(b) == 0 then
      i = i + 1
    elseif b.t == 'Para' or b.t == 'Plain' then
      -- a "Table N:" caption that is followed by something other than a table
      -- is kept for a table that may follow later
      out:insert(b); i = i + 1
    else
      out:insert(b); i = i + 1
    end
  end
  return out
end

------------------------------------------------------------------------------
-- Annexes: headings are list items with styles ANNEX and a2
------------------------------------------------------------------------------

local function is_heading_list(b)
  if not b or b.t ~= 'OrderedList' then return false end
  local first = b.content[1] and b.content[1][1]
  local style = first and first.t == 'Div' and first.attributes['custom-style']
  return style == 'ANNEX' or style == 'a2'
end

-- Annex headings nested in the last item of a list (Word continues the
-- numbering of the heading list inside the bullet list before it): the
-- heading and everything after it in the item are moved after the list.
local function lift_headings(blocks)
  local out = List()
  for _, b in ipairs(blocks) do
    if (b.t == 'BulletList' or b.t == 'OrderedList') and not is_heading_list(b) then
      local items = b.content
      local last = items[#items]
      local after = List()
      for k, x in ipairs(last) do
        if is_heading_list(x) then
          for j = k, #last do after:insert(last[j]) end
          for j = #last, k, -1 do last:remove(j) end
          break
        end
      end
      out:insert(b)
      out:extend(lift_headings(after))
    else
      out:insert(b)
    end
  end
  return out
end

local function annex_headings(blocks)
  blocks = lift_headings(blocks)
  local out = List()
  for _, b in ipairs(blocks) do
    if b.t == 'OrderedList' then
      local first = b.content[1] and b.content[1][1]
      local style = first and first.t == 'Div' and first.attributes['custom-style']
      if style == 'ANNEX' or style == 'a2' then
        for _, item in ipairs(b.content) do
          local d = item[1]
          local inls = List()
          for _, x in ipairs(d.content) do if x.content then inls:extend(x.content); inls:insert(pandoc.Space()) end end
          local title = clean_inlines(inls)
          local text = stringify(title)
          local h = pandoc.Header(style == 'ANNEX' and 1 or 2, { pandoc.Str(trim(text)) })
          h.attributes['ids'] = table.concat(ids_in(d), ' ')
          out:insert(h)
          local rest = List()
          for k = 2, #item do rest:insert(item[k]) end
          out:extend(annex_headings(rest))
        end
      else
        out:insert(b)
      end
    elseif b.t == 'Div' and (b.attributes['custom-style'] == 'ANNEX' or b.attributes['custom-style'] == 'a2') then
      out:extend(annex_headings({ pandoc.OrderedList({ { b } }) }))
    else
      out:insert(b)
    end
  end
  return out
end

------------------------------------------------------------------------------
-- References in the text
------------------------------------------------------------------------------

local SEC_WORDS = { clause = true, Clause = true, clauses = true, Clauses = true, section = true,
  Section = true, sections = true, Sections = true, subclause = true, Subclause = true,
  ['sub-clause'] = true, chapter = true, Chapter = true }

local anchors = {}

local function link_to(target, from_file)
  local href
  if target.kind == 'fig' then
    href = target.src
  else
    local anchor = target.anchor
    if target.file == from_file then href = '#' .. anchor
    else href = target.file .. '.md#' .. anchor end
  end
  return pandoc.Link(target.title:clone(), href)
end

-- Remove the word before a reference that the PDF prints itself ("Clause 12",
-- "Annex A", "Figure 7.1", "Table 8.2")
local function drop_word_before(out, target)
  if #out < 2 or out[#out].t ~= 'Space' or out[#out - 1].t ~= 'Str' then return end
  local w = out[#out - 1].text
  local lead = w:match('^(%p*)')
  w = w:sub(#lead + 1)
  local drop = false
  if target.kind == 'fig' and (w == 'Figure' or w == 'figure') then drop = true end
  if target.kind == 'tbl' and (w == 'Table' or w == 'table') then drop = true end
  if target.kind == 'sec' and target.level == 1 and not target.whole and (SEC_WORDS[w] or w == 'Annex' or w == 'annex') then
    if not w:match('s$') then drop = true end
  end
  if drop then
    out:remove(#out); out:remove(#out)
    if lead ~= '' then out:insert(pandoc.Str(lead)) end
  end
end

local function lookup_number(kind, text)
  if kind == 'fig' then
    local a, b = text:match('^([%dA-Z]+)[%-%.](%d+)$')
    if a then return numbers.fig[a .. '-' .. b] end
  elseif kind == 'tbl' then
    return numbers.tbl[text]
  else
    return numbers.sec[text]
  end
end

-- Turn "Figure 6-1", "Table 12", "clause 10.3.2", "Annex A" written as text
-- into links
local function text_references(inls, file)
  local out = List()
  local i = 1
  local mode = nil   -- kind of the previous reference, for "10.3 and 10.4"
  while i <= #inls do
    local x = inls[i]
    local handled = false
    if x.t == 'Str' then
      local prev = out[#out - 1]
      local word = (out[#out] and out[#out].t == 'Space' and prev and prev.t == 'Str') and prev.text or nil
      -- "(clause 10)"
      if word then word = word:gsub('^%p+', '') end
      local kind
      if word == 'Figure' or word == 'figure' or word == 'Figures' or word == 'figures' then kind = 'fig'
      elseif word == 'Table' or word == 'table' or word == 'Tables' or word == 'tables' then kind = 'tbl'
      elseif word and SEC_WORDS[word] then kind = 'sec'
      -- "(see 10.3.2.2)": a subclause number without "clause"
      elseif (word == 'see' or word == 'See') and x.text:match('^%d+%.%d[%.%d]*') then kind = 'sec'
      elseif word == 'Annex' or word == 'annex' then kind = 'annex'
      elseif mode and word and (word == 'and' or word == 'or' or word == 'to') then kind = mode
      elseif mode and out[#out] and out[#out].t == 'Space' and prev and prev.t == 'Str' and prev.text:match('[,;]$') then kind = mode
      end
      if kind then
        local num, suffix
        if kind == 'fig' then
          num, suffix = x.text:match('^([%dA-Z]+%-%d+)([%p]*)$')
          -- "Figure 10- 2"
          if not num and x.text:match('^%d+%-$') and inls[i + 1] and inls[i + 1].t == 'Space' and inls[i + 2] and inls[i + 2].t == 'Str' then
            local n2, s2 = inls[i + 2].text:match('^(%d+)([%p]*)$')
            if n2 then num = x.text .. n2; suffix = s2; i = i + 2 end
          end
        elseif kind == 'tbl' then
          num, suffix = x.text:match('^(%d+)([%p]*)$')
        elseif kind == 'annex' then
          num, suffix = x.text:match('^([A-B])([%.,;:%)]*)$')
          kind = 'sec'
        else
          num, suffix = x.text:match('^(%d+[%.%d]*%d)([%p]*)$')
          if not num then num, suffix = x.text:match('^(%d+)([%p]*)$') end
          if not num then num, suffix = x.text:match('^([A-B]%.%d[%.%d]*)([%p]*)$') end
        end
        local target = num and lookup_number(kind, num)
        if target then
          if num and suffix and suffix:match('^%-') then target = nil end
        end
        if target then
          log('text-reference', file, (word or '') .. ' ' .. num, '->', target.file or '', stringify(target.title))
          drop_word_before(out, target)
          out:insert(link_to(target, file))
          if suffix and suffix ~= '' then out:insert(pandoc.Str(suffix)) end
          mode = kind
          handled = true
        end
      end
    end
    if not handled then
      out:insert(x)
      if x.t == 'Str' and not (x.text == 'and' or x.text == 'or' or x.text == 'to' or x.text:match('^%d[%d%.%-]*[,;]?$')) then mode = nil end
    end
    i = i + 1
  end
  return out
end

local function resolve_links(blocks, file)
  -- 1. links to bookmarks and headings of the Word document; their text
  -- becomes the title or caption of the target. (A separate pass, so that the
  -- text of a link, such as "Table 111", is not taken for a reference.)
  local doc = pandoc.Pandoc(blocks):walk{
    Link = function(x)
      if x.target:sub(1, 1) ~= '#' then return nil end
      local target = targets[x.target:sub(2)]
      local label = stringify(x):gsub('\u{00A0}', ' '):gsub('%s+', ' ')
      local loc = local_labels[file] and local_labels[file][label]
      if loc and loc ~= target then
        log('same-file-label', file, label)
        target = loc
      end
      if not target then
        log('unresolved-link', file, x.target, stringify(x))
        return x.content
      end
      local res = link_to(target, file)
      if res.t == 'Link' then
        res.attributes['refkind'] = target.kind
        res.attributes['level'] = tostring(target.level or 0)
      end
      return res
    end,
  }
  -- 2. the word before a reference that the PDF prints itself, and
  -- references written as text
  doc = doc:walk{
    Inlines = function(inls)
      local out = List()
      for _, x in ipairs(inls) do
        if x.t == 'Link' and x.attributes['refkind'] then
          drop_word_before(out, { kind = x.attributes['refkind'], level = tonumber(x.attributes['level']) })
          x.attributes = {}
        end
        out:insert(x)
      end
      return text_references(out, file)
    end,
  }
  return doc.blocks
end

------------------------------------------------------------------------------
-- Main
------------------------------------------------------------------------------

-- Headings whose numbering is switched off in Word (tools/unnumbered.py)
local unnumbered = List()
local unnumbered_next = 1
do
  local f = os.getenv('UNNUMBERED') and io.open(os.getenv('UNNUMBERED'))
  if f then
    for line in f:lines() do
      local level, text = line:match('^(%d)\t(.*)$')
      -- "ANNEXES" only starts the annexes (see Pandoc below)
      if level and text:upper():match('^%s*ANNEXES%s*$') == nil then
        unnumbered:insert({ level = tonumber(level), text = trim(text:gsub('\u{00A0}', ' ')) })
      end
    end
    f:close()
  end
end

local WRITER_EXT = table.concat({
  'markdown',
  '-grid_tables', '-multiline_tables', '-simple_tables', '+pipe_tables', '-table_captions',
  '+header_attributes', '-link_attributes', '-fenced_divs', '-bracketed_spans', '-native_divs',
  '-native_spans', '-raw_html', '-raw_attribute', '-inline_code_attributes', '-fenced_code_attributes',
  '-smart', '-subscript', '-superscript', '-inline_notes', '-example_lists', '-implicit_figures',
  '-escaped_line_breaks', '-line_blocks',
}, '')

local READER_EXT = 'markdown+gfm_auto_identifiers+lists_without_preceding_blankline-blank_before_header-blank_before_blockquote+autolink_bare_uris+alerts'

local front

function Pandoc(doc)
  -- Inline clean-up
  doc = doc:walk{
    -- non-breaking hyphens; a bullet from the Symbol font
    Str = function(s) s.text = s.text:gsub('\u{2011}', '-'):gsub('\u{F02E}', '•'); return s end,
    Underline = function(u) return u.content end,
    Subscript = function(s) return script_filter(s, SUB, 'sub') end,
    Superscript = function(s) return script_filter(s, SUP, 'sup') end,
    SmallCaps = function(s) return s.content end,
  }
  -- Web addresses that Word split into several links ("(", "https://...REC",
  -- "-xmlschema-2...#ID),") become one link; targets lose trailing spaces
  doc = doc:walk{
    Link = function(l)
      l.target = l.target:gsub('%%20$', ''):gsub('%s+$', '')
      -- a quote character that Word made part of a link
      local text = stringify(l)
      if not l.target:match('^#') and not text:match('[%w]') then return l.content end
      return l
    end,
  }
  doc = doc:walk{
    Inlines = function(inls)
      local out = List()
      local i = 1
      while i <= #inls do
        local x = inls[i]
        if x.t == 'Link' and not x.target:match('^#') and inls[i + 1] and inls[i + 1].t == 'Link' and not inls[i + 1].target:match('^#') then
          local j = i
          local text = ''
          while inls[j] and inls[j].t == 'Link' and not inls[j].target:match('^#') do
            text = text .. stringify(inls[j]); j = j + 1
          end
          local pre, url, post = text:match('^(.-)(https?://[^%s]-)([%),;%.]*)$')
          if url then
            log('merged-link', url)
            if pre ~= '' then out:insert(pandoc.Str(pre)) end
            out:insert(pandoc.Link({ pandoc.Str(url) }, url))
            if post ~= '' then out:insert(pandoc.Str(post)) end
            i = j
          else
            out:insert(x); i = i + 1
          end
        else
          out:insert(x); i = i + 1
        end
      end
      return out
    end,
  }
  -- the blocks before Clause 1, with their Word styles
  front = List()
  for _, b in ipairs(doc.blocks) do
    if b.t == 'Header' and b.level == 1 and stringify(b):match('^%s*Scope%s*$') then break end
    front:insert(b)
  end
  -- Word styles: keep the divs that carry meaning, unwrap all others
  local keep = { Code = true, caption = true, ANNEX = true, a2 = true }
  doc = doc:walk{
    Div = function(d)
      local style = d.attributes['custom-style'] or ''
      if style:match('^toc') then return {} end
      if keep[style] then return nil end
      return d.content
    end,
  }

  -- Clause 1 starts the clause files; the notices and the preface before it
  -- become 00_Notices.md and 00_Preface.md (the cover page, the copyrights and
  -- the table of contents come from the template)
  local blocks = List()
  local started = false
  for _, b in ipairs(doc.blocks) do
    if b.t == 'Header' and b.level == 1 and stringify(b):match('^%s*Scope%s*$') then started = true end
    if started then blocks:insert(b) end
  end
  local front_files = List()
  do
    local notices, preface = List(), List()
    local part
    for _, b in ipairs(front) do
      local style = b.t == 'Div' and b.attributes['custom-style'] or ''
      if style == 'small-print-heading-western' and stringify(b):match('USE OF SPECIFICATION') then part = notices end
      if style == 'zzContents' or style:match('^toc') then part = nil end
      if style == 'Foreword Title' then
        part = preface
        local h = pandoc.Header(1, { pandoc.Str('Preface') })
        h.classes = { 'unnumbered' }
        preface:insert(h)
      elseif part then
        if style == 'small-print-heading-western' then
          -- headings of the notices, such as "LICENSES"
          part:insert(pandoc.Para({ pandoc.Strong(clean_inlines(pandoc.utils.blocks_to_inlines(b.content))) }))
        else
          part:insert(b)
        end
      end
    end
    local function unwrap(bs)
      return pandoc.Pandoc(bs):walk{
        Div = function(d) return d.content end,
        Span = function(x) return x.content end,
        Underline = function(u) return u.content end,
      }.blocks
    end
    -- the logo of the cover page, used by \maketitle in
    -- _Specification_AuthorSettings.tex
    local logo
    pandoc.Pandoc(front):walk{ Image = function(i) logo = logo or i end }
    if logo then image_target(logo, 'omg-logo') end
    front_files:insert({ name = '00_Notices', blocks = unwrap(notices) })
    front_files:insert({ name = '00_Preface', blocks = unwrap(preface) })
  end

  -- Split into clause files and process
  local files = List()   -- { name, blocks }
  local counters = { 0, 0, 0, 0, 0, 0 }
  local clause_no = 0
  local in_annexes = false
  local annex_no = 0
  local file
  local strip_left = 0

  local function new_file(name)
    file = { name = name, blocks = List() }
    files:insert(file)
    current.file = name
  end

  for _, f in ipairs(front_files) do
    current.file = f.name
    files:insert({ name = f.name, blocks = process(f.blocks) })
  end

  -- Collect the blocks of each clause, then process them
  local segments = List()
  local seg
  for _, b in ipairs(blocks) do
    if b.t == 'Header' and b.level == 1 then
      seg = { header = b, blocks = List() }
      segments:insert(seg)
    else
      seg.blocks:insert(b)
    end
  end

  for _, s in ipairs(segments) do
    local title = trim(stringify(s.header))
    local body
    if title:upper() == 'ANNEXES' then
      in_annexes = true
      new_file('A_Annexes')
      body = annex_headings(s.blocks)
      -- "(informative)" after an annex title belongs to it, as in "Relation
      -- to BPMN (informative)"
      local merged = List()
      for _, b in ipairs(body) do
        local prev = merged[#merged]
        if prev and prev.t == 'Header' and prev.level == 1 and b.t == 'Para' and trim(stringify(b)) == '(informative)' then
          prev.content:extend({ pandoc.Space(), pandoc.Str('(informative)') })
        else
          merged:insert(b)
        end
      end
      body = merged
      -- footnotes typed as text ("1.Shipment Process ...") and marked with
      -- superscript digits become Markdown footnotes
      local notes = {}
      local rest = List()
      for _, b in ipairs(body) do
        local n = b.t == 'Para' and stringify(b):match('^(%d)%.%u')
        if n then
          local inls = List(b.content)
          inls[1] = pandoc.Str((inls[1].text:gsub('^%d%.', '')))
          notes[n] = pandoc.Para(inls)
        else
          rest:insert(b)
        end
      end
      local marks = { ['¹'] = '1', ['²'] = '2', ['³'] = '3' }
      body = pandoc.Pandoc(rest):walk{
        Str = function(x)
          local n = marks[x.text]
          if n and notes[n] then return pandoc.Note({ notes[n] }) end
        end,
      }.blocks
      -- the introduction ("All the Annexes are informative ...") stays under
      -- the unnumbered heading "ANNEXES", as in DMN
      local h = pandoc.Header(1, { pandoc.Str('ANNEXES') })
      h.classes = { 'unnumbered' }
      body = List({ h }) .. body
    else
      clause_no = clause_no + 1
      local name = clause_file(clause_no, title)
      if not name then
        log('skipped-clause', clause_no, title)
        -- still count its headings, for numbers
        counters = { clause_no, 0, 0, 0, 0, 0 }
        goto continue
      end
      new_file(name)
      body = List({ s.header }) .. s.blocks
    end

    do
      -- headings: numbers, targets; other blocks processed in runs
      local run = List()
      local function flush()
        if #run > 0 then
          -- images that are not figures, e.g. notation symbols in tables
          local bs = pandoc.Pandoc(process(run)):walk{
            Image = function(img)
              if not img.src:match('^Images/') then
                img.src = image_target(img, slug(current.heading .. ' symbol'))
                img.caption = {}
                img.attributes = {}
                return img
              end
            end,
          }.blocks
          file.blocks:extend(bs)
          run = List()
        end
      end
      local strip = strip_headings[file.name] or 0
      for _, b in ipairs(body) do
        if b.t == 'Header' and trim(stringify(b)) ~= '' and not b.attributes['tbl'] then
          flush()
          local level = b.level
          local num
          local nonum = unnumbered[unnumbered_next]
          nonum = nonum and nonum.level == level and nonum.text == trim(stringify(b):gsub('\u{00A0}', ' '))
          if List(b.classes):includes('unnumbered') then
            num = 'unnumbered-annexes'
          elseif nonum then
            unnumbered_next = unnumbered_next + 1
            num = 'unnumbered-' .. unnumbered_next
          elseif in_annexes then
            if level == 1 then annex_no = annex_no + 1; counters = { annex_no, 0, 0, 0, 0, 0 }
            else counters[level] = counters[level] + 1; for k = level + 1, 6 do counters[k] = 0 end end
            local parts = { letter(counters[1], true) }
            for k = 2, level do parts[#parts + 1] = tostring(counters[k]) end
            num = table.concat(parts, '.')
          else
            if level == 1 then counters = { clause_no, 0, 0, 0, 0, 0 }
            else counters[level] = counters[level] + 1; for k = level + 1, 6 do counters[k] = 0 end end
            local parts = {}
            for k = 1, level do parts[#parts + 1] = tostring(counters[k]) end
            num = table.concat(parts, '.')
          end
          local inls = clean_inlines(b.content)
          -- headings such as "Decision Table " or "DMNShape [Class]"
          local h = pandoc.Header(level, inls)
          if nonum or List(b.classes):includes('unnumbered') then h.classes = { 'unnumbered' } end
          local target = { kind = 'sec', file = file.name, level = level, header = h, title = inls:clone(), num = num }
          keyed(h, target)
          local ids = ids_in(b)
          if b.attributes['ids'] then for id in b.attributes['ids']:gmatch('%S+') do ids:insert(id) end end
          register(ids, target)
          numbers.sec[num] = target
          current.heading = stringify(inls)
          if level == 1 and strip >= 1 then
            target.whole = true
          elseif level == 2 and strip >= 2 and counters[2] == 1 then
            -- "Conformance levels" becomes the template's "Basic Conformance"
            target.whole = true
          else
            file.blocks:insert(h)
          end
        elseif b.t == 'Header' and trim(stringify(b)) == '' then
          flush()
        else
          run:insert(b)
        end
      end
      flush()
    end
    ::continue::
  end

  -- Heading identifiers as GitHub (and the build) generate them, per file
  anchors = {}
  for _, f in ipairs(files) do
    local headers = List()
    pandoc.Pandoc(f.blocks):walk{ Header = function(h) headers:insert(h) end }
    local md = pandoc.write(pandoc.Pandoc(headers), WRITER_EXT)
    local back = pandoc.read(md, READER_EXT)
    local k = 0
    for _, b in ipairs(back.blocks) do
      if b.t == 'Header' then
        k = k + 1
        if headers[k].attributes['key'] then anchors[headers[k].attributes['key']] = b.identifier end
      end
    end
    if k ~= #headers then log('heading-count-mismatch', f.name, k, #headers) end
  end
  -- anchors of targets
  for _, t in pairs(targets) do
    if t.kind == 'sec' or t.kind == 'tbl' then t.anchor = anchors[t.key] end
  end
  for _, t in pairs(numbers.sec) do t.anchor = anchors[t.key] end
  for _, t in pairs(numbers.tbl) do t.anchor = anchors[t.key] end
  for _, labels in pairs(local_labels) do
    for _, t in pairs(labels) do if t.key then t.anchor = anchors[t.key] end end
  end
  -- headings that the template provides (Clauses 1, 2, 2.1 and 6) cannot be
  -- linked to: their numbers, which the template fixes, are written as text
  local orig_link_to = link_to
  local fixed = { ['01_Scope'] = '1', ['02_Basic_Conformance'] = '2', ['06_Additional'] = '6' }
  link_to = function(target, from_file)
    if target.kind == 'sec' and target.whole then
      return pandoc.Str(fixed[target.file] .. (target.level == 2 and '.1' or ''))
    end
    return orig_link_to(target, from_file)
  end

  -- Resolve references and write the files
  for _, f in ipairs(files) do
    local bs = resolve_links(f.blocks, f.name)
    -- remove remaining spans (bookmarks) and identifiers
    local d = pandoc.Pandoc(bs):walk{
      Span = function(s) return s.content end,
      Header = function(h) h.identifier = ''; h.attributes = {}; return h end,
      Image = function(i) i.identifier = ''; i.attributes = {}; i.classes = {}; return i end,
      Link = function(l) l.identifier = ''; l.attributes = {}; l.classes = {}; return l end,
    }
    local md = pandoc.write(d, WRITER_EXT, { wrap_text = 'none' })
    -- unnumbered headings as the guide writes them
    md = md:gsub(' {%.unnumbered}\n', ' {-}\n')
    local fh = io.open(OUT .. '/' .. f.name .. '.md', 'w')
    fh:write(md)
    fh:close()
    log('wrote', f.name)
  end

  -- Clauses 5 and later, in order (the template includes Clauses 1 to 4 itself)
  local list = io.open(OUT .. '/07+_Technical_Content.tex', 'w')
  list:write('% Clauses 5 and later of DMN, written by tools/docx2md.lua\n')
  for _, f in ipairs(files) do
    local n = tonumber(f.name:match('^(%d%d)_'))
    if n and n >= 5 then list:write('\\subimport{}{' .. f.name .. '}\n') end
  end
  list:close()

  local manifest = io.open(MANIFEST, 'w')
  for _, e in ipairs(manifest_entries) do manifest:write(table.concat(e, '\t'), '\n') end
  manifest:close()
  logf:close()
  return pandoc.Pandoc({})
end
