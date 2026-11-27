--[[
dmn-pages.lua: starts the pages of the PDF where the pages of the Word PDF of
DMN start. Part of the build (see omgLaTeX.yaml); the Markdown files have no
page breaks.

dmn-pages.txt (written by tools/pages.py from the Word PDF) lists, for each
page of the Word PDF, its clause, the number of words of the clause before it,
and its first words. This filter looks for each page's first words in the
clause file: at the start of a paragraph, heading, list item, definition,
figure caption, table caption, table row or code line, or inside a paragraph
or table row (Word continues paragraphs and table rows on the next page). Of
the places with these words, it takes the one at about the same position in
the clause, and starts a page there: before the paragraph, row or code line,
splitting tables and code blocks. Pages that cannot be placed (e.g. starting
with an image) start where LaTeX starts them.
]]

local stringify = pandoc.utils.stringify
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
do
  local dir = PANDOC_SCRIPT_FILE:match('^(.*)/[^/]*$') or '.'
  local f = io.open(dir .. '/dmn-pages.txt')
  if f then
    for line in f:lines() do
      local page, p, pos, first = line:match('^(%d+)\t(%S+)\t(%d+)\t(.*)$')
      if p == part then
        pages:insert({ page = tonumber(page), pos = tonumber(pos), words = words(first) })
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

local function add_slot(kind, text, inside)
  local slot = { kind = kind, words = words(text), pos = position, inside = inside }
  slots:insert(slot)
  return slot
end

-- The text of a block as the Word PDF shows it: a figure by its caption,
-- "Figure 6-1: ..."
local function block_text(b)
  if b.t == 'Figure' then return 'Figure ' .. stringify(b.caption.long) end
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
  local ref_total = 0
  for _, p in ipairs(pages) do ref_total = math.max(ref_total, p.pos) end
  ref_total = ref_total + 400   -- the words of the last page
  local from = 1
  for _, p in ipairs(pages) do
    local expected = total * p.pos / ref_total
    local best, best_d
    for i = from, #slots do
      if matches(p.words, slots[i]) then
        local d = math.abs(slots[i].pos - expected)
        if not best or d < best_d then best, best_d = i, d end
      end
    end
    -- a match far from the expected position is not taken
    if best and best_d <= math.max(400, total * 0.08) then
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
  for i, row in ipairs(t.bodies[1].body) do
    local br = next_break()
    if br and i == 1 then out:insert(BREAK)
    elseif br then emit(); out:insert(BREAK) end
    part:insert(row)
  end
  emit()
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
      local parts = split_rows(b)
      -- a page break before the table goes before its caption heading
      local prev = out[#out]
      if parts[1].t == 'RawBlock' and prev and prev.t == 'Header' and stringify(prev):match('^Table:') then
        out:remove(#out)
        out:insert(parts[1])
        out:insert(prev)
        parts:remove(1)
      end
      out:extend(parts)
    elseif b.t == 'CodeBlock' then
      out:extend(split_lines(b))
    elseif b.t == 'BulletList' or b.t == 'OrderedList' then
      local items = List()
      for _, item in ipairs(b.content) do items:insert(insert_breaks(item)) end
      b.content = items
      out:insert(b)
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

-- A table's first row is repeated on each page only if it is a heading row
-- (bold text, such as "Attribute | Description"); Markdown tables always have
-- a header row, also where the first row of the Word table is data (the
-- decision tables of Table 38), which Word does not repeat
local function is_heading_row(row)
  local any = false
  for _, c in ipairs(row.cells) do
    local inl = pandoc.utils.blocks_to_inlines(c.contents)
    local text = stringify(inl):gsub('%s', '')
    if text ~= '' then
      any = true
      local only_strong = true
      for _, x in ipairs(inl) do
        if not (x.t == 'Strong' or x.t == 'Space' or x.t == 'SoftBreak') then only_strong = false end
      end
      if not only_strong then return false end
    end
  end
  return any
end

local function demote_header(t)
  local rows = t.head.rows
  if #rows == 1 and #t.bodies == 1 and not is_heading_row(rows[1]) then
    local body = List({ rows[1] })
    body:extend(t.bodies[1].body)
    t.bodies[1].body = body
    t.head = pandoc.TableHead()
  end
  return t
end

function Pandoc(doc)
  doc = doc:walk{ Table = demote_header }
  if #pages == 0 then return doc end
  collect_blocks(doc.blocks)
  assign()
  doc.blocks = insert_breaks(doc.blocks)
  if slot_no ~= #slots then io.stderr:write('dmn-pages.lua: slot count mismatch\n') end
  return doc
end
