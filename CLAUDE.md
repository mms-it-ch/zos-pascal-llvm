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
  `zos-fixes`: LLVM 23.1.2 + z/OS-Korrekturen), 8 Patches, Details `llvm/README.md`. Build
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
  auch C ruft Pascal). **Vollständig seit FPC-Patch 0022 (28.09.2026, PF5, `pf5/README.md`):** alle
  Größen ≤ 24 Byte linksbündig in GPRs, complex-like in FPR 0/2 (Ergebnis und Parameter),
  Parameter immer volle 64-Bit-Slots linksbündig. `pf5/abi.pas` 27/27, test/cg tcalext*/tcalpvr* 12/12.
  Achtung: `test/cg` (und andere Unterverzeichnisse von `test/`) lief in PF3 nicht mit.
- **Testsuite-Unterverzeichnisse von `test/` (28.09.2026, 58 Verzeichnisse, 982 Tests):** z/OS
  828/982 = Referenz 828/982; kein Dump (Wächter zählte die Dump-Datasets). Dabei behoben:
  FPC-Patch 0024 (Record-Wertparameter beliebiger Größe: Slot-Liste war auf 10 begrenzt;
  `array of const` bei cdecl-Varargs: Compiler-Absturz), 0025 (statvfs statt statfs, FileSetDate
  per Handle über futimes, ENOTEMPTY -> 5), 0026 (fmtbcd Int128 auf Big-Endian, allgemein),
  RTL-Units unicodedata/character (test/units/character 36/36), C/C++-Objekte für test/cg
  (clang/clang++). Nur z/OS: tcse1/2 (Inline-Assembler, seit Patch 0035 ok), tfmtbcd (3: Literal ohne Extended),
  tstrutils2 (UTF-8), tiorte (rmdir('..') -> EINVAL statt ENOTEMPTY, POSIX erlaubt beides),
  tfile2 (fcntl-Sperren prozessweit). Aufruf: `fpc-testsuite.sh $(cat ~/subdirs.txt)`.
- **PF7 Packages (FPC-Patches 0028/0029, 28.09.2026, `pf7/README.md`):** `build-packages.sh`
  (am Ende von build-rtl.sh): 219 Units, zweiter Durchgang als Hilfs-Unit mit -B (sonst
  "checksum changed"). Semaphoren nachgebildet (zoscompat.c, sem_t = Zeiger), Sockets
  (rtl-extra/src/zos, gen-sockh.py, SOCK_HAS_SINLEN, addrinfo ai_eflags), Pipes: FIONREAD geht
  nicht -> fstat st_size. Kindprozesse schreiben EBCDIC -> Unit zosebcdic. pkgtest 18/18.
- **PF6 MVS-Datasets (FPC-Patch 0027, 28.09.2026, `pf6/README.md`):** Namen `//'DSN'`, `//NAME`,
  `DD:NAME` gehen in sysfile.inc an die C-Streams (`runtime/zosdsn.c`, eigene Handles ab
  X'7F000000'); Text = Textmodus + ISO-8859-1<->IBM-1047 (LF<->X'15'), binär = Bytestrom.
  Stolpersteine: fileno = -1 bei Datasets; `"w"` legt ein vorhandenes Dataset mit
  Standardattributen neu an (-> `recfm=*`); Satzmodus füllt FB mit X'00' (-> Textmodus);
  `fopen("DD:X")` gelingt ohne DD (-> TIOT prüfen); fileno ist für DD:SYSPRINT >= 0 (->
  fldata __dsorgHFS). Batch: STDIN/SYSIN, STDOUT/SYSPRINT, STDERR. `zos-batch.sh`:
  `ZOS_BATCH_DD` (weitere DDs, `@HLQ@`), `ZOS_BATCH_CEEOPTS`. Test-Datasets `<Präfix>.ZPAS.TEST.*`.
