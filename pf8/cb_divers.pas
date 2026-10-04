{ cb_divers: erzeugt von scripts/copybook2pas.py aus divers.cpy, nicht von Hand ändern.
  Felder sind Byte-Felder mit den Offsets des COBOL-Programms (packed, unabhängig von der
  Byte-Reihenfolge); Zugriff über Get_/Set_ (Units zoscobol, zosdecimal, zosccsid).
}
unit cb_divers;

{$mode objfpc}{$H+}
{$R-}

interface

uses
  zoscobol, zosdecimal, zosccsid;

const
  cb_divers_CCSID = 1047;   { CCSID der Textfelder (Standard der Get_/Set_) }

  DIVERS_SIZE = 36;
  { Satzbild DIVERS:
    01 DIVERS                   ofs     0 len    36  group
      05 D-NAT                    ofs     0 len     8  national PIC N(4)
      05 D-EDIT                   ofs     8 len    11  edited PIC ZZZ,ZZ9.99-
      05 D-PROZ                   ofs    19 len     3  zoned PIC SVPP999
      05 D-KENN                   ofs    22 len     2  text PIC X(2)
      05 D-VORZ                   ofs    24 len     3  zoned PIC S9(3)
      05 D-PTR                    ofs    27 len     4  pointer
      05 D-IDX                    ofs    31 len     4  index
      05 TYPE                     ofs    35 len     1  text PIC X
  }
  D_NAT_OFS = 0;  D_NAT_LEN = 8;
  D_EDIT_OFS = 8;  D_EDIT_LEN = 11;
  D_PROZ_OFS = 19;  D_PROZ_LEN = 3;
  D_KENN_OFS = 22;  D_KENN_LEN = 2;
  D_VORZ_OFS = 24;  D_VORZ_LEN = 3;
  D_PTR_OFS = 27;  D_PTR_LEN = 4;
  D_IDX_OFS = 31;  D_IDX_LEN = 4;
  TYPE__OFS = 35;  TYPE__LEN = 1;
  EINZEL_SIZE = 3;
  { Satzbild EINZEL:
    77 EINZEL                   ofs     0 len     3  packed PIC S9(5)
  }

type
  TDIVERS = packed record
    D_NAT: array[0..7] of byte;  { 0 }
    D_EDIT: array[0..10] of byte;  { 8 }
    D_PROZ: array[0..2] of byte;  { 19 }
    D_KENN: array[0..1] of byte;  { 22 }
    D_VORZ: array[0..2] of byte;  { 24 }
    D_PTR: array[0..3] of byte;  { 27 }
    D_IDX: array[0..3] of byte;  { 31 }
    TYPE_: array[0..0] of byte;  { 35 }
  end;
  PDIVERS = ^TDIVERS;
  TEINZEL = array[0..2] of byte;
  PEINZEL = ^TEINZEL;

function Get_D_NAT(const r: TDIVERS): UnicodeString;
procedure Set_D_NAT(var r: TDIVERS; const v: UnicodeString);
function Get_D_EDIT(const r: TDIVERS; ccsid: longint = cb_divers_CCSID): RawByteString;
procedure Set_D_EDIT(var r: TDIVERS; const v: RawByteString; ccsid: longint = cb_divers_CCSID);
function Get_D_PROZ(const r: TDIVERS): TDecimal;
procedure Set_D_PROZ(var r: TDIVERS; const v: TDecimal; rounding: TDecRounding = drTruncate);
function Get_D_KENN(const r: TDIVERS; ccsid: longint = cb_divers_CCSID): RawByteString;
procedure Set_D_KENN(var r: TDIVERS; const v: RawByteString; ccsid: longint = cb_divers_CCSID);
function Is_D_LEER(const r: TDIVERS): boolean;
function Is_D_NULL(const r: TDIVERS): boolean;
function Is_D_HEX(const r: TDIVERS): boolean;
function Get_D_VORZ(const r: TDIVERS): TDecimal;
procedure Set_D_VORZ(var r: TDIVERS; const v: TDecimal; rounding: TDecRounding = drTruncate);
function Get_D_PTR(const r: TDIVERS): Int64;
procedure Set_D_PTR(var r: TDIVERS; v: Int64);
function Get_D_IDX(const r: TDIVERS): Int64;
procedure Set_D_IDX(var r: TDIVERS; v: Int64);
function Get_TYPE_(const r: TDIVERS; ccsid: longint = cb_divers_CCSID): RawByteString;
procedure Set_TYPE_(var r: TDIVERS; const v: RawByteString; ccsid: longint = cb_divers_CCSID);
procedure Initialize_DIVERS(var r: TDIVERS; ccsid: longint = cb_divers_CCSID);
{ prüft SizeOf und die Offsets der Felder (erste Wiederholung) }
function DIVERS_LayoutOk: boolean;
function Get_EINZEL(const r: TEINZEL): TDecimal;
procedure Set_EINZEL(var r: TEINZEL; const v: TDecimal; rounding: TDecRounding = drTruncate);
function Is_EINZEL_NULL(const r: TEINZEL): boolean;
procedure Initialize_EINZEL(var r: TEINZEL; ccsid: longint = cb_divers_CCSID);
{ prüft SizeOf und die Offsets der Felder (erste Wiederholung) }
function EINZEL_LayoutOk: boolean;

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

function Get_D_NAT(const r: TDIVERS): UnicodeString;
begin
  result:=CobGetNational(r.D_NAT,4);
end;

