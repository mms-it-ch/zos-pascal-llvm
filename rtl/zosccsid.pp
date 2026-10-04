{
    zos-pascal-llvm: Umwandlung ISO-8859-1 <-> EBCDIC für die CECP-Codepages
    (CCSID 1047, 37, 273, 277, 278, 280, 284, 285, 297, 500, 871 und die Euro-Varianten
    1140-1149).

    Reines Pascal ohne z/OS-Aufrufe: läuft auch auf anderen Plattformen (Tests auf x86_64,
    Aufbereiten von EBCDIC-Daten ausserhalb von z/OS). Die Tabellen erzeugt
    scripts/gen-ccsid.py (zosccsid.inc) aus den IBM-Zuordnungen der ICU, dieselben wie in
    runtime/zosccsid.h für die Dataset-Schicht.

    - ASCII-Seite ist ISO-8859-1 (Codepage der RTL im ASCII-Modus). Bei den Euro-Varianten
      liegt das Euro-Zeichen dort auf X'A4' (Stelle des Euro in ISO-8859-15).
    - Zeilenende wie unter z/OS UNIX: LF <-> NL X'15'.

    Siehe COPYING.FPC (LGPL mit Ausnahme für statisches Binden).
}
unit zosccsid;

{$mode objfpc}{$H+}

interface

uses
{$ifdef FPC_DOTTEDUNITS}
  System.SysUtils;
{$else}
  sysutils;
{$endif}

type
  ECcsidError = class(Exception);
  TCcsidTable = array[0..255] of byte;
  PCcsidTable = ^TCcsidTable;

const
  { Standard der Dataset-Schicht (z/OS UNIX, Open Systems) }
  CcsidDefault = 1047;
  { Codepage-Nummer der RTL für ISO-8859-1 }
  CP_ISO_8859_1 = 28591;

{ unterstützte CCSIDs }
function CcsidSupported(ccsid: longint): boolean;
function CcsidCount: longint;
function CcsidByIndex(i: longint): longint;
{ Tabellen (nil, wenn die CCSID unbekannt ist) }
function CcsidA2ETable(ccsid: longint): PCcsidTable;
function CcsidE2ATable(ccsid: longint): PCcsidTable;

{ an Ort und Stelle umwandeln; unbekannte CCSID -> ECcsidError }
procedure AsciiToEbcdicBuf(var buf; len: SizeInt; ccsid: longint);
procedure EbcdicToAsciiBuf(var buf; len: SizeInt; ccsid: longint);
{ Zeichenketten: Ergebnis ISO-8859-1 (Codepage 28591) bzw. EBCDIC (CP_NONE) }
function AsciiToEbcdicStr(const s: RawByteString; ccsid: longint): RawByteString;
function EbcdicToAsciiStr(const s: RawByteString; ccsid: longint): RawByteString;

{ Felder fester Länge (Copybook PIC X): wie COBOL MOVE linksbündig, rechts mit EBCDIC-
  Leerzeichen aufgefüllt, zu lange Werte rechts abgeschnitten }
procedure StrToEbcdicField(const s: RawByteString; var field; len: SizeInt; ccsid: longint);
{ Feld -> Zeichenkette (ISO-8859-1); TrimRight: nachgestellte Leerzeichen entfernen }
function EbcdicFieldToStr(const field; len: SizeInt; ccsid: longint;
  TrimRight: boolean = true): RawByteString;

implementation

{$i zosccsid.inc}

function IndexOfCcsid(ccsid: longint): longint;
var
  i: longint;
begin
  for i:=0 to CcsidTableCount-1 do
    if CcsidList[i]=ccsid then
      exit(i);
  result:=-1;
end;

function CcsidSupported(ccsid: longint): boolean;
begin
  result:=IndexOfCcsid(ccsid)>=0;
end;

function CcsidCount: longint;
begin
  result:=CcsidTableCount;
end;

function CcsidByIndex(i: longint): longint;
begin
  if (i<0) or (i>=CcsidTableCount) then
    raise ECcsidError.CreateFmt('CCSID-Index %d außerhalb 0..%d', [i, CcsidTableCount-1]);
  result:=CcsidList[i];
end;

function CcsidA2ETable(ccsid: longint): PCcsidTable;
var
  i: longint;
begin
  i:=IndexOfCcsid(ccsid);
  if i<0 then
    exit(nil);
  result:=PCcsidTable(@CcsidA2E[i]);
end;

function CcsidE2ATable(ccsid: longint): PCcsidTable;
var
  i: longint;
begin
  i:=IndexOfCcsid(ccsid);
  if i<0 then
    exit(nil);
  result:=PCcsidTable(@CcsidE2A[i]);
end;

function NeedTable(t: PCcsidTable; ccsid: longint): PCcsidTable;
begin
  if t=nil then
    raise ECcsidError.CreateFmt('CCSID %d wird nicht unterstützt', [ccsid]);
  result:=t;
end;

procedure Translate(var buf; len: SizeInt; const t: TCcsidTable);
var
  p: PByte;
  i: SizeInt;
begin
  p:=@buf;
  for i:=0 to len-1 do
    p[i]:=t[p[i]];
end;

procedure AsciiToEbcdicBuf(var buf; len: SizeInt; ccsid: longint);
begin
  Translate(buf, len, NeedTable(CcsidA2ETable(ccsid), ccsid)^);
end;

procedure EbcdicToAsciiBuf(var buf; len: SizeInt; ccsid: longint);
begin
  Translate(buf, len, NeedTable(CcsidE2ATable(ccsid), ccsid)^);
end;

function AsciiToEbcdicStr(const s: RawByteString; ccsid: longint): RawByteString;
var
  t: PCcsidTable;
begin
  t:=NeedTable(CcsidA2ETable(ccsid), ccsid);
  result:=s;
  UniqueString(result);
  SetCodePage(result, CP_NONE, false);
  if length(result)>0 then
    Translate(result[1], length(result), t^);
end;

function EbcdicToAsciiStr(const s: RawByteString; ccsid: longint): RawByteString;
var
  t: PCcsidTable;
begin
  t:=NeedTable(CcsidE2ATable(ccsid), ccsid);
  result:=s;
  UniqueString(result);
  SetCodePage(result, CP_ISO_8859_1, false);
  if length(result)>0 then
    Translate(result[1], length(result), t^);
end;

procedure StrToEbcdicField(const s: RawByteString; var field; len: SizeInt; ccsid: longint);
var
  t: PCcsidTable;
  p: PByte;
  i, n: SizeInt;
begin
  t:=NeedTable(CcsidA2ETable(ccsid), ccsid);
  p:=@field;
  n:=length(s);
  if n>len then
    n:=len;
  for i:=0 to n-1 do
    p[i]:=t^[byte(s[i+1])];
  for i:=n to len-1 do
    p[i]:=t^[32];
end;

function EbcdicFieldToStr(const field; len: SizeInt; ccsid: longint;
  TrimRight: boolean): RawByteString;
var
  t: PCcsidTable;
  p: PByte;
  i, n: SizeInt;
begin
  t:=NeedTable(CcsidE2ATable(ccsid), ccsid);
  p:=@field;
  n:=len;
  if TrimRight then
    while (n>0) and (t^[p[n-1]]=32) do
      dec(n);
  SetLength(result, n);
  SetCodePage(result, CP_ISO_8859_1, false);
  for i:=0 to n-1 do
    result[i+1]:=AnsiChar(t^[p[i]]);
end;

end.
