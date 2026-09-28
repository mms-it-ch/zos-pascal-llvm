#!/bin/sh
# PF6: rectest.pas (satzweise E/A, VSAM) auf z/OS: KSDS mit IDCAMS anlegen, Test,
# KSDS löschen. In WSL, im Verzeichnis pf6.
cd "$(dirname "$0")" || exit 1
Z=../scripts
KSDS="\$(id -un | tr a-z A-Z).ZPAS.TEST.KSDS"
sh $Z/zos-sh "tsocmd \"DELETE '$KSDS' CLUSTER\" >/dev/null 2>&1;
  tsocmd \"DEFINE CLUSTER(NAME('$KSDS') INDEXED KEYS(8 0) RECORDSIZE(80 80) TRACKS(1 1))\" 2>&1 |
  grep -E 'IDC0001I|IDC3' | head -3"
sh $Z/zfpc rectest.pas >/dev/null || exit 1
ZOS_RUN_CEEOPTS=${ZOS_RUN_CEEOPTS:-TERMTHDACT(MSG)} ./rectest
rc=$?
sh $Z/zos-sh "tsocmd \"DELETE '$KSDS' CLUSTER\" 2>&1 | grep -E 'IDC0550I|IDC3' | head -2"
exit $rc
