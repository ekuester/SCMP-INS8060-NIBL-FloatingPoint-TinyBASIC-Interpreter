### TinyBASIC Interpreter with floating point extension

### Explanation to the **I**nterpretative **L**anguage
------------------------------------------------------

In principle, the interpretative language is a sequence of subprogram calls, consisting of the high byte and the low byte of the address from which the subprogram is in memory. Furthermore, there is the possibility to execute conditional and unconditional jumps and subprograms written in I.L. The highest four bits of the address high byte are taken as flags to determine what is to do. Actually the I.L. can only reside on page D.

Commands:

`DO      high byte of address 111x xxxx `
-    Execute a subroutine starting at the given address.
    Subroutines can only be on page E or F and are finished with '93D6', '9326' or '3F00'.

`TSTNUM  high byte of address 1101 xxxx `
-    The line buffer is tested for presence of a number.
    If this is the case the next command is processed, otherwise
    the execution of the I.L. commands is continued at the specified address.

`TSTVAR  high byte of address 1011 xxxx `
 -   The line buffer is tested for presence of a character. If this character is a letter, the next command is processed, otherwise the execution of the I.L. commands are continued at address with high byte 1101 xxxx ...

`TSTSTR  high byte of address 1001 xxxx `
 -   The line buffer is tested for a character matching the character following the TSTSTR command.`

`GOTO    high byte address 0101 xxxx`
-    The I.L. commands are processed from address with high byte 1101 xxxx onwards.

`ILCALL  high byte of address 0001 xxxx `
-    Will call a subroutines in I.L. Such subroutines are terminated with a zero byte 00.

`END     one-byte command 0000 0000 `
-    see ILCALL

Furthermore, subprograms are called within machine programs by the command 'XPPC P3' followed by the address to be jumped to (order is high byte - low byte). So the command sequence '3F D500' would be understood as CALL P3,PUTASC (that's the routine that transmits an ASCII character to the screen). These subprograms are exited with '9326' or '3F00' (mnemonic RTRN,P3).