- **Backtraces (FPC-Patch 0023, 28.09.2026, `pf5/README.md`):** get_caller_addr/-frame über den
  LE-Dienst `__le_traceback` (DSA = R4 = get_frame - 2048), Ende bei FPC_SYSTEMMAIN bzw. LE,
  Namen aus dem PPA1 in BackTraceStrFunc. Eigener EPM-Schritt scheiterte am Thread-Stack-Ende
  (ungültiges R7 -> Speichersuche -> SIGSEGV). raise: Label-Adresse + 1. ~11 µs je Ausnahme.
  Betraf `pthread_self` (pthread_t = 8-Byte-Struktur) → falsche Thread-IDs (tb0678).
- **Umgebung:** LE ruft `main` nur mit argc/argv auf, ein dritter Parameter ist Zufall →
  `envp` aus `environ` (`FPC_ZOS_ENVIRON`, im ASCII-Modus `*__EnvnA()`); sonst S0C4 in heaptrc.
- **Funktionszeiger-Gleichheit (LLVM-Patch 0008):** Code nimmt die Adresse externer Funktionen
  über `VD(f@indirect)` (Deskriptor vom Binder), statische Initialisierer bekamen einen eigenen
  ADA-Deskriptor → `@f` ≠ Konstante (auch in C). Betraf Methodenzeiger in typisierten Konstanten.
  Test `pf3/pvconst.pas`, `pf3/fpeq_c.c`.
- **Nicht-lokales goto / setjmp (FPC-Patch 0012):** `fpc_setjmp`/`fpc_longjmp` und die
  öffentlichen `setjmp`/`longjmp` sind die der C-Bibliothek (`jmp_buf` = long[128]); der Name
  `setjmp` lässt agllvm `returns_twice` setzen. tisogoto*, tmacnonlocal*, tintuint laufen.
- **Resourcestrings in typisierten Konstanten (FPC-Patch 0012):** allgemeiner FPC-LLVM-Fehler
  mit opaken Zeigern: Zeiger→Zeiger-Umwandlung wurde weggelassen, das GEP nahm den Typ der
  Variablen (`[2 x ptr]`) statt `[n x i8]` → Byte-Offset als Elementindex (tstring3).
- **Codepages/iconv:** z/OS-iconv kennt Windows-Codepages nur als CCSID (1252/1253 ohne Euro,
  mit Euro 5346..5354 = cp+4096), UTF-16 = 1200, UTF-32 = 1232, kein `//TRANSLIT`. cwstring
  angepasst (`pf3/cptest.pas`, `pf3/iconv_c.c`). **Systemcodepage im ASCII-Modus immer
  ISO-8859-1 (28591)**, auch mit UTF-8-Locale (LANG wird für 64-Bit-ASCII abgelehnt) → Tests,
  die eine UTF-8-Konsole voraussetzen (Referenz läuft mit C.UTF-8), sind Plattformunterschiede.
- **Atomare Operationen:** direkte C-Helfer (`__atomic_*`); 10 Mio. InterLockedIncrement in
  58 ms (`pf3/atomperf.pas`). tatomicmt/tinterlockedmt: 12 Compare-Exchange-Threads (6 Paare,
  Übergabe per sched_yield) werden in 60 s nicht fertig → Scheduler-/Last-Frage, kein Fehler.
- **Anonyme Funktionen + lokale Prozeduren (FPC-Patch 0013):** allgemeiner FPC-LLVM-Fehler: die
  Capturer-Variable wird erst nach dem Typecheck in die parentfpstruct verschoben, Loads blieben
  beim alten (nie beschriebenen) Temp → pass_1 leitet nachträglich um (tanonfunc27/56/60/69,
  tstatementexpr39).
- **FPC-Patches 0014-0016 (28.09.2026):** generierter Code (Call-through ohne Unit-Präfix,
  gültige Redirect-Namen, Interface-Wrapper intern + Aufruf über Typecast auf Elternklasse),
  Big-Endian (Bitpacked-Int64-Konstanten, SetToArray), Capturer + lokale Prozeduren
  (Capturer vorab in parentfpstruct, `tcgprocinfo.move_capturer_to_parentfpstruct`), neue
  Threads übernehmen FPU-Maske (DefaultFPUControlWord), Event-Mutex nicht rekursiv
  (z/OS: pthread_cond_timedwait scheitert sofort mit rekursivem Mutex).
