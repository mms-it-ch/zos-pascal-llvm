{
    zos-pascal-llvm: gepackte (COMP-3) und gezonte (DISPLAY) Dezimalzahlen

    - TDecimal: Festkommazahl mit bis zu DecMaxDigits Stellen und eigener Zahl von
      Nachkommastellen (Scale); Arithmetik ohne Gleitkomma (Ziffernfelder), Vergleich,
      Umskalieren mit Abschneiden (COBOL-Standard) oder Runden.
    - Felder in Sätzen (Copybooks): gepackt (COMP-3) und gezont (DISPLAY/zoned, EBCDIC),
      beliebige Stellen und Nachkommastellen, mit und ohne Vorzeichen; Vorzeichen-Nibbles
      C (+), D (-), F (ohne Vorzeichen). Lesen prüft die Daten wie die Hardware (S0C7):
      ungültige Ziffer oder ungültiges Vorzeichen -> EDecimalDataError.
    - Umwandlung in/aus Int64, Currency und Zeichenketten; TBCD (fmtbcd): Unit
      zosdecimalbcd.

    Reines Pascal, byteweise: unabhängig von der Byte-Reihenfolge, läuft auf z/OS und
    anderen Plattformen gleich (Tests auf x86_64: tests/run-x86.sh).

    Siehe COPYING.FPC (LGPL mit Ausnahme für statisches Binden).
}
unit zosdecimal;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$R-}{$Q-}

interface

uses
{$ifdef FPC_DOTTEDUNITS}
  System.SysUtils;
{$else}
  sysutils;
{$endif}

const
  { größte Zahl von Stellen eines TDecimal (Koeffizient) }
  DecMaxDigits = 63;

type
  EDecimalError = class(Exception);
  { ungültige gepackte/gezonte Daten (entspricht S0C7) }
  EDecimalDataError = class(EDecimalError);
  { Wert passt nicht ins Ziel (entspricht SIZE ERROR) }
  EDecimalOverflow = class(EDecimalError);
  { Division durch null (entspricht S0CB) }
  EDecimalDivByZero = class(EDecimalError);

  { Umgang mit wegfallenden Nachkommastellen: Abschneiden (COBOL ohne ROUNDED),
    kaufmännisch (ROUNDED, ab 5 weg von null), auf gerade Ziffer (Banker) }
  TDecRounding = (drTruncate, drHalfUp, drHalfEven);

  { Lage des Vorzeichens gezonter Felder: im Zonenteil der letzten bzw. ersten Ziffer
    (SIGN TRAILING/LEADING, Standard), oder als eigenes Zeichen '+'/'-' (SEPARATE) }
  TZonedSign = (zsTrailing, zsLeading, zsTrailingSeparate, zsLeadingSeparate);

  TDecDigits = array[0..DecMaxDigits-1] of byte;

  TDecimal = record
  private
    FDig: TDecDigits;  { Koeffizient, niedrigste Stelle zuerst }
    FScale: byte;      { Nachkommastellen }
    FNeg: boolean;     { nie bei null }
    function GetDigits: integer;
  public
    class function Zero: TDecimal; static;
    { v, ohne Nachkommastellen }
    class function FromInt64(v: Int64): TDecimal; static;
    { v * 10^-scale, z. B. FromUnscaled(12345, 2) = 123.45 }
    class function FromUnscaled(v: Int64; sc: integer): TDecimal; static;
    class function FromCurrency(c: Currency): TDecimal; static;
    { '-123.45', '+7', '.5', ' 12 '; Dezimaltrennzeichen '.' (bzw. sep) }
    class function FromString(const s: string; sep: char = '.'): TDecimal; static;
    class function TryFromString(const s: string; out d: TDecimal; sep: char = '.'): boolean; static;

    { ganzzahliger Teil (Nachkommastellen abgeschnitten), Überlauf -> EDecimalOverflow }
    function ToInt64: Int64;
    { Koeffizient nach Umskalieren auf scale, z. B. 123.45 -> ToUnscaled(2) = 12345 }
    function ToUnscaled(sc: integer; rounding: TDecRounding = drTruncate): Int64;
    function ToCurrency(rounding: TDecRounding = drTruncate): Currency;
    { mit genau Scale Nachkommastellen, Trennzeichen sep }
    function ToString(sep: char = '.'): string;

    { auf newScale Nachkommastellen; mehr Stellen: exakt, weniger: nach rounding }
    function Rescale(newScale: integer; rounding: TDecRounding = drTruncate): TDecimal;
    function IsZero: boolean;
    function IsNegative: boolean;
    { -1, 0, 1 }
    function Sign: integer;
    function Abs: TDecimal;
    function Negate: TDecimal;
    { Stellen des Koeffizienten ohne führende Nullen (mindestens 1) }
    property Digits: integer read GetDigits;
    property Scale: byte read FScale;

    class operator +(const a, b: TDecimal): TDecimal;
    class operator -(const a, b: TDecimal): TDecimal;
    class operator *(const a, b: TDecimal): TDecimal;
    class operator -(const a: TDecimal): TDecimal;
    class operator =(const a, b: TDecimal): boolean;
    class operator <>(const a, b: TDecimal): boolean;
    class operator <(const a, b: TDecimal): boolean;
    class operator >(const a, b: TDecimal): boolean;
    class operator <=(const a, b: TDecimal): boolean;
    class operator >=(const a, b: TDecimal): boolean;
    class operator :=(v: Int64): TDecimal;
  end;

