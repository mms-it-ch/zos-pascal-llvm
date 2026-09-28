// Prüfungen für JCL: JOB-Karte (REGION=0M,LINES=500000), Spaltengrenzen.
import * as vscode from 'vscode';
import { cfg } from './wsl';

export function checkJcl(doc: vscode.TextDocument, diags: vscode.DiagnosticCollection): void {
  if (doc.languageId !== 'jcl') {
    return;
  }
  const out: vscode.Diagnostic[] = [];
  const lines = doc.getText().split(/\r?\n/);

  lines.forEach((line, i) => {
    if (line.length > 80) {
      out.push(new vscode.Diagnostic(new vscode.Range(i, 80, i, line.length),
        'JCL-Zeile länger als 80 Zeichen', vscode.DiagnosticSeverity.Error));
    }
    // Anweisungen enden in Spalte 71; 73-80 sind Folgenummern
    if (line.startsWith('//') && !line.startsWith('//*') && line.length > 71) {
      const tail = line.slice(71, 72);
      if (tail.trim() !== '') {
        out.push(new vscode.Diagnostic(new vscode.Range(i, 71, i, 72),
          'Text in Spalte 72: Operanden müssen in Spalte 71 enden (Fortsetzung mit Komma und neuer Zeile)',
          vscode.DiagnosticSeverity.Warning));
      }
    }
  });

  if (cfg().get<boolean>('jcl.checkJobCard') ?? true) {
    const start = lines.findIndex((l) => /^\/\/\S*\s+JOB\b/i.test(l));
    if (start >= 0) {
      let text = lines[start].slice(0, 71);
      let i = start;
      while (text.trimEnd().endsWith(',') && i + 1 < lines.length && /^\/\/\s/.test(lines[i + 1])) {
        i++;
        text += ' ' + lines[i].slice(0, 71);
      }
      const u = text.toUpperCase();
      const missing = ['REGION=0M', 'LINES=500000'].filter((k) => !u.includes(k));
      if (missing.length) {
        out.push(new vscode.Diagnostic(new vscode.Range(start, 0, start, lines[start].length),
          `JOB-Karte ohne ${missing.join(' und ')} (Vorgabe: REGION=0M,LINES=500000)`,
          vscode.DiagnosticSeverity.Warning));
      }
    }
  }
  diags.set(doc.uri, out);
}
