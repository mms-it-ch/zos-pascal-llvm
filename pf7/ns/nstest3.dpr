program nstest3;
{$APPTYPE CONSOLE}
{$MODE DELPHIUNICODE}
uses
  nsunit, System.SysUtils, System.Classes, System.StrUtils, System.DateUtils, System.Math,
  System.TypInfo, System.Rtti;

type
  TFarbe = (Rot, Gruen, Blau);

var
  L: TStringList;
  C: TRttiContext;
  T: TRttiType;
begin
  L := TStringList.Create;
  try
    L.Add('eins'); L.Add('zwei'); L.Add('drei');
    L.Sort;
    Writeln(Joined(L));
  finally
    L.Free;
  end;
  Writeln(ReverseString('z/OS'), ' ', IfThen(True, 'ja', 'nein'));
  Writeln(YearOf(EncodeDate(2026, 9, 29)), ' ', DaysBetween(EncodeDate(2026, 1, 1), EncodeDate(2026, 9, 29)));
  Writeln(Max(3, 7), ' ', GetEnumName(TypeInfo(TFarbe), Ord(Blau)));
  C := TRttiContext.Create;
  T := C.GetType(TypeInfo(TStringList));
  Writeln(T.Name, ' ', T.IsInstance);
  Writeln(System.SysUtils.Format('%s %d', ['Namensraum', 42]));
end.
