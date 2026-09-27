# LLVM für den Pascal-Weg

Eigener Zweig `pascal-zos` (Worktree `~/src/llvm-pascal`) auf dem Zweig `zos-fixes`
(Stand `c854662c0`, LLVM 23.1.2 + z/OS-Korrekturen). Build:
`~/build/llvm-pascal` (nur SystemZ, Release + Assertions, wie `~/build/llvm-zos`; gebaut werden nur
`llc` und `opt`: `ninja llc opt`, cmake/ninja aus `~/opt/bt/bin`). FPC ruft beide über
`scripts/zos-irc` (Standard `ZOS_LLVM_BIN=~/build/llvm-pascal/bin`).

## Patches (`patches/`, auf `zos-fixes`)

| # | Inhalt | Herkunft |
|---|---|---|
| 0001 | Temporäre Labels in PR-Sektionen erlauben (DWARF-EH-Tabellen) | upstream `3c478e1` (#222435), Backport |
| 0002 | GOFF-Sektionen nicht wiederverwenden (eigenes C_WSA64 je Tabelle) | nach #225157 (offen), ohne Header-Änderung |
| 0003 | LSDA als eigenes SD im WSA (sonst IEW2353E ... 25000E beim Binden) | eigen, auf z/OS getestet |
| 0004 | ADA auch für Aliase von Funktionen (sonst falsches R5 → S0C4) | eigen, auf z/OS getestet |
| 0005 | Konstanten-Pool immer in die Code-Sektion ("relative immediate relocation section mismatch") | upstream `746d09a` (#222437), Backport |
| 0006 | Globale Variablen der Größe 0 bekommen 1 Byte (PR-Länge 0 = Referenz → unaufgelöst) | eigen, auf z/OS getestet |
| 0007 | Lit-Tests an 0003/0004 angepasst (zos-eh, zos-landingpad, zos-func-alias) | eigen |
| 0008 | Funktionszeiger in statischen Initialisierern: derselbe Deskriptor wie im Code (`VD(f@indirect)` für nicht-interne Funktionen), sonst sind `pf == f` falsch | eigen, auf z/OS getestet (C und Pascal) |

Kandidaten für upstream (Entscheidung beim Nutzer): 0003, 0004, 0006, 0008.
0008 ergänzt die Basis-Korrektur „function descriptor for external functions in initializers“
(`cd02b5ee0` auf `zos-fixes`, upstream PR llvm/llvm-project#226682): Seitdem sind Zeiger
aus Initialisierern aufrufbar, aber für externe Funktionen nicht gleich der im Code
genommenen Adresse (C-Test: `void f(void){} void (*pf)(void)=f;` → `pf != f`).

SystemZ- und GOFF-Lit-Tests (27.09.2026): 1279/1279 bestanden.

## Schnell-Build (nur noch bei Bedarf)

`scripts/llvm-quick-rebuild.sh <quelle>` übersetzt einzelne geänderte Quellen (ohne
Header-Änderungen) in `~/build/llvm-quick` (Kopie von `~/build/llvm-zos`) neu und linkt `llc`.
Nur für schnelles Ausprobieren, solange der volle Build fehlt;
`ZOS_LLVM_BIN=~/build/llvm-quick/bin` für zos-irc.
