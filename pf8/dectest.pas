program dectest;
{ PF8: gepackte und gezonte Dezimalzahlen (Units zosdecimal, zosdecimalbcd).
  Portabel: dieselben Erwartungen auf x86_64-linux und z/OS (byteweise Felder, keine
  Annahme über die Byte-Reihenfolge). Ergebnis: Zahl der Fehler als Returncode. }
{$mode objfpc}{$H+}
uses
  sysutils, fmtbcd, zosdecimal, zosdecimalbcd;

var
  errors: longint = 0;
  checks: longint = 0;

procedure check(const what: string; ok: boolean);
begin
  inc(checks);
  if ok then
    writeln('OK      ', what)
  else
    begin
      writeln('FEHLER  ', what);
      inc(errors);
    end;
end;

function hex(const b: array of byte; n: integer): string;
var
  i: integer;
begin
  result:='';
  for i:=0 to n-1 do
    result:=result+HexStr(b[i],2);
end;

function D(const s: string): TDecimal;
begin
  result:=TDecimal.FromString(s);
end;

var
  buf: array[0..63] of byte;

function packed_(const s: string; digits, scale: integer; signed: boolean = true): string;
begin
  FillChar(buf,sizeof(buf),$EE);
  DecimalToPacked(D(s),buf,digits,scale,signed);
  result:=hex(buf,PackedLength(digits));
end;

function zoned(const s: string; digits, scale: integer; signed: boolean = true;
  sign: TZonedSign = zsTrailing): string;
begin
  FillChar(buf,sizeof(buf),$EE);
  DecimalToZoned(D(s),buf,digits,scale,signed,sign);
  result:=hex(buf,ZonedLength(digits,sign));
end;

procedure sethex(const h: string);
var
  i: integer;
begin
  for i:=0 to length(h) div 2-1 do
    buf[i]:=StrToInt('$'+copy(h,2*i+1,2));
end;

function raisesData(const h: string; digits: integer; isPacked: boolean;
  sign: TZonedSign = zsTrailing): boolean;
begin
  sethex(h);
  result:=false;
  try
    if isPacked then
      PackedToDecimal(buf,digits,0)
    else
      ZonedToDecimal(buf,digits,0,true,sign);
  except
    on EDecimalDataError do result:=true;
  end;
end;

function overflows(const s: string; digits, scale: integer; signed: boolean = true): boolean;
begin
  result:=false;
  try
    DecimalToPacked(D(s),buf,digits,scale,signed);
  except
    on EDecimalOverflow do result:=true;
  end;
end;

procedure test_packed;
begin
  writeln('-- gepackt (COMP-3)');
  check('12345 S9(5) = 12345C', packed_('12345',5,0)='12345C');
  check('-12345 S9(5) = 12345D', packed_('-12345',5,0)='12345D');
  check('12345 9(5) = 12345F', packed_('12345',5,0,false)='12345F');
  check('1234 S9(4) = 01234C (Füllziffer)', packed_('1234',4,0)='01234C');
  check('-7 S9(4) = 00007D', packed_('-7',4,0)='00007D');
  check('0 S9(1) = 0C', packed_('0',1,0)='0C');
  check('-0 wird +0 (0C)', packed_('-0',1,0)='0C');
  check('123.45 S9(3)V99 = 12345C', packed_('123.45',5,2)='12345C');
  check('1.5 S9(3)V99 = 00150C (Scale auffüllen)', packed_('1.5',5,2)='00150C');
  check('1.239 S9(3)V99 abgeschnitten = 00123C', packed_('1.239',5,2)='00123C');
  check('S9(18) max', packed_('999999999999999999',18,0)='0999999999999999999C');
  check('S9(31) 31 Stellen', packed_('-1234567890123456789012345678901',31,0)=
    '1234567890123456789012345678901D');
  sethex('12345C'); check('lesen 12345C', PackedToDecimal(buf,5,0)=D('12345'));
  sethex('12345D'); check('lesen 12345D', PackedToDecimal(buf,5,0)=D('-12345'));
  sethex('12345B'); check('lesen Vorzeichen B = negativ', PackedToDecimal(buf,5,0)=D('-12345'));
  sethex('12345A'); check('lesen Vorzeichen A = positiv', PackedToDecimal(buf,5,0)=D('12345'));
  sethex('12345F'); check('lesen Vorzeichen F', PackedToDecimal(buf,5,2).ToString='123.45');
  sethex('0D'); check('lesen -0 = 0', PackedToDecimal(buf,1,0).IsZero and
    not PackedToDecimal(buf,1,0).IsNegative and (PackedToDecimal(buf,1,0).ToString='0'));
  check('ungültige Ziffer 1A345C', raisesData('1A345C',5,true));
  check('ungültiges Vorzeichen 123450', raisesData('123450',5,true));
  check('ungültiges Vorzeichen 123459', raisesData('123459',5,true));
  check('Füllziffer nicht 0: 11234C (S9(4))', raisesData('11234C',4,true));
  sethex('12345C'); check('PackedValid', PackedValid(buf,5));
  sethex('12345E'); check('PackedValid (E = +)', PackedValid(buf,5));
  check('PackedLength 5 = 3, 4 = 3, 1 = 1, 18 = 10', (PackedLength(5)=3) and
    (PackedLength(4)=3) and (PackedLength(1)=1) and (PackedLength(18)=10));
  check('Überlauf 100000 in S9(5)', overflows('100000',5,0));
  check('Überlauf 1000.00 in S9(3)V99', overflows('1000.00',5,2));
  check('negativ in 9(5) ohne Vorzeichen', overflows('-1',5,0,false));
  check('kein Überlauf 99999 in S9(5)', not overflows('99999',5,0));
  Int64ToPacked(-9223372036854775807-1,buf,19);
  check('Int64ToPacked Low(Int64)', hex(buf,10)='9223372036854775808D');
  check('PackedToInt64 Low(Int64)', PackedToInt64(buf,19)=Low(Int64));
  Int64ToPacked(High(Int64),buf,19);
  check('PackedToInt64 High(Int64)', PackedToInt64(buf,19)=High(Int64));
