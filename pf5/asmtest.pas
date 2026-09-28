program asmtest;
{ Inline-Assembler (HLASM) auf z/OS: lokale Variablen, Parameter, Result,
  globale Variablen, Recordfelder, Konstanten, Sprungmarken, SS-Befehle mit
  Länge, reine Assembler-Funktion (XPLINK), leerer asm-Block.
  Returncode = Anzahl Fehler. }
{$mode objfpc}{$H+}

type
  TRec = record
    a, b: longint;
    c: array[0..7] of char;
  end;

const
  K = 5;

var
  errors: longint = 0;
  g: longint = 7;

procedure check(const what: string; ok: boolean);
begin
  if ok then writeln('OK      ', what)
  else begin writeln('FEHLER  ', what); inc(errors); end;
end;

function add1(x: longint): longint;
begin
  asm
    L   R1,X          { Parameter }
    AHI R1,1
    ST  R1,RESULT
  end ['r1'];
end;

function sumto(n: longint): longint;
var
  s: longint;
begin
  s := 0;
  asm
    L    1,N
    SR   2,2
  LOOP:
    AR   2,1
    BRCT 1,LOOP       // Sprungmarke
    ST   2,S
  end ['r1','r2'];
  result := s;
end;

procedure incglobal;
begin
  asm
    L   1,G           { globale Variable }
    AHI 1,K           { Pascal-Konstante }
    ST  1,G
  end ['r1'];
end;

procedure setb(var r: TRec);
begin
  asm
    LG  1,R           { var-Parameter: Adresse des Records }
    L   2,TREC.B(1)   { Feldoffset über den Typ }
    AHI 2,K
    ST  2,TREC.B(1)
  end ['r1','r2'];
end;

procedure fields(out res: string);
var
  r: TRec;
  src: array[0..7] of char;
  t: string;
begin
  src := 'ABCDEFGH';
  r.a := 0;
  asm
    MVC R.C(8),SRC    { SS-Befehl mit Länge }
    MVI R.C+7,90      { 'Z' }
    LA  1,R           { Adresse }
    MVHI 0(1),42      { r.a := 42 }
  end ['r1'];
  str(r.a, t);
  res := r.c + '/' + t;
end;

{ reine Assembler-Funktion: Parameter und RESULT stehen für ihr XPLINK-Register
  (a = R1, b = R2, Ergebnis R3), den Rücksprung ergänzt der Compiler }
function pure3(a, b: longint): longint; assembler;
asm
  AR   A,B
  LGFR RESULT,A
end;

procedure empty;
begin
  asm
  end;
end;

var
  r: TRec;
  s: string;
begin
  check('add1(41) = 42', add1(41) = 42);
  check('sumto(10) = 55', sumto(10) = 55);
  incglobal;
  check('globale Variable: g = 12', g = 12);
  r.a := 1; r.b := 37;
  setb(r);
  check('var-Record: r.b = 42', (r.b = 42) and (r.a = 1));
  fields(s);
  check('MVC/MVI/LA: ' + s, s = 'ABCDEFGZ/42');
  check('reine Assembler-Funktion: pure3(40, 2) = 42', pure3(40, 2) = 42);
  empty;
  writeln('Fehler: ', errors);
  halt(errors);
end.
