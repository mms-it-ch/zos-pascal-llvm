program sqlint;
{ fpc/upstream/06-odbc-sqlinteger.md: SQLINTEGER = clong (8 Byte auf 64-Bit-Unix),
  unixODBC schreibt 4 Byte. Braucht unixodbc-dev und libsqliteodbc. }
{$mode objfpc}
uses odbcsql;
var env, dbc, st: SQLHANDLE; native: SQLINTEGER; state: array[0..5] of AnsiChar;
    msg: array[0..255] of AnsiChar; len: SQLSMALLINT; outlen: SQLSMALLINT;
begin
  SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, env);
  SQLSetEnvAttr(env, SQL_ATTR_ODBC_VERSION, SQLPOINTER(SQL_OV_ODBC3), 0);
  SQLAllocHandle(SQL_HANDLE_DBC, env, dbc);
  SQLDriverConnect(dbc, nil, 'DRIVER=SQLite3;Database=:memory:', SQL_NTS, nil, 0, outlen, SQL_DRIVER_NOPROMPT);
  SQLAllocHandle(SQL_HANDLE_STMT, dbc, st);
  SQLExecDirect(st, 'SELECT * FROM gibt_es_nicht', SQL_NTS);
  native:=-1;   { alle Bits gesetzt, wie zufälliger Speicherinhalt }
  SQLGetDiagRec(SQL_HANDLE_STMT, st, 1, @state, native, @msg, sizeof(msg), len);
  writeln('SizeOf(SQLINTEGER) = ', SizeOf(SQLINTEGER), ', native error = ', native, ' (Treiber: 1)');
end.
