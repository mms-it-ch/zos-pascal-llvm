/* PF7: Layout und Konstanten von SysV-IPC auf z/OS (AMODE 64) für rtl-extra/ipc.pp */
#define _XOPEN_SOURCE 600
#include <stddef.h>
#include <stdio.h>
#include <sys/ipc.h>
#include <sys/msg.h>
#include <sys/sem.h>
#include <sys/shm.h>

#define S(t) printf("sizeof(%s)=%zu\n", #t, sizeof(t))
#define O(t, f) printf("  %s.%s off=%zu size %zu\n", #t, #f, offsetof(t, f), sizeof(((t *)0)->f))
#define C(c) printf("%s=%ld\n", #c, (long)(c))

int main(void)
{
  S(key_t); S(uid_t); S(gid_t); S(mode_t); S(pid_t); S(time_t);
  S(msgqnum_t); S(msglen_t); S(shmatt_t);
  S(struct ipc_perm);
  O(struct ipc_perm, uid); O(struct ipc_perm, gid); O(struct ipc_perm, cuid);
  O(struct ipc_perm, cgid); O(struct ipc_perm, mode);
  S(struct msqid_ds);
  O(struct msqid_ds, msg_qnum); O(struct msqid_ds, msg_qbytes); O(struct msqid_ds, msg_lspid);
  O(struct msqid_ds, msg_lrpid); O(struct msqid_ds, msg_stime); O(struct msqid_ds, msg_rtime);
  O(struct msqid_ds, msg_ctime);
  S(struct semid_ds);
  O(struct semid_ds, sem_nsems); O(struct semid_ds, sem_otime); O(struct semid_ds, sem_ctime);
  S(struct sembuf);
  O(struct sembuf, sem_num); O(struct sembuf, sem_op); O(struct sembuf, sem_flg);
  S(struct shmid_ds);
  O(struct shmid_ds, shm_lpid); O(struct shmid_ds, shm_cpid); O(struct shmid_ds, shm_nattch);
  O(struct shmid_ds, shm_segsz); O(struct shmid_ds, shm_atime); O(struct shmid_ds, shm_dtime);
  O(struct shmid_ds, shm_ctime);
  C(IPC_CREAT); C(IPC_EXCL); C(IPC_NOWAIT); C(IPC_PRIVATE); C(IPC_RMID); C(IPC_SET); C(IPC_STAT);
  C(MSG_NOERROR);
  C(SEM_UNDO); C(GETNCNT); C(GETPID); C(GETVAL); C(GETALL); C(GETZCNT); C(SETVAL); C(SETALL);
  C(SHM_RDONLY); C(SHM_RND); C(SHMLBA);
  return 0;
}
