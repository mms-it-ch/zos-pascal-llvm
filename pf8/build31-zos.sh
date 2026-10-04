#!/bin/sh
# build31-zos.sh: läuft auf z/OS UNIX (von pf8/build31.sh hochgeladen und gestartet).
# Baut aus den ASCII-Quellen im aktuellen Verzeichnis:
#   ./zpcall31             AMODE-31-Brücke (z/OS-UNIX-Programm, ohne LE)
#   LOADLIB(ZPASM1)        HLASM-Testprogramm
#   LOADLIB(ZPCOB1)        COBOL-Testprogramm (Copybook KUNDE)
#   LOADLIB(ZPCOB2)        COBOL-Hauptprogramm mit ZP64CALL (CEL4RO64)
#   build31-zos.sh LOADLIB [CEE-HLQ]
# Braucht: as (HLASM), ld, cob2 (Enterprise COBOL); LOADLIB als PDSE (RECFM U).
# Auf z/OS noch nicht getestet.
set -e
LIB=$1; CEE=${2:-CEE}
[ -n "$LIB" ] || { echo "usage: build31-zos.sh LOADLIB [CEE-HLQ]" >&2; exit 2; }
mkdir -p e
for f in zpcall31.s zpasm1.s zp64call.s zpcob1.cbl zpcob2.cbl kunde.cpy; do
  iconv -f ISO8859-1 -t IBM-1047 "$f" > "e/$f"
done
cd e
echo "== Brücke zpcall31"
as -o zpcall31.o zpcall31.s
ld -b AMODE=31 -b RMODE=ANY -e ZPCALL31 -o ../zpcall31 zpcall31.o -S "//'SYS1.CSSLIB'"
echo "== ZPASM1"
as -o zpasm1.o zpasm1.s
ld -b AMODE=31 -b RMODE=ANY -e ZPASM1 -o "//'$LIB(ZPASM1)'" zpasm1.o
echo "== ZPCOB1"
cob2 -c -I. zpcob1.cbl
cob2 -o "//'$LIB(ZPCOB1)'" zpcob1.o
echo "== ZP64CALL + ZPCOB2"
as -I "//'$CEE.SCEEMAC'" -o zp64call.o zp64call.s
cob2 -c -I. zpcob2.cbl
cob2 -o "//'$LIB(ZPCOB2)'" zpcob2.o zp64call.o
echo "fertig"
