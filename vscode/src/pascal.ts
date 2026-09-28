// Pascal-Struktur ohne Compiler: Gliederung (Outline), Symbole für Definitionen und die
// Symbolsuche im Arbeitsbereich. Ein einfacher Tokenizer mit Tiefenzählung für
// begin/end, record/class/object, case, try, asm; kein vollständiger Parser.
import * as vscode from 'vscode';

export interface Tok {
  text: string; // Kleinbuchstaben
  raw: string;
  start: number;
  end: number;
}

/** Kommentare und Strings durch Leerzeichen ersetzen (Positionen bleiben erhalten). */
export function blank(src: string): string {
  const out = src.split('');
  let i = 0;
  const n = src.length;
  const fill = (a: number, b: number) => {
    for (let k = a; k < b && k < n; k++) {
      if (out[k] !== '\n' && out[k] !== '\r') {
        out[k] = ' ';
      }
    }
  };
  // bedingte Übersetzung: nur der erste Zweig zählt ({$else}/{$elseif}-Zweige ausblenden),
  // sonst stehen z. B. zwei Rümpfe derselben Routine hintereinander
  const skip: boolean[] = [];
  let skipFrom = -1;
  const skipping = () => skip.some((s) => s);
  while (i < n) {
    const c = src[i];
    if (c === '{') {
      const e = src.indexOf('}', i + 1);
      const j = e < 0 ? n : e + 1;
      const d = /^\{\$([A-Za-z]+)/.exec(src.slice(i, Math.min(j, i + 20)));
      if (d) {
        const name = d[1].toLowerCase();
        const was = skipping();
        if (name === 'if' || name === 'ifdef' || name === 'ifndef' || name === 'ifopt') {
          skip.push(false);
        } else if ((name === 'else' || name === 'elseif') && skip.length) {
          skip[skip.length - 1] = true;
        } else if ((name === 'endif' || name === 'ifend') && skip.length) {
          skip.pop();
        }
        const now = skipping();
        if (!was && now) {
          skipFrom = j;
        } else if (was && !now) {
          fill(skipFrom, i);
        }
      }
      fill(i, j);
      i = j;
    } else if (c === '(' && src[i + 1] === '*') {
      const e = src.indexOf('*)', i + 2);
      const j = e < 0 ? n : e + 2;
      fill(i, j);
      i = j;
    } else if (c === '/' && src[i + 1] === '/') {
      let j = src.indexOf('\n', i);
      j = j < 0 ? n : j;
      fill(i, j);
      i = j;
    } else if (c === "'") {
      let j = i + 1;
      while (j < n && src[j] !== '\n') {
        if (src[j] === "'") {
          if (src[j + 1] === "'") {
            j += 2;
            continue;
          }
          j++;
          break;
        }
        j++;
      }
      fill(i, j);
      i = j;
    } else {
      i++;
    }
  }
  if (skipping()) {
    fill(skipFrom, n);
  }
  return out.join('');
}

export function tokenize(src: string): Tok[] {
  const clean = blank(src);
  const toks: Tok[] = [];
  const re = /[A-Za-z_&][A-Za-z0-9_]*|:=|\.\.|[^\sA-Za-z0-9_]/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(clean)) !== null) {
    let raw = m[0];
    if (raw.startsWith('&') && raw.length > 1) {
      raw = raw.slice(1); // &begin = Bezeichner
    }
    toks.push({ text: raw.toLowerCase(), raw, start: m.index, end: m.index + m[0].length });
  }
  return toks;
}

export interface PSymbol {
  name: string;
  detail: string;
  kind: vscode.SymbolKind;
  start: number; // Offset Deklaration
  end: number; // Offset Ende (inkl. Rumpf)
  nameStart: number;
  nameEnd: number;
  children: PSymbol[];
}

const ROUTINE = new Set(['procedure', 'function', 'constructor', 'destructor', 'operator']);
const SECTION = new Set(['var', 'const', 'type', 'label', 'threadvar', 'resourcestring', 'uses',
  'interface', 'implementation', 'initialization', 'finalization', 'begin', 'exports', 'property',
  'class', 'public', 'private', 'protected', 'published', 'strict', 'automated', 'generic']);
