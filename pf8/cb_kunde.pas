{ cb_kunde: erzeugt von scripts/copybook2pas.py aus kunde.cpy, nicht von Hand ändern.
  Felder sind Byte-Felder mit den Offsets des COBOL-Programms (packed, unabhängig von der
  Byte-Reihenfolge); Zugriff über Get_/Set_ (Units zoscobol, zosdecimal, zosccsid).
}
unit cb_kunde;

{$mode objfpc}{$H+}
{$R-}

interface

uses
  zoscobol, zosdecimal, zosccsid;

const
  cb_kunde_CCSID = 1047;   { CCSID der Textfelder (Standard der Get_/Set_) }

  KUNDE_SATZ_SIZE = 97;
  { Satzbild KUNDE-SATZ:
    01 KUNDE-SATZ               ofs     0 len    97  group
      05 KUNDE-NR                 ofs     0 len     8  zoned PIC 9(8)
      05 KUNDE-NAME               ofs     8 len    30  text PIC X(30)
      05 KUNDE-STATUS             ofs    38 len     1  text PIC X
      05 KUNDE-SALDO              ofs    39 len     6  packed PIC S9(9)V99
      05 KUNDE-LIMIT              ofs    45 len     5  packed PIC S9(7)V99
      05 KUNDE-ANZAHL             ofs    50 len     2  binary PIC S9(4)
      05 KUNDE-PUNKTE             ofs    52 len     4  binary PIC 9(9)
      05 KUNDE-GROSS              ofs    56 len     8  comp5 PIC S9(18)
      05 KUNDE-DATUM              ofs    64 len     8  group
        10 KUNDE-JJJJ               ofs    64 len     4  zoned PIC 9(4)
        10 KUNDE-MM                 ofs    68 len     2  zoned PIC 99
        10 KUNDE-TT                 ofs    70 len     2  zoned PIC 99
      05 FILLER                   ofs    72 len     5  text PIC X(5)
      05 KUNDE-BETRAG             ofs    77 len     8  zoned PIC S9(5)V99
      05 KUNDE-KURS               ofs    85 len     8  float
      05 KUNDE-FAKTOR             ofs    93 len     4  float
  }
  KUNDE_NR_OFS = 0;  KUNDE_NR_LEN = 8;
  KUNDE_NAME_OFS = 8;  KUNDE_NAME_LEN = 30;
  KUNDE_STATUS_OFS = 38;  KUNDE_STATUS_LEN = 1;
  KUNDE_AKTIV = 'A';
  KUNDE_GESPERRT = 'S';
  KUNDE_SALDO_OFS = 39;  KUNDE_SALDO_LEN = 6;
  KUNDE_LIMIT_OFS = 45;  KUNDE_LIMIT_LEN = 5;
  KUNDE_ANZAHL_OFS = 50;  KUNDE_ANZAHL_LEN = 2;
  KUNDE_PUNKTE_OFS = 52;  KUNDE_PUNKTE_LEN = 4;
  KUNDE_GROSS_OFS = 56;  KUNDE_GROSS_LEN = 8;
  KUNDE_DATUM_OFS = 64;  KUNDE_DATUM_LEN = 8;
  KUNDE_JJJJ_OFS = 64;  KUNDE_JJJJ_LEN = 4;
  KUNDE_MM_OFS = 68;  KUNDE_MM_LEN = 2;
  KUNDE_TT_OFS = 70;  KUNDE_TT_LEN = 2;
  KUNDE_BETRAG_OFS = 77;  KUNDE_BETRAG_LEN = 8;
  KUNDE_KURS_OFS = 85;  KUNDE_KURS_LEN = 8;
  KUNDE_FAKTOR_OFS = 93;  KUNDE_FAKTOR_LEN = 4;

type
  TKUNDE_SATZ = packed record
    KUNDE_NR: array[0..7] of byte;  { 0 }
    KUNDE_NAME: array[0..29] of byte;  { 8 }
    KUNDE_STATUS: array[0..0] of byte;  { 38 }
    KUNDE_SALDO: array[0..5] of byte;  { 39 }
    KUNDE_LIMIT: array[0..4] of byte;  { 45 }
    KUNDE_ANZAHL: array[0..1] of byte;  { 50 }
    KUNDE_PUNKTE: array[0..3] of byte;  { 52 }
    KUNDE_GROSS: array[0..7] of byte;  { 56 }
    KUNDE_DATUM: packed record
      KUNDE_JJJJ: array[0..3] of byte;  { 64 }
      KUNDE_MM: array[0..1] of byte;  { 68 }
      KUNDE_TT: array[0..1] of byte;  { 70 }
    end;  { 64 }
    FILLER_1: array[0..4] of byte;  { 72 }
    KUNDE_BETRAG: array[0..7] of byte;  { 77 }
    KUNDE_KURS: array[0..7] of byte;  { 85 }
    KUNDE_FAKTOR: array[0..3] of byte;  { 93 }
  end;
  PKUNDE_SATZ = ^TKUNDE_SATZ;

