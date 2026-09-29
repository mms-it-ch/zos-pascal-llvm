unit nsunit;
{$MODE DELPHI}
interface
uses SysUtils, Classes;   // ohne Namensraum: über -FNSystem
function Joined(L: TStrings): string;
implementation
function Joined(L: TStrings): string;
begin
  Result := UpperCase(L.CommaText);
end;
end.
