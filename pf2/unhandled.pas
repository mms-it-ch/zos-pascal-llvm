program unhandled;
{ PF2: unbehandelte Exception -> Meldung auf stderr, Returncode 217 }
{$mode objfpc}{$H+}
uses SysUtils;
begin
  writeln('vor dem raise');
  raise Exception.Create('niemand faengt mich');
  writeln('nie erreicht');
end.
