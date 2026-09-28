# VS Code

## Erweiterung „z/OS Pascal“ (`vscode/`)

Bauen: `cd vscode && npm install && npm run compile && npm run package`, dann in VS Code
„Erweiterungen: Aus VSIX installieren…“ mit `vscode/zos-pascal-<version>.vsix`.

- Syntaxfärbung: Pascal (Free Pascal/Delphi, Direktiven, `asm`-Blöcke in HLASM-Syntax), JCL,
  JES-Spool (Meldungen, RC, Laufzeitfehler, Backtrace).
- Pascal-Editor: Gliederung/Breadcrumbs (Programm, Unit-Teile, Typen, Klassen mit Feldern,
  Methoden und Eigenschaften, Routinen mit lokalen Deklarationen; bei `{$if}…{$else}` zählt
  der erste Zweig), Gehe zu Definition (F12; auch Units in `uses`), Symbolsuche (Strg+T),
  Formatieren mit `ptop` (Umschalt+Alt+F; Konfiguration mit kleinen Schlüsselwörtern,
  `vscode/resources/ptop.cfg`), Snippets. RTL-Quellen für F12: `zosPascal.sourcePaths`.
  `ptop` bauen: `utils/ptop` mit `~/opt/fpc-main/bin/ppcx64` (FPC-Patch 0037 behebt den
  Absturz von `ptop -c`).
- Befehle (Editor-Titel, Kontextmenüs, Befehlspalette): übersetzen (Strg+Umschalt+B), übersetzen
  und ausführen im Terminal (Strg+F5), Batch-Job (PDSE, FTP/JES), JCL einreichen. Compilerfehler
  unter „Probleme“, Spool öffnet sich im Editor.
- Seitenleiste „z/OS“ → „JES-Jobs“: eigene Jobs mit Status und RC, Klick = Spool, Löschen mit
  Rückfrage; automatisch aktualisieren über `zosPascal.jes.autoRefreshSeconds`.
- JCL-Prüfung: JOB-Karte ohne `REGION=0M,LINES=500000`, Text in Spalte 72, Zeilen über 80.
- Einstellungen `zosPascal.*`: Pfad der Toolchain (Standard: Arbeitsbereich mit `scripts/zfpc`),
  WSL-Distribution, Compileroptionen (Standard `-gl`), Wartezeit für Jobs.
- Andere Pascal-Erweiterungen (z. B. alefragnani.pascal) sind nicht nötig und sollten
  deaktiviert sein (beide färben die Sprache `pascal`).
- Debuggen, lokal (Linux x86_64 in WSL, gdb): F5 in einer Pascal-Datei oder Konfiguration
  „Pascal lokal (gdb)“. Die Erweiterung übersetzt mit `~/opt/fpc-main/bin/ppcx64 -g -gw3 -gl -O-`
  nach `/tmp/zos-pascal-debug/<name>` und startet gdb über den Debug-Adapter der Erweiterung
  C/C++ (ms-vscode.cpptools). Haltepunkte, Einzelschritt, Aufrufliste, Variablen. Units: RTL und
  dieselben Packages wie für z/OS (FCL, fcl-web, fcl-db, …), gebaut mit
  `ZFPC_PKG_TARGET=x86_64-linux scripts/build-packages.sh` nach `~/opt/fpc-main/units/packages`
  (mit Debug-Informationen; fehlende rtl-objpas-Units wie rtti werden mitgebaut);
  `zosPascal.debug.localUnitPaths`. z/OS-eigene Units (zosebcdic, zosrecio, Datasets) gibt es
  lokal nicht; solche Programme auf z/OS debuggen.
