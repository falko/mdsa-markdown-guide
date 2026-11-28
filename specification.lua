--[[
specification.lua: DMN's own filter (the hook of mdsa-omg-core, which runs it
after pandoc-crossref and before tables.lua). It gives the PDF the pages and
the tables of the Word PDF of DMN; the Markdown files have neither page breaks
nor table styles.

Tables: Arial-like sans-serif text with some space in the cells, as in DMN.

Pages: dmn-pages.txt (written by tools/pages.py from the Word PDF, copied next
to this filter by Makefile.mdsa) lists, for each page of the Word PDF, its
clause, the number of words of the clause before it, and its first words. This
filter looks for each page's first words in the clause file: at the start of a
paragraph, heading, list item, definition, figure caption, table caption, table
row or code line, or inside a paragraph or table row (Word continues paragraphs
and table rows on the next page). Of the places with these words, it takes the
one at about the same position in the clause, and starts a page there: before
the paragraph, row or code line, splitting tables and code blocks. Pages that
cannot be placed (e.g. starting with an image) start where LaTeX starts them.
]]

--[[
Notation: DMN decision tables and boxed expressions are HTML tables in the
notation of DMN 8.2 and 10.2.1 (class dmn-decision-table or
dmn-boxed-expression), as described in the guide (guide/10_Tables.md,
"Specification-specific table styles"); this filter adds the tabularray
settings of the notation (see guide/specification.lua for the details). DMN
also has cells of class optional (inverse, in the schematic layouts),
highlight and invalid (in illustrations), and in boxed expressions rows of
class double-line (a double line above the row, as between list items).

FEEL: inline code is FEEL, highlighted with the listings language FEEL
(_Specification_AuthorSettings.tex), unless it starts with "<" (XML) or has a
class; so is a code block of language feel. Inline code in headings and
captions is not highlighted (listings cannot be used there).
]]

local function stringify(x)
  if type(x) == 'table' or type(x) == 'userdata' then
    local ok, clean = pcall(function()
      return pandoc.Pandoc({ pandoc.Div(x.t and { x } or x) }):walk{
        RawInline = function() return {} end, RawBlock = function() return {} end }.blocks
    end)
    if ok then return pandoc.utils.stringify(clean) end
  end
  return pandoc.utils.stringify(x)
end
local List = pandoc.List

local function words(text, n)
  local w = List()
  for word in text:gmatch('%a+') do
    w:insert(word:lower())
    if n and #w >= n then break end
  end
  return w
end

-- the clause of the converted file
local input = PANDOC_STATE.input_files[1] or ''
local base = input:match('([^/]+)%.md$') or ''
local part
if base == '00_Notices' then part = 'N'
elseif base == '00_Preface' then part = 'P'
elseif base:match('^A_') then part = 'A'
elseif base:match('^%d%d_') then part = tostring(tonumber(base:sub(1, 2)))
end

local pages = List()
local ref_words          -- the number of words of the clause in the Word PDF
do
  local dir = PANDOC_SCRIPT_FILE:match('^(.*)/[^/]*$') or '.'
  local f = io.open(dir .. '/dmn-pages.txt')
  if f then
    for line in f:lines() do
      local page, p, pos, first, before = line:match('^(%d+)\t(%S+)\t(%d+)\t([^\t]*)\t?(.*)$')
      if p == part and page == '0' then
        ref_words = tonumber(pos)
      elseif p == part then
        pages:insert({ page = tonumber(page), pos = tonumber(pos), words = words(first), before = words(before or '') })
      end
    end
    f:close()
  end
end

------------------------------------------------------------------------------
-- Places where a page can start ("slots"), in document order, with their
-- position (words before them) and their words
------------------------------------------------------------------------------

local slots = List()
local position = 0

