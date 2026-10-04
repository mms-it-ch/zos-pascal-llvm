# PF8: Produktion – Geschäftsdaten, Db2, COBOL-Interop

Stand 04.10.2026 (Port-Version 0.9.0). Entstanden ohne z/OS-Zugang: alles, was nur auf
z/OS geprüft werden kann, ist ausdrücklich als **auf z/OS noch nicht getestet** markiert.
Die portablen Teile sind auf x86_64-linux getestet (`tests/run-x86.sh`, CI-Schritt `x86`).

| Teil | Dateien | x86_64 | z/OS |
|---|---|---|---|
| EBCDIC-Codepages (CCSID) | `runtime/zosdsn.c`, `runtime/zosccsid.h`, `rtl/zosccsid.pp`, Unit `zosebcdic` (FPC-Patch 0044), `scripts/gen-ccsid.py` | getestet (`ccsidtest` 17/17, C-Prüfstand 131/131, `tests/test_ccsid.py`) | noch nicht getestet |
| Gepackte/gezonte Dezimalzahlen | `rtl/zosdecimal.pp`, `rtl/zosdecimalbcd.pp` | getestet (`dectest` 110/110) | noch nicht getestet |
| Copybook → Pascal | `scripts/copybook2pas.py`, `rtl/zoscobol.pp`, `tests/copybooks/` | getestet (`cobtest` 60/60, `tests/test_copybook2pas.py`) | noch nicht getestet |
| Db2 ODBC/CLI | `rtl/zosdb2cli.pp`, `rtl/zosdb2cli_zos.inc`, `pf8/db2probe*.{c,pas}`, `zfpc --db2`, `pf8/db2test.pas`, `*.jcl`, `dsnaoini.txt` | Pascal-Seite getestet gegen unixODBC + SQLite (`db2test` 13/13); Messprogramm gegen unixODBC-Header geprüft | **noch nicht getestet**; Typgrößen nicht gemessen |

## Ausführen auf z/OS

Voraussetzung wie immer: `sh scripts/build-rtl.sh` (baut jetzt auch `zosccsid`, `zosdecimal`,
`zosdecimalbcd`, `zoscobol` und die neue C-Laufzeit), danach `sh scripts/zos-install-rtl.sh`.

```sh
cd pf8
sh ../scripts/zfpc -O2 dectest.pas   && ./dectest        # erwartet: Prüfungen: 110, Fehler: 0, rc 0
sh ../scripts/zfpc -O2 cobtest.pas   && ./cobtest        # erwartet: Prüfungen: 60, Fehler: 0, rc 0
sh ../scripts/zfpc -O2 ccsidtest.pas && ./ccsidtest      # erwartet: Prüfungen: 30, Fehler: 0, rc 0
ZOS_RUN_CEEOPTS="ENVAR('ZOS_CCSID=273')" ./ccsidtest     # Standard 273: ebenfalls 30/0
```

- `dectest` und `cobtest` sind reines Pascal ohne z/OS-Aufrufe; auf z/OS müssen dieselben
  Zahlen herauskommen wie auf x86_64 (Big-Endian-Gegenprobe; die Felder werden byteweise
  verarbeitet). Abweichungen deuten auf einen Codegenerator-Fehler (Big-Endian, `-O2`).
- `ccsidtest` hat auf z/OS zusätzlich 13 Dataset-Prüfungen: legt `<User-ID>.ZPAS.TEST.CCSID1`
  und `…CCSID2` an (mit Präfix als Argument: `./ccsidtest HLQ` → `HLQ.ZPAS.TEST.…`), schreibt
  Text mit `,ccsid=273` im Namen, mit `SetTextCcsid(t, 1141)` (Euro → X'9F') und mit
  `SetDefaultCcsid(500)`, liest die Bytes binär zurück und vergleicht sie mit den
  Python-Codecs; löscht die Datasets am Ende. Die Prüfungen setzen die CCSID jeweils selbst,
  deshalb gilt das Ergebnis auch mit `ZOS_CCSID=273` (Probe, dass die Variable gelesen wird:
  die Kopfzeile `-- Datasets (Standard-CCSID 273)`).
