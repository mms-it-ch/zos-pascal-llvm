#!/usr/bin/env python3
"""copybook2pas.py: COBOL-Copybook -> Pascal-Unit mit Satzbeschreibung und Feldzugriffen.

    copybook2pas.py [Optionen] kunde.cpy [-o kunde.pas]

Optionen:
    -o DATEI          Ausgabe (Standard: Name des Copybooks mit .pas)
    --unit NAME       Unit-Name (Standard: Dateiname)
    --ccsid N         CCSID der Textfelder (Standard 1047; je Aufruf änderbar)
    --float hex|ieee  COMP-1/COMP-2: hexadezimal (COBOL FLOAT(HEX), Standard) oder IEEE
    --free            freies Format (sonst festes Format: Spalten 7-72)
    --pointer N       Größe von USAGE POINTER/INDEX (4 = 31-Bit-COBOL, Standard; 8 = LP64)
    --sync8 N         Ausrichtung von 8-Byte-Binärfeldern mit SYNC (Standard 8)
    --json            nur das Satzbild als JSON ausgeben (Tests)

Unterstützt: Stufen 01-49, 66 (nur Warnung), 77, 88; PIC X/A/N/9/S9/V/P (P links),
editierte Bilder (als Text); USAGE DISPLAY, COMP/COMP-4/BINARY, COMP-3/PACKED-DECIMAL,
COMP-5, COMP-1, COMP-2, INDEX, POINTER, NATIONAL (auch auf Gruppenstufe vererbt); SIGN
LEADING/TRAILING [SEPARATE]; SYNC/SYNCHRONIZED (Ausrichtung relativ zum Satzanfang,
Füllbytes SLACK_n); OCCURS n und OCCURS m TO n DEPENDING ON (Platz für n, Längenfunktion,
wenn die Tabelle am Satzende steht); REDEFINES (varianter Record); FILLER; VALUE bei 88
(Literale, THRU, mehrere Werte, figurative Konstanten).

Erzeugt je Satz (Stufe 01/77) einen packed record aus Byte-Feldern mit genau den Offsets
des COBOL-Programms (unabhängig von der Byte-Reihenfolge), Konstanten <FELD>_OFS/_LEN,
Zugriffe Get_<FELD>/Set_<FELD> (Text je CCSID, TDecimal für gezont/gepackt, Int64 bzw.
TDecimal für binär, Double für COMP-1/2), Is_/Set_ für Stufe 88, Initialize_<SATZ> (wie
COBOL INITIALIZE) und <SATZ>_LayoutOk (prüft die Offsets zur Laufzeit).
Laufzeit: Units zoscobol, zosdecimal, zosccsid (rtl/ dieses Repositorys).
"""
import argparse
import json
import os
import re
import sys

RESERVED = set("""and array as asm begin case class const constructor destructor dispinterface
div do downto else end except exports file finalization finally for function goto if
implementation in inherited initialization inline interface is label library mod nil not
object of on operator or out packed procedure program property raise record repeat
resourcestring set shl shr string then threadvar to try type unit until uses var while with
xor result self absolute abstract""".split())


class CopybookError(Exception):
    pass


class Item:
    def __init__(self, level, name, line):
        self.level = level
        self.name = name            # COBOL-Name oder FILLER
        self.line = line
        self.pic = None
        self.usage = None
        self.sign = None            # (leading, separate)
        self.sync = False
        self.occurs = None          # (min, max, depending)
        self.redefines = None
        self.values = []            # Stufe 88: Liste von (von, bis) Literalen
        self.children = []
        self.parent = None
        self.conditions = []        # Stufe-88-Einträge
        # Layout
        self.ofs = 0
        self.size = 0               # eine Wiederholung
        self.kind = None
        self.digits = 0
        self.scale = 0
        self.signed = False
        self.align = 1
        self.pasname = None
        self.slack_before = 0
        self.slack_after = 0        # je Wiederholung (OCCURS mit SYNC)

    @property
    def filler(self):
        return self.name.upper() == "FILLER"

    @property
    def count(self):
        return self.occurs[1] if self.occurs else 1

    @property
    def total(self):
        return (self.size + self.slack_after) * self.count


# ------------------------------------------------------------------------------------
# Einlesen

def source_text(text, free):
    out = []
    for raw in text.splitlines():
        line = raw.rstrip("\n\r")
        if free:
            s = line
            if s.lstrip().startswith("*>"):
                continue
            s = s.split("*>")[0]
        else:
            if len(line) >= 7 and line[6] in "*/":
                continue
            if len(line) >= 7 and line[6] == "-":
                # Fortsetzung: Literal ohne führendes Anführungszeichen anhängen
                cont = line[7:72].lstrip()
                if cont[:1] in "'\"" and out:
                    out[-1] = out[-1].rstrip()
                    if out[-1][-1:] in "'\"":
                        out[-1] = out[-1][:-1]
                    cont = cont[1:]
                    out[-1] += cont
                else:
                    out[-1] += " " + cont
                continue
            s = line[7:72] if len(line) > 7 else ""
            if re.match(r"^\s*\d", line[:6]) is None and line[:6].strip() and not line[:6].strip().isdigit():
                # Spalten 1-6 ohne Folgenummer: trotzdem festes Format
                pass
        out.append(s)
    return "\n".join(out)


TOKEN = re.compile(r"""\s*(?:(X'[0-9A-Fa-f]*'|'(?:[^']|'')*'|"(?:[^"]|"")*")|([^\s.'"]+(?:\.(?=[^\s.])[^\s.'"]*)*|\.(?=[^\s.])[^\s.'"]+(?:\.(?=[^\s.])[^\s.'"]*)*)|(\.)(?=\s|$))""")


