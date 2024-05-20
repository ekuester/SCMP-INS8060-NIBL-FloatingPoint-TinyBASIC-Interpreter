;
; NATIONAL INDUSTRIAL BASIC LANGUAGE, EXTENDED, WITH FLOATING POINT
;
; Originally written by Erich Küster during the late 1970s.
; Revived from old hex-dump listings in 2023. Many of the original
; intentions were lost, but slowly they are being reverse-engineered
; and documented.
;
; This code, as does all code that uses Interpretative Language,
; relies heavily on the use of macros, and, more to the point, on
; macros that support variable arguments. Currently, the assembler
; chosen to re-develop the project is ASL, written by Alfred Arnold,
; which can be found at https://john.ccac.rwth-aachen.de:8000/as/
;
; Started in May 8, 2023 by Erich, later that year increased effort
; put by Fred N. van Kempen to demystify the code, and to attempt to
; get a more or less cleaned up version ready for inclusion with his
; own VARCem projects. Many of the changes were developed with Erich,
; and many changes will find their way back into the "official"
; repository of this code, which, incidentally, can be found at:
;
;  https://github.com/ekuester/SCMP-INS8060-NIBL-FloatingPoint-TinyBASIC-Interpreter
;
; PLEASE NOTE that this code was rewritten to be more clear (and less
; dangerous) than the original, which used a number of smart tricks to
; save space, but which were also very dangerous for structure. So, at
; the expense of making the code a few bytes bigger, it is not as scary
; anymore!  That said.. amazing how Erich was able to write this WITHOUT
; the assistance of an assembler!!  His original (but updated) code will
; show you where these "danger zones" were, how they worked, and why
; they were there to begin with.
;
; AUTHORS:	National Semiconductor, NIBL, 1975
;		Erich Küster (ekuester), rewrite and FP, late 1970's-2024
;		Fred N. van Kempen (waltje), cleanup-rewrite, 2023,2024
;		
;		Redistribution and  use  in source  and binary forms, with
;		or  without modification, are permitted  provided that the
;		following conditions are met:
;	
;		1. Redistributions of  source  code must retain the entire
;		   above notice, this list of conditions and the following
;		   disclaimer.
;	
;		2. Redistributions in binary form must reproduce the above
;		   copyright  notice,  this list  of  conditions  and  the
;		   following disclaimer in  the documentation and/or other
;		   materials provided with the distribution.
;	
;		3. Neither the  name of the copyright holder nor the names
;		   of  its  contributors may be used to endorse or promote
;		   products  derived from  this  software without specific
;		   prior written permission.
;	
; THIS SOFTWARE  IS  PROVIDED BY THE  COPYRIGHT  HOLDERS AND CONTRIBUTORS
; "AS IS" AND  ANY EXPRESS  OR  IMPLIED  WARRANTIES,  INCLUDING, BUT  NOT
; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
; PARTICULAR PURPOSE  ARE  DISCLAIMED. IN  NO  EVENT  SHALL THE COPYRIGHT
; HOLDER OR  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
; SPECIAL,  EXEMPLARY,  OR  CONSEQUENTIAL  DAMAGES  (INCLUDING,  BUT  NOT
; LIMITED TO, PROCUREMENT OF SUBSTITUTE  GOODS OR SERVICES;  LOSS OF USE,
; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED  AND ON  ANY
; THEORY OF  LIABILITY, WHETHER IN  CONTRACT, STRICT  LIABILITY, OR  TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING  IN ANY  WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
; last update:	2024/04/15
;
; >>>>>>>>>>>>>>>>>>>           WORK IN PROGRESS           <<<<<<<<<<<<<<<<<
;
; TODO: 	Correct severe issue from those days (nowadays detected):
;		 PR -64/-16 gives SNTX ERROR, PR -64/(-16) gives correct result.
;		 In general plus or minus sign after an operator gives error.
;		Implement the dynamic RAM scan at startup, to get rid of
;		 the static RAMBASE definition.
;		Complete editing commands in GETLIN.
;		Implement key BACKSPACE = 0x7f in GETLIN.
;		Merge STREXP and REXP in I.L. table into a single "EXPR"
;		 function.
;		For CLOAD, detect if no cassette present and print error.
;
;
;******************************************************
;*     WE ARE TIED DOWN TO A LANGUAGE WHICH           *
;*     MAKES UP IN OBSCURITY WHAT IT LACKS            *
;*     IN STYLE.                                      *
;*                      - TOM STOPPARD                *
;*     CONFIRMED                                      *
;*                      - ERICH KUESTER               *
;*     NO KIDDING!                                    *
;*                      - FRED VAN KEMPEN             *
;******************************************************

; Functions.
L FUNCTION VAL16, (VAL16 & 0xFF)
H FUNCTION VAL16, ((VAL16 >> 8) & 0xFF)

; Do we want the cassette I/O routines?
	IFNDEF USE_CASS
USE_CASS = 2				; 1=normal,2=full,0=disabled
	ENDIF

; Opcodes used for I/O emulation.
	IFDEF EMULA
WRCHAR	= 0x20				; write char to TTY
RDCHAR	= 0x21				; read char from TTY
	MESSAGE	"Will generate emulation code."
	ENDIF

; Define KBPLUS to use system calls to KBPLUS monitor.
        IFDEF KBPLUS
GETC	= 0x00DE			; KBPLUS system call
PUTC	= 0x01C5			; KBPLUS system call
PUTS	= 0x0052			; KBPLUS system call
CASLD	= 0x0200			; KBPLUS system call
CASSV	= 0x0280			; KBPLUS system call
	MESSAGE	"Will generate for KBPLUS integration."
	ENDIF

; Set desired load address (3x4096 bytes.)
	IFNDEF BASE
BASE	= 0xD000
	ENDIF

; Set desired ram base address.
; Contiguous memory is assumed from 0x1000 through RAMBASE+0x0FFF.
	IFNDEF RAMBASE
RAMBASE	= 0x7000			; set page of RAM to use for scratch
	ENDIF
STKTOP	= 0x0C00			; offset into page (1K below top)
STKBASE	= RAMBASE+STKTOP		; this is the base of our scratch RAM
STKMID	= 0x0080			; center of RAM stack (for P2 offset)
STKIBUF	= 0x03B6			; input buffer offset from STKBASE
VARSBUF	= 0x0100			; start of vars (offset from STKBASE)

RAMSTK	= 0x00F6			; offset for syscalls stack

; NOTE:	following are six internal stack offsets relative to STKBASE
SUBSTK	= 0x001E			; offset for CALL/RTRN stack
AEXSTK	= 0x0060			; offset for arithmetic expression stack
SBRSTK	= 0x00F0			; offset for GOSUB/RETURN stack
; FIXME: SBRSTK was 0xFD, changed for RAMSTK
DOSTAK	= SBRSTK-16			; offset for DO/UNTIL stack
FORSTK	= DOSTAK-12			; offset for FOR/NEXT stack
ILCSTK	= FORSTK-48			; offset for ILCALL/ILRTRN stack

; NOTE: Input buffer for GETLIN begins at STKBASE+STKIBUF,
;	ends at STKBASE+STKIBUF+72 ( holds maximum 72 chars )

; RAM usage constants relative to P2 (work in progress.)
; Shown offsets are with P2 assumed to be at STKBASE+STKMID.
; -127	PUTASC:char			; temp storage for character
MSGOFF	= -126				; relative offset (E) in MESG
RAMBAS	= -125				; base address of RAM, high byte
PAGES	= -124				; number of valid pages for program
PGTOPH	= -123				; top of storage in page (H) / memory size (H)
PGTOPL	= -122				; top of storage in page (L) / memory size (L)

; -100	SUBSTK:init.H			; grows downwards, contains SPRVSR P3.H,
; -99	SUBSTK:init.L	
; -98	SUBSTK:top.H			; set to zero byte
; -97	SUBSTK:top.L			; set to zero byte
; -96	CASS routines
; -95	CASS routines
; -94	CASS routines
; -32	AEXSTK:top			; STBASE+AEXSTK (grows downwards)
UFRACS	= -31				; counter for '#'s behind ',' (USING routines)
UTOTAL	= -30				; total counter for '#'s (USING routines)
; NOTE:	next used to store actual SUBSTACK.L
SUBOFF	= -29				; P2 STACK (L), for CALL/RTRN, init STKBASE+SUBSTK (0x1E)
RNDY	= -28
RNDX	= -27				; seeds for random number
RNDF	= -26
CHRNUM	= -25				; char counter within line buffer, init 72 chars, also pointer.H
; -24	PUTASC:bitcount			; also pointer.L
; -23	PUTASC, ABSWP, ALGEXP, PSHSWP	; temporary counter
; -22	CASW, GETLIN, FADD		; temporary storage
COUNTR	= -21				; CASS routines, GETASC, USING routines
; -20	unknown				; P1.H : begin of actual program line
; -19	unknown				; P1.L
; -18	unknown
; -17	unknown
P1HIGH	= -16				; P1 SPACE (H); P3 CASW (H), CASR (H)
P1LOW	= -15				; P1 SPACE (L) to save cursor
; -14					; save P1.H
; -13					; save P1.L
; -12	unknown
; -11	unknown
CURPG	= -10				; current page number
NUMHI	= -9				; 16-bit number (H)
NUMLO	= -8				; 16-bit number (L)
ILCOFF	= -7				; P2 STACK (L), for ILCALL/ILRTRN, init STKBASE+ILCSTK (was 0xB1)
FOROFF	= -6				; P2 STACK (L), for FOR/NEXT/STEP STACK, init STKBASE+FORSTK (was 0xE1)
DOUOFF	= -5				; P2 STACK (L), for DO/UNTIL STACK, init STKBASE+DOSTAK (was 0xED)
SBROFF	= -4				; P2 STACK (L), for GOSUB/RETURN, init STKBASE+SBRSTK (was 0xFD)
AEXOFF	= -3				; P2 STACK (L), for arithmetics, init STKBASE+AEXSTK (0x60)
; -2	known				; general temp storage (H), init ILTBL.H
; -1	known				; general temp storage (L), init ILTBL.L
; 0	known				; character limit in line buffer (72)
; 1	unknown
; 2	unknown
; 3	unknown
; 4	unknown
; 5	unknown
; 6	unknown
; 7	unknown
; 8	unknown
; 12	unknown
; 13	unknown
; 30	SUBSTK.top (from STKBASE on, not STKBASE+STKMID)
; 42	ILCSTK.top (grows downwards)
; 90	FORSTK.top (grows downwards)
; 102	DOSTAK.top (grows downwards)
; 118	SBRSTK.top (grows downwards)
	; NOTE:	Downwards offset 119 begin six internal stacks, see above
; 119	STKP3.H	= 119			; KBPLUS
; 120	STKP3.L	= 120			; KBPLUS
; 121	STKP1.H	= 121			; KBPLUS
; 122	STKP1.L	= 122			; KBPLUS
; 123	STKP2.H	= 123			; KBPLUS
; 124	STKP2.L	= 124			; KBPLUS
ERRNUMH	= 125				; line number (H) for error message
ERRNUML = 126				; line number (L) for error message
BASMODE	= 127				; program/run mode INCMD with _QUMRK

; System constants.
EREG	= -128				; the extension register

; Misc constants.
_CTLC	= 0x03				; ctrl-c (BREAK)
_BS	= 0x08				; ctrl-h (backspace)
_HTAB	= 0x09				; (hor.) TAB
_LF	= 0x0A				; ctrl-j (line feed)
_CTLK	= 0x0B				; ctrl-k (^Kill, rubout one char, also used as <vtab>)
_CTLL	= 0x0C				; ctrl-l (one char to the ^Left, also used as <ff>)
_FF	= 0x0C				; form feed (clear screen)
_CR	= 0x0D				; ctrl-m (carriage return / enter)
_CTLO	= 0x0F				; ctrl-o (m^Ove and insert character)
_CTLR	= 0x12				; ctrl-r (one char to the ^Right)
_CTLX	= 0x18				; ctrl-x (e^Xit, cancel input and start anew)
_PRMPT	= '>'				; the prompt
_QMARK	= '?'				; question mark (for input)
INCMD	= 0x80				; "in command mode" flag

	IFDEF USETTY
; Select desired baud rate or 0 for original default.
	IFNDEF BAUD
BAUD	= 1200
	ENDIF
	IF BAUD == 0
TTY_B1	= 0xC2
TTY_B2	= 0x00
TTY_B3	= 0x76
TTY_B4	= 0x01
TTY_B5	= 0x01
TTY_B6	= 0x30
TTY_B7	= 0x03
TTY_B8	= 0x5C
TTY_B9	= 0x01
	ENDIF
	IF BAUD == 110
TTY_B1	= 0x57
TTY_B2	= 0x04
TTY_B3	= 0x7E
TTY_B4	= 0x08
TTY_B5	= 0x08
TTY_B6	= 0xFF
TTY_B7	= 0x17
TTY_B8	= 0x8A
TTY_B9	= 0x08
	ENDIF
	IF BAUD == 300
TTY_B1	= 0x76
TTY_B2	= 0x01
TTY_B3	= 0xE5
TTY_B4	= 0x02
TTY_B5	= 0x06
TTY_B6	= 0x64
TTY_B7	= 0x06
TTY_B8	= 0xF0
TTY_B9	= 0x02
	ENDIF
	IF BAUD == 600
TTY_B1	= 0xA7
TTY_B2	= 0x00
TTY_B3	= 0x45
TTY_B4	= 0x01
TTY_B5	= 0x04
TTY_B6	= 0x25
TTY_B7	= 0x03
TTY_B8	= 0x50
TTY_B9	= 0x01
	ENDIF
	IF BAUD == 1200
TTY_B1	= 0x3D
TTY_B2	= 0x00
TTY_B3	= 0x76
TTY_B4	= 0x00
TTY_B5	= 0x02
TTY_B6	= 0x86
TTY_B7	= 0x01
TTY_B8	= 0x81
TTY_B9	= 0x00
	ENDIF
	IF BAUD == 2400
TTY_B1	= 0xBB
TTY_B2	= 0x00
TTY_B3	= 0x34
TTY_B4	= 0x01
TTY_B5	= 0x01
TTY_B6	= 0x99
TTY_B7	= 0x01
TTY_B8	= 0x44
TTY_B9	= 0x01
	ENDIF
	ENDIF

; Important bits.
S_FLAG0	= 0x01				; tty "txd" pin in SR
S_SENSEA = 0x10				; intr pin in SR
S_SENSEB = 0x20				; tty "rxd" pin in SR

; Supervisor jumps using P3 offsetting.
SV_BASE		= BASE+0x0400		; which block is Supervisor at?
STKPHI		= (RESTRT -SPRVSR +1)	; storage for stackpointer high
SV_RESTRT	= (RESTRT -SPRVSR -1)
SV_MSGOUT	= (MSGOUT -SPRVSR -1)
SV_SPLOAD	= (SPLOAD -SPRVSR -1)
SV_RTNEST	= (RTNEST -SPRVSR -1)
SV_RTERRN	= (RTERRN -SPRVSR -1)
SV_LINE		= (SPLINE -SPRVSR -1)
SV_RTRN		= (SPRTN -SPRVSR -1)
SV_RTRN1	= (SPRTN1 -SPRVSR -1)
SV_RTFUNC	= (RTFUNC -SPRVSR -1)
SV_VALERR	= (VALERR -SPRVSR -1)

; I.L. control bits for Supervisor.
JMPBIT		= 0x80
JMPBITH		= JMPBIT*256
TSTBIT		= 0x40
TSTBITH		= TSTBIT*256
CALBIT		= 0x20
CALBITH		= CALBIT*256


; Macros.
JS	MACRO P,VAL			; Jump to Subroutine
	 LDI	H(VAL-1)
	 XPAH	P
	 LDI	L(VAL-1)
	 XPAL	P
	 XPPC	P
	ENDM

LDPI	MACRO P,VAL			; Load Pointer
	 LDI	L(VAL)
	 XPAL	P
	 LDI	H(VAL)
	 XPAH	P
	ENDM

	IFDEF	KBPLUS
SYSCALL	MACRO NUM			; perform kbplus system call
	 XPPC	P3
	 DB	NUM
	ENDM
	ENDIF

	IFDEF	INTERNAL
SYSCALL	MACRO NUM			; perform internal system call
	 XPPC	P3
	 DB	NUM
	ENDM
	ENDIF

TSTSTR	MACRO FAIL,A			; I.L. macro
	 DB	H(FAIL - TSTBITH)
	 DB	L(FAIL)
	 DB	A
	ENDM

TSTNUM	MACRO FAIL			; I.L. macro
	 DB	H(FAIL)
	 DB	L(FAIL)
	ENDM

TSTVAR	MACRO ADR			; I.L. macro
	 DB	H(ADR - CALBITH)
	 DB	L(ADR)
	ENDM

GOTO	MACRO ADR			; I.L. go to I.L. subroutine
	 DB	H(ADR - JMPBITH)
	 DB	L(ADR)
	ENDM

ILCALL	MACRO ADR			; I.L. call I.L. subroutine
	 DB	H(ADR - (JMPBITH + TSTBITH))
	 DB	L(ADR)
	ENDM

ILRTRN	MACRO				; I.L. return from I.L. subroutine
	 DB	0
	ENDM

DO	MACRO ADR			; I.L. - execute machine code
	 IFNB	ADR
	  DB	H(ADR)
	  DB	L(ADR)
	  SHIFT
	  DO	ALLARGS
	 ENDIF
	ENDM

CALL	MACRO ADR			; I.L. - call subroutine
	 XPPC	P3
	 DB	H(ADR)
	 DB	L(ADR)
	ENDM

RTRN	MACRO				; I.L. - return from subroutine
	 XPPC	P3
	 DB	0
	ENDM

MESG	MACRO A,B			; I.L. - create message string
	 DB	A
	 IFNB	B
	  DB	B|0x80
	 ENDIF
	ENDM

MESGCR	MACRO A				; message string terminated by <cr>
	 DB	A
	 DB	_CR
	ENDM

TOKEN	MACRO A,B,C			; I.L. - create token table entry
	 IF A == 0x80|79
	  ; Convert a T_STAR to the more common '^' symbol.
	  ; NOTE: if a token is added or deleted, DO NOT forget to update this!
	  DB	'^'
	 ELSE
	  DB	A
	 ENDIF
	 DB	B
	 DB	C|0x80
	ENDM


;**************************************
;*      NIBLFP - Initialization       *
;**************************************
	ORG	BASE
RESET:	NOP				; dummy byte
	JMP	ENTER
VERMSG:	DB	_CR,"NIBLFP VERSION "
VERSTR:	MESGCR	"2024/04/06"		; version ID

	IFDEF	KBPLUS
; Vectors for KBPLUS system calls
	BIGENDIAN ON
SCALLS:	DW	GETC			; call 1
	DW	PUTC			; call 2
	DW	PUTS			; call 3
	DW	CASLD			; call 4
	DW	CASSV			; call 5
	ENDIF

; Define input/output internally over lookup table
	IFDEF INTERNAL
	BIGENDIAN ON
SCALLS:	DW	GETASC			; call 1
	DW	PUTASC			; call 2
	MESSAGE	"Will generate internal system calls."
        ENDIF

	; On entry, we save the initial values of the P1, P2 and P3
	; registers of any potential calling program, for example a
	; system monitor.
	;
ENTER:	LDI	H(STKBASE)		; set P1 to variables
	ORI	H(VARSBUF)
	XPAH	P1			; get high byte of monitor P1
	XAE				; save prev P1.H in E
	LDI	0
	XPAL	P1			; get low byte of monitor P1
	ST	-6(P1)			; store byte at STKP1.L
	LDE
	ST	-7(P1)			; store byte at STKP1.H
	LDI	0
	ST	(P1)			; clear first byte of variables' buffer
	LDI	STKMID			; set P2 to STBASE+STKMID
	XPAL	P2			; get low byte of monitor P2
	ST	-4(P1)			; store byte at STKP2.L
	LDI	H(STKBASE)
	XPAH	P2			; get high byte of monitor P2
	ST	-5(P1)			; store byte at STKP2.H
	LDI	L(SPRVSR)		; load P3 with supervisor
	XPAL	P3			; get low of return address
	ST	-8(P1)			; store byte at STKP3.L
	LDI	H(SPRVSR)
	XPAH	P3			; get high of return address
	ST	-9(P1)			; store byte at STKP3.H
	LD	@1(P1)			; load zero value and advance P1 by one
	ST	-98(P2)			; clear two bytes at top of SUBSTACK
	ST	-97(P2)
	LDI	L(SUBSTK)
	ST	SUBOFF(P2)		; store default top of CALL/RTRN stack
	LDI	L(AEXSTK)		; initialize working stack
	ST	AEXOFF(P2)		; store default offset to arithmetics stack
	LDI	1
	ST	CURPG(P2)		; set current page to first page
	LDI	0
	ST	PAGES(P2)		; set available pages to zero	
	LDI	0x70			; set page 7
	ST	RAMBAS(P2)		; store as first RAMBASE..
	; NOTE:	P1 low was set to one above
ENTR1:	XPAH	P1			; set P1.H with page value
	LDI	_CR			; set line terminator <cr>
	ST	(P1)			; store in page
	LD	(P1)			; re-load stored byte
	XRI	_CR			; is it <cr> ?
	JNZ	ENTR4			; no ram, test next page
	LD	3(P1)			; test for valid line counter
	JZ	ENTR2			; certainly not
	XAE
	LD	EREG(P1)		; load byte at end of line
	XRI	_CR			; is it <cr> ?
	JZ	ENTR3			; valid line of existing program
ENTR2:	LDI	0xFF			; otherwise mark page as empty
	ST	1(P1)			; store -1 as line number
	ST	2(P1)
ENTR3:	ILD	PAGES(P2)		; increase page counter
	XPAH	P1
	SCL
	CAI	0x10			; corresponding value of one page
	JNZ	ENTR1
	JMP	ENTR5			; page 0 reached
ENTR4:	XPAH	P1
	SCL
	CAI	0x10			; corresponding value of one page
	ST	RAMBAS(P2)		; store as new RAMBASE
	JNZ	ENTR1			; and test next page if not zero
ENTR5:	JS	P1,RESTRT		; done with pre-init, start supervisor


	IFNDEF KBPLUS
; NOTE:	Use internal routines for output/input.
;***************************
;*   PUT CHAR TO STDOUT    *
;***************************
PUTASC:
	 IFDEF EMULA
	  DB	WRCHAR
	  IFDEF	INTERNAL
	   XPPC	P3
	   JMP	PUTASC
	  ELSE
	   JMP	SV_RTRN(P3)
	  ENDIF
	 ENDIF

; FIXME: Former TTY routine, actually switched off
	IF	0
	 IFDEF	USETTY
	  ANI	0x7F			; mask off parity bit
	  XAE				; save in E
	  ST	-127(P2)		; store old E in RAM
	  LDI	TTY_B6			; set delay for start bit
	  DLY	TTY_B7			;  (TTY_B6=30 and TTY_B7=03)
	  CSA				; get status
	  ORI	1			; set start bit (inverted logic)
	  CAS				; set status
	  LDI	9			; set bit count
	  ST	-24(P2)			; store in RAM
PUTAS1:	  LDI	TTY_B8			; set delay for 1 bit time
	  DLY	TTY_B9			;  (TTY_B8=5C and TTY_B9=01)
	  DLD	-24(P2)			; decrement bit count
	  JZ	PUTAS2
	  LDE				; prepare next bit
	  ANI	1
	  ST	-23(P2)
	  XAE				; shift data right one bit
	  RR
	  XAE
	  CSA				; set up output bit
	  ORI	1
	  XOR	-23(P2)
	  CAS				; put bit to TTY
	  JMP	PUTAS1
PUTAS2:	  CSA				; set stop bit
	  ANI	0xFE
	  CAS
	  LD	-127(P2)
	  XAE
	  IFDEF USE_SLOW
	   XRI	_FF			; if this is not FormFeed
	   JNZ	PUTAS3			; do short delay
	   DLY	255			; else longer delay
	   JMP	PUTAS4
PUTAS3:	   ANI	0x60			; is it digit or letter ?
	   JNZ	PUTAS4
	   DLY	16
	  ENDIF
PUTAS4:	  JMP	SV_RTRN(P3)
	 ENDIF
	ENDIF

	IFDEF	USETTY
; NOTE:	Regular tty routine taken from kbplus
	ST	-127(P2)		; save byte
	XAE
	LDI	TTY_B6
	DLY	TTY_B7
	CSA				; set output bit to logic 0
	ORI	S_FLAG0			;  for start bit (note inversion)
	CAS
	LDI	9			; initialize bit count
	ST	-24(P2)
putc1:	LDI	TTY_B8			; delay 1 bit time
	DLY	TTY_B9
	DLD	-24(P2)			; decrement bit count
	JZ	putc2
	LDE				; prepare next bit
	ANI	S_FLAG0			; mask FLAG0 bit
	ST	-23(P2)
	XAE				; shift data right 1 bit
	SR
	XAE
	CSA				; set up output bit
	ORI	S_FLAG0
	XOR	-23(P2)
	CAS				; put bit to TTY
	JMP	putc1
putc2:	CSA				; set stop bit
	ANI	~S_FLAG0		; clear FLAG0 bit
	CAS
	ANI	S_SENSEB		; check for keyboard input
	JNZ	putc3			; (note that input is not inverted)
	LDI	(M_BRK-M_BASE)		; 'BREAK'
	JMP	SV_MSGOUT(P3)
putc3:	LD	-127(P2)		; restore saved byte
	RTRN
	ENDIF

;***************************
;*   GET CHAR FROM STDIN   *
;***************************
GETASC:
	 IFDEF EMULA
	  DB	RDCHAR
	  IFDEF	INTERNAL
	   LDE
	   XPPC	P3			; return
	   JMP	PUTASC
	  ELSE
	   XRI	_CTLC			; test for CONTROL-C
	   JNZ	SV_RTRN(P3)
	   LDI	(M_BRK-M_BASE)		; 'BREAK'
	   JMP	SV_MSGOUT(P3)
	  ENDIF
	 ENDIF

; FIXME: Former TTY routine, actually switched off
	 IFDEF	USETTY
	  IF	0
	  LDI	8			; set bit count
	  ST	COUNTR(P2)
GETAS1:	  CSA				; wait for start bit
	  ANI	0x20
	  JNZ	GETAS1
	  LDI	TTY_B1			; delay 1/2 bit time
	  DLY	TTY_B2			;  (TTY_B1=C2 and TTY_B2=00)
	  CSA				; is start bit still there?
	  ANI	S_SENSEB
	  JNZ	GETAS1			; no
GETAS2:	  LDI	TTY_B3			; delay bit time
	  DLY	TTY_B4			;  (TTY_B3=76 and TTY_B4=01)
	  CSA				; get bit (SENSEB)
	  ANI	S_SENSEB
	  JZ	GETAS3
	  LDI	1
GETAS3:	  RRL				; rotate into link
	  XAE
	  SRL				; shift into character
	  XAE				; return char to E
	  DLD	COUNTR(P2)		; decrement bit count
	  JNZ	GETAS2			; loop until 0
	  DLY	TTY_B5			; set delay (TTY_B5=01)
	  LDE				; load character from E
	  ANI	0x7F			; mask parity bit
	  XAE
	  LDE
	  ANI	0x40			; test for uppercase
	  JZ	GETAS4
	  LDE
	  ANI	0x5F			; convert to uppercase
	  XAE
GETAS4:	  LDE
	  XRI	_CTLC			; test for CONTROL-C
	  JNZ	GETAS5
	  LDI	(M_BRK-M_BASE)		; 'BREAK'
	  JMP	SV_MSGOUT(P3)
GETAS5:   JMP	SV_RTRN(P3)
	  ENDIF

; NOTE:	Regular tty routine taken from kbplus
	LDI	8			; set bit count
	ST	COUNTR(P2)
getc1:	CSA				; get status (wait for start bit)
	ANI	S_SENSEB		; mask SENSEB bit
	JNZ	getc1			; not set
	LDI	TTY_B1			; delay 1/2 bit time
	DLY	TTY_B2
	CSA				; is start bit still there?
	ANI	S_SENSEB		; mask SENSEB bit
	JNZ	getc1			; no
getc2:	LDI	TTY_B3			; delay bit time
	DLY	TTY_B4
	CSA				; get status
	ANI	S_SENSEB		; mask SENSEB bit
	JZ	getc3
	LDI	1			; set "1" bit
getc3:	RRL				; rotate \0 or \1 into link
	XAE
	SRL				; shift into character
	XAE				; return char to E
	DLD	COUNTR(P2)		; decrement bit count
	JNZ	getc2			; loop until 0
	DLY	TTY_B5
	LDE				; AC has input character
	ANI	0x7F			; strip parity bit
	XAE
	LDE
	RTRN
	 ENDIF
	ENDIF

	IF USE_CASS == 2
;**************************************
;*	Cassette I/O routines.        *
;**************************************
; NOTE: these will be moved to KBPLUS.
;
CSPEED_A	= 0x17			; 1200 baud, 2MHz
CSPEED_B	= 0x01
CSPEED_C	= 0x78
CSPEED_D	= 0x00
CSPEED_E	= 0x24
CSPEED_F	= 0x01

;****************************
;*  WRITE ONE BYTE TO TAPE  *
;****************************
;
CASWR:	ST	-96(P2)			; store byte
	LDI	10			; set bit counter (data,2xstop)
	ST	COUNTR(P2)		; store counter
	LDI	0			; write 0 bit (start)
	XAE
	SIO
	XAE
	DLD	-95(P2)
	LD	-96(P2)			; re-load byte
	XAE				; store in E
CASWR1:	LDI	CSPEED_A		; delay one bit time
	DLY	CSPEED_B
	LD	-94(P2)			; get user-spec delay value
	ST	-95(P2)			; store it
CASWR2:	DLD	-95(P2)			; decrease until zero
	JNZ	CASWR2			; user-delay done?
	SIO				; yes, send next bit
	LDE				; load E
	ORI	0x80			; set highest bit (set up stop bit..)
	XAE				; save back to E
	DLD	COUNTR(P2)		; decrease bit counter
	JNZ	CASWR1			; loop until done
	XPPC	P3			; return to caller
	JMP	CASWR			; for repeated calls

;*****************************
;*  READ ONE BYTE FROM TAPE  *
;*****************************
;
CASRD:	LDI	0xFF			; send out 1-bit (so no start bit!)
	XAE
	SIO
	LDE				; load the bit received
	JP	CASRD1			; we received a 0-bit (start) !
	JMP	CASRD			; try again
CASRD1:	LDI	CSPEED_C		; delay one half bit time
	DLY	CSPEED_D
	LDI	0xFF			; set 1-bit for reading
	XAE
	LD	-94(P2)
	SR
	ST	-95(P2)
CASRD2:	DLD	-95(P2)
	JNZ	CASRD2
	LDI	8			; set bit counter
	ST	COUNTR(P2)		; store bit counter
CASRD3:	LD	-94(P2)
	ST	-95(P2)
	LDI	CSPEED_E		; delay one bit time
	DLY	CSPEED_F
CASRD4:	DLD	-95(P2)
	JNZ	CASRD4
	SIO				; read one bit
	DLD	COUNTR(P2)		; decrease bit counter
	JNZ	CASRD3			; not done yet, do next
	LD	-94(P2)			; delay for stop bits
	ST	-95(P2)
CASRD5:	DLD	-95(P2)
	JNZ	CASRD5
	LDE				; load byte into AC
	XPPC	P3			; return to caller
	JMP	CASRD			; for repeated calls

;**************************
;*  WRITE MEMORY TO TAPE  *
;**************************
;FIXME: used P2 STACK offset -33, -34, -35, -36, -37, -38 may interfere with AEX STACK.
CASW:	LDI	H(CASWR-1)		; set P3 to CASWR, save old P3
	XPAH	P3
	ST	-16(P2)
	LDI	L(CASWR-1)
	XPAL	P3
	ST	-15(P2)
	LD	-34(P2)			; load start of program H
	ST	-38(P2)			; store
	XPAH	P1			; set P1.H
	LD	-33(P2)			; load start of program L
	ST	-37(P2)			; store
	XPAL	P1			; set P1.L
	LD	-34(P2)			; load start.H
	XPPC	P3			; write byte to tape
	LD	-33(P2)			; load start.L
	XPPC	P3			; write byte to tape
	LD	-36(P2)			; load end.H
	XPPC	P3			; write byte to tape
	LD	-35(P2)			; load end.L
	XPPC	P3			; write byte to tape
CASW1:	LDI	32			; set byte counter for block
	ST	-22(P2)			; store
	LDI	0			; initialize checksum
	ST	-23(P2)			; store
	CCL				; clear carry
CASW2:	LD	(P1)			; load byte from program
	ADD	-23(P2)			; add to checksum
	ST	-23(P2)
	LD	(P1)			; re-load byte from program
	XPPC	P3			; write byte to tape
	LD	-38(P2)			; load high byte of addr
	XOR	-36(P2)			; are we done yet?
	JNZ	CASW3			; no, do next
;FIXME: we should check -37(P2), because we do not save LAST byte now!!
	XPAL	P1			; compare low byte of addr
	XOR	-35(P2)
	JNZ	CASW3			; not done yet
	LD	-23(P2)			; done, load checksum byte
	XPPC	P3			; write byte to tape
	LD	-16(P2)			; restore P3 to old value
	XPAH	P3
	LD	-15(P2)
	XPAL	P3
	XPPC	P3			; return
CASW3:	ILD	-37(P2)			; end of current block
	JNZ	CASW4
	XPAH	P1
	ILD	-38(P2)
	XPAH	P1
CASW4:	XPAL	P1
	DLD	-22(P2)			; decrease block byte counter
	JNZ	CASW2			; not done yet, do next byte in block
	LD	-23(P2)			; block done, load checksum
	XPPC	P3			; write byte to tape
	JMP	CASW1			; do next block

;***************************
;*  READ MEMORY FROM TAPE  *
;***************************
;
CASR:	LDI	H(CASRD-1)		; set P3 to CASRD, save old P3
	XPAH	P3
	ST	-16(P2)
	LDI	L(CASRD-1)
	XPAL	P3
	ST	-15(P2)
	XPPC	P3			; read byte from cassette
	ST	-34(P2)			; store start addr H
	ST	NUMHI(P2)		; save to P1.H
	XPPC	P3			; read byte from cassette
	ST	-33(P2)			; store start addr L
	ST	NUMLO(P2)		; save to P1.L
	XPPC	P3			; read byte from cassette
	ST	-36(P2)			; store end addr H
	XPPC	P3			; read byte from cassette
	ST	-35(P2)			; store end addr L
CASR1:	LDI	32			; set block byte counter
	ST	-22(P2)			; store
	LDI	0			; initialize checksum
	ST	-23(P2)			; store
	CCL				; clear carry
CASR2:	LD	NUMLO(P2)		; set P1 to program's current addr
	XPAL	P1
	LD	NUMHI(P2)
	XPAH	P1
	XPPC	P3			; read byte from cassette
	ST	(P1)			; store in memory
	ADD	-23(P2)			; add to checksum
	ST	-23(P2)
	XPAH	P1			; check P1.H for all done
	XOR	-36(P2)
	JNZ	CASR4			; no, do next byte
	XPAL	P1			; check P1.L for all done
	XOR	-35(P2)
	JNZ	CASR4			; no, do next byte
	XPPC	P3			; read checksum from cassette
	XOR	-23(P2)			; check against current value
CASR3:	XAE				; save AC
	LD	-16(P2)			; restore P3 to old value
	XPAH	P3
	LD	-15(P2)
	XPAL	P3
	LDE				; restore AC
	XPPC	P3			; return
CASR4:	ILD	NUMLO(P2)		; increase P1 value by one
	JNZ	CASR5
	ILD	NUMHI(P2)
CASR5:	DLD	-22(P2)			; decrease block byte counter
	JNZ	CASR2			; not zero, do next byte in block
	XPPC	P3			; read checksum from cassette
	XOR	-23(P2)			; check against current value
	JNZ	CASR3			; whoops, a bad block!
	JMP	CASR1
	ENDIF

;*******************************************************
;*  Get 16-bit number (label) from BASIC program line  *
;*                and store on STACK.                  *
;*******************************************************
;
SPRNUM:	LD	@1(P1)			; get byte from program and increase
	ST	NUMHI(P2)		; save high byte of number
	LD	@2(P1)			; get byte from program and advance by 2
	ST	NUMLO(P2)		; save low byte of number

;*******************************************************
;*        Print 16-bit number on STACK -9, -8          *
;*         as decimal ASCII-representation.            *
;*******************************************************;  
;
PRNUM:	LDI	L(AEXSTK)-6		; reserve six bytes on arithmetics stack
	ST	AEXOFF(P2)		; save actual AEXSTK.L for later use
	XPAL	P1
	ST	-15(P2)			; save P1.low 
	LD	STKPHI(P3)
	XPAH	P1
	ST	-16(P2)			; save P1.high
	LDI	0
	ST	3(P1)
	LD	NUMLO(P2)
	ST	2(P1)
	LD	NUMHI(P2)
	ST	1(P1)
; NOTE:	Convert 16-bit integer into 4-byte float.
	LDI	0x8E			; load +14 and..
	ST	(P1)			; store as exponent
PNORM:	LD	1(P1)
	ADD	1(P1)
	XOR	1(P1)
	ANI	0x80			; test bit7
	JNZ	PFNUM			; go, we are ready for printing
	LD	(P1)			; normalize floating point number
	JZ	PFNUM
	DLD	(P1)			; decrease exponent..
	CCL				; ..and shift mantissa one bit left
	LD	3(P1)
	ADD	3(P1)
	ST	3(P1)
	LD	2(P1)
	ADD	2(P1)
	ST	2(P1)
	LD	1(P1)
	ADD	1(P1)
	ST	1(P1)
	JMP	PNORM
; NOTE: Print positive 4-byte floating point number
PFNUM:	LDI	0			; load zero
	ST	CHRNUM(P2)	; digit counter or sign ? 0 = positive ?
	LDI	' '			; load <space> for positive number
	ST	-5(P1)			; store 5 bytes lower (below scratch)
; NOTE:	only positive numbers are relevant, so fall through directly to ZERO
	LD	1(P1)
	JZ	ZERO			; is MSB of mantissa zero ?
	JP	DIG10			; go, mantissa is positive
	LDI	'-'			; load <minus> for negative number
	ST	-5(P1)			; store 5 bytes lower (below scratch)
	SCL
	LDI	0			; negate number on AEX STACK
	CAD	3(P1)
	ST	3(P1)
	LDI	0
	CAD	2(P1)
	ST	2(P1)
	LDI	0
	CAD	1(P1)
	ST	1(P1)			; now positive BUT sometimes bit7 set!
; NOTE:	now invert bit7 of exponent (strip characteristic)
DIG10:	LD	(P1)
	XRI	0x80
; NOTE:	If number is positive, skip and fall through directly to ZERO
	JP	ZERO			; go, exponent is positive
	CALL	NEGEXP
ZERO:	LDI	1
	ST	-4(P1)			; store 1 temporary
	LD	1(P1)			; load MANT1
	JZ	DIG19			; go, MANT1 is zero
DIG13:	LDI	0xA0			; load b'10100000' 10<<4 ?
	XAE				; preserve in E
	LD	3(P1)			; copy number four bytes down in SCRATCH
	ST	-1(P1)
	LD	2(P1)
	ST	-2(P1)
	LD	1(P1)
	ST	-3(P1)
	LDI	0			; set top mantissa to zero
	ST	3(P1)
	ST	2(P1)
	ST	1(P1)
	LDI	24			; shift 24 bit
	ST	-6(P1)			; store bit counter
DIGLP:	SCL				; shift left loop
	LD	-3(P1)			; load MANT1
	CAI	0x50			; subtract b'01010000' 10<<3 ?
	JP	DIG15			; go, greater / equal 10
	JMP	DIG16			; otherwise subtraction "failed"
DIG15:	ST	-3(P1)			; store again
	ILD	3(P1)			; increase quotient
DIG16:	DLD	-6(P1)			; decrease shift counter
	JZ	DIG17			; zero, shift loop complete
	CCL
	LDE				; E holds 0xA0, see above
	ADE
	XAE
	LD	-1(P1)
	ADD	-1(P1)
	ST	-1(P1)
	LD	-2(P1)
	ADD	-2(P1)
	ST	-2(P1)
	LD	-3(P1)
	ADD	-3(P1)
	ST	-3(P1)
; NOTE: shifted E and mantissa 1 bit left
	LD	3(P1)
	ADD	3(P1)
	ST	3(P1)
	LD	2(P1)
	ADD	2(P1)
	ST	2(P1)
	LD	1(P1)
	ADD	1(P1)
	ST	1(P1)
; NOTE: shifted quotient 1 bit left
	JMP	DIGLP			; continue shift loop
DIG17:	LD	1(P1)			; comes here from shift loop
	JP	DIG18			; test bit7 of QUOTIENT1
; NOTE:	bit7 set, so shift quotient right one bit (dividde by 2)
	CCL
	RRL
	ST	1(P1)
	LD	2(P1)
	RRL
	ST	2(P1)
	LD	3(P1)
	RRL
	ST	3(P1)
; NOTE:	compensate divide by increasing exp by one
	ILD	(P1)
DIG18:	SCL
	LD	(P1)
	CAI	4			; subtract exponent by 4
	ST	(P1)
	JP	DIG19
	ILD	-4(P1)			; increase temporary
	JMP	DIG13
DIG19:	LD	-4(P1)			; load temporary
	ST	COUNTR(P2)		; store on STACK -21
	LD	CHRNUM(P2)		; load digit counter
	JNZ	DIG20
	SCL
	LDI	6			; maximal digit limit ?
	CAD	-4(P1)
	JP	DIG20			; not reached
	DLD	-4(P1)			; decrease temporary..
	ST	CHRNUM(P2)		; ..store as digit counter
	LDI	1
	ST	-4(P1)			; store one in temporary
DIG20:	CCL
	LD	1(P1)
	RRL
	ST	1(P1)
	LD	2(P1)
	RRL
	ST	2(P1)
	LD	3(P1)
	RRL
	ST	3(P1)
	LDE
	RRL
	XAE
	ILD	(P1)
	XRI	0x86
	JNZ	DIG20
; shifted E and quotient 1 bit right until exp equal 6
	LDE
	ADI	2
	ST	1(P1)
	LDI	5
	ST	(P1)
; NOTE:	advance AEX STACK pointer to begin of number string
	LD	@-5(P1)
	CSA
; NOTE: Bit7 in status reg is carry/link.
	JP	DEC
	ILD	8(P1)			; was before 3(P1)
	JNZ	DEC
	ILD	7(P1)			; was before 2(P1)
	JNZ	DEC
	LDI	'1'
	ST	@-1(P1)			; increase and store <one>
	LD	CHRNUM(P2)		; load digit counter
	JNZ	DIG21
	LD	2(P1)			; temporary, was before -4(P1) ?
	XRI	6
	JNZ	DEC
	ADI	5
DIG21:	ADI	0
	ST	CHRNUM(P2)		; store digit counter
	JMP	PEXP
DEC:	CALL	BINDEC			; convert binary to decimal digits
	LD	CHRNUM(P2)		; load digit counter
	JZ	PFNUMD 
PEXP:	XAE				; calculate decimal exponent
	LDI	'E'
	ST	@-1(P1)			; store 'E' for exponent
	LDE				; E holds exponent
	JP	PEXP1			; positive exponent ?
	LDI	'-'
	ST	@-1(P1)			; store <minus> for negative exponent
PEXP1:	SCL
	LDE
	ANI	0x7F			; strip characteristic
	CAI	10			; subtract 10
	JP	PEXP2			; exponent is equal / greater 10
	JMP	PEXPD
PEXP2:	XAE
	LDI	'0'
	ST	@-1(P1)			; decrease and store <zero>
PEXP3:	ILD	(P1)			; increase digit
	LDE
	CAI	10			; subtract 10 while positive and increase counter
	XAE
	LDE
	JP	PEXP3			; exponent still equal / greater 10
PEXPD:	ADI	'9'+1			; calculate ASCII value of latest digit
	ST	@-1(P1)			; decrease and store ASCII digit
PFNUMD:	LDI	0			; load <null>
	ST	@-1(P1)			; decrease P1 and store as string delimiter
	LD	AEXOFF(P2)
	XPAL	P1
	LDI	L(AEXSTK)-2		; let two bytes free for 16-bit number
	ST	AEXOFF(P2)		; reset arithmetics stack
	LD	@-5(P1)			; skip after stored floating point number
PTNUM:	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	LD	@-1(P1)
	JNZ	PTNUM			; loop until <null>
PTEND:	LD	-15(P2)			; restore P1 and return
	XPAL	P1
	LD	-16(P2)
	XPAH	P1
	RTRN

	IF	0
; NOTE: Old PRNUM routine
	LDI	' '			; positive, store leading space
	ST	-5(P1)			; save as prefix for number
	LDI	-6			; load index of first digit
	ST	CHRNUM(P2)		; store as digit counter
	LD	NUMLO(P2)
	ST	-3(P1)
	LD	NUMHI(P2)		; load 16-bit number..
	ST	-4(P1)			; and put as dividend on AEX STACK
; FIXME: Negating number is omitted (not needed, should never happen.)
	IF	0
	 JP	DIV
	 LDI	'-'			; negative, so store <minus>
	 ST	-5(P1)			; save as prefix for number
	 SCL
	 LDI	0			; negate number on AEX STACK
	 CAD	NUMLO(P2)
	 ST	-3(P1)
	 LDI	0
	 CAD	NUMHI(P2)
	 ST	-4(P1)
	ENDIF
; NOTE: Place for quotient is reserved at -2 and -1 of AEX STACK.
DIV:	LDI	0			; clear quotient
	ST	-1(P1)
	ST	-2(P1)
	XAE				; set E to zero
	LDI	16			; shift 16 bit
	ST	-6(P1)			; store as bit counter below number
DIVLP:	CCL
	LD	-1(P1)			; shift 4 byte left one bit
	ADD	-1(P1)
	ST	-1(P1)
	LD	-2(P1)
	ADD	-2(P1)
	ST	-2(P1)
	LD	-3(P1)
	ADD	-3(P1)
	ST	-3(P1)
	LD	-4(P1)
	ADD	-4(P1)
	ST	-4(P1)
	LDE
	ADE				; shift carry into E
	XAE
	LDE
	ADI	-10			; subtract 10
	JP	DIV1			; go, greater/equal 10
	JMP	DIV2			; otherwise subtraction "failed"
DIV1:	XAE
	ILD	-1(P1)			; increase quotient
DIV2:	DLD	-6(P1)			; decrease bit counter
	JNZ	DIVLP			; loop again
; NOTE: AEX STACK -6 is now zero, serves as delimiter for ASCII string.
	DLD	CHRNUM(P2)		; decrease digit counter
	XAE				; put into E, A holds now remainder from divide
	ORI	'0'			; prepare ASCII value
	ST	EREG(P1)		; put it on AEX STACK
	LD	-1(P1)			; store incomplete quotient as new dividend
	ST	-3(P1)
	LD	-2(P1)
	ST	-4(P1)
	OR	-3(P1)
	JNZ	DIV			; loop, quotient not yet zero
	DLD	CHRNUM(P2)
	XAE
	LD	-5(P1)			; load prefix for number
	ST	@EREG(P1)		; advance stack to begin of number string and store
PRNT:	LD	@1(P1)			; load digit from stack and increase
	JZ	PNEND			; zero ends printing, see above
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	JMP	PRNT
PNEND:	LD	-15(P2)			; restore P1 and return
	XPAL	P1
	LD	-16(P2)
	XPAH	P1
	RTRN
	ENDIF

;***************************
;*  FREE SPACE IN D BLOCK  *
;***************************


;***************************
;*  START OF NIBLFP BASIC  *
;***************************
;
; This block of code forms the core of the interpreter, centered
; around the I.L. Supervisor. This routine, in the middle of the
; block, handles most I.L. calls. Because of the limited jumping
; capabilities of the SC/MP, we also abuse it to place often-used
; routines very close around it, so we can 'reach' them using an
; offset off the P3 register (which permanently points to this
; core routine), effectively allowing us to address $xx00 through
; $xxFF with a single mechanism.
;
; Because of the above, THIS CODE MUST START at a $xx00-based
; offset in memory, with the Supervisor at offset $0080 for a
; maximized jump reach.
;
; Initialization code can either jump to INIT ($xx00), or directly
; to the RESTRT routine. NOTE that because of jump limitations and
; other "fun stuff", code here should not be changed unless you
; (really!) know what you are doing.

; Following for two-byte SYSCALLs taken from a lookup table.
	IFDEF	SCALLS
	ORG	SV_BASE - 1		; **MUST START HERE**
	IFDEF DEBUG
	 ASSERT	* == SV_BASE - 1	; **MUST** BE HERE!!
	ENDIF
; Perform System call with address from lookup table
; CAVEAT: Do not change extension register.
SCALL:	DLD	SUBOFF(P2)		; reserve place on SUBSTACK..
	DLD	SUBOFF(P2)		; ..two bytes for return address
	XPAL	P2			; load P2.L with prepared SUBSTACK.L
	CCL
	LD	@1(P3)			; re-get first byte in macro, advance one byte
	; calculate syscall address with this byte
	ADD	-1(P3)			; double SYSCALL number
	ADI	L(SCALLS - 2)		; add low byte base address
	XPAL	P3			; low byte address SYSCALL in P3.L
	ST	1(P2)			; store prev value P3.L
	LDI	H(SCALLS - 2)		; load high byte base address
	XPAH	P3			; high byte address SYSCALL in P3.H
	ST	(P2)			; store prev value P3.H
	LD	(P3)			; load high byte SYSCALL
	XPAL	P2			; store temporary in P2.L ..
	LD	1(P3)			; load low byte SYSCALL
	XPAL	P3			; put into P3.L
	IFDEF	KBPLUS
	 LDI	RAMSTK			; default STACK.L for KBPLUS syscalls
	ELSE
	 LDI	STKMID			; default STACK.L for internal syscalls
	ENDIF
	XPAL	P2
	XPAH	P3			; load new P3.H from P2.L
	JMP	SPEXEC			; go and execute
SCALL1:	JMP	SCALL

	; This is the real start of the supervisor code. Although
	; it does not have to start at this address, we do force it
	; here so we do not break the relative jump addresses which
	; could otherwise run "out of range".
	;

	ELSE
	ORG	SV_BASE + 33		; **MUST START HERE**
	IFDEF DEBUG
	 ASSERT	* == SV_BASE + 33	; **MUST** BE HERE!!
	ENDIF
	ENDIF

	; NOTE:
	; We cannot use LDPI here, because the second byte
	; of the first instruction below is used everywhere
	; in the code to fetch the HIGH BYTE of the stack.
	; This is why we add the +1 in the next instruction.
	;
RESTRT:	LDI	H(STKBASE)		; must remain, gives RAMBASE.H
; FIXME: following switched off to get space, very preliminary
	IF	0
	 ORI	H(VARSBUF)
	 XPAH	P1
	 LDI	L(STKBASE)
	 XPAL	P1			; point P1 to program memory
	 LDI	0			; mark variables' storage as empty
	 ST	(P1)			; store zero at begin
	 ST	BASMODE(P2)		; clear command/run flag
	ENDIF
	LDI	0x1F
	ST	-94(P2)
	CALL	CLRSTK			; clear BASIC stack
	CALL	VERS			; say HELLO to the user
	CALL	MEMSIZ			; report memory size
	LDI	L(SUBSTK)-2		; initialize stack offset
	ST	SUBOFF(P2)		; store default top of CALL/RTRN stack
	LDE				; E holds offset for FREE message
MSGOUT:	CALL	MESG			; print messages (offset in A)
	LDI	72			; max. characters per line
	ST	(P2)
	LDI	_PRMPT			; set mode to "COMMAND PROMPT"
	ST	BASMODE(P2)		; store command/run flag
	LDI	L(ILCSTK)
	ST	ILCOFF(P2)		; store top of ILCALL/ILRTRN stack
	LDI	L(AEXSTK)		; initialize arithmetics stack
	ST	AEXOFF(P2)		; store default offset to arithmetics stack
	LDI	H(ILTBL)		; get ILTBL.H
	ST	-2(P2)			; store
	LDI	L(ILTBL)		; get ILTBL.L
	ST	-1(P2)			; store
	CALL	LINE			; print new line (to finish message)
	LDI	L(SUBSTK)-4		; reserve bytes on CALL/RTRN stack
	ST	SUBOFF(P2)		; set initial value for P2.L

SPLOAD:	LD	-1(P2)			; get call ADDR.L
	XPAL	P3
	LD	-2(P2)			; get call ADDR.H
	ORI	0xC0			; set bits 7:6 for valid high byte
	XPAH	P3

SPTEST:	LD	1(P3)			; get second (low) byte from IL code
	ST	-1(P2)			; store
	LD	@2(P3)			; get first (high) byte from IL code
	JZ	RTFUNC			; return if zero
	ST	-2(P2)			; store
	ANI	(JMPBIT+TSTBIT+CALBIT)	; only test IL control (upper 3) bits
	JZ	GOFUNC			; no bits set, must be ILCALL
	JP	SPLOAD
	XRI	(JMPBIT+TSTBIT+CALBIT)
	JNZ	TESTLP
	LD	-1(P3)			; load call ADDR.L
	XPAL	P3
	ST	-1(P2)			; save prev P3.L
	LD	-2(P2)			; load call ADDR.H
	XPAH	P3
	ST	-2(P2)			; save prev P3.H
SPEXEC:	LD	@-1(P3)			; decrease P3 by 1 for PC prefetch
	LDE

	; The central routine in the I.L. Supervisor. This is
	; where it all happens, and this is what the P3 pointer
	; usually is set to. We can jump here, or we can do far
	; jumps to co-routines in this block by using a relative
	; offset to the P3 pointer (the SV_xxx values above.)
	;
	IFDEF DEBUG
	 ASSERT	* == SV_BASE+0x0080	; **MUST** BE HERE!!
	ENDIF
SPRVSR:	XPPC	P3			; supervisor for call and return
	XAE				; save A in E, content of E is lost!
	LD	@1(P3)			; skip last byte of ret addr, is 0x3F
	LD	(P3)			; grab first byte in macro
	JZ	SPRTN			; if zero, it is a return from subroutine
	IFDEF	SCALLS
	 JP	SCALL1			; if > 0, two-byte system call
	 XRI	0x90			; is it a return from SYSCALL ?
	 JZ	SYSRTN			; if zero, it is a return from SYSCALL
	ENDIF
	LD	SUBOFF(P2)		; reset P2.L to initial state
	XPAL	P2
	LD	@2(P3)			; re-get first byte in macro, advance two bytes
	ST	-2(P2)			; store
	LD	-1(P3)			; get second byte in macro
	XPAL	P3			; set low byte of addr
	ST	@-1(P2)			; decrease and store prev value P3.L
	LD	-1(P2)			; re-get first byte of macro
	XPAH	P3			; set high byte of addr
	ST	@-1(P2)			; decrease and store prev value P3.H
	LDI	STKMID			; initialize stack..
	XPAL	P2
	ST	SUBOFF(P2)		; .. and store prev SUBSTACK.L
	JNZ	SPEXEC			; go and execute
RTNEST:	LDI	(M_NEST-M_BASE)		; 'NEST ERROR'
RTERRN:	XAE				; return with error offset in AC
	LDI	L(SUBSTK)		; reset CALL/RTRN stack
	JMP	SPRTN1
SYSRTN:
	IFDEF	KBPLUS
	 LD	@-118(P2)		; reset P2.L back to STKMID
	ENDIF
	JMP	SPRTN
SPTST1:	JMP	SPTEST
SPLINE:	LDI	_CR
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	LDI	_LF
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
SPRTN:	ILD	SUBOFF(P2)		; adjust SUBSTK.L by two bytes up
	ILD	SUBOFF(P2)
SPRTN1:	XPAL	P2
	LD	-1(P2)
	XPAL	P3
	LD	-2(P2)
	XPAH	P3
	LDI	STKMID			; reset stack
	XPAL	P2
	JMP	SPEXEC
SPLOD2:	JMP	SPLOAD
GOFUNC:	DLD	ILCOFF(P2)		; adjust ILCSTK.L by two down
	DLD	ILCOFF(P2)
	JP	RTNEST
	XPAL	P2
	XPAL	P3
	ST	1(P2)
	XPAH	P3
	ST	(P2)
	XPAL	P3
	XPAL	P2
	JMP	SPLOD2
RTFUNC:	ILD	ILCOFF(P2)		; adjust ILCSTK.L by two up
	ILD	ILCOFF(P2)
	XPAL	P2
	LD	-1(P2)
	XPAL	P3
	LD	-2(P2)
	XPAH	P3
	LDI	STKMID			; reset stack
	XPAL	P2
SPTST2:	JMP	SPTST1			; only stepping stone to avoid too far jumps

VALERR:	LDI	(M_VALU-M_BASE)		; 'VALUE ERROR'
	JMP	RTERRN

; FIXME:
; uncertain if space eating always needed, in principle only for TSTVAR.
; TSTSTR tests for <cr> with leading spaces, in principle now needed only for token.
TESTLP:	LD	@1(P1)			; get byte from program and increase
	XRI	' '			; is it <space> ?
	JZ	TESTLP			; yes, eat it
	LD	-2(P2)
	ANI	(TSTBIT+CALBIT)		; look at bits 6:5 (TSTSTR or TSTNUM or TSTVAR)
	JNZ	TESTB6			; jump for TSTNUM or TSTVAR
	LD	-1(P1)			; TSTSTR, load prev byte from program
	XOR	@1(P3)
	JZ	SPTST2
	LD	@-1(P1)			; decrease and load byte from program
	JMP	SPLOD2
TESTB6:	XRI	TSTBIT			; test for number (bit6=1)
	JZ	TESTN			; could be, jump to asure
	LD	-1(P1)			; get previous byte from program
	XAE				; now test for variable,
	SCL				; must begin with letter
	LDE
	CAI	'Z'+1			; no beginning letter
	JP	LVTST1			; leave test
	ADI	26			; 'Z'-'A'+1
	JP	LKVAR			; found letter
LVTST1:	LD	-2(P2)
	ANI	0xFF ! CALBIT		; clear TSTVAR = CALBIT
	ST	-2(P2)
LVTST2:	LD	@-1(P1)			; decrease P1 and get previous byte
	JMP	SPLOD2
VALER2:	JMP	VALERR
LKVAR:	SCL				; beginning letter found, got more ?
	LD	(P1)			; get current byte from program
	CAI	'Z'+1
	JP	LVTST3			; no more letter found
	ADI	26			; 'Z'-'A'+1
	JP	SPTST2			; found letter
	SCL
	LD	(P1)
	CAI	'9'+1
	JP	LVTST3			; no digit
	ADI	10			; '9'-'0'+1
	JP	SPTST2			; next test
LVTST3:	LDE
	ORI	0x80			; set bit7 to terminate variable
	XAE
SPTST3:	JMP	SPTST2			; next test

TESTN:	ST	-24(P2)			; clear temporary digit counter
	LD	-1(P1)			; get previous byte from program
TSTN1:	SCL
	CAI	'9'+1
	JP	TSTN3			; no digit
	ADI	10			; '9'-'0'+1
	JNZ	TSTN2			; digit is not (leading) zero
	ILD	-24(P2)			; increase temporary digit counter
	LD	@1(P1)			; get current byte and increase
	JMP	TSTN1			; go for next test
TSTN2:	JP	TSTN4			; go store digit
TSTN3:	LD	-24(P2)			; was there any digit
	JZ	LVTST2			; if not leave test
	LD	@-1(P1)			; decrease and get byte from program
	LDI	0
	ST	-24(P2)			; clear temporary counter again
TSTN4:	XAE
	LD	AEXOFF(P2)		; setup arithmetics stack
	XPAL	P2
	LDI	0x96
; NOTE:	b'10010110' is stored as exponent, means b'00010110' = 22 decimal
;	MSB most, LSB least significant byte
	ST	@-4(P2)			; reserve four bytes on stack
	LDI	0			; clear mantissa,
	ST	1(P2)			; fractional point is at MSB between bit7 and bit6
	ST	2(P2)
	LDE
	ST	3(P2)			; store digit out of E in LSB
TSTN5:	SCL
	LD	@1(P1)			; load current byte and increase
	CAI	'9'+1
	JP	TSTN6			; no digit
	ADI	10			; '9'-'0'+1
	JP	TSTN10			; is digit
TSTN6:	LD	@-1(P1)			; reset to previous byte
TSTN7:	LD	1(P2)			; load MSB of mantissa
	ADD	1(P2)			; shift bit left, bit6 -> bit7 in A
	XOR	1(P2)
	JP	TSTN9			; jump if bit6 and bit7 were set
TSTN8:	LDI	STKMID
	XPAL	P2
	ST	AEXOFF(P2)		; save arithmetics stack low	
	JMP	SPTST3			; go back to I.L.
VALER1:	JMP	VALER2			; only stepping stone to avoid too far jumps
TSTN10:	XAE				; save new digit in E
	CCL				; shift mantissa left by 1
	LD	3(P2)
	ADD	3(P2)
	ST	3(P2)
	ST	-1(P2)			; temporary store result 4 bytes lower
	LD	2(P2)
	ADD	2(P2)
	ST	2(P2)
	ST	-2(P2)
	LD	1(P2)
	ADD	1(P2)
	ST	1(P2)
	ST	-3(P2)
	LDI	4			; load shift counter
	ST	-4(P2)			; store 4 bytes lower
TSTN11:	LD	3(P2)			; perform another shift
	ADD	-1(P2)
	ST	3(P2)
	LD	2(P2)
	ADD	-2(P2)
	ST	2(P2)
	LD	1(P2)
	ADD	-3(P2)
	ST	1(P2)
	ANI	0x80
	JNZ	VALER1			; bit7 is set, throw value error
	DLD	-4(P2)			; decrease shift counter
	JNZ	TSTN11			; and shift again
	XAE				; add in new digit, E holds zero
	ADD	3(P2)
	ST	3(P2)
	LDE
	ADD	2(P2)
	ST	2(P2)
	LDE
	ADD	1(P2)
	ST	1(P2)
	JP	TSTN5			; try for more digits
	JMP	VALER1			; bit7 is set, throw value error
TSTN9:	LD	(P2)			; test exponent
	JZ	TSTN8			; zero, we're done
	DLD	(P2)			; decrease exponent
	CCL				; shift mantissa left by 1
	LD	3(P2)
	ADD	3(P2)
	ST	3(P2)
	LD	2(P2)
	ADD	2(P2)
	ST	2(P2)
	LD	1(P2)
	ADD	1(P2)
	ST	1(P2)
	JMP	TSTN7			; try again

;**************************************
;*    PRINT AVAILABLE MEMORY SIZE     *
;**************************************
;
; NOTE:	Count memory bytes in the available pages, leave out page 0,
;	 so first accessible page is 1, highest countable page is 7.
;	Assume contiguous memory block at least in page 1, occupied
;	 place by an existent program is taken into account.
;	Last page holds max. 3072 bytes until beginning of STACK.
;
MEMSIZ:	LDI	0
	ST	NUMLO(P2)		; set memsize to zero
	ST	NUMHI(P2)
	LD	PAGES(P2)
	ST	-24(P2)			; temporary store number of pages
	LDI	0x10			; first page high byte
	XPAL	P1
MEM1:	LDI	2			; position of first byte in line
	XPAL	P1			; use pointer P3
	XPAH	P1
MEM2:	LD	(P1)			; get current program byte
	XRI	0xFF			; is it first byte of end termination ?
	JNZ	MEM3			; no, go ahead
	LD	1(P1)
	XRI	0xFF			; do we have second byte ?
	JZ	MEM4			; yes, we are done
MEM3:	LD	2(P1)
	XAE
	LD	@EREG(P1)		; advance to next program line
	JMP	MEM2
MEM4:	LD	@2(P1)			; advance to first free byte
	XPAL	P1			; store P1 as TOP
	ST	PGTOPL(P2)
	CCL
	XPAH	P1
	ST	PGTOPH(P2)
	ADI	0x10			; calculate next page high
	ANI	0xF0			; set lowest 4 bits to zero
	XPAL	P1
	SCL				; now calculate free memory on page
	LDI	0			; subtract TOP from end of page
	CAD	PGTOPL(P2)
	ST	PGTOPL(P2)		; store as FREE.L
	LDI	0
	CAD	PGTOPH(P2)
	ANI	0x0F			; only last 4 bits are relevant
	ST	PGTOPH(P2)		; store as FREE.H
	CCL
	LD	PGTOPL(P2)		; add to memsize in STACK -9,-8
	ADD	NUMLO(P2)
	ST	NUMLO(P2)
	LD	PGTOPH(P2)
	ADD	NUMHI(P2)
	ST	NUMHI(P2)
	DLD	-24(P2)			; decrease number of pages
	JNZ	MEM1
	SCL				; subtract 1024 bytes for STACK
	LD	NUMHI(P2)
	CAI	4
	ST	NUMHI(P2)
	CALL	PRNUM			; print memsize
	LDI	' '			; next print a space
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	LDI	(M_FREE-M_BASE)		; set message offset


;***************************
;*  PRINT ERROR MESSAGES   *
;***************************
;
; We use relative offsets to messages instead of absolute
; addresses and adjust the message pointer by adding the E
; register.
;
; If offset is NEGATIVE, it is an error, and we print a ?
; first, then the error message, followed by a SPACE and
; the word 'error'. If postive, we ONLY print the word
; pointed to by the offset.
;
MESG:	ST	MSGOFF(P2)		; store relative offset
	XAE				; save offset into E
	LDPI	P1,M_BASE		; set P1 to message base addr
	LD	@EREG(P1)		; adjust pointer
	LDE	
	JP	MESG1			; not error, skip
	LDI	_QMARK			; print a question mark (error!)
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
MESG1:	LD	@1(P1)			; now print the message
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	JP	MESG1
	LD	MSGOFF(P2)		; load used offset
	JP	MESG2			; no error message, skip
	LDI	' '			; print a space before ERROR
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	LDI	(M_ERR-M_BASE)		; set 'ERROR' message offset
	JMP	MESG
MESG2:	XRI	(M_FREE-M_BASE)		; was it 'FREE' message ?
	JNZ	LNUM			; no, print line number
	JMP	SV_LINE(P3)		; return and print newline


;***************************
;* MESSAGE AT LINE NUMBER  *
;***************************
;
LNUM:	LD	BASMODE(P2)		; increase command/run flag
	JP	LNUM1			; return if in command mode
	LDI	' '			; print <space>
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	LDI	'A'			; print "AT"
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	LDI	'T'
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	CALL	PRNUM			; print line number
LNUM1:	LD	MSGOFF(P2)		; load last message offset
	XRI	(M_ERR-M_BASE)		; minus 'ERROR' message offset
	JNZ	SV_RTRN(P3)
	ST	BASMODE(P2)		; clear command / run flag
	LDI	(M_RDY-M_BASE)		; set 'READY' message offset
	CALL	LINE
	JMP	MESG


;***************************
;*        MESSAGES         *
;***************************
;
M_AREA:	MESG	"ARE",'A'
M_ARG:	MESG	"ARGUMEN",'T'
M_CASS:	MESG	"CAS",'S'
M_CHAR:	MESG	"CHA",'R'
M_DEF:	MESG	"DEFIN",'E'
M_DATA:	MESG	"DAT",'A'
M_RDIM:	MESG	"RE"
M_DIM:	MESG	"DI",'M'
M_DIV0:	MESG	"DIV/",'0'
M_ENDP:	MESG	"END",')'
M_ENDQ:	MESG	"END",'"'
M_FOR:	MESG	"FO",'R'
M_HEX:	MESG	"HE",'X'
M_NEST:	MESG	"NES",'T'
M_NEXT:	MESG	"NEX",'T'
M_NOGO:	MESG	"NOG",'O'
M_OVRF:	MESG	"OVERFLO",'W'
M_RAM:	MESG	"RA",'M'		; FIXME: unused (use for RAM testing)
M_RTRN:	MESG	"RETUR",'N'
M_SNTX:	MESG	"SYNTA",'X'
M_STMT:	MESG	"STATEMEN",'T'
M_UNTL:	MESG	"UNTI",'L'
M_VALU:	MESG	"VALU",'E'
M_VAR:	MESG	"VARIABL",'E'
M_VRST:	MESG	"VARSTAC",'K'
M_BASE	= $				; message separator (see MSGOUT)
M_BRK:	MESG	"BREA",'K'
M_ERR:	MESG	"ERRO",'R'
M_RDY:	MESG	"READ",'Y'
M_FREE:	MESG	"BYTES MEMORY FRE",'E'


;***************************
;*       TOKEN TABLE       *
;***************************
;
TOKENS:
T_AUTO	= 0x80|0
	TOKEN	T_AUTO,"AUT",'O'
T_BYE	= 0x80|1
	TOKEN	T_BYE,"BY",'E'
T_CLEAR	= 0x80|2
	TOKEN	T_CLEAR,"CLEA",'R'
T_CLOAD	= 0x80|3
	TOKEN	T_CLOAD,"CLOA",'D'
T_CSAVE	= 0x80|4
	TOKEN	T_CSAVE,"CSAV",'E'
T_EDIT	= 0x80|5
	TOKEN	T_EDIT,"EDI",'T'
T_LIST	= 0x80|6
	TOKEN	T_LIST,"LIS",'T'
T_NEW	= 0x80|7
	TOKEN	T_NEW,"NE",'W'
T_RUN	= 0x80|8
	TOKEN	T_RUN,"RU",'N'
T_VERS	= 0x80|9
	TOKEN	T_VERS,"VER",'S'
T_LAST	= T_VERS			; last command
T_DATA	= 0x80|10
	TOKEN	T_DATA,"DAT",'A'
T_DEF	= 0x80|11
	TOKEN	T_DEF,"DE",'F'
T_DIM	= 0x80|12
	TOKEN	T_DIM,"DI",'M'
T_DO	= 0x80|13
	TOKEN	T_DO,"D",'O'
T_ELSE	= 0x80|14
	TOKEN	T_ELSE,"ELS",'E'
T_END	= 0x80|15
	TOKEN	T_END,"EN",'D'
T_FOR	= 0x80|16
	TOKEN	T_FOR,"FO",'R'
T_GOSUB	= 0x80|17
	TOKEN	T_GOSUB,"GOSU",'B'
T_GOTO	= 0x80|18
	TOKEN	T_GOTO,"GOT",'O'
T_IF	= 0x80|19
	TOKEN	T_IF,"I",'F'
T_INPUT	= 0x80|20
	TOKEN	T_INPUT,"INPU",'T'
T_LINK	= 0x80|21
	TOKEN	T_LINK,"LIN",'K'
T_NEXT	= 0x80|22
	TOKEN	T_NEXT,"NEX",'T'
T_ON	= 0x80|23
	TOKEN	T_ON,"O",'N'
T_PAGE	= 0x80|24
	TOKEN	T_PAGE,"PAG",'E'
T_POKE	= 0x80|25
	TOKEN	T_POKE,"POK",'E'
T_PRINT	= 0x80|26
	TOKEN	T_PRINT,"PRIN",'T'
T_PR	= 0x80|27
	TOKEN	T_PR,"P",'R'
T_READ	= 0x80|28
	TOKEN	T_READ,"REA",'D'
T_REM	= 0x80|29
	TOKEN	T_REM,"RE",'M'
T_RESTORE = 0x80|30
	TOKEN	T_RESTORE,"RESTOR",'E'
T_RETURN = 0x80|31
	TOKEN	T_RETURN,"RETUR",'N'
T_STAT	= 0x80|32
	TOKEN	T_STAT,"STA",'T'
T_UNTIL	= 0x80|33
	TOKEN	T_UNTIL,"UNTI",'L'
T_LET	= 0x80|34
	TOKEN	T_LET,"LE",'T'
T_AND	= 0x80|35
	TOKEN	T_AND,"AN",'D'
T_DIV	= 0x80|36
	TOKEN	T_DIV,"DI",'V'
T_EXOR	= 0x80|37
	TOKEN	T_EXOR,"EXO",'R'
T_MOD	= 0x80|38
	TOKEN	T_MOD,"MO",'D'
T_OR	= 0x80|39
	TOKEN	T_OR,"O",'R'
T_PEEK	= 0x80|40
	TOKEN	T_PEEK,"PEE",'K'
T_LE	= 0x80|41
	TOKEN	T_LE,"<",'='
T_GE	= 0x80|42
	TOKEN	T_GE,">",'='
T_NE	= 0x80|43
	TOKEN	T_NE,"<",'>'
T_ABS	= 0x80|44
	TOKEN	T_ABS,"AB",'S'
T_ATN	= 0x80|45
	TOKEN	T_ATN,"AT",'N'
T_COS	= 0x80|46
	TOKEN	T_COS,"CO",'S'
T_EXP	= 0x80|47
	TOKEN	T_EXP,"EX",'P'
T_FN	= 0x80|48
	TOKEN	T_FN,"F",'N'
T_INT	= 0x80|49
	TOKEN	T_INT,"IN",'T'
T_LB	= 0x80|50
	TOKEN	T_LB,"L",'B'
T_LG	= 0x80|51
	TOKEN	T_LG,"L",'G'
T_LN	= 0x80|52
	TOKEN	T_LN,"L",'N'
T_NOT	= 0x80|53
	TOKEN	T_NOT,"NO",'T'
T_PI	= 0x80|54
	TOKEN	T_PI,"P",'I'
T_RND	= 0x80|55
	TOKEN	T_RND,"RN",'D'
T_SGN	= 0x80|56
	TOKEN	T_SGN,"SG",'N'
T_SIN	= 0x80|57
	TOKEN	T_SIN,"SI",'N'
T_SQR	= 0x80|58
	TOKEN	T_SQR,"SQ",'R'
T_TAN	= 0x80|59
	TOKEN	T_TAN,"TA",'N'
T_VAL	= 0x80|60
	TOKEN	T_VAL,"VA",'L'
T_ASC	= 0x80|61
	TOKEN	T_ASC,"AS",'C'
T_FREE	= 0x80|62
	TOKEN	T_FREE,"FRE",'E'
T_LEN	= 0x80|63
	TOKEN	T_LEN,"LE",'N'
T_POS	= 0x80|64
	TOKEN	T_POS,"PO",'S'
T_TOP	= 0x80|65
	TOKEN	T_TOP,"TO",'P'
T_STEP	= 0x80|66
	TOKEN	T_STEP,"STE",'P'
T_THEN	= 0x80|67
	TOKEN	T_THEN,"THE",'N'
T_TO	= 0x80|68
	TOKEN	T_TO,"T",'O'
T_CHR	= 0x80|69
	TOKEN	T_CHR,"CHR",'$'
T_LEFT	= 0x80|70
	TOKEN	T_LEFT,"LEFT",'$'
T_MID	= 0x80|71
	TOKEN	T_MID,"MID",'$'
T_RIGHT	= 0x80|72
	TOKEN	T_RIGHT,"RIGHT",'$'
T_SPC	= 0x80|73
	TOKEN	T_SPC,"SP",'C'
T_STR	= 0x80|74
	TOKEN	T_STR,"STR",'$'
T_TAB	= 0x80|75
	TOKEN	T_TAB,"TA",'B'
T_USING	= 0x80|76
	TOKEN	T_USING,"USIN",'G'
T_VER	= 0x80|77
	TOKEN	T_VER,"VER",'$'
T_VERT	= 0x80|78
	TOKEN	T_VERT,"VER",'T'
T_STAR	= 0x80|79
	TOKEN	T_STAR,"*",'*'
	DB	0


;*************************************
;*      I. L. TABLE PREAMBLE         *
;*************************************
;
ILTBL:	DO	GETLIN			; get next line of input
ILTB1:	TSTSTR	ILTB2,_CR		; if just a <cr>, do it again
	GOTO	ILTBL
ILTB2:	DO	SCANR			; scan and parse the line
	TSTNUM	ILSTRT			; do we have a line number?
	DO	POPAE		 	; yes, so handle that
	DO	FNDLBL
	DO	INSRT
	GOTO	ILTBL			; and do again

;*************************************
;*         I. L. LOOKUP TABLE        *
;*    FOR COMMANDS AND STATEMENTS    *
;*************************************
;
ILSTRT:	DO	NEXT			; find token or variable
	GOTO	AUTO			; handle AUTO
	DO	BYE			; handle BYE
	DO	CLEAR			; handle CLEAR
	IF USE_CASS
	 GOTO	CLOAD			; handle CLOAD
	 GOTO	CSAVE			; handle CSAVE
	ELSE
	 DO	IGNRE			; ignore CLOAD (not implemented)
	 DO	IGNRE			; ignore CSAVE (not implemented)
	ENDIF
	GOTO	EDIT			; handle EDIT
	GOTO	LIST			; handle LIST
	GOTO	NEW			; handle NEW
	GOTO	RUN			; handle RUN
	DO	VERS			; handle VERS
	DO	IGNRE			; ignore DATA (handled elsewhere)
	DO	IGNRE			; ignore DEF (handled elsewhere)
	GOTO	DIM			; handle DIM
	GOTO	DO			; handle DO
	DO	IGNORE			; ignore ELSE (handled elsewhere)
	DO	BRK			; handle END
	GOTO	FOR			; handle FOR
	GOTO	GOSUB			; handle GOSUB
	GOTO	GOTO			; handle GOTO
	GOTO	IF			; handle IF
	GOTO	INPUT			; handle INPUT
	GOTO	LINK			; handle LINK
	GOTO	NEXTG			; handle NEXT
	GOTO	ON			; handle ON
	GOTO	PAGE			; handle PAGE
	GOTO	POKE			; handle POKE
	GOTO	PRINT			; handle PRINT
	GOTO	PRINT			; handle PR
	GOTO	READ			; handle READ
	DO	IGNORE			; ignore REM (handled elsewhere)
	GOTO	RESTOR			; handle RESTORE
	GOTO	RETURN			; handle RETURN
	GOTO	STAT			; handle STAT
	GOTO	UNTIL			; handle UNTIL

;*************************************
;*         MAIN I. L. TABLE          *
;*************************************
; This part is a regular I.L. processor, where we check
; and process tokens as we parse them. Using the 'FAIL'
; argument, it creates a linked list of things to try.
;
	TSTVAR	PAGE0
	DO	FNDVAR
	DO	DEFVAR
	TSTSTR	DOLLAR,'('
	ILCALL	INDEX
LET:	TSTSTR	SYNTAX,'='		; check for implied 'LET'
	ILCALL	REXPR
	DO	STVAR
	DO	DNE
DOLLAR:	TSTSTR	LET,'$'			; test for var$, string expression
	DO	LDVAR
	DO	FIX
	TSTSTR	SYNTAX,'='
	ILCALL	STREXP
	DO	DNE
PAGE0:	TSTSTR	PRINT0,T_PAGE		; handle PAGE
PAGE:	TSTSTR	SYNTAX,'='
	ILCALL	REXPR
	DO	DONE
	DO	POPAE
	DO	NUPAGE
	DO	LKPAGE
	DO	NXT
ENDPAR:	DO	ENDPR			; complain about missing parenthesis
PRINT0:	TSTSTR	STAT0,'?'		; handle ? (short for PR[INT])
	GOTO	PRINT
STAT0:	TSTSTR	SYNTAX,T_STAT		; handle STAT
STAT:	TSTSTR	SYNTAX,'='
	ILCALL	REXPR
	DO	POPAE
	DO	MOVESR
SYNTAX:	DO	SYNTX			; complain about syntax error
LIST:	TSTNUM	LIST2			; handle LIST
	DO	POPAE
	TSTSTR	LIST4,'-'
	TSTNUM	SYNTAX
	DO	FNDLBL
	DO	POPAE
LIST1:	DO	LST1
	GOTO	LIST1
LIST2:	DO	CHPAGE
LIST3:	DO	LST2
	GOTO	LIST3
LIST4:	DO	FNDLBL
	DO	LST1
	DO	NXT
NEW:	TSTNUM	NEW1			; handle NEW
	DO	POPAE
	DO	NUPAGE
	GOTO	NEW2
NEW1:	DO	NUPGE1
NEW2:	DO	DONE
	DO	NEWPGM
	DO	NXT2
FOR:	DO	CKMODE			; handle FOR
	TSTVAR	SYNTAX
	DO	FNDVAR
	DO	DEFVAR
	TSTSTR	SYNTAX,'='
	ILCALL	REXPR
	TSTSTR	SYNTAX,T_TO		; handle TO
	ILCALL	REXPR
	TSTSTR	FOR1,T_STEP		; handle STEP
	ILCALL	REXPR
	GOTO	FOR2
FOR1:	DO	ONE
FOR2:	DO	DONE
	DO	SAVFOR
	DO	NXT
NEXTG:	DO	CKMODE			; handle NEXT
	TSTVAR	SYNTAX
	DO	FNDVAR
	DO	NXTVAR
	DO	FADD
	DO	NXTV
	DO	DETPGE
RUN:	DO	DONE			; handle RUN
	DO	CHPAGE
	DO	STRT
RUN1:	DO	NXT1
READ:	DO	CKMODE			; handle READ
	DO	LDDTA
READ1:	DO	NXTDTA
	DO	XCHPNT
	TSTVAR	LIST
	DO	FNDVAR
	DO	DEFVAR
	TSTSTR	READ5,'('
	ILCALL	INDEX
READ2:	DO	XCHPNT
	TSTSTR	READ3,'-'
	TSTNUM	READ9
	ILCALL	RNUM
	ILCALL	NEG
	DO	STVAR
	GOTO	READ7
READ3:	TSTSTR	READ4,'+'
READ4:	TSTNUM	READ9
	ILCALL	RNUM
	DO	STVAR
	GOTO	READ7
READ5:	TSTSTR	READ2,'$'
	DO	LDVAR
	DO	POPAE
	DO	XCHPNT
	TSTSTR	READ6,'"'
	DO	PUTSTR
	GOTO	READ7
READ6:	DO	INSTR
READ7:	DO	XCHPNT
	TSTSTR	READ8,','
	DO	XCHPNT
	GOTO	READ1
READ8:	DO	LDPNT
	DO	DNE
READ9:	DO	SNTX
RESTOR:	DO	CKMODE			; handle RESTORE
	DO	FNDDTA
	TSTNUM	RESTR1
	DO	POPAE
	DO	FNDLBL
	DO	XCHPNT
RESTR1:	DO	LDPNT
	DO	DNE
INPUT:	DO	CKMODE			; handle INPUT
	TSTSTR	INPUT1,'"'
	DO	PRSTR
INPUT1:	TSTVAR	SYNTAX
	DO	FNDVAR
	DO	DEFVAR
	TSTSTR	INPUT3,'$'
	DO	LDVAR
	DO	POPAE
	DO	GETLIN
	DO	ISTRNG
INPUT2:	DO	DNE
INPUT3:	DO	GETLIN
INPUT4:	DO	XCHPNT
	TSTSTR	INPUT5,'('
	ILCALL	INDEX
INPUT5:	DO	XCHPNT
	ILCALL	REXPR
	DO	STVAR
	DO	XCHPNT
	TSTSTR	INPUT2,','
	TSTVAR	SYNTAX
	DO	FNDVAR
	DO	DEFVAR
	DO	XCHPNT
	TSTSTR	SYNTAX,','
	GOTO	INPUT4
DO:	DO	CKMODE			; handle DO
	DO	DONE
	DO	SAVEDO
UNTIL:	DO	CKMODE			; handle UNTIL
	ILCALL	RELSTR
	DO	DONE
	DO	UNTL
LINK:	ILCALL	REXPR			; handle LINK
	DO	POPAE
	DO	DONE
	DO	XCHPNT
	DO	MC			; execute machine code
	DO	XCHPNT
	DO	NXT
ON:	ILCALL	REXPR			; handle ON..
	DO	POPAE
	TSTSTR	ON1,T_GOSUB		; ..GOSUB
	ILCALL	REXPR
	DO	GTO
	GOTO	GOSUB1
ON1:	TSTSTR	SYNTAX,T_GOTO		; ..GOTO
	ILCALL	REXPR
	DO	GTO
	GOTO	GOTO1
GOTO:	ILCALL	REXPR			; handle GOTO
	DO	DONE
	GOTO	GOTO1
GOSUB:	ILCALL	REXPR			; handle GOSUB
	DO	DONE
GOSUB1:	DO	SAV
GOTO1:	DO	POPAE
	DO	FNDLBL
	DO	XFER
RETURN:	DO	DONE			; handle RETURN
	DO	RSTR
EDIT:	TSTNUM	SYNTAX			; handle EDIT
	DO	POPAE
	DO	FNDLBL
	DO	EDITR
	DO	INPT
	GOTO	ILTB1
AUTO:	TSTNUM	SYNTAX			; handle AUTO
	DO	POPAE
	TSTSTR	AUTO1,','
	DO	NUMTST
	GOTO	AUTO2
AUTO1:	DO	TEN
AUTO2:	DO	AUTONM
	DO	GETLN1
	DO	SCANR
	TSTNUM	AUTO3
	DO	POPAE
AUTO3:	DO	FNDLBL
	DO	INSRT
	DO	AUTON
	GOTO	AUTO2
IF:	ILCALL	RELSTR			; handle IF
	DO	CMPRE
	TSTNUM	RUN1
	DO	POPAE
	DO	FNDLBL
	DO	XFER
POKE:	ILCALL	REXPR			; handle POKE
	DO	FIX
	TSTSTR	SYNTAX,','
	ILCALL	REXPR
	DO	FIX
	DO	PUTBYT
	DO	DNE
DIM:	TSTVAR	SYNTAX			; handle DIM
	DO	FNDVAR
	DO	LODVAR
	DO	FIX
	DO	STFLD
	ILCALL	REXPR
	DO	FIX
	DO	DIMSN
	TSTSTR	ENDPAR,')'
	TSTSTR	INPUT2,','
	GOTO	DIM
NEG:	DO	STACK
	DO	FNEG
	DO	STBCK


; Handle the PRINT commands.
;
; We use PREXP for both USING/formatted and unformatted printing. 
; Since we moved the number printing out of the ILCALL procedure,
; it is now called every time the loop is executed. So number
; printing only takes place IF a number is found on the STACK. 
;
PRINT:	TSTSTR	PRNT2,T_USING		; handle PR[INT] and USING
	TSTSTR	SYNTAX,'"'		; do we have a literal?
	DO	USING			; yes, handle format for USING
PRNT1:	ILCALL	PREXP			; handle the expression
	DO	USING2			; format the result
	TSTSTR	PRNT6,','		; test if next is comma
	GOTO	PRNT1			; yes, do again
PRNT2:	TSTSTR	PRNT3,':'		; test if next is colon
	GOTO	PRNT4			; yes, all done
PRNT3:	TSTSTR	PRNT5,_CR		; test if next is <cr>
PRNT4:	DO	LINE			; print newline
	DO	NXT			; end of statement
PRNT5:	ILCALL	PREXP			; handle the expression
	DO	PRFNUM			; print the result
	TSTSTR	PRNT6,','		; test if next is comma
	GOTO	PRNT5			; yes, do again
PRNT6:	TSTSTR	PRNT7,';'		; test if semicolon
	DO	DNE			; yes, done
PRNT7:	DO	LINE			; print newline
	DO	DNE			; done
	ILRTRN				; return

; PRINT USING routine (part 3.)
USING3:	LD	@-1(P1)			; decr P1 and load prev program byte
	XRI	'.'			; is it <dot> ?
	JZ	USING3
	LD	@1(P1)			; get byte from program and increase
	XRI	'E'			; is it 'E' ?
	JZ	USNG31
	LD	-1(P1)
	JNZ	USNG32			; jump if not terminated by <null>
USNG31:	LDI	'0'
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	DLD	COUNTR(P2)
	JNZ	USNG31
	JMP	SV_RTRN(P3)
USNG32:	LD	@-1(P1)
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	DLD	COUNTR(P2)
	JNZ	USING3
	JMP	SV_RTRN(P3)

; Handle expression to print.
PREXP:	TSTSTR	PREX1,'"'		; do we have a literal?
	DO	PRSTRG			; yes, print it
PREX1:	TSTSTR	PREX2,T_CHR		; handle CHR$(x)
	ILCALL	SNGL
	DO	POPAE
	DO	PRCHAR
PREX2:	TSTSTR	PREX3,T_SPC		; handle SPC(x)
	ILCALL	SNGL
	DO	POPAE
	DO	SPC
PREX3:	TSTSTR	PREX4,T_STR		; handle STR$(x)
	ILCALL	SNGL
	GOTO	PREX10
PREX4:	TSTSTR	PREX5,T_TAB		; handle TAB(x)
	ILCALL	SNGL
	DO	POPAE
	DO	TAB
PREX5:	TSTSTR	PREX6,T_VER		; handle VER$
	DO	VSTRNG
PREX6:	TSTSTR	PREX7,T_VERT		; handle VERT(x)
	ILCALL	SNGL
	DO	POPAE
	DO	VERT
PREX7:	DO	STRPNT
	TSTVAR	PREX9
	DO	FNDVAR
	DO	POPDLR
	TSTSTR	PREX8,'$'
	DO	LDVAR
	DO	POPAE
	DO	PSTRNG
PREX8:	DO	XCHPNT
PREX9:	ILCALL	REXPR			; handle numeric expression
PREX10:	DO	STACK
	DO	FNUM
	DO	STPBCK
	ILRTRN

; Handle string expressions
STREXP:	ILCALL	STRF
STREX1:	TSTSTR	STREX2,'&'
	ILCALL	STRF
	GOTO	STREX1
STREX2:	DO	POPSTR
STRF:	TSTSTR	STRF1,'"'
	DO	PUTST
STRF1:	TSTSTR	STRF2,T_CHR		; handle CHR$(x)
	ILCALL	SNGL
	DO	FIX
	DO	CHRSTR
STRF2:	TSTSTR	STRF4,T_LEFT		; handle LEFT$(x$,y)
	TSTSTR	SYNTAX,'('
	TSTSTR	STRF3,'"'
	DO	STPNT
	TSTSTR	SYNTAX,','
	ILCALL	REXPR
	DO	FIX
	TSTSTR	ENDPAR,')'
	DO	XCHPNT
	DO	LEFTST
STRF3:	TSTVAR	SYNTAX
	DO	FNDVAR
	DO	DEFVAR
	TSTSTR	SYNTAX,'$'
	DO	LDVAR
	DO	FIX
	TSTSTR	SYNTAX,','
	ILCALL	REXPR
	DO	FIX
	TSTSTR	ENDPAR,')'
	DO	LFTSTR
STRF4:	TSTSTR	STRF6,T_MID		; handle MID$(x$,y,z)
	TSTSTR	SYNTAX,'('
	TSTSTR	STRF5,'"'
	DO	STPNT
	TSTSTR	SYNTAX,','
	ILCALL	REXPR
	DO	FIX
	TSTSTR	SYNTAX,','
	ILCALL	REXPR
	DO	FIX
	TSTSTR	ENDPAR,')'
	DO	XCHPNT
	DO	MIDST
STRF5:	TSTVAR	SYNTAX
	DO	FNDVAR
	DO	DEFVAR
	TSTSTR	SYNTAX,'$'
	DO	LDVAR
	DO	FIX
	TSTSTR	SYNTAX,','
	ILCALL	REXPR
	DO	FIX
	TSTSTR	SYNTAX,','
	ILCALL	REXPR
	DO	FIX
	TSTSTR	ENDPAR,')'
	DO	MIDSTR
STRF6:	TSTSTR	STRF8,T_RIGHT		; handle RIGHT$(x$,y)
	TSTSTR	SYNTAX,'('
	TSTSTR	STRF7,'"'
	DO	STPNT
	TSTSTR	SYNTAX,','
	ILCALL	REXPR
	DO	FIX
	TSTSTR	ENDPAR,')'
	DO	XCHPNT
	DO	RGHTST
STRF7:	TSTVAR	SYNTAX
	DO	FNDVAR
	DO	DEFVAR
	TSTSTR	SYNTAX,'$'
	DO	LDVAR
	DO	FIX
	TSTSTR	SYNTAX,','
	ILCALL	REXPR
	DO	FIX
	TSTSTR	ENDPAR,')'
	DO	RGHSTR
STRF8:	TSTSTR	STRF9,T_STR		; handle STR$(x)
	ILCALL	SNGL
	DO	STACK
	DO	FNUM
	DO	FSTRNG
	DO	STBCK
STRF9:	TSTSTR	STRF10,T_VER		; handle VER$
	DO	LDVER
	DO	MOVSTR
STRF10:	TSTVAR	SYNTAX			; test for variable
	DO	FNDVAR
	DO	DEFVAR
	TSTSTR	SYNTAX,'$'
	DO	LDVAR
	DO	FIX
	DO	MOVSTR
RELSTR:	DO	STRPNT
	TSTVAR	RELEXP
	DO	FNDVAR
	DO	POPDLR
	TSTSTR	RELXPR,'$'
	DO	LDVAR
	DO	FIX
	TSTSTR	SYNTAX,'='
	TSTSTR	RESTR,'"'
	DO	CMPRST
RESTR:	TSTVAR	SYNTAX
	DO	FNDVAR
	DO	DEFVAR
	TSTSTR	SYNTAX,'$'
	DO	LDVAR
	DO	FIX
	DO	CMPSTR
RELXPR:	DO	XCHPNT
RELEXP:	ILCALL	REXPR
	TSTSTR	REL1,'='
	ILCALL	REXPR
	DO	EQU
REL1:	TSTSTR	REL2,T_NE		; handle <>
	ILCALL	REXPR
	DO	NEQ
REL2:	TSTSTR	REL3,'<'		; handle <
	ILCALL	REXPR
	DO	LSS
REL3:	TSTSTR	REL4,T_LE		; handle <=
	ILCALL	REXPR
	DO	LEQ
REL4:	TSTSTR	REL5,'>'		; handle >
	ILCALL	REXPR
	DO	GTR
REL5:	TSTSTR	RTRN,T_GE		; handle >=
	ILCALL	REXPR
	DO	GEQ
REXPR:	TSTSTR	REX1,'-'		; handle - (subtraction)
	ILCALL	RTERM
	DO	STACK
	DO	FNEG
	DO	STBACK
	GOTO	REX3
REX1:	TSTSTR	REX2,'+'
REX2:	ILCALL	RTERM
REX3:	TSTSTR	REX4,'-'
	ILCALL	RTERM
	DO	STACK
	DO	FSUB
	DO	STBACK
	GOTO	REX3
REX4:	TSTSTR	REX5,'+'		; handle + (addition)
	ILCALL	RTERM
	DO	STACK
	DO	FADD
	DO	STBACK
	GOTO	REX3
REX5:	TSTSTR	REX6,T_EXOR		; handle ^ (EXOR)
	ILCALL	RTERM
	DO	STACK
	DO	ALGEXP
	DO	EXOR
	DO	STBACK
	GOTO	REX3
REX6:	TSTSTR	RTRN,T_OR		; handle | (OR)
	ILCALL	RTERM
	DO	STACK
	DO	ALGEXP
	DO	OR
	DO	STBACK
	GOTO	REX3

; Evaluate expression with two terms
RTERM:	ILCALL	REXPN
RT1:	TSTSTR	RT2,'*'			; handle * (multiplication)
	ILCALL	REXPN
	DO	STACK
	DO	FMUL
	DO	STBACK
	GOTO	RT1
RT2:	TSTSTR	RT3,'/'			; handle / (division)
	ILCALL	REXPN
	DO	STACK
	DO	FDIV
	DO	STBACK
	GOTO	RT1
RT3:	TSTSTR	RT4,T_AND		; handle & (AND)
	ILCALL	REXPN
	DO	STACK
	DO	ALGEXP
	DO	AND
	DO	STBACK
	GOTO	RT1
RT4:	TSTSTR	RT5,T_DIV		; handle // (DIV)
	ILCALL	REXPN
	DO	STACK
	DO	FDIV
	DO	INT
	DO	STBACK
	GOTO	RT1
RT5:	TSTSTR	RTRN,T_MOD		; handle % (MOD)
	ILCALL	REXPN
	DO	STACK
	DO	FMOD
	DO	PSHSWP
	DO	FMUL
	DO	STBACK
	GOTO	RT1

REXPN:	ILCALL	RFACTR
REXPN1:	TSTSTR	RTRN,'^'		; handle exponentiation
	ILCALL	RFACTR
	DO	STACK
	DO	SWAP
	DO	LOG2
	DO	FMUL
	DO	EXP2
	DO	STBACK
	GOTO	REXPN1

SNGL:	TSTSTR	SYNTAX,'('
	ILCALL	REXPR
	TSTSTR	ENDPAR,')'
RTRN:	ILRTRN

; NOTE:	Handle floating point numbers	
RFACTR:	TSTNUM	RF1			; number before decimal point
RNUM:	TSTSTR	RNUM1,'.'		; decimal point
	TSTNUM	RNUM1			; number after decimal point
	DO	STACK
	DO	FD10			; transform fractional part into binary..
	DO	FADD			; ..and add to integer part
	DO	STBACK
RNUM1:	TSTSTR	RTRN,'E'		; look for an exponent part
	TSTSTR	RNUM2,'-'
	DO	NUMTST
	DO	FDIV11
RNUM2:	TSTSTR	RNUM3,'+'
RNUM3:	DO	NUMTST
	DO	FMUL11
RF1:	TSTVAR	RF2
	DO	FNDVAR
	ILCALL	RINDEX
	DO	LDVAR
	ILRTRN

RF2:	TSTSTR	RF3,'('
	ILCALL	RELSTR
	TSTSTR	ENDPAR,')'
	ILRTRN

RF3:	TSTSTR	RF4,T_ABS		; handle ABS(x)
	ILCALL	SNGL
	DO	STACK
	DO	FABS
	DO	STBCK
RF4:	TSTSTR	RF5,T_ATN		; handle ATN(x)
	ILCALL	SNGL
	DO	STACK
	DO	ATN
	DO	STBCK
RF5:	TSTSTR	RF6,T_COS		; handle COS(x)
	ILCALL	SNGL
	DO	STACK
	DO	PI2
	DO	FADD
	DO	SIN
	DO	STBCK
RF6:	TSTSTR	RF7,T_EXP		; handle EXP(x)
	ILCALL	SNGL
	DO	STACK
	DO	LN2
	DO	FDIV
	DO	EXP2
	DO	STBCK
RF7:	TSTSTR	RF8,T_FN		; handle FN
	TSTVAR	SYNTAX
	DO	FNDDEF
	TSTSTR	FN6,'('
	DO	XCHPNT
	TSTSTR	SYNTAX,'('
FN1:	DO	XCHPNT
	TSTVAR	FN7
	DO	FNDVAR
	DO	DEFVAR
	TSTSTR	FN4,'('
	ILCALL	INDEX
FN2:	DO	XCHPNT
	ILCALL	REXPR
	DO	STVAR
FN3:	DO	XCHPNT
	TSTSTR	FN5,','
	DO	XCHPNT
	TSTSTR	SYNTAX,','
	GOTO	FN1
FN4:	TSTSTR	FN2,'$'
	DO	LDVAR
	DO	FIX
	DO	XCHPNT
	ILCALL	STREXP
	GOTO	FN3
FN5:	DO	XCHPNT
	TSTSTR	ENDPAR,')'
	DO	XCHPNT
	TSTSTR	FN7,')'
FN6:	TSTSTR	FN7,'='
	DO	FNT
	ILCALL	REXPR
	DO	FNDNE
FN7:	DO	FNERR
RF8:	TSTSTR	RF9,T_INT		; handle INT(x)
	ILCALL	SNGL
	DO	STACK
	DO	INT
	DO	STBCK
RF9:	TSTSTR	RF10,T_LB		; handle LB(x)
	ILCALL	SNGL
	DO	STACK
	DO	LOG2
	DO	STBCK
RF10:	TSTSTR	RF11,T_LG		; handle LG(x)
	ILCALL	SNGL
	DO	STACK
	DO	LOG2
	DO	LG2
	DO	FMUL
	DO	STBCK
RF11:	TSTSTR	RF12,T_LN		; handle LN(x)
	ILCALL	SNGL
	DO	STACK
	DO	LOG2
	DO	LN2
	DO	FMUL
	DO	STBCK
RF12:	TSTSTR	RF13,T_NOT		; handle ! (not)
	ILCALL	RFACTR
	DO	STACK
	DO	NOT
	DO	STBCK
RF13:	TSTSTR	RF14,T_PI
	DO	PI
RF14:	TSTSTR	RF15,T_RND		; handle RND(x)
	DO	STACK
	DO	RND
	DO	NORM
	DO	STBCK
RF15:	TSTSTR	RF16,T_SGN		; handle SGN(x)
	ILCALL	SNGL
	DO	SGN
RF16:	TSTSTR	RF17,T_SIN		; handle SIN(x)
	ILCALL	SNGL
	DO	STACK
	DO	SIN
	DO	STBCK
RF17:	TSTSTR	RF18,T_SQR		; handle SQR(x)
	ILCALL	SNGL
	DO	STACK
	DO	SQRT
	DO	STBCK
RF18:	TSTSTR	RF19,T_TAN		; handle TAN(x)
	ILCALL	SNGL
	DO	STACK
	DO	TAN
	DO	SWAP
	DO	PI2
	DO	FADD
	DO	SIN
	DO	FDIV
	DO	STBCK
RF19:	TSTSTR	RF21,T_VAL		; handle VAL(x$)
	TSTSTR	SYNTAX,'('
	TSTVAR	SYNTAX
	DO	FNDVAR
	DO	CKDLLR
	DO	LDVAR
	DO	FIX
	DO	VALSTR
	TSTSTR	RF20,'-'
	TSTNUM	SYNTAX
	ILCALL	RNUM
	ILCALL	NEG
	DO	XCHPNT
	ILRTRN
RF20:	TSTNUM	SYNTAX
	ILCALL	RNUM
	DO	XCHPNT
	ILRTRN

RF21:	ILCALL	FACTOR
	DO	FLOAT2
FACTOR:	TSTSTR	FCTR1,'#'
	DO	HEX
FCTR1:	TSTSTR	FCTR3,T_ASC		; handle ASC(str)..
	TSTSTR	SYNTAX,'('
	TSTSTR	FCTR2,'"'
	DO	ASC			; ..for quoted string
FCTR2:	TSTVAR	SYNTAX
	DO	FNDVAR
	DO	CKDLLR
	DO	LDVAR
	DO	FIX
	DO	ASTRNG			; ..for string variable
FCTR3:	TSTSTR	FCTR4,T_FREE		; handle FREE
	DO	TOP
	DO	FREE
FCTR4:	TSTSTR	FCTR6,T_LEN		; handle LEN(x)..
	TSTSTR	SYNTAX,'('
	TSTSTR	FCTR5,'"'
	DO	LEN			; ..for quoted string
FCTR5:	TSTVAR	SYNTAX
	DO	FNDVAR
	DO	CKDLLR
	DO	LDVAR
	DO	FIX
	DO	LSTRNG			; ..for string variable
FCTR6:	TSTSTR	FCTR7,T_PAGE		; handle PAGE
	DO	PGE
FCTR7:	TSTSTR	FCTR8,T_PEEK		; handle PEEK(x)
	ILCALL	SNGL
	DO	FIX
	DO	GETBYT
; FIXME: Keyword POS is not implemented,
;	the whole block until FCTR10 is not functional.
FCTR8:	TSTSTR	FCTR10,T_POS		; handle POS(x$)
	TSTSTR	SYNTAX,'('
	TSTSTR	FCTR9,'"'
	GOTO	SYNTAX
	TSTVAR	SYNTAX
	DO	FNDVAR
	DO	CKDLLR
	DO	LDVAR
	DO	FIX
	GOTO	SYNTAX
FCTR9:	TSTVAR	SYNTAX
	DO	FNDVAR
	DO	CKDLLR
	DO	LDVAR
	DO	FIX
	GOTO	SYNTAX
; FIXME: Is there really a way to these statements?
;;FIXME: I dont think so, since previous is a hard GOTO.
	IF 0
	 TSTVAR	SYNTAX
	 DO	FNDVAR
	 DO	CKDLLR
	 DO	LDVAR
	 DO	FIX
	 GOTO	SYNTAX
	ENDIF
FCTR10:	TSTSTR	FCTR11,T_STAT		; handle STAT
	DO	STATUS
FCTR11:	TSTSTR	SYNTAX,T_TOP		; handle TOP
	DO	TOP
	ILRTRN

RINDEX:	DO	CKPT
INDEX:	DO	LADVAR
	ILCALL	REXPR
	DO	FIX
	DO	DMNSN

	IF USE_CASS
;*******************************
;*  WRITE PROGRAM TO CASSETTE  *
;*******************************
;
CSAVE:	DO	BOT			; determine start of program
	DO	TOP			; determine top of program
	DO	CSAVE2			; do the actual saving
	DO	CFINI			; finish up


;********************************
;*  LOAD PROGRAM FROM CASSETTE  *
;********************************
;
CLOAD:	DO	CLOAD2			; do the actual loading
	DO	CFINI			; finish up
	ENDIF


;*************************************
;*  PAGE BREAK - SECOND BLOCK OF 4K  *
;*************************************
;
	ORG	BASE+0x1000
	NOP				; needed so Supervisor can do -1 here

; Read line from input and store in program storage.
GETLIN:	LD	BASMODE(P2)		; load command/run flag
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	JP	GETLN1
	LDI	' '			; load space character
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
GETLN1:	LDI	L(STKIBUF)		; set P1.L to start of input buffer
	XPAL	P1
	ST	-15(P2)			; save prev P1.L
	LD	STKPHI(P3)
	ORI	H(STKIBUF)		; offset for STKBASE.H
	XPAH	P1			; set P1.H to start of input buffer
	ST	-16(P2)			; save prev P1.H
	LD	(P2)			; load max. input buffer length
	ST	CHRNUM(P2)		; store as character counter
	XAE
	LDI	_CR			; load <cr>
	ST	EREG(P1)		; store as last char in input buffer
	DLD	CHRNUM(P2)
GETLN2:	XAE				; put counter in E and use as index
	LDI	0xFF			; load as empty-marker (nothing here)
	ST	EREG(P1)		; fill input buffer with empty-marker
	DLD	CHRNUM(P2)		; decrease char counter
	JNZ	GETLN2
; NOTE: Read character goes into AC and E
INPT:
	IFDEF	SCALLS
	 SYSCALL	1
	ELSE
	 CALL	GETASC
	ENDIF
	LD	CHRNUM(P2)		; load line counter
	XAE				; into E
	ST	-1(P1)			; temporary store char before line buffer
	ANI	0x60			; test for control character
	JZ	CTRLS			; go, handle control chars
INCR:	LD	-1(P1)			; load character from temp
	ST	EREG(P1)		; and store in input buffer
OUTCH:	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	ILD	CHRNUM(P2)
	XOR	(P2)			; max chars (72) reached ?
	JZ	SV_LINE(P3)		; return and print newline
	JMP	INPT
; NOTE:	The following handles two control characters, the rest is handled externally.
;	Control/M = <cr>	Carriage Return / Enter
;	Control/R = <dc2>	Move cursor one to the ^Right
CTRLS:	LD	-1(P1)			; actual cursor is in E
	XRI	_CR			; is it <cr> ?
	JZ	CTRL1
	XRI	_CR ! _CTLR		; we XOR'ed above, is it <control-r> ?
	JZ	CTRL4
	CALL	HCTRLS			; go handle some more controls
	JMP	INPT
; NOTE:	Carriage Return / Enter
CTRL1:	LDI	_CR			; finish line with <cr>
	ST	EREG(P1)		; store <cr> E indexed behind last character
	JMP	SV_LINE(P3)		; return and print newline
; Move cursor one to ^Right.
CTRL4:	LD	EREG(P1)		; load char under cursor
	XRI	0xFF			; is here an empty-marker ?
	JZ	INPT			; yes, do not move cursor
	LD	EREG(P1)		; load next charactor right
	JMP	OUTCH

;*************************************
;*      CALLS FROM GETLIN ROUTINE    *
;* (HANDLING OF CONTROL CHARACTERS)  *
;*************************************
;
; NOTE:	The following handles some control characters, all others are ignored.
;	Control/H = <bs>	delete char and move cursor one to left
; ???	Control/I = <ht>	cursor pos one to right
;	Control/K = <vt>	^Kill, rubout char at cursor pos	
;	Control/L = <ff>	cursor pos one to the ^Left
;	Control/O = <si>	m^Ove right and insert char at cursor pos
;	Control/R = <dc2>	cursor pos one to the ^Right
;	Control/X = <can>	e^Xit, cancel input and start anew
HCTRLS:	LD	CHRNUM(P2)
	XAE				; store actual cursor pos in E
	LD	-1(P1)
	XRI	_BS			; is it <backspace> ?
	JZ	CTRL2
	XRI	_BS ! _CTLL		; we XOR'ed above, is it <ctrl-L> ?
	JZ	CTRL3
	XRI	_CTLL ! _CTLK		; we XOR'ed above, is it <ctrl-K> ?
	JZ	CTRL5
	XRI	_CTLK ! _CTLO		; we XOR'ed above, is it <ctrl-O> ?
	JZ	CTRL6
	XRI	_CTLO ! _CTLX		; we XOR'ed above, is it <ctrl-X> ?
	JZ	CTRL7
	RTRN				; ignore other control chars and return

; ^H Delete char and move cursor one to the left.
CTRL2:	LDE
	JZ	SV_RTRN(P3)		; do nothing, is begin of buffer
	DLD	CHRNUM(P2)
	XAE
	LDI	0xFF
	ST	EREG(P1)		; store empty-marker
	LDI	_BS
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	LDI	' '
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	JMP	BACK

; ^L Move cursor one to left.
CTRL3:	LDE
	JZ	SV_RTRN(P3)		; do nothing, is begin of buffer
	DLD	CHRNUM(P2)
	JMP	BACK

; ^K Rubout character under cursor.
CTRL5:	LD	@EREG(P1)		; set pointer P1 to current char
SHFTL:	LD	1(P1)			; get next char
	XRI	0xFF			; is here an empty-marker ?
	JZ	RUBEND
	LD	1(P1)
	ST	@1(P1)			; store char one position left and incr
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	ILD	CHRNUM(P2)
	JMP	SHFTL
RUBEND:	LDI	0xFF			; set new empty-marker
	ST	(P1)
	LDI	L(STKIBUF)		; set P1.L back to start of input buffer
	XPAL	P1
	LDI	' '
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
BACK:	LDI	_BS
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	RTRN

; ^O Insert character under cursor.
CTRL6:	LD	(P2)			; load input buffer length (max. chars)
	XAE
	LD	@EREG(P1)		; set pointer P1 to end of input buffer
	LD	@-1(P1)			; ultimate position in buffer
	XRI	0xFF			; is here an empty-marker ?
	JNZ	NOMSPC			; no more space for insertion
	SCL
	LDE				; max. number
	CAD	CHRNUM(P2)		; subtract actual number
	ST	-22(P2)			; store as temporary counter		
SHFTR:	LD	@-1(P1)			; decrease and get character
	ST	1(P1)			; store one position right
	DLD	-22(P2)
	JNZ	SHFTR
	LDI	L(STKIBUF)		; set P1.L back to start of input buffer
	XPAL	P1
	LD	CHRNUM(P2)
	XAE
	LDI	' '
	ST	EREG(P1)
BUFOUT:	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	ILD	CHRNUM(P2)
	XAE
	LD	EREG(P1)
	XRI	_CR			; line terminator reached ?
	JZ	SV_LINE(P3)		; return and print newline
	XRI	_CR			; we XOR'ed above
	JP	BUFOUT
NOMSPC:	LDI	L(STKIBUF)		; set P1.L back to start of input buffer
	XPAL	P1
	RTRN

; ^X Cancel input and start new input.
CTRL7:	LDI	L(STKIBUF)		; set P1.L back to start of input buffer
	XPAL	P1
	LDI	'\\'
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	LDI	(M_BRK-M_BASE)		; 'BREAK'
	JMP	SV_MSGOUT(P3)

; Print new line as standalone routine.
LINE:	LDI	_CR
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	LDI	_LF
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	JMP	SV_RTRN(P3)

; Scan input buffer for BASIC keywords, convert to one-byte tokens and store.
SCAN:	SCL
	LD	@1(P1)			; get byte from input and increase
	CAI	'Z'+1
	JP	SCANR			; no beginning letter ?
	ADI	26			; 'Z'-'A'+1
	JP	SSCAN			; yes, found letter
	JMP	SCANR
	; NOTE:	A variable has at least a beginning letter, followed by
	;	letters and/or digits. All other characters terminate
	;	evaluating a variable.
SSCAN:	SCL
	LD	@1(P1)			; get byte from input and increase
	CAI	'Z'+1			; does another letter follow ?
	JP	SSCAN1
	ADI	26			; 'Z'-'A'+1
	JP	SSCAN			; yes, found letter
	ADI	7			; 'A'-'9'-1
	JP	SSCAN1			; no digit
	ADI	10			; '9'-'0'+1
	JP	SSCAN			; is digit
SSCAN1:	LD	@-1(P1)			; decr and load previous input byte
SCANR:	LD	@1(P1)			; get byte from input and increase
	XRI	' '			; is it <space> ?
	JZ	SCANR			; yes, just eat it
	LD	-1(P1)			; load last byte again
	XRI	':'			; is it <colon> ?
	JZ	SCAN3			; go, next statement on line
	XRI	':' ! _CR		; we XOR'ed above, is it <cr> ?
	JZ	SCAND			; go, return (end of line)
	XRI	_CR ! '"'		; we XOR'ed above, is it beginning <quote> ?
	JNZ	SCAN2			; no string literal
SCAN1:	LD	@1(P1)			; get byte from input and increase
	XRI	'"'			; look for terminating <quote>
	JZ	SCANR			; there is one, start new scanning
	XRI	'"' ! _CR		; we XOR'ed above, is it <cr> ?
	JNZ	SCAN1			; no, loop for terminating <quote>
	JMP	SCNRR			; no terminating <quote>, send error
SCAND:	LDI	L(SPRVSR)		; restore P3 to Supervisor
	XPAL	P3
	LD	-100(P2)
	XPAH	P3
	LDI	L(STKIBUF)		; load start of input buffer
	XPAL	P1			; put into P1.L
	JMP	SV_SPLOAD(P3)
SCAN2:	LD	@-1(P1)			; decr input buffer back and load byte 
SCAN3:	LDPI	P3,TOKENS		; load P3 with token table
SCAN4:	LD	@1(P3)			; get token from table, incr P3
	JZ	SCAN			; end of table
	ST	-24(P2)			; store token value
	LDI	0xFF			; initialize index
	ST	CHRNUM(P2)		; set index to -1 for beginning with 0
SCAN5:	ILD	CHRNUM(P2)		; increase index
	XAE				; load index into E
	LD	EREG(P1)		; get next byte from input buffer
	XOR	@1(P3)			; compare with char from table and incr
	JZ	SCAN5			; same, continue comparing
	XRI	0x80			; high bit set, end of word
	JZ	SCAN7			; yes, words are same
	JP	SCAN4			; not same, try next token
SCAN6:	LD	@1(P3)			; end of word, skip table word
	JP	SCAN6
	JMP	SCAN4			; and try next token
SCAN7:	LD	-24(P2)			; we have a token, load it
	ST	@1(P1)			; store into program line and increase
	XPAL	P1			; position of found token..
	ST	-24(P2)			; ..is now stored in -24
	XPAL	P1			; put again into P1.L
SCAN8:	LD	EREG(P1)		; load current byte from word
	ST	@1(P1)			; store into program and increase
	XRI	_CR			; is it a <cr> ?
	JNZ	SCAN8			; no, continue copying
	LD	-24(P2)			; yes, restore location from -24
	XPAL	P1
	LD	-1(P1)			; load previous byte from input
	XRI	T_DATA			; is it T_DATA ?
	JZ	SSKP1			; yes, skip stmt (but check strings)
	XRI	T_DATA ! T_REM		; we XOR'ed above, is it T_REM ?
	JZ	SCAND			; found REM, leave scan routine
	JMP	SCANR			; no DATA, no REM continue scanning
	; NOTE: Skip characters in line until end of statement
SSKP1:	LD	@1(P1)			; get byte from input and increase
	XRI	':'			; is it <colon> ?
	JZ	SCAN3			; go, look anew for token
 	XRI	':' ! _CR		; we XOR'ed above, is it <cr> ?
	JZ	SCAND			; go, leave scan routine
	XRI	_CR ! '"'		; we XOR'ed above, is it <quote> ?
	JNZ	SSKP1			; no, skip character
SSKP2:	LD	@1(P1)			; get byte from input and increase
	XRI	'"'			; is it <quote> ?
	JZ	SSKP1
	XRI	'"' ! _CR		; we XOR'ed above, is it <cr> ?
	JNZ	SSKP2
SCNRR:	LDI	L(SPRVSR)		; restore P3 to supervisor..
	XPAL	P3
	LD	-100(P2)
	XPAH	P3			; ..and perform error message
	LDI	(M_ENDQ-M_BASE)		; 'ENDQUOTE ERROR'
	JMP	SV_MSGOUT(P3)

; Free four bytes on arithmetics stack.
; Put two bytes into STACK -17, -18.
POPAE:	CCL
	LD	AEXOFF(P2)		; adjust AEXSTK by four up
	ADI	4
	ST	AEXOFF(P2)
	XPAL	P2			; pointer P2 holds corrected AEXSTK
	LDI	0
POP1:	XAE
POP2:	SCL
	ILD	-4(P2)
	JZ	SV_VALERR(P3)
	JP	POP4
	CAI	0x8F
	JZ	POP3
	LD	-3(P2)
	ADD	-3(P2)
	LD	-3(P2)
	RRL
	ST	-3(P2)
	LD	-2(P2)
	RRL
	ST	-2(P2)
	CSA
	JP	POP2
	JMP	POP1
POP3:	LDE
	AND	-3(P2)
	JP	POP5
	ILD	-2(P2)
	JNZ	POP5
	ILD	-3(P2)
	JMP	POP5
POP4:	LDI	0
	ST	-2(P2)
	ST	-3(P2)
POP5:	LD	-2(P2)
	XAE
	LD	AEXOFF(P2)
	XPAL	P2
	LDI	STKMID
	XPAL	P2
	ST	-18(P2)
	XAE
	ST	-17(P2)
	JMP	SV_SPLOAD(P3)

; Insert a program line into BASIC program storage on actual page,
; three cases are distinguished, move up, move down lines, add line.
INSRT:	LD	-17(P2)
	ST	NUMLO(P2)
	LD	-18(P2)
	ST	NUMHI(P2)
	LD	-15(P2)
	XPAL	P3
	LD	-16(P2)
	XPAH	P3
	LDI	3
	ST	CHRNUM(P2)
INS1:	ILD	CHRNUM(P2)
	LD	@1(P3)
	XRI	_CR
	JNZ	INS1
	LD	CHRNUM(P2)
	XRI	4
	JNZ	INS2
	ST	CHRNUM(P2)
INS2:	LD	CHRNUM(P2)
	XAE
	JNZ	MOVE
	LD	@3(P1)
	LDE
	CCL
	ADI	0xFC
	XAE
INS3:	LD	@1(P1)			; get byte from program and increase
	XRI	_CR
	JZ	MOVE
	LDE
	CCL
	ADI	0xFF
	XAE
	JMP	INS3
MOVE:	LDE
	OR	CHRNUM(P2)
	JZ	ADD1
	LDE
	JZ	ADD
	JP	UP
DOWN:	LD	(P1)
	ST	EREG(P1)
	LD	@1(P1)			; get byte from program and increase
	XRI	0xFF
	JNZ	DOWN
	LD	(P1)
	XRI	0xFF
	JNZ	DOWN
	XRI	0xFF
	ST	EREG(P1)
	JMP	ADD
UP:	LD	-2(P1)
	ST	-22(P2)
	LDI	0xFF
	ST	-2(P1)
	LDI	0x55
	ST	-1(P1)
UP1:	LD	@1(P1)			; get byte from program and increase
	XRI	0xFF			; is it first terminating X'FF of program area ?
	JNZ	UP1			; no, continue
	LD	(P1)			; get actual byte
	XRI	0xFF			; is it second terminating X'FF of program area ?
	JNZ	UP1			; no, continue
	XPAH	P1			; yes, we are done
	ST	-18(P2)
	XPAH	P1
	XPAL	P1
	ST	-17(P2)
	XPAL	P1
	CCL
	LD	-17(P2)
	ADE
	LDI	0
	ADD	-18(P2)
	XOR	-18(P2)
	ANI	0xF0
	JZ	UP2
	LDI	0
	XAE
UP2:	LD	(P1)
	ST	EREG(P1)
	LD	@-1(P1)
	XRI	0xFF
	JNZ	UP2
	LD	1(P1)
	XRI	0x55
	JNZ	UP2
	LD	-22(P2)
	ST	(P1)
	LDI	_CR
	ST	1(P1)
	LDE
	JZ	ADD4
ADD:	LD	CHRNUM(P2)
ADD1:	JZ	ADD3
	LD	-15(P2)
	XPAL	P1
	LD	-16(P2)
	XPAH	P1
	LD	-13(P2)
	XPAL	P3
	LD	-14(P2)
	XPAH	P3
	LD	NUMHI(P2)
	ST	@1(P3)
	LD	NUMLO(P2)
	ST	@1(P3)
	LD	CHRNUM(P2)
	ST	@1(P3)
ADD2:	LD	@1(P1)			; get byte from program and increase
	ST	@1(P3)			; store in new location
	XRI	_CR			; is it terminating <cr> ?
	JNZ	ADD2			; no, continue
ADD3:	XPAH	P3
ADD4:	LDI	L(SPRVSR)		; restore P3 to Supervisor
	XPAL	P3
	LD	-100(P2)
	XPAH	P3
	JZ	SV_SPLOAD(P3)
	LDI	(M_AREA-M_BASE)		; 'AREA ERROR' (program area too small)
	JMP	SV_MSGOUT(P3)

; Find a variable in storage.
; NOTE:	Storage for variables begins at STKBASE+0x0100 and ends at STKBASE+0x03B4
FNDVAR:	LD	STKPHI(P3)		; get stack address.H
	ORI	H(VARSBUF)		; start of variables storage high
	XPAH	P3
	LDI	0
	XPAL	P3			; P3 holds begin of variables storage
FNDV0:	LD	@1(P3)			; load byte of variable storage and incr
	JZ	FNDV9			; zero means end of variable storage
	JP	FNDV1
	XRE
	JZ	FNDV8
	LD	@4(P3)
	JMP	FNDV0
FNDV1:	XRE
	JNZ	FNDV5
	XPAL	P1
	ST	-24(P2)
	XPAL	P1
	XPAH	P1
	ST	CHRNUM(P2)
	XPAH	P1
FNDV2:	LD	@1(P3)
	XOR	@1(P1)
	JZ	FNDV2
	JP	FNDV4
	XRI	0x80
	JZ	FNDV6
FNDV3:	LD	-24(P2)
	XPAL	P1
	LD	CHRNUM(P2)
	XPAH	P1
	LD	@4(P3)
	JMP	FNDV0
FNDV4:	LD	-24(P2)
	XPAL	P1
	LD	CHRNUM(P2)
	XPAH	P1
FNDV5:	LD	@1(P3)
	JP	FNDV5
	LD	@4(P3)
	JMP	FNDV0
FNDV6:	SCL
	LD	(P1)			; load current storage byte
	CAI	'Z'+1
	JP	FNDV7			; no beginning letter
	ADI	26			; 'Z'-'A'+1
	JP	FNDV3			; found letter
	ADI	7			; 'A'-'9'-1
	JP	FNDV7			; no digit
	ADI	10			; '9'-'0'+1
	JP	FNDV3			; is digit
FNDV7:	LDI	0			; zero means no variable found
FNDV8:	XAE
FNDV9:	LD	@-1(P3)
	LD	AEXOFF(P2)		; load last offset AEXSTK
	XPAL	P2
	XPAL	P3
	ST	@-1(P2)			; store P3.L on AEXSTK
	XPAH	P3
	ST	@-1(P2)			; store P3.H on AEXSTK
	LDI	STKMID			; reset P2 stack (also L(SPRVSR) !)
	XPAL	P2
	ST	AEXOFF(P2)		; store offset to AEXSTK
	LD	-100(P2)		; see above, loads SPRVSR high
	XPAH	P3
	JMP	SV_SPLOAD(P3)

SAV:	LD	SBROFF(P2)
	XRI	DOSTAK			; is it top of DO/UNTIL stack ?
	JZ	SV_RTNEST(P3)		; yes, no loop
	LD	BASMODE(P2)		; load program/run flag
	XRI	(INCMD + _QMARK)	; are we running?
	JZ	SAV1			; yes
	LDI	0x80
SAV1:	XAE
	LD	SBROFF(P2)
	XPAL	P2
	XPAL	P1
	ST	@-1(P2)
	XPAL	P1
	XPAH	P1
	ORE
	ST	@-1(P2)
	XRE
	XPAH	P1
	XPAL	P2
	ST	SBROFF(P2)
	JMP	SV_SPLOAD(P3)

DONE:	LD	@1(P1)			; get byte from program and increase
	XRI	' '			; is it <space> ?
	JZ	DONE			; yes, just eat it
	XRI	_CR ! ' '		; we XOR'ed above, is it <cr> ?
	JZ	SV_SPLOAD(P3)
	XRI	_CR ! ':'		; we XOR'ed above, is it <colon> ?
	JZ	SV_SPLOAD(P3)
	LDI	(M_CHAR-M_BASE)		; 'CHARACTER ERROR'
	JMP	SV_MSGOUT(P3)

;**************************************
;*	EXIT FROM BASIC ROUTINE       *
;**************************************
;
; Return to KBPLUS or something else, address is stored on STACK.
;
BYE:	LD	119(P2)			; load high byte of return address
	XPAH	P3
	LD	120(P2)			; load low byte of return address
	XPAL	P3
	XPPC	P3			; jump to return address

; Ignore rest of statement, go to next if there is one.
IGNRE:	LD	@1(P1)			; get byte from program and increase
	XRI	_CR			; is it <cr> ?
	JZ	NXT
	XRI	_CR ! ':'		; we XOR'ed above, is it <colon> ?
	JZ	NXT
	JMP	IGNRE

XFER:	JZ	XFER1
	LDI	(M_NOGO-M_BASE)		; 'NOGO ERROR'
	JMP	SV_MSGOUT(P3)
XFER1:	LDI	(INCMD + _QMARK)	; set "PROGRAM RUNNING"
	ST	BASMODE(P2)		; store program/run flag
	JMP	NXT1

THEN:	LD	@1(P1)			; get byte from program and increase
	XRI	' '			; is it <space> ?
	JZ	THEN			; yes, just eat it
	XRI	T_THEN ! ' '		; we XOR'ed above, is it THEN ?
	JZ	SV_SPLOAD(P3)
	LD	@-1(P1)
	JMP	NEXT
MOVESR:	LD	-17(P2)
	CAS
DNE:	LD	@1(P1)			; get byte from program and increase
	XRI	' '			; is it <space> ?
	JZ	DNE			; yes, just eat it
	XRI	_CR ! ' '		; we XOR'ed above, is it <cr> ?
	JZ	NXT
	XRI	_CR ! ':'		; we XOR'ed above, is it <colon> ?
	JZ	NXT
	LDI	(M_CHAR-M_BASE)		; 'CHARACTER ERROR'
	JMP	SV_MSGOUT(P3)
CMPRE:	LD	AEXOFF(P2)
	XPAL	P2
	XAE
	LD	1(P2)
	OR	@4(P2)
	XAE
	XPAL	P2
	ST	AEXOFF(P2)		; store last AEXSTK.L
	LDE
	JNZ	THEN
ELS:	LD	@1(P1)			; get byte from program and increase
	XRI	_CR			; is it <CR> ?
	JZ	NXT			; yes, end of line!
	XRI	_CR ! ':'		; we XOR'ed above, is it <colon> ?
	JZ	ELS2
	XRI	':' ! '"'		; we XOR'ed above, is it <quote> ?
	JNZ	ELS
ELS1:	LD	@1(P1)			; get byte from program and increase
	XRI	'"'			; is it <quote> ?
	JNZ	ELS1			; nope, keep scanning
	JMP	ELS
ELS2:	LD	@1(P1)			; get byte from program and increase
	XRI	' '			; is it <space> ?
	JZ	ELS2			; yes, just eat it
	XRI	T_ELSE ! ' '		; we XOR'ed above
	JZ	NEXT
	LD	@-1(P1)
	JMP	ELS
SNTX:	LD	ERRNUML(P2)		; load number low
	ST	NUMLO(P2)		; and store for PRNUM
	LD	ERRNUMH(P2)		; load number high
	ST	NUMHI(P2)		; and store for PRNUM
SYNTX:	LDI	(M_SNTX-M_BASE)		; 'SYNTAX ERROR'
	JMP	SV_MSGOUT(P3)
ENDPR:	LDI	(M_ENDP-M_BASE)		; 'END) ERROR'
	JMP	SV_MSGOUT(P3)
IGNORE:	LD	@1(P1)			; get byte from program and increase
	XRI	_CR			; is it a <cr> ?
	JNZ	IGNORE			; no, keep reading
NXT:	LD	BASMODE(P2)		; load program / run flag
	JP	NXT2			; are we at the command line?
NXT1:	LD	(P1)			; get current byte from program
	XRI	0xFF			; is it $FF (end of program) ?
	JNZ	NXT3			; no, so not done yet
NXT2:	LDI	(M_RDY-M_BASE)		; 'READY'
	JMP	SV_MSGOUT(P3)
NXT3:	CSA				; get CPU status
	ANI	0x20			; test SENSEB (start bit)
	JZ	BRK			; if not clear, all OK, continue
	LD	-1(P1)			; continue to execute
	XRI	_CR
	JNZ	NEXT
	LD	@1(P1)			; get byte from program and increase
	ST	NUMHI(P2)
	LD	@2(P1)
	ST	NUMLO(P2)
NEXT:	LD	BASMODE(P2)		; load command/run flag
	XAE				; save in E
NEXT1:	LD	@1(P1)			; get byte from program and increase
	XRI	' '			; is it <space> ?
	JZ	NEXT1			; yep, just eat it
	JP	NEXT3			; no token, potential variable
	SCL
	LD	-1(P1)			; load last byte
	CAI	T_LET+1			; must be positive if token not allowed		
	JP	SYNTX			; tokens beyond LET not allowed
	ADI	T_LET-127		; restore token without bit7 set
	XAE				; command/run flag in A, token in E
	JP	NEXT2			; all tokens in lookup table allowed
	LDI	T_LAST-128		; clear bit7
	CAE
	JP	SYNTX			; first tokens not allowed
NEXT2:	CCL
	LDE				; calculate offset
	ADE
	JMP	NEXT4
NEXT3:	LD	@-1(P1)			; re-get byte to correct P1
	LDI	(T_LET-128)*2		; set offset for LET
NEXT4:	XAE				; E holds offset
	LDPI	P3,(ILSTRT+2)		; calculate lookup table address
	LD	@EREG(P3)
	LDI	L(SPRVSR)		; set P3 to SPRVSR
	XPAL	P3
	ST	-1(P2)			; store next ILCALL address low
	LDI	H(SPRVSR)
	XPAH	P3
	ST	-2(P2)			; store next ILCALL address high
	JMP	SV_SPLOAD(P3)

SAVEDO:	LD	DOUOFF(P2)
	XRI	FORSTK			; is FOR/NEXT stack reached ?
	JZ	SV_RTNEST(P3)		; yes, too many loops
	XRI	FORSTK			; we XOR'ed above, restore byte
	XPAL	P2
	XPAL	P1
	ST	@-1(P2)
	XPAL	P1
	XPAH	P1
	ST	@-1(P2)
	XPAH	P1
	XPAL	P2
	ST	DOUOFF(P2)
	JMP	NXT1

; Convert current pointer P1.H into PAGE number.
DETPGE:	XPAH	P1			; load P1.H into E
	XAE
	LDE
	XPAH	P1
	LDE
	SR				; shift AC (divide by 16)
	SR
	SR
	SR
	ST	CURPG(P2)		; store page #
	JMP	NXT

; leave UNTIL and execute next statement; do not move (jump distance.)
LVUNTL:	ILD	DOUOFF(P2)		; adjust DSTAK by two up
	ILD	DOUOFF(P2)
	JMP	NXT1

; Send BREAK message after END statement, sometimes used otherwise.
BRK:	LDI	(M_BRK-M_BASE)		; 'BREAK'
	JMP	SV_MSGOUT(P3)

UNTL:	LD	DOUOFF(P2)
	XRI	DOSTAK			; is this top of DO/UNTIL stack ?
	JNZ	UNTL1			; no, perform loop
	LDI	(M_UNTL-M_BASE)		; 'UNTIL ERROR'
	JMP	SV_MSGOUT(P3)
UNTL1:	LD	AEXOFF(P2)
	XPAL	P2
	XAE
	LD	1(P2)
	OR	@4(P2)
	XAE
	XPAL	P2
	ST	AEXOFF(P2)		; store last AEXSTK.L
	LDE
	JNZ	LVUNTL
	LD	DOUOFF(P2)
	XPAL	P2
	XPAH	P1
	LD	1(P2)
	XPAL	P1
	LD	(P2)
	XPAH	P1
	XPAL	P2
	JMP	DETPGE

STRT:	LDI	(INCMD + _QMARK)	; set "PROGRAM RUNNING" mode
	ST	BASMODE(P2)		; store program/run flag
	LDI	0
	ST	NUMLO(P2)		; set line number to zero
	ST	NUMHI(P2)
CLRSTK:	LDI	FORSTK			; top of FOR/NEXT stack
	ST	FOROFF(P2)
	LDI	DOSTAK			; top of DO/UNTIL stack
	ST	DOUOFF(P2)
	LDI	L(SBRSTK)
	ST	SBROFF(P2)
; FIXME: Next not needed anymore.
;	LDI	(M_RDY-M_BASE)		; 'READY'
	RTRN

; Return from GOSUB statement
RSTR:	LD	SBROFF(P2)
	XRI	L(SBRSTK)		; is it top of GOSUB/RETURN stack
	JNZ	RSTR1			; no, continue
	LDI	(M_RTRN-M_BASE)		; 'RETURN ERROR'
	JMP	SV_MSGOUT(P3)
RSTR1:	ILD	SBROFF(P2)		; adjust SBRSTK by two up
	ILD	SBROFF(P2)
	XPAL	P2
	LD	-2(P2)
	JP	RSTR2
	LDI	(M_RDY-M_BASE)		; 'READY'
	JMP	SV_RTERRN(P3)
RSTR2:	XPAH	P1
	LD	-1(P2)
	XPAL	P1
	LDI	STKMID
	XPAL	P2
	JMP	DETPGE

; Store pointer P1 and scan input for quote.
STPNT:	XPAL	P1			; store current P1 into -15,-16 STACK
	ST	-15(P2)
	XPAL	P1
	XPAH	P1
	ST	-16(P2)
	XPAH	P1
STPNT1:	LD	@1(P1)			; get byte from program and increase
	XRI	'"'			; is it <quote> ?
	JNZ	STPNT1			; no, keep scanning
	JMP	SV_SPLOAD(P3)

; Load pointer P1 back.
LDPNT:	LD	-15(P2)			; load pointer from -15,-16 STACK
	ST	-19(P2)			; store into -19,-20
	LD	-16(P2)
	ST	-20(P2)
	JMP	SV_SPLOAD(P3)

; Identify variable and store in memory followed by 4-byte zero value.
; NOTE:	Storage for variables begins at STKBASE+0x0100 and ends at STKBASE+0x03B4
DEFVAR:	JZ	SV_SPLOAD(P3)
	LD	@-1(P1)			; set back to previous program byte
	LD	AEXOFF(P2)		; load previous P2.L STACK
	XPAL	P2
	LD	1(P2)			; load P3 from top of STACK
	XPAL	P3			; and use it to hold var name
	LD	(P2)
	XPAH	P3
	LDI	0
	XAE				; E is used in error handling, see below
	JMP	DEFV2
DEFV1:	ILD	1(P2)			; increase STACK stored P3, full 16-bit
	JNZ	DEFV2
	ILD	(P2)
DEFV2:	SCL
	LD	(P2)			; load stored P3.H
	ANI	0x0F			; stay in page, only last 4 bits
	CAI	0x0F			; still enough stack space ?
	JP	DEFERR			; throw variable stack error
	LDE				; E is used in error handling, see below
	ADI	0xFF
	XAE				; E = E + 255
	LD	@1(P1)			; get byte from program and incr
	ST	@1(P3)			; store byte in var stack and incr
	SCL				; now test for letter or digit
	LD	(P1)			; get current byte from program
	CAI	'Z'+1
	JP	DEFV3			; completed, no letter or digit anymore
	ADI	26			; 'Z'-'A'+1
	JP	DEFV1			; found letter
	ADI	7			; 'A'-'9'-1
	JP	DEFV3			; no digit either, go complete operation
	ADI	10			; '9'-'0'+1
	JP	DEFV1			; is digit
DEFV3:	LD	-1(P3)			; load previous char of var name
	ORI	0x80
	ST	-1(P3)			; bit7 set terminates var name
	LD	(P1)			; get current byte from program
	XRI	'$'			; is it '$' ?
	JZ	VARERR			; string is not allowed here !
	XRI	'$' ! '('		; we XOR'ed above, is it '(' ?
  	JZ	VARERR			; array is not allowed here !
	LDI	0
	ST	4(P3)			; set exponent of var to zero
	LDI	STKMID			; reset P2 stack pointer
	XPAL	P2
	LDPI	P3,SPRVSR		; reset P3 to supervisor
	JMP	SV_SPLOAD(P3)		; next instruction

; Find line number (the label) in program context.
; Searched line number is stored in STACK -18,-17.
; Routine returns zero in A if label was found.
FNDLBL:	LDI	2			; set P1 to begin of BASIC program lines
	XPAL	P1
	ST	-15(P2)
	LD	CURPG(P2)		; convert page# into P1 high
	RR				; rotate right AC (multiply by 16)
	RR
	RR
	RR
	XPAH	P1
	ST	-16(P2)			; store P1 in STACK -16,-15
FNDLB1:	LD	(P1)			; load high byte of line number
	XRI	0xFF			; is it -1 (end of program lines ?)
	JNZ	FNDLB2			; no, valid line number
	LD	1(P1)			; load second byte
	XRI	0xFF			; is it -1 ?
	JZ	FNDLB3			; go, end of program lines reached
FNDLB2:	SCL				; compare line numbers
	LD	1(P1)
	CAD	-17(P2)
	XAE
	LD	(P1)
	CAD	-18(P2)
	JP	FNDLB4
	LD	2(P1)			; length of program line
	XAE
	LD	@EREG(P1)		; advance to next line
	JMP	FNDLB1			; have a new look
FNDLB3:	LDI	0x80			; not found, set bit7
FNDLB4:	ORE
	XPAL	P1
	ST	-13(P2)
	XPAL	P1
	XPAH	P1
	ST	-14(P2)
	XPAH	P1
	RTRN

; Some error handling.
DEFERR:	LDI	0
	ST	@EREG(P3)
	LDI	(M_VRST-M_BASE)		; 'VARIABLE STACK'
	JMP	HDLERR
VARERR:	ST	@EREG(P3)
	LDI	(M_VAR-M_BASE)		; 'VARIABLE ERROR'
HDLERR:	XPAH	P3			; P3.H holds offset temporarily
	LDPI	P3,SPRVSR
	JMP	SV_RTERRN(P3)

CKMODE:	LD	BASMODE(P2)		; load program/run flag
	XRI	INCMD			; invert high bit
	JP	SV_SPLOAD(P3)		; was set, so in run mode, OK
	LDI	(M_STMT-M_BASE)		; 'STATEMENT ERROR'
	JMP	SV_MSGOUT(P3)		; not running, throw error

; Print spaces (number determined by stack value.)
SPC:	LD	-17(P2)			; get argument value
	JZ	SV_RTFUNC(P3)		; zero, nothing to do here
SPC1:	LDI	' '			; load <space>
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF				; print it
	DLD	-17(P2)			; decrement counter
	JNZ	SPC1			; do again
	JMP	SV_RTFUNC(P3)		; all done

; Print string terminated by quote.
PRSTRG:	LD	@1(P1)			; get byte from program and increase
	XRI	'"'			; is it <quote> ?
	JZ	SV_RTFUNC(P3)		; yes, all done
	LD	-1(P1)			; no, re-load char from string
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF				; print it
	JMP	PRSTRG			; do again

	IF	0
; FIXME: Following switched off, new PRNUM is on page D
; Get 16-bit number (label) from BASIC program line and store on STACK.
SPRNUM:	LD	@1(P1)			; get byte from program and increase
	ST	NUMHI(P2)		; save high byte of number
	LD	@2(P1)			; get byte from program and advance by 2
	ST	NUMLO(P2)		; save low byte of number

; FIXME: Added just for fun another routine to convert binaries into decimal representation.
; old routine is enclosed in IFNDEF..ELSE..ENDIF statements.
	IFNDEF	KBPLUS
; Print 16-bit number on STACK -9, -8 as decimal ASCII-representation.
PRNUM:	LD	AEXOFF(P2)
	XPAL	P1
	ST	-15(P2)			; save P1.low 
	LD	STKPHI(P3)
	XPAH	P1
	ST	-16(P2)			; save P1.high
	LDI	' '			; positive, store leading space
	ST	-5(P1)			; save as prefix for number
	LDI	-6			; load index of first digit
	ST	CHRNUM(P2)		; store as digit counter
	LD	NUMLO(P2)
	ST	-3(P1)
	LD	NUMHI(P2)		; load 16-bit number..
	ST	-4(P1)			; and put as dividend on AEX STACK
	JP	DIV
	LDI	'-'			; negative, so store <minus>
	ST	-5(P1)			; save as prefix for number
	SCL
	LDI	0			; negate number on AEX STACK
	CAD	NUMLO(P2)
	ST	-3(P1)
	LDI	0
	CAD	NUMHI(P2)
	ST	-4(P1)
; NOTE: Place for quotient is reserved at -2 and -1 of AEX STACK.
DIV:	LDI	0			; clear quotient
	ST	-1(P1)
	ST	-2(P1)
	XAE				; set E to zero
	LDI	16			; shift 16 bit
	ST	-6(P1)			; store as bit counter below number
DIVLP:	CCL
	LD	-1(P1)			; shift 4 byte left one bit
	ADD	-1(P1)
	ST	-1(P1)
	LD	-2(P1)
	ADD	-2(P1)
	ST	-2(P1)
	LD	-3(P1)
	ADD	-3(P1)
	ST	-3(P1)
	LD	-4(P1)
	ADD	-4(P1)
	ST	-4(P1)
	LDE
	ADE				; shift carry into E
	XAE
	LDE
	ADI	-10			; subtract 10
	JP	DIV1			; go, greater/equal 10
	JMP	DIV2			; otherwise subtraction "failed"
DIV1:	XAE
	ILD	-1(P1)			; increase quotient
DIV2:	DLD	-6(P1)			; decrease bit counter
	JNZ	DIVLP			; loop again
; NOTE: AEX STACK -6 is now zero, serves as delimiter for ASCII string.
	DLD	CHRNUM(P2)		; decrease digit counter
	XAE				; put into E, A holds now remainder from divide
	ORI	'0'			; prepare ASCII value
	ST	EREG(P1)		; put it on AEX STACK
	LD	-1(P1)			; store incomplete quotient as new dividend
	ST	-3(P1)
	LD	-2(P1)
	ST	-4(P1)
	OR	-3(P1)
	JNZ	DIV			; loop, quotient not yet zero
	ELSE
; Print 16-bit number on STACK -9, -8 as decimal ASCII-representation.
; From historical reasons the division by ten is realized by bit shifting,
; first mentioned by Dennis Allison in Dr. Dobb's Journal Vol.1, p.2 (January 1976).
; Advantage: Less loops while calculating BUT very gossipy code
PRNUM:	LD	AEXOFF(P2)
	XPAL	P1
	ST	-15(P2)			; save P1.low 
	LDI	H(STKBASE)
	XPAH	P1
	ST	-16(P2)			; save P1.high
	LDI	' '			; positive, store leading space
	ST	-7(P1)			; save as prefix for number
	LDI	-6			; load index for first digit
	ST	CHRNUM(P2)		; store as digit counter
	LD	NUMLO(P2)		; load line number from STACK
	ST	@-1(P1)
	LD	NUMHI(P2)		; load 16-bit number..
	ST	@-1(P1)			; and put as dividend on top of AEX STACK
	JP	DIV
	LDI	'-'			; negative, so store <minus>
	ST	-5(P1)			; save as prefix for number
	SCL
	LDI	0			; negate number on AEX STACK
	CAD	1(P1)
	ST	1(P1)
	LDI	0
	CAD	(P1)
	ST	(P1)
; NOTE:	Place for quotient is reserved at -2 and -1 of AEX STACK.
DIV:	CCL				; shift number 1 bit right
	LD	(P1)
	RRL
	ST	-2(P1)
	LD	1(P1)
	RRL
	ST	-1(P1)			; and store n >> 1 two bytes lower
	CCL				; shift 1 bit right
	LD	-2(P1)
	RRL
	ST	-4(P1)
	LD	-1(P1)
	RRL
	ST	-3(P1)			; and store n >> 2 two bytes lower
; NOTE:	Add n >> 1 and n >> 2
	CCL
	LD	-3(P1)
	ADD	-1(P1)
	ST	-1(P1)
	ST	-3(P1)
	LD	-4(P1)
	ADD	-2(P1)
	ST	-2(P1)
	ST	-4(P1)			
; NOTE:	Shift 4 bits right.
	LDI	4			; shift 4 bit
	ST	-6(P1)			; store as bit counter below number
SHFTR4:	CCL				; shift 1 bit right
	LD	-4(P1)
	RRL
	ST	-4(P1)
	LD	-3(P1)
	RRL
	ST	-3(P1)
	DLD	-6(P1)
	JNZ	SHFTR4			; continue shift loop
; NOTE:	add to result from above
	CCL
	LD	-3(P1)
	ADD	-1(P1)
	ST	-1(P1)
	ST	-3(P1)
	LD	-4(P1)
	ADD	-2(P1)
	ST	-2(P1)
	ST	-4(P1)			
	LDI	8			; shift 8 bit
	ST	-6(P1)			; store as bit counter below number
SHFTR8:	CCL				; shift 1 bit right
	LD	-4(P1)
	RRL
	ST	-4(P1)
	LD	-3(P1)
	RRL
	ST	-3(P1)
	DLD	-6(P1)
	JNZ	SHFTR8			; continue shift loop
; NOTE:	add to result from above
	CCL
	LD	-3(P1)
	ADD	-1(P1)
	ST	-1(P1)
	ST	-3(P1)
	LD	-4(P1)
	ADD	-2(P1)
	ST	-2(P1)
	ST	-4(P1)			; multiplied with 13107/16384 = 0.799987793
	LDI	3			; shift 3 bit
	ST	-6(P1)			; store as bit counter below number
	JMP	SHFTR3
DIV1:	JMP	DIV			; stepping stone
; NOTE: now divide by 8, factor over all is then 0.099998474, roughly 0.1
SHFTR3:	CCL				; shift 1 bit right
	LD	-2(P1)
	RRL
	ST	-2(P1)
	LD	-1(P1)
	RRL
	ST	-1(P1)
	DLD	-6(P1)
	JNZ	SHFTR3			; continue shift loop
; NOTE:	Quotient q is now multiplied by ten.
	CCL				; shift quotient 1 bit left
	LD	-1(P1)
	ADD	-1(P1)
	ST	-3(P1)
	LD	-2(P1)
	ADD	-2(P1)
	ST	-4(P1)			; and store q << 1 two bytes lower
	CCL				; shift 1 bit left
	LD	-3(P1)
	ADD	-3(P1)
	ST	-3(P1)
	LD	-4(P1)
	ADD	-4(P1)
	ST	-4(P1)			; and store q << 2
	CCL
	LD	-3(P1)
	ADD	-1(P1)
	ST	-3(P1)
	LD	-4(P1)
	ADD	-2(P1)
	ST	-4(P1)			; ((q << 2) + q) = 5 * q
; NOTE:	Let the quotient unchanged.
	CCL
	LD	-3(P1)
	ADD	-3(P1)
	ST	-3(P1)
	LD	-4(P1)
	ADD	-4(P1)
	ST	-4(P1)			; (((q << 2) + q)) << 2) = 10 * q
; NOTE:	Calculate the remainder.
	SCL
	LD	1(P1)
	CAD	-3(P1)
	ST	-3(P1)			; r = n - 10 * q (only low is needed)
	XAE				; put remainder into E
	SCL
	LDI	9
	CAE				; is remainder less than ten ?
	JP	GSTORE			; yes, go and store
	SCL				; otherwise subtract ten..
	LDE
	CAI	10
	XAE
	ILD	-1(P1)			; ..and increase quotient by one
	JNZ	GSTORE
	ILD	-2(P1)
GSTORE:	DLD	CHRNUM(P2)
	XAE
	ORI	'0'			; prepare ASCII value
	ST	EREG(P1)		; put it E indexed on AEX STACK
	LD	-1(P1)			; store quotient as next dividend
	ST	1(P1)
	LD	-2(P1)
	ST	(P1)
	OR	1(P1)			; is quotient zero ?
	JNZ	DIV1			; no, loop again
	ENDIF
	DLD	CHRNUM(P2)
	XAE
	LD	-5(P1)			; load prefix for number
	ST	@EREG(P1)		; advance stack to begin of number string and store
PRNT:	LD	@1(P1)			; load digit from stack and increase
	JZ	PNEND			; zero ends printing, see above
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	JMP	PRNT
PNEND:	LD	-15(P2)			; restore P1 and return
	XPAL	P1
	LD	-16(P2)
	XPAH	P1
	RTRN
	ENDIF

; Relational operators.
EQU:	LDI	1
	JMP	CMP
NEQ:	LDI	2
	JMP	CMP
LSS:	LDI	3
	JMP	CMP
LEQ:	LDI	4
	JMP	CMP
GTR:	LDI	5
	JMP	CMP
GEQ:	LDI	6
CMP:	ST	COUNTR(P2)
	LD	AEXOFF(P2)
	XPAL	P1
	ST	-15(P2)
	LD	STKPHI(P3)
	XPAH	P1
	ST	-16(P2)
	LD	5(P1)
	ST	-18(P2)
	LD	1(P1)
	ST	-17(P2)
	CALL	FSUB
	LD	1(P1)
	XOR	-18(P2)
	XAE
	LD	-18(P2)
	XOR	-17(P2)
	ANE
	XOR	1(P1)
	ST	-22(P2)
	LD	1(P1)
	OR	(P1)
	JZ	SETZ
	LDI	0x80
SETZ:	XRI	0x80
	XAE
	DLD	COUNTR(P2)
	JNZ	NEQU
	LDE
	JMP	CMPR
NEQU:	DLD	COUNTR(P2)
	JNZ	LESS
	LDE
	XRI	0x80
	JMP	CMPR
LESS:	DLD	COUNTR(P2)
	JNZ	LEQU
	LD	-22(P2)
	JMP	CMPR
LEQU:	DLD	COUNTR(P2)
	JNZ	GRTR
	LDE
	OR	-22(P2)
	JMP	CMPR
GRTR:	DLD	COUNTR(P2)
	JNZ	GEQU
	LDE
	OR	-22(P2)
	XRI	0x80
	JMP	CMPR
GEQU:	LD	-22(P2)
	XRI	0x80
CMPR:	JP	FLSE
	LDI	0x80
	ST	(P1)
	LDI	0x40
	ST	1(P1)
	JMP	STRE1
FLSE:	LDI	0
	ST	(P1)
	ST	1(P1)
STRE1:	LDI	0
	ST	2(P1)
	ST	3(P1)
	LD	-15(P2)
	XPAL	P1
	ST	AEXOFF(P2)		; store last AEXSTK.L
	LD	-16(P2)
	XPAH	P1
	JMP	SV_RTFUNC(P3)

STBCK:	LD	-13(P2)			; restore P1.L
	XPAL	P1
	ST	AEXOFF(P2)		; store last AEXSTK.L
	LD	-14(P2)
	XPAH	P1			; restore P1.H
	JMP	SV_RTFUNC(P3)

; Implement LIST command.
LST1:	SCL
	LD	1(P1)
	CAD	-17(P2)
	XAE
	LD	(P1)
	CAD	-18(P2)
	JP	LST3
LST2:	LD	(P1)			; test for end of program lines
	XRI	0xFF
	JNZ	LST4
	LD	1(P1)
	XRI	0xFF
	JNZ	LST4
LST3:	ORE
	JZ	LST4	 		; go, print actual line
	LDI	(M_RDY-M_BASE)		; 'READY'
	JMP	SV_MSGOUT(P3)
LST4:	CALL	SPRNUM			; first print line number 
LST5:	LD	@1(P1)			; get byte of actual line and incr
	JP	LST9			; no token, so go and print char
; FIXME: Can we use ext reg instead of chrnum ?
	ST	CHRNUM(P2)		; store token temporarily
	LDI	L(TOKENS)		; load P1 with token table
	XPAL	P1
	ST	-15(P2)			; save prev P1.L
	LDI	H(TOKENS)
	XPAH	P1
	ST	-16(P2)			; save prev P1.H
LST6:	LD	CHRNUM(P2)		; load token again
	XOR	@1(P1)			; compare with token from table
	JZ	LST8			; found, so go and print related keyword
LST7:	LD	@1(P1)			; not found, skip keyword
	JP	LST7
	JMP	LST6			; test next token in table
LST8:	LD	@1(P1)			; get char of keyword and incr
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	JP	LST8
	LD	-15(P2)			; restore P1
	XPAL	P1
	LD	-16(P2)
	XPAH	P1
	JMP	LST5			; go ahead with rest of line
LST9:	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	XRI	_CR			; was it <cr> (end of line ?)
	JNZ	LST5			; no, continue
	LDI	_LF			; yes, print <lf>
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	CSA				; get CPU status
	ANI	0x20			; check for start bit (we have input)
	JNZ	SV_SPLOAD(P3)		; nope, continue
	LDI	(M_BRK-M_BASE)		; 'BREAK'
	JMP	SV_MSGOUT(P3)

; Look on new page for GOSUB or GOTO statement,
; GOSUB resp.GOTO must follow <cr> or <colon>.
LKPAGE:	LD	-1(P1)			; get previous byte from program
	XRI	_CR			; is it <cr> ?
	JZ	CHPAGE
	LDI	0xFF
	ST	CHRNUM(P2)		; set counter to -1
LKPGE:	ILD	CHRNUM(P2)		; increase by 1
	XAE				; exchange with E
	LD	EREG(P1)		; load byte E-indexed
	XRI	' '			; is it <space> ?
	JZ	LKPGE			; yes, eat it
	XRI	' ' ! T_GOSUB		; we XOR'ed above, is it <gosub> ?
	JZ	CHPGE			; found GOSUB token
	XRI	T_GOSUB ! T_GOTO	; we XOR'ed above, is it <goto> ?
	JZ	CHPGE			; found GOTO token
CHPAGE:	LDI	2			; begin of program lines
	ST	-19(P2)
	XPAL	P1
	LD	CURPG(P2)		; convert page# into P1 high
	RR
	RR
	RR
	RR
	ST	-20(P2)
	XPAH	P1
	JMP	SV_SPLOAD(P3)
CHPGE:	LDI	2			; begin of program lines
	ST	-19(P2)
	LD	CURPG(P2)		; convert page# into P1 high
	RR
	RR
	RR
	RR
	ST	-20(P2)
	JMP	SV_SPLOAD(P3)

; Put the number one (DCM 1.0) onto stack.
ONE:	LD	AEXOFF(P2)
	XPAL	P2			; AC holds STKMID
	ST	@SBROFF(P2)		; save as EXP
	SR				; shift right
	ST	1(P2)			; save as M1
	LDI	0
	ST	2(P2)
	ST	3(P2)
	LDI	STKMID
	XPAL	P2
	ST	AEXOFF(P2)		; store last AEXSTK.L
	JMP	SV_SPLOAD(P3)

SAVFOR:	LD	FOROFF(P2)
	XAE
	LDE
	XRI	L(ILCSTK)		; maximum depth for FOR/NEXT STACK reached ?
	JZ	SV_RTNEST(P3)		; yes, too much nested FOR/NEXT loops
	LD	STKPHI(P3)
	XPAH	P3
	LD	AEXOFF(P2)
	XPAL	P2
	LDE
SFOR1:	XRI	L(FORSTK)
	JZ	SFOR3
	XRI	L(FORSTK)		; we XOR'ed above, restore
	XPAL	P3
	LD	12(P2)
	XOR	@12(P3)
	JNZ	SFOR2
	LD	13(P2)
	XOR	-11(P3)
	JZ	SFOR4
SFOR2:	XPAL	P3
	JMP	SFOR1
SFOR3:	LDE
	XPAL	P3
SFOR4:	XPAL	P1
	ST	@-1(P3)
	XPAL	P1
	XPAH	P1
	ST	@-1(P3)
	XPAH	P1
	LD	7(P2)
	ST	@-1(P3)
	LD	6(P2)
	ST	@-1(P3)
	LD	5(P2)
	ST	@-1(P3)
	LD	4(P2)
	ST	@-1(P3)
	LD	3(P2)
	ST	@-1(P3)
	LD	2(P2)
	ST	@-1(P3)
	LD	1(P2)
	ST	@-1(P3)
	LD	@8(P2)
	ST	@-1(P3)
	LD	5(P2)
	ST	@-1(P3)
	LD	4(P2)
	ST	@-1(P3)
	LDI	STKMID
	XPAL	P2
	ST	AEXOFF(P2)		; store last AEXSTK.L
	XPAL	P3
	ST	FOROFF(P2)
STVAR:	LD	AEXOFF(P2)
	XPAL	P2
	LD	5(P2)
	XPAL	P3
	LD	4(P2)
	XPAH	P3
	LD	@6(P2)
	ST	1(P3)
	LD	-5(P2)
	ST	2(P3)
	LD	-4(P2)
	ST	3(P3)
	LD	-3(P2)
	ST	4(P3)
	LDI	STKMID
	XPAL	P2
	ST	AEXOFF(P2)		; store last AEXSTK.L
	LDI	L(SPRVSR)
	XPAL	P3
	LD	-100(P2)
	XPAH	P3
	JMP	SV_SPLOAD(P3)

NXTVAR:	JZ	VARFND
	LDI	(M_VAR-M_BASE)		; 'VARIABLE ERROR'
	JMP	SV_MSGOUT(P3)
VARFND:	LD	@1(P1)			; get byte from program and increase
	XRI	' '			; is it <space> ?
	JZ	VARFND			; yes, just eat it
	XRI	_CR ! ' '		; we XOR'ed above, is it <cr> ?
	JZ	VAR1
	XRI	_CR ! ':'		; we XOR'ed above, is it <colon> ?
	JZ	VAR1
	LDI	(M_CHAR-M_BASE)		; 'CHARACTER ERROR'
	JMP	SV_MSGOUT(P3)
VAR1:	LD	FOROFF(P2)
	XRI	L(FORSTK)
	JNZ	VAR2
	LDI	(M_NEXT-M_BASE)		; 'NEXT ERROR'
	JMP	SV_MSGOUT(P3)
VAR2:	ILD	AEXOFF(P2)		; adjust AEXSTK by two up
	ILD	AEXOFF(P2)
	XPAL	P1
	ST	-15(P2)
	LD	STKPHI(P3)
	XPAH	P1
	ST	-16(P2)
VAR3:	LD	FOROFF(P2)
	XPAL	P2
	LD	-1(P1)
	XOR	1(P2)
	JNZ	VAR4
	LD	-2(P1)
	XOR	(P2)
	JZ	VAR5
VAR4:	LD	@12(P2)
	LDI	STKMID
	XPAL	P2
	ST	FOROFF(P2)
	XRI	L(FORSTK)		; is variable on FOR/NEXT stack ?
	JNZ	VAR3			; yes, continue
	LDI	(M_FOR-M_BASE)		; 'FOR ERROR'
	JMP	SV_MSGOUT(P3)
VAR5:	SCL
	LDI	12
VAR6:	CAI	1
	XAE
	LD	EREG(P2)
	ST	@-1(P1)
	LDE
	JNZ	VAR6
	SRL
	XPAL	P2
	LD	3(P1)
	ST	-22(P2)
	XPAL	P1
	ST	AEXOFF(P2)		; store last AEXSTK.L
	XPAL	P1
	LD	@-2(P1)
LDVAR:	LD	AEXOFF(P2)		; load last AEXSTK.L
	XPAL	P2
	LD	1(P2)			; set P3 to var address
	XPAL	P3
	LD	(P2)
	XPAH	P3
	XAE				; save P3.H in E
	LD	4(P3)			; load value from var
	ST	1(P2)			; and store in temp
	LD	3(P3)
	ST	(P2)
	LD	2(P3)
	ST	-1(P2)
	LD	1(P3)
	ST	@-2(P2)
	LDI	STKMID			; restore P2.L
	XPAL	P2
	ST	AEXOFF(P2)		; save actual STACK.L
	LDI	L(SPRVSR)		; restore P3 to Supervisor
	XPAL	P3
	LDE
	XPAH	P3
	JMP	SV_SPLOAD(P3)

; Load address of version string on STACK.
LDVER:	LD	AEXOFF(P2)		; load last STACK.L
	XPAL	P2
	LDI	L(VERSTR)
	ST	@-1(P2)
	LDI	H(VERSTR)
	ST	@-1(P2)
	LDI	STKMID			; restore P2.L
	XPAL	P2
	ST	AEXOFF(P2)		; save actual STACK.L
	JMP	SV_SPLOAD(P3)

NXTV:	LD	FOROFF(P2)
	XPAL	P2
	LD	(P2)
	XAE
	LD	1(P2)
	XPAL	P2
	LDE
	XPAH	P2
	LD	(P1)
	ST	1(P2)
	LD	1(P1)
	ST	2(P2)
	LD	2(P1)
	ST	3(P2)
	LD	3(P1)
	ST	4(P2)
	LDI	STKMID
	XPAL	P2
	LD	STKPHI(P3)
	XPAH	P2
	LD	-22(P2)
	JP	NXTV2
	CALL	SWAP
	CALL	FSUB
	LD	1(P1)
	XRI	0x80
	JP	NXTV3
NXTV1:	LD	@6(P1)
	LD	-2(P1)
	XAE
	LD	-1(P1)
	XPAL	P1
	ST	AEXOFF(P2)		; store actual AEXSTK.L
	LDE
	XPAH	P1
	JMP	SV_SPLOAD(P3)
NXTV2:	CALL	FSUB
	LD	1(P1)
	JP	NXTV1
NXTV3:	CCL
	LD	FOROFF(P2)
	ADI	12			; adjust FORSTK.L by 12 up
	ST	FOROFF(P2)
	LD	@6(P1)
	LD	-15(P2)
	XPAL	P1
	ST	AEXOFF(P2)		; store actual AEXSTK.L
	LD	-16(P2)
	XPAH	P1
	JMP	SV_SPLOAD(P3)

; Load pointer P1 to search for DATA.
LDDTA:	LD	-19(P2)			; load P1 from STACK -20,-19
	XPAL	P1
	ST	-15(P2)			; and store old one on STACK -16,-15
	LD	-20(P2)
	XPAH	P1
	ST	-16(P2)
	JMP	SV_SPLOAD(P3)

; Find next DATA statement.
NXTDTA:	LD	-1(P1)			; was previous BASIC char
	XRI	_CR			; .. a <cr> ?
	JZ	DTA2			; no, keep scanning
DTA1:	LD	@1(P1)			; get byte from program and increase
	XRI	' '			; is it <space> ?
	JZ	DTA1			; yes, just eat it
	XRI	' ' ! ','		; we XOR'ed above, is it <comma> ?
	JZ	FNDTA
	XRI	',' ! ':'		; we XOR'ed above, is it <colon> ?
	JZ	DTA4
	XRI	':' ! _CR		; we XOR'ed above, is it <cr> ?
	JZ	DTA2
	LD	ERRNUML(P2)		; load number low
	ST	NUMLO(P2)		; and store for PRNUM
	LD	ERRNUMH(P2)		; load number high
	ST	NUMHI(P2)		; and store for PRNUM
	LDI	(M_CHAR-M_BASE)		; 'CHARACTER ERROR'
	JMP	SV_MSGOUT(P3)
DTA2:	LD	(P1)			; check if we are at end
	XRI	0xFF			; of program
	JNZ	DTA3			; no, not yet
	LDI	(M_DATA-M_BASE)		; 'DATA ERROR'
	JMP	SV_MSGOUT(P3)
DTA3:	LD	@1(P1)			; get high byte of line number and increase
	ST	ERRNUMH(P2)		; store number high for possible error message 
	LD	@2(P1)			; get low byte of line number and incr by 2
	ST	ERRNUML(P2)		; store number low for possible error message
DTA4:	LD	@1(P1)			; get byte from program and increase
	XRI	' '			; is it <space> ?
	JZ	DTA4			; yes, just eat it
	XRI	T_DATA ! ' '		; we XOR'ed above, is it DATA token ?
	JZ	FNDTA
NODTA:	LD	-1(P1)			; get previous byte from program
	XRI	':'			; is it <colon> ?
	JZ	DTA4
	XRI	':' ! _CR		; we XOR'ed above, is it <cr> ?
	JZ	DTA2
	LD	@1(P1)			; get byte from program and increase
	JMP	NODTA
FNDTA:	LD	@1(P1)			; get byte from program and increase
	XRI	' '			; is it <space> ?
	JZ	FNDTA			; yes, just eat it
	LD	@-1(P1)			; decrease pointer to previous byte
	JMP	SV_SPLOAD(P3)

ISTRNG:	LD	-17(P2)			; set P3 to -17,-18
	XPAL	P3
	LD	-18(P2)
	XPAH	P3
	XAE				; save P3.H into E
ISTR1:	LD	@1(P1)			; get byte from program and increase
	ST	@1(P3)			; store into P3
	XRI	_CR			; is it <cr> ?
	JNZ	ISTR1			; no, continue
	LDI	L(SPRVSR)		; restore P3
	XPAL	P3
	LDE
	XPAH	P3
XCHPNT:	LD	-15(P2)			; exhange P1 with -15,-16
	XPAL	P1
	ST	-15(P2)
	LD	-16(P2)
	XPAH	P1
	ST	-16(P2)
	JMP	SV_SPLOAD(P3)

INSTR:	LD	-17(P2)			; load P3 from STACK -18,-17
	XPAL	P3
	LD	-18(P2)
	XPAH	P3
	XAE				; save P3.H into E
INSTR1:	LD	(P1)			; get char from program line
	XRI	','			; is it <comma> ?
	JZ	PUTS2
	XRI	',' ! ':'		; we XOR'ed above, is it <colon> ?
	JZ	PUTS2
	XRI	':' ! _CR		; we XOR'ed above, is it <cr> ?
	JZ	PUTS2
	LD	@1(P1)			; get char from program line and increase
	ST	@1(P3)
	JMP	INSTR1

; Store quoted string at address stored on STACK
PUTSTR:	LD	-17(P2)			; load P3 from -18,-17
	XPAL	P3
	LD	-18(P2)
	XPAH	P3
	XAE				; save P3.H into E
PUTS1:	LD	@1(P1)			; get char from program line and increase
	XRI	'"'			; is it <quote> ?
	JZ	PUTS2			; yes
	XRI	'"'			; we XOR'ed above, restore char
	ST	@1(P3)			; store into P3
	JMP	PUTS1			; do again
PUTS2:	LDI	_CR			; load <cr>
	ST	(P3)			; store to terminate string
	LDI	L(SPRVSR)		; restore P3 to Supervisor
	XPAL	P3
	LDE
	XPAH	P3
	JMP	SV_SPLOAD(P3)

; Store begin of BASIC Program, so that READ command
;  can get the very first DATA line.
; NOTE:	Address is stored in STACK -16,-15.
FNDDTA:	LDI	2
	ST	-15(P2)			; low byte to -15
	LD	CURPG(P2)
	RR
	RR
	RR
	RR
	ST	-16(P2)			; store high byte in -16
	JMP	SV_SPLOAD(P3)

; Print quoted string.
PRSTR:	LD	@1(P1)			; get char from program line and incr
	XRI	'"'			; is it <quote> ?
	JZ	SV_SPLOAD(P3)		; yes, done
	LD	-1(P1)			; no, get previous character
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF			; print it
	JMP	PRSTR			; do again

; After ON command determine where to go.
; NOTE: Use 16-byte integer stored on STACK -18,-17.
GTO:	LD	-17(P2)
	JNZ	GTO1
	DLD	-18(P2)
GTO1:	DLD	-17(P2)
	OR	-18(P2)
	JZ	GTO4
GTO2:	LD	@1(P1)			; get char from program line and incr
	XRI	' '			; is it <space> ?
	JZ	GTO2			; yes, just eat it
	XRI	' ' ! ','		; we XOR'ed above, is it <comma> ?
	JZ	GTO3
	LDI	(M_NOGO-M_BASE)		; 'NOGO ERROR'
	JMP	SV_MSGOUT(P3)
GTO3:	CCL
	LD	AEXOFF(P2)		; adjust AEXSTK by four up
	ADI	4
	ST	AEXOFF(P2)
	SCL
	LD	-1(P2)			; decrease stored pointer by four
	CAI	4
	ST	-1(P2)
	LD	-2(P2)
	CAI	0
	ST	-2(P2)
	JMP	SV_SPLOAD(P3)
GTO4:	LD	@1(P1)			; get char from program line and incr
	XRI	_CR			; is it <cr> ?
	JZ	SV_SPLOAD(P3)		; yes, done
	XRI	_CR ! ':'		; we XOR'ed above, is it <colon> ?
	JZ	SV_SPLOAD(P3)		; yes, done
	JMP	GTO4			; continue (skip until end of statement)

; Execute machine code.
MC:	LDI	AEXSTK+16
	JMP	SV_RTRN1(P3)

; Implement EDIT statement.
EDITR:	JZ	EDIT1			; correct label was found
	LDI	(M_RDY-M_BASE)		; 'READY'
	JMP	SV_MSGOUT(P3)
EDIT1:	ST	-22(P2)			; store <null> as temporary counter
; FIXME: redundant code, so replaced PRNUM by SPRNUM
	IF	0
	 LD	@1(P1)			; get line number high from BASIC line
	 ST	NUMHI(P2)
	 LD	@2(P1)			; get line number low and skip length of line
	 ST	NUMLO(P2)		; store line number in NUMHI / NUMLO of STACK
	 CALL	PRNUM			; print line number of BASIC line
	ENDIF
	CALL	SPRNUM			; store line number on STACK and print
EDIT2:	LD	@1(P1)			; get byte from BASIC line and increase
	XRI	_FF
	JNZ	EDIT3
	LDI	'\\'			; print a <backslash> instead of <ff>
	JMP	EDIT8
EDIT3:	XRI	_FF ! _CR		; we XOR'ed above, is it <cr> ?
	JZ	EDIT9			; yes, output line
	LD	-1(P1)			; load byte again
	JP	EDIT7			; jump, is normal character
	XAE				; save in E
	; NOTE:	Byte has bit7 set, so must be token, identify it.
	LDI	L(TOKENS)		; load P1 with token table
	XPAL	P1
	ST	-15(P2)			; save prev P1.L
	LDI	H(TOKENS)
	XPAH	P1
	ST	-16(P2)			; save prev P1.H
EDIT4:	LDE				; load token from E
	XOR	@1(P1)			; compare with token from table and incr
	JZ	EDIT6			; jump if token found
EDIT5:	LD	@1(P1)			; get byte from token table and incr
	JP	EDIT5			; loop until terminating byte (bit7 set)
	JMP	EDIT4			; compare with next token
EDIT6:	ILD	-22(P2)
	LD	@1(P1)			; load byte of keyword pointed to by P1 and incr
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	JP	EDIT6			; loop until terminating byte (bit7 set)
	LD	-15(P2)			; load saved P1 (line buffer) from STACK -15, -16
	XPAL	P1
	LD	-16(P2)
	XPAH	P1			; load old P1 (line buffer) from STACK
	JMP	EDIT2
EDIT7:	ANI	0x60			; is it really digit or letter ?
	JZ	EDIT2			; looks as non-printable, continue
	LD	-1(P1)
EDIT8:	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	ILD	-22(P2)
	JMP	EDIT2
; NOTE:	Set cursor back behind line number, use counter fron STACK -22
EDIT9:	LDI	_BS			; load <backspace>
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	DLD	-22(P2)
	JNZ	EDIT9			; not zero, loop again
	LDI	L(STKIBUF)		; set P1.L back to start of input buffer
	XPAL	P1
	LD	STKPHI(P3)
	ORI	H(STKIBUF)		; offset for STKBASE.H
	XPAH	P1			; set P1.H to start of input buffer
	LD	(P2)			; load input buffer length, max. number of chars
	ST	-22(P2)			; store as temporary counter
CLRBUF:	XAE
	LDI	0xFF			; load as empty-marker (nothing here)
	ST	EREG(P1)		; fill input buffer with empty-marker
	DLD	-22(P2)			; decrease temp counter
	JP	CLRBUF
	LDI	0
	XAE
;NOTE:	Copy line number into line buffer
	LD	AEXOFF(P2)
	XPAL	P2
	LD	@-9(P2)			; advance P1 to begin of stored number string
EDIT10:	ST	@1(P1)			; store digit in line buffer
	CCL
	XAE
	ADI	1
	XAE
	LD	@-1(P2)
	JNZ	EDIT10			; loop until <null>
EDIT11:	LDI	STKMID
	XPAL	P2
	LDE
	ST	CHRNUM(P2)		; store as index after line number
	LD	-13(P2)
	XPAL	P3
	LD	-14(P2)
	XPAH	P3
	LD	@3(P3)			; advance P3 to first byte of program line
EDIT12:	LD	@1(P3)			; get that byte
	XRI	_CR			; is it <cr> ?
	JZ	EDIT17			; yes, we are done
	LD	-1(P3)			; no, load byte anew
	JP	EDIT16			; go, no token
	ST	-22(P2)			; save token temporary
	LDI	L(TOKENS)		; load P3 with token table
	XPAL	P3
	ST	-15(P2)			; save prev P3.L
	LDI	H(TOKENS)
	XPAH	P3
	ST	-16(P2)			; save prev P3.H
EDIT13:	LD	-22(P2)			; load token
	XOR	@1(P3)			; test for it in table
	JZ	EDIT15
EDIT14:	LD	@1(P3)
	JP	EDIT14			; skip keyword
	JMP	EDIT13			; loop for next
EDIT15:	LD	@1(P3)
	ANI	0x7F
	ST	@1(P1)
	LD	-1(P3)
	JP	EDIT15
	LD	-15(P2)
	XPAL	P3
	LD	-16(P2)
	XPAH	P3
	JMP	EDIT12
EDIT16:	ST	@1(P1)
	JMP	EDIT12
EDIT17:	LDI	L(STKIBUF)		; set P1.L back to start of input buffer
	XPAL	P1
	LDI	L(SPRVSR)		; restore P3 to Supervisor
	XPAL	P3
	LD	-100(P2)
	XPAH	P3
	JMP	SV_SPLOAD(P3)

; Test for decimal number and store as 16-byte integer on AEXSTK.
NUMTST:	LD	@1(P1)			; get byte from program and increase
	XRI	' '			; is it <space> ?
	JZ	NUMTST			; yes, just eat it
	XRI	' '			; XOR back, restore byte
	SCL
	CAI	'9'+1
	JP	NUMERR			; no digit
	ADI	10			; '9'-'0'+1
	JP	DIGIT			; is digit
NUMERR:	LD	@-1(P1)
	LDI	(M_SNTX-M_BASE)		; 'SYNTAX ERROR'
	JMP	SV_MSGOUT(P3)
DIGIT:	XAE
	DLD	AEXOFF(P2)		; adjust AEXSTK by two down
	DLD	AEXOFF(P2)
	XPAL	P2
	LDE
	ST	1(P2)
	XRE
DIGIT1:	ST	(P2)
	SCL
	LD	@1(P1)			; get byte from program and increase
	CAI	'9'+1
	JP	NUMEND			; no digit
	ADI	10			; '9'-'0'+1
	JP	MORE
NUMEND:	LD	@-1(P1)			; decr P1, load previous program byte
	LDI	STKMID
	XPAL	P2
	JMP	SV_SPLOAD(P3)
MORE:	XAE
	CCL
	LD	1(P2)
	ADD	1(P2)
	ST	-1(P2)
	LD	(P2)
	ADD	(P2)
	ST	-2(P2)
	CCL
	LD	-1(P2)
	ADD	-1(P2)
	ST	-1(P2)
	LD	-2(P2)
	ADD	-2(P2)
	ST	-2(P2)
	CCL
	LD	-1(P2)
	ADD	1(P2)
	ST	1(P2)
	LD	-2(P2)
	ADD	(P2)
	ST	(P2)
	CCL
	LD	1(P2)
	ADD	1(P2)
	ST	1(P2)
	LD	(P2)
	ADD	(P2)
	ST	(P2)
	CCL
	LDE
	ADD	1(P2)
	ST	1(P2)
	LDI	0
	ADD	(P2)
	JP	DIGIT1
	JMP	SV_VALERR(P3)

; AUTO statement: Output line number and give max. char count per line.
AUTONM:	LD	-17(P2)			; get line number from STACK -18, -17
	ST	NUMLO(P2)		; and store for PRNUM
	LD	-18(P2)
	ST	NUMHI(P2)
	CALL	PRNUM
	LDI	72			; max. characters per line
	ST	(P2)
	JMP	SV_SPLOAD(P3)

; AUTO statement: Load distance to next line from AEXSTK.
AUTON:	LD	CHRNUM(P2)
	JZ	SV_SPLOAD(P3)
	LD	AEXOFF(P2)		; load P1 with arithmetics stack
	XPAL	P1
	LD	STKPHI(P3)
	XPAH	P1
	CCL
	LD	NUMLO(P2)		; load last line number.
	ADD	1(P1)			; add distance to next line..
	ST	-17(P2)			; ..and store on STACK -18, -17
	LD	NUMHI(P2)
	ADD	(P1)
	ST	-18(P2)
	JMP	SV_SPLOAD(P3)

; Convert floating point number on arithmetics stack into 16-bit integer.
FIX:	ILD	AEXOFF(P2)		; adjust STACK top by two up
	ILD	AEXOFF(P2)
	XPAL	P2
	LD	(P2)
	ST	1(P2)
	LD	-1(P2)
	ST	(P2)
	LDI	0
FIX1:	XAE
FIX2:	SCL
	ILD	-2(P2)
	JZ	SV_VALERR(P3)
	JP	FIX5
	CAI	0x8F
	JZ	FIX3
	LD	(P2)
	ADD	(P2)
	LD	(P2)
	RRL
	ST	(P2)
	LD	1(P2)
	RRL
	ST	1(P2)
	CSA
	JP	FIX2
	JMP	FIX1
FIX3:	LDE
	AND	(P2)
	JP	FIX4
	ILD	1(P2)
	JNZ	FIX4
	ILD	(P2)
FIX4:	LDI	STKMID
	XPAL	P2
	JMP	SV_SPLOAD(P3)
FIX5:	LDI	0
	ST	1(P2)
	ST	(P2)
	JMP	FIX4

; Implement MID$ string function for quoted strings.
MIDST:	LD	AEXOFF(P2)
	XPAL	P2
MID1:	LD	@1(P1)			; get byte from program and increase
	XRI	'"'			; is it <quote> ?
	JZ	MID3
	LD	3(P2)
	JNZ	MID2
	DLD	2(P2)
MID2:	DLD	3(P2)
	OR	2(P2)
	JNZ	MID1
MID3:	LD	@-1(P1)
	LD	1(P2)
	ST	3(P2)
	LD	@2(P2)
	ST	(P2)
	LDI	STKMID
	XPAL	P2
	ST	AEXOFF(P2)		; store last AEXSTK.L

; Implement LEFT$ string function for quoted strings.
LEFTST:	ILD	AEXOFF(P2)		; adjust STACK top by two up
	ILD	AEXOFF(P2)
	XPAL	P2
	LD	1(P2)
	XPAL	P3
	LD	(P2)
	XPAH	P3
	XAE
LEFT1:	LD	@1(P1)			; get byte from program and increase
	XRI	'"'			; is it <quote> ?
	JZ	LEFT3
	XRI	'"'			; undo XOR, restore char
	ST	@1(P3)
	LD	-1(P2)
	JNZ	LEFT2
	DLD	-2(P2)
LEFT2:	DLD	-1(P2)
	OR	-2(P2)
	JNZ	LEFT1
LEFT3:	LDI	_CR			; store <cr> in P3
	ST	(P3)			; (terminate string)
	LDI	L(SPRVSR)		; restore P3 to Supervisor
	XPAL	P3
	ST	1(P2)
	LDE
	XPAH	P3
	ST	(P2)			; store string addr.H
	LDI	STKMID			; restore stack
	XPAL	P2
	LD	-15(P2)			; restore P1
	XPAL	P1
	LD	-16(P2)
	XPAH	P1
	JMP	SV_RTFUNC(P3)

; Implement RIGHT$ string function for quoted strings.
RGHTST:	ILD	AEXOFF(P2)		; adjust STACK top by two up
	ILD	AEXOFF(P2)
	XPAL	P2
	LD	1(P2)
	XPAL	P3
	LD	(P2)
	XPAH	P3
	XAE
RIGHT1:	LD	@1(P1)			; get byte from program and increase
	XRI	'"'			; is it <quote> ?
	JNZ	RIGHT1
	LD	@-1(P1)
RIGHT2:	LD	-1(P1)
	XRI	'"'			; is it <quote> ?
	JZ	RIGHT4
	LD	@-1(P1)
	LD	-1(P2)
	JNZ	RIGHT3
	DLD	-2(P2)
RIGHT3:	DLD	-1(P2)
	OR	-2(P2)
	JNZ	RIGHT2
RIGHT4:	LD	@1(P1)			; get byte from program and increase
	XRI	'"'			; is it <quote> ?
	JZ	LEFT3			; use end of LEFT$ for restoring ponzers
	XRI	'"'			; undo XOR, restore char
	ST	@1(P3)
	JMP	RIGHT4

; Implement CHR$ string function.
CHRSTR:	ILD	AEXOFF(P2)		; adjust STACK top by two up
	ILD	AEXOFF(P2)
	XPAL	P2
	LD	1(P2)
	XPAL	P3
	LD	(P2)
	XPAH	P3
	XAE
	LD	-1(P2)
	ST	@1(P3)
	JMP	PUTST2

PUTST:	LD	AEXOFF(P2)
	XPAL	P2
	LD	1(P2)
	XPAL	P3
	LD	(P2)
	XPAH	P3
	XAE
PUTST1:	LD	@1(P1)			; get byte from program and increase
	XRI	'"'			; is it <quote> ?
	JZ	PUTST2
	XRI	'"'			; we XOR'ed above, restore char
	ST	@1(P3)
	JMP	PUTST1
PUTST2:	LDI	_CR
	ST	(P3)			; store terminating <cr>
	LDI	L(SPRVSR)
	XPAL	P3
	ST	1(P2)
	LDE
	XPAH	P3
	ST	(P2)
	LDI	STKMID
	XPAL	P2
	JMP	SV_RTFUNC(P3)

; Implement MID$ function with string variable.
MIDSTR:	LD	AEXOFF(P2)
	XPAL	P2
	LD	5(P2)
	XPAL	P1
	ST	5(P2)
	LD	4(P2)
	XPAH	P1
	ST	4(P2)
MSTR1:	LD	@1(P1)			; get byte from program and increase
	XRI	_CR			; is it <cr> ?
	JZ	MSTR3
	LD	3(P2)
	JNZ	MSTR2
	DLD	2(P2)
MSTR2:	DLD	3(P2)
	OR	2(P2)
	JNZ	MSTR1
MSTR3:	LD	@-1(P1)
	LD	1(P2)
	ST	3(P2)
	LD	@6(P2)
	ST	-4(P2)
	JMP	LFSTR1

; Implement LEFT$ function with string variable.
LFTSTR:	LD	AEXOFF(P2)
	XPAL	P2
	LD	3(P2)
	XPAL	P1
	ST	3(P2)
	LD	2(P2)
	XPAH	P1
	ST	2(P2)
	LD	@4(P2)
LFSTR1:	LD	1(P2)
	XPAL	P3
	LD	(P2)
	XPAH	P3
	XAE
LFSTR2:	LD	@1(P1)			; get byte from program and increase
	XRI	_CR			; is it <cr> ?
	JZ	LFSTR4
	XRI	_CR			; undo XOR, restore char
	ST	@1(P3)
	LD	AEXOFF(P2)
	JNZ	LFSTR3
	DLD	-4(P2)
LFSTR3:	DLD	AEXOFF(P2)
	OR	-4(P2)
	JNZ	LFSTR2
LFSTR4:	LDI	_CR			; load <cr>
	ST	(P3)			; store as string terminator
	JMP	STREND

; Implement RIGHT$ function with string variable.
RGHSTR:	LD	AEXOFF(P2)
	XPAL	P2
	LD	3(P2)
	XPAL	P1
	ST	3(P2)
	LD	2(P2)
	XPAH	P1
	ST	2(P2)
	LD	5(P2)
	XPAL	P3
	LD	4(P2)
	XPAH	P3
	XAE
	LDI	0xFF
	ST	-1(P2)
	ST	-2(P2)
RGSTR1:	ILD	-1(P2)
	JNZ	RGSTR2
	ILD	-2(P2)
RGSTR2:	LD	@1(P1)			; get byte from program and increase
	XRI	_CR			; is it <cr> ?
	JNZ	RGSTR1
	LD	@-1(P1)
	SCL
	LD	-1(P2)
	CAD	1(P2)
	LD	-2(P2)
	CAD	@4(P2)
	JP	RGSTR3
	LD	-5(P2)
	ST	AEXOFF(P2)
	LD	-6(P2)
	ST	-4(P2)
RGSTR3:	SCL
	XPAL	P1
	CAD	AEXOFF(P2)
	XPAL	P1
	XPAH	P1
	CAD	-4(P2)
	XPAH	P1
	JMP	MVSTR1
MOVSTR:	LD	AEXOFF(P2)
	XPAL	P2
	LD	@1(P2)
	XPAH	P1
	ST	-1(P2)
	LD	@1(P2)
	XPAL	P1
	ST	-1(P2)
	LD	(P2)
	XPAH	P3
	XAE
	LD	1(P2)
	XPAL	P3
MVSTR1:	LD	@1(P1)			; get byte from source string
	ST	@1(P3)			; store in destination string
	XRI	_CR			; is it a <cr> ?
	JNZ	MVSTR1			; nope, continue
	LD	@-1(P3)
STREND:	LD	-1(P2)			; finish functions for string variables
	XPAL	P1
	LD	-2(P2)
	XPAH	P1
	LDI	L(SPRVSR)
	XPAL	P3
	ST	1(P2)
	LDE
	XPAH	P3
	ST	(P2)
	LDI	STKMID
	XPAL	P2
	ST	AEXOFF(P2)		; store last AEXSTK.L
	JMP	SV_RTFUNC(P3)

; Convert floating point number into string and
;  Leave address of string on arithmetics stack.
; NOTE: By using FNUM before the desired string is on AEXSTK.
FSTRNG:	LD	AEXOFF(P2)		; load actual offset to AEXSTK.L
	XPAL	P1			; P1 holds arithmetics stack
	LD	5(P1)			; get destination address from AEXSTK
	XPAL	P3
	LD	4(P1)
	XPAH	P3			; P3 holds start of ASCII representation
	XAE				; save prev P3.H to E
	LD	@-5(P1)			; get byte from source string
FSTR1:	ST	@1(P3)			; store byte into destination string
	LD	@-1(P1)			; get previous byte from source string
; FIXME: delimiter byte changed from bit7 set to zero byte.
	JNZ	FSTR1			; loop until <null>
	LDI	_CR			; terminate string with a <cr>
	ST	(P3)
	LDI	L(AEXSTK)-2		; restore P1 back so point to destination
	XPAL	P1
	LDI	L(SPRVSR)		; restore P3 to Supervisor
	XPAL	P3
	ST	1(P1)			; store address of new string in P1
	LDE				; restore saved P3.H from E
	XPAH	P3
	ST	(P1)
	JMP	SV_SPLOAD(P3)

POPSTR:	ILD	AEXOFF(P2)		; adjust STACK top by two up
	ILD	AEXOFF(P2)
	JMP	SV_RTFUNC(P3)

; Store pointer P1 on STACK.
STRPNT:	XPAL	P1
	ST	-15(P2)
	XPAL	P1
	XPAH	P1
	ST	-16(P2)
	XPAH	P1
	JMP	SV_SPLOAD(P3)

; Compare string variable with quoted string.
CMPRST:	DLD	AEXOFF(P2)		; adjust AEXSTK.L by two down
	DLD	AEXOFF(P2)
	XPAL	P2			; P2 holds arithmetics stack
	LD	3(P2)
	XPAL	P3
	LD	2(P2)
	XPAH	P3
	XAE
CMPR1:	LD	@1(P1)			; get byte from program and increase
	XRI	'"'			; is it <quote> ?
	JZ	CMPR4
	XRI	'"'			; undo XOR, restore char
	XOR	@1(P3)
	JZ	CMPR1
CMPR2:	LD	@1(P1)			; get byte from program and increase
	XRI	'"'			; is it <quote> ?
	JNZ	CMPR2
CMPR3:	LDI	0
	ST	(P2)
	ST	1(P2)
	JMP	CMPEND
CMPR4:	LD	(P3)			; load char from src
	XRI	_CR			; is it <cr> ?
	JNZ	CMPR3			; no, continue
	LDI	0x80			; yes
	ST	(P2)
	SR
	ST	1(P2)
	JMP	CMPEND			; go and finish comparing

; Compare string variable with another one.
CMPSTR:	LD	AEXOFF(P2)
	XPAL	P2
	LD	3(P2)
	XPAL	P3
	LD	2(P2)
	XPAH	P3
	XAE
	LD	1(P2)
	XPAL	P1
	ST	3(P2)
	LD	(P2)
	XPAH	P1
	ST	2(P2)
CMP1:	LD	@1(P1)			; get byte from program and increase
	XRI	_CR			; is it <cr> ?
	JZ	CMP3
	XRI	_CR			; undo XOR, restore char
	XOR	@1(P3)
	JZ	CMP1
CMP2:	LDI	0
	ST	(P2)
	ST	1(P2)
	JMP	CMP4
CMP3:	LD	(P3)			; load char from src
	XRI	_CR			; is it <cr> ?
	JNZ	CMP2			; no, continue
	LDI	0x80			; yes
	ST	(P2)
	SR
	ST	1(P2)
CMP4:	LD	3(P2)			; restore P1
	XPAL	P1
	LD	2(P2)
	XPAH	P1
; Finish compare, restore P2 and P3.
CMPEND:	LDI	0
	ST	2(P2)
	ST	3(P2)
	LDI	L(SPRVSR)		; restore P3 to Supervisor
	XPAL	P3
	LDE
	XPAH	P3
	LDI	STKMID			; restore stack
	XPAL	P2
	JMP	SV_RTFUNC(P3)

; Implement POKE command.
PUTBYT:	LD	AEXOFF(P2)
	XPAL	P2
	LD	@4(P2)			; adjust AEXSTK top by four up
	LD	-1(P2)
	XPAL	P3
	LD	-2(P2)
	XPAH	P3
	XAE
	LD	AEXOFF(P2)
	ST	(P3)
	LDI	STKMID			; restore stack
	XPAL	P2
	ST	AEXOFF(P2)		; save actual offset
	LDI	L(SPRVSR)		; restore P3 to Supervisor
	XPAL	P3
	LDE
	XPAH	P3
	JMP	SV_SPLOAD(P3)

; Implement PEEK command.
GETBYT:	LD	AEXOFF(P2)
	XPAL	P2
	LD	1(P2)
	XPAL	P3
	LD	(P2)
	XPAH	P3
	XAE
	LD	(P3)
	ST	1(P2)
	LDI	0
	ST	(P2)
STRNG:	LDI	STKMID			; restore stack
	XPAL	P2
	LDI	L(SPRVSR)		; restore P3 to Supervisor
	XPAL	P3
	LDE
	XPAH	P3
	JMP	SV_RTFUNC(P3)

; Take the first char of a quoted string and output its numeric value.
ASC:	LD	AEXOFF(P2)
	XPAL	P2
	LDI	0
	ST	@-1(P2)
	ST	@-1(P2)
	LD	@1(P1)			; get byte from program and increase
	XRI	'"'			; is it <quote> ?
	JZ	LEN3			; yes, done
	XRI	'"'			; undo XOR, restore char
	ST	1(P2)
ASC1:	LD	@1(P1)			; get byte from program and increase
	XRI	'"'			; is it <quote> ?
	JNZ	ASC1			; no, keep scanning
	JMP	LEN3			; done

; Take the first char of a string variable and output its numeric value.
ASTRNG:	LD	AEXOFF(P2)
	XPAL	P2
	LD	1(P2)
	XPAL	P3
	LD	(P2)
	XPAH	P3
	XAE
	LDI	0
	ST	(P2)
	LD	@1(P3)
	XRI	_CR			; is it <cr> ?
	JZ	ASTR1			; yes
	XRI	_CR			; undo XOR, restore char
ASTR1:	ST	1(P2)
	JMP	STRNG

; Store length of a string variable on stack.
LSTRNG:	LD	AEXOFF(P2)		; load actual offset to AEXSTK.L
	XPAL	P2
	LD	1(P2)
	XPAL	P3
	LD	(P2)
	XPAH	P3
	XAE
	LDI	0xFF
	ST	1(P2)
	ST	(P2)
LSTR1:	ILD	1(P2)
	JNZ	LSTR2
	ILD	(P2)
LSTR2:	LD	@1(P3)
	XRI	_CR			; is it <cr> ?
	JNZ	LSTR1			; no, continue scanning
	JMP	STRNG			; yes, done

; Store length of a quoted string on stack.
LEN:	LD	AEXOFF(P2)		; load actual offset of AEXSTK.L
	XPAL	P2
	LDI	-1
	ST	@-1(P2)
	ST	@-1(P2)			; reserve two bytes on stack
LEN1:	ILD	1(P2)
	JNZ	LEN2
	ILD	(P2)
LEN2:	LD	@1(P1)			; get byte from program
	XRI	'"'			; is it <quote> ?
	JNZ	LEN1			; no, continue counting
LEN3:	LDI	STKMID			; yes, reset P2 stack
	XPAL	P2
	ST	AEXOFF(P2)		; save last AEXSTK.L
LEN4:	LD	@1(P1)			; get byte from program
	XRI	' '			; is it <space> ?
	JZ	LEN4			; yes, just eat it
	XRI	' ' ! ')'		; we XOR'ed above, is it ')' ?
	JZ	SV_RTFUNC(P3)
	LDI	(M_ENDP-M_BASE)		; 'END) ERROR'
	JMP	SV_MSGOUT(P3)

