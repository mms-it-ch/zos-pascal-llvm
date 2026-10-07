program sqldbtest;
{ PF8: Db2 über fcl-db/SQLDB (TODBCConnection, TSQLQuery).

    sqldbtest <dsn>|<verbindungszeichenfolge> [tabelle] [in-klausel]

  z/OS: TODBCConnection bindet statisch gegen DSNAO64C (FPC-Patch 0045), Typen wie
  zosdb2cli (rtl/zosdb2cli_zos.inc); Aufruf wie pf8/db2test (DSNAOINI, STEPLIB).
  lokal: ./sqldbtest "DRIVER=SQLite3;Database=/tmp/sqldbtest.db" (unixODBC + SQLite).
  Prüft DDL, Parameter (Text, Integer, BCD, Double, NULL), Lesen über TSQLQuery,
  Commit/Rollback, einen SQL-Fehler mit SQLSTATE. Returncode = Zahl der Fehler. }
{$mode objfpc}{$H+}
uses
  sysutils, db, sqldb, odbcconn, fmtbcd;

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

var
  c: TODBCConnection;
  t: TSQLTransaction;
  q: TSQLQuery;
  target, tab, inclause: string;
  ok: boolean;
  fs: TFormatSettings;
  n: integer;

function bcd(const s: string): TBCD;
begin
  result:=StrToBCD(s,fs);
end;

{ Name mit Umlaut: Db2 liefert den Text in der Codepage der Anwendung, der SQLite-Treiber
  UTF-8 ohne passende Kennung des Felds - beides gilt }
function sameName(f: TField; const expected: UnicodeString): boolean;
begin
  result:=(f.AsUnicodeString=expected) or (UTF8Decode(f.AsString)=expected);
end;

{ DECIMAL-Spalte: Db2 liefert BCD (ftFMTBcd/ftBCD), SQLite Text }
function fieldbcd(f: TField): TBCD;
begin
  case f.DataType of
    ftBCD, ftFMTBcd: result:=f.AsBCD;
    ftFloat: result:=DoubleToBCD(f.AsFloat);
  else
    result:=StrToBCD(f.AsString,fs);   { SQLite: Text }
  end;
end;

begin
  writeln('Free Pascal auf z/OS - PF8 Db2 über SQLDB');
  if ParamCount<1 then
    begin
      writeln('Aufruf: sqldbtest <dsn>|<verbindungszeichenfolge> [tabelle] [in-klausel]');
      halt(2);
    end;
  fs:=DefaultFormatSettings;
  fs.DecimalSeparator:='.';
  target:=ParamStr(1);
  tab:='PASSQLDB';
  if ParamCount>=2 then tab:=ParamStr(2);
  inclause:='';
  if ParamCount>=3 then inclause:=' '+ParamStr(3);
  c:=TODBCConnection.Create(nil);
  t:=TSQLTransaction.Create(nil);
  q:=TSQLQuery.Create(nil);
  try
    try
      if Pos('=',target)>0 then
        c.Params.Text:=StringReplace(target,';',LineEnding,[rfReplaceAll])
      else
        begin
          c.DatabaseName:=target;
          c.UserName:=GetEnvironmentVariable('DB2_USER');
          c.Password:=GetEnvironmentVariable('DB2_PASSWORD');
        end;
      c.Transaction:=t;
      q.Database:=c;
      q.Transaction:=t;
      c.Open;
      check('verbunden', c.Connected);
      try
        c.ExecuteDirect('DROP TABLE '+tab);
        t.Commit;
      except
        on EDatabaseError do t.Rollback;
      end;
      c.ExecuteDirect('CREATE TABLE '+tab+' (ID INTEGER NOT NULL, NAME VARCHAR(40), '+
        'BETRAG DECIMAL(11,2), KURS DOUBLE)'+inclause);
      t.Commit;
      check('CREATE TABLE '+tab, true);

      q.SQL.Text:='INSERT INTO '+tab+' (ID, NAME, BETRAG, KURS) VALUES (:ID, :NAME, :BETRAG, :KURS)';
      q.Params.ParamByName('ID').AsInteger:=1;
      q.Params.ParamByName('NAME').AsUnicodeString:='M'#$00FC'ller';
      q.Params.ParamByName('BETRAG').AsFMTBCD:=bcd('1234.50');
      q.Params.ParamByName('KURS').AsFloat:=1.5;
      q.ExecSQL;
      check('INSERT 1 (RowsAffected 1)', q.RowsAffected=1);
      q.Params.ParamByName('ID').AsInteger:=2;
      q.Params.ParamByName('NAME').Clear;
      q.Params.ParamByName('BETRAG').AsFMTBCD:=bcd('-0.05');
      q.Params.ParamByName('KURS').Clear;
      q.ExecSQL;
      t.Commit;
      check('INSERT 2 (NULL) und COMMIT', true);

      q.SQL.Text:='SELECT ID, NAME, BETRAG, KURS FROM '+tab+' ORDER BY ID';
      q.Open;
      writeln('        Feldtypen: ', FieldTypeNames[q.Fields[0].DataType], ' ',
        FieldTypeNames[q.Fields[1].DataType], ' ', FieldTypeNames[q.Fields[2].DataType], ' ',
        FieldTypeNames[q.Fields[3].DataType]);
      n:=0;
      while not q.EOF do
        begin
          inc(n);
          case q.FieldByName('ID').AsInteger of
            1: check('Zeile 1: Name, Betrag, Kurs', sameName(q.FieldByName('NAME'),'M'#$00FC'ller')
                 and (BCDCompare(fieldbcd(q.FieldByName('BETRAG')),bcd('1234.50'))=0)
                 and (q.FieldByName('KURS').AsFloat=1.5));
            2: check('Zeile 2: NULL, negativer Betrag', q.FieldByName('NAME').IsNull
                 and q.FieldByName('KURS').IsNull
                 and (BCDCompare(fieldbcd(q.FieldByName('BETRAG')),bcd('-0.05'))=0));
          end;
          q.Next;
        end;
      q.Close;
      check('2 Zeilen', n=2);

      c.ExecuteDirect('UPDATE '+tab+' SET BETRAG = BETRAG + 1');
      t.Rollback;
      q.SQL.Text:='SELECT BETRAG FROM '+tab+' WHERE ID = 1';
      q.Open;
      check('ROLLBACK: Betrag unverändert', BCDCompare(fieldbcd(q.Fields[0]),bcd('1234.50'))=0);
      q.Close;
      t.Commit;

      ok:=false;
      try
        q.SQL.Text:='SELECT * FROM GIBT_ES_NICHT_4711';
        q.Open;
      except
        on e: ESQLDatabaseError do
          begin
            ok:=e.SQLState<>'';
            writeln('        erwarteter Fehler: SQLSTATE ', e.SQLState, ', Code ', e.ErrorCode);
          end;
      end;
      check('Fehler -> ESQLDatabaseError mit SQLSTATE', ok);
      t.Rollback;
      c.ExecuteDirect('DROP TABLE '+tab);
      t.Commit;
      check('DROP TABLE', true);
      c.Close;
    except
      on e: Exception do
        begin
          writeln('FEHLER  ', e.ClassName, ': ', e.Message);
          inc(errors);
        end;
    end;
  finally
    q.Free;
    t.Free;
    c.Free;
  end;
  writeln('Prüfungen: ', checks, ', Fehler: ', errors);
  halt(errors);
end.
