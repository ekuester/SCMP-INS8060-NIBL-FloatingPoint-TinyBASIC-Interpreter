; NIBLFP.ASM by Erich Küster, late seventies of last century
; assembler listing
; some labels are fallen into oblivion and substituted by L_[hex address]
; rewritten 2023 for macro assembler asl
; the macro-assembler used here is a free tool by Alfred Arnold:
;           http://john.ccac.rwth-aachen.de:8000/as/
;
;   .TITLE  NIBLFP,'05/08/2023'
;   .LIST   1
;
; Krefeld / Germany May 8, 2023
;

L FUNCTION VAL16, (VAL16 & 0xFF)
H FUNCTION VAL16, ((VAL16 >> 8) & 0xFF)

JS    MACRO  P,VAL            ;JUMP TO SUBROUTINE
        LDI  H(VAL-1)
        XPAH P
        LDI  L(VAL-1)
        XPAL P
        XPPC P
      ENDM

LDPI  MACRO  P,VAL            ;LOAD POINTER
        LDI  L(VAL)
        XPAL P
        LDI  H(VAL)
        XPAH P
      ENDM

CALL  MACRO  P,VAL            ;CALL SUBROUTINE
        XPPC P
        DB   H(VAL)
        DB   L(VAL)
      ENDM

RTRN  MACRO  P,VAL            ;RETURN FROM SUBROUTINE
        XPPC P
        DB   0
      ENDM

;******************************************************
;*     WE ARE TIED DOWN TO A LANGUAGE WHICH           *
;*     MAKES UP IN OBSCURITY WHAT IT LACKS            *
;*     IN STYLE.                                      *
;*                     - TOM STOPPARD                 *
;*     CONFIRMED                                      *
;*                     - ERICH KUESTER                *
;******************************************************

JMPBIT  =  0x80
TSTBIT  =  0x40               ;I.L. INSTRUCTION FLAGS
CALBIT  =  0x20
P1      =  1                  ;SC/MP POINTER ASSIGNMENTS
P2      =  2
P3      =  3
EREG    =  -128               ;THE EXTENSION REGISTER

        ORG    0xD000
L_D000: LDI    0x0C
        CALL   P3,PUTASC
        LDI    0x1C           ;BASIC STACK AT 1C00
        ORI    0x01           ;NOW AT 1D00
        XPAH   P1
        LDI    0x00
        XPAL   P1             ;SET P1 WITH ADDRESS
        LDI    0x00
        ST     (P1)
        ST     127(P2)
        LDI    0x1F
        ST     -94(P2)
        CALL   P3,CLRSTK
        LDI    0x1C
        ST     -29(P2)
        LDE
        XPAL   P1
        LDI    0xD6
        XPAH   P1
L_D023: LDI    0x20
        CALL   P3,PUTASC
L_D028: LD     @1(P1)
        CALL   P3,PUTASC
        JP     L_D028         ;to $D028
        LDI    0x81
        XPAL   P1
        JP     L_D023         ;to $D023
        CALL   P3,L_D400
        NOP
        LDI    0x48
        ST     (P2)
        LDI    0x3E
        ST     127(P2)
        LDI    0xB1
        ST     -7(P2)
        LDI    0x60
        ST     -3(P2)
        LDI    0xD8
        ST     -2(P2)
        LDI    0x02
        ST     -1(P2)
        CALL   P3,LINE
        LDI    0x1A
        ST     -29(P2)
L_D057: LD     -1(P2)
        XPAL   P3
        LD     -2(P2)
        ORI    0xC0
        XPAH   P3
L_D05F: LD     1(P3)
        ST     -1(P2)
        LD     @2(P3)
        JZ     L_D0C8         ;to $D0C8
        ST     -2(P2)
        ANI    0xE0
        JZ     L_D0B7         ;to $D0B7
        JP     L_D057         ;to $D057
        XRI    0xE0
        JNZ    L_D0DC         ;to $D0DC
        LD     -1(P3)
        XPAL   P3
        ST     -1(P2)
        LD     -2(P2)
        XPAH   P3
        ST     -2(P2)
L_D07D: LD     @-1(P3)
        LDE
L_D080: XPPC   P3
        XAE
        LD     @1(P3)
        LD     (P3)
        JZ     L_D0A7         ;to $D0A7
        LD     -29(P2)
        XPAL   P2
        LD     @2(P3)
        ST     -2(P2)
        LD     -1(P3)
        XPAL   P3
        ST     @-1(P2)
        LD     -1(P2)
        XPAH   P3
        ST     @-1(P2)
        LDI    0x80
        XPAL   P2
        ST     -29(P2)
        JNZ    L_D07D         ;to $D07D
L_D0A0: LDI    0x46
L_D0A2: XAE
        LDI    0x1E
        JMP    L_D0AB         ;to $D0AB
L_D0A7: ILD    -29(P2)
        ILD    -29(P2)
L_D0AB: XPAL   P2
        LD     -1(P2)
        XPAL   P3
        LD     -2(P2)
        XPAH   P3
        LDI    0x80
        XPAL   P2
        JMP    L_D07D         ;to $D07D
L_D0B7: DLD    -7(P2)
        DLD    -7(P2)
        JP     L_D0A0         ;to $D0A0
        XPAL   P2
        XPAL   P3
        ST     1(P2)
        XPAH   P3
        ST     (P2)
        XPAL   P3
        XPAL   P2
L_D0C6: JMP    L_D057         ;to $D057
L_D0C8: ILD    -7(P2)
        ILD    -7(P2)
        XPAL   P2
        LD     -1(P2)
        XPAL   P3
        LD     -2(P2)
        XPAH   P3
        LDI    0x80
        XPAL   P2
L_D0D6: JMP    L_D05F         ;to $D05F
        LDI    0x6F
        JMP    L_D0A2         ;to $D0A2
L_D0DC: LD     @1(P1)
        XRI    0x20
        JZ     L_D0DC         ;to $D0DC
        LD     -2(P2)
        ANI    0x60
        JNZ    L_D0F2         ;to $D0F2
        LD     -1(P1)
        XOR    @1(P3)
        JZ     L_D0D6         ;to $D0D6
        LD     @-1(P1)
        JMP    L_D0C6         ;to $D0C6
L_D0F2: XRI    0x40
        JZ     L_D129         ;to $D129
        LD     -1(P1)
        XAE
        SCL
        LDE
        CAI    0x5B
        JP     L_D103         ;to $D103
        ADI    0x1A
        JP     L_D10D         ;to $D10D
L_D103: LD     -2(P2)
        ANI    0xDF
        ST     -2(P2)
L_D109: LD     @-1(P1)
        JMP    L_D0C6         ;to $D0C6
L_D10D: SCL
        LD     (P1)
        CAI    0x5B
        JP     L_D123         ;to $D123
        ADI    0x1A
        JP     L_D0D6         ;to $D0D6
        SCL
        LD     (P1)
        CAI    0x3A
        JP     L_D123         ;to $D123
        ADI    0x0A
        JP     L_D0D6         ;to $D0D6
L_D123: LDE
        ORI    0x80
        XAE
L_D127: JMP    L_D0D6         ;to $D0D6
L_D129: ST     -24(P2)
        LD     -1(P1)
L_D12D: SCL
        CAI    0x3A
        JP     L_D13E         ;to $D13E
        ADI    0x0A
        JNZ    L_D13C         ;to $D13C
        ILD    -24(P2)
        LD     @1(P1)
        JMP    L_D12D         ;to $D12D
L_D13C: JP     L_D148         ;to $D148
L_D13E: LD     -24(P2)
        JZ     L_D109         ;to $D109
        LD     @-1(P1)
        LDI    0x00
        ST     -24(P2)
L_D148: XAE
        LD     -3(P2)
        XPAL   P2
        LDI    0x96
        ST     @-04(P2)
        LDI    0x00
        ST     1(P2)
        ST     2(P2)
        LDE
        ST     3(P2)
L_D159: SCL
        LD     @1(P1)
        CAI    0x3A
        JP     L_D164         ;to $D164
        ADI    0x0A
        JP     L_D190         ;to $D190
L_D164: LD     @-1(P1)
L_D166: LD     1(P2)
        ADD    1(P2)
        XOR    1(P2)
        JP     L_D175         ;to $D175
L_D16E: LDI    0x80
        XPAL   P2
        ST     -3(P2)
        JMP    L_D127         ;to $D127
L_D175: LD     (P2)
        JZ     L_D16E         ;to $D16E
        DLD    (P2)
        CCL
        LD     3(P2)
        ADD    3(P2)
        ST     3(P2)
        LD     2(P2)
        ADD    2(P2)
        ST     2(P2)
        LD     1(P2)
        ADD    1(P2)
        ST     1(P2)
        JMP    L_D166         ;to $D166
L_D190: XAE
        CCL
        LD     3(P2)
        ADD    3(P2)
        ST     3(P2)
        ST     -1(P2)
        LD     2(P2)
        ADD    2(P2)
        ST     2(P2)
        ST     -2(P2)
        LD     1(P2)
        ADD    1(P2)
        ST     1(P2)
        ST     -3(P2)
        LDI    0x04
        ST     -4(P2)
L_D1AE: LD     3(P2)
        ADD    -1(P2)
        ST     3(P2)
        LD     2(P2)
        ADD    -2(P2)
        ST     2(P2)
        LD     1(P2)
        ADD    -3(P2)
        ST     1(P2)
        DLD    -4(P2)
        JNZ    L_D1AE         ;to $D1AE
        XAE
        ADD    3(P2)
        ST     3(P2)
        LDE
        ADD    2(P2)
        ST     2(P2)
        LDE
        ADD    1(P2)
        ST     1(P2)
        JP     L_D159         ;to $D159
        LDI    0xD0
        XPAH   P0
L_D1D8: LD     @-1(P1)
        XRI    0x2E
        JZ     L_D1D8         ;to $D1D8
        LD     @1(P1)
        XRI    0x45
        JZ     L_D1EA         ;to $D1EA
        LD     -1(P1)
        XRI    0xA0
        JNZ    L_D1F5         ;to $D1F5
L_D1EA: LDI    0x30
        CALL   P3,PUTASC
        DLD    -21(P2)
        JNZ    L_D1EA         ;to $D1EA
        JMP    38(P3)
L_D1F5: LD     @-1(P1)
        CALL   P3,PUTASC
        DLD    -21(P2)
        JNZ    L_D1D8         ;to $D1D8
        JMP    38(P3)

        ORG    0xD400
L_D400: LDI    0x01
        XAE
        SIO
        ILD    127(P2)
        JP     38(P3)
        LDI    0x20
        CALL   P3,PUTASC
        LDI    0x41
        CALL   P3,PUTASC
        LDI    0x54
        CALL   P3,PUTASC
        CALL   P3,PRNUM
        JMP    38(P3)
        CAD    @-01(P3)
        CAD    @-01(P3)

        ORG    0xD45B
L_D45B: ST     -96(P2)
        LDI    0x0B
        ST     -21(P2)
        LDI    0x00
        XAE
        SIO
        XAE
        DLD    -95(P2)
        LD     -96(P2)
        XAE
L_D46B: LDI    0x17
        DLY    1
        LD     -94(P2)
        ST     -95(P2)
L_D473: DLD    -95(P2)
        JNZ    L_D473         ;to $D473
        SIO
        LDE
        ORI    0x80
        XAE
        DLD    -21(P2)
        JNZ    L_D46B         ;to $D46B
        XPPC   P3
        JMP    L_D45B         ;to $D45B
L_D483: LDI    0xFF
        XAE
        SIO
        LDE
        JP     L_D48C         ;to $D48C
        JMP    L_D483         ;to $D483
L_D48C: LDI    0x78
        DLY    0
        LDI    0xFF
        XAE
        LD     -94(P2)
        SR
        ST     -95(P2)
L_D498: DLD    -95(P2)
        JNZ    L_D498         ;to $D498
        LDI    0x08
        ST     -21(P2)
L_D4A0: LD     -94(P2)
        ST     -95(P2)
        LDI    0x24
        DLY    1
L_D4A8: DLD    -95(P2)
        JNZ    L_D4A8         ;to $D4A8
        SIO
        DLD    -21(P2)
        JNZ    L_D4A0         ;to $D4A0
        LD     -94(P2)
        ST     -95(P2)
L_D4B5: DLD    -95(P2)
        JNZ    L_D4B5         ;to $D4B5
        LDE
        XPPC   P3
        JMP    L_D483         ;to $D483

        ORG    0xD4C0
L_D4C0: LDI    0x00
        ST     -95(P2)
        ST     -96(P2)
L_D4C6: LD     @1(P1)
        XRI    0x20
        JZ     L_D4C6         ;to $D4C6
        LD     -1(P1)
        XRI    0x23
        JNZ    L_D4F6         ;to $D4F6
L_D4D2: ILD    -96(P2)
        LD     @1(P1)
        XRI    0x23
        JZ     L_D4D2         ;to $D4D2
        XRI    0x0F
        JNZ    L_D4F0         ;to $D4F0
        LD     -96(P2)
        ORI    0x80
        ST     -96(P2)
L_D4E4: ILD    -96(P2)
        LD     @1(P1)
        XRI    0x23
        JNZ    L_D4F0         ;to $D4F0
        ILD    -95(P2)
        JMP    L_D4E4         ;to $D4E4
L_D4F0: LD     -1(P1)
        XRI    0x22
        JZ     38(P3)
L_D4F6: LDI    0x63
        JMP    -98(P3)
        CAD    @-1(P3)
        CAD    @-1(P3)
        CAD    @-1(P3)

;***************************
;*   PUT CHAR TO STDOUT    *
;***************************

PUTASC: ANI    0x7F           ;MASK OFF PARITY BIT
        XAE                   ;SAVE IN EXT
        ST     -127(P2)       ;STORE IN RAM
        LDI    0x30           ;SET DELAY FOR START BIT
        DLY    3              ; (TTY_B6 AND TTY_B7)
        CSA                   ;GET STATUS
        ORI    1              ;SET START BIT (INVERTED LOGIC)
        CAS                   ;SET STATUS
        LDI    9              ;GET BIT COUNT
        ST     -24(P2)        ;STORE IN RAM
PUTA1:  LDI    0x5C           ;SET DELAY FOR 1 BIT TIME
        DLY    1              ; (TTY_B8 AND TTY_B9)
        DLD    -24(P2)        ;DECREMENT BIT COUNT
        JZ     PUTA2
        LDE                   ;PREPARE NEXT BIT
        ANI    0x01
        ST     -23(P2)
        XAE                   ;SHIFT DATA RIGHT ONE BIT
        RR
        XAE
        CSA                   ;SET UP OUTPUT BIT
        ORI    1
        XOR    -23(P2)
        CAS                   ;PUT BIT TO TTY
        JMP    PUTA1
PUTA2:  CSA                   ;SET STOP BIT
        ANI    0xFE
        CAS
        LD     -127(P2)
        XAE
        XRI    0x0C
        JNZ    PUTA3
        DLY    255
        JMP    38(P3)         ;JUMP RTRN
PUTA3:  ANI    0x60
        JNZ    38(P3)         ;JUMP RTRN
        DLY    0x10
        JMP    38(P3)         ;JUMP RTRN

;***************************
;*   GET CHAR FROM STDIN   *
;***************************

        ORG    0xD5CE
GETASC: LDI    0x08           ;SET COUNT
        ST     -21(P2)
L_WAIT: CSA                   ;WAIT FOR START BIT
        ANI    0x20
        JNZ    L_WAIT
        LDI    0xC2           ;DELAY 1/2 BIT TIME
        DLY    0              ; (TTY_B1 AND TTY_B2)
        CSA                   ;IS START BIT STILL THERE?
        ANI    0x20
        JNZ    L_WAIT         ;NO
