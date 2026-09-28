program niltest;
{ Lesezugriff über nil: ohne Prüfung liest z/OS still aus der PSA (ab Adresse 0).
  Mit -gc -gh (heaptrc, Zeigerprüfung) bricht das Programm ab:
    niltest ok    nur gültige Zugriffe (Heap, global, Stack, C-Speicher) -> rc 0
    niltest       Zugriff über nil                                       -> Laufzeitfehler 204
    niltest psa   Zeiger in die PSA (z. B. nil + Feldoffset)              -> Laufzeitfehler 216
  Ohne -gc: rc 3 (nicht erkannt). }
{$mode objfpc}
uses
  ctypes;

type
  PRec = ^TRec;
  TRec = record a, b: longint; end;

function malloc(n: csize_t): pointer; cdecl; external 'c';
procedure free(p: pointer); cdecl; external 'c';

var
  g: longint = 5;
  p: PRec;
  q: PLongint;
  l, s: longint;
  arg: shortstring;
begin
  arg := ParamStr(1);
  new(p); p^.a := 1; p^.b := 2;
  q := @g;
  s := p^.a + p^.b + q^;
  q := @l; l := 4; s := s + q^;
  q := malloc(4); q^ := 30; s := s + q^; free(q);
  dispose(p);
  writeln('gueltige Zugriffe: ', s);
  if arg = 'ok' then halt(0);
  if arg = 'psa' then
    q := PLongint(PtrUInt($10))
  else
    q := nil;
  writeln('Lesezugriff: ', q^);
  writeln('nicht erkannt');
  halt(3);
end.
