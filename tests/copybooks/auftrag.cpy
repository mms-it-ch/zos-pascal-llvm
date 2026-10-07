      * Auftrag mit Positionen: OCCURS (auch verschachtelt), REDEFINES,
      * Stufe 88 mit THRU
       01  AUFTRAG.
           05  AUF-NR              PIC X(10).
           05  AUF-ART             PIC 9.
               88  AUF-NORMAL      VALUE 1.
               88  AUF-EIL         VALUE 2 THRU 4.
           05  AUF-ADRESSE.
               10  AUF-STRASSE     PIC X(25).
               10  AUF-ORT         PIC X(20).
           05  AUF-POSTFACH REDEFINES AUF-ADRESSE.
               10  AUF-PF-NR       PIC 9(6).
               10  FILLER          PIC X(39).
           05  AUF-KURZ REDEFINES AUF-ADRESSE PIC X(10).
           05  AUF-ANZ-POS         PIC S9(3) COMP-3.
           05  AUF-POS OCCURS 5 TIMES INDEXED BY POS-IX.
               10  POS-ARTIKEL     PIC X(8).
               10  POS-MENGE       PIC S9(5) COMP-3.
               10  POS-PREIS       PIC S9(7)V99 COMP-3.
               10  POS-RABATT      PIC 99 OCCURS 3.
           05  AUF-SUMME           PIC S9(11)V99 COMP-3.