function Get_KUNDE_NR(const r: TKUNDE_SATZ): TDecimal;
procedure Set_KUNDE_NR(var r: TKUNDE_SATZ; const v: TDecimal; rounding: TDecRounding = drTruncate);
function Get_KUNDE_NAME(const r: TKUNDE_SATZ; ccsid: longint = cb_kunde_CCSID): RawByteString;
procedure Set_KUNDE_NAME(var r: TKUNDE_SATZ; const v: RawByteString; ccsid: longint = cb_kunde_CCSID);
function Get_KUNDE_STATUS(const r: TKUNDE_SATZ; ccsid: longint = cb_kunde_CCSID): RawByteString;
procedure Set_KUNDE_STATUS(var r: TKUNDE_SATZ; const v: RawByteString; ccsid: longint = cb_kunde_CCSID);
function Is_KUNDE_AKTIV(const r: TKUNDE_SATZ): boolean;
procedure Set_KUNDE_AKTIV(var r: TKUNDE_SATZ);
function Is_KUNDE_GESPERRT(const r: TKUNDE_SATZ): boolean;
procedure Set_KUNDE_GESPERRT(var r: TKUNDE_SATZ);
function Get_KUNDE_SALDO(const r: TKUNDE_SATZ): TDecimal;
procedure Set_KUNDE_SALDO(var r: TKUNDE_SATZ; const v: TDecimal; rounding: TDecRounding = drTruncate);
function Get_KUNDE_LIMIT(const r: TKUNDE_SATZ): TDecimal;
procedure Set_KUNDE_LIMIT(var r: TKUNDE_SATZ; const v: TDecimal; rounding: TDecRounding = drTruncate);
function Get_KUNDE_ANZAHL(const r: TKUNDE_SATZ): Int64;
procedure Set_KUNDE_ANZAHL(var r: TKUNDE_SATZ; v: Int64);
function Get_KUNDE_PUNKTE(const r: TKUNDE_SATZ): Int64;
procedure Set_KUNDE_PUNKTE(var r: TKUNDE_SATZ; v: Int64);
function Get_KUNDE_GROSS(const r: TKUNDE_SATZ): Int64;
procedure Set_KUNDE_GROSS(var r: TKUNDE_SATZ; v: Int64);
function Get_KUNDE_JJJJ(const r: TKUNDE_SATZ): TDecimal;
procedure Set_KUNDE_JJJJ(var r: TKUNDE_SATZ; const v: TDecimal; rounding: TDecRounding = drTruncate);
function Get_KUNDE_MM(const r: TKUNDE_SATZ): TDecimal;
procedure Set_KUNDE_MM(var r: TKUNDE_SATZ; const v: TDecimal; rounding: TDecRounding = drTruncate);
function Get_KUNDE_TT(const r: TKUNDE_SATZ): TDecimal;
procedure Set_KUNDE_TT(var r: TKUNDE_SATZ; const v: TDecimal; rounding: TDecRounding = drTruncate);
function Get_KUNDE_BETRAG(const r: TKUNDE_SATZ): TDecimal;
procedure Set_KUNDE_BETRAG(var r: TKUNDE_SATZ; const v: TDecimal; rounding: TDecRounding = drTruncate);
function Get_KUNDE_KURS(const r: TKUNDE_SATZ): double;
procedure Set_KUNDE_KURS(var r: TKUNDE_SATZ; v: double);
function Get_KUNDE_FAKTOR(const r: TKUNDE_SATZ): double;
procedure Set_KUNDE_FAKTOR(var r: TKUNDE_SATZ; v: double);
procedure Initialize_KUNDE_SATZ(var r: TKUNDE_SATZ; ccsid: longint = cb_kunde_CCSID);
{ prüft SizeOf und die Offsets der Felder (erste Wiederholung) }
function KUNDE_SATZ_LayoutOk: boolean;

implementation

uses
  sysutils;

function D(const s: string): TDecimal; inline;
begin
  result:=TDecimal.FromString(s);
end;

function AllBytes(const f; len: SizeInt; b: byte): boolean;
var
  i: SizeInt;
begin
  for i:=0 to len-1 do
    if PByte(@f)[i]<>b then
      exit(false);
  result:=true;
end;

function Get_KUNDE_NR(const r: TKUNDE_SATZ): TDecimal;
begin
  result:=ZonedToDecimal(r.KUNDE_NR,8,0,false,zsTrailing);
end;

