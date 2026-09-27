program hello;
{$mode objfpc}
{ PF0-Gegenprobe: Klassen, AnsiString, Format, Exceptions, RC }
uses sysutils;

type
  TFoo = class
    n: integer;
    function Twice: integer;
  end;

function TFoo.Twice: integer;
begin
  result := 2 * n;
end;

var
  f: TFoo;
  s: ansistring;
  i: integer;
begin
  f := TFoo.Create;
  f.n := 21;
  s := Format('Hello from FPC/LLVM: %d', [f.Twice]);
  writeln(s);
  try
    raise Exception.Create('boom');
  except
    on e: Exception do writeln('caught: ', e.Message);
  end;
  for i := 1 to 3 do write(i, ' ');
  writeln;
  f.Free;
  halt(42);
end.
