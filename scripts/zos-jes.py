#!/usr/bin/env python3
"""zos-jes.py: JCL über die JES-Schnittstelle des z/OS-FTP-Servers einreichen.

  zos-jes.py JOB.jcl              einreichen, auf das Ende warten, Spool holen, RC melden
  zos-jes.py -                    JCL von stdin (z. B. zos-batch.sh -n MEMBER | zos-jes.py -)
  zos-jes.py --status JOBnnnnn    Status eines Jobs
  zos-jes.py --output JOBnnnnn    Spool eines Jobs holen
  zos-jes.py --list               eigene Jobs

Optionen: --nowait (nur einreichen), --wait SEK (Standard 300), --out DIR (Spool-Dateien,
Standard ./jes-output), --purge (Job nach dem Holen aus dem Spool löschen), --tail N (nur die
letzten N Zeilen des Spools zeigen; 0 = nichts, Standard alles).

Zugang: Host aus ZOS_FTP_HOST oder dem Hostteil von ZOS_HOST (.zos.env); Benutzer und Passwort
aus ~/.netrc (Eintrag "machine <host> login <user> password <pw>", chmod 600) - das Passwort
steht nie im Repo und nie auf der Kommandozeile. ZOS_FTP_TLS=1: FTPS (AUTH TLS).

JES: Der Spool lässt sich per FTP nur holen, wenn die Ausgabe in einer gehaltenen Klasse
liegt (MSGCLASS). Die JOB-Karte soll REGION=0M,LINES=500000 haben (Warnung sonst).
Returncode des Skripts: RC des Jobs (höchstens 255); JCL-Fehler/ABEND: 12; Zeitüberschreitung: 124.
"""
import argparse
import ftplib
import io
import netrc
import os
import re
import subprocess
import sys
import time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load_env():
    """ZOS_* aus .zos.env (Shell-Syntax, nur einfache Zuweisungen)."""
    env = {}
    path = os.environ.get('ZOS_ENV', os.path.join(REPO, '.zos.env'))
    if os.path.exists(path):
        for line in open(path, encoding='utf-8', errors='replace'):
            m = re.match(r'\s*(?:export\s+)?(ZOS_[A-Z_]+)=(.*)$', line)
            if m:
                env[m.group(1)] = m.group(2).strip().strip('"').strip("'")
    env.update({k: v for k, v in os.environ.items() if k.startswith('ZOS_')})
    return env


def connect(env):
    host = env.get('ZOS_FTP_HOST') or env.get('ZOS_HOST', '').split('@')[-1]
    if not host:
        sys.exit('zos-jes: kein Host (ZOS_FTP_HOST oder ZOS_HOST in .zos.env)')
    try:
        auth = netrc.netrc().authenticators(host)
    except (FileNotFoundError, netrc.NetrcParseError) as e:
        sys.exit(f'zos-jes: ~/.netrc nicht lesbar ({e})')
    if not auth:
        sys.exit('zos-jes: kein Eintrag für den Host in ~/.netrc')
    user, _, password = auth
    if env.get('ZOS_FTP_TLS') == '1':
        ftp = ftplib.FTP_TLS(host, timeout=60)
        ftp.login(user, password)
        ftp.prot_p()
    else:
        ftp = ftplib.FTP(host, timeout=60)
        ftp.login(user, password)
    ftp.sendcmd('SITE FILETYPE=JES')
    return ftp, user.upper()


def check_jobcard(jcl):
    """Die JOB-Anweisung (mit Fortsetzungszeilen) muss REGION=0M,LINES=500000 enthalten."""
    lines = jcl.upper().splitlines()
    start = next((i for i, l in enumerate(lines) if re.match(r'//\S*\s+JOB\b', l)), None)
    if start is None:
        print('zos-jes: WARNUNG: keine JOB-Anweisung gefunden', file=sys.stderr)
        return
    card = [lines[start][:71]]
    i = start + 1
    while card[-1].rstrip().endswith(',') and i < len(lines) and lines[i].startswith('// '):
        card.append(lines[i][:71])
        i += 1
    text = ' '.join(card)
    if 'REGION=0M' not in text or 'LINES=500000' not in text:
        print('zos-jes: WARNUNG: JOB-Karte ohne REGION=0M,LINES=500000', file=sys.stderr)