const DIRECTIVES = new Set(['overload', 'override', 'virtual', 'abstract', 'dynamic', 'reintroduce',
  'static', 'inline', 'cdecl', 'stdcall', 'safecall', 'pascal', 'register', 'varargs', 'assembler',
  'nostackframe', 'deprecated', 'platform', 'experimental', 'unimplemented', 'message', 'forward',
  'external', 'export', 'public', 'name', 'alias', 'weakexternal', 'final', 'noreturn', 'local',
  'interrupt', 'far', 'near', 'cppdecl', 'mwpascal', 'syscall', 'softfloat', 'iocheck', 'section',
  'cvar', 'index', 'default', 'enumerator', 'hardfloat', 'vectorcall', 'ms_abi_default',
  'sysv_abi_default', 'winapi', 'compilerproc', 'rtlproc', 'internproc', 'internconst', 'nodefault']);

/** Tiefenzähler: öffnet einen Block, der mit end schließt? */
function opens(toks: Tok[], i: number): boolean {
  const t = toks[i].text;
  if (t === 'begin' || t === 'case' || t === 'try' || t === 'asm' || t === 'record') {
    return true;
  }
  if (t === 'object') {
    // "procedure of object" ist kein Block
    return toks[i - 1]?.text !== 'of';
  }
  if (t === 'class' || t === 'interface' || t === 'dispinterface' || t === 'objcclass') {
    // nur Typdefinition "= class" / "= class(...)", nicht "class of", "class;" oder "class function"
    if (toks[i - 1]?.text !== '=' && toks[i - 1]?.text !== 'packed' && toks[i - 1]?.text !== 'sealed') {
      return false;
    }
    const nx = toks[i + 1]?.text;
    if (nx === 'of' || nx === ';') {
      return false;
    }
    if (nx === '(') {
      // class(TBase); = Vorwärtsdeklaration mit Basisklasse
      let k = i + 2;
      while (k < toks.length && toks[k].text !== ')') {
        k++;
      }
      return toks[k + 1]?.text !== ';';
    }
    return true;
  }
  return false;
}

/** Index des passenden end zu einem Block ab Token i (öffnend). */
function matchEnd(toks: Tok[], i: number): number {
  let depth = 0;
  for (let k = i; k < toks.length; k++) {
    if (opens(toks, k)) {
      depth++;
    } else if (toks[k].text === 'end') {
      depth--;
      if (depth === 0) {
        return k;
      }
    }
  }
  return toks.length - 1;
}

function sym(name: string, detail: string, kind: vscode.SymbolKind, a: Tok, b: Tok, nameTok: Tok, nameEnd?: Tok): PSymbol {
  return { name, detail, kind, start: a.start, end: b.end, nameStart: nameTok.start,
    nameEnd: (nameEnd ?? nameTok).end, children: [] };
}

export class PascalParser {
  private i = 0;
  constructor(private readonly toks: Tok[]) {}

  static parse(src: string): PSymbol[] {
    return new PascalParser(tokenize(src)).parseTop();
  }

  private t(k = 0): string {
    return this.toks[this.i + k]?.text ?? '';
  }

