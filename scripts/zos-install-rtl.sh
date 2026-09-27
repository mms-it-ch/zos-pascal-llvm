#!/bin/sh
# Installiert die RTL-Objekte (GOFF) als z/OS-ar-Archiv $ZOS_DIR/lib/libfpc.a.
# zos-ld bindet dann gegen das Archiv (ld nimmt nur die benötigten Member) statt
# bei jedem Programm alle RTL-Objekte hochzuladen. In WSL ausführen.
#
# Lokal wird $U/.zos-installed mit der Prüfsumme der Objekte geschrieben; passt sie
# nicht mehr (RTL neu gebaut), lädt zos-ld wieder die Objekte selbst hoch.
set -e
SELF=$(readlink -f "$0")
REPO=$(dirname "$SELF")/..
PREFIX=${ZFPC_PREFIX:-$HOME/opt/zfpc}
U=$PREFIX/units/zos
ENVFILE=${ZOS_ENV:-$REPO/.zos.env}
WH=$(wslpath -u "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" | sed 's|^/mnt/\([a-z]\)/|/\1/|')
HOME=$WH . "$ENVFILE"
DIR=${ZOS_DIR:-/u/zuser/ZPAS}
SSHOPT="-i $ZOS_KEY -o BatchMode=yes"

WTMP=$(wslpath -u "$(cmd.exe /c 'echo %TEMP%' 2>/dev/null | tr -d '\r')")
T=$WTMP/zfpc-rtl.$$.tar
( cd "$U" && tar --format=ustar -cf "$T" ./*.o )
echo "put $(wslpath -m "$T") $DIR/rtl.tar" | sftp.exe -q $SSHOPT -b - "$ZOS_HOST" >/dev/null
rm -f "$T"
ssh.exe $SSHOPT "$ZOS_HOST" "cd $DIR && rm -rf rtl && mkdir -p rtl lib && cd rtl && pax -rf ../rtl.tar && \
  rm -f ../lib/libfpc.a && ar -rc ../lib/libfpc.a *.o && cd .. && rm -rf rtl rtl.tar && ls -l lib/libfpc.a" \
  | sed -E 's|/u/[A-Za-z0-9]+/|/u/<u>/|'
( cd "$U" && cat ./*.o | md5sum | cut -d' ' -f1 ) > "$U/.zos-installed"
echo "RTL installiert ($(ls "$U"/*.o | wc -l) Objekte)"
