#!/bin/sh
# PF6: Batch-Test mit DD-Anweisungen (in WSL, im Verzeichnis pf6):
#   1. dsnbat.pas in die PDSE binden (ZOS_PDS=DSNBAT)
#   2. Eingabe-Dataset <Präfix>.ZPAS.TEST.INDATA anlegen (über dsnprep.pas)
#   3. Job einreichen (zos-batch.sh mit dsnbat.dd), erwartet RC=3
#   4. SYSPRINT- und OUTDATA-Dataset zeigen (über dsnshow.pas), alles löschen
cd "$(dirname "$0")" || exit 1
Z=../scripts
export ZOS_RUN_CEEOPTS=${ZOS_RUN_CEEOPTS:-TERMTHDACT(MSG)}
ZOS_PDS=DSNBAT sh $Z/zfpc dsnbat.pas >/dev/null || exit 1
sh $Z/zfpc dsnprep.pas >/dev/null && sh $Z/zfpc dsnshow.pas >/dev/null || exit 1
./dsnprep || exit 1
ZOS_BATCH_DD=dsnbat.dd sh $Z/zos-batch.sh DSNBAT
rc=$?
echo "--- Job-RC: $rc (erwartet 3)"
./dsnshow
exit $rc