procedure Set_KUNDE_NR(var r: TKUNDE_SATZ; const v: TDecimal; rounding: TDecRounding = drTruncate);
begin
  DecimalToZoned(v,r.KUNDE_NR,8,0,false,zsTrailing,rounding);
end;

function Get_KUNDE_NAME(const r: TKUNDE_SATZ; ccsid: longint = cb_kunde_CCSID): RawByteString;
begin
  result:=CobGetText(r.KUNDE_NAME,30,ccsid);
end;

procedure Set_KUNDE_NAME(var r: TKUNDE_SATZ; const v: RawByteString; ccsid: longint = cb_kunde_CCSID);
begin
  CobSetText(r.KUNDE_NAME,30,v,ccsid);
end;

function Get_KUNDE_STATUS(const r: TKUNDE_SATZ; ccsid: longint = cb_kunde_CCSID): RawByteString;
begin
  result:=CobGetText(r.KUNDE_STATUS,1,ccsid);
end;

procedure Set_KUNDE_STATUS(var r: TKUNDE_SATZ; const v: RawByteString; ccsid: longint = cb_kunde_CCSID);
begin
  CobSetText(r.KUNDE_STATUS,1,v,ccsid);
end;

function Is_KUNDE_AKTIV(const r: TKUNDE_SATZ): boolean;
begin
  result:=(Get_KUNDE_STATUS(r)=TrimRight('A'));
end;

procedure Set_KUNDE_AKTIV(var r: TKUNDE_SATZ);
begin
  Set_KUNDE_STATUS(r,'A');
end;

function Is_KUNDE_GESPERRT(const r: TKUNDE_SATZ): boolean;
begin
  result:=(Get_KUNDE_STATUS(r)=TrimRight('S')) or
    (Get_KUNDE_STATUS(r)=TrimRight('X'));
end;

procedure Set_KUNDE_GESPERRT(var r: TKUNDE_SATZ);
begin
  Set_KUNDE_STATUS(r,'S');
end;

function Get_KUNDE_SALDO(const r: TKUNDE_SATZ): TDecimal;
begin
  result:=PackedToDecimal(r.KUNDE_SALDO,11,2);
end;

procedure Set_KUNDE_SALDO(var r: TKUNDE_SATZ; const v: TDecimal; rounding: TDecRounding = drTruncate);
begin
  DecimalToPacked(v,r.KUNDE_SALDO,11,2,true,rounding);
end;

function Get_KUNDE_LIMIT(const r: TKUNDE_SATZ): TDecimal;
begin
  result:=PackedToDecimal(r.KUNDE_LIMIT,9,2);
end;

procedure Set_KUNDE_LIMIT(var r: TKUNDE_SATZ; const v: TDecimal; rounding: TDecRounding = drTruncate);
begin
  DecimalToPacked(v,r.KUNDE_LIMIT,9,2,true,rounding);
end;

function Get_KUNDE_ANZAHL(const r: TKUNDE_SATZ): Int64;
begin
  result:=CobGetBinary(r.KUNDE_ANZAHL,2,true);
end;

procedure Set_KUNDE_ANZAHL(var r: TKUNDE_SATZ; v: Int64);
begin
  CobSetBinary(r.KUNDE_ANZAHL,2,true,v,4);
end;

function Get_KUNDE_PUNKTE(const r: TKUNDE_SATZ): Int64;
begin
  result:=CobGetBinary(r.KUNDE_PUNKTE,4,false);
end;

procedure Set_KUNDE_PUNKTE(var r: TKUNDE_SATZ; v: Int64);
begin
  CobSetBinary(r.KUNDE_PUNKTE,4,false,v,9);
end;

function Get_KUNDE_GROSS(const r: TKUNDE_SATZ): Int64;
begin
  result:=CobGetBinary(r.KUNDE_GROSS,8,true);
end;

procedure Set_KUNDE_GROSS(var r: TKUNDE_SATZ; v: Int64);
begin
  CobSetBinary(r.KUNDE_GROSS,8,true,v,0);
end;

function Get_KUNDE_JJJJ(const r: TKUNDE_SATZ): TDecimal;
begin
  result:=ZonedToDecimal(r.KUNDE_DATUM.KUNDE_JJJJ,4,0,false,zsTrailing);
end;

procedure Set_KUNDE_JJJJ(var r: TKUNDE_SATZ; const v: TDecimal; rounding: TDecRounding = drTruncate);
begin
  DecimalToZoned(v,r.KUNDE_DATUM.KUNDE_JJJJ,4,0,false,zsTrailing,rounding);
end;

function Get_KUNDE_MM(const r: TKUNDE_SATZ): TDecimal;
begin
  result:=ZonedToDecimal(r.KUNDE_DATUM.KUNDE_MM,2,0,false,zsTrailing);
