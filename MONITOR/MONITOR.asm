; MONITOR.ASM by Erich Küster, late seventies of last century
; assembler listing
; read-in from paper listing and disasssembled again
; fed into macro assembler asl 40 years later (in 2023)
; the macro-assembler used here is a free tool by Alfred Arnold:
;           http://john.ccac.rwth-aachen.de:8000/as/
;
;   .TITLE  MONITOR FOR ELEKTOR-SYSTEM,'06/20/2023'
;   .LIST   1
;
; Krefeld / Germany June 20, 2023
;

; SELECT DESIRED BAUD RATE, 0 FOR ORIGINAL DEFAULT
BAUD	=  0
; SET BASE ADDRESS
BASE	=  0xC000
; Set stack pointer
STACK   =  0x1F80

; ILLEGAL OPCODES
WRITECH = 0x20
READCHR = 0x21

L FUNCTION VAL16, (VAL16 & 0xFF)
H FUNCTION VAL16, ((VAL16 >> 8) & 0xFF)

JS    MACRO  P,VAL            ;JUMP TO SUBROUTINE
        LDI     H(VAL-1)
        XPAH    P
        LDI     L(VAL-1)
        XPAL    P
        XPPC    P
      ENDM

LDPI  MACRO  P,VAL            ;LOAD POINTER
        LDI     L(VAL)
        XPAL    P
        LDI     H(VAL)
        XPAH    P
      ENDM

CALL  MACRO  P,VAL            ;CALL SUBROUTINE
        XPPC    P
        DB      H(VAL)
        DB      L(VAL)
      ENDM

RTRN  MACRO     P,VAL            ;RETURN FROM SUBROUTINE
        XPPC    P
        DB      0
      ENDM

JMPBIT  =  0x80
TSTBIT  =  0x40               ;I.L. INSTRUCTION FLAGS
CALBIT  =  0x20
JMPBITH =  JMPBIT*256
TSTBITH =  TSTBIT*256
CALBITH =  CALBIT*256

; SC/MP POINTER ASSIGNMENTS
P1      =  1
P2      =  2
P3      =  3

; THE EXTENSION REGISTER
EREG    =  -128

; DISPLACEMENTS FOR STACK USED BY MONITOR
P3LOW   =  -1
P3HIGH  =  -2

TSTSTR  MACRO  FAIL,A,B
        DB      H(FAIL - TSTBITH)
        DB      L(FAIL)
        IFB     B
          DB    A |0x80 
        ELSE
          DB    A 
          DB    B |0x80
        ENDIF
        ENDM

MESSAGE MACRO  A,B
        DB      A
        DB      B|0x80
        ENDM

GOTO    MACRO  ADR
        DB      H(ADR - JMPBITH)
        DB      L(ADR)
        ENDM
 
DO      MACRO  ADR
        IFNB    ADR 
        DB      H(ADR)
        DB      L(ADR)

        SHIFT
        DO      ALLARGS
        ENDIF
        ENDM 

        ORG     BASE
START:  NOP
        DINT
        LDPI    P2,STACK
        LDI     0x20
        ST      -29(P2)
        LDPI    P3, SPRVSR-1 ;POINT P3 AT SUPERVISOR
        CALL    P3,ASCOUT
        MESSAGE "\12  MONITO",'R'
NEU:    LDI     0x1E
        ST      -29(P2)    
        LDI     0x60
        ST      -03(P2)    
        LDI     0xFF
        ST      -12(P2)    
        LDI     0x04
        ST      +00(P2)    
        LDI     L(BEGIN) ; LOAD LOW OF BEGIN   
        ST      P3LOW(P2)    
        LD      -98(P2)  ; LOAD PAGE (HIGH OF BEGIN)
        ST      P3HIGH(P2)    
        
        CALL    P3,ASCOUT
        DB      13,10,'*',0xA0
XCT:    LD      P3LOW(P2)
        XPAL    P3
        LD      P3HIGH(P2) ; LOAD P3 FROM STACK
        ORI     0xC0    ; SET TWO HIGH BITS
        XPAH    P3
NXT:    LD      +00(P3) ; LOAD BYTE AFTER 3F INSTRUCTION
        JZ      XCUTE   ; IF ZERO RETURN
        JP      GTO     ; GOTO COMMAND
        ANI     0x40    ; IS TSTSTR COMMAND?
        JNZ     SUPRVS  ; YES, JUMP TO SUPERVISOR
GTO:    LD      +01(P3)
        ST      P3LOW(P2)    
        LD      @+02(P3)    
        ST      P3HIGH(P2)
        JP      XCT     ; to $C03E
        LD      +00(P3)
        XRE
        JNZ     XCT     ; to $C03E
        LDI     0x69
        XPAL    P3
        XPAL    P1
        LD      -98(P2)
        XPAH    P3
        XPAH    P1
        JMP     NXT     ; to $C046
        DO      TXTOUT
        NOP
        NOP
        NOP
RTRN:   ILD     -29(P2)
        ILD     -29(P2)
RTN1:   XPAL    P2
RTN2:   LD      P3LOW(P2)
        XPAL    P3
        LD      P3HIGH(P2)
        XPAH    P3
        LDI     0x80
        XPAL    P2
XCTE:   LD      @-01(P3)    
XCUTE:  LD      -96(P2)
        XPPC    P3
