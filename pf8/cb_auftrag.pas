{ cb_auftrag: erzeugt von scripts/copybook2pas.py aus auftrag.cpy, nicht von Hand ändern.
  Felder sind Byte-Felder mit den Offsets des COBOL-Programms (packed, unabhängig von der
  Byte-Reihenfolge); Zugriff über Get_/Set_ (Units zoscobol, zosdecimal, zosccsid).
}
unit cb_auftrag;

{$mode objfpc}{$H+}
{$R-}

interface

uses
  zoscobol, zosdecimal, zosccsid;

const
  cb_auftrag_CCSID = 1047;   { CCSID der Textfelder (Standard der Get_/Set_) }

  AUFTRAG_SIZE = 175;
  { Satzbild AUFTRAG:
    01 AUFTRAG                  ofs     0 len   175  group
      05 AUF-NR                   ofs     0 len    10  text PIC X(10)
      05 AUF-ART                  ofs    10 len     1  zoned PIC 9
      05 AUF-ADRESSE              ofs    11 len    45  group
        10 AUF-STRASSE              ofs    11 len    25  text PIC X(25)
        10 AUF-ORT                  ofs    36 len    20  text PIC X(20)
      05 AUF-POSTFACH             ofs    11 len    45  group REDEFINES AUF-ADRESSE
        10 AUF-PF-NR                ofs    11 len     6  zoned PIC 9(6)
        10 FILLER                   ofs    17 len    39  text PIC X(39)
      05 AUF-KURZ                 ofs    11 len    10  text PIC X(10) REDEFINES AUF-ADRESSE
      05 AUF-ANZ-POS              ofs    56 len     2  packed PIC S9(3)
      05 AUF-POS                  ofs    58 len    22  group OCCURS 5
        10 POS-ARTIKEL              ofs    58 len     8  text PIC X(8)
        10 POS-MENGE                ofs    66 len     3  packed PIC S9(5)
        10 POS-PREIS                ofs    69 len     5  packed PIC S9(7)V99
        10 POS-RABATT               ofs    74 len     2  zoned PIC 99 OCCURS 3
      05 AUF-SUMME                ofs   168 len     7  packed PIC S9(11)V99
  }
  AUF_NR_OFS = 0;  AUF_NR_LEN = 10;
  AUF_ART_OFS = 10;  AUF_ART_LEN = 1;
  AUF_NORMAL = 1;
  AUF_ADRESSE_OFS = 11;  AUF_ADRESSE_LEN = 45;
  AUF_STRASSE_OFS = 11;  AUF_STRASSE_LEN = 25;
  AUF_ORT_OFS = 36;  AUF_ORT_LEN = 20;
  AUF_POSTFACH_OFS = 11;  AUF_POSTFACH_LEN = 45;
  AUF_PF_NR_OFS = 11;  AUF_PF_NR_LEN = 6;
  AUF_KURZ_OFS = 11;  AUF_KURZ_LEN = 10;
  AUF_ANZ_POS_OFS = 56;  AUF_ANZ_POS_LEN = 2;
  AUF_POS_OFS = 58;  AUF_POS_LEN = 22;
  POS_ARTIKEL_OFS = 58;  POS_ARTIKEL_LEN = 8;
  POS_MENGE_OFS = 66;  POS_MENGE_LEN = 3;
  POS_PREIS_OFS = 69;  POS_PREIS_LEN = 5;
  POS_RABATT_OFS = 74;  POS_RABATT_LEN = 2;
  AUF_SUMME_OFS = 168;  AUF_SUMME_LEN = 7;

type
  TAUFTRAG = packed record
    AUF_NR: array[0..9] of byte;  { 0 }
    AUF_ART: array[0..0] of byte;  { 10 }
    AUF_ADRESSE_R: packed record  { 11, REDEFINES }
      case byte of
        0: (AUF_ADRESSE: packed record
            AUF_STRASSE: array[0..24] of byte;  { 11 }
            AUF_ORT: array[0..19] of byte;  { 36 }
          end);
        1: (AUF_POSTFACH: packed record
            AUF_PF_NR: array[0..5] of byte;  { 11 }
            FILLER_1: array[0..38] of byte;  { 17 }
          end);
        2: (AUF_KURZ: array[0..9] of byte);
    end;
    AUF_ANZ_POS: array[0..1] of byte;  { 56 }
    AUF_POS: packed array[1..5] of packed record
      POS_ARTIKEL: array[0..7] of byte;  { 58 }
      POS_MENGE: array[0..2] of byte;  { 66 }
      POS_PREIS: array[0..4] of byte;  { 69 }
      POS_RABATT: packed array[1..3] of array[0..1] of byte;  { 74 }
    end;  { 58 }
    AUF_SUMME: array[0..6] of byte;  { 168 }
  end;
  PAUFTRAG = ^TAUFTRAG;

