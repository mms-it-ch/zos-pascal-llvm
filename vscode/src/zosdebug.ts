// Debug-Adapter für Pascal auf z/OS (target "zos"). Spricht mit dem Debug-Agenten im
// Programm (runtime/zosdbg.c) über die ssh-Sitzung: Zeilen "@@Z ..." vom Agenten,
// Befehle zeilenweise auf stdin. Portweiterleitung ist auf z/OS gesperrt, deshalb stdio.
import * as cp from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';
import { Builder } from './build';
import { PascalLaunch } from './debug';
import { runBash, shPath, shq, toolchainRoot } from './wsl';

interface DapMessage {
  seq: number;
  type: string;
  command?: string;
  arguments?: any;
  [k: string]: any;
}

interface ZosEnv { host: string; key: string; dir: string; }

/** .zos.env wie die Skripte auswerten (HOME = Windows-Profil); Werte nicht protokollieren. */
async function readZosEnv(root: string): Promise<ZosEnv> {
  const env = `${shPath(root)}/.zos.env`;
  const res = await runBash(
    `WH=$(wslpath -u "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\\r')" | sed 's|^/mnt/\\([a-z]\\)/|/\\1/|'); ` +
    `HOME=$WH . ${env} && printf '%s\\n' "$ZOS_HOST" "$ZOS_KEY" "$ZOS_DIR"`);
  const [host, key, dir] = res.stdout.split('\n');
  if (res.code !== 0 || !host || !dir) {
    throw new Error('.zos.env nicht lesbar (ZOS_HOST, ZOS_KEY, ZOS_DIR)');
  }
  // msys-Pfad /c/... -> C:\...
  const m = /^\/([a-z])\/(.*)$/.exec(key ?? '');
  return { host, key: m ? `${m[1].toUpperCase()}:\\${m[2].replace(/\//g, '\\')}` : (key ?? ''), dir };
}

export class ZosDebugSession implements vscode.DebugAdapter {
  private readonly emitter = new vscode.EventEmitter<vscode.DebugProtocolMessage>();
  readonly onDidSendMessage = this.emitter.event;
  private seq = 1;
  private proc: cp.ChildProcess | undefined;
  private buf = '';
  private ready = false;
  private configDone = false;
  private started = false;
  private stopAtEntry = false;
  private readonly bps = new Map<string, number[]>(); // Basisname -> Zeilen
  private reqId = 1;
  private readonly pending = new Map<number, (v: any) => void>();
  private readonly varRefs: string[] = [''];
  private programDir = '';
  private readonly sourceCache = new Map<string, string | undefined>();
  private exitCode: number | undefined;
  private ended = false;

  constructor(private readonly builder: Builder, private readonly out: vscode.OutputChannel) {}

  dispose(): void {
    this.kill();
  }

  // ---------- DAP ----------
  private send(msg: Record<string, unknown>): void {
    this.emitter.fire({ seq: this.seq++, ...msg } as vscode.DebugProtocolMessage);
  }
  private respond(req: DapMessage, body: unknown = {}, success = true, message?: string): void {
    this.send({ type: 'response', request_seq: req.seq, command: req.command, success, body, message });
  }
  private event(event: string, body: unknown = {}): void {
    this.send({ type: 'event', event, body });
  }
  private output(text: string, category = 'stdout'): void {
    this.event('output', { category, output: text });
  }

  handleMessage(m: vscode.DebugProtocolMessage): void {
    const req = m as DapMessage;
    if (req.type !== 'request') {
      return;
    }
    this.dispatch(req).catch((e) => this.respond(req, {}, false, e instanceof Error ? e.message : String(e)));
  }