def tokenize(text):
    """Token-Folge; '.' am Satzende als eigenes Token."""
    pos = 0
    toks = []
    line = 1
    while pos < len(text):
        m = TOKEN.match(text, pos)
        if not m or m.end() == pos:
            if text[pos].isspace():
                if text[pos] == "\n":
                    line += 1
                pos += 1
                continue
            raise CopybookError(f"Zeile {line}: unerwartetes Zeichen {text[pos]!r}")
        line += text.count("\n", pos, m.start(0) + len(m.group(0)) - len(m.group(0).lstrip()))
        tok = m.group(1) or m.group(2) or m.group(3)
        toks.append((tok, line))
        line += tok.count("\n")
        pos = m.end()
    return toks


def sentences(toks):
    cur = []
    for t, line in toks:
        if t == ".":
            if cur:
                yield cur
            cur = []
        else:
            cur.append((t, line))
    if cur:
        yield cur


def literal(tok):
    """Literal -> ('str', text) | ('num', text) | ('hex', bytes) | ('fig', NAME)."""
    u = tok.upper()
    if u.startswith("X'"):
        return ("hex", bytes.fromhex(tok[2:-1]))
    if tok[0] in "'\"":
        q = tok[0]
        return ("str", tok[1:-1].replace(q + q, q))
    figs = {"SPACE": "SPACE", "SPACES": "SPACE", "ZERO": "ZERO", "ZEROS": "ZERO",
            "ZEROES": "ZERO", "LOW-VALUE": "LOW", "LOW-VALUES": "LOW",
            "HIGH-VALUE": "HIGH", "HIGH-VALUES": "HIGH", "QUOTE": "QUOTE", "QUOTES": "QUOTE"}
    if u in figs:
        return ("fig", figs[u])
    if re.fullmatch(r"[+-]?(\d+(\.\d*)?|\.\d+)", tok):
        return ("num", tok)
    raise CopybookError(f"Literal {tok!r} nicht unterstützt")


def parse(text, free=False):
    toks = tokenize(source_text(text, free))
    records = []
    stack = []
    warnings = []
    last_data = None
    for sent in sentences(toks):
        words = [t for t, _ in sent]
        line = sent[0][1]
        if words[0].upper() in ("COPY", "EJECT", "SKIP1", "SKIP2", "SKIP3"):
            if words[0].upper() == "COPY":
                warnings.append(f"Zeile {line}: COPY {words[1]} nicht aufgelöst")
            continue
        if not words[0].isdigit():
            raise CopybookError(f"Zeile {line}: Stufennummer erwartet, gefunden {words[0]!r}")
        level = int(words[0])
        i = 1
        name = "FILLER"
        if i < len(words) and not is_clause(words[i]):
            name = words[i]
            i += 1
        it = Item(level, name, line)
        if level == 66:
            warnings.append(f"Zeile {line}: Stufe 66 (RENAMES) {name} übergangen")
            continue
        if level == 88:
            if last_data is None:
                raise CopybookError(f"Zeile {line}: Stufe 88 ohne Datenfeld")
            parse_88(it, words[i:], line)
            it.parent = last_data
            last_data.conditions.append(it)
            continue
        parse_clauses(it, words[i:], line)
        if level in (1, 77):
            stack = [it]
            records.append(it)
        else:
            if not stack:
                raise CopybookError(f"Zeile {line}: Stufe {level} ohne Stufe 01")
            while stack and stack[-1].level >= level:
                stack.pop()
            if not stack:
                raise CopybookError(f"Zeile {line}: Stufe {level} passt zu keiner Gruppe")
            parent = stack[-1]
            if parent.pic:
                raise CopybookError(f"Zeile {line}: {parent.name} hat PIC und Unterfelder")
            it.parent = parent
            parent.children.append(it)
            stack.append(it)
        last_data = it
    return records, warnings


CLAUSES = {"PIC", "PICTURE", "USAGE", "COMP", "COMPUTATIONAL", "COMP-1", "COMP-2", "COMP-3",
           "COMP-4", "COMP-5", "COMPUTATIONAL-1", "COMPUTATIONAL-2", "COMPUTATIONAL-3",
           "COMPUTATIONAL-4", "COMPUTATIONAL-5", "BINARY", "PACKED-DECIMAL", "DISPLAY",
           "NATIONAL", "INDEX", "POINTER", "OCCURS", "REDEFINES", "SIGN", "LEADING",
           "TRAILING", "SYNC", "SYNCHRONIZED", "VALUE", "VALUES", "JUST", "JUSTIFIED",
           "BLANK", "GLOBAL", "EXTERNAL", "IS", "RENAMES"}


def is_clause(w):
    return w.upper() in CLAUSES


USAGES = {"COMP": "binary", "COMPUTATIONAL": "binary", "COMP-4": "binary",
          "COMPUTATIONAL-4": "binary", "BINARY": "binary", "COMP-5": "comp5",
          "COMPUTATIONAL-5": "comp5", "COMP-3": "packed", "COMPUTATIONAL-3": "packed",
          "PACKED-DECIMAL": "packed", "COMP-1": "float4", "COMPUTATIONAL-1": "float4",
          "COMP-2": "float8", "COMPUTATIONAL-2": "float8", "DISPLAY": "display",
          "NATIONAL": "national", "INDEX": "index", "POINTER": "pointer"}


