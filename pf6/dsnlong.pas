program dsnlong;
{ PF6: zu lange Zeile in einem FB-Dataset (neu angelegt und vorhanden) }
{$mode objfpc}{$H+}{$I-}
var
  t: text;
  s: string;
  r: longint;

procedure show;
begin
  reset(t);
  while not eof(t) do
    begin
      readln(t, s);
      writeln('  Satz: ', length(s), ' Zeichen');
    end;
  close(t);
end;

begin
  assign(t, '//ZPAS.TEST.LONG,recfm=fb,lrecl=80,space=(trk,(1,1))');
  rewrite(t);
  writeln(t, 'kurz');
  close(t);
  r := ioresult;
  writeln('neu angelegt, close: ', r);
  assign(t, '//ZPAS.TEST.LONG');
  rewrite(t);
  writeln(t, StringOfChar('x', 100));
  close(t);
  r := ioresult;
  writeln('vorhanden, lange Zeile, close: ', r);
  show;
  erase(t);
  r := ioresult;
  writeln('erase: ', r);
end.
