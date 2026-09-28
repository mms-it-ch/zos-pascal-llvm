program procprobe2;
{ PF7: wartende Bytes in einer Pipe auf z/OS - ioctl FIONREAD, fstat, poll }
{$mode objfpc}{$H+}
uses Classes, Process, SysUtils, BaseUnix, termio;
var
  p: TProcess;
  n: longint;
  r: cint;
  st: stat;
  fds: array[0..0] of pollfd;
begin
  p := TProcess.Create(nil);
  p.Executable := '/bin/echo';
  p.Parameters.Add('hallo welt');
  p.Options := [poUsePipes];
  p.Execute;
  sleep(500);
  n := 0;
  r := fpioctl(p.Output.Handle, FIONREAD, @n);
  writeln('ioctl FIONREAD: rc=', r, ' errno=', fpgeterrno, ' n=', n);
  r := fpfstat(p.Output.Handle, st);
  writeln('fstat: rc=', r, ' st_size=', st.st_size, ' mode=', IntToHex(st.st_mode, 8));
  fds[0].fd := p.Output.Handle;
  fds[0].events := POLLIN;
  fds[0].revents := 0;
  r := fppoll(@fds[0], 1, 0);
  writeln('poll: rc=', r, ' revents=', fds[0].revents);
  p.WaitOnExit;
  p.Free;
end.