function Get_AUF_NR(const r: TAUFTRAG; ccsid: longint = cb_auftrag_CCSID): RawByteString;
procedure Set_AUF_NR(var r: TAUFTRAG; const v: RawByteString; ccsid: longint = cb_auftrag_CCSID);
function Get_AUF_ART(const r: TAUFTRAG): TDecimal;
procedure Set_AUF_ART(var r: TAUFTRAG; const v: TDecimal; rounding: TDecRounding = drTruncate);
function Is_AUF_NORMAL(const r: TAUFTRAG): boolean;
procedure Set_AUF_NORMAL(var r: TAUFTRAG);
function Is_AUF_EIL(const r: TAUFTRAG): boolean;
procedure Set_AUF_EIL(var r: TAUFTRAG);
function Get_AUF_STRASSE(const r: TAUFTRAG; ccsid: longint = cb_auftrag_CCSID): RawByteString;
procedure Set_AUF_STRASSE(var r: TAUFTRAG; const v: RawByteString; ccsid: longint = cb_auftrag_CCSID);
function Get_AUF_ORT(const r: TAUFTRAG; ccsid: longint = cb_auftrag_CCSID): RawByteString;
procedure Set_AUF_ORT(var r: TAUFTRAG; const v: RawByteString; ccsid: longint = cb_auftrag_CCSID);
function Get_AUF_PF_NR(const r: TAUFTRAG): TDecimal;
procedure Set_AUF_PF_NR(var r: TAUFTRAG; const v: TDecimal; rounding: TDecRounding = drTruncate);
function Get_AUF_KURZ(const r: TAUFTRAG; ccsid: longint = cb_auftrag_CCSID): RawByteString;
procedure Set_AUF_KURZ(var r: TAUFTRAG; const v: RawByteString; ccsid: longint = cb_auftrag_CCSID);
function Get_AUF_ANZ_POS(const r: TAUFTRAG): TDecimal;
procedure Set_AUF_ANZ_POS(var r: TAUFTRAG; const v: TDecimal; rounding: TDecRounding = drTruncate);
function Get_POS_ARTIKEL(const r: TAUFTRAG; i1: SizeInt; ccsid: longint = cb_auftrag_CCSID): RawByteString;
procedure Set_POS_ARTIKEL(var r: TAUFTRAG; i1: SizeInt; const v: RawByteString; ccsid: longint = cb_auftrag_CCSID);
function Get_POS_MENGE(const r: TAUFTRAG; i1: SizeInt): TDecimal;
procedure Set_POS_MENGE(var r: TAUFTRAG; i1: SizeInt; const v: TDecimal; rounding: TDecRounding = drTruncate);
function Get_POS_PREIS(const r: TAUFTRAG; i1: SizeInt): TDecimal;
procedure Set_POS_PREIS(var r: TAUFTRAG; i1: SizeInt; const v: TDecimal; rounding: TDecRounding = drTruncate);
function Get_POS_RABATT(const r: TAUFTRAG; i1: SizeInt; i2: SizeInt): TDecimal;
procedure Set_POS_RABATT(var r: TAUFTRAG; i1: SizeInt; i2: SizeInt; const v: TDecimal; rounding: TDecRounding = drTruncate);
function Get_AUF_SUMME(const r: TAUFTRAG): TDecimal;
procedure Set_AUF_SUMME(var r: TAUFTRAG; const v: TDecimal; rounding: TDecRounding = drTruncate);
procedure Initialize_AUFTRAG(var r: TAUFTRAG; ccsid: longint = cb_auftrag_CCSID);
{ prüft SizeOf und die Offsets der Felder (erste Wiederholung) }
function AUFTRAG_LayoutOk: boolean;

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

function Get_AUF_NR(const r: TAUFTRAG; ccsid: longint = cb_auftrag_CCSID): RawByteString;
begin
  result:=CobGetText(r.AUF_NR,10,ccsid);
end;

procedure Set_AUF_NR(var r: TAUFTRAG; const v: RawByteString; ccsid: longint = cb_auftrag_CCSID);
begin
  CobSetText(r.AUF_NR,10,v,ccsid);
end;

function Get_AUF_ART(const r: TAUFTRAG): TDecimal;
begin
  result:=ZonedToDecimal(r.AUF_ART,1,0,false,zsTrailing);
