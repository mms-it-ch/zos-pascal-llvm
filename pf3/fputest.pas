program fputest;
{ PF3: Gleitkomma-Ausnahmen und Rundung auf z/OS (FPC-Register, SIGFPE).
  Returncode = Anzahl Fehler. }
{$mode objfpc}{$H+}
uses SysUtils, Math;

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

var
  a, b, c: double;
  kind: string;
  old: TFPUExceptionMask;
begin
  writeln('Free Pascal auf z/OS - PF3 Gleitkomma');
  a := 1.0;
  b := 0.0;

  kind := '';
  try
    c := a / b;
  except
    on e: EZeroDivide do kind := 'EZeroDivide';
    on e: Exception do kind := e.ClassName;
  end;
  check('1/0 -> EZeroDivide (' + kind + ')', kind = 'EZeroDivide');

  kind := '';
  try
    c := MaxDouble;
    c := c * 10;
  except
    on e: EOverflow do kind := 'EOverflow';
    on e: Exception do kind := e.ClassName;
  end;
  check('MaxDouble*10 -> EOverflow (' + kind + ')', kind = 'EOverflow');

  kind := '';
  try
    c := Sqrt(-a);
  except
    on e: EInvalidOp do kind := 'EInvalidOp';
    on e: Exception do kind := e.ClassName;
  end;
  check('Sqrt(-1) -> EInvalidOp (' + kind + ')', kind = 'EInvalidOp');

  { mit maskierten Ausnahmen: Inf/NaN statt Exception }
  old := SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  c := a / b;
  check('maskiert: 1/0 = +Inf', IsInfinite(c) and (c > 0));
  c := b / b;
  check('maskiert: 0/0 = NaN', IsNan(c));
  SetExceptionMask(old);
  check('Maske wiederhergestellt', (GetExceptionMask = old) and not (exZeroDivide in old));

  { Rundungsmodi (Division zur Laufzeit, a/3 statt 1/3) }
  c := 3.0;
  SetRoundMode(rmUp);
  kind := FloatToStr(a / c - 0.333333333333333314829616256247);
  check('rmUp: 1/3 aufgerundet', a / c > 0.333333333333333314829616256247);
  SetRoundMode(rmDown);
  check('rmDown: 1/3 abgerundet', a / c = 0.333333333333333314829616256247);
  check('GetRoundMode = rmDown', GetRoundMode = rmDown);
  SetRoundMode(rmNearest);
  check('GetRoundMode = rmNearest', GetRoundMode = rmNearest);

  writeln('Fehler: ', errors);
  halt(errors);
end.