SPRVSR: ST      -96(P2)
        LD      +01(P3)
        JZ      RTRN    ; to $C06E
        LD      @+01(P3)    
        LD      -29(P2)
        XPAL    P2
SUPRVS: LD      @+02(P3)    
        ST      P3HIGH(P2)    
CALL:   LD      -01(P3)
        XPAL    P3
        ST      P3LOW(P2)    
        LD      P3HIGH(P2)
        XPAH    P3
        ST      P3HIGH(P2)    
        LDI     0x80
        XPAL    P2
        DLD     -29(P2)
        DLD     -29(P2)
        JNZ     XCTE    ; to $C07C
        LDI     0x80
        XPAL    P3
        LD      -98(P2)
        XPAH    P3
        LDI     0x1C
        ST      -29(P2)    
NSTERR: LDI     0x56
        JMP     ERRTYP  ; to $C0BB
HEXERR: LDI     0x53
        JMP     ERRTYP  ; to $C0BB
BRK:     LDI     0x82
        JMP     ERRTYP  ; to $C0BB
SNTERR: LDI     0x6D
ERRTYP: XPAL    P1
        LD      -98(P2)
        ORI     0x01
        XPAH    P1
ERR:    LDI     0x20
        
        CALL    P3,PUTASC
PRERR:  LD      @+01(P1)    
        
        CALL    P3,PUTASC
        JP      PRERR   ; to $C0C6
        LDI     0x7D
        XPAL    P1
        JP      ERR     ; to $C0C1
        ILD     -12(P2)
        JZ      -98(P3)
        
        CALL    P3,0xE03E ; RTNERR

        ORG    0xC0D9
BEGIN:  DO      GETASC
        TSTSTR  LIST,"GOT",'O'
        DO      GETHEX
        DB      0       ; END OF I.L. COMMANDS
USER:   ILD     -03(P2)
        ILD     -03(P2)
        JMP     -15(P3)
LIST:   TSTSTR  MDFY,"LIS",'T'
        DO      GETHEX
        DB      0       ; END OF I.L. COMMANDS
LIST0:  LDI     0x0F
LIST1:  ST      -17(P2)    
LINE:   
        CALL    P3,PRHEX
        LDI     0x10
        ST      -18(P2)    
BYTES:  
        CALL    P3,GETBYT
        
        CALL    P3,P2HEX1
        
        CALL    P3,PRADD
        DLD     -18(P2)
        JNZ     BYTES   ; to $C0FE
        LD      -17(P2)
        JNZ     LIST2   ; to $C112
        
        CALL    P3,GETASC
LIST2:  
        CALL    P3,ASCOUT
        DB      13,0x8A ; CARRIAGE RETURN, LINE FEED
        DLD     -17(P2)
        JP      LINE
        LDE
        XRI     13      ; IS CARRIAGE RETURN?
        JZ      LIST0   ; to $C0F3
        XRI     0x07
        JNZ     +52(P3)  
        JMP     LIST1   ; to $C0F5

;***************************
;*     ERROR MESSAGES      *
;***************************
 
        ORG     BASE+0x130

MESGS:  MESSAGE "ARE",'A'     ; 1
        MESSAGE "BL",'K'      ; 2
        MESSAGE "CAS",'S'     ; 3
        MESSAGE "CHA",'R'     ; 4
        MESSAGE "DAT",'A'     ; 5
        MESSAGE "DIV",'0'     ; 6
        MESSAGE "END",'"'     ; 7
        MESSAGE "ERAS",'E'    ; 8
        MESSAGE "FO",'R'      ; 9
        MESSAGE "HE",'X'      ; 10
        MESSAGE "NES",'T'     ; 11
        MESSAGE "NEX",'T'     ; 12
        MESSAGE "NOG",'O'     ; 13
        MESSAGE "PRO",'M'     ; 14
        MESSAGE "RA",'M'      ; 15
        MESSAGE "RTR",'N'     ; 16
        MESSAGE "SNT",'X'     ; 17
        MESSAGE "STM",'T'     ; 18
        MESSAGE "UNT",'L'     ; 19
        MESSAGE "VAL",'U'     ; 20
        MESSAGE "ERRO",'R'    ; 21
        MESSAGE "BREA",'K'    ; 22

ASCOUT: LD      -29(P2)
        XPAL    P2
        LD      +01(P2)
        XPAL    P1
        ST      -03(P2)    
        LD      +00(P2)
        XPAH    P1
        ST      -04(P2)    
        LDI     0x80
        XPAL    P2
PRASC:  LD      @+01(P1)    
        
        CALL    P3,PUTASC
        JP      PRASC   ; to $C197
        LD      -29(P2)
        XPAL    P2
        LD      -03(P2)
        XPAL    P1
        ST      +01(P2)    
        LD      -04(P2)
        XPAH    P1
        ST      +00(P2)    
        LDI     0x80
        XPAL    P2
        RTRN P3
GETHEX: 
        CALL    P3,GETLIN
        
        CALL    P3,HEX
        LD      +00(P1)
        XRI     0x0D
        JNZ     +48(P3)  
        RTRN P3
PRTXT:  LD      P3LOW(P2)
        XPAL    P1
        LD      P3HIGH(P2)
        XPAH    P1