end;

procedure Set_AUF_ART(var r: TAUFTRAG; const v: TDecimal; rounding: TDecRounding = drTruncate);
begin
  DecimalToZoned(v,r.AUF_ART,1,0,false,zsTrailing,rounding);
end;

function Is_AUF_NORMAL(const r: TAUFTRAG): boolean;
begin
  result:=(Get_AUF_ART(r)=D('1'));
end;

procedure Set_AUF_NORMAL(var r: TAUFTRAG);
begin
  Set_AUF_ART(r,D('1'));
end;

function Is_AUF_EIL(const r: TAUFTRAG): boolean;
begin
  result:=((Get_AUF_ART(r)>=D('2')) and (Get_AUF_ART(r)<=D('4')));
end;

procedure Set_AUF_EIL(var r: TAUFTRAG);
begin
  Set_AUF_ART(r,D('2'));
end;

function Get_AUF_STRASSE(const r: TAUFTRAG; ccsid: longint = cb_auftrag_CCSID): RawByteString;
begin
  result:=CobGetText(r.AUF_ADRESSE_R.AUF_ADRESSE.AUF_STRASSE,25,ccsid);
end;

procedure Set_AUF_STRASSE(var r: TAUFTRAG; const v: RawByteString; ccsid: longint = cb_auftrag_CCSID);
begin
  CobSetText(r.AUF_ADRESSE_R.AUF_ADRESSE.AUF_STRASSE,25,v,ccsid);
end;

function Get_AUF_ORT(const r: TAUFTRAG; ccsid: longint = cb_auftrag_CCSID): RawByteString;
begin
  result:=CobGetText(r.AUF_ADRESSE_R.AUF_ADRESSE.AUF_ORT,20,ccsid);
end;

procedure Set_AUF_ORT(var r: TAUFTRAG; const v: RawByteString; ccsid: longint = cb_auftrag_CCSID);
begin
  CobSetText(r.AUF_ADRESSE_R.AUF_ADRESSE.AUF_ORT,20,v,ccsid);
end;

function Get_AUF_PF_NR(const r: TAUFTRAG): TDecimal;
begin
  result:=ZonedToDecimal(r.AUF_ADRESSE_R.AUF_POSTFACH.AUF_PF_NR,6,0,false,zsTrailing);
end;

procedure Set_AUF_PF_NR(var r: TAUFTRAG; const v: TDecimal; rounding: TDecRounding = drTruncate);
begin
  DecimalToZoned(v,r.AUF_ADRESSE_R.AUF_POSTFACH.AUF_PF_NR,6,0,false,zsTrailing,rounding);
end;

function Get_AUF_KURZ(const r: TAUFTRAG; ccsid: longint = cb_auftrag_CCSID): RawByteString;
begin
  result:=CobGetText(r.AUF_ADRESSE_R.AUF_KURZ,10,ccsid);
end;

procedure Set_AUF_KURZ(var r: TAUFTRAG; const v: RawByteString; ccsid: longint = cb_auftrag_CCSID);
begin
  CobSetText(r.AUF_ADRESSE_R.AUF_KURZ,10,v,ccsid);
end;

function Get_AUF_ANZ_POS(const r: TAUFTRAG): TDecimal;
begin
  result:=PackedToDecimal(r.AUF_ANZ_POS,3,0);
end;

procedure Set_AUF_ANZ_POS(var r: TAUFTRAG; const v: TDecimal; rounding: TDecRounding = drTruncate);
begin
  DecimalToPacked(v,r.AUF_ANZ_POS,3,0,true,rounding);
end;

function Get_POS_ARTIKEL(const r: TAUFTRAG; i1: SizeInt; ccsid: longint = cb_auftrag_CCSID): RawByteString;
begin
  result:=CobGetText(r.AUF_POS[i1].POS_ARTIKEL,8,ccsid);
end;

procedure Set_POS_ARTIKEL(var r: TAUFTRAG; i1: SizeInt; const v: RawByteString; ccsid: longint = cb_auftrag_CCSID);
begin
  CobSetText(r.AUF_POS[i1].POS_ARTIKEL,8,v,ccsid);
end;

function Get_POS_MENGE(const r: TAUFTRAG; i1: SizeInt): TDecimal;
begin
  result:=PackedToDecimal(r.AUF_POS[i1].POS_MENGE,5,0);
end;

procedure Set_POS_MENGE(var r: TAUFTRAG; i1: SizeInt; const v: TDecimal; rounding: TDecRounding = drTruncate);
begin
  DecimalToPacked(v,r.AUF_POS[i1].POS_MENGE,5,0,true,rounding);
