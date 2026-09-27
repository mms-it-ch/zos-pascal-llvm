program sigtest;
{ PF3: kommt SIGFPE beim Pascal-Handler an? }
{$mode objfpc}
uses BaseUnix;

procedure handler(sig: longint; info: PSigInfo; ctx: PSigContext); cdecl;
begin
  writeln('Handler: Signal ', sig, ' si_code ', info^.si_code);
  fpexit(sig);
end;

var
  act, old: SigActionRec;
  r: longint;
  a, b: double;
begin
  fillchar(act, sizeof(act), 0);
  act.sa_handler := @handler;
  act.sa_flags := SA_SIGINFO;
  r := fpsigaction(SIGFPE, @act, @old);
  writeln('sigaction = ', r, ' errno ', fpgeterrno, ' alter Handler ', ptruint(old.sa_handler)); flush(output);
  fillchar(old, sizeof(old), 0);
  r := fpsigaction(SIGFPE, nil, @old);
  writeln('abgefragt: Handler ', hexstr(ptruint(old.sa_handler),16), ' eigener ', hexstr(ptruint(@handler),16), ' flags ', old.sa_flags); writeln('FPC ', hexstr(GetNativeFPUControlWord,8)); flush(output);
  a := 1.0; b := 0.0;
  writeln('Division ...');
  writeln(a / b);
  writeln('nicht erreicht');
end.