TXTOUT: LD      @+01(P1)    
        
        CALL    P3,PUTASC
        JP      TXTOUT  ; to $C1C4
        XPAL    P1
        ST      P3LOW(P2)    
        XPAH    P1
        ST      P3HIGH(P2)    
BLNK:   LDI     0x20
        
        CALL    P3,PUTASC
        RTRN P3
P2HEX1: ST      -21(P2)    
        LDI     0x00
        JMP     HEXOUT  ; to $C1E2
P2HEX2: ST      -21(P2)    
        LDI     0x01
HEXOUT: ST      -11(P2)    
        LDI     0x02
        ST      -22(P2)    
HEXASC: LD      -21(P2)
        RR
        RR
        RR
        RR
        ST      -21(P2)    
        ANI     0x0F
        CCL
        ADI     0xF6
        JP      LETR    ; to $C1FB
        ADI     0x3A
        JMP     NUM     ; to $C1FD
LETR:   ADI     0x40
NUM:  
        CALL    P3,PUTASC
        DLD     -22(P2)
        JNZ     HEXASC  ; to $C1E8
        LD      -11(P2)
        JZ      BLNK    ; to $C1D1
        RTRN P3

        ORG     BASE+0x20B
PRADD:  LD      -03(P2)
PRADD0: XPAL    P2
        ILD     +01(P2)
        JNZ     PRADD1  ; to $C214
        ILD     +00(P2)
PRADD1: LDI     0x80
        XPAL    P2
        RTRN P3
PRSUB:  LD      -03(P2)
PRSUB0: XPAL    P2
        LD      +01(P2)
        JNZ     PRSUB1  ; to $C222
        DLD     +00(P2)
PRSUB1: DLD     +01(P2)
        LDI     0x80
        XPAL    P2
        RTRN P3
GETDSP: LD      -03(P2)
        XPAL    P2
        LD      +01(P2)
        XPAL    P1
        LD      +00(P2)
        XPAH    P1
        LD      @+01(P1)    
        LD      +00(P1)
        XPAL    P1
        ST      +01(P2)    
        XPAH    P1
        ST      +00(P2)    
        LDI     0x80
        XPAL    P2
        XPAL    P1
        RTRN P3
GETBYT: LD      -03(P2)
        XPAL    P2
        LD      +01(P2)
        XPAL    P1
        LD      +00(P2)
        XPAH    P1
        LDI     0x80
        XPAL    P2
        LD      +00(P1)
        RTRN P3
PUTBYT: LD      -03(P2)
        XPAL    P2
        LD      +01(P2)
        XPAL    P1
        LD      +00(P2)
        XPAH    P1
        LDI     0x80
        XPAL    P2
        LD      -96(P2)
        ST      +00(P1)    
        RTRN P3
MDFY:   TSTSTR  TRNSFR,"MODIF",'Y'
        DO      GETHEX
MDFY1:  DO      PRHEX
        DO      GETBYT,P2HEX1,GETLIN,MODFY
        GOTO    MDFY1
MODFY:  LD      -25(P2)
        JNZ     MODFY1  ; to $C289
        LD      -01(P1)
        XRI     0x0D
        JZ      ADD0    ; to $C2B1
        
        CALL    P3,HEX
        JMP     MODFY2  ; to $C2B8
MODFY1: 
        CALL    P3,HEX
        LD      +00(P1)
        XRI     0x0D
        JNZ     +48(P3) ; HEXERR
        DLD     -25(P2)
        SR
        ST      -25(P2)    
        ILD     -03(P2)
        ILD     -03(P2)
BYTE0:  SCL
        LDI     0xDD
        CAD     -25(P2)    
        XAE
        LD      EREG(P2)
       
        CALL    P3,PUTBYT
        
        CALL    P3,GETBYT
        XOR     EREG(P2)
        JZ      ADD0    ; to $C2B1
        LDI     0x66
        JMP     +58(P3) ; ERRTYP
ADD0:   
        CALL    P3,PRADD
        DLD     -25(P2)
        JP      BYTE0   ; to $C29B
MODFY2: RTRN P3

TRNSF1: CALL    P3,ASCOUT
        MESSAGE "TRANSFE",'R'
TRNSF2: CALL    P3,ASCOUT
        MESSAGE "\13\10ANFAD=",' '
        CALL    P3,GETHEX
        CALL    P3,ASCOUT
        MESSAGE "ENDAD=",' '
        CALL    P3,GETHEX
        SCL
        LD      -35(P2)
        CAD     -33(P2)    
        LD      -36(P2)
        CAD     -34(P2)    
        JP      -19(P3) ; to RTRN
        LDI     0x34
        JMP     +58(P3) ; to ERRTYP
TRNSF3: CALL    P3,ASCOUT
        MESSAGE "NEWAD=",' '
        RTRN    P3
TRNSFR: TSTSTR  CASS,"BLOC",'K'
        DO      TRNSF1,TRNSF3,GETHEX
        DB      0
        SCL
        LD      -37(P2)
        CAD     -33(P2)    
        ST      -39(P2)    
        LD      -38(P2)
        CAD     -34(P2)    
        ST      -40(P2)    
        JP      TRANS    ; to $C336
