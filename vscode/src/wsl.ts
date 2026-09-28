// Aufrufe der Toolchain-Skripte (scripts/) in WSL bzw. direkt unter Linux.
import * as cp from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';

export const onWindows = process.platform === 'win32';

export function cfg(): vscode.WorkspaceConfiguration {
  return vscode.workspace.getConfiguration('zosPascal');
}

/** Für die Shell in einfache Anführungszeichen setzen. */
export function shq(s: string): string {
  return "'" + s.replace(/'/g, "'\\''") + "'";
}

/** Shell-Ausdruck für einen (Windows- oder Linux-)Pfad in der WSL-Shell. */
export function shPath(p: string): string {
  if (p.startsWith('~/')) {
    return '~/' + shq(p.slice(2));
  }
  if (!onWindows || p.startsWith('/')) {
    return shq(p);
  }
  return `"$(wslpath -u ${shq(p)})"`;
}

/** Linux-Pfad aus einer Compilermeldung als Windows-Pfad (nur /mnt/<lw>/...). */
export function hostPath(p: string, cwd: string): string | undefined {
  if (!onWindows) {
    return path.isAbsolute(p) ? p : path.join(cwd, p);
  }
  const m = /^\/mnt\/([a-z])\/(.*)$/.exec(p);
  if (m) {
    return `${m[1].toUpperCase()}:\\${m[2].replace(/\//g, '\\')}`;
  }
  if (p.startsWith('/')) {
    return undefined; // Datei nur in WSL (z. B. RTL-Quellen)
  }
  return path.join(cwd, p);
}

/** Wurzel des Repos zos-pascal-llvm (enthält scripts/zfpc). */
export function toolchainRoot(): string {
  const configured = cfg().get<string>('toolchainPath');
  if (configured) {
    return configured;
  }
  for (const f of vscode.workspace.workspaceFolders ?? []) {
    if (fs.existsSync(path.join(f.uri.fsPath, 'scripts', 'zfpc'))) {
      return f.uri.fsPath;
    }
  }
  throw new Error('zos-pascal-llvm nicht gefunden: Einstellung "zosPascal.toolchainPath" setzen ' +
    '(Ordner mit scripts/zfpc) oder das Repo als Arbeitsbereich öffnen.');
}

/** Shell-Ausdruck für ein Skript aus scripts/. */
export function script(name: string): string {
  return `${shPath(toolchainRoot())}/scripts/${name}`;
}

export interface RunResult {
  code: number;
  stdout: string;
  stderr: string;
}

/** Programm und Argumente, um ein bash-Skript in WSL (oder lokal) zu starten. */
export function bashCommand(bashScript: string, cwd?: string): { file: string; args: string[] } {
  if (!onWindows) {
    return { file: 'bash', args: ['-lc', cwd ? `cd ${shq(cwd)} && ${bashScript}` : bashScript] };
  }
  const args: string[] = [];
  const distro = cfg().get<string>('wslDistribution');
  if (distro) {
    args.push('-d', distro);
  }
  if (cwd) {
    args.push('--cd', cwd);
  }
  args.push('-e', 'bash', '-lc', bashScript);
  return { file: 'wsl.exe', args };
}

/** bash-Skript ausführen; Ausgabe optional in einen Ausgabekanal. */
export function runBash(bashScript: string, opts: {
  cwd?: string;
  out?: vscode.OutputChannel;
  token?: vscode.CancellationToken;
  stdoutToChannel?: boolean;
} = {}): Promise<RunResult> {
  const { file, args } = bashCommand(bashScript, opts.cwd);
  return new Promise((resolve, reject) => {
    const child = cp.spawn(file, args, { windowsHide: true });
    let stdout = '';
    let stderr = '';
    child.stdout.setEncoding('utf8');
    child.stderr.setEncoding('utf8');
    child.stdout.on('data', (d: string) => {
      stdout += d;
      if (opts.out && opts.stdoutToChannel !== false) {
        opts.out.append(d);
      }
    });
    child.stderr.on('data', (d: string) => {
      stderr += d;
      opts.out?.append(d);
    });
    opts.token?.onCancellationRequested(() => child.kill());
    child.on('error', reject);
    child.on('close', (code) => resolve({ code: code ?? -1, stdout, stderr }));
  });
}
