*---------------------------------------------------------------------*
* ZPCALL31: Bruecke fuer Aufrufe von AMODE-31-Programmen aus Pascal  *
* (AMODE 64, Unit zoscall31, runtime/zosc31.c).                       *
*                                                                     *
* Laeuft als eigener z/OS-UNIX-Prozess (AMODE 31, ohne LE). Liest     *
* Auftraege von fd 0, schreibt Antworten auf fd 1 (BPX1RED/BPX1WRT).  *
* Auftrag: X'E9F3F1C3', Name CL8, Anzahl F, je Bereich Laenge F und   *
* Daten. Die Bereiche kommen in eigenen Speicher (GETMAIN LOC=31),    *
* R1 zeigt auf die Adressliste (Hochbit am letzten Eintrag), das      *
* Programm wird mit LOAD geladen und mit BASSM aufgerufen.            *
* Antwort: X'E9F3F1D9', Status F (0 ok, 1 LOAD gescheitert), R15 bzw. *
* Abend-Code, je Bereich Laenge und Daten. Ende: X'E9F3F1C5'.         *
*                                                                     *
* Bauen auf z/OS (pf8/build31-zos.sh):                                *
*   as -o zpcall31.o zpcall31.s                                       *
*   ld -b AMODE=31 -b RMODE=ANY -e ZPCALL31 -o zpcall31 zpcall31.o \  *
*      -S "//'SYS1.CSSLIB'"                                           *
* Auf z/OS noch nicht getestet.                                       *
*---------------------------------------------------------------------*
ZPCALL31 CSECT
ZPCALL31 AMODE 31
ZPCALL31 RMODE ANY
         SAVE  (14,12)
         LR    12,15
         USING ZPCALL31,12
         LA    11,SAVEA
         ST    13,4(,11)
         ST    11,8(,13)
         LR    13,11
*
LOOP     DS    0H
         LA    2,HDR
         LA    3,4
         BAL   10,READN
         LTR   15,15
         BNZ   EXIT0               Ende der Eingabe
         CLC   HDR,ENDMAG
         BE    EXIT0
         CLC   HDR,CALLMAG
         BNE   EXIT2               Protokollfehler
         LA    2,MODNAME
         LA    3,8
         BAL   10,READN
         LTR   15,15
         BNZ   EXIT2
         LA    2,NAREAS
         LA    3,4
         BAL   10,READN
         LTR   15,15
         BNZ   EXIT2
         L     4,NAREAS
         C     4,MAXAREAS
         BH    EXIT2
*        Bereiche lesen
         SR    5,5                 Index * 4
         LTR   4,4
         BZ    DOLOAD
RDAREA   DS    0H
         LA    2,ALEN(5)
         LA    3,4
         BAL   10,READN
         LTR   15,15
         BNZ   EXIT2
         L     0,ALEN(5)
         LTR   0,0
         BNZ   GETM
         LA    0,8                 Laenge 0: trotzdem eine Adresse
GETM     DS    0H
         ST    0,GLEN(5)
         GETMAIN RU,LV=(0),LOC=31
         ST    1,AADDR(5)
         LR    2,1
         L     3,ALEN(5)
         LTR   3,3
         BZ    NEXTRD
         BAL   10,READN
         LTR   15,15
         BNZ   EXIT2
NEXTRD   LA    5,4(,5)
         BCT   4,RDAREA
*        Programm laden und aufrufen
DOLOAD   DS    0H
         LOAD  EPLOC=MODNAME,ERRET=LOADERR
         ST    0,EPADDR
         SR    1,1
         L     6,NAREAS
         LTR   6,6
         BZ    CALLIT
         BCTR  6,0
         SLL   6,2
         L     7,AADDR(6)
         O     7,HIBIT
         ST    7,AADDR(6)          Hochbit am letzten Eintrag
         LA    1,AADDR