  private async dispatch(req: DapMessage): Promise<void> {
    const a = req.arguments ?? {};
    switch (req.command) {
      case 'initialize':
        this.respond(req, {
          supportsConfigurationDoneRequest: true,
          supportsTerminateRequest: true,
          supportsEvaluateForHovers: true,
        });
        this.event('initialized');
        return;
      case 'launch':
        await this.launch(req, a as PascalLaunch);
        return;
      case 'setBreakpoints': {
        const file = path.basename(a.source?.path ?? '');
        const lines: number[] = (a.breakpoints ?? []).map((b: any) => b.line);
        this.bps.set(file, lines);
        if (this.ready) {
          this.write(`B ${file} ${lines.join(' ')}`);
        }
        this.respond(req, { breakpoints: lines.map((l) => ({ verified: true, line: l })) });
        return;
      }
      case 'configurationDone':
        this.configDone = true;
        this.respond(req);
        this.maybeStart();
        return;
      case 'threads':
        this.respond(req, { threads: [{ id: 1, name: 'Hauptprogramm' }] });
        return;
      case 'stackTrace': {
        const frames: any[] = (await this.query('T')) ?? [];
        const stackFrames = await Promise.all(frames.map(async (f, i) => {
          const p = await this.localSource(f.file);
          return { id: i, name: f.name, line: f.line || 1, column: 1,
            source: p ? { name: path.basename(p), path: p } : { name: f.file } };
        }));
        this.respond(req, { stackFrames, totalFrames: stackFrames.length });
        return;
      }
      case 'scopes': {
        const f = a.frameId ?? 0;
        this.respond(req, { scopes: [
          { name: 'Lokal', variablesReference: this.ref(`L ${f}`), expensive: false },
          { name: 'Global', variablesReference: this.ref(`G ${f}`), expensive: true },
        ] });
        return;
      }
      case 'variables': {
        const q = this.varRefs[a.variablesReference] ?? '';
        const list: any[] = q ? (await this.query(q.split(' ')[0], q.split(' ').slice(1).join(' '))) ?? [] : [];
        this.respond(req, { variables: list.map((v) => ({
          name: v.name, value: v.value, type: v.type,
          variablesReference: v.ref ? this.ref(`V ${v.ref}`) : 0 })) });
        return;
      }
      case 'evaluate': {
        const v = await this.evaluate(String(a.expression ?? ''), a.frameId ?? 0);
        if (v) {
          this.respond(req, { result: v.value, type: v.type, variablesReference: v.ref ? this.ref(`V ${v.ref}`) : 0 });
        } else {
          this.respond(req, {}, false, 'nicht verfügbar');
        }
        return;
      }
      case 'continue':
        this.write('C');
        this.respond(req, { allThreadsContinued: true });
        return;
      case 'next':
        this.write('N');
        this.respond(req);
        return;
      case 'stepIn':
        this.write('I');
        this.respond(req);
        return;
      case 'stepOut':
        this.write('O');
        this.respond(req);
        return;
      case 'pause':
        this.write('P');
        this.respond(req);
        return;
      case 'terminate':
      case 'disconnect':
        this.write('X');
        setTimeout(() => this.kill(), 500);
        this.respond(req);
        return;
      default:
        this.respond(req, {}, false, `nicht unterstützt: ${req.command}`);
    }
  }

  private ref(q: string): number {
    this.varRefs.push(q);
    return this.varRefs.length - 1;
  }

  /** Ausdruck: Name einer lokalen/globalen Variablen, Felder mit Punkt (a.b.c). */
  private async evaluate(expr: string, frame: number): Promise<any | undefined> {
    const parts = expr.trim().split('.').map((s) => s.trim().toLowerCase()).filter((s) => s);
    if (!parts.length) {
      return undefined;
    }
    let list: any[] = (await this.query('L', String(frame))) ?? [];
    let v = list.find((x) => String(x.name).toLowerCase() === parts[0]);
    if (!v) {
      list = (await this.query('G', String(frame))) ?? [];
      v = list.find((x) => String(x.name).toLowerCase() === parts[0]);
    }
    for (const p of parts.slice(1)) {
      if (!v?.ref) {
        return undefined;
      }
      const kids: any[] = (await this.query('V', v.ref)) ?? [];
      v = kids.find((x) => String(x.name).toLowerCase() === p);
    }
    return v;
  }

  // ---------- Start ----------
  private async launch(req: DapMessage, c: PascalLaunch): Promise<void> {
    const program = c.program!;
    this.programDir = path.dirname(program);
    this.stopAtEntry = !!c.stopAtEntry;
    const name = path.basename(program).replace(/\.[^.]*$/, '');
    this.output(`Übersetze ${path.basename(program)} für z/OS mit Debug-Agent …\n`, 'console');
    const ok = await this.builder.build(vscode.Uri.file(program), 'ZOS_ZDBG=1', `-g -O- ${c.compilerOptions ?? ''}`);
    if (!ok) {
      this.respond(req, {}, false, 'Übersetzen fehlgeschlagen (siehe Probleme / Ausgabe „z/OS Pascal“)');
      this.event('terminated');
      return;
    }
    const env = await readZosEnv(toolchainRoot());
    const args = Array.isArray(c.args) ? c.args : (c.args ? String(c.args).split(/\s+/).filter((s) => s) : []);
    const run = `${env.dir}/run/${name}.dbg`;
    const remote = `mkdir -p ${run} && cd ${run} && export ZDBG=1 && ` +
      `export LIBPATH=${env.dir}:${env.dir}/lib:$LIBPATH && ${env.dir}/${name} ${args.map(shq).join(' ')}; ` +
      `rc=$?; cd ${env.dir} && rm -rf ${run}; exit $rc`;
    this.output(`Starte ${name} auf z/OS …\n`, 'console');
    const sshArgs = ['-o', 'BatchMode=yes'];
    if (env.key) {
      sshArgs.push('-i', env.key);
    }
    sshArgs.push(env.host, remote);
    // wie die Skripte: ssh von Git für Windows, falls vorhanden (sonst das aus dem PATH)
    const gitSsh = 'C:/Program Files/Git/usr/bin/ssh.exe';
    const p = cp.spawn(fs.existsSync(gitSsh) ? gitSsh : 'ssh.exe', sshArgs, { windowsHide: true });
    this.proc = p;
    p.stdout?.setEncoding('latin1');
    p.stderr?.setEncoding('latin1');
    p.stdout?.on('data', (d: string) => this.onData(d));
    p.stderr?.on('data', (d: string) => this.output(d, 'stderr'));
    p.on('error', (e) => {
      this.output(`ssh: ${e.message}\n`, 'stderr');
      this.finish();
    });
    p.on('close', (code) => {
      this.exitCode = code ?? undefined;
      this.finish();
    });
    this.respond(req);
  }