  private parseTop(): PSymbol[] {
    const res: PSymbol[] = [];
    const toks = this.toks;
    let container: PSymbol[] = res;
    let modSym: PSymbol | undefined;
    let section = '';
    while (this.i < toks.length) {
      const t = this.t();
      if ((t === 'program' || t === 'unit' || t === 'library' || t === 'package') && this.i + 1 < toks.length) {
        const a = toks[this.i];
        let k = this.i + 1;
        let name = toks[k].raw;
        while (toks[k + 1]?.text === '.' && toks[k + 2]) {
          name += '.' + toks[k + 2].raw;
          k += 2;
        }
        modSym = sym(name, t, vscode.SymbolKind.Module, a, toks[toks.length - 1], toks[this.i + 1], toks[k]);
        res.push(modSym);
        container = modSym.children;
        this.i = k + 1;
        continue;
      }
      if ((t === 'interface' || t === 'implementation') && this.t(-1) !== '=') {
        const s = sym(t, '', vscode.SymbolKind.Namespace, toks[this.i], toks[toks.length - 1], toks[this.i]);
        (modSym ? modSym.children : res).push(s);
        // Ende des Interface-Teils: Beginn des Implementation-Teils
        if (t === 'implementation') {
          const parent = modSym ? modSym.children : res;
          const intf = parent.find((p) => p.name === 'interface');
          if (intf) {
            intf.end = toks[this.i - 1].end;
          }
        }
        container = s.children;
        section = '';
        this.i++;
        continue;
      }
      if (t === 'initialization' || t === 'finalization' || (t === 'begin' && section !== 'routine')) {
        // Hauptprogramm / Unit-Initialisierung
        const a = toks[this.i];
        const e = t === 'begin' ? matchEnd(toks, this.i) : this.i;
        container.push(sym(t === 'begin' ? 'begin … end.' : t, '', vscode.SymbolKind.Event, a, toks[e], a));
        this.i = e + 1;
        continue;
      }
      if (t === 'var' || t === 'const' || t === 'type' || t === 'threadvar' || t === 'resourcestring') {
        section = t;
        this.i++;
        continue;
      }
      if (t === 'uses') {
        while (this.i < toks.length && this.t() !== ';') {
          this.i++;
        }
        this.i++;
        continue;
      }
      if (ROUTINE.has(t) || (t === 'class' && ROUTINE.has(this.t(1)))) {
        const r = this.parseRoutine(container === res ? undefined : container);
        if (r) {
          container.push(r);
        }
        continue;
      }
      if (/^[a-z_]/.test(t) && !SECTION.has(t) && section !== '' &&
          (this.t(1) === '=' || this.t(1) === ':' || this.t(1) === ',' || (this.t(1) === '<'))) {
        this.parseDecl(section, container);
        continue;
      }
      this.i++;
    }
    return res;
  }

  /** Deklaration in var/const/type: Name(n) = … ; / Name(n) : … ; */
  private parseDecl(section: string, container: PSymbol[]): void {
    const toks = this.toks;
    const names: Tok[] = [toks[this.i]];
    this.i++;
    // generische Parameter <T>
    if (this.t() === '<') {
      while (this.i < toks.length && this.t() !== '>') {
        this.i++;
      }
      this.i++;
    }
    while (this.t() === ',') {
      names.push(toks[this.i + 1]);
      this.i += 2;
    }
    const sep = this.t();
    const kindOf = (): [vscode.SymbolKind, string] => {
      if (section === 'type') {
        const nx = this.t(1) === 'packed' || this.t(1) === 'bitpacked' ? this.t(2) : this.t(1);
        if (nx === 'class' && this.t(2) !== 'of') {
          return [vscode.SymbolKind.Class, 'class'];
        }
        if (nx === 'object') {
          return [vscode.SymbolKind.Class, 'object'];
        }
        if (nx === 'record') {
          return [vscode.SymbolKind.Struct, 'record'];
        }
        if (nx === 'interface' || nx === 'dispinterface') {
          return [vscode.SymbolKind.Interface, 'interface'];
        }
        if (nx === '(') {
          return [vscode.SymbolKind.Enum, 'enum'];
        }
        if (ROUTINE.has(nx) || nx === 'reference') {
          return [vscode.SymbolKind.Function, 'procedural type'];
        }
        return [vscode.SymbolKind.TypeParameter, 'type'];
      }
      if (section === 'const' || section === 'resourcestring') {
        return [vscode.SymbolKind.Constant, sep === ':' ? 'typed const' : 'const'];
      }
      return [vscode.SymbolKind.Variable, section];
    };
    const [kind, detail] = kindOf();
    const first = names[0];
    // Ende: ; auf Tiefe 0 (Records/Klassen: nach dem passenden end)
    let k = this.i;
    let endTok = toks[k];
    let children: PSymbol[] = [];
    while (k < toks.length) {
      if (opens(toks, k)) {
        const e = matchEnd(toks, k);
        if (kind === vscode.SymbolKind.Class || kind === vscode.SymbolKind.Struct || kind === vscode.SymbolKind.Interface) {
          children = this.parseMembers(k + 1, e);
        }
        k = e + 1;
        continue;
      }
      if (toks[k].text === '(') {
        let depth = 0;
        for (; k < toks.length; k++) {
          if (toks[k].text === '(') {
            depth++;
          } else if (toks[k].text === ')' && --depth === 0) {
            break;
          }
        }
      }
      if (toks[k]?.text === ';') {
        endTok = toks[k];
        break;
      }
      k++;
    }
    for (const n of names) {
      const s = sym(n.raw, detail, kind, first, endTok ?? toks[toks.length - 1], n);
      if (n === first) {
        s.children = children;
      }
      container.push(s);
    }
    // Aufzählungswerte als Kinder
    if (kind === vscode.SymbolKind.Enum) {
      const s = container[container.length - 1];
      for (let j = this.i + 2; j < k && toks[j].text !== ')'; j++) {
        if (/^[a-z_]/.test(toks[j].text) && (toks[j + 1]?.text === ',' || toks[j + 1]?.text === ')' || toks[j + 1]?.text === '=')) {
          s.children.push(sym(toks[j].raw, '', vscode.SymbolKind.EnumMember, toks[j], toks[j], toks[j]));
        }
      }
    }
    this.i = k + 1;
  }

