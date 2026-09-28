program dsnpds;
{ PF6: Member in PDS und PDSE anlegen, lesen, ersetzen, löschen (unter z/OS UNIX).
  Legt <Präfix>.ZPAS.TEST.PDS / .PDSE an und löscht sie am Ende.
  Returncode = Anzahl Fehler. }
{$mode objfpc}{$H+}{$I-}
uses SysUtils;

var
  errors: longint = 0;

procedure check(const what: string; ok: boolean);
begin
  if ok then writeln('OK      ', what)
  else begin writeln('FEHLER  ', what); inc(errors); end;
end;

function writemember(const name, text: string): boolean;
var
  t: textfile;
begin
  assign(t, name);
  rewrite(t);
  writeln(t, text);
  writeln(t, 'zweite Zeile');
  close(t);
  result := ioresult = 0;
end;

function readmember(const name: string; out first: string): integer;
var
  t: textfile;
  s: string;
begin
  result := -1;
  first := '';
  assign(t, name);
  reset(t);
  if ioresult <> 0 then
    exit;
  result := 0;
  while not eof(t) do
    begin
      readln(t, s);
      if result = 0 then
        first := s;
      inc(result);
    end;
  close(t);
end;

procedure pdstest(const lib, attr: string);
var
  t: textfile;
  s: string;
begin
  { erstes Member legt die Bibliothek mit den Attributen an }
  check(lib + ': Member A anlegen (neue Bibliothek)',
    writemember('//' + lib + '(MEMA)' + attr, 'Member A'));
  check(lib + ': Member B anlegen', writemember('//' + lib + '(MEMB)', 'Member B'));
  check(lib + ': Member A lesen', (readmember('//' + lib + '(MEMA)', s) = 2) and (s = 'Member A'));
  check(lib + ': Member B lesen', (readmember('//' + lib + '(MEMB)', s) = 2) and (s = 'Member B'));
  check(lib + ': Member A ersetzen', writemember('//' + lib + '(MEMA)', 'Member A neu'));
  check(lib + ': Member A neu gelesen', (readmember('//' + lib + '(MEMA)', s) = 2) and (s = 'Member A neu'));
  assign(t, '//' + lib + '(MEMB)');
  erase(t);
  check(lib + ': Member B löschen', ioresult = 0);
  check(lib + ': Member B weg', readmember('//' + lib + '(MEMB)', s) < 0);
  check(lib + ': Member A noch da', readmember('//' + lib + '(MEMA)', s) = 2);
  assign(t, '//' + lib);
  erase(t);
  check(lib + ': Bibliothek löschen', ioresult = 0);
end;

begin
  { PDS: entsteht mit dem ersten Member, wenn space Directory-Blöcke angibt }
  pdstest('ZPAS.TEST.PDS', ',recfm=fb,lrecl=80,space=(trk,(1,1,5))');
  { dsntype kennt fopen nicht: die RTL legt die Bibliothek mit dynalloc an }
  pdstest('ZPAS.TEST.PDS2', ',recfm=fb,lrecl=80,dsntype=pds,space=(trk,(1,1,5))');
  pdstest('ZPAS.TEST.PDSE', ',recfm=vb,lrecl=255,dsntype=library,space=(trk,(1,1,5))');
  writeln('Fehler: ', errors);
  halt(errors);
end.
