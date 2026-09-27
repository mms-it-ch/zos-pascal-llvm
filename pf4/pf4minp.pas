program pf4minp;
function pf4min_value: longint; cdecl; external 'pf4min';
begin
  writeln('pf4min_value = ', pf4min_value);
  if pf4min_value <> 42 then halt(1);
end.
