# Grid table probe

+---------------------+-----------------------+--------+
| Applicant Data                              | Risk   |
+=====================+=======================+========+
| Age                 | Income                | low    |
+---------------------+-----------------------+        |
| 51                  | 10000                 |        |
+---------------------+-----------------------+--------+
| A cell with two paragraphs.                 | - item |
|                                             | - two  |
| Second paragraph with `code`.               |        |
+---------------------------------------------+--------+

Same content as an HTML table:

<table>
<tr><th colspan="2">Applicant Data</th><th>Risk</th></tr>
<tr><td>Age</td><td>Income</td><td rowspan="2">low</td></tr>
<tr><td>51</td><td>10000</td></tr>
<tr><td colspan="2"><p>A cell with two paragraphs.</p><p>Second paragraph with <code>code</code>.</p></td><td><ul><li>item</li><li>two</li></ul></td></tr>
</table>
