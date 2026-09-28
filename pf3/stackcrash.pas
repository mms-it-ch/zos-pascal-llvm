program stackcrash;
{ Probe: zerstört die Rückwärtskette des Stacks und greift dann über nil zu.
  Mit TERMTHDACT(TRACE) (Standard) läuft LE beim Traceback in den zerstörten
  Stack (U4083, Systemdump); die Testsuite läuft deshalb mit TERMTHDACT(MSG).
  Nur mit ZOS_RUN_CEEOPTS="TERMTHDACT(MSG)" starten. }
{$mode objfpc}{$R-}
procedure smash;
var
  a: array[0..15] of int64;
  p: pint64;
  i: longint;
begin
  { über das Ende der lokalen Variablen hinaus in die Frames der Aufrufer }
  p := @a[0];
  for i := 0 to 4095 do
    begin
      p^ := 0;
      inc(p);
    end;
  pint64(nil)^ := 1;
end;

begin
  smash;
end.
