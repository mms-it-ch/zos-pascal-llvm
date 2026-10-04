program db2probe;
{ PF8: Hülle für das Messprogramm db2probe_c.c (Db2-ODBC-Typen, -Prototypen, -Konstanten).
  Ausgabe = neue rtl/zosdb2cli_zos.inc; Anleitung pf8/README.md, Abschnitt Db2. }
{$L db2probe_c.o}
function db2probe_run: longint; cdecl; external name 'db2probe_run';
begin
  halt(db2probe_run);
end.