- **Debuggen auf z/OS** (Konfiguration „Pascal auf z/OS“, `"target": "zos"`): Die Erweiterung
  übersetzt mit `ZOS_ZDBG=1 zfpc -g -O-`, startet das Programm über ssh mit `ZDBG=1` und spricht
  mit dem Debug-Agenten im Programm. Haltepunkte, Halt am Anfang (`stopAtEntry`), Schritt
  über/hinein/hinaus, Pause, Aufrufliste mit Zeilen, lokale und globale Variablen (Zahlen,
  Boolean, Zeichen, Aufzählungen, AnsiString/ShortString/UnicodeString, Records, Arrays,
  Zeiger/Objekte aufklappbar), Hover und Überwachen (`name`, `a.b.c`). Programmausgabe in der
  Debugkonsole; die Standardeingabe des Programms ist leer.
  - Aufbau: `scripts/zdbg-instrument.py` (in `zos-irc`) fügt ins LLVM-IR je Routine einen
    Frame-Satz (Adressen der Variablen aus `llvm.dbg.declare`) und vor jeder neuen Quellzeile
    `FPC_ZOS_DBG_LINE` ein, dazu Typbeschreibungen aus den DWARF-Metadaten. Der Agent
    `runtime/zosdbg.c` (im RTL-Archiv) ist ohne `ZDBG=1` untätig.
  - Verbindung: Portweiterleitung ist auf dem z/OS-sshd gesperrt; der Agent übernimmt stdin/stdout
    der ssh-Sitzung (Zeilen `@@Z …`, Programmausgabe über eine Pipe) und gleicht die
    ASCII/EBCDIC-Wandlung des sshd aus.
  - Grenzen: nur der Haupt-Thread; RTL und Packages sind nicht instrumentiert (Schritt hinein
    läuft über sie hinweg); reine Assembler-Routinen (naked) werden ausgelassen; keine
    Ausdrücke außer Variablen/Feldern; eine Zeile, die sich selbst wiederholt
    (`while x do inc(i);` in einer Zeile), läuft beim Einzelschritt ganz durch.
  - Test: `bt.pas` auf z/OS (Haltepunkt, Schritte, Aufrufliste, Variablen); lokal nachgebaut mit
    dem x86_64-LLVM-FPC (siehe CLAUDE.md).

## Tasks (`.vscode/tasks.json`, ohne Erweiterung)

| Task | macht |
|---|---|
| z/OS: übersetzen und binden (Strg+Umschalt+B) | `zfpc -gl` für die geöffnete Datei; Fehler erscheinen unter „Probleme“ |
| z/OS: übersetzen und ausführen | danach das Programm auf z/OS starten (Argumente werden abgefragt) |
| z/OS: Batch-Job (PDSE, FTP/JES) | in die PDSE binden (Member abgefragt), JCL mit `zos-batch.sh -j` erzeugen (Ausgabe nach SYSOUT, ohne RC-Schritte), per FTP/JES einreichen; Programmausgabe steht im Spool |
| z/OS: JCL einreichen (FTP/JES) | die geöffnete JCL-Datei einreichen, warten, Spool nach `jes-output/` |
| z/OS: eigene Jobs / Spool holen | Jobliste bzw. Spool eines Jobs |

## FTP/JES (`scripts/zos-jes.py`)

Nutzt die JES-Schnittstelle des z/OS-FTP-Servers (`SITE FILETYPE=JES`): Einreichen, Status
(JESINTERFACELEVEL 2), Spool holen (`JOBnnnnn.X`), auf Wunsch `--purge`. Returncode = RC des Jobs.

Einrichten (einmal, in WSL; das Passwort steht nur dort, nie im Repo):

```
machine <z/OS-Host> login <User-ID> password <Passwort>
```

in `~/.netrc`, dann `chmod 600 ~/.netrc`. Host = `ZOS_FTP_HOST` oder Hostteil von `ZOS_HOST`
(`.zos.env`). FTPS: `ZOS_FTP_TLS=1`, oder automatisch, wenn der Server TLS verlangt.

Hinweise:
- Per FTP lässt sich nur Ausgabe in einer **gehaltenen** Ausgabeklasse holen: `ZOS_MSGCLASS`
  in `.zos.env` auf eine gehaltene Klasse setzen (`zos-batch.sh` nimmt sie für die JOB-Karte).
- Getestet (28.09.2026): IEFBR14 (RC 0), `asmtest` im Batch (Ausgabe im Spool, RC 0),
  `niltest` mit `-gc -gh` (Laufzeitfehler 204 = RC 0204 des Jobs = Returncode des Skripts).
- JOB-Karten brauchen `REGION=0M,LINES=500000`; `zos-jes.py` warnt sonst.
