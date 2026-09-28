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
  `P$PROG_$$_PROC$LONGINT`).
- **Zeilennummern (`-gl`, FPC-Patch 0034):** FPC erzeugt DWARF (dbg_dwarf3), der z/OS-Binder
  lehnt die DWARF-Klassen in GOFF aber ab (IEW2353E). Daher schreibt `zos-irc` ein Objekt ohne
  Debug-Information und daneben `NAME.dbgo` mit DWARF. `zos-ld` liest aus den `.dbgo`-Dateien
  (`scripts/goff-lines.py`: GOFF-ESD/TXT/RLD, D_LINE-Zeilenprogramm DWARF 2–5, Code-Vergleich
  mit dem gebundenen Objekt) eine Tabelle Funktion → (Offset, Zeile) und bindet sie als
  `zzz_lines.o` mit (Tabelle nicht const, sonst IEW2353E). Ohne `-gl` kommt die leere Tabelle
  `zoslines0.o` aus dem Archiv. Ausgabe wie unter Linux:
  `$000000002030AAE8  P$BT_$$_LEVEL3$LONGINT,  line 41 of bt.pas`. `ZOS_LINES=0` schaltet es
  ab. RTL und Packages sind ohne `-gl` übersetzt (dort nur Funktionsnamen).
- Signale: `zossig.c` übergibt als Frame jetzt R4 + 2048 (wie `get_frame`).
- Tests: `bt.pas` (2/2; `bt div`, `bt runerror` zeigen die Standardausgabe), `btthr.pas`
  (Ausnahme im Thread und im qsort-Callback durch LE-Frames: 2/2), `raiseperf.pas`: 20000
  Ausnahmen aus Tiefe 5 in 213 ms (~11 µs je Ausnahme inkl. Backtrace und Unwinding).

## Inline-Assembler (FPC-Patch 0035, 28.09.2026)

`asm … end` in HLASM-Syntax. Der Port hat keine eigenen Befehlstabellen: LLVM liest die
Inline-Assembly selbst (auf z/OS im HLASM-Dialekt). Der Leser `compiler/s390x/rahlasm.pas`
gibt jeden Befehl als Text weiter und ersetzt nur, was er kennt:

| Im `asm`-Block | wird zu |
|---|---|
| `LOOP:` am Zeilenanfang | Marke, je Block eindeutig (`LOOP${:uid}`) |
| `R0`..`R15`, `F0`..`F15` | Registernummer |
| Pascal-Konstante, `TYP.FELD` | Wert bzw. Feldoffset |
| Variable, Parameter, `RESULT` | `D(B)` bzw. `D(L,B)`, Adresse der Variablen in einem Register: `L 1,X`, `L 1,X+4`, `MVC R.C(8),SRC`, `LA 1,X` |

- Ein Befehl je Zeile (oder `;`), Kommentare wie in Pascal. Leerzeichen in den Operanden
  werden entfernt (HLASM beendet die Operanden am ersten Leerzeichen).
- Globale Variablen gehen genauso (Adresse als Argument); `var`-Parameter: die Variable
  enthält die Adresse (`LG 1,R` und dann `L 2,TREC.B(1)`).
- Veränderte Register angeben: `end ['r1','r2'];` (ohne Liste gelten R0–R7 als verändert).
- **Reine Assembler-Routinen** (`assembler; asm … end;`, im Modus Delphi auch ohne
  `assembler`) werden nackte LLVM-Funktionen: kein Frame, Parameter und `RESULT` stehen für ihr
  XPLINK-Register (1. bis 3. Parameter R1–R3, Ergebnis R3), den Rücksprung `B 2(7)` ergänzt
  der Compiler. Sie dürfen nichts aufrufen (kein eigener Stack-Rahmen).
- Nicht möglich: Indexregister zusammen mit einer Variablen (`X(2)` ist die Länge), Literale
  (`=F'1'`), Sprünge zu Pascal-Marken, Aufrufe von Pascal-Routinen aus dem `asm`-Block.
- Test `asmtest.pas` (Parameter, Result, Schleife mit Marke, globale Variable, Konstante,
  var-Record mit Feldoffset, MVC/MVI/LA, reine Assembler-Funktion): 6/6 auf z/OS. Testsuite:
  tb0072 (s390x-Variante ergänzt), tb0142, tb0283, tb0444, test/opt/tcse1, tcse2 laufen;
  tb0193 hat keinen s390x-Zweig, tb0268 braucht die Unit `objects` (jetzt mit gebaut).
- Bau-Hinweis: Jede Änderung am Interface von `s390x/aasmcpu.pas` führte beim Übersetzen des
  Compilers zu unsinnigen Typfehlern um `treference` - Ursache waren veraltete `.ppu` in
  `compiler/s390x/units` (`make clean` räumt sie nicht weg). Die Texte liegen trotzdem in
  einer eigenen Unit (`hlasmtxt.pas`), `aasmcpu` bleibt unverändert.

## Lesezugriffe über nil (`-gc -gh`, FPC-Patch 0036, 28.09.2026)

Lesen ab Adresse 0 löst auf z/OS keinen Fehler aus: die PSA (8 KB) ist lesbar, ein Zugriff über
nil liefert still deren Inhalt. Schreibzugriffe dort scheitern wie gewohnt.

- Zum Suchen solcher Fehler: mit `-gc -gh` übersetzen (Zeigerprüfung mit heaptrc, vorher für
  z/OS gesperrt). Vor jedem Zugriff über einen Zeiger ruft das Programm dann `CheckPointer` auf:
  nil → Laufzeitfehler 204, andere Adressen in der PSA (unter X'2000', z. B. nil + Feldoffset)
  → 216, jeweils mit Backtrace und Zeilennummer. Alles andere gilt als gültig: statische Daten
  liegen im dynamisch angelegten WSA und C-Speicher kennt heaptrc nicht, eine genauere Prüfung
  wie unter Linux ginge daher nicht.
- Kostet einen Aufruf je Zugriff; nur für die Fehlersuche.
- Dabei behoben (nicht z/OS-spezifisch): `ncgmem` gab den Parameter des Prüfaufrufs vor
  `a_call_name` frei, der LLVM-Codegenerator schrieb den Aufruf dann ohne Argument
  (ungültiges IR, llc: "not enough parameters").
- Test `niltest.pas`: `ok` → rc 0 (Heap, global, Stack, malloc), ohne Argument → 204 in Zeile 39,
  `psa` → 216; ohne `-gc` rc 3 (nicht erkannt).
