# Projektkontext für Claude Code

Pascal-Compiler für z/OS: lokal übersetzen (Free Pascal + LLVM), auf z/OS binden und ausführen.

## Getroffene Entscheidungen (Nutzer-Signoff 27.09.2026)
- **Frontend: Free Pascal mit LLVM-Backend (Plan B)**, nicht p2c und kein eigenes Frontend.
  Grund: modernes Object Pascal (alle FPC-Modi). Keine Kundenquellen in Pascal vorhanden.
- **Basis FPC `main` (3.3.1)**, eigener Zweig `zos` in `~/src/fpc`, Patchserie in `fpc/patches/`
  (Basis-Commit 37b8a1a9). Autor der Commits: `mms-it-ch <info@mms-it.ch>`, Trailer
  `Assisted-by: Claude Code (Anthropic)` (wie bei den LLVM-Patches).
- **Nur LLVM-Modus** für s390x, kein nativer s390x-Codegenerator.
- **ASCII-Modus + POSIX(ON) + AMODE 64.**
- **Eigenes Repo** (dieses).

## Stand
- **PF0 erreicht (27.09.2026):** `pf0/minrtl/hello.pas` (Mini-System-Unit) → `ppcs390x` → IR →
  `~/build/llvm-zos/bin/clang` → GOFF → `ld` auf z/OS: Ausgabe korrekt, RC 42.
- Compiler-Port (`fpc/patches/0002`): `compiler/s390x/*` (cpubase, cpuinfo, cpupara = XPLINK-64
  nach clang `ZOSXPLinkABIInfo`, Stubs für cgcpu/hlcgcpu/aasmcpu), `systems/i_zos.pas`,
  `systems/t_zos.pas`, Triple `s390x-ibm-zos`, Datenlayout von clang.
  Bau: `make -C ~/src/fpc/compiler LLVM=1 PPC_TARGET=s390x FPC=~/opt/fpc-main/bin/ppcx64`.
  **Achtung:** `make` erkennt Änderungen nicht immer → vorher `rm compiler/ppcs390x`.
- Erkenntnisse:
  - Im LLVM-Modus braucht FPC trotzdem alle CPU-Units; der CPU-Codegenerator wird nur für reine
    Assembler-Prozeduren instanziiert (hlcgllvm `create_hlcodegen_llvm`).
  - FPC gibt Symbole als `@"\01name"` aus → Patch 0008 (CELQMAIN) fand `main` nicht. Für z/OS
    ohne `\01` (llvmdef `llvmmangledname`), dann CELQMAIN/CELQINPL/CELQBST automatisch.
  - Ordinal-Paraloc größer als Typ ⇒ FPC schreibt `signext`/`zeroext` (XPLINK verlangt 64 Bit).
  - C-Funktionen brauchen im ASCII-Modus die gemappten Namen (`puts` → `@@A00304`); die RTL muss
    die Zuordnung aus den z/OS-Headern übernehmen (`scripts/gen-zosmap.py`).
  - Struct-Rückgabe an C (z. B. `div_t`) noch nicht C-kompatibel: FPC gibt Records über
    verstecktes Ergebnis zurück, clang über `inreg [N x i64]` in GPR1-3. Offen.
  - FPC-`main` mit `-Clv17.0` (höchste bekannte Version) funktioniert mit LLVM 23.
  - x86-Gegenprobe (FPC-LLVM, x86_64-linux, clang 23): läuft, Exceptions scheitern dort am
    Linken (`.eh_frame_hdr` überlappende FDEs) – nicht z/OS-relevant.
- **Exceptions:** FPC-LLVM nutzt immer invoke/landingpad (`tf_use_psabieh`); LLVM legt auf z/OS
  Personality + LSDA im PPA1 ab. Upstream-libunwind kann z/OS nicht. IBM Open XL (auf dem System,
  lizenzpflichtig) wird NICHT benutzt. Lösung: eigener XPLINK-Unwinder `runtime/zosunwind.c`.

