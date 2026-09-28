program procprobe;
{ PF7: Ausgabe eines z/OS-UNIX-Kommandos über TProcess (Pipes) }
{$mode objfpc}{$H+}
uses Classes, Process, SysUtils;

procedure run(const exe: string; const args: array of string);
var
  p: TProcess;
  s: TStringList;
  i: integer;
  buf: array[0..255] of byte;
  n: longint;
  all: string;
begin
  p := TProcess.Create(nil);
  try
    p.Executable := exe;
    for i := 0 to high(args) do
      p.Parameters.Add(args[i]);
    p.Options := [poUsePipes, poWaitOnExit];
    p.Execute;
    all := '';
    repeat
      n := p.Output.Read(buf, sizeof(buf));
      for i := 0 to n - 1 do
        all := all + IntToHex(buf[i], 2) + ' ';
    until n <= 0;
    writeln(exe, ': ExitStatus=', p.ExitStatus, ' ExitCode=', p.ExitCode, ' stdout: ', all);
  finally
    p.Free;
  end;
end;

begin
  run('/bin/echo', ['hallo']);
  run('/bin/sh', ['-c', 'echo hallo; echo fehler >&2; exit 3']);
end.
