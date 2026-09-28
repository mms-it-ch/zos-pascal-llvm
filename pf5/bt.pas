program bt;
{ Backtraces mit Funktionsnamen (Stack-Durchlauf über EPM/PPA1, zosunwind.c).
    bt          prüft CaptureBacktrace und den Backtrace einer abgefangenen Ausnahme,
                Returncode = Anzahl Fehler
    bt div      unbehandelte Ausnahme aus einem Signal (Division durch 0)
    bt runerror Laufzeitfehler 201 (RunError) in einer verschachtelten Prozedur
  Kein Test zerstört den Stack (dann schreibt LE einen Dump). }
{$mode objfpc}{$H+}
uses SysUtils;

var
  errors: longint = 0;

procedure check(const what: string; ok: boolean);
begin
  if ok then writeln('OK      ', what)
  else begin writeln('FEHLER  ', what); inc(errors); end;
end;

{ Backtrace-Zeilen als ein Text (für die Prüfung) }
function capture_lines: string;
var
  frames: array[0..31] of codepointer;
  n, i: longint;
begin
  n := CaptureBacktrace(0, length(frames), @frames[0]);
  result := '';
  for i := 0 to n - 1 do
    result := result + BackTraceStrFunc(frames[i]) + LineEnding;
end;

var
  captured, excepttrace: string;
  zero: longint = 0;

procedure level3(mode: longint);
begin
  case mode of
    0: captured := capture_lines;
    1: raise Exception.Create('Test aus LEVEL3');
    2: writeln(10 div zero);
    3: RunError(201);
  end;
end;

procedure level2(mode: longint);
begin
  level3(mode);
end;

procedure level1(mode: longint);
begin
  level2(mode);
end;

function exception_trace: string;
var
  i: longint;
  frames: PCodePointer;
begin
  result := BackTraceStrFunc(ExceptAddr) + LineEnding;
  frames := ExceptFrames;
  for i := 0 to ExceptFrameCount - 1 do
    result := result + BackTraceStrFunc(frames[i]) + LineEnding;
end;

function has_order(const s: string; const names: array of string): boolean;
var
  i, p, q: longint;
begin
  result := true;
  p := 0;
  for i := 0 to high(names) do
    begin
      q := Pos(names[i], s);
      if (q = 0) or (q < p) then
        exit(false);
      p := q;
    end;
end;

begin
  if ParamStr(1) = 'div' then
    level1(2)
  else if ParamStr(1) = 'runerror' then
    level1(3)
  else
    begin
      level1(0);
      write(captured);
      check('CaptureBacktrace: LEVEL3, LEVEL2, LEVEL1, PASCALMAIN',
        has_order(captured, ['LEVEL3', 'LEVEL2', 'LEVEL1', 'PASCALMAIN']));
      try
        level1(1);
      except
        on e: Exception do
          excepttrace := exception_trace;
      end;
      write(excepttrace);
      check('Ausnahme: Adresse in LEVEL3, dann LEVEL2, LEVEL1, PASCALMAIN',
        has_order(excepttrace, ['LEVEL3', 'LEVEL2', 'LEVEL1', 'PASCALMAIN']));
      writeln('Fehler: ', errors);
      halt(errors);
    end;
end.
