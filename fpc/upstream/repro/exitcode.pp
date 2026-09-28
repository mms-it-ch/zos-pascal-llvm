program exitcode;
{ TProcess.ExitCode after poWaitOnExit: /bin/sh -c "exit 3" must give 3 }
{$mode objfpc}{$H+}
uses Process;
var
  p: TProcess;
begin
  p := TProcess.Create(nil);
  p.Executable := '/bin/sh';
  p.Parameters.Add('-c');
  p.Parameters.Add('exit 3');
  p.Options := [poWaitOnExit];
  p.Execute;
  writeln('ExitStatus=', p.ExitStatus, ' ExitCode=', p.ExitCode);
  if p.ExitCode <> 3 then
    halt(1);
  p.Free;
end.