def parse_clauses(it, w, line):
    i = 0
    up = [x.upper() for x in w]
    while i < len(w):
        u = up[i]
        if u in ("PIC", "PICTURE"):
            i += 1
            if i < len(w) and up[i] == "IS":
                i += 1
            it.pic = w[i].upper()
            i += 1
        elif u == "USAGE":
            i += 1
            if i < len(w) and up[i] == "IS":
                i += 1
        elif u in USAGES:
            it.usage = USAGES[u]
            i += 1
        elif u == "REDEFINES":
            it.redefines = w[i + 1]
            i += 2
        elif u == "OCCURS":
            i += 1
            lo = int(w[i])
            i += 1
            hi = lo
            dep = None
            if i < len(w) and up[i] == "TO":
                hi = int(w[i + 1])
                i += 2
            if i < len(w) and up[i] == "TIMES":
                i += 1
            if i < len(w) and up[i] == "DEPENDING":
                i += 1
                if up[i] == "ON":
                    i += 1
                dep = w[i]
                i += 1
            # ASCENDING/DESCENDING KEY, INDEXED BY: überspringen
            while i < len(w) and up[i] in ("ASCENDING", "DESCENDING", "KEY", "IS", "INDEXED", "BY"):
                if up[i] in ("KEY", "BY"):
                    i += 1
                    while i < len(w) and not is_clause(w[i]) and up[i] not in ("ASCENDING", "DESCENDING", "INDEXED"):
                        i += 1
                else:
                    i += 1
            it.occurs = (lo, hi, dep)
        elif u == "SIGN":
            i += 1
            if i < len(w) and up[i] == "IS":
                i += 1
        elif u in ("LEADING", "TRAILING"):
            sep = i + 1 < len(w) and up[i + 1] == "SEPARATE"
            it.sign = (u == "LEADING", sep)
            i += 2 if sep else 1
            if i < len(w) and up[i] == "CHARACTER":
                i += 1
        elif u in ("SYNC", "SYNCHRONIZED"):
            it.sync = True
            i += 1
            if i < len(w) and up[i] in ("LEFT", "RIGHT"):
                i += 1
        elif u in ("VALUE", "VALUES"):
            # Anfangswert (nicht Stufe 88): wird nicht ausgewertet
            i += 1
            while i < len(w) and not is_clause(w[i]):
                i += 1
            if i < len(w) and up[i] in ("IS", "ARE"):
                i += 1
                while i < len(w) and not is_clause(w[i]):
                    i += 1
        elif u in ("JUST", "JUSTIFIED"):
            i += 1
            if i < len(w) and up[i] == "RIGHT":
                i += 1
        elif u == "BLANK":
            i += 3 if i + 2 < len(w) and up[i + 1] == "WHEN" else 2
        elif u in ("GLOBAL", "EXTERNAL", "IS"):
            i += 1
        else:
            raise CopybookError(f"Zeile {line}: unbekannte Angabe {w[i]!r} bei {it.name}")


def parse_88(it, w, line):
    i = 0
    up = [x.upper() for x in w]
    if i < len(w) and up[i] in ("VALUE", "VALUES"):
        i += 1
    else:
        raise CopybookError(f"Zeile {line}: Stufe 88 {it.name} ohne VALUE")
    if i < len(w) and up[i] in ("IS", "ARE"):
        i += 1
    while i < len(w):
        lo = literal(w[i])
        i += 1
        hi = None
        if i < len(w) and up[i] in ("THRU", "THROUGH"):
            hi = literal(w[i + 1])
            i += 2
        it.values.append((lo, hi))
    if not it.values:
        raise CopybookError(f"Zeile {line}: Stufe 88 {it.name} ohne Wert")


# ------------------------------------------------------------------------------------
# Bild und Größe

def expand_pic(pic):
    out = ""
    for m in re.finditer(r"(CR|DB|[^(])(?:\((\d+)\))?", pic):
        out += m.group(1) * (int(m.group(2)) if m.group(2) else 1)
    return out


def classify(it, usage, sign, opts):
    """Art, Stellen, Scale und Größe eines Elementarfelds."""
    if usage in ("float4", "float8"):
        it.kind = "float"
        it.size = 4 if usage == "float4" else 8
        it.align = it.size
        return
    if usage in ("index", "pointer"):
        it.kind = usage
        it.size = opts.pointer
        it.align = opts.pointer
        return
    if not it.pic:
        raise CopybookError(f"Zeile {it.line}: {it.name} ohne PIC")
    p = expand_pic(it.pic)
    if "N" in p and set(p) <= set("N"):
        it.kind = "national"
        it.digits = len(p)
        it.size = 2 * len(p)
        return
    if set(p) <= set("S9VP") and "9" in p:
        it.signed = p.startswith("S")
        body = p[1:] if it.signed else p
        if "S" in body:
            raise CopybookError(f"Zeile {it.line}: PIC {it.pic}")
        intpart, _, frac = body.partition("V")
        if "P" in intpart.lstrip("P") and intpart.rstrip("P") != intpart:
            raise CopybookError(f"Zeile {it.line}: PIC {it.pic}: P rechts der Ziffern (negativer Scale) nicht unterstützt")
        it.digits = p.count("9")
        it.scale = frac.count("9") + frac.count("P") + (intpart.count("P") if intpart.startswith("P") else 0)
        if intpart.startswith("P"):
            # PIC P(n)9: implizite Nachkommastellen ohne V
            it.scale = intpart.count("P") + intpart.count("9")
        u = usage or "display"
        if u == "display":
            it.kind = "zoned"
            sep = bool(sign and sign[1]) and it.signed
            it.size = it.digits + (1 if sep else 0)
            it.zsign = "zsTrailing"
            if it.signed and sign:
                it.zsign = {(False, False): "zsTrailing", (True, False): "zsLeading",
                            (False, True): "zsTrailingSeparate", (True, True): "zsLeadingSeparate"}[sign]
        elif u == "packed":
            it.kind = "packed"
            it.size = it.digits // 2 + 1
        elif u in ("binary", "comp5"):
            it.kind = u
            if it.digits > 18:
                raise CopybookError(f"Zeile {it.line}: Binärfeld mit {it.digits} Stellen")
            it.size = 2 if it.digits <= 4 else 4 if it.digits <= 9 else 8
            it.align = it.size if it.size < 8 else opts.sync8
        elif u == "national":
            raise CopybookError(f"Zeile {it.line}: PIC 9 mit USAGE NATIONAL nicht unterstützt")
        else:
            raise CopybookError(f"Zeile {it.line}: USAGE {u} mit PIC {it.pic}")
        return
    # Text: X, A, alphanumerisch und numerisch editiert
    if usage not in (None, "display"):
        raise CopybookError(f"Zeile {it.line}: PIC {it.pic} mit USAGE {usage}")
    it.kind = "edited" if set(p) - set("XA") else "text"
    it.size = len(p)