{ a / b mit scale Nachkommastellen; b = 0 -> EDecimalDivByZero }
function DecDivide(const a, b: TDecimal; scale: integer;
  rounding: TDecRounding = drTruncate): TDecimal;
{ Rest wie COBOL DIVIDE ... REMAINDER: a - b * trunc(a / b) (Quotient ganzzahlig) }
function DecRemainder(const a, b: TDecimal): TDecimal;
{ -1, 0, 1 }
function DecCompare(const a, b: TDecimal): integer;

{ gepackt (COMP-3): digits Stellen belegen digits div 2 + 1 Bytes }
function PackedLength(digits: integer): integer;
{ gültig? (Ziffern 0-9, Vorzeichen A-F, bei gerader Stellenzahl Füllziffer 0) }
function PackedValid(const buf; digits: integer): boolean;
function PackedToDecimal(const buf; digits, scale: integer): TDecimal;
{ signed: Vorzeichen C/D, sonst F (negativer Wert -> EDecimalOverflow); zu viele Stellen
  -> EDecimalOverflow, Nachkommastellen nach rounding }
procedure DecimalToPacked(const d: TDecimal; var buf; digits, scale: integer;
  signed: boolean = true; rounding: TDecRounding = drTruncate);
function PackedToInt64(const buf; digits: integer): Int64;
procedure Int64ToPacked(v: Int64; var buf; digits: integer; signed: boolean = true);

{ gezont (DISPLAY, EBCDIC-Ziffern X'F0'-X'F9'; in allen CECP-Codepages gleich) }
function ZonedLength(digits: integer; sign: TZonedSign = zsTrailing): integer;
function ZonedValid(const buf; digits: integer; signed: boolean = true;
  sign: TZonedSign = zsTrailing): boolean;
function ZonedToDecimal(const buf; digits, scale: integer; signed: boolean = true;
  sign: TZonedSign = zsTrailing): TDecimal;
procedure DecimalToZoned(const d: TDecimal; var buf; digits, scale: integer;
  signed: boolean = true; sign: TZonedSign = zsTrailing;
  rounding: TDecRounding = drTruncate);

{ Kurzform für d.ToString (z. B. in Format-Argumenten) }
function DecStr(const d: TDecimal): string;

implementation

type
  { Ganzzahl beliebiger Länge, Dezimalziffern, niedrigste zuerst, ohne führende Nullen
    (null = leeres Feld) }
  TBig = array of byte;

const
  EBCDIC_PLUS = $4E;
  EBCDIC_MINUS = $60;

{ ---------------------------------------------------------------------------------- }
{ TBig                                                                                }

procedure BigTrim(var a: TBig);
var
  n: SizeInt;
begin
  n:=length(a);
  while (n>0) and (a[n-1]=0) do
    dec(n);
  SetLength(a,n);