end;

procedure Set_KUNDE_MM(var r: TKUNDE_SATZ; const v: TDecimal; rounding: TDecRounding = drTruncate);
begin
  DecimalToZoned(v,r.KUNDE_DATUM.KUNDE_MM,2,0,false,zsTrailing,rounding);
end;

function Get_KUNDE_TT(const r: TKUNDE_SATZ): TDecimal;
begin
  result:=ZonedToDecimal(r.KUNDE_DATUM.KUNDE_TT,2,0,false,zsTrailing);
end;

procedure Set_KUNDE_TT(var r: TKUNDE_SATZ; const v: TDecimal; rounding: TDecRounding = drTruncate);
begin
  DecimalToZoned(v,r.KUNDE_DATUM.KUNDE_TT,2,0,false,zsTrailing,rounding);
end;

function Get_KUNDE_BETRAG(const r: TKUNDE_SATZ): TDecimal;
begin
  result:=ZonedToDecimal(r.KUNDE_BETRAG,7,2,true,zsLeadingSeparate);
end;

procedure Set_KUNDE_BETRAG(var r: TKUNDE_SATZ; const v: TDecimal; rounding: TDecRounding = drTruncate);
begin
  DecimalToZoned(v,r.KUNDE_BETRAG,7,2,true,zsLeadingSeparate,rounding);
end;

function Get_KUNDE_KURS(const r: TKUNDE_SATZ): double;
begin
  result:=HfpToDouble(r.KUNDE_KURS,8);
end;

procedure Set_KUNDE_KURS(var r: TKUNDE_SATZ; v: double);
begin
  DoubleToHfp(v,r.KUNDE_KURS,8);
end;

function Get_KUNDE_FAKTOR(const r: TKUNDE_SATZ): double;
begin
  result:=HfpToDouble(r.KUNDE_FAKTOR,4);
end;

procedure Set_KUNDE_FAKTOR(var r: TKUNDE_SATZ; v: double);
begin
  DoubleToHfp(v,r.KUNDE_FAKTOR,4);
end;

procedure Initialize_KUNDE_SATZ(var r: TKUNDE_SATZ; ccsid: longint = cb_kunde_CCSID);
begin
  FillChar(r,SizeOf(r),0);
  Set_KUNDE_NR(r,TDecimal.Zero);
  Set_KUNDE_NAME(r,'',ccsid);
  Set_KUNDE_STATUS(r,'',ccsid);
  Set_KUNDE_SALDO(r,TDecimal.Zero);
  Set_KUNDE_LIMIT(r,TDecimal.Zero);
  Set_KUNDE_ANZAHL(r,0);
  Set_KUNDE_PUNKTE(r,0);
  Set_KUNDE_GROSS(r,0);
  Set_KUNDE_JJJJ(r,TDecimal.Zero);
  Set_KUNDE_MM(r,TDecimal.Zero);
  Set_KUNDE_TT(r,TDecimal.Zero);
  Set_KUNDE_BETRAG(r,TDecimal.Zero);
  Set_KUNDE_KURS(r,0);
  Set_KUNDE_FAKTOR(r,0);
end;

function KUNDE_SATZ_LayoutOk: boolean;
var
  r: TKUNDE_SATZ;
  b: PtrUInt;
begin
  b:=PtrUInt(@r);
  result:=SizeOf(TKUNDE_SATZ)=97;
  result:=result and (PtrUInt(@r.KUNDE_NR)-b=0);
  result:=result and (PtrUInt(@r.KUNDE_NAME)-b=8);
  result:=result and (PtrUInt(@r.KUNDE_STATUS)-b=38);
  result:=result and (PtrUInt(@r.KUNDE_SALDO)-b=39);
  result:=result and (PtrUInt(@r.KUNDE_LIMIT)-b=45);
  result:=result and (PtrUInt(@r.KUNDE_ANZAHL)-b=50);
  result:=result and (PtrUInt(@r.KUNDE_PUNKTE)-b=52);
  result:=result and (PtrUInt(@r.KUNDE_GROSS)-b=56);
  result:=result and (PtrUInt(@r.KUNDE_DATUM)-b=64);
  result:=result and (PtrUInt(@r.KUNDE_DATUM.KUNDE_JJJJ)-b=64);
  result:=result and (PtrUInt(@r.KUNDE_DATUM.KUNDE_MM)-b=68);
  result:=result and (PtrUInt(@r.KUNDE_DATUM.KUNDE_TT)-b=70);
  result:=result and (PtrUInt(@r.KUNDE_BETRAG)-b=77);
  result:=result and (PtrUInt(@r.KUNDE_KURS)-b=85);
  result:=result and (PtrUInt(@r.KUNDE_FAKTOR)-b=93);
end;

end.
