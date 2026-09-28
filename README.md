# zos-pascal-llvm

Ziel: Pascal-Programme (Free Pascal, alle Modi inkl. Object Pascal/Delphi) lokal übersetzen und als
lauffähige z/OS-Binaries ausliefern – ohne IBM-Compilerlizenz.

## Ansatz

```
Pascal ──FPC (Port s390x/zos, nur LLVM-Backend)──▶ LLVM-IR ──llc (s390x-ibm-zos)──▶ GOFF ──z/OS ld/Binder──▶ Programm
```

- **Compiler:** Free Pascal `main` (3.3.1) mit neuem CPU-Port `s390x` und Target `zos`
  (Patchserie `fpc/patches/`, Basis FPC `main` 37b8a1a9).
- **RTL:** `rtl/zos` (libc-basiert wie AIX, Werte auf z/OS gemessen) + `rtl/s390x` (ohne Assembler),
  kleine C-Laufzeit des Ports in `runtime/`: eigener XPLINK-Unwinder (`zosunwind.c`) für die
  LLVM-Exceptions, atomare Operationen.
- **Backend:** eigener LLVM-Zweig (`llvm/`, LLVM 23.1.2 mit z/OS-Korrekturen, +10 Patches).
- **Laufzeitmodell:** ASCII-Modus, POSIX(ON), AMODE 64, XPLINK-64, LE. C-Funktionen über die
  ASCII-Einstiege (`zosmap.txt`, aus den z/OS-Headern erzeugt).

## Stand

| Meilenstein | Inhalt | Status |
|---|---|---|
| PF0 | Machbarkeit: FPC→LLVM-IR→GOFF→z/OS | erreicht 27.09.2026 |
| PF1 | echte `system`-Unit: writeln, Strings, Heap, Textdateien, halt | erreicht 27.09.2026 (`pf1/pf1test.pas`: 17/17) |
| PF2 | Exceptions (eigener XPLINK-Unwinder), Basis-RTL (sysutils, classes, math, strutils, dateutils, fgl, …) | **erreicht 27.09.2026** (`pf2/`: exctest 7/7, objtest 26/26) |
| PF3 | FPC-Testsuite auf z/OS | tbs 772, tbf 317, webtbf 549, test 2025, webtbs 2696 (Referenz x86_64: 777, 318, 547, 2039, 2696); Unterverzeichnisse von `test/`: 828/982 (Referenz 828/982) |
| PF4 | Interop Pascal ↔ C, DLL, Batch/JCL, PDSE | **erreicht 27.09.2026** (`pf4/`: Pascal-DLL implizit/dynamisch, Ausnahmen über die DLL-Grenze, Programm in PDSE als Batch-Job) |
| PF5 | C-ABI für Records (alle Größen, complex-artig, beide Richtungen) | **erreicht 28.09.2026** (`pf5/abi.pas` 27/27, Testsuite `test/cg/tcalext*`, `tcalpvr*` 12/12); Backtraces mit Funktionsnamen und mit `-gl` Zeilennummern (`pf5/bt.pas`); Inline-Assembler in HLASM-Syntax (`pf5/asmtest.pas` 6/6) |
| PF6 | MVS-Datasets und DD-Anweisungen in der normalen Pascal-Datei-E/A (Text mit EBCDIC-Umwandlung, binär), Batch mit SYSIN/SYSPRINT | **erreicht 28.09.2026** (`pf6/`) |
| PF7 | FPC-Packages: fcl-base, fcl-json, fcl-xml, fcl-process, fcl-net/Sockets, rtl-generics, hash, paszlib u. a., fcl-web, fcl-db, System V IPC (332 Units) | **erreicht 28.09.2026** (`pf7/pkgtest.pas` 18/18, `webtest` 3/3, `ipctest` 22/22) |

## Benutzung (WSL)

```sh
sh scripts/build-rtl.sh            # Compiler + RTL + Packages nach ~/opt/zfpc
sh scripts/zfpc prog.pas           # übersetzen, auf z/OS binden
./prog                             # startet das Programm auf z/OS (über SSH)
```

`zfpc` ruft `ppcs390x`; FPC ruft `clang` (= `scripts/zos-irc`, LLVM-IR → GOFF mit `llc`) und als
Linker `scripts/zos-ld` (lädt die Objekte hoch, bindet mit `ld` auf z/OS, hinterlässt ein
Start-Skript). Zugangsdaten: `.zos.env` im Repo (nicht versioniert).

## Werkzeuge

| Skript | Zweck |
|---|---|
| `scripts/build-rtl.sh` | Cross-Compiler, Port-Laufzeit, RTL-Units, `zosmap.txt` nach `~/opt/zfpc` |
| `scripts/zfpc` | Compiler-Aufruf mit den z/OS-Einstellungen |
| `scripts/zos-irc` | „clang“ für FPC: LLVM-IR → GOFF (llc, ggf. opt) |
| `scripts/zos-ld` | „Linker“ für FPC: Upload + `ld` auf z/OS + Start-Skript |
| `scripts/zos-sh` | Befehl in der z/OS-UNIX-Shell ausführen |
| `scripts/zos-batch.sh [-n] MEMBER [PARM]` | Programm aus der PDSE (`ZOS_PDS=MEMBER zfpc …`) als Batch-Job ausführen |
| `scripts/gen-zosmap.py` | C-Name → ASCII-Einstieg aus den z/OS-Headern |
| `scripts/gen-errno.py` | `rtl/zos/errno.inc` aus `errno.h` |
| `pf1/probe/zosprobe.c` | misst Typen, Layouts, Konstanten auf z/OS (Pascal-Ausgabe) |
| `scripts/goffdump.py [-v]` | GOFF-Objekte prüfen |
| `scripts/llvm-quick-rebuild.sh` | einzelne LLVM-Quellen schnell neu übersetzen |

## Lizenz

Wie Free Pascal: Port-Laufzeit, Skripte und Tests unter LGPL-2.1-or-later mit der
Ausnahme für statisches Binden der FPC-RTL (`COPYING.LGPL.txt`, `COPYING.FPC`) – damit
gebundene Programme dürfen unter beliebigen Bedingungen weitergegeben werden. Die
FPC-Patches (`fpc/patches`) folgen der Lizenz der geänderten FPC-Dateien (Compiler:
GPL-2.0-or-later, `COPYING.GPL.txt`; RTL: wie oben), die LLVM-Patches (`llvm/patches`)
der LLVM-Lizenz (Apache-2.0 WITH LLVM-exception). Details: `LICENSE`.
