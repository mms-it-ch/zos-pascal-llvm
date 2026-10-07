program db2test;
{ PF8: Db2 über ODBC/CLI (Unit zosdb2cli).

    db2test <dsn>|<verbindungszeichenfolge> [tabelle] [in-klausel]

  z/OS:   ./db2test DB2A                  (Location/Subsystem aus DSNAOINI; Benutzer aus
                                           DB2_USER/DB2_PASSWORD, sonst die eigene User-ID)
          ./db2test DB2A HLQ.PASTEST "IN DATABASE DBTEST"
  lokal:  ./db2test "DRIVER=SQLite3;Database=/tmp/db2test.db"   (unixODBC + SQLite)

  Legt die Tabelle an (Standard PASTEST), schreibt, liest, ändert und löscht Zeilen mit
  Parametern (Text, BIGINT, DECIMAL(11,2), DOUBLE, NULL), prüft COMMIT/ROLLBACK, SQLSTATE
  einer fehlerhaften Anweisung und löscht die Tabelle wieder. Returncode = Fehler. }
{$mode objfpc}{$H+}
uses
  sysutils, zosdecimal, zosdb2cli;

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

function D(const s: string): TDecimal;
begin
  result:=TDecimal.FromString(s);
end;

var
  c: TDb2Connection;
  st: TDb2Statement;
  target, tab, inclause: string;
  n: Int64;
  ok: boolean;
  e: EDb2Error;
  sum: TDecimal;
  rows: integer;
begin
  writeln('Free Pascal auf z/OS - PF8 Db2/ODBC');
  if ParamCount<1 then
    begin
      writeln('Aufruf: db2test <dsn>|<verbindungszeichenfolge> [tabelle] [in-klausel]');
      halt(2);
    end;
  target:=ParamStr(1);
  tab:='PASTEST';
  if ParamCount>=2 then tab:=ParamStr(2);
  inclause:='';
  if ParamCount>=3 then inclause:=' '+ParamStr(3);
  if not ZOSDB2CLI_MEASURED then
    writeln('Hinweis: Typgrößen der CLI nicht gemessen (rtl/zosdb2cli_zos.inc, pf8/db2probe_c.c)');
  c:=TDb2Connection.Create;
  try
    if Pos('=',target)>0 then
      c.DriverConnect(target)
    else
      c.Connect(target,GetEnvironmentVariable('DB2_USER'),GetEnvironmentVariable('DB2_PASSWORD'));
    check('verbunden mit '+c.DbmsName, c.Connected);
    try
      c.ExecSQL('DROP TABLE '+tab);
      c.Commit;
    except
      on EDb2Error do c.Rollback;   { gab es nicht }
    end;
    c.ExecSQL('CREATE TABLE '+tab+' (ID INTEGER NOT NULL, NAME VARCHAR(40), '+
      'BETRAG DECIMAL(11,2), KURS DOUBLE)'+inclause);
    c.Commit;
    check('CREATE TABLE '+tab, true);

    st:=c.NewStatement;
    try
      st.Prepare('INSERT INTO '+tab+' (ID, NAME, BETRAG, KURS) VALUES (?, ?, ?, ?)');
      st.SetInt64(1,1); st.SetText(2,'M'#$FC'ller'); st.SetDecimal(3,D('1234.50'),11); st.SetDouble(4,1.5);
      st.Execute;
      check('INSERT 1 (RowCount 1)', st.RowCount=1);
      st.SetInt64(1,2); st.SetText(2,'Meier'); st.SetDecimal(3,D('-0.05'),11); st.SetDouble(4,-2.25);
      st.Execute;
      st.SetInt64(1,3); st.SetNull(2); st.SetDecimal(3,D('99999999.99'),11); st.SetNull(4,SQL_DOUBLE);
      st.Execute;
      check('INSERT 2 und 3 (mit NULL)', st.RowCount=1);
    finally
      st.Free;
    end;
    c.Commit;

    st:=c.NewStatement;
    try
      st.Prepare('SELECT ID, NAME, BETRAG, KURS FROM '+tab+' WHERE BETRAG > ? ORDER BY ID');
      st.SetDecimal(1,D('-1'),11);
      st.Execute;
      check('4 Spalten, Name Spalte 2 = NAME', (st.ColumnCount=4) and SameText(st.ColumnName(2),'NAME'));
      rows:=0;
      sum:=TDecimal.Zero;
      while st.Fetch do
        begin
          inc(rows);
          sum:=sum+st.AsDecimal(3);
          case st.AsInt64(1) of
            1: check('Zeile 1: Name mit Umlaut, Betrag, Kurs',
                 (st.AsString(2)='M'#$FC'ller') and (st.AsDecimal(3)=D('1234.50')) and (st.AsDouble(4)=1.5));
            2: check('Zeile 2: negativer Betrag', (st.AsDecimal(3)=D('-0.05')) and (st.AsDouble(4)=-2.25));
            3: check('Zeile 3: NULL', st.IsNull(2) and st.IsNull(4) and not st.IsNull(3)
                 and (st.AsDecimal(3)=D('99999999.99')));
          end;
        end;
      check('3 Zeilen, Summe 100001234.44', (rows=3) and (sum=D('100001234.44')));
      st.CloseCursor;
    finally
      st.Free;
    end;

    n:=c.ExecSQL('UPDATE '+tab+' SET BETRAG = BETRAG + 1 WHERE ID < 3');
    check('UPDATE 2 Zeilen', n=2);
    c.Rollback;
    st:=c.NewStatement;
    try
      st.ExecDirect('SELECT BETRAG FROM '+tab+' WHERE ID = 1');
      check('ROLLBACK: Betrag unverändert', st.Fetch and (st.AsDecimal(1)=D('1234.50')));
    finally
      st.Free;
    end;
    c.Commit;

    ok:=false;
    try
      c.ExecSQL('SELECT * FROM GIBT_ES_NICHT_4711');
    except
      on ex: EDb2Error do
        begin
          e:=ex;
          ok:=e.SqlState<>'';
          writeln('        erwarteter Fehler: SQLSTATE ', e.SqlState, ', SQLCODE ', e.NativeError);
        end;
    end;
    check('Fehler -> EDb2Error mit SQLSTATE', ok);
    c.Rollback;

    c.ExecSQL('DROP TABLE '+tab);
    c.Commit;
    check('DROP TABLE', true);
    c.Disconnect;
  except
    on ex: Exception do
      begin
        writeln('FEHLER  ', ex.ClassName, ': ', ex.Message);
        inc(errors);
      end;
  end;
  c.Free;
  writeln('Prüfungen: ', checks, ', Fehler: ', errors);
  halt(errors);
end.
