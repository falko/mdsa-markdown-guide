# B-FEEL

## Introduction

**DMN** defines the friendly enough expression language (FEEL) for the purpose of giving standard executable semantics to many kinds of expressions in a decision model (see [Expression Language (FEEL)](10_Expression_Language_FEEL.md#expression-language-feel)).

This chapter defines a dialect of FEEL: B-FEEL (Business Friendly Enough Expression Language). B-FEEL shares the same grammar as FEEL but alters the semantics to be friendlier and more intuitive toward non-IT users.

In FEEL, the **null** value is used to both represent missing data or an execution error. In B-FEEL, **null** is used only to represent missing data. All operations and built-in functions that returns null in FEEL when an error occurs have their semantics modified in B-FEEL to return a non-**null** value. A warning message should still be produced when an error occurs.

To use B-FEEL instead of FEEL, the expression language must be set to: "https://www.omg.org/spec/DMN/B-FEEL/"  
If FEEL is used in other languages, e.g. as an expression language in a BPMN process model, a version number MUST be added to the URL, i.e. "https://www.omg.org/spec/DMN/B-FEEL/1.7".

The following sections present the semantics of B-FEEL and compare it to the semantics of FEEL. Anything not covered in this chapter has the behavior described for FEEL in [Expression Language (FEEL)](10_Expression_Language_FEEL.md#expression-language-feel).

## Operator and built-in functions returning a Boolean

Removing **null** as an error from the result of operators and built-in functions for boolean values makes B-FEEL a two-value logic (**true** and **false**) compared to the three-value logic of FEEL (**true**, **false** and **null**).

In B-FEEL boolean operators ( =, \<=, \<, \>, \>=, not(), and, or, in, between ) always return a true or false result (never **null**) even when incompatible types are used in their expression.

In B-FEEL an incompatible type in a boolean expression is considered false with the exception of the not equal (!=) where it is considered true.

| Expression             | FEEL | B-FEEL |
|------------------------|------|--------|
| "a" = 1                | null | false  |
| "a" \< 1               | null | false  |
| "a" \<= null           | null | false  |
| "a" \> 1               | null | false  |
| null \>= 1             | null | false  |
| not("a")               | null | false  |
| true and “x”           | null | false  |
| false or “x”           | null | false  |
| "a" in \[1..100\]      | null | false  |
| null between 1 and 100 | null | false  |
| “a” != 1               | null | true   |

Several FEEL built-in functions return a boolean result. In B-FEEL, those functions’ semantics are modified to return **false** everywhere FEEL would return **null** for them.

| Expression                       | FEEL | B-FEEL |
|----------------------------------|------|--------|
| matches("bad pattern","\[0-9")   | null | false  |
| before(date("2021-01-01"), null) | null | false  |
| all(true,"x",true)               | null | false  |
| any(null)                        | null | false  |

## Built-in functions returning a number

Several FEEL built-in functions return a numeric result. In B-FEEL, those functions’ semantics are modified to return 0 everywhere FEEL would return **null** for them.

In addition, the list functions that return a number (mean(), median(), product(), stddev(), sum()) except count() ignore non-numeric parameters passed in their input list in B-FEEL.

| Expression          | FEEL | B-FEEL |
|---------------------|------|--------|
| decimal(“a”, 0)     | null | 0      |
| round up(“5.5”, 0)  | null | 0      |
| string length(22)   | null | 0      |
| day of year(“a”)    | null | 0      |
| count(\[1,null,3\]) | 3    | 3      |
| sum(\[1, null, 3\]) | null | 4      |
| sum(\[1, ”1” ,3\])  | null | 4      |
| sum(\[\])           | null | 0      |
| mean(\[“a”\])       | null | 0      |
| mean(\[1, “a”, 3\]) | null | 2      |

The C+ decision table policy being defined as the sum of the outputs yields a slightly different result in B-FEEL because the sum function semantics are altered.

## Built-in functions returning a string

Several FEEL built-in functions return a string result. Those methods’ semantics in B-FEEL are modified to return an empty string (“”) everywhere FEEL would return **null** for them.

| Expression          | FEEL | B-FEEL |
|---------------------|------|--------|
| lowercase(12)       | null | “”     |
| string(null)        | null | “”     |
| day of week(“a”)    | null | “”     |
| substring(“a”, “z”) | null | “”     |

## Built-in functions returning a date and time, date and time

Several FEEL built-in functions return a date and time, date or time result. In B-FEEL, those functions’ semantics are modified to return January 1st of year 1970 (1970-01-01T00:00:00+00:00) value (epoch) everywhere FEEL would return **null** for them.

The default values are based on the return type:

| Type          | Default Value                              |
|---------------|--------------------------------------------|
| Date and time | date and time(“1970-01-01T00:00:00+00:00”) |
| Date          | date(“1970-01-01”)                         |
| Time          | time(“00:00:00+00:00”)                     |

| Expression | FEEL | B-FEEL                 |
|------------|------|------------------------|
| time(“a”)  | null | time(“00:00:00+00:00”) |
| date(null) | null | date(“1970-01-01”)     |

## Built-in functions returning a duration

Several FEEL built-in functions return a duration result. In B-FEEL, those functions’ semantics are modified to return a duration of 0 months (years and months durations) or 0 seconds (days and time duration) everywhere FEEL would return **null** for them.

| Expression | FEEL | B-FEEL |
|------------------------|------------------------|------------------------|
| duration(“a”) | null | duration(“P0M”) |
| years and months duration(null, null) | null | duration(“P0M”) |
| days and time duration(“a”) | null | days and time duration(“P0S”) |
| years and months duration(“a”) | null | years and months duration(“P0M”) |

## Built-in functions returning a collection and expressions using a collection

Several FEEL built-in functions return collection results. In B-FEEL, those functions’ semantics are modified to return an empty collection everywhere FEEL would return **null** for them.

The *mode* function additionally ignores non-numeric parameters passed in their input list in B-FEEL.

Some specific FEEL grammar expression can reference collections that could be **null**. In B-FEEL the execution semantic is altered as follow:

- for expression (grammar [for expression](10_Expression_Language_FEEL.md#rule-for-expression)), when the iteration context is evaluated to **null**, the expression returns an empty collection.

- for quantified expression (grammar [quantified expression](10_Expression_Language_FEEL.md#rule-quantified-expression)), when one of the expression is evaluated to **null**, the expression returns **false**.

- for comparison using "in" (grammar rules 49c, 49d), when the positive unary test is evaluated to **null**, the expression returns **false**.

| Expression                       | FEEL | B-FEEL |
|----------------------------------|------|--------|
| split(“abc”, 22)                 | null | \[\]   |
| mode(\[null,null,null, 1, 1,2\]) | null | \[1\]  |
| for x in null return x           | null | \[\]   |
| some x in null satisfies x\>0    | null | \[\]   |
| 1 in null                        | null | false  |

## Built-in functions returning a range

The FEEL built-in function range() returns a range result. In B-FEEL, that function’s semantics is modified to return an empty range that does not match anything ( (0..0) ) where in FEEL it would return **null**.

| Expression | FEEL | B-FEEL          |
|------------|------|-----------------|
| range(“x”) | null | range(“(0..0)”) |

## Semantics of addition and subtraction

In B-FEEL, the semantics of addition and subtraction are modified when the types of e1 and e2 in [General semantics of addition and subtraction](10_Expression_Language_FEEL.md#table-general-semantics-of-addition-and-subtraction) do not match.

The following rules are added after the rules in [Specific semantics of addition and subtraction](10_Expression_Language_FEEL.md#table-specific-semantics-of-addition-and-subtraction) in order of precedence:

<table>
<tr><td>If type(e₁) or type(e₂) is …</td><td>e₁ + e₂ / e₁ - e₂</td></tr>
<tr><td>string</td><td>

The non-string value is converted to a string using the string B-FEEL function and [Specific semantics of addition and subtraction](10_Expression_Language_FEEL.md#table-specific-semantics-of-addition-and-subtraction) applies. Subtraction returns an empty string.

</td></tr>
<tr><td>number</td><td>

The non-number value is converted to a number using the number B-FEEL function and [Specific semantics of addition and subtraction](10_Expression_Language_FEEL.md#table-specific-semantics-of-addition-and-subtraction) applies.

</td></tr>
<tr><td>date and time</td><td>

The non-date and time value is converted to a duration using the duration B-FEEL function and [Specific semantics of addition and subtraction](10_Expression_Language_FEEL.md#table-specific-semantics-of-addition-and-subtraction) applies.

</td></tr>
<tr><td>date</td><td>

The non-date value is converted to a duration using the duration B-FEEL function and [Specific semantics of addition and subtraction](10_Expression_Language_FEEL.md#table-specific-semantics-of-addition-and-subtraction) applies.

</td></tr>
<tr><td>time</td><td>

The non-time value is converted to a duration using the duration B-FEEL function and [Specific semantics of addition and subtraction](10_Expression_Language_FEEL.md#table-specific-semantics-of-addition-and-subtraction) applies.

</td></tr>
<tr><td>years and months duration</td><td>

The non-years and months duration value is converted to a duration using the duration B-FEEL function and [Specific semantics of addition and subtraction](10_Expression_Language_FEEL.md#table-specific-semantics-of-addition-and-subtraction) applies.

</td></tr>
<tr><td>days and time duration</td><td>

The non-days and time duration value is converted to a duration using the duration B-FEEL function and [Specific semantics of addition and subtraction](10_Expression_Language_FEEL.md#table-specific-semantics-of-addition-and-subtraction) applies.

</td></tr>
</table>

| Expression             | FEEL | B-FEEL                |
|------------------------|------|-----------------------|
| "Today is " + today()  | null | "Today is 2020-01-01" |
| "The result is: " + 1  | null | "The result is: 1"    |
| 5 + " minutes"         | null | "5 minutes"           |
| "This is " + null      | null | "This is "            |
| 1 + null               | null | 1                     |
| null - 6               | null | -6                    |
| date(“2021-01-01”) + 7 | null | 7                     |
| “abc” - 2              | null | “”                    |

## Semantics of multiplication and division

In B-FEEL, the semantics of multiplication and division are modified when the types of e1 and e2 in [General semantics of multiplication and division](10_Expression_Language_FEEL.md#table-general-semantics-of-multiplication-and-division) do not match.

The following rules are added after the rules in [Specific semantics of multiplication and division](10_Expression_Language_FEEL.md#table-specific-semantics-of-multiplication-and-division) in order of precedence:

<table>
<tr><td>If type(e₁) or type(e₂) is …</td><td>e₁ * e₂ and e₁ / e₂</td></tr>
<tr><td>number</td><td>

The non-number type is converted to a number using the number B-FEEL function and [Specific semantics of multiplication and division](10_Expression_Language_FEEL.md#table-specific-semantics-of-multiplication-and-division) applies.

</td></tr>
<tr><td>years and months duration</td><td>

The non-years and months duration type is converted to a number using the number B-FEEL function and [Specific semantics of multiplication and division](10_Expression_Language_FEEL.md#table-specific-semantics-of-multiplication-and-division) applies.

</td></tr>
<tr><td>days and time duration</td><td>

The non-days and time duration type is converted to a number using the number B-FEEL function and [Specific semantics of multiplication and division](10_Expression_Language_FEEL.md#table-specific-semantics-of-multiplication-and-division) applies.

</td></tr>
</table>

| Expression              | FEEL | B-FEEL          |
|-------------------------|------|-----------------|
| 22 \* “a”               | null | 0               |
| null / 22               | null | 0               |
| duration(“P1Y”) \* null | null | duration(“P0M”) |

## Semantics of exponentiation

The FEEL semantics of exponentiation described in [Semantics of exponentiation](10_Expression_Language_FEEL.md#table-semantics-of-exponentiation) (grammar [exponentiation](10_Expression_Language_FEEL.md#rule-exponentiation)) are used and B-FEEL further specifies that each operand is converted to a number using the number B-FEEL function.
