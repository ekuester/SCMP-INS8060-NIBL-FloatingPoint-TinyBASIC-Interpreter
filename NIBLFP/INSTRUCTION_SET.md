NIBLFP (Floating Point NIBL)
----------------------------

Instruction set
---------------

Constant
--------
```
    PI (3.14159)
```
Variables
---------

 Variable names have to start with A-Z and range between 1E-39 and 1E38. When entering or in statements the numbers can be written in normal (e.g. 12.34) or in exponential representation (e.g. 1234.56E-12). Numbers that are larger than 8,388,607 (2 to the power of 23 -1), however, must *always* be written in exponential representation. In general calculations are done with an accuracy of at most 6 significant digits.<br>
 String variable names end with a $ e.g. `TEXT$`. The user has to supply the starting address of the string in the coresponding variable TEXT.<br>
 Only one dimensional arrays are possible. The number of elements in the array must be specified in a DIM statement. The user has to supply the starting address of the array within memory in the coresponding variable. An array occupies 6 bytes for organization and 4 bytes per element. So for an array with 12 elements a space of 54 bytes must be allocated.
```
   10 FELD = #4100: DIM FELD(12): FELD(9) = 128: PR FELD(1), FELD(9)
```
Expressions
-----------
    FREE returns the number of bytes left in the page
    PAGE returns the current page number
    RND returns a random number between 0 and 1
    STAT returns the value of the INS8060 Status Register
    TOP returns the highest address of the BASIC program in the current page 

Program entry
-------------
    AUTO n generate line numbers starting at number n (ctrl c to quit)
    AUTO n,m
      generate line numbers starting at n with increment m (ctrl c to quit)
    BYE (quit floating point basic, return to calling program)
    EDIT n
      allows editing of line n. Characters may be inserted with ctrl Q,<br>
      deleted with ctrl X, ctrl C will exit

    LINK #C000 (link to user routine at hex C000)
    LIST
    LIST n (show line n)
    LIST n-m (show line from n until m)
    NEW (clear BASIC program, set PAGE to 1)
    NEW n (clear BASIC program, set PAGE to n)

Declaration Statements
----------------------
    CLEAR (clears all stacks)
    DATA
    DEF FN
    DIM
    LET 

DEF FN must be followed by a character A-Z, so 26 user defined functions are possible. An expression between brackets can be added to transfer a parameter.<br>
e.g.:
```
 >LIST
  2 PRINT"SQUARE ROOT OF A"
  10 DEF FNA (ROOT) = SQR(ROOT): INPUT A: PRINT FNA(A)
  18 PRINT"SINUS CALCULATION"
  20 DEF FNB(X) = SIN(X)+1: INPUT"ANGLE IN RADIANS" S: PRINT FNB(S)
  READY
 >RUN
 SQUARE ROOT OF A
 A? 2
  1.41421
 SINUS CALCULATION
 ANGLE IN RADIANS? 0.78539
  1.7071
  READY AT 20
```

Program Flow Control
--------------------
    DO / UNTIL
    END
    FOR / NEXT / STEP
    GOTO
    GOSUB / RETURN
    ON ... GOSUB / GOTO
    IF ... THEN ...: ELSE
    IF ... THEN n: ELSE (n is line number as jump target)
    IF ...: ELSE
    READ
    RESTORE
    RESTORE n 


Numeric functions
-----------------
As mentioned above floating point numbers have to be between 10E-39 and 10E38, maximal nesting of 5 brackets is allowed and numbers larger than 8.388.607 have to be entered in exponential form. Normal accuracy for calculation is 6 digits (a floating point number is stored in 32 bits, 8 bits for exponent and 24 bits for mantissa, so overall 4 bytes are occupied per number).<br>
**CAVEAT:** Annoying rounding errors are possible, especially when using calculations in string functions.

    + - / * ** ^
    DIV
    MOD
    ABS
    SQR
    ATN
    SIN
    COS
    TAN
    INT
    LB logarithm on base 2
    LG logarithm on base 10
    LN logaritm on e
    EXP
    SGN 

Logical Operators
-----------------
    AND
    EXOR
    NOT
    OR 

Relational Operators
--------------------
```
    =
    <>
    >=
    <=
    >
    < 
```

String Functions
----------------
```
    ASC
    LEN
    VAL
    CHR$
    LEFT$
    MID$
    RIGHT$
    STR$ 
```
String Concatenation with & (ampersand)
e.g.
```
 > 10 VAR = TOP: VAR1 = TOP + 72: VAR1$ = "123456" 
 > 20 VAR$ = RIGHT$(VAR1$,2)&CHR$(65)&"LT"&MID$(VAR1$,2,3) 
 > 30 PRINT VAR$
 > RUN 
 56ALT234

```

String Comparison
-----------------
    IF var$ = "string" ...
    IF var1$ = var2$ ... 

Input/Output
------------
    CLOAD
    CSAVE
    INPUT "string" ...
    INPUT ...
    PRINT, PRINT USING
    PR, PR USING
```
 > PR USING "####,##" 12.3, 12.34, PI
    12,30  12,34   3,14
```
    TAB(x)
    SPC(x)
    VERT(x)
    VERT(-x)
    PEEK
    POKE
    #DFC1 (# marks hexadecimal number)
```
 > POKE #1001,13: REM write 13 to storage address
 > PR PEEK(#1001): REM read storage address
```

**Attention:** The PRINT USING statement uses as separator the decimal comma (standard in continental Europe)
