      * PIC N, editiert, P, figurative Konstanten, X'..', SIGN LEADING, POINTER/INDEX, 77
       01  DIVERS.
           05  D-NAT       PIC N(4).
           05  D-EDIT      PIC ZZZ,ZZ9.99-.
           05  D-PROZ      PIC SVPP999.
           05  D-KENN      PIC X(2).
               88  D-LEER  VALUE SPACES.
               88  D-NULL  VALUE LOW-VALUES.
               88  D-HEX   VALUE X'C1C2'.
           05  D-VORZ      PIC S9(3) SIGN IS LEADING.
           05  D-PTR       USAGE POINTER.
           05  D-IDX       USAGE INDEX.
           05  TYPE        PIC X.
       77  EINZEL          PIC S9(5) COMP-3.
           88  EINZEL-NULL VALUE ZERO.
