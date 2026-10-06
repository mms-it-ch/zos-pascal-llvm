**Title:** odbc: SQLINTEGER is 64 bit on 64-bit Unix, the driver writes 32 bit

### Summary

`packages/odbc/src/odbcsql.inc` declares `SQLINTEGER = clong` and `SQLUINTEGER = culong`.
On 64-bit Unix `clong` is 64 bit, but unixODBC and iODBC define `SQLINTEGER` as `int` when
`long` is 64 bit (`sqltypes.h`). Wherever the driver writes through a `PSQLINTEGER` or a
`var ... : SQLINTEGER` parameter, only 4 of the 8 bytes are written; the other half keeps its
previous contents. On little endian the result is wrong whenever that half is not zero, on big
endian the value always lands in the upper half.

### Reproducer (x86_64-linux, unixODBC + SQLite ODBC driver)

`sqlint.pp`:

```pascal
program sqlint;
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
  SQLExecDirect(st, 'SELECT * FROM does_not_exist', SQL_NTS);
  native:=-1;
  SQLGetDiagRec(SQL_HANDLE_STMT, st, 1, @state, native, @msg, sizeof(msg), len);
  writeln('SizeOf(SQLINTEGER) = ', SizeOf(SQLINTEGER), ', native error = ', native, ' (driver: 1)');
end.
```

Observed (FPC main 37b8a1a9, `apt install unixodbc-dev libsqliteodbc`):

```
SizeOf(SQLINTEGER) = 8, native error = -4294967295 (driver: 1)
```

Expected: `SizeOf(SQLINTEGER) = 4, native error = 1`. `TODBCConnection` passes such variables
too (`SQLGetDiagRec` in `ODBCCheckResult`, `SQLGetConnectAttr`, ...).

### Fix

Use `cint`/`cuint` for 64-bit non-Windows targets (Windows is LLP64, `clong` is 32 bit there).
Patch `0008-odbc-SQLINTEGER-is-32-bit-on-64-bit-Unix.patch`; with it the reproducer prints
`native error = 1`, and `TODBCConnection` still works against SQLite (insert/select/rollback,
BCD and NULL parameters).

Found while porting FPC to z/OS (big endian), where Db2's ODBC driver showed the problem first.
The issue text and patch were prepared with Claude Code (Anthropic).
