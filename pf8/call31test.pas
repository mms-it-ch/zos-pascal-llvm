program call31test;
{ PF8: AMODE-31-Programme aus Pascal (AMODE 64) aufrufen (Unit zoscall31).
  z/OS: Brücke zpcall31 (pf8/zpcall31.s) und die Testprogramme ZPASM1 (HLASM) und ZPCOB1
  (COBOL) in einer Lade-Bibliothek in STEPLIB (pf8/README.md, Abschnitt AMODE 31).
  x86_64: dieselben Prüfungen gegen die Attrappe tests/c/fake_zpcall31.c
  (ZOS_CALL31_BRIDGE). Returncode = Zahl der Fehler. }
{$mode objfpc}{$H+}
uses
  sysutils, zosdecimal, zoscall31, cb_kunde;

var
  errors: longint = 0;
  checks: longint = 0;

procedure check(const what: string; ok: boolean);
begin
  inc(checks);
  if ok then
    writeln('OK      ', what)
  else
    begin
      writeln('FEHLER  ', what);
      inc(errors);
    end;
end;

{ Fullword Big-Endian wie im AMODE-31-Programm (auf z/OS ohnehin die Byte-Reihenfolge) }
procedure setfw(var b: array of byte; v: longint);
begin
  b[0]:=(v shr 24) and $FF; b[1]:=(v shr 16) and $FF; b[2]:=(v shr 8) and $FF; b[3]:=v and $FF;
end;

function getfw(const b: array of byte): longint;
begin
  result:=longint((longword(b[0]) shl 24) or (longword(b[1]) shl 16) or (longword(b[2]) shl 8) or b[3]);
end;

var
  s: TCall31Session;
  a, b, c: array[0..3] of byte;
  k: TKUNDE_SATZ;
  rc, i: longint;
  ok: boolean;
begin
  writeln('Free Pascal auf z/OS - PF8 AMODE-31-Aufrufe');
  try
    s:=TCall31Session.Create;
  except
    on e: ECall31Error do
      begin
        writeln('FEHLER  ', e.Message);
        halt(1);
      end;
  end;
  try
    { HLASM: P3 := P1 + P2 }
    setfw(a,7); setfw(b,35); setfw(c,0);
    rc:=s.Call('ZPASM1',[Call31Area(a,4),Call31Area(b,4),Call31Area(c,4)]);
    check('ZPASM1(7, 35) = 42, R15 0', (getfw(c)=42) and (rc=0));
    setfw(a,-50); setfw(b,8);
    rc:=s.Call('zpasm1',[Call31Area(a,4),Call31Area(b,4),Call31Area(c,4)]);
    check('ZPASM1(-50, 8) = -42, R15 8 (Kleinbuchstaben im Namen)', (getfw(c)=-42) and (rc=8));

    { COBOL mit dem Copybook-Satz KUNDE-SATZ }
    Initialize_KUNDE_SATZ(k);
    Set_KUNDE_NR(k,4711);
    Set_KUNDE_NAME(k,'Muster AG');
    Set_KUNDE_SALDO(k,TDecimal.FromString('-20.25'));
    Set_KUNDE_ANZAHL(k,12);
    rc:=s.Call('ZPCOB1',[Call31Area(k,SizeOf(k))]);
    check('ZPCOB1: RETURN-CODE 4', rc=4);
    check('ZPCOB1: Saldo -20.25 + 100.50 = 80.25', Get_KUNDE_SALDO(k)=TDecimal.FromString('80.25'));
    check('ZPCOB1: Status A', Is_KUNDE_AKTIV(k));
    check('ZPCOB1: Punkte = Anzahl * 10 = 120', Get_KUNDE_PUNKTE(k)=120);
    check('ZPCOB1: übrige Felder unverändert', (Get_KUNDE_NR(k)=TDecimal.FromInt64(4711))
      and (Get_KUNDE_NAME(k)='Muster AG'));

    { 100 Aufrufe in einer Sitzung }
    ok:=true;
    for i:=1 to 100 do
      begin
        setfw(a,i); setfw(b,i);
        s.Call('ZPASM1',[Call31Area(a,4),Call31Area(b,4),Call31Area(c,4)]);
        ok:=ok and (getfw(c)=2*i);
      end;
    check('100 Aufrufe in einer Sitzung', ok);

    { unbekanntes Programm }
    ok:=false;
    try
      s.Call('NIXDA',[]);
    except
      on e: ECall31Error do
        begin
          ok:=e.Status=1;
          writeln('        erwarteter Fehler: ', e.Message);
        end;
    end;
    check('unbekanntes Programm -> ECall31Error (LOAD)', ok);
    { die Sitzung arbeitet danach weiter }
    setfw(a,1); setfw(b,2);
    s.Call('ZPASM1',[Call31Area(a,4),Call31Area(b,4),Call31Area(c,4)]);
    check('Sitzung nach Fehler weiter benutzbar', getfw(c)=3);
    ok:=false;
    try
      s.Call('VIELZULANG',[]);
    except
      on e: ECall31Error do ok:=true;
    end;
    check('Name > 8 Zeichen -> Fehler', ok);
  finally
    s.Free;
  end;
  writeln('Prüfungen: ', checks, ', Fehler: ', errors);
  halt(errors);
end.