end;

function BigFromDigits(const d: TDecDigits): TBig;
var
  i: integer;
begin
  SetLength(result,DecMaxDigits);
  for i:=0 to DecMaxDigits-1 do
    result[i]:=d[i];
  BigTrim(result);
end;

function BigFromQWord(v: QWord): TBig;
var
  n: integer;
begin
  result:=nil;
  n:=0;
  while v<>0 do
    begin
      SetLength(result,n+1);
      result[n]:=v mod 10;
      v:=v div 10;
      inc(n);
    end;
end;

function BigCmp(const a, b: TBig): integer;
var
  i: SizeInt;
begin
  if length(a)<>length(b) then
    exit(ord(length(a)>length(b))*2-1);
  for i:=length(a)-1 downto 0 do
    if a[i]<>b[i] then
      exit(ord(a[i]>b[i])*2-1);
  result:=0;
end;

function BigAdd(const a, b: TBig): TBig;
var
  i, n, c, s: SizeInt;
begin
  n:=length(a);
  if length(b)>n then
    n:=length(b);
  SetLength(result,n+1);
  c:=0;
  for i:=0 to n-1 do
    begin
      s:=c;
      if i<length(a) then inc(s,a[i]);
      if i<length(b) then inc(s,b[i]);
      result[i]:=s mod 10;
      c:=s div 10;
    end;
  result[n]:=c;
  BigTrim(result);
end;

{ a - b, a >= b }
function BigSub(const a, b: TBig): TBig;
var
  i, s, borrow: SizeInt;
begin
  SetLength(result,length(a));
  borrow:=0;
  for i:=0 to length(a)-1 do
    begin
      s:=a[i]-borrow;
      if i<length(b) then dec(s,b[i]);
      if s<0 then
        begin
          inc(s,10);
          borrow:=1;
        end
      else
        borrow:=0;
      result[i]:=s;
    end;
  BigTrim(result);
end;

{ a * 10^k }
function BigShift(const a: TBig; k: integer): TBig;
var
  i: SizeInt;
begin
  if length(a)=0 then
    exit(nil);
  SetLength(result,length(a)+k);
  for i:=0 to k-1 do
    result[i]:=0;
  for i:=0 to length(a)-1 do
    result[i+k]:=a[i];
end;

function BigMul(const a, b: TBig): TBig;
var
  i, j: SizeInt;
  t: array of SizeInt;
  c: SizeInt;
begin
  if (length(a)=0) or (length(b)=0) then
    exit(nil);
  SetLength(t,length(a)+length(b)+1);
  for i:=0 to high(t) do
    t[i]:=0;
  for i:=0 to length(a)-1 do
    for j:=0 to length(b)-1 do
      inc(t[i+j],a[i]*b[j]);
  SetLength(result,length(t));
  c:=0;
  for i:=0 to high(t) do
    begin
      inc(c,t[i]);
      result[i]:=c mod 10;
      c:=c div 10;
    end;
  BigTrim(result);
end;

{ q = a div b, r = a mod b; b <> 0 }
procedure BigDivMod(const a, b: TBig; out q, r: TBig);
var
  i: SizeInt;
  digit: byte;
begin
  SetLength(q,length(a));
  r:=nil;
  for i:=length(a)-1 downto 0 do
    begin
      { r := r * 10 + a[i] }
      r:=BigShift(r,1);
      if length(r)=0 then
        begin
          if a[i]<>0 then
            begin
              SetLength(r,1);
              r[0]:=a[i];
            end;
        end
      else
        r[0]:=a[i];
      digit:=0;
      while BigCmp(r,b)>=0 do
        begin
          r:=BigSub(r,b);
          inc(digit);
        end;
      q[i]:=digit;
    end;
  BigTrim(q);
end;

function BigIsOdd(const a: TBig): boolean;
begin
  result:=(length(a)>0) and odd(a[0]);
end;

function BigOne: TBig;
begin
  SetLength(result,1);
  result[0]:=1;
end;

