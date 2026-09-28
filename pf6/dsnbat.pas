program dsnbat;
{ PF6: Pascal-Batchprogramm mit DD-Anweisungen (JCL: dsnbat.dd):
    Input   <- //SYSIN DD *          (Zahlen, eine je Zeile)
    Output  -> //SYSPRINT            (Dataset)
    DD:INDATA  (Dataset, Text)  -> in Großbuchstaben nach DD:OUTDATA (FB 80)
  Returncode = Anzahl der SYSIN-Zeilen. }
{$mode objfpc}{$H+}
uses SysUtils;
var
  fin, fout: text;
  s: string;
  n, sum, lines: longint;
begin
  writeln('Pascal im Batch mit DD-Anweisungen');
  n := 0;
  sum := 0;
  while not eof(input) do
    begin
      readln(s);
      inc(n);
      sum := sum + StrToIntDef(Trim(s), 0);
    end;
  writeln('SYSIN: ', n, ' Zeilen, Summe ', sum);

  assign(fin, 'DD:INDATA');
  reset(fin);
  assign(fout, 'DD:OUTDATA');
  rewrite(fout);
  lines := 0;
  while not eof(fin) do
    begin
      readln(fin, s);
      writeln(fout, UpperCase(s));
      inc(lines);
    end;
  close(fin);
  close(fout);
  writeln('INDATA -> OUTDATA: ', lines, ' Zeilen');
  writeln('Umlaute: ', #$C4#$D6#$DC);
  halt(n);
end.
