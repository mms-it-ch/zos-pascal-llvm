program rectest;
{ PF6: satzweise E/A (Unit zosrecio): VB/FB-Datasets und VSAM-KSDS.
  Der KSDS <Präfix>.ZPAS.TEST.KSDS (Schlüssel 8 Byte ab 0, Sätze 80 Byte) muss
  angelegt und leer sein (rectest.sh). Returncode = Anzahl Fehler. }
{$mode objfpc}{$H+}
uses SysUtils, zosrecio, zosebcdic;

var
  errors: longint = 0;

procedure check(const what: string; ok: boolean);
begin
  if ok then writeln('OK      ', what)
  else begin writeln('FEHLER  ', what, ' (errno ', RecLastError, ')'); inc(errors); end;
end;

procedure vbtest;
const
  lens: array[0..3] of longint = (3, 80, 200, 1);
var
  f: TRecFile;
  buf: array[0..299] of byte;
  i, n: longint;
  ok: boolean;
begin
  check('VB: anlegen', RecOpen(f, '//ZPAS.TEST.VB,recfm=vb,lrecl=300,space=(trk,(1,1))', romWrite));
  check('VB: Format', (f.Format = rfVariable) and (f.MaxLength = 296));
  for i := 0 to high(lens) do
    begin
      FillChar(buf, lens[i], i + 1);
      RecWrite(f, buf, lens[i]);
    end;
  check('VB: schließen', RecClose(f));
  check('VB: öffnen', RecOpen(f, '//ZPAS.TEST.VB', romRead));
  ok := true;
  for i := 0 to high(lens) do
    begin
      n := RecRead(f, buf, sizeof(buf));
      if (n <> lens[i]) or (buf[0] <> i + 1) or (buf[n - 1] <> i + 1) then
        begin
          writeln('        Satz ', i, ': Länge ', n);
          ok := false;
        end;
    end;
  check('VB: Satzlängen 3, 80, 200, 1 exakt zurück', ok);
  check('VB: Ende', (RecRead(f, buf, sizeof(buf)) = -1) and (RecLastError = 0));
  RecClose(f);
  check('SysUtils: FileExists', FileExists('//ZPAS.TEST.VB'));
  check('SysUtils: RenameFile', RenameFile('//ZPAS.TEST.VB', '//ZPAS.TEST.VB2'));
  check('SysUtils: DeleteFile', DeleteFile('//ZPAS.TEST.VB2'));
  check('SysUtils: danach nicht mehr da', not FileExists('//ZPAS.TEST.VB2') and not FileExists('//ZPAS.TEST.VB'));
end;

procedure fbtest;
var
  f: TRecFile;
  buf: array[0..79] of byte;
  n: longint;
begin
  check('FB: anlegen', RecOpen(f, '//ZPAS.TEST.FB,recfm=fb,lrecl=80,space=(trk,(1,1))', romWrite));
  FillChar(buf, 80, $C1);
  RecWrite(f, buf, 80);
  RecWrite(f, buf, 10);     { kurzer Satz: die C-Laufzeit füllt auf }
  RecClose(f);
  RecOpen(f, '//ZPAS.TEST.FB', romRead);
  check('FB: Format', (f.Format = rfFixed) and (f.MaxLength = 80));
  n := RecRead(f, buf, 80);
  check('FB: Satz 1', n = 80);
  n := RecRead(f, buf, 80);
  check('FB: Satz 2 auf 80 aufgefüllt', n = 80);
  RecClose(f);
  DeleteFile('//ZPAS.TEST.FB');
end;

type
  TKRec = packed record
    key: array[0..7] of AnsiChar;
    data: array[0..71] of AnsiChar;
  end;

function mkrec(const key, data: string): TKRec;
begin
  FillChar(result, sizeof(result), $40);   { EBCDIC-Leerzeichen }
  Move(AsciiToEbcdic(key)[1], result.key, length(key));
  Move(AsciiToEbcdic(data)[1], result.data, length(data));
end;

function keyof(const r: TKRec): string;
begin
  SetLength(result, 8);
  Move(r.key, result[1], 8);
  result := Trim(EbcdicToAscii(result));
end;

function dataof(const r: TKRec): string;
begin
  SetLength(result, 72);
  Move(r.data, result[1], 72);
  result := Trim(EbcdicToAscii(result));
end;

procedure ksdstest;
var
  f: TRecFile;
  r: TKRec;
  k: array[0..7] of AnsiChar;
  keys: string;
  n: longint;
begin
  { laden (aufsteigende Schlüssel) }
  check('KSDS: öffnen zum Laden', RecOpen(f, '//ZPAS.TEST.KSDS', romWrite));
  check('KSDS: Typ', (f.Format = rfVSAM) and (f.VSAMType = vtKSDS) and (f.KeyLength = 8) and (f.KeyOffset = 0));
  r := mkrec('K001', 'eins');   RecWrite(f, r, sizeof(r));
  r := mkrec('K003', 'drei');   RecWrite(f, r, sizeof(r));
  r := mkrec('K005', 'fuenf');  check('KSDS: laden', RecWrite(f, r, sizeof(r)));
  RecClose(f);

  check('KSDS: öffnen zum Ändern', RecOpen(f, '//ZPAS.TEST.KSDS', romUpdate));
  r := mkrec('K002', 'zwei');
  check('KSDS: einfügen K002', RecWrite(f, r, sizeof(r)));
  r := mkrec('K003', '');
  Move(r.key, k, 8);
  check('KSDS: positionieren K003', RecLocate(f, k, 8, rlKeyEqual));
  n := RecRead(f, r, sizeof(r));
  check('KSDS: lesen K003', (n = 80) and (keyof(r) = 'K003') and (dataof(r) = 'drei'));
  r := mkrec('K003', 'drei geaendert');
  check('KSDS: ändern K003', RecUpdate(f, r, sizeof(r)));
  r := mkrec('K005', '');
  Move(r.key, k, 8);
  RecLocate(f, k, 8, rlKeyEqual);
  RecRead(f, r, sizeof(r));
  check('KSDS: löschen K005', RecDelete(f));
  r := mkrec('K004', '');
  Move(r.key, k, 8);
  check('KSDS: K004 gibt es nicht', not RecLocate(f, k, 8, rlKeyEqual));
  RecClose(f);

  RecOpen(f, '//ZPAS.TEST.KSDS', romRead);
  keys := '';
  while RecRead(f, r, sizeof(r)) = 80 do
    keys := keys + keyof(r) + '=' + dataof(r) + ' ';
  check('KSDS: sequentiell ' + keys, keys = 'K001=eins K002=zwei K003=drei geaendert ');
  check('KSDS: letzter Satz', RecLocate(f, k, 0, rlLast) and (RecRead(f, r, sizeof(r)) = 80) and (keyof(r) = 'K003'));
  RecClose(f);
end;

begin
  vbtest;
  fbtest;
  ksdstest;
  writeln('Fehler: ', errors);
  halt(errors);
end.
