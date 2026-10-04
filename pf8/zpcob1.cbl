      *----------------------------------------------------------------*
      * ZPCOB1: Testprogramm fuer pf8/call31test.pas (AMODE 31).       *
      * Satz KUNDE-SATZ aus dem Copybook KUNDE (tests/copybooks/       *
      * kunde.cpy, in Pascal: pf8/cb_kunde.pas).                       *
      * Auf z/OS noch nicht getestet.                                  *
      *----------------------------------------------------------------*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ZPCOB1.
       DATA DIVISION.
       LINKAGE SECTION.
       COPY KUNDE.
       PROCEDURE DIVISION USING KUNDE-SATZ.
           ADD 100.50 TO KUNDE-SALDO
           SET KUNDE-AKTIV TO TRUE
           COMPUTE KUNDE-PUNKTE = KUNDE-ANZAHL * 10
           MOVE 4 TO RETURN-CODE
           GOBACK.