; After found variable check for existence of $ and closing parenthesis.
; NOTE: Needed at end of string functions.
CKDLLR:	JZ	CKDLL1
	LDI	(M_VAR-M_BASE)		; 'VARIABLE ERROR'
	JMP	SV_MSGOUT(P3)
CKDLL1:	LD	@1(P1)			; get byte from program
	XRI	'$'			; is it $ ?
	JZ	CKDLL2
	LDI	(M_SNTX-M_BASE)		; 'SYNTAX ERROR'
	JMP	SV_MSGOUT(P3)
CKDLL2:	LD	@1(P1)			; get byte from program
	XRI	' '			; is it <space> ?
	JZ	CKDLL2			; yes, just eat it
	XRI	' ' ! ')'		; we XOR'ed above, is it ')' ?
	JZ	SV_SPLOAD(P3)
	LDI	(M_ENDP-M_BASE)		; 'END) ERROR'
	JMP	SV_MSGOUT(P3)

; Implement CHR$ function.
PRCHAR:	LD	-17(P2)			; load value to be printed
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	JMP	SV_RTFUNC(P3)		; .. and return

; Determine first free byte after BASIC program storage on actual page.
; Put absolute address on STACK, return actual STACK.L value.
TOP:	LD	CURPG(P2)		; convert page# into high address byte 
	RR				; rotate right AC (multiply by 16)
	RR
	RR
	RR
	XPAL	P3			; store temporarely in P3.L
	LDI	2			; position of first program byte
	XPAL	P3			; use pointer P3
	XPAH	P3			; P3 holds pointer to program storage
