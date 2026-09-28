# VS Code

Editor: Erweiterung „Pascal“ (alefragnani.pascal; wird über `.vscode/extensions.json` vorgeschlagen).
Wer Vervollständigung will: „Pascal Language Server“ (Lazarus-CodeTools) mit den FPC-Quellen
`~/src/fpc` (Zweig `zos`). Übersetzen und z/OS laufen über Tasks (`.vscode/tasks.json`), alles in
WSL mit den Skripten aus `scripts/`:

| Task | macht |
|---|---|
| z/OS: übersetzen und binden (Strg+Umschalt+B) | `zfpc -gl` für die geöffnete Datei; Fehler erscheinen unter „Probleme“ |
| z/OS: übersetzen und ausführen | danach das Programm auf z/OS starten (Argumente werden abgefragt) |
| z/OS: Batch-Job (PDSE, FTP/JES) | in die PDSE binden (Member abgefragt), JCL mit `zos-batch.sh -n` erzeugen, per FTP/JES einreichen |
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
(`.zos.env`). FTPS: `ZOS_FTP_TLS=1`.

Hinweise:
- Per FTP lässt sich nur Ausgabe in einer **gehaltenen** Ausgabeklasse holen. Die Batch-JCL von
  `zos-batch.sh` nimmt `ZOS_MSGCLASS` (Standard X); dafür eine gehaltene Klasse setzen, sonst
  endet der Job zwar, aber der Spool ist nicht abrufbar. Die Programmausgabe selbst schreibt
  `zos-batch.sh` ohnehin per DD PATH in USS-Dateien.
- JOB-Karten brauchen `REGION=0M,LINES=500000`; `zos-jes.py` warnt sonst.