# ------------------------------------------------------------------------------------
# Satzbild

def resolve(rec, opts):
    """Arten (Vererbung von USAGE/SIGN) und Offsets berechnen."""
    def kinds(it, usage, sign):
        usage = it.usage or usage
        sign = it.sign or sign
        if it.children:
            if it.pic:
                raise CopybookError(f"Zeile {it.line}: Gruppe {it.name} mit PIC")
            it.kind = "group"
            for c in it.children:
                kinds(c, usage, sign)
            it.align = max([c.align if (c.sync or c.kind == "group") else 1 for c in it.children] + [1])
        else:
            classify(it, usage, sign, opts)
            if not it.sync:
                it.align = 1
    kinds(rec, None, None)
    layout(rec, 0)
    rec.size_total = rec.total


def layout(it, ofs):
    """Offsets ab ofs (absolut im Satz); setzt size, slack."""
    it.ofs = ofs
    if it.kind != "group":
        if it.occurs and it.align > 1 and it.size % it.align:
            it.slack_after = it.align - it.size % it.align
        return
    cur = ofs
    region = None   # (Start, Ende) des letzten nicht umdefinierenden Felds
    names = {}
    for c in it.children:
        if c.redefines:
            target = names.get(c.redefines.upper())
            if target is None:
                raise CopybookError(f"Zeile {c.line}: REDEFINES {c.redefines}: Feld nicht davor auf gleicher Stufe")
            if c.sync and c.align > 1 and target.ofs % c.align:
                raise CopybookError(f"Zeile {c.line}: SYNC in REDEFINES an nicht ausgerichteter Stelle")
            layout(c, target.ofs)
            region = (region[0], max(region[1], target.ofs + c.total))
            cur = region[1]
        else:
            start = cur
            # Füllbytes vor einem SYNC-Feld (Ausrichtung relativ zum Satzanfang); Gruppen
            # selbst werden nicht ausgerichtet, ihre SYNC-Felder bekommen eigene Füllbytes
            if c.sync and c.kind != "group" and c.align > 1:
                pad = (-start) % c.align
                if pad:
                    c.slack_before = pad
                    start += pad
            layout(c, start)
            region = (c.ofs, c.ofs + c.total)
            cur = region[1]
        if not c.filler:
            names[c.name.upper()] = c
    it.size = cur - ofs
    if it.occurs and it.align > 1 and any_sync(it) and it.size % it.align:
        it.slack_after = it.align - it.size % it.align


def any_sync(it):
    if it.kind != "group":
        return it.sync
    return any(any_sync(c) for c in it.children)


def walk(it, path=(), occ=()):
    """(item, Pfad der Pascal-Namen, Liste der OCCURS-Stufen) für alle Felder."""
    yield it, path, occ
    for c in it.children:
        cocc = occ + ((c,) if c.occurs else ())
        yield from walk(c, path + (c,), cocc)


# ------------------------------------------------------------------------------------
# Pascal-Namen

def pas_ident(name):
    s = re.sub(r"[^A-Za-z0-9_]", "_", name.upper().replace("-", "_"))
    if s[0].isdigit():
        s = "F_" + s
    if s.lower() in RESERVED:
        s += "_"
    return s


def assign_names(rec):
    # Feldnamen je Record-Ebene eindeutig; FILLER -> FILLER_n
    counter = [0]
    def fix(it):
        seen = {}
        for c in it.children:
            if c.filler:
                counter[0] += 1
                c.pasname = f"FILLER_{counter[0]}"
            else:
                c.pasname = pas_ident(c.name)
            k = c.pasname.lower()
            if k in seen:
                seen[k] += 1
                c.pasname += f"_{seen[k]}"
            else:
                seen[k] = 1
            fix(c)
    rec.pasname = pas_ident(rec.name)
    fix(rec)


def global_names(records):
    """Namen der Zugriffsfunktionen: Feldname, bei Mehrdeutigkeit mit Eltern."""
    allitems = []
    for r in records:
        r.gname = r.pasname
        for c in r.conditions:
            allitems.append((c, ()))
        for it, path, occ in walk(r):
            if it is r or it.filler:
                continue
            allitems.append((it, path))
            for c in it.conditions:
                allitems.append((c, path))
    count = {}
    for it, path in allitems:
        count[pas_ident(it.name).lower()] = count.get(pas_ident(it.name).lower(), 0) + 1
    used = set()
    for it, path in allitems:
        base = pas_ident(it.name)
        if count[base.lower()] > 1:
            par = it.parent
            while par is not None and par.filler:
                par = par.parent
            if par is not None:
                base = pas_ident(par.name) + "_" + base
        n = base
        k = 2
        while n.lower() in used:
            n = f"{base}_{k}"
            k += 1
        used.add(n.lower())
        it.gname = n


