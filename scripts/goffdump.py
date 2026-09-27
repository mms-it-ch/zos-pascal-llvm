#!/usr/bin/env python3
"""Minimaler GOFF-Dumper (llvm-readobj kann GOFF nicht lesen).

Aufbau: 80-Byte-Records, Byte 0 = 0x03, Byte 1 obere 4 Bit = Recordtyp
(0 ESD, 1 TXT, 2 RLD, 4 END, F HDR), untere Bits = Fortsetzungsflags.
Aufruf: goffdump.py datei.o [...]   Exit-Code 1 bei Formatfehlern.
"""
import sys

REC_TYPES = {0x0: "ESD", 0x1: "TXT", 0x2: "RLD", 0x4: "END", 0xF: "HDR"}
ESD_TYPES = {0: "SD", 1: "ED", 2: "LD", 3: "PR", 4: "ER"}


def ebcdic(b):
    # cp037 statt IBM-1047: für Symbolnamen identisch bis auf wenige Sonderzeichen
    return b.decode("cp037", errors="replace")


def records(data):
    """Liefert (Index, Typ, Nutzdaten) und fügt Fortsetzungsrecords zusammen."""
    cur = None
    for i in range(0, len(data), 80):
        r = data[i:i + 80]
        if r[0] != 0x03:
            raise ValueError(f"Record {i // 80}: Byte 0 ist 0x{r[0]:02x}, erwartet 0x03")
        rtype, continued, is_cont = r[1] >> 4, bool(r[1] & 0x01), bool(r[1] & 0x02)
        if is_cont:
            if cur is None:
                raise ValueError(f"Record {i // 80}: Fortsetzung ohne Vorgänger")
            cur[2] += r[3:]
        else:
            if cur is not None:
                yield tuple(cur)
            cur = [i // 80, rtype, bytearray(r)]
        if not continued:
            yield tuple(cur)
            cur = None
    if cur is not None:
        raise ValueError("Letzter Record kündigt Fortsetzung an, die fehlt")


RLD_REFTYPES = {0: "A", 1: "Q", 2: "L", 6: "RI", 7: "R", 9: "LD"}


def dump_rld(data, names):
    """RLD-Items: 6 Flagbytes, 2 reserviert, dann R-/P-ESDID und Offset,
    sofern nicht per 'same'-Flag vom Vorgänger übernommen."""
    pos, r_id, p_id, off = 0, None, None, None
    while pos + 8 <= len(data):
        f = data[pos:pos + 6]
        pos += 8
        if not f[0] & 0x80:
            r_id = int.from_bytes(data[pos:pos + 4], "big"); pos += 4
        if not f[0] & 0x40:
            p_id = int.from_bytes(data[pos:pos + 4], "big"); pos += 4
        if not f[0] & 0x20:
            n = 8 if f[0] & 0x02 else 4
            off = int.from_bytes(data[pos:pos + n], "big"); pos += n
        rtype = RLD_REFTYPES.get(f[1] >> 4, f"?{f[1] >> 4}")
        print(f"  RLD {rtype:3}-Con len={f[4]} "
              f"{'store' if f[2] & 0x01 else 'fetch'} "
              f"R=#{r_id} ({names.get(r_id, '?')}) -> P=#{p_id} ({names.get(p_id, '?')})+{off}")


def dump(path):
    data = open(path, "rb").read()
    if len(data) % 80:
        raise ValueError(f"Länge {len(data)} ist kein Vielfaches von 80 (Textkonvertierung beim Transfer?)")
    counts, names = {}, {}
    for idx, rtype, r in records(data):
        name = REC_TYPES.get(rtype, f"?{rtype:X}")
        counts[name] = counts.get(name, 0) + 1
        if rtype == 0x0:
            esdid = int.from_bytes(r[4:8], "big")
            parent = int.from_bytes(r[8:12], "big")
            nlen = int.from_bytes(r[70:72], "big")
            sym = ebcdic(bytes(r[72:72 + nlen]))
            names[esdid] = sym
            print(f"  ESD #{esdid:<3} {ESD_TYPES.get(r[3], '?'):2} parent={parent:<3} {sym}")
            if VERBOSE:
                # Bytes 12-69: Offset, Länge, ADA-ESDID, Attribute (roh)
                print(f"        off={int.from_bytes(r[16:20], 'big')} "
                      f"len={int.from_bytes(r[24:28], 'big')} "
                      f"ada={int.from_bytes(r[44:48], 'big')} "
                      f"attr={bytes(r[60:70]).hex()} raw12-60={bytes(r[12:60]).hex()}")
        elif rtype == 0x1:
            esdid = int.from_bytes(r[4:8], "big")
            off = int.from_bytes(r[12:16], "big")
            dlen = int.from_bytes(r[22:24], "big")
            print(f"  TXT -> #{esdid:<3} ({names.get(esdid, '?')}) offset={off} len={dlen}")
        elif rtype == 0x2:
            dump_rld(bytes(r[6:6 + int.from_bytes(r[4:6], "big")]), names)
    if list(counts)[:1] != ["HDR"] or list(counts)[-1:] != ["END"]:
        raise ValueError("Objekt beginnt nicht mit HDR oder endet nicht mit END")
    print("  Records: " + ", ".join(f"{k}={v}" for k, v in counts.items()))


VERBOSE = False


def main():
    global VERBOSE
    rc = 0
    args = sys.argv[1:]
    if args[:1] == ["-v"]:
        VERBOSE, args = True, args[1:]
    for path in args:
        print(path)
        try:
            dump(path)
        except (ValueError, IndexError) as e:
            print(f"  FEHLER: {e}")
            rc = 1
    return rc


if __name__ == "__main__":
    sys.exit(main())
