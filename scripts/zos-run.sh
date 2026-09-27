#!/bin/sh
# Lädt GOFF-Objekte nach z/OS (USS), bindet sie mit ld zu einem USS-Programm und startet es.
#   zos-run.sh NAME obj.o [weitere.o ...]      (Ziel: $ZOS_DIR/NAME, Standard /u/zuser/m2)
# Voraussetzungen auf z/OS: $ZOS_DIR/celqmain.o (RENT-CELQMAIN) und $ZOS_DIR/zosmain.o.
# Die ASCII-Ausgabe des Programms wird für die Anzeige über SSH nach IBM-1047 gewandelt.
# Umgebung: ZOS_HOST (zuser@zos.example.com), ZOS_KEY (~/.ssh/zos_rsa),
#           ZOS_LEHLQ (CEE), ZOS_EXTRA (zusätzliche ld-Eingaben, relativ zu ZOS_DIR).
set -e
NAME=$1; shift
# Lokale Zugangsdaten (ZOS_HOST, ZOS_DIR, ZOS_LOADLIB) aus .zos.env im Repo (nicht versioniert)
_ENV="$(cd "$(dirname "$0")/.." && pwd)/.zos.env"; [ -f "$_ENV" ] && . "$_ENV"
HOST=${ZOS_HOST:-zuser@zos.example.com}
KEY=${ZOS_KEY:-$HOME/.ssh/zos_rsa}
DIR=${ZOS_DIR:-/u/zuser/m2}
LE=${ZOS_LEHLQ:-CEE}
SSH="ssh -i $KEY -o BatchMode=yes $HOST"
{ echo "cd $DIR"; for o in "$@"; do echo "put $o"; done; } |
  sftp -q -i "$KEY" -o BatchMode=yes -b - "$HOST" >/dev/null
objs=""; for o in "$@"; do objs="$objs $(basename "$o")"; done
# Objekte vom eigenen LLVM-Build bringen CELQMAIN (+ Referenz auf CELQBST) selbst mit
HELPERS="zosmain.o celqmain.o \"//'$LE.SCEEBND2(CELQBST)'\""
for o in "$@"; do
  python "$(dirname "$0")/goffdump.py" "$o" | tr -d '\r' | grep -q "LD parent=[0-9]* *CELQMAIN$" && HELPERS=""
done
$SSH "cd $DIR && ld -b AMODE=64 -b CASE=MIXED -b DYNAM=DLL -b REUS=RENT -b MAP -b XREF \
  -e CELQSTRT -V -o $NAME $objs $HELPERS $ZOS_EXTRA \
  -S \"//'$LE.SCEEBND2'\" \
  \"//'$LE.SCEELIB(CELQS001)'\" \"//'$LE.SCEELIB(CELQS003)'\" > $NAME.map 2>&1 \
  || { echo 'ld fehlgeschlagen (Meldungen nach Art, Anzahl):';
       grep -E 'IEW2[0-9]+[EWS]' $NAME.map | cut -c2-9 | sort | uniq -c;
       grep -E 'IEW2(353|307)E|IEW2[0-9]+S' $NAME.map | head -6;
       grep -E 'IEW2456E' $NAME.map | head -5; exit 1; }
  grep -E 'IEW2[0-9]+[WS]' $NAME.map | head -10
  ./$NAME > $NAME.out 2> $NAME.err; rc=\$?
  iconv -f ISO8859-1 -t IBM-1047 $NAME.out
  [ -s $NAME.err ] && { echo '--- stderr:'; iconv -f ISO8859-1 -t IBM-1047 $NAME.err; }
  echo \"--- rc=\$rc\""