# ------------------------------------------------------------------------------------
# Ausgabe Pascal

def bytes_type(n):
    return f"array[0..{n - 1}] of byte"


def emit_type(it, ind):
    """Pascal-Typ eines Felds (eine Wiederholung)."""
    if it.kind != "group":
        t = bytes_type(it.size)
        if it.slack_after:
            t = (f"packed record\n{ind}  V: {t};\n{ind}  SLACK: {bytes_type(it.slack_after)};\n{ind}end")
        return t
    lines = ["packed record"]
    lines += emit_fields(it.children, ind + "  ")
    if it.slack_after:
        lines.append(f"{ind}  SLACK_END: {bytes_type(it.slack_after)};")
    lines.append(f"{ind}end")
    return "\n".join(lines)


def field_decl(c, ind):
    t = emit_type(c, ind)
    if c.occurs:
        t = f"packed array[1..{c.occurs[1]}] of {t}"
    return t


def emit_fields(children, ind):
    """Felder einer Gruppe; Umdefinitionen als varianter Record."""
    out = []
    i = 0
    slack = [0]
    while i < len(children):
        c = children[i]
        group = [c]
        j = i + 1
        while j < len(children) and children[j].redefines:
            group.append(children[j])
            j += 1
        if c.slack_before:
            slack[0] += 1
            out.append(f"{ind}SLACK_{c.ofs - c.slack_before}: {bytes_type(c.slack_before)};  {{ SYNC }}")
        if len(group) == 1:
            out.append(f"{ind}{c.pasname}: {field_decl(c, ind)};  {{ {c.ofs} }}")
        else:
            out.append(f"{ind}{c.pasname}_R: packed record  {{ {c.ofs}, REDEFINES }}")
            out.append(f"{ind}  case byte of")
            for k, g in enumerate(group):
                pre = ""
                if g.slack_before:
                    pre = f"SLACK_{g.ofs - g.slack_before}_{k}: {bytes_type(g.slack_before)}; "
                out.append(f"{ind}    {k}: ({pre}{g.pasname}: {field_decl(g, ind + '      ')});")
            out.append(f"{ind}end;")
        i = j
    return out


def access_path(it, path, rname):
    """Pascal-Ausdruck des Felds im Record r mit Indizes i1, i2, ..."""
    parts = ["r"]
    k = 0
    for p in path:
        nm = p.pasname
        if p.redefines or (p.parent and redefined_by_next(p)):
            parts.append(base_of_set(p).pasname + "_R")
        parts.append(nm)
        if p.occurs:
            k += 1
            parts[-1] += f"[i{k}]"
            if p.kind != "group" and p.slack_after:
                parts.append("V")
    return ".".join(parts)


def redefined_by_next(p):
    sib = p.parent.children
    i = sib.index(p)
    return i + 1 < len(sib) and sib[i + 1].redefines is not None


def base_of_set(p):
    sib = p.parent.children
    i = sib.index(p)
    while sib[i].redefines:
        i -= 1
    return sib[i]


def lit_pas(lit, kind):
    t, v = lit
    if t == "str":
        return "'" + v.replace("'", "''") + "'"
    if t == "num":
        return "'" + v.lstrip("+") + "'" if kind not in ("text", "edited") else "'" + v + "'"
    raise CopybookError("Literal")


def emit_unit(records, unitname, opts, warnings, srcname):
    L = []
    w = L.append
    w(f"{{ {unitname}: erzeugt von scripts/copybook2pas.py aus {srcname}, nicht von Hand ändern.")
    w("  Felder sind Byte-Felder mit den Offsets des COBOL-Programms (packed, unabhängig von der")
    w("  Byte-Reihenfolge); Zugriff über Get_/Set_ (Units zoscobol, zosdecimal, zosccsid).")
    for x in warnings:
        w("  Warnung: " + x)
    w("}")
    w(f"unit {unitname};")
    w("")
    w("{$mode objfpc}{$H+}")
    w("{$R-}")
    w("")
    w("interface")
    w("")
    w("uses")
    w("  zoscobol, zosdecimal, zosccsid;")
    w("")
    w("const")
    w(f"  {unitname}_CCSID = {opts.ccsid};   {{ CCSID der Textfelder (Standard der Get_/Set_) }}")
    w("")
    # Konstanten (Offsets, 88-Werte)
    consts = []
    types = []
    procs_if = []
    procs_impl = []
    for rec in records:
        tname = "T" + rec.pasname
        if rec.children:
            body = ["packed record"] + emit_fields(rec.children, "    ") + ["  end"]
            if rec.occurs:
                raise CopybookError("OCCURS auf Stufe 01")
            types.append(f"  {tname} = " + "\n".join(body) + ";")
        else:
            types.append(f"  {tname} = {bytes_type(rec.size)};")
        types.append(f"  P{rec.pasname} = ^{tname};")
        consts.append(f"  {rec.pasname}_SIZE = {rec.size};")
        # Satzbild als Kommentar
        consts.append(f"  {{ Satzbild {rec.name}:")
        for it, path, occ in walk(rec):
            desc = it.kind
            if it.pic:
                desc += " PIC " + it.pic
            if it.occurs:
                lo, hi, dep = it.occurs
                desc += f" OCCURS {hi}" if lo == hi and not dep else f" OCCURS {lo} TO {hi} DEPENDING ON {dep}"
            if it.redefines:
                desc += " REDEFINES " + it.redefines
            if it.sync:
                desc += " SYNC"
            consts.append(f"    {'  ' * len(path)}{it.level:02d} {it.name:<24} ofs {it.ofs:5d} len {it.size:5d}  {desc}")
        consts.append("  }")
        for it, path, occ in walk(rec):
            if it.filler:
                continue
            if it is not rec:
                consts.append(f"  {it.gname}_OFS = {it.ofs};  {it.gname}_LEN = {it.size};")
            for c in it.conditions:
                v = c.values[0][0]
                if v[0] in ("str", "num") and c.values[0][1] is None:
                    consts.append(f"  {c.gname} = {lit_pas(v, it.kind) if v[0] == 'str' else v[1].lstrip('+')};")
        emit_access(rec, tname, opts, procs_if, procs_impl, unitname)
    for c in consts:
        w(c)
    w("")
    w("type")
    for t in types:
        w(t)
    w("")
    for p in procs_if:
        w(p)
    w("")
    w("implementation")
    w("")
    w("uses")
    w("  sysutils;")
    w("")
    w("function D(const s: string): TDecimal; inline;")
    w("begin")
    w("  result:=TDecimal.FromString(s);")
    w("end;")
    w("")
    w("function AllBytes(const f; len: SizeInt; b: byte): boolean;")
    w("var")
    w("  i: SizeInt;")
    w("begin")
    w("  for i:=0 to len-1 do")
    w("    if PByte(@f)[i]<>b then")
    w("      exit(false);")
    w("  result:=true;")
    w("end;")
    w("")
    for p in procs_impl:
        w(p)
    w("end.")
    return "\n".join(L) + "\n"


