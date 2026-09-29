// Debug-Adapter für Pascal auf z/OS (target "zos"). Spricht mit dem Debug-Agenten im
// Programm (runtime/zosdbg.c) über die ssh-Sitzung: Zeilen "@@Z ..." vom Agenten,
// Befehle zeilenweise auf stdin. Portweiterleitung ist auf z/OS gesperrt, deshalb stdio.
// Eingaben in der Debugkonsole gehen an die Standardeingabe des Programms, solange es läuft
// (angehalten: mit führendem '>'); '^D' schließt die Standardeingabe.
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
  private stoppedThread = 0; // 0 = Programm läuft
  private threads: { id: number; name: string }[] = [{ id: 1, name: 'Hauptprogramm' }];

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
      case 'threads': {
        // Threadliste nur, solange einer steht (sonst die zuletzt bekannte)
        if (this.stoppedThread) {
          const t: any[] | undefined = await this.query('H');
          if (Array.isArray(t) && t.length) {
            this.threads = t.map((x) => ({ id: +x.id, name: String(x.name) }));
          }
        }
        this.respond(req, { threads: this.threads });
        return;
      }
      case 'stackTrace': {
        const tid = +(a.threadId ?? this.stoppedThread) || 1;
        const frames: any[] = (await this.query('T', String(tid))) ?? [];
        const stackFrames = await Promise.all(frames.map(async (f, i) => {
          const p = await this.localSource(f.file);
          return { id: tid * 1000 + i, name: f.name, line: f.line || 1, column: 1,
            source: p ? { name: path.basename(p), path: p } : { name: f.file } };
        }));
        this.respond(req, { stackFrames, totalFrames: stackFrames.length });
        return;
      }
      case 'scopes': {
        const f = this.frameArg(a.frameId);
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
        const expr = String(a.expression ?? '');
        if (a.context === 'repl' && (!this.stoppedThread || expr.startsWith('>'))) {
          this.input(this.stoppedThread ? expr.slice(1) : expr);
          this.respond(req, { result: '', variablesReference: 0 });
          return;
        }
        const v = await this.evaluate(expr, this.frameArg(a.frameId));
        if (v) {
          this.respond(req, { result: v.value, type: v.type, variablesReference: v.ref ? this.ref(`V ${v.ref}`) : 0 });
        } else {
          this.respond(req, {}, false, 'nicht verfügbar');
        }
        return;
      }
      case 'continue':
        this.stoppedThread = 0;
        this.write('C');
        this.respond(req, { allThreadsContinued: true });
        return;
      case 'next':
        this.stoppedThread = 0;
        this.write('N');
        this.respond(req);
        return;
      case 'stepIn':
        this.stoppedThread = 0;
        this.write('I');
        this.respond(req);
        return;
      case 'stepOut':
        this.stoppedThread = 0;
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

  /** frameId (Thread*1000 + Frame) -> "thread frame" für L/G */
  private frameArg(frameId: unknown): string {
    const n = typeof frameId === 'number' ? frameId : (this.stoppedThread || 1) * 1000;
    return `${Math.floor(n / 1000)} ${n % 1000}`;
  }

  /** Text als Programmeingabe (eine Zeile); '^D' schließt die Standardeingabe. */
  private input(text: string): void {
    if (text.trim() === '^D') {
      this.write('EOF');
      return;
    }
    // nur ASCII auf der Leitung (sshd wandelt nach EBCDIC); Latin-1 als \u00XX
    const js = JSON.stringify(text + '\n').replace(/[\u0080-￿]/g,
      (c) => c.charCodeAt(0) < 256 ? '\\u' + c.charCodeAt(0).toString(16).padStart(4, '0') : '?');
    this.write(`IN ${js}`);
  }

  /** Ausdruck: Variable, danach Felder (.x), Indizes ([3], [1,2]) und Dereferenzierung (^),
   *  z. B. pt.x, arr[3], pp^.y, liste^.naechster^.wert. */
  private async evaluate(expr: string, frame: string): Promise<any | undefined> {
    const toks = /^\s*([A-Za-z_][A-Za-z0-9_]*)((?:\s*(?:\.\s*[A-Za-z_][A-Za-z0-9_]*|\[[^\]]*\]|\^))*)\s*$/.exec(expr);
    if (!toks) {
      return undefined;
    }
    const steps: string[] = [];
    for (const m of toks[2].matchAll(/\.\s*([A-Za-z_][A-Za-z0-9_]*)|\[([^\]]*)\]|\^/g)) {
      if (m[1] !== undefined) {
        steps.push(m[1].toLowerCase());
      } else if (m[2] !== undefined) {
        for (const ix of m[2].split(',')) {
          steps.push(`[${ix.trim().toLowerCase()}]`);
        }
      } else {
        steps.push('^');
      }
    }
    const name = toks[1].toLowerCase();
    let list: any[] = (await this.query('L', frame)) ?? [];
    let v = list.find((x) => String(x.name).toLowerCase() === name);
    if (!v) {
      list = (await this.query('G', frame)) ?? [];
      v = list.find((x) => String(x.name).toLowerCase() === name);
    }
    for (const p of steps) {
      if (!v?.ref) {
        return undefined;
      }
      let kids: any[] = (await this.query('V', v.ref)) ?? [];
      let k = kids.find((x) => String(x.name).toLowerCase() === p);
      // Feld über einen Zeiger ohne ^ (p.x wie p^.x)
      if (!k && p !== '^' && kids.length === 1 && kids[0].name === '^' && kids[0].ref) {
        kids = (await this.query('V', kids[0].ref)) ?? [];
        k = kids.find((x) => String(x.name).toLowerCase() === p);
      }
      v = k;
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
      const m = /^STOP (\S+) (\d+) (\d+) (.*)$/.exec(rest);
      const reason = m?.[1] === 'breakpoint' ? 'breakpoint' : m?.[1] === 'pause' ? 'pause'
        : m?.[1] === 'entry' ? 'entry' : 'step';
      this.varRefs.length = 1;
      this.stoppedThread = m ? +m[3] : 1;
      this.event('stopped', { reason, threadId: this.stoppedThread, allThreadsStopped: true });
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
