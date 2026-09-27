program atomperf;
{ PF3: Geschwindigkeit atomarer Operationen und einfacher Schleifen (1 Thread) }
{$mode objfpc}
uses SysUtils;
var
  c: longint = 0;
  i, n: longint;
  t: QWord;
  s: int64 = 0;
begin
  n := 10000000;
  t := GetTickCount64;
  for i := 1 to n do
    InterLockedIncrement(c);
  writeln('InterLockedIncrement: ', n, ' in ', GetTickCount64 - t, ' ms');
  t := GetTickCount64;
  for i := 1 to n do
    s := s + i xor (s shr 3);
  writeln('einfache Schleife:    ', n, ' in ', GetTickCount64 - t, ' ms (', s, ')');
  if c <> n then halt(1);
end.
