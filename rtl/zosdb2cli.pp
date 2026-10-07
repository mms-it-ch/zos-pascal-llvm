{
    zos-pascal-llvm: Db2 for z/OS über ODBC/CLI (64 Bit, ASCII-Modus).

    Teil 1: die CLI-Funktionen (SQLAllocHandle, SQLConnect, SQLDriverConnect,
    SQLExecDirect, SQLPrepare, SQLExecute, SQLBindParameter, SQLBindCol, SQLFetch,
    SQLGetData, SQLGetDiagRec, SQLEndTran, SQLFreeHandle, ...) mit Typen und Konstanten.
    Teil 2: eine kleine Klassenschicht (TDb2Connection, TDb2Statement) mit Ausnahmen
    (EDb2Error mit SQLSTATE, SQLCODE und Text), Parametern als Text/Int64/TDecimal/Double
    und Spaltenwerten über SQLGetData.

    z/OS: gebunden wird gegen die DLL DSNAO64C (Sidedeck <db2hlq>.SDSNMACS(DSNAO64C),
    zfpc --db2); Typgrößen in zosdb2cli_zos.inc (Messprogramm pf8/db2probe_c.c), die
    Einstiegsnamen der C-Funktionen ggf. über zosmap.txt (gen-zosmap.py mit
    ZOS_DB2_INCLUDE). Programme brauchen eine ODBC-Initialisierungsdatei (DSNAOINI) mit
    CURRENTAPPENSCHEME=ASCII und den Plan DSNACLI (pf8/README.md).
    Andere Plattformen: unixODBC (libodbc) - dieselbe API, für Tests der Pascal-Seite
    (pf8/db2test.pas mit SQLite).

    Siehe COPYING.FPC (LGPL mit Ausnahme für statisches Binden).
}
unit zosdb2cli;

{$mode objfpc}{$H+}
{$macro on}

interface

uses
{$ifdef FPC_DOTTEDUNITS}
  System.SysUtils,
{$else}
  sysutils,
{$endif}
  zosdecimal;

{$ifdef zos}
{$i zosdb2cli_zos.inc}
{$define CLIEXT:=external}
{$else}
{ unixODBC, LP64 }
type
  SQLCHAR = byte;
  SQLSCHAR = shortint;
  SQLSMALLINT = smallint;
  SQLUSMALLINT = word;
  SQLINTEGER = longint;
  SQLUINTEGER = longword;
  SQLLEN = Int64;
  SQLULEN = QWord;
  SQLRETURN = SQLSMALLINT;
  SQLDOUBLE = double;
  SQLREAL = single;
  SQLPOINTER = pointer;
  SQLHANDLE = pointer;
  SQLHWND = pointer;

const
  ZOSDB2CLI_MEASURED = true;
  clilib = 'odbc';
{$define CLIEXT:=external clilib}
{$endif}

type
  PSQLCHAR = ^SQLCHAR;
  PSQLSMALLINT = ^SQLSMALLINT;
  PSQLINTEGER = ^SQLINTEGER;
  PSQLLEN = ^SQLLEN;
  PSQLULEN = ^SQLULEN;
  SQLHENV = SQLHANDLE;
  SQLHDBC = SQLHANDLE;
  SQLHSTMT = SQLHANDLE;
  SQLHDESC = SQLHANDLE;

