program dbgtest;
{ Testprogramm für den z/OS-Debugger (VS-Code-Erweiterung): zweiter Thread, Standardeingabe,
  Ausgabe Zeile für Zeile, Ausdrücke mit Feldern, Indizes und Zeigern
  (pt.x, arr[3], pp^.y, foo.name). }
{$mode objfpc}{$H+}
uses
  cthreads, Classes, SysUtils;

type
  TPt = record
    x, y: longint;
  end;
  PPt = ^TPt;

  TFoo = class
    name: string;
    count: integer;
  end;

  TWorker = class(TThread)
    procedure Execute; override;
  end;

var
  arr: array[1..5] of longint;
  pt: TPt;
  pp: PPt;
  foo: TFoo;
  s: string;
  i: integer;
  total: longint = 0;

procedure TWorker.Execute;
var
  k: integer;
begin
  for k := 1 to 3 do
  begin
    writeln('Thread ', k);
    inc(total, k);
    sleep(200);
  end;
end;

begin
  for i := 1 to 5 do
    arr[i] := i * i;
  pt.x := 3;
  pt.y := 4;
  new(pp);
  pp^ := pt;
  foo := TFoo.Create;
  foo.name := 'Hallo';
  foo.count := 7;
  writeln('Zeile 1');
  writeln('Zeile 2');
  write('Name? ');
  readln(s);
  writeln('Gelesen: ', s);
  with TWorker.Create(false) do
  begin
    WaitFor;
    Free;
  end;
  writeln('Summe aus dem Thread: ', total);
  foo.Free;
  dispose(pp);
  writeln('Ende');
end.
