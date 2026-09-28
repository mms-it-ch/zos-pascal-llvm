# VS Code

## Erweiterung „z/OS Pascal“ (`vscode/`)

Bauen: `cd vscode && npm install && npm run compile && npm run package`, dann in VS Code
„Erweiterungen: Aus VSIX installieren…“ mit `vscode/zos-pascal-<version>.vsix`.

- Syntaxfärbung: Pascal (Free Pascal/Delphi, Direktiven, `asm`-Blöcke in HLASM-Syntax), JCL,
  JES-Spool (Meldungen, RC, Laufzeitfehler, Backtrace).
- Befehle (Editor-Titel, Kontextmenüs, Befehlspalette): übersetzen (Strg+Umschalt+B), übersetzen
  und ausführen im Terminal (Strg+F5), Batch-Job (PDSE, FTP/JES), JCL einreichen. Compilerfehler
  unter „Probleme“, Spool öffnet sich im Editor.
- Seitenleiste „z/OS“ → „JES-Jobs“: eigene Jobs mit Status und RC, Klick = Spool, Löschen mit
  Rückfrage; automatisch aktualisieren über `zosPascal.jes.autoRefreshSeconds`.
- JCL-Prüfung: JOB-Karte ohne `REGION=0M,LINES=500000`, Text in Spalte 72, Zeilen über 80.
- Einstellungen `zosPascal.*`: Pfad der Toolchain (Standard: Arbeitsbereich mit `scripts/zfpc`),
  WSL-Distribution, Compileroptionen (Standard `-gl`), Wartezeit für Jobs.
- Nicht zusammen mit „Pascal“ (alefragnani.pascal) verwenden: beide färben die Sprache `pascal`.
- Debugger: lokal mit gdb und für z/OS (in Arbeit).

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
