"""Tests für scripts/copybook2pas.py: Satzbilder der Beispiel-Copybooks (tests/copybooks/,
Offsets von Hand nach den Regeln von Enterprise COBOL berechnet), Fehlerfälle und dass die
erzeugten Units in pf8/ aktuell sind (pf8/cobtest.pas prüft die Offsets zusätzlich zur
Laufzeit mit FPC, auf x86_64 und z/OS).
"""
import os
import subprocess
import sys
import unittest

REPO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
sys.path.insert(0, os.path.join(REPO, "scripts"))
import copybook2pas as cb  # noqa: E402

# Name -> (Offset, Länge einer Wiederholung)
EXPECTED = {
    "kunde": ("KUNDE-SATZ", 97, {
        "KUNDE-NR": (0, 8), "KUNDE-NAME": (8, 30), "KUNDE-STATUS": (38, 1),
        "KUNDE-SALDO": (39, 6), "KUNDE-LIMIT": (45, 5), "KUNDE-ANZAHL": (50, 2),
        "KUNDE-PUNKTE": (52, 4), "KUNDE-GROSS": (56, 8), "KUNDE-DATUM": (64, 8),
        "KUNDE-JJJJ": (64, 4), "KUNDE-MM": (68, 2), "KUNDE-TT": (70, 2),
        "KUNDE-BETRAG": (77, 8), "KUNDE-KURS": (85, 8), "KUNDE-FAKTOR": (93, 4)}),
    "auftrag": ("AUFTRAG", 175, {
        "AUF-NR": (0, 10), "AUF-ART": (10, 1), "AUF-ADRESSE": (11, 45),
        "AUF-STRASSE": (11, 25), "AUF-ORT": (36, 20), "AUF-POSTFACH": (11, 45),
        "AUF-PF-NR": (11, 6), "AUF-KURZ": (11, 10), "AUF-ANZ-POS": (56, 2),
        "AUF-POS": (58, 22), "POS-ARTIKEL": (58, 8), "POS-MENGE": (66, 3),
        "POS-PREIS": (69, 5), "POS-RABATT": (74, 2), "AUF-SUMME": (168, 7)}),
    "sync": ("SYNC-SATZ", 87, {
        "S-KZ": (0, 1), "S-HALB": (2, 2), "S-X3": (4, 3), "S-VOLL": (8, 4),
        "S-X1": (12, 1), "S-DOPPEL": (16, 8), "S-F1": (24, 4), "S-TAB": (28, 8),
        "T-A": (28, 1), "T-B": (32, 4), "S-ANZ": (44, 3), "S-ZEILE": (47, 4)}),
    "divers": ("DIVERS", 36, {
        "D-NAT": (0, 8), "D-EDIT": (8, 11), "D-PROZ": (19, 3), "D-KENN": (22, 2),
        "D-VORZ": (24, 3), "D-PTR": (27, 4), "D-IDX": (31, 4), "TYPE": (35, 1)}),
}


def layout(text, **kw):
    o = cb.options(["x.cpy", "--json"] + [f"--{k}={v}" if v != "" else f"--{k}" for k, v in kw.items()])
    import json
    return json.loads(cb.convert(text, o))