  private maybeStart(): void {
    if (!this.ready || !this.configDone || this.started) {
      return;
    }
    this.started = true;
    for (const [file, lines] of this.bps) {
      this.write(`B ${file} ${lines.join(' ')}`);
    }
    this.write(this.stopAtEntry ? 'RUNSTOP' : 'RUN');
  }

  private write(line: string): void {
    this.proc?.stdin?.write(line + '\n');
  }

  private query(cmd: string, arg = ''): Promise<any> {
    const id = this.reqId++;
    return new Promise((resolve) => {
      this.pending.set(id, resolve);
      this.write(`${cmd} ${id}${arg ? ' ' + arg : ''}`);
      setTimeout(() => {
        if (this.pending.delete(id)) {
          resolve(undefined);
        }
      }, 15000);
    });
  }

  private onData(d: string): void {
    this.buf += d;
    let nl: number;
    while ((nl = this.buf.indexOf('\n')) >= 0) {
      const line = this.buf.slice(0, nl).replace(/\r$/, '');
      this.buf = this.buf.slice(nl + 1);
      this.onLine(line);
    }
  }

  private onLine(line: string): void {
    if (!line.startsWith('@@Z ')) {
      this.output(line + '\n'); // Ausgabe vor dem Start des Agenten, ssh-Meldungen
      return;
    }
    const rest = line.slice(4);
    if (rest === 'READY') {
      this.ready = true;
      this.maybeStart();
    } else if (rest.startsWith('O ')) {
      try {
        this.output(JSON.parse(rest.slice(2)));
      } catch {
        this.output(rest.slice(2) + '\n');
      }
    } else if (rest.startsWith('STOP ')) {
      const m = /^STOP (\S+) (\d+) (.*)$/.exec(rest);
      const reason = m?.[1] === 'breakpoint' ? 'breakpoint' : m?.[1] === 'pause' ? 'pause'
        : m?.[1] === 'entry' ? 'entry' : 'step';
      this.varRefs.length = 1;
      this.event('stopped', { reason, threadId: 1, allThreadsStopped: true });
    } else if (rest.startsWith('R ')) {
      const m = /^R (\d+) (.*)$/.exec(rest);
      if (m) {
        const cb = this.pending.get(+m[1]);
        this.pending.delete(+m[1]);
        try {
          cb?.(JSON.parse(m[2]));
        } catch {
          cb?.(undefined);
        }
      }
    } else if (rest === 'END') {
      this.ended = true;
    }
  }

  private finish(): void {
    if (this.proc === undefined) {
      return;
    }
    this.proc = undefined;
    if (this.buf) {
      this.onLine(this.buf);
      this.buf = '';
    }
    this.event('exited', { exitCode: this.exitCode ?? (this.ended ? 0 : 1) });
    this.event('terminated');
  }

  private kill(): void {
    const p = this.proc;
    if (p) {
      try {
        p.stdin?.end();
        p.kill();
      } catch {
        // schon beendet
      }
    }
  }

  /** Dateiname aus dem Programm (DIFile) -> lokaler Pfad. */
  private async localSource(file: string): Promise<string | undefined> {
    if (this.sourceCache.has(file)) {
      return this.sourceCache.get(file);
    }
    let res: string | undefined;
    const direct = path.join(this.programDir, path.basename(file));
    if (fs.existsSync(direct)) {
      res = direct;
    } else {
      const found = await vscode.workspace.findFiles(`**/${path.basename(file)}`, '**/node_modules/**', 1);
      res = found[0]?.fsPath;
    }
    this.sourceCache.set(file, res);
    return res;
  }
}

export class ZosDebugFactory implements vscode.DebugAdapterDescriptorFactory {
  constructor(private readonly builder: Builder, private readonly out: vscode.OutputChannel) {}

  createDebugAdapterDescriptor(): vscode.ProviderResult<vscode.DebugAdapterDescriptor> {
    return new vscode.DebugAdapterInlineImplementation(new ZosDebugSession(this.builder, this.out));
  }
}