- Auf z/OS noch nicht getestet. Besonders zu beobachten: `fopen` mit dem Zusatz `ccsid=` darf
  nicht ankommen (die Schicht entfernt ihn vorher), `FileSize` auf dem VB-Dataset im
  Binärmodus.

## EBCDIC-Codepages (CCSID)

Bisher waren Textdateien auf Datasets und die Unit `zosebcdic` fest auf IBM-1047. Jetzt:

| Auswahl | Wirkung |
|---|---|
| Umgebungsvariable `ZOS_CCSID=273` (auch `IBM-273`, `IBM273`) | Standard für alle danach geöffneten Text-Datasets, Batch-SYSIN/SYSPRINT und `EbcdicToAscii`/`AsciiToEbcdic` ohne CCSID; unbekannter Wert → Meldung auf stderr, es bleibt 1047 |
| `SetDefaultCcsid(273)` (Unit `zosebcdic`) | dasselbe im Programm; `false` bei unbekannter CCSID |
| Zusatz `,ccsid=273` im Dateinamen | nur diese Datei, z. B. `assign(t, '//''HLQ.DATEN'',ccsid=1141')`; unbekannte CCSID → Fehler beim Öffnen (EINVAL) |
| `SetTextCcsid(t, 273)` direkt nach `Reset`/`Rewrite`/`Append` | nur diese Datei; `GetTextCcsid(t)` liefert sie (−1: kein Dataset) |
| `EbcdicToAscii(s, 273)`, `AsciiToEbcdic(s, 273)` | Umwandlung im Speicher (Laufzeitfehler 201 bei unbekannter CCSID) |
| Unit `zosccsid` (portabel) | `AsciiToEbcdicStr`, `EbcdicToAsciiStr`, `…Buf`, Felder fester Länge `StrToEbcdicField`/`EbcdicFieldToStr`; `ECcsidError` |

Unterstützt: **1047, 37, 273, 277, 278, 280, 284, 285, 297, 500, 871 und die Euro-Varianten
1140–1149** (alle CECP-Codepages mit Latin-1-Zeichenvorrat).

- Tabellen: `scripts/gen-ccsid.py` erzeugt `runtime/zosccsid.h` und `rtl/zosccsid.inc` aus den
  IBM-Zuordnungen der ICU (UCM-Dateien, fester Stand, Prüfsummen; nur Rundreise-Einträge).
  Gegenproben ohne Netz in `tests/test_ccsid.py`: Python-Codecs cp037/cp273/cp500/cp1140,
  die früher auf z/OS mit iconv gemessene 1047-Tabelle, Euro-Varianten = Basis.
- Die RTL arbeitet in ISO-8859-1. **Euro:** In den Varianten 1140–1149 steht das Euro-Zeichen
  an der Stelle von ¤; auf der ASCII-Seite liegt es auf X'A4' (wie in ISO-8859-15). Damit
  bleibt die Umwandlung umkehrbar; wer den Text als Unicode braucht, muss X'A4' bei diesen
  Dateien als € deuten.
- Zeilenende wie unter z/OS UNIX: LF ↔ NL X'15' (EBCDIC-LF X'25' ↔ U+0085).
- Abweichung Python ↔ IBM: cp273 X'BC' ist bei Python U+203E, bei IBM U+00AF (Makron) – es
  gilt IBM.
- DD-Namen in der TIOT werden immer mit 1047 verglichen (Zeichen `@#$` liegen in 273 anders).
- Binärdateien und `zosrecio` wandeln nichts um (wie bisher).

## Dezimalzahlen: Unit `zosdecimal`

```pascal
uses zosdecimal;
var a, b: TDecimal; buf: array[0..5] of byte;
begin
  a := TDecimal.FromString('1234.56');
  b := DecDivide(a, TDecimal.FromInt64(3), 2, drHalfUp);       { 411.52 }
  DecimalToPacked(b, buf, 11, 2);                              { PIC S9(9)V99 COMP-3 }
  a := PackedToDecimal(buf, 11, 2);                            { prüft wie S0C7 }
  writeln(a.ToString, ' ', a.ToCurrency(drHalfUp));
end.
```

