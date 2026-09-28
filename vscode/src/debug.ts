// Debuggen: Typ "zos-pascal".
//   target "local": für Linux x86_64 übersetzen (FPC in WSL, -g -gw3 -O-) und mit gdb debuggen;
//                   Debug-Adapter ist cppdbg (Erweiterung C/C++), Transport wsl.exe.
//   target "zos":   Programm auf z/OS mit Debug-Agent (siehe zosdebug.ts).
import * as path from 'path';
import * as vscode from 'vscode';
import { Builder } from './build';
import { cfg, onWindows, runBash, shPath, shq } from './wsl';

export interface PascalLaunch extends vscode.DebugConfiguration {
  target?: 'local' | 'zos';
  program?: string;
  args?: string[] | string;
  stopAtEntry?: boolean;
  compilerOptions?: string;
}

export class PascalDebugProvider implements vscode.DebugConfigurationProvider {
  constructor(private readonly builder: Builder, private readonly out: vscode.OutputChannel) {}

  provideDebugConfigurations(): vscode.DebugConfiguration[] {
    return [
      { type: 'zos-pascal', request: 'launch', name: 'Pascal lokal (gdb)', target: 'local',
        program: '${file}', args: [], stopAtEntry: false },
      { type: 'zos-pascal', request: 'launch', name: 'Pascal auf z/OS', target: 'zos',
        program: '${file}', args: [], stopAtEntry: true },
    ];
  }

  /** F5 ohne launch.json: aktuelle Pascal-Datei lokal debuggen. */
  resolveDebugConfiguration(_f: vscode.WorkspaceFolder | undefined, c: PascalLaunch): PascalLaunch | undefined {
    if (!c.type && !c.request && !c.name) {
      const ed = vscode.window.activeTextEditor;
      if (ed?.document.languageId !== 'pascal') {
        return undefined;
      }
      return { type: 'zos-pascal', request: 'launch', name: 'Pascal lokal (gdb)', target: 'local',
        program: ed.document.uri.fsPath, stopAtEntry: false };
    }
    return c;
  }

  async resolveDebugConfigurationWithSubstitutedVariables(
    _f: vscode.WorkspaceFolder | undefined, c: PascalLaunch): Promise<vscode.DebugConfiguration | undefined> {
    const program = c.program;
    if (!program || !/\.(pas|pp|lpr|dpr)$/i.test(program)) {
      vscode.window.showErrorMessage('Debuggen: "program" muss eine Pascal-Quelldatei sein.');
      return undefined;
    }
    for (const d of vscode.workspace.textDocuments) {
      if (d.isDirty && d.languageId === 'pascal') {
        await d.save();
      }
    }
    if ((c.target ?? 'local') === 'local') {
      return this.local(c, program);
    }
    // z/OS: der Debug-Adapter (zosdebug.ts) übersetzt und startet selbst
    return c;
  }

  private async local(c: PascalLaunch, program: string): Promise<vscode.DebugConfiguration | undefined> {
    if (!vscode.extensions.getExtension('ms-vscode.cpptools')) {
      vscode.window.showErrorMessage('Lokales Debuggen braucht die Erweiterung „C/C++“ (ms-vscode.cpptools, Debug-Adapter für gdb).');
      return undefined;
    }
    const cwd = path.dirname(program);
    const base = path.basename(program);
    const name = base.replace(/\.[^.]*$/, '');
    const outDir = `/tmp/zos-pascal-debug/${name}`;
    const fpc = cfg().get<string>('debug.localCompiler') ?? '~/opt/fpc-main/bin/ppcx64';
    const unitPaths = (cfg().get<string[]>('debug.localUnitPaths') ?? [])
      .map((p) => `-Fu${shPath(p)}`).join(' ');
    const opts = c.compilerOptions ?? '';
    const gdb = cfg().get<string>('debug.gdb') ?? 'gdb';

    // gdb vorhanden?
    const chk = await runBash(`command -v ${gdb} >/dev/null || command -v ${shq(gdb)} >/dev/null`);
    if (chk.code !== 0) {
      vscode.window.showErrorMessage(`gdb fehlt in WSL ("${gdb}"). Installieren: sudo apt install gdb`);
      return undefined;
    }

    this.out.show(true);
    this.out.appendLine(`> lokal übersetzen (x86_64-linux, Debug): ${base}`);
    const res = await vscode.window.withProgress(
      { location: vscode.ProgressLocation.Notification, title: `Pascal lokal: übersetze ${base}` },
      () => runBash(`mkdir -p ${outDir} && ${shPath(fpc)} -g -gw3 -gl -O- -FE${outDir} -FU${outDir} ` +
        `${unitPaths} ${opts} ${shq(base)}`, { cwd, out: this.out }));
    this.builder.parseMessages(res.stdout + '\n' + res.stderr, cwd);
    if (res.code !== 0) {
      vscode.window.showErrorMessage(`Pascal lokal: ${base} nicht übersetzt (siehe Probleme / Ausgabe).`);
      return undefined;
    }

    const args = Array.isArray(c.args) ? c.args : (c.args ? c.args.split(/\s+/).filter((s) => s) : []);
    const conf: vscode.DebugConfiguration = {
      type: 'cppdbg',
      request: 'launch',
      name: c.name,
      program: `${outDir}/${name}`,
      args,
      stopAtEntry: c.stopAtEntry ?? false,
      cwd: onWindows ? toWsl(cwd) : cwd,
      MIMode: 'gdb',
      miDebuggerPath: gdb,
      setupCommands: [
        { text: '-enable-pretty-printing', ignoreFailures: true },
        { text: 'set debuginfod enabled off', ignoreFailures: true },
      ],
    };
    if (onWindows) {
      const distro = cfg().get<string>('wslDistribution');
      conf.pipeTransport = {
        pipeCwd: '',
        pipeProgram: 'wsl.exe',
        pipeArgs: distro ? ['-d', distro] : [],
        debuggerPath: gdb,
      };
      const map: Record<string, string> = {};
      for (const drive of 'cdefghij') {
        map[`/mnt/${drive}`] = `${drive.toUpperCase()}:\\`;
      }
      conf.sourceFileMap = map;
    }
    return conf;
  }
}

function toWsl(p: string): string {
  const m = /^([A-Za-z]):\\(.*)$/.exec(p);
  return m ? `/mnt/${m[1].toLowerCase()}/${m[2].replace(/\\/g, '/')}` : p;
}

