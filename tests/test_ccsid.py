"""Gegenproben zu den CCSID-Tabellen (scripts/gen-ccsid.py), ohne Netz:

- C-Tabellen (runtime/zosccsid.h) und Pascal-Tabellen (rtl/zosccsid.inc) sind gleich,
- jede Tabelle ist umkehrbar und a2e/e2a passen zueinander,
- 037, 273, 500, 1140 stimmen mit den Python-Codecs überein (LF/NL-Tausch, Euro auf X'A4',
  bei 273 X'BC' = U+00AF statt Pythons U+203E),
- 1047 ist gleich der Tabelle, die auf z/OS mit iconv gemessen wurde (bis 0.9.0 fest in
  runtime/zosdsn.c),
- die Euro-Varianten 1140-1149 sind byteweise gleich ihrer Basis (Euro an Stelle von U+00A4,
  auf der ASCII-Seite X'A4'; in 1140/1141/1148 ist das X'9F').

    python3 -m unittest discover -s tests -p 'test_*.py'
"""
import os
import re
import unittest

REPO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")

# IBM-1047 -> ISO-8859-1, auf z/OS mit iconv gemessen (LF <-> X'15')
E2A_1047_ICONV = bytes.fromhex(
    "000102039c09867f978d8e0b0c0d0e0f101112139d0a08871819928f1c1d1e1f808182838485171b"
    "88898a8b8c050607909116939495960498999a9b14159e1a20a0e2e4e0e1e3e5e7f1a22e3c282b7c"
    "26e9eaebe8edeeefecdf21242a293b5e2d2fc2c4c0c1c3c5c7d1a62c255f3e3ff8c9cacbc8cdcecf"
    "cc603a2340273d22d8616263646566676869abbbf0fdfeb1b06a6b6c6d6e6f707172aabae6b8c6a4"
    "b57e737475767778797aa1bfd05bdeaeaca3a5b7a9a7b6bcbdbedda8af5db4d77b41424344454647"
    "4849adf4f6f2f3f57d4a4b4c4d4e4f505152b9fbfcf9faff5cf7535455565758595ab2d4d6d2d3d5"
    "30313233343536373839b3dbdcd9da9f")

EURO_BASE = {1140: 37, 1141: 273, 1142: 277, 1143: 278, 1144: 280, 1145: 284, 1146: 285,
             1147: 297, 1148: 500, 1149: 871}


def parse_c():
    with open(os.path.join(REPO, "runtime", "zosccsid.h"), encoding="utf-8") as f:
        s = f.read()
    res = {}
    for m in re.finditer(r"\{ (\d+), /\*.*?\*/\s*\{(.*?)\}, \{(.*?)\} \}", s, re.S):
        a2e = [int(x, 16) for x in re.findall(r"0x([0-9A-F]{2})", m.group(2))]
        e2a = [int(x, 16) for x in re.findall(r"0x([0-9A-F]{2})", m.group(3))]
        res[int(m.group(1))] = (a2e, e2a)
    return res


def parse_pas():
    with open(os.path.join(REPO, "rtl", "zosccsid.inc"), encoding="utf-8") as f:
        s = f.read()
    ccsids = [int(x) for x in re.search(r"CcsidList: .*?\((.*?)\);", s).group(1).split(",")]
    a2e_part, e2a_part = s.split("CcsidE2A:")
    def tabs(part):
        res = {}
        for m in re.finditer(r"\{ (\d+) \} \((.*?)\)", part, re.S):
            res[int(m.group(1))] = [int(x, 16) for x in re.findall(r"\$([0-9A-F]{2})", m.group(2))]
        return res
    a2e, e2a = tabs(a2e_part), tabs(e2a_part)
    return ccsids, {c: (a2e[c], e2a[c]) for c in ccsids}


def python_e2a(codec):
    out = []
    for b in range(256):
        u = ord(bytes([b]).decode(codec))
        if b == 0x15:
            u = 0x0A
        elif b == 0x25:
            u = 0x85
        elif u == 0x20AC:
            u = 0xA4
        elif codec == "cp273" and b == 0xBC:
            u = 0xAF          # IBM: Makron, Python: U+203E
        out.append(u)
    return out


class CcsidTables(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.c = parse_c()
        cls.order, cls.p = parse_pas()

    def test_same_in_c_and_pascal(self):
        self.assertEqual(sorted(self.c), sorted(self.p))
        self.assertEqual(self.order[0], 1047, "1047 muss zuerst stehen (Standard in zosdsn.c)")
        self.assertEqual(list(self.c)[0], 1047)
        for c in self.c:
            self.assertEqual(self.c[c], self.p[c], f"CCSID {c}")

    def test_required_ccsids(self):
        for c in (1047, 37, 273, 500, 1140, 1141, 1148):
            self.assertIn(c, self.c)

    def test_bijective(self):
        for c, (a2e, e2a) in self.c.items():
            self.assertEqual(sorted(a2e), list(range(256)), f"a2e {c}")
            self.assertEqual(sorted(e2a), list(range(256)), f"e2a {c}")
            for a in range(256):
                self.assertEqual(e2a[a2e[a]], a, f"Rundreise {c} bei {a:02X}")

    def test_python_codecs(self):
        for c, codec in ((37, "cp037"), (273, "cp273"), (500, "cp500"), (1140, "cp1140")):
            self.assertEqual(self.c[c][1], python_e2a(codec), f"CCSID {c} gegen Python {codec}")

    def test_1047_as_measured_on_zos(self):
        self.assertEqual(bytes(self.c[1047][1]), E2A_1047_ICONV)

    def test_euro_variants(self):
        for euro, base in EURO_BASE.items():
            e, b = self.c[euro][1], self.c[base][1]
            diff = [i for i in range(256) if e[i] != b[i]]
            self.assertEqual(diff, [], f"{euro} gegen {base}")   # Euro liegt wie ¤ auf X'A4'
        for euro in (1140, 1141, 1148):
            self.assertEqual(self.c[euro][1][0x9F], 0xA4, f"Euro in {euro} auf X'9F'")

    def test_invariants(self):
        # Ziffern, Großbuchstaben, Leerzeichen, NL sind in allen CECP-Codepages gleich
        for c, (a2e, _) in self.c.items():
            self.assertEqual([a2e[ord(ch)] for ch in "0123456789"], list(range(0xF0, 0xFA)))
            self.assertEqual(a2e[ord("A")], 0xC1)
            self.assertEqual(a2e[ord("Z")], 0xE9)
            self.assertEqual(a2e[0x20], 0x40)
            self.assertEqual(a2e[0x0A], 0x15)

    def test_generator_up_to_date(self):
        cache = os.environ.get("ZOS_UCM_DIR", os.path.expanduser("~/.cache/zos-pascal-llvm/ucm"))
        if not os.path.exists(os.path.join(cache, "ibm-1047_P100-1995.ucm")):
            self.skipTest("UCM-Dateien nicht im Cache (gen-ccsid.py lädt sie bei Bedarf)")
        import subprocess
        r = subprocess.run(["python3", os.path.join(REPO, "scripts", "gen-ccsid.py"), "--check"],
                           capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)


if __name__ == "__main__":
    unittest.main()