- **Verbleibende Fehler, eingeordnet:** Plattform: Inline-Assembler (7; seit Patch 0035 bis auf tb0193 ohne s390x-Zweig ok), DLL/library (PF4, 7),
  Lesen über nil (tabsvr6/7, tw9073), fcntl-Sperren prozessweit (tw27998, wie AIX/Solaris),
  UTF-8-Konsole (twide3/6, tunistr6, tcpstr27), Little-Endian-Annahme (tw41210a), Codegröße
  zwischen Labels (tw39785, tw38267b), /etc/host* (tw1255), Scheduler (tatomicmt u. a.),
  Stack-Prüfung {$S+}/-Ct: seit FPC-Patch 0033 umgesetzt (28.09.2026, tw40598 und tstack
  bestehen: Laufzeitfehler 202 statt Stackwachstum bis zum CPU-Limit), Testfehler Big-Endian (tb0662: @Integer als PSizeInt). Allgemeine FPC-Fehler
  ohne x87 (Currency: tw40550, tw41865g/h bei -O4). FPC-LLVM-Grenze: tsuperregister 16 Bit,
  eine Prozedur mit ~13000 Zeilen braucht mehr virtuelle Register (tw2242).
- **FPC-Patch 0017 / Skripte (28.09.2026):** `-k`-Optionen gehen über zos-ld an ld (testlderror);
  `%FILES` der Tests: fpc-testsuite.sh setzt `ZOS_RUN_FILES`, das Startskript lädt die Dateien
  per sftp ins Laufverzeichnis (tw37415).
- **Testsuite-Stand (28.09.2026, nach Patch 0016):** tbs 772/784 (Ref. 777), tbf 317/319
  (318), webtbf 549/554 (547), test 2025/2073 (2039), webtbs 2696/2765 (2696). Nur z/OS: 41.
- **safecall (FPC-Patch 0011):** allgemeiner Fehler im FPC-LLVM-Pfad: `sret` + HRESULT-Ergebnis,
  falsche Erweiterung in der Deklaration, HRESULT per Speicher kopiert (Big-Endian: falsche Hälfte).

- **PF4 erreicht (27.09.2026), Details `pf4/README.md`:** Pascal-DLL (`library`) mit
  Sidedeck (`zos-ld dll`: `-x <name>.x`, altes Sidedeck vorher löschen, ld hängt sonst an),
  `external 'x'` bindet `libx.x` mit, LIBPATH im Start-Skript. Nur `exports` wird exportiert
  (FPC-Patch 0018: sonst `hidden` = SCOPE(LIBRARY)). S0C1 in LE `cxxctor` beim Laden der DLL:
  LLVM-Patch 0002 verteilte die `.xtor`-Einträge auf mehrere gleichnamige Teile → Patch 0009.
  Unwinder erkennt main über `FPC_SYSTEMMAIN` (schwaches `main` war in DLLs unaufgelöst).
  PDSE `ZOS_PASLIB` (`.zos.env`), `ZOS_PDS=MEMBER zfpc`, Batch per `scripts/zos-batch.sh`.
  **Im Batch (JCL, POSIX(ON)) sind fd 0/1/2 geschlossen**, nur C-Streams gehen an die DDs →
  FPC-Patch 0019: `FPC_ZOS_BATCH_STDIO` öffnet DD:STDIN/STDOUT/STDERR und legt sie per dup2
  auf 0/1/2. JCL-Zeilen ≤ 71 Spalten (PATHOPTS umbrechen), BPXBATCH mit STDPARM statt PARM.
- **Library-Tests (27.09.2026):** 13/14 laufen (tlib1b: DWARF-Zeileninfo). FPC-Patch 0020 (dladdr
  auf z/OS nur LE-Stub → CEE3728S), 0021 (weakexternal → `extern_weak`), LLVM-Patch 0010 (weak
  über `@indirect` und Daten-PR). Startskript: `ZOS_RUN_DLLS`, `ZOS_RUN_CEEOPTS`.