const
  SQL_NULL_HANDLE = SQLHANDLE(0);

  { Rückgabewerte }
  SQL_SUCCESS = 0;
  SQL_SUCCESS_WITH_INFO = 1;
  SQL_STILL_EXECUTING = 2;
  SQL_NEED_DATA = 99;
  SQL_NO_DATA = 100;
  SQL_NO_DATA_FOUND = 100;
  SQL_ERROR = -1;
  SQL_INVALID_HANDLE = -2;

  { Handle-Arten }
  SQL_HANDLE_ENV = 1;
  SQL_HANDLE_DBC = 2;
  SQL_HANDLE_STMT = 3;
  SQL_HANDLE_DESC = 4;

  { Attribute }
  SQL_ATTR_ODBC_VERSION = 200;
  SQL_OV_ODBC3 = 3;
  SQL_ATTR_AUTOCOMMIT = 102;
  SQL_AUTOCOMMIT_OFF = 0;
  SQL_AUTOCOMMIT_ON = 1;
  SQL_ATTR_TXN_ISOLATION = 108;
  SQL_TXN_READ_UNCOMMITTED = 1;
  SQL_TXN_READ_COMMITTED = 2;
  SQL_TXN_REPEATABLE_READ = 4;
  SQL_TXN_SERIALIZABLE = 8;
  SQL_ATTR_QUERY_TIMEOUT = 0;
  SQL_ATTR_MAX_ROWS = 1;

  { Transaktionen }
  SQL_COMMIT = 0;
  SQL_ROLLBACK = 1;

  { Längen }
  SQL_NTS = -3;
  SQL_NULL_DATA = -1;
  SQL_DATA_AT_EXEC = -2;

  { SQLDriverConnect }
  SQL_DRIVER_NOPROMPT = 0;

  { SQLFreeStmt }
  SQL_CLOSE = 0;
  SQL_DROP = 1;
  SQL_UNBIND = 2;
  SQL_RESET_PARAMS = 3;

  { Parameterrichtung }
  SQL_PARAM_INPUT = 1;
  SQL_PARAM_INPUT_OUTPUT = 2;
  SQL_PARAM_OUTPUT = 4;

  { C-Datentypen }
  SQL_C_CHAR = 1;
  SQL_C_LONG = 4;
  SQL_C_SHORT = 5;
  SQL_C_FLOAT = 7;
  SQL_C_DOUBLE = 8;
  SQL_C_BINARY = -2;
  SQL_C_SBIGINT = -25;
  SQL_C_DEFAULT = 99;

  { SQL-Datentypen }
  SQL_UNKNOWN_TYPE = 0;
  SQL_CHAR = 1;
  SQL_NUMERIC = 2;
  SQL_DECIMAL = 3;
  SQL_INTEGER = 4;
  SQL_SMALLINT = 5;
  SQL_FLOAT = 6;
  SQL_REAL = 7;
  SQL_DOUBLE = 8;
  SQL_VARCHAR = 12;
  SQL_TYPE_DATE = 91;
  SQL_TYPE_TIME = 92;
  SQL_TYPE_TIMESTAMP = 93;
  SQL_LONGVARCHAR = -1;
  SQL_BINARY = -2;
  SQL_VARBINARY = -3;
  SQL_BIGINT = -5;
  { Db2-spezifisch (sqlcli1.h) }
  SQL_GRAPHIC = -95;
  SQL_VARGRAPHIC = -96;
  SQL_BLOB = -98;
  SQL_CLOB = -99;

  { Nullbarkeit }
  SQL_NO_NULLS = 0;
  SQL_NULLABLE = 1;

  { SQLGetInfo }
  SQL_DBMS_NAME = 17;
  SQL_DBMS_VER = 18;

  SQL_MAX_MESSAGE_LENGTH = 1024;
  SQL_SQLSTATE_SIZE = 5;

{ ---------------------------------------------------------------------------------- }
{ CLI-Funktionen                                                                      }

function SQLAllocHandle(HandleType: SQLSMALLINT; InputHandle: SQLHANDLE;
  out OutputHandle: SQLHANDLE): SQLRETURN; cdecl; CLIEXT name 'SQLAllocHandle';
function SQLFreeHandle(HandleType: SQLSMALLINT; Handle: SQLHANDLE): SQLRETURN;
  cdecl; CLIEXT name 'SQLFreeHandle';
function SQLSetEnvAttr(EnvironmentHandle: SQLHENV; Attribute: SQLINTEGER; Value: SQLPOINTER;
  StringLength: SQLINTEGER): SQLRETURN; cdecl; CLIEXT name 'SQLSetEnvAttr';
function SQLSetConnectAttr(ConnectionHandle: SQLHDBC; Attribute: SQLINTEGER; Value: SQLPOINTER;
  StringLength: SQLINTEGER): SQLRETURN; cdecl; CLIEXT name 'SQLSetConnectAttr';
function SQLGetConnectAttr(ConnectionHandle: SQLHDBC; Attribute: SQLINTEGER; Value: SQLPOINTER;
  BufferLength: SQLINTEGER; StringLength: PSQLINTEGER): SQLRETURN; cdecl; CLIEXT name 'SQLGetConnectAttr';
function SQLSetStmtAttr(StatementHandle: SQLHSTMT; Attribute: SQLINTEGER; Value: SQLPOINTER;
  StringLength: SQLINTEGER): SQLRETURN; cdecl; CLIEXT name 'SQLSetStmtAttr';
function SQLConnect(ConnectionHandle: SQLHDBC; ServerName: PSQLCHAR; NameLength1: SQLSMALLINT;
  UserName: PSQLCHAR; NameLength2: SQLSMALLINT; Authentication: PSQLCHAR;
  NameLength3: SQLSMALLINT): SQLRETURN; cdecl; CLIEXT name 'SQLConnect';
