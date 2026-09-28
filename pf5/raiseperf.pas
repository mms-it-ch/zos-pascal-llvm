program raiseperf;
{ Kosten von raise/except (mit Backtrace über __le_traceback): 20000 Ausnahmen
  aus Tiefe 5 }
{$mode objfpc}{$H+}
uses SysUtils;

procedure d(n: longint);
begin
  if n = 0 then raise Exception.Create('x') else d(n - 1);
end;

var
  i: longint;
  t: QWord;
begin
  t := GetTickCount64;
  for i := 1 to 20000 do
    try
      d(5);
    except
    end;
  writeln('20000 Ausnahmen aus Tiefe 5: ', GetTickCount64 - t, ' ms');
end.
