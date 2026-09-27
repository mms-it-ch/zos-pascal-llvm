#!/usr/bin/env python3
"""Erzeugt rtl/zos/errno.inc (ESys*-Konstanten) aus dem z/OS-Header errno.h.

    gen-errno.py > ~/src/fpc/rtl/zos/errno.inc
Umgebung: ZOS_CLANG, ZOS_INCLUDE (wie gen-zosmap.py).
"""
import os
import re
import subprocess
import tempfile

CLANG = os.environ.get("ZOS_CLANG", os.path.expanduser("~/build/llvm-zos/bin/clang"))
INCLUDE = os.environ.get("ZOS_INCLUDE", os.path.expanduser("~/zos/include"))

HEADER = """{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2026 by the Free Pascal development team.

    z/OS error numbers, generated from the z/OS C header errno.h
    by scripts/gen-errno.py (zos-pascal-llvm)

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

const"""


def main():
    with tempfile.NamedTemporaryFile("w", suffix=".c", delete=False) as t:
        t.write("#include <errno.h>\n")
        src = t.name
    try:
        out = subprocess.run([CLANG, "--target=s390x-ibm-zos", "-trigraphs",
                              f"-mzos-sys-include={INCLUDE}", "-D__CHARSET_LIB=1",
                              "-D_ALL_SOURCE", "-D_UNIX03_SOURCE", "-D_UNIX03_THREADS",
                              "-dM", "-E", src],
                             capture_output=True, text=True, check=True).stdout
    finally:
        os.unlink(src)
    errs = sorted(((int(v), n) for n, v in
                   re.findall(r"^#define (E[A-Z0-9]+) +([0-9]+) *$", out, re.M)))
    print(HEADER)
    for v, n in errs:
        print(f"  ESys{n} = {v};")


if __name__ == "__main__":
    main()
