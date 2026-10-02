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
| 0003 | LSDA als eigenes SD im WSA (sonst IEW2353E ... 25000E beim Binden) | eigen, gemeldet: llvm/llvm-project#226804 |
| 0004 | ADA auch für Aliase von Funktionen (sonst falsches R5 → S0C4) | eigen, gemeldet: llvm/llvm-project#226799 |
| 0005 | Konstanten-Pool immer in die Code-Sektion ("relative immediate relocation section mismatch") | upstream `746d09a` (#222437), Backport |
| 0006 | Globale Variablen der Größe 0 bekommen 1 Byte (PR-Länge 0 = Referenz → unaufgelöst) | eigen, gemeldet: llvm/llvm-project#226800 |
| 0007 | Lit-Tests an 0003/0004 angepasst (zos-eh, zos-landingpad, zos-func-alias) | eigen |
| 0008 | Funktionszeiger in statischen Initialisierern: derselbe Deskriptor wie im Code (`VD(f@indirect)` für nicht-interne Funktionen), sonst sind `pf == f` falsch | eigen, als Kommentar zu PR llvm/llvm-project#226682 gemeldet |
| 0009 | Statische Initialisierer (C_@@SQINIT/`.xtor`): Klasse und Teile gemeinsam, alle Einträge eines Moduls in einem Teil (sonst S0C1 in LE `cxxctor` beim Laden einer DLL); Test `zos-xtor-one-part.ll` | eigen, Folge von 0002 (nicht upstream) |
| 0010 | Schwache Referenzen (`extern_weak`) bleiben schwach: `<f>@indirect` übernimmt „weak“, PR-Referenzen (externe Daten) bekommen die Bindungsstärke (sonst IEW2456E bei fehlendem Symbol); Test `zos-extern-weak.ll` | eigen, gemeldet: llvm/llvm-project#226835, PR #226840 |
| 0011 | `lowerSTACKRESTORE` (XPLINK): `@@ALCAXP` (dynamisches alloca) senkt R4 und kopiert den Rahmenkopf (Sicherungsbereich R4+2048) mit; Aufrufe bei gesenktem R4 überschreiben den alten Kopf, stackrestore setzte nur R4 zurück -> Epilog/LE-Stackwalk lasen überschriebene Register (U4083 RSN 0F). Jetzt Kopf von SP+2048 an den wiederhergestellten SP+2048 kopieren; Test `zos-stackrestore.ll` | eigen (aus dem Fortran-Zweig übernommen, 02.10.2026) |

Upstream gemeldet (27.09.2026): 0003 → #226804, 0004 → #226799, 0006 → #226800, 0008 → Kommentar zu PR #226682, 0010 → #226835 (PR #226840, Zweig `zos-extern-weak` im Fork, Review-Hilfe `llvm/pr/REVIEW-1.md`).
0009 → Kommentar zu PR #225157 (28.09.2026): ohne Zwischenspeicher der Sektionen zerfällt auch C_@@SQINIT;
beobachtet mit unserer Variante 0002, nicht mit dem PR-Zweig selbst.
0008 ergänzt die Basis-Korrektur „function descriptor for external functions in initializers“
(`cd02b5ee0` auf `zos-fixes`, upstream PR llvm/llvm-project#226682): Seitdem sind Zeiger
aus Initialisierern aufrufbar, aber für externe Funktionen nicht gleich der im Code
genommenen Adresse (C-Test: `void f(void){} void (*pf)(void)=f;` → `pf != f`).

SystemZ- und GOFF-Lit-Tests (27.09.2026): 1281/1281 bestanden (mit 0009, 0010).
Mit 0011 (02.10.2026): 1304 bestanden / 19 nicht unterstützt / 0 Fehler (1323 Tests;
`fixups.s` braucht `llvm-readelf` im Build: `ninja llvm-readelf`).

## Schnell-Build (nur noch bei Bedarf)

`scripts/llvm-quick-rebuild.sh <quelle>` übersetzt einzelne geänderte Quellen (ohne
Header-Änderungen) in `~/build/llvm-quick` (Kopie von `~/build/llvm-zos`) neu und linkt `llc`.
Nur für schnelles Ausprobieren, solange der volle Build fehlt;
`ZOS_LLVM_BIN=~/build/llvm-quick/bin` für zos-irc.