  /** Felder, Methoden, Eigenschaften in record/class/object zwischen Token a und b. */
  private parseMembers(a: number, b: number): PSymbol[] {
    const toks = this.toks;
    const res: PSymbol[] = [];
    let k = a;
    // Basisklasse überspringen
    if (toks[k]?.text === '(') {
      while (k < b && toks[k].text !== ')') {
        k++;
      }
      k++;
    }
    while (k < b) {
      const t = toks[k].text;
      if (ROUTINE.has(t) || (t === 'class' && ROUTINE.has(toks[k + 1]?.text))) {
        const st = toks[k];
        if (t === 'class') {
          k++;
        }
        const kind = toks[k].text === 'constructor' ? vscode.SymbolKind.Constructor : vscode.SymbolKind.Method;
        const nameTok = toks[k + 1];
        let j = k + 1;
        let depth = 0;
        for (; j < b; j++) {
          if (toks[j].text === '(') {
            depth++;
          } else if (toks[j].text === ')') {
            depth--;
          } else if (toks[j].text === ';' && depth === 0) {
            break;
          }
        }
        // Direktiven nach dem ;
        while (j + 1 < b && DIRECTIVES.has(toks[j + 1].text)) {
          j++;
          while (j < b && toks[j].text !== ';') {
            j++;
          }
        }
        if (nameTok) {
          res.push(sym(nameTok.raw, toks[k].text, kind, st, toks[j] ?? st, nameTok));
        }
        k = j + 1;
        continue;
      }
      if (t === 'property') {
        const nameTok = toks[k + 1];
        let j = k + 1;
        while (j < b && toks[j].text !== ';') {
          j++;
        }
        while (j + 1 < b && DIRECTIVES.has(toks[j + 1].text)) {
          j++;
          while (j < b && toks[j].text !== ';') {
            j++;
          }
        }
        if (nameTok) {
          res.push(sym(nameTok.raw, 'property', vscode.SymbolKind.Property, toks[k], toks[j] ?? toks[k], nameTok));
        }
        k = j + 1;
        continue;
      }
      if (t === 'case' || t === 'record' || t === 'begin') {
        // varianter Teil / verschachtelte Records: Felder darin weiter einsammeln
        k++;
        continue;
      }
      if (/^[a-z_]/.test(t) && !SECTION.has(t) && (toks[k + 1]?.text === ':' || toks[k + 1]?.text === ',')) {
        const names: Tok[] = [toks[k]];
        let j = k + 1;
        while (toks[j]?.text === ',') {
          names.push(toks[j + 1]);
          j += 2;
        }
        let e = j;
        while (e < b && toks[e].text !== ';') {
          if (opens(toks, e)) {
            e = matchEnd(toks, e);
          }
          e++;
        }
        for (const n of names) {
          res.push(sym(n.raw, 'field', vscode.SymbolKind.Field, names[0], toks[Math.min(e, b)], n));
        }
        k = e + 1;
        continue;
      }
      k++;
    }
    return res;
  }

