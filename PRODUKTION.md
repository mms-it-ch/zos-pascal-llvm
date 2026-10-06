# Produktion: Schalter, Versionen, Releases, CI

Stand 04.10.2026, Port-Version 0.9.0 (`VERSION`).

## Freigegebene Compilerschalter

`zfpc` setzt die Grundeinstellungen selbst (`-Tzos -Clv17.0`, Unit-Pfad); sie werden nicht
geändert. Für Produktionsprogramme gilt:

| Schalter | Status | Begründung / Hinweis |
|---|---|---|
| `-O2` | **Standard für Produktion** | Damit laufen die Fremd-Suiten auf z/OS fehlerfrei (`suite/`: HashLib4Pascal 1967/1967, SimpleBaseLib4Pascal 239/239, Benchmarks Game); `zos-irc` gibt die Stufe an `opt`/`llc` weiter. |
| `-O-`, `-O1` | freigegeben | Fehlersuche, Vergleich bei Verdacht auf Optimierungsfehler. |
| `-O3` | nicht freigegeben | Nicht systematisch getestet (kein Testsuite-Lauf mit `-O3`). Erst nach einem Lauf von `tbs`/`webtbs` mit `-O3` freigeben. |
| `-O4` | **nicht freigegeben** | Allgemeiner FPC-Fehler ohne x87: Currency-Rechnungen falsch (`tw41865g`, `tw41865h` nur bei `-O4`). |
| `-Cr` (Bereichsprüfung), `-Co` (Überlauf), `-Ci` (E/A-Prüfung) | **empfohlen** | Laufzeitfehler 201/215/1xx statt stiller Fehlrechnung; Kosten gering. `-Ci` ist ohnehin Standard. |
| `-Ct` (Stack-Prüfung) | empfohlen bei Rekursion und Threads | FPC-Patch 0033: Laufzeitfehler 202 statt Stackwachstum bis zum CPU-Limit (`tw40598`, `tstack`). Ein Vergleich je Routine. |
| `-gl` (Zeilennummern) | **empfohlen** | FPC-Patch 0034: Backtraces mit Zeile. Der gebundene Code ist derselbe (DWARF geht nur in die `.dbgo`-Beiwagen, `zos-irc`); zusätzlich nur die Zeilentabelle `zzz_lines.o`. RTL/Packages sind ohne `-gl` übersetzt (dort Funktionsnamen). |
| `-gc -gh` (Zeigerprüfung) | nur Fehlersuche | FPC-Patch 0036: erkennt Lesen über nil (auf z/OS sonst still: PSA lesbar); ein Aufruf je Zeigerzugriff. |
| `-gh` (heaptrc) | nur Fehlersuche | Speicherlecks. |
| `-Sa` (Assertions) | nach Projekt | |
| `-g`, `-gw*` (volles DWARF) | nur Debugger | Für den z/OS-Debugger (`VSCODE.md`, `ZOS_ZDBG=1`); `naked`-Funktionen werden nicht instrumentiert. |
| `-Cn`, `-s` | Werkzeug | nur übersetzen, nicht binden (CI). |

Empfohlene Zeile für Produktion:

```sh
zfpc -O2 -Cr -Co -gl prog.pas          # bei Rekursion/Threads zusätzlich -Ct
```

Nicht verändern: `-Clv17.0` (LLVM-Version der IR-Ausgabe, passend zum eigenen LLVM-Zweig),
`-Tzos`, die Unit-Sätze (`units/zos` bzw. mit `--ns` `units/zos-ns`, nie mischen).

### Laufzeit (LE)

- Programme laufen im ASCII-Modus mit **POSIX(ON)** (im Batch über CEEOPTS, `zos-batch.sh`).
- JOB-Karte immer mit `REGION=0M,LINES=500000`.
- `TERMTHDACT(MSG)` verhindert bei zerstörtem Stack keinen Dump (U4083, Dump-Dataset unter der
  User-ID) – Abstürze vor der Produktion mit `-Ct`/`-Cr` ausschließen.
- Zeichensatz der RTL ist immer ISO-8859-1 (CCSID 819/28591). Datasets im Textmodus werden
  umgewandelt: Standard IBM-1047, einstellbar (`ZOS_CCSID`, `pf8/README.md`).

### Bekannte Grenzen (Produktion)

