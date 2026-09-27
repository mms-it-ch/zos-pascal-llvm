program objtest;
{ PF2: Object Pascal mit der Basis-RTL auf z/OS (sysutils, classes, math,
  strutils, dateutils, fgl). Returncode = Anzahl Fehler. }
{$mode objfpc}{$H+}

uses
  SysUtils, Classes, Math, StrUtils, DateUtils, fgl;

var
  errors: longint = 0;

procedure check(const what: string; ok: boolean);
begin
  if ok then
    writeln('OK      ', what)
  else
    begin
      writeln('FEHLER  ', what);
      inc(errors);
    end;
end;

type
  IShape = interface
    ['{9F1B4C2E-6A7D-4E0B-9C3A-2B5E8F10A7D1}']
    function Area: double;
    function Name: string;
  end;

  TShape = class(TInterfacedObject, IShape)
  public
    function Area: double; virtual; abstract;
    function Name: string; virtual;
  end;

  TCircle = class(TShape)
  private
    FR: double;
  public
    constructor Create(r: double);
    function Area: double; override;
    function Name: string; override;
    property Radius: double read FR write FR;
  end;

  TRect = class(TShape)
  private
    FW, FH: double;
  public
    constructor Create(w, h: double);
    function Area: double; override;
  end;

  TIntList = specialize TFPGList<longint>;

function CompareInt(const a, b: longint): integer;
begin
  result := CompareValue(a, b);
end;

function TShape.Name: string;
begin
  result := ClassName;
end;

constructor TCircle.Create(r: double);
begin
  FR := r;
end;

function TCircle.Area: double;
begin
  result := Pi * FR * FR;
end;

function TCircle.Name: string;
begin
  result := 'Kreis';
end;

constructor TRect.Create(w, h: double);
begin
  FW := w;
  FH := h;
end;

function TRect.Area: double;
begin
  result := FW * FH;
end;

var
  sl: TStringList;
  shapes: array of IShape;
  total: double;
  i, n: longint;
  s: string;
  ms: TMemoryStream;
  fs: TFileStream;
  il: TIntList;
  dt: TDateTime;
  caught: boolean;
begin
  writeln('Free Pascal auf z/OS - PF2 Object Pascal');

  { sysutils: Format, Konvertierung }
  check('Format', Format('%d-%s-%.2f', [42, 'z/OS', 3.14159]) = '42-z/OS-3.14');
  check('IntToStr/StrToInt', StrToInt(IntToStr(-123456789)) = -123456789);
  check('FloatToStr', FloatToStr(2.5) = '2.5');
  check('UpperCase/Trim', UpperCase(Trim('  pascal  ')) = 'PASCAL');
  check('IntToHex', IntToHex(255, 4) = '00FF');

  { sysutils-Exceptions }
  caught := false;
  try
    StrToInt('keine Zahl');
  except
    on e: EConvertError do caught := true;
  end;
  check('EConvertError aus StrToInt', caught);

  caught := false;
  try
    raise Exception.CreateFmt('Fehler %d', [7]);
  except
    on e: Exception do caught := e.Message = 'Fehler 7';
  end;
  check('Exception.CreateFmt / Message', caught);

  caught := false;
  try
    try
      raise EInvalidOperation.Create('innen');
    finally
      s := 'finally';
    end;
  except
    on e: EInvalidOperation do caught := s = 'finally';
  end;
  check('EInvalidOperation mit finally', caught);

  caught := false;
  try
    n := 0;
    i := 10 div n;
  except
    on e: EDivByZero do caught := true;
  end;
  check('EDivByZero (Ganzzahl)', caught);

  { Klassen, virtuelle Methoden, Interfaces }
  SetLength(shapes, 3);
  shapes[0] := TCircle.Create(1.0);
  shapes[1] := TRect.Create(2.0, 3.0);
  shapes[2] := TCircle.Create(2.0);
  total := 0;
  for i := 0 to High(shapes) do
    total := total + shapes[i].Area;
  check('virtuelle Methoden über Interfaces', SameValue(total, 6.0 + 5 * Pi, 1e-9));
  check('Name/ClassName', (shapes[0].Name = 'Kreis') and (shapes[1].Name = 'TRect'));
  shapes := nil;   { Referenzzählung gibt die Objekte frei }

  { TStringList }
  sl := TStringList.Create;
  try
    sl.Add('Zürich');
    sl.Add('Bern');
    sl.Add('Basel');
    sl.Sort;
    check('TStringList.Sort', sl.CommaText = 'Basel,Bern,Zürich');
    sl.Values['ort'] := 'Leipzig';
    check('TStringList.Values', sl.Values['ort'] = 'Leipzig');
    sl.SaveToFile('objtest.txt');
    sl.Clear;
    sl.LoadFromFile('objtest.txt');
    check('SaveToFile/LoadFromFile', sl.Count = 4);
  finally
    sl.Free;
  end;
  check('FileExists', FileExists('objtest.txt'));
  check('DeleteFile', DeleteFile('objtest.txt') and not FileExists('objtest.txt'));

  { Streams }
  ms := TMemoryStream.Create;
  try
    for i := 1 to 1000 do
      ms.WriteDWord(i);
    ms.Position := 0;
    n := 0;
    for i := 1 to 1000 do
      inc(n, ms.ReadDWord);
    check('TMemoryStream', (ms.Size = 4000) and (n = 500500));
    ms.SaveToFile('objtest.bin');
  finally
    ms.Free;
  end;
  fs := TFileStream.Create('objtest.bin', fmOpenRead);
  try
    check('TFileStream Größe', fs.Size = 4000);
  finally
    fs.Free;
  end;
  DeleteFile('objtest.bin');

  { Generics }
  il := TIntList.Create;
  try
    for i := 10 downto 1 do
      il.Add(i * i);
    il.Sort(@CompareInt);
  finally
    check('TFPGList Sort', (il.Count = 10) and (il[0] = 1) and (il[9] = 100));
    il.Free;
  end;

  { math, strutils, dateutils }
  check('Math.Power/Log10', SameValue(Power(2, 10), 1024) and SameValue(Log10(1000), 3));
  check('Math.MaxIntValue', MaxIntValue([3, 9, 4]) = 9);
  check('StrUtils.ReverseString', ReverseString('z/OS') = 'SO/z');
  check('StrUtils.ReplaceStr', ReplaceStr('Modula und Modula', 'Modula', 'Pascal') = 'Pascal und Pascal');
  dt := EncodeDate(2026, 9, 27);
  check('DayOfWeek 27.09.2026 = Sonntag', DayOfTheWeek(dt) = 7);
  check('FormatDateTime', FormatDateTime('yyyy-mm-dd', dt) = '2026-09-27');
  check('IncDay', FormatDateTime('dd.mm.yyyy', IncDay(dt, 5)) = '02.10.2026');
  writeln('  Jetzt: ', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));

  writeln('Fehler: ', errors);
  halt(errors);
end.
