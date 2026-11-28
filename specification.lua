-- Specification filter (see specification.lua in mdsa-omg-core): DMN decision
-- tables and boxed expressions in the notation of DMN 1.7 (8.2 and 10.2.1),
-- and FEEL code.
--
-- Both are HTML tables, which GitHub shows with their merged cells. A table's
-- caption is an ordinary table caption (numbered, listed, linkable). The name
-- box (the information item name) is the first header row, with a single cell
-- spanning the whole table. Italics are written by the author (<em>), because
-- in DMN they mean string literals (7.2.2.1), and so is the default output
-- value, underlined (<ins>, 8.2.12).
--
-- Decision tables, <table class="dmn-decision-table">, in three orientations:
--
-- - Rules as rows (Figures 8-5, 8-6, 8-12): a <colgroup> marks each column as
--   hit-policy, input, output or annotation. The hit policy cell spans the
--   clause rows; allowed values have the class "values".
-- - Rules as columns (Figures 8-7, 8-8, 8-13): each row has the class input,
--   output, annotation or hit-policy (the row of the hit policy and the rule
--   numbers). The clause cells come first, then the "values" cells, then the
--   entries.
-- - Crosstab (Figures 8-9 to 8-11, 8-14): the table also has the class
--   crosstab. The header rows hold the output label (its width is the width of
--   the row header columns) and the column inputs; input expressions and the
--   output label have the class input or output. The other body cells right
--   of the row headers are output entries.
--
-- The PDF shows single lines between all cells and the double lines of 8.2.1:
-- between inputs and outputs, between outputs and annotations, and between
-- clauses and entries. The clauses are shaded per kind (colors dmninput,
-- dmnoutput, dmnannotation in _Specification_AuthorSettings.tex; in crosstabs
-- also the output entries, as in Figure 8-10); the hit policy, the allowed
-- values and the entries stay white. Sans-serif, not bold; entries centered,
-- annotations left-aligned.
--
-- Boxed expressions, <table class="dmn-boxed-expression"> (10.2.1): name
-- cells (context entry names, parameters, if/then/else) have the class name and
-- are shaded (dmnname), and so are cells of class input, output or annotation
-- (a decision table entry of a context, Figure 10-10); nested boxed
-- expressions are merged cells or tables in cells. Cells of class gap are whitespace: they draw no lines of their own,
-- except the line on the left (top) edge of the table that connects the
-- entries of a context (10.2.1.4, Figures 10-6, 10-7 and 10-10).
--
-- tables.lua of the core writes the tables; this filter only adds tabularray
-- settings through the table's tblr-* attributes.

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

function Table(tbl)
  if tbl.classes:includes('dmn-decision-table') then return decision_table(tbl) end
  if tbl.classes:includes('dmn-boxed-expression') then return boxed_expression(tbl) end
end

-- FEEL code (```feel, `...`{.feel}): pandoc passes only languages it knows to
-- the listings package; FEEL is defined in _Specification_AuthorSettings.tex
local function delimiter(text)
  for d in ('!|+@#%&^'):gmatch('.') do
    if not text:find(d, 1, true) then return d end
  end
end

function CodeBlock(el)
  if el.classes:includes('feel') then
    return pandoc.RawBlock('latex', '\\begin{lstlisting}[language=FEEL]\n' .. el.text .. '\n\\end{lstlisting}')
  end
end

function Code(el)
  if el.classes:includes('feel') then
    local d = delimiter(el.text)
    return pandoc.RawInline('latex', '\\passthrough{\\lstinline[language=FEEL]' .. d .. el.text .. d .. '}')
  end
end