TOP1:	LD	(P3)			; get current program byte
	XRI	0xFF			; is it first byte of end termination ?
	JNZ	TOP2			; no, go ahead
	LD	1(P3)
	XRI	0xFF			; do we have second byte ?
	JZ	TOP3			; yes, we are finished
TOP2:	LD	2(P3)			; get byte, advance pointer by two
	XAE				; E holds length of line
	LD	@EREG(P3)		; advance to next program line
	JMP	TOP1			; loop again
TOP3:	LD	@2(P3)			; advance to first free byte
	LD	-100(P2)		; load SPRVSR.H
	XPAH	P3
	XAE				; TOP.H into E
	LD	AEXOFF(P2)		; load actual offset to AEXSTK.L
	XPAL	P2			; P2 holds arithmetics stack
	XPAL	P3
	ST	@-1(P2)			; put TOP.L on stack
	LDE
	ST	@-1(P2)			; put TOP.H on stack
	LDI	STKMID			; reset P2 stack
	XPAL	P2
	ST	AEXOFF(P2)		; save actual AEXSTK.L
	RTRN

; Calculate amount of free space above BASIC program in page.
FREE:	LD	AEXOFF(P2)		; load actual offset to AEXSTK.L
	XPAL	P2			; P2 holds arithmetics stack
	SCL
	LDI	0
	CAD	1(P2)			; subtract TOP.L
	ST	1(P2)			; store as FREE.L
	LD	(P2)			; load TOP.H
	ANI	0xF0			; isolate PAGE, shifted by 16
	XRI	H(RAMBASE)		; compare with RAMBASE.H
	JNZ	FREE1			; go, normal page
	LDI	H(STKTOP)		; no, must subtract STACK space
	JMP	FREE2
