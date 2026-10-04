program cobtest;
{ PF8: Sätze aus COBOL-Copybooks (scripts/copybook2pas.py, Unit zoscobol).
  Die Units cb_*.pas sind aus tests/copybooks/*.cpy erzeugt. Geprüft werden die Offsets
  (LayoutOk), die Bytebilder der Felder, wie ein COBOL-Programm sie schreibt (EBCDIC,
  gepackt, gezont, binär Big-Endian, HFP), Stufe 88, OCCURS, REDEFINES und ODO.
  Portabel: dieselben Erwartungen auf x86_64-linux und z/OS. Returncode = Fehler. }
{$mode objfpc}{$H+}
uses
  sysutils, math, zosdecimal, zoscobol, cb_kunde, cb_auftrag, cb_sync, cb_divers;

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

function hex(const b; ofs, n: integer): string;
var
  i: integer;
begin
  result:='';
  for i:=0 to n-1 do
    result:=result+HexStr(PByte(@b)[ofs+i],2);
end;

function D(const s: string): TDecimal;
begin
  result:=TDecimal.FromString(s);
end;

procedure test_kunde;
var
  k: TKUNDE_SATZ;
begin
  writeln('-- KUNDE');
  check('Satzlänge 97, Offsets', KUNDE_SATZ_LayoutOk and (SizeOf(k)=97));
  Initialize_KUNDE_SATZ(k);
  check('INITIALIZE: Name Leerzeichen (X''40'')', hex(k,KUNDE_NAME_OFS,3)='404040');
  check('INITIALIZE: Saldo 0 gepackt', hex(k,KUNDE_SALDO_OFS,6)='00000000000C');
  check('INITIALIZE: Nr gezont 0', hex(k,KUNDE_NR_OFS,8)='F0F0F0F0F0F0F0F0');
  check('INITIALIZE: FILLER X''00''', hex(k,72,5)='0000000000');
  Set_KUNDE_NR(k,12345678);
  check('PIC 9(8) = F1..F8', hex(k,0,8)='F1F2F3F4F5F6F7F8');
  Set_KUNDE_NAME(k,'M'#$FC'ller AG',273);
  check('PIC X(30) in 273: M'#$FC'ller', hex(k,8,4)='D4D09393');
  check('Name zurück (273)', Get_KUNDE_NAME(k,273)='M'#$FC'ller AG');
  Set_KUNDE_SALDO(k,D('-1234.56'));
  check('S9(9)V99 COMP-3 -1234.56 = 00000123456D', hex(k,39,6)='00000123456D');
  check('Saldo zurück', Get_KUNDE_SALDO(k)=D('-1234.56'));
  Set_KUNDE_LIMIT(k,D('5000.999'),drHalfUp);
  check('S9(7)V99 kaufmännisch 5000.999 -> 0000500100C', hex(k,45,5)='000500100C');
  Set_KUNDE_ANZAHL(k,-2);
  check('S9(4) COMP -2 = FFFE', hex(k,50,2)='FFFE');
  check('Anzahl zurück', Get_KUNDE_ANZAHL(k)=-2);
  Set_KUNDE_PUNKTE(k,100000);
  check('9(9) BINARY 100000 = 000186A0', hex(k,52,4)='000186A0');
  Set_KUNDE_GROSS(k,-1);
  check('S9(18) COMP-5 -1', hex(k,56,8)='FFFFFFFFFFFFFFFF');
  Set_KUNDE_JJJJ(k,2026);
  check('Gruppe DATUM: JJJJ', hex(k,64,4)='F2F0F2F6');
  Set_KUNDE_BETRAG(k,D('123.45'));
  check('S9(5)V99 SIGN LEADING SEPARATE = 4EF0F0F1F2F3F4F5', hex(k,77,8)='4EF0F0F1F2F3F4F5');
  Set_KUNDE_BETRAG(k,D('-0.01'));
  check('... -0.01 = 60F0F0F0F0F0F0F1', hex(k,77,8)='60F0F0F0F0F0F0F1');
  Set_KUNDE_KURS(k,1.0);
  check('COMP-2 HFP 1.0 = 4110000000000000', hex(k,85,8)='4110000000000000');
  Set_KUNDE_KURS(k,100.0);
  check('COMP-2 HFP 100.0 = 4264000000000000', hex(k,85,8)='4264000000000000');
  Set_KUNDE_FAKTOR(k,-0.5);
  check('COMP-1 HFP -0.5 = C0800000', hex(k,93,4)='C0800000');
  check('COMP-1 zurück', Get_KUNDE_FAKTOR(k)=-0.5);
  Set_KUNDE_AKTIV(k);
  check('88 SET AKTIV TO TRUE: STATUS = C1', (hex(k,38,1)='C1') and Is_KUNDE_AKTIV(k) and not Is_KUNDE_GESPERRT(k));
  Set_KUNDE_STATUS(k,'X');
  check('88 GESPERRT bei X (zweiter Wert)', Is_KUNDE_GESPERRT(k) and not Is_KUNDE_AKTIV(k));
  check('Konstante KUNDE_AKTIV', KUNDE_AKTIV='A');
  try
    Set_KUNDE_ANZAHL(k,10000);
    check('S9(4) COMP 10000 -> Überlauf', false);
  except
    on EDecimalOverflow do check('S9(4) COMP 10000 -> Überlauf (TRUNC(STD))', true);
  end;
  Set_KUNDE_GROSS(k,High(Int64));
  check('COMP-5 ohne Stellenprüfung', Get_KUNDE_GROSS(k)=High(Int64));
  k.KUNDE_SALDO[5]:=$C5;
  try
    Get_KUNDE_SALDO(k);
    check('ungültiges Vorzeichen -> EDecimalDataError', false);
  except
    on EDecimalDataError do check('ungültiges Vorzeichen -> EDecimalDataError (S0C7)', true);
  end;
end;

procedure test_auftrag;
var
  a: TAUFTRAG;
  i: integer;
begin
  writeln('-- AUFTRAG');
  check('Satzlänge 175, Offsets', AUFTRAG_LayoutOk and (SizeOf(a)=175));
  Initialize_AUFTRAG(a);
  Set_AUF_STRASSE(a,'Hauptstrasse 1');
  check('REDEFINES: KURZ sieht die Straße', Get_AUF_KURZ(a)='Hauptstras');
  Set_AUF_PF_NR(a,4711);
  check('REDEFINES: Postfach-Nr. überschreibt', (hex(a,11,6)='F0F0F4F7F1F1') and (Get_AUF_KURZ(a)='004711tras'));
  for i:=1 to 5 do
    begin
      Set_POS_ARTIKEL(a,i,'ART'+IntToStr(i));
      Set_POS_MENGE(a,i,i*10);
      Set_POS_PREIS(a,i,D('19.95'));
      Set_POS_RABATT(a,i,3,i);
    end;
  check('OCCURS: Position 3 Artikel bei 58+2*22', hex(a,58+2*22,4)='C1D9E3F3');
  check('OCCURS: Menge 5 = 00050C', hex(a,58+4*22+8,3)='00050C');
  check('verschachtelt: Rabatt(5,3) = F0F5', hex(a,58+4*22+16+4,2)='F0F5');
  check('Get Position 4', (Get_POS_ARTIKEL(a,4)='ART4') and (Get_POS_MENGE(a,4)=D('40')));
  Set_AUF_ART(a,3);
  check('88 THRU: EIL bei 3', Is_AUF_EIL(a) and not Is_AUF_NORMAL(a));
  Set_AUF_NORMAL(a);
  check('88 SET NORMAL', Is_AUF_NORMAL(a) and (hex(a,10,1)='F1'));
  Set_AUF_SUMME(a,D('99.75'));
  check('Summe S9(11)V99', hex(a,168,7)='0000000009975C');
end;

procedure test_sync;
var
  s: TSYNC_SATZ;
begin
  writeln('-- SYNC/ODO');
  check('Satzlänge 87, Offsets mit Füllbytes', SYNC_SATZ_LayoutOk and (SizeOf(s)=87));
  check('Offsets HALB 2, VOLL 8, DOPPEL 16, F1 24', (S_HALB_OFS=2) and (S_VOLL_OFS=8)
    and (S_DOPPEL_OFS=16) and (S_F1_OFS=24));
  FillChar(s,SizeOf(s),0);
  Set_T_B(s,2,-5);
  check('OCCURS mit SYNC: T-B(2) bei 40', hex(s,40,4)='FFFFFFFB');
  Set_S_ANZ(s,3);
  check('ODO: Länge 47+3*4 = 59', SYNC_SATZ_Length(s)=59);
  Set_S_ANZ(s,11);
  try
    SYNC_SATZ_Length(s);
    check('ODO 11 > 10 -> Fehler', false);
  except
    on EDecimalOverflow do check('ODO 11 > 10 -> Fehler', true);
  end;
end;

procedure test_divers;
var
  d1: TDIVERS;
  e: TEINZEL;
begin
  writeln('-- DIVERS');
  check('Satzlänge 36, Offsets', DIVERS_LayoutOk and (SizeOf(d1)=36));
  Initialize_DIVERS(d1);
  Set_D_NAT(d1,#$C4'b');
  check('PIC N(4) UTF-16BE', hex(d1,0,8)='00C4006200200020');
  check('PIC N zurück', Get_D_NAT(d1)=#$C4'b');
  Set_D_EDIT(d1,'  1.234,50-');
  check('editiert als Text', Get_D_EDIT(d1)='  1.234,50-');
  Set_D_PROZ(d1,D('0.00123'));
  check('PIC SVPP999 0.00123 = F1F2C3', hex(d1,19,3)='F1F2C3');
  check('PIC SVPP999 zurück', Get_D_PROZ(d1)=D('0.00123'));
  check('88 VALUE SPACES nach INITIALIZE', Is_D_LEER(d1) and not Is_D_NULL(d1));
  d1.D_KENN[0]:=0; d1.D_KENN[1]:=0;
  check('88 LOW-VALUES', Is_D_NULL(d1) and not Is_D_LEER(d1));
  Set_D_KENN(d1,'AB');
  check('88 X''C1C2''', Is_D_HEX(d1));
  Set_D_VORZ(d1,-12);
  check('S9(3) SIGN LEADING = D0F1F2', hex(d1,24,3)='D0F1F2');
  Set_D_PTR(d1,$12345678);
  check('POINTER 4 Byte', hex(d1,27,4)='12345678');
  Set_TYPE_(d1,'T');
  check('Name TYPE -> TYPE_', Get_TYPE_(d1)='T');
  FillChar(e,SizeOf(e),0);
  e[2]:=$0C;
  check('Stufe 77 mit 88 ZERO', Is_EINZEL_NULL(e) and (EINZEL_SIZE=3));
end;

procedure test_float;
var
  b: array[0..7] of byte;
  i, bad: integer;
  x, y: double;
begin
  writeln('-- HFP/IEEE');
  RandSeed:=99;
  bad:=0;
  for i:=1 to 10000 do
    begin
      x:=(Random-0.5)*Power(10,Random(40)-20);
      DoubleToHfp(x,b,8);
      y:=HfpToDouble(b,8);
      if (x<>0) and (abs((y-x)/x)>1e-15) then inc(bad);
      DoubleToHfp(x,b,4);
      y:=HfpToDouble(b,4);
      if (x<>0) and (abs((y-x)/x)>1e-6) then inc(bad);
      DoubleToIeeeBE(x,b,8);
      if IeeeBEToDouble(b,8)<>x then inc(bad);
    end;
  check('10000 Zufallswerte: HFP lang/kurz, IEEE BE ('+IntToStr(bad)+' Abweichungen)', bad=0);
  DoubleToIeeeBE(1.0,b,8);
  check('IEEE BE 1.0 = 3FF0000000000000', hex(b,0,8)='3FF0000000000000');
  DoubleToHfp(0.1,b,8);
  check('HFP 0.1 = 401999999999999A', hex(b,0,8)='401999999999999A');
  DoubleToHfp(-123.456,b,4);
  check('HFP kurz -123.456 = C27B74BC', hex(b,0,4)='C27B74BC');
end;

begin
  writeln('Free Pascal auf z/OS - PF8 Copybook-Sätze');
  test_kunde;
  test_auftrag;
  test_sync;
  test_divers;
  test_float;
  writeln('Prüfungen: ', checks, ', Fehler: ', errors);
  halt(errors);
end.
