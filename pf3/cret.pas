program cret;
{ PF3: C-ABI - Records als Funktionsergebnis (XPLINK). Returncode = Anzahl Fehler. }
{$mode objfpc}
{$L cret_c.o}
type
  r8 = record a, b: longint; end;
  r16 = record a, b: int64; end;
  r24 = record a, b, c: int64; end;

function cret8(x: longint): r8; cdecl; external;
function cret16(x: int64): r16; cdecl; external;
function cret24(x: int64): r24; cdecl; external;
function call_pret16(x: int64): int64; cdecl; external;

function pret16(x: int64): r16; cdecl; public name 'pret16';
begin
  result.a := x + 1;
  result.b := x + 2;
end;

var
  errors: longint = 0;

procedure check(const what: string; ok: boolean);
begin
  if ok then writeln('OK      ', what)
  else begin writeln('FEHLER  ', what); inc(errors); end;
end;

var
  a: r8; b: r16; c: r24;
begin
  a := cret8(7);
  check('cret8', (a.a = 7) and (a.b = 8));
  b := cret16(5);
  check('cret16', (b.a = 5) and (b.b = -5));
  c := cret24(3);
  check('cret24', (c.a = 3) and (c.b = 6) and (c.c = 9));
  check('C ruft Pascal pret16', call_pret16(10) = 11 * 1000 + 12);
  writeln('Fehler: ', errors);
  halt(errors);
end.
