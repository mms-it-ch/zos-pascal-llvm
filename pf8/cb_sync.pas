{ cb_sync: erzeugt von scripts/copybook2pas.py aus sync.cpy, nicht von Hand ändern.
  Felder sind Byte-Felder mit den Offsets des COBOL-Programms (packed, unabhängig von der
  Byte-Reihenfolge); Zugriff über Get_/Set_ (Units zoscobol, zosdecimal, zosccsid).
}
unit cb_sync;

{$mode objfpc}{$H+}
{$R-}

interface

uses
  zoscobol, zosdecimal, zosccsid;

const
  cb_sync_CCSID = 1047;   { CCSID der Textfelder (Standard der Get_/Set_) }

  SYNC_SATZ_SIZE = 87;
  { Satzbild SYNC-SATZ:
    01 SYNC-SATZ                ofs     0 len    87  group
      05 S-KZ                     ofs     0 len     1  text PIC X
      05 S-HALB                   ofs     2 len     2  binary PIC S9(4) SYNC
      05 S-X3                     ofs     4 len     3  text PIC X(3)
      05 S-VOLL                   ofs     8 len     4  binary PIC S9(9) SYNC
      05 S-X1                     ofs    12 len     1  text PIC X
      05 S-DOPPEL                 ofs    16 len     8  binary PIC S9(18) SYNC
      05 S-F1                     ofs    24 len     4  float SYNC
      05 S-TAB                    ofs    28 len     8  group OCCURS 2
        10 T-A                      ofs    28 len     1  text PIC X
        10 T-B                      ofs    32 len     4  binary PIC S9(9) SYNC
      05 S-ANZ                    ofs    44 len     3  zoned PIC 9(3)
      05 S-ZEILE                  ofs    47 len     4  text PIC X(4) OCCURS 1 TO 10 DEPENDING ON S-ANZ
  }
  S_KZ_OFS = 0;  S_KZ_LEN = 1;
  S_HALB_OFS = 2;  S_HALB_LEN = 2;
  S_X3_OFS = 4;  S_X3_LEN = 3;
  S_VOLL_OFS = 8;  S_VOLL_LEN = 4;
  S_X1_OFS = 12;  S_X1_LEN = 1;
  S_DOPPEL_OFS = 16;  S_DOPPEL_LEN = 8;
  S_F1_OFS = 24;  S_F1_LEN = 4;
  S_TAB_OFS = 28;  S_TAB_LEN = 8;
  T_A_OFS = 28;  T_A_LEN = 1;
  T_B_OFS = 32;  T_B_LEN = 4;
  S_ANZ_OFS = 44;  S_ANZ_LEN = 3;
  S_ZEILE_OFS = 47;  S_ZEILE_LEN = 4;

type
  TSYNC_SATZ = packed record
    S_KZ: array[0..0] of byte;  { 0 }
    SLACK_1: array[0..0] of byte;  { SYNC }
    S_HALB: array[0..1] of byte;  { 2 }
    S_X3: array[0..2] of byte;  { 4 }
    SLACK_7: array[0..0] of byte;  { SYNC }
    S_VOLL: array[0..3] of byte;  { 8 }
    S_X1: array[0..0] of byte;  { 12 }
    SLACK_13: array[0..2] of byte;  { SYNC }
    S_DOPPEL: array[0..7] of byte;  { 16 }
    S_F1: array[0..3] of byte;  { 24 }
    S_TAB: packed array[1..2] of packed record
      T_A: array[0..0] of byte;  { 28 }
      SLACK_29: array[0..2] of byte;  { SYNC }
      T_B: array[0..3] of byte;  { 32 }
    end;  { 28 }
    S_ANZ: array[0..2] of byte;  { 44 }
    S_ZEILE: packed array[1..10] of array[0..3] of byte;  { 47 }
  end;
  PSYNC_SATZ = ^TSYNC_SATZ;