{ Quotient q mit Rest r (Divisor b) nach rounding auf/abrunden (Betrag) }
function BigRoundQuot(const q, r, b: TBig; rounding: TDecRounding): TBig;
var
  c: integer;
begin
  result:=q;
  if (rounding=drTruncate) or (length(r)=0) then
    exit;
  { 2r <=> b }
  c:=BigCmp(BigAdd(r,r),b);
  if (c>0) or ((c=0) and ((rounding=drHalfUp) or BigIsOdd(q))) then
    result:=BigAdd(q,BigOne);
end;

function BigToQWord(const a: TBig; out v: QWord): boolean;
var
  i: SizeInt;
begin
  v:=0;
  if length(a)>20 then
    exit(false);
  for i:=length(a)-1 downto 0 do
    begin
      if v>(High(QWord)-a[i]) div 10 then
        exit(false);
      v:=v*10+a[i];
    end;
  result:=true;
end;

{ ---------------------------------------------------------------------------------- }
{ TDecimal intern                                                                     }

function MakeDec(const a: TBig; scale: integer; neg: boolean): TDecimal;
var
  i: SizeInt;
begin
  if (scale<0) or (scale>DecMaxDigits) then
    raise EDecimalOverflow.CreateFmt('Nachkommastellen %d außerhalb 0..%d', [scale, DecMaxDigits]);
  if length(a)>DecMaxDigits then
    raise EDecimalOverflow.CreateFmt('Ergebnis hat mehr als %d Stellen', [DecMaxDigits]);
  FillChar(result,SizeOf(result),0);
  for i:=0 to length(a)-1 do
    result.FDig[i]:=a[i];
  result.FScale:=scale;
  result.FNeg:=neg and (length(a)>0);
end;

{ Koeffizienten von a und b auf gemeinsamen Scale bringen }
procedure Align(const a, b: TDecimal; out ba, bb: TBig; out scale: integer);
begin
  ba:=BigFromDigits(a.FDig);
  bb:=BigFromDigits(b.FDig);
  scale:=a.FScale;
  if b.FScale>scale then
    scale:=b.FScale;
  ba:=BigShift(ba,scale-a.FScale);
  bb:=BigShift(bb,scale-b.FScale);
end;

{ Betrag mit Vorzeichen addieren }
function AddSigned(const a: TBig; na: boolean; const b: TBig; nb: boolean;
  scale: integer): TDecimal;
var
  c: integer;
begin
  if na=nb then
    exit(MakeDec(BigAdd(a,b),scale,na));
  c:=BigCmp(a,b);
  if c>=0 then
    result:=MakeDec(BigSub(a,b),scale,na)
  else
    result:=MakeDec(BigSub(b,a),scale,nb);
end;

{ Koeffizient a (Scale from) auf Scale to, mit Rundung }
function RescaleBig(const a: TBig; from, to_: integer; rounding: TDecRounding): TBig;
var
  q, r, p: TBig;
begin
  if to_>=from then
    exit(BigShift(a,to_-from));
  p:=BigShift(BigOne,from-to_);
  BigDivMod(a,p,q,r);
  result:=BigRoundQuot(q,r,p,rounding);
end;

{ ---------------------------------------------------------------------------------- }
{ TDecimal                                                                            }

class function TDecimal.Zero: TDecimal;
begin
  FillChar(result,SizeOf(result),0);
end;

class function TDecimal.FromInt64(v: Int64): TDecimal;
begin
  result:=FromUnscaled(v,0);
end;

class function TDecimal.FromUnscaled(v: Int64; sc: integer): TDecimal;
var
  m: QWord;
begin
  if v<0 then
    m:=QWord(-(v+1))+1
  else
    m:=QWord(v);
  result:=MakeDec(BigFromQWord(m),sc,v<0);
end;

class function TDecimal.FromCurrency(c: Currency): TDecimal;
begin
  { Currency = Int64 mit 4 Nachkommastellen }
  result:=FromUnscaled(PInt64(@c)^,4);
end;

class function TDecimal.TryFromString(const s: string; out d: TDecimal; sep: char): boolean;
var
  i, n, sc: integer;
  neg, seenSep, any: boolean;
  dig: TBig;
  t: string;