UP:     LDI     0x5E
        
        CALL    P3,GETBYT+2
        
        CALL    P3,PUTBYT
        LDI     0x5E
        
        CALL    P3,PRADD0
        
        CALL    P3,PRADD
        SCL
        LD      -35(P2)
        CAD     -33(P2)    
        LD      -36(P2)
        CAD     -34(P2)    
        JP      UP      ; to $C319
        RTRN P3
TRANS:  ANI     0xF0
        JNZ     UP      ; to $C319
        CCL
        LD      -35(P2)
        ADD     -39(P2)
        ST      -37(P2)    
        LD      -36(P2)
        ADD     -40(P2)
        ST      -38(P2)    
DOWN:   LDI     0x5C
        
        CALL    P3,GETBYT+2
        
        CALL    P3,PUTBYT
        LDI     0x5C
        
        CALL    P3,PRSUB0
        
        CALL    P3,PRSUB
        SCL
        LD      -35(P2)
        CAD     -33(P2)    
        LD      -36(P2)
        CAD     -34(P2)    
        JP      DOWN    ; to $C347
        RTRN P3

; CASSETTE ROUTINES SC/MP II 2 MHz
        ORG     BASE+0x364
BYTOUT: ST      -96(P2)    
        LDI     0x0B
        ST      -21(P2)    
        LDI     0x00
        XAE
        SIO
        XAE
        DLD     -127(P2)
        LD      -96(P2)
        XAE
BYTE1:  LDI     0x0B
        DLY     0x00
        LD      -20(P2)
        ST      -19(P2)    
BYTE2:  DLD     -19(P2)
        JNZ     BYTE2
        SIO
        LDE
        ORI     0x80
        XAE
        DLD     -21(P2)
        JNZ     BYTE1
        XPPC    P3
        JMP     BYTOUT
        DB      0,0,0,0
LDBYTE: LDI     0xFF
        XAE
        SIO
        LDE
        JP      LD1
        JMP     LDBYTE
LD1:    LDI     0xFF
        XAE
        LD      -20(P2)
        SR
        ST      -19(P2)    
LD2:    DLD     -19(P2)
        JNZ     LD2
        LDI     0x08
        ST      -21(P2)    
LD3:    LD      -20(P2)
        ST      -19(P2)    
        LDI     0x16
        DLY     0x00
LD4:    DLD     -19(P2)
        JNZ     LD4
        SIO
        DLD     -21(P2)
        JNZ     LD3
        LD      -20(P2)
        ST      -19(P2)    
LD5:    DLD     -19(P2)
        JNZ     LD5
        LDE
        XPPC    P3
        JMP     LDBYTE

CASS:   TSTSTR  CLRS,"CASSETT",'E'
        DO      PCASS
CASS1:  DO      PRTXT
        DB      13,10
        DB      "SELECT: "
        DB      "D=DUMP/L"
        DB      "=LOAD/S="
        MESSAGE "SPEED\13",'\10'
CASS2:  DO      GETASC
        TSTSTR  CASS3,"DUM",'P'
        DO      TRNSF2
        DB      0
MORE:   LD      @+09(P3)    
        XPAH    P3
        ORI     0x03
        XPAH    P3            ; $C389 = ADDRESS OF JMP BYTOUT
        LD      -33(P2)
        XPAL    P1
        LD      -34(P2)
        XPAH    P1
        LD      -34(P2)
        XPPC    P3
        LD      -33(P2)
        XPPC    P3
        LD      -36(P2)
        XPPC    P3
        LD      -35(P2)
        XPPC    P3
DUMP:   LDI     0x20
        ST      -22(P2)    
        LDI     0x00
        ST      -23(P2)    
        CCL
DUMP0:  LD      +00(P1)
        ADD     -23(P2)
        ST      -23(P2)    
        LD      +00(P1)
        XPPC    P3
        LD      -34(P2)
        XOR    -36(P2)
        JNZ     DUMP1
        XPAL    P1
        XOR    -35(P2)
        JNZ     DUMP1
        LD      -23(P2)
        XPPC    P3
        LDI     0x80
        XPAL    P3
        LD      -98(P2)
        XPAH    P3
        RTRN P3
DUMP1:  ILD     -33(P2)
        JNZ     DUMP2
        XPAH    P1
        ILD     -34(P2)
        XPAH    P1
DUMP2:  XPAL    P1
        DLD     -22(P2)
        JNZ     DUMP0
        LD      -23(P2)
        XPPC    P3
        JNZ     DUMP
PCASS:  LDI     0x01
        XAE
        SIO
        LDI     0x15          ;SC/MPII 4 MHz: 0x1f
        ST      -20(P2)    
        RTRN P3
CASS3:  TSTSTR  SPEED,"LOA",'D'
        DO      GETASC
        TSTSTR  CASS4,"\11\10",0x5E
        DO      LOAD
        DO      PRTXT
        MESSAGE "\13\10ANFAD",'='
        DO      PRHEX
        DO      PRTXT
        MESSAGE "\13\10ENDAD",'='
        DO      PRNHEX
        DO      NEU
CASS4:  DO TRNSF2
        DB      0
        LD      @+67(P3)    
        XPAH    P3
        ORI     0x03
        XPAH    P3
        XPPC    P3
        XPPC    P3
        XPPC    P3
        XPPC    P3
        JMP     LOAD1