FREE1:	LDI	0
FREE2:	CAD	(P2)			; subtract TOP.H
	ANI	0x0F			; only last 4 bits are relevant
	ST	(P2)			; store as FREE.H
	LDI	STKMID
	XPAL	P2
	JMP	SV_RTFUNC(P3)

; Read hexadecimal number and store on arithmetics stack.
; NOTE: Numbers greater than #7FFF are negative (#8000 is -32768.)
HEX:	DLD	AEXOFF(P2)		; adjust STACK top by two down
	DLD	AEXOFF(P2)
	XPAL	P2			; P2 holds arithmetics stack
	LDI	0			; clear the two reserved bytes
	ST	1(P2)
	ST	(P2)
	ST	-1(P2)
HEX1:	XAE
	LD	(P1)
	SCL
	CAI	'9'+1
	JP	HEX2			; no digit
	ADI	10			; '9'-'0'+1
	JP	HEX6
	JMP	HEX3
HEX2:	CAI	_CR
	JP	HEX3
	ADI	6
	JP	HEX5
HEX3:	LDI	STKMID			; reset P2 stack
	XPAL	P2
	LDE
	JNZ	HEX4
	LDI	(M_HEX-M_BASE)		; 'HEX ERROR', not a valid hexadecimal
	JMP	SV_MSGOUT(P3)