def submit(ftp, jcl):
    resp = ftp.storlines('STOR JOB.JCL', io.BytesIO(jcl.encode('latin-1')))
    m = re.search(r'\b(J(?:OB)?\d{5,7})\b', resp)
    if not m:
        sys.exit(f'zos-jes: keine Job-ID in der Antwort: {resp}')
    return m.group(1)


def status(ftp, jobid):
    """(Status, RC-Text) aus der DIR-Zeile (JESINTERFACELEVEL=2)."""
    ftp.sendcmd('SITE JESJOBNAME=* JESOWNER=*')
    lines = []
    try:
        ftp.retrlines(f'LIST {jobid}', lines.append)
    except ftplib.error_perm as e:
        return 'UNKNOWN', str(e)
    for line in lines:
        if jobid in line:
            words = line.split()
            st = next((w for w in words if w in ('INPUT', 'HELD', 'ACTIVE', 'OUTPUT')), '?')
            rc = ''
            m = re.search(r'(RC=\d+|ABEND=?\s*\S+|\(JCL error\)|JCL error|CC=\d+)', line, re.I)
            if m:
                rc = m.group(1)
            return st, rc
    return 'UNKNOWN', ''


def rc_of(rctext):
    m = re.match(r'(?:RC|CC)=(\d+)', rctext or '')
    if m:
        return min(int(m.group(1)), 255)
    return 12 if rctext else 0


def fetch(ftp, jobid, outdir, tail):
    os.makedirs(outdir, exist_ok=True)
    lines = []
    ftp.retrlines(f'RETR {jobid}.X', lines.append)
    path = os.path.join(outdir, f'{jobid}.txt')
    with open(path, 'w', encoding='latin-1') as f:
        f.write('\n'.join(lines) + '\n')
    show = lines if tail is None else lines[-tail:] if tail > 0 else []
    for line in show:
        print(line)
    print(f'zos-jes: Spool in {path} ({len(lines)} Zeilen)', file=sys.stderr)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('jcl', nargs='?')
    ap.add_argument('--status')
    ap.add_argument('--output')
    ap.add_argument('--list', action='store_true')
    ap.add_argument('--nowait', action='store_true')
    ap.add_argument('--wait', type=int, default=300)
    ap.add_argument('--out', default='jes-output')
    ap.add_argument('--purge', action='store_true')
    ap.add_argument('--tail', type=int)
    a = ap.parse_args()
    env = load_env()
    ftp, user = connect(env)
    try:
        if a.list:
            ftp.sendcmd(f'SITE JESJOBNAME=* JESOWNER={user}')
            ftp.retrlines('LIST')
            return 0
        if a.status:
            st, rc = status(ftp, a.status.upper())
            print(st, rc)
            return 0
        if a.output:
            fetch(ftp, a.output.upper(), a.out, a.tail)
            return 0
        if not a.jcl:
            ap.error('JCL-Datei, - (stdin), --status, --output oder --list')
        jcl = sys.stdin.read() if a.jcl == '-' else open(a.jcl, encoding='utf-8').read()
        check_jobcard(jcl)
        jobid = submit(ftp, jcl)
        print(f'zos-jes: eingereicht als {jobid}', file=sys.stderr)
        if a.nowait:
            return 0
        end = time.time() + a.wait
        st, rc = status(ftp, jobid)
        while st != 'OUTPUT' and time.time() < end:
            time.sleep(3)
            st, rc = status(ftp, jobid)
        if st != 'OUTPUT':
            print(f'zos-jes: {jobid} nach {a.wait} s noch {st}', file=sys.stderr)
            return 124
        fetch(ftp, jobid, a.out, a.tail)
        if a.purge:
            ftp.delete(jobid)
        print(f'zos-jes: {jobid} beendet: {rc or "RC unbekannt"}', file=sys.stderr)
        return rc_of(rc)
    finally:
        try:
            ftp.quit()
        except Exception:
            pass


if __name__ == '__main__':
    sys.exit(main())
