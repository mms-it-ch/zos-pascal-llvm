# PF6: MVS-Datasets und DD-Anweisungen

Normale Pascal-Datei-E/A (`Assign`, `Reset`, `Rewrite`, `Append`, `ReadLn`, `WriteLn`,
`BlockRead`, `Seek`, `FileSize`, `Erase`, `Rename`) mit MVS-Datasets, unter z/OS UNIX und im
Batch (FPC-Patch 0027, `runtime/zosdsn.c`, 28.09.2026).

## Namen

| Name | Bedeutung |
|---|---|
| `//'HLQ.NAME'`, `//'HLQ.PDS(MEMBER)'` | Dataset mit vollem Namen |
| `//NAME` | Dataset mit TSO-Präfix (User-ID), z. B. `//ZPAS.TEST.FB80` |
| `//DD:NAME`, `DD:NAME` | DD-Anweisung des Job-Schritts (Batch) |
| `…,recfm=fb,lrecl=80,space=(trk,(5,5))` | Attribute für ein neues Dataset (fopen-Syntax) |

```pascal
assign(t, '//''HLQ.DATEN.NEU'',recfm=fb,lrecl=80,space=(trk,(5,5))');
rewrite(t);
writeln(t, 'Hallo');
close(t);
```

## Verhalten

- **Textdateien** (`text`): Textmodus der C-Laufzeit, ein Satz je Zeile, Umwandlung
  ISO-8859-1 ↔ IBM-1047 (Zeilenende LF ↔ X'15', wie iconv unter z/OS UNIX).
  FB: beim Schreiben mit Leerzeichen aufgefüllt, beim Lesen nachgestellte Leerzeichen entfernt;
  zu lange Zeile → Fehler 101 (Satz abgeschnitten). VB: Länge bleibt; eine Leerzeile wird als
  Satz mit einem Leerzeichen geschrieben und als Leerzeile gelesen.
- **Binärdateien** (`file`, `file of …`): Bytestrom ohne Umwandlung (FB: Sätze
  hintereinander), `Seek`/`FileSize` gehen; `Truncate` nicht (Fehler 5).
- **Rewrite eines vorhandenen Datasets** ohne Attribute behält dessen Attribute (`recfm=*`); ohne
  das würde die C-Laufzeit es als VB 1024 neu anlegen.
- Datasets haben keine Dateideskriptoren (`fileno` = -1); die RTL vergibt eigene Handles.

## Bibliotheken (PDS, PDSE)

- Neues PDS mit dem ersten Member: `space` mit Directory-Blöcken, z. B.
  `//ZPAS.LIB(MEM1),recfm=fb,lrecl=80,space=(trk,(1,1,5))`.
- `dsntype=library` (PDSE) bzw. `dsntype=pds`: fopen kennt dsntype nicht (EINVAL); die RTL legt die
  Bibliothek vorher mit `dynalloc` an (recfm, lrecl, blksize, space aus den Attributen).
- Member ersetzen (`Rewrite`), löschen (`Erase`/`DeleteFile`), Bibliothek löschen.
- Test `dsnpds.pas`: PDS, PDS über dsntype=pds, PDSE: 30/30.

## Satzweise E/A und VSAM (Unit `zosrecio`)

```pascal
uses zosrecio;
var f: TRecFile; r: TKundenSatz;
begin
  RecOpen(f, '//''HLQ.KUNDEN.KSDS''', romUpdate);
  RecLocate(f, key, 8, rlKeyEqual);          { KSDS: über den Schlüssel }
  if RecRead(f, r, sizeof(r)) > 0 then
    RecUpdate(f, r, sizeof(r));              { oder RecDelete(f) }
  RecClose(f);
end.
```

- Ein Aufruf = ein Satz (`type=record`): VB-Sätze behalten ihre Länge, auch in Binärdaten; FB wird
  beim Schreiben aufgefüllt. Kein Umwandeln des Inhalts (Text: Unit `zosebcdic`).
- VSAM: KSDS (Laden in Schlüsselfolge mit `romWrite`, Einfügen/Ändern/Löschen mit `romUpdate`),
  ESDS, RRDS; `RecLocate` mit `rlKeyEqual`, `rlKeyGreaterEqual`, `rlFirst`, `rlLast`.
  `TRecFile` enthält Format, maximale Satzlänge, VSAM-Typ, Schlüssellänge und -position.
- `SysUtils.FileExists`, `DeleteFile`, `RenameFile` kennen Dataset-Namen.
- Test `rectest.sh` (legt den KSDS per IDCAMS an und löscht ihn): VB-Längen 3/80/200/1 exakt,
  FB, KSDS laden/einfügen/positionieren/ändern/löschen/sequentiell/letzter Satz: 0 Fehler.

## Batch

Sind die Deskriptoren 0/1/2 nicht offen (JCL mit POSIX(ON)), nimmt die RTL beim Start:

| Handle | DD-Anweisung | |
|---|---|---|
| Eingabe | `STDIN`, sonst `SYSIN` | z. B. `//SYSIN DD *` |
| Ausgabe | `STDOUT`, sonst `SYSPRINT` | z. B. `//SYSPRINT DD SYSOUT=*` oder ein Dataset |
| Fehler | `STDERR` | |

z/OS-UNIX-Dateien (`DD PATH=`) werden als Deskriptor übernommen (Inhalt ASCII), alles andere
über die Dataset-Schicht (EBCDIC). Ob eine DD-Anweisung existiert, prüft die RTL in der TIOT:
`fopen("DD:STDOUT")` gelingt unter POSIX(ON) auch ohne DD (LE legt dann einen Stream auf eine
z/OS-UNIX-Datei an). Und `fileno` taugt nicht als Unterscheidung (für `DD:SYSPRINT` liefert es
einen Deskriptor, obwohl ein Dataset dahintersteht) - entscheidend ist `fldata` (`__dsorgHFS`).
Diagnose: `ZOS_BATCH_CEEOPTS="ENVAR('ZOS_DSN_DEBUG=1')"` (Ausgabe nach STDERR).

## Tests

- `dsntest.pas` (z/OS UNIX): FB/VB-Text mit Umlauten, Leerzeilen, Append; zu lange Zeile;
  Binär mit Seek/FileSize; Erase; fehlendes Dataset: 26/26.
- `dsnlong.pas`: zu lange Zeile und Rewrite eines vorhandenen FB-Datasets.
- `dsnbat.sh` (Batch, `dsnbat.pas` + `dsnbat.dd`): SYSIN DD *, SYSPRINT auf ein Dataset,
  `DD:INDATA` → `DD:OUTDATA` (FB 80): RC 3, Ausgaben wie erwartet. `zos-batch.sh` nimmt dafür
  weitere DD-Anweisungen aus `ZOS_BATCH_DD` (`@HLQ@` = Präfix, erst beim Einreichen ersetzt).
- `dsnprobe*_c.c`: C-Proben zum Verhalten der C-Laufzeit (Satz-/Textmodus, fldata, recfm=*).

Die Tests legen Datasets `<Präfix>.ZPAS.TEST.*` an und löschen sie wieder.
