// Übersetzen (zfpc), Compilermeldungen als Diagnosen, Ausführen auf z/OS, Batch über JES.
import * as path from 'path';
import * as vscode from 'vscode';
import { cfg, hostPath, runBash, script, shq, bashCommand } from './wsl';
import { SpoolProvider } from './jes';

const MSG = /^(.+?)\((\d+),(\d+)\)\s+(Fatal|Error|Warning|Note|Hint):\s+(.*)$/;

export class Builder {
  constructor(
    private readonly out: vscode.OutputChannel,
    private readonly diags: vscode.DiagnosticCollection,
    private readonly spool: SpoolProvider,
    private readonly state: vscode.Memento,
    private readonly onJobsChanged: () => void,
  ) {}

  /** Datei aus Argument (Explorer) oder aktivem Editor; speichert sie. */
  async target(uri?: vscode.Uri, lang = 'pascal'): Promise<vscode.Uri | undefined> {
    const u = uri ?? vscode.window.activeTextEditor?.document.uri;
    if (!u || u.scheme !== 'file') {
      vscode.window.showErrorMessage('Keine Datei ausgewählt.');
      return undefined;
    }
    const doc = await vscode.workspace.openTextDocument(u);
    if (doc.languageId !== lang) {
      vscode.window.showErrorMessage(`${path.basename(u.fsPath)} ist keine ${lang === 'jcl' ? 'JCL' : 'Pascal'}-Datei.`);
      return undefined;
    }
    if (doc.isDirty) {
      await doc.save();
    }
    return u;
  }

  parseMessages(text: string, cwd: string): void {
    this.diags.clear();
    const byFile = new Map<string, vscode.Diagnostic[]>();
    for (const line of text.split(/\r?\n/)) {
      const m = MSG.exec(line);
      if (!m) {
        continue;
      }
      const file = hostPath(m[1], cwd);
      if (!file) {
        continue;
      }
      const ln = Math.max(0, parseInt(m[2], 10) - 1);
      const col = Math.max(0, parseInt(m[3], 10) - 1);
      const sev = m[4] === 'Warning' ? vscode.DiagnosticSeverity.Warning
        : m[4] === 'Note' || m[4] === 'Hint' ? vscode.DiagnosticSeverity.Information
        : vscode.DiagnosticSeverity.Error;
      const d = new vscode.Diagnostic(new vscode.Range(ln, col, ln, col + 1), m[5], sev);
      d.source = 'fpc';
      const list = byFile.get(file) ?? [];
      list.push(d);
      byFile.set(file, list);
    }
    for (const [file, list] of byFile) {
      this.diags.set(vscode.Uri.file(file), list);
    }
  }

  /** zfpc für die Datei; true bei Erfolg. extraEnv z. B. ZOS_PDS=MEMBER. */
  async build(uri: vscode.Uri, extraEnv = '', extraOpts = ''): Promise<boolean> {
    const cwd = path.dirname(uri.fsPath);
    const base = path.basename(uri.fsPath);
    const opts = `${cfg().get<string>('compilerOptions') ?? ''} ${extraOpts}`.trim();
    this.out.show(true);
    this.out.appendLine(`> zfpc ${opts} ${base}`);
    const res = await vscode.window.withProgress(
      { location: vscode.ProgressLocation.Notification, title: `z/OS: übersetze ${base}`, cancellable: true },
      (_p, token) => runBash(`${extraEnv} ${script('zfpc')} ${opts} ${shq(base)}`, { cwd, out: this.out, token }));
    this.parseMessages(res.stdout + '\n' + res.stderr, cwd);
    if (res.code !== 0) {
      this.out.appendLine(`--- zfpc: Fehler (Exitcode ${res.code})`);
      vscode.window.showErrorMessage(`z/OS: ${base} nicht übersetzt (siehe Probleme / Ausgabe).`);
      return false;
    }
    this.out.appendLine('--- übersetzt und auf z/OS gebunden');
    return true;
  }

  async buildCommand(uri?: vscode.Uri): Promise<void> {
    const u = await this.target(uri);
    if (u) {
      await this.build(u);
    }
  }

