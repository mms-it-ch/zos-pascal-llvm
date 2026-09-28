program dsntest;
{ PF6: MVS-Datasets mit normaler Pascal-Datei-E/A (unter z/OS UNIX).
  Legt <Präfix>.ZPAS.TEST.* an und löscht sie am Ende. Returncode = Anzahl Fehler. }
{$mode objfpc}{$H+}{$I-}
uses SysUtils;

var
  errors: longint = 0;

procedure check(const what: string; ok: boolean);
begin
  if ok then writeln('OK      ', what)
  else begin writeln('FEHLER  ', what); inc(errors); end;
end;

const
  lines: array[0..4] of string = (
    'Erste Zeile',
    '',
    'Umlaute: ' + #$C4#$D6#$DC#$E4#$F6#$FC#$DF + ' {[]}|\~^@#$%',
    '  eingerückt, mit Leerzeichen am Ende   ',
    'Letzte Zeile');

{ Zeilen schreiben, zurücklesen und vergleichen; stripped: FB kürzt
  nachgestellte Leerzeichen beim Lesen }
procedure texttest(const name, attr: string; stripped: boolean);
var
  t: text;
  s, want: string;
  i, n: longint;
  ok: boolean;
begin
  assign(t, name + attr);
  rewrite(t);
  check(name + ': Rewrite', ioresult = 0);
  for i := 0 to high(lines) do
    writeln(t, lines[i]);
  close(t);
  check(name + ': Close nach Schreiben', ioresult = 0);

  assign(t, name);
  reset(t);
  check(name + ': Reset', ioresult = 0);
  n := 0;
  ok := true;
  while not eof(t) do
    begin
      readln(t, s);
      want := lines[n];
      if stripped then
        want := TrimRight(want);
      if s <> want then
        begin
          writeln('        Zeile ', n, ': "', s, '" statt "', want, '"');
          ok := false;
        end;
      inc(n);
    end;
  close(t);
  check(name + ': Zeilen gleich', ok and (n = length(lines)));

  append(t);
  check(name + ': Append', ioresult = 0);
  writeln(t, 'angehängt');
  close(t);
  reset(t);
  n := 0;
  while not eof(t) do
    begin
      readln(t, s);
      inc(n);
    end;
  close(t);
  check(name + ': angehängte Zeile da', (n = length(lines) + 1) and (s = 'angehängt'));
end;

type
  trec = array[0..79] of char;

procedure bintest(const name, attr: string);
var
  f: file;
  r: trec;
  i, got: longint;
  ok: boolean;
begin
  assign(f, name + attr);
  rewrite(f, sizeof(trec));
  check(name + ': Rewrite (binär)', ioresult = 0);
  for i := 1 to 3 do
    begin
      fillchar(r, sizeof(r), chr(ord('0') + i));
      blockwrite(f, r, 1);
    end;
  close(f);
  check(name + ': Close', ioresult = 0);
  assign(f, name);
  reset(f, sizeof(trec));
  check(name + ': Reset (binär)', ioresult = 0);
  check(name + ': FileSize = 3', filesize(f) = 3);
  seek(f, 2);
  blockread(f, r, 1, got);
  check(name + ': Seek + BlockRead Satz 3', (got = 1) and (r[0] = '3') and (r[79] = '3'));
  seek(f, 0);
  ok := true;
  for i := 1 to 3 do
    begin
      blockread(f, r, 1, got);
      if (got <> 1) or (r[0] <> chr(ord('0') + i)) then
        ok := false;
    end;
  check(name + ': alle Sätze', ok);
  close(f);
end;

procedure erasetest(const name: string);
var
  f: file;
begin
  assign(f, name);
  erase(f);
  check(name + ': Erase', ioresult = 0);
  reset(f);
  check(name + ': danach nicht mehr da', ioresult <> 0);
end;

var
  t: text;
begin
  texttest('//ZPAS.TEST.FB80', ',recfm=fb,lrecl=80,space=(trk,(1,1))', true);
  texttest('//ZPAS.TEST.VB255', ',recfm=vb,lrecl=255,space=(trk,(1,1))', false);

  { zu lange Zeile bei FB: Fehler }
  assign(t, '//ZPAS.TEST.FB80');
  rewrite(t);
  writeln(t, StringOfChar('x', 100));
  close(t);
  check('FB80: zu lange Zeile meldet einen Fehler', ioresult <> 0);

  bintest('//ZPAS.TEST.BIN80', ',recfm=fb,lrecl=80,space=(trk,(1,1))');

  erasetest('//ZPAS.TEST.FB80');
  erasetest('//ZPAS.TEST.VB255');
  erasetest('//ZPAS.TEST.BIN80');

  assign(t, '//ZPAS.TEST.GIBTESNICHT');
  reset(t);
  check('fehlendes Dataset: IOResult <> 0', ioresult <> 0);
  writeln('Fehler: ', errors);
  halt(errors);
end.
