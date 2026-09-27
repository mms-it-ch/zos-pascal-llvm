program pf4exc;
{ PF4: Ausnahme in der DLL, im Programm gefangen (eigene RTL je Modul: nur
  "except" ohne Klassenauswahl, wie bei FPC-DLLs auf anderen Zielen) }
{$mode objfpc}{$H+}
procedure pf4_raise; cdecl; external 'pf4lib';
function pf4_add(a, b: longint): longint; cdecl; external 'pf4lib';

var
  caught: boolean = false;
begin
  try
    pf4_raise;
    writeln('FEHLER  keine Ausnahme');
  except
    caught := true;
  end;
  if caught then writeln('OK      Ausnahme aus der DLL gefangen')
  else writeln('FEHLER  Ausnahme nicht gefangen');
  if pf4_add(1, 1) = 2 then writeln('OK      DLL danach weiter benutzbar')
  else caught := false;
  if caught then halt(0) else halt(1);
end.