-- the last words before the current slot, to tell apart places that start
-- with the same words (a name in several lists)
local recent = List()
local function add_slot(kind, text, inside)
  local w = words(text)
  local slot = { kind = kind, words = w, pos = position, inside = inside, before = recent }
  slots:insert(slot)
  local r = List()
  r:extend(recent)
  r:extend(w)
  while #r > 12 do r:remove(1) end
  recent = r
  return slot
end

-- do the words before a slot end with the words before a page?
local function preceded_by(slot, before)
  if #before == 0 then return false end
  local n, m = #slot.before, #before
  if n < m then return false end
  for i = 1, m do if slot.before[n - m + i] ~= before[i] then return false end end
  return true
end

-- The text of a block as the Word PDF shows it: a figure by its caption,
-- "Figure 6-1: ..."
local function block_text(b)
  if b.t == 'Figure' then return 'Figure ' .. stringify(b.caption.long) end
  if b.t == 'Table' then return 'Table ' .. stringify(b.caption.long) end
  if (b.t == 'Para' or b.t == 'Plain') and #b.content == 1 and b.content[1].t == 'Image' then
    return 'Figure ' .. stringify(b.content[1].caption)
  end
  return stringify(b)
end

local collect

local function collect_blocks(blocks)
  for _, b in ipairs(blocks) do collect(b) end
end

local function add(kind, text, inside)
  local s = add_slot(kind, text, inside)
  position = position + #s.words
end

local function code_lines(text)
  local lines = List()
  for line in (text .. '\n'):gmatch('([^\n]*)\n') do lines:insert(line) end
  return lines
end

-- The traversal of collect and insert_breaks must be the same: slots are
-- numbered in this order
collect = function(b)
  if b.t == 'Para' or b.t == 'Plain' or b.t == 'BlockQuote' then
    add('block', block_text(b), true)
  elseif b.t == 'Header' or b.t == 'Figure' then
    add('block', block_text(b), false)
  elseif b.t == 'CodeBlock' then
    for _, line in ipairs(code_lines(b.text)) do add('line', line, false) end
  elseif b.t == 'Table' then
    -- the caption (above the table, "Table 10: ..."), then the rows
    add('block', block_text(b), false)
    for _, body in ipairs(b.bodies) do
      for _, row in ipairs(body.body) do
        local text = List()
        for _, c in ipairs(row.cells) do text:insert(stringify(c.contents)) end
        add('row', table.concat(text, ' '), true)
      end
    end
  elseif b.t == 'BulletList' or b.t == 'OrderedList' then
    for _, item in ipairs(b.content) do collect_blocks(item) end
  elseif b.t == 'DefinitionList' then
    for _, item in ipairs(b.content) do
      local text = stringify(item[1])
      for _, def in ipairs(item[2]) do text = text .. ' ' .. stringify(def) end
      add('def', text, true)
    end
  elseif b.t == 'Div' then
    collect_blocks(b.content)
  end
end

