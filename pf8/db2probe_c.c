/* db2probe: misst die Db2-for-z/OS-ODBC-Schnittstelle (sqlcli1.h, 64 Bit, ASCII-Modus) und
 * gibt rtl/zosdb2cli_zos.inc vollständig neu aus (Typgrößen, Vorzeichen, Zeiger oder
 * Ganzzahl), dazu als Kommentar: Prototypen der Funktionen gegen die Annahmen der Unit
 * zosdb2cli (ODBC 3, LP64) und die Werte der benutzten Konstanten.
 *
 *   $ZOS_CLANG --target=s390x-ibm-zos -O1 -mzos-sys-include=$ZOS_INCLUDE \
 *     -I$ZOS_DB2_INCLUDE -D__CHARSET_LIB=1 -D_ALL_SOURCE -D_UNIX03_SOURCE \
 *     -c db2probe_c.c -o db2probe_c.o
 *   sh ../scripts/zfpc db2probe.pas && ./db2probe > ../rtl/zosdb2cli_zos.inc
 *
 * Es wird nichts aus der Db2-DLL aufgerufen (die Funktionen erscheinen nur in _Generic,
 * das nicht ausgewertet wird); Binden mit --db2 ist nicht nötig. Auf z/OS noch nicht
 * gelaufen. */
#include <stdio.h>
#include <stddef.h>
#include <time.h>
#include <sqlcli1.h>

static const char *itype(size_t size, int sgn)
{
  switch (size) {
  case 1: return sgn ? "shortint" : "byte";
  case 2: return sgn ? "smallint" : "word";
  case 4: return sgn ? "longint" : "longword";
  case 8: return sgn ? "Int64" : "QWord";
  }
  return "?";
}