HEX4:	SCL
	CAI	5
	JP	SV_VALERR(P3)		; jump to 'VALUE ERROR'
	JMP	SV_RTFUNC(P3)
HEX5:	ADI	9
HEX6:	XAE
	LDI	4			; shift four times left
	ST	-2(P2)			; store as temporary counter
HEX7:	CCL
	LD	1(P2)
	ADD	1(P2)
	ST	1(P2)
	LD	(P2)
	ADD	(P2)
	ST	(P2)
	DLD	-2(P2)
	JNZ	HEX7
	LD	1(P2)			; multiplication by 16 done
	ORE
	ST	1(P2)			; OR in new digit
	LD	@1(P1)			; get byte from program and increase
	ILD	-1(P2)
	JMP	HEX1

	IFDEF	SCALLS
; Print version string via external tty.
VERS:	LDI	L(VERMSG)		; point P1 to string
	XPAL	P1
	ST	-15(P2)			; save prev P1.L
	LDI	H(VERMSG)
	XPAH	P1
	ST	-16(P2)			; save prev P1.H
	LD	@1(P1)			; get first byte from string and increase
	SYSCALL	2
VER1:	LD	(P1)			; get byte from string
	XRI	_CR			; is it terminating <cr> ?
	JZ	SV_LINE(P3)		; return and print a newline
	LD	@1(P1)			; get byte again and increase
	SYSCALL	2
	JMP	VER1
	ELSE