begin
  result:=false;
  d:=Zero;
  t:=Trim(s);
  if t='' then
    exit;
  i:=1;
  neg:=false;
  if t[1] in ['+','-'] then
    begin
      neg:=t[1]='-';
      inc(i);
    end;
  n:=0;
  sc:=0;
  seenSep:=false;
  any:=false;
  SetLength(dig,length(t));
  { Ziffern höchste zuerst einsammeln, danach umdrehen }
  while i<=length(t) do
    begin
      if t[i] in ['0'..'9'] then
        begin
          dig[n]:=ord(t[i])-ord('0');
          inc(n);
          any:=true;
          if seenSep then
            inc(sc);
        end
      else if (t[i]=sep) and not seenSep then
        seenSep:=true
      else
        exit;
      inc(i);
    end;
  if not any then
    exit;
  SetLength(dig,n);
  for i:=0 to n div 2-1 do
    begin
      dig[i]:=dig[i] xor dig[n-1-i];
      dig[n-1-i]:=dig[i] xor dig[n-1-i];
      dig[i]:=dig[i] xor dig[n-1-i];
    end;
  BigTrim(dig);
  if (length(dig)>DecMaxDigits) or (sc>DecMaxDigits) then
    exit;
  d:=MakeDec(dig,sc,neg);
  result:=true;
end;

class function TDecimal.FromString(const s: string; sep: char): TDecimal;
begin
  if not TryFromString(s,result,sep) then
    raise EConvertError.CreateFmt('"%s" ist keine gültige Dezimalzahl', [s]);
end;

function TDecimal.ToUnscaled(sc: integer; rounding: TDecRounding): Int64;
var
  b: TBig;
  m: QWord;
begin
  b:=RescaleBig(BigFromDigits(FDig),FScale,sc,rounding);
  if not BigToQWord(b,m) then
    raise EDecimalOverflow.Create('Wert passt nicht in Int64');
  if FNeg then
    begin
      if m>QWord(High(Int64))+1 then
        raise EDecimalOverflow.Create('Wert passt nicht in Int64');
      result:=-Int64(m-1)-1;
    end
  else
    begin
      if m>QWord(High(Int64)) then
        raise EDecimalOverflow.Create('Wert passt nicht in Int64');
      result:=Int64(m);
    end;
end;

function TDecimal.ToInt64: Int64;
begin
  result:=ToUnscaled(0,drTruncate);
end;

function TDecimal.ToCurrency(rounding: TDecRounding): Currency;
var
  v: Int64;
begin
  v:=ToUnscaled(4,rounding);
  PInt64(@result)^:=v;
end;

function TDecimal.ToString(sep: char): string;
var
  n, i, p: integer;
begin
  n:=GetDigits;
  if n<=FScale then
    n:=FScale+1;
  SetLength(result,n);
  for i:=0 to n-1 do
    result[n-i]:=char(ord('0')+FDig[i]);
  if FScale>0 then
    begin
      p:=n-FScale;
      result:=Copy(result,1,p)+sep+Copy(result,p+1,FScale);
    end;
  if FNeg then
    result:='-'+result;
end;

function TDecimal.Rescale(newScale: integer; rounding: TDecRounding): TDecimal;
begin
  result:=MakeDec(RescaleBig(BigFromDigits(FDig),FScale,newScale,rounding),newScale,FNeg);
end;

function TDecimal.GetDigits: integer;
begin
  result:=DecMaxDigits;
  while (result>1) and (FDig[result-1]=0) do
    dec(result);
end;

function TDecimal.IsZero: boolean;
var
  i: integer;
begin
  for i:=0 to DecMaxDigits-1 do
    if FDig[i]<>0 then
      exit(false);
  result:=true;
end;

function TDecimal.IsNegative: boolean;
begin
  result:=FNeg;
end;

function TDecimal.Sign: integer;
begin
  if IsZero then
    result:=0
  else if FNeg then
    result:=-1
  else
    result:=1;
end;

function TDecimal.Abs: TDecimal;
begin
  result:=self;
  result.FNeg:=false;
end;

function TDecimal.Negate: TDecimal;
begin
  result:=self;
  result.FNeg:=not FNeg and not IsZero;