procedure Set_D_NAT(var r: TDIVERS; const v: UnicodeString);
begin
  CobSetNational(r.D_NAT,4,v);
end;

function Get_D_EDIT(const r: TDIVERS; ccsid: longint = cb_divers_CCSID): RawByteString;
begin
  result:=CobGetText(r.D_EDIT,11,ccsid);
end;

procedure Set_D_EDIT(var r: TDIVERS; const v: RawByteString; ccsid: longint = cb_divers_CCSID);
begin
  CobSetText(r.D_EDIT,11,v,ccsid);
end;

function Get_D_PROZ(const r: TDIVERS): TDecimal;
begin
  result:=ZonedToDecimal(r.D_PROZ,3,5,true,zsTrailing);
end;

procedure Set_D_PROZ(var r: TDIVERS; const v: TDecimal; rounding: TDecRounding = drTruncate);
begin
  DecimalToZoned(v,r.D_PROZ,3,5,true,zsTrailing,rounding);
end;

function Get_D_KENN(const r: TDIVERS; ccsid: longint = cb_divers_CCSID): RawByteString;
begin
  result:=CobGetText(r.D_KENN,2,ccsid);
end;

procedure Set_D_KENN(var r: TDIVERS; const v: RawByteString; ccsid: longint = cb_divers_CCSID);
begin
  CobSetText(r.D_KENN,2,v,ccsid);
end;

function Is_D_LEER(const r: TDIVERS): boolean;
begin
  result:=(Get_D_KENN(r)='');
end;

function Is_D_NULL(const r: TDIVERS): boolean;
begin
  result:=AllBytes(r.D_KENN,2,$00);
end;

function Is_D_HEX(const r: TDIVERS): boolean;
begin
  result:=((PByte(@r.D_KENN)[0]=$C1) and (PByte(@r.D_KENN)[1]=$C2));
end;

function Get_D_VORZ(const r: TDIVERS): TDecimal;
begin
  result:=ZonedToDecimal(r.D_VORZ,3,0,true,zsLeading);
end;

procedure Set_D_VORZ(var r: TDIVERS; const v: TDecimal; rounding: TDecRounding = drTruncate);
begin
  DecimalToZoned(v,r.D_VORZ,3,0,true,zsLeading,rounding);
end;

function Get_D_PTR(const r: TDIVERS): Int64;
begin
  result:=CobGetBinary(r.D_PTR,4,false);
end;

procedure Set_D_PTR(var r: TDIVERS; v: Int64);
begin
  CobSetBinary(r.D_PTR,4,false,v,0);
end;

function Get_D_IDX(const r: TDIVERS): Int64;
begin
  result:=CobGetBinary(r.D_IDX,4,false);
end;

procedure Set_D_IDX(var r: TDIVERS; v: Int64);
begin
  CobSetBinary(r.D_IDX,4,false,v,0);
end;

function Get_TYPE_(const r: TDIVERS; ccsid: longint = cb_divers_CCSID): RawByteString;
begin
  result:=CobGetText(r.TYPE_,1,ccsid);
end;

procedure Set_TYPE_(var r: TDIVERS; const v: RawByteString; ccsid: longint = cb_divers_CCSID);
begin
  CobSetText(r.TYPE_,1,v,ccsid);
end;

procedure Initialize_DIVERS(var r: TDIVERS; ccsid: longint = cb_divers_CCSID);
begin
  FillChar(r,SizeOf(r),0);
  Set_D_NAT(r,'');
  Set_D_EDIT(r,'',ccsid);
  Set_D_PROZ(r,TDecimal.Zero);
  Set_D_KENN(r,'',ccsid);
  Set_D_VORZ(r,TDecimal.Zero);
  Set_D_PTR(r,0);
  Set_D_IDX(r,0);
  Set_TYPE_(r,'',ccsid);
end;

function DIVERS_LayoutOk: boolean;
var
  r: TDIVERS;
  b: PtrUInt;
begin
  b:=PtrUInt(@r);
  result:=SizeOf(TDIVERS)=36;
  result:=result and (PtrUInt(@r.D_NAT)-b=0);
  result:=result and (PtrUInt(@r.D_EDIT)-b=8);
  result:=result and (PtrUInt(@r.D_PROZ)-b=19);
  result:=result and (PtrUInt(@r.D_KENN)-b=22);
  result:=result and (PtrUInt(@r.D_VORZ)-b=24);
  result:=result and (PtrUInt(@r.D_PTR)-b=27);
  result:=result and (PtrUInt(@r.D_IDX)-b=31);
  result:=result and (PtrUInt(@r.TYPE_)-b=35);
end;

function Get_EINZEL(const r: TEINZEL): TDecimal;
begin
  result:=PackedToDecimal(r,5,0);
end;

procedure Set_EINZEL(var r: TEINZEL; const v: TDecimal; rounding: TDecRounding = drTruncate);
begin
  DecimalToPacked(v,r,5,0,true,rounding);
end;

function Is_EINZEL_NULL(const r: TEINZEL): boolean;
begin
  result:=Get_EINZEL(r).IsZero;
end;

procedure Initialize_EINZEL(var r: TEINZEL; ccsid: longint = cb_divers_CCSID);
begin
  FillChar(r,SizeOf(r),0);
end;

function EINZEL_LayoutOk: boolean;
var
  r: TEINZEL;
  b: PtrUInt;
begin
  b:=PtrUInt(@r);
  result:=SizeOf(TEINZEL)=3;
end;

end.