def idx_params(occ):
    return "".join(f"; i{k + 1}: SizeInt" for k in range(len(occ)))


def idx_args(occ):
    return "".join(f", i{k + 1}" for k in range(len(occ)))


def emit_access(rec, tname, opts, IF, IMPL, unitname):
    ccsid = f"{unitname}_CCSID"
    for it, path, occ in walk(rec):
        if it is rec and not rec.children:
            path = ()
        if it.kind == "group" or it.filler:
            continue
        expr = access_path(it, path, "r") if path else "r"
        ip = idx_params(occ)
        g = it.gname if it is not rec else rec.pasname
        sig_get = sig_set = None
        if it.kind in ("text", "edited"):
            sig_get = f"function Get_{g}(const r: {tname}{ip}; ccsid: longint = {ccsid}): RawByteString;"
            body_get = f"  result:=CobGetText({expr},{it.size},ccsid);"
            sig_set = f"procedure Set_{g}(var r: {tname}{ip}; const v: RawByteString; ccsid: longint = {ccsid});"
            body_set = f"  CobSetText({expr},{it.size},v,ccsid);"
        elif it.kind == "national":
            sig_get = f"function Get_{g}(const r: {tname}{ip}): UnicodeString;"
            body_get = f"  result:=CobGetNational({expr},{it.digits});"
            sig_set = f"procedure Set_{g}(var r: {tname}{ip}; const v: UnicodeString);"
            body_set = f"  CobSetNational({expr},{it.digits},v);"
        elif it.kind == "zoned":
            s = "true" if it.signed else "false"
            sig_get = f"function Get_{g}(const r: {tname}{ip}): TDecimal;"
            body_get = f"  result:=ZonedToDecimal({expr},{it.digits},{it.scale},{s},{it.zsign});"
            sig_set = f"procedure Set_{g}(var r: {tname}{ip}; const v: TDecimal; rounding: TDecRounding = drTruncate);"
            body_set = f"  DecimalToZoned(v,{expr},{it.digits},{it.scale},{s},{it.zsign},rounding);"
        elif it.kind == "packed":
            s = "true" if it.signed else "false"
            sig_get = f"function Get_{g}(const r: {tname}{ip}): TDecimal;"
            body_get = f"  result:=PackedToDecimal({expr},{it.digits},{it.scale});"
            sig_set = f"procedure Set_{g}(var r: {tname}{ip}; const v: TDecimal; rounding: TDecRounding = drTruncate);"
            body_set = f"  DecimalToPacked(v,{expr},{it.digits},{it.scale},{s},rounding);"
        elif it.kind in ("binary", "comp5"):
            s = "true" if it.signed else "false"
            dg = it.digits if it.kind == "binary" else 0
            if it.scale == 0:
                sig_get = f"function Get_{g}(const r: {tname}{ip}): Int64;"
                body_get = f"  result:=CobGetBinary({expr},{it.size},{s});"
                sig_set = f"procedure Set_{g}(var r: {tname}{ip}; v: Int64);"
                body_set = f"  CobSetBinary({expr},{it.size},{s},v,{dg});"
            else:
                sig_get = f"function Get_{g}(const r: {tname}{ip}): TDecimal;"
                body_get = f"  result:=CobGetBinaryDec({expr},{it.size},{s},{it.scale});"
                sig_set = f"procedure Set_{g}(var r: {tname}{ip}; const v: TDecimal; rounding: TDecRounding = drTruncate);"
                body_set = f"  CobSetBinaryDec({expr},{it.size},{s},{it.scale},{dg},v,rounding);"
        elif it.kind == "float":
            fn = ("HfpToDouble", "DoubleToHfp") if opts.float == "hex" else ("IeeeBEToDouble", "DoubleToIeeeBE")
            sig_get = f"function Get_{g}(const r: {tname}{ip}): double;"
            body_get = f"  result:={fn[0]}({expr},{it.size});"
            sig_set = f"procedure Set_{g}(var r: {tname}{ip}; v: double);"
            body_set = f"  {fn[1]}(v,{expr},{it.size});"
        elif it.kind in ("index", "pointer"):
            sig_get = f"function Get_{g}(const r: {tname}{ip}): Int64;"
            body_get = f"  result:=CobGetBinary({expr},{it.size},false);"
            sig_set = f"procedure Set_{g}(var r: {tname}{ip}; v: Int64);"
            body_set = f"  CobSetBinary({expr},{it.size},false,v,0);"
        IF.append(sig_get)
        IF.append(sig_set)
        IMPL += [sig_get, "begin", body_get, "end;", "", sig_set, "begin", body_set, "end;", ""]
        for c in it.conditions:
            emit_88(c, it, tname, ip, occ, IF, IMPL)
    emit_init(rec, tname, IF, IMPL, unitname)
    emit_layout_check(rec, tname, IF, IMPL)
    emit_odo(rec, tname, IF, IMPL)