- **PF1 erreicht (27.09.2026):** `pf1/pf1test.pas` mit echter RTL auf z/OS: 17/17 OK, rc=0
  (Zahlen/Gleitkomma, AnsiString, Heap, Textdateien, ParamStr). Entscheidung Exceptions:
  **Option A (eigener XPLINK-Unwinder)**, Nutzer-Go 27.09.2026.
- Toolchain: `scripts/build-rtl.sh` → `~/opt/zfpc` (ppcs390x, `clang`=zos-irc, `zos-ld`,
  Units + GOFF in `units/zos`, `zosmap.txt`). `scripts/zfpc prog.pas` bindet auf z/OS und
  hinterlässt `./prog` als Start-Skript (läuft per SSH auf z/OS). USS-Verzeichnis `…/ZPAS`
  (eigenes ZFS, 360 MB; in `.zos.env`: `ZOS_DIR=${ZOS_DIR%/*}/ZPAS`). zos-ld/zos-sh laufen in WSL mit `ssh.exe`/
  `sftp.exe` von Git für Windows (Schlüssel liegt unter Windows; `.zos.env` nutzt `$HOME` →
  beim Einlesen HOME = Windows-Profil in msys-Form). Upload per tar+sftp (stdin-Pipe über
  ssh.exe verfälscht Binärdaten: pax "checksum error").
- **LLVM (`llvm/`):** eigener Zweig `pascal-zos` (Worktree `~/src/llvm-pascal`, auf
  `zos-fixes`: LLVM 23.1.2 + z/OS-Korrekturen), 6 Patches, Details `llvm/README.md`. Build
  `~/build/llvm-pascal` (`ninja llc opt`, cmake/ninja aus `~/opt/bt/bin`), Standard für zos-irc.
  Gefundene LLVM-Fehler: LSDA-Platzierung (IEW2353E 25000E), Aliase ohne ADA (S0C4 bei Aufruf
  über Alias), Globals der Größe 0 (PR-Länge 0 = Referenz → unaufgelöst).
- **RTL-Erkenntnisse:** z/OS-Werte weichen stark ab (O_RDONLY=2, F_OK=8, S_IFMT=$FF000000,
  SIGABRT=3, errno ab 111, struct stat mit Eyecatcher, timeval mit Füllbytes) → immer per
  `pf1/probe/zosprobe.c` auf z/OS messen, nie von anderen Unixen übernehmen. mmap kann kein
  MAP_ANONYMOUS (erst ab z/OS 3.1 mit __XPLAT) → Heap über malloc. errno = `__errno()`. Mathe-Funktionen gehen auf die
  IEEE-Einstiege (`sin` → `@@SSIN@B`, über zosmap). Inline-Asm in clang für z/OS ist HLASM:
  Befehle mit führendem Leerzeichen (Spalte 1 = Label).
- **Für den Unwinder (PF2) ermittelt:** Prolog `stmg 5,15,1800(4)`, `aghi 4,-DSA` → Sicherung
  R5..R15 im eigenen Frame ab R4+2048+8 (R7 = Rücksprung bei +24); Aufrufer-R4 = R4+DSA-Größe
  (Entry Point Marker vor der Funktion: Eyecatcher 00C300C500C500F1, Offset PPA1, DSA-Größe).
  PPA1-EH-Block: Personality und LSDA als ADA-Displacements. Landing Pad: Exception-Zeiger R1,
  Selektor R2 (XPLINK64). LSDA-Call-Sites relativ zum Funktionsanfang. LE-Traceback-Dienst
  `__le_traceback(__TRACEBACK_FIELDS, …)` liefert Einsprung/Aufrufer-DSA (nicht benutzt).
  Tatsächliches EPM-Format: 16 Byte (Eyecatcher 8, PPA1-Offset 4, DSA/Flags 4), Einsprung = EPM+16.
  Funktionen mit Landing Pads sichern R5 immer. Personality-ADA-Slot = Zeiger auf Deskriptor
  (= C-Funktionszeiger), LSDA-Slot = Adresse. FPR-Sicherung: Locator R4+Offset, F8 zuerst.
