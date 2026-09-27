program sigexc;
{ PF3: Signale als Ausnahmen (SIGSEGV, ganzzahlige Division, Blattfunktion).
  Returncode = Anzahl Fehler. }
{$mode objfpc}{$H+}
uses SysUtils;

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

{ Blattfunktionen: keine Aufrufe, kein eigener Frame }
function fdiv(x, y: double): double;
begin
  result := x / y;
end;

function idiv(x, y: longint): longint;
begin
  result := x div y;
end;

procedure poke(p: plongint);
begin
  p^ := 1;
end;

var
  kind: string;
  i, j: longint;
  d: double;
begin
  kind := '';
  try
    poke(nil);
  except
    on e: Exception do kind := e.ClassName;
  end;
  check('nil^ := 1 -> EAccessViolation (' + kind + ')', kind = 'EAccessViolation');

  kind := '';
  i := 1; j := 0;
  try
    i := i div j;
  except
    on e: Exception do kind := e.ClassName;
  end;
  check('i div 0 -> EDivByZero (' + kind + ')', kind = 'EDivByZero');

  kind := '';
  try
    i := idiv(i, j);
  except
    on e: Exception do kind := e.ClassName;
  end;
  check('Blatt: idiv(1,0) -> EDivByZero (' + kind + ')', kind = 'EDivByZero');

  kind := '';
  try
    d := fdiv(1.0, 0.0);
    writeln(d);
  except
    on e: Exception do kind := e.ClassName;
  end;
  check('Blatt: fdiv(1,0) -> EZeroDivide (' + kind + ')', kind = 'EZeroDivide');

  { Lesen über nil löst auf z/OS nichts aus: Adresse 0 ist die PSA (lesbar,
    nur schreibgeschützt) -> kein Test }

  writeln('Fehler: ', errors);
  halt(errors);
end.