- **Vorsicht Dumps:** Abstürze mit zerstörtem Stack enden mit U4083 RSN F und je einem
  Dump-Dataset `<USERID>.Dddd.Thhmmsst.Ppid` unter der User-ID (DYNDUMP ist NODYNAMIC, hilft
  nicht). **Auch `TERMTHDACT(MSG)` verhindert das nicht** (Probe `pf3/stackcrash.pas`,
  28.09.2026: trotzdem ein Dataset). Die Testsuite setzt es trotzdem (kein Traceback), aber
  Läufe mit möglichen Abstürzen nur nach Rücksprache mit dem Nutzer; `pf3/stackcrash` nie
  ohne Grund starten. tb0662 selbst endet inzwischen sauber (EOutOfMemory, RC 217).

- **PF8 Produktion (04.10.2026, Cloud-Sitzung ohne z/OS-Zugang, `pf8/README.md`, `PRODUKTION.md`):**
  Version 0.9.0 (`VERSION`, `ppcs390x -iZ`, `ZosPortVersion`, Eyecatcher; FPC-Patch 0043), CHANGELOG.md.
  FPC-Patch 0042: cwstring mit FPC 3.2.2 als Start-Compiler. CI `.github/workflows/ci.yml` =
  `scripts/ci-build.sh` (Patches 45/45 auf `fpc/BASE`, `make cycle` mit 3.2.2, ppcs390x, RTL +
  340 Package-Units mit Distributions-llc 18 (`ZFPC_CI=1`: ohne runtime/*.c und zosmap; GOFF
  nur Gerüst, `library` stürzt in llc 18/20 ab → übersprungen), pf-Programme `-Cn`, Python,
  x86-Tests); GitHub-Job ~3 min. z/OS-Job für Self-Hosted-Runner (`vars.ZOS_RUNNER`, Secrets),
  Skripte dafür auch ohne WSL (`scripts/zos-hostenv.sh`). Skripte waren im Repo nicht ausführbar.
  CCSID (FPC-Patch 0044, `runtime/zosdsn.c`, `ZOS_CCSID`, `,ccsid=NNN`, 21 CECP-Codepages aus ICU,
  `scripts/gen-ccsid.py`), `rtl/` im Repo für eigene Units (zosccsid, zosdecimal, zosdecimalbcd,
  zoscobol, zosdb2cli, zoscall31; build-rtl.sh baut sie mit), `scripts/copybook2pas.py`, Db2 CLI
  (`zfpc --db2`, Typgrößen NICHT gemessen → `pf8/db2probe_c.c`), AMODE 31: eigener Brückenprozess
  `pf8/zpcall31.s` (CEL4RO31-Layout unbekannt), COBOL→Pascal über CEL4RO64 (Layout aus OpenJ9).
  Lokal getestet (x86_64, `tests/run-x86.sh`): dectest 110, ccsidtest 17, cobtest 60, call31test 11
  (Attrappe), db2test 13 (unixODBC+SQLite), zosdsn.c-Prüfstand 131, Python 18. **Auf z/OS ist
  von PF8 noch nichts gelaufen** – Reihenfolge und Erwartungen in `pf8/README.md`.
  Namensfalle: C-Datei und Pascal-Unit gleichen Namens überschreiben sich in `units/zos` (`zosc31.c`).
  SQLDB (06.10.2026, FPC-Patch 0045): `TODBCConnection` auf z/OS statisch gegen DSNAO64C mit den
  Typen aus `rtl/zosdb2cli_zos.inc` (`clib dsnao64c` → zos-ld nimmt das Db2-Sidedeck), `sqldbtest`
  lokal 10/10. Allgemeiner FPC-Fehler gefunden: `odbcsql` `SQLINTEGER = clong` = 8 Byte auf
  64-Bit-Unix (`fpc/upstream/06-odbc-sqlinteger.md`, Patch 0008).

## Nächste Schritte
1. PF3: FPC-Testsuite (`~/src/fpc/tests`) auf z/OS. **tbs (27.09.2026): 772/784 ok, Referenz
   x86_64-linux 777/784.** Nur z/OS: 5 × Inline-Assembler (seit Patch 0035 HLASM-Leser, `pf5/README.md`),
   tb0582 (library → PF4), tb0662 (Testfehler: `@I` Integer als PSizeInt, auf Big-Endian
   riesige Länge). **tbf 316/319 (Ref. 318), webtbf 546/554 (Ref. 547)**: tb0110 (skipcpu ohne
   s390x), uw40621 (Hilfs-Unit); tb0265 war ein Absturz im FPC-LLVM-Codegenerator (behoben,
   Patch 0010). Weiter: test, webtbs. `fpc-testsuite.sh -r` wiederholt nur
   gescheiterte Tests; dotest läuft mit `-L` (sonst Wettlauf um `out.`/Logs bei `-P`, Einträge
   gehen verloren). Referenz-Wrapper ohne `-FU` (sonst Unit-Tests „Failed to run“, Exit 2000).
   z/OS-Platz: ZPAS-ZFS 360 MB; zos-ld bindet erst ab 60 MB frei (`ZOS_MIN_FREE_KB`).
2. Offene TODOs: keine größeren. PF4, PF5 (C-ABI), Backtraces und die Unterverzeichnisse von
   `test/` erledigt. **Zeilennummern in Backtraces (28.09.2026, `-gl`, FPC-Patch 0034):**
   Objekt ohne DWARF + `.dbgo`-Beiwagen (zos-irc), Zeilentabelle beim Binden
   (`scripts/goff-lines.py` → `zzz_lines.o`, leer: `zoslines0.o`), s. `pf5/README.md`.
   zos-ld: `.zos.env` wird mit `HOME=$WH .` eingelesen, das ändert HOME dauerhaft (dash) →
   WSL-Pfade über `$UHOME`. **Inline-Assembler (HLASM, Patch 0035)**: `pf5/README.md`,
   `pf5/asmtest.pas` 6/6. Compilerbau: `make clean` lässt `compiler/s390x/units/*.ppu` stehen →
   bei seltsamen Typfehlern das Verzeichnis leeren. Noch offen aus der Liste des Nutzers:
   Lesezugriffe über nil: `-gc -gh` (Patch 0036, `pf5/README.md`). Liste damit erledigt.
   Offen: ncgmem-Korrektur (Parameter des FPC_CHECKPOINTER-Aufrufs) als FPC-Meldung.
3. **Meldungen an FPC (28.09.2026, `fpc/upstream/`):** 5 Issue-Texte + 7 eigenständige Patches gegen
   FPC main b19181d6 (Zweig `upstream-fixes`, Worktree `~/src/fpc-upstream`). Einreichen muss der
   Nutzer (kein GitLab-Zugang). Auf x86_64-linux nachgestellt (LLVM-Compiler `~/build/fpc-llvm-x64`,
   mit Patches `~/build/fpc-llvm-x64-fix`; ld.bfd braucht dort das Entfernen von --eh-frame-hdr,
   libgcc_s.so-Verknüpfung in ~/opt/linklibs): weakexternal, Capturer/lokale Routinen,
   Interface-Wrapper; fcl-process ExitCode auch mit normalem FPC (FPC-Patch 0030 im Port).

## Arbeitsweise
- **Testsuite aus freien Quellen (`suite/`, 29.09.2026):** HashLib4Pascal, SimpleBaseLib4Pascal,
  CryptoLib4Pascal (FPCUnit) und Benchmarks Game, lokal und auf z/OS (`suite/README.md`). Befunde:
  **Unwinder-Fehler** (`runtime/zosunwind.c`): eine Rücksprungadresse genau am Funktionsende (Aufruf
  als letzter Befehl, z. B. `_Unwind_Resume` in einer Aufräum-Landestelle, bei `-O2` häufig) wurde
  keiner Funktion zugeordnet, die Suche lief rückwärts in nicht lesbaren Speicher -> SIGSEGV ->
  neue Ausnahme -> Endlosschleife. Jetzt ip-1 und nur der erste EPM vor ip. Nachbau
  `lp1`: Funktion mit TBytes-Local + raise, `-O2`. Interface-Wrapper (FPC-Patch 0038).
  Fehlersuche: `ZOS_IRC_OPT`/`ZOS_IRC_LLC` (Stufen von opt/llc getrennt), `ZOS_UNWIND_DEBUG=1`.
  `zos-install-rtl.sh` lädt in Paketen (ZFS-Platz). `pidigits` ist nicht portabel (LE).
- **Units mit Namensraum (29.09.2026):** zweiter Satz `units/zos-ns` (`ZFPC_DOTTED=1` für
  build-rtl.sh/build-packages.sh, Hüllen aus `rtl/namespaced`, `packages/*/namespaced`),
  `zfpc --ns` (-FNSystem,System.Console,UnixApi,TP,Data), Archiv `lib/libfpcns.a`
  (`zos-install-rtl.sh --ns`; zos-ld wählt es nach dem Verzeichnisnamen). 392 Units. FPC-Patch
  0040 (pthreads: z/OS-Zweig ohne Namensraum-Variante), 0041 (Compiler: `uses Classes` über
  -FNSystem und `System.Classes` im selben Programm = zwei Module -> "Got TStringList, expected
  TStrings"; betrifft auch FPC main). Übersetzt: Tests in `pf7/ns/`. z/OS-Lauf stand am
  29.09.2026 aus: ZFS voll (zos-ld verlangt 60 MB frei, Archiv braucht ~52 MB).
- VS Code: `VSCODE.md` (Erweiterung `vscode/`, Tasks, FTP/JES über `scripts/zos-jes.py`, Passwort nur
  in `~/.netrc` in WSL). Zowe Explorer und alefragnani.pascal will der Nutzer nicht („direkt einbauen“).
  z/OS-Debugger: Agent `runtime/zosdbg.c`, Instrumentierung `scripts/zdbg-instrument.py`, Adapter
  `vscode/src/zosdebug.ts`. Lokal testen ohne z/OS: `~/build/fpc-llvm-x64/compiler/ppcx64 -Clv17.0 -g -O- -s`,
  IR instrumentieren, Agent mit clang für Linux + Attrappe für FPC_ZOS_A2E/E2A und `__dso_handle`
  (`-k`), `--eh-frame-hdr` aus ppas.sh; Befehle über stdin. naked-Funktionen nie instrumentieren
  (Absturz 28.09.2026, 2 Dumps). Attrappe braucht auch `FPC_ZOS_DBG_EXITHOOK` (Haken in
  rtl/zos/system.pp System_exit, weil FpExit = _exit). Protokoll mit Threads (H, T/L/G mit
  Thread-Nummer, STOP mit Thread) und Standardeingabe (IN <json>, EOF); Test `pf5/dbgtest.pas`
  (29.09.2026 lokal und z/OS, 0 Dumps).
- **JCL: JOB-Karte immer mit `REGION=0M,LINES=500000`.**
- **Host und User-ID nie ins Repo schreiben**; Zugangsdaten nur in `.zos.env` (nicht versioniert).
  Eigenes USS-Verzeichnis `…/ZPAS` mit eigenem ZFS (getrennt von anderen Verzeichnissen und vom Home-ZFS, das der Testlauf am 27.09.2026 einmal vollgeschrieben hat). Bei Ausgaben von
  Remote-Befehlen Host/User maskieren (sed), sie landen sonst im Sitzungsprotokoll.
- `~/src/llvm-project` und `~/build/llvm-zos` gehören nicht zu diesem Projekt: nicht ändern
  (nur den clang aus `~/build/llvm-zos` für `runtime/*.c` benutzen).
- Nutzer schreibt Deutsch; Antworten auf Deutsch.
- Lokaler Pfad: `C:\Users\marce\Documents\GitHub\zos-pascal-llvm` (Windows), Quellen/Builds in WSL.
