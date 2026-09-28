#!/usr/bin/env python3
"""Zeilentabelle für Backtraces aus GOFF-Objekten (DWARF D_LINE) erzeugen.

    goff-lines.py ausgabe.c objekt.o...

Der z/OS-Binder übernimmt die DWARF-Klassen (D_LINE, D_INFO, ...) als nicht
ladbare Daten; zur Laufzeit sind sie nicht erreichbar. Deshalb wird die
Zeileninformation beim Binden (zos-ld) aus den Objekten gelesen und als kleine
C-Tabelle FPC_ZOS_LINETABLE mitgebunden: je Funktion (Name wie im PPA1)
Datei und Paare (Offset ab Funktionsbeginn, Zeile). runtime/zosunwind.c
(FPC_ZOS_FUNC_LINE) sucht darin.

GOFF: 80-Byte-Records (ESD/TXT/RLD, siehe goffdump.py). DWARF-Adressen in
D_LINE (DW_LNE_set_address) sind A-Konstanten mit einer RLD auf C_CODE64 (der
Addend im Text ist der Offset im Code) oder auf ein LD-Symbol. Funktionen sind
die LD-Symbole in C_CODE64 mit ihrem Offset.
Ausgabe: Anzahl Funktionen mit Zeilen auf stderr.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from goffdump import ebcdic, records  # noqa: E402


def parse(path):
    data = open(path, "rb").read()
    esd = {}           # id -> (typ, parent, name, offset)
    text = {}          # id -> bytearray
    rlds = []          # (r_id, p_id, offset, length)
    for _, rtype, r in records(data):
        if rtype == 0x0:
            esdid = int.from_bytes(r[4:8], "big")
            parent = int.from_bytes(r[8:12], "big")
            off = int.from_bytes(r[16:20], "big")
            nlen = int.from_bytes(r[70:72], "big")
            esd[esdid] = (r[3], parent, ebcdic(bytes(r[72:72 + nlen])), off)
        elif rtype == 0x1:
            esdid = int.from_bytes(r[4:8], "big")
            off = int.from_bytes(r[12:16], "big")
            dlen = int.from_bytes(r[22:24], "big")
            buf = text.setdefault(esdid, bytearray())
            if len(buf) < off + dlen:
                buf.extend(b"\0" * (off + dlen - len(buf)))
            buf[off:off + dlen] = r[24:24 + dlen]
        elif rtype == 0x2:
            items = bytes(r[6:6 + int.from_bytes(r[4:6], "big")])
            pos, r_id, p_id, off = 0, None, None, None
            while pos + 8 <= len(items):
                f = items[pos:pos + 6]
                pos += 8
                if not f[0] & 0x80:
                    r_id = int.from_bytes(items[pos:pos + 4], "big"); pos += 4
                if not f[0] & 0x40:
                    p_id = int.from_bytes(items[pos:pos + 4], "big"); pos += 4
                if not f[0] & 0x20:
                    n = 8 if f[0] & 0x02 else 4
                    off = int.from_bytes(items[pos:pos + n], "big"); pos += n
                rlds.append((r_id, p_id, off, f[4]))
    return esd, text, rlds


def uleb(b, p):
    v = s = 0
    while True:
        x = b[p]; p += 1
        v |= (x & 0x7F) << s; s += 7
        if not x & 0x80:
            return v, p


def sleb(b, p):
    v = s = 0
    while True:
        x = b[p]; p += 1
        v |= (x & 0x7F) << s; s += 7
        if not x & 0x80:
            if x & 0x40:
                v -= 1 << s
            return v, p


def u(b, p, n):
    return int.from_bytes(b[p:p + n], "big")


def cstr(b, p):
    e = b.index(0, p)
    return b[p:e].decode("latin-1"), e + 1


def line_programs(line, dstr):
    """Alle Zeilenprogramme in D_LINE: Liefert (Dateinamen, [(addr, datei, zeile)])."""
    p = 0
    while p + 4 <= len(line):
        unit_len = u(line, p, 4)
        if unit_len == 0 or unit_len >= 0xFFFFFFF0:
            break
        end = p + 4 + unit_len
        ver = u(line, p + 4, 2)
        q = p + 6
        if ver >= 5:
            q += 2                          # address_size, segment_selector_size
        hlen = u(line, q, 4); q += 4
        prog = q + hlen
        min_inst = line[q]; q += 1
        if ver >= 4:
            q += 1                          # maximum_operations_per_instruction
        q += 1                              # default_is_stmt
        line_base = line[q] - 256 if line[q] > 127 else line[q]; q += 1
        line_range = line[q]; q += 1
        opcode_base = line[q]; q += 1
        std_len = list(line[q:q + opcode_base - 1]); q += opcode_base - 1
        files = [""] if ver < 5 else []
        if ver < 5:
            while line[q]:                  # include_directories
                _, q = cstr(line, q)
            q += 1
            while line[q]:                  # file_names
                name, q = cstr(line, q)
                _, q = uleb(line, q); _, q = uleb(line, q); _, q = uleb(line, q)
                files.append(name)
        else:
            fmt_cnt = line[q]; q += 1
            fmts = []
            for _ in range(fmt_cnt):
                a, q = uleb(line, q); f, q = uleb(line, q); fmts.append((a, f))
            dcnt, q = uleb(line, q)
            for _ in range(dcnt):
                for a, f in fmts:
                    q = skip_form(line, q, f)
            fmt_cnt = line[q]; q += 1
            fmts = []
            for _ in range(fmt_cnt):
                a, q = uleb(line, q); f, q = uleb(line, q); fmts.append((a, f))
            fcnt, q = uleb(line, q)
            for _ in range(fcnt):
                name = ""
                for a, f in fmts:
                    if a == 1:              # DW_LNCT_path
                        if f == 0x08:       # DW_FORM_string
                            name, q = cstr(line, q)
                        elif f == 0x1f:     # DW_FORM_line_strp
                            off = u(line, q, 4); q += 4
                            name, _ = cstr(dstr, off) if dstr else ("?", 0)
                        else:
                            q = skip_form(line, q, f)
                    else:
                        q = skip_form(line, q, f)
                files.append(name)
        rows = []
        q = prog
        addr, fidx, ln = 0, 1, 1
        while q < end:
            op = line[q]; q += 1
            if op >= opcode_base:
                adj = op - opcode_base
                addr += (adj // line_range) * min_inst
                ln += line_base + adj % line_range
                rows.append((addr, fidx, ln))
            elif op == 0:
                n, q = uleb(line, q)
                sub = line[q]
                if sub == 1:                # end_sequence
                    addr, fidx, ln = 0, 1, 1
                elif sub == 2:              # set_address
                    addr = int.from_bytes(line[q + 1:q + n], "big")
                    yield_addr_pos = q + 1
                    addr = ("R", yield_addr_pos, addr)
                    rows.append(addr)       # Marke: Adresse neu setzen (Relokation)
                    addr = addr[2]
                q += n
            elif op == 1:                   # copy
                rows.append((addr, fidx, ln))
            elif op == 2:
                v, q = uleb(line, q); addr += v * min_inst
            elif op == 3:
                v, q = sleb(line, q); ln += v
            elif op == 4:
                fidx, q = uleb(line, q)
            elif op in (5, 7):
                if op == 5:
                    _, q = uleb(line, q)
            elif op == 6:
                pass
            elif op == 8:
                addr += ((255 - opcode_base) // line_range) * min_inst
            elif op == 9:
                addr += u(line, q, 2); q += 2
            else:
                for _ in range(std_len[op - 1]):
                    _, q = uleb(line, q)
        yield files, rows
        p = end


def skip_form(b, q, f):
    sizes = {0x0b: 1, 0x05: 2, 0x06: 4, 0x07: 8, 0x0e: 4, 0x1f: 4, 0x17: 4, 0x1e: 16, 0x0c: 1}
    if f in sizes:
        return q + sizes[f]
    if f == 0x08:
        return b.index(0, q) + 1
    if f in (0x0f, 0x0d):
        _, q = uleb(b, q)
        return q
    raise ValueError(f"DWARF-Form 0x{f:x} nicht unterstützt")


def code_of(path):
    esd, text, _ = parse(path)
    ids = {name: i for i, (typ, _, name, _) in esd.items() if typ == 1}
    return bytes(text.get(ids.get("C_CODE64"), b""))


def object_lines(path):
    """Liefert {Funktionsname: (Datei, [(Offset in der Funktion, Zeile)])}.
    path: Objekt mit Debug-Informationen (.dbgo); liegt daneben das gebundene
    Objekt (Name ohne .dbgo), muss dessen Code gleich sein."""
    esd, text, rlds = parse(path)
    ids = {name: i for i, (typ, _, name, _) in esd.items() if typ == 1}
    bound = path[:-5] if path.endswith(".dbgo") else None
    if bound and os.path.exists(bound) and             code_of(bound) != bytes(text.get(ids.get("C_CODE64"), b"")):
        raise ValueError("Code mit und ohne Debug-Informationen verschieden, keine Zeilen")
    line_id = ids.get("D_LINE")
    code_id = ids.get("C_CODE64")
    if line_id is None or code_id is None:
        return {}
    line = bytes(text.get(line_id, b""))
    dstr = bytes(text.get(ids["D_LSTR"], b"")) if "D_LSTR" in ids else b""
    # Basis der Relokationen in D_LINE: C_CODE64 -> 0, LD-Symbol -> sein Offset
    reloc_base = {}
    for r_id, p_id, off, ln in rlds:
        if p_id == line_id and r_id in esd:
            typ, parent, _, loff = esd[r_id]
            if r_id == code_id:
                reloc_base[off] = 0
            elif typ == 2 and parent == code_id:
                reloc_base[off] = loff
    funcs = sorted((off, name) for typ, parent, name, off in esd.values()
                   if typ == 2 and parent == code_id and not name.startswith(("L#", "."))
                   and not name.endswith("#C"))
    result = {}
    for files, rows in line_programs(line, dstr):
        cur = []
        base = 0
        for r in rows:
            if r[0] == "R":
                base = reloc_base.get(r[1], 0)
                continue
            addr, fidx, ln = r
            cur.append((base + addr, fidx, ln))
        cur.sort()
        for i, (foff, fname) in enumerate(funcs):
            fend = funcs[i + 1][0] if i + 1 < len(funcs) else 1 << 62
            frows = [(a - foff, f, l) for a, f, l in cur if foff <= a < fend and l > 0]
            if not frows:
                continue
            fidx = frows[0][1]
            out = []
            for a, f, l in frows:
                if not out or out[-1][1] != l:
                    out.append((a, l))
            fn = files[fidx] if 0 <= fidx < len(files) else "?"
            result[fname] = (os.path.basename(fn), out)
    return result


def cname(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def main():
    out, objs = sys.argv[1], sys.argv[2:]
    table = {}
    for o in objs:
        try:
            table.update(object_lines(o))
        except (ValueError, IndexError) as e:
            print(f"goff-lines: {o}: {e}", file=sys.stderr)
    with open(out, "w") as f:
        f.write("/* erzeugt von goff-lines.py: Zeilentabelle für Backtraces (zosunwind.c) */\n")
        f.write("struct fpc_zos_lrow { unsigned int off, line; };\n")
        f.write("struct fpc_zos_lfunc { const char *name, *file; "
                "const struct fpc_zos_lrow *rows; unsigned int n; };\n")
        for i, (name, (fn, rows)) in enumerate(sorted(table.items())):
            f.write(f"static struct fpc_zos_lrow r{i}[] = {{")
            f.write(",".join(f"{{{a},{l}}}" for a, l in rows))
            f.write("};\n")
        # nicht const: eine const-Tabelle mit Zeigern legt clang für z/OS in den
        # Code, die Zeiger zeigen aber in den WSA (Binder: IEW2353E 250001)
        f.write("struct fpc_zos_lfunc FPC_ZOS_LINETABLE[] = {\n")
        for i, (name, (fn, rows)) in enumerate(sorted(table.items())):
            f.write(f'  {{"{cname(name)}", "{cname(fn)}", r{i}, {len(rows)}}},\n')
        f.write("  {0, 0, 0, 0}\n};\n")
    print(f"goff-lines: {len(table)} Funktionen mit Zeilen", file=sys.stderr)


if __name__ == "__main__":
    main()
