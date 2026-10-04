#!/usr/bin/env python3
"""Erzeugt die Umwandlungstabellen ISO-8859-1 <-> EBCDIC für die Dataset-Schicht und die
Units zosccsid/zosebcdic:

    gen-ccsid.py            schreibt runtime/zosccsid.h und rtl/zosccsid.inc
    gen-ccsid.py --check    vergleicht nur (Rückgabe 1 bei Abweichung)

Quelle sind die Zuordnungen der ICU (UCM-Dateien von IBM, Repository unicode-org/icu-data,
fester Stand ICU_COMMIT, Prüfsummen unten), nur Rundreise-Einträge (|0). Sie werden nach
~/.cache/zos-pascal-llvm/ucm geladen (oder ZOS_UCM_DIR). Gegenprobe ohne Netz:
tests/test_ccsid.py (Python-Codecs cp037/cp273/cp500/cp1140, gemessene IBM-1047-Tabelle).

Alle Tabellen sind CECP-Codepages (Repertoire = Latin-1), die Euro-Varianten 1140-1149
haben an Stelle von X'9F' das Euro-Zeichen statt U+00A4. Regeln:
  - ASCII-Seite ist ISO-8859-1 (die Codepage der RTL im ASCII-Modus); das Euro-Zeichen
    der Euro-Varianten liegt dort auf X'A4' (Stelle des Euro in ISO-8859-15), damit die
    Tabellen umkehrbar bleiben.
  - Zeilenende wie unter z/OS UNIX (iconv, C-Textmodus): EBCDIC NL X'15' <-> LF X'0A',
    EBCDIC LF X'25' <-> U+0085 (ICU-Variante ",swaplfnl"). Für IBM-1047 ergibt das genau
    die auf z/OS mit iconv gemessene Tabelle.
  - Abweichung von Python: cp273 setzt X'BC' auf U+203E, IBM/ICU auf U+00AF (Makron).
"""
import hashlib
import os
import re
import sys
import urllib.request

