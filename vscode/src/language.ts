// Sprachfunktionen: Gliederung, Definitionen (F12), Symbolsuche (Strg+T), Formatieren (ptop).
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import * as vscode from 'vscode';
import { PascalParser, PSymbol, toDocumentSymbols } from './pascal';
import { cfg, runBash, shPath } from './wsl';

const GLOB = '**/*.{pas,pp,inc,lpr,dpr,PAS,PP,INC}';

interface IndexEntry {
  name: string; // letzter Namensteil, Kleinbuchstaben
  full: string;
  kind: vscode.SymbolKind;
  container: string;
  uri: vscode.Uri;
  line: number;
  col: number;
}

/** Symbole aller Pascal-Dateien des Arbeitsbereichs (und zosPascal.sourcePaths). */
export class SymbolIndex {
  private readonly byFile = new Map<string, IndexEntry[]>();
  private ready: Thenable<void> | undefined;

  constructor(context: vscode.ExtensionContext) {
    const w = vscode.workspace.createFileSystemWatcher(GLOB);
    context.subscriptions.push(w,
      w.onDidChange((u) => this.update(u)),
      w.onDidCreate((u) => this.update(u)),
      w.onDidDelete((u) => this.byFile.delete(u.toString())),
      vscode.workspace.onDidSaveTextDocument((d) => d.languageId === 'pascal' && this.update(d.uri)),
      vscode.workspace.onDidChangeConfiguration((e) => {
        if (e.affectsConfiguration('zosPascal.sourcePaths')) {
          this.ready = undefined;
          this.byFile.clear();
        }
      }));
  }

  private async build(): Promise<void> {
    const files = await vscode.workspace.findFiles(GLOB, '**/{node_modules,out,.git}/**', 20000);
    for (const extra of cfg().get<string[]>('sourcePaths') ?? []) {
      files.push(...listFiles(extra));
    }
    // in Portionen, damit die Oberfläche nicht hängt
    for (let k = 0; k < files.length; k += 50) {
      await Promise.all(files.slice(k, k + 50).map((f) => this.update(f)));
    }
  }

  ensure(): Thenable<void> {
    if (!this.ready) {
      this.ready = vscode.window.withProgress(
        { location: vscode.ProgressLocation.Window, title: 'Pascal: Symbole einlesen' }, () => this.build());
    }
    return this.ready;
  }

  async update(uri: vscode.Uri): Promise<void> {
    let text: string;
    try {
      text = await fs.promises.readFile(uri.fsPath, 'latin1');
    } catch {
      this.byFile.delete(uri.toString());
      return;
    }
    const entries: IndexEntry[] = [];
    const lines = lineStarts(text);
    const walk = (syms: PSymbol[], container: string, depth: number) => {
      for (const s of syms) {
        if (s.kind === vscode.SymbolKind.Namespace) {
          walk(s.children, container, depth);
          continue;
        }
        const [line, col] = pos(lines, s.nameStart);
        const last = s.name.split('.').pop() ?? s.name;
        entries.push({ name: last.toLowerCase(), full: s.name, kind: s.kind, container, uri, line, col });
        // lokale Symbole von Routinen nicht in den Index (nur Typ-Member und Aufzählungen)
        if (s.kind !== vscode.SymbolKind.Function && s.kind !== vscode.SymbolKind.Method &&
            s.kind !== vscode.SymbolKind.Constructor && depth < 4) {
          walk(s.children, s.name, depth + 1);
        }
      }
    };
    try {
      walk(PascalParser.parse(text), '', 0);
    } catch {
      // unvollständiger Quelltext: Datei auslassen
    }
    this.byFile.set(uri.toString(), entries);
  }

  find(name: string): IndexEntry[] {
    const n = name.toLowerCase();
    const res: IndexEntry[] = [];
    for (const list of this.byFile.values()) {
      for (const e of list) {
        if (e.name === n) {
          res.push(e);
        }
      }
    }
    return res;
  }

  search(query: string, limit = 500): IndexEntry[] {
    const q = query.toLowerCase();
    const res: IndexEntry[] = [];
    for (const list of this.byFile.values()) {
      for (const e of list) {
        if (fuzzy(e.name, q)) {
          res.push(e);
          if (res.length >= limit) {
            return res;
          }
        }
      }
    }
    return res;
  }

  unitFile(unit: string): vscode.Uri | undefined {
    const u = unit.toLowerCase();
    for (const key of this.byFile.keys()) {
      const f = vscode.Uri.parse(key);
      const b = path.basename(f.fsPath).toLowerCase();
      if (b === `${u}.pas` || b === `${u}.pp` || b === `${u}.lpr`) {
        return f;
      }
    }
    return undefined;
  }
}

function fuzzy(name: string, q: string): boolean {
  let k = 0;
  for (const c of name) {
    if (c === q[k]) {
      k++;
      if (k === q.length) {
        return true;
      }
    }
  }
  return q.length === 0;
}

function listFiles(dir: string): vscode.Uri[] {
  const res: vscode.Uri[] = [];
  const walk = (d: string, depth: number) => {
    let ents: fs.Dirent[];
    try {
      ents = fs.readdirSync(d, { withFileTypes: true });
    } catch {
      return;
    }
    for (const e of ents) {
      const p = path.join(d, e.name);
      if (e.isDirectory() && depth < 8 && !e.name.startsWith('.') && e.name !== 'units') {
        walk(p, depth + 1);
      } else if (/\.(pas|pp|inc|lpr)$/i.test(e.name)) {
        res.push(vscode.Uri.file(p));
      }
    }
  };
  walk(dir, 0);
  return res;
}

