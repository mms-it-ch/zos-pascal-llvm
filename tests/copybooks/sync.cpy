      * SYNC-Ausrichtung (relativ zum Satzanfang) und OCCURS DEPENDING ON
       01  SYNC-SATZ.
           05  S-KZ                PIC X.
           05  S-HALB              PIC S9(4) COMP SYNC.
           05  S-X3                PIC X(3).
           05  S-VOLL              PIC S9(9) COMP SYNC.
           05  S-X1                PIC X.
           05  S-DOPPEL            PIC S9(18) COMP SYNC.
           05  S-F1                COMP-1 SYNC.
           05  S-TAB OCCURS 2.
               10  T-A             PIC X.
               10  T-B             PIC S9(9) BINARY SYNC.
           05  S-ANZ               PIC 9(3).
           05  S-ZEILE OCCURS 1 TO 10 TIMES DEPENDING ON S-ANZ
                                   PIC X(4).
