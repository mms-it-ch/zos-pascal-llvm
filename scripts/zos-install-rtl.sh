#!/bin/sh
# Installiert die RTL-Objekte (GOFF) als z/OS-ar-Archiv $ZOS_DIR/lib/libfpc.a
# (mit --ns die Units mit Namensraum als lib/libfpcns.a).
# zos-ld bindet dann gegen das Archiv (ld nimmt nur die benötigten Member) statt
# bei jedem Programm alle RTL-Objekte hochzuladen. In WSL ausführen.
#
# Lokal wird $U/.zos-installed mit der Prüfsumme der Objekte geschrieben; passt sie
# nicht mehr (RTL neu gebaut), lädt zos-ld wieder die Objekte selbst hoch.
set -e
SELF=$(readlink -f "$0")
. "$(dirname "$SELF")/zos-hostenv.sh"
REPO=$(dirname "$SELF")/..
PREFIX=${ZFPC_PREFIX:-$HOME/opt/zfpc}
U=$PREFIX/units/zos
LIB=libfpc.a
# --ns (oder ZFPC_DOTTED=1): Units mit Namensraum (units/zos-ns) als lib/libfpcns.a
if [ "$1" = --ns ] || [ "$ZFPC_DOTTED" = 1 ]; then
  U=$PREFIX/units/zos-ns
  LIB=libfpcns.a
fi
ENVFILE=${ZOS_ENV:-$REPO/.zos.env}
WH=$(zos_winhome)
HOME=$WH . "$ENVFILE"
DIR=${ZOS_DIR:-/u/zuser/ZPAS}
SSHOPT="-i $ZOS_KEY -o BatchMode=yes"

WTMP=$(zos_wintemp)
T=$WTMP/zfpc-rtl.$$.tar
# In Paketen zu je 100 Objekten hochladen und sofort auspacken: Archiv und ausgepackte
# Objekte liegen sonst gleichzeitig im ZFS (rund 90 MB). Bei einem Fehler (z. B. ZFS voll)
# das eigene Zwischenzeug (rtl, rtl.tar) entfernen und abbrechen - libfpc.a bleibt dann alt.
MASK='s|/u/[A-Za-z0-9]+/|/u/<u>/|g; s|\([A-Z0-9#$@]+\.|(<u>.|g; s|^(-[-rwx]+ +[0-9]+ +)[A-Z0-9#$@]+|\1<u>|'
fail() {
  $ZOS_SSH $SSHOPT "$ZOS_HOST" "cd $DIR; rm -rf rtl rtl.tar; df -k ." 2>&1 | sed -E "$MASK"
  rm -f "$T"
  echo "FEHLER: RTL nicht installiert ($1; Platz im ZFS? df oben)" >&2
  exit 1
}
$ZOS_SSH $SSHOPT "$ZOS_HOST" "cd $DIR && rm -rf rtl rtl.tar && mkdir -p rtl lib" || fail "Vorbereitung"
( cd "$U" && ls ./*.o ) | split -l 100 - "$WTMP/zfpc-rtl.$$.part."
for part in "$WTMP"/zfpc-rtl.$$.part.*; do
  ( cd "$U" && tar --format=ustar -cf "$T" -T "$part" ) || fail "tar"
  rm -f "$part"
  echo "put $(zos_winpath "$T") $DIR/rtl.tar" | $ZOS_SFTP -q $SSHOPT -b - "$ZOS_HOST" >/dev/null || fail "sftp"
  $ZOS_SSH $SSHOPT "$ZOS_HOST" "cd $DIR/rtl && pax -rf ../rtl.tar && rm -f ../rtl.tar" || fail "pax"
done
rm -f "$T" "$WTMP"/zfpc-rtl.$$.part.*
OUT=$($ZOS_SSH $SSHOPT "$ZOS_HOST" "cd $DIR && rm -f lib/$LIB && cd rtl && ar -rc ../lib/$LIB *.o && \
  cd .. && rm -rf rtl && ls -l lib/$LIB && echo INSTALL-OK || { cd $DIR; rm -rf rtl rtl.tar; df -k .; }" 2>&1 \
  | sed -E "$MASK")
echo "$OUT" | grep -v INSTALL-OK
if ! echo "$OUT" | grep -q INSTALL-OK; then
  echo "FEHLER: RTL nicht installiert (Platz im ZFS? df oben)" >&2
  exit 1
fi
( cd "$U" && cat ./*.o | md5sum | cut -d' ' -f1 ) > "$U/.zos-installed"
echo "RTL installiert ($(ls "$U"/*.o | wc -l) Objekte)"
