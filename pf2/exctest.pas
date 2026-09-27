program exctest;
{ PF2: Exceptions auf z/OS (eigener XPLINK-Unwinder, runtime/zosunwind.c).
  Ohne sysutils: eigene Exception-Klassen. Returncode = Anzahl Fehler. }
{$mode objfpc}{$H+}

type
  EBase = class(TObject)
    msg: ansistring;
    constructor Create(const m: ansistring);
  end;
  EFoo = class(EBase);
  EBar = class(EBase);

constructor EBase.Create(const m: ansistring);
begin
  msg := m;
end;

var
  errors: longint = 0;
  trace: ansistring = '';

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

procedure raise_foo(depth: longint);
var
  s: ansistring;
begin
  s := 'Tiefe ' + chr(ord('0') + depth);   { AnsiString muss aufgeräumt werden }
  if depth = 0 then
    raise EFoo.Create('foo aus der Tiefe')
  else
    raise_foo(depth - 1);
  trace := trace + s;                      { nie erreicht }
end;

function with_finally: longint;
begin
  result := 0;
  try
    trace := trace + 'a';
    raise EBar.Create('bar');
  finally
    trace := trace + 'f';
  end;
  result := 1;                             { nie erreicht }
end;

var
  caught, i: longint;
  d: double;
begin
  writeln('Free Pascal auf z/OS - PF2 Exceptions');

  { 1: einfaches raise/except }
  caught := 0;
  try
    raise EFoo.Create('eins');
  except
    on e: EFoo do
      if e.msg = 'eins' then caught := 1;
  end;
  check('raise/except on EFoo', caught = 1);

  { 2: Klassenauswahl: EBar wird nicht von "on EFoo" gefangen }
  caught := 0;
  try
    try
      raise EBar.Create('zwei');
    except
      on e: EFoo do caught := 1;
    end;
  except
    on e: EBar do caught := 2;
  end;
  check('Klassenauswahl (EBar an äußeren Handler)', caught = 2);

  { 3: Exception aus 5 Aufrufebenen Tiefe }
  caught := 0;
  try
    raise_foo(5);
  except
    on e: EBase do
      if e.msg = 'foo aus der Tiefe' then caught := 3;
  end;
  check('Exception aus Tiefe 5', caught = 3);

  { 4: try/finally läuft beim Auslösen, dann äußerer Handler }
  trace := '';
  caught := 0;
  try
    with_finally;
  except
    on e: EBar do caught := 4;
  end;
  check('finally ausgeführt (trace=af)', (caught = 4) and (trace = 'af'));

  { 5: Weiterwerfen }
  caught := 0;
  try
    try
      raise EFoo.Create('fünf');
    except
      on e: EFoo do
        begin
          caught := 1;
          raise;
        end;
    end;
  except
    on e: EFoo do
      if caught = 1 then caught := 5;
  end;
  check('raise; (weiterwerfen)', caught = 5);

  { 6: Gleitkommawerte in Registern bleiben über den Handler erhalten }
  d := 1.5;
  try
    d := d * 2;
    raise EFoo.Create('sechs');
  except
    on e: EFoo do d := d + 0.25;
  end;
  check('Gleitkomma über Exception erhalten (3.25)', d = 3.25);

  { 7: viele Exceptions hintereinander (Speicher, Stack) }
  caught := 0;
  for i := 1 to 1000 do
    try
      raise EFoo.Create('viele');
    except
      on e: EFoo do inc(caught);
    end;
  check('1000 Exceptions', caught = 1000);

  writeln('Fehler: ', errors);
  halt(errors);
end.
