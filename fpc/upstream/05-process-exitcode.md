**Title:** TProcess.ExitCode is always 0 after poWaitOnExit / WaitOnExit on unix

### Summary

On unix, `TProcess.ExitCode` is 0 after `WaitOnExit` (or `poWaitOnExit`), whatever the exit code of the child was. `ExitStatus` contains the exit code instead.

### Reproducer (x86_64-linux, normal code generator)

```pascal
program exitcode;
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
```

Observed (main): `ExitStatus=3 ExitCode=0`. Expected: `ExitCode=3`.

### Cause

`FExitCode` is filled in two ways (`packages/fcl-process/src/unix/process.inc`): `PeekExitStatus` (used by `Running`, e.g. in `RunCommand`) stores the raw wait status of `fpWaitPid`, while `WaitOnExit` stores the result of `WaitProcess`, which is the already decoded exit code. `GetExitCode` always decodes `FExitCode` again with `wifexited`/`wexitstatus`; for the decoded value 3 `wifexited` is false, so `ExitCode` is 0.

### Patch

`0007-fcl-process-ExitCode-after-WaitOnExit-on-unix.patch`: `WaitOnExit` also stores the raw wait status (`fpWaitPid(Handle, @FExitCode, 0)`, retried on `EINTR`). Result of the reproducer with the patch: `ExitStatus=768 ExitCode=3`, the same values as when the process is waited for via `Running`. The return value of `WaitOnExit` stays false for an error or a process terminated by a signal.

Behaviour change: after `WaitOnExit`, `ExitStatus` is now the raw wait status (as after waiting via `Running`) instead of the decoded exit code. Code that relied on `ExitStatus` being the exit code after `poWaitOnExit` should use `ExitCode`.

Verified on x86_64-linux (normal code generator) and on s390x/z/OS.

---
*Drafted with the help of Claude Code (Anthropic). The results above were produced with the attached reproducer and patch.*
