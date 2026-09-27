program pf4bat;
{ PF4: Pascal-Programm als Batch-Job (PDSE-Member PF4BAT, JCL mit POSIX(ON)) }
{$mode objfpc}{$H+}
uses SysUtils;
var
  i: longint;
  s: string;
begin
  writeln('Pascal im Batch auf z/OS');
  writeln('Parameter: ', ParamCount);
  for i := 1 to ParamCount do
    writeln('  ', i, ': ', ParamStr(i));
  s := Format('%d * %d = %d', [6, 7, 6 * 7]);
  writeln(s);
  try
    raise Exception.Create('Test');
  except
    on e: Exception do writeln('Ausnahme gefangen: ', e.Message);
  end;
  halt(ParamCount + 3);
end.