end;

procedure test_zoned;
var
  ok: boolean;
begin
  writeln('-- gezont (DISPLAY)');
  check('12345 S9(5) = F1F2F3F4C5', zoned('12345',5,0)='F1F2F3F4C5');
  check('-12345 S9(5) = F1F2F3F4D5', zoned('-12345',5,0)='F1F2F3F4D5');
  check('12345 9(5) = F1F2F3F4F5', zoned('12345',5,0,false)='F1F2F3F4F5');
  check('-12 S9(4) LEADING = D0F0F1F2', zoned('-12',4,0,true,zsLeading)='D0F0F1F2');
  check('12 S9(4) SEPARATE TRAILING = F0F0F1F24E', zoned('12',4,0,true,zsTrailingSeparate)='F0F0F1F24E');
  check('-12 S9(4) SEPARATE LEADING = 60F0F0F1F2', zoned('-12',4,0,true,zsLeadingSeparate)='60F0F0F1F2');
  check('-3.5 S9(3)V9 = F0F3D5', zoned('-3.5',3,1)='F0F3D5');
  check('ZonedLength', (ZonedLength(4)=4) and (ZonedLength(4,zsLeadingSeparate)=5));
  sethex('F1F2F3F4D5'); check('lesen F1F2F3F4D5', ZonedToDecimal(buf,5,0)=D('-12345'));
  sethex('F1F2F3F4F5'); check('lesen F1F2F3F4F5 (V99)', ZonedToDecimal(buf,5,2).ToString='123.45');
  sethex('F1F2F3F4C5'); check('lesen ohne Vorzeichen', ZonedToDecimal(buf,5,0,false)=D('12345'));
  sethex('D1F2'); check('lesen LEADING D1F2', ZonedToDecimal(buf,2,0,true,zsLeading)=D('-12'));
  sethex('604EF1'); ok:=raisesData('604EF1',2,false,zsLeadingSeparate);
  check('SEPARATE: Vorzeichen nur vorn', ok);
  sethex('60F1F2'); check('lesen 60F1F2 SEPARATE LEADING', ZonedToDecimal(buf,2,0,true,zsLeadingSeparate)=D('-12'));
  check('ungültige Zone F1C2C3', raisesData('F1C2C3',3,false));
  check('ungültige Ziffer F1FAC3', raisesData('F1FAC3',3,false));
  check('ASCII-Ziffern 313233', raisesData('313233',3,false));
  check('Leerzeichen 404040', raisesData('404040',3,false));
  check('Vorzeichenzone fehlt F1F2', not raisesData('F1F2',2,false));
  sethex('F1F2F3'); check('ZonedValid', ZonedValid(buf,3));
end;

procedure test_arith;
var
  a, b: TDecimal;
  ok: boolean;