def emit_88(c, it, tname, ip, occ, IF, IMPL):
    a = idx_args(occ)
    g = it.gname
    conds = []
    numeric = it.kind in ("zoned", "packed", "binary", "comp5")
    raw = access_path(it, walk_path(it), "r")
    for lo, hi in c.values:
        if lo[0] == "fig":
            f = lo[1]
            if f == "SPACE":
                conds.append(f"(Get_{g}(r{a})='')" if not numeric else "false")
            elif f == "ZERO":
                conds.append(f"Get_{g}(r{a}).IsZero" if numeric and it.kind not in ("binary", "comp5")
                             else f"(Get_{g}(r{a})=0)" if numeric
                             else f"(Get_{g}(r{a})=StringOfChar('0',{it.size}))")
            elif f == "LOW":
                conds.append(f"AllBytes({raw},{it.size},$00)")
            elif f == "HIGH":
                conds.append(f"AllBytes({raw},{it.size},$FF)")
            else:
                conds.append(f"(Get_{g}(r{a})=StringOfChar('\"',{it.size}))")
            continue
        if lo[0] == "hex":
            conds.append("(" + " and ".join(f"(PByte(@{raw})[{k}]=${b:02X})" for k, b in enumerate(lo[1])) + ")")
            continue
        if numeric:
            v = f"D('{lo[1].lstrip('+')}')"
            if it.kind in ("binary", "comp5") and it.scale == 0:
                v = lo[1].lstrip("+")
                if hi:
                    conds.append(f"((Get_{g}(r{a})>={v}) and (Get_{g}(r{a})<={hi[1].lstrip('+')}))")
                else:
                    conds.append(f"(Get_{g}(r{a})={v})")
                continue
            if hi:
                conds.append(f"((Get_{g}(r{a})>={v}) and (Get_{g}(r{a})<=D('{hi[1].lstrip('+')}')))")
            else:
                conds.append(f"(Get_{g}(r{a})={v})")
        else:
            if hi:
                # Bereich bei Text: ein Vergleich in ISO-8859-1 hätte eine andere
                # Sortierfolge als EBCDIC
                raise CopybookError(f"Zeile {c.line}: Stufe 88 {c.name}: THRU bei Textfeldern nicht unterstützt")
            conds.append(f"(Get_{g}(r{a})=TrimRight({lit_pas(lo, it.kind)}))")
    sig = f"function Is_{c.gname}(const r: {tname}{ip}): boolean;"
    IF.append(sig)
    IMPL += [sig, "begin", "  result:=" + " or\n    ".join(conds) + ";", "end;", ""]
    # SET cond TO TRUE: erster Wert
    lo = c.values[0][0]
    if lo[0] in ("str", "num"):
        sig = f"procedure Set_{c.gname}(var r: {tname}{ip});"
        if numeric:
            val = f"D('{lo[1].lstrip('+')}')" if not (it.kind in ("binary", "comp5") and it.scale == 0) else lo[1].lstrip("+")
            body = f"  Set_{g}(r{a},{val});"
        else:
            body = f"  Set_{g}(r{a},{lit_pas(lo, it.kind)});"
        IF.append(sig)
        IMPL += [sig, "begin", body, "end;", ""]


def walk_path(it):
    p = []
    x = it
    while x.parent is not None:
        p.append(x)
        x = x.parent
    return tuple(reversed(p))


def emit_init(rec, tname, IF, IMPL, unitname):
    """Initialize_<Satz>: Text Leerzeichen, numerisch 0 (wie COBOL INITIALIZE), FILLER und
    Füllbytes X'00'... FILLER bleibt wie COBOL unverändert, Füllbytes 0."""
    sig = f"procedure Initialize_{rec.pasname}(var r: {tname}; ccsid: longint = {unitname}_CCSID);"
    IF.append(sig)
    body = []
    depth = [0]
    loops = []
    vars_ = set()
    for it, path, occ in walk(rec):
        if it.kind == "group" or it.filler or (it is rec and not rec.children):
            continue
        if path == ():
            continue
        a = idx_args(occ)
        stmt = {
            "text": f"Set_{it.gname}(r{a},'',ccsid);",
            "edited": f"Set_{it.gname}(r{a},'',ccsid);",
            "national": f"Set_{it.gname}(r{a},'');",
            "zoned": f"Set_{it.gname}(r{a},TDecimal.Zero);",
            "packed": f"Set_{it.gname}(r{a},TDecimal.Zero);",
            "float": f"Set_{it.gname}(r{a},0);",
            "index": f"Set_{it.gname}(r{a},0);",
            "pointer": f"Set_{it.gname}(r{a},0);",
        }.get(it.kind)
        if it.kind in ("binary", "comp5"):
            stmt = f"Set_{it.gname}(r{a},0);" if it.scale == 0 else f"Set_{it.gname}(r{a},TDecimal.Zero);"
        ind = "  "
        pre = []
        post = []
        for k, o in enumerate(occ):
            vars_.add(f"i{k + 1}")
            pre.append(f"{ind}for i{k + 1}:=1 to {o.occurs[1]} do")
            ind += "  "
        body += pre + [ind + stmt]
    IMPL.append(sig)
    if vars_:
        IMPL.append("var")
        IMPL.append("  " + ", ".join(sorted(vars_)) + ": SizeInt;")
    IMPL.append("begin")
    IMPL.append("  FillChar(r,SizeOf(r),0);")
    IMPL += body
    IMPL += ["end;", ""]


