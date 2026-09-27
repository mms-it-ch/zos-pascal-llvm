program pf4dyn;
{ PF4: DLL pf4lib zur Laufzeit laden (dynlibs: dlopen/dlsym) }
{$mode objfpc}{$H+}
uses SysUtils, dynlibs;
type
  tadd = function(a, b: longint): longint; cdecl;
  tcalls = function: longint; cdecl;
var
  h: TLibHandle;
  add: tadd;
  calls: tcalls;
  errors: longint = 0;

procedure check(const what: string; ok: boolean);
begin
  if ok then writeln('OK      ', what)
  else begin writeln('FEHLER  ', what); inc(errors); end;
end;

begin
  h := LoadLibrary('libpf4lib.so');
  check('LoadLibrary', h <> NilHandle);
  if h = NilHandle then
    begin
      writeln('  ', GetLoadErrorStr);
      halt(1);
    end;
  add := tadd(GetProcedureAddress(h, 'pf4_add'));
  calls := tcalls(GetProcedureAddress(h, 'pf4_calls'));
  check('pf4_add gefunden', assigned(add));
  check('interne Funktion nicht exportiert', GetProcedureAddress(h, 'fpc_ansistr_assign') = nil);
  if assigned(add) then
    check('pf4_add(20, 22) = 42', add(20, 22) = 42);
  if assigned(calls) then
    check('calls = 101', calls() = 101);
  check('UnloadLibrary', UnloadLibrary(h));
  writeln('Fehler: ', errors);
  halt(errors);
end.
