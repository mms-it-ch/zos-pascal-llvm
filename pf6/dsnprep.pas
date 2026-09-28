program dsnprep;
{ PF6: Eingabe-Dataset für dsnbat anlegen (VB, drei Zeilen), vorherige Ausgaben löschen }
{$mode objfpc}{$H+}{$I-}
var
  t: text;
begin
  assign(t, '//ZPAS.TEST.PRINT');   erase(t);   ioresult;
  assign(t, '//ZPAS.TEST.OUTDATA'); erase(t);   ioresult;
  assign(t, '//ZPAS.TEST.INDATA,recfm=vb,lrecl=255,space=(trk,(1,1))');
  rewrite(t);
  writeln(t, 'erste zeile aus indata');
  writeln(t, 'zweite: äöü');
  writeln(t, 'dritte');
  close(t);
  if ioresult <> 0 then
    halt(1);
end.
