# PF5: C-ABI für Records (XPLINK-64)

`abi.pas` + `abi_c.c`: Records als Ergebnis und als Wertparameter von `cdecl`-Funktionen, in
beide Richtungen (Pascal ruft C, C ruft Pascal). Ergebnis (28.09.2026): 27/27.

```sh
clang --target=s390x-ibm-zos -O1 -trigraphs -mzos-sys-include=$HOME/zos/include \
      -D__CHARSET_LIB=1 -c abi_c.c -o abi_c.o      # clang aus ~/build/llvm-zos
sh ../scripts/zfpc abi.pas && ./abi
```

## Regeln (wie clang, `ZOSXPLinkABIInfo`)

| Fall | Übergabe |
|---|---|
| Ergebnis ≤ 24 Byte | GPR 1–3, `inreg [n x i64]`, Daten linksbündig (auch 1–7, 12, 20 Byte, einzelnes float/double, `{float, double}`) |
| Ergebnis complex-artig (`{float, float}`, `{double, double}`) | FPR 0 und 2, normales Struct |
| Ergebnis > 24 Byte | versteckter Ergebniszeiger (`sret`) |
| Wertparameter | volle 64-Bit-Slots, Daten linksbündig (auch 1, 2, 4 Byte und der letzte Teil-Slot), auch > 24 Byte |
| Wertparameter complex-artig | zwei FPRs (bzw. Stack), GPR-Slots werden mitgezählt |

## Was vorher falsch war (FPC-Patch 0022)

- Ergebnisse: nur 8/16/24 Byte kamen in Registern, alle anderen Größen per `sret` (C gibt sie
  in GPRs zurück), complex-artige Records per `sret` statt in FPRs.
- Parameter: Records mit 1, 2, 4 Byte gingen als Ganzzahl eigener Größe (rechtsbündig); der
  letzte, teilweise gefüllte Slot größerer Records wurde als `i32` geladen und mit `zext`
  erweitert (generischer Code in `llvmgetcgparadef`, für Little-Endian gedacht);
  complex-artige Records gingen in GPRs.
- Dafür nötig im generischen Code: `gen_load_loc_cgpara` behandelte einen Record in mehreren
  FPU-Locations wie einen einzelnen Gleitkommawert (Internal Error 200408162); der
  LLVM-Codegenerator lädt/speichert jetzt FPU-Locations solcher Records.

## FPC-Testsuite

`test/cg/tcalext*`, `tcalpvr*` (C-Objekte `test/cg/obj/*.c`, von `fpc-testsuite.sh` mit clang
für z/OS übersetzt): 12/12. Diese Tests (und `test/cg` insgesamt) waren im PF3-Lauf nicht dabei,
weil nur die oberste Ebene von `test/` lief; `fpc-testsuite.sh test/cg` geht jetzt (Lognamen
mit `_` statt `/`).

## Backtraces mit Funktionsnamen (FPC-Patch 0023, 28.09.2026)

Laufzeitfehler, unbehandelte Ausnahmen, `DumpExceptionBackTrace`, `CaptureBacktrace` und
`ExceptFrames` zeigen jetzt die Aufrufkette mit Namen (vorher eine feste Scheinadresse
`$EEEEEEEE`):

```
An unhandled exception occurred at $000000002030AAE8:
EDivByZero: Division by zero
  $000000002030AAE8  P$BT_$$_LEVEL3$LONGINT
  $000000002030ACA6  P$BT_$$_LEVEL2$LONGINT
  $000000002030ACF6  P$BT_$$_LEVEL1$LONGINT
  $000000002030B2D0  PASCALMAIN
  $000000002037CDCE  SYSTEM_$$_FPC_SYSTEMMAIN$LONGINT$PPANSICHAR$PPANSICHAR
```

- `get_frame` = `llvm.frameaddress(0)` = R4 + 2048. Den Schritt zum Aufrufer macht der
  LE-Traceback-Dienst `__le_traceback` (`runtime/zosunwind.c`, Probe `letb_c.c`): DSA = R4,
  Ergebnis DSA und Aufrufbefehl des Aufrufers; LE erkennt das Ende (Hauptprogramm: CELQINIT,
  Thread: CELQPCMM). Ein eigener Schritt über EPM/PPA1 lief am Ende eines Thread-Stacks in ein
  ungültiges R7 und suchte dann im Speicher nach einem EPM (SIGSEGV).
- Der Durchlauf endet bei `FPC_SYSTEMMAIN`. `StackTop` taugt nicht als Grenze (StackBottom wird
  bei der Initialisierung aus `Sptr` gesetzt, unterhalb der Frames des Hauptprogramms).
- FPC übergibt bei `raise` die Adresse eines Labels + 1 (ungerade); gilt als Adresse in der
  Funktion.
- Name: `BackTraceStrFunc` hängt den Namen aus dem PPA1 an (Objektdatei-Name, z. B.
  `P$PROG_$$_PROC$LONGINT`); Zeilennummern gibt es ohne DWARF-Leser für GOFF nicht.
- Signale: `zossig.c` übergibt als Frame jetzt R4 + 2048 (wie `get_frame`).
- Tests: `bt.pas` (2/2; `bt div`, `bt runerror` zeigen die Standardausgabe), `btthr.pas`
  (Ausnahme im Thread und im qsort-Callback durch LE-Frames: 2/2), `raiseperf.pas`: 20000
  Ausnahmen aus Tiefe 5 in 213 ms (~11 µs je Ausnahme inkl. Backtrace und Unwinding).