- `TDecimal`: Festkomma mit bis zu 63 Stellen (Koeffizient) und eigenem Scale; Operatoren
  `+ - *`, Vergleiche, `DecDivide(a, b, scale, rounding)`, `DecRemainder` (wie COBOL
  REMAINDER: Vorzeichen des Dividenden), `Rescale`, Rundung `drTruncate` (Standard, wie
  COBOL ohne ROUNDED), `drHalfUp` (ROUNDED), `drHalfEven`. Keine Gleitkommarechnung.
- Umwandlung: `FromInt64`, `FromUnscaled(12345, 2)`, `FromCurrency`, `FromString`/
  `TryFromString` (Punkt oder angegebenes Trennzeichen), `ToInt64` (schneidet ab),
  `ToUnscaled`, `ToCurrency(rounding)`, `ToString`; TBCD über Unit `zosdecimalbcd`
  (`DecimalToBCD`, `BCDToDecimal`; eigene Unit, weil `fmtbcd` `variants` mitbringt).
- Gepackt: `PackedToDecimal`, `DecimalToPacked(d, buf, digits, scale, signed, rounding)`,
  `PackedValid`, `PackedLength`, `PackedToInt64`, `Int64ToPacked`. Schreiben: Vorzeichen C/D,
  ohne Vorzeichen F.
- Gezont (DISPLAY): `ZonedToDecimal`, `DecimalToZoned`, `ZonedValid`, `ZonedLength`, Vorzeichen
  `zsTrailing` (Standard), `zsLeading`, `zsTrailingSeparate`, `zsLeadingSeparate` (SIGN …
  SEPARATE: X'4E'/X'60').
- Prüfung beim Lesen (Ausnahme `EDecimalDataError`, entspricht S0C7): Ziffer > 9,
  Vorzeichen-Nibble 0–9, bei gerader Stellenzahl gepackt eine Füllziffer ≠ 0, gezont eine
  Zone ≠ F außerhalb der Vorzeichenstelle (auch ASCII-Ziffern oder Leerzeichen). Vorzeichen
  A, C, E, F = positiv, B, D = negativ (wie die Hardware).
- Schreiben: zu viele Stellen → `EDecimalOverflow` (COBOL würde ohne ON SIZE ERROR still
  abschneiden), negativer Wert in ein Feld ohne Vorzeichen → `EDecimalOverflow` (COBOL MOVE
  ließe das Vorzeichen fallen) – bewusst strenger.
- Division durch null → `EDecimalDivByZero`.

## Copybook → Pascal: `scripts/copybook2pas.py`

```sh
python3 scripts/copybook2pas.py --ccsid 273 KUNDE.cpy -o kunde.pas
```

Erzeugt je Stufe 01/77 einen `packed record` aus Byte-Feldern mit genau den Offsets des
COBOL-Programms, dazu:

| Erzeugt | Beispiel |
|---|---|
| Typ und Zeiger | `TKUNDE_SATZ`, `PKUNDE_SATZ`, `KUNDE_SATZ_SIZE` |
| Satzbild als Kommentar und Konstanten | `KUNDE_SALDO_OFS = 39; KUNDE_SALDO_LEN = 6;` |
| Zugriffe | `Get_KUNDE_SALDO(r): TDecimal`, `Set_KUNDE_SALDO(r, v, rounding)`, Text `Get_KUNDE_NAME(r [, ccsid]): RawByteString`, OCCURS mit Indizes `Get_POS_MENGE(r, i1)` |
| Stufe 88 | Konstante (einfacher Wert), `Is_KUNDE_AKTIV(r)`, `Set_KUNDE_AKTIV(r)` (SET … TO TRUE) |
| INITIALIZE | `Initialize_KUNDE_SATZ(r [, ccsid])`: Text Leerzeichen, numerisch 0, FILLER X'00' |
| Prüfung | `KUNDE_SATZ_LayoutOk`: SizeOf und alle Offsets zur Laufzeit |
| ODO | `<SATZ>_Length(r)`, wenn die Tabelle mit DEPENDING ON am Satzende steht |