function SQLDriverConnect(ConnectionHandle: SQLHDBC; WindowHandle: SQLHWND;
  InConnectionString: PSQLCHAR; StringLength1: SQLSMALLINT; OutConnectionString: PSQLCHAR;
  BufferLength: SQLSMALLINT; StringLength2Ptr: PSQLSMALLINT;
  DriverCompletion: SQLUSMALLINT): SQLRETURN; cdecl; CLIEXT name 'SQLDriverConnect';
function SQLDisconnect(ConnectionHandle: SQLHDBC): SQLRETURN; cdecl; CLIEXT name 'SQLDisconnect';
function SQLExecDirect(StatementHandle: SQLHSTMT; StatementText: PSQLCHAR;
  TextLength: SQLINTEGER): SQLRETURN; cdecl; CLIEXT name 'SQLExecDirect';
function SQLPrepare(StatementHandle: SQLHSTMT; StatementText: PSQLCHAR;
  TextLength: SQLINTEGER): SQLRETURN; cdecl; CLIEXT name 'SQLPrepare';
function SQLExecute(StatementHandle: SQLHSTMT): SQLRETURN; cdecl; CLIEXT name 'SQLExecute';
function SQLBindParameter(StatementHandle: SQLHSTMT; ParameterNumber: SQLUSMALLINT;
  InputOutputType: SQLSMALLINT; ValueType: SQLSMALLINT; ParameterType: SQLSMALLINT;
  ColumnSize: SQLULEN; DecimalDigits: SQLSMALLINT; ParameterValuePtr: SQLPOINTER;
  BufferLength: SQLLEN; StrLen_or_IndPtr: PSQLLEN): SQLRETURN; cdecl; CLIEXT name 'SQLBindParameter';
function SQLBindCol(StatementHandle: SQLHSTMT; ColumnNumber: SQLUSMALLINT;
  TargetType: SQLSMALLINT; TargetValue: SQLPOINTER; BufferLength: SQLLEN;
  StrLen_or_Ind: PSQLLEN): SQLRETURN; cdecl; CLIEXT name 'SQLBindCol';
function SQLFetch(StatementHandle: SQLHSTMT): SQLRETURN; cdecl; CLIEXT name 'SQLFetch';
function SQLGetData(StatementHandle: SQLHSTMT; ColumnNumber: SQLUSMALLINT;
  TargetType: SQLSMALLINT; TargetValue: SQLPOINTER; BufferLength: SQLLEN;
  StrLen_or_Ind: PSQLLEN): SQLRETURN; cdecl; CLIEXT name 'SQLGetData';
function SQLNumResultCols(StatementHandle: SQLHSTMT; out ColumnCount: SQLSMALLINT): SQLRETURN;
  cdecl; CLIEXT name 'SQLNumResultCols';
function SQLDescribeCol(StatementHandle: SQLHSTMT; ColumnNumber: SQLUSMALLINT;
  ColumnName: PSQLCHAR; BufferLength: SQLSMALLINT; NameLength: PSQLSMALLINT;
  DataType: PSQLSMALLINT; ColumnSize: PSQLULEN; DecimalDigits: PSQLSMALLINT;
  Nullable: PSQLSMALLINT): SQLRETURN; cdecl; CLIEXT name 'SQLDescribeCol';
function SQLRowCount(StatementHandle: SQLHSTMT; out RowCount: SQLLEN): SQLRETURN;
  cdecl; CLIEXT name 'SQLRowCount';
function SQLNumParams(StatementHandle: SQLHSTMT; out ParameterCount: SQLSMALLINT): SQLRETURN;
  cdecl; CLIEXT name 'SQLNumParams';
function SQLGetDiagRec(HandleType: SQLSMALLINT; Handle: SQLHANDLE; RecNumber: SQLSMALLINT;
  Sqlstate: PSQLCHAR; NativeError: PSQLINTEGER; MessageText: PSQLCHAR;
  BufferLength: SQLSMALLINT; TextLength: PSQLSMALLINT): SQLRETURN; cdecl; CLIEXT name 'SQLGetDiagRec';
function SQLEndTran(HandleType: SQLSMALLINT; Handle: SQLHANDLE;
  CompletionType: SQLSMALLINT): SQLRETURN; cdecl; CLIEXT name 'SQLEndTran';
