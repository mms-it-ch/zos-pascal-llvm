#!/bin/sh
# zos-batch.sh: ein Pascal-Programm (Programmobjekt in der PDSE ZOS_PASLIB) als
# Batch-Job auf z/OS ausführen. In WSL ausführen.
#
#   zos-batch.sh MEMBER [PARM]          Job einreichen, auf das Ende warten, Ausgabe und RC zeigen
#   zos-batch.sh -n MEMBER [PARM]       nur die JCL ausgeben (nicht einreichen)
#   zos-batch.sh -j MEMBER [PARM]       JCL für FTP/JES ausgeben (zos-jes.py): Ausgabe nach
#                                       SYSOUT=* (Spool), ohne RC-Schritte (RC liefert JES)
#
# Das Programm vorher in die PDSE binden:  ZOS_PDS=MEMBER zfpc prog.pas
#
# JCL: JOB-Karte mit REGION=0M,LINES=500000; STEPLIB = ZOS_PASLIB; CEEOPTS POSIX(ON)
# (ASCII-Programme laufen nur mit POSIX(ON)); Standardausgabe und -fehler per DD PATH
# in USS-Dateien unter $ZOS_DIR/batch (die Ausgabeklassen sind hier nicht gehalten).
# Den Returncode schreiben IF-Schritte (BPXBATCH) in eine Datei: genau für RC 0-16 und
# die FPC-Laufzeitfehler 200-232, sonst Bereich; ABEND wird erkannt.
#
# Umgebung: .zos.env (ZOS_HOST, ZOS_KEY, ZOS_DIR, ZOS_PASLIB), ZOS_BATCH_WAIT (Sekunden,
# Standard 300), ZOS_JOBCLASS (A), ZOS_MSGCLASS (X).
# ZOS_BATCH_DD=datei: weitere DD-Anweisungen für den Programmschritt (z. B. SYSIN DD *,
# SYSPRINT auf ein Dataset, Eingabe-/Ausgabe-Datasets); @HLQ@ wird durch das Präfix
# (User-ID) ersetzt, damit sie nicht in der Datei steht. Definiert die Datei STDOUT oder
# SYSPRINT (bzw. STDERR oder SYSOUT), entfallen beide PATH-DDs dieses Paars.
set -e
ONLYJCL=0; JES=0
[ "$1" = -n ] && { ONLYJCL=1; shift; }
[ "$1" = -j ] && { ONLYJCL=1; JES=1; shift; }
MEMBER=$(echo "$1" | tr a-z A-Z); PARM=$2
[ -n "$MEMBER" ] || { echo "usage: zos-batch.sh [-n] MEMBER [PARM]" >&2; exit 2; }
case "$MEMBER" in
  [A-Z@#\$]*) ;;
  *) echo "zos-batch: ungültiger Membername: $MEMBER" >&2; exit 2 ;;