function Get_S_KZ(const r: TSYNC_SATZ; ccsid: longint = cb_sync_CCSID): RawByteString;
procedure Set_S_KZ(var r: TSYNC_SATZ; const v: RawByteString; ccsid: longint = cb_sync_CCSID);
function Get_S_HALB(const r: TSYNC_SATZ): Int64;
procedure Set_S_HALB(var r: TSYNC_SATZ; v: Int64);
function Get_S_X3(const r: TSYNC_SATZ; ccsid: longint = cb_sync_CCSID): RawByteString;
procedure Set_S_X3(var r: TSYNC_SATZ; const v: RawByteString; ccsid: longint = cb_sync_CCSID);
function Get_S_VOLL(const r: TSYNC_SATZ): Int64;
procedure Set_S_VOLL(var r: TSYNC_SATZ; v: Int64);
function Get_S_X1(const r: TSYNC_SATZ; ccsid: longint = cb_sync_CCSID): RawByteString;
procedure Set_S_X1(var r: TSYNC_SATZ; const v: RawByteString; ccsid: longint = cb_sync_CCSID);
function Get_S_DOPPEL(const r: TSYNC_SATZ): Int64;
procedure Set_S_DOPPEL(var r: TSYNC_SATZ; v: Int64);
function Get_S_F1(const r: TSYNC_SATZ): double;
procedure Set_S_F1(var r: TSYNC_SATZ; v: double);
function Get_T_A(const r: TSYNC_SATZ; i1: SizeInt; ccsid: longint = cb_sync_CCSID): RawByteString;
procedure Set_T_A(var r: TSYNC_SATZ; i1: SizeInt; const v: RawByteString; ccsid: longint = cb_sync_CCSID);
function Get_T_B(const r: TSYNC_SATZ; i1: SizeInt): Int64;
procedure Set_T_B(var r: TSYNC_SATZ; i1: SizeInt; v: Int64);
function Get_S_ANZ(const r: TSYNC_SATZ): TDecimal;
procedure Set_S_ANZ(var r: TSYNC_SATZ; const v: TDecimal; rounding: TDecRounding = drTruncate);
function Get_S_ZEILE(const r: TSYNC_SATZ; i1: SizeInt; ccsid: longint = cb_sync_CCSID): RawByteString;
procedure Set_S_ZEILE(var r: TSYNC_SATZ; i1: SizeInt; const v: RawByteString; ccsid: longint = cb_sync_CCSID);
procedure Initialize_SYNC_SATZ(var r: TSYNC_SATZ; ccsid: longint = cb_sync_CCSID);
{ prüft SizeOf und die Offsets der Felder (erste Wiederholung) }
function SYNC_SATZ_LayoutOk: boolean;
{ tatsächliche Länge: S-ZEILE OCCURS DEPENDING ON S-ANZ }
function SYNC_SATZ_Length(const r: TSYNC_SATZ): SizeInt;

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

function Get_S_KZ(const r: TSYNC_SATZ; ccsid: longint = cb_sync_CCSID): RawByteString;
begin
  result:=CobGetText(r.S_KZ,1,ccsid);
end;

procedure Set_S_KZ(var r: TSYNC_SATZ; const v: RawByteString; ccsid: longint = cb_sync_CCSID);
begin
  CobSetText(r.S_KZ,1,v,ccsid);
end;

function Get_S_HALB(const r: TSYNC_SATZ): Int64;
begin
  result:=CobGetBinary(r.S_HALB,2,true);
end;

procedure Set_S_HALB(var r: TSYNC_SATZ; v: Int64);
begin
  CobSetBinary(r.S_HALB,2,true,v,4);
end;

function Get_S_X3(const r: TSYNC_SATZ; ccsid: longint = cb_sync_CCSID): RawByteString;
begin
  result:=CobGetText(r.S_X3,3,ccsid);
end;

procedure Set_S_X3(var r: TSYNC_SATZ; const v: RawByteString; ccsid: longint = cb_sync_CCSID);
begin
  CobSetText(r.S_X3,3,v,ccsid);
end;

function Get_S_VOLL(const r: TSYNC_SATZ): Int64;
begin
  result:=CobGetBinary(r.S_VOLL,4,true);
end;

procedure Set_S_VOLL(var r: TSYNC_SATZ; v: Int64);
begin
  CobSetBinary(r.S_VOLL,4,true,v,9);
end;

function Get_S_X1(const r: TSYNC_SATZ; ccsid: longint = cb_sync_CCSID): RawByteString;
begin
  result:=CobGetText(r.S_X1,1,ccsid);
end;

procedure Set_S_X1(var r: TSYNC_SATZ; const v: RawByteString; ccsid: longint = cb_sync_CCSID);
begin
  CobSetText(r.S_X1,1,v,ccsid);
end;

function Get_S_DOPPEL(const r: TSYNC_SATZ): Int64;
begin
  result:=CobGetBinary(r.S_DOPPEL,8,true);
end;

procedure Set_S_DOPPEL(var r: TSYNC_SATZ; v: Int64);
begin
  CobSetBinary(r.S_DOPPEL,8,true,v,18);