/* Ganzzahl-Typ: Größe und Vorzeichen; Zeiger (void*) erkennt _Generic */
#define ISPTR(t) _Generic((t)0, void *: 1, const void *: 1, default: 0)
#define INT(t, comment) \
  printf("  %s = %s;%s\n", #t, ISPTR(t) ? "pointer" : itype(sizeof(t), (t)-1 < (t)0), comment)

/* Prototyp gegen die Annahme der Unit */
#define PROTO(f, ...) \
  printf("  %s %s\n", _Generic(&f, __VA_ARGS__: "OK        ", default: "ABWEICHUNG"), #f)

#define CONST(c, expect) \
  printf("  %-28s = %6ld%s\n", #c, (long)(c), (long)(c) == (expect) ? "" : "   <- Unit: " #expect)

int db2probe_run(void)
{
  time_t now = time(0);
  char d[32];
  strftime(d, sizeof d, "%d.%m.%Y", localtime(&now));
  printf("{ zosdb2cli_zos.inc - Typen der Db2-for-z/OS-ODBC-Schnittstelle (sqlcli1.h, 64 Bit).\n");
  printf("  Erzeugt von pf8/db2probe_c.c auf z/OS am %s. Gemessen: ja }\n\n", d);
  printf("type\n");
  INT(SQLCHAR, "");
  INT(SQLSCHAR, "");
  INT(SQLSMALLINT, "");
  INT(SQLUSMALLINT, "");
  INT(SQLINTEGER, "");
  INT(SQLUINTEGER, "");
  INT(SQLLEN, "");
  INT(SQLULEN, "");
  INT(SQLRETURN, "");
  printf("  SQLDOUBLE = double;\n  SQLREAL = single;\n  SQLPOINTER = pointer;\n");
  INT(SQLHANDLE, "");
  INT(SQLHWND, "");
  printf("\nconst\n  ZOSDB2CLI_MEASURED = true;\n\n");
  printf("{ sizeof: SQLHANDLE %zu, SQLHENV %zu, SQLHDBC %zu, SQLHSTMT %zu, SQLLEN %zu, SQLPOINTER %zu\n",
         sizeof(SQLHANDLE), sizeof(SQLHENV), sizeof(SQLHDBC), sizeof(SQLHSTMT), sizeof(SQLLEN),
         sizeof(SQLPOINTER));
  printf("  (SQLHENV/SQLHDBC/SQLHSTMT müssen so groß sein wie SQLHANDLE)\n\n");
  printf("  Prototypen (Annahme der Unit zosdb2cli):\n");
  PROTO(SQLAllocHandle, SQLRETURN (*)(SQLSMALLINT, SQLHANDLE, SQLHANDLE *));
  PROTO(SQLFreeHandle, SQLRETURN (*)(SQLSMALLINT, SQLHANDLE));
  PROTO(SQLSetEnvAttr, SQLRETURN (*)(SQLHENV, SQLINTEGER, SQLPOINTER, SQLINTEGER));
  PROTO(SQLSetConnectAttr, SQLRETURN (*)(SQLHDBC, SQLINTEGER, SQLPOINTER, SQLINTEGER));
  PROTO(SQLGetConnectAttr, SQLRETURN (*)(SQLHDBC, SQLINTEGER, SQLPOINTER, SQLINTEGER, SQLINTEGER *));
  PROTO(SQLSetStmtAttr, SQLRETURN (*)(SQLHSTMT, SQLINTEGER, SQLPOINTER, SQLINTEGER));
  PROTO(SQLConnect, SQLRETURN (*)(SQLHDBC, SQLCHAR *, SQLSMALLINT, SQLCHAR *, SQLSMALLINT, SQLCHAR *, SQLSMALLINT));
  PROTO(SQLDriverConnect, SQLRETURN (*)(SQLHDBC, SQLHWND, SQLCHAR *, SQLSMALLINT, SQLCHAR *, SQLSMALLINT, SQLSMALLINT *, SQLUSMALLINT));
  PROTO(SQLDisconnect, SQLRETURN (*)(SQLHDBC));
  PROTO(SQLExecDirect, SQLRETURN (*)(SQLHSTMT, SQLCHAR *, SQLINTEGER));
  PROTO(SQLPrepare, SQLRETURN (*)(SQLHSTMT, SQLCHAR *, SQLINTEGER));
  PROTO(SQLExecute, SQLRETURN (*)(SQLHSTMT));
  PROTO(SQLBindParameter, SQLRETURN (*)(SQLHSTMT, SQLUSMALLINT, SQLSMALLINT, SQLSMALLINT, SQLSMALLINT, SQLULEN, SQLSMALLINT, SQLPOINTER, SQLLEN, SQLLEN *));
  PROTO(SQLBindCol, SQLRETURN (*)(SQLHSTMT, SQLUSMALLINT, SQLSMALLINT, SQLPOINTER, SQLLEN, SQLLEN *));
  PROTO(SQLFetch, SQLRETURN (*)(SQLHSTMT));
  PROTO(SQLGetData, SQLRETURN (*)(SQLHSTMT, SQLUSMALLINT, SQLSMALLINT, SQLPOINTER, SQLLEN, SQLLEN *));
  PROTO(SQLNumResultCols, SQLRETURN (*)(SQLHSTMT, SQLSMALLINT *));
  PROTO(SQLDescribeCol, SQLRETURN (*)(SQLHSTMT, SQLUSMALLINT, SQLCHAR *, SQLSMALLINT, SQLSMALLINT *, SQLSMALLINT *, SQLULEN *, SQLSMALLINT *, SQLSMALLINT *));
  PROTO(SQLRowCount, SQLRETURN (*)(SQLHSTMT, SQLLEN *));
  PROTO(SQLNumParams, SQLRETURN (*)(SQLHSTMT, SQLSMALLINT *));
  PROTO(SQLGetDiagRec, SQLRETURN (*)(SQLSMALLINT, SQLHANDLE, SQLSMALLINT, SQLCHAR *, SQLINTEGER *, SQLCHAR *, SQLSMALLINT, SQLSMALLINT *));
  PROTO(SQLEndTran, SQLRETURN (*)(SQLSMALLINT, SQLHANDLE, SQLSMALLINT));
  PROTO(SQLFreeStmt, SQLRETURN (*)(SQLHSTMT, SQLUSMALLINT));
  PROTO(SQLCloseCursor, SQLRETURN (*)(SQLHSTMT));
  PROTO(SQLMoreResults, SQLRETURN (*)(SQLHSTMT));
  PROTO(SQLCancel, SQLRETURN (*)(SQLHSTMT));
  PROTO(SQLGetInfo, SQLRETURN (*)(SQLHDBC, SQLUSMALLINT, SQLPOINTER, SQLSMALLINT, SQLSMALLINT *));
  PROTO(SQLTables, SQLRETURN (*)(SQLHSTMT, SQLCHAR *, SQLSMALLINT, SQLCHAR *, SQLSMALLINT, SQLCHAR *, SQLSMALLINT, SQLCHAR *, SQLSMALLINT));
  PROTO(SQLColumns, SQLRETURN (*)(SQLHSTMT, SQLCHAR *, SQLSMALLINT, SQLCHAR *, SQLSMALLINT, SQLCHAR *, SQLSMALLINT, SQLCHAR *, SQLSMALLINT));
  printf("  (ABWEICHUNG: Deklaration in rtl/zosdb2cli.pp an sqlcli1.h anpassen; Abweichungen nur\n");
  printf("   in Aufrufkonventions-Attributen sind harmlos)\n\n");
  printf("  Konstanten:\n");
  CONST(SQL_SUCCESS, 0); CONST(SQL_SUCCESS_WITH_INFO, 1); CONST(SQL_NO_DATA_FOUND, 100);
  CONST(SQL_NEED_DATA, 99); CONST(SQL_ERROR, -1); CONST(SQL_INVALID_HANDLE, -2);
  CONST(SQL_HANDLE_ENV, 1); CONST(SQL_HANDLE_DBC, 2); CONST(SQL_HANDLE_STMT, 3);
  CONST(SQL_ATTR_ODBC_VERSION, 200); CONST(SQL_OV_ODBC3, 3);
  CONST(SQL_ATTR_AUTOCOMMIT, 102); CONST(SQL_AUTOCOMMIT_OFF, 0); CONST(SQL_AUTOCOMMIT_ON, 1);
  CONST(SQL_ATTR_TXN_ISOLATION, 108); CONST(SQL_COMMIT, 0); CONST(SQL_ROLLBACK, 1);
  CONST(SQL_NTS, -3); CONST(SQL_NULL_DATA, -1); CONST(SQL_DRIVER_NOPROMPT, 0);
  CONST(SQL_CLOSE, 0); CONST(SQL_DROP, 1); CONST(SQL_UNBIND, 2); CONST(SQL_RESET_PARAMS, 3);
  CONST(SQL_PARAM_INPUT, 1); CONST(SQL_PARAM_OUTPUT, 4);
  CONST(SQL_C_CHAR, 1); CONST(SQL_C_LONG, 4); CONST(SQL_C_SHORT, 5); CONST(SQL_C_DOUBLE, 8);
  CONST(SQL_C_BINARY, -2); CONST(SQL_C_DEFAULT, 99);
#ifdef SQL_C_SBIGINT
  CONST(SQL_C_SBIGINT, -25);
#else
  printf("  SQL_C_SBIGINT fehlt: SetInt64 als Text binden (zosdb2cli.pp ändern)\n");
#endif
  CONST(SQL_CHAR, 1); CONST(SQL_DECIMAL, 3); CONST(SQL_INTEGER, 4); CONST(SQL_SMALLINT, 5);
  CONST(SQL_DOUBLE, 8); CONST(SQL_VARCHAR, 12); CONST(SQL_BIGINT, -5);
  CONST(SQL_TYPE_DATE, 91); CONST(SQL_TYPE_TIME, 92); CONST(SQL_TYPE_TIMESTAMP, 93);
  CONST(SQL_BLOB, -98); CONST(SQL_CLOB, -99); CONST(SQL_GRAPHIC, -95); CONST(SQL_VARGRAPHIC, -96);
  CONST(SQL_DBMS_NAME, 17); CONST(SQL_DBMS_VER, 18);
  printf("}\n");
  return 0;
}