function SQLFreeStmt(StatementHandle: SQLHSTMT; Option: SQLUSMALLINT): SQLRETURN;
  cdecl; CLIEXT name 'SQLFreeStmt';
function SQLCloseCursor(StatementHandle: SQLHSTMT): SQLRETURN; cdecl; CLIEXT name 'SQLCloseCursor';
function SQLMoreResults(StatementHandle: SQLHSTMT): SQLRETURN; cdecl; CLIEXT name 'SQLMoreResults';
function SQLCancel(StatementHandle: SQLHSTMT): SQLRETURN; cdecl; CLIEXT name 'SQLCancel';
function SQLGetInfo(ConnectionHandle: SQLHDBC; InfoType: SQLUSMALLINT; InfoValue: SQLPOINTER;
  BufferLength: SQLSMALLINT; StringLength: PSQLSMALLINT): SQLRETURN; cdecl; CLIEXT name 'SQLGetInfo';
function SQLTables(StatementHandle: SQLHSTMT; CatalogName: PSQLCHAR; NameLength1: SQLSMALLINT;
  SchemaName: PSQLCHAR; NameLength2: SQLSMALLINT; TableName: PSQLCHAR; NameLength3: SQLSMALLINT;
  TableType: PSQLCHAR; NameLength4: SQLSMALLINT): SQLRETURN; cdecl; CLIEXT name 'SQLTables';
function SQLColumns(StatementHandle: SQLHSTMT; CatalogName: PSQLCHAR; NameLength1: SQLSMALLINT;
  SchemaName: PSQLCHAR; NameLength2: SQLSMALLINT; TableName: PSQLCHAR; NameLength3: SQLSMALLINT;
  ColumnName: PSQLCHAR; NameLength4: SQLSMALLINT): SQLRETURN; cdecl; CLIEXT name 'SQLColumns';

function SQL_SUCCEEDED(rc: SQLRETURN): boolean; inline;

{ ---------------------------------------------------------------------------------- }
{ Klassenschicht                                                                      }

type
  EDb2Error = class(Exception)
  public
    SqlState: string;      { erster Diagnosesatz }
    NativeError: longint;  { Db2: SQLCODE }
    ReturnCode: SQLRETURN;
  end;

  { Text der Diagnosesätze eines Handles ("SQLSTATE 42704 (-204): ...", je Zeile) }
function Db2DiagText(HandleType: SQLSMALLINT; Handle: SQLHANDLE): string;
{ rc prüfen: SQL_ERROR/SQL_INVALID_HANDLE -> EDb2Error; sonst rc zurück }
function Db2Check(rc: SQLRETURN; HandleType: SQLSMALLINT; Handle: SQLHANDLE;
  const what: string): SQLRETURN;

type
  TDb2Connection = class;

  TDb2ParamKind = (dpNull, dpText, dpInt64, dpDouble, dpDecimal);

  TDb2Statement = class
  private
    FConn: TDb2Connection;
    FHandle: SQLHSTMT;
    FParams: array of record
      kind: TDb2ParamKind;
      buf: RawByteString;      { Text, Dezimalzahl als Text }
      i64: Int64;
      dbl: double;
      ind: SQLLEN;             { Länge bzw. SQL_NULL_DATA }
      sqltype: SQLSMALLINT;
      prec, scale: integer;
    end;
    procedure NeedParam(n: integer);
    function Check(rc: SQLRETURN; const what: string): SQLRETURN;
  public
    constructor Create(AConn: TDb2Connection);
    destructor Destroy; override;
    procedure Prepare(const sql: RawByteString);
    { Parameter 1..n vor Execute setzen (Eingabe) }
    procedure SetText(n: integer; const v: RawByteString);
    procedure SetInt64(n: integer; v: Int64);
    procedure SetDouble(n: integer; v: double);
    { DECIMAL(precision, scale): als Text übergeben, Db2 wandelt um }
    procedure SetDecimal(n: integer; const v: TDecimal; precision: integer = 31);
    procedure SetNull(n: integer; sqltype: SQLSMALLINT = SQL_VARCHAR);
    procedure Execute;
    procedure ExecDirect(const sql: RawByteString);
    { nächste Zeile; false am Ende }
    function Fetch: boolean;
    procedure CloseCursor;
    function ColumnCount: integer;
    function ColumnName(col: integer): string;
    { Spaltenwerte der aktuellen Zeile (je Spalte nur einmal abrufen, SQLGetData) }
    function IsNull(col: integer): boolean;
    function AsString(col: integer): RawByteString;
    function AsInt64(col: integer): Int64;
    function AsDecimal(col: integer): TDecimal;
    function AsDouble(col: integer): double;
    function RowCount: Int64;
    property Handle: SQLHSTMT read FHandle;
  private
    FNullCache: array of SQLSMALLINT;   { -1 unbekannt, 0 Wert, 1 NULL }
    FValueCache: array of RawByteString;
    procedure LoadColumn(col: integer);
  end;

  TDb2Connection = class
  private
    FEnv: SQLHENV;
    FDbc: SQLHDBC;
    FConnected: boolean;
  public
    { Umgebung (ODBC 3), Verbindung mit AUTOCOMMIT aus }
    constructor Create;
    destructor Destroy; override;
    { Datenquelle (Db2 z/OS: Location bzw. Subsystem aus DSNAOINI) }
    procedure Connect(const dsn: RawByteString; const user: RawByteString = '';
      const password: RawByteString = '');
    { Verbindungszeichenfolge, z. B. 'DSN=DB2A' oder 'DRIVER=SQLite3;Database=x.db' }
    procedure DriverConnect(const connstr: RawByteString);
    procedure Disconnect;
    procedure SetAutoCommit(on: boolean);
    procedure Commit;
    procedure Rollback;
    { SQL ohne Ergebnis; Ergebnis: betroffene Zeilen }
    function ExecSQL(const sql: RawByteString): Int64;
    function NewStatement: TDb2Statement;
    function DbmsName: string;
    property EnvHandle: SQLHENV read FEnv;
    property DbcHandle: SQLHDBC read FDbc;
    property Connected: boolean read FConnected;
  end;