def emit_layout_check(rec, tname, IF, IMPL):
    sig = f"function {rec.pasname}_LayoutOk: boolean;"
    IF.append(f"{{ prüft SizeOf und die Offsets der Felder (erste Wiederholung) }}")
    IF.append(sig)
    IMPL += [sig, "var", "  r: " + tname + ";", "  b: PtrUInt;", "begin",
             "  b:=PtrUInt(@r);",
             f"  result:=SizeOf({tname})={rec.size};"]
    for it, path, occ in walk(rec):
        if it is rec or it.filler:
            continue
        e = access_path(it, path, "r")
        for k in range(len(occ)):
            e = e.replace(f"[i{k + 1}]", "[1]")
        IMPL.append(f"  result:=result and (PtrUInt(@{e})-b={it.ofs});")
    IMPL += ["end;", ""]


def emit_odo(rec, tname, IF, IMPL):
    for it, path, occ in walk(rec):
        if not it.occurs or not it.occurs[2]:
            continue
        dep = it.occurs[2]
        depitem = None
        for x, p, o in walk(rec):
            if x.name.upper() == dep.upper() and not o:
                depitem = x
        last = it.ofs + it.total == rec.size and len(occ) == 1
        if depitem is None or not last or depitem.kind not in ("zoned", "packed", "binary", "comp5"):
            IF.append(f"{{ {it.name}: OCCURS DEPENDING ON {dep} erkannt; Satzlänge nicht erzeugt "
                      f"(Tabelle nicht am Satzende oder {dep} nicht ermittelbar) }}")
            continue
        sig = f"function {rec.pasname}_Length(const r: {tname}): SizeInt;"
        IF.append(f"{{ tatsächliche Länge: {it.name} OCCURS DEPENDING ON {dep} }}")
        IF.append(sig)
        getv = f"Get_{depitem.gname}(r)" + ("" if depitem.kind in ("binary", "comp5") and depitem.scale == 0 else ".ToInt64")
        IMPL += [sig, "var", "  n: Int64;", "begin", f"  n:={getv};",
                 f"  if (n<{it.occurs[0]}) or (n>{it.occurs[1]}) then",
                 f"    raise EDecimalOverflow.CreateFmt('{dep} = %d außerhalb {it.occurs[0]}..{it.occurs[1]}', [n]);",
                 f"  result:={it.ofs}+n*{it.size + it.slack_after};", "end;", ""]


# ------------------------------------------------------------------------------------

def layout_json(records):
    out = []
    for rec in records:
        items = []
        for it, path, occ in walk(rec):
            d = {"level": it.level, "name": it.name, "ofs": it.ofs, "len": it.size,
                 "kind": it.kind}
            if it.kind not in ("group", "text", "edited", "float", "index", "pointer"):
                d["digits"] = it.digits
                d["scale"] = it.scale
                d["signed"] = it.signed
            if it.occurs:
                d["occurs"] = list(it.occurs)
            if it.redefines:
                d["redefines"] = it.redefines
            if it.slack_before:
                d["slack_before"] = it.slack_before
            if it.slack_after:
                d["slack_after"] = it.slack_after
            if it.conditions:
                d["conditions"] = [c.name for c in it.conditions]
            items.append(d)
        out.append({"record": rec.name, "size": rec.size, "items": items})
    return out


def convert(text, opts, unitname="copybook", srcname="copybook"):
    records, warnings = parse(text, opts.free)
    if not records:
        raise CopybookError("keine Stufe 01/77 gefunden")
    for r in records:
        resolve(r, opts)
        assign_names(r)
    global_names(records)
    if opts.json:
        return json.dumps(layout_json(records), indent=1, ensure_ascii=False) + "\n"
    return emit_unit(records, unitname, opts, warnings, srcname)


def options(argv=None):
    ap = argparse.ArgumentParser(description="COBOL-Copybook -> Pascal-Unit")
    ap.add_argument("copybook")
    ap.add_argument("-o", "--output")
    ap.add_argument("--unit")
    ap.add_argument("--ccsid", type=int, default=1047)
    ap.add_argument("--float", choices=("hex", "ieee"), default="hex")
    ap.add_argument("--free", action="store_true")
    ap.add_argument("--pointer", type=int, choices=(4, 8), default=4)
    ap.add_argument("--sync8", type=int, choices=(4, 8), default=8)
    ap.add_argument("--json", action="store_true")
    return ap.parse_args(argv)


def main(argv=None):
    o = options(argv)
    with open(o.copybook, encoding="utf-8", errors="replace") as f:
        text = f.read()
    base = os.path.splitext(os.path.basename(o.copybook))[0]
    unitname = o.unit or pas_ident(base).lower()
    try:
        out = convert(text, o, unitname, os.path.basename(o.copybook))
    except CopybookError as e:
        print(f"copybook2pas: {o.copybook}: {e}", file=sys.stderr)
        return 1
    if o.json and not o.output:
        sys.stdout.write(out)
        return 0
    path = o.output or os.path.join(os.path.dirname(o.copybook), unitname + ".pas")
    with open(path, "w", encoding="utf-8") as f:
        f.write(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