LOAD:   LDI     0x5E
        ST      -03(P2)    
        LD      @+67(P3)    
        XPAH    P3
        ORI     0x03
        XPAH    P3
        XPPC    P3
        ST      -34(P2)    
        XPPC    P3
        ST      -33(P2)    
        XPPC    P3
        ST      -36(P2)    
        XPPC    P3
        ST      -35(P2)    
LOAD1:  LD      -33(P2)
        ST      -37(P2)    
        LD      -34(P2)
        ST      -38(P2)    
LOAD2:  LDI     0x20
        ST      -22(P2)    
        LDI     0x00
        ST      -23(P2)    
        CCL
LOAD3:  LD      -37(P2)
        XPAL    P1
        LD      -38(P2)
        XPAH    P1
        XPPC    P3
        ST      +00(P1)    
        ADD     -23(P2)
        ST      -23(P2)    
        XPAH    P1
        XOR    -36(P2)
        JNZ     LOAD5
        XPAL    P1
        XOR    -35(P2)
        JNZ     LOAD5
        XPPC    P3
        XOR    -23(P2)
LOAD4:  XPAH    P3
        LDI     0x80
        XPAL    P3
        LD      -98(P2)
        XPAH    P3
        JZ      -19(P3)
        LDI     0x5A
        XPPC    P3
        LD      @-126(P2)    
        LDI     0x37
        JMP     +58(P3)
LOAD5:  ILD     -37(P2)
        JNZ     LOAD6
        ILD     -38(P2)
LOAD6:  DLD     -22(P2)
        JNZ     LOAD3
        XPPC    P3
        XOR    -23(P2)
        JZ      LOAD2
        JMP     LOAD4

        ORG     BASE+0x500
GETLIN: LDI     0x9D
        XPAL    P1
        ST      -15(P2)    
        SCL
        LD      -122(P3)
        CAI     0x01
        XPAH    P1
        ST      -16(P2)    
        LD      -12(P2)
        ANI     0xBF
        
        CALL    P3,PUTASC
        JP      GETL    ; to $C51B
        LDI     0x20
        
        CALL    P3,PUTASC
GETL:   LD      +00(P2)
        ST      -25(P2)    
CLRBUF: XAE
        LDI     0x20
        ST      EREG(P1)    
        DLD     -25(P2)
        JNZ     CLRBUF  ; to $C51F
INP:    
        CALL    P3,GETASC
        ST      -01(P1)    
        ANI     0x60
        JNZ     STORE   ; to $C55D
        LDE
        XRI     0x08
        JNZ     HT      ; to $C542
        LD      -25(P2)
        JZ      INP     ; to $C528
        DLD     -25(P2)
        LDE
        
        CALL    P3,PUTASC
        JMP     INP     ; to $C528
HT:     XRI     0x01
        JZ      OUTP    ; to $C563
        XRI     0x05
        JNZ     CR      ; to $C550
        LDE
        
        CALL    P3,PUTASC
        JMP     +52(P3)
CR:     XRI     0x01
        JZ      STORE   ; to $C55D
        XRI     0x07
        OR      -25(P2)    
        JNZ     INP     ; to $C528
EX:     LDI     0x0D
        XAE
STORE:  LD      -25(P2)
        XAE
        ST      EREG(P1)    
        XAE
OUTP:   LDE
        
        CALL    P3,PUTASC
        XRI     0x0D
        JZ      EXT     ; to $C573
        ILD     -25(P2)
        XOR     +00(P2)
        JZ      EX      ; to $C55A
        JMP     INP     ; to $C528
EXT:    LDI     0x0A
        
        CALL    P3,PUTASC
        RTRN P3

        ORG    BASE+0x580 
; GET CHARACTER AND ECHO IT
GETASC: LDI    0x08
        ST     -21(P2)
GWAIT:  CSA
        ANI    0x20
        JNZ    GWAIT
        LDI    0xC2
        DLY    0
        CSA
        ANI    0x20
        JNZ    GWAIT
GINP:   LDI    0x76
        DLY    1
        CSA
        ANI    0x20
        JZ     GZERO
        LDI    0x01
GZERO:  RRL
        XAE
        SRL
        XAE
        DLD    -21(P2)
        JNZ    GINP
        DLY    1
        LDE
        ANI    0x7F
        XAE
        LDE
        ANI    0x40
        JZ     UPPERC
        LDE
        ANI    0x5F
        XAE
UPPERC: LDE
        XRI    3
        JZ     +38(P3)        ;JUMP BRK(3)
        LDE
        RTRN   P3

        ORG     BASE+0x5CE 
CLRS:   TSTSTR  INTR,0x0c,0xAA
        GOTO    BEGIN
INTR:   TSTSTR  PROM,"INTERPRETE",'R'    
        DB      0
        LDI     0xC0    ; LOAD ENTRY POINT INTO P1
        XPAL    P1
        LDI     0xDF
        XPAH    P1
        XPPC    P1      ; TRANSFER TO NIBLFP

SPEED:  TSTSTR  CASS2,"SPEE",'D'
        DO      GETHEX,SPEED0
        GOTO    CASS1
SPEED0: LDI     0x60
        ST      -03(P2)    
        LD      -33(P2)
        ST      -20(P2)    
        RTRN P3

        ORG     BASE+0x600 