implementation

function SQL_SUCCEEDED(rc: SQLRETURN): boolean;
begin
  result:=(rc=SQL_SUCCESS) or (rc=SQL_SUCCESS_WITH_INFO);
end;

function Db2DiagText(HandleType: SQLSMALLINT; Handle: SQLHANDLE): string;
var
  state: array[0..SQL_SQLSTATE_SIZE] of AnsiChar;
  msg: array[0..SQL_MAX_MESSAGE_LENGTH] of AnsiChar;
  native: SQLINTEGER;
  len: SQLSMALLINT;
  i: SQLSMALLINT;
begin
  result:='';
  i:=1;
  while SQL_SUCCEEDED(SQLGetDiagRec(HandleType,Handle,i,@state,@native,@msg,
    SizeOf(msg),@len)) do
    begin
      if result<>'' then
        result:=result+LineEnding;
      result:=result+Format('SQLSTATE %s (%d): %s', [PAnsiChar(@state), native, PAnsiChar(@msg)]);
      inc(i);
    end;
end;

function Db2Check(rc: SQLRETURN; HandleType: SQLSMALLINT; Handle: SQLHANDLE;
  const what: string): SQLRETURN;
var
  e: EDb2Error;
  state: array[0..SQL_SQLSTATE_SIZE] of AnsiChar;
  msg: array[0..SQL_MAX_MESSAGE_LENGTH] of AnsiChar;
  native: SQLINTEGER;
  len: SQLSMALLINT;
begin
  result:=rc;
  if (rc<>SQL_ERROR) and (rc<>SQL_INVALID_HANDLE) then
    exit;
  if rc=SQL_INVALID_HANDLE then
    e:=EDb2Error.CreateFmt('%s: ungültiges Handle', [what])
  else
    e:=EDb2Error.CreateFmt('%s: %s', [what, Db2DiagText(HandleType,Handle)]);
  e.ReturnCode:=rc;
  e.SqlState:='';
  e.NativeError:=0;
  if (rc=SQL_ERROR) and SQL_SUCCEEDED(SQLGetDiagRec(HandleType,Handle,1,@state,@native,
    @msg,SizeOf(msg),@len)) then
    begin
      e.SqlState:=PAnsiChar(@state);
      e.NativeError:=native;
    end;
  raise e;
end;

{ ---------------------------------------------------------------------------------- }
{ TDb2Connection                                                                      }

constructor TDb2Connection.Create;
var
  h: SQLHANDLE;
begin
  inherited Create;
  if not SQL_SUCCEEDED(SQLAllocHandle(SQL_HANDLE_ENV,SQL_NULL_HANDLE,h)) then
    raise EDb2Error.Create('SQLAllocHandle(ENV) gescheitert (ODBC-Treiber/DSNAOINI?)');
  FEnv:=h;
  Db2Check(SQLSetEnvAttr(FEnv,SQL_ATTR_ODBC_VERSION,SQLPOINTER(PtrUInt(SQL_OV_ODBC3)),0),
    SQL_HANDLE_ENV,FEnv,'SQLSetEnvAttr(ODBC_VERSION)');
  Db2Check(SQLAllocHandle(SQL_HANDLE_DBC,FEnv,h),SQL_HANDLE_ENV,FEnv,'SQLAllocHandle(DBC)');
  FDbc:=h;
