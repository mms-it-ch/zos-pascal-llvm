*---------------------------------------------------------------------*
* ZP64CALL: AMODE-31-Programm (COBOL, LE) ruft eine Pascal-Funktion   *
* (AMODE 64, XPLINK) in einer Pascal-DLL ueber die LE-Schnittstelle   *
* CEL4RO64 (z/OS 3.1 bzw. LE mit APAR; zweite LE-Umgebung AMODE 64).  *
*                                                                     *
*   CALL 'ZP64CALL' USING DLL-NAME FUNC-NAME ERGEBNIS [ARG1 ...]      *
*     DLL-NAME  PIC X(64)  Name/Pfad der DLL (Leerzeichen am Ende)    *
*     FUNC-NAME PIC X(32)  exportierter Funktionsname                 *
*     ERGEBNIS  PIC S9(9) COMP  Ergebnis der Funktion (R3), oder      *
*               -999 Parameter falsch, -1000-rc CEL4RO64-Fehler,      *
*               -1006 CEL4RO64 nicht vorhanden                        *
*     ARGn      bis zu 16 Datenbereiche: die Funktion bekommt ihre    *
*               Adressen (31 Bit, als 64-Bit-Zeiger)                  *
*                                                                     *
* Kontrollblock RO64_CB wie in Eclipse OpenJ9 (runtime/j9vm31/        *
* j9cel4ro64.h): version, length, flags, moduleOffset,                *
* functionOffset, argumentsOffset, dllHandle (8), functionDescriptor  *
* (8), gpr1/gpr2/gpr3 (je 8), retcode; Laenge 72. Einstieg ueber      *
* CAA+1024 -> +8, Pruefung CEEPCB_3164 (PCB+84 X'04', PCB = CAA+756), *
* Aufruf mit OS-Linkage (OS_UPSTACK).                                 *
* Annahme: Namen in EBCDIC. Auf z/OS noch nicht getestet.             *
*---------------------------------------------------------------------*
ZP64CALL CEEENTRY PPA=ZPPPA,MAIN=NO,AUTO=WORKSIZE,BASE=10
         USING WORKAREA,13
         LR    9,1                 Parameterliste
         L     2,756(,12)          PCB
         TM    84(2),X'04'         CEEPCB_3164
         BZ    NOSUPP
         LA    7,CBAREA
         XC    0(256,7),0(7)
         XC    256(256,7),256(7)
         MVC   0(4,7),=F'1'        version
         MVC   8(4,7),=X'E0000000' load + query + execute
         LA    6,72(,7)            Modulteil
         LA    3,72
         ST    3,12(,7)            moduleOffset
         L     4,0(,9)             A(DLL-NAME)
         LA    5,64
         BAL   8,TRIM
         LTR   5,5
         BZ    BADPARM
         ST    5,0(,6)
         BCTR  5,0
         EX    5,MVCNAME
         LA    6,5(5,6)            hinter Laenge und Namen
         LR    3,6
         SR    3,7
         ST    3,16(,7)            functionOffset
         L     4,4(,9)             A(FUNC-NAME)
         LA    5,32
         BAL   8,TRIM
         LTR   5,5
         BZ    BADPARM
         ST    5,0(,6)
         BCTR  5,0
         EX    5,MVCNAME
         LA    6,5(5,6)
         L     2,8(,9)             A(ERGEBNIS)
         LR    3,2
         N     2,=X'7FFFFFFF'
         ST    2,RESADDR
         SR    5,5                 Zahl der Argumente
         LTR   3,3
         BM    ARGSDONE            ERGEBNIS war der letzte Parameter
         LA    4,12(,9)
ARGLOOP  L     3,0(,4)
         LR    2,3
         N     2,=X'7FFFFFFF'
         LR    1,5
         SLL   1,3
         LA    1,4(1,6)            Slot n: 8 Byte, oberes Wort 0
         ST    2,4(,1)
         LA    5,1(,5)
         C     5,=F'16'
         BH    BADPARM
         LTR   3,3
         BM    ARGSDONE
         LA    4,4(,4)
         B     ARGLOOP
ARGSDONE LTR   5,5
         BZ    NOARGS
         LR    3,6
         SR    3,7
         ST    3,20(,7)            argumentsOffset
         LR    1,5
         SLL   1,3
         ST    1,0(,6)             Laenge der Argumente
         LA    6,4(1,6)
         B     SETLEN
NOARGS   XC    20(4,7),20(7)       ohne Argumente: argumentsOffset 0
SETLEN   LR    3,6
         SR    3,7
         ST    3,4(,7)             Gesamtlaenge
         ST    7,PLIST
         OI    PLIST,X'80'
         LA    1,PLIST
         L     15,1024(,12)
         L     15,8(,15)           CEL4RO64
         BALR  14,15
         L     2,RESADDR
         L     3,64(,7)            retcode
         LTR   3,3
         BNZ   FAILED
         MVC   0(4,2),60(7)        unteres Wort von GPR3
         B     DONE
FAILED   LA    4,1000(,3)
         LCR   4,4
         ST    4,0(,2)
         B     DONE
NOSUPP   L     2,8(,9)
         N     2,=X'7FFFFFFF'
         MVC   0(4,2),=F'-1006'
         B     DONE
BADPARM  L     2,8(,9)
         N     2,=X'7FFFFFFF'
         MVC   0(4,2),=F'-999'
DONE     CEETERM RC=0
*
* TRIM: R4 Adresse, R5 Hoechstlaenge -> R5 Laenge ohne Leerzeichen
* und X'00' am Ende; Ruecksprung ueber R8
TRIM     LA    1,0(5,4)
         BCTR  1,0
TRIML    LTR   5,5
         BZR   8
         CLI   0(1),X'40'
         BE    TRIMB
         CLI   0(1),X'00'
         BNER  8
TRIMB    BCTR  1,0
         BCTR  5,0
         B     TRIML
MVCNAME  MVC   4(0,6),0(4)
*
ZPPPA    CEEPPA
         LTORG
WORKAREA DSECT
         ORG   *+CEEDSASZ
PLIST    DS    F
RESADDR  DS    F
         DS    0D
CBAREA   DS    XL512
WORKSIZE EQU   *-WORKAREA
         CEEDSA
         CEECAA
         END   ZP64CALL