HEX:    DLD     -03(P2)
        DLD     -03(P2)
        XPAL    P2
        LDI     0x00
        ST      +01(P2)    
        ST      +00(P2)    
        ST      P3LOW(P2)    
HEX0:   XAE
        LD      +00(P1)
        SCL
        CAI     0x3A
        JP      LETTR   ; to $C61C
        SCL
        CAI     0xF6
        JP      ENTR    ; to $C636
        JMP     END     ; to $C62A
LETTR:  SCL
        CAI     0x0D
        JP      END     ; to $C626
        SCL
        CAI     0xFA
        JP      OK      ; to $C633
END:    LDI     0x80
        XPAL    P2
        LDE
        JZ      +48(P3)
        SCL
        CAI     0x05
        JP      VALUE   ; to $C657
        RTRN P3
OK:     CCL
        ADI     0x0A
ENTR:   XAE
        LDI     0x04
        ST      P3HIGH(P2)    
SHIFT:  CCL
        LD      +01(P2)
        ADD     +01(P2)
        ST      +01(P2)    
        LD      +00(P2)
        ADD     +00(P2)
        ST      +00(P2)    
        DLD     P3HIGH(P2)
        JNZ     SHIFT   ; to $C63B
        LD      +01(P2)
        ORE
        ST      +01(P2)    
        LD      @+01(P1)    
        ILD     P3LOW(P2)
        JMP     HEX0    ; to $C60D
VALUE:  LDI     0x79
        JMP     +58(P3)
  
        ORG     BASE+0x67C
PRNHEX: DLD     -03(P2)
        DLD     -03(P2)
PRHEX:  LD      -03(P2)
PRHEX1: XPAL    P1
        ST      -15(P2)    
        LD      -122(P3)
        XPAH    P1
        ST      -16(P2)    
        LDI     0x20
        ST      @-08(P1)    
        LDI     0x04
        ST      -25(P2)    
DIGIT:  XAE
        LD      +09(P1)
        ANI     0x0F
        CCL
        ADI     0xF6
        JP      BUCH    ; to $C6A0
        ADI     0x3A
        JMP     AUSG    ; to $C6A2
BUCH:   ADI     0x40
AUSG:   ST      EREG(P1)    
        LDI     0x04
        ST      -23(P2)    
DIVHEX: LD      +09(P1)
        RRL
        LD      +08(P1)
        RRL
        ST      +08(P1)    
        LD      +09(P1)
        RRL
        ST      +09(P1)    
        DLD     -23(P2)
        JNZ     DIVHEX  ; to $C6A8
        DLD     -25(P2)
        JNZ     DIGIT   ; to $C692
        LDI     0xA0
        ST      +06(P1)    
PRNTHX: LD      @+01(P1)    
        
        CALL    P3,PUTASC
        JP      PRNTHX  ; to $C6C1
        LDI     0x5E
        ST      -03(P2)    
        LD      -15(P2)
        XPAL    P1
        LD      -16(P2)
        XPAH    P1
        RTRN P3

        ORG    BASE+0x700
; OUTPUT CHARACTER
PUTASC: ANI    0x7F
        XAE
        ST     -127(P2)
        LDI    0x30
        DLY    3
        CSA
        ORI    1
        CAS
        LDI    9
        ST     -24(P2)
PUTA1:  LDI    0x5C
        DLY    1
        DLD    -24(P2)
        JZ     PUTA2
        LDE
        ANI    0x01
        ST     -23(P2)
        XAE
        RR
        XAE
        CSA
        ORI    1
        XOR    -23(P2)
        CAS
        JMP    PUTA1
PUTA2:  CSA
        ANI    0xFE
        CAS
        LD     -127(P2)
        XAE
        XRI    0x0C
        JNZ    PUTA3
        DLY    255
        LD     -96(P2)
        RTRN   P3
PUTA3:  XRI    6
        JNZ    PUTA4
        DLY    0x10
PUTA4:  LD     -96(P2)
        RTRN   P3

        ORG     BASE+0x0800
PROM:   TSTSTR  DASMBL,"PROGRA",'M'
        DO      GETHEX
        DO      PPRGM
PRGM1:  DO      PRTXT
        DB      "\13SELECT:"
        DB      " C=CHECK/"
        DB      "L=LIST/T="
        MESSAGE "TRANSFER\13",'\10'
PRGM2:  DO      GETASC
        TSTSTR  LST,"CHECK",' '
        DO      ERASE
        DO      PRTXT
        MESSAGE "O.K.",'\10'
        GOTO    PRGM1
PPRGM:  LD      -34(P2)       ; EPROM TYP
        XRI     0x27
        JNZ     +56(P3)       ; JMP SNTERR(P3)  
        ST      -34(P2)    
        LDI     0xFF
        ST      -35(P2)    
        LD      -33(P2)    
        XRI     0x58
        JNZ     PPRGM1
        ST      -33(P2)    
        ST      -20(P2)    
        LDI     0x03
        ST      -36(P2)    
        RTRN P3

PPRGM1: LDI     0x40
        ST      -20(P2)    
        LD      -33(P2)
        XRI     0x16
        JNZ     +56(P3)  
        ST      -33(P2)    
        LDI     0x07
        ST      -36(P2)    
        RTRN P3

        ORG     BASE+0x884
