{
    zos-pascal-llvm: Feldzugriffe für Sätze aus COBOL-Copybooks (scripts/copybook2pas.py).

    Die erzeugten Records bestehen nur aus Byte-Feldern (packed, genaue Offsets wie im
    COBOL-Programm); die Werte liest und schreibt man über diese Routinen:
      - Text (PIC X/A, alphanumerisch editiert): EBCDIC je CCSID (Unit zosccsid)
      - PIC N (NATIONAL): UTF-16 Big-Endian
      - gezont/gepackt (DISPLAY, COMP-3): Unit zosdecimal
      - binär (COMP, COMP-4, BINARY, COMP-5): Big-Endian wie auf z/OS; COMP/COMP-4/BINARY
        mit Prüfung der PIC-Stellen beim Schreiben (wie TRUNC(STD)), COMP-5 ohne
      - COMP-1/COMP-2: auf z/OS meist hexadezimales Gleitkomma (HFP, COBOL FLOAT(HEX),
        Standard), Pascal rechnet mit IEEE-754: Umwandlung HfpToDouble/DoubleToHfp; mit
        COBOL FLOAT(IEEE) übersetzte Programme benutzen IEEE (Big-Endian)

    Byteweise und damit unabhängig von der Byte-Reihenfolge des Rechners (Tests auf x86_64).

    Siehe COPYING.FPC (LGPL mit Ausnahme für statisches Binden).
}
unit zoscobol;

{$mode objfpc}{$H+}
{$R-}{$Q-}

interface

uses
{$ifdef FPC_DOTTEDUNITS}
  System.SysUtils, System.Math,
{$else}
  sysutils, math,
{$endif}
  zosccsid, zosdecimal;

type
  ECobolField = class(Exception);

{ Text }
function CobGetText(const f; len: SizeInt; ccsid: longint; TrimRight: boolean = true): RawByteString;
procedure CobSetText(var f; len: SizeInt; const s: RawByteString; ccsid: longint);
{ PIC N: nchars UTF-16-Zeichen (Big-Endian), rechts mit Leerzeichen U+0020 }
function CobGetNational(const f; nchars: SizeInt; TrimRight: boolean = true): UnicodeString;
procedure CobSetNational(var f; nchars: SizeInt; const s: UnicodeString);

{ binär, Big-Endian, size 2/4/8 Byte; digits > 0: Prüfung |v| < 10^digits beim
  Schreiben (COMP/COMP-4/BINARY), digits = 0: nur Bereich des Felds (COMP-5) }
function CobGetBinary(const f; size: integer; signed: boolean): Int64;
procedure CobSetBinary(var f; size: integer; signed: boolean; v: Int64; digits: integer = 0);
{ mit Nachkommastellen (PIC S9(5)V99 COMP) }
function CobGetBinaryDec(const f; size: integer; signed: boolean; scale: integer): TDecimal;
procedure CobSetBinaryDec(var f; size: integer; signed: boolean; scale, digits: integer;
  const v: TDecimal; rounding: TDecRounding = drTruncate);

{ hexadezimales Gleitkomma (IBM HFP): size 4 (COMP-1) oder 8 (COMP-2) }
function HfpToDouble(const f; size: integer): double;
procedure DoubleToHfp(v: double; var f; size: integer);
{ IEEE-754 Big-Endian (COBOL FLOAT(IEEE)) }
function IeeeBEToDouble(const f; size: integer): double;
procedure DoubleToIeeeBE(v: double; var f; size: integer);

implementation

function CobGetText(const f; len: SizeInt; ccsid: longint; TrimRight: boolean): RawByteString;
begin
  result:=EbcdicFieldToStr(f,len,ccsid,TrimRight);
end;

procedure CobSetText(var f; len: SizeInt; const s: RawByteString; ccsid: longint);
begin
  StrToEbcdicField(s,f,len,ccsid);
end;

function CobGetNational(const f; nchars: SizeInt; TrimRight: boolean): UnicodeString;
var
  p: PByte;
  i, n: SizeInt;
begin
  p:=@f;
  n:=nchars;
  if TrimRight then
    while (n>0) and (p[2*n-2]=0) and (p[2*n-1]=$20) do
      dec(n);
  SetLength(result,n);
  for i:=0 to n-1 do
    result[i+1]:=WideChar((p[2*i] shl 8) or p[2*i+1]);
end;

procedure CobSetNational(var f; nchars: SizeInt; const s: UnicodeString);
var
  p: PByte;
  i: SizeInt;
  c: word;
begin
  p:=@f;
  for i:=0 to nchars-1 do
    begin
      if i<length(s) then
        c:=word(s[i+1])
      else
        c:=$20;
      p[2*i]:=c shr 8;
      p[2*i+1]:=c and $FF;
    end;
end;

procedure CheckSize(size: integer);
begin
  if not (size in [2,4,8]) then
    raise ECobolField.CreateFmt('Binärfeld mit %d Byte (2, 4 oder 8)', [size]);
end;

function CobGetBinary(const f; size: integer; signed: boolean): Int64;
var
  p: PByte;
  u: QWord;
  i: integer;
begin
  CheckSize(size);
  p:=@f;
  u:=0;
  for i:=0 to size-1 do
    u:=(u shl 8) or p[i];
  if signed and (size<8) and ((p[0] and $80)<>0) then
    u:=u or (not QWord(0) shl (8*size));   { Vorzeichen erweitern }
  result:=Int64(u);
  if not signed and (size=8) and (result<0) then
    raise EDecimalOverflow.Create('Binärfeld ohne Vorzeichen größer als High(Int64)');
end;

function Pow10(n: integer): QWord;
begin
  result:=1;
  while n>0 do
    begin
      result:=result*10;
      dec(n);
    end;