; Print version string via internal tty.
VERS:	LDI	L(VERMSG)		; point P1 to string
	XPAL	P1
	ST	-15(P2)			; save prev P1.L
	LDI	H(VERMSG)
	XPAH	P1
	ST	-16(P2)			; save prev P1.H
	LD	@1(P1)			; get first byte from string and increase
	CALL	PUTASC
VER1:	LD	(P1)			; get byte from string
	XRI	_CR			; is it terminating <cr> ?
	JZ	SV_LINE(P3)		; return and print a newline
	LD	@1(P1)			; get byte again and increase
	CALL	PUTASC
	JMP	VER1
	ENDIF

;************************************
;*  PAGE BREAK - THIRD BLOCK OF 4K  *
;************************************
;
	ORG	BASE+0x2000
	NOP				; needed so Supervisor can do -1 here

; NEW command (store new page number.)
NUPAGE:	LD	-17(P2)
	ANI	7			; allow pages 0..7
	JNZ	NUPGE2
NUPGE1:	LDI	1			; reset page# to 1
NUPGE2:	ST	CURPG(P2)
	JMP	SV_SPLOAD(P3)

; Mark current page as empty.
NEWPGM:	LDI	2			; set P1 to new page, offset 2
	XPAL	P1
	LD	CURPG(P2)
	RR
	RR
	RR
	RR
	XPAH	P1
	LDI	_CR			; store a <cr>
	ST	-1(P1)
	LDI	-1			; store line number -1
	ST	(P1)
	ST	1(P1)
	JMP	SV_SPLOAD(P3)

; CLEAR command (clear stacks and all variables.)
CLEAR:	JMP	SV_RESTRT(P3)

; Swap first and second number on STACK in P1.
ABSWP:	LD	5(P1)
	XOR	1(P1)
	ST	-22(P2)
	CALL	ABSWP1
ABSWP1:	LD	1(P1)
	JP	SWAP			; positive, go ahead
	CALL	FNEG			; negate number
SWAP:	LDI	4			; counter for 4-byte swap
	ST	-23(P2)
SWAP1:	LD	@1(P1)			; load byte of first number from stack
	ST	-5(P1)			; temporary store 4 bytes lower
	LD	3(P1)			; load byte of second number from stack
	ST	-1(P1)			; store byte into first number on stack
	LD	-5(P1)			; load temporary stored byte
	ST	3(P1)			; store byte into second number on stack
	DLD	-23(P2)			; decrease counter
	JNZ	SWAP1			; do again
	LD	@-4(P1)
	RTRN

; Two floats are on AEX STACK at -4(P1) and (P1), E holds difference of exponents.
MD:	LDI	0
	ST	3(P1)
	ST	2(P1)
	ST	1(P1)
	ST	(P1)			; set topmost float to zero
	CSA
	JP	MD1
	LDI	0xA0			; load b'10100000' 10<<4 ?
	XAE
	JP	MD2
	LDI	(M_OVRF-M_BASE)		; 'OVERFLOW ERROR'
	JMP	SV_MSGOUT(P3)
MD1:	LDI	0xA0			; load b'10100000' 10<<4 ?
	XAE
	JP	MD3
MD2:	XRI	0x80
	ST	(P1)
	LDI	0x18
	ST	-8(P1)
	JMP	SV_RTRN(P3)
MD3:	ILD	SUBOFF(P2)		; adjust SUBSTK.L by two bytes up
	ILD	SUBOFF(P2)
	JMP	SV_RTRN(P3)

FDIV:	CALL	ABSWP
FDIV0:	CCL
	LD	4(P1)
	CAD	@4(P1)
	CALL	MD
FDIV1:	SCL
	LD	-5(P1)
	CAD	-1(P1)
	ST	-5(P1)
	LD	-6(P1)
	CAD	-2(P1)
	ST	-6(P1)
	LD	-7(P1)
	CAD	-3(P1)
	ST	-7(P1)
	JP	FDIV2
	CCL
	LD	-5(P1)
	ADD	-1(P1)
	ST	-5(P1)
	LD	-6(P1)
	ADD	-2(P1)
	ST	-6(P1)
	LD	-7(P1)
	ADD	-3(P1)
	ST	-7(P1)
	JMP	FDIV3
FDIV2:	ILD	3(P1)
FDIV3:	DLD	-8(P1)
	JZ	MDEND
	CCL
	LDE
	ADE
	XAE
	LD	-5(P1)
	ADD	-5(P1)
	ST	-5(P1)
	LD	-6(P1)
	ADD	-6(P1)
	ST	-6(P1)
	LD	-7(P1)
	JP	FDIV4
	LDI	(M_DIV0-M_BASE)		; 'DIVISION BY 0 ERROR'
	JMP	SV_MSGOUT(P3)
FDIV4:	ADD	-7(P1)
	ST	-7(P1)
	LD	3(P1)
	ADD	3(P1)
	ST	3(P1)
	LD	2(P1)
	ADD	2(P1)
	ST	2(P1)
	LD	1(P1)
	ADD	1(P1)
	ST	1(P1)
	JMP	FDIV1

FMUL:	CALL	ABSWP
	CCL
	LD	4(P1)
	ADD	@4(P1)
	CALL	MD
FMUL1:	CCL
	LD	-7(P1)
	RRL
	ST	-7(P1)
	LD	-6(P1)
	RRL
	ST	-6(P1)
	LD	-5(P1)
	RRL
	ST	-5(P1)
	CSA
	JP	FMUL2
	LD	3(P1)
	ADD	-1(P1)
	ST	3(P1)
	LD	2(P1)
	ADD	-2(P1)
	ST	2(P1)
	LD	1(P1)
	ADD	-3(P1)
	ST	1(P1)
FMUL2:	DLD	-8(P1)
	XRI	1
	JZ	MDEND
	CCL
	LD	1(P1)
	RRL
	ST	1(P1)
	LD	2(P1)
	RRL
	ST	2(P1)
	LD	3(P1)
	RRL
	ST	3(P1)
	JMP	FMUL1
MDEND:	CCL
	LD	1(P1)
	JP	MDSGN
	CALL	ALGN2
MDSGN:	LD	-22(P2)
	JP	SV_RTRN(P3)
	JMP	FNEG

; Subtract the two topmost floating point numbers on arithmetics stack.
FSUB:	CALL	FNEG			; negate and add

; Add the two topmost floating point numbers on arithmetics stack.
FADD:	CALL	ALGEXP			; align exponents for addition
	CCL
	LD	7(P1)
	ADD	3(P1)
	ST	7(P1)
	LD	6(P1)
	ADD	2(P1)
	ST	6(P1)
	LD	5(P1)
	ADD	1(P1)
	ST	5(P1)
	LD	@4(P1)
	JMP	ALGN1

; Logical Operations with the two topmost floats on arithmetics stack.
AND:	LD	7(P1)
	AND	3(P1)
	ST	7(P1)
	LD	6(P1)
	AND	2(P1)
	ST	6(P1)
	LD	5(P1)
	AND	1(P1)
	ST	5(P1)
	LD	@4(P1)
	JMP	NORM

OR:	LD	7(P1)
	OR	3(P1)
	ST	7(P1)
	LD	6(P1)
	OR	2(P1)
	ST	6(P1)
	LD	5(P1)
	OR	1(P1)
	ST	5(P1)
	LD	@4(P1)
	JMP	NORM

