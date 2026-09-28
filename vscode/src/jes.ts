// JES-Ansicht über FTP (scripts/zos-jes.py): Jobliste, Spool im Editor, Löschen.
import * as vscode from 'vscode';
import { cfg, runBash, script, shq } from './wsl';

interface Job {
  name: string;
  id: string;
  owner: string;
  status: string;
  class: string;
  rc: string;
  spool: number;
}

/** Spool als schreibgeschütztes Dokument (zosjes:/JOB01234.spool). */
export class SpoolProvider implements vscode.TextDocumentContentProvider {
  static readonly scheme = 'zosjes';
  private readonly content = new Map<string, string>();
  private readonly changed = new vscode.EventEmitter<vscode.Uri>();
  readonly onDidChange = this.changed.event;

  provideTextDocumentContent(uri: vscode.Uri): string {
    return this.content.get(uri.path) ?? '';
  }

  async show(jobid: string, text: string): Promise<void> {
    const uri = vscode.Uri.parse(`${SpoolProvider.scheme}:/${jobid}.spool`);
    this.content.set(uri.path, text);
    this.changed.fire(uri);
    const doc = await vscode.workspace.openTextDocument(uri);
    await vscode.languages.setTextDocumentLanguage(doc, 'jes-spool');
    await vscode.window.showTextDocument(doc, { preview: false });
  }
}

class JobItem extends vscode.TreeItem {
  constructor(readonly job: Job) {
    super(`${job.id}  ${job.name}`, vscode.TreeItemCollapsibleState.None);
    this.description = [job.status, job.rc, job.spool ? `${job.spool} Spool-Dateien` : '']
      .filter((s) => s).join('  ');
    this.contextValue = 'job';
    this.tooltip = `${job.name} ${job.id}\nBesitzer ${job.owner}, Klasse ${job.class}\n${job.status} ${job.rc}`;
    this.iconPath = JobItem.icon(job);
    this.command = { command: 'zosPascal.jes.open', title: 'Spool öffnen', arguments: [this] };
  }

  private static icon(job: Job): vscode.ThemeIcon {
    if (job.status === 'ACTIVE') {
      return new vscode.ThemeIcon('sync~spin');
    }
    if (job.status === 'INPUT' || job.status === 'HELD') {
      return new vscode.ThemeIcon('clock');
    }
    const m = /RC=(\d+)/.exec(job.rc);
    if (m) {
      const rc = parseInt(m[1], 10);
      if (rc === 0) {
        return new vscode.ThemeIcon('pass', new vscode.ThemeColor('testing.iconPassed'));
      }
      if (rc <= 4) {
        return new vscode.ThemeIcon('warning', new vscode.ThemeColor('list.warningForeground'));
      }
    }
    if (!job.rc) {
      return new vscode.ThemeIcon('circle-outline');
    }
    return new vscode.ThemeIcon('error', new vscode.ThemeColor('testing.iconFailed'));
  }
}

export class JobsProvider implements vscode.TreeDataProvider<vscode.TreeItem> {
  private readonly changed = new vscode.EventEmitter<void>();
  readonly onDidChangeTreeData = this.changed.event;
  private timer: NodeJS.Timeout | undefined;
  private error: string | undefined;

  constructor(private readonly out: vscode.OutputChannel, private readonly spool: SpoolProvider) {
    this.configureTimer();
  }

  configureTimer(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = undefined;
    }
    const s = cfg().get<number>('jes.autoRefreshSeconds') ?? 0;
    if (s > 0) {
      this.timer = setInterval(() => this.refresh(), Math.max(10, s) * 1000);
    }
  }

  dispose(): void {
    if (this.timer) {
      clearInterval(this.timer);
    }
  }

  refresh(): void {
    this.changed.fire();
  }

  getTreeItem(e: vscode.TreeItem): vscode.TreeItem {
    return e;
  }

  async getChildren(): Promise<vscode.TreeItem[]> {
    let res;
    try {
      res = await runBash(`python3 ${script('zos-jes.py')} --list --json`);
    } catch (e) {
      return [this.message(String(e))];
    }
    if (res.code !== 0) {
      this.error = res.stderr.trim().split('\n').pop() ?? `Exitcode ${res.code}`;
      this.out.appendLine(`JES: ${res.stderr.trim()}`);
      return [this.message(this.error)];
    }
    this.error = undefined;
    let jobs: Job[];
    try {
      jobs = JSON.parse(res.stdout) as Job[];
    } catch {
      return [this.message('Antwort von zos-jes.py unverständlich')];
    }
    if (jobs.length === 0) {
      return [this.message('keine Jobs')];
    }
    return jobs.map((j) => new JobItem(j));
  }

  private message(text: string): vscode.TreeItem {
    const i = new vscode.TreeItem(text);
    i.iconPath = new vscode.ThemeIcon('info');
    return i;
  }

  async open(item?: JobItem): Promise<void> {
    const id = item?.job.id ?? await vscode.window.showInputBox({ prompt: 'Job-ID (z. B. JOB01234)' });
    if (!id) {
      return;
    }
    const res = await vscode.window.withProgress(
      { location: vscode.ProgressLocation.Window, title: `Spool ${id}` },
      () => runBash(`python3 ${script('zos-jes.py')} --output ${shq(id)} --out /tmp/zos-pascal-jes`));
    if (res.code !== 0) {
      vscode.window.showErrorMessage(`Spool von ${id}: ${res.stderr.trim()}`);
      return;
    }
    await this.spool.show(id, res.stdout);
  }

  async delete(item?: JobItem): Promise<void> {
    if (!item) {
      return;
    }
    const ok = await vscode.window.showWarningMessage(
      `Job ${item.job.id} (${item.job.name}) aus dem Spool löschen?`, { modal: true }, 'Löschen');
    if (ok !== 'Löschen') {
      return;
    }
    const res = await runBash(`python3 ${script('zos-jes.py')} --delete ${shq(item.job.id)}`);
    if (res.code !== 0) {
      vscode.window.showErrorMessage(`Löschen von ${item.job.id}: ${res.stderr.trim()}`);
    }
    this.refresh();
  }

  async copyId(item?: JobItem): Promise<void> {
    if (item) {
      await vscode.env.clipboard.writeText(item.job.id);
    }
  }
}