end;

procedure CobSetBinary(var f; size: integer; signed: boolean; v: Int64; digits: integer);
var
  p: PByte;
  u, m: QWord;
  i: integer;
  ok: boolean;
begin
  CheckSize(size);
  if v<0 then
    m:=QWord(-(v+1))+1
  else
    m:=QWord(v);
  if (v<0) and not signed then
    raise EDecimalOverflow.CreateFmt('negativer Wert %d in Binärfeld ohne Vorzeichen', [v]);
  if (digits>0) and (digits<20) and (m>=Pow10(digits)) then
    raise EDecimalOverflow.CreateFmt('%d hat mehr als %d Stellen', [v, digits]);
  case size of
    2: if signed then ok:=(v>=-32768) and (v<=32767) else ok:=v<=65535;
    4: if signed then ok:=(v>=-2147483648) and (v<=2147483647) else ok:=v<=4294967295;
  else
    ok:=true;
  end;
  if not ok then
    raise EDecimalOverflow.CreateFmt('%d passt nicht in %d Byte', [v, size]);
  p:=@f;
  u:=QWord(v);
  for i:=size-1 downto 0 do
    begin
      p[i]:=u and $FF;
      u:=u shr 8;
    end;
end;

function CobGetBinaryDec(const f; size: integer; signed: boolean; scale: integer): TDecimal;
begin
  result:=TDecimal.FromUnscaled(CobGetBinary(f,size,signed),scale);
end;

procedure CobSetBinaryDec(var f; size: integer; signed: boolean; scale, digits: integer;
  const v: TDecimal; rounding: TDecRounding);
begin
  CobSetBinary(f,size,signed,v.ToUnscaled(scale,rounding),digits);
end;

{ HFP: Bit 0 Vorzeichen, Bits 1-7 Exponent zur Basis 16 (Überschuss 64), dann der Bruch
  (24 bzw. 56 Bit): Wert = 0.Bruch * 16^(Exponent-64) }
function HfpToDouble(const f; size: integer): double;
var
  p: PByte;
  frac: QWord;
  i, bits, e: integer;
begin
  if not (size in [4,8]) then
    raise ECobolField.CreateFmt('HFP mit %d Byte (4 oder 8)', [size]);
  p:=@f;
  frac:=0;
  for i:=1 to size-1 do
    frac:=(frac shl 8) or p[i];
  bits:=8*(size-1);
  e:=p[0] and $7F;
  if frac=0 then
    result:=0
  else
    result:=ldexp(double(frac),4*(e-64)-bits);
  if (p[0] and $80)<>0 then
    result:=-result;
end;

procedure DoubleToHfp(v: double; var f; size: integer);
var
  p: PByte;
  m: float;
  e2, k, bits, i: integer;
  frac: QWord;
  neg: boolean;
begin
  if not (size in [4,8]) then
    raise ECobolField.CreateFmt('HFP mit %d Byte (4 oder 8)', [size]);
  if IsNan(v) or IsInfinite(v) then
    raise EDecimalOverflow.Create('NaN/Unendlich hat keine HFP-Darstellung');
  p:=@f;
  FillChar(p^,size,0);
  if v=0 then
    exit;
  neg:=v<0;
  v:=system.abs(v);
  bits:=8*(size-1);
  { v = m * 2^e2, 0.5 <= m < 1;  gesucht v = g * 16^k, 1/16 <= g < 1 }
  Frexp(v,m,e2);
  { k = aufgerundet e2/4 (div schneidet zur Null ab) }
  k:=e2 div 4;
  if 4*k<e2 then
    inc(k);
  { g = v / 16^k = m * 2^(e2-4k) }
  frac:=QWord(round(ldexp(m,e2-4*k+bits)));
  if frac>=(QWord(1) shl bits) then
    begin
      frac:=frac shr 4;
      inc(k);
    end;
  if k+64>127 then
    raise EDecimalOverflow.CreateFmt('%g ist zu groß für HFP', [v]);
  if k+64<0 then
    exit;   { Unterlauf: 0 }
  p[0]:=(k+64) and $7F;
  if neg then
    p[0]:=p[0] or $80;
  for i:=size-1 downto 1 do
    begin
      p[i]:=frac and $FF;
      frac:=frac shr 8;
    end;
end;

function IeeeBEToDouble(const f; size: integer): double;
var
  p: PByte;
  u: QWord;
  d: longword;
  i: integer;
  s: single;
begin
  p:=@f;
  case size of
    4:
      begin
        d:=0;
        for i:=0 to 3 do
          d:=(d shl 8) or p[i];
        s:=PSingle(@d)^;
        result:=s;
      end;
    8:
      begin
        u:=0;
        for i:=0 to 7 do
          u:=(u shl 8) or p[i];
        result:=PDouble(@u)^;
      end;
  else
    raise ECobolField.CreateFmt('IEEE mit %d Byte (4 oder 8)', [size]);
  end;
end;

procedure DoubleToIeeeBE(v: double; var f; size: integer);
var
  p: PByte;
  u: QWord;
  d: longword;
  s: single;
  i: integer;
begin
  p:=@f;
  case size of
    4:
      begin
        s:=v;
        d:=PLongWord(@s)^;
        for i:=3 downto 0 do
          begin
            p[i]:=d and $FF;
            d:=d shr 8;
          end;
      end;
    8:
      begin
        u:=PQWord(@v)^;
        for i:=7 downto 0 do
          begin
            p[i]:=u and $FF;
            u:=u shr 8;
          end;
      end;
  else
    raise ECobolField.CreateFmt('IEEE mit %d Byte (4 oder 8)', [size]);
  end;
end;

end.
