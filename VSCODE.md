# VS Code

Editor: Erweiterung „Pascal“ (alefragnani.pascal; wird über `.vscode/extensions.json` vorgeschlagen).
Wer Vervollständigung will: „Pascal Language Server“ (Lazarus-CodeTools) mit den FPC-Quellen
`~/src/fpc` (Zweig `zos`). Übersetzen und z/OS laufen über Tasks (`.vscode/tasks.json`), alles in
WSL mit den Skripten aus `scripts/`:

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
