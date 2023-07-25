### Monitor program (year of origin around 1982)

### A. Explanation to the listing

1 The monitor program works with a kind of "Interpretative Language" as it is also used in the NIBL dialects. In this version, the first two bits of the "high byte" of the address are used to decode certain routines.
Because of this, the monitor program can only run on pages C, D, E, F without major changes. In principle by changing the code area from hex C03E to C05A, however, it is possible to move the monitor to either side.

Commands:

`DO      high byte of address 11xx xxxx `
-    Execute a subroutine starting at the given address.
    Subroutines must end with hex 3F00 ==> RTRN P3.

Example: `C580 DO GETASC` -> executes routine at hex C580 (read character from keyboard)

`TSTSTR  high byte of address 10xx xxxx `
 -   tests a character read from the keyboard via GETASC against the string following the TSTSTR command. If there is a match with the first character in the text string, the string is shown and the next following command is processed. Otherwise, the program continues to be processed at the point specified by the command.

Example:</br>
```
         80E8 TSTSTR LIST
         474F54CF "GOTO"
```
If the character read in is a G, GOTO is printed on the screen, if not, the next command is interpreted at the position hex C0C8.

`GOTO    high byte of address 01xx xxxx `
-    The I.L. commands are processed from address with high byte 01xx xxxx onwards.

`END     one-byte command 000 0000 `
-    Subsequent commands are interpreted as a machine program; if hex 3F00 is found, the program jumps into the command loop.

2 Within a machine program, subprograms can be called with 3F ABCD ==> CALL P3,ABCD, where ABCD is the address of the subprogram. The return to the calling program also is done by hex 3F00 ==> RTRN P3.
In this way writing on the screen with full cursor control is possible with the following simple program:
```
    0C00 3FC580 LOOP: CALL GETASC
    0C03 3FC700       CALL PUTASC
    0C06 90F8         JMP LOOP
```

3 To store data, the monitor program requires at least 1/2k RAM in any page, with pointer 2 of the SC/MP being loaded as a RAM pointer. In this version, this is an area from hex 0E00 to 0FFF and pointer 2 must be loaded with 0F80 (see program addresses hex C002 to C008).

4 To move the monitor to another page, all DO, TSTSTR, GOTO and CALL commands must be changed. Furthermore, pointer 3 must be loaded with hex x080, where x is the page number (see program addresses hex C00F to C011).

### B. Commands

1 The monitor is activated by setting the program counter of the SC/MP to hex C000 (using ELBUG with RUN C000 or in NIBL with LINK C000 cr). The monitor responds
```
 MONITOR
* _
```
and expects one-character commands from the keyboard:</br>
 ( B=BLOCK TRANSFER, C=CASSETTE, D=DISASSEMBLE, G=GOTO, I=INTERPRETER , L=LIST, M=MODIFY and P=PROGRAM )</br>
? always means readiness to accept a hexadecimal number with 1 to 4 digits. Input is terminated with cr (ASCII OD), except after entering four hex characters, where cr is automatically set, thus allowing continuous input with the MODIFY command. Each entry can be interrupted with Control C (ASCII 03), whereby a BREAK message is sent to the screen and the program returns into the command loop.

