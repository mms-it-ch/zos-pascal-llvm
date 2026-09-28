program btthr;
{ Backtrace einer Ausnahme in einem Thread und in einem Callback, den die
  C-Bibliothek ruft (qsort): der Stack-Durchlauf muss am Ende des Thread-Stacks
  bzw. in LE-Frames sauber aufhören. Returncode = Anzahl Fehler. }
{$mode objfpc}{$H+}
uses cthreads, SysUtils, Classes;

var
  errors: longint = 0;

procedure check(const what: string; ok: boolean);
begin
  if ok then writeln('OK      ', what)
  else begin writeln('FEHLER  ', what); inc(errors); end;
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

var
  thrtrace, cbtrace: string;

procedure thrlevel2;
begin
  raise Exception.Create('im Thread');
end;

function thrfunc(p: pointer): ptrint;
begin
  try
    thrlevel2;
  except
    thrtrace := exception_trace;
  end;
  result := 0;
end;

procedure qsort(base: pointer; n, size: SizeUInt; cmp: pointer); cdecl; external 'c' name 'qsort';

function cmp(a, b: pointer): longint; cdecl;
begin
  raise Exception.Create('im qsort-Callback');
end;

var
  t: TThreadID;
  arr: array[0..3] of longint = (4, 3, 2, 1);
begin
  t := BeginThread(@thrfunc, nil);
  WaitForThreadTerminate(t, 0);
  write(thrtrace);
  check('Thread: THRLEVEL2, THRFUNC', (Pos('THRLEVEL2', thrtrace) > 0) and (Pos('THRFUNC', thrtrace) > 0));
  try
    qsort(@arr[0], 4, sizeof(longint), @cmp);
  except
    cbtrace := exception_trace;
  end;
  write(cbtrace);
  check('qsort-Callback: CMP, PASCALMAIN', (Pos('CMP', cbtrace) > 0) and (Pos('PASCALMAIN', cbtrace) > 0));
  writeln('Fehler: ', errors);
  halt(errors);
end.
