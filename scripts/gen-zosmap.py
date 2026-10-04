#!/usr/bin/env python3
"""Erzeugt zosmap.txt für den FPC-Compiler (Target zos).

Die z/OS-C-Header geben im ASCII-Modus vielen C-RTL-Funktionen per
`#pragma map` einen anderen externen Namen (fopen -> @@A00246). Das Skript
lässt clang die Header mit den Makros des ASCII-Modus (DEFINES)
vorverarbeiten, sammelt die aktiven `#pragma map` ein und
schreibt Zeilen "<name> <externer Name>".

Die Tabelle stammt aus den (lizenzierten) z/OS-Headern und wird deshalb nicht
versioniert, sondern lokal erzeugt:
    gen-zosmap.py > <RTL-Unit-Verzeichnis>/zosmap.txt
Umgebung: ZOS_CLANG (Standard ~/build/llvm-zos/bin/clang),
          ZOS_INCLUDE (Standard ~/zos/include),
          ZOS_DB2_INCLUDE: Verzeichnis mit den Db2-ODBC-Headern (sqlcli1.h, sqlcli.h,
          sqlsystm.h aus <db2hlq>.SDSNC.H, nach ISO-8859-1 gewandelt); dann werden auch
          deren #pragma map übernommen (Unit zosdb2cli).
"""
import os
import re
import subprocess
import sys
import tempfile

CLANG = os.environ.get("ZOS_CLANG", os.path.expanduser("~/build/llvm-zos/bin/clang"))
INCLUDE = os.environ.get("ZOS_INCLUDE", os.path.expanduser("~/zos/include"))
DB2_INCLUDE = os.environ.get("ZOS_DB2_INCLUDE", "")
# ASCII-Modus, UNIX-/SUSv3-Schnittstellen, alle
# Zeichenkettenfunktionen auf die ASCII-Einstiege, C-RTL-Variablen über Funktionen
DEFINES = ["-D__CHARSET_LIB=1", "-D_ALL_SOURCE", "-D_UNIX03_SOURCE", "-D_SHARE_EXT_VARS",
           "-D_ENHANCED_ASCII_EXT=0xFFFFFFFF", "-D_LARGE_TIME_API", "-D_UNIX03_THREADS",
           "-D_XOPEN_SOURCE_EXTENDED=1"]
HEADERS = """stdio.h stdlib.h string.h strings.h ctype.h wchar.h wctype.h locale.h
langinfo.h iconv.h time.h math.h errno.h signal.h setjmp.h stdarg.h
unistd.h fcntl.h sys/types.h sys/stat.h sys/wait.h sys/time.h sys/times.h
sys/utsname.h sys/resource.h sys/mman.h sys/ioctl.h sys/select.h poll.h
dirent.h utime.h termios.h pwd.h grp.h dlfcn.h pthread.h semaphore.h
fnmatch.h glob.h regex.h libgen.h spawn.h sys/ipc.h sys/shm.h sys/sem.h
sys/msg.h sys/socket.h netdb.h netinet/in.h arpa/inet.h sys/statvfs.h
sys/uio.h syslog.h""".split()

PRAGMA_MAP = re.compile(r'^\s*#\s*pragma\s+map\s*\(\s*(\w+)\s*,\s*"((?:[^"\\]|\\.)*)"\s*\)', re.M)


def c_unescape(s):
    """Oktal-Escapes sind EBCDIC-Bytes (\\174 = X'7C' = '@')."""
    return re.sub(r"\\([0-7]{1,3}|.)",
                  lambda m: bytes([int(m.group(1), 8)]).decode("cp037")
                  if m.group(1)[0] in "01234567" else m.group(1),
                  s)


def main():
    with tempfile.NamedTemporaryFile("w", suffix=".c", delete=False) as t:
        for h in HEADERS:
            if os.path.exists(os.path.join(INCLUDE, h)):
                t.write(f"#include <{h}>\n")
        extra = []
        if DB2_INCLUDE and os.path.exists(os.path.join(DB2_INCLUDE, "sqlcli1.h")):
            t.write("#include <sqlcli1.h>\n")
            extra = ["-I", DB2_INCLUDE]
        src = t.name
    try:
        out = subprocess.run([CLANG, "--target=s390x-ibm-zos", "-trigraphs",
                              f"-mzos-sys-include={INCLUDE}", *extra, *DEFINES, "-E", src],
                             capture_output=True, text=True, encoding="latin-1")
    finally:
        os.unlink(src)
    if out.returncode:
        sys.stderr.write(out.stderr)
        sys.exit(out.returncode)
    names = {}
    for name, ext in PRAGMA_MAP.findall(out.stdout):
        ext = c_unescape(ext)
        if ext != name:
            names.setdefault(name, ext)
    print("# z/OS C-RTL: externe Namen im ASCII-Modus (aus den z/OS-Headern erzeugt)")
    for name in sorted(names):
        print(name, names[name])
    sys.stderr.write(f"{len(names)} Namen\n")


if __name__ == "__main__":
    main()
