program dsnshow;
{ PF6: Ausgabe-Datasets von dsnbat zeigen und alle Test-Datasets löschen }
{$mode objfpc}{$H+}{$I-}

procedure show(const name: string);
var
  t: text;
  s: string;
begin
  writeln('=== ', name);
  assign(t, name);
  reset(t);
  if ioresult <> 0 then
    begin
      writeln('(nicht vorhanden)');
      exit;
    end;
  while not eof(t) do
    begin
      readln(t, s);
      writeln('| ', s);
    end;
  close(t);
  erase(t);
  ioresult;
end;

var
  t: text;
begin
  show('//ZPAS.TEST.PRINT');
  show('//ZPAS.TEST.OUTDATA');
  assign(t, '//ZPAS.TEST.INDATA');
  erase(t);
  ioresult;
end.