| COBOL | Pascal-Zugriff |
|---|---|
| `PIC X`, `A`, editiert | `RawByteString` (ISO-8859-1), EBCDIC je CCSID, rechts gekürzt / aufgefüllt |
| `PIC N` (NATIONAL) | `UnicodeString` (UTF-16 Big-Endian) |
| `PIC 9/S9 … DISPLAY` | `TDecimal` (gezont, SIGN-Klausel beachtet) |
| `COMP-3`, `PACKED-DECIMAL` | `TDecimal` |
| `COMP`, `COMP-4`, `BINARY` | `Int64` (bzw. `TDecimal` mit V), Big-Endian, Schreiben prüft die PIC-Stellen (TRUNC(STD)) |
| `COMP-5` | wie COMP, ohne Stellenprüfung |
| `COMP-1`, `COMP-2` | `Double`; Standard HFP (COBOL `FLOAT(HEX)`), mit `--float ieee` IEEE Big-Endian |
| `POINTER`, `INDEX` | `Int64`, 4 Byte (`--pointer 8` für LP64) |

- REDEFINES → varianter Record `<FELD>_R` (Zugriff im Record: `r.AUF_ADRESSE_R.AUF_POSTFACH`;
  die Get_/Set_ kennen den Weg). FILLER → `FILLER_n` (keine Zugriffe). Pascal-Schlüsselwörter
  bekommen `_` (`TYPE` → `TYPE_`); doppelte Namen in verschiedenen Gruppen werden mit dem
  Gruppennamen qualifiziert.
- SYNC: Füllbytes `SLACK_<ofs>` vor dem Feld, Ausrichtung relativ zum Satzanfang (2/4 Byte,
  8-Byte-Binärfelder auf 8 – mit `--sync8 4` auf 4; **mit der MAP des COBOL-Compilers
  vergleichen**, auf z/OS noch nicht geprüft), in Tabellen Füllbytes je Wiederholung.
- Nicht unterstützt (Fehlermeldung bzw. Warnung): `COPY … REPLACING` (nicht aufgelöst), Stufe 66,
  `P` rechts der Ziffern (negativer Scale), 88 mit THRU bei Textfeldern (Sortierfolge EBCDIC),
  VALUE-Klauseln außerhalb von 88 (werden übergangen), `USAGE NATIONAL` mit `PIC 9`,
  Binärfelder > 18 Stellen.
- Laufzeit: Units `zoscobol` (Binär, HFP, Text, NATIONAL), `zosdecimal`, `zosccsid`.

Tests: `tests/test_copybook2pas.py` (Satzbilder von vier Beispiel-Copybooks in
`tests/copybooks/`, von Hand nach den COBOL-Regeln berechnet; Fehlerfälle; erzeugte Units
aktuell) und `pf8/cobtest.pas` (Bytebilder wie aus einem COBOL-Programm, HFP-Werte, 88, OCCURS,
REDEFINES, ODO, 10 000 HFP-/IEEE-Rundreisen). Die Units `pf8/cb_*.pas` sind erzeugt:
`for f in kunde auftrag sync divers; do python3 scripts/copybook2pas.py --unit cb_$f -o pf8/cb_$f.pas tests/copybooks/$f.cpy; done`.

## Db2 über ODBC/CLI: Unit `zosdb2cli`

```pascal
uses zosdecimal, zosdb2cli;
var c: TDb2Connection; st: TDb2Statement;
begin
  c := TDb2Connection.Create;
  c.Connect('DB2A');                                  { AUTOCOMMIT aus }
  st := c.NewStatement;
  st.Prepare('SELECT NAME, SALDO FROM KUNDE WHERE SALDO > ?');
  st.SetDecimal(1, TDecimal.FromString('1000.00'), 11);
  st.Execute;
  while st.Fetch do
    writeln(st.AsString(1), ' ', st.AsDecimal(2).ToString);
  st.Free;
  c.Commit;
  c.Free;
end.
```

