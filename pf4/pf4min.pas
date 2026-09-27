library pf4min;
{ PF4: minimale Pascal-DLL mit Initialisierungsteil }
function pf4min_value: longint; cdecl;
begin
  pf4min_value := 42;
end;
exports pf4min_value;
begin
  writeln('pf4min: Initialisierung');
end.
