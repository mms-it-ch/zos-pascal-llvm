# PF4: DLL, PDSE, Batch/JCL

## Pascal-DLL (`library`)

```sh
sh ../scripts/zfpc pf4lib.pas      # -> $ZOS_DIR/libpf4lib.so + Sidedeck $ZOS_DIR/libpf4lib.x
sh ../scripts/zfpc pf4imp.pas      # external 'pf4lib' -> Sidedeck wird mitgebunden
./pf4imp                           # 4/4
sh ../scripts/zfpc pf4dyn.pas && ./pf4dyn    # LoadLibrary/GetProcedureAddress: 6/6
sh ../scripts/zfpc pf4exc.pas && ./pf4exc    # Ausnahme aus der DLL im Programm gefangen
```

- zos-ld bindet eine DLL mit `-x <name>.x` (Sidedeck mit IMPORT-Anweisungen) statt mit dem
  Einstieg CELQSTRT. ld hängt an ein vorhandenes Sidedeck an → vorher löschen.
- Exportiert werden nur die Symbole aus `exports`; alle anderen globalen Symbole sind
  `hidden` (GOFF SCOPE(LIBRARY)): FPC-Patch 0018. Ohne das exportierte jede DLL die ganze RTL.
- `external 'name'` → zos-ld sucht `lib<name>.x` in `$ZOS_DIR` und `$ZOS_DIR/lib` und bindet es
  mit; sonst stammt die Bibliothek aus der LE (c, pthread, …).
- Laufzeit: die DLL wird über `LIBPATH` gefunden (Start-Skript setzt `$ZOS_DIR:$ZOS_DIR/lib`).
- Initialisierung/Finalisierung der Units einer DLL laufen über C_@@SQINIT (`.xtor`), das LE
  beim Laden der DLL abarbeitet. Alle Einträge müssen in **einem** Teil liegen, sonst ruft LE
  eine falsche Adresse (S0C1) → LLVM-Patch 0009. Die C-Proben `cdll*_c.c` zeigen das auch mit
  clang (bei -O0; mit -O1 faltet clang den Konstruktor weg).
- Der Unwinder erkennt das Hauptprogramm an `FPC_SYSTEMMAIN` (ein schwaches `main` in der DLL
  wäre unaufgelöst).

## Library-Tests der FPC-Testsuite

tb0582, tlib1a, tlibrary1-3, tweaklib1/2, tw3402, tw34021, tw6822a/b, tw13628a/b laufen
(27.09.2026); tlib1b braucht DWARF-Zeileninfo (auf z/OS nicht vorhanden) → Plattformunterschied.
Dafür nötig:
- `dladdr` gibt es in der z/OS-C-Bibliothek nicht (LE-Stub bricht mit CEE3728S ab) →
  FPC-Patch 0020: `rtl/zos/dlzos.inc` meldet „nicht gefunden“.
- `weakexternal`: FPC schrieb Deklarationen nie als `extern_weak` (FPC-Patch 0021), LLVM
  machte `<f>@indirect` und Daten-PRs immer stark (LLVM-Patch 0010). C-Probe `weak_c.c`.
- Startskript: `ZOS_RUN_DLLS=1` verlinkt `$ZOS_DIR/lib*.so` ins Laufverzeichnis (Tests laden
  `./lib<name>.so`), `ZOS_RUN_CEEOPTS` setzt `_CEE_RUNOPTS`. Die Testsuite nimmt
  `TERMTHDACT(MSG)`: Tests, die den Stack zerstören (tb0662), führten beim LE-Traceback zu
  U4083 RSN F und einem Transaction-Dump-Dataset je Lauf (trotz DYNDUMP NODYNAMIC).

## PDSE und Batch

```sh
ZOS_PDS=PF4BAT sh ../scripts/zfpc pf4bat.pas          # zusätzlich nach $ZOS_PASLIB(PF4BAT)
sh ../scripts/zos-batch.sh PF4BAT "eins zwei"         # Job einreichen, Ausgabe + RC
sh ../scripts/zos-batch.sh -n PF4BAT                  # nur die JCL zeigen
```

- PDSE `ZOS_PASLIB` (in `.zos.env`, RECFM U, DSNTYPE LIBRARY).
- JCL: JOB-Karte mit `REGION=0M,LINES=500000`, STEPLIB = PDSE, `CEEOPTS` mit `POSIX(ON)`
  (ASCII-Programm), `PARM='/args'` (vor dem `/` stünden LE-Optionen), STDOUT/STDERR und
  SYSPRINT/SYSOUT als `DD PATH=` in USS-Dateien. Returncode per IF-Schritte + BPXBATCH
  (`STDPARM DD *`, sonst ist PARM zu lang), weil die Ausgabeklassen nicht gehalten sind.
- **Im Batch sind die Dateideskriptoren 0/1/2 nicht offen** (`pf4/batio_c.c`: fcntl → -1), nur
  die C-Streams hängen an den DDs. Die RTL schreibt über Deskriptoren → Ausgabe verloren.
  Abhilfe (FPC-Patch 0019, `runtime/zoscompat.c`): beim Start wird jeder geschlossene
  Deskriptor per `fopen("DD:STDOUT")` usw. geöffnet und mit `dup2` auf 0/1/2 gelegt (bei einer
  DD PATH hat der Stream einen echten Deskriptor). Unter z/OS UNIX ändert sich nichts.
- Ergebnis (27.09.2026): PF4BAT gibt Parameter, Format, gefangene Ausnahme aus, RC = 5.
