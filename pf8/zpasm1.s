*---------------------------------------------------------------------*
* ZPASM1: Testprogramm fuer pf8/call31test.pas (AMODE 31, OS-Linkage) *
*   CALL ZPASM1,(P1,P2,P3),VL   P3 := P1 + P2 (Fullwords)             *
*   R15 = 0, bei negativem P1 R15 = 8                                 *
* Auf z/OS noch nicht getestet.                                       *
*---------------------------------------------------------------------*
ZPASM1   CSECT
ZPASM1   AMODE 31
ZPASM1   RMODE ANY
         STM   14,12,12(13)
         LR    12,15
         USING ZPASM1,12
         LM    2,4,0(1)            A(P1), A(P2), A(P3)
         LA    4,0(,4)             Hochbit entfernen
         L     5,0(,2)
         A     5,0(,3)
         ST    5,0(,4)
         SR    15,15
         L     6,0(,2)
         LTR   6,6
         BNM   RET
         LA    15,8
RET      L     14,12(,13)
         LM    0,12,20(13)
         BR    14
         END   ZPASM1
