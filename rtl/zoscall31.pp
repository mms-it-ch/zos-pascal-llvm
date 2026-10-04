{
    zos-pascal-llvm: AMODE-31-Programme (COBOL, PL/I, Assembler mit OS-Linkage) aus Pascal
    (AMODE 64) aufrufen.

    Der Aufruf geht über einen Brückenprozess (pf8/zpcall31.s, HLASM, AMODE 31, ohne LE):
    er lädt das Programm (LOAD aus STEPLIB/LNKLST), kopiert die Bereiche in seinen Speicher
    (unter 2 GB), übergibt sie als OS-Parameterliste (R1, Hochbit am letzten Eintrag),
    ruft mit BASSM auf und gibt R15 und die geänderten Bereiche zurück
    (runtime/zosc31.c). Die Bereiche sind gewöhnliche Pascal-Variablen, typischerweise
    Records aus scripts/copybook2pas.py (genaue COBOL-Offsets).

      var s: TCall31Session; k: TKUNDE_SATZ;
      s := TCall31Session.Create;                  // Brücke aus ZOS_CALL31_BRIDGE
      rc := s.Call('KUNDUPD', [Call31Area(k, SizeOf(k))]);
      s.Free;

    Grenzen: Daten nur über die Bereiche (keine Zeiger in den Bereichen - sie zeigen in den
    falschen Prozess), höchstens 32 Bereiche zu je 16 MB, jeder Aufruf kopiert die Daten
    zweimal. COBOL-Programme laufen unter der Brücke als eigene LE-Enclave je Aufruf
    (WORKING-STORAGE wird nicht über Aufrufe gehalten). Siehe pf8/README.md.

    Siehe COPYING.FPC (LGPL mit Ausnahme für statisches Binden).
}
unit zoscall31;

{$mode objfpc}{$H+}

interface

uses
{$ifdef FPC_DOTTEDUNITS}
  System.SysUtils;
{$else}
  sysutils;
{$endif}

type
  ECall31Error = class(Exception)
  public
    Status: longint;   { 1 LOAD gescheitert, 2 Auftrag ungültig, 3 Speicher, -1 Übertragung }
    Code: longint;     { bei Status 1: Abend-/Fehlercode von LOAD }
  end;

  TCall31Area = record
    Data: pointer;
    Len: SizeInt;
  end;

  TCall31Session = class
  private
    FHandle: longint;
  public
    { bridge = '': Umgebungsvariable ZOS_CALL31_BRIDGE, sonst 'zpcall31' im Verzeichnis
      des Programms bzw. im aktuellen Verzeichnis }
    constructor Create(const bridge: string = '');
    destructor Destroy; override;
    { Programm (bis 8 Zeichen) aufrufen; Ergebnis: R15 (RETURN-CODE) }
    function Call(const module: string; const areas: array of TCall31Area): longint;
  end;

function Call31Area(var data; len: SizeInt): TCall31Area;
{ einzelner Aufruf mit eigener Sitzung }
function Call31(const module: string; const areas: array of TCall31Area): longint;

implementation

{ runtime/zosc31.c; auf z/OS mit der RTL gebaut. Andere Plattformen (Tests): die
  Objekte legt tests/run-x86.sh neben die Units, dazu zosdsn.o (CCSID-Tabellen) }
{$L zosc31.o}
{$ifndef zos}
{$L zosdsn.o}
{$linklib c}
{$endif}

function zos_c31_open(bridge: PAnsiChar): longint; cdecl; external name 'FPC_ZOS_C31_OPEN';
function zos_c31_call(s: longint; module: PAnsiChar; n: longint; areas: PPointer;
  lens: PInt64; out rc: longint): longint; cdecl; external name 'FPC_ZOS_C31_CALL';
function zos_c31_close(s: longint): longint; cdecl; external name 'FPC_ZOS_C31_CLOSE';

function Call31Area(var data; len: SizeInt): TCall31Area;
begin
  result.Data:=@data;
  result.Len:=len;
end;

function DefaultBridge: string;
begin
  result:=GetEnvironmentVariable('ZOS_CALL31_BRIDGE');
  if result<>'' then
    exit;
  result:=ExtractFilePath(ParamStr(0))+'zpcall31';
  if not FileExists(result) then
    result:='./zpcall31';
end;

constructor TCall31Session.Create(const bridge: string);
var
  b: string;
  e: ECall31Error;
begin
  inherited Create;
  b:=bridge;
  if b='' then
    b:=DefaultBridge;
  if not FileExists(b) then
    begin
      FHandle:=-1;
      e:=ECall31Error.CreateFmt('AMODE-31-Brücke %s nicht gefunden', [b]);
      e.Status:=-1;
      raise e;
    end;
  FHandle:=zos_c31_open(PAnsiChar(AnsiString(b)));
  if FHandle<0 then
    begin
      e:=ECall31Error.CreateFmt('AMODE-31-Brücke %s nicht gestartet (errno %d)', [b, GetLastOSError]);
      e.Status:=-1;
      raise e;
    end;
end;

destructor TCall31Session.Destroy;
begin
  if FHandle>=0 then
    zos_c31_close(FHandle);
  inherited Destroy;
end;

function TCall31Session.Call(const module: string; const areas: array of TCall31Area): longint;
var
  ptrs: array of pointer;
  lens: array of Int64;
  i, st: longint;
  rc: longint;
  e: ECall31Error;
begin
  SetLength(ptrs,length(areas)+1);
  SetLength(lens,length(areas)+1);
  for i:=0 to high(areas) do
    begin
      ptrs[i]:=areas[i].Data;
      lens[i]:=areas[i].Len;
    end;
  rc:=0;
  st:=zos_c31_call(FHandle,PAnsiChar(AnsiString(module)),length(areas),@ptrs[0],@lens[0],rc);
  if st<>0 then
    begin
      case st of
        1: e:=ECall31Error.CreateFmt('%s: LOAD gescheitert (Code %x)', [module, rc]);
        2: e:=ECall31Error.CreateFmt('%s: Auftrag von der Brücke abgelehnt', [module]);
        3: e:=ECall31Error.CreateFmt('%s: kein Speicher in der Brücke', [module]);
      else
        e:=ECall31Error.CreateFmt('%s: Übertragung zur Brücke gescheitert (errno %d)',
          [module, GetLastOSError]);
      end;
      e.Status:=st;
      e.Code:=rc;
      raise e;
    end;
  result:=rc;
end;

function Call31(const module: string; const areas: array of TCall31Area): longint;
var
  s: TCall31Session;
begin
  s:=TCall31Session.Create;
  try
    result:=s.Call(module,areas);
  finally
    s.Free;
  end;
end;

end.