end;

destructor TDb2Connection.Destroy;
begin
  if FConnected then
    begin
      SQLEndTran(SQL_HANDLE_DBC,FDbc,SQL_ROLLBACK);
      SQLDisconnect(FDbc);
    end;
  if FDbc<>SQL_NULL_HANDLE then
    SQLFreeHandle(SQL_HANDLE_DBC,FDbc);
  if FEnv<>SQL_NULL_HANDLE then
    SQLFreeHandle(SQL_HANDLE_ENV,FEnv);
  inherited Destroy;
end;

function PCharOrNil(const s: RawByteString): PSQLCHAR;
begin
  if s='' then
    result:=nil
  else
    result:=PSQLCHAR(PAnsiChar(s));
end;

procedure TDb2Connection.Connect(const dsn, user, password: RawByteString);
begin
  Db2Check(SQLConnect(FDbc,PCharOrNil(dsn),SQL_NTS,PCharOrNil(user),SQL_NTS,
    PCharOrNil(password),SQL_NTS),SQL_HANDLE_DBC,FDbc,'SQLConnect('+dsn+')');
  FConnected:=true;
  SetAutoCommit(false);
end;

procedure TDb2Connection.DriverConnect(const connstr: RawByteString);
var
  outlen: SQLSMALLINT;
begin
  Db2Check(SQLDriverConnect(FDbc,nil,PSQLCHAR(PAnsiChar(connstr)),SQL_NTS,nil,0,@outlen,
    SQL_DRIVER_NOPROMPT),SQL_HANDLE_DBC,FDbc,'SQLDriverConnect');
  FConnected:=true;
  SetAutoCommit(false);
end;

procedure TDb2Connection.Disconnect;
begin
  if not FConnected then
    exit;
  Db2Check(SQLDisconnect(FDbc),SQL_HANDLE_DBC,FDbc,'SQLDisconnect');
  FConnected:=false;
end;

procedure TDb2Connection.SetAutoCommit(on: boolean);
begin
  Db2Check(SQLSetConnectAttr(FDbc,SQL_ATTR_AUTOCOMMIT,SQLPOINTER(PtrUInt(ord(on))),0),
    SQL_HANDLE_DBC,FDbc,'SQLSetConnectAttr(AUTOCOMMIT)');
end;

procedure TDb2Connection.Commit;
begin
  Db2Check(SQLEndTran(SQL_HANDLE_DBC,FDbc,SQL_COMMIT),SQL_HANDLE_DBC,FDbc,'COMMIT');
end;

procedure TDb2Connection.Rollback;
begin
  Db2Check(SQLEndTran(SQL_HANDLE_DBC,FDbc,SQL_ROLLBACK),SQL_HANDLE_DBC,FDbc,'ROLLBACK');
end;

function TDb2Connection.ExecSQL(const sql: RawByteString): Int64;
var
  st: TDb2Statement;
begin
  st:=NewStatement;
  try
    st.ExecDirect(sql);
    result:=st.RowCount;
  finally
    st.Free;
  end;
end;

function TDb2Connection.NewStatement: TDb2Statement;
begin
  result:=TDb2Statement.Create(self);
end;

function TDb2Connection.DbmsName: string;
var
  buf: array[0..127] of AnsiChar;
  len: SQLSMALLINT;
begin
  buf[0]:=#0;
  Db2Check(SQLGetInfo(FDbc,SQL_DBMS_NAME,@buf,SizeOf(buf),@len),SQL_HANDLE_DBC,FDbc,
    'SQLGetInfo(DBMS_NAME)');
  result:=PAnsiChar(@buf);
end;

{ ---------------------------------------------------------------------------------- }
{ TDb2Statement                                                                       }

constructor TDb2Statement.Create(AConn: TDb2Connection);
var
  h: SQLHANDLE;
begin
  inherited Create;
  FConn:=AConn;
  Db2Check(SQLAllocHandle(SQL_HANDLE_STMT,AConn.FDbc,h),SQL_HANDLE_DBC,AConn.FDbc,
    'SQLAllocHandle(STMT)');
  FHandle:=h;
end;