  /** übersetzen, dann im Terminal auf z/OS ausführen (Ein-/Ausgabe interaktiv). */
  async runCommand(uri?: vscode.Uri): Promise<void> {
    const u = await this.target(uri);
    if (!u || !(await this.build(u))) {
      return;
    }
    const key = `args:${u.fsPath}`;
    const args = await vscode.window.showInputBox({
      prompt: 'Programmargumente (leer = keine)',
      value: this.state.get<string>(key, ''),
    });
    if (args === undefined) {
      return;
    }
    await this.state.update(key, args);
    const prog = path.basename(u.fsPath).replace(/\.[^.]*$/, '');
    const cwd = path.dirname(u.fsPath);
    const cmd = `./${shq(prog)} ${args}; rc=$?; echo; echo "--- ${prog}: rc=$rc"`;
    const { file, args: shellArgs } = bashCommand(cmd + '; read -r -p "(Enter schließt das Terminal)" _', cwd);
    const term = vscode.window.createTerminal({ name: `z/OS: ${prog}`, shellPath: file, shellArgs });
    term.show();
  }

  /** in die PDSE binden, Batch-JCL erzeugen, über FTP/JES einreichen, Spool öffnen. */
  async batchCommand(uri?: vscode.Uri): Promise<void> {
    const u = await this.target(uri);
    if (!u) {
      return;
    }
    const prog = path.basename(u.fsPath).replace(/\.[^.]*$/, '');
    const suggested = prog.toUpperCase().replace(/[^A-Z0-9@#$]/g, '').slice(0, 8);
    const member = await vscode.window.showInputBox({
      prompt: 'Membername in der PDSE',
      value: this.state.get<string>(`member:${u.fsPath}`, suggested),
      validateInput: (v) => /^[A-Za-z@#$][A-Za-z0-9@#$]{0,7}$/.test(v) ? undefined
        : '1-8 Zeichen, beginnt mit Buchstabe, @, # oder $',
    });
    if (!member) {
      return;
    }
    const parm = await vscode.window.showInputBox({
      prompt: 'PARM für das Programm (leer = keine)',
      value: this.state.get<string>(`parm:${u.fsPath}`, ''),
    });
    if (parm === undefined) {
      return;
    }
    await this.state.update(`member:${u.fsPath}`, member);
    await this.state.update(`parm:${u.fsPath}`, parm);
    const m = member.toUpperCase();
    if (!(await this.build(u, `ZOS_PDS=${m}`))) {
      return;
    }
    const wait = cfg().get<number>('jes.waitSeconds') ?? 300;
    await this.submit(`sh ${script('zos-batch.sh')} -j ${m} ${parm ? shq(parm) : ''} | ` +
      `python3 ${script('zos-jes.py')} --wait ${wait} --out /tmp/zos-pascal-jes -`,
      path.dirname(u.fsPath), `${m} (Batch)`);
  }

  async submitJclCommand(uri?: vscode.Uri): Promise<void> {
    const u = await this.target(uri, 'jcl');
    if (!u) {
      return;
    }
    const wait = cfg().get<number>('jes.waitSeconds') ?? 300;
    await this.submit(`python3 ${script('zos-jes.py')} --wait ${wait} --out /tmp/zos-pascal-jes ` +
      shq(path.basename(u.fsPath)), path.dirname(u.fsPath), path.basename(u.fsPath));
  }

  /** zos-jes.py ausführen: stdout = Spool, stderr = Meldungen (Job-ID, RC). */
  private async submit(cmd: string, cwd: string, what: string): Promise<void> {
    this.out.show(true);
    this.out.appendLine(`> JES: ${what}`);
    const res = await vscode.window.withProgress(
      { location: vscode.ProgressLocation.Notification, title: `z/OS: ${what} läuft …`, cancellable: true },
      (_p, token) => runBash(cmd, { cwd, out: this.out, token, stdoutToChannel: false }));
    this.onJobsChanged();
    const id = /eingereicht als (J(?:OB)?\d+)/.exec(res.stderr)?.[1];
    const rc = /beendet: (.*)$/m.exec(res.stderr)?.[1] ?? `Exitcode ${res.code}`;
    if (id && res.stdout) {
      await this.spool.show(id, res.stdout);
    }
    const text = `z/OS: ${what}${id ? ' ' + id : ''}: ${rc}`;
    if (res.code === 0) {
      vscode.window.showInformationMessage(text);
    } else {
      vscode.window.showWarningMessage(text);
    }
  }
}
