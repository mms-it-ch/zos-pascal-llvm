# PF7: FPC-Packages (FCL u. a.) für z/OS

`scripts/build-packages.sh` (läuft am Ende von `build-rtl.sh` mit) übersetzt 219 Units aus

rtl-extra, pthreads, rtl-generics, hash, paszlib, fcl-base, fcl-json, fcl-xml, fcl-process,
fcl-registry, fcl-fpcunit, fcl-passrc, fcl-stl, fcl-res, fcl-async, fcl-net, fcl-extra

nach `~/opt/zfpc/units/zos`; `zos-install-rtl.sh` legt sie mit ins Archiv `libfpc.a` (ld nimmt nur
benötigte Member). Dazu kamen in die RTL: `rtti`, `nullable`, `tuples` (rtl-objpas), `zosebcdic`.

## Test (28.09.2026): `pkgtest.pas` 18/18

fcl-json (Parsen, Erzeugen), fcl-xml (DOM lesen, schreiben), Generics.Collections
(TDictionary, TList), SyncObjs (4 Threads mit TCriticalSection, TEvent), TProcess/RunCommand,
md5, sha1, base64, zlib (TCompressionStream), Sockets über loopback (ssockets: TInetServer im
Thread, TInetSocket als Client).

## Was für z/OS nötig war (FPC-Patches 0028, 0029)

- **Bauweise:** Die `fpmake.pp` kennen z/OS nicht. Erster Durchgang: jede Unit einzeln (welche
  gehen?); zweiter Durchgang: eine Hilfs-Unit, die alle benutzt, mit `-B` in einem Lauf.
  Einzeln übersetzt ändern sich die Prüfsummen mehrfach gebauter Abhängigkeiten
  ("checksum changed", generics.collections/generics.defaults).
- **Semaphoren:** z/OS hat keine unbenannten POSIX-Semaphoren (`sem_init` …) → Nachbildung mit
  Mutex und Condition Variable (`runtime/zoscompat.c`), `sem_t` ist ein Zeiger.
- **Sockets:** `rtl-extra/src/zos` (`osdefs.inc`, `unxsockh.inc` aus den z/OS-Headern erzeugt mit
  `scripts/gen-sockh.py`); `sockaddr` hat ein Längenbyte (`SOCK_HAS_SINLEN`); kein
  `MSG_NOSIGNAL` (0). `struct addrinfo`: `ai_canonname` vor `ai_addr`, zusätzlich `ai_eflags`
  (getaddrinfo liest es aus den Hints).
- **Pipes:** `ioctl(FIONREAD)` lehnt z/OS bei Pipes ab (EINVAL) → `NumBytesAvailable` über
  `fstat` (`st_size` = wartende Bytes); vorher las `RunCommand` nichts.
- **pthreads-Unit:** nutzt `rtl/zos/pthread.inc`; FIONREAD in `termios.inc`.

## Weitere Packages (28.09.2026): 332 Units

- **fcl-web** (`src/base`, `jsonrpc`, `jwt`, `websocket`, `restbridge`), **fcl-hash**, **fastcgi**,
  **fcl-db** (`base`: db, bufdataset, …; `sqldb`; `dbase`): HTTP-Server und -Client, Routing,
  fpweb, WebSocket, JSON-RPC, JWT, FastCGI, TDataSet/BufDataset, sqldb-Grundgerüst.
  Test `webtest.pas`: TFPHttpServer im Thread, TFPHTTPClient über loopback (GET, POST mit JSON,
  404): 3/3. Nicht gebaut: Apache-, libmicrohttpd-, http.sys-Anbindung (fremde Bibliotheken),
  sqldbrestbridge, dbase-Sprachvarianten/Lazarus-Registrierung.
- **System V IPC** (Unit `ipc`, FPC-Patch 0032): eigener Interface-Teil `rtl-extra/src/zos/ipczos.inc`,
  Layouts auf z/OS gemessen (`ipcprobe_c.c`; AMODE 64: Zeitfelder hinter 4-Byte-Feldern des
  31-Bit-Layouts). Shared-Memory-Segmente liegen oberhalb der 2-GB-Grenze und werden auf 1 MB
  aufgerundet. Test `ipctest.pas` (Shared Memory, Message Queue, Semaphoren): 22/22.

## Hinweise

- **Kindprozesse schreiben EBCDIC:** z/OS-UNIX-Kommandos (`/bin/echo`, `/bin/sh` …) geben
  EBCDIC aus. Unit `zosebcdic`: `EbcdicToAscii`, `AsciiToEbcdic` (IBM-1047 ↔ ISO-8859-1,
  NL ↔ LF, dieselben Tabellen wie die Dataset-Schicht).
- `TProcess.ExitCode` ist nach `poWaitOnExit` 0 (WaitProcess liefert schon den Exitcode, ExitCode
  wertet ihn ein zweites Mal aus - wie unter Linux); `ExitStatus` enthält den Exitcode.
  Probe `procprobe.pas`.
- Nicht übersetzt (nicht z/OS oder fehlende Packages): gpm, serial, xmliconv (iconvenc),
  processunicode/fpsimpleservice (Windows), digesttestreport (libtar), rcreader/rcparser (lexlib),
  httpsvlt (HTTPBase).