ERASE:  LDI     4
        XPAL    P1
        LDI     0x82
        XPAH    P1
        LDI     0x90
        ST      +03(P1)    
ERASE0: LD      -34(P2)
        OR      -20(P2)    
        ST      +02(P1)    
        LD      -33(P2)
        ST      +01(P1)    
        SCL
        LD      +00(P1)
        XRI     0xFF
        JZ      ERASE1
        XPPC    P3
        LD      @EREG(P2)    
        LDI     0x4B
        JMP     +58(P3)
ERASE1: ILD     -33(P2)
        JNZ     ERASE2
        ILD     -34(P2)
ERASE2: LD      -35(P2)
        CAD     -33(P2)    
        LD      -36(P2)
        CAD     -34(P2)    
        JP      ERASE0
        LDI     0x00
        ST      -33(P2)    
        ST      -34(P2)    
        RTRN P3

LST:    TSTSTR  PRM,"LIS",'T'
        DB      0
        LDI     0x04
        XPAL    P1
        LDI     0x82
        XPAH    P1
        LDI     0x90
        ST      +03(P1)    
LST1:   LDI     0x0F
        ST      -17(P2)    
LST2:   
        CALL    P3,ASCOUT
        DB      '\13',0x8A
        
        CALL    P3,PRHEX
        LDI     0x10
        ST      -18(P2)    
LST3:   LD      -34(P2)
        OR      -20(P2)    
        ST      +02(P1)    
        LD      -33(P2)
        ST      +01(P1)    
        ILD     -33(P2)
        JNZ     LST4    ; to LST4
        ILD     -34(P2)
LST4:   LD      +00(P1)
        
        CALL    P3,P2HEX1
        DLD     -18(P2)
        JNZ     LST3    ; to LST3
        DLD     -17(P2)
        JP      LST2    ; to LST2
        
        CALL    P3,GETASC
        SCL
        LD      -35(P2)
        CAD     -33(P2)    
        LD      -36(P2)
        CAD     -34(P2)    
        JP      LST2    ; to LST1
        RTRN P3
PRM:    TSTSTR   PRGM2,"TRANSFE",'R'
        DB      0
        LDI     0x60
        ST      -03(P2)    
        
        CALL    P3,TRNSF2
        
        CALL    P3,TRNSF3
        
        CALL    P3,GETHEX
PRM1:   LD      -33(P2)
        XPAL    P1
        LD      -34(P2)
        XPAH    P1
        LD      +00(P1)
        XAE
        LDI     4
        XPAL    P1
        LDI     0x82
        XPAH    P1
        LDI     0x80
        ST      +3(P1)    
        LDI     0x0F
        ST      +03(P1)    
        LD      -37(P2)
        ST      +1(P1)    
        LDE
        ST      +0(P1)    
        LD      -38(P2)
        ANI     0x0F
        OR      -20(P2)    
        ORI     0xB0
        ST      +02(P1)    
        LDI     0x94        ; (2 MHZ), 0x37 (4 MHZ)
        DLY     0x30        ; (2 MHZ), 0x61 (4 MHZ)
        LDI     0x90
        ST      +03(P1)    
        LD      -38(P2)
        ANI     0x0F
        OR      -20(P2)    
        ST      +02(P1)    
        LD      -37(P2)
        ST      +01(P1)    
        SCL
        LD      +00(P1)
        XRE
        JZ      PRM2    ; to PRM2
        
        CALL    P3,PRHEX
        LD      @-126(P2)    
        JMP     +58(P3)
PRM2:   ILD     -33(P2)
        JNZ     PRM3    ; to PRM3
        ILD     -34(P2)
PRM3:   ILD     -37(P2)
        JNZ     PRM4    ; to PRM4
        ILD     -38(P2)
PRM4:   LD      -35(P2)
        CAD     -33(P2)    
        LD      -36(P2)
        CAD     -34(P2)    
        JP      PRM1   ; to PRM1
        RTRN P3

OPCODE  MACRO A,B,C
          DB  A
          DB  B
          DB  C|0x80
          DB  0,0
        ENDM

        ORG     BASE+0x985
DASMBL: TSTSTR  BEGIN,"DISASSEMBL",'E'
        DO      GETHEX
NXTD:   DO      PRTXT
        DB      0x8D
        DO      PRHEX,GETBYT,P2HEX2,DSMB,DSASMB,DSMBL,GETDSP
        DO      PRTXT
        DB      0x8A
        DO      BRKR
        GOTO    NXTD
DSMB:   LD      0(P1)
        XAE
        LDI     0x00
        ST      -17(P2)    
        ST      -18(P2)    
        LDE
        ANI     0xF0
        XRI     0x30
        JZ      PNTR
        JP      OBYTE   ; ONE-BYTE INSTRUCTION
        
        CALL    P3,GETDSP
        
        CALL    P3,P2HEX1
        
        CALL    P3,ASCOUT
        DB      0x20, 0xA0
        LDE
        XRI     0x8F
        JZ      -19(P3)
PNTR:   LDE
        ANI     0x03    ; ISOLATE POINTER INDEX
        ST      -18(P2)    
        JZ      L1      ; to $C9E4
        LDE
        ANI     0x40
        JZ      L1      ; to $C9E4
        LDE
        ANI     0xF8
        XAE
        ANI     0x04
        ST      -17(P2)    
        RTRN P3
