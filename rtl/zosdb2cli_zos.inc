{ zosdb2cli_zos.inc - Typen der Db2-for-z/OS-ODBC-Schnittstelle (sqlcli1.h, 64 Bit).

  *** NICHT GEMESSEN. ***  Annahmen nach ODBC 3 für LP64 und der Db2-Tradition ganzzahliger
  Handles. Vor dem ersten Einsatz auf z/OS mit pf8/db2probe_c.c messen: das Programm gibt
  diese Datei vollständig neu aus (Anleitung pf8/README.md, Abschnitt Db2) und prüft die
  Prototypen der Funktionen (SQLLEN oder SQLINTEGER bei SQLBindCol, SQLGetData,
  SQLBindParameter, SQLRowCount, SQLDescribeCol).
  Gemessen: nein }

type
  SQLCHAR = byte;
  SQLSCHAR = shortint;
  SQLSMALLINT = smallint;
  SQLUSMALLINT = word;
  SQLINTEGER = longint;
  SQLUINTEGER = longword;
  SQLLEN = Int64;          { Annahme: long (LP64) }
  SQLULEN = QWord;         { Annahme: unsigned long (LP64) }
  SQLRETURN = SQLSMALLINT;
  SQLDOUBLE = double;
  SQLREAL = single;
  SQLPOINTER = pointer;
  SQLHANDLE = longint;     { Annahme: ganzzahliges Handle (SQLINTEGER) }
  SQLHWND = pointer;

const
  ZOSDB2CLI_MEASURED = false;