destructor TDb2Statement.Destroy;
begin
  if FHandle<>SQL_NULL_HANDLE then
    SQLFreeHandle(SQL_HANDLE_STMT,FHandle);
  inherited Destroy;
end;

function TDb2Statement.Check(rc: SQLRETURN; const what: string): SQLRETURN;
begin
  result:=Db2Check(rc,SQL_HANDLE_STMT,FHandle,what);
end;

procedure TDb2Statement.Prepare(const sql: RawByteString);
begin
  Check(SQLFreeStmt(FHandle,SQL_RESET_PARAMS),'SQLFreeStmt');
  SetLength(FParams,0);
  Check(SQLPrepare(FHandle,PSQLCHAR(PAnsiChar(sql)),SQL_NTS),'SQLPrepare');
end;

procedure TDb2Statement.NeedParam(n: integer);
begin
  if n<1 then
    raise EDb2Error.CreateFmt('Parameter %d', [n]);
  if length(FParams)<n then
    SetLength(FParams,n);
end;

{ Die Werte bleiben in FParams; gebunden wird erst in Execute (SQLBindParameter merkt
  sich die Adressen, ODBC liest sie beim Ausführen; SetLength in NeedParam darf die
  Puffer vorher noch verschieben). }
procedure TDb2Statement.SetText(n: integer; const v: RawByteString);
begin
  NeedParam(n);
  FParams[n-1].kind:=dpText;
  FParams[n-1].buf:=v;
  UniqueString(FParams[n-1].buf);
  FParams[n-1].ind:=length(v);
  FParams[n-1].sqltype:=SQL_VARCHAR;
end;

procedure TDb2Statement.SetInt64(n: integer; v: Int64);
begin
  NeedParam(n);
  FParams[n-1].kind:=dpInt64;
  FParams[n-1].i64:=v;
  FParams[n-1].ind:=SizeOf(Int64);
  FParams[n-1].sqltype:=SQL_BIGINT;
end;

procedure TDb2Statement.SetDouble(n: integer; v: double);
begin
  NeedParam(n);
  FParams[n-1].kind:=dpDouble;
  FParams[n-1].dbl:=v;
  FParams[n-1].ind:=SizeOf(double);
  FParams[n-1].sqltype:=SQL_DOUBLE;
end;

procedure TDb2Statement.SetDecimal(n: integer; const v: TDecimal; precision: integer);
begin
  SetText(n,v.ToString('.'));
  FParams[n-1].kind:=dpDecimal;
  FParams[n-1].sqltype:=SQL_DECIMAL;
  FParams[n-1].prec:=precision;
  FParams[n-1].scale:=v.Scale;
end;

procedure TDb2Statement.SetNull(n: integer; sqltype: SQLSMALLINT);
begin
  NeedParam(n);
  FParams[n-1].kind:=dpNull;
  FParams[n-1].buf:='';
  FParams[n-1].ind:=SQL_NULL_DATA;
  FParams[n-1].sqltype:=sqltype;
end;

procedure TDb2Statement.Execute;
var
  i: integer;
  ctype, digits: SQLSMALLINT;
  size: SQLULEN;
  p: SQLPOINTER;
  buflen: SQLLEN;
  rc: SQLRETURN;