L1:     LDE
        ANI     0xFC
        XAE
        ANI     0x80
        JNZ     -19(P3)  
        
OBYTE:  CALL    P3,ASCOUT
        DB      "    ", 0xA0
        RTRN P3
DSASMB: SCL
        LDI     L(TAB4) ; LOAD LOW OF TAB4
        XPAL    P1
        LD      -98(P2) ; LOAD PAGE
        ORI     0x0A
        XPAH    P1      ; SET P1 TO TAB4
DSM1:   LD      @+01(P1)    
        XRE
        JZ      FOUND   ; to $CA12
        XRE
        XRI     0xFF
        JZ      NOTFND  ; to $CA11
DSM2:   LD      @+01(P1)    
        JP      DSM2    ; to $CA09
        LD      @+02(P1)    
        JMP     DSM1    ; to $C9FFHAL
NOTFND: CCL
FOUND:  LD      @+01(P1)    
        
        CALL    P3,PUTASC
        JP      FOUND
        LDI     0x20
        
        CALL    P3,PUTASC
        RTRN P3
DSMBL:  CSA
        JP      -19(P3)
        CCL
        LDE
        ANI     0xF0
        XAE
        XRI     0x8F
        JZ      DSPL    ; to $CA73
        ANI     0xC4
        XRI     0x40
        JZ      DSPL    ; to $CA73
        LDE
        XRI     0x30
        JNZ     DSMB2   ; to $CA47
        LDI     0x50
        
        CALL    P3,PUTASC
        LD      -18(P2)
        JNZ     DSMB1   ; to $CA42
        LDI     0x13
DSMB1:  ADI     0x30
        
        CALL    P3,PUTASC
DSMB2:  JP      -19(P3)
        LD      -21(P2)
        XRI     0x80
        JZ      DSMB4   ; to $CA6A
        LD      -18(P2)
        JNZ     DSMB4   ; to $CA6A
        
        CALL    P3,GETBYT
        XAE
        XRI     0x90
        JNZ     DSMB3   ; to $CA5D
        LD      @+01(P1)    
DSMB3:  LD      @EREG(P1)    
        XPAL    P1
        ST      -35(P2)    
        XPAH    P1
        ST      -36(P2)    
        
        CALL    P3,PRNHEX
        RTRN P3
DSMB4:  LD      -17(P2)
        JZ      DSPL    ; to $CA73
        LDI     0x40
        
        CALL    P3,PUTASC
DSPL:   LD      -21(P2)
        
        CALL    P3,P2HEX1
        LD      -18(P2)
        JZ      -19(P3)
        
        CALL    P3,ASCOUT
        DB      '(', 0xD0
        LD      -18(P2)
        ORI     0x30
        
        CALL    P3,PUTASC
        LDI     0x29
        
        CALL    P3,PUTASC
        RTRN P3
BRKR:   CSA
        ANI     0x20
        JNZ     BRKR
        RTRN P3
TAB4:   OPCODE 0, "HAL",'T'
        OPCODE 1, "XA",'E'
        OPCODE 2, "CC",'L'
        OPCODE 3, "SC",'L'
        OPCODE 4, "DIN",'T'
        OPCODE 5, "IE",'N'
        OPCODE 6, "CS",'A'
        OPCODE 7, "CA",'S'
        OPCODE 8, "NO",'P'
        OPCODE 0x19, "SI",'O'
        OPCODE 0x1C, "S",'R'
        OPCODE 0x1D, "SR",'L'
        OPCODE 0x1E, "R",'R'
        OPCODE 0x1F, "RR",'L'
        OPCODE 0x30, "XPA",'L'
        OPCODE 0x34, "XPA",'H'
        OPCODE 0x3C, "XPP",'C'
        OPCODE 0x40, "LD",'E'
        OPCODE 0x50, "AN",'E'
        OPCODE 0x55, ".BYT",'E'
        OPCODE 0x58, "OR",'E'
        OPCODE 0x60, "XR",'E'
        OPCODE 0x68, "DA",'E'
        OPCODE 0x70, "AD",'E'
        OPCODE 0x78, "CA",'E'
        OPCODE 0x8F, "DL",'Y'
        OPCODE 0x90, "JM",'P'
        OPCODE 0x94, "J",'P'
        OPCODE 0x98, "J",'Z'
        OPCODE 0x9C, "JN",'Z'
        OPCODE 0xA8, "IL",'D'
        OPCODE 0xB8, "DL",'D'
        OPCODE 0xC0, "L",'D'
        OPCODE 0xC4, "LD",'I'
        OPCODE 0xC8, "S",'T'
        OPCODE 0xD0, "AN",'D'
        OPCODE 0xD4, "AN",'I'
        OPCODE 0xD8, "O",'R'
        OPCODE 0xDC, "OR",'I'
        OPCODE 0xE0, "XO",'R'
        OPCODE 0xE4, "XR",'I'
        OPCODE 0xE8, "DA",'D'
        OPCODE 0xEC, "DA",'I'
        OPCODE 0xF0, "AD",'D'
        OPCODE 0xF4, "AD",'I'
        OPCODE 0xF8, "CA",'D'
        OPCODE 0xFC, "CA",'I'
        OPCODE 0xFF, "?",'?'
        DB     0