; BEGIN FOR VARCEM
;        CSA                   ;SEND START BIT (NOTE THAT
;        ORI    0x01           ; (OUTPUT IS INVERTED)
;        CAS
; END FOR VARCEM
L_INP:  LDI    0x76           ;DELAY BIT TIME
        DLY    1              ; (TTY_B3 AND TTY_B4)
        CSA                   ; GET BIT (SENSEB)
        ANI    0x20
        JZ     L_ZERO
        LDI    0x01
L_ZERO: RRL                   ;ROTATE INTO LINK
        XAE
        SRL                   ;SHIFT INTO CHARACTER
        XAE                   ;RETURN CHAR TO E
        DLD    -21(P2)        ;DECREMENT BIT COUNT
        JNZ    L_INP          ;LOOP UNTIL 0
        DLY    1
        LDE                   ;LOAD CHARACTER FROM E
        ANI    0x7F           ;MASK PARITY BIT
        XAE
        LDE
        ANI    0x40           ;TEST FOR UPPERCASE
        JZ     UPPERC
        LDE
        ANI    0x5F           ;CONVERT TO UPPERCASE
        XAE
UPPERC: LDE
        XRI    3              ;TEST FOR CONTROL-C
        JNZ    38(P3)         ;JUMP RTRN
        LDI    0x7C
        JMP    -98(P3)

        DB     "00000"
        DB     "000000"
        DB     "000000"

;***************************
;*       MESSAGES          *
;***************************

MESSAGE MACRO A,B
           DB  A
           DB  B|0x80
        ENDM

MESGS:  MESSAGE "DE",'F'      ; 1
        MESSAGE "ARE",'A'     ; 2
        MESSAGE "AR",'G'      ; 3
        MESSAGE "BL",'K'      ; 4
        MESSAGE "CAS",'S'     ; 5
        MESSAGE "CHA",'R'     ; 6
        MESSAGE "DI",'M'      ; 7
        MESSAGE "DAT",'A'     ; 8
        MESSAGE "DIV",'0'     ; 9
        MESSAGE "END",'"'     ; 10
        MESSAGE "FO",'R'      ; 11
        MESSAGE "HE",'X'      ; 12
        MESSAGE "NES",'T'     ; 13
        MESSAGE "NEX",'T'     ; 14
        MESSAGE "NOG",'O'     ; 15
        MESSAGE "OVRF",'L'    ; 16
        MESSAGE "RA",'M'      ; 17
        MESSAGE "REDI",'M'    ; 18
        MESSAGE "RTR",'N'     ; 19
        MESSAGE "SNT",'X'     ; 20
        MESSAGE "STM",'T'     ; 21
        MESSAGE "UNT",'L'     ; 22
        MESSAGE "VAL",'U'     ; 23
        MESSAGE "VA",'R'      ; 24
        MESSAGE "VARST",'K'   ; 25
        MESSAGE "BREA",'K'    ; 26
        MESSAGE "ERRO",'R'    ; 27
        MESSAGE "READ",'Y'    ; 28

        DB      "000000"
        DB      "000000"
        DB      "000000"
        DB      "000"

;***************************
;*      TOKEN TABLE        *
;***************************

TOKEN   MACRO A,B,C
        IF A == 78
           DB  94
        ELSE
           DB  A|0x80
        ENDIF
           DB  B
           DB  C|0x80
        ENDM

TABLE:  TOKEN   0,"AUT",'O'     ; 0
        TOKEN   1,"BY",'E'      ; 1
        TOKEN   2,"CLEA",'R'    ; 2
        TOKEN   3,"CLOA",'D'    ; 3
        TOKEN   4,"CSAV",'E'    ; 4
        TOKEN   5,"EDI",'T'     ; 5
        TOKEN   6,"LIS",'T'     ; 6
        TOKEN   7,"NE",'W'      ; 7
        TOKEN   8,"RU",'N'      ; 8
        TOKEN   9,"DAT",'A'     ; 9
        TOKEN   10,"DE",'F'     ; 10
        TOKEN   11,"DI",'M'     ; 11
        TOKEN   12,"D",'O'      ; 12
        TOKEN   13,"ELS",'E'    ; 13
        TOKEN   14,"EN",'D'     ; 14
        TOKEN   15,"FO",'R'     ; 15
        TOKEN   16,"GOSU",'B'   ; 16
        TOKEN   17,"GOT",'O'    ; 17
        TOKEN   18,"I",'F'      ; 18
        TOKEN   19,"INPU",'T'   ; 19
        TOKEN   20,"LIN",'K'    ; 20
        TOKEN   21,"MA",'T'     ; 21
        TOKEN   22,"NEX",'T'    ; 22
        TOKEN   23,"O",'N'      ; 23
        TOKEN   24,"PAG",'E'    ; 24
        TOKEN   25,"POK",'E'    ; 25
        TOKEN   26,"PRIN",'T'   ; 26
        TOKEN   27,"P",'R'      ; 27
        TOKEN   28,"REA",'D'    ; 28
        TOKEN   29,"RE",'M'     ; 29
        TOKEN   30,"RESTOR",'E' ; 30
        TOKEN   31,"RETUR",'N'  ; 31
        TOKEN   32,"STA",'T'    ; 32
        TOKEN   33,"UNTI",'L'   ; 33
        TOKEN   34,"LE",'T'     ; 34
        TOKEN   35,"AN",'D'     ; 35
        TOKEN   36,"DI",'V'     ; 36
        TOKEN   37,"EXO",'R'    ; 37
        TOKEN   38,"MO",'D'     ; 38
        TOKEN   39,"O",'R'      ; 39
        TOKEN   40,"PEE",'K'    ; 40
        TOKEN   41,"<",'='      ; 41
        TOKEN   42,">",'='      ; 42
        TOKEN   43,"<",'>'      ; 43
        TOKEN   44,"AB",'S'     ; 44
        TOKEN   45,"AT",'N'     ; 45
        TOKEN   46,"CO",'S'     ; 46
        TOKEN   47,"EX",'P'     ; 47
        TOKEN   48,"F",'N'      ; 48
        TOKEN   49,"IN",'T'     ; 49
        TOKEN   50,"L",'B'      ; 50
        TOKEN   51,"L",'G'      ; 51
        TOKEN   52,"L",'N'      ; 52
        TOKEN   53,"NO",'T'     ; 53
        TOKEN   54,"P",'I'      ; 54
        TOKEN   55,"RN",'D'     ; 55
        TOKEN   56,"SG",'N'     ; 56
        TOKEN   57,"SI",'N'     ; 57
        TOKEN   58,"SQ",'R'     ; 58
        TOKEN   59,"TA",'N'     ; 59
        TOKEN   60,"VA",'L'     ; 60
        TOKEN   61,"AS",'C'     ; 61
        TOKEN   62,"FRE",'E'    ; 62
        TOKEN   63,"LE",'N'     ; 63
        TOKEN   64,"PO",'S'     ; 64
        TOKEN   65,"TO",'P'     ; 65
        TOKEN   66,"STE",'P'    ; 66
        TOKEN   67,"THE",'N'    ; 67
        TOKEN   68,"T",'O'      ; 68
        TOKEN   69,"CHR",'$'    ; 69
        TOKEN   70,"LEFT",'$'   ; 70
        TOKEN   71,"MID",'$'    ; 71
        TOKEN   72,"RIGHT",'$'  ; 72
        TOKEN   73,"SP",'C'     ; 73
        TOKEN   74,"STR",'$'    ; 74
        TOKEN   75,"TA",'B'     ; 75
        TOKEN   76,"USIN",'G'   ; 76
        TOKEN   77,"VER",'T'    ; 77
        TOKEN   78,"*",'*'      ; 78
        DB      0,0,0,0

JMPBITH =       JMPBIT*256
TSTBITH =       TSTBIT*256
CALBITH =       CALBIT*256

TSTSTR  MACRO   FAIL,A
        DB      H(FAIL - TSTBITH)
        DB      L(FAIL)
        DB      A
        ENDM

TSTNUM  MACRO   FAIL
        DB      H(FAIL)
        DB      L(FAIL)
        ENDM

TSTVAR  MACRO   ADR
        DB      H(ADR - CALBITH)
        DB      L(ADR)
        ENDM

GOTO    MACRO   ADR
        DB      H(ADR - JMPBITH)
        DB      L(ADR)
        ENDM

ILCALL  MACRO   ADR
        DB      H(ADR - (JMPBITH + TSTBITH))
        DB      L(ADR)
        ENDM

DO      MACRO   ADR
        IFNB    ADR
        DB      H(ADR)
        DB      L(ADR)
        SHIFT
        DO      ALLARGS
        ENDIF
        ENDM

;*************************************
;*            I. L. TABLE            *
;*************************************

PROMPT: DO      GETLIN
PRMPT1: TSTSTR  BEGIN
        DB      0x0D
        GOTO    PROMPT
BEGIN:  DO      SCANR
        TSTNUM  START
        DO      POPAE
        DO      FNDLBL
        DO      INSRT
        GOTO    PROMPT
START:  DO      NEXT
        GOTO    AUTO
        DO      BYE
        DO      CLEAR
        DO      CLOAD
        GOTO    L_DA56
        GOTO    EDIT
        GOTO    LIST
        GOTO    NEW
        GOTO    RUN
        DO      IGNRE
        DO      IGNRE
        GOTO    DIM
        GOTO    DO
        DO      IGNORE
        DO      BRK
        GOTO    FOR
        GOTO    GOSUB
        GOTO    GOTO
        GOTO    IF
        GOTO    INPUT
        GOTO    LINK
        GOTO    SYNTAX
        GOTO    NEXTG
        GOTO    ON
        GOTO    PAGE
        GOTO    POKE
        GOTO    PRINT
        GOTO    PRINT
        GOTO    READ
        DO      IGNORE
        GOTO    RESTOR
        GOTO    RETURN
        GOTO    STAT
        GOTO    UNTIL
        TSTVAR  PAGE0
        DO      FNDVAR
        DO      DEFVAR
        TSTSTR  DOLLAR
        DB      '('
        ILCALL  INDEX
LET:    TSTSTR  SYNTAX
        DB      '='
        ILCALL  REXPR
        DO      STVAR
        DO      DNE
DOLLAR: TSTSTR  LET
        DB      '$'
        DO      LDVAR
        DO      FIX
        TSTSTR  SYNTAX
        DB      '='
        ILCALL  STREXP
        DO      DNE
PAGE0:  TSTSTR  STAT0
        DB      0x98          ;'PAGE'
PAGE:   TSTSTR  SYNTAX
        DB      '='
        ILCALL  REXPR
        DO      DONE
        DO      POPAE
        DO      NUPAGE
        DO      LKPAGE
        DO      NXT
STAT0:  TSTSTR  SYNTAX
        DB      0xA0          ;'STAT'
STAT:   TSTSTR  SYNTAX
        DB      '='
        ILCALL  REXPR
        DO      POPAE
        DO      MOVESR
SYNTAX: DO      SYNT
LIST:   TSTNUM  LIST2
        DO      POPAE
        TSTSTR  LIST4
        DB      '-'
        TSTNUM  SYNTAX
        DO      FNDLBL
        DO      POPAE
LIST1:  DO      LST1
        GOTO    LIST1
LIST2:  DO      CHPAGE
LIST3:  DO      LST2
        GOTO    LIST3
LIST4:  DO      FNDLBL
        DO      LST1
        DO      NXT
NEW:    TSTNUM  NEW1
        DO      POPAE
        DO      NUPAGE
        GOTO    NEW2
NEW1:   DO      NUPGE1
NEW2:   DO      DONE
        DO      NEWPGM
        DO      NXT2
FOR:    DO      CKMODE
        TSTVAR  SYNTAX
        DO      FNDVAR
        DO      DEFVAR
        TSTSTR  SYNTAX
        DB      '='
        ILCALL  REXPR
        TSTSTR  SYNTAX
        DB      0xC4          ;'TO'
        ILCALL  REXPR
        TSTSTR  FOR1
        DB      0xC2          ;'STEP'
        ILCALL  REXPR
        GOTO    FOR2
FOR1:   DO      ONE
FOR2:   DO      DONE
        DO      SAVFOR
        DO      NXT
NEXTG:  DO      CKMODE
        TSTVAR  SYNTAX
        DO      FNDVAR
        DO      NXTVAR
        DO      FADD
        DO      NXTV
        DO      DETPGE
RUN:    DO      DONE
        DO      CHPAGE
        DO      STRT
RUN1:   DO      NXT1
READ:   DO      CKMODE
        DO      LDDTA
READ1:  DO      NXTDTA
        DO      XCHPNT
        TSTVAR  LIST
        DO      FNDVAR
        DO      DEFVAR
        TSTSTR  READ5
        DB      '('
        ILCALL  INDEX
READ2:  DO      XCHPNT
        TSTSTR  READ3
        DB      '-'
        TSTNUM  READ9
        ILCALL  RNUM
        ILCALL  NEG
        DO      STVAR
        GOTO    READ7
READ3:  TSTSTR  READ4
        DB      '+'
READ4:  TSTNUM  READ9
        ILCALL  RNUM
        DO      STVAR
        GOTO    READ7
READ5:  TSTSTR  READ2
        DB      '$'
        DO      LDVAR
        DO      POPAE
        DO      XCHPNT
        TSTSTR  READ6
        DB      '"'
        DO      PUTSTR
        GOTO    READ7
READ6:  DO      INSTR
READ7:  DO      XCHPNT
        TSTSTR  READ8
        DB      ','
        DO      XCHPNT
        GOTO    READ1
READ8:  DO      L_E4F2
        DO      DNE
READ9:  DO      SNTX
RESTOR: DO      CKMODE
        DO      FNDDTA
        TSTNUM  RESTR1
        DO      POPAE
        DO      FNDLBL
        DO      XCHPNT
RESTR1: DO      L_E4F2
        DO      DNE
INPUT:  DO      CKMODE
        TSTSTR  INPUT1
        DB      '"'
        DO      PRSTR
INPUT1: TSTVAR  SYNTAX
        DO      FNDVAR
        DO      DEFVAR
        TSTSTR  INPUT3
        DB      '$'
        DO      LDVAR
        DO      POPAE
        DO      GETLIN
        DO      ISTRNG
INPUT2: DO      DNE
INPUT3: DO      GETLIN
INPUT4: DO      XCHPNT
        TSTSTR  INPUT5
        DB      '('
        ILCALL  INDEX
INPUT5: DO      XCHPNT
        ILCALL  REXPR
        DO      STVAR
        DO      XCHPNT
        TSTSTR  INPUT2
        DB      ','
        TSTVAR  SYNTAX
        DO      FNDVAR
        DO      DEFVAR
        DO      XCHPNT
        TSTSTR  SYNTAX
        DB      ','
        GOTO    INPUT4
DO:     DO      CKMODE
        DO      DONE
        DO      SAVEDO
UNTIL:  DO      CKMODE
        ILCALL  RELSTR
        DO      DONE
        DO      UNTL
LINK:   ILCALL  REXPR
        DO      POPAE
        DO      DONE
        DO      XCHPNT
        DO      MC
        DO      XCHPNT
        DO      NXT
ON:     ILCALL  REXPR
        DO      POPAE
        TSTSTR  ON1
        DB      0x90          ;'GOSUB'
        ILCALL  REXPR
        DO      GTO
        GOTO    GOSUB1
ON1:    TSTSTR  SYNTAX
        DB      0x91          ;'GOTO'
        ILCALL  REXPR
        DO      GTO
        GOTO    GOTO1
GOTO:   ILCALL  REXPR
        DO      DONE
        GOTO    GOTO1
GOSUB:  ILCALL  REXPR
        DO      DONE
GOSUB1: DO      SAV
GOTO1:  DO      POPAE
        DO      FNDLBL
        DO      XFER
RETURN: DO      DONE
        DO      RSTR
EDIT:   TSTNUM  SYNTAX
        DO      POPAE
        DO      FNDLBL
        DO      EDITR
        DO      INP
        GOTO    PRMPT1
AUTO:   TSTNUM  SYNTAX
        DO      POPAE
        TSTSTR  AUTO1
        DB      ','
        DO      NUMTST
        GOTO    AUTO2
AUTO1:  DO      TEN
AUTO2:  DO      AUTONM
        DO      GETL
        DO      SCANR
        TSTNUM  AUTO3
        DO      POPAE
AUTO3:  DO      FNDLBL
        DO      INSRT
        DO      AUTON
        GOTO    AUTO2
IF:     ILCALL  RELSTR
        DO      CMPRE
        TSTNUM  RUN1
        DO      POPAE
        DO      FNDLBL
        DO      XFER
POKE:   ILCALL  REXPR
        DO      FIX
        TSTSTR  SYNTAX
        DB      ','
        ILCALL  REXPR
        DO      FIX
        DO      PUTBYT
        DO      DNE
PRINT1: ILCALL  PREXP
        TSTSTR  PRINT2
        DB      ','
        GOTO    PRINT1
PRINT2: TSTSTR  PRINT3
        DB      ';'
        DO      DNE
PRINT3: DO      LINE
        DO      DNE
DIM:    TSTVAR  SYNTAX
        DO      FNDVAR
        DO      LODVAR
        DO      FIX
        DO      STFLD
        ILCALL  REXPR
        DO      FIX
        DO      DIMSN
        TSTSTR  SYNTAX
        DB      ')'
        TSTSTR  INPUT2
        DB      ','
        GOTO    DIM
NEG:    DO      STACK
        DO      FNEG
        DO      STBCK
L_DA56: DO      BOTTOM
        DO      TOP
        DO      SAVE
        DO      ADDOUT

        DB      255,255,255,255,255,255

PRINT:  TSTSTR  PRINT1
        DB      0xCC          ;'USING'
        TSTSTR  SYNTAX
        DB      '"'
        DO      USING
USNG:   ILCALL  USEXP
        TSTSTR  US1
        DB      ','
        GOTO    USNG
US1:    TSTSTR  US2
        DB      ';'
        DO      DNE
US2:    DO      LINE
        DO      DNE
        DB      0

        ORG     0xDB00
STREXP: ILCALL  STRF
STREX1: TSTSTR  STREX2
        DB      '&'
        ILCALL  STRF
        GOTO    STREX1
STREX2: DO      POPSTR
STRF:   TSTSTR  STRF1
        DB      '"'
        DO      PUTST
STRF1:  TSTSTR  STRF2
        DB      0xC5          ;'CHR$'
        ILCALL  SNGL
        DO      FIX
        DO      CHRSTR
STRF2:  TSTSTR  STRF4
        DB      0xC6          ;'LEFT$'
        TSTSTR  SYNTAX
        DB      '('
        TSTSTR  STRF3
        DB      '"'
        DO      STPNT
        TSTSTR  SYNTAX
        DB      ','
        ILCALL  REXPR
        DO      FIX
        TSTSTR  SYNTAX
        DB      ')'
        DO      XCHPNT
        DO      LEFTST
STRF3:  TSTVAR  SYNTAX
        DO      FNDVAR
        DO      DEFVAR
        TSTSTR  SYNTAX
        DB      '$'
        DO      LDVAR
        DO      FIX
        TSTSTR  SYNTAX
        DB      ','
        ILCALL  REXPR
        DO      FIX
        TSTSTR  SYNTAX
        DB      ')'
        DO      LFTSTR
STRF4:  TSTSTR  STRF6
        DB      0xC7          ;'MID$'
        TSTSTR  SYNTAX
        DB      '('
        TSTSTR  STRF5
        DB      '"'
        DO      STPNT
        TSTSTR  SYNTAX
        DB      ','
        ILCALL  REXPR
        DO      FIX
        TSTSTR  SYNTAX
        DB      ','
        ILCALL  REXPR
        DO      FIX
        TSTSTR  SYNTAX
        DB      ')'
        DO      XCHPNT
        DO      MIDST
STRF5:  TSTVAR  SYNTAX
        DO      FNDVAR
        DO      DEFVAR
        TSTSTR  SYNTAX
        DB      '$'
        DO      LDVAR
        DO      FIX
        TSTSTR  SYNTAX
        DB      ','
        ILCALL  REXPR
        DO      FIX
        TSTSTR  SYNTAX
        DB      ','
        ILCALL  REXPR
        DO      FIX
        TSTSTR  SYNTAX
        DB      ')'
        DO      MIDSTR
STRF6:  TSTSTR  STRF8
        DB      0xC8          ;'RIGHT$'
        TSTSTR  SYNTAX
        DB      '('
        TSTSTR  STRF7
        DB      '"'
        DO      STPNT
        TSTSTR  SYNTAX
        DB      ','
        ILCALL  REXPR
        DO      FIX
        TSTSTR  SYNTAX
        DB      ')'
        DO      XCHPNT
        DO      RGHTST
STRF7:  TSTVAR  SYNTAX
        DO      FNDVAR
        DO      DEFVAR
        TSTSTR  SYNTAX
        DB      '$'
        DO      LDVAR
        DO      FIX
        TSTSTR  SYNTAX
        DB      ','
        ILCALL  REXPR
        DO      FIX
        TSTSTR  SYNTAX
        DB      ')'
        DO      RGHSTR
STRF8:  TSTSTR  STRF9
        DB      0xCA          ;'STR$'
        ILCALL  SNGL
        DO      FNUM
        DO      FSTRNG
        DO      STBCK
STRF9:  TSTVAR  SYNTAX
        DO      FNDVAR
        DO      DEFVAR
        TSTSTR  SYNTAX
        DB      '$'
        DO      LDVAR
        DO      FIX
        DO      MOVSTR
RELSTR: DO      STRPNT
        TSTVAR  RELEXP
        DO      FNDVAR
        DO      POPDLR
        TSTSTR  RELXPR
        DB      '$'
        DO      LDVAR
        DO      FIX
        TSTSTR  SYNTAX
        DB      '='
        TSTSTR  RESTR
        DB      '"'
        DO      CMPRST
RESTR:  TSTVAR  SYNTAX
        DO      FNDVAR
        DO      DEFVAR
        TSTSTR  SYNTAX
        DB      '$'
        DO      LDVAR
        DO      FIX
        DO      CMPSTR
RELXPR: DO      XCHPNT
RELEXP: ILCALL  REXPR
        TSTSTR  REL1
        DB      '='
        ILCALL  REXPR
        DO      EQU
REL1:   TSTSTR  REL2
        DB      0xAB          ;'<>'
        ILCALL  REXPR
        DO      NEQ
REL2:   TSTSTR  REL3
        DB      '<'
        ILCALL  REXPR
        DO      LSS
REL3:   TSTSTR  REL4
        DB      0xA9          ;'<='
        ILCALL  REXPR
        DO      LEQ
REL4:   TSTSTR  REL5
        DB      '>'
        ILCALL  REXPR
        DO      GTR
REL5:   TSTSTR  RTRN
        DB      0xAA          ;'>='
        ILCALL  REXPR
        DO      GEQ
REXPR:  TSTSTR  REX1
        DB      '-'
        ILCALL  RTERM
        DO      STACK
        DO      FNEG
        DO      STBACK
        GOTO    REX3
REX1:   TSTSTR  REX2
        DB      '+'
REX2:   ILCALL  RTERM
REX3:   TSTSTR  REX4
        DB      '-'
        ILCALL  RTERM
        DO      STACK
        DO      FSUB
        DO      STBACK
        GOTO    REX3
REX4:   TSTSTR  REX5
        DB      '+'
        ILCALL  RTERM
        DO      STACK
        DO      FADD
        DO      STBACK
        GOTO    REX3
REX5:   TSTSTR  REX6
        DB      0xA5          ;'EXOR'
        ILCALL  RTERM
        DO      STACK
        DO      ALGEXP
        DO      EXOR
        DO      STBACK
        GOTO    REX3
REX6:   TSTSTR  RTRN
        DB      0xA7          ;'OR'
        ILCALL  RTERM
        DO      STACK
        DO      ALGEXP
        DO      OR
        DO      STBACK
        GOTO    REX3
RTERM:  ILCALL  REXPN
RT1:    TSTSTR  RT2
        DB      '*'
        ILCALL  REXPN
        DO      STACK
        DO      FMUL
        DO      STBACK
        GOTO    RT1
RT2:    TSTSTR  RT3
        DB      '/'
        ILCALL  REXPN
        DO      STACK
        DO      FDIV
        DO      STBACK
        GOTO    RT1
RT3:    TSTSTR  RT4
        DB      0xA3          ;'AND'
        ILCALL  REXPN
        DO      STACK
        DO      ALGEXP
        DO      AND
        DO      STBACK
        GOTO    RT1
RT4:    TSTSTR  RT5
        DB      0xA4          ;'DIV'
        ILCALL  REXPN
        DO      STACK
        DO      FDIV
        DO      INT
        DO      STBACK
        GOTO    RT1
RT5:    TSTSTR  RTRN
        DB      0xA6          ;'MOD'
        ILCALL  REXPN
        DO      STACK
        DO      FMOD
        DO      PSHSWP
        DO      FMUL
        DO      STBACK
        GOTO    RT1
REXPN:  ILCALL  RFACTR
REXPN1: TSTSTR  RTRN
        DB      '^'
        ILCALL  RFACTR
        DO      STACK
        DO      SWAP
        DO      LOG2
        DO      FMUL
        DO      EXP2
        DO      STBACK
        GOTO    REXPN1
SNGL:   TSTSTR  SYNTAX
        DB      '('
        ILCALL  REXPR
        TSTSTR  SYNTAX
        DB      ')'
RTRN:   DB      0
RFACTR: TSTNUM  RF1
RNUM:   TSTSTR  RNUM1
        DB      '.'
        TSTNUM  RNUM1
        DO      STACK
        DO      FD10
        DO      FADD
        DO      STBACK
RNUM1:  TSTSTR  RTRN
        DB      'E'
        TSTSTR  RNUM2
        DB      '-'
        DO      NUMTST
        DO      FDIV11
RNUM2:  TSTSTR  RNUM3
        DB      '+'
RNUM3:  DO      NUMTST
        DO      FMUL11
RF1:    TSTVAR  RF2
        DO      FNDVAR
        ILCALL  RINDEX
        DO      LDVAR
        DB      0
RF2:    TSTSTR  RF3
        DB      '('
        ILCALL  RELSTR
        TSTSTR  SYNTAX
        DB      ')'
        DB      0
RF3:    TSTSTR  RF4
        DB      0xAC          ;'ABS'
        ILCALL  SNGL
        DO      STACK
        DO      FABS
        DO      STBCK
RF4:    TSTSTR  RF5
        DB      0xAD          ;'ATN'
        ILCALL  SNGL
        DO      STACK
        DO      ATN
        DO      STBCK
RF5:    TSTSTR  RF6
        DB      0xAE          ;'COS'
        ILCALL  SNGL
        DO      STACK
        DO      PI2
        DO      FADD
        DO      SIN
        DO      STBCK
RF6:    TSTSTR  RF7
        DB      0xAF          ;'EXP'
        ILCALL  SNGL
        DO      STACK
        DO      LN2
        DO      FDIV
        DO      EXP2
        DO      STBCK
RF8:    TSTSTR  RF9
        DB      0xB1          ;'INT'
        ILCALL  SNGL
        DO      STACK
        DO      INT
        DO      STBCK
RF9:    TSTSTR  RF10
        DB      0xB2          ;'LB'
        ILCALL  SNGL
        DO      STACK
        DO      LOG2
        DO      STBCK
RF10:   TSTSTR  RF11
        DB      0xB3          ;'LG'
        ILCALL  SNGL
        DO      STACK
        DO      LOG2
        DO      LG2
        DO      FMUL
        DO      STBCK
RF11:   TSTSTR  RF12
        DB      0xB4          ;'LN'
        ILCALL  SNGL
        DO      STACK
        DO      LOG2
        DO      LN2
        DO      FMUL
        DO      STBCK
RF12:   TSTSTR  RF13
        DB      0xB5          ;'NOT'
        ILCALL  RFACTR
        DO      STACK
        DO      NOT
        DO      STBCK
RF13:   TSTSTR  RF14
        DB      0xB6          ;'PI'
        DO      PI
RF14:   TSTSTR  RF15
        DB      0xB7          ;'RND'
        DO      STACK
        DO      RND
        DO      NORM
        DO      STBCK
RF15:   TSTSTR  RF16
        DB      0xB8          ;'SGN'
        ILCALL  SNGL
        DO      SGN
RF16:   TSTSTR  RF17
        DB      0xB9          ;'SIN'
        ILCALL  SNGL
        DO      STACK
        DO      SIN
        DO      STBCK
RF17:   TSTSTR  RF18
        DB      0xBA          ;'SQR'
        ILCALL  SNGL
        DO      STACK
        DO      SQRT
        DO      STBCK
RF18:   TSTSTR  RF19
        DB      0xBB          ;'TAN'
        ILCALL  SNGL
        DO      STACK
        DO      TAN
        DO      SWAP
        DO      PI2
        DO      FADD
        DO      SIN
        DO      FDIV
        DO      STBCK
RF19:   TSTSTR  RF20
        DB      0xBC          ;'VAL'
        TSTSTR  SYNTAX
        DB      '('
        TSTVAR  SYNTAX
        DO      FNDVAR
        DO      CKDLLR
        DO      LDVAR
        DO      FIX
        DO      VSTRNG
        TSTNUM  SYNTAX
        ILCALL  RNUM
        DO      XCHPNT
        DB      0
RF20:   ILCALL  FACTOR
        DO      FLOAT2
FACTOR: TSTSTR  FCTR1
        DB      '#'
        DO      HEX
FCTR1:  TSTSTR  FCTR3
        DB      0xBD          ;'ASC'
        TSTSTR  SYNTAX
        DB      '('
        TSTSTR  FCTR2
        DB      '"'
        DO      ASC
FCTR2:  TSTVAR  SYNTAX
        DO      FNDVAR
        DO      CKDLLR
        DO      LDVAR
        DO      FIX
        DO      ASTRNG
FCTR3:  TSTSTR  FCTR4
        DB      0xBE          ;'FREE'
        DO      TOP
        DO      FREE
FCTR4:  TSTSTR  FCTR6
        DB      0xBF          ;'LEN'
        TSTSTR  SYNTAX
        DB      '('
        TSTSTR  FCTR5
        DB      '"'
        DO      LEN
FCTR5:  TSTVAR  SYNTAX
        DO      FNDVAR
        DO      CKDLLR
        DO      LDVAR
        DO      FIX
        DO      LSTRNG
FCTR6:  TSTSTR  FCTR7
        DB      0x98          ;'PAGE'
        DO      PGE
FCTR7:  TSTSTR  FCTR8
        DB      0xA8          ;'PEEK'
        ILCALL  SNGL
        DO      FIX
        DO      GETBYT
FCTR8:  TSTSTR  FCTR10
        DB      0xC0          ;'POS'
        TSTSTR  SYNTAX
        DB      '('
        TSTSTR  FCTR9
        DB      '"'
        GOTO    SYNTAX
        TSTVAR  SYNTAX
        DO      FNDVAR
        DO      CKDLLR
        DO      LDVAR
        DO      FIX
        GOTO    SYNTAX
FCTR9:  TSTVAR  SYNTAX
        DO      FNDVAR
        DO      CKDLLR
        DO      LDVAR
        DO      FIX
        GOTO    SYNTAX
        TSTVAR  SYNTAX
        DO      FNDVAR
        DO      CKDLLR
        DO      LDVAR
        DO      FIX
        GOTO    SYNTAX
FCTR10: TSTSTR  FCTR11
        DB      0xA0          ;'STAT'
        DO      STATUS
FCTR11: TSTSTR  SYNTAX
        DB      0xC1          ;'TOP'
        DO      TOP
        DB      0
RINDEX: DO      CKPT
INDEX:  DO      LADVAR
        ILCALL  REXPR
        DO      FIX
        DO      DMNSN
PREXP:  TSTSTR  PREX1
        DB      '"'
        DO      PRSTRG
PREX1:  TSTSTR  PREX2
        DB      0xC5          ;'CHR$'
        ILCALL  SNGL
        DO      POPAE
        DO      L_EF4C
PREX2:  TSTSTR  PREX3
        DB      0xC9          ;'SPC'
        ILCALL  SNGL
        DO      POPAE
        DO      SPC
PREX3:  TSTSTR  PREX4
        DB      0xCA          ;'STR$'
        ILCALL  SNGL
        GOTO    PREX9
PREX4:  TSTSTR  PREX5
        DB      0xCB          ;'TAB'
        ILCALL  SNGL
        DO      POPAE
        DO      TAB
PREX5:  TSTSTR  PREX6
        DB      0xCD          ;'VERT'
        ILCALL  SNGL
        DO      POPAE
        DO      VERT
PREX6:  DO      STRPNT
        TSTVAR  PREX8
        DO      FNDVAR
        DO      POPDLR
        TSTSTR  PREX7
        DB      '$'
        DO      LDVAR
        DO      POPAE
        DO      PSTRNG
PREX7:  DO      XCHPNT
PREX8:  ILCALL  REXPR
PREX9:  DO      FNUM
        DO      PRFNUM
        DB      0
RF7:    TSTSTR  RF8
        DB      0xB0          ;'FN'
        TSTVAR  SYNTAX
        DO      FNDDEF
        TSTSTR  FN6
        DB      '('
        DO      XCHPNT
        TSTSTR  SYNTAX
        DB      '('
FN1:    DO      XCHPNT
        TSTVAR  FN7
        DO      FNDVAR
        DO      DEFVAR
        TSTSTR  FN4
        DB      '('
        ILCALL  INDEX
FN2:    DO      XCHPNT
        ILCALL  REXPR
        DO      STVAR
FN3:    DO      XCHPNT
        TSTSTR  FN5
        DB      ','
        DO      XCHPNT
        TSTSTR  SYNTAX
        DB      ','
        GOTO    FN1
FN4:    TSTSTR  FN2
        DB      '$'
        DO      LDVAR
        DO      FIX
        DO      XCHPNT
        ILCALL  STREXP
        GOTO    FN3
FN5:    DO      XCHPNT
        TSTSTR  SYNTAX
        DB      ')'
        DO      XCHPNT
        TSTSTR  FN7
        DB      ')'
FN6:    TSTSTR  FN7
        DB      '='
        DO      FNT
        ILCALL  REXPR
        DO      FNDNE
FN7:    DO      FNERR
USEXP:  TSTSTR  USEX1
        DB      '"'
        DO      PRSTRG
USEX1:  TSTSTR  USEX2
        DB      0xC5          ;'CHR$'
        ILCALL  SNGL
        DO      POPAE
        DO      L_EF4C
USEX2:  TSTSTR  USEX3
        DB      0xC9          ;'SPC'
        ILCALL  SNGL
        DO      POPAE
        DO      SPC
USEX3:  TSTSTR  USEX4
        DB      0xCA          ;'STR$'
        ILCALL  SNGL
        GOTO    USEX9
USEX4:  TSTSTR  USEX5
        DB      0xCB          ;'TAB'
        ILCALL  SNGL
        DO      POPAE
        DO      TAB
USEX5:  TSTSTR  USEX6
        DB      0xCD          ;'VERT'
        ILCALL  SNGL
        DO      POPAE
        DO      VERT
USEX6:  DO      STRPNT
        TSTVAR  USEX8
        DO      FNDVAR
        DO      POPDLR
        TSTSTR  USEX7
        DB      '$'
        DO      LDVAR
        DO      POPAE
        DO      PSTRNG
USEX7:  DO      XCHPNT
USEX8:  ILCALL  REXPR
USEX9:  DO      FNUM
        DO      BOTOM1
        DO      PREND
        DB      0

        ORG     0xDFC1
;**************************************
;*   NIBLFP - INITIALIZATION OF NIBL  *
;**************************************

ENTRY:  DINT
        LDI     0x80
        XPAL    P3
        LDI     0xD0
        XPAH    P3
        LDI     0x1E
        XPAL    P2
        LD      -122(P3)
        XPAH    P2
        LDI     0x00
        ST      1(P2)
        LDI     0x00
        ST      (P2)
        LDI     0x80
        XPAL    P2
        ST      -29(P2)
        LDI     0x01
        ST      -10(P2)
        XPAL    P1
        LDI     0x70
L_DFE2: XPAH    P1
        LDI     0x0D
        ST      (P1)
        LD      3(P1)
        JZ      L_DFF2
        XAE
        LD      EREG(P1)
        XRI     0x0D
        JZ      L_DFF8
L_DFF2: LDI     0xFF
        ST      1(P1)
        ST      2(P1)
L_DFF8: XPAH    P1
        SCL
        CAI     0x10
        JNZ     L_DFE2
        NOP
        NOP
GETLIN: LD      127(P2)
        ANI     0xBF

        CALL    P3,PUTASC
        JP      GETL
        LDI     0x20

        CALL    P3,PUTASC
GETL:   LDI     0xB6
        XPAL    P1
        ST      -15(P2)
        LD      -122(P3)
        ORI     0x03
        XPAH    P1
        ST      -16(P2)
        LD      (P2)
        ST      -25(P2)
SETBUF: XAE
        LDI     0xFF
        ST      EREG(P1)
        DLD     -25(P2)
        JNZ     SETBUF
INP:
        CALL    P3,GETASC
        LD      -25(P2)
        XAE
        ST      -1(P1)
        ANI     0x60
        JNZ     STORE
        LD      -1(P1)
        XRI     0x08
        JZ      BS
        XRI     0x01
        JNZ     CR
        LD      EREG(P1)
        XRI     0xFF
        JNZ     NOS
        LDI     0x20
        ST      EREG(P1)
        JMP     HTAB
NOS:    XRI     0xFF
        XRI     0x0C
        JZ      HTAB
        ANI     0x60
        JZ      INCR
HTAB:   LDI     0x09

        CALL    P3,PUTASC
        JMP     INCR
BS:     LDE
        JZ      INP
        DLD     -25(P2)
        XAE
        LD      EREG(P1)
        XRI     0x0C
        JZ      OUTPT
        ANI     0x60
        JZ      INP
OUTPT:  LDI     0x08

        CALL    P3,PUTASC
INPT:   JMP     INP
CR:     XRI     0x04
        JZ      EX
        XRI     0x1C
        JZ      INSR
        XRI     0x09
        JZ      RUBOUT
        XRI     0x13
        OR      -25(P2)
        JZ      EX
STORE:  LD      -1(P1)
        ST      EREG(P1)
        XRI     0x0C
        JZ      STRE
        ANI     0x60
        JZ      LOAD
        LDI     0x00
        JMP     STRE
LOAD:   LDI     0xFF
STRE:   ST      -22(P2)
SSTRE:  LD      @EREG(P1)
BUFOUT: LD      @1(P1)
        XRI     0xFF
        JZ      BACK
        XRI     0xFF
        XRI     0x0C
        JNZ     NOF
        LDI     0x5C
        JMP     OUTCH
NOF:    ANI     0x60
        JZ      BUFOUT
        LD      -1(P1)
OUTCH:
        CALL    P3,PUTASC
        DLD     -22(P2)
        JMP     BUFOUT
BACK:   LDI     0x20

        CALL    P3,PUTASC
BCKS:   LDI     0x08

        CALL    P3,PUTASC
        ILD     -22(P2)
        ANI     0x80
        JNZ     BCKS
        LDI     0xB6
        XPAL    P1
INCR:   ILD     -25(P2)
        XOR     (P2)
        JNZ     INPT
EX:     LDI     0x0D
        XAE
        LD      -25(P2)
        XAE
        ST      EREG(P1)
LINE:   LDI     0x0D

        CALL    P3,PUTASC
        LDI     0x0A

        CALL    P3,PUTASC
        RTRN    P3
RUBOUT: LD      @EREG(P1)
SHFTL:  LD      1(P1)
        ST      @1(P1)
        LD      (P1)
        XRI     0xFF
        JNZ     SHFTL
        LDI     0xB6
        XPAL    P1
        DLD     -25(P2)
        JMP     LOAD
INSR:   ST      -22(P2)
        LD      @EREG(P1)
LOOK:   DLD     -22(P2)
        LD      @1(P1)
        XRI     0xFF
        JNZ     LOOK
SHFTR:  LD      -2(P1)
        ST      @-1(P1)
        ILD     -22(P2)
        XRI     0xFF
        JNZ     SHFTR
        LDI     0xB6
        XPAL    P1
        LDI     0xFF
        ST      72(P1)
        DLD     -25(P2)
        JMP     SSTRE         ; to $E097
SCAN:   SCL
        LD      @1(P1)
        CAI     0x5B
        JP      SSCAN2
        ADI     0x1A
        JP      SSCAN
        JMP     SSCAN2
SSCAN:  SCL
        LD      @1(P1)
        CAI     0x5B
        JP      SSCAN1
        ADI     0x1A
        JP      SSCAN
        ADI     0x07
        JP      SSCAN1
        ADI     0x0A
        JP      SSCAN
SSCAN1: LD      @-1(P1)
SSCAN2: LDI     0x80
        XPAL    P3
        LD      -100(P2)
        XPAH    P3
SCANR:  LD      @1(P1)
        XRI     0x20
        JZ      SCANR
        XRI     0x2D
        JZ      SCAN9
        XRI     0x37
        JZ      SCAN3
        XRI     0x18
        JNZ     SCAN2
SCAN1:  LD      @1(P1)
        XRI     0x22
        JZ      SCANR
        XRI     0x2F
        JNZ     SCAN1
        LDI     0x3C
        JMP     -98(P3)
SCAN2:  LD      @-1(P1)
SCAN3:  LDI     0xA0
        XPAL    P3
        LDI     0xD6
        XPAH    P3
SCAN4:  LD      @1(P3)
        JZ      SCAN
        ST      -24(P2)
        LDI     0xFF
        ST      -25(P2)
SCAN5:  ILD     -25(P2)
        XAE
        LD      EREG(P1)
        XOR     @1(P3)
        JZ      SCAN5
        XRI     0x80
        JZ      SCAN7
        JP      SCAN4
SCAN6:  LD      @+01(P3)
        JP      SCAN6
        JMP     SCAN4
SCAN7:  LD      -24(P2)
        ST      @1(P1)
        XPAL    P1
        ST      -24(P2)
        XPAL    P1
SCAN8:  LD      EREG(P1)
        ST      @1(P1)
        XRI     0x0D
        JNZ     SCAN8
        LD      -24(P2)
        XPAL    P1
        LD      -1(P1)
        XRI     0x89
        JNZ     SSCAN2
        LDI     0x80
        XPAL    P3
        LD      -100(P2)
        XPAH    P3
SCN1:   LD      @1(P1)
        XRI     0x3A
        JZ      SCAN3
        XRI     0x37
        JZ      SCAN9
        XRI     0x2F
        JNZ     SCN1
SCN2:   LD      @1(P1)
        XRI     0x22
        JZ      SCN1
        XRI     0x2F
        JNZ     SCN2
        LDI     0x3C
        JMP     -98(P3)
SCAN9:  LDI     0xB6
        XPAL    P1
        JMP     -42(P3)
POPAE:  CCL
        LD      -3(P2)
        ADI     0x04
        ST      -3(P2)
        XPAL    P2
        LDI     0x00
POP1:   XAE
POP2:   SCL
        ILD     -04(P2)
        JZ      87(P3)
        JP      POP4
        CAI     0x8F
        JZ      POP3
        LD      -3(P2)
        ADD     -3(P2)
        LD      -3(P2)
        RRL
        ST      -3(P2)
        LD      -2(P2)
        RRL
        ST      -2(P2)
        CSA
        JP      POP2
        JMP     POP1
POP3:   LDE
        AND     -3(P2)
        JP      POP5
        ILD     -2(P2)
        JNZ     POP5
        ILD     -03(P2)
        JMP     POP5
POP4:   LDI     0x00
        ST      -2(P2)
        ST      -3(P2)
POP5:   LD      -2(P2)
        XAE
        LD      -3(P2)
        XPAL    P2
        LDI     0x80
        XPAL    P2
        ST      -18(P2)
        XAE
        ST      -17(P2)
        JMP     -42(P3)
INSRT:  LD      -17(P2)
        ST      -8(P2)
        LD      -18(P2)
        ST      -9(P2)
        LD      -15(P2)
        XPAL    P3
        LD      -16(P2)
        XPAH    P3
        LDI     0x03
        ST      -25(P2)
L_1:    ILD     -25(P2)
        LD      @1(P3)
        XRI     0x0D
        JNZ     L_1
        LD      -25(P2)
        XRI     0x04
        JNZ     L_2
        ST      -25(P2)
L_2:    LD      -25(P2)
        XAE
        JNZ     L_MOVE
        LD      @3(P1)
        LDE
        CCL
        ADI     0xFC
        XAE
L_3:    LD      @1(P1)
        XRI     0x0D
        JZ      L_MOVE
        LDE
        CCL
        ADI     0xFF
        XAE
        JMP     L_3
L_MOVE: LDE
        OR      -25(P2)
        JZ      L_ADD1
        LDE
        JZ      L_ADD
        JP      L_UP
L_DOWN: LD      (P1)
        ST      EREG(P1)
        LD      @1(P1)
        XRI     0xFF
        JNZ     L_DOWN
        LD      (P1)
        XRI     0xFF
        JNZ     L_DOWN
        XRI     0xFF
        ST      EREG(P1)
        JMP     L_ADD
L_UP:   LD      -2(P1)
        ST      -22(P2)
        LDI     0xFF
        ST      -2(P1)
        LDI     0x55
        ST      -1(P1)
L_UP1:  LD      @+01(P1)
        XRI     0xFF
        JNZ     L_UP1
        LD      (P1)
        XRI     0xFF
        JNZ     L_UP1
        XPAH    P1
        ST      -18(P2)
        XPAH    P1
        XPAL    P1
        ST      -17(P2)
        XPAL    P1
        CCL
        LD      -17(P2)
        ADE
        LDI     0x00
        ADD     -18(P2)
        XOR     -18(P2)
        ANI     0xF0
        JZ      L_UP2
        LDI     0x00
        XAE
L_UP2:  LD      (P1)
        ST      EREG(P1)
        LD      @-1(P1)
        XRI     0xFF
        JNZ     L_UP2
        LD      1(P1)
        XRI     0x55
        JNZ     L_UP2
        LD      -22(P2)
        ST      (P1)
        LDI     0x0D
        ST      1(P1)
        LDE
        JZ      L_E2DE
L_ADD:  LD      -25(P2)
L_ADD1: JZ      L_E2DD
        LD      -15(P2)
        XPAL    P1
        LD      -16(P2)
        XPAH    P1
        LD      -13(P2)
        XPAL    P3
        LD      -14(P2)
        XPAH    P3
        LD      -9(P2)
        ST      @1(P3)
        LD      -8(P2)
        ST      @1(P3)
        LD      -25(P2)
        ST      @1(P3)
L_ADD2: LD      @1(P1)
        ST      @1(P3)
        XRI     0x0D
        JNZ     L_ADD2
L_E2DD: XPAH    P3
L_E2DE: LDI     0x80
        XPAL    P3
        LD      -100(P2)
        XPAH    P3
        JZ      -42(P3)
        LDI     0x1F
        JMP     -98(P3)
FNDVAR: LD      -122(P3)
        ORI     0x01
        XPAH    P3
        LDI     0x00
        XPAL    P3
FNDV:   LD      @1(P3)
        JZ      NTFND
        JP      FNDV1
        XRE
        JZ      FOUND
        LD      @4(P3)
        JMP     FNDV
FNDV1:  XRE
        JNZ     FNDV5
        XPAL    P1
        ST      -24(P2)
        XPAL    P1
        XPAH    P1
        ST      -25(P2)
        XPAH    P1
FNDV2:  LD      @1(P3)
        XOR     @1(P1)
        JZ      FNDV2
        JP      FNDV4
        XRI     0x80
        JZ      FNDV6
FNDV3:  LD      -24(P2)
        XPAL    P1
        LD      -25(P2)
        XPAH    P1
        LD      @4(P3)
        JMP     FNDV
FNDV4:  LD      -24(P2)
        XPAL    P1
        LD      -25(P2)
        XPAH    P1
FNDV5:  LD      @1(P3)
        JP      FNDV5
        LD      @4(P3)
        JMP     FNDV
FNDV6:  SCL
        LD      (P1)
        CAI     0x5B
        JP      SFOUND
        ADI     0x1A
        JP      FNDV3
        ADI     0x07
        JP      SFOUND
        ADI     0x0A
        JP      FNDV3
SFOUND: LDI     0x00
FOUND:  XAE
NTFND:  LD      @-1(P3)
        LD      -3(P2)
        XPAL    P2
        XPAL    P3
        ST      @-1(P2)
        XPAH    P3
        ST      @-1(P2)
        LDI     0x80
        XPAL    P2
        ST      -3(P2)
        LD      -100(P2)
        XPAH    P0
SAV:    LD      -4(P2)
        XRI     0xED
        JZ      31(P3)
        LD      127(P2)
        XRI     0xBF
        JZ      SAVMOD
        LDI     0x80
SAVMOD: XAE
        LD      -4(P2)
        XPAL    P2
        XPAL    P1
        ST      @-1(P2)
        XPAL    P1
        XPAH    P1
        ORE
        ST      @-1(P2)
        XRE
        XPAH    P1
        XPAL    P2
        ST      -4(P2)
        JMP     -42(P3)
DONE:   LD      @1(P1)
        XRI     0x20
        JZ      DONE
        XRI     0x2D
        JZ      -42(P3)
        XRI     0x37
        JZ      -42(P3)
        LDI     0x2D
        JMP     -98(P3)
BYE:    LDI     0x20
        JMP     42(P3)
IGNRE:  LD      @1(P1)
        XRI     0x0D
        JZ      NXT
        XRI     0x37
        JZ      NXT
        JMP     IGNRE
XFER:   JZ      XFER1
        LDI     0x4E
        JMP     -98(P3)
XFER1:  LDI     0xBF
        ST      127(P2)
        JMP     NXT1
THEN:   LD      @1(P1)
        XRI     0x20
        JZ      THEN
        XRI     0xE3
        JZ      -42(P3)
        LD      @-1(P1)
        JMP     NXT5
MOVESR: LD      -17(P2)
        CAS
DNE:    LD      @1(P1)
        XRI     0x20
        JZ      DNE
        XRI     0x2D
        JZ      NXT
        XRI     0x37
        JZ      NXT
        LDI     0x2D
        JMP     -98(P3)
CMPRE:  LD      -3(P2)
        XPAL    P2
        XAE
        LD      1(P2)
        OR      @4(P2)
        XAE
        XPAL    P2
        ST      -3(P2)
        LDE
        JNZ     THEN
ELS:    LD      @1(P1)
        XRI     0x0D
        JZ      NXT
        XRI     0x37
        JZ      ELS2
        XRI     0x18
        JNZ     ELS
ELS1:   LD      @1(P1)
        XRI     0x22
        JNZ     ELS1
        JMP     ELS
ELS2:   LD      @1(P1)
        XRI     0x20
        JZ      ELS2
        XRI     0xAD
        JZ      NXT5
        LD      @-1(P1)
        JMP     ELS
SNTX:   LD      126(P2)
        ST      -8(P2)
        LD      125(P2)
        ST      -9(P2)
SYNT:   LDI     0x63
        JMP     -98(P3)
IGNORE: LD      @1(P1)
        XRI     0x0D
        JNZ     IGNORE
NXT:    LD      127(P2)
        JP      NXT2
NXT1:   LD      (P1)
        XRI     0xFF
        JNZ     NXT3
NXT2:   LDI     0x86
        JMP     -98(P3)
NXT3:   CSA
        ANI     0x20
        JNZ     NXT4
BRK:    LDI     0x7C
        JMP     -98(P3)
NXT4:   LD      -01(P1)
        XRI     0x0D
        JNZ     NXT5
        LD      @1(P1)
        ST      -9(P2)
        LD      @2(P1)
        ST      -8(P2)
NXT5:   LDI     0x28
        JMP     NEXT1
NEXT:   LDI     0x16
NEXT1:  XAE
NEXT2:  LD      @1(P1)
        XRI     0x20
        JZ      NEXT2
        SCL
        JP      NEXT3
        LD      -1(P1)
        ADD     -1(P1)
        CAI     0x47
        JP      SYNT
        ADI     0x5D
        JMP     NEXT4
NEXT3:  LD      @-1(P1)
        LDI     0x5B
NEXT4:  XAE
        CAE
        JP      SYNT
        LDE
        XPAL    P3
        LDI     0xD8
        XPAH    P3
        LDI     0xD0
        XPAH    P0
SAVEDO: LD      -5(P2)
        XRI     0xE1
        JZ      31(P3)
        XRI     0xE1
        XPAL    P2
        XPAL    P1
        ST      @-1(P2)
        XPAL    P1
        XPAH    P1
        ST      @-1(P2)
        XPAH    P1
        XPAL    P2
        ST      -5(P2)
        JMP     NXT1
DETPGE: XPAH    P1
        XAE
        LDE
        XPAH    P1
        LDE
        SR
        SR
        SR
        SR
        ST      -10(P2)
        JMP     NXT
L_UNTL: ILD     -5(P2)
        ILD     -5(P2)
        JMP     NXT1
UNTL:   LD      -5(P2)
        XRI     0xED
        JNZ     UNTL1
        LDI     0x6B
        JMP     -98(P3)
UNTL1:  LD      -3(P2)
        XPAL    P2
        XAE
        LD      1(P2)
        OR      @4(P2)
        XAE
        XPAL    P2
        ST      -3(P2)
        LDE
        JNZ     L_UNTL
        LD      -5(P2)
        XPAL    P2
        XPAH    P1
        LD      1(P2)
        XPAL    P1
        LD      (P2)
        XPAH    P1
        XPAL    P2
        JMP     DETPGE
STPNT:  XPAL    P1
        ST      -15(P2)
        XPAL    P1
        XPAH    P1
        ST      -16(P2)
        XPAH    P1
STP:    LD      @1(P1)
        XRI     0x22
        JNZ     STP
        JMP     -42(P3)
STRT:   LDI     0xBF
        ST      127(P2)
CLRSTK: LDI     0xE1
        ST      -6(P2)
        LDI     0xED
        ST      -5(P2)
        LDI     0xFD
        ST      -4(P2)
        LDI     0x86
        RTRN    P3
RSTR:   LD      -4(P2)
        XRI     0xFD
        JNZ     RSTR1
        LDI     0x5F
        JMP     -98(P3)
RSTR1:  ILD     -4(P2)
        ILD     -4(P2)
        XPAL    P2
        LD      -2(P2)
        JP      RSTR2
        LDI     0x86
        JMP     33(P3)
RSTR2:  XPAH    P1
        LD      -1(P2)
        XPAL    P1
        LDI     0x80
        XPAL    P2
        JMP     DETPGE
L_E4F2: LD      -15(P2)
        ST      -19(P2)
        LD      -16(P2)
        ST      -20(P2)
        JMP     -42(P3)
        NOP
DEFVAR: JZ      -42(P3)
        LD      @-1(P1)
        LD      -3(P2)
        XPAL    P2
        LD      1(P2)
        XPAL    P3
        LD      (P2)
        XPAH    P3
        LDI     0x00
        XAE
        JMP     DEFV2
DEFV1:  ILD     1(P2)
        JNZ     DEFV2
        ILD     (P2)
DEFV2:  SCL
        LD      (P2)
        CAI     0xAF
        LD      (P2)
        ANI     0x0F
        CAI     0x0F
        JP      DEFERR
        LDE
        ADI     0xFF
        XAE
        LD      @1(P1)
        ST      @1(P3)
        SCL
        LD      (P1)
        CAI     0x5B
        JP      DEFV
        ADI     0x1A
        JP      DEFV1
        ADI     0x07
        JP      DEFV
        ADI     0x0A
        JP      DEFV1
DEFV:   LD      -1(P3)
        ORI     0x80
        ST      -1(P3)
        LD      (P1)
        XRI     0x24
        JZ      VARERR
        XRI     0x0C
        JZ      VARERR
        LDI     0x00
        ST      4(P3)
        LDI     0x80
        XPAL    P2
        LDI     0xD0
        XPAH    P0
FNDLBL: LDI     0x02
        XPAL    P1
        ST      -15(P2)
        LD      -10(P2)
        RR
        RR
        RR
        RR
        XPAH    P1
        ST      -16(P2)
L_LOOK: LD      (P1)
        XRI     0xFF
        JNZ     L_DIFF
        LD      1(P1)
        XRI     0xFF
        JZ      L_NO
L_DIFF: SCL
        LD      1(P1)
        CAD     -17(P2)
        XAE
        LD      (P1)
        CAD     -18(P2)
        JP      L_FIND
        LD      2(P1)
        XAE
        LD      @EREG(P1)
        JMP     L_LOOK
L_NO:   LDI     0x80
L_FIND: ORE
        XPAL    P1
        ST      -13(P2)
        XPAL    P1
        XPAH    P1
        ST      -14(P2)
        XPAH    P1
        RTRN    P3
        CAD     @-1(P3)
DEFERR: LDI     0x00
        ST      @EREG(P3)
        LDI     0x76
        JMP     VERR
VARERR: ST      @EREG(P3)
        LDI     0x73
VERR:   XAE
        LDI     0xD0
        XPAH    P0
CKMODE: LD      127(P2)
        XRI     0x80
        JP      -42(P3)
        LDI     0x67
        JMP     -98(P3)
SPC:    LD      -17(P2)
        JZ      71(P3)
SPC1:   LDI     0x20

        CALL    P3,PUTASC
        DLD     -17(P2)
        JNZ     SPC1
        JMP     71(P3)
PRSTRG: LD      @1(P1)
        XRI     0x22
        JZ      71(P3)
        LD      -1(P1)

        CALL    P3,PUTASC
        JMP     PRSTRG
        NOP
        NOP
SPRNUM: LD      @1(P1)
        ST      -9(P2)
        LD      @2(P1)
        ST      -8(P2)
PRNUM:  LD      -3(P2)
        XPAL    P1
        ST      -15(P2)
        LD      -122(P3)
        XPAH    P1
        ST      -16(P2)
        LDI     0x20
        ST      -11(P2)
        LDI     0xFB
        ST      -25(P2)
        LD      -8(P2)
        ST      -3(P1)
        LD      -9(P2)
        ST      -4(P1)
        JP      DIV
        LDI     0x2D
        ST      -11(P2)
        SCL
        LDI     0x00
        CAD     -8(P2)
        ST      -3(P1)
        LDI     0x00
        CAD     -9(P2)
        ST      -4(P1)
DIV:    LDI     0x00
        ST      -1(P1)
        ST      -2(P1)
        XAE
        LDI     0x10
        ST      -5(P1)
DIVLP:  CCL
        LD      -1(P1)
        ADD     -1(P1)
        ST      -1(P1)
        LD      -2(P1)
        ADD     -2(P1)
        ST      -2(P1)
        LD      -3(P1)
        ADD     -3(P1)
        ST      -3(P1)
        LD      -4(P1)
        ADD     -4(P1)
        ST      -4(P1)
        LDE
        ADE
        XAE
        LDE
        ADI     0xF6
        JP      DIV1
        JMP     DIV2
DIV1:   XAE
        ILD     -1(P1)
DIV2:   DLD     -5(P1)
        JNZ     DIVLP
        DLD     -25(P2)
        XAE
        ORI     0x30
        ST      EREG(P1)
        LD      -1(P1)
        ST      -3(P1)
        LD      -2(P1)
        ST      -4(P1)
        OR      -3(P1)
        JNZ     DIV
        LD      @EREG(P1)
        LD      -11(P2)
PRNT:
        CALL    P3,PUTASC
        LD      @1(P1)
        JNZ     PRNT
        LD      -15(P2)
        XPAL    P1
        LD      -16(P2)
        XPAH    P1
        RTRN    P3
        NOP
        NOP
        NOP
EQU:    LDI     0x01
        JMP     CMP
NEQ:    LDI     0x02
        JMP     CMP
LSS:    LDI     0x03
        JMP     CMP
LEQ:    LDI     0x04
        JMP     CMP
GTR:    LDI     0x05
        JMP     CMP
GEQ:    LDI     0x06
CMP:    ST      -21(P2)
        LD      -3(P2)
        XPAL    P1
        ST      -15(P2)
        LD      -122(P3)
        XPAH    P1
        ST      -16(P2)
        LD      5(P1)
        ST      -18(P2)
        LD      1(P1)
        ST      -17(P2)

        CALL    P3,FSUB
        LD      1(P1)
        XOR     -18(P2)
        XAE
        LD      -18(P2)
        XOR     -17(P2)
        ANE
        XOR     1(P1)
        ST      -22(P2)
        LD      1(P1)
        OR      (P1)
        JZ      SETZ
        LDI     0x80
SETZ:   XRI     0x80
        XAE
        DLD     -21(P2)
        JNZ     NEQU
        LDE
        JMP     CMPR
NEQU:   DLD     -21(P2)
        JNZ     LESS
        LDE
        XRI     0x80
        JMP     CMPR
LESS:   DLD     -21(P2)
        JNZ     LEQU
        LD      -22(P2)
        JMP     CMPR
LEQU:   DLD     -21(P2)
        JNZ     GRTR
        LDE
        OR      -22(P2)
        JMP     CMPR
GRTR:   DLD     -21(P2)
        JNZ     GEQU
        LDE
        OR      -22(P2)
        XRI     0x80
        JMP     CMPR
GEQU:   LD      -22(P2)
        XRI     0x80
CMPR:   JP      FLSE
        LDI     0x80
        ST      (P1)
        LDI     0x40
        ST      1(P1)
        JMP     STRE1
FLSE:   LDI     0x00
        ST      (P1)
        ST      1(P1)
STRE1:  LDI     0x00
        ST      2(P1)
        ST      3(P1)
        LD      -15(P2)
        XPAL    P1
        ST      -3(P2)
        LD      -16(P2)
        XPAH    P1
        JMP     71(P3)
STBCK:  LD      -13(P2)
        XPAL    P1
        ST      -3(P2)
        LD      -14(P2)
        XPAH    P1
        JMP     71(P3)
LST1:   SCL
        LD      1(P1)
        CAD     -17(P2)
        XAE
        LD      (P1)
        CAD     -18(P2)
        JP      LST3
LST2:   LD      (P1)
        XRI     0xFF
        JNZ     LST4
        LD      1(P1)
        XRI     0xFF
        JNZ     LST4
LST3:   ORE
        JZ      LST4
        LDI     0x86
        JMP     -98(P3)
LST4:
        CALL    P3,SPRNUM
LST5:   LD      @1(P1)
        JP      LST9
        ST      -25(P2)
        LDI     0xA0
        XPAL    P1
        ST      -15(P2)
        LDI     0xD6
        XPAH    P1
        ST      -16(P2)
LST6:   LD      -25(P2)
        XOR     @1(P1)
        JZ      LST8
LST7:   LD      @1(P1)
        JP      LST7
        JMP     LST6
LST8:   LD      @1(P1)

        CALL    P3,PUTASC
        JP      LST8
        LD      -15(P2)
        XPAL    P1
        LD      -16(P2)
        XPAH    P1
        JMP     LST5
LST9:
        CALL    P3,PUTASC
        XRI     0x0D
        JNZ     LST5
        LDI     0x0A

        CALL    P3,PUTASC
        CSA
        ANI     0x20
        JNZ     -42(P3)
        LDI     0x7C
        JMP     -98(P3)
LKPAGE: LD      -1(P1)
        XRI     0x0D
        JZ      CHPAGE
        LDI     0xFF
        ST      -25(P2)
LKPGE:  ILD     -25(P2)
        XAE
        LD      EREG(P1)
        XRI     0x20
        JZ      LKPGE
        XRI     0xB0
        JZ      CHPGE
        XRI     0x01
        JZ      CHPGE
CHPAGE: LDI     0x02
        ST      -19(P2)
        XPAL    P1
        LD      -10(P2)
        RR
        RR
        RR
        RR
        ST      -20(P2)
        XPAH    P1
        JMP     -42(P3)
CHPGE:  LDI     0x02
        ST      -19(P2)
        LD      -10(P2)
        RR
        RR
        RR
        RR
        ST      -20(P2)
        JMP     -42(P3)
ONE:    LD      -3(P2)
        XPAL    P2
        ST      @-4(P2)
        SR
        ST      1(P2)
        LDI     0x00
        ST      2(P2)
        ST      3(P2)
        LDI     0x80
        XPAL    P2
        ST      -3(P2)
        JMP     -42(P3)
SAVFOR: LD      -6(P2)
        XAE
        LDE
        XRI     0xB1
        JZ      31(P3)
        LD      -122(P3)
        XPAH    P3
        LD      -3(P2)
        XPAL    P2
        LDE
SFOR1:  XRI     0xE1
        JZ      SFOR3
        XRI     0xE1
        XPAL    P3
        LD      12(P2)
        XOR     @12(P3)
        JNZ     SFOR2
        LD      13(P2)
        XOR     -11(P3)
        JZ      SFOR4
SFOR2:  XPAL    P3
        JMP     SFOR1
SFOR3:  LDE
        XPAL    P3
SFOR4:  XPAL    P1
        ST      @-1(P3)
        XPAL    P1
        XPAH    P1
        ST      @-1(P3)
        XPAH    P1
        LD      7(P2)
        ST      @-1(P3)
        LD      6(P2)
        ST      @-1(P3)
        LD      5(P2)
        ST      @-1(P3)
        LD      4(P2)
        ST      @-1(P3)
        LD      3(P2)
        ST      @-1(P3)
        LD      2(P2)
        ST      @-1(P3)
        LD      1(P2)
        ST      @-1(P3)
        LD      @8(P2)
        ST      @-1(P3)
        LD      5(P2)
        ST      @-1(P3)
        LD      4(P2)
        ST      @-1(P3)
        LDI     0x80
        XPAL    P2
        ST      -3(P2)
        XPAL    P3
        ST      -6(P2)
STVAR:  LD      -3(P2)
        XPAL    P2
        LD      5(P2)
        XPAL    P3
        LD      4(P2)
        XPAH    P3
        LD      @6(P2)
        ST      1(P3)
        LD      -5(P2)
        ST      2(P3)
        LD      -4(P2)
        ST      3(P3)
        LD      -3(P2)
        ST      4(P3)
        LDI     0x80
        XPAL    P2
        ST      -3(P2)
        LDI     0x80
        XPAL    P3
        LD      -100(P2)
        XPAH    P3
        JMP     -42(P3)
NXTVAR: JZ      VARFND
        LDI     0x73
        JMP     -98(P3)
VARFND: LD      @1(P1)
        XRI     0x20
        JZ      VARFND
        XRI     0x2D
        JZ      VAR1
        XRI     0x37
        JZ      VAR1
        LDI     0x2D
        JMP     -98(P3)
VAR1:   LD      -6(P2)
        XRI     0xE1
        JNZ     VAR2
        LDI     0x4A
        JMP     -98(P3)
VAR2:   ILD     -3(P2)
        ILD     -3(P2)
        XPAL    P1
        ST      -15(P2)
        LD      -122(P3)
        XPAH    P1
        ST      -16(P2)
VAR3:   LD      -6(P2)
        XPAL    P2
        LD      -1(P1)
        XOR    +01(P2)
        JNZ     VAR4
        LD      -2(P1)
        XOR    +00(P2)
        JZ      VAR5
VAR4:   LD      @12(P2)
        LDI     0x80
        XPAL    P2
        ST      -6(P2)
        XRI     0xE1
        JNZ     VAR3
        LDI     0x40
        JMP     -98(P3)
VAR5:   SCL
        LDI     0x0C
VAR6:   CAI     0x01
        XAE
        LD      EREG(P2)
        ST      @-1(P1)
        LDE
        JNZ     VAR6
        SRL
        XPAL    P2
        LD      3(P1)
        ST      -22(P2)
        XPAL    P1
        ST      -3(P2)
        XPAL    P1
        LD      @-2(P1)
LDVAR:  LD      -3(P2)
        XPAL    P2
        LD      1(P2)
        XPAL    P3
        LD      (P2)
        XPAH    P3
        XAE
        LD      4(P3)
        ST      1(P2)
        LD      3(P3)
        ST      (P2)
        LD      2(P3)
        ST      -1(P2)
        LD      1(P3)
        ST      @-2(P2)
        LDI     0x80
        XPAL    P2
        ST      -3(P2)
        LDI     0x80
        XPAL    P3
        LDE
        XPAH    P3
        JMP     -42(P3)
NXTV:   LD      -06(P2)
        XPAL    P2
        LD      (P2)
        XAE
        LD      1(P2)
        XPAL    P2
        LDE
        XPAH    P2
        LD      (P1)
        ST      1(P2)
        LD      1(P1)
        ST      2(P2)
        LD      2(P1)
        ST      3(P2)
        LD      3(P1)
        ST      4(P2)
        LDI     0x80
        XPAL    P2
        LD      -122(P3)
        XPAH    P2
        LD      -22(P2)
        JP      NXTV2

        CALL    P3,SWAP

        CALL    P3,FSUB
        LD      1(P1)
        XRI     0x80
        JP      NXTV3
NXTV1:  LD      @6(P1)
        LD      -2(P1)
        XAE
        LD      -1(P1)
        XPAL    P1
        ST      -3(P2)
        LDE
        XPAH    P1
        JMP     -42(P3)
NXTV2:
        CALL    P3,FSUB
        LD      1(P1)
        JP      NXTV1
NXTV3:  CCL
        LD      -6(P2)
        ADI     0x0C
        ST      -6(P2)
        LD      @6(P1)
        LD      -15(P2)
        XPAL    P1
        ST      -3(P2)
        LD      -16(P2)
        XPAH    P1
        JMP     -42(P3)
LDDTA:  LD      -19(P2)
        XPAL    P1
        ST      -15(P2)
        LD      -20(P2)
        XPAH    P1
        ST      -16(P2)
        JMP     -42(P3)
NXTDTA: LD      -1(P1)
        XRI     0x0D
        JZ      DTA2
DTA1:   LD      @1(P1)
        XRI     0x20
        JZ      DTA1
        XRI     0x0C
        JZ      FNDTA
        XRI     0x16
        JZ      DTA4
        XRI     0x37
        JZ      DTA2
        LD      126(P2)
        ST      -8(P2)
        LD      125(P2)
        ST      -9(P2)
        LDI     0x2D
        JMP     -98(P3)
DTA2:   LD      (P1)
        XRI     0xFF
        JNZ     DTA3
        LDI     0x34
        JMP     -98(P3)
DTA3:   LD      @1(P1)
        ST      125(P2)
        LD      @2(P1)
        ST      126(P2)
DTA4:   LD      @1(P1)
        XRI     0x20
        JZ      DTA4
        XRI     0xA9
        JZ      FNDTA
NODTA:  LD      -1(P1)
        XRI     0x3A
        JZ      DTA4
        XRI     0x37
        JZ      DTA2
        LD      @1(P1)
        JMP     NODTA
FNDTA:  LD      @1(P1)
        XRI     0x20
        JZ      FNDTA
        LD      @-1(P1)
        JMP     -42(P3)
ISTRNG: LD      -17(P2)
        XPAL    P3
        LD      -18(P2)
        XPAH    P3
        XAE
ISTR1:  LD      @1(P1)
        ST      @1(P3)
        XRI     0x0D
        JNZ     ISTR1
        LDI     0x80
        XPAL    P3
        LDE
        XPAH    P3
XCHPNT: LD      -15(P2)
        XPAL    P1
        ST      -15(P2)
        LD      -16(P2)
        XPAH    P1
        ST      -16(P2)
        JMP     -42(P3)
INSTR:  LD      -17(P2)
        XPAL    P3
        LD      -18(P2)
        XPAH    P3
        XAE
INSTR1: LD      (P1)
        XRI     0x2C
        JZ      PUTS2
        XRI     0x16
        JZ      PUTS2
        XRI     0x37
        JZ      PUTS2
        LD      @1(P1)
        ST      @1(P3)
        JMP     INSTR1
PUTSTR: LD      -17(P2)
        XPAL    P3
        LD      -18(P2)
        XPAH    P3
        XAE
PUTS1:  LD      @1(P1)
        XRI     0x22
        JZ      PUTS2
        XRI     0x22
        ST      @1(P3)
        JMP     PUTS1
PUTS2:  LDI     0x0D
        ST      (P3)
        LDI     0x80
        XPAL    P3
        LDE
        XPAH    P3
        JMP     -42(P3)
FNDDTA: LDI     0x02
        ST      -15(P2)
        LD      -10(P2)
        RR
        RR
        RR
        RR
        ST      -16(P2)
        JMP     -42(P3)
PRSTR:  LD      @1(P1)
        XRI     0x22
        JZ      -42(P3)
        LD      -1(P1)

        CALL    P3,PUTASC
        JMP     PRSTR
GTO:    LD      -17(P2)
        JNZ     GTO1
        DLD     -18(P2)
GTO1:   DLD     -17(P2)
        OR      -18(P2)
        JZ      GTO4
GTO2:   LD      @1(P1)
        XRI     0x20
        JZ      GTO2
        XRI     0x0C
        JZ      GTO3
        LDI     0x4E
        JMP     -98(P3)
GTO3:   CCL
        LD      -3(P2)
        ADI     0x04
        ST      -3(P2)
        SCL
        LD      -1(P2)
        CAI     0x04
        ST      -1(P2)
        LD      -2(P2)
        CAI     0x00
        ST      -2(P2)
        JMP     -42(P3)
GTO4:   LD      @1(P1)
        XRI     0x0D
        JZ      -42(P3)
        XRI     0x37
        JZ      -42(P3)
        JMP     GTO4
NEWPGM: LDI     0x02
        XPAL    P1
        LD      -10(P2)
        RR
        RR
        RR
        RR
        XPAH    P1
        LDI     0x0D
        ST      -1(P1)
        LDI     0xFF
        ST      (P1)
        ST      1(P1)
        JMP     -42(P3)
MC:     LDI     0x70
        JMP     42(P3)
EDITR:  JZ      EDIT1
        LDI     0x86
        JMP     -98(P3)
EDIT1:  ST      -22(P2)
        LD      @1(P1)
        ST      -9(P2)
        LD      @2(P1)
        ST      -8(P2)

        CALL    P3,PRNUM
EDIT2:  LD      @1(P1)
        XRI     0x0C
        JNZ     EDIT3
        LDI     0x5C
        JMP     EDIT8
EDIT3:  XRI     0x01
        JZ      EDIT9
        JP      EDIT7
        XRI     0x0D
        XAE
        LDI     0xA0
        XPAL    P1
        ST      -15(P2)
        LDI     0xD6
        XPAH    P1
        ST      -16(P2)
EDIT4:  LDE
        XOR     @1(P1)
        JZ      EDIT6
EDIT5:  LD      @1(P1)
        JP      EDIT5
        JMP     EDIT4
EDIT6:  ILD     -22(P2)
        LD      @1(P1)

        CALL    P3,PUTASC
        JP      EDIT6
        LD      -15(P2)
        XPAL    P1
        LD      -16(P2)
        XPAH    P1
        JMP     EDIT2
EDIT7:  ANI     0x60
        JZ      EDIT2
        LD      -1(P1)
EDIT8:
        CALL    P3,PUTASC
        ILD     -22(P2)
        JMP     EDIT2
EDIT9:  LDI     0x08

        CALL    P3,PUTASC
        DLD     -22(P2)
        JNZ     EDIT9
        LDI     0xB6
        XPAL    P1
        LD      -122(P3)
        ORI     0x03
        XPAH    P1
        LD      (P2)
        ST      -22(P2)
CLRBUF: XAE
        LDI     0xFF
        ST      EREG(P1)
        DLD     -22(P2)
        JP      CLRBUF
        XAE
        CCL
        LD      -25(P2)
        ADD     -3(P2)
        XPAL    P2
EDIT10: CCL
        LDE
        ADI     0x01
        XAE
        LD      @1(P2)
        JZ      EDIT11
        ST      EREG(P1)
        JMP     EDIT10
EDIT11: LDI     0x80
        XPAL    P2
        LDE
        ST      -25(P2)
        LD      -13(P2)
        XPAL    P3
        LD      -14(P2)
        XPAH    P3
        LD      @3(P3)
EDIT12: LD      @1(P3)
        XRI     0x0D
        JZ      EDIT17
        XRI     0x0D
        JP      EDIT16
        ST      -22(P2)
        LDI     0xA0
        XPAL    P3
        ST      -15(P2)
        LDI     0xD6
        XPAH    P3
        ST      -16(P2)
EDIT13: LD      -22(P2)
        XOR     @1(P3)
        JZ      EDIT15
EDIT14: LD      @1(P3)
        JP      EDIT14
        JMP     EDIT13
EDIT15: LD      @1(P3)
        ANI     0x7F
        ST      EREG(P1)
        LDE
        ADI     0x01
        XAE
        LD      -1(P3)
        JP      EDIT15
        LD      -15(P2)
        XPAL    P3
        LD      -16(P2)
        XPAH    P3
        JMP     EDIT12
EDIT16: ST      EREG(P1)
        LDE
        ADI     0x01
        XAE
        JMP     EDIT12
EDIT17: LDI     0x80
        XPAL    P3
        LD      -100(P2)
        XPAH    P3
        JMP     -42(P3)
NUMTST: LD      @1(P1)
        XRI     0x20
        JZ      NUMTST
        XRI     0x20
        SCL
        CAI     0x3A
        JP      NUMERR
        ADI     0x0A
        JP      DIGIT
NUMERR: LD      @-1(P1)
        LDI     0x63
        JMP     -98(P3)
DIGIT:  XAE
        DLD     -3(P2)
        DLD     -3(P2)
        XPAL    P2
        LDE
        ST      1(P2)
        XRE
DIGIT1: ST      (P2)
        SCL
        LD      @1(P1)
        CAI     0x3A
        JP      NUMEND
        ADI     0x0A
        JP      MORE
NUMEND: LD      @-1(P1)
        LDI     0x80
        XPAL    P2
        JMP     -42(P3)
MORE:   XAE
        CCL
        LD      1(P2)
        ADD     1(P2)
        ST      -1(P2)
        LD      (P2)
        ADD     (P2)
        ST      -2(P2)
        CCL
        LD      -1(P2)
        ADD     -1(P2)
        ST      -1(P2)
        LD      -2(P2)
        ADD     -2(P2)
        ST      -2(P2)
        CCL
        LD      -1(P2)
        ADD     1(P2)
        ST      1(P2)
        LD      -2(P2)
        ADD     (P2)
        ST      (P2)
        CCL
        LD      1(P2)
        ADD     1(P2)
        ST      1(P2)
        LD      (P2)
        ADD     (P2)
        ST      (P2)
        CCL
        LDE
        ADD     1(P2)
        ST      1(P2)
        LDI     0x00
        ADD     (P2)
        JP      DIGIT1
        JMP     87(P3)
AUTONM: LD      -17(P2)
        ST      -8(P2)
        LD      -18(P2)
        ST      -9(P2)

        CALL    P3,PRNUM
        CCL
        LD      -25(P2)
        ADI     0x4D
        ST      (P2)
        JMP     -42(P3)
AUTON:  LD      -25(P2)
        JZ      -42(P3)
        LD      -3(P2)
        XPAL    P1
        LD      -122(P3)
        XPAH    P1
        CCL
        LD      -8(P2)
        ADD     1(P1)
        ST      -17(P2)
        LD      -9(P2)
        ADD     (P1)
        ST      -18(P2)
        JMP     -42(P3)
TEN:    LD      -3(P2)
        XPAL    P2
        LDI     0x0A
        ST      @-1(P2)
        LDI     0x00
        ST      @-1(P2)
        LDI     0x80
        XPAL    P2
        ST      -3(P2)
        JMP     -42(P3)
FIX:    ILD     -3(P2)
        ILD     -3(P2)
        XPAL    P2
        LD      (P2)
        ST      1(P2)
        LD      -1(P2)
        ST      (P2)
        LDI     0x00
FIX1:   XAE
FIX2:   SCL
        ILD     -2(P2)
        JZ      87(P3)
        JP      FIX5
        CAI     0x8F
        JZ      FIX3
        LD      (P2)
        ADD     (P2)
        LD      (P2)
        RRL
        ST      (P2)
        LD      1(P2)
        RRL
        ST      1(P2)
        CSA
        JP      FIX2
        JMP     FIX1
FIX3:   LDE
        AND     (P2)
        JP      FIX4
        ILD     1(P2)
        JNZ     FIX4
        ILD     (P2)
FIX4:   LDI     0x80
        XPAL    P2
        JMP     -42(P3)
FIX5:   LDI     0x00
        ST      1(P2)
        ST      (P2)
        JMP     FIX4
MIDST:  LD      -3(P2)
        XPAL    P2
MID1:   LD      @1(P1)
        XRI     0x22
        JZ      MID3
        LD      3(P2)
        JNZ     MID2
        DLD     2(P2)
MID2:   DLD     3(P2)
        OR      2(P2)
        JNZ     MID1
MID3:   LD      @-1(P1)
        LD      1(P2)
        ST      3(P2)
        LD      @2(P2)
        ST      (P2)
        LDI     0x80
        XPAL    P2
        ST      -3(P2)
LEFTST: ILD     -3(P2)
        ILD     -3(P2)
        XPAL    P2
        LD      1(P2)
        XPAL    P3
        LD      (P2)
        XPAH    P3
        XAE
LEFT1:  LD      @1(P1)
        XRI     0x22
        JZ      LEFT3
        XRI     0x22
        ST      @1(P3)
        LD      -1(P2)
        JNZ     LEFT2
        DLD     -2(P2)
LEFT2:  DLD     -1(P2)
        OR      -2(P2)
        JNZ     LEFT1
LEFT3:  LDI     0x0D
        ST      (P3)
        LDI     0x80
        XPAL    P3
        ST      1(P2)
        LDE
        XPAH    P3
        ST      (P2)
        LDI     0x80
        XPAL    P2
        LD      -15(P2)
        XPAL    P1
        LD      -16(P2)
        XPAH    P1
        JMP     71(P3)
RGHTST: ILD     -3(P2)
        ILD     -3(P2)
        XPAL    P2
        LD      1(P2)
        XPAL    P3
        LD      (P2)
        XPAH    P3
        XAE
RIGHT1: LD      @1(P1)
        XRI     0x22
        JNZ     RIGHT1
        LD      @-1(P1)
RIGHT2: LD      -1(P1)
        XRI     0x22
        JZ      RIGHT4
        LD      @-1(P1)
        LD      -1(P2)
        JNZ     RIGHT3
        DLD     -2(P2)
RIGHT3: DLD     -1(P2)
        OR      -2(P2)
        JNZ     RIGHT2
RIGHT4: LD      @1(P1)
        XRI     0x22
        JZ      LEFT3
        XRI     0x22
        ST      @1(P3)
        JMP     RIGHT4
CHRSTR: ILD     -3(P2)
        ILD     -3(P2)
        XPAL    P2
        LD      1(P2)
        XPAL    P3
        LD      (P2)
        XPAH    P3
        XAE
        LD      -1(P2)
        ST      @1(P3)
        JMP     PUTST2
PUTST:  LD      -3(P2)
        XPAL    P2
        LD      1(P2)
        XPAL    P3
        LD      (P2)
        XPAH    P3
        XAE
PUTST1: LD      @1(P1)
        XRI     0x22
        JZ      PUTST2
        XRI     0x22
        ST      @1(P3)
        JMP     PUTST1
PUTST2: LDI     0x0D
        ST      (P3)
        LDI     0x80
        XPAL    P3
        ST      1(P2)
        LDE
        XPAH    P3
        ST      (P2)
        LDI     0x80
        XPAL    P2
        JMP     71(P3)
MIDSTR: LD      -3(P2)
        XPAL    P2
        LD      5(P2)
        XPAL    P1
        ST      5(P2)
        LD      4(P2)
        XPAH    P1
        ST      4(P2)
MSTR1:  LD      @1(P1)
        XRI     0x0D
        JZ      MSTR3
        LD      3(P2)
        JNZ     MSTR2
        DLD     2(P2)
MSTR2:  DLD     3(P2)
        OR      2(P2)
        JNZ     MSTR1
MSTR3:  LD      @-1(P1)
        LD      1(P2)
        ST      3(P2)
        LD      @6(P2)
        ST      -4(P2)
        JMP     LFSTR1
LFTSTR: LD      -3(P2)
        XPAL    P2
        LD      3(P2)
        XPAL    P1
        ST      3(P2)
        LD      2(P2)
        XPAH    P1
        ST      2(P2)
        LD      @4(P2)
LFSTR1: LD      1(P2)
        XPAL    P3
        LD      (P2)
        XPAH    P3
        XAE
LFSTR2: LD      @1(P1)
        XRI     0x0D
        JZ      LFSTR4
        XRI     0x0D
        ST      @1(P3)
        LD      -3(P2)
        JNZ     LFSTR3
        DLD     -4(P2)
LFSTR3: DLD     -3(P2)
        OR      -4(P2)
        JNZ     LFSTR2
LFSTR4: LDI     0x0D
        ST      (P3)
        JMP     STREND
RGHSTR: LD      -3(P2)
        XPAL    P2
        LD      3(P2)
        XPAL    P1
        ST      3(P2)
        LD      2(P2)
        XPAH    P1
        ST      2(P2)
        LD      5(P2)
        XPAL    P3
        LD      4(P2)
        XPAH    P3
        XAE
        LDI     0xFF
        ST      -1(P2)
        ST      -2(P2)
RGSTR1: ILD     -1(P2)
        JNZ     RGSTR2
        ILD     -2(P2)
RGSTR2: LD      @1(P1)
        XRI     0x0D
        JNZ     RGSTR1
        LD      @-1(P1)
        SCL
        LD      -1(P2)
        CAD     1(P2)
        LD      -2(P2)
        CAD     @4(P2)
        JP      RGSTR3
        LD      -5(P2)
        ST      -3(P2)
        LD      -6(P2)
        ST      -4(P2)
RGSTR3: SCL
        XPAL    P1
        CAD     -3(P2)
        XPAL    P1
        XPAH    P1
        CAD     -4(P2)
        XPAH    P1
        JMP     MVSTR1
MOVSTR: LD      -3(P2)
        XPAL    P2
        LD      @1(P2)
        XPAH    P1
        ST      -1(P2)
        LD      @1(P2)
        XPAL    P1
        ST      -1(P2)
        LD      (P2)
        XPAH    P3
        XAE
        LD      1(P2)
        XPAL    P3
MVSTR1: LD      @1(P1)
        ST      @1(P3)
        XRI     0x0D
        JZ      MVSTR2
        CSA
        ANI     0x20
        JNZ     MVSTR1
MVSTR2: LD      @-1(P3)
STREND: LD      -1(P2)
        XPAL    P1
        LD      -2(P2)
        XPAH    P1
        LDI     0x80
        XPAL    P3
        ST      1(P2)
        LDE
        XPAH    P3
        ST      (P2)
        LDI     0x80
        XPAL    P2
        ST      -3(P2)
        JMP     71(P3)
FSTRNG: LD      -3(P2)
        XPAL    P1
        LD      5(P1)
        XPAL    P3
        LD      4(P1)
        XPAH    P3
        XAE
        LD      @-5(P1)
FSTR1:  ST      @1(P3)
        LD      @-1(P1)
        JP      FSTR1
        LDI     0x0D
        ST      (P3)
        LDI     0x5E
        XPAL    P1
        LDI     0x80
        XPAL    P3
        ST      1(P1)
        LDE
        XPAH    P3
        ST      (P1)
        JMP     -42(P3)
POPSTR: ILD     -3(P2)
        ILD     -3(P2)
        JMP     71(P3)
STRPNT: XPAL    P1
        ST      -15(P2)
        XPAL    P1
        XPAH    P1
        ST      -16(P2)
        XPAH    P1
        JMP     -42(P3)
CMPRST: DLD     -3(P2)
        DLD     -3(P2)
        XPAL    P2
        LD      3(P2)
        XPAL    P3
        LD      2(P2)
        XPAH    P3
        XAE
CMPR1:  LD      @1(P1)
        XRI     0x22
        JZ      CMPR4
        XRI     0x22
        XOR     @1(P3)
        JZ      CMPR1
CMPR2:  LD      @1(P1)
        XRI     0x22
        JNZ     CMPR2
CMPR3:  LDI     0x00
        ST      (P2)
        ST      1(P2)
        JMP     CMPEND
CMPR4:  LD      (P3)
        XRI     0x0D
        JNZ     CMPR3
        LDI     0x80
        ST      (P2)
        SR
        ST      1(P2)
        JMP     CMPEND
CMPSTR: LD      -3(P2)
        XPAL    P2
        LD      3(P2)
        XPAL    P3
        LD      2(P2)
        XPAH    P3
        XAE
        LD      1(P2)
        XPAL    P1
        ST      3(P2)
        LD      (P2)
        XPAH    P1
        ST      2(P2)
CMP1:   LD      @1(P1)
        XRI     0x0D
        JZ      CMP3
        XRI     0x0D
        XOR     @1(P3)
        JZ      CMP1
CMP2:   LDI     0x00
        ST      (P2)
        ST      1(P2)
        JMP     CMP4
CMP3:   LD      (P3)
        XRI     0x0D
        JNZ     CMP2
        LDI     0x80
        ST      (P2)
        SR
        ST      1(P2)
CMP4:   LD      3(P2)
        XPAL    P1
        LD      2(P2)
        XPAH    P1
CMPEND: LDI     0x00
        ST      2(P2)
        ST      3(P2)
        LDI     0x80
        XPAL    P3
        LDE
        XPAH    P3
        LDI     0x80
        XPAL    P2
        JMP     71(P3)
PUTBYT: LD      -3(P2)
        XPAL    P2
        LD      @4(P2)
        LD      -1(P2)
        XPAL    P3
        LD      -2(P2)
        XPAH    P3
        XAE
        LD      -3(P2)
        ST      (P3)
        LDI     0x80
        XPAL    P2
        ST      -3(P2)
        LDI     0x80
        XPAL    P3
        LDE
        XPAH    P3
        JMP     -42(P3)
GETBYT: LD      -3(P2)
        XPAL    P2
        LD      1(P2)
        XPAL    P3
        LD      (P2)
        XPAH    P3
        XAE
        LD      (P3)
        ST      1(P2)
        LDI     0x00
        ST      (P2)
STRNG:  LDI     0x80
        XPAL    P2
        LDI     0x80
        XPAL    P3
        LDE
        XPAH    P3
        JMP     71(P3)
ASC:    LD      -3(P2)
        XPAL    P2
        LDI     0x00
        ST      @-1(P2)
        ST      @-1(P2)
        LD      @1(P1)
        XRI     0x22
        JZ      LEN3
        XRI     0x22
        ST      1(P2)
ASC1:   LD      @1(P1)
        XRI     0x22
        JNZ     ASC1
        JMP     LEN3
ASTRNG: LD      -3(P2)
        XPAL    P2
        LD      1(P2)
        XPAL    P3
        LD      (P2)
        XPAH    P3
        XAE
        LDI     0x00
        ST      (P2)
        LD      @1(P3)
        XRI     0x0D
        JZ      ASTR1
        XRI     0x0D
ASTR1:  ST      1(P2)
        JMP     STRNG
LSTRNG: LD      -3(P2)
        XPAL    P2
        LD      1(P2)
        XPAL    P3
        LD      (P2)
        XPAH    P3
        XAE
        LDI     0xFF
        ST      1(P2)
        ST      (P2)
LSTR1:  ILD     1(P2)
        JNZ     LSTR2
        ILD     (P2)
LSTR2:  LD      @1(P3)
        XRI     0x0D
        JNZ     LSTR1
        JMP     STRNG
LEN:    LD      -3(P2)
        XPAL    P2
        LDI     0xFF
        ST      @-1(P2)
        ST      @-1(P2)
LEN1:   ILD     1(P2)
        JNZ     LEN2
        ILD     (P2)
LEN2:   LD      @1(P1)
        XRI     0x22
        JNZ     LEN1
LEN3:   LDI     0x80
        XPAL    P2
        ST      -3(P2)
LEN4:   LD      @1(P1)
        XRI     0x20
        JZ      LEN4
        XRI     0x09
        JZ      71(P3)
SNTERR: LDI     0x63
        JMP     -98(P3)
CKDLLR: JZ      CK1
        LDI     0x73
        JMP     -98(P3)
CK1:    LD      @1(P1)
        XRI     0x24
        JNZ     SNTERR
CK2:    LD      @1(P1)
        XRI     0x20
        JZ      CK2
        XRI     0x09
        JZ      -42(P3)
        JMP     SNTERR
L_EF4C: LD      -17(P2)

        CALL    P3,PUTASC
        JMP     71(P3)
FREE:   XPAL    P2
        SCL
        LDI     0x00
        CAD     1(P2)
        ST      1(P2)
        LDI     0x00
        CAD     (P2)
        ANI     0x0F
        ST      (P2)
        LDI     0x80
        XPAL    P2
        JMP     71(P3)
HEX:    DLD     -3(P2)
        DLD     -3(P2)
        XPAL    P2
        LDI     0x00
        ST      1(P2)
        ST      (P2)
        ST      -1(P2)
HEX1:   XAE
        LD      (P1)
        SCL
        CAI     0x3A
        JP      L_LETR
        ADI     0x0A
        JP      L_ENTR
        JMP     L_END
L_LETR: CAI     0x0D
        JP      L_END
        ADI     0x06
        JP      OK
L_END:  LDI     0x80
        XPAL    P2
        LDE
        JNZ     HEX2
        LDI     0x43
        JMP     -98(P3)
HEX2:   SCL
        CAI     0x05
        JP      87(P3)
        JMP     71(P3)
OK:     ADI     0x09
L_ENTR: XAE
        LDI     0x04
        ST      -2(P2)
L_SHIF: CCL
        LD      1(P2)
        ADD     1(P2)
        ST      1(P2)
        LD      (P2)
        ADD     (P2)
        ST      (P2)
        DLD     -2(P2)
        JNZ     L_SHIF
        LD      1(P2)
        ORE
        ST      1(P2)
        LD      @1(P1)
        ILD     -1(P2)
        JMP     HEX1
TOP:    LDI     0x02
        XPAL    P3
        LD      -10(P2)
        RR
        RR
        RR
        RR
        XPAH    P3
TOP1:   LD      (P3)
        XRI     0xFF
        JNZ     TOP2
        LD      1(P3)
        XRI     0xFF
        JZ      TOP3
TOP2:   LD      2(P3)
        XAE
        LD      @EREG(P3)
        JMP     TOP1
TOP3:   LD      @2(P3)
        LD      -100(P2)
        XPAH    P3
        XAE
        LD      -3(P2)
        XPAL    P2
        XPAL    P3
        ST      @-1(P2)
        LDE
        ST      @-1(P2)
        LDI     0x80
        XPAL    P2
        ST      -3(P2)
        RTRN    P3
NUPAGE: LD      -17(P2)
        ANI     0x07
        JNZ     NUPGE2
NUPGE1: LDI     0x01
NUPGE2: ST      -10(P2)
        JMP     -42(P3)
CLEAR:  JMP     -124(P3)
ABSWP:  LD      5(P1)
        XOR     1(P1)
        ST      -22(P2)

        CALL    P3,ABSWP1
ABSWP1: LD      1(P1)
        JP      SWAP

        CALL    P3,FNEG
SWAP:   LDI     0x04
        ST      -23(P2)
SWAP1:  LD      @1(P1)
        ST      -5(P1)
        LD      3(P1)
        ST      -1(P1)
        LD      -5(P1)
        ST      3(P1)
        DLD     -23(P2)
        JNZ     SWAP1
        LD      @-4(P1)
        RTRN    P3
MD:     LDI     0x00
        ST      3(P1)
        ST      2(P1)
        ST      1(P1)
        ST      (P1)
        CSA
        JP      MD1
        LDI     0xA0
        XAE
        JP      MD2
        LDI     0x52
        JMP     -98(P3)
MD1:    LDI     0xA0
        XAE
        JP      MD3
MD2:    XRI     0x80
        ST      (P1)
        LDI     0x18
        ST      -8(P1)
        JMP     38(P3)
MD3:    ILD     -29(P2)
        ILD     -29(P2)
        JMP     38(P3)
FDIV:
        CALL    P3,ABSWP
FDIV0:  CCL
        LD      4(P1)
        CAD     @4(P1)

        CALL    P3,MD
FDIV1:  SCL
        LD      -5(P1)
        CAD     -1(P1)
        ST      -5(P1)
        LD      -6(P1)
        CAD     -2(P1)
        ST      -6(P1)
        LD      -7(P1)
        CAD     -3(P1)
        ST      -7(P1)
        JP      FDIV2
        CCL
        LD      -5(P1)
        ADD     -1(P1)
        ST      -5(P1)
        LD      -6(P1)
        ADD     -2(P1)
        ST      -6(P1)
        LD      -7(P1)
        ADD     -3(P1)
        ST      -7(P1)
        JMP     FDIV3
FDIV2:  ILD     3(P1)
FDIV3:  DLD     -8(P1)
        JZ      MDEND
        CCL
        LDE
        ADE
        XAE
        LD      -5(P1)
        ADD     -5(P1)
        ST      -5(P1)
        LD      -6(P1)
        ADD     -6(P1)
        ST      -6(P1)
        LD      -7(P1)
        JP      FDIV4
        LDI     0x38
        JMP     -98(P3)
FDIV4:  ADD     -7(P1)
        ST      -7(P1)
        LD      3(P1)
        ADD     3(P1)
        ST      3(P1)
        LD      2(P1)
        ADD     2(P1)
        ST      2(P1)
        LD      1(P1)
        ADD     1(P1)
        ST      1(P1)
        JMP     FDIV1
FMUL:
        CALL    P3,ABSWP
        CCL
        LD      4(P1)
        ADD     @4(P1)

        CALL    P3,MD
FMUL1:  CCL
        LD      -7(P1)
        RRL
        ST      -7(P1)
        LD      -6(P1)
        RRL
        ST      -6(P1)
        LD      -5(P1)
        RRL
        ST      -5(P1)
        CSA
        JP      FMUL2
        NOP
        LD      3(P1)
        ADD     -1(P1)
        ST      3(P1)
        LD      2(P1)
        ADD     -2(P1)
        ST      2(P1)
        LD      1(P1)
        ADD     -3(P1)
        ST      1(P1)
FMUL2:  DLD     -8(P1)
        XRI     0x01
        JZ      MDEND
        CCL
        LD      1(P1)
        RRL
        ST      1(P1)
        LD      2(P1)
        RRL
        ST      2(P1)
        LD      3(P1)
        RRL
        ST      3(P1)
        JMP     FMUL1
MDEND:  CCL
        LD      1(P1)
        JP      MDSGN

        CALL    P3,ALGN2
MDSGN:  LD      -22(P2)
        JP      38(P3)
        JMP     FNEG
FSUB:
        CALL    P3,FNEG
FADD:
        CALL    P3,ALGEXP
        CCL
        LD      7(P1)
        ADD     3(P1)
        ST      7(P1)
        LD      6(P1)
        ADD     2(P1)
        ST      6(P1)
        LD      5(P1)
        ADD     1(P1)
        ST      5(P1)
        LD      @4(P1)
        JMP     ALGN1
AND:    LD      7(P1)
        AND     3(P1)
        ST      7(P1)
        LD      6(P1)
        AND     2(P1)
        ST      6(P1)
        LD      5(P1)
        AND     1(P1)
        ST      5(P1)
        LD      @4(P1)
        JMP     NORM
OR:     LD      7(P1)
        OR      3(P1)
        ST      7(P1)
        LD      6(P1)
        OR      2(P1)
        ST      6(P1)
        LD      5(P1)
        OR      1(P1)
        ST      5(P1)
        LD      @4(P1)
        JMP     NORM
NOT:    XRE
        ST      @-1(P1)
        ST      @-1(P1)
        LDI     0x80
        ST      @-1(P1)
        LDI     0x7F
        ST      @-1(P1)

        CALL    P3,ALGEXP
EXOR:   LD      7(P1)
        XOR     3(P1)
        ST      7(P1)
        LD      6(P1)
        XOR     2(P1)
        ST      6(P1)
        LD      5(P1)
        XOR     1(P1)
        ST      5(P1)
        LD      @4(P1)
        JMP     NORM
FABS:   LD      1(P1)
        JP      38(P3)
FNEG:   SCL
        LDI     0x00
        CAD     3(P1)
        ST      3(P1)
        LDI     0x00
        CAD     2(P1)
        ST      2(P1)
        LDI     0x00
        CAD     1(P1)
        ST      1(P1)
ALGN1:  CSA
        ANI     0x40
        JNZ     ALGN2
NORM:   LD      1(P1)
        ADD     1(P1)
        XOR     1(P1)
        JP      NORM1
        JMP     38(P3)
NORM1:  LD      (P1)
        JZ      38(P3)
        DLD     (P1)
        CCL
        LD      3(P1)
        ADD     3(P1)
        ST      3(P1)
        LD      2(P1)
        ADD     2(P1)
        ST      2(P1)
        LD      1(P1)
        ADD     1(P1)
        ST      1(P1)
        JMP     NORM
ALGN2:  ILD     (P1)
        JNZ     ALGN3
        LDI     0x52
        JMP     -98(P3)
ALGN3:  LD      1(P1)
        RRL
        ST      1(P1)
        LD      2(P1)
        RRL
        ST      2(P1)
        LD      3(P1)
        RRL
        ST      3(P1)
        JMP     38(P3)
INT:    XRE
INT1:   XAE
INT2:   SCL
        LD      (P1)
        JP      INT3
        CAI     0x96
        JZ      INT4
        JP      38(P3)
INT3:   LD      1(P1)
        ADD     1(P1)
        LD      1(P1)
        RRL
        ST      1(P1)
        LD      2(P1)
        RRL
        ST      2(P1)
        LD      3(P1)
        RRL
        ST      3(P1)
        ILD     (P1)
        CSA
        JP      INT2
        JMP     INT1
INT4:   XAE
        AND     1(P1)
        JP      NORM
        LDE
        ADD     3(P1)
        ST      3(P1)
        LDE
        ADD     2(P1)
        ST      2(P1)
        LDE
        ADD     1(P1)
        ST      1(P1)
        JMP     ALGN1         ; to $F19B
VERT:   JP      VERT2
VERT1:  LDI     0x0B

        CALL    P3,PUTASC
        ILD     -17(P2)
        JNZ     VERT1
        JMP     71(P3)
VERT2:  OR      -17(P2)
        JZ      71(P3)
VERT3:  LDI     0x0A

        CALL    P3,PUTASC
        DLD     -17(P2)
        JNZ     VERT3
        JMP     71(P3)
ALGEXP: SCL
        LD      (P1)
        CAD     4(P1)
        JZ      38(P3)
        CSA
        JP      ALG2
        LDI     0x04
        ST      -23(P2)
ALG1:   LD      @1(P1)
        XAE
        LD      3(P1)
        ST      -1(P1)
        LDE
        ST      3(P1)
        DLD     -23(P2)
        JNZ     ALG1
        LD      @-4(P1)
ALG2:   ILD     (P1)
        LD      1(P1)
        ADD     1(P1)
        LD      1(P1)
        RRL
        ST      1(P1)
        LD      2(P1)
        RRL
        ST      2(P1)
        LD      3(P1)
        RRL
        ST      3(P1)
        JMP     ALGEXP
STACK:  LD      -3(P2)
        XPAL    P1
        ST      -13(P2)
        LD      -122(P3)
        XPAH    P1
        ST      -14(P2)
        JMP     -42(P3)
FNUM:   LD      -3(P2)
        XPAL    P1
        ST      -13(P2)
        LD      -122(P3)
        XPAH    P1
        ST      -14(P2)
        LDI     0x00
        ST      -25(P2)
        LDI     0x20
        ST      -5(P1)
        LD      1(P1)
        JZ      L_F305
        JP      FMUL10
        LDI     0x2D
        ST      -5(P1)
        SCL
        LDI     0x00
        CAD     3(P1)
        ST      3(P1)
        LDI     0x00
        CAD     2(P1)
        ST      2(P1)
        LDI     0x00
        CAD     1(P1)
        ST      1(P1)
FMUL10: LD      (P1)
        XRI     0x80
        JP      L_F305
        CCL
        ADI     0x09
        JP      L_F305
        LDI     0x80
        ST      -25(P2)
MUL10:  ILD     -25(P2)
        CCL
        LD      1(P1)
        RRL
        ST      -3(P1)
        LD      2(P1)
        RRL
        ST      -2(P1)
        LD      3(P1)
        RRL
        ST      -1(P1)
        CCL
        LD      -3(P1)
        RRL
        ST      -3(P1)
        LD      -2(P1)
        RRL
        ST      -2(P1)
        LD      -1(P1)
        RRL
        ST      -1(P1)
        LD      3(P1)
        ADD     -1(P1)
        ST      3(P1)
        LD      2(P1)
        ADD     -2(P1)
        ST      2(P1)
        LD      1(P1)
        ADD     -3(P1)
        ST      1(P1)
        JP      L_F2FC
        CCL
        RRL
        ST      1(P1)
        LD      2(P1)
        RRL
        ST      2(P1)
        LD      3(P1)
        RRL
        ST      3(P1)
        ILD     (P1)
L_F2FC: CCL
        LD      (P1)
        ADI     0x03
        ST      (P1)
        JP      MUL10
L_F305: LDI     0x01
        ST      -4(P1)
        LD      1(P1)
        JZ      L_F384
L_F30D: LDI     0xA0
        XAE
        LD      3(P1)
        ST      -1(P1)
        LD      2(P1)
        ST      -2(P1)
        LD      1(P1)
        ST      -3(P1)
        LDI     0x00
        ST      3(P1)
        ST      2(P1)
        ST      1(P1)
        LDI     0x18
        ST      -6(P1)
L_F328: SCL
        LD      -3(P1)
        CAI     0x50
        JP      L_F331
        JMP     L_F335
L_F331: ST      -3(P1)
        ILD     3(P1)
L_F335: DLD     -6(P1)
        JZ      L_F363
        CCL
        LDE
        ADE
        XAE
        LD      -1(P1)
        ADD     -1(P1)
        ST      -1(P1)
        LD      -2(P1)
        ADD     -2(P1)
        ST      -2(P1)
        LD      -3(P1)
        ADD     -3(P1)
        ST      -3(P1)
        LD      3(P1)
        ADD     3(P1)
        ST      3(P1)
        LD      2(P1)
        ADD     2(P1)
        ST      2(P1)
        LD      1(P1)
        ADD     1(P1)
        ST      1(P1)
        JMP     L_F328
L_F363: LD      1(P1)
        JP      L_F377
        CCL
        RRL
        ST      1(P1)
        LD      2(P1)
        RRL
        ST      2(P1)
        LD      3(P1)
        RRL
        ST      3(P1)
        ILD     (P1)
L_F377: SCL
        LD      (P1)
        CAI     0x04
        ST      (P1)
        JP      L_F384
        ILD     -4(P1)
        JMP     L_F30D
L_F384: LD      -4(P1)
        ST      -21(P2)
        LD      -25(P2)
        JNZ     L_F39B
        SCL
        LDI     0x06
        CAD     -4(P1)
        JP      L_F39B
        DLD     -4(P1)
        ST      -25(P2)
        LDI     0x01
        ST      -4(P1)
L_F39B: CCL
        LD      1(P1)
        RRL
        ST      1(P1)
        LD      2(P1)
        RRL
        ST      2(P1)
        LD      3(P1)
        RRL
        ST      3(P1)
        LDE
        RRL
        XAE
        ILD     (P1)
        XRI     0x86
        JNZ     L_F39B
        LDE
        ADI     0x02
        ST      1(P1)
        LDI     0x05
        ST      (P1)
        LD      @-5(P1)
        CSA
        JP      L_F3E0
        ILD     8(P1)
        JNZ     L_F3E0
        ILD     7(P1)
        JNZ     L_F3E0
        LDI     0x31
        ST      @-1(P1)
        LD      -25(P2)
        JNZ     L_F3DA
        LD      2(P1)
        XRI     0x06
        JNZ     L_F3E0
        ADI     0x05
L_F3DA: ADI     0x00
        ST      -25(P2)
        JMP     L_F45E
L_F3E0: LD      -3(P2)
        XPAL    P2
L_F3E3: LDI     0x06
        XAE
        CCL
        LD      1(P2)
        ADD     1(P2)
        ST      -1(P2)
        LD      3(P2)
        ADD     3(P2)
        ST      -2(P2)
        LD      2(P2)
        ADD     2(P2)
        ST      -3(P2)
        LDE
        ADE
        XAE
        LD      -1(P2)
        ADD     -1(P2)
        ST      -1(P2)
        LD      -2(P2)
        ADD     -2(P2)
        ST      -2(P2)
        LD      -3(P2)
        ADD     -3(P2)
        ST      -3(P2)
        LDE
        ADE
        XAE
        LD      1(P2)
        ADD     -1(P2)
        ST      1(P2)
        LD      3(P2)
        ADD     -2(P2)
        ST      3(P2)
        LD      2(P2)
        ADD     -3(P2)
        ST      2(P2)
        LDE
        ADI     0x00
        XAE
        LD      1(P2)
        ADD     1(P2)
        ST      1(P2)
        LD      3(P2)
        ADD     3(P2)
        ST      3(P2)
        LD      2(P2)
        ADD     2(P2)
        ST      2(P2)
        LDE
        ADE
        ST      @-1(P1)
        DLD     (P2)
        DLD     -4(P2)
        JNZ     L_F447
        LDI     0x2E
        ST      @-1(P1)
L_F447: LD      (P2)
        JP      L_F3E3
L_F44B: LD      @1(P1)
        XRI     0x30
        JZ      L_F44B
        ANI     0xF0
        JNZ     L_F457
        LD      @-1(P1)
L_F457: LDI     0x80
        XPAL    P2
        LD      -25(P2)
        JZ      L_F486
L_F45E: XAE
        LDI     0x45
        ST      @-1(P1)
        LDE
        JP      L_F46A
        LDI     0x2D
        ST      @-1(P1)
L_F46A: SCL
        LDE
        ANI     0x7F
        CAI     0x0A
        JP      L_F474
        JMP     L_F482
L_F474: XAE
        LDI     0x30
        ST      @-1(P1)
L_F479: ILD     (P1)
        LDE
        CAI     0x0A
        XAE
        LDE
        JP      L_F479
L_F482: ADI     0x3A
        ST      @-1(P1)
L_F486: LDI     0xA0
        ST      @-1(P1)
        JMP     -42(P3)
        NOP
        LDI     0x60
        XPAL    P1
STBACK: LD      -13(P2)
        XPAL    P1
        ST      -3(P2)
        LD      -14(P2)
        XPAH    P1
        JMP     -42(P3)
LG2:    LDI     0x4D
        ST      @-1(P1)
        ST      @-2(P1)
        LDI     0x10
        ST      1(P1)
        LDI     0x7E
        ST      @-1(P1)
        JMP     -42(P3)
LN2:    LDI     0x0C
        ST      @-1(P1)
        LDI     0xB9
        ST      @-1(P1)
        LDI     0x58
        ST      @-1(P1)
        LDI     0x7F
        ST      @-1(P1)
        JMP     -42(P3)
LOG2:   LD      1(P1)
        JP      LOG21
LGERR:  LDI     0x23
        JMP     -98(P3)
LOG21:  OR      2(P1)
        OR      3(P1)
        JZ      LGERR
        LDI     0x00
        ST      -01(P1)
        LD      (P1)
        XRI     0x80
        ST      -3(P1)
        LDI     0x80
        ST      (P1)
        ST      -2(P1)
        LDI     0x86
        ST      @-4(P1)

        CALL    P3,NORM

        CALL    P3,SWAP
        LD      3(P1)
        ST      -1(P1)
        LD      2(P1)
        ST      -2(P1)
        LD      1(P1)
        ST      -3(P1)
        LD      (P1)
        ST      @-4(P1)
        LDI     0x7A
        ST      @-1(P1)
        LDI     0x82
        ST      @-1(P1)
        LDI     0x5A
        ST      @-1(P1)
        LDI     0x80
        ST      @-1(P1)

        CALL    P3,FSUB

        CALL    P3,SWAP
        LDI     0x7A
        ST      @-1(P1)
        LDI     0x82
        ST      @-1(P1)
        LDI     0x5A
        ST      @-1(P1)
        LDI     0x80
        ST      @-1(P1)

        CALL    P3,FADD

        CALL    P3,FDIV
        LDI     0x49
        ST      @-1(P1)
        LDI     0x86
        ST      @-1(P1)
        LDI     0xAB
        ST      @-1(P1)
        LDI     0x81
        ST      @-1(P1)
        LD      7(P1)
        ST      -1(P1)
        ST      -5(P1)
        LD      6(P1)
        ST      -2(P1)
        ST      -6(P1)
        LD      5(P1)
        ST      -3(P1)
        ST      -7(P1)
        LD      4(P1)
        ST      -4(P1)
        ST      @-8(P1)

        CALL    P3,FMUL
        LDI     0x66
        ST      @-1(P1)
        LDI     0x08
        ST      @-1(P1)
        LDI     0x6A
        ST      @-1(P1)
        LDI     0x80
        ST      @-1(P1)

        CALL    P3,FSUB

        CALL    P3,FDIV
        LDI     0x40
        ST      @-1(P1)
        LDI     0xB0
        ST      @-1(P1)
        LDI     0x52
        ST      @-1(P1)
        LDI     0x80
        ST      @-1(P1)

        CALL    P3,FADD

        CALL    P3,FMUL

        CALL    P3,FADD
        JMP     -42(P3)
EXP2:   LDI     0x00
        ST      -1(P1)
        ST      -2(P1)
        LD      1(P1)
        JNZ     EXP21
        LDI     0x80
        ST      (P1)
        SR
        ST      1(P1)
        JMP     -42(P3)
EXP21:  ST      -03(P1)
        LD      (P1)
        ST      @-4(P1)
EXP22:  SCL
        LDI     0x86
        CAD     (P1)
        JZ      EXP25
        JP      EXP24
        LD      1(P1)
        JP      EXP23
        LD      @+4(P1)
        LDI     0x00
        ST      3(P1)
        ST      2(P1)
        ST      1(P1)
        ST      (P1)
        JMP     -42(P3)
EXP23:  LDI     0x52
        JMP     -98(P3)
EXP24:  LD      1(P1)
        ADD     1(P1)
        LD      1(P1)
        SRL
        ST      1(P1)
        ILD     (P1)
        JMP     EXP22
EXP25:  LD      1(P1)
        ST      -24(P2)

        CALL    P3,NORM

        CALL    P3,FSUB
        LDI     0x70
        ST      @-1(P1)
        LDI     0xFA
        ST      @-1(P1)
        LDI     0x46
        ST      @-1(P1)
        LDI     0x7B
        ST      @-1(P1)
        LD      7(P1)
        ST      -1(P1)
        ST      -5(P1)
        LD      6(P1)
        ST      -2(P1)
        ST      -6(P1)
        LD      5(P1)
        ST      -3(P1)
        ST      -7(P1)
        LD      4(P1)
        ST      -4(P1)
        ST      @-08(P1)

        CALL    P3,FMUL

        CALL    P3,FMUL
        LDI     0xE1
        ST      @-5(P1)
        LDI     0x6A
        ST      @-1(P1)
        LDI     0x57
        ST      @-1(P1)
        LDI     0x86
        ST      @-1(P1)

        CALL    P3,FADD
        LDI     0x1D
        ST      @-1(P1)
        LDI     0x3F
        ST      @-1(P1)
        LDI     0x4D
        ST      @-1(P1)
        LDI     0x89
        ST      @-1(P1)
        LD      5(P1)
        XOR     1(P1)
        ST      -22(P2)

        CALL    P3,SWAP

        CALL    P3,FDIV0

        CALL    P3,FSUB
        LD      7(P1)
        ST      -1(P1)
        LD      6(P1)
        ST      -2(P1)
        LD      5(P1)
        ST      -3(P1)
        LD      4(P1)
        ST      @-4(P1)

        CALL    P3,FSUB
        LDI     0x03
        ST      @-1(P1)
        LDI     0xA3
        ST      @-1(P1)
        LDI     0x4F
        ST      @-1(P1)
        LDI     0x83
        ST      @-1(P1)

        CALL    P3,FADD

        CALL    P3,FDIV
        LDI     0x00
        ST      @-1(P1)
        ST      @-1(P1)
        LDI     0x40
        ST      @-1(P1)
        LDI     0x7F
        ST      @-1(P1)

        CALL    P3,FADD
        SCL
        LD      -24(P2)
        ADD     (P1)
        ST      (P1)
        JMP     -42(P3)
FMOD:
        CALL    P3,ABSWP
        CCL
        LD      4(P1)
        CAD     @4(P1)

        CALL    P3,MD
FMOD1:  SCL
        LD      -5(P1)
        CAD     -1(P1)
        ST      -5(P1)
        LD      -6(P1)
        CAD     -2(P1)
        ST      -6(P1)
        LD      -7(P1)
        CAD     -3(P1)
        ST      -7(P1)
        JP      FMOD2
        LD      -5(P1)
        ADD     -1(P1)
        ST      -5(P1)
        LD      -6(P1)
        ADD     -2(P1)
        ST      -6(P1)
        LD      -7(P1)
        ADD     -3(P1)
        ST      -7(P1)
        JMP     FMOD3
FMOD2:  ILD     3(P1)
FMOD3:  DLD     -8(P1)
        CAI     0x01
        JP      FMOD5
        LD      (P1)
        JZ      FMOD10
        JP      FMOD7
FMOD4:  DLD     (P1)
        LD      1(P1)
        ANI     0x3F
        ST      1(P1)
FMOD5:  CCL
        LD      -5(P1)
        ADD     -5(P1)
        ST      -5(P1)
        LD      -6(P1)
        ADD     -6(P1)
        ST      -6(P1)
        LD      -7(P1)
        JP      FMOD6
        LDI     0x38
        JMP     -98(P3)
FMOD6:  ADD     -7(P1)
        ST      -7(P1)
        LD      3(P1)
        ADD     3(P1)
        ST      3(P1)
        LD      2(P1)
        ADD     2(P1)
        ST      2(P1)
        LD      1(P1)
        ADD     1(P1)
        ST      1(P1)
        JMP     FMOD1
FMOD7:  XRI     0x7F
        JNZ     FMOD8
        LD      1(P1)
        JP      FMOD9
        ANI     0x7F
        ST      1(P1)
FMOD8:  LD      1(P1)
FMOD9:  ANI     0xC0
        JZ      FMOD4
        JP      FMOD10

        CALL    P3,ALGN2
FMOD10: LD      -22(P2)
        JP      -42(P3)

        CALL    P3,FNEG
        JMP     -42(P3)
PSHSWP: LD      @-4(P1)
        LDI     0x04
        ST      -23(P2)
SWP1:   LD      @1(P1)
        XAE
        LD      3(P1)
        ST      -1(P1)
        LDE
        ST      3(P1)
        DLD     -23(P2)
        JNZ     SWP1
        LD      @-4(P1)
        JMP     -42(P3)
FD10:   LD      1(P1)
        JZ      -42(P3)
FD11:   LDI     0xA0
        XAE
        LD      3(P1)
        ST      -1(P1)
        LD      2(P1)
        ST      -2(P1)
        LD      1(P1)
        ST      -3(P1)
        LDI     0x00
        ST      3(P1)
        ST      2(P1)
        ST      1(P1)
        LDI     0x18
        ST      -4(P1)
FD12:   SCL
        LD      -3(P1)
        CAI     0x50
        JP      FD13
        JMP     FD14
FD13:   ST      -3(P1)
        ILD     3(P1)
FD14:   DLD     -4(P1)
        JZ      FD15
        CCL
        LDE
        ADE
        XAE
        LD      -1(P1)
        ADD     -1(P1)
        ST      -1(P1)
        LD      -2(P1)
        ADD     -2(P1)
        ST      -2(P1)
        LD      -3(P1)
        ADD     -3(P1)
        ST      -3(P1)
        LD      3(P1)
        ADD     3(P1)
        ST      3(P1)
        LD      2(P1)
        ADD     2(P1)
        ST      2(P1)
        LD      1(P1)
        ADD     1(P1)
        ST      1(P1)
        JMP     FD12
FD15:   LD      1(P1)
        JP      FD16
        CCL
        RRL
        ST      1(P1)
        LD      2(P1)
        RRL
        ST      2(P1)
        LD      3(P1)
        RRL
        ST      3(P1)
        ILD     (P1)
FD16:   SCL
        LD      (P1)
        CAI     0x04
        ST      (P1)
        XRI     0x80
        JP      FD11
        DLD     -24(P2)
        JP      FD11
        JMP     -42(P3)
FDIV11: LD      -3(P2)
        XPAL    P2
        LD      @2(P2)
        JNZ     87(P3)  
        LD      1(P2)
        JZ      FDEND
FDIV12: SCL
        LD      (P2)
        CAI     0x04
        XAE
        LD      3(P2)
        ST      -2(P2)
        LD      2(P2)
        ST      -3(P2)
        LD      1(P2)
        ST      -4(P2)
        LDI     0x00
        ST      3(P2)
        ST      2(P2)
        ST      1(P2)
        ST      (P2)
        CSA
        JP      FDEND
        LDI     0xA0
        XAE
        ST      (P2)
        LDI     0x18
        ST      -5(P2)
FDIV13: SCL
        LD      -4(P2)
        CAI     0x50
        JP      L_F7D8
        JMP     FDIV15
L_F7D8: ST      -4(P2)
        ILD     3(P2)
FDIV15: DLD     -5(P2)
        JZ      FDIV16
        CCL
        LDE
        ADE
        XAE
        LD      -2(P2)
        ADD     -2(P2)
        ST      -2(P2)
        LD      -3(P2)
        ADD     -3(P2)
        ST      -3(P2)
        LD      -4(P2)
        ADD     -4(P2)
        ST      -4(P2)
        LD      3(P2)
        ADD     3(P2)
        ST      3(P2)
        LD      2(P2)
        ADD     2(P2)
        ST      2(P2)
        LD      1(P2)
        ADD     1(P2)
        ST      1(P2)
        JMP     FDIV13
FDIV16: LD      1(P2)
        JP      FDIV17
        CCL
        RRL
        ST      1(P2)
        LD      2(P2)
        RRL
        ST      2(P2)
        LD      3(P2)
        RRL
        ST      3(P2)
        ILD     (P2)
FDIV17: DLD     -1(P2)
        JNZ     FDIV12
FDEND:  LDI     0x80
        XPAL    P2
        ST      -3(P2)
        JMP     71(P3)
FMUL11: LD      -3(P2)
        XPAL    P2
        LD      @2(P2)
        JNZ     87(P3)
        LD      1(P2)
        JZ      FMEND
FMUL12: CCL
        LD      1(P2)
        RRL
        ST      -4(P2)
        LD      2(P2)
        RRL
        ST      -3(P2)
        LD      3(P2)
        RRL
        ST      -2(P2)
        CCL
        LD      -4(P2)
        RRL
        ST      -4(P2)
        LD      -3(P2)
        RRL
        ST      -3(P2)
        LD      -2(P2)
        RRL
        ST      -2(P2)
        LD      3(P2)
        ADD     -2(P2)
        ST      3(P2)
        LD      2(P2)
        ADD     -3(P2)
        ST      2(P2)
        LD      1(P2)
        ADD     -4(P2)
        ST      1(P2)
        JP      FMUL13
        CCL
        RRL
        ST      1(P2)
        LD      2(P2)
        RRL
        ST      2(P2)
        LD      3(P2)
        RRL
        ST      3(P2)
        ILD     (P2)
        JZ      FMUL14
FMUL13: CCL
        LD      (P2)
        ADI     0x03
        ST      (P2)
        CSA
        JP      FMUL15
FMUL14: LDI     0x52
        JMP     33(P3)
FMUL15: DLD     -1(P2)
        JNZ     FMUL12
FMEND:  LDI     0x80
        XPAL    P2
        ST      -3(P2)
        JMP     71(P3)
ATN:    LD      1(P1)
        JZ      -42(P3)
        ST      -24(P2)
        JP      ATN1

        CALL    P3,FNEG
ATN1:   LD      (P1)
        ST      -21(P2)
        JP      ATN2
        ST      @-4(P1)
        LD      5(P1)
        ST      1(P1)
        LD      6(P1)
        ST      2(P1)
        LD      7(P1)
        ST      3(P1)
        LDI     0x80
        ST      4(P1)
        SR
        ST      5(P1)
        LDI     0x00
        ST      6(P1)
        ST      7(P1)

        CALL    P3,FDIV
ATN2:   LDI     0x81
        ST      -1(P1)
        LDI     0xD5
        ST      -2(P1)
        LDI     0x6B
        ST      -3(P1)
        LDI     0x7B
        ST      -4(P1)
        LDI     0xDD
        ST      -5(P1)
        LDI     0xFA
        ST      -6(P1)
        LDI     0x9F
        ST      -7(P1)
        LDI     0x79
        ST      -8(P1)
        LD      3(P1)
        ST      -9(P1)
        ST      -13(P1)
        LD      2(P1)
        ST      -10(P1)
        ST      -14(P1)
        LD      1(P1)
        ST      -11(P1)
        ST      -15(P1)
        LD      (P1)
        ST      -12(P1)
        ST      @-16(P1)

        CALL    P3,FMUL

        CALL    P3,FMUL

        CALL    P3,FADD
        LDI     0xD2
        ST      -1(P1)
        LDI     0xC5
        ST      -2(P1)
        LDI     0x88
        ST      -3(P1)
        LDI     0x7C
        ST      @-4(P1)

        CALL    P3,SWPMUL
        LDI     0x21
        ST      -1(P1)
        LDI     0x18
        ST      -2(P1)
        LDI     0x63
        ST      -3(P1)
        LDI     0x7D
        ST      @-4(P1)

        CALL    P3,SWPMUL
        LDI     0x30
        ST      -1(P1)
        LDI     0xD9
        ST      -2(P1)
        LDI     0xAA
        ST      -3(P1)
        LDI     0x7E
        ST      @-4(P1)

        CALL    P3,SWPMUL
        LDI     0x41
        ST      -1(P1)
        LDI     0xFF
        ST      -2(P1)
        LDI     0x7F
        ST      -3(P1)
        ST      @-4(P1)

        CALL    P3,SWPMUL

        CALL    P3,FMUL
        LD      -21(P2)
        JP      ATN3

        CALL    P3,PI2

        CALL    P3,SWAP

        CALL    P3,FSUB
ATN3:   LD      -24(P2)
        JP      -42(P3)

        CALL    P3,FNEG
        JMP     -42(P3)
SWPMUL: LDI     0x04
        ST      -23(P2)
SWPM:   LD      @1(P1)
        ST      -9(P1)
        LD      3(P1)
        ST      -1(P1)
        LD      -9(P1)
        ST      3(P1)
        DLD     -23(P2)
        JNZ     SWPM
        LD      @-8(P1)

        CALL    P3,FMUL

        CALL    P3,FADD
        RTRN    P3
PI2:    LDI     0xED
        ST      @-1(P1)
        LDI     0x87
        ST      @-1(P1)
        LDI     0x64
        ST      @-1(P1)
        LDI     0x80
        ST      @-1(P1)
        RTRN    P3
TAN:    LD      3(P1)
        ST      -1(P1)
        LD      2(P1)
        ST      -2(P1)
        LD      1(P1)
        ST      -3(P1)
        LD      (P1)
        ST      @-4(P1)
SIN:    LD      1(P1)
        JZ      -42(P3)
        ST      -24(P2)
        JP      SIN1

        CALL    P3,FNEG
SIN1:   LDI     0xEC
        ST      -1(P1)
        LDI     0x87
        ST      -2(P1)
        LDI     0x64
        ST      -3(P1)
        LDI     0x80
        ST      @-4(P1)

        CALL    P3,FDIV
        LD      (P1)
        JP      SIN4
        LD      3(P1)
        ANI     0xFE
        ST      3(P1)
SIN2:   CCL
        LD      3(P1)
        ADD     3(P1)
        ST      3(P1)
        LD      2(P1)
        ADD     2(P1)
        ST      2(P1)
        LD      1(P1)
        ADD     1(P1)
        ST      1(P1)
        DLD     (P1)
        XRI     0x7F
        JNZ     SIN2
        CSA
        XOR     1(P1)

        CALL    P3,NORM
        JP      SIN4

        CALL    P3,FNEG
        NOP
        NOP
SIN4:   SCL
        LD      (P1)
        CAI     0x76
        JP      SIN5
        LD      @-4(P1)

        CALL    P3,FMUL
        JMP     SIN7
SIN5:   CAI     0x0A
        JZ      SIN7
        ADI     0x01
        JNZ     SIN6
        SRL
        XOR     1(P1)
        OR      2(P1)
        OR      3(P1)
        JZ      SIN7
SIN6:   LDI     0x37
        ST      -1(P1)
        LDI     0x65
        ST      -2(P1)
        LDI     0x51
        ST      -3(P1)
        LDI     0x7C
        ST      -4(P1)
        LDI     0x73
        ST      -5(P1)
        LDI     0x86
        ST      -6(P1)
        LDI     0xB8
        ST      -7(P1)
        LDI     0x78
        ST      -8(P1)
        LD      3(P1)
        ST      -9(P1)
        ST      -13(P1)
        LD      2(P1)
        ST      -10(P1)
        ST      -14(P1)
        LD      1(P1)
        ST      -11(P1)
        ST      -15(P1)
        LD      (P1)
        ST      -12(P1)
        ST      @-16(P1)

        CALL    P3,FMUL

        CALL    P3,FMUL

        CALL    P3,FADD
        LDI     0x76
        ST      -1(P1)
        LDI     0x52
        ST      -2(P1)
        LDI     0xAD
        ST      -3(P1)
        LDI     0x7F
        ST      @-4(P1)

        CALL    P3,SWPMUL
        LDI     0xE7
        ST      -1(P1)
        LDI     0x87
        ST      -2(P1)
        LDI     0x64
        ST      -3(P1)
        LDI     0x80
        ST      @-4(P1)

        CALL    P3,SWPMUL

        CALL    P3,FMUL
SIN7:   LD      -24(P2)
        JP      -42(P3)

        CALL    P3,FNEG
        JMP     -42(P3)
PI:     LD      -3(P2)
        XPAL    P2
        LDI     0xED
        ST      @-1(P2)
        LDI     0x87
        ST      @-1(P2)
        LDI     0x64
        ST      @-1(P2)
        LDI     0x81
        ST      @-1(P2)
        LDI     0x80
        XPAL    P2
        ST      -3(P2)
        JMP     71(P3)
RND:    LDI     0x08
        ST      -23(P2)
        LD      -28(P2)
        ST      @-1(P1)
        LD      -27(P2)
        ST      @-1(P1)
        LD      -26(P2)
        XAE
RND1:   CCL
        LD      -28(P2)
        ADD     1(P1)
        ST      -28(P2)
        CCL
        LD      -27(P2)
        ADD     (P1)
        ST      -27(P2)
        CCL
        LD      -26(P2)
        ADE
        XAE
        DLD     -23(P2)
        JNZ     RND1
        CCL
        LD      -28(P2)
        ADI     0x07
        RR
        ST      -28(P2)
        ST      1(P1)
        CCL
        LD      -27(P2)
        ADI     0x07
        RR
        ST      -27(P2)
        ST      (P1)
        CCL
        LDE
        ADI     0x07
        XAE
        ILD     -96(P2)
        JZ      RND2
        LDE
        ST      -26(P2)
RND2:   LD      -26(P2)
        XRI     0xFF
        ANI     0x7F
        ST      @-1(P1)
        LDI     0x7F
        ST      @-1(P1)
        JMP     -42(P3)
SGN:    LD      -3(P2)
        XPAL    P2
        XAE
        LD      1(P2)
        JZ      SGN3
        JP      SGN1
        LDI     0x7F
        ST      (P2)
        LDE
        ST      1(P2)
        JMP     SGN2
SGN1:   LDE
        ST      (P2)
        SR
        ST      1(P2)
SGN2:   LDI     0x00
        ST      2(P2)
        ST      3(P2)
SGN3:   LDE
        XPAL    P2
        JMP     71(P3)
SQRT:   LD      1(P1)
        JP      SQRT1
        LDI     0x23
        JMP     -98(P3)
SQRT1:  ST      -3(P1)
        OR      2(P1)
        OR      3(P1)
        JZ      -42(P3)
        LD      3(P1)
        ST      -1(P1)
        LD      2(P1)
        ST      -2(P1)
        LD      (P1)
        ST      @-4(P1)
        LDI     0x00
        ST      @-1(P1)
        ST      @-1(P1)
        LDI     0x40
        ST      @-1(P1)
        CCL
        LD      3(P1)
        JP      SQRT2
        SCL
SQRT2:  SRL
        XRI     0x40
        ST      @-1(P1)

        CALL    P3,FDIV
        LDI     0x04
        ST      -24(P2)
SQRT3:  LD      3(P1)
        ST      -1(P1)
        LD      2(P1)
        ST      -2(P1)
        LD      1(P1)
        ST      -3(P1)
        LD      (P1)
        ST      @-4(P1)
        LD      11(P1)
        ST      7(P1)
        LD      10(P1)
        ST      6(P1)
        LD      9(P1)
        ST      5(P1)
        LD      8(P1)
        ST      4(P1)

        CALL    P3,FDIV
        LD      @-4(P1)

        CALL    P3,FADD
        DLD     (P1)
        DLD     -24(P2)
        JNZ     SQRT3
        LD      3(P1)
        ST      7(P1)
        LD      2(P1)
        ST      6(P1)
        LD      1(P1)
        ST      5(P1)
        LD      @4(P1)
        ST      (P1)
        JMP     -42(P3)
VSTRNG: ILD     -3(P2)
        ILD     -03(P2)
        XPAL    P2
        LD      -1(P2)
        XPAL    P1
        XAE
        LD      -2(P2)
        XPAH    P1
        XPAL    P2
        LDI     0x80
        XPAL    P2
        ST      -16(P2)
        LDE
        ST      -15(P2)
        JMP     -42(P3)
FLOAT2: LD      -3(P2)
        XPAL    P2
        LD      (P2)
        ST      -1(P2)
        LD      1(P2)
        ST      (P2)
        LDI     0x00
        ST      1(P2)
        LDI     0x8E
        ST      @-2(P2)
FNORM:  LD      1(P2)
        ADD     1(P2)
        XOR     1(P2)
        JP      FNORM1
FLEND:  LDI     0x80
        XPAL    P2
        ST      -3(P2)
        JMP     71(P3)
FNORM1: LD      (P2)
        JZ      FLEND
        DLD     (P2)
        CCL
        LD      3(P2)
        ADD     3(P2)
        ST      3(P2)
        LD      2(P2)
        ADD     2(P2)
        ST      2(P2)
        LD      1(P2)
        ADD     1(P2)
        ST      1(P2)
        JMP     FNORM
LODVAR: JZ      LOD1
        LDI     0x73
        JMP     -98(P3)
LOD1:   LD      @1(P1)
        XRI     0x28
        JZ      LOD2
        LD      @-1(P1)
        LDI     0x63
        JMP     -98(P3)
LOD2:   LD      -3(P2)
        XPAL    P2
        LD      1(P2)
        XPAL    P1
        ST      -5(P2)
        LD      (P2)
        XPAH    P1
        ST      -06(P2)
        LD      4(P1)
        ST      @-01(P2)
        LD      3(P1)
        ST      @-01(P2)
        LD      2(P1)
        JNZ     LOD3
        LDI     0x5A
        JMP     33(P3)
LOD3:   ST      @-1(P2)
        LD      1(P1)
        ST      @-1(P2)
        LD      -1(P2)
        XPAL    P1
        LD      -2(P2)
        XPAH    P1
        LDI     0x80
        XPAL    P2
        ST      -3(P2)
        JMP     -42(P3)
STFLD:  LD      -3(P2)
        XPAL    P2
        LD      3(P2)
        XPAL    P3
        LD      2(P2)
        XPAH    P3
        XAE
        LD      1(P2)
        ST      3(P2)
        ST      4(P3)
        LD      @2(P2)
        ST      (P2)
        ST      3(P3)
        LDI     0x00
        ST      2(P3)
        ST      1(P3)
        LDI     0x80
        XPAL    P3
        LDE
        XPAH    P3
        LDI     0x80
        XPAL    P2
        ST      -3(P2)
        JMP     -42(P3)
DIMSN:  LD      -3(P2)
        XPAL    P2
        LD      (P2)
        ANI     0xFC
        JZ      DIMS1
        LDI     0x31
        JMP     33(P3)
DIMS1:  CCL
        LD      1(P2)
        ADD     1(P2)
        ST      -1(P2)
        LD      (P2)
        ADD     (P2)
        ST      -2(P2)
        LD      -1(P2)
        ADD     -1(P2)
        ST      -1(P2)
        LD      -2(P2)
        ADD     -2(P2)
        ST      -2(P2)
        LD      -1(P2)
        ADI     0x04
        ST      -1(P2)
        LD      -2(P2)
        ADI     0x00
        ST      -2(P2)
        LD      3(P2)
        ADI     0x02
        ST      3(P2)
        LD      2(P2)
        ADI     0x00
        XOR     2(P2)
        ANI     0xF0
        JZ      DIMS2
ARERR:  LDI     0x1F
        JMP     33(P3)
DIMS2:  LD      2(P2)
        ADI     0x00
        ST      2(P2)
        LD      3(P2)
        ADD     -1(P2)
        LD      2(P2)
        ADD     -2(P2)
        XOR     2(P2)
        ANI     0xF0
        JNZ     ARERR
        LD      3(P2)
        XPAL    P3
        LD      2(P2)
        XPAH    P3
        XAE
        LD      1(P2)
        ST      -2(P3)
        LD      @4(P2)
        ST      -1(P3)
DIMS3:  LDI     0x00
        ST      @1(P3)
        LD      -5(P2)
        JNZ     DIMS4
        DLD     -6(P2)
DIMS4:  DLD     -5(P2)
        OR      -6(P2)
        JNZ     DIMS3
        LDI     0x80
        XPAL    P3
        LDE
        XPAH    P3
        LDI     0x80
        XPAL    P2
        ST      -3(P2)
        JMP     -42(P3)
CKPT:   JZ      CKP1
        LDI     0x73
        JMP     -98(P3)
CKP1:   LD      @1(P1)
        XRI     0x28
        JZ      -42(P3)
        LD      @-1(P1)
        JMP     71(P3)
LADVAR: LD      -3(P2)
        XPAL    P2
        LD      1(P2)
        XPAL    P1
        ST      -1(P2)
        LD      (P2)
        XPAH    P1
        ST      -2(P2)
        LD      1(P1)
        OR      2(P1)
        JZ      LAD1
        LDI     0x31
        JMP     33(P3)
LAD1:   LD      4(P1)
        ST      1(P2)
        LD      3(P1)
        ST      (P2)
        LD      -1(P2)
        XPAL    P1
        LD      -2(P2)
        XPAH    P1
        LDI     0x80
        XPAL    P2
        JMP     -42(P3)
DMNSN:  LD      -3(P2)
        XPAL    P2
        LD      3(P2)
        XPAL    P1
        ST      3(P2)
        LD      2(P2)
        XPAH    P1
        ST      2(P2)
        SCL
        LD      @1(P1)
        CAD     1(P2)
        LD      (P1)
        CAD     (P2)
        JP      DMN1
        LDI     0x31
        JMP     33(P3)
DMN1:   CCL
        LD      1(P2)
        ADD     1(P2)
        ST      1(P2)
        LD      (P2)
        ADD     (P2)
        ST      (P2)
        LD      1(P2)
        ADD     1(P2)
        ST      1(P2)
        LD      (P2)
        ADD     (P2)
        ST      (P2)
        LD      3(P2)
        XPAL    P1
        ADD     1(P2)
        ST      3(P2)
        LD      2(P2)
        XPAH    P1
        ADD     @2(P2)
        ST      (P2)
        LDI     0x80
        XPAL    P2
        ST      -3(P2)
DMN2:   LD      @1(P1)
        XRI     0x20
        JZ      DMN2
        XRI     0x09
        JZ      71(P3)
        LD      @-1(P1)
        LDI     0x63
        JMP     -98(P3)
POPDLR: JZ      PD1
        LDI     0x73
        JMP     -98(P3)
PD1:    LD      (P1)
        XRI     0x24
        JZ      -42(P3)
        ILD     -3(P2)
        ILD     -3(P2)
        JMP     -42(P3)
PSTRNG: LD      -17(P2)
        XPAL    P1
        ST      -17(P2)
        LD      -18(P2)
        XPAH    P1
        ST      -18(P2)
PSTR1:  LD      @1(P1)
        XRI     0x0D
        JZ      PSTR2
        XRI     0x0D

        CALL    P3,PUTASC
        CSA
        ANI     0x20
        JNZ     PSTR1
PSTR2:  LD      -17(P2)
        XPAL    P1
        LD      -18(P2)
        XPAH    P1
        JMP     71(P3)
TAB:    LDI     0x1D

        CALL    P3,PUTASC
        LD      -17(P2)
        JZ      71(P3)
TAB1:   LDI     0x09

        CALL    P3,PUTASC
        DLD     -17(P2)
        JNZ     TAB1
        JMP     71(P3)
STATUS: CSA
        JMP     PSH
PGE:    LD      -10(P2)
PSH:    XAE
        LD      -3(P2)
        XPAL    P2
        XAE
        ST      @-1(P2)
        LDI     0x00
        ST      @-1(P2)
        LDE
        XPAL    P2
        ST      -3(P2)
        JMP     71(P3)
FNDDEF: LDI     0x02
        XPAL    P1
        ST      -15(P2)
        LD      -10(P2)
        RR
        RR
        RR
        RR
        XPAH    P1
        ST      -16(P2)
DEF1:   LD      (P1)
        XRI     0xFF
        JNZ     DEF2
        LDI     0x1C
        JMP     -98(P3)
DEF2:   LD      @1(P1)
        ST      -12(P2)
        LD      @2(P1)
        ST      -11(P2)
DEF3:   LD      @1(P1)
        XRI     0x20
        JZ      DEF3
        XRI     0xAA
        JZ      DEF5
DEF4:   LD      -1(P1)
        XRI     0x3A
        JZ      DEF3
        XRI     0x37
        JZ      DEF1
        LD      @1(P1)
        JMP     DEF4
DEF5:   LD      @1(P1)
        XRI     0x20
        JZ      DEF5
        XRI     0x90
        JZ      DEF6
FNERR:  LD      -11(P2)
        ST      -8(P2)
        LD      -12(P2)
        ST      -9(P2)
        LDI     0x63
        JMP     -98(P3)
DEF6:   LD      @1(P1)
        XRE
        XRI     0x80
        JNZ     DEF4
        SCL
        LD      (P1)
        CAI     0x5B
        JP      -42(P3)
        ADI     0x1A
        JP      DEF4
        ADI     0x07
        JP      -42(P3)
        ADI     0x0A
        JP      DEF4
        JMP     -42(P3)
FNT:    LD      -11(P2)
        ST      -8(P2)
        LD      -12(P2)
        ST      -9(P2)
        LD      -15(P2)
        ST      -11(P2)
        LD      -16(P2)
        ST      -12(P2)
        JMP     -42(P3)
FNDNE:  LD      @1(P1)
        XRI     0x20
        JZ      FNDNE
        XRI     0x2D
        JZ      FNDN
        XRI     0x37
        JZ      FNDN
        LDI     0x2D
        JMP     -98(P3)
FNDN:   LD      -11(P2)
        XPAL    P1
        LD      -12(P2)
        XPAH    P1
FNDN1:  LD      @-1(P1)
        XRI     0x0D
        JNZ     FNDN1
        LD      1(P1)
        ST      -9(P2)
        LD      2(P1)
        ST      -8(P2)
        LD      -11(P2)
        XPAL    P1
        LD      -12(P2)
        XPAH    P1
        JMP     71(P3)
PRFNUM: LD      -03(P2)
        XPAL    P1
        LD      @-4(P1)
L_FE71: LD      @-1(P1)

        CALL    P3,PUTASC
        JP      L_FE71
PREND:  LDI     0x60
        ST      -3(P2)
        LD      -13(P2)
        XPAL    P1
        LD      -14(P2)
        XPAH    P1
        JMP     -42(P3)
BOTTOM: LD      -10(P2)
        RR
        RR
        RR
        RR
        XAE
        DLD     -3(P2)
        DLD     -3(P2)
        XPAL    P2
        XAE
        ST      (P2)
        LDI     0x01
        ST      1(P2)
        LDE
        XPAL    P2
        JMP     -42(P3)
SAVE:   XPAH    P3
        ORI     0x04
        XPAH    P3
        LD      -33(P2)
        ST      -37(P2)
        XPAL    P1
        LD      -34(P2)
        ST      -38(P2)
        XPAH    P1
        LD      -34(P2)
        XPPC    P3
        LD      -33(P2)
        XPPC    P3
        LD      -36(P2)
        XPPC    P3
        LD      -35(P2)
        XPPC    P3
SAVE1:  LDI     0x20
        ST      -22(P2)
        LDI     0x00
        ST      -23(P2)
        CCL
SAVE2:  LD      (P1)
        ADD     -23(P2)
        ST      -23(P2)
        LD      (P1)
        XPPC    P3
        LD      -38(P2)
        XOR     -36(P2)
        JNZ     SAVE3
        XPAL    P1
        XOR     -35(P2)
        JNZ     SAVE3
        LD      -23(P2)
        XPPC    P3
        XPAH    P3
        ANI     0xF0
        XPAH    P3
        JMP     -42(P3)
SAVE3:  ILD     -37(P2)
        JNZ     SAVE4
        XPAH    P1
        ILD     -38(P2)
        XPAH    P1
SAVE4:  XPAL    P1
        DLD     -22(P2)
        JNZ     SAVE2
        LD      -23(P2)
        XPPC    P3
        JMP     SAVE1
CLOAD:  LDI     0x5C
        ST      -3(P2)
        LD      @58(P3)
        XPAH    P3
        ORI     0x04
        XPAH    P3
        XPPC    P3
        ST      -34(P2)
        XPPC    P3
        ST      -33(P2)
        XPPC    P3
        ST      -36(P2)
        XPPC    P3
        ST      -35(P2)
        LD      -33(P2)
        ST      -8(P2)
        LD      -34(P2)
        ST      -9(P2)
LOAD1:  LDI     0x20
        ST      -22(P2)
        LDI     0x00
        ST      -23(P2)
        CCL
LOAD2:  LD      -8(P2)
        XPAL    P1
        LD      -9(P2)
        XPAH    P1
        XPPC    P3
        ST      (P1)
        ADD     -23(P2)
        ST      -23(P2)
        XPAH    P1
        XOR     -36(P2)
        JNZ     L_FF3E
        XPAL    P1
        XOR     -35(P2)
        JNZ     L_FF3E

        CALL    P3,FNDVAR
        JZ      L_FF4F
LOAD3:  LD      @-58(P3)
        XPAH    P3
        ANI     0xF0
        XPAH    P3
        LDI     0xBF
        ST      127(P2)
        LDI     0x29
        JMP     -98(P3)
L_FF3E: ILD     -8(P2)
        JNZ     L_FF44
        ILD     -9(P2)
L_FF44: DLD     -22(P2)
        JNZ     LOAD2

        CALL    P3,FNDVAR
        JZ      LOAD1
        JMP     LOAD3
L_FF4F: LD      @-58(P3)
        XPAH    P3
        ANI     0xF0
        XPAH    P3
ADDOUT: LD      -33(P2)
        ST      -8(P2)
        LD      -34(P2)
        ST      -9(P2)

        CALL    P3,PRNUM
        LDI     0x2D

        CALL    P3,PUTASC
        LD      -35(P2)
        ST      -8(P2)
        LD      -36(P2)
        ST      -9(P2)

        CALL    P3,PRNUM
        LDI     0x86
        JMP     -98(P3)
BOTOM1: LD      -3(P2)
        XPAL    P1
        LD      @-4(P1)
        SCL
        LD      -96(P2)
        ANI     0x7F
        ST      -18(P2)
        CAD     -95(P2)
        ST      -17(P2)
        LD      -96(P2)
        JP      L_FF8C
        DLD     -17(P2)
        JZ      L_FF9F
L_FF8C: LD      @-1(P1)
        XRI     0x2D
        JNZ     L_FF98
        LD      @1(P1)
        ILD     -21(P2)
        JZ      L_FF9F
L_FF98: SCL
        LD      -17(P2)
        CAD     -21(P2)
        JP      L_FFAA
L_FF9F: LDI     0x2A

        CALL    P3,PUTASC
        DLD     -18(P2)
        JNZ     L_FF9F
        JMP     -42(P3)
L_FFAA: JZ      L_FFB7
        ST      -22(P2)
L_FFAE: LDI     0x20

        CALL    P3,PUTASC
        DLD     -22(P2)
        JNZ     L_FFAE
L_FFB7: LD      -25(P2)
        JP      L_FFCF
        LD      -1(P1)
        XRI     0x2D
        JNZ     L_FFC8
        DLD     -21(P2)
        LD      @-1(P1)

        CALL    P3,PUTASC
L_FFC8: LDI     0x30

        CALL    P3,PUTASC
        JMP     L_FFD2
L_FFCF:
        CALL    P3,L_D1D8
L_FFD2: LD      -96(P2)
        JP      -42(P3)
        LDI     0x2C

        CALL    P3,PUTASC
        LD      -95(P2)
        JZ      -42(P3)
        ST      -21(P2)
        LD      -25(P2)
        JP      L_FFF6
        ST      -22(P2)
L_FFE7: LDI     0x30

        CALL    P3,PUTASC
        DLD     -21(P2)
        JZ      -42(P3)
        DLD     -22(P2)
        XRI     0x81
        JNZ     L_FFE7
L_FFF6:
        CALL    P3,L_D1D8
        JMP     -42(P3)
USING:
        CALL    P3,L_D4C0
        JMP     -42(P3)

        END     ENTRY