ICU_COMMIT = "bae5ca647fa41703393dbf00240ec1b807a9c353"
URL = "https://raw.githubusercontent.com/unicode-org/icu-data/%s/charset/data/ucm/%s"
# CCSID -> (UCM-Datei, sha256, Beschreibung)
TABLES = {
    1047: ("ibm-1047_P100-1995.ucm", "f6de10bcf4f3316a05e9bba055999c1062a0a0c1968d937a724ed0a72e0f1e55", "Latin-1/Open Systems (z/OS UNIX)"),
    37: ("ibm-37_P100-1999.ucm", "8ec1b7019dfdab88bc1b607486d928f2de0ace9fa7b5726056fe46c0ce167e15", "USA, Kanada, Niederlande, Portugal"),
    273: ("ibm-273_P100-1999.ucm", "0a8fb7cc194d50daccc4b5b73af0892341854233865574d0f53b09567a56be49", "Deutschland, Österreich"),
    277: ("ibm-277_P100-1999.ucm", "8f212969d38fa5a685a85daffb2187f27dc82d10872d79908a0eadc7a5021db3", "Dänemark, Norwegen"),
    278: ("ibm-278_P100-1999.ucm", "17ca20985ba3e18bf71c392cbbf44ec5412b54d319b1f4ae8378c6a6b3dae9dd", "Finnland, Schweden"),
    280: ("ibm-280_P100-1999.ucm", "88d76b3adaf20abcb45b1b66d41bb43d3eeee7126284102afd3aefb7851376fc", "Italien"),
    284: ("ibm-284_P100-1999.ucm", "a19fc6ff58a98ad4f656312384ef99f6c4bd9792a4b26b6496aa9c711a41c5dd", "Spanien, Lateinamerika"),
    285: ("ibm-285_P100-1999.ucm", "823ae6a766081b952757823367aee64c2376650e9d3160e19513745eac6e82fe", "Großbritannien"),
    297: ("ibm-297_P100-1999.ucm", "b597986b401c21cf7365a4d3801f6bb31894a4e67396a74bb17d67512e519c80", "Frankreich"),
    500: ("ibm-500_P100-1999.ucm", "1370a76b4a7f6e1d85e404e1bc29be49367312c6bc5eea5d707a9dfe3626c0df", "International (Schweiz, Belgien)"),
    871: ("ibm-871_P100-1999.ucm", "05ac7ae91ac8e3edcb4877d17ab0d1e2cb9a2ca4f30575ba1db951b01e4ac095", "Island"),
    1140: ("ibm-1140_P100-1997.ucm", "8f95b217dc6eec1bf0c694b29e952098922e09184a8956d35b3d2061f9e82e24", "37 mit Euro"),
    1141: ("ibm-1141_P100-1997.ucm", "20f4a0d39aac9d4533b63e01d7cb3c8a2745415218a11008cb65e21dafcb29db", "273 mit Euro"),
    1142: ("ibm-1142_P100-1997.ucm", "7cc8cb357d427480d20e02995013bae08501fd1f88cc9d6a17c26ad1c3a35ccc", "277 mit Euro"),
    1143: ("ibm-1143_P100-1997.ucm", "15f34e47ba48e5037e65077bae4d894c7032ff2ff9667e5390bf1dd3d239c9c6", "278 mit Euro"),
    1144: ("ibm-1144_P100-1997.ucm", "05f90508a3ef58d322ce0f723b6b6d55b004ea4ffdb920e765fb267b93b3c811", "280 mit Euro"),
    1145: ("ibm-1145_P100-1997.ucm", "19214813c8cda58eb02d17b3d33a9c3681265ec33be0d3f0fb884019f6ab34ca", "284 mit Euro"),
    1146: ("ibm-1146_P100-1997.ucm", "47cdab6c14ff793a3d0b611c78a5298ed9bf9b79431ad2a4086b9537a1775fe3", "285 mit Euro"),
    1147: ("ibm-1147_P100-1997.ucm", "a0ff0dc559e6ccc00fa1c461be3eb458b4fe23a6c2d66a13ac62eeaaeb9f54d0", "297 mit Euro"),
    1148: ("ibm-1148_P100-1997.ucm", "f0f393fa3274ce5e1a966a3ccfb7416051427b98194f19bbb5efc79938007e9e", "500 mit Euro"),
    1149: ("ibm-1149_P100-1997.ucm", "a9cd03b4d79ef568c8674d2dd24c7920cd33e06cb27bd84a950c9136ae460448", "871 mit Euro"),
}
EURO_POS = 0xA4      # Euro auf der ASCII-Seite (wie ISO-8859-15)
REPO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
CACHE = os.environ.get("ZOS_UCM_DIR", os.path.expanduser("~/.cache/zos-pascal-llvm/ucm"))
UCM_LINE = re.compile(r"<U([0-9A-F]{4,6})>\s+\\x([0-9A-F]{2})\s+\|0")


def ucm_file(name, sha):
    path = os.path.join(CACHE, name)
    if not os.path.exists(path):
        os.makedirs(CACHE, exist_ok=True)
        with urllib.request.urlopen(URL % (ICU_COMMIT, name), timeout=60) as r:
            data = r.read()
        with open(path, "wb") as f:
            f.write(data)
    data = open(path, "rb").read()
    if hashlib.sha256(data).hexdigest() != sha:
        sys.exit(f"gen-ccsid: Prüfsumme von {path} falsch")
    return data.decode("latin-1")


def ebcdic_to_unicode(ccsid):
    """EBCDIC-Byte -> Unicode (Rundreise-Zuordnung der ICU, mit LF/NL-Tausch)."""
    name, sha, _ = TABLES[ccsid]
    m = {}
    for line in ucm_file(name, sha).splitlines():
        r = UCM_LINE.match(line)
        if r:
            m[int(r.group(2), 16)] = int(r.group(1), 16)
    if sorted(m) != list(range(256)):
        sys.exit(f"gen-ccsid: {name}: keine vollständige Einbyte-Tabelle")
    # z/OS UNIX: NL X'15' <-> LF
    m[0x15], m[0x25] = 0x0A, 0x85
    return m


