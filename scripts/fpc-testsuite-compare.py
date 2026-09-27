#!/usr/bin/env python3
"""Vergleicht die Testsuite-Logs von z/OS (s390x-zos) mit der Referenz (x86_64-linux).

    fpc-testsuite-compare.py verzeichnis...   (z.B. tbs test)

Je Test zählt die letzte Log-Zeile (dotest schreibt z.B. erst "Successfully compiled",
dann "Successfully run" oder "Failed to run"). Ausgabe: Zusammenfassung je Plattform und
die Tests, die nur auf z/OS scheitern (mit Kategorie).
"""
import os
import re
import sys
from collections import Counter

T = os.environ.get("FPCTESTS", os.path.expanduser("~/src/fpc/tests"))
LINE = re.compile(r"^(?P<msg>.*?) (?P<file>\S+\.(?:pp|pas))(?: \d{4}/.*)?$")


def load(target, d):
    res = {}
    try:
        with open(f"{T}/output/{target}/log.{d}log", errors="replace") as f:
            for line in f:
                m = LINE.match(line.rstrip("\n"))
                if m:
                    res[m.group("file")] = m.group("msg")
    except FileNotFoundError:
        pass
    return res


def ok(msg):
    return msg.startswith(("Success", "Skipping"))


def main():
    for d in sys.argv[1:]:
        z, r = load("s390x-zos", d), load("x86_64-linux", d)
        print(f"== {d}: z/OS {len(z)} Tests, Referenz {len(r)} Tests")
        for name, res in (("z/OS", z), ("Referenz", r)):
            c = Counter(("ok" if ok(m) else m) for m in res.values())
            print(f"  {name:9}: " + ", ".join(f"{k}: {v}" for k, v in c.most_common()))
        only = sorted(f for f, m in z.items() if not ok(m) and (f not in r or ok(r[f])))
        both = sorted(f for f, m in z.items() if not ok(m) and f in r and not ok(r[f]))
        print(f"  scheitern nur auf z/OS: {len(only)}, auch in der Referenz: {len(both)}")
        for f in only:
            print(f"    {z[f]:40} {f}")


if __name__ == "__main__":
    main()
