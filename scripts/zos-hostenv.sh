# zos-hostenv.sh: Umgebung des lokalen Rechners für die z/OS-Skripte (zos-ld, zos-sh,
# zos-put, zos-batch.sh, zos-install-rtl.sh und die Start-Skripte von zos-ld); wird mit
# "." eingelesen.
#
# Zwei Arten:
#   wsl    (Standard, wenn wslpath und cmd.exe da sind): ssh.exe/sftp.exe von Git für
#          Windows (der Schlüssel liegt unter Windows), Dateien für sftp.exe im
#          Windows-Temp, .zos.env mit HOME = Windows-Profil (msys-Pfade)
#   linux  (sonst, z. B. der Self-Hosted-Runner der CI): ssh/sftp, $TMPDIR bzw. /tmp,
#          HOME bleibt
# Vorgeben mit ZOS_HOSTENV=wsl|linux; ssh/sftp mit ZOS_SSH/ZOS_SFTP.
if [ -z "$ZOS_HOSTENV" ]; then
  if command -v wslpath >/dev/null 2>&1 && command -v cmd.exe >/dev/null 2>&1; then
    ZOS_HOSTENV=wsl
  else
    ZOS_HOSTENV=linux
  fi
fi
if [ "$ZOS_HOSTENV" = wsl ]; then
  # ssh.exe/sftp.exe von Git für Windows (msys-Pfade aus .zos.env), auch wenn der Aufrufer
  # (z. B. VS Code) das Windows-OpenSSH zuerst im PATH hat
  G="${ZOS_GIT_BIN:-/mnt/c/Program Files/Git/usr/bin}"; [ -x "$G/ssh.exe" ] && PATH="$G:$PATH"
  ZOS_SSH=${ZOS_SSH:-ssh.exe}
  ZOS_SFTP=${ZOS_SFTP:-sftp.exe}
else
  ZOS_SSH=${ZOS_SSH:-ssh}
  ZOS_SFTP=${ZOS_SFTP:-sftp}
fi

# HOME zum Einlesen von .zos.env (WSL: Windows-Profil in msys-Form)
zos_winhome() {
  if [ "$ZOS_HOSTENV" = wsl ]; then
    wslpath -u "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" | sed 's|^/mnt/\([a-z]\)/|/\1/|'
  else
    echo "$HOME"
  fi
}

# Verzeichnis für Dateien, die sftp lesen muss (WSL: Windows-Temp)
zos_wintemp() {
  if [ "$ZOS_HOSTENV" = wsl ]; then
    wslpath -u "$(cmd.exe /c 'echo %TEMP%' 2>/dev/null | tr -d '\r')"
  else
    echo "${TMPDIR:-/tmp}"
  fi
}

# Pfad einer lokalen Datei, wie sftp ihn erwartet (WSL: Windows-Pfad)
zos_winpath() {
  if [ "$ZOS_HOSTENV" = wsl ]; then
    wslpath -m "$1"
  else
    echo "$1"
  fi
}
