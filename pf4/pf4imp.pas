program pf4imp;
{ PF4: Programm, das die DLL pf4lib beim Binden über ihr Sidedeck einbindet }
{$mode objfpc}{$H+}
const
  lib = 'pf4lib';
function pf4_add(a, b: longint): longint; cdecl; external lib;
function pf4_greeting(const name: PAnsiChar): PAnsiChar; cdecl; external lib;
function pf4_calls: longint; cdecl; external lib;

var
  errors: longint = 0;

procedure check(const what: string; ok: boolean);
begin
  if ok then writeln('OK      ', what)
  else begin writeln('FEHLER  ', what); inc(errors); end;
end;

begin
  check('DLL initialisiert (calls = 100)', pf4_calls = 100);
  check('pf4_add(2, 40) = 42', pf4_add(2, 40) = 42);
  check('pf4_greeting', string(pf4_greeting('z/OS')) = 'Hallo Z/OS aus der DLL');
  check('pf4_calls = 102', pf4_calls = 102);
  writeln('Fehler: ', errors);
  halt(errors);
end.
