### TinyBASIC Interpreter (Elektor Magazine 1979)

### Explanation to the **I**nterpretative **L**anguage
------------------------------------------------------ 

In principle, the interpretative language is a sequence of subprogram calls, consisting of the high byte and the low byte of the address from which the subprogram is in memory. Furthermore, there is the possibility to execute conditional and unconditional jumps and subprograms written in I.L. The highest three bits of the address high byte are taken as flags to determine what is to do. Actually this NIBLE I.L. can only reside on page 1.

Commands:

`DO      high byte of address 0001 xxxx `
-    Execute a subroutine starting at the given address minus one.

`TSTN    high and low byte of address 0001 0110 1010 1011 `
-    Special case of DO : execute routine TSTNUM at address plus 1, the line buffer is tested for presence of a number. If this fails the following command is processed.

`TSTV    high and low byte of address 0001 0100 1110 0000`
-    Special case of DO : execute routine TSTVAR at address plus 1, the line buffer is tested for presence of a letter. If this fails the next command is processed.

`TSTCR   command 1010 xxxx xxxx xxxx 1000 1101  `
 -   The line buffer is tested for control character '0x0D' (carriage return).

`TSTR    high byte of address 0010 xxxx `
 -   The line buffer is tested for a string matching the string following the TSTR command. The following string is terminated with set bit 7 of last byte.

JUMP    high byte address 0100 xxxx`
-    The I.L. commands are processed from address with high byte 0001 xxxx onwards.

`CALL    high byte of address 1000 xxxx `
-    Will call a subroutines in I.L. at address with high byte 0001 xxxx. Such subroutines are terminated with a 'JS P3' macro.

Furthermore, subprograms are called within machine programs by the macro 'JS' followed by the address minus one to be jumped to (order is high byte - low byte).