  /** procedure/function … ; [Direktiven] [lokale Deklarationen, Unterroutinen] begin … end; */
  private parseRoutine(_outer?: PSymbol[]): PSymbol | undefined {
    const toks = this.toks;
    const st = toks[this.i];
    if (this.t() === 'class') {
      this.i++;
    }
    const kw = this.t();
    this.i++;
    // Name: A.B.C oder Operator
    const nameTok = toks[this.i];
    if (!nameTok) {
      return undefined;
    }
    let name = nameTok.raw;
    let last = nameTok;
    this.i++;
    while (this.t() === '.' && toks[this.i + 1]) {
      name += '.' + toks[this.i + 1].raw;
      last = toks[this.i + 1];
      this.i += 2;
    }
    if (this.t() === '<') {
      while (this.i < toks.length && this.t() !== '>') {
        this.i++;
      }
      this.i++;
    }
    // Parameterliste, Ergebnistyp bis ;
    let depth = 0;
    while (this.i < toks.length) {
      const t = this.t();
      if (t === '(') {
        depth++;
      } else if (t === ')') {
        depth--;
      } else if (t === ';' && depth === 0) {
        break;
      }
      this.i++;
    }
    let endTok = toks[this.i] ?? st;
    this.i++;
    let external = false;
    while (DIRECTIVES.has(this.t())) {
      if (this.t() === 'forward' || this.t() === 'external') {
        external = true;
      }
      while (this.i < toks.length && this.t() !== ';') {
        this.i++;
      }
      endTok = toks[this.i] ?? endTok;
      this.i++;
    }
    const kind = kw === 'constructor' ? vscode.SymbolKind.Constructor
      : name.includes('.') ? vscode.SymbolKind.Method : vscode.SymbolKind.Function;
    const s = sym(name, kw, kind, st, endTok, nameTok, last);
    // im Interface-Teil / forward / external: kein Rumpf
    if (external || this.inInterface(st.start)) {
      return s;
    }
    // lokale Deklarationen und Unterroutinen bis begin/asm
    let section = '';
    while (this.i < toks.length) {
      const t = this.t();
      if (t === 'begin' || t === 'asm') {
        const e = matchEnd(toks, this.i);
        s.end = (toks[e + 1]?.text === ';' ? toks[e + 1] : toks[e]).end;
        this.i = e + 1;
        return s;
      }
      if (ROUTINE.has(t) || (t === 'class' && ROUTINE.has(this.t(1)))) {
        const sub = this.parseRoutine(s.children);
        if (sub) {
          s.children.push(sub);
        }
        continue;
      }
      if (t === 'var' || t === 'const' || t === 'type' || t === 'label') {
        section = t;
        this.i++;
        continue;
      }
      if (t === 'implementation' || t === 'initialization' || t === 'finalization') {
        return s; // Rumpf fehlt (Fehler im Quelltext)
      }
      if (section && section !== 'label' && /^[a-z_]/.test(t) &&
          (this.t(1) === '=' || this.t(1) === ':' || this.t(1) === ',')) {
        this.parseDecl(section, s.children);
        continue;
      }
      this.i++;
    }
    return s;
  }

  private intfRange: [number, number] | undefined | null = null;
  private inInterface(pos: number): boolean {
    if (this.intfRange === null) {
      const toks = this.toks;
      const a = toks.findIndex((t, k) => t.text === 'interface' && toks[k - 1]?.text !== '=' &&
        (toks[k - 1]?.text === ';'));
      const b = toks.findIndex((t) => t.text === 'implementation');
      this.intfRange = a >= 0 ? [toks[a].start, b >= 0 ? toks[b].start : Number.MAX_SAFE_INTEGER] : undefined;
    }
    return !!this.intfRange && pos > this.intfRange[0] && pos < this.intfRange[1];
  }
}

export function toDocumentSymbols(doc: vscode.TextDocument, syms: PSymbol[]): vscode.DocumentSymbol[] {
  return syms.map((s) => {
    const range = new vscode.Range(doc.positionAt(s.start), doc.positionAt(Math.max(s.end, s.nameEnd)));
    const sel = new vscode.Range(doc.positionAt(s.nameStart), doc.positionAt(s.nameEnd));
    const d = new vscode.DocumentSymbol(s.name, s.detail, s.kind, range, range.contains(sel) ? sel : range);
    d.children = toDocumentSymbols(doc, s.children);
    return d;
  });
}
