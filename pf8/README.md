# PF8: Produktion – Geschäftsdaten, Db2, COBOL-Interop

Stand 04.10.2026 (Port-Version 0.9.0). Entstanden ohne z/OS-Zugang: alles, was nur auf
z/OS geprüft werden kann, ist ausdrücklich als **auf z/OS noch nicht getestet** markiert.
Die portablen Teile sind auf x86_64-linux getestet (`tests/run-x86.sh`, CI-Schritt `x86`).

| Teil | Dateien | x86_64 | z/OS |
|---|---|---|---|
| EBCDIC-Codepages (CCSID) | `runtime/zosdsn.c`, `runtime/zosccsid.h`, `rtl/zosccsid.pp`, Unit `zosebcdic` (FPC-Patch 0044), `scripts/gen-ccsid.py` | getestet (`ccsidtest` 17/17, C-Prüfstand 131/131, `tests/test_ccsid.py`) | noch nicht getestet |
| Gepackte/gezonte Dezimalzahlen | `rtl/zosdecimal.pp`, `rtl/zosdecimalbcd.pp` | getestet (`dectest` 110/110) | noch nicht getestet |
| Copybook → Pascal | `scripts/copybook2pas.py`, `rtl/zoscobol.pp`, `tests/copybooks/` | getestet (`cobtest` 60/60, `tests/test_copybook2pas.py`) | noch nicht getestet |

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
