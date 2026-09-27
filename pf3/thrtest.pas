program thrtest;
{ PF3: Threads (cthreads) auf z/OS }
{$mode objfpc}
uses cthreads, SysUtils;

var
  counter: longint = 0;
  cs: TRTLCriticalSection;

function worker(p: pointer): ptrint;
var
  i: longint;
begin
  for i := 1 to 1000 do
    begin
      EnterCriticalSection(cs);
      inc(counter);
      LeaveCriticalSection(cs);
    end;
  result := ptrint(p);
end;

var
  t: array[1..4] of TThreadID;
  i: longint;
  rc: longint;
begin
  writeln('Start'); flush(output);
  InitCriticalSection(cs);
  for i := 1 to 4 do
    begin
      t[i] := BeginThread(@worker, pointer(ptrint(i)));
      writeln('Thread ', i, ' gestartet'); flush(output);
    end;
  rc := 0;
  for i := 1 to 4 do
    rc := rc + WaitForThreadTerminate(t[i], 0);
  DoneCriticalSection(cs);
  writeln('counter = ', counter, ' rc-Summe = ', rc);
  if (counter = 4000) and (rc = 10) then halt(0) else halt(1);
end.