- **PF2 erreicht (27.09.2026):** Exceptions über eigenen Unwinder (`pf2/exctest.pas` 7/7:
  Klassenauswahl, verschachtelt, Tiefe 5, finally, raise;, FPR erhalten, 1000×), Basis-RTL
  (`pf2/objtest.pas` 26/26: sysutils, classes, math, strutils, dateutils, fgl, Interfaces,
  Streams), unbehandelte Exception → Meldung + rc 217. Dabei behoben:
  - FPC-LLVM: typisierte Landing Pads bekommen ein catch-all (sonst findet Phase 1 den äußeren
    Handler derselben Funktion nicht; vermutlich allgemeiner FPC-Fehler, nur für z/OS geändert).
  - Resourcestrings: Binder hält die Reihenfolge der Datenparts NICHT ein (getestet:
    `pf2/order/order.ll`) → START..END-Iteration unmöglich; Compiler erzeugt je Unit
    `RESSTR_$unit_$$_PTRLIST`, RTL iteriert darüber (`FPC_RESSTR_PTRLIST`). Grundsätzlich: auf
    z/OS nie auf Nachbarschaft/Reihenfolge von Globals verlassen.
  - Parameter: Records/Sets mit 1/2/4 Byte als Ganzzahl dieser Größe (Big-Endian-Lage), andere
    Pascal-Record-Größen per Referenz; "complex-like"-Records vorerst nicht in FPRs (TODO für
    C-Interop, ebenso Struct-Rückgabe und C-Records mit ungeraden Größen).
  - RTL: futimens/flock/sys_errlist fehlen auf z/OS; statvfs gemessen; math-FPU-Modi fest (TODO fenv).
- **PF3 Gleitkomma/Signale (27.09.2026):** `pf3/fputest.pas` 10/10, `pf3/sigexc.pas` 4/4.
  - FPU-Steuerwort = FPC-Register (`efpc`/`sfpc`, `runtime/zosfpu.c`): Masken 0x80 invalid,
    0x40 zerodiv, 0x20 overflow, 0x10 underflow, 0x08 inexact (obere 8 Bit), Flags 0x00F80000,
    DXC 0x0000FF00, Rundung untere 2 Bit. SysInitFPU schaltet invalid/zerodiv/overflow scharf.
  - **struct sigaction auf z/OS:** `sa_handler` (+0) und `sa_sigaction` (+24) sind getrennte
    Felder, keine Union → RTL ruft `FPC_ZOS_SIGACTION` (`runtime/zoscompat.c`), sonst kommt
    SIGFPE nie beim Pascal-Handler an. SIGFPE-si_code: INTDIV 31 … FLTSUB 38 (zosprobe).
  - **Exception aus Signal:** direkt im Handler auslösen geht nicht (Unwinder kommt nicht durch
    die LE-Zustellframes → Endlosschleife). Stattdessen `FPC_ZOS_SIGREDIRECT`
    (`runtime/zossig.c`): Kontext so ändern, als hätte die Fehlerstelle HandleErrorAddrFrame
    gerufen (R1..R3 Argumente, R5/R6 aus Deskriptor, R7 = PC−2, PSW = Einsprung, FPC-Flags/DXC
    löschen), dann **`setcontext`** – normale Rückkehr aus dem Handler ignoriert LE bei
    Programmunterbrechungen (CEE3224S, rc 136). mcontext_t (nur `long[85]`) gemessen mit
    `pf3/ctxprobe.c`: GPR +0x80, FPR +0x140, FPC +0x1C0, PSW-Maske +0x228, PSW-Adresse +0x230.
  - Funktioniert, weil FPC-LLVM jeden try-Block mit Dummy-Invokes (FPC_DUMMYPOTENTIALRAISE)
    einrahmt → die Fehlerstelle liegt in der Call-Site-Spanne. Lesen über nil löst auf z/OS
    nichts aus (Adresse 0 = PSA, lesbar); Schreiben → EAccessViolation.
  - Diagnose: `ZOS_UNWIND_DEBUG=1` zeigt auch Signal-Umleitungen mit Funktionsnamen (aus dem
    PPA1, `FPC_ZOS_FUNC_NAME`); `ZOS_KEEP_MAP=1` lässt die Binder-Map `$ZOS_DIR/<prog>.map` liegen.
