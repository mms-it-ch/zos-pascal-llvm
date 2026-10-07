program ccsidtest;
{ PF8: EBCDIC-Codepages (CCSID).
  Teil 1 (überall, auch x86_64): Unit zosccsid - Rundreisen aller Tabellen, Stichproben
  gegen Python-Codecs, Felder fester Länge.
  Teil 2 (nur z/OS): Textdateien auf Datasets mit Standard-CCSID (ZOS_CCSID),
  ",ccsid=NNN" im Namen und SetTextCcsid; Prüfung der geschriebenen Bytes binär.
  Aufruf auf z/OS: ./ccsidtest [präfix]  (Datasets <präfix>.ZPAS.TEST.CCSID*, ohne
  Präfix die User-ID über //NAME). Ergebnis: Zahl der Fehler als Returncode. }
{$mode objfpc}{$H+}
uses
  sysutils, zosccsid
{$ifdef zos}
  , zosebcdic
{$endif}
  ;

var
  errors: longint = 0;
  checks: longint = 0;

procedure check(const what: string; ok: boolean);
begin
  inc(checks);
  if ok then
    writeln('OK      ', what)
  else
    begin
      writeln('FEHLER  ', what);
      inc(errors);
    end;
end;

function hex(const s: RawByteString): string;
var
  i: integer;
begin
  result:='';
  for i:=1 to length(s) do
    result:=result+HexStr(ord(s[i]),2);
end;

const
  { 'Grüße, [x] @1 §' in ISO-8859-1 }
  Sample: RawByteString = 'Gr'#$FC#$DF'e, [x] @1 '#$A7;

procedure test_tables;
var
  i, c, k: integer;
  all, e, a: RawByteString;
  ok: boolean;
  fld: array[0..9] of byte;
begin
  writeln('-- Tabellen (zosccsid)');
  SetLength(all,256);
  for i:=0 to 255 do
    all[i+1]:=AnsiChar(i);
  ok:=true;
  for k:=0 to CcsidCount-1 do
    begin
      c:=CcsidByIndex(k);
      e:=AsciiToEbcdicStr(all,c);
      a:=EbcdicToAsciiStr(e,c);
      if a<>all then
        begin
          ok:=false;
          writeln('  Rundreise ', c);
        end;
      if (e[ord('0')+1]<>#$F0) or (e[ord(' ')+1]<>#$40) or (e[10+1]<>#$15) then
        begin
          ok:=false;
          writeln('  Invariante ', c);
        end;
    end;
  check(IntToStr(CcsidCount)+' CCSIDs: Rundreise aller 256 Zeichen, Ziffern/Leerzeichen/NL', ok);
  check('mindestens 1047 37 273 500 1140 1141 1148', CcsidSupported(1047) and CcsidSupported(37)
    and CcsidSupported(273) and CcsidSupported(500) and CcsidSupported(1140)
    and CcsidSupported(1141) and CcsidSupported(1148) and not CcsidSupported(1208));
  { Erwartung aus Python: 'Grüße, [x] @1 §'.encode(cpNNN) }
  check('273 = cp273', hex(AsciiToEbcdicStr(Sample,273))='C799D0A1856B4063A7FC40B5F1407C');
  check('37 = cp037', hex(AsciiToEbcdicStr(Sample,37))='C799DC59856B40BAA7BB407CF140B5');
  check('500 = cp500', hex(AsciiToEbcdicStr(Sample,500))='C799DC59856B404AA75A407CF140B5');
  check('1140 = cp1140 (ohne Euro wie 37)', hex(AsciiToEbcdicStr(Sample,1140))='C799DC59856B40BAA7BB407CF140B5');
  check('1047: [ = AD, ] = BD', hex(AsciiToEbcdicStr('[]',1047))='ADBD');
  check('Euro 1141: X''A4'' -> X''9F''', hex(AsciiToEbcdicStr('5 '#$A4,1141))='F5409F');
  check('Euro 1148 zurück', EbcdicToAsciiStr(#$9F,1148)=#$A4);
  check('LF -> NL X''15''', hex(AsciiToEbcdicStr('a'#10,273))='8115');
  check('Ergebnis-Codepage ISO-8859-1', StringCodePage(EbcdicToAsciiStr(#$C1,37))=CP_ISO_8859_1);
  ok:=false;
  try AsciiToEbcdicStr('x',4711); except on ECcsidError do ok:=true; end;
  check('unbekannte CCSID -> ECcsidError', ok);
  check('Tabellen-Zeiger nil bei unbekannt', CcsidA2ETable(4711)=nil);
  { Felder fester Länge (PIC X(10)) }
  StrToEbcdicField('M'#$FC'ller',fld,10,273);
  check('Feld PIC X(10) 273: aufgefüllt', (fld[0]=$D4) and (fld[1]=$D0) and (fld[6]=$40) and (fld[9]=$40));
  check('Feld zurück, rechts gekürzt', EbcdicFieldToStr(fld,10,273)='M'#$FC'ller');
  check('Feld zurück, ungekürzt', length(EbcdicFieldToStr(fld,10,273,false))=10);
  StrToEbcdicField('ABCDEFGHIJKL',fld,10,1047);
  check('Feld zu lang: rechts abgeschnitten', EbcdicFieldToStr(fld,10,1047)='ABCDEFGHIJ');
end;

{$ifdef zos}
function dsn(const prefix, suffix: string): string;
begin
  if prefix='' then
    result:='//ZPAS.TEST.'+suffix
  else
    result:='//'''+prefix+'.ZPAS.TEST.'+suffix+'''';
end;

{ Datei binär lesen }
function rawread(const name: string): RawByteString;
var
  f: file;
  n: longint;
begin
  assign(f,name);
  reset(f,1);
  SetLength(result,FileSize(f));
  n:=0;
  if length(result)>0 then
    blockread(f,result[1],length(result),n);
  SetLength(result,n);
  close(f);
end;

procedure test_datasets(const prefix: string);
var
  t: text;
  s: string;
  n, n2: string;
  raw: RawByteString;
begin
  writeln('-- Datasets (Standard-CCSID ', GetDefaultCcsid, ')');
  n:=dsn(prefix,'CCSID1');
  n2:=dsn(prefix,'CCSID2');
  DeleteFile(n);
  DeleteFile(n2);
  { 1. ,ccsid=273 im Namen, VB }
  assign(t,n+',ccsid=273,recfm=vb,lrecl=80,space=(trk,(1,1))');
  rewrite(t);
  check('GetTextCcsid nach Rewrite = 273', GetTextCcsid(t)=273);
  writeln(t,Sample);
  close(t);
  raw:=rawread(n);
  check('Inhalt binär = cp273 ('+hex(raw)+')', hex(raw)='C799D0A1856B4063A7FC40B5F1407C');
  assign(t,n+',ccsid=273');
  reset(t);
  readln(t,s);
  close(t);
  check('zurückgelesen mit 273', s=Sample);
  { 2. dasselbe Dataset mit 1047 gelesen: andere Zeichen }
  assign(t,n);
  reset(t);
  check('SetTextCcsid(1047)', SetTextCcsid(t,1047));
  readln(t,s);
  close(t);
  check('mit 1047 gelesen ist es anders', s<>Sample);
  { 3. SetTextCcsid vor dem Schreiben, Euro 1141 }
  assign(t,n2+',recfm=fb,lrecl=20,space=(trk,(1,1))');
  rewrite(t);
  check('SetTextCcsid(1141)', SetTextCcsid(t,1141));
  writeln(t,'5 '#$A4);
  close(t);
  raw:=rawread(n2);
  check('Euro 1141: X''9F'' im Dataset ('+copy(hex(raw),1,6)+')', copy(hex(raw),1,6)='F5409F');
  { 4. Standard umstellen }
  check('SetDefaultCcsid(500)', SetDefaultCcsid(500) and (GetDefaultCcsid=500));
  assign(t,n2);
  rewrite(t);
  writeln(t,'[!]');
  close(t);
  raw:=rawread(n2);
  check('Standard 500: [!] = 4A4F5A', copy(hex(raw),1,6)='4A4F5A');
  check('SetDefaultCcsid(4711) scheitert', not SetDefaultCcsid(4711) and (GetDefaultCcsid=500));
  SetDefaultCcsid(1047);
  { 5. unbekannte CCSID im Namen -> Fehler beim Öffnen }
  assign(t,n2+',ccsid=4711');
  {$I-} reset(t); {$I+}
  check('ccsid=4711: IOResult <> 0', IOResult<>0);
  { 6. Umwandlung im Speicher mit CCSID }
  check('AsciiToEbcdic(s, 273)', hex(AsciiToEbcdic(Sample,273))='C799D0A1856B4063A7FC40B5F1407C');
  check('EbcdicToAscii(s, 1148)', EbcdicToAscii(#$9F,1148)=#$A4);
  DeleteFile(n);
  DeleteFile(n2);
end;
{$endif}

begin
  writeln('Free Pascal auf z/OS - PF8 CCSID');
  test_tables;
{$ifdef zos}
  test_datasets(ParamStr(1));
{$endif}
  writeln('Prüfungen: ', checks, ', Fehler: ', errors);
  halt(errors);
end.