end;

function Get_POS_PREIS(const r: TAUFTRAG; i1: SizeInt): TDecimal;
begin
  result:=PackedToDecimal(r.AUF_POS[i1].POS_PREIS,9,2);
end;

procedure Set_POS_PREIS(var r: TAUFTRAG; i1: SizeInt; const v: TDecimal; rounding: TDecRounding = drTruncate);
begin
  DecimalToPacked(v,r.AUF_POS[i1].POS_PREIS,9,2,true,rounding);
end;

function Get_POS_RABATT(const r: TAUFTRAG; i1: SizeInt; i2: SizeInt): TDecimal;
begin
  result:=ZonedToDecimal(r.AUF_POS[i1].POS_RABATT[i2],2,0,false,zsTrailing);
end;

procedure Set_POS_RABATT(var r: TAUFTRAG; i1: SizeInt; i2: SizeInt; const v: TDecimal; rounding: TDecRounding = drTruncate);
begin
  DecimalToZoned(v,r.AUF_POS[i1].POS_RABATT[i2],2,0,false,zsTrailing,rounding);
end;

function Get_AUF_SUMME(const r: TAUFTRAG): TDecimal;
begin
  result:=PackedToDecimal(r.AUF_SUMME,13,2);
end;

procedure Set_AUF_SUMME(var r: TAUFTRAG; const v: TDecimal; rounding: TDecRounding = drTruncate);
begin
  DecimalToPacked(v,r.AUF_SUMME,13,2,true,rounding);
end;

procedure Initialize_AUFTRAG(var r: TAUFTRAG; ccsid: longint = cb_auftrag_CCSID);
var
  i1, i2: SizeInt;
begin
  FillChar(r,SizeOf(r),0);
  Set_AUF_NR(r,'',ccsid);
  Set_AUF_ART(r,TDecimal.Zero);
  Set_AUF_STRASSE(r,'',ccsid);
  Set_AUF_ORT(r,'',ccsid);
  Set_AUF_PF_NR(r,TDecimal.Zero);
  Set_AUF_KURZ(r,'',ccsid);
  Set_AUF_ANZ_POS(r,TDecimal.Zero);
  for i1:=1 to 5 do
    Set_POS_ARTIKEL(r, i1,'',ccsid);
  for i1:=1 to 5 do
    Set_POS_MENGE(r, i1,TDecimal.Zero);
  for i1:=1 to 5 do
    Set_POS_PREIS(r, i1,TDecimal.Zero);
  for i1:=1 to 5 do
    for i2:=1 to 3 do
      Set_POS_RABATT(r, i1, i2,TDecimal.Zero);
  Set_AUF_SUMME(r,TDecimal.Zero);
end;

function AUFTRAG_LayoutOk: boolean;
var
  r: TAUFTRAG;
  b: PtrUInt;
begin
  b:=PtrUInt(@r);
  result:=SizeOf(TAUFTRAG)=175;
  result:=result and (PtrUInt(@r.AUF_NR)-b=0);
  result:=result and (PtrUInt(@r.AUF_ART)-b=10);
  result:=result and (PtrUInt(@r.AUF_ADRESSE_R.AUF_ADRESSE)-b=11);
  result:=result and (PtrUInt(@r.AUF_ADRESSE_R.AUF_ADRESSE.AUF_STRASSE)-b=11);
  result:=result and (PtrUInt(@r.AUF_ADRESSE_R.AUF_ADRESSE.AUF_ORT)-b=36);
  result:=result and (PtrUInt(@r.AUF_ADRESSE_R.AUF_POSTFACH)-b=11);
  result:=result and (PtrUInt(@r.AUF_ADRESSE_R.AUF_POSTFACH.AUF_PF_NR)-b=11);
  result:=result and (PtrUInt(@r.AUF_ADRESSE_R.AUF_KURZ)-b=11);
  result:=result and (PtrUInt(@r.AUF_ANZ_POS)-b=56);
  result:=result and (PtrUInt(@r.AUF_POS[1])-b=58);
  result:=result and (PtrUInt(@r.AUF_POS[1].POS_ARTIKEL)-b=58);
  result:=result and (PtrUInt(@r.AUF_POS[1].POS_MENGE)-b=66);
  result:=result and (PtrUInt(@r.AUF_POS[1].POS_PREIS)-b=69);
  result:=result and (PtrUInt(@r.AUF_POS[1].POS_RABATT[1])-b=74);
  result:=result and (PtrUInt(@r.AUF_SUMME)-b=168);
end;

end.