CALLIT   L     15,EPADDR
         BASSM 14,15               R13 = SAVEA
         ST    15,RCODE
         L     6,NAREAS
         LTR   6,6
         BZ    NOHIBIT
         BCTR  6,0
         SLL   6,2
         L     7,AADDR(6)
         N     7,LOWMASK
         ST    7,AADDR(6)
NOHIBIT  DELETE EPLOC=MODNAME
         XC    RSTAT,RSTAT
*        Antwort
SENDRSP  MVC   RHDR,RESPMAG
         LA    2,RHDR
         LA    3,12                RHDR, RSTAT, RCODE
         BAL   10,WRITEN
         LTR   15,15
         BNZ   EXIT2
         L     4,NAREAS
         SR    5,5
         LTR   4,4
         BZ    LOOP
WRAREA   DS    0H
         CLC   RSTAT,=F'0'
         BNE   FREEA               bei Fehler keine Daten zurueck
         LA    2,ALEN(5)
         LA    3,4
         BAL   10,WRITEN
         L     2,AADDR(5)
         L     3,ALEN(5)
         LTR   3,3
         BZ    FREEA
         BAL   10,WRITEN
FREEA    L     0,GLEN(5)
         L     1,AADDR(5)
         FREEMAIN RU,LV=(0),A=(1)
         LA    5,4(,5)
         BCT   4,WRAREA
         B     LOOP
*
LOADERR  DS    0H                  R1 = Abend-Code, R15 = Grund
         ST    1,RCODE
         MVC   RSTAT,=F'1'
         B     SENDRSP
*
EXIT0    SR    2,2
         B     EXIT
EXIT2    LA    2,2
EXIT     L     13,4(,13)
         LR    15,2
         RETURN (14,12),RC=(15)
*
*---------------------------------------------------------------------*
* READN: R3 Bytes von fd 0 nach R2 lesen; R15 = 0 ok, 4 Ende/Fehler   *
* Ruecksprung ueber R10                                               *
*---------------------------------------------------------------------*
READN    DS    0H
         ST    2,BUFA
         ST    3,CNT
         CALL  BPX1RED,(FD0,BUFA,ALET0,CNT,RV,RETC,RSN),VL
         L     6,RV
         LTR   6,6
         BNP   READX               0 = Ende, -1 = Fehler
         AR    2,6
         SR    3,6
         BP    READN
         SR    15,15
         BR    10
READX    LA    15,4
         BR    10
*---------------------------------------------------------------------*
* WRITEN: R3 Bytes ab R2 auf fd 1 schreiben; R15 = 0 ok, 4 Fehler     *
*---------------------------------------------------------------------*
WRITEN   DS    0H
         ST    2,BUFA
         ST    3,CNT
         CALL  BPX1WRT,(FD1,BUFA,ALET0,CNT,RV,RETC,RSN),VL
         L     6,RV
         LTR   6,6
         BNP   WRITEX
         AR    2,6
         SR    3,6
         BP    WRITEN
         SR    15,15
         BR    10
WRITEX   LA    15,4
         BR    10
*
         LTORG
SAVEA    DC    18F'0'
CALLMAG  DC    X'E9F3F1C3'
ENDMAG   DC    X'E9F3F1C5'
RESPMAG  DC    X'E9F3F1D9'
HIBIT    DC    X'80000000'
LOWMASK  DC    X'7FFFFFFF'
MAXAREAS DC    F'32'
FD0      DC    F'0'
FD1      DC    F'1'
ALET0    DC    F'0'
BUFA     DS    F
CNT      DS    F
RV       DS    F
RETC     DS    F
RSN      DS    F
HDR      DS    F
MODNAME  DS    CL8
NAREAS   DS    F
EPADDR   DS    F
RHDR     DS    F                   RHDR, RSTAT, RCODE hintereinander
RSTAT    DS    F
RCODE    DS    F
ALEN     DS    32F
GLEN     DS    32F
AADDR    DS    32F
         END   ZPCALL31
