#!/bin/sh
# build31.sh: AMODE-31-Teile von PF8 auf z/OS bauen (Brücke, HLASM- und COBOL-Programme)
# und die Pascal-Seite übersetzen. Lokal ausführen (WSL oder Linux), Zugangsdaten aus
# .zos.env; ZOS_LOAD31 = PDSE für die AMODE-31-Programme (Standard <ZOS_PASLIB>31 ist
# nicht sinnvoll: bitte setzen, z. B. HLQ.ZPAS.LOAD31).
#   sh pf8/build31.sh
# Danach (pf8/README.md): ./call31test, Batch-Job pf8/call64.jcl.
# Auf z/OS noch nicht getestet.
set -e
R=$(cd "$(dirname "$0")/.." && pwd)
[ -n "$ZOS_LOAD31" ] || { echo "ZOS_LOAD31 setzen (PDSE für ZPASM1/ZPCOB1/ZPCOB2)" >&2; exit 2; }
# Arbeitsverzeichnis auf z/OS: ZOS_DIR/b31
D=$(sh "$R/scripts/zos-sh" "mkdir -p b31 && cd b31 && pwd" | tr -d '\r')
for f in pf8/zpcall31.s pf8/zpasm1.s pf8/zp64call.s pf8/zpcob1.cbl pf8/zpcob2.cbl \
         tests/copybooks/kunde.cpy pf8/build31-zos.sh; do
  sh "$R/scripts/zos-put" "$R/$f" "$D/$(basename "$f")"
done
sh "$R/scripts/zos-sh" "cd b31 && sh build31-zos.sh $ZOS_LOAD31 \${ZOS_LEHLQ:-CEE} && cp zpcall31 .. && cd .. && rm -rf b31"
cd "$R/pf8"
sh ../scripts/zfpc -O2 call31test.pas
sh ../scripts/zfpc -O2 call64lib.pas
