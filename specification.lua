-- Specification filter (see specification.lua in mdsa-omg-core): DMN decision
-- tables in the official notation (DMN 1.7, 8.2.1 "Line style and color").
--
-- A decision table is an HTML table with the class dmn-decision-table, whose
-- <colgroup> marks each column as hit-policy, input, output or annotation:
--
--   <table class="dmn-decision-table">
--   <caption>Discount</caption>
--   <colgroup><col class="hit-policy"><col class="input"><col class="output"></colgroup>
--   <thead>
--   <tr><th rowspan="2">U</th><th>Customer</th><th>Discount</th></tr>
--   <tr><td class="values"><em>Business</em>, <em>Private</em></td><td class="values">0, 0.05</td></tr>
--   </thead>
--   <tbody>...rules...</tbody>
--   </table>
--
-- The hit policy cell spans the clause rows (rowspan), as in DMN Figures 8-5,
-- 8-6 and 8-12. The PDF shows:
-- - the caption as the name box above and adjoining the table (8.2.5)
-- - single lines between all cells, double lines between input and output
--   columns, between output and annotation columns, and below the clauses
--   (8.2.1, normative)
-- - the clauses (input expressions, output label, output component names and
--   annotation names) shaded per column group (colors dmninput, dmnoutput,
--   dmnannotation, defined in _Specification_AuthorSettings.tex); the hit
--   policy cell, the allowed values (cells of class "values") and the entries
--   stay white, as in Figure 8-6
-- - sans-serif text, not bold; entries centered, annotations left-aligned
-- Italics are not added: in DMN they mean string literals (7.2.2.1), so the
-- author writes them (<em>Business</em>), in allowed values and entries alike.
-- tables.lua of the core writes the table; this filter only adds tabularray
-- settings through the table's tblr-* attributes.

local COLOR = { input = 'dmninput', output = 'dmnoutput', annotation = 'dmnannotation' }

local function double_vline(i)
  return ('vline{%d}={1}{-}{solid}, vline{%d}={2}{-}{solid}'):format(i, i)
end

-- Cells of the given rows with their row and column, taking merged cells
-- into account
local function placed(rows)
  local cells, covered = {}, {}
  for r, row in ipairs(rows) do
    covered[r] = covered[r] or {}
    local c = 1
    for _, cell in ipairs(row.cells) do
      while covered[r][c] do c = c + 1 end
      table.insert(cells, { row = r, col = c, cell = cell })
      for dr = 0, cell.row_span - 1 do
        covered[r + dr] = covered[r + dr] or {}
        for dc = 0, cell.col_span - 1 do covered[r + dr][c + dc] = true end
      end
      c = c + cell.col_span
    end
  end
  return cells
end

-- Rough natural width of the table in characters: the longest text per column,
-- plus some room for the cell padding
local function natural_width(tbl, n)
  local rows = {}
  for _, r in ipairs(tbl.head.rows) do table.insert(rows, r) end
  for _, b in ipairs(tbl.bodies) do
    for _, r in ipairs(b.body) do table.insert(rows, r) end
  end
  local len = {}
  for i = 1, n do len[i] = 2 end
  for _, p in ipairs(placed(rows)) do
    if p.cell.col_span == 1 then
      len[p.col] = math.max(len[p.col], utf8.len(pandoc.utils.stringify(p.cell.contents)) or 0)
    end
  end
  local total = 0
  for i = 1, n do total = total + len[i] + 3 end
  return total
end

-- Natural column widths while the table fits the text width (about 95
-- characters of small sans-serif text); wider tables get the column widths
-- that tables.lua computes, and wrap their cells, as in DMN Figure 8-19
local FITS = 95

function Table(tbl)
  if not tbl.classes:includes('dmn-decision-table') then return nil end
  local groups = {}
  for g in (tbl.attributes['columns'] or ''):gmatch('%S+') do table.insert(groups, g) end
  local n, nhead = #tbl.colspecs, #tbl.head.rows

  local inner = { 'cells={font=\\sffamily\\small}', ('row{1-%d}={font=\\sffamily\\small}'):format(nhead) }
  -- double lines between the column groups and below the clauses
  for i = 1, n - 1 do
    local a, b = groups[i], groups[i + 1]
    if (a == 'input' and (b == 'output' or b == 'annotation')) or (a == 'output' and b == 'annotation') then
      table.insert(inner, double_vline(i + 1))
    end
  end
  table.insert(inner, ('hline{%d}={1}{-}{solid}, hline{%d}={2}{-}{solid}'):format(nhead + 1, nhead + 1))
  -- shaded clauses; the hit policy cell at the top
  for _, p in ipairs(placed(tbl.head.rows)) do
    local g = groups[p.col]
    if COLOR[g] and not p.cell.classes:includes('values') then
      table.insert(inner, ('cell{%d}{%d}={bg=%s}'):format(p.row, p.col, COLOR[g]))
    elseif g == 'hit-policy' and p.row == 1 then
      table.insert(inner, ('cell{1}{%d}={valign=h}'):format(p.col))
    end
  end
  tbl.attributes['tblr-inner'] = table.concat(inner, ',\n  ')
  -- entries centered, annotations left-aligned; room for the hit policy
  if natural_width(tbl, n) <= FITS then
    local colspec = {}
    for i = 1, n do
      colspec[i] = groups[i] == 'annotation' and 'Q[l]' or groups[i] == 'hit-policy' and 'Q[c,wd=1.2em]' or 'Q[c]'
    end
    tbl.attributes['tblr-colspec'] = table.concat(colspec)
  else
    for i = 1, n do
      tbl.colspecs[i] = { groups[i] == 'annotation' and pandoc.AlignLeft or pandoc.AlignCenter, tbl.colspecs[i][2] }
    end
  end
  tbl.attributes['tblr-env'] = 'tblr'

  -- the caption is the name box above the table
  local name = pandoc.write(pandoc.Pandoc({ pandoc.Plain(pandoc.utils.blocks_to_inlines(tbl.caption.long)) }),
                            'latex', PANDOC_WRITER_OPTIONS):gsub('%s+$', '')
  tbl.caption.long = {}
  local before = '\\begin{center}\\begin{tabular}{@{}l@{}}'
  if name ~= '' then
    before = before .. '\\begin{tblr}{colspec={Q[l,wd=12em]}, hlines, vlines, cells={font=\\sffamily\\small\\bfseries}}\n'
      .. name .. '\n\\end{tblr}\\\\[-\\arrayrulewidth]\n'
  end
  tbl.attributes['tblr-before'] = before
  tbl.attributes['tblr-after'] = '\\end{tabular}\\end{center}'
  return tbl
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
