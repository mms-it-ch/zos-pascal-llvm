// z/OS Pascal: Einstiegspunkt der Erweiterung.
import * as vscode from 'vscode';
import { Builder } from './build';
import { checkJcl } from './jcl';
import { JobsProvider, SpoolProvider } from './jes';

/** Befehl mit Fehlermeldung statt stillem Abbruch. */
function cmd(id: string, f: (...a: any[]) => unknown): vscode.Disposable {
  return vscode.commands.registerCommand(id, async (...a: any[]) => {
    try {
      await f(...a);
    } catch (e) {
      vscode.window.showErrorMessage(`z/OS Pascal: ${e instanceof Error ? e.message : String(e)}`);
    }
  });
}

export function activate(context: vscode.ExtensionContext): void {
  const out = vscode.window.createOutputChannel('z/OS Pascal');
  const buildDiags = vscode.languages.createDiagnosticCollection('zos-pascal');
  const jclDiags = vscode.languages.createDiagnosticCollection('zos-jcl');
  const spool = new SpoolProvider();
  const jobs = new JobsProvider(out, spool);
  const builder = new Builder(out, buildDiags, spool, context.workspaceState, () => jobs.refresh());

  context.subscriptions.push(
    out, buildDiags, jclDiags, jobs,
    vscode.workspace.registerTextDocumentContentProvider(SpoolProvider.scheme, spool),
    vscode.window.registerTreeDataProvider('zosPascal.jobs', jobs),

    cmd('zosPascal.build', (u?: vscode.Uri) => builder.buildCommand(u)),
    cmd('zosPascal.run', (u?: vscode.Uri) => builder.runCommand(u)),
    cmd('zosPascal.batch', (u?: vscode.Uri) => builder.batchCommand(u)),
    cmd('zosPascal.submitJcl', (u?: vscode.Uri) => builder.submitJclCommand(u)),
    cmd('zosPascal.jes.refresh', () => jobs.refresh()),
    cmd('zosPascal.jes.open', (i) => jobs.open(i)),
    cmd('zosPascal.jes.delete', (i) => jobs.delete(i)),
    cmd('zosPascal.jes.copyId', (i) => jobs.copyId(i)),

    vscode.workspace.onDidOpenTextDocument((d) => checkJcl(d, jclDiags)),
    vscode.workspace.onDidChangeTextDocument((e) => checkJcl(e.document, jclDiags)),
    vscode.workspace.onDidCloseTextDocument((d) => jclDiags.delete(d.uri)),
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration('zosPascal.jes.autoRefreshSeconds')) {
        jobs.configureTimer();
      }
    }),
  );
  vscode.workspace.textDocuments.forEach((d) => checkJcl(d, jclDiags));
}

export function deactivate(): void {
  // nichts
}
