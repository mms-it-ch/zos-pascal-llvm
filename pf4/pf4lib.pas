library pf4lib;
{ PF4: Pascal-DLL für z/OS (exportiert nur die Funktionen aus "exports") }
{$mode objfpc}{$H+}
uses SysUtils;

var
  calls: longint = 0;

function pf4_add(a, b: longint): longint; cdecl;
begin
  inc(calls);
  result := a + b;
end;

function pf4_greeting(const name: PAnsiChar): PAnsiChar; cdecl;
const
  buf: array[0..127] of AnsiChar = '';
begin
  inc(calls);
  StrPLCopy(buf, 'Hallo ' + UpperCase(string(name)) + ' aus der DLL', high(buf));
  result := @buf[0];
end;

function pf4_calls: longint; cdecl;
begin
  result := calls;
end;

procedure pf4_raise; cdecl;
begin
  raise Exception.Create('Ausnahme in der DLL');
end;

exports
  pf4_add, pf4_greeting, pf4_calls, pf4_raise;

begin
  calls := 100;  { Initialisierung der DLL beim Laden }
end.
