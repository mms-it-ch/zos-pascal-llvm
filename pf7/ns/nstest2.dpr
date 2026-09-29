program nstest2;
{$APPTYPE CONSOLE}
{$MODE DELPHIUNICODE}
{$MODESWITCH FUNCTIONREFERENCES}{$MODESWITCH ANONYMOUSFUNCTIONS}
uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Generics.Defaults,
  FpJson.Data, FpJson.Parser;

type
  TPerson = class
    Name: string;
    Alter: Integer;
    constructor Create(const AName: string; AAlter: Integer);
  end;

constructor TPerson.Create(const AName: string; AAlter: Integer);
begin
  Name := AName;
  Alter := AAlter;
end;

var
  L: TObjectList<TPerson>;
  P: TPerson;
  D: TDictionary<string, Integer>;
  J: TJSONData;
  O: TJSONObject;
begin
  L := TObjectList<TPerson>.Create;
  try
    L.Add(TPerson.Create('Vreni', 51));
    L.Add(TPerson.Create('Ueli', 34));
    L.Add(TPerson.Create('Hans', 42));
    L.Sort(TComparer<TPerson>.Construct(
      function(const A, B: TPerson): Integer
      begin
        Result := A.Alter - B.Alter;
      end));
    for P in L do
      Writeln(P.Name, ' ', P.Alter);
  finally
    L.Free;
  end;
  D := TDictionary<string, Integer>.Create;
  D.AddOrSetValue('z/OS', 64);
  Writeln('z/OS=', D['z/OS'], ' Count=', D.Count);
  D.Free;
  J := GetJSON('{"system":"z/OS","bits":64,"le":true}');
  O := J as TJSONObject;
  Writeln(O.Get('system', ''), ' ', O.Integers['bits'], ' ', O.Booleans['le']);
  Writeln(O.AsJSON);
  J.Free;
end.
