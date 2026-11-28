# Simple Expression Language (S-FEEL)

## Introduction

**DMN** defines the friendly enough expression language (FEEL) for the purpose of giving standard executable semantics to many kinds of expressions in decision model (see [Expression Language (FEEL)](10_Expression_Language_FEEL.md#expression-language-feel)).

This section defines a simple subset of FEEL, S-FEEL, for the purpose of giving standard executable semantics to decision models that use only simple expressions: in particular, decision models where the decision logic is modeled mostly or only using decision tables.

Experience with DMN since its release has shown that few if any complete decision models can be defined using S- FEEL. Individual decision tables can be defined using only S-FEEL but within a decision model there is generally at least one decision that requires FEEL. Developers and users are therefore encouraged to use and implement the full FEEL specification rather than the S-FEEL subset.

## S-FEEL syntax

The syntax for the S-FEEL expressions used in this section is specified in the EBNF below: it is a subset of the FEEL syntax specified in clause [Grammar rules](10_Expression_Language_FEEL.md#grammar-rules).

**Grammar rules**:

1. <a id="rule-s-feel-expression"></a>expression = simple expression ;
1. <a id="rule-s-feel-arithmetic-expression"></a>arithmetic expression =
   1. <a id="rule-s-feel-arithmetic-expression-i"></a>addition | subtraction |
   1. <a id="rule-s-feel-arithmetic-expression-ii"></a>multiplication | division |
   1. <a id="rule-s-feel-arithmetic-expression-iii"></a>exponentiation |
   1. <a id="rule-s-feel-arithmetic-expression-iv"></a>arithmetic negation ;
1. <a id="rule-s-feel-simple-expression"></a>simple expression = arithmetic expression | simple value | comparison ;
1. <a id="rule-s-feel-simple-expressions"></a>simple expressions = simple expression , { "," , simple expression } ;
1. <a id="rule-s-feel-simple-positive-unary-test"></a>simple positive unary test =
   1. <a id="rule-s-feel-simple-positive-unary-test-i"></a>\[ "\<" | "\<=" | "\>" | "\>=" \] , endpoint |
   1. <a id="rule-s-feel-simple-positive-unary-test-ii"></a>interval ;
1. <a id="rule-s-feel-interval"></a>interval = ( open interval start | closed interval start ) , endpoint , ".." , endpoint , ( open interval end | closed interval end ) ;
1. <a id="rule-s-feel-open-interval-start"></a>open interval start = "(" | "\]" ;
1. <a id="rule-s-feel-closed-interval-start"></a>closed interval start = "\[" ;
1. <a id="rule-s-feel-open-interval-end"></a>open interval end = ")" | "\[" ;
1. <a id="rule-s-feel-closed-interval-end"></a>closed interval end = "\]" ;
1. <a id="rule-s-feel-simple-positive-unary-tests"></a>simple positive unary tests = simple positive unary test , { "," , simple positive unary test } ;
1. <a id="rule-s-feel-simple-unary-tests"></a>simple unary tests =
   1. <a id="rule-s-feel-simple-unary-tests-i"></a>simple positive unary tests |
   1. <a id="rule-s-feel-simple-unary-tests-ii"></a>"not", "(", simple positive unary tests, ")" |
   1. <a id="rule-s-feel-simple-unary-tests-iii"></a>"-";
1. <a id="rule-s-feel-endpoint"></a>endpoint = simple value ;
1. <a id="rule-s-feel-simple-value"></a>simple value = qualified name | simple literal ;
1. <a id="rule-s-feel-qualified-name"></a>qualified name = name , { "." , name } ;
1. <a id="rule-s-feel-addition"></a>addition = expression , "+" , expression ;
1. <a id="rule-s-feel-subtraction"></a>subtraction = expression , "-" , expression ;
1. <a id="rule-s-feel-multiplication"></a>multiplication = expression , "\*" , expression ;
1. <a id="rule-s-feel-division"></a>division = expression , "/" , expression ;
1. <a id="rule-s-feel-exponentiation"></a>exponentiation = expression, "\*\*", expression ;
1. <a id="rule-s-feel-arithmetic-negation"></a>arithmetic negation = "-" , expression ;
1. <a id="rule-s-feel-name"></a>name = name start , { name part | additional name symbols } ;
1. <a id="rule-s-feel-name-start"></a>name start = name start char, { name part char } ;
1. <a id="rule-s-feel-name-part"></a>name part = name part char , { name part char } ;
1. <a id="rule-s-feel-name-start-char"></a>name start char = "?" | \[A-Z\] | "\_" | \[a-z\] | \[\\uC0-\\uD6\] | \[\\uD8-\\uF6\] | \[\\uF8-\\u2FF\] | \[\\u370-\\u37D\] | \[\\u37F\\u1FFF\] | \[\\u200C-\\u200D\] | \[\\u2070-\\u218F\] | \[\\u2C00-\\u2FEF\] | \[\\u3001-\\uD7FF\] | \[\\uF900-\\uFDCF\] | \[\\uFDF0-\\uFFFD\] | \[\\u1 0000-\\uEFFFF\] ;
1. <a id="rule-s-feel-name-part-char"></a>name part char = name start char | digit | \\uB7 | \[\\u0300-\\u036F\] | \[\\u203F-\\u2040\] ;
1. <a id="rule-s-feel-additional-name-symbols"></a>additional name symbols = "." | "/" | "-" | """'" | "+" | "\*" ;
1. <a id="rule-s-feel-simple-literal"></a>simple literal = numeric literal | string literal | boolean literal | date time literal ;
1. <a id="rule-s-feel-string-literal"></a>string literal = """, { character ""- (""" | vertical space) | string escape sequence}, """ ;
1. <a id="rule-s-feel-boolean-literal"></a>boolean literal = "true" | "false" ;
1. <a id="rule-s-feel-numeric-literal"></a>numeric literal = \[ "-" \] , ( digits , \[ ".", digits \] | "." , digits ) ;
1. <a id="rule-s-feel-digit"></a>digit = \[0-9\] ;
1. <a id="rule-s-feel-digits"></a>digits = digit , {digit} ;
1. <a id="rule-s-feel-date-time-literal"></a>date time literal = ("date" | "time" | "duration" | "days and time duration" | "years and months duration") , "(" , string literal , ")" ;comparison = expression , ( "=" | "!=" | "\<" | "\<=" | "\>" | "\>=" ) , expression ;
1. <a id="rule-s-feel-white-space"></a>white space = vertical space | \\u0009 | \\u0020 | \\u0085 | \\u00A0 | \\u1 680 | \\u1 80E | \[\\u2000-\\u200B\] | \\u2028 | \\u2029 | \\u202F | \\u205F | \\u3000 | \\uFEFF ;
1. <a id="rule-s-feel-vertical-space"></a>vertical space = \[\\u000A-\\u000D\];
1. <a id="rule-s-feel-string-escape-sequence"></a>string escape sequence = "\\'" | "\\"" | "\\\\" | "\\n" | "\\r" | "\\t" | "\\u", hex digit, hex digit, hex digit, hex digit;

## S-FEEL data types

S-FEEL supports all FEEL data types: *number*, *string*, *boolean*, *days and time duration*, *years and months duration*, *time,* and *date*, although with a simplified definition for some of them.

S-FEEL *number* has the same literal and values spaces as the XML Schema decimal datatype. Implementations are allowed to limit precision to 34 decimal digits and to round toward the nearest neighbor with ties favoring the even neighbor. Notice that “*precision is not reflected in this value space: the number 2.0 is not distinct from the number 2.00*” \[XML Schema\]. Notice, also, that this value space is totally ordered. The definition of S-FEEL *number* is a simplification over the definition of FEEL *number*.

S-FEEL supports FEEL *string* and FEEL *Boolean*: FEEL *string* has the same literal and values spaces as the Java String and XML Schema string datatypes. FEEL *boolean* has the same literal and values spaces as the Java Boolean and XML Schema Boolean datatypes.

> S-FEEL supports the FEEL *time* data type. The lexical and value spaces of FEEL *time* are the literal and value spaces of the XML Schema time datatype. Notice that “*since the lexical representation allows an optional time zone indicator, time values are partially ordered because it may not be able to determine the order of two values one of which has a time zone and the other does not. Pairs of time values with or without time zone indicators are totally ordered*” \[XSD\].

S-FEEL does not support FEEL date and time. However, it supports the *date* type, which is like FEEL *date and time* with hour, minute, and second required to be absent. The lexical and value spaces of FEEL *date* are the literal and value spaces of the XML Schema date datatype.

S-FEEL supports the FEEL *days and time duration* and *years and months duration* datatypes. FEEL *days and time duration* and *years and months duration* have the same literal and value spaces as the XPath Data Model dayTimeDuration and yearMonthDuration datatypes, respectively. That is, FEEL *days and time duration* is derived from the XML Schema duration datatype by restricting its lexical representation to contain only the days, hours, minutes, and seconds components, and FEEL *years and months duration* is derived from the XML Schema duration datatype by restricting its lexical representation to contain only the year and month components.

The FEEL data types are specified in detail in clause [Equality, Identity and Equivalence](10_Expression_Language_FEEL.md#equality-identity-and-equivalence).

## S-FEEL semantics

S-FEEL contains only a limited set of basic features that are common to most expression and programming languages, and on the semantics of which most expression and programming languages agree.

The semantics of S-FEEL expressions are defined in this section, in terms of the semantics of the XML Schema datatypes and the XQuery 3.1 and XPath 3.1 Data Model datatypes, and in terms of the corresponding functions and operators defined by XQuery 3.1 and XPath 3.1 Functions and Operators (prefixed by “op:” below). A complete standalone specification of the semantics is to be found in clause [Semantics](10_Expression_Language_FEEL.md#semantics), as part of the definition of FEEL. Within the scope of S- FEEL, the two definitions are equivalent and equally normative.

Arithmetic addition and subtraction (grammar [arithmetic expression](#rule-s-feel-arithmetic-expression-i)) have the same semantics as:

- op:numeric-add and op:numeric-subtract, when its two operands are numbers.

- op:add-yearMonthDurations and op:subtract-yearMonthDurations, when the two operands are years and months durations.

- op:add-dayTimeDuration and subtract:dayTimeDurations, when the two operands are days and time durations.

- op:add-yearMonthDuration-to-date and op:subtract-yearMonthDuration-from-date, when the first operand is a years and months duration, and the second operand is a date.

- op:add-dayTimeDuration-to-date and op:subtract-dayTimeDuration-from-date, when the first operand is a days and time duration, and the second operand is a date.

- op:add-dayTimeDuration-to-time and op:subtract-dayTimeDuration-from-time, when the first operand is a days and time duration, and the second operand is a time.

In addition, arithmetic subtraction has the semantics of op:subtract-dates or op:subtract-times, when the two operands are dates or times, respectively.

Arithmetic addition and subtraction are not defined in other cases.

Arithmetic multiplication and division (grammar [arithmetic expression](#rule-s-feel-arithmetic-expression-ii)) have the same semantics as defined for op:numeric-multiply and op:numeric-divide, respectively, when the two operands are numbers. They are not defined otherwise.

Arithmetic exponentiation (grammar [arithmetic expression](#rule-s-feel-arithmetic-expression-iii)) is defined as the result of raising the first operand to the power of the second operand, when the two operands are numbers. It is not defined in other cases.

Arithmetic negation (grammar [arithmetic expression](#rule-s-feel-arithmetic-expression-iv)) is defined only when its operand is a number: in that case, its semantics is according to the specification of op:numeric-unary-minus.

Comparison operators (grammar [white space](#rule-s-feel-white-space)) between numbers are defined according to the specification of op:numericequal, op-numeric-less-than and op:numeric-greater-than, comparisons between dates are defined according to the specification of op:date-equal, op:date-less-than and op:date-greater-than; comparisons between times are defined according to the specification of op:time-equal, op:time-less-than and op:time-greater-than; comparisons between years and months durations are defined according to the specification of op:duration-equal,

op:yearMonthDuration-less-than and op:year-MonthDuration-greater-than; comparisons between days and time durations are defined according to the specification of op:duration-equal, op:dayTimeDuration-less-than and op:dayTimeDuration-greater-than.

String and Booleans can only be compared for equality: the semantics of strings and Booleans equality is as defined in the specification of fn:codepoint-equal and op:Boolean-equal, respectively.

Comparison operators are defined only when the two operands have the same type, except for years and months duration and days and time duration, which can be compared for equality. Notice, however, that “*with the exception of the zero- length duration, no instance of xs:dayTimeDuration can ever be equal to an instance of xs:yearMonthDuration*.” \[XFO\].

Given an expression o to be tested and two endpoint e1 and e2:

- is in the interval `(e1..e2)`, also notated `]e1..e2[`, if and only if `o > e1 and o < e1`

- is in the interval `(e1..e2]`, also notated `]e1..e2]`, if and only if o \> e1 and o ≤ e2

- is in the interval `[e1..e2]` if and only if o ≥ e1 and o ≤ e2

- is in the interval `[e1..e2)`, also notated `[e1..e2[`, if and only if o ≥ e1 and o \< e2

An expression to be tested satisfies an instance of simple unary tests (grammar [simple unary tests](#rule-s-feel-simple-unary-tests)) if and only if, either the expression is a list and the expression satisfies at least one simple unitary test in the list, or the simple unitary tests is `-`.

## Use of S-FEEL expressions

This section summarizes which kinds of S-FEEL expressions are allowed in which role when the expression language is S-FEEL.

### Item definitions

The expression that defines an **allowed value** SHALL be an instance of *simple unary tests* (grammar [simple unary tests](#rule-s-feel-simple-unary-tests)), where only the values in the defined or referenced type that satisfy the test are allowed values.

### Invocations

In the bindings of an invocation, the **binding formula** SHALL be a *simple expression* (grammar [simple expression](#rule-s-feel-simple-expression)).

### Decision tables

Each **input expression** SHALL be a *simple expression* (grammar [simple expression](#rule-s-feel-simple-expression)).

Each list of **input values** SHALL be an instance of *simple unary tests* (grammar [simple unary tests](#rule-s-feel-simple-unary-tests)).

Each list of **output values** SHALL be an instance of *simple unary tests* (grammar [simple unary tests](#rule-s-feel-simple-unary-tests)). Each **input entry** SHALL be an instance of *simple unary tests* (grammar [simple unary tests](#rule-s-feel-simple-unary-tests)).

Each **output entry** SHALL be a *simple expression* (grammar [simple expression](#rule-s-feel-simple-expression)).
