#!/bin/sh
# Installiert die RTL-Objekte (GOFF) als z/OS-ar-Archiv $ZOS_DIR/lib/libfpc.a.
# zos-ld bindet dann gegen das Archiv (ld nimmt nur die benötigten Member) statt
# bei jedem Programm alle RTL-Objekte hochzuladen. In WSL ausführen.
#
# Lokal wird $U/.zos-installed mit der Prüfsumme der Objekte geschrieben; passt sie
# nicht mehr (RTL neu gebaut), lädt zos-ld wieder die Objekte selbst hoch.
set -e
# ssh.exe/sftp.exe von Git für Windows (msys-Pfade aus .zos.env), auch wenn der Aufrufer
# (z. B. VS Code) das Windows-OpenSSH zuerst im PATH hat
G="${ZOS_GIT_BIN:-/mnt/c/Program Files/Git/usr/bin}"; [ -x "$G/ssh.exe" ] && PATH="$G:$PATH"
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
# In Paketen zu je 100 Objekten hochladen und sofort auspacken: Archiv und ausgepackte
# Objekte liegen sonst gleichzeitig im ZFS (rund 90 MB). Bei einem Fehler (z. B. ZFS voll)
# das eigene Zwischenzeug (rtl, rtl.tar) entfernen und abbrechen - libfpc.a bleibt dann alt.
MASK='s|/u/[A-Za-z0-9]+/|/u/<u>/|g; s|\([A-Z0-9#$@]+\.|(<u>.|g; s|^(-[-rwx]+ +[0-9]+ +)[A-Z0-9#$@]+|\1<u>|'
fail() {
  ssh.exe $SSHOPT "$ZOS_HOST" "cd $DIR; rm -rf rtl rtl.tar; df -k ." 2>&1 | sed -E "$MASK"
  rm -f "$T"
  echo "FEHLER: RTL nicht installiert ($1; Platz im ZFS? df oben)" >&2
  exit 1
}
ssh.exe $SSHOPT "$ZOS_HOST" "cd $DIR && rm -rf rtl rtl.tar && mkdir -p rtl lib" || fail "Vorbereitung"
( cd "$U" && ls ./*.o ) | split -l 100 - "$WTMP/zfpc-rtl.$$.part."
for part in "$WTMP"/zfpc-rtl.$$.part.*; do
  ( cd "$U" && tar --format=ustar -cf "$T" -T "$part" ) || fail "tar"
  rm -f "$part"
  echo "put $(wslpath -m "$T") $DIR/rtl.tar" | sftp.exe -q $SSHOPT -b - "$ZOS_HOST" >/dev/null || fail "sftp"
  ssh.exe $SSHOPT "$ZOS_HOST" "cd $DIR/rtl && pax -rf ../rtl.tar && rm -f ../rtl.tar" || fail "pax"
done
rm -f "$T" "$WTMP"/zfpc-rtl.$$.part.*
OUT=$(ssh.exe $SSHOPT "$ZOS_HOST" "cd $DIR && rm -f lib/libfpc.a && cd rtl && ar -rc ../lib/libfpc.a *.o && \
  cd .. && rm -rf rtl && ls -l lib/libfpc.a && echo INSTALL-OK || { cd $DIR; rm -rf rtl rtl.tar; df -k .; }" 2>&1 \
  | sed -E "$MASK")
echo "$OUT" | grep -v INSTALL-OK
if ! echo "$OUT" | grep -q INSTALL-OK; then
  echo "FEHLER: RTL nicht installiert (Platz im ZFS? df oben)" >&2
  exit 1
fi
( cd "$U" && cat ./*.o | md5sum | cut -d' ' -f1 ) > "$U/.zos-installed"
echo "RTL installiert ($(ls "$U"/*.o | wc -l) Objekte)"