- **CLI-Funktionen** wie in `sqlcli1.h`: `SQLAllocHandle`, `SQLFreeHandle`, `SQLSetEnvAttr`,
  `SQLSetConnectAttr`, `SQLGetConnectAttr`, `SQLSetStmtAttr`, `SQLConnect`, `SQLDriverConnect`,
  `SQLDisconnect`, `SQLExecDirect`, `SQLPrepare`, `SQLExecute`, `SQLBindParameter`, `SQLBindCol`,
  `SQLFetch`, `SQLGetData`, `SQLNumResultCols`, `SQLDescribeCol`, `SQLRowCount`, `SQLNumParams`,
  `SQLGetDiagRec`, `SQLEndTran`, `SQLFreeStmt`, `SQLCloseCursor`, `SQLMoreResults`, `SQLCancel`,
  `SQLGetInfo`, `SQLTables`, `SQLColumns`; Konstanten nach ODBC 3 (+ Db2: `SQL_BLOB`, `SQL_CLOB`,
  `SQL_GRAPHIC`, `SQL_VARGRAPHIC`).
- **Klassen:** `TDb2Connection` (`Connect`, `DriverConnect`, `Commit`, `Rollback`, `ExecSQL`,
  `SetAutoCommit`, `DbmsName`), `TDb2Statement` (`Prepare`, `SetText`/`SetInt64`/`SetDouble`/
  `SetDecimal`/`SetNull`, `Execute`, `ExecDirect`, `Fetch`, `AsString`/`AsInt64`/`AsDecimal`/
  `AsDouble`/`IsNull`, `ColumnName`, `RowCount`), Fehler als `EDb2Error` mit `SqlState`,
  `NativeError` (= SQLCODE) und dem Text aller Diagnosesätze. DECIMAL geht als Text hin und
  zurück (keine Gleitkommarundung), `TDecimal` aus `zosdecimal`.
- **Typen:** auf z/OS aus `rtl/zosdb2cli_zos.inc` – **noch nicht gemessen** (Annahme: ODBC 3
  für LP64, `SQLLEN` 8 Byte, Handles als 4-Byte-Ganzzahl wie traditionell bei Db2). Auf anderen
  Plattformen unixODBC (Handles = Zeiger); so lässt sich die Pascal-Seite lokal testen.

### Einstiegsnamen, Binden

- 64-Bit-ODBC-Programme binden gegen die DLL **DSNAO64C** (Sidedeck `<db2hlq>.SDSNMACS(DSNAO64C)`);
  DSNAO64W ist die Variante mit den Unicode-„W“-Funktionen. `zfpc --db2` (oder `ZOS_DB2=1`) lässt
  `zos-ld` das Sidedeck dazunehmen: `ZOS_DB2HLQ` (Standard `DSN`) und `ZOS_DB2_SIDEDECK` (Standard
  `DSNAO64C`) in `.zos.env`.
- Die Unit ruft die Funktionen unter ihren C-Namen (`SQLConnect`, …). Ob `sqlcli1.h` im
  ASCII-/64-Bit-Modus andere externe Namen vergibt (`#pragma map`), ist **nicht geprüft**:
  `gen-zosmap.py` übernimmt sie, wenn `ZOS_DB2_INCLUDE` auf die Header zeigt (dann landen sie in
  `zosmap.txt`, und der Compiler ersetzt die Namen wie bei der C-Laufzeit). Meldet `ld`
  IEW2456E für `SQL…`, ist genau das der Fall oder das Sidedeck fehlt.
- Programme im ASCII-Modus brauchen `CURRENTAPPENSCHEME=ASCII` in der Initialisierungsdatei;
  Zeichendaten kommen dann in der ASCII-CCSID des Subsystems (DSNHDECP) – für die RTL passt
  ISO-8859-1 (819); bei einer anderen ASCII-CCSID (z. B. 1252) weichen einzelne Zeichen ab.

### Einmalig auf z/OS

1. Header holen (für Messprogramm und `gen-zosmap.py`), z. B. unter z/OS UNIX:
   `for m in SQLCLI1 SQLCLI SQLSYSTM; do cp "//'DSN.SDSNC.H($m)'" /tmp/$m.h; iconv -f IBM-1047 -t ISO8859-1 /tmp/$m.h > /tmp/$(echo $m | tr A-Z a-z).h; done`
   und die drei `.h` nach `~/zos/db2include` übertragen (lizenziert, nicht ins Repo).
