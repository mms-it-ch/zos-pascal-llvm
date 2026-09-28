program ipctest;
{ PF7: System V IPC (Unit ipc) auf z/OS: Shared Memory, Message Queue, Semaphoren.
  Alle Objekte sind privat (IPC_PRIVATE) und werden am Ende entfernt.
  Returncode = Anzahl Fehler. }
{$mode objfpc}{$H+}
uses BaseUnix, ipc, SysUtils;

var
  errors: longint = 0;

procedure check(const what: string; ok: boolean);
begin
  if ok then writeln('OK      ', what)
  else begin writeln('FEHLER  ', what, ' (errno ', fpgeterrno, ')'); inc(errors); end;
end;

procedure shmtest;
var
  id: cint;
  p: PAnsiChar;
  ds: TShmid_ds;
begin
  id := shmget(IPC_PRIVATE, 4096, IPC_CREAT or &600);
  check('shmget', id >= 0);
  p := shmat(id, nil, 0);
  check('shmat', p <> pointer(-1));
  StrPCopy(p, 'geteilter Speicher');
  check('shmctl IPC_STAT', shmctl(id, IPC_STAT, @ds) = 0);
  { AMODE 64: das Segment liegt oberhalb der 2-GB-Grenze (shm_seg64, Bit X'80' in
    shm_flags64), z/OS rundet die Größe auf 1 MB auf }
  check('shm_segsz >= 4096 (64-Bit-Segment), nattch = 1, cpid = eigene',
    (ds.shm_segsz >= 4096) and (ds.shm_flags64 and $80000000 <> 0) and (ds.shm_nattch = 1)
    and (ds.shm_cpid = fpgetpid));
  check('Inhalt', StrPas(p) = 'geteilter Speicher');
  check('shmdt', shmdt(p) = 0);
  check('shmctl IPC_RMID', shmctl(id, IPC_RMID, nil) = 0);
end;

type
  TMyMsg = record
    mtype: clong;
    text: array[0..31] of AnsiChar;
  end;

procedure msgtest;
var
  id: cint;
  m, r: TMyMsg;
  ds: TMSQid_ds;
  n: ssize_t;
begin
  id := msgget(IPC_PRIVATE, IPC_CREAT or &600);
  check('msgget', id >= 0);
  m.mtype := 7;
  StrPCopy(m.text, 'Nachricht');
  check('msgsnd', msgsnd(id, PMSGbuf(@m), 10, 0) = 0);
  check('msgctl IPC_STAT', msgctl(id, IPC_STAT, @ds) = 0);
  check('msg_qnum = 1, msg_lspid = eigene', (ds.msg_qnum = 1) and (ds.msg_lspid = fpgetpid)
    and (ds.msg_stime > 0));
  FillChar(r, sizeof(r), 0);
  n := msgrcv(id, PMSGbuf(@r), sizeof(r.text), 0, 0);
  check('msgrcv', (n = 10) and (r.mtype = 7) and (StrPas(r.text) = 'Nachricht'));
  check('msgctl IPC_RMID', msgctl(id, IPC_RMID, nil) = 0);
end;

procedure semtest;
var
  id: cint;
  arg: TSEMun;
  op: TSEMbuf;
  ds: TSEMid_ds;
begin
  id := semget(IPC_PRIVATE, 2, IPC_CREAT or &600);
  check('semget', id >= 0);
  arg.val := 5;
  check('semctl SETVAL 5', semctl(id, 1, SEM_SETVAL, arg) = 0);
  arg.val := 0;
  check('semctl GETVAL = 5', semctl(id, 1, SEM_GETVAL, arg) = 5);
  op.sem_num := 1;
  op.sem_op := -2;
  op.sem_flg := 0;
  check('semop -2', semop(id, @op, 1) = 0);
  check('semctl GETVAL = 3', semctl(id, 1, SEM_GETVAL, arg) = 3);
  check('semctl GETPID = eigene', semctl(id, 1, SEM_GETPID, arg) = fpgetpid);
  arg.buf := @ds;
  check('semctl IPC_STAT', semctl(id, 0, IPC_STAT, arg) = 0);
  check('sem_nsems = 2', (ds.sem_nsems = 2) and (ds.sem_otime > 0));
  check('semctl IPC_RMID', semctl(id, 0, IPC_RMID, arg) = 0);
end;

begin
  shmtest;
  msgtest;
  semtest;
  writeln('Fehler: ', errors);
  halt(errors);
end.
