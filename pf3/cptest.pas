program cptest;
{ PF3: Codepage-Umwandlung über cwstring/iconv auf z/OS }
{$mode objfpc}{$H+}
uses cwstring;
type
  tcp1253 = type AnsiString(1253);
var
  a1: tcp1253;
  a2: utf8string;
  u: unicodestring;
  i: longint;
begin
  writeln('DefaultSystemCodePage=', DefaultSystemCodePage);
  a1 := ' ';
  a1[1] := char($80);  { Euro in cp1253 }
  u := a1;
  write('cp1253 -> UTF-16: len ', length(u), ':');
  for i := 1 to length(u) do write(' ', hexstr(ord(u[i]), 4));
  writeln;
  a2 := a1;
  write('cp1253 -> UTF-8: len ', length(a2), ':');
  for i := 1 to length(a2) do write(' ', hexstr(ord(a2[i]), 2));
  writeln;
  u := 'Ä€';
  a2 := u;
  write('UTF-16 -> UTF-8:');
  for i := 1 to length(a2) do write(' ', hexstr(ord(a2[i]), 2));
  writeln;
end.