function lineStarts(text: string): number[] {
  const res = [0];
  for (let i = 0; i < text.length; i++) {
    if (text.charCodeAt(i) === 10) {
      res.push(i + 1);
    }
  }
  return res;
}

function pos(starts: number[], off: number): [number, number] {
  let lo = 0;
  let hi = starts.length - 1;
  while (lo < hi) {
    const mid = (lo + hi + 1) >> 1;
    if (starts[mid] <= off) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  return [lo, off - starts[lo]];
}

export class PascalSymbolProvider implements vscode.DocumentSymbolProvider {
  provideDocumentSymbols(doc: vscode.TextDocument): vscode.DocumentSymbol[] {
    return toDocumentSymbols(doc, PascalParser.parse(doc.getText()));
  }
}

export class PascalWorkspaceSymbols implements vscode.WorkspaceSymbolProvider {
  constructor(private readonly index: SymbolIndex) {}

  async provideWorkspaceSymbols(query: string): Promise<vscode.SymbolInformation[]> {
    await this.index.ensure();
    return this.index.search(query).map((e) => new vscode.SymbolInformation(e.full, e.kind, e.container,
      new vscode.Location(e.uri, new vscode.Position(e.line, e.col))));
  }
}

export class PascalDefinitionProvider implements vscode.DefinitionProvider {
  constructor(private readonly index: SymbolIndex) {}

  async provideDefinition(doc: vscode.TextDocument, position: vscode.Position): Promise<vscode.Location[]> {
    const range = doc.getWordRangeAtPosition(position, /[A-Za-z_][A-Za-z0-9_]*/);
    if (!range) {
      return [];
    }
    const word = doc.getText(range);
    const lw = word.toLowerCase();
    const res: vscode.Location[] = [];

    // uses-Liste: Unit-Datei
    const before = doc.getText(new vscode.Range(new vscode.Position(Math.max(0, position.line - 30), 0), range.start));
    if (/\buses\b[^;]*$/i.test(before)) {
      await this.index.ensure();
      const f = this.index.unitFile(word);
      if (f) {
        return [new vscode.Location(f, new vscode.Position(0, 0))];
      }
    }

    // 1. aktuelle Datei, innerste Routine zuerst (lokale Variablen, Parameter nicht erfasst)
    const syms = PascalParser.parse(doc.getText());
    const off = doc.offsetAt(position);
    const local: PSymbol[] = [];
    const walk = (list: PSymbol[], inScope: boolean) => {
      for (const s of list) {
        const last = (s.name.split('.').pop() ?? '').toLowerCase();
        if (last === lw && inScope) {
          local.push(s);
        }
        const contains = off >= s.start && off <= s.end;
        const isRoutine = s.kind === vscode.SymbolKind.Function || s.kind === vscode.SymbolKind.Method ||
          s.kind === vscode.SymbolKind.Constructor;
        walk(s.children, !isRoutine || contains);
      }
    };
    walk(syms, true);
    for (const s of local) {
      res.push(new vscode.Location(doc.uri, doc.positionAt(s.nameStart)));
    }
    // 2. Arbeitsbereich und sourcePaths
    await this.index.ensure();
    for (const e of this.index.find(word)) {
      if (e.uri.toString() === doc.uri.toString()) {
        continue;
      }
      res.push(new vscode.Location(e.uri, new vscode.Position(e.line, e.col)));
    }
    return res;
  }
}

/** Formatieren mit ptop (Free Pascal) in WSL. */
export class PtopFormatter implements vscode.DocumentFormattingEditProvider {
  constructor(private readonly extPath: string, private readonly out: vscode.OutputChannel) {}

  async provideDocumentFormattingEdits(doc: vscode.TextDocument): Promise<vscode.TextEdit[]> {
    const ptop = cfg().get<string>('format.ptop') ?? '~/opt/fpc-main/bin/ptop';
    const conf = cfg().get<string>('format.config') || path.join(this.extPath, 'resources', 'ptop.cfg');
    const opts = vscode.window.activeTextEditor?.options;
    const indent = typeof opts?.tabSize === 'number' ? opts.tabSize : 2;
    const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'zos-pascal-fmt-'));
    const inF = path.join(tmp, 'in.pas');
    const outF = path.join(tmp, 'out.pas');
    try {
      fs.writeFileSync(inF, doc.getText(), 'latin1');
      const res = await runBash(`${shPath(ptop)} -i ${indent} -l 100 -c ${shPath(conf)} ${shPath(inF)} ${shPath(outF)}`);
      if (res.code !== 0 || !fs.existsSync(outF)) {
        this.out.appendLine(`ptop: ${res.stdout}${res.stderr}`);
        vscode.window.showErrorMessage('Formatieren mit ptop fehlgeschlagen (siehe Ausgabe „z/OS Pascal“).');
        return [];
      }
      let text = fs.readFileSync(outF, 'latin1');
      // ptop beginnt mit einer Leerzeile
      if (!doc.getText().startsWith('\n') && text.startsWith('\n')) {
        text = text.replace(/^\n+/, '');
      }
      if (doc.eol === vscode.EndOfLine.CRLF) {
        text = text.replace(/\r?\n/g, '\r\n');
      }
      const all = new vscode.Range(doc.positionAt(0), doc.positionAt(doc.getText().length));
      return [vscode.TextEdit.replace(all, text)];
    } finally {
      fs.rmSync(tmp, { recursive: true, force: true });
    }
  }
}
