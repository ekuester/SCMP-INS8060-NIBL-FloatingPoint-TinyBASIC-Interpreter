### Floating Point Routines for the 6502

by Roy Rankin, Department of Mechanical Engineering,</br>
Stanford University, Stanford, CA 94305</br>
(415) 497-1822</br>
and</br>
Steve Wozniak, Apple Computer Company</br>
770 Welch Road, Suite 154</br>
Palo Alto, CA 94304</br>
(415) 326-4248</br>

#### Editor’s Note:

Although these routines are for the 6502, it would appear that one could generate equivalent routines for most of the “traditional” microprocessors, relatively easily, by following the flow of the algorithms given in the excellent comments included in the program listing. This is particularly true of the transcendental functions which were directly modeled after well-known and proven algorithms, and for which, the comments are relatively machine-independent.

These floating point routines allow 6502 users to perform most of the more popular and desired floating point and transcendental functions, namely:
```
Natural Log - LOG
Common Log - LOG10
Exponential - EXP
Floating Add - FADD
Floating Subtract - FSUB
Floating Multiply - FMUL
Floating Divide - FDIV
Convert Floating to Fixed - FIX
Convert Fixed to Floating - FLOAT
```
They presume a four-byte floating point operand consisting of a one-byte exponent ranging from -218 through +127, and a 24-bit two’s complement mantissa between 1.0 and 2.0.

The floating point routines were done by Steve Wozniak, one of the principals in Apple Computer Company.

The transcendental functions were patterned after those offered by Hewlett-Packard for their HP2100 minicomputer (with some modifications), and were done by Roy Rankin, a Ph.D. student at Stanford University.

There are three error traps; two for overflow, and one for prohibited logarithm argument.</br>
`ERROR (1DO6)` is the error exit used in event of a non-positive log argument.</br>
`OVFLW (1E3B)` is the error exit for overflow occuring during calculation of e to some power.</br>
`OVFL (1FE4)` is the error exit for overflow in all of the floating point routines.</br>
There is no trap for underflow; in such cases, the result is set to 0.0.

All routines are called and exited in a uniform manner:</br>
The argument(s) are placed in the specified floating point storage locations (for specifics, see documentation preceeding each routine in the listing), then a JSR is used to enter the desired routine. Upon normal completion, the called routine is exited via a subroutine return instruction (RTS).

Note:</br>
The preceeding documentation was written by the Editor, based on phone conversations with Roy and studying the listing. There is a high probability that it is correct. However, since it was not written nor reviewed by the authors of these routines, the preceeding documentation may contain errors in concept or in detail.
JCW, Jr.</br>
August, 1976 Dr. Dobb’s Journal of Computer Calisthenics & Orthodontia, Box 310, Menlo Park CA 94025</br>
pages 207 - 209</br>

Note by Erich Kuester 2023:</br>
The original listings were scanned and OCR'd, then prepared for feeding into Alfred Arnold's macro assembler. I added constant PI, besides that the binary code is unaltered compared to the original one.</br>
My floating point routines for the SC/MP base on this excellent work.
