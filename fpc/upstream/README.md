# Meldungen an Free Pascal (zum Einreichen)

Allgemeine FPC-Fehler, gefunden beim z/OS-Port, aber nicht z/OS-spezifisch. Je Datei ein
Issue-Text für das FPC-GitLab (https://gitlab.com/freepascal.org/fpc/source/-/issues), englisch,
mit Reproduzierer und Patch. Einreichen muss der Nutzer (hier kein GitLab-Zugang); jeder Text
trägt den Hinweis auf Claude Code.

Die Patches in `patches/` sind eigenständig und gegen FPC `main` b19181d6 (28.09.2026) erstellt
(Zweig `upstream-fixes`, Worktree `~/src/fpc-upstream`); dort übersetzen der Compiler (normal und
LLVM=1, x86_64) und die geänderten Units. Jeder Patch passt allein auf `main`.

| Datei | Fehler | Patch | Nachweis |
|---|---|---|---|
| `01-llvm-weakexternal.md` | LLVM: `weakexternal` wird nicht `extern_weak` | 0001 | x86_64-linux LLVM: vorher „undefined reference“, nachher läuft |
| `02-llvm-nested-capturer.md` | LLVM: anonyme Funktionen + lokale Routinen (zwei Fehler) | 0002, 0004 (Teil) | x86_64-linux LLVM: tanonfunc27/56/60/69 RC 216 → 0, tfuncref26/48 RC 3 → 0 |
| `03-generated-code.md` | Intern erzeugter Code: Interface-Wrapper, Call-through | 0003 | x86_64-linux LLVM: tw9306a/b, tw39736 übersetzen nicht → laufen |
| `04-bigendian.md` | Big-Endian: bitgepackte Int64-Konstanten, fmtbcd Int128, SetToArray | 0004 (Teil), 0005, 0006 | s390x (z/OS): tw36156, test/units/fmtbcd, trtti24 |
| `05-process-exitcode.md` | fcl-process: `ExitCode` nach `WaitOnExit` immer 0 | 0007 | x86_64-linux, normaler Codegenerator: 0 → 3 |

Reproduzierer: `repro/` (`weakext.pp`, `exitcode.pp`, `run-x64.sh` für den LLVM-Codegenerator auf
x86_64). Die übrigen Nachweise sind Tests der FPC-Testsuite.

Nicht gemeldet (im Port behoben, aber nicht allgemein nachgestellt): safecall-Ergebnis und
Resourcestrings in typisierten Konstanten im LLVM-Pfad (Patches 0011/0012 des Ports; `tstring3`
läuft auf x86_64 LLVM), Record-Parameter mit mehr als zehn Locations (0024), mehrere
FPU-Locations eines Records in `gen_load_loc_cgpara` (0022) - beides tritt auf x86_64 nicht auf.
