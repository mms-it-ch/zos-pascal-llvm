      *----------------------------------------------------------------*
      * ZPCOB2: COBOL (AMODE 31) ruft die Pascal-Funktion KUNDE_PRUEFEN*
      * (AMODE 64, pf8/call64lib.pas) ueber ZP64CALL/CEL4RO64.         *
      * SYSIN: Name bzw. Pfad der Pascal-DLL (Spalte 1-64).            *
      * RETURN-CODE = Zahl der Fehler. Auf z/OS noch nicht getestet.   *
      *----------------------------------------------------------------*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ZPCOB2.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  DLL-NAME            PIC X(64).
       01  FUNC-NAME           PIC X(32) VALUE 'KUNDE_PRUEFEN'.
       01  ERGEBNIS            PIC S9(9) COMP.
       01  FEHLER              PIC S9(4) COMP VALUE 0.
       COPY KUNDE.
       PROCEDURE DIVISION.
           ACCEPT DLL-NAME FROM SYSIN
           INITIALIZE KUNDE-SATZ
           MOVE 4711 TO KUNDE-NR
           MOVE 1500.00 TO KUNDE-SALDO
           MOVE 1000.00 TO KUNDE-LIMIT
           CALL 'ZP64CALL' USING DLL-NAME FUNC-NAME ERGEBNIS
                                 KUNDE-SATZ
           DISPLAY 'ZPCOB2: ERGEBNIS ' ERGEBNIS
                   ' STATUS ' KUNDE-STATUS ' PUNKTE ' KUNDE-PUNKTE
           IF ERGEBNIS NOT = 8 OR NOT KUNDE-GESPERRT
              OR KUNDE-PUNKTE NOT = 1
              DISPLAY 'FEHLER  Saldo ueber Limit'
              ADD 1 TO FEHLER
           ELSE
              DISPLAY 'OK      Saldo ueber Limit -> gesperrt'
           END-IF
           MOVE 500.00 TO KUNDE-SALDO
           CALL 'ZP64CALL' USING DLL-NAME FUNC-NAME ERGEBNIS
                                 KUNDE-SATZ
           IF ERGEBNIS NOT = 0 OR NOT KUNDE-AKTIV
              OR KUNDE-PUNKTE NOT = 2
              DISPLAY 'FEHLER  Saldo unter Limit'
              ADD 1 TO FEHLER
           ELSE
              DISPLAY 'OK      Saldo unter Limit -> aktiv'
           END-IF
           MOVE FEHLER TO RETURN-CODE
           GOBACK.