-- Does a slot have the words of a page: at its start, or (for paragraphs and
-- rows) inside, also with other words between them (the first lines of the
-- cells of a table row)?
local function matches(key, slot)
  local w = slot.words
  if #w == 0 or #key == 0 then return false end
  local at_start = #w >= #key
  for i = 1, #key do if w[i] ~= key[i] then at_start = false; break end end
  -- short keys (a heading such as "time") must be the whole text
  if at_start and #key < 3 and #w ~= #key then at_start = false end
  if at_start then return true end
  if not slot.inside or #key < 4 then return false end
  if slot.kind == 'row' or slot.kind == 'def' then
    -- the first lines of the cells (of a table row, or of the term and the
    -- definition of a glossary entry): the words in order, with others between
    local i = 1
    for n, x in ipairs(w) do
      if n > 60 then return false end
      if x == key[i] then i = i + 1 end
      if i > #key then return true end
    end
    return false
  end
  -- inside a paragraph only near its start: the page starts before the
  -- paragraph, which moves the paragraph's first lines to the page
  for s = 1, math.min(#w - #key, 25) do
    local ok = true
    for i = 1, #key do if w[s + i] ~= key[i] then ok = false; break end end
    if ok then return true end
  end
  return false
end

-- For each page, the slot with its words nearest to the page's position in
-- the clause, after the slot of the page before
local function assign()
  local total = position
  local ref_total = ref_words
  if not ref_total then
    ref_total = 0
    for _, p in ipairs(pages) do ref_total = math.max(ref_total, p.pos) end
    ref_total = ref_total + 400   -- the words of the last page
  end
  local from = 1
  for _, p in ipairs(pages) do
    local expected = total * p.pos / ref_total
    local best, best_d
    for i = from, #slots do
      if matches(p.words, slots[i]) then
        local d = math.abs(slots[i].pos - expected)
        -- the place after the words that end the page before is the one
        if preceded_by(slots[i], p.before) then d = d - total end
        if not best or d < best_d then best, best_d = i, d end
      end
    end
    -- a match far from the expected position is not taken
    if best and best_d <= math.max(400, total * 0.08) or (best and best_d < 0) then
      slots[best].page_break = true
      from = best + 1
    end
  end
end

------------------------------------------------------------------------------
-- Page breaks
------------------------------------------------------------------------------

local BREAK = pandoc.RawBlock('latex', '\\clearpage')

local slot_no = 0
local function next_break()
  slot_no = slot_no + 1
  return slots[slot_no] and slots[slot_no].page_break
end

local insert_breaks

local function split_rows(t)
  local before = next_break()
  if #t.bodies ~= 1 then
    for _, body in ipairs(t.bodies) do for _ in ipairs(body.body) do next_break() end end
    return List({ t })
  end
  local out = List()
  local part, first = List(), true
  local function emit()
    local nt = t:clone()
    nt.bodies[1].body = part
    if not first then nt.caption = pandoc.Caption() end
    out:insert(nt)
    part, first = List(), false
  end
  -- rows that a merged cell of an earlier row reaches into: no break there
  local covered = {}
  for i, row in ipairs(t.bodies[1].body) do
    for _, c in ipairs(row.cells) do
      for k = i + 1, i + c.row_span - 1 do covered[k] = true end
    end
  end
  for i, row in ipairs(t.bodies[1].body) do
    local br = next_break()
    if br and covered[i] then br = false end
    if br and i == 1 then out:insert(BREAK)
    elseif br then emit(); out:insert(BREAK) end
    part:insert(row)
  end
  emit()
  -- a page that starts with the caption of the table
  if before and out[1].t ~= 'RawBlock' then out:insert(1, BREAK) end
  return out
end

local function split_lines(b)
  local out = List()
  local part = List()
  for _, line in ipairs(code_lines(b.text)) do
    if next_break() then
      if #part > 0 then out:insert(pandoc.CodeBlock(table.concat(part, '\n'), b.attr)) end
      out:insert(BREAK)
      part = List()
    end
    part:insert(line)
  end
  out:insert(pandoc.CodeBlock(table.concat(part, '\n'), b.attr))
  return out
end

insert_breaks = function(blocks)
  local out = List()
  for _, b in ipairs(blocks) do
    if b.t == 'Para' or b.t == 'Plain' or b.t == 'BlockQuote' or b.t == 'Header' or b.t == 'Figure' then
      -- a clause starts on a new page anyway (Specification_Template.tex)
      if next_break() and not (b.t == 'Header' and b.level == 1) then out:insert(BREAK) end
      out:insert(b)
    elseif b.t == 'Table' then
      out:extend(split_rows(b))
    elseif b.t == 'CodeBlock' then
      out:extend(split_lines(b))
    elseif b.t == 'BulletList' or b.t == 'OrderedList' then
      -- a page that starts with an item: the list is split there, so that
      -- the item's bullet or number moves to the new page with it
      local items = List()
      local start = b.t == 'OrderedList' and (b.listAttributes.start or 1) or nil
      local function emit()
        if #items == 0 then return end
        local l = b:clone()
        l.content = items
        if start then l.listAttributes.start = start end
        out:insert(l)
        if start then start = start + #items end
        items = List()
      end
      for _, item in ipairs(b.content) do
        local blocks = insert_breaks(item)
        if blocks[1] and blocks[1].t == 'RawBlock' and blocks[1].text == '\\clearpage' then
          blocks:remove(1)
          emit()
          out:insert(BREAK)
        end
        items:insert(blocks)
      end
      emit()
    elseif b.t == 'DefinitionList' then
      -- each definition is a list of its own, so that a page can start with it
      for _, item in ipairs(b.content) do
        if next_break() then out:insert(BREAK) end
        out:insert(pandoc.DefinitionList({ item }))
      end
    elseif b.t == 'Div' then
      b.content = insert_breaks(b.content)
      out:insert(b)
    else
      out:insert(b)
    end
  end
  return out
end

-- The cells of all tables in a sans-serif font, a little smaller than the
-- text, with some space above and below, as the tables of DMN
local function table_style(t)
  local inner = 'cells={font=\\sffamily\\small}, rowsep=3pt'
  -- first, so that a notation's own fonts (e.g. a bold name box) win
  t.attributes['tblr-inner'] = t.attributes['tblr-inner'] and (inner .. ', ' .. t.attributes['tblr-inner']) or inner
  return t
end

local COLOR = { input = 'dmninput', output = 'dmnoutput', annotation = 'dmnannotation', name = 'dmnname' }
local KINDS = { 'input', 'output', 'annotation', 'hit-policy' }

-- Natural column widths while the table fits the text width (about 95
-- characters of small sans-serif text); wider tables get the column widths
-- that tables.lua computes, and wrap their cells, as in DMN Figure 8-19
local FITS = 95

-- All rows (header rows first) and their cells with row and column, taking
-- merged cells into account; owner[r][c] is the cell covering row r, column c
local function grid(tbl)
  local rows = {}
  for _, r in ipairs(tbl.head.rows) do table.insert(rows, r) end
  for _, b in ipairs(tbl.bodies) do
    for _, r in ipairs(b.head) do table.insert(rows, r) end
    for _, r in ipairs(b.body) do table.insert(rows, r) end
  end
  for _, r in ipairs(tbl.foot.rows) do table.insert(rows, r) end
  local cells, owner = {}, {}
  for r = 1, #rows do owner[r] = owner[r] or {} end
  for r, row in ipairs(rows) do
    local c = 1
    for _, cell in ipairs(row.cells) do
      while owner[r][c] do c = c + 1 end
      local p = { row = r, col = c, cell = cell, last_col = c + cell.col_span - 1, last_row = r + cell.row_span - 1 }
      table.insert(cells, p)
      for dr = 0, cell.row_span - 1 do
        owner[r + dr] = owner[r + dr] or {}
        for dc = 0, cell.col_span - 1 do owner[r + dr][c + dc] = p end
      end
      c = c + cell.col_span
    end
  end
  return rows, cells, owner
end

local function kind(classes)
  for _, k in ipairs(KINDS) do
    if classes:includes(k) then return k end
  end
end

local function double_vline(j, from)
  return ('vline{%d}={1}{%d-Z}{solid}, vline{%d}={2}{%d-Z}{solid}'):format(j, from, j, from)
end

local function double_hline(i)
  return ('hline{%d}={1}{-}{solid}, hline{%d}={2}{-}{solid}'):format(i, i)
end

local function shade(inner, p, color)
  table.insert(inner, ('cell{%d}{%d}={bg=%s}'):format(p.row, p.col, color))
end

-- Column widths: natural while the table fits, else computed by tables.lua.
-- align[i] is l or c; the hit policy column (hit) gets a little room.
local function column_widths(tbl, cells, n, align, hit)
  local len = {}
  for i = 1, n do len[i] = 2 end
  for _, p in ipairs(cells) do
    if p.cell.col_span == 1 then
      len[p.col] = math.max(len[p.col], utf8.len(pandoc.utils.stringify(p.cell.contents)) or 0)
    end
  end
  local total = 0
  for i = 1, n do total = total + len[i] + 3 end
  if total <= FITS then
    local colspec = {}
    for i = 1, n do colspec[i] = i == hit and 'Q[c,wd=1.2em]' or ('Q[' .. align[i] .. ']') end
    tbl.attributes['tblr-colspec'] = table.concat(colspec)
  else
    for i = 1, n do
      tbl.colspecs[i] = { align[i] == 'l' and pandoc.AlignLeft or pandoc.AlignCenter, tbl.colspecs[i][2] }
    end
  end
end

-- The name box: the first header row, with a single cell spanning the table.
-- Returns the first row after it.
local function name_box(tbl, n, inner)
  local first = tbl.head.rows[1]
  if first and #first.cells == 1 and first.cells[1].col_span == n then
    table.insert(inner, 'cell{1}{1}={halign=l, font=\\sffamily\\small\\bfseries}')
    return 2
  end
  return 1
end

-- Rules as rows: the <colgroup> marks the columns
local function rules_as_rows(tbl, cells, n, nhead, first, inner)
  local groups = {}
  for g in (tbl.attributes['columns'] or ''):gmatch('%S+') do table.insert(groups, g) end
  local hit
  for i = 1, n - 1 do
    local a, b = groups[i], groups[i + 1]
    if (a == 'input' and (b == 'output' or b == 'annotation')) or (a == 'output' and b == 'annotation') then
      table.insert(inner, double_vline(i + 1, first))
    end
  end
  table.insert(inner, double_hline(nhead + 1))
  for _, p in ipairs(cells) do
    local g = groups[p.col]
    if p.row >= first and p.row <= nhead then
      if COLOR[g] and not p.cell.classes:includes('values') then
        shade(inner, p, COLOR[g])
      elseif g == 'hit-policy' and p.row == first then
        table.insert(inner, ('cell{%d}{%d}={valign=h}'):format(p.row, p.col))
      end
    end
  end
  local align = {}
  for i = 1, n do
    align[i] = groups[i] == 'annotation' and 'l' or 'c'
    if groups[i] == 'hit-policy' then hit = i end
  end
  return align, hit
end

-- Rules as columns: the classes of the rows mark them
local function rules_as_columns(rows, cells, n, first, inner)
  local k = 1 -- the last column of clauses and allowed values
  local firsts = {}
  for _, p in ipairs(cells) do
    local kd = kind(rows[p.row].attr.classes)
    if kd == 'input' or kd == 'output' or kd == 'annotation' then
      if not firsts[p.row] or p.cell.classes:includes('values') then
        firsts[p.row] = true
        k = math.max(k, p.last_col)
      end
    end
  end
  table.insert(inner, double_vline(k + 1, first))
  local before
  for r = first, #rows do
    local kd = kind(rows[r].attr.classes)
    if (before == 'input' and (kd == 'output' or kd == 'annotation')) or (before == 'output' and kd == 'annotation') then
      table.insert(inner, double_hline(r))
    end
    before = kd
  end
  for _, p in ipairs(cells) do
    local kd = kind(rows[p.row].attr.classes)
    if COLOR[kd] and p.col <= k and not p.cell.classes:includes('values') then shade(inner, p, COLOR[kd]) end
  end
  local align = {}
  for i = 1, n do align[i] = 'c' end
  return align
end

-- Crosstab: the output label, first in the header, is as wide as the row
-- headers
local function crosstab(tbl, cells, n, nhead, first, inner)
  local label = tbl.head.rows[first] and tbl.head.rows[first].cells[1]
  local k = label and label.col_span or 1
  table.insert(inner, double_vline(k + 1, first))
  table.insert(inner, double_hline(nhead + 1))
  for _, p in ipairs(cells) do
    local kd = kind(p.cell.classes)
    if COLOR[kd] then
      shade(inner, p, COLOR[kd])
    elseif p.row > nhead and p.col > k then
      shade(inner, p, COLOR.output)
    end
  end
  local align = {}
  for i = 1, n do align[i] = 'c' end
  return align
end

local function decision_table(tbl)
  local rows, cells = grid(tbl)
  local n, nhead = #tbl.colspecs, #tbl.head.rows
  local inner = { 'cells={font=\\sffamily\\small}', ('row{1-%d}={font=\\sffamily\\small}'):format(math.max(nhead, 1)),
    -- vertical lines run through the gap of the double line below the clauses
    'vlines={abovepos=1, belowpos=1}' }
  local first = name_box(tbl, n, inner)
  local align, hit
  if tbl.classes:includes('crosstab') then
    align = crosstab(tbl, cells, n, nhead, first, inner)
  elseif tbl.attributes['columns'] then
    align, hit = rules_as_rows(tbl, cells, n, nhead, first, inner)
  else
    align = rules_as_columns(rows, cells, n, first, inner)
  end
  tbl.attributes['tblr-inner'] = table.concat(inner, ',\n  ')
  column_widths(tbl, cells, n, align, hit)
  return tbl
end

-- Line segments of a boxed expression: a line between two different cells, or
-- on the edge of the table, unless both sides are whitespace (gap cells or
-- outside the table). A gap across the whole width (between the entries of a
-- vertical context) keeps the line on its left, a gap across the whole height
-- (in a horizontal context) the line on its top; other gaps (a jagged edge) have
-- no lines of their own.
local function boxed_lines(rows, owner, n)
  local R = #rows
  local function real(p) return p ~= nil and not p.cell.classes:includes('gap') end
  local function across_width(p) return p and p.col == 1 and p.last_col == n end
  local function across_height(p) return p and p.last_row == R and (p.row == 1 or not real(owner[p.row - 1][p.col])) end
  local segments = {}
  local function add(kind_, i, from, to)
    -- vertical lines run through the gap of a double line (abovepos, belowpos)
    local style = kind_ == 'vline' and 'solid, abovepos=1, belowpos=1' or 'solid'
    table.insert(segments, ('%s{%d}={1}{%d-%d}{%s}'):format(kind_, i, from, to, style))
    -- a row of class double-line has a double line above it (e.g. between the
    -- items of a boxed list, Figure 10-12)
    if kind_ == 'hline' and rows[i] and rows[i].attr.classes:includes('double-line') then
      table.insert(segments, ('%s{%d}={2}{%d-%d}{solid}'):format(kind_, i, from, to))
    end
  end
  for i = 1, R + 1 do -- hline i is above row i
    local start
    for c = 1, n + 1 do
      local a, b = owner[i - 1] and owner[i - 1][c], owner[i] and owner[i][c]
      local draw = c <= n and a ~= b and (real(a) or real(b) or (a == nil and across_height(b)))
      if draw and not start then start = c end
      if not draw and start then add('hline', i, start, c - 1); start = nil end
    end
  end
  for j = 1, n + 1 do -- vline j is left of column j
    local start
    for r = 1, R + 1 do
      local a, b = owner[r] and owner[r][j - 1], owner[r] and owner[r][j]
      local draw = r <= R and a ~= b and (real(a) or real(b) or (a == nil and across_width(b)))
      if draw and not start then start = r end
      if not draw and start then add('vline', j, start, r - 1); start = nil end
    end
  end
  return table.concat(segments, ',\n  ')
end

local function boxed_expression(tbl)
  local rows, cells, owner = grid(tbl)
  local n, nhead = #tbl.colspecs, #tbl.head.rows
  local inner = { 'cells={font=\\sffamily\\small}', ('row{1-%d}={font=\\sffamily\\small}'):format(math.max(nhead, 1)) }
  name_box(tbl, n, inner)
  for _, p in ipairs(cells) do
    local kd = p.cell.classes:includes('name') and 'name' or kind(p.cell.classes)
    if COLOR[kd] then shade(inner, p, COLOR[kd]) end
  end
  tbl.attributes['tblr-lines'] = boxed_lines(rows, owner, n)
  tbl.attributes['tblr-inner'] = table.concat(inner, ',\n  ')
  local align = {}
  for i = 1, n do align[i] = 'l' end
  column_widths(tbl, cells, n, align)
  return tbl
end

-- Cells of class optional are drawn in inverse, as the optional cells of the
-- schematic layouts (Figures 8-5, 8-7, 8-12); highlight and invalid mark cells
-- in illustrations (merged input entry cells allowed and not allowed, Figures
-- 8-15, 8-16)
local MARK = { optional = 'bg=dmnoptional, fg=white', highlight = 'bg=dmnhighlight', invalid = 'bg=dmninvalid' }

local function marks(tbl)
  local _, cells = grid(tbl)
  local inner = {}
  for _, p in ipairs(cells) do
    for class, style in pairs(MARK) do
      if p.cell.classes:includes(class) then
        table.insert(inner, ('cell{%d}{%d}={%s}'):format(p.row, p.col, style))
      end
    end
  end
  if #inner > 0 then
    tbl.attributes['tblr-inner'] = (tbl.attributes['tblr-inner'] or '') .. ',\n  ' .. table.concat(inner, ',\n  ')
  end
  return tbl
end

-- Quotes in the notation are FEEL (string literals): straight, not the curly
-- quotes of pandoc's smart typography
local function straight_quotes(tbl)
  return tbl:walk({ Quoted = function(q)
    local mark = q.quotetype == 'DoubleQuote' and '"' or "'"
    local out = pandoc.Inlines({ pandoc.Str(mark) })
    out:extend(q.content)
    out:insert(pandoc.Str(mark))
    return out
  end })
end

local function notation(tbl)
  if tbl.classes:includes('dmn-decision-table') then return decision_table(tbl) end
  if tbl.classes:includes('dmn-boxed-expression') then return boxed_expression(tbl) end
end


-- FEEL code: inline code (unless XML or with a class) and ```feel blocks.
-- pandoc writes inline code (escaping and delimiters) only with a language it
-- knows, so it is written as Ada and the language is then replaced by FEEL.
local function feel_code(el)
  if #el.classes == 0 and not el.text:match('^%s*<') then
    local code = pandoc.Code(el.text, pandoc.Attr('', { 'ada' }))
    local tex = pandoc.write(pandoc.Pandoc({ pandoc.Plain({ code }) }), 'latex', PANDOC_WRITER_OPTIONS)
    tex = tex:gsub('%s+$', '')
    local replaced, n = tex:gsub('language=Ada', 'language=FEEL', 1)
    if n == 1 then return pandoc.RawInline('latex', replaced) end
  end
end

local function feel_block(el)
  if el.classes:includes('feel') then
    return pandoc.RawBlock('latex', '\\begin{lstlisting}[language=FEEL]\n' .. el.text .. '\n\\end{lstlisting}')
  end
end

-- not in headings and captions
local feel = { traverse = 'topdown', Code = feel_code, CodeBlock = feel_block }
feel.Header = function(h) return h, false end
feel.Figure = function(f) return f, false end
feel.Table = function(t)
  local caption = t.caption
  t.caption = pandoc.Caption()
  t = t:walk(feel)
  t.caption = caption
  return t, false
end

function Pandoc(doc)
  doc = doc:walk{ Table = function(t)
    if t.classes:includes('dmn-decision-table') or t.classes:includes('dmn-boxed-expression') then t = marks(notation(straight_quotes(t))) end
    return table_style(t)
  end }
  doc = doc:walk(feel)
  if #pages == 0 then return doc end
  collect_blocks(doc.blocks)
  assign()
  doc.blocks = insert_breaks(doc.blocks)
  if slot_no ~= #slots then io.stderr:write('specification.lua: slot count mismatch\n') end
  return doc
end
