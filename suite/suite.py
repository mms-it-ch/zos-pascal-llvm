#!/usr/bin/env python3
"""suite.py: Testsuite aus freien Pascal-Quellen, lokal (x86_64-linux) und auf z/OS.

  suite.py build  [--target local|zos] [projekt ...]
  suite.py run    [--target local|zos] [projekt ...]
  suite.py list

Quellen: ~/src/pascal-suite (flache Klone, siehe suite/README.md). Ergebnisse:
~/build/suite/<target>/<projekt>/ (Programm, Protokolle) und suite/results-<target>.txt.

Projekte (PROJECTS unten): FPCUnit-Konsolenläufer der Bibliotheken (Suchpfade und Optionen
aus .lpi/.lpk) und einzelne Programme (Benchmarks Game) mit erwarteter Ausgabe.

z/OS: Programm mit zfpc binden (USS-Programm in ZOS_DIR), Testdaten per tar+sftp nach
ZOS_DIR/suite/<projekt>, Lauf per ssh; vor und nach jedem Lauf werden die Dump-Datasets
der User-ID gezählt - bei einem neuen Dump bricht die Suite ab.
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

HOME = os.path.expanduser('~')
SRC = os.environ.get('SUITE_SRC', f'{HOME}/src/pascal-suite')
OUT = os.environ.get('SUITE_OUT', f'{HOME}/build/suite')
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HOSTFPC = os.environ.get('HOSTFPC', f'{HOME}/opt/fpc-main')

# name, Art, Projektdatei (lpr/pas), Datenverzeichnis (relativ zu SRC) bzw. Programmargumente
PROJECTS = [
    ('hashlib', 'fpcunit', 'HashLib4Pascal/HashLib.Tests/FreePascal.Tests/HashLibConsole.lpr',
     'HashLib4Pascal/HashLib.Tests/Data'),
    ('simplebaselib', 'fpcunit', 'SimpleBaseLib4Pascal/SimpleBaseLib.Tests/FreePascal.Tests/SimpleBaseLibConsole.lpr',
     'SimpleBaseLib4Pascal/SimpleBaseLib.Tests/Data'),
    ('cryptolib', 'fpcunit', 'CryptoLib4Pascal/CryptoLib.Tests/FreePascal.Tests/CryptoLibConsole.lpr',
     'CryptoLib4Pascal/CryptoLib.Tests/Data'),
]
# Benchmarks Game: alle *.fpascal aus SRC/bench/src/<aufgabe>/, Argument je Aufgabe,
# erwartete Ausgabe SRC/bench/<aufgabe>-output.txt, Eingabe SRC/bench/<aufgabe>-input.txt
BENCH_ARGS = {'nbody': '1000', 'fannkuchredux': '7', 'spectralnorm': '100', 'binarytrees': '10',
              'mandelbrot': '200', 'fasta': '1000', 'knucleotide': '', 'revcomp': '',
              'pidigits': '30', 'regexredux': ''}


# auf z/OS nicht lauffähig, mit Grund
ZOS_SKIP = {
    'pidigits': 'nicht portabel: array[0..1] of dword absolute int64 setzt Little-Endian voraus '
                '(auf z/OS Endlosschleife)',
    'pidigits-2': 'braucht libgmp (auf z/OS nicht vorhanden)',
    'pidigits-3': 'braucht libgmp (auf z/OS nicht vorhanden)',
    'regexredux': 'braucht PCRE (nicht vorhanden)',
}


def bench_list():
    res = []
    root = f'{SRC}/bench/src'
    if not os.path.isdir(root):
        return res
    for task in sorted(os.listdir(root)):
        for f in sorted(os.listdir(f'{root}/{task}')):
            if not f.endswith('.fpascal'):
                continue
            m = re.match(r'[a-z]+\.fpascal(?:-(\d+))?', f)
            name = task + (('-' + m.group(1)) if m and m.group(1) else '')
            inp = f'{SRC}/bench/{task}-input.txt'
            res.append((name, f'{root}/{task}/{f}', BENCH_ARGS.get(task, ''),
                        f'{SRC}/bench/{task}-output.txt', inp if os.path.exists(inp) else None))
    return res


def sh(cmd, cwd=None, timeout=None, env=None):
    e = dict(os.environ)
    if env:
        e.update(env)
    try:
        p = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True,
                           encoding='latin-1', timeout=timeout, env=e)
    except subprocess.TimeoutExpired as t:
        out = t.stdout or ''
        if isinstance(out, bytes):
            out = out.decode('latin-1')
        return 124, out + '\n@@ZEITUEBERSCHREITUNG\n'
    return p.returncode, p.stdout + p.stderr


# ---------- Lazarus-Projekte ----------
def lazpaths(xmlfile):
    """-Fu/-Fi/-d und Paketabhängigkeiten aus einer .lpi/.lpk."""
    base = os.path.dirname(xmlfile)
    try:
        root = ET.parse(xmlfile).getroot()
    except ET.ParseError:
        return [], [], [], []
    units, incs, opts, deps = [], [], [], []

    def paths(v):
        res = []
        for p in (v or '').split(';'):
            p = p.strip().replace('\\', '/')
            if not p or '$(' in p:
                continue
            q = os.path.normpath(os.path.join(base, p))
            if os.path.isdir(q):
                res.append(q)
        return res

    for so in root.iter('SearchPaths'):
        for el in so:
            if el.tag == 'OtherUnitFiles':
                units += paths(el.get('Value'))
            elif el.tag == 'IncludeFiles':
                incs += paths(el.get('Value'))
    for sm in root.iter('SyntaxMode'):
        m = {'delphi': '-Mdelphi', 'objfpc': '-Mobjfpc', 'fpc': '-Mfpc', 'tp': '-Mtp',
             'macpas': '-Mmacpas', 'iso': '-Miso', 'delphiunicode': '-Mdelphiunicode'}.get(
            (sm.get('Value') or '').lower())
        if m and m not in opts:
            opts.append(m)
    for co in root.iter('CustomOptions'):
        v = co.get('Value') or ''
        opts += [o for o in v.replace('&#xA;', ' ').split() if o.startswith('-d')]
    for rp in list(root.iter('RequiredPackages')) + list(root.iter('RequiredPkgs')):
        for item in rp:
            pn = item.find('PackageName')
            if pn is not None and pn.get('Value'):
                deps.append(pn.get('Value'))
    # .lpk: Dateien mit Pfaden
    for f in root.iter('Filename'):
        v = (f.get('Value') or '').replace('\\', '/')
        if v.lower().endswith(('.pas', '.pp')):
            d = os.path.normpath(os.path.join(base, os.path.dirname(v)))
            if os.path.isdir(d) and d not in units:
                units.append(d)
    return units, incs, opts, deps


def find_lpk(name):
    for dirpath, _, files in os.walk(SRC):
        if '.git' in dirpath:
            continue
        for f in files:
            if f.lower() == name.lower() + '.lpk':
                return os.path.join(dirpath, f)
    return None


def project_options(lpr):
    lpi = os.path.splitext(lpr)[0] + '.lpi'
    units, incs, opts, deps = lazpaths(lpi) if os.path.exists(lpi) else ([], [], [], [])
    units.insert(0, os.path.dirname(lpr))
    seen = set()
    while deps:
        d = deps.pop()
        if d in seen or d in ('FCL', 'fpcunittestrunner', 'LCL', 'LazUtils', 'FPCUnitConsoleRunner'):
            continue
        seen.add(d)
        lpk = find_lpk(d)
        if not lpk:
            continue
        u, i, o, dd = lazpaths(lpk)
        units += u
        incs += i
        opts += o
        deps += dd
        # alle Unterverzeichnisse der Paketquellen (Include-Dateien)
        top = os.path.dirname(lpk)
        for p in u:
            for dirpath, _, files in os.walk(p):
                if any(f.lower().endswith('.inc') for f in files):
                    incs.append(dirpath)
    for p in list(units):
        for dirpath, _, files in os.walk(p):
            if any(f.lower().endswith('.inc') for f in files):
                incs.append(dirpath)
    uniq = lambda l: list(dict.fromkeys(l))
    # Includes mit Pfaden relativ zur Unit ({$I ../../Include/...} in einer Include-Datei):
    # die Unit-Verzeichnisse auch als Include-Pfade
    incs += units
    # nur ein Syntaxmodus (der des Projekts, sonst der erste)
    modes = [o for o in opts if o.startswith('-M')]
    # Lazarus-Voreinstellung, wenn das Projekt keinen Modus setzt: -MObjFPC -Scghi
    opts = [o for o in opts if not o.startswith('-M')] + (modes[:1] or ['-Mobjfpc']) + ['-Scghi']
    return uniq(units), uniq(incs), uniq(opts)


# ---------- Übersetzen ----------
def compiler_cmd(target, outdir):
    if target == 'local':
        # Referenz ohne Optimierung (CryptoLib: -O2 des x86_64-FPC ergibt 53 Zugriffsverletzungen)
        return (f'{HOSTFPC}/bin/ppcx64 {os.environ.get("SUITE_LOCAL_OPT", "-O-")} -g -gl -FE{outdir} -FU{outdir}/units '
                f'-Fu{HOSTFPC}/units/rtl -Fu{HOSTFPC}/units/rtlobjpas -Fu{HOSTFPC}/units/packages')
    return f'{REPO}/scripts/zfpc {os.environ.get("SUITE_ZOS_OPT", "-O2")} -gl -FU{outdir}/units'


def build(target, name, lpr, extra=''):
    outdir = f'{OUT}/{target}/{name}'
    # FPC übersetzt Units nicht neu, wenn sich nur die Optionen geändert haben (-O2 -> -O-)
    shutil.rmtree(f'{outdir}/units', ignore_errors=True)
    os.makedirs(f'{outdir}/units', exist_ok=True)
    units, incs, opts = project_options(lpr) if lpr.endswith('.lpr') else ([os.path.dirname(lpr)], [], [])
    # Quellen, deren Dateiname anders geschrieben ist als in uses/{$I} (unter Windows egal):
    # FPC sucht unter Linux auch den kleingeschriebenen Namen -> Verzeichnis mit Verknüpfungen
    lc = f'{outdir}/lc'
    shutil.rmtree(lc, ignore_errors=True)
    os.makedirs(lc)
    for d in list(dict.fromkeys(units + incs)):
        for f in os.listdir(d):
            if f.lower().endswith(('.pas', '.pp', '.inc')) and f != f.lower():
                link = os.path.join(lc, f.lower())
                if not os.path.exists(link):
                    os.symlink(os.path.join(d, f), link)
    args = ' '.join([f'-Fu{u}' for u in units] + [f'-Fi{i}' for i in incs] + [f'-Fu{lc}', f'-Fi{lc}'] + opts)
    src = lpr
    if not lpr.endswith(('.lpr', '.pas', '.pp')):
        # Benchmarks Game: .fpascal -> .pas
        src = f'{outdir}/{name.replace("-", "_")}.pas'
        shutil.copy(lpr, src)
    if not lpr.endswith(('.lpr', '.pas', '.pp')):
        extra += ' -Sc -Sh'  # wie beim Benchmarks Game
        if target == 'local':
            extra += f' -Fl{HOME}/opt/linklibs'  # libgmp.so (pidigits)
    cmd = f'{compiler_cmd(target, outdir)} -FE{outdir} {extra} {args} {src}'
    t = time.time()
    # zfpc bindet ins aktuelle Verzeichnis (Startskript) -> im Ausgabeverzeichnis arbeiten
    rc, out = sh(cmd, cwd=outdir, timeout=7200)
    open(f'{outdir}/build.log', 'w').write(cmd + '\n' + out)
    errs = [l for l in out.splitlines() if re.search(r'\b(Error|Fatal):', l)]
    return rc, time.time() - t, errs[:3]


# ---------- z/OS ----------
def zos_env():
    rc, out = sh(f'WH=$(wslpath -u "$(cmd.exe /c \'echo %USERPROFILE%\' 2>/dev/null | tr -d \'\\r\')" | '
                 f'sed \'s|^/mnt/\\([a-z]\\)/|/\\1/|\'); HOME=$WH . {REPO}/.zos.env; '
                 'printf "%s\\n" "$ZOS_DIR"')
    return out.strip().splitlines()[-1]


def zsh(cmd, timeout=3600):
    return sh(f'{REPO}/scripts/zos-sh {shq(cmd)}', timeout=timeout)


def shq(s):
    return "'" + s.replace("'", "'\\''") + "'"


def dump_count():
    rc, out = zsh('tsocmd "LISTCAT LEVEL($(id -un))" 2>/dev/null | grep -c "\\.D[0-9][0-9]*\\.T"', 300)
    try:
        return int(out.strip().splitlines()[-1])
    except (ValueError, IndexError):
        return -1


def upload_dir(local, remote, exclude_bigger_than_mb=4):
    """Verzeichnis als tar hochladen (Windows-Temp, sftp.exe), große Dateien auslassen."""
    if not os.path.isdir(local):
        # Projekt ohne Testdaten: nur das Arbeitsverzeichnis anlegen
        zsh(f'mkdir -p {remote}')
        return []
    wtmp = sh("wslpath -u \"$(cmd.exe /c 'echo %TEMP%' 2>/dev/null | tr -d '\\r')\"")[1].strip()
    tar = f'{wtmp}/suite-{os.getpid()}.tar'
    left_out = []
    with open(f'{wtmp}/suite-excl-{os.getpid()}', 'w') as ex:
        for dirpath, _, files in os.walk(local):
            for f in files:
                p = os.path.join(dirpath, f)
                if os.path.getsize(p) > exclude_bigger_than_mb * 1024 * 1024:
                    rel = os.path.relpath(p, local)
                    ex.write('./' + rel + '\n')
                    left_out.append(rel)
    sh(f'cd {shq(local)} && tar --format=ustar -X {wtmp}/suite-excl-{os.getpid()} -cf {tar} .')
    zsh(f'rm -rf {remote} && mkdir -p {remote}')
    sh(f'{REPO}/scripts/zos-put {shq(tar)} {remote}/data.tar')
    zsh(f'cd {remote} && pax -rf data.tar && rm -f data.tar')
    os.remove(tar)
    return left_out


# ---------- Ausführen ----------
FPCUNIT = re.compile(r'Number of run tests:\s*(\d+)\s*Number of errors:\s*(\d+)\s*Number of failures:\s*(\d+)', re.S)


def parse_fpcunit(out):
    m = FPCUNIT.search(out)
    if not m:
        return None
    return int(m.group(1)), int(m.group(2)), int(m.group(3))


def exe_name(src):
    return os.path.splitext(os.path.basename(src))[0].replace('.fpascal', '')


def run_local(name, exe_base, workdir, args='', stdin=None, timeout=3600):
    exe = f'{OUT}/local/{name}/{exe_base}'
    inp = f' < {shq(stdin)}' if stdin else ''
    t = time.time()
    rc, out = sh(f'{exe} {args}{inp}', cwd=workdir, timeout=timeout)
    return rc, out, time.time() - t


def run_zos(exe_base, rdir, args='', stdin=None, cpu=3600):
    zdir = zos_env()
    inp = f' < {stdin}' if stdin else ''
    cmd = (f'mkdir -p {rdir} && cd {rdir} && ulimit -t {cpu}; export LIBPATH={zdir}:{zdir}/lib:$LIBPATH; '
           f'{zdir}/{exe_base} {args}{inp} > {rdir}/.out 2>&1; rc=$?; '
           f'iconv -f ISO8859-1 -t IBM-1047 {rdir}/.out; echo; echo "@@RC $rc"')
    t = time.time()
    rc, out = zsh(cmd, timeout=cpu + 600)
    m = re.search(r'@@RC (\d+)', out)
    return (int(m.group(1)) if m else -1), out, time.time() - t


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('action', choices=['build', 'run', 'list'])
    ap.add_argument('--target', choices=['local', 'zos'], default='local')
    ap.add_argument('names', nargs='*')
    a = ap.parse_intermixed_args()
    BENCH = bench_list()
    names = a.names or [p[0] for p in PROJECTS] + [b[0] for b in BENCH]
    if a.names == ['bench']:
        names = [b[0] for b in BENCH]
    if a.action == 'list':
        for p in PROJECTS:
            print(p[0], p[2])
        for b in bench_list():
            print(b[0], b[1])
        return 0

    results = []
    zdir = zos_env() if a.target == 'zos' else ''
    dumps0 = dump_count() if a.target == 'zos' and a.action == 'run' else 0
    for name, kind, lpr, data in PROJECTS:
        if name not in names:
            continue
        if a.action == 'build':
            rc, secs, errs = build(a.target, name, f'{SRC}/{lpr}')
            results.append(f'{name}: build {"ok" if rc == 0 else "FEHLER"} ({secs:.0f} s) {" | ".join(errs)}')
            print(results[-1], flush=True)
            continue
        wd = os.path.dirname(f'{SRC}/{data}')  # Tests-Projektverzeichnis (enthält Data)
        if a.target == 'local':
            rc, out, secs = run_local(name, exe_name(lpr), wd, '-a --format=plain')
            left = []
        else:
            rdir = f'{zdir}/suite/{name}/{os.path.basename(wd)}'
            left = upload_dir(f'{SRC}/{data}', f'{rdir}/Data')
            rc, out, secs = run_zos(exe_name(lpr), rdir, '-a --format=plain')
        open(f'{OUT}/{a.target}/{name}/run.log', 'w').write(out)
        r = parse_fpcunit(out)
        s = f'{name}: rc={rc} ({secs:.0f} s) '
        s += f'Tests {r[0]}, Fehler {r[1]}, Abweichungen {r[2]}' if r else 'keine FPCUnit-Zusammenfassung'
        if left:
            s += f' (ohne {len(left)} große Datendateien)'
        results.append(s)
        print(s, flush=True)
        if a.target == 'zos':
            d = dump_count()
            if d > dumps0 >= 0:
                print(f'ABBRUCH: neuer Dump nach {name} ({dumps0} -> {d})', flush=True)
                results.append(f'ABBRUCH nach {name}: neuer Dump')
                break
    for name, src, arg, expected, stdin in BENCH:
        if name not in names:
            continue
        srcp = src
        if a.action == 'build':
            rc, secs, errs = build(a.target, name, srcp)
            results.append(f'{name}: build {"ok" if rc == 0 else "FEHLER"} ({secs:.0f} s) {" | ".join(errs)}')
            print(results[-1], flush=True)
            continue
        inp = stdin
        if a.target == 'zos' and name in ZOS_SKIP:
            results.append(f'{name}: übersprungen ({ZOS_SKIP[name]})')
            print(results[-1], flush=True)
            continue
        if a.target == 'local':
            rc, out, secs = run_local(name, name.replace('-', '_'), f'{OUT}/local/{name}', arg, inp)
        else:
            rdir = f'{zdir}/suite/{name}'
            rin = None
            if inp:
                zsh(f'mkdir -p {rdir}')
                sh(f'{REPO}/scripts/zos-put {shq(inp)} {rdir}/input.txt')
                rin = f'{rdir}/input.txt'
            rc, out, secs = run_zos(name.replace('-', '_'), rdir, arg, rin, cpu=120)
            out = re.sub(r'\n?@@RC \d+\s*$', '', out)
        open(f'{OUT}/{a.target}/{name}/run.log', 'w').write(out)
        ok = ''
        if expected and os.path.exists(expected):
            want = open(expected, encoding='latin-1').read()
            ok = 'Ausgabe gleich' if out.rstrip('\n') == want.rstrip('\n') else 'AUSGABE ANDERS'
        results.append(f'{name}: rc={rc} ({secs:.1f} s) {ok}')
        print(results[-1], flush=True)
        if a.target == 'zos':
            d = dump_count()
            if d > dumps0 >= 0:
                print(f'ABBRUCH: neuer Dump nach {name}', flush=True)
                break
    if a.action == 'run':
        with open(f'{REPO}/suite/results-{a.target}.txt', 'w') as f:
            f.write(time.strftime('%Y-%m-%d %H:%M') + '\n' + '\n'.join(results) + '\n')
    return 0


if __name__ == '__main__':
    sys.exit(main())
