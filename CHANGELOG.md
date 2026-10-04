# Änderungen

Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/), Versionen nach
[Semantic Versioning](https://semver.org/lang/de/) (Port-Version, `VERSION`; Ablauf
`PRODUKTION.md`). Vor 0.9.0 gab es keine Versionsnummern, die Meilensteine stehen unten.

## [Unveröffentlicht]

## [0.9.0] – noch ohne Tag

Erste Version mit Versionsnummer: Release-Stand, CI und Geschäftsdaten-Anbindung (PF8).

### Neu
- Versionierung: `VERSION`, `zfpc --version`, `ppcs390x -iZ`, Logo, `ZosPortVersion` in der
  RTL, Eyecatcher `ZPAS <version> FPC 3.3.1` (ASCII/EBCDIC) in jedem Programm, Kopfzeile im
  Start-Skript (FPC-Patch 0043).
- CI (`.github/workflows/ci.yml`, `scripts/ci-build.sh`): Patchserie anwenden, Compiler,
  RTL/Packages und Testprogramme übersetzen, Python-Skripte, portable Units auf x86_64;
  vorbereiteter z/OS-Job für einen Self-Hosted-Runner (`scripts/ci-zos.sh`).
- `PRODUKTION.md`: freigegebene Compilerschalter, Versionen, Release-Ablauf, CI-Einrichtung.
- EBCDIC-Codepages für Datasets und `zosebcdic` einstellbar (`ZOS_CCSID`, `,ccsid=NNN`,
  `SetDefaultCcsid`, `SetTextCcsid`; FPC-Patch 0044): 1047, 37, 273, 277, 278, 280, 284, 285,
  297, 500, 871, 1140–1149; Tabellen aus den ICU-Zuordnungen (`scripts/gen-ccsid.py`),
  portable Unit `zosccsid`.
- Unit `zosdecimal`: gepackte (COMP-3) und gezonte Dezimalzahlen, `TDecimal` mit Arithmetik
  ohne Gleitkomma, Prüfung wie S0C7; `zosdecimalbcd` (TBCD).
- `scripts/copybook2pas.py`: COBOL-Copybook → Pascal-Unit (packed records mit genauen
  Offsets, Get_/Set_, Stufe 88, OCCURS/ODO, REDEFINES, SYNC, HFP); Laufzeit-Unit `zoscobol`.
- Db2 ODBC/CLI: Unit `zosdb2cli` (CLI-Funktionen, `TDb2Connection`/`TDb2Statement`,
  `EDb2Error`), `zfpc --db2` (Sidedeck DSNAO64C, STEPLIB/DSNAOINI im Start-Skript),
  `ZOS_BATCH_STEPLIB`, Messprogramm `pf8/db2probe_c.c`, `pf8/db2test.pas`, JCL, DSNAOINI-Beispiel;
  Typgrößen auf z/OS noch nicht gemessen.
- AMODE 31 ↔ 64: Unit `zoscall31` mit eigenem Übergang (HLASM-Brücke `pf8/zpcall31.s` als
  Prozess, `runtime/zosc31.c`), COBOL → Pascal über LE CEL4RO64 (`pf8/zp64call.s`), Test-
  programme ZPASM1 (HLASM), ZPCOB1/ZPCOB2 (COBOL), `call64lib`; `ZOS_RUN_ENV` im Start-Skript.
  Auf z/OS noch nicht getestet.
- Tests: `pf8/dectest`, `ccsidtest`, `cobtest`, `call31test` (Attrappe), `db2test` (SQLite), `tests/` (Python, C-Prüfstand), CI-Schritt `x86`.
- z/OS-Skripte auch unter Linux ohne WSL (`scripts/zos-hostenv.sh`: ssh/sftp statt
  ssh.exe/sftp.exe).

### Korrigiert
- FPC-Patch 0042: `rtl/unix/cwstring.pp` ließ sich mit dem Start-Compiler FPC 3.2.2 nicht
  übersetzen (`{$elseif}` nach `{$ifdef}`).
- Skripte im Repo ausführbar (Dateimodus).

## Meilensteine vor 0.9.0

| Datum | Meilenstein |
|---|---|
| 27.09.2026 | PF0: Machbarkeit FPC → LLVM-IR → GOFF → z/OS |
| 27.09.2026 | PF1: echte `system`-Unit (17/17) |
| 27.09.2026 | PF2: Exceptions mit eigenem XPLINK-Unwinder, Basis-RTL |
| 27.09.2026 | PF4: Interop Pascal ↔ C, DLL, Batch/JCL, PDSE |
| 27.–28.09.2026 | PF3: FPC-Testsuite auf z/OS (tbs 772, tbf 317, webtbf 549, test 2025, webtbs 2696) |
| 28.09.2026 | PF5: C-ABI für Records, Backtraces mit Zeilennummern, HLASM-Inline-Assembler |
| 28.09.2026 | PF6: MVS-Datasets und DD-Anweisungen in der Pascal-Datei-E/A, VSAM (`zosrecio`) |
| 28.09.2026 | PF7: FPC-Packages (332 Units) |
| 29.09.2026 | Testsuite aus freien Quellen (`suite/`), Units mit Namensraum, z/OS-Debugger |
| 02.10.2026 | LLVM-Patch 0011 (Rahmenkopf bei stackrestore) |
