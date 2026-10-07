#!/usr/bin/env python3
"""zdbg-instrument.py: LLVM-IR (FPC, -g) für den z/OS-Debugger instrumentieren.

  zdbg-instrument.py in.ll > out.ll

Für jede Funktion mit Debug-Informationen (DISubprogram):
  - ein Frame-Satz im Stack: { ptr prev, ptr func, i32 line, i32 0, [N x ptr] vars }
    (Adressen der Variablen aus llvm.dbg.declare), am Anfang FPC_ZOS_DBG_ENTER(satz);
  - vor der ersten Anweisung jeder neuen Quellzeile FPC_ZOS_DBG_LINE(satz, zeile).
Dazu Beschreibungen (Funktion, Variablen, Typen, globale Variablen des Moduls) als
Datenobjekte, die der Debug-Agent (runtime/zosdbg.c) liest. Die Beschreibungen sind
bewusst nicht "constant" (Zeigertabellen im Code-Bereich: Binder IEW2353E).

Typarten (kind, wie in zosdbg.c): 0 unbekannt, 1 int, 2 unsigned, 3 float, 4 boolean,
5 char, 6 Zeiger, 7 Record, 8 Array, 9 AnsiString, 10 ShortString, 11 Aufzählung,
12 Klasse (Zeiger auf Record), 13 WideChar, 14 UnicodeString/WideString, 15 Menge,
16 Referenz (var-Parameter: Adresse der Variablen).
"""
import re
import sys

K_UNKNOWN, K_INT, K_UINT, K_FLOAT, K_BOOL, K_CHAR, K_PTR, K_STRUCT, K_ARRAY, K_ANSI, \
    K_SHORT, K_ENUM, K_CLASS, K_WCHAR, K_USTR, K_SET, K_REF = range(17)

MD = re.compile(r'^!(\d+) = (?:distinct )?(.*)$')


def field(s, name):
    m = re.search(r'\b' + name + r': (?:"((?:[^"\\]|\\.)*)"|(![0-9]+|[-A-Za-z0-9_|]+))', s)
    if not m:
        return None
    return m.group(1) if m.group(1) is not None else m.group(2)


def ref(s, name):
    v = field(s, name)
    return v[1:] if v and v.startswith('!') else None


def cstr(s):
    """LLVM-String-Konstante (c"...\\00") und Länge."""
    b = s.encode('latin-1', 'replace') + b'\0'
    out = ''.join(chr(c) if 32 <= c < 127 and c not in (34, 92) else '\\%02X' % c for c in b)
    return out, len(b)


