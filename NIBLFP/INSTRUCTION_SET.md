## NIBLFP

### Instruction set

Constant
--------
    PI (3.14159)
Variables
---------
    Variable names have to start with A-Z and range between 1E-39 and 1E38.
    String variable names end with a $ e.g. TEXT$. The user has to supply the starting address of the string in the coresponding variable TEXT.
    Only one dimensional arrays are possible. The number of elements in the array must be specified in a DIM statement. The user has to supply the starting address of the array in the memory in the coresponding variable.
    e.g. 'FELD = #4100: DIM FELD(20): FELD(9) = 128: PR FELD(0), FELD(9)'

Expressions
-----------
    FREE returns the number of bytes left in the page
    PAGE returns the current page number
    RND returns a random number between 0 and 1
    STAT returns the value of the INS8060 Status Register
    TOP returns the highest address of the NIBL program in the current page 

Program entry
-------------
    AUTO n generates line numbers starting at number n (ctrl c to quit)
    AUTO n,m generates line numbers starting at n with increment m (ctrl c to quit)
    BYE quit floating point basic
    EDIT n
    allows editing of line n. Characters may be inserted with cntrl Q and deleted with cntrl X, cntrl C will exit EDIT
    LINK x (link to user routine at hex x)
    LIST
    LIST n
    LIST n-m
    NEW
    NEW x
 
Declaration Statements
----------------------
    CLEAR clears all variables and stacks
    DATA
    DEF FN
    DIM
    LET 

DEF FN must be followed by a character A-Z, so 26 user defined functions are possible. An expression between brackets can be added to transfer a parameter.  
e.g.:  
``` DEF FNA (SQROOT) = SQR(SQROOT): INPUT A PRINT FNA(A): REM prints square root of A
    DEF FNB = SIN(X)+1: INPUT X: PRINT FNB ```

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
Floating point numbers have to be between 10E-39 and 10E38, maximal nesting of 5 brackets, numbers larger than 8.388.607 have to be entered in exponential form and normal accuracy for calculation is 6 digits (a floating point number is stored in 32 bits).

    + - / * **
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
    =
    <>
    >=
    <=
    >
    < 

String Functions
----------------
    ASC
    LEN
    VAL
    CHR$
    LEFT$
    MID$
    RIGHT$
    STR$ 

String Concatenation with & (ampersand)  
e.g.  
```    VAR = TOP: VAR1 = TOP + 72 VAR1$ = "123456": VAR$ = RIGHT$(VAR1$,2)&CHR$(65)&"LT"&MID$(VAR1$,2,3): PRINT VAR$ ```

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
    TAB(x)
    SPC(x)
    VERT(x)
    VERT(-x)
    PEEK
    POKE
    #DFC1 (hexadecimal number)