begin
  writeln('-- Arithmetik');
  check('0.1 + 0.2 = 0.3 (exakt)', D('0.1')+D('0.2')=D('0.3'));
  check('0.1 + 0.2 Scale 1', (D('0.1')+D('0.2')).ToString='0.3');
  check('1.50 + 2.5 = 4.00', (D('1.50')+D('2.5')).ToString='4.00');
  check('5 - 7.25 = -2.25', (D('5')-D('7.25')).ToString='-2.25');
  check('-5 - -7 = 2', D('-5')-D('-7')=D('2'));
  check('123.45 * 2.5 = 308.625', (D('123.45')*D('2.5')).ToString='308.625');
  check('-0.5 * 0.5 = -0.25', (D('-0.5')*D('0.5')).ToString='-0.25');
  check('10 / 3 (2, abschneiden) = 3.33', DecDivide(D('10'),D('3'),2).ToString='3.33');
  check('2 / 3 (2, kaufmännisch) = 0.67', DecDivide(D('2'),D('3'),2,drHalfUp).ToString='0.67');
  check('-2 / 3 (2, kaufmännisch) = -0.67', DecDivide(D('-2'),D('3'),2,drHalfUp).ToString='-0.67');
  check('1 / 8 (2, Banker) = 0.12', DecDivide(D('1'),D('8'),2,drHalfEven).ToString='0.12');
  check('0.135 -> 0.14 (Banker)', D('0.135').Rescale(2,drHalfEven).ToString='0.14');
  check('0.125 -> 0.13 (kaufmännisch)', D('0.125').Rescale(2,drHalfUp).ToString='0.13');
  check('-2.5 -> -3 (kaufmännisch)', D('-2.5').Rescale(0,drHalfUp).ToString='-3');
  check('-2.5 -> -2 (abschneiden)', D('-2.5').Rescale(0).ToString='-2');
  check('1.005 / 0.01 = 100.5', DecDivide(D('1.005'),D('0.01'),1).ToString='100.5');
  check('7 / 0.5 = 14', DecDivide(D('7'),D('0.5'),0)=D('14'));
  check('17 rem 5 = 2', DecRemainder(D('17'),D('5'))=D('2'));
  check('-17 rem 5 = -2 (Vorzeichen des Dividenden)', DecRemainder(D('-17'),D('5'))=D('-2'));
  check('7.5 rem 2 = 1.5', DecRemainder(D('7.5'),D('2')).ToString='1.5');
  ok:=false;
  try DecDivide(D('1'),D('0.00'),2); except on EDecimalDivByZero do ok:=true; end;
  check('Division durch 0', ok);
  check('Vergleich 1.10 = 1.1', D('1.10')=D('1.1'));
  check('Vergleich -1 < 0.5', D('-1')<D('0.5'));
  check('Vergleich -2 < -1', D('-2')<D('-1'));
  check('Vergleich 0 = -0', D('0')=D('-0.00'));
  check('Sign/Abs/Negate', (D('-3').Sign=-1) and (D('-3').Abs=D('3')) and (-D('3')=D('-3')) and (D('0').Sign=0));
  a:=D('99999999999999999999999999999999999999999999999999999999999999');
  b:=a*D('10');
  check('62 Stellen * 10 = 63 Stellen', b.Digits=63);
  ok:=false;
  try b:=b*D('10'); except on EDecimalOverflow do ok:=true; end;
  check('64 Stellen -> Überlauf', ok);
  a:=12345;   { Zuweisung aus Int64 }
  check('Int64 := 12345', a=D('12345'));
  check('Digits 000123', D('000123').Digits=3);
end;

procedure test_conv;
var
  d1: TDecimal;
  c: Currency;
  ok: boolean;
  b: TBCD;
