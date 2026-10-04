000100*----------------------------------------------------------------*
000200* KUNDE: Kundensatz (festes Format, Folgenummern in Spalte 1-6)  *
000300*----------------------------------------------------------------*
000400 01  KUNDE-SATZ.
000500     05  KUNDE-NR            PIC 9(8).
000600     05  KUNDE-NAME          PIC X(30).
000700     05  KUNDE-STATUS        PIC X.
000800         88  KUNDE-AKTIV     VALUE 'A'.
000900         88  KUNDE-GESPERRT  VALUE 'S' 'X'.
001000     05  KUNDE-SALDO         PIC S9(9)V99 COMP-3.
001100     05  KUNDE-LIMIT         PIC S9(7)V99 USAGE IS PACKED-DECIMAL.
001200     05  KUNDE-ANZAHL        PIC S9(4) COMP.
001300     05  KUNDE-PUNKTE        PIC 9(9) BINARY.
001400     05  KUNDE-GROSS         PIC S9(18) COMP-5.
001500     05  KUNDE-DATUM.
001600         10  KUNDE-JJJJ      PIC 9(4).
001700         10  KUNDE-MM        PIC 99.
001800         10  KUNDE-TT        PIC 99.
001900     05  FILLER              PIC X(5).
002000     05  KUNDE-BETRAG        PIC S9(5)V99 SIGN LEADING SEPARATE.
002100     05  KUNDE-KURS          COMP-2.
002200     05  KUNDE-FAKTOR        USAGE COMP-1.
