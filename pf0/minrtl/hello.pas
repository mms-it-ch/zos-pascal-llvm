program hello;
{ PF0: first Free Pascal program for z/OS (minimal system unit).
  Checks C call, integer parameter extension and 64 bit arithmetic;
  exit code 42 = correct. }

function add(a: longint; b: byte; c: int64): int64;
begin
  add := a + b + c;
end;

var
  r: int64;
begin
  puts('Hello from Free Pascal on z/OS');
  r := add(-2, 200, 30000000000);
  if r = 30000000198 then
    exitcode := 42
  else
    exitcode := 1;
end.