begin
  for i:=0 to high(FParams) do
    with FParams[i] do
      begin
        digits:=0;
        case kind of
          dpNull:
            begin
              ctype:=SQL_C_CHAR; p:=nil; buflen:=0; size:=1;
            end;
          dpInt64:
            begin
              ctype:=SQL_C_SBIGINT; p:=@i64; buflen:=SizeOf(Int64); size:=19;
            end;
          dpDouble:
            begin
              ctype:=SQL_C_DOUBLE; p:=@dbl; buflen:=SizeOf(double); size:=15;
            end;
        else
          begin
            ctype:=SQL_C_CHAR;
            p:=PAnsiChar(buf);   { '' -> Zeiger auf #0 }
            buflen:=length(buf);
            size:=length(buf);
            if kind=dpDecimal then
              begin
                size:=prec;
                digits:=scale;
              end;
            if size=0 then
              size:=1;
          end;
        end;
        Check(SQLBindParameter(FHandle,i+1,SQL_PARAM_INPUT,ctype,sqltype,size,digits,p,buflen,
          @ind),Format('SQLBindParameter(%d)', [i+1]));
      end;
  rc:=SQLExecute(FHandle);
  if rc<>SQL_NO_DATA then   { UPDATE/DELETE ohne Treffer }
    Check(rc,'SQLExecute');
  SetLength(FNullCache,0);
end;

procedure TDb2Statement.ExecDirect(const sql: RawByteString);
var
  rc: SQLRETURN;
begin
  rc:=SQLExecDirect(FHandle,PSQLCHAR(PAnsiChar(sql)),SQL_NTS);
  if rc<>SQL_NO_DATA then   { UPDATE/DELETE ohne Treffer }
    Check(rc,'SQLExecDirect');
  SetLength(FNullCache,0);
end;

function TDb2Statement.Fetch: boolean;
var
  rc: SQLRETURN;
  i: integer;
begin
  rc:=SQLFetch(FHandle);
  if rc=SQL_NO_DATA then
    exit(false);
  Check(rc,'SQLFetch');
  SetLength(FNullCache,ColumnCount+1);
  SetLength(FValueCache,length(FNullCache));
  for i:=0 to high(FNullCache) do
    begin
      FNullCache[i]:=-1;
      FValueCache[i]:='';
    end;
  result:=true;
end;

procedure TDb2Statement.CloseCursor;
begin
  Check(SQLFreeStmt(FHandle,SQL_CLOSE),'SQLFreeStmt(CLOSE)');
end;

function TDb2Statement.ColumnCount: integer;
var
  n: SQLSMALLINT;
begin
  Check(SQLNumResultCols(FHandle,n),'SQLNumResultCols');
  result:=n;
end;

function TDb2Statement.ColumnName(col: integer): string;
var
  name: array[0..255] of AnsiChar;
  len, typ, digits, nullable: SQLSMALLINT;
  size: SQLULEN;
begin
  Check(SQLDescribeCol(FHandle,col,@name,SizeOf(name),@len,@typ,@size,@digits,@nullable),
    'SQLDescribeCol');
  result:=PAnsiChar(@name);
end;

{ Spalte als Text holen (lange Werte in Stücken) }
procedure TDb2Statement.LoadColumn(col: integer);
var
  buf: array[0..4095] of AnsiChar;
  ind: SQLLEN;
  rc: SQLRETURN;
  s: RawByteString;
  n: SizeInt;
begin
  if (col<1) or (col>high(FNullCache)) then
    raise EDb2Error.CreateFmt('Spalte %d (keine Zeile oder außerhalb)', [col]);
  if FNullCache[col]>=0 then
    exit;
  s:='';
  repeat
    rc:=SQLGetData(FHandle,col,SQL_C_CHAR,@buf,SizeOf(buf),@ind);
    if rc=SQL_NO_DATA then
      break;
    Check(rc,Format('SQLGetData(%d)', [col]));
    if ind=SQL_NULL_DATA then
      begin
        FNullCache[col]:=1;
        exit;
      end;
    { ohne abschließende 0; bei SQL_SUCCESS_WITH_INFO (01004) ist der Puffer voll }
    if (rc=SQL_SUCCESS_WITH_INFO) and ((ind<0) or (ind>=SizeOf(buf))) then
      n:=SizeOf(buf)-1
    else
      n:=ind;
    s:=s+Copy(PAnsiChar(@buf),1,n);
  until rc=SQL_SUCCESS;
  FNullCache[col]:=0;
  FValueCache[col]:=s;
end;

function TDb2Statement.IsNull(col: integer): boolean;
begin
  LoadColumn(col);
  result:=FNullCache[col]=1;
end;

function TDb2Statement.AsString(col: integer): RawByteString;
begin
  LoadColumn(col);
  result:=FValueCache[col];
end;

function TDb2Statement.AsInt64(col: integer): Int64;
begin
  result:=AsDecimal(col).ToInt64;
end;

function TDb2Statement.AsDecimal(col: integer): TDecimal;
var
  s: RawByteString;
begin
  s:=Trim(AsString(col));
  if s='' then
    exit(TDecimal.Zero);
  if not TDecimal.TryFromString(s,result,'.') then
    raise EDb2Error.CreateFmt('Spalte %d: "%s" ist keine Dezimalzahl', [col, s]);
end;

function TDb2Statement.AsDouble(col: integer): double;
var
  fs: TFormatSettings;
begin
  fs:=DefaultFormatSettings;
  fs.DecimalSeparator:='.';
  result:=StrToFloat(Trim(AsString(col)),fs);
end;

function TDb2Statement.RowCount: Int64;
var
  n: SQLLEN;
begin
  Check(SQLRowCount(FHandle,n),'SQLRowCount');
  result:=n;
end;

end.