class Layouts(unittest.TestCase):
    def test_examples(self):
        for f, (rec, size, fields) in EXPECTED.items():
            with open(os.path.join(REPO, "tests", "copybooks", f + ".cpy"), encoding="utf-8") as fh:
                recs = layout(fh.read())
            self.assertEqual(recs[0]["record"], rec)
            self.assertEqual(recs[0]["size"], size, f)
            got = {i["name"]: (i["ofs"], i["len"]) for i in recs[0]["items"] if i["name"] != "FILLER"}
            for name, exp in fields.items():
                self.assertEqual(got[name], exp, f"{f}: {name}")

    def test_kinds(self):
        with open(os.path.join(REPO, "tests", "copybooks", "kunde.cpy"), encoding="utf-8") as fh:
            items = {i["name"]: i for i in layout(fh.read())[0]["items"]}
        self.assertEqual(items["KUNDE-SALDO"]["kind"], "packed")
        self.assertEqual((items["KUNDE-SALDO"]["digits"], items["KUNDE-SALDO"]["scale"]), (11, 2))
        self.assertEqual(items["KUNDE-ANZAHL"]["kind"], "binary")
        self.assertEqual(items["KUNDE-GROSS"]["kind"], "comp5")
        self.assertEqual(items["KUNDE-STATUS"]["conditions"], ["KUNDE-AKTIV", "KUNDE-GESPERRT"])

    def test_usage_inherited(self):
        r = layout("""
       01  G.
           05  H COMP-3.
               10  A PIC S9(5).
               10  B PIC S9(4).
           05  C PIC S9(9).
""")[0]
        items = {i["name"]: i for i in r["items"]}
        self.assertEqual((items["A"]["kind"], items["A"]["len"]), ("packed", 3))
        self.assertEqual((items["B"]["ofs"], items["B"]["len"]), (3, 3))
        self.assertEqual((items["C"]["kind"], items["C"]["ofs"], items["C"]["len"]), ("zoned", 6, 9))

    def test_binary_sizes(self):
        r = layout("""
       01  B.
           05  B1 PIC S9 COMP.
           05  B4 PIC S9(4) COMP.
           05  B5 PIC S9(5) COMP.
           05  B9 PIC S9(9) COMP.
           05  B10 PIC S9(10) COMP.
           05  B18 PIC S9(18) COMP.
""")[0]
        self.assertEqual([i["len"] for i in r["items"][1:]], [2, 2, 4, 4, 8, 8])
        self.assertEqual(r["size"], 28)

    def test_free_format_and_period_in_picture(self):
        r = layout("01 E. 05 X PIC ZZ9.99. 05 Y PIC X(3).", free="")
        self.assertEqual([(i["name"], i["ofs"], i["len"]) for i in r[0]["items"][1:]],
                         [("X", 0, 6), ("Y", 6, 3)])

    def test_sync8_option(self):
        text = "       01  S.\n           05 A PIC X.\n           05 B PIC S9(18) COMP SYNC.\n"
        self.assertEqual(layout(text)[0]["items"][2]["ofs"], 8)
        self.assertEqual(layout(text, sync8=4)[0]["items"][2]["ofs"], 4)

    def test_occurs_sync_slack(self):
        # Wiederholung 5 Byte mit Fullword-SYNC -> 3 Füllbytes je Wiederholung
        r = layout("""
       01  T.
           05  E OCCURS 3.
               10  N PIC S9(9) COMP SYNC.
               10  K PIC X.
""")[0]
        e = r["items"][1]
        self.assertEqual((e["len"], e.get("slack_after")), (5, 3))
        self.assertEqual(r["size"], 24)

    def test_errors(self):
        bad = [
            "       01  A.\n           05 B PIC X.\n               88 C VALUE 'A' THRU 'C'.\n",
            "       01  A.\n           05 B PIC 9(3)PP.\n",
            "       01  A.\n           05 B PIC X FOO.\n",
            "       01  A.\n           05 B REDEFINES Z PIC X.\n",
            "       05  B PIC X.\n",
        ]
        o = cb.options(["x.cpy"])
        for t in bad:
            with self.assertRaises(cb.CopybookError, msg=t):
                cb.convert(t, o)

    def test_generated_units_up_to_date(self):
        for f in EXPECTED:
            src = os.path.join(REPO, "tests", "copybooks", f + ".cpy")
            with open(src, encoding="utf-8") as fh:
                text = fh.read()
            o = cb.options([src, "--unit", "cb_" + f])
            out = cb.convert(text, o, "cb_" + f, f + ".cpy")
            with open(os.path.join(REPO, "pf8", f"cb_{f}.pas"), encoding="utf-8") as fh:
                self.assertEqual(fh.read(), out, f"pf8/cb_{f}.pas neu erzeugen")

    def test_cli(self):
        r = subprocess.run([sys.executable, os.path.join(REPO, "scripts", "copybook2pas.py"),
                            "--json", os.path.join(REPO, "tests", "copybooks", "sync.cpy")],
                           capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('"SYNC-SATZ"', r.stdout)


if __name__ == "__main__":
    unittest.main()
