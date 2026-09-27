program evtwait;
{ PF3: pthread_cond_timedwait aus Pascal (Zeitlimit für BasicEventWaitFor) }
{$mode objfpc}
uses cthreads, SysUtils, BaseUnix, Unix, UnixType;
type
  tmutex = array[0..7] of qword;
  tcond = array[0..7] of qword;
function pthread_mutex_init(m: pointer; a: pointer): cint; cdecl; external 'c';
function pthread_cond_init(c: pointer; a: pointer): cint; cdecl; external 'c';
function pthread_mutex_lock(m: pointer): cint; cdecl; external 'c';
function pthread_cond_timedwait(c, m: pointer; t: ptimespec): cint; cdecl; external 'c';
var
  tv: timeval;
  ts: timespec;
  m: tmutex;
  c: tcond;
  r: cint;
begin
  fpgettimeofday(@tv, nil);
  writeln('gettimeofday: sec=', tv.tv_sec, ' usec=', tv.tv_usec, ' sizeof(timeval)=', sizeof(tv), ' sizeof(timespec)=', sizeof(ts));
  flush(output);
  ts.tv_sec := tv.tv_sec + 1;
  ts.tv_nsec := tv.tv_usec * 1000;
  pthread_mutex_init(@m, nil);
  pthread_cond_init(@c, nil);
  pthread_mutex_lock(@m);
  r := pthread_cond_timedwait(@c, @m, @ts);
  writeln('pthread_cond_timedwait = ', r, ' errno ', fpgeterrno, ' (ESysETIMEDOUT=', ESysETIMEDOUT, ')');
end.