- Lesen über nil löst nichts aus (PSA) – nur mit `-gc -gh` erkennbar.
- `fcntl`-Sperren gelten prozessweit (wie AIX/Solaris), nicht je Thread.
- Keine UTF-8-Konsole (Systemcodepage ISO-8859-1).
- Inline-Assembler nur HLASM über LLVM (`pf5/README.md`), keine Literale, keine Aufrufe.
- Struktur-/Konstantenwerte der z/OS-Header sind gemessen (`pf1/probe/zosprobe.c`); neue
  Schnittstellen erst nach Messung freigeben.

## Versionen

- **Port-Version** (Semantic Versioning, `MAJOR.MINOR.PATCH`) in `VERSION`. Dieselbe Zahl steht
  im Compiler (FPC-Patch 0043, `compiler/version.pas`: `zosport_version`) und in der RTL
  (`system.pp`: `ZosPortVersion`).
- Sichtbar:
  - `zfpc --version` → `zfpc (zos-pascal-llvm) 0.9.0` und Compiler-/FPC-Version,
  - `ppcs390x -iZ` → `0.9.0`, das Logo (`-l`) zeigt `z/OS port (zos-pascal-llvm) version 0.9.0`;
    `-iV`/`-iW` bleiben die FPC-Version (3.3.1) für fpcmake und Werkzeuge,
  - im Programm: Konstante `ZosPortVersion` (Unit `system`),
  - im Programmobjekt: Eyecatcher `ZPAS 0.9.0 FPC 3.3.1` als ASCII (`FPC_ZOS_VERSION`, z. B.
    `grep -a ZPAS prog` unter z/OS UNIX) und EBCDIC (`FPC_ZOS_VERSION_E`, lesbar beim
    Durchblättern in ISPF bzw. mit AMBLIST),
  - im Start-Skript von `zos-ld`: Kopfzeile `# zos-pascal-llvm 0.9.0, gebunden <Datum>`.
- IDR (Binder-Kommentar, `IDENTIFY`): nicht umgesetzt. `IDENTIFY` braucht den Namen einer
  Section des Programms; welche Sections LLVM/der Binder für XPLINK-Programme anlegen, ist
  noch nicht gemessen (auf z/OS mit `ZOS_KEEP_MAP=1` die Map ansehen). Bis dahin dient der
  Eyecatcher als Kennzeichnung (auf z/OS noch nicht getestet).
- Erhöhen: bei Änderungen an RTL/Compiler-ABI mindestens MINOR (PPU- und Objektformat können
  sich ändern, alle Units und Programme neu übersetzen); reine Fehlerkorrekturen PATCH. Vor 1.0
  sind Units/Objekte verschiedener MINOR-Versionen nicht kompatibel.

### Basisstände (je Release festhalten)

| Teil | Stand |
|---|---|
| FPC | `main` 37b8a1a9 (`fpc/BASE`) + Patches `fpc/patches/0001`–`0045` |
| LLVM | Zweig `pascal-zos` auf `zos-fixes` (`c854662c0`, LLVM 23.1.2) + `llvm/patches/0001`–`0011` |
| Start-Compiler | FPC 3.2.2 (für den nativen FPC main) |
| z/OS | LE, C-RTL ASCII-Einstiege aus den Headern (`zosmap.txt`, lokal erzeugt) |

## Releases

1. `CHANGELOG.md`: Abschnitt „Unveröffentlicht“ in die neue Version umbenennen, Datum.
2. Version erhöhen: `VERSION`; im FPC-Zweig `zos` `compiler/version.pas` (`zosport_version`)
   und `rtl/zos/system.pp` (`ZosPortVersion`, beide Eyecatcher) anpassen und Patch 0043 neu
   erzeugen (`git format-patch`). Die CI prüft, dass `ppcs390x -iZ` gleich `VERSION` ist.
3. CI grün: Job `build` (GitHub) und Job `zos` (Self-Hosted, echtes Binden und Ausführen);
   vor einem MINOR-Release zusätzlich die Testsuite über `workflow_dispatch` (`testsuite: tbs
   tbf webtbf test webtbs`) und Vergleich mit der Referenz (`fpc-testsuite-compare.py`).
4. Tag `vX.Y.Z` (annotiert) auf `main`; Release-Zweig `release/X.Y` nur bei Korrekturen für
   eine ältere Version.