begin
  writeln('-- Umwandlungen');
  check('FromInt64/ToInt64 High', TDecimal.FromInt64(High(Int64)).ToInt64=High(Int64));
  check('FromInt64/ToInt64 Low', TDecimal.FromInt64(Low(Int64)).ToInt64=Low(Int64));
  check('ToInt64 schneidet ab: -12.99 -> -12', D('-12.99').ToInt64=-12);
  ok:=false;
  try D('9223372036854775808').ToInt64; except on EDecimalOverflow do ok:=true; end;
  check('ToInt64 Überlauf', ok);
  check('-9223372036854775808 passt', D('-9223372036854775808').ToInt64=Low(Int64));
  check('FromUnscaled(12345, 2) = 123.45', TDecimal.FromUnscaled(12345,2).ToString='123.45');
  check('ToUnscaled(2) 1.239 = 123', D('1.239').ToUnscaled(2)=123);
  check('ToUnscaled(2, kaufmännisch) 1.235 = 124', D('1.235').ToUnscaled(2,drHalfUp)=124);
  c:=1234.5678;
  check('Currency -> 1234.5678', TDecimal.FromCurrency(c).ToString='1234.5678');
  c:=-0.0001;
  check('Currency -> -0.0001', TDecimal.FromCurrency(c).ToString='-0.0001');
  check('ToCurrency 12.34567 (abschneiden)', D('12.34567').ToCurrency=12.3456);
  check('ToCurrency 12.34567 (kaufmännisch)', D('12.34567').ToCurrency(drHalfUp)=12.3457);
  check('ToString .5 = 0.5', D('.5').ToString='0.5');
  check('ToString +7', D('+7').ToString='7');
  check('ToString 0.00', D('0.00').ToString='0.00');
  check('ToString -0.05', D('-0.05').ToString='-0.05');
  check('Trennzeichen Komma', TDecimal.FromString('1,25',',').ToString(',')='1,25');
  check('Leerzeichen außen', D(' 42 ')=D('42'));
  check('ungültig: abc', not TDecimal.TryFromString('abc',d1));
  check('ungültig: 1.2.3', not TDecimal.TryFromString('1.2.3',d1));
  check('ungültig: leer', not TDecimal.TryFromString('',d1));
  check('ungültig: -', not TDecimal.TryFromString('-',d1));
  ok:=false;
  try D('x'); except on EConvertError do ok:=true; end;
  check('FromString ungültig -> EConvertError', ok);
  b:=DecimalToBCD(D('-12345.678'));
  check('TBCD hin: '+BCDToStr(b), BCDToStr(b)=FormatFloat('0.000',-12345.678));
  check('TBCD zurück', BCDToDecimal(b)=D('-12345.678'));
  b:=StrToBCD('1'+FormatSettings.DecimalSeparator+'50');
  d1:=BCDToDecimal(b);
  check('TBCD 1.50 -> '+d1.ToString, d1=D('1.5'));
  b:=DecimalToBCD(D('123456789012345678901234567890.12'));
  check('TBCD 32 Stellen', BCDToDecimal(b)=D('123456789012345678901234567890.12'));
end;

{ Zufallsvergleich gegen Int64-Arithmetik (Ganzzahlen im sicheren Bereich) und
  Rundreisen über gepackte/gezonte Felder }
procedure test_random;
var
  i, bad: integer;
  x, y: Int64;
  dx, dy: TDecimal;
  sc: integer;
  t: TDecimal;
begin
  writeln('-- Zufallsvergleich (20000 Paare)');
  RandSeed:=4711;
  bad:=0;
  for i:=1 to 20000 do
    begin
      x:=Int64(Random($7FFFFFFF))*Random(1000000)-Int64(Random($7FFFFFFF))*Random(1000000);
      y:=Int64(Random($7FFFFFFF))-Int64(Random($7FFFFFFF));
      if y=0 then y:=7;
      dx:=x; dy:=y;
      if (dx+dy).ToInt64<>x+y then inc(bad);
      if (dx-dy).ToInt64<>x-y then inc(bad);
      if (TDecimal.FromInt64(x div 1000000)*dy).ToInt64<>(x div 1000000)*y then inc(bad);
      if DecDivide(dx,dy,0).ToInt64<>x div y then inc(bad);
      if DecRemainder(dx,dy).ToInt64<>x mod y then inc(bad);
      if (dx<dy)<>(x<y) then inc(bad);
      { Rundreise gepackt 19 Stellen, gezont 19 Stellen }
      DecimalToPacked(dx,buf,19,0);
      if PackedToDecimal(buf,19,0)<>dx then inc(bad);
      DecimalToZoned(dx,buf,19,0);
      if ZonedToDecimal(buf,19,0)<>dx then inc(bad);
      { mit Nachkommastellen: x * 10^-sc }
      sc:=Random(6);
      t:=TDecimal.FromUnscaled(x,sc);
      DecimalToPacked(t,buf,21,sc);
      if PackedToDecimal(buf,21,sc).ToUnscaled(sc)<>x then inc(bad);
      DecimalToZoned(t,buf,21,sc,true,zsLeadingSeparate);
      if ZonedToDecimal(buf,21,sc,true,zsLeadingSeparate).ToUnscaled(sc)<>x then inc(bad);
      if TDecimal.FromString(t.ToString)<>t then inc(bad);
    end;
  check('20000 Paare: + - * div rem < und Rundreisen ('+IntToStr(bad)+' Abweichungen)', bad=0);
end;

begin
  writeln('Free Pascal auf z/OS - PF8 Dezimalzahlen');
  test_packed;
  test_zoned;
  test_arith;
  test_conv;
  test_random;
  writeln('Prüfungen: ', checks, ', Fehler: ', errors);
  halt(errors);
end.
