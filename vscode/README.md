# z/OS Pascal (VS Code)

Free Pascal für z/OS in VS Code, auf Basis der Toolchain aus `zos-pascal-llvm` (Skripte in
`scripts/`, laufen in WSL).

- **Editor:** Syntaxfärbung für Pascal (Free Pascal/Delphi, Direktiven, `asm`-Blöcke in
  HLASM-Syntax), JCL und JES-Spool; Klammern, Kommentare, Einrückung, Falten.
- **Übersetzen** (Strg+Umschalt+B): `zfpc` mit den eingestellten Optionen (Standard `-gl`),
  Meldungen unter „Probleme“.
- **Ausführen** (Strg+F5): übersetzen, dann das Programm auf z/OS im Terminal starten.
- **Batch:** in die PDSE binden, JCL erzeugen, über FTP/JES einreichen, Spool öffnen.
- **JCL einreichen:** geöffnete JCL-Datei; Prüfung der JOB-Karte (`REGION=0M,LINES=500000`)
  und der Spaltengrenzen.
- **JES-Ansicht** (Seitenleiste „z/OS“): eigene Jobs mit Status und RC; Klick öffnet den Spool,
  Löschen mit Rückfrage.

Einrichtung: `VSCODE.md` im Repo (Zugang über `.zos.env`, FTP-Passwort nur in `~/.netrc` in WSL,
gehaltene Ausgabeklasse in `ZOS_MSGCLASS`).

Bau: `npm install && npm run compile && npm run package` → `zos-pascal-<version>.vsix`,
installieren mit „Erweiterungen: Aus VSIX installieren…“.