- **Threads (27.09.2026):** `pf3/thrtest.pas` (4 Threads, Critical Section, Join) ok.
  **Nur die POSIX-Thread-API (`_UNIX03_THREADS`) benutzen:** ohne sie (oder mit `_OPEN_THREADS`)
  binden die unmappten Namen die alte IBM-API mit anderen Signaturen (z. B.
  `int pthread_getspecific(key, void**)`) → S0C4 in der LE. Mit `_UNIX03_THREADS`: Einstiege
  `@@PT3…`/`@@PT8GS` (zosmap), `pthread_mutex_t`/`pthread_cond_t` 64 Byte, Mutex-Typen NORMAL 4,
  ERRORCHECK 0, RECURSIVE 1 (`pf3/thrprobe.c`). `pthread_attr_setinheritsched/setscope` gibt es
  auf z/OS nicht.
- **C-ABI Record-Ergebnis (27.09.2026):** XPLINK gibt C-Aggregate bis 24 Byte in GPR 1, 2, 3 zurück
  (clang: `inreg [n x i64]`; der SystemZ-Backend nimmt R1..R3 nur bei `inreg`, sonst R3, R2, R1).
  FPC: cpupara `c_record_in_regs` (Größen 8/16/24, cdecl, nicht complex-like), llvmdef
  `llvm_ret_inreg` schreibt `inreg` in Deklaration und Aufruf. Test `pf3/cret.pas` (+ `cret_c.c`,
  auch C ruft Pascal). Offen: andere Größen (linksbündig im letzten Register), complex-like in FPRs.
  Betraf `pthread_self` (pthread_t = 8-Byte-Struktur) → falsche Thread-IDs (tb0678).

## Nächste Schritte
1. PF3: FPC-Testsuite (`~/src/fpc/tests`) auf z/OS. **tbs (27.09.2026): 772/784 ok, Referenz
   x86_64-linux 777/784.** Nur z/OS: 5 × Inline-Assembler (LLVM-Ziel ohne Assembler-Leser),
   tb0582 (library → PF4), tb0662 (Testfehler: `@I` Integer als PSizeInt, auf Big-Endian
   riesige Länge). **tbf 316/319 (Ref. 318), webtbf 546/554 (Ref. 547)**: tb0110 (skipcpu ohne
   s390x), uw40621 (Hilfs-Unit); tb0265 war ein Absturz im FPC-LLVM-Codegenerator (behoben,
   Patch 0010). Weiter: test, webtbs. `fpc-testsuite.sh -r` wiederholt nur
   gescheiterte Tests; dotest läuft mit `-L` (sonst Wettlauf um `out.`/Logs bei `-P`, Einträge
   gehen verloren). Referenz-Wrapper ohne `-FU` (sonst Unit-Tests „Failed to run“, Exit 2000).
   z/OS-Platz: ZPAS-ZFS 360 MB; zos-ld bindet erst ab 60 MB frei (`ZOS_MIN_FREE_KB`).
2. Offene TODOs: C-ABI Record-Ergebnis anderer Größen und complex-like Records, Backtraces
   (get_caller_addr), DLL/PDSE/Batch (PF4; tb0582 = library).

## Arbeitsweise
- **JCL: JOB-Karte immer mit `REGION=0M,LINES=500000`.**
- **Host und User-ID nie ins Repo schreiben**; Zugangsdaten nur in `.zos.env` (nicht versioniert).
  Eigenes USS-Verzeichnis `…/ZPAS` mit eigenem ZFS (getrennt von anderen Verzeichnissen und vom Home-ZFS, das der Testlauf am 27.09.2026 einmal vollgeschrieben hat). Bei Ausgaben von
  Remote-Befehlen Host/User maskieren (sed), sie landen sonst im Sitzungsprotokoll.
- `~/src/llvm-project` und `~/build/llvm-zos` gehören nicht zu diesem Projekt: nicht ändern
  (nur den clang aus `~/build/llvm-zos` für `runtime/*.c` benutzen).
- Nutzer schreibt Deutsch; Antworten auf Deutsch.
- Lokaler Pfad: `C:\Users\marce\Documents\GitHub\zos-pascal-llvm` (Windows), Quellen/Builds in WSL.