class Instrumenter:
    def __init__(self, text):
        self.lines = text.split('\n')
        self.md = {}
        for l in self.lines:
            m = MD.match(l)
            if m:
                self.md[m.group(1)] = m.group(2)
        self.globals_out = []   # neue globale Definitionen
        self.strings = {}       # Text -> Name
        self.types = {}         # Metadaten-Nr. -> Name der Typbeschreibung
        self.nfunc = 0

    # ---------- Datenobjekte ----------
    def string(self, s):
        if s not in self.strings:
            name = '@zdbg.s.%d' % len(self.strings)
            body, n = cstr(s)
            self.globals_out.append('%s = internal global [%d x i8] c"%s", align 1' % (name, n, body))
            self.strings[s] = name
        return self.strings[s]

    def strip_typedef(self, n):
        name = None
        seen = 0
        while n and seen < 20:
            v = self.md.get(n, '')
            if v.startswith('!DIDerivedType') and field(v, 'tag') in ('DW_TAG_typedef', 'DW_TAG_const_type',
                                                                      'DW_TAG_volatile_type'):
                name = name or field(v, 'name')
                n = ref(v, 'baseType')
                seen += 1
                continue
            break
        return n, name

    def type_desc(self, n):
        """Name der Typbeschreibung für Metadaten-Knoten n (rekursiv, mit Zyklen)."""
        if n is None:
            return 'null'
        if n in self.types:
            return self.types[n]
        tname = '@zdbg.t.%s' % n
        self.types[n] = tname
        base_n, tdname = self.strip_typedef(n)
        v = self.md.get(base_n, '')
        size = int(field(v, 'size') or 0) // 8
        name = tdname or field(v, 'name') or ''
        kind, base, count, low, fields = K_UNKNOWN, 'null', 0, 0, 'null'
        upname = name.upper()
        if v.startswith('!DIBasicType'):
            enc = field(v, 'encoding') or ''
            kind = {'DW_ATE_signed': K_INT, 'DW_ATE_unsigned': K_UINT, 'DW_ATE_float': K_FLOAT,
                    'DW_ATE_boolean': K_BOOL, 'DW_ATE_signed_char': K_CHAR,
                    'DW_ATE_unsigned_char': K_CHAR, 'DW_ATE_UTF': K_WCHAR}.get(enc, K_UINT)
            if kind == K_CHAR and size == 2:
                kind = K_WCHAR
        elif v.startswith('!DIDerivedType'):
            tag = field(v, 'tag')
            b = ref(v, 'baseType')
            if upname in ('ANSISTRING', 'RAWBYTESTRING', 'UTF8STRING', 'STRING') and tag == 'DW_TAG_pointer_type' \
                    or (tdname or '').upper() in ('ANSISTRING', 'RAWBYTESTRING', 'UTF8STRING'):
                kind = K_ANSI
            elif (tdname or '').upper() in ('UNICODESTRING', 'WIDESTRING'):
                kind = K_USTR
            elif tag in ('DW_TAG_pointer_type',):
                bb, _ = self.strip_typedef(b)
                bv = self.md.get(bb, '')
                kind = K_CLASS if field(bv, 'tag') == 'DW_TAG_class_type' or \
                    (field(bv, 'tag') == 'DW_TAG_structure_type' and '_vptr' in self.members_text(bv)) else K_PTR
                base = self.type_desc(b)
                size = size or 8
            elif tag in ('DW_TAG_reference_type', 'DW_TAG_rvalue_reference_type'):
                kind = K_REF
                base = self.type_desc(b)
                size = 8
        elif v.startswith('!DICompositeType'):
            tag = field(v, 'tag')
            if tag in ('DW_TAG_structure_type', 'DW_TAG_class_type', 'DW_TAG_union_type'):
                mems = self.members(v)
                if upname == 'SHORTSTRING' or ([m[0].upper() for m in mems[:2]] == ['LENGTH', 'ST']):
                    kind = K_SHORT
                else:
                    kind = K_STRUCT
                    count = len(mems)
                    fields = self.field_table(tname, mems)
            elif tag == 'DW_TAG_array_type':
                kind = K_ARRAY
                el = ref(v, 'elements')
                subs = re.findall(r'!(\d+)', self.md.get(el, '')) if el else []
                sv = self.md.get(subs[0], '') if subs else ''
                c = field(sv, 'count')
                lb = field(sv, 'lowerBound')
                ub = field(sv, 'upperBound')
                try:
                    low = int(lb) if lb and not lb.startswith('!') else 0
                    if c and not c.startswith('!'):
                        count = int(c)
                    elif ub and not ub.startswith('!'):
                        count = int(ub) - low + 1
                except ValueError:
                    count = 0
                if count < 0:
                    count = 0   # offenes/dynamisches Array
                if len(subs) > 1:
                    # mehrdimensional: Rest als eigener Arraytyp
                    inner = 'zdbg.a.%s' % n
                    self.md[inner] = '!DICompositeType(tag: DW_TAG_array_type, baseType: !%s, elements: !%s.rest, size: %d)' % (
                        ref(v, 'baseType'), inner, (size // max(count, 1)) * 8)
                    self.md[inner + '.rest'] = '!{' + ', '.join('!' + s for s in subs[1:]) + '}'
                    base = self.type_desc(inner)
                else:
                    base = self.type_desc(ref(v, 'baseType'))
            elif tag == 'DW_TAG_enumeration_type':
                kind = K_ENUM
                el = ref(v, 'elements')
                vals = []
                for e in re.findall(r'!(\d+)', self.md.get(el, '')) if el else []:
                    ev = self.md.get(e, '')
                    vals.append((field(ev, 'name') or '?', int(field(ev, 'value') or 0)))
                count = len(vals)
                fields = self.enum_table(tname, vals)
            elif tag == 'DW_TAG_set_type':
                kind = K_SET
        elif v.startswith('!DISubroutineType'):
            kind = K_PTR
            size = 8
        nm = self.string(name or '?')
        self.globals_out.append(
            '%s = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr %s, i32 %d, i32 %d, ptr %s, i32 %d, i32 %d, ptr %s }, align 8'
            % (tname, nm, kind, size, base, count, low, fields))
        return tname

    def members_text(self, v):
        el = ref(v, 'elements')
        return ' '.join(self.md.get(e, '') for e in re.findall(r'!(\d+)', self.md.get(el, ''))) if el else ''

    def members(self, v):
        el = ref(v, 'elements')
        res = []
        for e in re.findall(r'!(\d+)', self.md.get(el, '')) if el else []:
            mv = self.md.get(e, '')
            tag = field(mv, 'tag')
            if tag == 'DW_TAG_member':
                res.append((field(mv, 'name') or '?', int(field(mv, 'offset') or 0) // 8, ref(mv, 'baseType')))
            elif tag == 'DW_TAG_inheritance':
                res.append(('(inherited)', int(field(mv, 'offset') or 0) // 8, ref(mv, 'baseType')))
        return res

    def field_table(self, tname, mems):
        name = tname + '.f'
        items = ', '.join('{ ptr, i32, i32, ptr, i64 } { ptr %s, i32 %d, i32 0, ptr %s, i64 0 }'
                          % (self.string(m[0]), m[1], self.type_desc(m[2])) for m in mems)
        self.globals_out.append('%s = internal global [%d x { ptr, i32, i32, ptr, i64 }] [%s], align 8'
                                % (name, len(mems), items))
        return name

    def enum_table(self, tname, vals):
        name = tname + '.e'
        items = ', '.join('{ ptr, i32, i32, ptr, i64 } { ptr %s, i32 0, i32 0, ptr null, i64 %d }'
                          % (self.string(a), b) for a, b in vals)
        self.globals_out.append('%s = internal global [%d x { ptr, i32, i32, ptr, i64 }] [%s], align 8'
                                % (name, len(vals), items))
        return name

    def line_of(self, loc):
        v = self.md.get(loc, '')
        if v.startswith('!DILocation'):
            try:
                return int(field(v, 'line') or 0)
            except ValueError:
                return 0
        return 0

    # ---------- globale Variablen des Moduls ----------
    def module_globals(self):
        res = []
        for l in self.lines:
            m = re.match(r'^(@"[^"]+"|@[-\w.$]+) = .*\bglobal\b.*!dbg !(\d+)', l)
            if not m:
                continue
            gve = self.md.get(m.group(2), '')
            gv = ref(gve, 'var') if gve.startswith('!DIGlobalVariableExpression') else m.group(2)
            v = self.md.get(gv, '')
            if not v.startswith('!DIGlobalVariable'):
                continue
            res.append((field(v, 'name') or '?', m.group(1), ref(v, 'type')))
        items = ', '.join('{ ptr, ptr, ptr } { ptr %s, ptr %s, ptr %s }'
                          % (self.string(n), g, self.type_desc(t)) for n, g, t in res)
        self.globals_out.append('@zdbg.globals = internal global [%d x { ptr, ptr, ptr }] [%s], align 8'
                                % (len(res), items))
        self.globals_out.append('@zdbg.module = internal global { i32, ptr } { i32 %d, ptr @zdbg.globals }, align 8'
                                % len(res))

    # ---------- Funktionen ----------
    def run(self):
        self.module_globals()
        out = []
        i = 0
        n = len(self.lines)
        while i < n:
            l = self.lines[i]
            m = re.match(r'^define .*!dbg !(\d+) \{\s*$', l)
            # naked (reine Assembler-Routinen): kein Frame, dort darf nichts eingefügt werden
            if not m or 'DISubprogram' not in self.md.get(m.group(1), '') or re.search(r'\bnaked\b', l):
                out.append(l)
                i += 1
                continue
            j = i + 1
            while j < n and self.lines[j] != '}':
                j += 1
            out.append(l)
            out.extend(self.function(m.group(1), self.lines[i + 1:j]))
            out.append('}')
            i = j + 1
        out.append('')
        out.append('; z/OS-Debugger (zdbg-instrument.py)')
        out.append('declare void @FPC_ZOS_DBG_ENTER(ptr)')
        out.append('declare void @FPC_ZOS_DBG_LINE(ptr, i32 signext)')
        out.extend(self.globals_out)
        return '\n'.join(out) + '\n'

    def function(self, sp, body):
        spv = self.md[sp]
        fname = field(spv, 'name') or '?'
        file_n = ref(spv, 'file')
        fv = self.md.get(file_n, '')
        fname_file = field(fv, 'filename') or ''
        # Variablen aus llvm.dbg.declare (Adresse, DILocalVariable)
        decl = re.compile(r'@llvm\.dbg\.declare\s*\(metadata ptr (%[-\w.$"]+|%"[^"]+"), metadata !(\d+)')
        vars_ = []
        seen = set()
        for l in body:
            dm = decl.search(l)
            if dm and dm.group(2) not in seen:
                seen.add(dm.group(2))
                vars_.append((dm.group(1), dm.group(2)))
        k = self.nfunc
        self.nfunc += 1
        # Beschreibungen
        vitems = []
        for addr, dv in vars_:
            v = self.md.get(dv, '')
            vname = field(v, 'name') or '?'
            flags = 1 if field(v, 'arg') else 0
            vitems.append('{ ptr, ptr, i32, i32 } { ptr %s, ptr %s, i32 %d, i32 0 }'
                          % (self.string(vname), self.type_desc(ref(v, 'type')), flags))
        self.globals_out.append('@zdbg.v.%d = internal global [%d x { ptr, ptr, i32, i32 }] [%s], align 8'
                                % (k, len(vitems), ', '.join(vitems)))
        self.globals_out.append(
            '@zdbg.f.%d = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr %s, ptr %s, i32 %d, i32 0, ptr @zdbg.v.%d, ptr @zdbg.module }, align 8'
            % (k, self.string(fname), self.string(fname_file), len(vitems), k))
        nv = max(len(vars_), 1)
        rtype = '{ ptr, ptr, i32, i32, [%d x ptr] }' % nv

        # Einfügestelle der Initialisierung: nach dem letzten dbg.declare / alloca des Eintrittsblocks
        entry_end = 0
        first_loc = None
        for idx, l in enumerate(body):
            s = l.strip()
            if re.match(r'^[-\w.$"]+:', s) or s.startswith(';'):
                if idx > 0 and re.match(r'^[-\w.$"]+:', s):
                    break
                continue
            if 'alloca' in s or '@llvm.dbg.declare' in s or '@llvm.lifetime.start' in s or \
                    (s.startswith('%') and ' bitcast ' in s):
                entry_end = idx + 1
            locm = re.search(r'!dbg !(\d+)\s*$', s)
            if locm and first_loc is None and self.line_of(locm.group(1)) > 0:
                first_loc = locm.group(1)
        dbg = ', !dbg !%s' % first_loc if first_loc else ''
        init = ['\t%%zdbg.r = alloca %s, align 8' % rtype,
                '\t%%zdbg.fp = getelementptr inbounds %s, ptr %%zdbg.r, i32 0, i32 1' % rtype,
                '\tstore ptr @zdbg.f.%d, ptr %%zdbg.fp, align 8' % k]
        for j, (addr, _) in enumerate(vars_):
            init.append('\t%%zdbg.vp.%d = getelementptr inbounds %s, ptr %%zdbg.r, i32 0, i32 4, i32 %d' % (j, rtype, j))
            init.append('\tstore ptr %s, ptr %%zdbg.vp.%d, align 8' % (addr, j))
        init.append('\tcall void @FPC_ZOS_DBG_ENTER(ptr %%zdbg.r)%s' % dbg)

        out = body[:entry_end] + init
        last_line = -1
        block_start = False
        for l in body[entry_end:]:
            s = l.strip()
            if re.match(r'^[-\w.$"]+:', s):
                out.append(l)
                block_start = True
                last_line = -1
                continue
            locm = re.search(r'!dbg !(\d+)\s*$', s)
            skip = (not s or s.startswith(';') or ' phi ' in s or s.startswith('phi ') or
                    'landingpad' in s or '@llvm.dbg.' in s or '@llvm.lifetime' in s or
                    ' alloca ' in s or 'catchswitch' in s or 'cleanuppad' in s or 'catchpad' in s)
            if locm and not skip:
                ln = self.line_of(locm.group(1))
                if ln > 0 and ln != last_line:
                    out.append('\tcall void @FPC_ZOS_DBG_LINE(ptr %%zdbg.r, i32 signext %d), !dbg !%s' % (ln, locm.group(1)))
                    last_line = ln
            out.append(l)
            if block_start and not (' phi ' in s or 'landingpad' in s):
                block_start = False
        return out


def main():
    text = open(sys.argv[1], encoding='latin-1').read()
    sys.stdout.write(Instrumenter(text).run())


if __name__ == '__main__':
    main()