end;

function Get_S_F1(const r: TSYNC_SATZ): double;
begin
  result:=HfpToDouble(r.S_F1,4);
end;

procedure Set_S_F1(var r: TSYNC_SATZ; v: double);
begin
  DoubleToHfp(v,r.S_F1,4);
end;

function Get_T_A(const r: TSYNC_SATZ; i1: SizeInt; ccsid: longint = cb_sync_CCSID): RawByteString;
begin
  result:=CobGetText(r.S_TAB[i1].T_A,1,ccsid);
end;

procedure Set_T_A(var r: TSYNC_SATZ; i1: SizeInt; const v: RawByteString; ccsid: longint = cb_sync_CCSID);
begin
  CobSetText(r.S_TAB[i1].T_A,1,v,ccsid);
end;

function Get_T_B(const r: TSYNC_SATZ; i1: SizeInt): Int64;
begin
  result:=CobGetBinary(r.S_TAB[i1].T_B,4,true);
end;

procedure Set_T_B(var r: TSYNC_SATZ; i1: SizeInt; v: Int64);
begin
  CobSetBinary(r.S_TAB[i1].T_B,4,true,v,9);
end;

function Get_S_ANZ(const r: TSYNC_SATZ): TDecimal;
begin
  result:=ZonedToDecimal(r.S_ANZ,3,0,false,zsTrailing);
end;

procedure Set_S_ANZ(var r: TSYNC_SATZ; const v: TDecimal; rounding: TDecRounding = drTruncate);
begin
  DecimalToZoned(v,r.S_ANZ,3,0,false,zsTrailing,rounding);
end;

function Get_S_ZEILE(const r: TSYNC_SATZ; i1: SizeInt; ccsid: longint = cb_sync_CCSID): RawByteString;
begin
  result:=CobGetText(r.S_ZEILE[i1],4,ccsid);
end;

procedure Set_S_ZEILE(var r: TSYNC_SATZ; i1: SizeInt; const v: RawByteString; ccsid: longint = cb_sync_CCSID);
begin
  CobSetText(r.S_ZEILE[i1],4,v,ccsid);
end;

procedure Initialize_SYNC_SATZ(var r: TSYNC_SATZ; ccsid: longint = cb_sync_CCSID);
var
  i1: SizeInt;
begin
  FillChar(r,SizeOf(r),0);
  Set_S_KZ(r,'',ccsid);
  Set_S_HALB(r,0);
  Set_S_X3(r,'',ccsid);
  Set_S_VOLL(r,0);
  Set_S_X1(r,'',ccsid);
  Set_S_DOPPEL(r,0);
  Set_S_F1(r,0);
  for i1:=1 to 2 do
    Set_T_A(r, i1,'',ccsid);
  for i1:=1 to 2 do
    Set_T_B(r, i1,0);
  Set_S_ANZ(r,TDecimal.Zero);
  for i1:=1 to 10 do
    Set_S_ZEILE(r, i1,'',ccsid);
end;

function SYNC_SATZ_LayoutOk: boolean;
var
  r: TSYNC_SATZ;
  b: PtrUInt;
begin
  b:=PtrUInt(@r);
  result:=SizeOf(TSYNC_SATZ)=87;
  result:=result and (PtrUInt(@r.S_KZ)-b=0);
  result:=result and (PtrUInt(@r.S_HALB)-b=2);
  result:=result and (PtrUInt(@r.S_X3)-b=4);
  result:=result and (PtrUInt(@r.S_VOLL)-b=8);
  result:=result and (PtrUInt(@r.S_X1)-b=12);
  result:=result and (PtrUInt(@r.S_DOPPEL)-b=16);
  result:=result and (PtrUInt(@r.S_F1)-b=24);
  result:=result and (PtrUInt(@r.S_TAB[1])-b=28);
  result:=result and (PtrUInt(@r.S_TAB[1].T_A)-b=28);
  result:=result and (PtrUInt(@r.S_TAB[1].T_B)-b=32);
  result:=result and (PtrUInt(@r.S_ANZ)-b=44);
  result:=result and (PtrUInt(@r.S_ZEILE[1])-b=47);
end;

function SYNC_SATZ_Length(const r: TSYNC_SATZ): SizeInt;
var
  n: Int64;
begin
  n:=Get_S_ANZ(r).ToInt64;
  if (n<1) or (n>10) then
    raise EDecimalOverflow.CreateFmt('S-ANZ = %d außerhalb 1..10', [n]);
  result:=47+n*4;
end;

end.
