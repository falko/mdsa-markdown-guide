# Grammar

1. <a id="rule-expression"></a>expression =
   1. boxed expression |
   2. textual expression ;
2. <a id="rule-textual-expression"></a>textual expression =
   1. <a id="rule-textual-expression-for"></a>for expression | if expression | quantified expression |
   2. disjunction |
   3. conjunction ;
3. textual expressions = textual expression , { "," , textual expression } ;
4. <a id="rule-arithmetic-expression"></a>arithmetic expression =
   1. addition | subtraction |
   2. multiplication | division ;

See [textual expression](#rule-textual-expression) and [for expressions](#rule-textual-expression-for).