end;

class operator TDecimal.+(const a, b: TDecimal): TDecimal;
var
  ba, bb: TBig;
  s: integer;
begin
  Align(a,b,ba,bb,s);
  result:=AddSigned(ba,a.FNeg,bb,b.FNeg,s);
end;

class operator TDecimal.-(const a, b: TDecimal): TDecimal;
var
  ba, bb: TBig;
  s: integer;
begin
  Align(a,b,ba,bb,s);
  result:=AddSigned(ba,a.FNeg,bb,not b.FNeg,s);
end;

class operator TDecimal.*(const a, b: TDecimal): TDecimal;
begin
  result:=MakeDec(BigMul(BigFromDigits(a.FDig),BigFromDigits(b.FDig)),
    a.FScale+b.FScale,a.FNeg<>b.FNeg);
end;

class operator TDecimal.-(const a: TDecimal): TDecimal;
begin
  result:=a.Negate;
end;

function DecCompare(const a, b: TDecimal): integer;
var
  ba, bb: TBig;
  s: integer;
  na, nb: boolean;
begin
  Align(a,b,ba,bb,s);
  na:=a.FNeg and (length(ba)>0);
  nb:=b.FNeg and (length(bb)>0);
  if na<>nb then
    exit(ord(nb)*2-1);
  result:=BigCmp(ba,bb);
  if na then
    result:=-result;
end;

class operator TDecimal.=(const a, b: TDecimal): boolean;
begin
  result:=DecCompare(a,b)=0;
end;

class operator TDecimal.<>(const a, b: TDecimal): boolean;
begin
  result:=DecCompare(a,b)<>0;
end;

class operator TDecimal.<(const a, b: TDecimal): boolean;
begin
  result:=DecCompare(a,b)<0;
end;

class operator TDecimal.>(const a, b: TDecimal): boolean;
begin
  result:=DecCompare(a,b)>0;
end;

class operator TDecimal.<=(const a, b: TDecimal): boolean;
begin
  result:=DecCompare(a,b)<=0;
end;

class operator TDecimal.>=(const a, b: TDecimal): boolean;
begin
  result:=DecCompare(a,b)>=0;
end;

class operator TDecimal.:=(v: Int64): TDecimal;
begin
  result:=TDecimal.FromInt64(v);
end;

function DecDivide(const a, b: TDecimal; scale: integer; rounding: TDecRounding): TDecimal;
var
  na, nb, q, r: TBig;
  k: integer;
begin
  nb:=BigFromDigits(b.FDig);
  if length(nb)=0 then
    raise EDecimalDivByZero.Create('Division durch null');
  if (scale<0) or (scale>DecMaxDigits) then
    raise EDecimalOverflow.CreateFmt('Nachkommastellen %d außerhalb 0..%d', [scale, DecMaxDigits]);
  { a/b * 10^scale = (A * 10^(scale + sb - sa)) / B }
  na:=BigFromDigits(a.FDig);
  k:=scale+b.FScale-a.FScale;
  if k>=0 then
    na:=BigShift(na,k)
  else
    nb:=BigShift(nb,-k);
  BigDivMod(na,nb,q,r);
  result:=MakeDec(BigRoundQuot(q,r,nb,rounding),scale,a.FNeg<>b.FNeg);
end;

function DecRemainder(const a, b: TDecimal): TDecimal;
begin
  result:=a-DecDivide(a,b,0,drTruncate)*b;
end;

function DecStr(const d: TDecimal): string;
begin
  result:=d.ToString;
end;

{ ---------------------------------------------------------------------------------- }
{ gepackt                                                                             }

{ Feldinhalt für Meldungen: X'...' }
function HexDump(p: PByte; n: integer): string;
var
  i: integer;
