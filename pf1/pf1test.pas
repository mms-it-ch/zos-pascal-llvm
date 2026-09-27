program pf1test;
{ PF1: echte System-Unit auf z/OS - writeln, Strings, Heap, Textdateien, halt.
  Jeder Teiltest meldet OK/FEHLER; Returncode = Anzahl Fehler (0 = alles gut). }
{$mode objfpc}{$H+}

var
  errors: longint = 0;

procedure check(const what: string; ok: boolean);
begin
  if ok then
    writeln('OK      ', what)
  else
    begin
      writeln('FEHLER  ', what);
      inc(errors);
    end;
end;

type
  PNode = ^TNode;
  TNode = record
    value: longint;
    next: PNode;
  end;

var
  s, t: ansistring;
  ss: shortstring;
  i, sum: longint;
  q: int64;
  d: double;
  head, n: PNode;
  p: pointer;
  f: text;
  line: string;
  count: longint;
begin
  writeln('Free Pascal auf z/OS - PF1');

  { Ganzzahlen und Gleitkomma }
  q := 1;
  for i := 1 to 20 do
    q := q * i;
  check('20! = 2432902008176640000', q = 2432902008176640000);
  str(q, ss);
  check('str(int64)', ss = '2432902008176640000');
  d := 1.0 / 3.0;
  str(d:0:6, ss);
  check('str(double) = 0.333333', ss = '0.333333');
  check('sqrt(2)', abs(sqrt(2.0) - 1.41421356237) < 1e-9);
  writeln('  pi = ', pi:0:10, ', -7 div 2 = ', -7 div 2, ', -7 mod 2 = ', -7 mod 2);

  { Strings }
  s := 'Hallo';
  t := s + ', ' + 'z/OS';
  check('AnsiString-Verkettung', t = 'Hallo, z/OS');
  check('Length', length(t) = 11);
  check('Pos', pos('z/OS', t) = 8);
  check('Copy', copy(t, 1, 5) = 'Hallo');
  check('UpCase', upcase(t) = 'HALLO, Z/OS');
  s := '';
  for i := 1 to 1000 do
    s := s + chr(ord('A') + i mod 26);
  check('1000 Zeichen angehängt', (length(s) = 1000) and (s[26] = 'A'));
  check('Ordinalwerte ASCII', (ord('A') = 65) and (ord('a') = 97) and (ord('0') = 48));

  { Heap }
  head := nil;
  for i := 1 to 10000 do
    begin
      new(n);
      n^.value := i;
      n^.next := head;
      head := n;
    end;
  sum := 0;
  while head <> nil do
    begin
      n := head;
      inc(sum, n^.value);
      head := n^.next;
      dispose(n);
    end;
  check('Heap: 10000 Knoten, Summe 50005000', sum = 50005000);
  getmem(p, 1000000);
  fillchar(p^, 1000000, $5A);
  check('GetMem 1 MB', pbyte(p)[999999] = $5A);
  freemem(p);

  { Textdateien }
  assign(f, 'pf1test.txt');
  rewrite(f);
  for i := 1 to 100 do
    writeln(f, 'Zeile ', i);
  close(f);
  check('Datei geschrieben (IOResult)', ioresult = 0);
  reset(f);
  count := 0;
  line := '';
  while not eof(f) do
    begin
      readln(f, line);
      inc(count);
    end;
  close(f);
  check('100 Zeilen zurückgelesen', count = 100);
  check('letzte Zeile', line = 'Zeile 100');
  erase(f);
  {$I-}
  reset(f);
  {$I+}
  check('gelöschte Datei fehlt (IOResult 2)', ioresult = 2);

  { Programmparameter }
  writeln('  ParamCount = ', paramcount, ', ParamStr(0) = ', paramstr(0));

  writeln('Fehler: ', errors);
  halt(errors);
end.