esac
[ ${#MEMBER} -le 8 ] || { echo "zos-batch: Membername länger als 8 Zeichen" >&2; exit 2; }

SELF=$(readlink -f "$0")
. "$(dirname "$SELF")/zos-hostenv.sh"
ENVFILE=${ZOS_ENV:-$(dirname "$SELF")/../.zos.env}
WH=$(zos_winhome)
[ -f "$ENVFILE" ] && HOME=$WH . "$ENVFILE"
HOST=${ZOS_HOST:-zuser@zos.example.com}
KEY=${ZOS_KEY:-$HOME/.ssh/zos_rsa}
DIR=${ZOS_DIR:-/u/zuser/ZPAS}
PASLIB=${ZOS_PASLIB:-ZUSER.ZPAS.LOAD}
SSH=$ZOS_SSH
SFTP=$ZOS_SFTP
SSHOPT="-i $KEY -o BatchMode=yes"
# Jobname: User-ID (bis 7 Zeichen) + 'P'
USERID=$(echo "${HOST%%@*}" | tr a-z A-Z | cut -c1-7)
HLQ=$(echo "${HOST%%@*}" | tr a-z A-Z)
EXTRA=""
if [ -n "$ZOS_BATCH_DD" ]; then
  [ -f "$ZOS_BATCH_DD" ] || { echo "zos-batch: $ZOS_BATCH_DD fehlt" >&2; exit 2; }
  EXTRA=$(sed "s/@HLQ@/$HLQ/g" "$ZOS_BATCH_DD")
fi
# DD-Name in den zusätzlichen DD-Anweisungen definiert?
has_dd() { printf '%s\n' "$EXTRA" | grep -qE "^//$1 +DD "; }
JOB=${USERID}P
B=$DIR/batch
TAG=$MEMBER.$$

jcl() {
  echo "//$JOB JOB (ACCT),'PASCAL BATCH',CLASS=${ZOS_JOBCLASS:-A},MSGCLASS=${ZOS_MSGCLASS:-X},"
  echo "//             NOTIFY=&SYSUID,REGION=0M,LINES=500000"
  echo "//*"
  echo "//* Pascal-Programm $MEMBER aus der PDSE (erzeugt von zos-batch.sh)"
  echo "//*"
  if [ -n "$PARM" ]; then
    echo "//RUN      EXEC PGM=$MEMBER,PARM='/$PARM'"
  else
    echo "//RUN      EXEC PGM=$MEMBER"
  fi
  echo "//STEPLIB  DD DISP=SHR,DSN=$PASLIB"
  echo "//CEEOPTS  DD *"
  echo "POSIX(ON)"
  # weitere LE-Optionen, z. B. ZOS_BATCH_CEEOPTS="ENVAR('ZOS_DSN_DEBUG=1')"
  [ -n "$ZOS_BATCH_CEEOPTS" ] && echo "$ZOS_BATCH_CEEOPTS"
  echo "/*"
  for dd in STDOUT:out STDERR:err SYSPRINT:out SYSOUT:err; do
    name=${dd%%:*}; ext=${dd#*:}
    case $name in
      STDOUT|SYSPRINT) { has_dd STDOUT || has_dd SYSPRINT; } && continue ;;
      STDERR|SYSOUT) { has_dd STDERR || has_dd SYSOUT; } && continue ;;
    esac
    if [ $JES = 1 ]; then
      printf '//%-8s DD SYSOUT=*\n' "$name"
      continue
    fi
    printf '//%-8s DD PATH='"'"'%s'"'"',\n' "$name" "$B/$TAG.$ext"
    echo "//            PATHOPTS=(OWRONLY,OCREAT,OAPPEND),"
    echo "//            PATHMODE=(SIRUSR,SIWUSR)"
  done
  [ -n "$EXTRA" ] && printf '%s\n' "$EXTRA"
  echo "//CEEDUMP  DD SYSOUT=*"
  [ $JES = 1 ] && return
  n=0
  rcstep() {  # Bedingung, Text
    n=$((n+1))
    echo "//         IF ($1) THEN"
    # Befehl per STDPARM (Instream, bis 80 Spalten): mit Pfad wäre PARM zu lang
    printf "//R%-7s EXEC PGM=BPXBATCH\n" "$n"
    echo "//STDPARM  DD *"
    echo "SH echo $2 >$B/$TAG.rc"
    echo "/*"
    echo "//         ENDIF"
  }
  rcstep "RUN.ABEND" "ABEND"
  for rc in $(seq 0 16) $(seq 200 232); do
    rcstep "RUN.RC = $rc" "RC=$rc"
  done
  rcstep "RUN.RC > 16 & RUN.RC < 200" "RC=17-199"
  rcstep "RUN.RC > 232" "RC>232"
}

if [ $ONLYJCL = 1 ]; then
  jcl
  exit 0
fi

# JCL übertragen (ASCII), auf z/OS nach EBCDIC wandeln und einreichen
WTMP=$(zos_wintemp)
TMP=$(mktemp "$WTMP/zos-batch.XXXXXX")
trap 'rm -f "$TMP"' EXIT
jcl > "$TMP"
printf -- '-mkdir %s\nput %s %s/%s.jcl.a\n' "$B" "$(zos_winpath "$TMP")" "$B" "$TAG" |
  $SFTP -q $SSHOPT -b - "$HOST" 2>&1 >/dev/null | grep -v "mkdir.*Failure" >&2 || true
$SSH $SSHOPT "$HOST" sh -s <<EOS
cd $B || exit 1
iconv -f ISO8859-1 -t IBM-1047 $TAG.jcl.a > $TAG.jcl && rm -f $TAG.jcl.a
submit $TAG.jcl 2>&1 | sed 's/.*\(JOB[0-9]*\).*/eingereicht: \1/'
# warten, bis ein IF-Schritt den Returncode geschrieben hat
i=0
while [ ! -s $TAG.rc ] && [ \$i -lt ${ZOS_BATCH_WAIT:-300} ]; do sleep 2; i=\$((i+2)); done
if [ ! -s $TAG.rc ]; then
  echo "zos-batch: kein Ergebnis nach ${ZOS_BATCH_WAIT:-300} s (Job läuft noch oder hängt)"
  exit 3
fi
sleep 1
[ -f $TAG.out ] && iconv -f ISO8859-1 -t IBM-1047 $TAG.out
[ -s $TAG.err ] && { echo '--- stderr:'; iconv -f ISO8859-1 -t IBM-1047 $TAG.err; }
echo "--- \$(cat $TAG.rc)"
res=\$(cat $TAG.rc)
[ -n "$ZOS_BATCH_KEEP" ] || rm -f $TAG.jcl $TAG.out $TAG.err $TAG.rc
case "\$res" in
  RC=[0-9]*) r=\${res#RC=}; case "\$r" in *[!0-9]*) exit 99 ;; *) exit \$r ;; esac ;;
  *) exit 99 ;;
esac
EOS