5. GitHub-Release zum Tag: Text aus `CHANGELOG.md`; Anhänge vom Self-Hosted-Runner (sie
   brauchen den eigenen LLVM-Zweig): `zfpc-X.Y.Z-x86_64-linux.tar.xz` (`ppcs390x`, Skripte,
   `units/zos` mit GOFF-Objekten, ohne `zosmap.txt` – sie stammt aus lizenzierten Headern und
   wird beim Empfänger erzeugt), dazu die Patchserien `fpc/patches`, `llvm/patches`.

## CI

`.github/workflows/ci.yml`, lokal nachvollziehbar mit `scripts/ci-build.sh`.

### Job `build` (GitHub-Runner)

| Schritt | Inhalt | Dauer (Container, 4 Kerne) |
|---|---|---|
| `source` | FPC main blobfrei klonen (Cache), Basis `fpc/BASE`, `git am fpc/patches/*.patch` | ~1 min (ohne Cache) |
| `compiler` | nativer FPC main mit FPC 3.2.2 (`make cycle`), dann `ppcs390x` (LLVM=1) | ~1,5 min |
| `rtl` | `build-rtl.sh` mit `ZFPC_CI=1`: RTL + 340 Package-Units bis zum Objekt (llc 18), gescheiterte Units = `ci/package-failures.txt` | ~4 min |
| `pf` | alle `pf*/*.pas` mit `-Cn` (ohne Binden) | ~2 min |
| `python` | `py_compile` aller Skripte, `tests/test_*.py` | Sekunden |
| `x86` | portable Units (CCSID, Dezimal) auf x86_64 übersetzen und testen (`tests/run-x86.sh`) | Sekunden |

Grenzen des Distributions-llc (LLVM 18): GOFF-Ausgabe ist nur ein Gerüst (Kopf/Ende), und
`llvm.global_ctors` stürzt für z/OS ab → Bibliotheken (`library`) werden im Schritt `pf`
übersprungen. Geprüft wird also: Patchserie, Compilerbau, IR-Gültigkeit und
SystemZ-Codeerzeugung für alle Units und Programme. Echtes GOFF nur im Job `zos`.
`ZFPC_CI=1` lässt außerdem die C-Laufzeit (`runtime/*.c`, braucht die z/OS-Header) und
`zosmap.txt` weg.

### Job `zos` (Self-Hosted-Runner)

Läuft nur, wenn die Repository-Variable `ZOS_RUNNER` = `true` ist (Settings → Secrets and
variables → Actions → Variables) und nicht für Pull Requests (Secrets).

Runner einrichten (Linux x86_64 oder WSL, Labels `self-hosted`, `zos`):

- eigener LLVM-Zweig gebaut (`llc`, `opt`), Pfad in der Variablen `ZOS_LLVM_BIN`,
- clang mit z/OS-Korrekturen (`ZOS_CLANG`) und die z/OS-Header (`ZOS_INCLUDE`) für
  `runtime/*.c` und `zosmap.txt`,
- FPC 3.2.2 (Start-Compiler), `ssh`/`sftp` (Linux; unter WSL geht auch `ssh.exe` wie bisher,
  `zos-hostenv.sh`), Python 3.

Secrets (nie ins Repo, nie in Logs – GitHub maskiert sie):

| Secret | Inhalt |
|---|---|
| `ZOS_HOST` | `user@host` für ssh/sftp |
| `ZOS_SSH_KEY` | privater Schlüssel (OpenSSH-Format) |
| `ZOS_DIR` | USS-Arbeitsverzeichnis (eigenes ZFS, z. B. `…/ZPAS`) |
| `ZOS_LEHLQ` | HLQ der LE-Bibliotheken (Standard `CEE`) |
| `ZOS_PASLIB` | PDSE für Batch-Programme (optional) |

Der Job schreibt daraus eine `.zos.env` nach `$RUNNER_TEMP` (Rechte 600) und löscht sie am
Ende. Ablauf: Bau mit echtem GOFF, `zos-install-rtl.sh`, `scripts/ci-zos.sh` (Programme aus
`ci/zos-tests.txt` binden und ausführen, Returncode 0 erwartet, Ausgaben mit maskiertem
Host/User), auf Wunsch die FPC-Testsuite mit Vergleich. Platz im ZFS beachten (`zos-ld`
bindet erst ab 60 MB frei). **Auf z/OS noch nicht getestet** (in dieser Umgebung gab es keinen
z/OS-Zugang; `zos-ld` im Linux-Modus ist mit einem ssh-Stub geprüft).