2. Messen (ersetzt die Annahmen):
   ```sh
   cd pf8
   $ZOS_CLANG --target=s390x-ibm-zos -O1 -mzos-sys-include=$HOME/zos/include \
     -I$HOME/zos/db2include -D__CHARSET_LIB=1 -D_ALL_SOURCE -D_UNIX03_SOURCE \
     -c db2probe_c.c -o db2probe_c.o
   sh ../scripts/zfpc db2probe.pas && ./db2probe > ../rtl/zosdb2cli_zos.inc
   ```
   Erwartet: eine vollständige Include-Datei mit „Gemessen: ja“; im Kommentar alle Prototypen
   `OK` (sonst die Deklaration in `rtl/zosdb2cli.pp` anpassen) und keine Konstante mit
   „<- Unit:“. Danach `ZOS_DB2_INCLUDE=$HOME/zos/db2include sh scripts/build-rtl.sh` (neue
   `zosmap.txt` und Units) und `zos-install-rtl.sh`.
3. Plan **DSNACLI**: meist vom Db2-Systemprogrammierer gebunden (Installationsjob DSNTIJCL);
   sonst `pf8/dsnacli-bind.jcl` anpassen. Der Benutzer braucht `EXECUTE` auf den Plan und die
   Rechte für die Testtabelle (CREATE TABLE im Standard-Datenbankbereich oder eine eigene
   Datenbank, 3. Argument von db2test).
4. Initialisierungsdatei nach `pf8/dsnaoini.txt` (Subsystem `DB2A` ersetzen) z. B. als
   `$ZOS_DIR/dsnaoini` ablegen; in `.zos.env`:
   `ZOS_DB2HLQ=DSN`, `ZOS_DB2_STEPLIB=DSN.SDSNEXIT:DSN.SDSNLOAD:DSN.SDSNLOD2`,
   `ZOS_DB2_INI=<pfad>/dsnaoini` (das Start-Skript setzt daraus STEPLIB und DSNAOINI).

### Test `db2test`

```sh
cd pf8
sh ../scripts/zfpc --db2 -O2 db2test.pas
./db2test DB2A                         # Tabelle PASTEST im Standard-Bereich
./db2test DB2A HLQ.PASTEST "IN DATABASE DBTEST"
```

Erwartet: `verbunden mit DB2` (Produktname aus SQLGetInfo), 13 Prüfungen, `Fehler: 0`, rc 0;
die Zeile `erwarteter Fehler: SQLSTATE 42704, SQLCODE -204` (Tabelle fehlt). Batch:
`ZOS_PDS=DB2TEST sh ../scripts/zfpc --db2 db2test.pas`, dann `pf8/db2test.jcl` (Platzhalter
ersetzen) einreichen oder `ZOS_BATCH_STEPLIB=DSN.SDSNEXIT:DSN.SDSNLOAD:DSN.SDSNLOD2
ZOS_BATCH_DD=<datei mit //DSNAOINI DD ...> sh ../scripts/zos-batch.sh DB2TEST DB2A`.
**Auf z/OS noch nicht getestet** – mögliche Stolpersteine in dieser Reihenfolge: Typgrößen
(Messprogramm), Einstiegsnamen (IEW2456E), DLL nicht gefunden (STEPLIB, CEE3501S), ODBC
ohne `CURRENTAPPENSCHEME=ASCII` (unlesbare Texte), fehlende Rechte (SQLCODE -551/-922).

Lokal (x86_64, unixODBC + SQLite, CI-Schritt `x86`):
`./db2test "DRIVER=SQLite3;Database=/tmp/db2test.db"` → 13/13.

### SQLDB-Connector (fcl-db)

Nicht umgesetzt. Weg, sobald die Unit auf z/OS läuft: eine `TSQLConnection`-Ableitung nach dem
Muster von `TODBCConnection` (`packages/fcl-db/src/sqldb/odbc/odbcconn.pas`), die statt der
dynamisch geladenen `odbcsql` die Deklarationen von `zosdb2cli` benutzt (dort sind Handles
Zeiger, bei Db2 z/OS vermutlich Ganzzahlen – deshalb nicht einfach `odbcconn` mit DSNAO64C).