begin
  result:='X''';
  for i:=0 to n-1 do
    result:=result+HexStr(p[i],2);
  result:=result+'''';
end;

procedure CheckDigits(digits: integer);
begin
  if (digits<1) or (digits>DecMaxDigits) then
    raise EDecimalError.CreateFmt('Stellenzahl %d außerhalb 1..%d', [digits, DecMaxDigits]);
end;

function PackedLength(digits: integer): integer;
begin
  result:=digits div 2+1;
end;

{ Nibble i (0 = höchstes) des Felds }
function Nibble(p: PByte; i: integer): byte; inline;
begin
  if odd(i) then
    result:=p[i shr 1] and $0F
  else
    result:=p[i shr 1] shr 4;
end;

function PackedValid(const buf; digits: integer): boolean;
var
  p: PByte;
  n, i, first: integer;
begin
  CheckDigits(digits);
  p:=@buf;
  n:=PackedLength(digits)*2;   { Nibbles inkl. Vorzeichen }
  { gerade Stellenzahl: erstes Nibble ist Füllziffer 0 }
  first:=n-1-digits;
  for i:=0 to first-1 do
    if Nibble(p,i)<>0 then
      exit(false);
  for i:=first to n-2 do
    if Nibble(p,i)>9 then
      exit(false);
  result:=Nibble(p,n-1)>=$A;
end;

function PackedToDecimal(const buf; digits, scale: integer): TDecimal;
var
  p: PByte;
  n, i, j: integer;
  s: byte;
begin
  CheckDigits(digits);
  if not PackedValid(buf,digits) then
    raise EDecimalDataError.CreateFmt('ungültige gepackte Daten (%d Stellen): %s',
      [digits, HexDump(@buf,PackedLength(digits))]);
  p:=@buf;
  n:=PackedLength(digits)*2;
  FillChar(result,SizeOf(result),0);
  j:=0;
  for i:=n-2 downto n-1-digits do
    begin
      result.FDig[j]:=Nibble(p,i);
      inc(j);
    end;
  if (scale<0) or (scale>DecMaxDigits) then
    raise EDecimalError.CreateFmt('Nachkommastellen %d außerhalb 0..%d', [scale, DecMaxDigits]);
  result.FScale:=scale;
  s:=Nibble(p,n-1);
  result.FNeg:=(s in [$B,$D]) and not result.IsZero;
end;

{ Koeffizient von d für ein Feld mit digits Stellen und scale Nachkommastellen }
function FieldDigits(const d: TDecimal; digits, scale: integer; signed: boolean;
  rounding: TDecRounding): TBig;
begin
  CheckDigits(digits);
  { scale > digits ist erlaubt (PIC SVPP999: implizite führende Nullen) }
  if (scale<0) or (scale>DecMaxDigits) then
    raise EDecimalError.CreateFmt('Nachkommastellen %d außerhalb 0..%d', [scale, DecMaxDigits]);
  result:=RescaleBig(BigFromDigits(d.FDig),d.FScale,scale,rounding);
  if length(result)>digits then
    raise EDecimalOverflow.CreateFmt('%s passt nicht in %d Stellen mit %d Nachkommastellen',
      [d.ToString, digits, scale]);
  if d.FNeg and not signed and (length(result)>0) then
    raise EDecimalOverflow.CreateFmt('negativer Wert %s in Feld ohne Vorzeichen', [d.ToString]);
end;

procedure DecimalToPacked(const d: TDecimal; var buf; digits, scale: integer;
  signed: boolean; rounding: TDecRounding);
var
  b: TBig;
  p: PByte;
  n, i, j: integer;
  v, s: byte;
begin
  b:=FieldDigits(d,digits,scale,signed,rounding);
  p:=@buf;
  n:=PackedLength(digits)*2;
  if not signed then
    s:=$F
  else if d.FNeg and (length(b)>0) then
    s:=$D
  else
    s:=$C;
  FillChar(p^,n div 2,0);
  p[n div 2-1]:=s;
  j:=0;
  for i:=n-2 downto 0 do
    begin
      if j<length(b) then
        v:=b[j]
      else
        v:=0;
      if odd(i) then
        p[i shr 1]:=p[i shr 1] or v
      else
        p[i shr 1]:=p[i shr 1] or (v shl 4);
      inc(j);
    end;
end;

function PackedToInt64(const buf; digits: integer): Int64;
begin
  result:=PackedToDecimal(buf,digits,0).ToInt64;
end;

procedure Int64ToPacked(v: Int64; var buf; digits: integer; signed: boolean);
begin
  DecimalToPacked(TDecimal.FromInt64(v),buf,digits,0,signed);
end;

{ ---------------------------------------------------------------------------------- }
{ gezont                                                                              }

function ZonedLength(digits: integer; sign: TZonedSign): integer;
begin
  result:=digits;
  if sign in [zsTrailingSeparate,zsLeadingSeparate] then
    inc(result);
end;

{ Lage der Ziffern und des Vorzeichens im Feld }
procedure ZonedLayout(digits: integer; signed: boolean; sign: TZonedSign;
  out first, signpos: integer; out separate: boolean);
begin
  first:=0;
  separate:=signed and (sign in [zsTrailingSeparate,zsLeadingSeparate]);
  if not signed then
    signpos:=digits-1                  { Zone F in der letzten Ziffer }
  else
    case sign of
      zsTrailing: signpos:=digits-1;
      zsLeading: signpos:=0;
      zsTrailingSeparate: signpos:=digits;
      zsLeadingSeparate:
        begin
          signpos:=0;
          first:=1;
        end;
    end;
end;

function ZonedValid(const buf; digits: integer; signed: boolean; sign: TZonedSign): boolean;
var
  p: PByte;
  first, signpos, i: integer;
  separate: boolean;
begin
  CheckDigits(digits);
  p:=@buf;
  ZonedLayout(digits,signed,sign,first,signpos,separate);
  for i:=first to first+digits-1 do
    begin
      if (p[i] and $0F)>9 then
        exit(false);
      if (i=signpos) and not separate then
        begin
          if (p[i] shr 4)<$A then
            exit(false);
        end
      else if (p[i] shr 4)<>$F then
        exit(false);
    end;
  if separate then
    result:=p[signpos] in [EBCDIC_PLUS,EBCDIC_MINUS]
  else
    result:=true;
end;

function ZonedToDecimal(const buf; digits, scale: integer; signed: boolean;
  sign: TZonedSign): TDecimal;
var
  p: PByte;
  first, signpos, i: integer;
  separate, neg: boolean;
begin
  if not ZonedValid(buf,digits,signed,sign) then
    raise EDecimalDataError.CreateFmt('ungültige gezonte Daten (%d Stellen): %s',
      [digits, HexDump(@buf,ZonedLength(digits,sign))]);
  if (scale<0) or (scale>DecMaxDigits) then
    raise EDecimalError.CreateFmt('Nachkommastellen %d außerhalb 0..%d', [scale, DecMaxDigits]);
  p:=@buf;
  ZonedLayout(digits,signed,sign,first,signpos,separate);
  FillChar(result,SizeOf(result),0);
  for i:=0 to digits-1 do
    result.FDig[i]:=p[first+digits-1-i] and $0F;
  if separate then
    neg:=p[signpos]=EBCDIC_MINUS
  else
    neg:=(p[signpos] shr 4) in [$B,$D];
  result.FScale:=scale;
  result.FNeg:=neg and not result.IsZero;
end;

procedure DecimalToZoned(const d: TDecimal; var buf; digits, scale: integer;
  signed: boolean; sign: TZonedSign; rounding: TDecRounding);
var
  b: TBig;
  p: PByte;
  first, signpos, i: integer;
  separate, neg: boolean;
  v: byte;
begin
  b:=FieldDigits(d,digits,scale,signed,rounding);
  neg:=d.FNeg and (length(b)>0);
  p:=@buf;
  ZonedLayout(digits,signed,sign,first,signpos,separate);
  for i:=0 to digits-1 do
    begin
      if i<length(b) then
        v:=b[i]
      else
        v:=0;
      p[first+digits-1-i]:=$F0 or v;
    end;
  if separate then
    begin
      if neg then
        p[signpos]:=EBCDIC_MINUS
      else
        p[signpos]:=EBCDIC_PLUS;
    end
  else if signed then
    begin
      if neg then
        p[signpos]:=$D0 or (p[signpos] and $0F)
      else
        p[signpos]:=$C0 or (p[signpos] and $0F);
    end;
end;

end.