NOT:	XRE
	ST	@-1(P1)
	ST	@-1(P1)
	LDI	0x80
	ST	@-1(P1)
	LDI	0x7F
	ST	@-1(P1)
	CALL	ALGEXP

EXOR:	LD	7(P1)
	XOR	3(P1)
	ST	7(P1)
	LD	6(P1)
	XOR	2(P1)
	ST	6(P1)
	LD	5(P1)
	XOR	1(P1)
	ST	5(P1)
	LD	@4(P1)
	JMP	NORM

; Return absolute value of topmost float on arithmetics stack.
FABS:	LD	1(P1)
	JP	SV_RTRN(P3)		; positive, do nothing
; Negate topmost floating point number on arithmetics stack.
FNEG:	SCL
	LDI	0
	CAD	3(P1)
	ST	3(P1)
	LDI	0
	CAD	2(P1)
	ST	2(P1)
	LDI	0
	CAD	1(P1)
	ST	1(P1)
ALGN1:	CSA
	ANI	0x40
	JNZ	ALGN2
NORM:	LD	1(P1)
	ADD	1(P1)
	XOR	1(P1)
	JP	NORM1
	JMP	SV_RTRN(P3)
NORM1:	LD	(P1)
	JZ	SV_RTRN(P3)
	DLD	(P1)
	CCL
	LD	3(P1)
	ADD	3(P1)
	ST	3(P1)
	LD	2(P1)
	ADD	2(P1)
	ST	2(P1)
	LD	1(P1)
	ADD	1(P1)
	ST	1(P1)
	JMP	NORM
ALGN2:	ILD	(P1)
	JNZ	ALGN3
	LDI	(M_OVRF-M_BASE)		; 'OVERFLOW ERROR'
	JMP	SV_MSGOUT(P3)
ALGN3:	LD	1(P1)
	RRL
	ST	1(P1)
	LD	2(P1)
	RRL
	ST	2(P1)
	LD	3(P1)
	RRL
	ST	3(P1)
	JMP	SV_RTRN(P3)

INT:	XRE
INT1:	XAE
INT2:	SCL
	LD	(P1)
	JP	INT3
	CAI	0x96
	JZ	INT4
	JP	SV_RTRN(P3)
INT3:	LD	1(P1)
	ADD	1(P1)
	LD	1(P1)
	RRL
	ST	1(P1)
	LD	2(P1)
	RRL
	ST	2(P1)
	LD	3(P1)
	RRL
	ST	3(P1)
	ILD	(P1)
	CSA
	JP	INT2
	JMP	INT1
INT4:	XAE
	AND	1(P1)
	JP	NORM
	LDE
	ADD	3(P1)
	ST	3(P1)
	LDE
	ADD	2(P1)
	ST	2(P1)
	LDE
	ADD	1(P1)
	ST	1(P1)
	JMP	ALGN1

; Print vertical tabs (number in AC and determined by stack value.)
VERT:	JP	VERT2
VERT1:	LDI	_CTLK			; used as <vtab> for lines upwards
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	ILD	-17(P2)
	JNZ	VERT1
	JMP	SV_RTFUNC(P3)
VERT2:	OR	-17(P2)
	JZ	SV_RTFUNC(P3)		; do nothing if zero
VERT3:	LDI	_LF			; lines downwards
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	DLD	-17(P2)
	JNZ	VERT3
	JMP	SV_RTFUNC(P3)

; Align exponents of two floating point numbers on arithmetics stack.
; NOTE: Pointer P1 contains actual arithmetics stack.
ALGEXP:	SCL
	LD	(P1)			; compare the exponents of the floats
	CAD	4(P1)
	JZ	SV_RTRN(P3)		; all done when equal
	CSA
	JP	ALG2
	LDI	4
	ST	-23(P2)			; store as temporary counter
ALG1:	LD	@1(P1)			; swap two floats on STACK
	XAE
	LD	3(P1)
	ST	-1(P1)
	LDE
	ST	3(P1)
	DLD	-23(P2)
	JNZ	ALG1			; handle four bytes
	LD	@-4(P1)
ALG2:	ILD	(P1)			; increment exponent..
	LD	1(P1)			; ..and shift mantissa one bit right
	ADD	1(P1)
	LD	1(P1)
	RRL
	ST	1(P1)
	LD	2(P1)
	RRL
	ST	2(P1)
	LD	3(P1)
	RRL
	ST	3(P1)
	JMP	ALGEXP

; Load arithmetics stack into P1 and save previous content.
STACK:	LD	AEXOFF(P2)
	XPAL	P1
	ST	-13(P2)
	LD	STKPHI(P3)
	XPAH	P1
	ST	-14(P2)
	JMP	SV_SPLOAD(P3)

; Convert 4-byte floating point number to ASCII-representation,
; store beyond number as string (terminated by <null> byte.)
; NOTE: Pointer P1 contains actual arithmetics stack.
; 4 BYTES: CHARA MAN1 MAN2 MAN3, EXP = CHARA - 128
; MAN1 bits 7:6 b'10' negative (whole mantissa 2's complement), bits 7:6 b'01' positive
; AEXOFF = AEXSTK-4, means one fp number on AEX STACK
; scratch is 4 bytes lower as fp number
; NOTE:	DB	0x83, 0x50, 0, 0	; DCM  10.0
;	DB	0x82, 0xB0, 0, 0	; DCM -10.0
FNUM:	LDI	0			; load zero
	ST	CHRNUM(P2)	; digit counter or sign ? 0 = positive ?
	LDI	' '			; load <space> for positive number
	ST	-5(P1)			; store 5 bytes lower (below scratch)
	LD	1(P1)
	JZ	FZERO			; is MSB of mantissa <null> ?
	JP	FDIG10			; go, mantissa is positive
	LDI	'-'			; load <minus> for negative number
	ST	-5(P1)			; store 5 bytes lower (below scratch)
	SCL
	LDI	0			; negate number on AEX STACK
	CAD	3(P1)
	ST	3(P1)
	LDI	0
	CAD	2(P1)
	ST	2(P1)
	LDI	0
	CAD	1(P1)
	ST	1(P1)			; now positive BUT sometimes bit7 set!
; NOTE:	now invert bit7 of exponent (strip characteristic)
FDIG10:	LD	(P1)
	XRI	0x80
; NOTE:	If number is positive, skip and fall through directly to ZERO
	JP	FZERO			; go, exponent is positive
	CALL	NEGEXP
FZERO:	LDI	1
	ST	-4(P1)			; store 1 in temporary
	LD	1(P1)			; load MANT1
	JZ	FDIG19			; go, MANT1 is zero
FDIG13:	LDI	0xA0			; load b'10100000' 10<<4 ?
	XAE				; preserve in E
	LD	3(P1)			; copy number four bytes down in SCRATCH
	ST	-1(P1)
	LD	2(P1)
	ST	-2(P1)
	LD	1(P1)
	ST	-3(P1)
	LDI	0			; set top mantissa to zero
	ST	3(P1)
	ST	2(P1)
	ST	1(P1)
	LDI	24			; shift 24 bit
	ST	-6(P1)			; store bit counter
FDIGLP:	SCL				; shift left loop
	LD	-3(P1)			; load MANT1
	CAI	0x50			; subtract b'01010000' 10<<3 ?
	JP	FDIG15			; go, greater / equal 10
	JMP	FDIG16			; otherwise subtraction "failed"
FDIG15:	ST	-3(P1)			; store again
	ILD	3(P1)			; increase quotient
FDIG16:	DLD	-6(P1)			; decrease shift counter
	JZ	FDIG17			; zero, shift loop complete
	CCL
	LDE				; E holds 0xA0, see above
	ADE
	XAE
	LD	-1(P1)
	ADD	-1(P1)
	ST	-1(P1)
	LD	-2(P1)
	ADD	-2(P1)
	ST	-2(P1)
	LD	-3(P1)
	ADD	-3(P1)
	ST	-3(P1)
; NOTE: shifted E and mantissa 1 bit left
	LD	3(P1)
	ADD	3(P1)
	ST	3(P1)
	LD	2(P1)
	ADD	2(P1)
	ST	2(P1)
	LD	1(P1)
	ADD	1(P1)
	ST	1(P1)
; NOTE: shifted quotient 1 bit left
	JMP	FDIGLP			; continue shift loop
FDIG17:	LD	1(P1)			; comes here from shift loop
	JP	FDIG18			; test bit7 of QUOTIENT1
; NOTE:	bit7 set, so shift quotient right one bit (dividde by 2)
	CCL
	RRL
	ST	1(P1)
	LD	2(P1)
	RRL
	ST	2(P1)
	LD	3(P1)
	RRL
	ST	3(P1)
; NOTE:	compensate divide by increasing exp by one
	ILD	(P1)
FDIG18:	SCL
	LD	(P1)
	CAI	4			; subtract exponent by 4
	ST	(P1)
	JP	FDIG19
	ILD	-4(P1)			; increase temporary
	JMP	FDIG13
FDIG19:	LD	-4(P1)			; load temporary
	ST	COUNTR(P2)		; store on STACK -21
	LD	CHRNUM(P2)		; load digit counter
	JNZ	FDIG20
	SCL
	LDI	6			; maximal digit limit ?
	CAD	-4(P1)
	JP	FDIG20			; not reached
	DLD	-4(P1)			; decrease temporary..
	ST	CHRNUM(P2)		; ..store as digit counter
	LDI	1
	ST	-4(P1)			; store one in temporary
FDIG20:	CCL
	LD	1(P1)
	RRL
	ST	1(P1)
	LD	2(P1)
	RRL
	ST	2(P1)
	LD	3(P1)
	RRL
	ST	3(P1)
	LDE
	RRL
	XAE
	ILD	(P1)
	XRI	0x86
	JNZ	FDIG20
; shifted E and quotient 1 bit right until exp equal 6
	LDE
	ADI	2
	ST	1(P1)
	LDI	5
	ST	(P1)
; NOTE:	advance AEX STACK pointer to begin of number string
	LD	@-5(P1)
	CSA
; NOTE: Bit7 in status reg is carry/link.
	JP	FDEC
	ILD	8(P1)			; was before 3(P1)
	JNZ	FDEC
	ILD	7(P1)			; was before 2(P1)
	JNZ	FDEC
	LDI	'1'
	ST	@-1(P1)			; increase and store <one>
	LD	CHRNUM(P2)		; load digit counter
	JNZ	FDIG21
	LD	2(P1)			; temporary, was before -4(P1) ?
	XRI	6
	JNZ	FDEC
	ADI	5
FDIG21:	ADI	0
	ST	CHRNUM(P2)		; store digit counter
	JMP	FEXP
FDEC:	CALL	BINDEC			; convert binary to decimal
	LD	CHRNUM(P2)		; load digit counter
	JZ	FNUMND 
FEXP:	XAE				; calculate decimal exponent
	LDI	'E'
	ST	@-1(P1)			; store 'E' for exponent
	LDE				; E holds exponent
	JP	FEXP1			; positive exponent ?
	LDI	'-'
	ST	@-1(P1)			; store <minus> for negative exponent
FEXP1:	SCL
	LDE
	ANI	0x7F			; strip characteristic
	CAI	10			; subtract 10
	JP	FEXP2			; exponent is equal / greater 10
	JMP	FEXPD
FEXP2:	XAE
	LDI	'0'
	ST	@-1(P1)			; decrease and store <zero>
FEXP3:	ILD	(P1)			; increase digit
	LDE
	CAI	10			; subtract 10 while positive and increase counter
	XAE
	LDE
	JP	FEXP3			; exponent still equal / greater 10
FEXPD:	ADI	'9'+1			; calculate ASCII value of latest digit
	ST	@-1(P1)			; decrease and store ASCII digit
FNUMND:	LDI	0			; load <null>
	ST	@-1(P1)			; and store as string delimiter
	JMP	SV_SPLOAD(P3)

; Special treatment for floats with negative exponent.
NEGEXP:	CCL				; exponent is negative
	ADI	9			; add 9 (lb 512 = 9)
	JP	NEGSKP			; exponent < 9, so < 1/512 or >= -1/512
	LDI	0x80			; load 128
	ST	CHRNUM(P2)	; digit counter or sign ? 128 = negative ?
; NOTE:
; Following only if exponent is negative and greater/equal -1/512 or less than 1/512.
; Printed number will then have scientific notation,
; so count zero before and zero(s) behind decimal point.
; -1/512 = -1.95312E-3 and 1/512 = 0.00195
FDIG11:	ILD	CHRNUM(P2)		; increase digit counter by one
	CCL
	LD	1(P1)			; shift MANT1 right
	RRL
	ST	-3(P1)			; store 4 bytes lower SCRATCH1
	LD	2(P1)			; shift MANT2 right
	RRL
	ST	-2(P1)			; store 4 bytes lower SCRATCH2
	LD	3(P1)			; shift MANT3 right
	RRL
	ST	-1(P1)			; store 4 bytes lower SCRATCH3
; NOTE:	shifted mantissa one bit right and stored in scratch
; scratch = mantissa / 2
	CCL
	LD	-3(P1)			; shift SCRATCH1 right
	RRL
	ST	-3(P1)			; store in SCRATCH1
	LD	-2(P1)			; shift SCRATCH2 right
	RRL
	ST	-2(P1)			; store in SCRATCH2
	LD	-1(P1)			; shift SCRATCH3 right
	RRL
	ST	-1(P1)			; store in SCRATCH3
; NOTE:	shifted scratch one bit right,
; scratch = scratch / 2
	LD	3(P1)
	ADD	-1(P1)
	ST	3(P1)
	LD	2(P1)
	ADD	-2(P1)
	ST	2(P1)
	LD	1(P1)
	ADD	-3(P1)
	ST	1(P1)
; NOTE: added mantissa and scratch
; result = mantissa + mantissa / 4
	JP	FDIG12			; bit7=0, so no more shift right
	CCL
	RRL
	ST	1(P1)
	LD	2(P1)
	RRL
	ST	2(P1)
	LD	3(P1)
	RRL
	ST	3(P1)
; NOTE: mantissa has an extra shift right
	ILD	(P1)			; increase exponent
FDIG12:	CCL
	LD	(P1)
	ADI	3
	ST	(P1)			; add 3 to exponent (multiply mantissa by 8)
	JP	FDIG11			; positive, repeat
NEGSKP:	RTRN

; Convert binary to decimal number, digits are stored on arithmetics stack.
BINDEC:	LD	AEXOFF(P2)		; load P2 with offset to topmost number
	XPAL	P2
FDEC1:	LDI	6			; evaluate decimal fraction
	XAE
; NOTE:	E holds b'00000110', after 3 left shifts it is b'0011xxxx'.
;	After multiplication by 10 there is the searched decimal as ASCII digit
	CCL
	LD	1(P2)
	ADD	1(P2)
	ST	-1(P2)
	LD	3(P2)
	ADD	3(P2)
	ST	-2(P2)
	LD	2(P2)
	ADD	2(P2)
	ST	-3(P2)
	LDE
	ADE
	XAE
; NOTE: shifted quotient and E one bit left and store result in scratch and E
	LD	-1(P2)
	ADD	-1(P2)
	ST	-1(P2)
	LD	-2(P2)
	ADD	-2(P2)
	ST	-2(P2)
	LD	-3(P2)
	ADD	-3(P2)
	ST	-3(P2)
	LDE
	ADE
	XAE
; NOTE: shifted scratch and E one bit left,
; result = quotient * 4
	LD	1(P2)
	ADD	-1(P2)
	ST	1(P2)
	LD	3(P2)
	ADD	-2(P2)
	ST	3(P2)
	LD	2(P2)
	ADD	-3(P2)
	ST	2(P2)
	LDE
	ADI	0			; take care of carry/link
	XAE
; NOTE: added scratch to quotient
; result = 4 * quotient + quotient = 5 * quotient
	LD	1(P2)
	ADD	1(P2)
	ST	1(P2)
	LD	3(P2)
	ADD	3(P2)
	ST	3(P2)
	LD	2(P2)
	ADD	2(P2)
	ST	2(P2)
	LDE
	ADE
	ST	@-1(P1)			; store as next decimal digit
; NOTE:	shifted modified quotient one bit left
; result = (5 * quotient) * 2 = 10 * quotient
	DLD	(P2)
	DLD	-4(P2)
	JNZ	FDEC2
	LDI	'.'			; load <period>
	ST	@-1(P1)			; store as decimal point
FDEC2:	LD	(P2)
	JP	FDEC1
FDEC3:	LD	@1(P1)			; get byte from number string and increase
	XRI	'0'			; is it leading <zero> ?
	JZ	FDEC3			; yes, just eat it
	ANI	0xF0
	JNZ	FDEC4			; was there another digit ?
	LD	@-1(P1)			; yes, set back to previous byte
FDEC4:	LDI	STKMID			; load P2 with STACK
	XPAL	P2
	RTRN

; restore only P1, leave top of AEX STACK unchanged.
STPBCK:	LD	-13(P2)
	XPAL	P1
	LD	-14(P2)
	XPAH	P1
	JMP	SV_SPLOAD(P3)

; Characteristic has bias 128, so subtract 128 to obtain exponent
; 00 = -128 ... 7F = -1, 80 = 0, 81 = +1 ... FF = +127
; e is Euler's number
; 80 5C 55 1E	L2E	DCM 1.4426950409	; log base 2 of e ( lb e )
; 86 57 6A E1	A2	DCM 87.417497202
; 89 4D 3F 1D	B2	DCM 617.9722695
; 7B 46 FA 70	C2	DCM 0.034657359		; (ln 2) / 20
; 83 4F A3 03	D	DCM 9.9545957821
; 7E 6F 2D ED	L10E	DCM 0.4342945		; log base 10 of e ( log e )
; 7E 4D 10 4D	L102	DCM 0.301029996		; log base 10 of 2 ( log 2 )
; 80 5A 82 7A	R22	DCM 1.414213562		; sqrt(2)
; 7F 58 B9 0C	LE2	DCM 0.69314718		; log base e of 2 ( ln 2 )
; 80 52 B0 40	A1	DCM 1.2920074
; 81 AB 86 49	MB	DCM -2.6398577
; 80 6A 08 66	C	DCM 1.6567626
; 7F 40 00 00	MHLF	DCM 0.5
; 7E 80 00 00	MMHLF	DCM -0.5
; 80 40 00 00	ONE	DCM 1.0
; 7F 80 00 00	MONE	DCM -1.0
; 81 64 87 ED	PI	DCM 3.14159265		; circle number

; Put logarithmic base 10 of 2 ( log 2 ) on stack.
LG2:	LDI	0x4D
	ST	@-1(P1)
	ST	@-2(P1)
	LDI	0x10
	ST	1(P1)
	LDI	0x7E
	ST	@-1(P1)			; 7E 4D 10 4D -> DCM 0.301029996
	JMP	SV_SPLOAD(P3)

; Put logarithmic base e of 2 ( ln 2 ) on stack.
LN2:	LDI	0x0C
	ST	@-1(P1)
	LDI	0xB9
	ST	@-1(P1)
	LDI	0x58
	ST	@-1(P1)
	LDI	0x7F
	ST	@-1(P1)			; 7F 58 B9 0C -> DCM 0.69314718
	JMP	SV_SPLOAD(P3)

; Calculate natural log of topmost floating point number.
; NOTE: Pointer P1 contains actual arithmetics stack.
LOG2:	LD	1(P1)
	JP	LOG21
LGERR:	LDI	(M_ARG-M_BASE)		; 'ARGUMENT ERROR', can not be negative..
	JMP	SV_MSGOUT(P3)
LOG21:	OR	2(P1)
	OR	3(P1)
	JZ	LGERR			; ..let alone zero
	LDI	0
	ST	-1(P1)
	LD	(P1)
	XRI	0x80			; complement sign bit of original exp
	ST	-3(P1)
	LDI	0x80
	ST	(P1)
	ST	-2(P1)
	LDI	0x86
	ST	@-4(P1)
	CALL	NORM
	CALL	SWAP
	LD	3(P1)
	ST	-1(P1)
	LD	2(P1)
	ST	-2(P1)
	LD	1(P1)
	ST	-3(P1)
	LD	(P1)
	ST	@-4(P1)			; adjust stack by four down
	LDI	0x7A			; load sqrt(2) on stack
	ST	@-1(P1)
	LDI	0x82
	ST	@-1(P1)
	LDI	0x5A
	ST	@-1(P1)
	LDI	0x80
	ST	@-1(P1)			; 80 5A 82 7A -> DCM 1.414213562 ( SQRT(2) )
	CALL	FSUB			; z - sqrt(2)
	CALL	SWAP
	LDI	0x7A			; load sqrt(2) on stack
	ST	@-1(P1)
	LDI	0x82
	ST	@-1(P1)
	LDI	0x5A
	ST	@-1(P1)
	LDI	0x80
	ST	@-1(P1)			; 80 5A 82 7A -> DCM 1.414213562 ( SQRT(2) )
	CALL	FADD			; z + sqrt(2)
	CALL	FDIV			; z - sqrt(2) / z + sqrt(2)
	LDI	0x49			; load mb on stack
	ST	@-1(P1)
	LDI	0x86
	ST	@-1(P1)
	LDI	0xAB
	ST	@-1(P1)
	LDI	0x81
	ST	@-1(P1)			; 81 AB 86 49 -> DCM -2.6398577 ( MB )
	LD	7(P1)
	ST	-1(P1)
	ST	-5(P1)
	LD	6(P1)
	ST	-2(P1)
	ST	-6(P1)
	LD	5(P1)
	ST	-3(P1)
	ST	-7(P1)
	LD	4(P1)
	ST	-4(P1)
	ST	@-8(P1)
	CALL	FMUL			; t * t
	LDI	0x66			; load c on stack
	ST	@-1(P1)
	LDI	8
	ST	@-1(P1)
	LDI	0x6A
	ST	@-1(P1)
	LDI	0x80
	ST	@-1(P1)			; 80 6A 08 66 -> DCM 1.6567626 ( C )
	CALL	FSUB			; t * t -c 
	CALL	FDIV			; mb / (t * t - c)
	LDI	0x40			; load a1 on stack
	ST	@-1(P1)
	LDI	0xB0
	ST	@-1(P1)
	LDI	0x52
	ST	@-1(P1)
	LDI	0x80
	ST	@-1(P1)			; 80 52 B0 40 -> DCM 1.2920074 ( A1 )
	CALL	FADD			; mb / (t * t - c) + a1
	CALL	FMUL			; (mb / (t * t - c) + a1) * t
	CALL	FADD
	JMP	SV_SPLOAD(P3)

; Calculate exponentiation.
; NOTE: Pointer P1 contains actual arithmetics stack.
EXP2:	LDI	0
	ST	-1(P1)
	ST	-2(P1)
	LD	1(P1)
	JNZ	EXP21
	LDI	0x80
	ST	(P1)
	SR
	ST	1(P1)
	JMP	SV_SPLOAD(P3)
EXP21:	ST	-3(P1)
	LD	(P1)
	ST	@-4(P1)
EXP22:	SCL
	LDI	0x86
	CAD	(P1)
	JZ	EXP25
	JP	EXP24
	LD	1(P1)
	JP	EXP23
	LD	@4(P1)
	LDI	0
	ST	3(P1)
	ST	2(P1)
	ST	1(P1)
	ST	(P1)
	JMP	SV_SPLOAD(P3)
EXP23:	LDI	(M_OVRF-M_BASE)		; 'OVERFLOW ERROR'
	JMP	SV_MSGOUT(P3)
EXP24:	LD	1(P1)
	ADD	1(P1)
	LD	1(P1)
	SRL
	ST	1(P1)
	ILD	(P1)
	JMP	EXP22
EXP25:	LD	1(P1)
	ST	-24(P2)
	CALL	NORM
	CALL	FSUB
	LDI	0x70
	ST	@-1(P1)
	LDI	0xFA
	ST	@-1(P1)
	LDI	0x46
	ST	@-1(P1)
	LDI	0x7B
	ST	@-1(P1)			; 7B 46 FA 70 -> DCM .03465735903 ( C2 )
	LD	7(P1)
	ST	-1(P1)
	ST	-5(P1)
	LD	6(P1)
	ST	-2(P1)
	ST	-6(P1)
	LD	5(P1)
	ST	-3(P1)
	ST	-7(P1)
	LD	4(P1)
	ST	-4(P1)
	ST	@-8(P1)
	CALL	FMUL
	CALL	FMUL
	LDI	0xE1
	ST	@-5(P1)
	LDI	0x6A
	ST	@-1(P1)
	LDI	0x57
	ST	@-1(P1)
	LDI	0x86
	ST	@-1(P1)			; 86 57 6A E1 -> DCM 87.417497202 ( A2 )
	CALL	FADD			; z * z + a2
	LDI	0x1D
	ST	@-1(P1)
	LDI	0x3F
	ST	@-1(P1)
	LDI	0x4D
	ST	@-1(P1)
	LDI	0x89
	ST	@-1(P1)			; 89 4D 3F 1D -> DCM 617.9722695 ( B2 )
	LD	5(P1)
	XOR	1(P1)
	ST	-22(P2)
	CALL	SWAP
	CALL	FDIV0
	CALL	FSUB
	LD	7(P1)
	ST	-1(P1)
	LD	6(P1)
	ST	-2(P1)
	LD	5(P1)
	ST	-3(P1)
	LD	4(P1)
	ST	@-4(P1)
	CALL	FSUB
	LDI	3
	ST	@-1(P1)
	LDI	0xA3
	ST	@-1(P1)
	LDI	0x4F
	ST	@-1(P1)
	LDI	0x83
	ST	@-1(P1)			; 83 4F A3 03 -> DCM 9.9545957821 ( D )
	CALL	FADD			; d + c2 * z * z - b2 / (z * z + a2)
	CALL	FDIV			; z / (d + c2 * z * z - b2 / (z * z + a2))
	LDI	0
	ST	@-1(P1)
	ST	@-1(P1)
	LDI	0x40
	ST	@-1(P1)
	LDI	0x7F
	ST	@-1(P1)			; 7F 40 00 00 -> DCM 0.5 ( MHLF )
	CALL	FADD			; z / (d + c2 * z * z - b2 / (z * z + a2)) + 0.5
	SCL
	LD	-24(P2)
	ADD	(P1)
	ST	(P1)
	JMP	SV_SPLOAD(P3)

; Modulo operation
; Return remainder or signed remainder of a division.
; NOTE: Pointer P1 is set to actual arithmetics stack.
FMOD:	CALL	ABSWP
	CCL
	LD	4(P1)
	CAD	@4(P1)
	CALL	MD
FMOD1:	SCL
	LD	-5(P1)
	CAD	-1(P1)
	ST	-5(P1)
	LD	-6(P1)
	CAD	-2(P1)
	ST	-6(P1)
	LD	-7(P1)
	CAD	-3(P1)
	ST	-7(P1)
	JP	FMOD2
	LD	-5(P1)
	ADD	-1(P1)
	ST	-5(P1)
	LD	-6(P1)
	ADD	-2(P1)
	ST	-6(P1)
	LD	-7(P1)
	ADD	-3(P1)
	ST	-7(P1)
	JMP	FMOD3
FMOD2:	ILD	3(P1)
FMOD3:	DLD	-8(P1)
	CAI	1
	JP	FMOD5
	LD	(P1)
	JZ	FMOD10
	JP	FMOD7
FMOD4:	DLD	(P1)
	LD	1(P1)
	ANI	0x3F
	ST	1(P1)
FMOD5:	CCL
	LD	-5(P1)
	ADD	-5(P1)
	ST	-5(P1)
	LD	-6(P1)
	ADD	-6(P1)
	ST	-6(P1)
	LD	-7(P1)
	JP	FMOD6
	LDI	(M_DIV0-M_BASE)		; 'DIVISION BY 0 ERROR'
	JMP	SV_MSGOUT(P3)
FMOD6:	ADD	-7(P1)
	ST	-7(P1)
	LD	3(P1)
	ADD	3(P1)
	ST	3(P1)
	LD	2(P1)
	ADD	2(P1)
	ST	2(P1)
	LD	1(P1)
	ADD	1(P1)
	ST	1(P1)
	JMP	FMOD1
FMOD7:	XRI	0x7F
	JNZ	FMOD8
	LD	1(P1)
	JP	FMOD9
	ANI	0x7F
	ST	1(P1)
FMOD8:	LD	1(P1)
FMOD9:	ANI	0xC0
	JZ	FMOD4
	JP	FMOD10
	CALL	ALGN2
FMOD10:	LD	-22(P2)
	JP	SV_SPLOAD(P3)
	CALL	FNEG
	JMP	SV_SPLOAD(P3)

; Push four bytes on STACK and swap with former topmost four bytes.
PSHSWP:	LD	@-4(P1)			; reserve four bytes on STACK
	LDI	4
	ST	-23(P2)			; temporary counter
SWP1:	LD	@1(P1)			; get byte from STACK and increase
	XAE
	LD	3(P1)
	ST	-1(P1)
	LDE
	ST	3(P1)
	DLD	-23(P2)			; decrease counter
	JNZ	SWP1			; loop four times
	LD	@-4(P1)			; reset STACK
	JMP	SV_SPLOAD(P3)

; Number on AEXSTK represents fractional part of decimal number
; and is transformed into the corresponding binary float.
; NOTE: Pointer P1 is set to actual arithmetics stack.
FD10:	LD	1(P1)
	JZ	SV_SPLOAD(P3)
FD11:	LDI	0xA0
	XAE
	LD	3(P1)			
	ST	-1(P1)
	LD	2(P1)
	ST	-2(P1)
	LD	1(P1)
	ST	-3(P1)			; topmost 3-byte number is copied downwards
	LDI	0
	ST	3(P1)			; topmost 3 bytes are set to zero..
	ST	2(P1)
	ST	1(P1)			; ..and used as mantissa
	LDI	0x18			; corresponding to 24 bit
	ST	-4(P1)			; store as bit counter
FD12:	SCL
	LD	-3(P1)
	CAI	0x50
	JP	FD13
	JMP	FD14
FD13:	ST	-3(P1)
	ILD	3(P1)
FD14:	DLD	-4(P1)			; decrease bit counter
	JZ	FD15			; all bits processed ?
	CCL				; clear carry for addition
; NOTE:	both mantissas are shifted left one bit (multiplied by 2)
	LDE
	ADE
	XAE
	LD	-1(P1)
	ADD	-1(P1)
	ST	-1(P1)
	LD	-2(P1)
	ADD	-2(P1)
	ST	-2(P1)
	LD	-3(P1)
	ADD	-3(P1)
	ST	-3(P1)
	LD	3(P1)
	ADD	3(P1)
	ST	3(P1)
	LD	2(P1)
	ADD	2(P1)
	ST	2(P1)
	LD	1(P1)
	ADD	1(P1)
	ST	1(P1)
	JMP	FD12
; NOTE:	topmost mantissa is shifted right one bit (divided by 2)
FD15:	LD	1(P1)
	JP	FD16
	CCL
	RRL
	ST	1(P1)
	LD	2(P1)
	RRL
	ST	2(P1)
	LD	3(P1)
	RRL
	ST	3(P1)
	ILD	(P1)
FD16:	SCL
	LD	(P1)
	CAI	4
	ST	(P1)
	XRI	0x80
	JP	FD11
	DLD	-24(P2)			; take the digit count from TESTN routine
	JP	FD11			; process all digits
	JMP	SV_SPLOAD(P3)		; we're done

; Build-in the number for the negative exponent to binary float.
; Divide binary representation on AEXSTK by 10 and adjust exponent.
FDIV11:	LD	AEXOFF(P2)
	XPAL	P2
	LD	@2(P2)			; load MSB of number, advance 2 bytes
	JNZ	SV_VALERR(P3)		; exponent > 255 not valid	
	LD	1(P2)
	JZ	FDEND
FDIV12:	SCL
	LD	(P2)
	CAI	4
	XAE
	LD	3(P2)
	ST	-2(P2)
	LD	2(P2)
	ST	-3(P2)
	LD	1(P2)
	ST	-4(P2)			; topmost 3-byte number is copied downwards
	LDI	0
	ST	3(P2)			; topmost 4 bytes are set to zero..
	ST	2(P2)
	ST	1(P2)
	ST	(P2)			; ..and used as mantissa with exponent
	CSA
	JP	FDEND
	LDI	0xA0
	XAE
	ST	(P2)
	LDI	0x18			; corresponding to 24 bit
	ST	-5(P2)			; store as temporary counter
FDIV13:	SCL
	LD	-4(P2)
	CAI	0x50
	JP	FDIV14
	JMP	FDIV15
FDIV14:	ST	-4(P2)
	ILD	3(P2)
FDIV15:	DLD	-5(P2)			; decrease bit counter
	JZ	FDIV16			; all bits processed ?
	CCL
	LDE
	ADE
	XAE
	LD	-2(P2)
	ADD	-2(P2)
	ST	-2(P2)
	LD	-3(P2)
	ADD	-3(P2)
	ST	-3(P2)
	LD	-4(P2)
	ADD	-4(P2)
	ST	-4(P2)
	LD	3(P2)
	ADD	3(P2)
	ST	3(P2)
	LD	2(P2)
	ADD	2(P2)
	ST	2(P2)
	LD	1(P2)
	ADD	1(P2)
	ST	1(P2)
	JMP	FDIV13
FDIV16:	LD	1(P2)
	JP	FDIV17
	CCL
	RRL
	ST	1(P2)
	LD	2(P2)
	RRL
	ST	2(P2)
	LD	3(P2)
	RRL
	ST	3(P2)
	ILD	(P2)
FDIV17:	DLD	-1(P2)
	JNZ	FDIV12
FDEND:	LDI	STKMID
	XPAL	P2
	ST	AEXOFF(P2)		; store last AEXSTK.L
	JMP	SV_RTFUNC(P3)

; Build-in the number for the positive exponent to binary float.
; Multiply binary representation on AEXSTK by 10 and adjust exponent.
FMUL11:	LD	AEXOFF(P2)
	XPAL	P2
	LD	@2(P2)			; load MSB of number, advance 2 bytes
	JNZ	SV_VALERR(P3)		; exponent > 255 not valid
	LD	1(P2)
	JZ	FMEND
FMUL12:	CCL
	LD	1(P2)
	RRL
	ST	-4(P2)
	LD	2(P2)
	RRL
	ST	-3(P2)
	LD	3(P2)
	RRL
	ST	-2(P2)
	CCL
	LD	-4(P2)
	RRL
	ST	-4(P2)
	LD	-3(P2)
	RRL
	ST	-3(P2)
	LD	-2(P2)
	RRL
	ST	-2(P2)
	LD	3(P2)
	ADD	-2(P2)
	ST	3(P2)
	LD	2(P2)
	ADD	-3(P2)
	ST	2(P2)
	LD	1(P2)
	ADD	-4(P2)
	ST	1(P2)
	JP	FMUL13
	CCL
	RRL
	ST	1(P2)
	LD	2(P2)
	RRL
	ST	2(P2)
	LD	3(P2)
	RRL
	ST	3(P2)
	ILD	(P2)
	JZ	FMUL14
FMUL13:	CCL
	LD	(P2)
	ADI	3
	ST	(P2)
	CSA
	JP	FMUL15
FMUL14: LDI	(M_OVRF-M_BASE)		; 'OVERFLOW ERROR'
	JMP	SV_RTERRN(P3)
FMUL15:	DLD	-1(P2)
	JNZ	FMUL12
FMEND:	LDI	STKMID
	XPAL	P2
	ST	AEXOFF(P2)		; store last AEXSTK.L
	JMP	SV_RTFUNC(P3)

; Calculate the trigonometric function arctangens by a Taylor series.
ATN:	LD	1(P1)
	JZ	SV_SPLOAD(P3)
	ST	-24(P2)
	JP	ATN1
	CALL	FNEG
ATN1:	LD	(P1)
	ST	COUNTR(P2)
	JP	ATN2
	ST	@-4(P1)
	LD	5(P1)
	ST	1(P1)
	LD	6(P1)
	ST	2(P1)
	LD	7(P1)
	ST	3(P1)
	LDI	0x80
	ST	4(P1)
	SR
	ST	5(P1)
	LDI	0
	ST	6(P1)
	ST	7(P1)
	CALL	FDIV
ATN2:	LDI	0x81
	ST	-1(P1)
	LDI	0xD5
	ST	-2(P1)
	LDI	0x6B
	ST	-3(P1)
	LDI	0x7B
	ST	-4(P1)			; 7B 6B D5 81 -> DCM 0.05265332
	LDI	0xDD
	ST	-5(P1)
	LDI	0xFA
	ST	-6(P1)
	LDI	0x9F
	ST	-7(P1)
	LDI	0x79
	ST	-8(P1)			; 79 9F FA DD -> DCM -0.0117212
	LD	3(P1)
	ST	-9(P1)
	ST	-13(P1)
	LD	2(P1)
	ST	-10(P1)
	ST	-14(P1)
	LD	1(P1)
	ST	-11(P1)
	ST	-15(P1)
	LD	(P1)
	ST	-12(P1)
	ST	@-16(P1)
	CALL	FMUL
	CALL	FMUL
	CALL	FADD
	LDI	0xD2
	ST	-1(P1)
	LDI	0xC5
	ST	-2(P1)
	LDI	0x88
	ST	-3(P1)
	LDI	0x7C
	ST	@-4(P1)
	CALL	SWPMUL
	LDI	0x21
	ST	-1(P1)
	LDI	0x18
	ST	-2(P1)
	LDI	0x63
	ST	-3(P1)
	LDI	0x7D
	ST	@-4(P1)			; 7D 63 18 21 -> DCM 0.1935435
	CALL	SWPMUL
	LDI	0x30
	ST	-1(P1)
	LDI	0xD9
	ST	-2(P1)
	LDI	0xAA
	ST	-3(P1)
	LDI	0x7E
	ST	@-4(P1)			; 7E AA D9 30 -> DCM -0.3326235
	CALL	SWPMUL
	LDI	0x41
	ST	-1(P1)
	LDI	0xFF
	ST	-2(P1)
	LDI	0x7F
	ST	-3(P1)			; 7F 7F FF 41 -> DCM 0.9999772
	ST	@-4(P1)
	CALL	SWPMUL
	CALL	FMUL
	LD	COUNTR(P2)
	JP	ATN3
	CALL	PI2
	CALL	SWAP
	CALL	FSUB
ATN3:	LD	-24(P2)
	JP	SV_SPLOAD(P3)
	CALL	FNEG
	JMP	SV_SPLOAD(P3)

; Bytewise swap topmost two floating point numbers,
; multiply and add.
SWPMUL:	LDI	4
	ST	-23(P2)			; store as byte counter
SWPM:	LD	@1(P1)			; get byte from STACK and increase
	ST	-9(P1)
	LD	3(P1)
	ST	-1(P1)
	LD	-9(P1)
	ST	3(P1)
	DLD	-23(P2)
	JNZ	SWPM
	LD	@-8(P1)
	CALL	FMUL
	CALL	FADD
	RTRN

; Put half of circle number PI (90 degrees) onto STACK.
PI2:	LDI	0xED
	ST	@-1(P1)
	LDI	0x87
	ST	@-1(P1)
	LDI	0x64
	ST	@-1(P1)
	LDI	0x80
	ST	@-1(P1)
	RTRN

; Calculate the trigonometric functions tangens and sinus by Taylor series.
TAN:	LD	3(P1)
	ST	-1(P1)
	LD	2(P1)
	ST	-2(P1)
	LD	1(P1)
	ST	-3(P1)
	LD	(P1)
	ST	@-4(P1)
SIN:	LD	1(P1)
	JZ	SV_SPLOAD(P3)
	ST	-24(P2)
	JP	SIN1
	CALL	FNEG
SIN1:	LDI	0xEC
	ST	-1(P1)
	LDI	0x87
	ST	-2(P1)
	LDI	0x64
	ST	-3(P1)
	LDI	0x80
	ST	@-4(P1)			; 80 64 87 EC -> DCM 
	CALL	FDIV
	LD	(P1)
	JP	SIN4
	LD	3(P1)
	ANI	0xFE
	ST	3(P1)
SIN2:	CCL
	LD	3(P1)
	ADD	3(P1)
	ST	3(P1)
	LD	2(P1)
	ADD	2(P1)
	ST	2(P1)
	LD	1(P1)
	ADD	1(P1)
	ST	1(P1)
	DLD	(P1)
	XRI	0x7F
	JNZ	SIN2
	CSA
	XOR	1(P1)
	CALL	NORM
	JP	SIN4
	CALL	FNEG
SIN4:	SCL
	LD	(P1)
	CAI	0x76
	JP	SIN5
	LD	@-4(P1)
	CALL	FMUL
	JMP	SIN7
SIN5:	CAI	10
	JZ	SIN7
	ADI	1
	JNZ	SIN6
	SRL
	XOR	1(P1)
	OR	2(P1)
	OR	3(P1)
	JZ	SIN7
SIN6:	LDI	0x37
	ST	-1(P1)
	LDI	0x65
	ST	-2(P1)
	LDI	0x51
	ST	-3(P1)
	LDI	0x7C
	ST	-4(P1)			; 7C 51 65 37 -> DCM 
	LDI	0x73
	ST	-5(P1)
	LDI	0x86
	ST	-6(P1)
	LDI	0xB8
	ST	-7(P1)
	LDI	0x78
	ST	-8(P1)			; 78 B8 86 73 -> DCM 
	LD	3(P1)
	ST	-9(P1)
	ST	-13(P1)
	LD	2(P1)
	ST	-10(P1)
	ST	-14(P1)
	LD	1(P1)
	ST	-11(P1)
	ST	-15(P1)
	LD	(P1)
	ST	-12(P1)
	ST	@-16(P1)
	CALL	FMUL
	CALL	FMUL
	CALL	FADD
	LDI	0x76
	ST	-1(P1)
	LDI	0x52
	ST	-2(P1)
	LDI	0xAD
	ST	-3(P1)
	LDI	0x7F
	ST	@-4(P1)			; 7F AD 52 76 -> DCM 
	CALL	SWPMUL
	LDI	0xE7
	ST	-1(P1)
	LDI	0x87
	ST	-2(P1)
	LDI	0x64
	ST	-3(P1)
	LDI	0x80
	ST	@-4(P1)			; 80 64 87 E7 -> DCM 
	CALL	SWPMUL
	CALL	FMUL
SIN7:	LD	-24(P2)
	JP	SV_SPLOAD(P3)
	CALL	FNEG
	JMP	SV_SPLOAD(P3)

; Put circle number PI onto arithmetics stack.
PI:	LD	AEXOFF(P2)
	XPAL	P2
	LDI	0xED
	ST	@-1(P2)
	LDI	0x87
	ST	@-1(P2)
	LDI	0x64
	ST	@-1(P2)
	LDI	0x81
	ST	@-1(P2)
	LDI	STKMID
	XPAL	P2
	ST	AEXOFF(P2)		; store last AEXSTK.L
	JMP	SV_RTFUNC(P3)

; Put ten ( 10 ) as 16-bit number onto arithmetics stack.
TEN:	LD	AEXOFF(P2)
	XPAL	P2
	LDI	L(10)
	ST	@-1(P2)
	LDI	H(10)
	ST	@-1(P2)
	LDI	STKMID
	XPAL	P2
	ST	AEXOFF(P2)		; store last AEXSTK.L
	JMP	SV_SPLOAD(P3)

; Calculate a float random number from 0..1 and put it onto STACK.
RND:	LDI	8
	ST	-23(P2)
	LD	RNDY(P2)
	ST	@-1(P1)
	LD	RNDX(P2)
	ST	@-1(P1)
	LD	RNDF(P2)
	XAE
RND1:	CCL
	LD	RNDY(P2)
	ADD	1(P1)
	ST	RNDY(P2)
	CCL
	LD	RNDX(P2)
	ADD	(P1)
	ST	RNDX(P2)
	CCL
	LD	RNDF(P2)
	ADE
	XAE
	DLD	-23(P2)
	JNZ	RND1
	CCL
	LD	RNDY(P2)
	ADI	7
	RR
	ST	RNDY(P2)
	ST	1(P1)
	CCL
	LD	RNDX(P2)
	ADI	7
	RR
	ST	RNDX(P2)
	ST	(P1)
	CCL
	LDE
	ADI	7
	XAE
	ILD	-96(P2)
	JZ	RND2
	LDE
	ST	RNDF(P2)
RND2:	LD	RNDF(P2)
	XRI	0xFF
	ANI	0x7F
	ST	@-1(P1)
	LDI	0x7F
	ST	@-1(P1)
	JMP	SV_SPLOAD(P3)

; Depending on the sign put +1, 0 or -1 onto STACK.
SGN:	LD	AEXOFF(P2)
	XPAL	P2
	XAE				; E holds STKMID
	LD	1(P2)
	JZ	SGN3			; SGN(0) is 0 so return
	JP	SGN1			; is mantissa positive ?
	LDI	0x7F			; prepare exp and MSB of -1
	ST	(P2)
	LDE
	ST	1(P2)
	JMP	SGN2
SGN1:	LDE				; prepare exp and MSB of +1
	ST	(P2)
	SR
	ST	1(P2)
SGN2:	LDI	0			; complete mantissa with zeros
	ST	2(P2)
	ST	3(P2)
SGN3:	LDE
	XPAL	P2
	JMP	SV_RTFUNC(P3)

; Calculate square root of (positive) number S following Heron's method.
; Iterate over (xi + S / xi) / 2
SQRT:	LD	1(P1)			; load first byte of mantissa
	JP	SQRT1			; go, valid number
	LDI	(M_ARG-M_BASE)		; 'ARGUMENT ERROR', cannot be negative
	JMP	SV_MSGOUT(P3)
SQRT1:	ST	-3(P1)			; test mantissa for zero
	OR	2(P1)
	OR	3(P1)
	JZ	SV_SPLOAD(P3)		; sqrt(0) is 0, we're done
	LD	3(P1)
	ST	-1(P1)
	LD	2(P1)
	ST	-2(P1)
	LD	(P1)
	ST	@-4(P1)			; argument is copied downwards
; NOTE: arithmetics stack was adjusted by four down
	LDI	0
	ST	@-1(P1)
	ST	@-1(P1)
	LDI	0x40
	ST	@-1(P1)			; 7F 40 00 00 -> DCM 0.5
	CCL
	LD	3(P1)
	JP	SQRT2
	SCL
SQRT2:	SRL				; shift right (divide by 2)
	XRI	0x40
	ST	@-1(P1)
	CALL	FDIV
	LDI	4
	ST	-24(P2)			; temporary counter
SQRT3:	LD	3(P1)
	ST	-1(P1)
	LD	2(P1)
	ST	-2(P1)
	LD	1(P1)
	ST	-3(P1)
	LD	(P1)
	ST	@-4(P1)			; adjust arithmetics stack by four down
	LD	11(P1)
	ST	7(P1)
	LD	10(P1)
	ST	6(P1)
	LD	9(P1)
	ST	5(P1)
	LD	8(P1)
	ST	4(P1)
	CALL	FDIV
	LD	@-4(P1)
	CALL	FADD
	DLD	(P1)
	DLD	-24(P2)			; decrease counter
	JNZ	SQRT3			; do four loops
	LD	3(P1)
	ST	7(P1)
	LD	2(P1)
	ST	6(P1)
	LD	1(P1)
	ST	5(P1)
	LD	@4(P1)			; re-adjust arithmetics stack
	ST	(P1)
	JMP	SV_SPLOAD(P3)

; Final action to perform VAL() function.
; Pull pointer P1 from top of arithmetics stack as begin of string
;  and resave on normal STACK -16,15 to be used by RNUM.
VALSTR:	ILD	AEXOFF(P2)		; adjust AEXSTK by two up
	ILD	AEXOFF(P2)
	XPAL	P2
	LD	-1(P2)
	XPAL	P1
	XAE
	LD	-2(P2)
	XPAH	P1
	XPAL	P2
	LDI	STKMID
	XPAL	P2
	ST	-16(P2)
	LDE
	ST	-15(P2)			; store begin of string in STACK -16,-15
	JMP	SV_SPLOAD(P3)

; Convert 16-bit integer into 4-byte float.
FLOAT2:	LD	AEXOFF(P2)
	XPAL	P2
	LD	(P2)
	ST	-1(P2)
	LD	1(P2)
	ST	(P2)
	LDI	0
	ST	1(P2)
	LDI	0x8E			; load +14 as exponent
	ST	@-2(P2)			; adjust two byte down and store exp
FNORM:	LD	1(P2)
	ADD	1(P2)
	XOR	1(P2)
	JP	FNORM1			; go, normalize number
FLEND:	LDI	STKMID			; reset pointer P2
	XPAL	P2
	ST	AEXOFF(P2)		; store last offset to AEXSTK
	JMP	SV_RTFUNC(P3)		; return
FNORM1:	LD	(P2)			; normalize floating point number
	JZ	FLEND
	DLD	(P2)			; decrease exponent..
	CCL				; ..and shift mantissa one bit left
	LD	3(P2)
	ADD	3(P2)
	ST	3(P2)
	LD	2(P2)
	ADD	2(P2)
	ST	2(P2)
	LD	1(P2)
	ADD	1(P2)
	ST	1(P2)
	JMP	FNORM

LODVAR:	JZ	LOD1
	LDI	(M_VAR-M_BASE)		; 'VARIABLE ERROR'
	JMP	SV_MSGOUT(P3)
LOD1:	LD	@1(P1)			; get byte from program and increase
	XRI	'('
	JZ	LOD2
	LD	@-1(P1)
	LDI	(M_SNTX-M_BASE)		; 'SYNTAX ERROR'
	JMP	SV_MSGOUT(P3)
LOD2:	LD	AEXOFF(P2)
	XPAL	P2
	LD	1(P2)
	XPAL	P1
	ST	-5(P2)
	LD	(P2)
	XPAH	P1
	ST	FOROFF(P2)
	LD	4(P1)
	ST	@-1(P2)
	LD	3(P1)
	ST	@-1(P2)
	LD	2(P1)
	JNZ	LOD3
	LDI	(M_RDIM-M_BASE)		; 'REDIMENSION ERROR'
	JMP	SV_RTERRN(P3)
LOD3:	ST	@-1(P2)
	LD	1(P1)
	ST	@-1(P2)
	LD	-1(P2)
	XPAL	P1
	LD	-2(P2)
	XPAH	P1
	LDI	STKMID
	XPAL	P2
	ST	AEXOFF(P2)		; store last AEXSTK.L
	JMP	SV_SPLOAD(P3)

STFLD:	LD	AEXOFF(P2)
	XPAL	P2
	LD	3(P2)
	XPAL	P3
	LD	2(P2)
	XPAH	P3
	XAE
	LD	1(P2)
	ST	3(P2)
	ST	4(P3)
	LD	@2(P2)
	ST	(P2)
	ST	3(P3)
	LDI	0
	ST	2(P3)
	ST	1(P3)
	LDI	0x80
	XPAL	P3
	LDE
	XPAH	P3
	LDI	STKMID
	XPAL	P2
	ST	AEXOFF(P2)		; store last AEXSTK.L
	JMP	SV_SPLOAD(P3)

DIMSN:	LD	AEXOFF(P2)
	XPAL	P2
	LD	(P2)
	ANI	0xFC
	JZ	DIMS1
	LDI	(M_DIM-M_BASE)		; 'DIMENSION ERROR'
	JMP	SV_RTERRN(P3)
DIMS1:	CCL
	LD	1(P2)
	ADD	1(P2)
	ST	-1(P2)
	LD	(P2)
	ADD	(P2)
	ST	-2(P2)
	LD	-1(P2)
	ADD	-1(P2)
	ST	-1(P2)
	LD	-2(P2)
	ADD	-2(P2)
	ST	-2(P2)
	LD	-1(P2)
	ADI	4
	ST	-1(P2)
	LD	-2(P2)
	ADI	0
	ST	-2(P2)
	LD	3(P2)
	ADI	2
	ST	3(P2)
	LD	2(P2)
	ADI	0
	XOR	2(P2)
	ANI	0xF0
	JZ	DIMS2
ARERR:	LDI	(M_AREA-M_BASE)		; 'AREA ERROR'
	JMP	SV_RTERRN(P3)
DIMS2:	LD	2(P2)
	ADI	0
	ST	2(P2)
	LD	3(P2)
	ADD	-1(P2)
	LD	2(P2)
	ADD	-2(P2)
	XOR	2(P2)
	ANI	0xF0
	JNZ	ARERR
	LD	3(P2)
	XPAL	P3
	LD	2(P2)
	XPAH	P3
	XAE
	LD	1(P2)
	ST	-2(P3)
	LD	@4(P2)
	ST	-1(P3)
DIMS3:	LDI	0
	ST	@1(P3)
	LD	-5(P2)
	JNZ	DIMS4
	DLD	FOROFF(P2)
DIMS4:	DLD	-5(P2)
	OR	FOROFF(P2)
	JNZ	DIMS3
	LDI	L(SPRVSR)
	XPAL	P3
	LDE
	XPAH	P3
	LDI	STKMID
	XPAL	P2
	ST	AEXOFF(P2)		; store last AEXSTK.L
	JMP	SV_SPLOAD(P3)

; Check for opening parenthesis.
CKPT:	JZ	CKP1
	LDI	(M_VAR-M_BASE)		; 'VARIABLE ERROR'
	JMP	SV_MSGOUT(P3)
CKP1:	LD	@1(P1)			; get byte from program and increase
	XRI	'('
	JZ	SV_SPLOAD(P3)
	LD	@-1(P1)
	JMP	SV_RTFUNC(P3)

LADVAR:	LD	AEXOFF(P2)
	XPAL	P2
	LD	1(P2)
	XPAL	P1
	ST	-1(P2)
	LD	(P2)
	XPAH	P1
	ST	-2(P2)
	LD	1(P1)
	OR	2(P1)
	JZ	LAD1
	LDI	(M_DIM-M_BASE)		; 'DIMENSION ERROR'
	JMP	SV_RTERRN(P3)
LAD1:	LD	4(P1)
	ST	1(P2)
	LD	3(P1)
	ST	(P2)
	LD	-1(P2)
	XPAL	P1
	LD	-2(P2)
	XPAH	P1
	LDI	STKMID
	XPAL	P2
	JMP	SV_SPLOAD(P3)

DMNSN:	LD	AEXOFF(P2)
	XPAL	P2
	LD	3(P2)
	XPAL	P1
	ST	3(P2)
	LD	2(P2)
	XPAH	P1
	ST	2(P2)
	SCL
	LD	@1(P1)			; get byte from program and increase
	CAD	1(P2)
	LD	(P1)
	CAD	(P2)
	JP	DMN1
	LDI	(M_DIM-M_BASE)		; 'DIMENSION ERROR'
	JMP	SV_RTERRN(P3)
DMN1:	CCL
	LD	1(P2)
	ADD	1(P2)
	ST	1(P2)
	LD	(P2)
	ADD	(P2)
	ST	(P2)
	LD	1(P2)
	ADD	1(P2)
	ST	1(P2)
	LD	(P2)
	ADD	(P2)
	ST	(P2)
	LD	3(P2)
	XPAL	P1
	ADD	1(P2)
	ST	3(P2)
	LD	2(P2)
	XPAH	P1
	ADD	@2(P2)
	ST	(P2)
	LDI	STKMID
	XPAL	P2
	ST	AEXOFF(P2)		; store last AEXSTK.L
DMN2:	LD	@1(P1)			; get byte from program and increase
	XRI	' '			; is it <space> ?
	JZ	DMN2			; yes, just eat it
	XRI	' ' ! ')'		; we XOR'ed above, is it ')' ?
	JZ	SV_RTFUNC(P3)
	LD	@-1(P1)			; decrease, so pointing to last byte
	LDI	(M_ENDP-M_BASE)		; 'END) ERROR'
	JMP	SV_MSGOUT(P3)