def tables(ccsid):
    """(a2e, e2a) mit ASCII-Seite ISO-8859-1, Euro auf X'A4'."""
    m = ebcdic_to_unicode(ccsid)
    e2a = [0] * 256
    for b, u in m.items():
        if u == 0x20AC:
            e2a[b] = EURO_POS
        elif u <= 0xFF:
            e2a[b] = u
        else:
            sys.exit(f"gen-ccsid: CCSID {ccsid}: U+{u:04X} hat keinen Platz in ISO-8859-1")
    if sorted(e2a) != list(range(256)):
        sys.exit(f"gen-ccsid: CCSID {ccsid}: nicht umkehrbar")
    a2e = [0] * 256
    for b, a in enumerate(e2a):
        a2e[a] = b
    return a2e, e2a


def rows(t, fmt, indent):
    out = []
    for i in range(0, 256, 16):
        out.append(indent + ", ".join(fmt % v for v in t[i:i + 16]))
    return (",\n").join(out)


def gen_c(all_tabs):
    s = ["/* zosccsid.h - erzeugt von scripts/gen-ccsid.py, nicht von Hand ändern.",
         " * ISO-8859-1 <-> EBCDIC (CECP-Codepages), Quelle ICU icu-data " + ICU_COMMIT[:12] + ",",
         " * LF <-> NL X'15'; Euro-Varianten: Euro auf X'A4' der ASCII-Seite. */",
         "",
         "struct zos_ccsid {",
         "  int ccsid;",
         "  unsigned char a2e[256];",
         "  unsigned char e2a[256];",
         "};",
         "",
         "static const struct zos_ccsid zos_ccsids[] = {"]
    for c, (a2e, e2a) in all_tabs:
        s.append("  { %d, /* %s */" % (c, TABLES[c][2]))
        s.append("    {")
        s.append(rows(a2e, "0x%02X", "      "))
        s.append("    }, {")
        s.append(rows(e2a, "0x%02X", "      "))
        s.append("    } },")
    s.append("};")
    s.append("#define ZOS_NCCSIDS (sizeof zos_ccsids / sizeof zos_ccsids[0])")
    return "\n".join(s) + "\n"


def gen_pas(all_tabs):
    s = ["{ zosccsid.inc - erzeugt von scripts/gen-ccsid.py, nicht von Hand ändern.",
         "  ISO-8859-1 <-> EBCDIC (CECP-Codepages), Quelle ICU icu-data " + ICU_COMMIT[:12] + ",",
         "  LF <-> NL X'15'; Euro-Varianten: Euro auf X'A4' der ASCII-Seite. }",
         "",
         "const",
         "  CcsidTableCount = %d;" % len(all_tabs),
         "  CcsidList: array[0..CcsidTableCount-1] of longint = (%s);" % ", ".join(str(c) for c, _ in all_tabs),
         "  CcsidA2E: array[0..CcsidTableCount-1, 0..255] of byte = ("]
    parts = []
    for c, (a2e, _) in all_tabs:
        parts.append("    { %d } (\n%s)" % (c, rows(a2e, "$%02X", "      ")))
    s.append(",\n".join(parts))
    s.append("  );")
    s.append("  CcsidE2A: array[0..CcsidTableCount-1, 0..255] of byte = (")
    parts = []
    for c, (_, e2a) in all_tabs:
        parts.append("    { %d } (\n%s)" % (c, rows(e2a, "$%02X", "      ")))
    s.append(",\n".join(parts))
    s.append("  );")
    return "\n".join(s) + "\n"


def main():
    check = "--check" in sys.argv
    all_tabs = [(c, tables(c)) for c in TABLES]
    outs = {os.path.join(REPO, "runtime", "zosccsid.h"): gen_c(all_tabs),
            os.path.join(REPO, "rtl", "zosccsid.inc"): gen_pas(all_tabs)}
    bad = 0
    for path, text in outs.items():
        if check:
            try:
                old = open(path, encoding="utf-8").read()
            except FileNotFoundError:
                old = None
            if old != text:
                print(f"gen-ccsid: {path} ist nicht aktuell")
                bad = 1
        else:
            with open(path, "w", encoding="utf-8") as f:
                f.write(text)
    if not check:
        print(f"gen-ccsid: {len(all_tabs)} CCSIDs")
    return bad


if __name__ == "__main__":
    sys.exit(main())
