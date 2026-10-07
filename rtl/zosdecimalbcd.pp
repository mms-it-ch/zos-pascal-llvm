{
    zos-pascal-llvm: TDecimal (Unit zosdecimal) <-> TBCD (Unit fmtbcd, Datenbanken).

    Eigene Unit, weil fmtbcd die Unit variants mitbringt. Die Umwandlung geht über die
    Zeichenkettenform (Punkt als Trennzeichen) und ist damit unabhängig vom Aufbau des
    TBCD-Records; der Scale bleibt erhalten.

    Siehe COPYING.FPC (LGPL mit Ausnahme für statisches Binden).
}
unit zosdecimalbcd;

{$mode objfpc}{$H+}

interface

uses
{$ifdef FPC_DOTTEDUNITS}
  System.SysUtils, Data.FMTBcd, zosdecimal;
{$else}
  sysutils, fmtbcd, zosdecimal;
{$endif}

function DecimalToBCD(const d: TDecimal): TBCD;
{ Scale = BCDScale(b); mehr als DecMaxDigits Stellen -> EDecimalOverflow }
function BCDToDecimal(const b: TBCD): TDecimal;

implementation

var
  fs: TFormatSettings;

function DecimalToBCD(const d: TDecimal): TBCD;
begin
  result:=StrToBCD(d.ToString('.'),fs);
end;

function BCDToDecimal(const b: TBCD): TDecimal;
var
  s: string;
begin
  s:=BCDToStr(b,fs);
  if not TDecimal.TryFromString(s,result,'.') then
    raise EDecimalOverflow.CreateFmt('BCD-Wert %s passt nicht in TDecimal', [s]);
  if result.Scale<BCDScale(b) then
    result:=result.Rescale(BCDScale(b));
end;

initialization
  fs:=DefaultFormatSettings;
  fs.DecimalSeparator:='.';
  fs.ThousandSeparator:=#0;
end.
