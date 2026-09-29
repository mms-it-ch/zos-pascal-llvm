# Testsuite aus freien Pascal-Quellen

Große, fremde Pascal-Programme und -Bibliotheken, übersetzt und ausgeführt **lokal**
(x86_64-linux, normaler FPC aus `~/opt/fpc-main`) und **auf z/OS** (dieser Port). Die Quellen
liegen nur lokal in WSL (`~/src/pascal-suite`), nicht in diesem Repo.

## Quellen

| Projekt | Lizenz | Stand | Tests |
|---|---|---|---|
| [Xor-el/HashLib4Pascal](https://github.com/Xor-el/HashLib4Pascal) | MIT | `8b2cd8de` (2026-09-02) | FPCUnit, Hashes, Prüfsummen, KDF (Argon2, scrypt, PBKDF2), Testvektoren aus `HashLib.Tests/Data` |
| [Xor-el/SimpleBaseLib4Pascal](https://github.com/Xor-el/SimpleBaseLib4Pascal) | MIT | `bcbb404f` (2026-09-03) | FPCUnit, Base16/32/58/64/85 |
| [Xor-el/CryptoLib4Pascal](https://github.com/Xor-el/CryptoLib4Pascal) | MIT | `692644d7` (2026-09-27) | FPCUnit, Kryptografie (braucht HashLib, SimpleBaseLib) |
| Computer Language Benchmarks Game, `benchmarksgame-sourcecode.zip` ([salsa.debian.org](https://salsa.debian.org/benchmarksgame-team/benchmarksgame)) | BSD-3-Clause | sha256 `aabcf6726cdc14f0…` | alle Free-Pascal-Programme, Ausgabe gegen `*-output.txt` |

Holen (einmalig):

```
mkdir -p ~/src/pascal-suite && cd ~/src/pascal-suite
for r in HashLib4Pascal SimpleBaseLib4Pascal CryptoLib4Pascal; do git clone --depth 1 https://github.com/Xor-el/$r.git; done
mkdir bench && cd bench && U=https://salsa.debian.org/benchmarksgame-team/benchmarksgame/-/raw/master/public/download
curl -LO $U/benchmarksgame-sourcecode.zip   # dazu <aufgabe>-output.txt / -input.txt
```

## Bedienung

```
python3 suite/suite.py build --target local|zos [projekt ... | bench]
python3 suite/suite.py run   --target local|zos [projekt ... | bench]
```

- Suchpfade, Syntaxmodus und Pakete kommen aus den Lazarus-Dateien (`.lpi`, `.lpk`);
  ohne Angabe gilt die Lazarus-Voreinstellung `-MObjFPC -Scghi`.
- Dateinamen, die anders geschrieben sind als in `uses` (unter Windows egal): Verzeichnis mit
  kleingeschriebenen Verknüpfungen im Suchpfad.
- Lokal ohne Optimierung (`SUITE_LOCAL_OPT`, Standard `-O-`), z/OS mit `-O2` (`SUITE_ZOS_OPT`).
- z/OS: Testdaten per tar+sftp nach `ZOS_DIR/suite/<projekt>` (Dateien über 4 MB bleiben lokal),
  Lauf per ssh; nach jedem Programm werden die Dump-Datasets gezählt, bei einem neuen bricht die
  Suite ab.
- Ergebnisse: `suite/results-local.txt`, `suite/results-zos.txt`, Protokolle in
  `~/build/suite/<target>/<projekt>/`.

## Befunde beim Aufbau

- **FPC x86_64, `-O2`:** CryptoLib hat 53 Fehler (Zugriffsverletzungen bei elliptischen Kurven),
  ohne Optimierung 0 → lokale Referenz ohne Optimierung.
- **Interface-Wrapper im LLVM-Modus (FPC-Patch 0038):** Liegt die Unit der Elternklasse nicht im
  Sichtbereich (nur von der Unit einer Zwischenklasse benutzt), fand der erzeugte Wrapper-Code
  sie nicht (HashLib: `Identifier not found "HLPHASH"`). Behoben.
- **Offen, CryptoLib auf z/OS:** Im LLVM-Modus erzeugt FPC die Interface-Wrapper einer Klasse
  (`TX509DefaultEntryConverter`) beim Übersetzen einer anderen Unit
  (`ClpX509Asn1Objects`, Kreisabhängigkeit über den Implementierungsteil); dort ist der Aufruf
  `GetConvertedValue` mehrdeutig. Auch mit dem x86_64-LLVM-FPC (Hauptzweig), mit dem normalen
  x86_64-FPC nicht. Kleiner Nachbau gelang noch nicht.
- Ausgelassen: Benchmarks mit PasMP/MTProcs (nicht freigegeben), `regexredux` (PCRE),
  `pidigits-2/3` auf z/OS (GMP).
