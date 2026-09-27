program pvconst;
{ PF3: Funktions-/Methodenzeiger in typisierten Konstanten vs. @Funktion (XPLINK-Deskriptoren) }
{$mode delphi}
type C = class
    class procedure Foo;
end;
class procedure C.Foo; begin end;
type T = procedure of object;
procedure bar; begin end;
const ViaClass: T = C.Foo;
      PBar: procedure = bar;
var   VBar: procedure = bar;
begin
  writeln('@C.Foo   ', hexstr(PtrUInt(@C.Foo), 16));
  writeln('ViaClass ', hexstr(PtrUInt(TMethod(ViaClass).Code), 16));
  writeln('@bar     ', hexstr(PtrUInt(@bar), 16));
  writeln('PBar     ', hexstr(PtrUInt(@PBar), 16));
  writeln('VBar     ', hexstr(PtrUInt(@VBar), 16));
  if (TMethod(ViaClass).Code = @C.Foo) and (@PBar = @bar) and (@VBar = @bar) then halt(0) else halt(1);
end.