POPDLR:	JZ	PD1
	LDI	(M_VAR-M_BASE)		; 'VARIABLE ERROR'
	JMP	SV_MSGOUT(P3)
PD1:	LD	(P1)
	XRI	'$'
	JZ	SV_SPLOAD(P3)
	ILD	AEXOFF(P2)		; adjust AEXSTK by two up
	ILD	AEXOFF(P2)
	JMP	SV_SPLOAD(P3)

; Print version string (abuse PSTRNG routine).
VSTRNG:	LDI	L(VERSTR)
	ST	-17(P2)
	LDI	H(VERSTR)
	ST	-18(P2)

; Print string variable.
PSTRNG:	LD	-17(P2)			; load P1 and save prev content
	XPAL	P1
	ST	-17(P2)
	LD	-18(P2)
	XPAH	P1
	ST	-18(P2)
PSTR1:	LD	@1(P1)			; get byte from program and increase
	XRI	_CR
	JZ	PSTR2
	XRI	_CR
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	CSA				; get CPU status
	ANI	0x20			; check for SENSEB (start bit)
	JNZ	PSTR1			; no input, continue
PSTR2:	LD	-17(P2)			; restore P1
	XPAL	P1
	LD	-18(P2)
	XPAH	P1
	JMP	SV_RTFUNC(P3)

TAB:	LDI	0x1D
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	LD	-17(P2)
	JZ	SV_RTFUNC(P3)
TAB1:	LDI	_HTAB
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	DLD	-17(P2)
	JNZ	TAB1
	JMP	SV_RTFUNC(P3)

; Put status register as 16-bit integer onto STACK.
STATUS:	CSA				; load CPU status register
	JMP	PSH
; Put current page as 16-bit integer onto STACK
PGE:	LD	CURPG(P2)		; load value for current page
PSH:	XAE				; save in E
	LD	AEXOFF(P2)		; load actual offset of AEXSTK
	XPAL	P2
	XAE				; save prev P2.L in E
	ST	@-1(P2)			; push value as low byte onto STACK
	LDI	0
	ST	@-1(P2)			; push zero as high byte
	LDE				; load prev P2.L
	XPAL	P2			; restore P2..
	ST	AEXOFF(P2)		; ..and save AEXSTK.L
	JMP	SV_RTFUNC(P3)

; Find 'DEF' token with following 'FN' in current page containing BASIC program.
FNDDEF:	LDI	2			; load begin of basic program into P1
	XPAL	P1
	ST	-15(P2)
	LD	CURPG(P2)		; convert current page# into P1.H
	RR
	RR
	RR
	RR
	XPAH	P1
	ST	-16(P2)			; save prev P1 in STACK -16,-15
DEF1:	LD	(P1)
	XRI	0xFF			; end of program ?
	JNZ	DEF2			; go ahead
	LDI	(M_DEF-M_BASE)		; 'DEFINE ERROR'
	JMP	SV_MSGOUT(P3)
DEF2:	LD	@1(P1)			; load number.H and increase
	ST	-12(P2)
	LD	@2(P1)			; load number.L and skip line length
	ST	-11(P2)			; save number on STACK -12, -11
DEF3:	LD	@1(P1)			; get byte from program and increase
	XRI	' '			; is it <space> ?
	JZ	DEF3			; yes, just eat it
	XRI	' ' ! T_DEF		; we XOR'ed above, is it 'DEF' token ?
	JZ	DEF5			; found, go ahead
DEF4:	LD	-1(P1)			; get previous byte
	XRI	':'			; is it <colon> ?
	JZ	DEF3			; search token on line behind colon
	XRI	':' ! _CR		; we XOR'ed above, is it <cr> ?
	JZ	DEF1			; search token on next line
	LD	@1(P1)			; get byte from program and incr
	JMP	DEF4			; keep searching
DEF5:	LD	@1(P1)			; get byte from program and incr
	XRI	' '			; is it <space> ?
	JZ	DEF5			; yes, just eat it
	XRI	' ' ! T_FN		; we XOR'ed above, is it 'FN' token ?
	JZ	DEF6			; found, go ahead
FNERR:	LD	-11(P2)			; prepare error message
	ST	NUMLO(P2)		; load line number from STACK -12,-11
	LD	-12(P2)
	ST	NUMHI(P2)		; put line number onto STACK -9, -8
	LDI	(M_SNTX-M_BASE)		; 'SYNTAX ERROR'
	JMP	SV_MSGOUT(P3)
DEF6:	LD	@1(P1)			; get byte from program and incr
	XRE
	XRI	0x80
	JNZ	DEF4
	SCL
	LD	(P1)			; get current byte
	CAI	'Z'+1			; no beginning letter
	JP	SV_SPLOAD(P3)
	ADI	26			; 'Z'-'A'+1
	JP	DEF4			; found letter
	ADI	7			; 'A'-'9'-1
	JP	SV_SPLOAD(P3)		; no digit
	ADI	10			; '9'-'0'+1
	JP	DEF4			; is digit
	JMP	SV_SPLOAD(P3)

FNT:	LD	-11(P2)
	ST	NUMLO(P2)
	LD	-12(P2)
	ST	NUMHI(P2)
	LD	-15(P2)
	ST	-11(P2)
	LD	-16(P2)
	ST	-12(P2)
	JMP	SV_SPLOAD(P3)

FNDNE:	LD	@1(P1)			; get byte from program and increase
	XRI	' '			; is it <space> ?
	JZ	FNDNE			; yes, just eat it
	XRI	_CR ! ' '		; we XOR'ed above, is it <cr> ?
	JZ	FNDN
	XRI	_CR ! ':'		; we XOR'ed above, is it <colon> ?
	JZ	FNDN
	LDI	(M_CHAR-M_BASE)		; 'CHARACTER ERROR'
	JMP	SV_MSGOUT(P3)
FNDN:	LD	-11(P2)
	XPAL	P1
	LD	-12(P2)
	XPAH	P1
FNDN1:	LD	@-1(P1)
	XRI	_CR
	JNZ	FNDN1
	LD	1(P1)
	ST	NUMHI(P2)
	LD	2(P1)
	ST	NUMLO(P2)
	LD	-11(P2)
	XPAL	P1
	LD	-12(P2)
	XPAH	P1
	JMP	SV_RTFUNC(P3)

; Implement the USING keyword.
; Takes string argument and counts '#' before and behind the decimal comma.
; After FNUM had generated a number string, the quoted string determines
;  the format for printing the number string.
USING:	LDI	0
	ST	UFRACS(P2)		; counter for '#'s behind decimal comma
	ST	UTOTAL(P2)		; total counter for '#'s
USNG1:	LD	@1(P1)			; get byte from program and increase
	XRI	' '			; is it <space> ?
	JZ	USNG1			; yes, just eat it
	LD	-1(P1)			; get previous byte of program
	XRI	'#'			; is it '#' ?
	JNZ	USNG5			; at least one '#' must be there
USNG2:	ILD	UTOTAL(P2)
	LD	@1(P1)			; get byte from program and increase
	XRI	'#'			; is it '#' ?
	JZ	USNG2
	XRI	'#' ! ','		; we XOR'ed above, is it ',' ?
	JNZ	USNG4
	LD	UTOTAL(P2)
	ORI	0x80			; set bit7 (found separator <comma>)
	ST	UTOTAL(P2)
USNG3:	ILD	UTOTAL(P2)
	LD	@1(P1)			; get byte from program and increase
	XRI	'#'
	JNZ	USNG4
	ILD	UFRACS(P2)
	JMP	USNG3
USNG4:	LD	-1(P1)			; get previous byte of program
	XRI	'"'			; is it <quote> ?
	JZ	SV_SPLOAD(P3)		; yes, we are done
	LDI	(M_ENDQ-M_BASE)		; 'ENDQUOTE ERROR'
	JMP	SV_MSGOUT(P3)
USNG5:	LDI	(M_SNTX-M_BASE)		; 'SYNTAX ERROR'
	JMP	SV_MSGOUT(P3)

; Print floating point number after applying of formatting from USING statement.
USING2:	LD	AEXOFF(P2)		; load actual AEXSTK.L
	XRI	L(AEXSTK)		; default top of AEXSTK
	JZ	SV_SPLOAD(P3)		; STACK empty, jump back
	XRI	L(AEXSTK)		; we XOR'ed above
	XPAL	P1
	LD	STKPHI(P3)
	XPAH	P1
	LD	@-4(P1)			; set P1 to begin of number string
	SCL
	LD	UTOTAL(P2)
	ANI	0x7F
	ST	-18(P2)			; store total count of '#'s
	CAD	UFRACS(P2)
	ST	-17(P2)
	LD	UTOTAL(P2)
	JP	USNG21			; bit7 not set, so no separator <comma>
	DLD	-17(P2)
	JZ	USNG23
USNG21:	LD	@-1(P1)			; decrease and get byte from program
	XRI	'-'
	JNZ	USNG22
	LD	@1(P1)			; get byte from program and increase
	ILD	COUNTR(P2)
	JZ	USNG23
USNG22:	SCL
	LD	-17(P2)
	CAD	COUNTR(P2)
	JP	USNG24
USNG23:	LDI	'*'			; fill with '*' if format too small
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	DLD	-18(P2)
	JNZ	USNG23
	JMP	STINIT
USNG24:	JZ	USNG26
	ST	-22(P2)
USNG25:	LDI	' '			; fill with spaces
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	DLD	-22(P2)
	JNZ	USNG25
USNG26:	LD	CHRNUM(P2)
	JP	USNG28
	LD	-1(P1)
	XRI	'-'
	JNZ	USNG27
	DLD	COUNTR(P2)
	LD	@-1(P1)
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
USNG27:	LDI	'0'
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	JMP	USNG29
USNG28:	CALL	USING3
USNG29:	LD	UTOTAL(P2)
	JP	STINIT
	LDI	','
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	LD	UFRACS(P2)
	JZ	STINIT
	ST	COUNTR(P2)
	LD	CHRNUM(P2)
	JP	USNG2B
	ST	-22(P2)
USNG2A:	LDI	'0'			; <zero>'s post <comma>
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	DLD	COUNTR(P2)
	JZ	STINIT
	DLD	-22(P2)
	XRI	0x81
	JNZ	USNG2A
USNG2B:	CALL	USING3
	JMP	STINIT

; Print floating point number (as string on STACK.)
PRFNUM:	LD	AEXOFF(P2)		; load actual AEXSTK.L
	XRI	L(AEXSTK)		; is it top of arithmetics stack ?
	JZ	SV_SPLOAD(P3)		; STACK empty, jump back
	XRI	L(AEXSTK)		; we XOR'ed above
	XPAL	P1
	LD	STKPHI(P3)
	XPAH	P1
	LD	@-5(P1)			; set P1 below stored number to ASCII string
PRFNM1:	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	LD	@-1(P1)			; decrease P1 and load byte
	JNZ	PRFNM1			; loop until <null>

; Print a <space> and reset arithmetics stack
PRSPCE:	LDI	' '
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF

; After printing, top of the arithmetic STACK is reset to default.
STINIT:	LDI	L(AEXSTK)		; load default top of AEXSTK.L
	XPAL	P1			; temporarily put into P1.L

; Set stack back (also use as stand-alone routine.)
STBACK:	LD	-13(P2)			; restore pointer P1
	XPAL	P1
	ST	AEXOFF(P2)		; store default/actual top of AEXSTK.L
	LD	-14(P2)
	XPAH	P1
	JMP	SV_SPLOAD(P3)

	IF USE_CASS
CSAVE2:	JS	P3,CASW			; execute Cassette Write system call
	LDPI	P3,SPRVSR		; restore P3 to Supervisor
	JMP	SV_SPLOAD(P3)		; return to supervisor

CLOAD2:	LDI	L(AEXSTK)-4		; set buffer address for PRNUM
	ST	AEXOFF(P2)		; store as actual offset to AEXSTK.L
	JS	P3,CASR			; execute Cassette Read system call
	XAE				; save AC
	LDPI	P3,SPRVSR		; set P3 back to SPRVSR
	LDE				; load saved AC
	JZ	CLOAD4			; all OK
CLOAD3:	LDI	(INCMD + _QMARK)	; set "PROGRAM RUNNING" flag
	ST	BASMODE(P2)		; store program / run flag
	LDI	(M_CASS-M_BASE)		; 'CASS ERROR'
	JMP	SV_MSGOUT(P3)
CLOAD4:	CALL	FNDVAR
	JZ	CLOAD3			; no variable found
	JMP	SV_SPLOAD(P3)		; return to supervisor

; Determine start of program on current page.
BOT:	LD	CURPG(P2)		; load page #
	RR				; rotate right AC (multiply by 16)
	RR
	RR
	RR
	XAE
	DLD	AEXOFF(P2)		; decrease stored P2.L by 2
	DLD	AEXOFF(P2)
	XPAL	P2
	XAE				; save prev P2.L in E
	ST	(P2)			; store START.H on STACK 0
	LDI	1			; program begins at byte 1 of page
	ST	1(P2)			; store START.L on STACK 1
	LDE
	XPAL	P2
	JMP	SV_SPLOAD(P3)

CFINI:	LD	-33(P2)			; get start addr L
	ST	NUMLO(P2)		; store for PRNUM
	LD	-34(P2)			; get start addr H
	ST	NUMHI(P2)		; store for PRNUM
	CALL	PRNUM			; print the number
	LDI	'-'			; print <minus>
	IFDEF	SCALLS
	 SYSCALL	2
	ELSE
	 CALL	PUTASC
	ENDIF
	LD	-35(P2)			; get end addr L
	ST	NUMLO(P2)		; store for PRNUM
	LD	-36(P2)			; get end addr H
	ST	NUMHI(P2)		; store for PRNUM
	CALL	PRNUM			; print the number
	CALL	LINE			; print newline
	LDI	(M_RDY-M_BASE)		; 'READY'
	JMP	SV_MSGOUT(P3)
	ENDIF

	; Fill up space to end of ROM.
	ORG	(BASE+0x3000) - 1
	DB	0xFF

	END	RESET
