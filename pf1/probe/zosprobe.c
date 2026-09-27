/* zosprobe: ermittelt auf z/OS (64 Bit, ASCII-Modus, dieselben Makros wie
 * zos-cc) Typgrößen, Strukturlayouts und Konstanten und gibt sie als
 * Pascal-Quelltext für rtl/zos aus.
 *
 *   zos-cc -c zosprobe.c -o zosprobe.o ; auf z/OS binden und ausführen
 *
 * Strukturen werden nach Offsets sortiert ausgegeben; Lücken werden mit
 * Füllbytes (_padN) aufgefüllt, so dass Größe und Lage jedes Feldes exakt dem
 * C-Layout entsprechen. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <setjmp.h>
#include <wchar.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#include <dirent.h>
#include <utime.h>
#include <poll.h>
#include <termios.h>
#include <pthread.h>
#include <dlfcn.h>
#include <locale.h>
#include <langinfo.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/times.h>
#include <sys/utsname.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <sys/mman.h>
#include <sys/uio.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/statvfs.h>

enum { K_INT, K_CHARS, K_PTR, K_BYTES };

struct fld { const char *name; size_t off, size; int sgn, kind; };
static struct fld flds[64];
static int nfld;
static const char *sname;
static size_t ssize;

static const char *inttype(size_t size, int sgn)
{
  switch (size) {
  case 1: return sgn ? "cschar" : "cuchar";
  case 2: return sgn ? "cshort" : "cushort";
  case 4: return sgn ? "cint" : "cuint";
  case 8: return sgn ? "clong" : "culong";
  }
  return "?";
}

static void begin(const char *n, size_t size) { sname = n; ssize = size; nfld = 0; }

static void field(const char *n, size_t off, size_t size, int sgn, int kind)
{
  flds[nfld].name = n; flds[nfld].off = off; flds[nfld].size = size;
  flds[nfld].sgn = sgn; flds[nfld].kind = kind; nfld++;
}

static int cmpfld(const void *a, const void *b)
{
  const struct fld *x = a, *y = b;
  return x->off < y->off ? -1 : x->off > y->off;
}

static void end(void)
{
  size_t pos = 0;
  int pad = 0, i;
  qsort(flds, nfld, sizeof flds[0], cmpfld);
  printf("  %s = record { C: %zu Bytes }\n", sname, ssize);
  for (i = 0; i < nfld; i++) {
    struct fld *f = &flds[i];
    if (f->off > pos)
      printf("    _pad%d: array[0..%zu] of byte;\n", pad++, f->off - pos - 1);
    switch (f->kind) {
    case K_INT:   printf("    %s: %s;\n", f->name, inttype(f->size, f->sgn)); break;
    case K_CHARS: printf("    %s: array[0..%zu] of AnsiChar;\n", f->name, f->size - 1); break;
    case K_PTR:   printf("    %s: pointer;\n", f->name); break;
    case K_BYTES: printf("    %s: array[0..%zu] of byte;\n", f->name, f->size - 1); break;
    }
    pos = f->off + f->size;
  }
  if (ssize > pos)
    printf("    _pad%d: array[0..%zu] of byte;\n", pad, ssize - pos - 1);
  printf("  end;\n\n");
}

#define SGN(x) ((__typeof__(x))-1 < (__typeof__(x))0)
#define BEGIN(T, n) begin(n, sizeof(T))
#define FI(T, f, n) field(n, offsetof(T, f), sizeof(((T *)0)->f), SGN(((T *)0)->f), K_INT)
#define FC(T, f, n) field(n, offsetof(T, f), sizeof(((T *)0)->f), 0, K_CHARS)
#define FP(T, f, n) field(n, offsetof(T, f), sizeof(((T *)0)->f), 0, K_PTR)
#define FB(T, f, n) field(n, offsetof(T, f), sizeof(((T *)0)->f), 0, K_BYTES)
#define END() end()

#define TYPE(T, n) printf("  %s = %s;\n", n, inttype(sizeof(T), SGN((T)0)))
#define OPAQUE(T, n) printf("  %s = record _data: array[0..%zu] of byte; end; { C: %zu Bytes, Ausrichtung %zu }\n", \
                            n, sizeof(T) - 1, sizeof(T), _Alignof(T))
#define C(x) printf("  %s = %lld;\n", #x, (long long)(x))

int main(void)
{
  printf("{ Erzeugt von pf1/probe/zosprobe.c auf z/OS - nicht von Hand ändern }\n\n");

  printf("{ --- Typen --- }\ntype\n");
  TYPE(dev_t, "dev_t"); TYPE(ino_t, "ino_t"); TYPE(mode_t, "mode_t");
  TYPE(nlink_t, "nlink_t"); TYPE(uid_t, "uid_t"); TYPE(gid_t, "gid_t");
  TYPE(off_t, "off_t"); TYPE(pid_t, "pid_t"); TYPE(size_t, "size_t");
  TYPE(ssize_t, "ssize_t"); TYPE(time_t, "time_t"); TYPE(clock_t, "clock_t");
  TYPE(suseconds_t, "suseconds_t"); TYPE(blksize_t, "blksize_t");
  TYPE(blkcnt_t, "blkcnt_t"); TYPE(socklen_t, "socklen_t"); TYPE(wchar_t, "wchar_t");
  TYPE(wint_t, "wint_t"); TYPE(rlim_t, "rlim_t"); TYPE(clockid_t, "clockid_t");
  TYPE(key_t, "key_t"); TYPE(id_t, "id_t");
  printf("\n");
  OPAQUE(sigset_t, "sigset_t");
  OPAQUE(pthread_t, "pthread_t");
  OPAQUE(pthread_attr_t, "pthread_attr_t");
  OPAQUE(pthread_mutex_t, "pthread_mutex_t");
  OPAQUE(pthread_mutexattr_t, "pthread_mutexattr_t");
  OPAQUE(pthread_cond_t, "pthread_cond_t");
  OPAQUE(pthread_condattr_t, "pthread_condattr_t");
  OPAQUE(pthread_key_t, "pthread_key_t");
  OPAQUE(pthread_once_t, "pthread_once_t");
  OPAQUE(pthread_rwlock_t, "pthread_rwlock_t");
  OPAQUE(fd_set, "fd_set");
  OPAQUE(jmp_buf, "c_jmp_buf");
  OPAQUE(mbstate_t, "mbstate_t");
  printf("\n");

  printf("{ --- Strukturen --- }\ntype\n");
  BEGIN(struct stat, "stat");
  FC(struct stat, st_eye, "st_eye"); FI(struct stat, st_length, "st_length");
  FI(struct stat, st_version, "st_version");
  FI(struct stat, st_mode, "st_mode"); FI(struct stat, st_ino, "st_ino");
  FI(struct stat, st_dev, "st_dev"); FI(struct stat, st_nlink, "st_nlink");
  FI(struct stat, st_uid, "st_uid"); FI(struct stat, st_gid, "st_gid");
  FI(struct stat, st_size, "st_size"); FI(struct stat, st_atime, "st_atime");
  FI(struct stat, st_mtime, "st_mtime"); FI(struct stat, st_ctime, "st_ctime");
  FI(struct stat, st_rdev, "st_rdev"); FI(struct stat, st_blksize, "st_blksize");
  FI(struct stat, st_blocks, "st_blocks");
  END();

  BEGIN(struct dirent, "dirent");
  FI(struct dirent, d_ino, "d_ino"); FC(struct dirent, d_name, "d_name");
  END();

  BEGIN(struct timeval, "timeval");
  FI(struct timeval, tv_sec, "tv_sec"); FI(struct timeval, tv_usec, "tv_usec");
  END();
  BEGIN(struct timespec, "timespec");
  FI(struct timespec, tv_sec, "tv_sec"); FI(struct timespec, tv_nsec, "tv_nsec");
  END();
  BEGIN(struct timezone, "timezone");
  FI(struct timezone, tz_minuteswest, "tz_minuteswest"); FI(struct timezone, tz_dsttime, "tz_dsttime");
  END();
  BEGIN(struct tms, "tms");
  FI(struct tms, tms_utime, "tms_utime"); FI(struct tms, tms_stime, "tms_stime");
  FI(struct tms, tms_cutime, "tms_cutime"); FI(struct tms, tms_cstime, "tms_cstime");
  END();
  BEGIN(struct tm, "tm");
  FI(struct tm, tm_sec, "tm_sec"); FI(struct tm, tm_min, "tm_min"); FI(struct tm, tm_hour, "tm_hour");
  FI(struct tm, tm_mday, "tm_mday"); FI(struct tm, tm_mon, "tm_mon"); FI(struct tm, tm_year, "tm_year");
  FI(struct tm, tm_wday, "tm_wday"); FI(struct tm, tm_yday, "tm_yday"); FI(struct tm, tm_isdst, "tm_isdst");
  END();
  BEGIN(struct utsname, "utsname");
  FC(struct utsname, sysname, "sysname"); FC(struct utsname, nodename, "nodename");
  FC(struct utsname, release, "release"); FC(struct utsname, version, "version");
  FC(struct utsname, machine, "machine");
  END();
  BEGIN(struct utimbuf, "utimbuf");
  FI(struct utimbuf, actime, "actime"); FI(struct utimbuf, modtime, "modtime");
  END();
  BEGIN(struct flock, "flock");
  FI(struct flock, l_type, "l_type"); FI(struct flock, l_whence, "l_whence");
  FI(struct flock, l_start, "l_start"); FI(struct flock, l_len, "l_len");
  FI(struct flock, l_pid, "l_pid");
  END();
  BEGIN(struct rlimit, "rlimit");
  FI(struct rlimit, rlim_cur, "rlim_cur"); FI(struct rlimit, rlim_max, "rlim_max");
  END();
  BEGIN(struct iovec, "iovec");
  FP(struct iovec, iov_base, "iov_base"); FI(struct iovec, iov_len, "iov_len");
  END();
  BEGIN(struct pollfd, "pollfd");
  FI(struct pollfd, fd, "fd"); FI(struct pollfd, events, "events"); FI(struct pollfd, revents, "revents");
  END();
  BEGIN(struct sigaction, "sigactionrec");
  FP(struct sigaction, sa_handler, "sa_handler"); FB(struct sigaction, sa_mask, "sa_mask");
  FI(struct sigaction, sa_flags, "sa_flags");
  END();
  BEGIN(siginfo_t, "siginfo_t");
  FI(siginfo_t, si_signo, "si_signo"); FI(siginfo_t, si_errno, "si_errno");
  FI(siginfo_t, si_code, "si_code"); FP(siginfo_t, si_addr, "si_addr");
  END();
  BEGIN(struct termios, "termios");
  FI(struct termios, c_iflag, "c_iflag"); FI(struct termios, c_oflag, "c_oflag");
  FI(struct termios, c_cflag, "c_cflag"); FI(struct termios, c_lflag, "c_lflag");
  FB(struct termios, c_cc, "c_cc");
  END();

  BEGIN(struct statvfs, "statvfs");
  FI(struct statvfs, f_bsize, "bsize"); FI(struct statvfs, f_frsize, "frsize");
  FI(struct statvfs, f_blocks, "blocks"); FI(struct statvfs, f_bfree, "bfree");
  FI(struct statvfs, f_bavail, "bavail"); FI(struct statvfs, f_files, "files");
  FI(struct statvfs, f_ffree, "ffree"); FI(struct statvfs, f_favail, "favail");
  FI(struct statvfs, f_fsid, "fsid"); FI(struct statvfs, f_flag, "flag");
  FI(struct statvfs, f_namemax, "namemax");
  END();

  printf("{ --- Konstanten --- }\nconst\n");
  /* errno */
  C(EPERM); C(ENOENT); C(ESRCH); C(EINTR); C(EIO); C(ENXIO); C(E2BIG); C(ENOEXEC);
  C(EBADF); C(ECHILD); C(EAGAIN); C(ENOMEM); C(EACCES); C(EFAULT); C(EBUSY);
  C(EEXIST); C(EXDEV); C(ENODEV); C(ENOTDIR); C(EISDIR); C(EINVAL); C(ENFILE);
  C(EMFILE); C(ENOTTY); C(EFBIG); C(ENOSPC); C(ESPIPE); C(EROFS); C(EMLINK);
  C(EPIPE); C(EDOM); C(ERANGE); C(EDEADLK); C(ENAMETOOLONG); C(ENOLCK);
  C(ENOSYS); C(ENOTEMPTY); C(ELOOP); C(EWOULDBLOCK); C(ENOMSG); C(EILSEQ);
  C(EINPROGRESS); C(EALREADY); C(ENOTSOCK); C(EDESTADDRREQ); C(EMSGSIZE);
  C(EPROTOTYPE); C(ENOPROTOOPT); C(EPROTONOSUPPORT); C(EOPNOTSUPP);
  C(EAFNOSUPPORT); C(EADDRINUSE); C(EADDRNOTAVAIL); C(ENETDOWN); C(ENETUNREACH);
  C(ECONNABORTED); C(ECONNRESET); C(ENOBUFS); C(EISCONN); C(ENOTCONN);
  C(ETIMEDOUT); C(ECONNREFUSED); C(EHOSTUNREACH); C(ETXTBSY); C(EOVERFLOW);
  C(ECANCELED); C(ENOTSUP);
  /* open/fcntl/access/seek */
  C(O_RDONLY); C(O_WRONLY); C(O_RDWR); C(O_ACCMODE); C(O_CREAT); C(O_EXCL);
  C(O_NOCTTY); C(O_TRUNC); C(O_APPEND); C(O_NONBLOCK); C(O_SYNC);
  C(F_DUPFD); C(F_GETFD); C(F_SETFD); C(F_GETFL); C(F_SETFL); C(F_GETLK);
  C(F_SETLK); C(F_SETLKW); C(FD_CLOEXEC); C(F_RDLCK); C(F_WRLCK); C(F_UNLCK);
  C(F_OK); C(R_OK); C(W_OK); C(X_OK); C(SEEK_SET); C(SEEK_CUR); C(SEEK_END);
  /* Dateimodi */
  C(S_IFMT); C(S_IFIFO); C(S_IFCHR); C(S_IFDIR); C(S_IFBLK); C(S_IFREG);
  C(S_IFLNK); C(S_IFSOCK); C(S_ISUID); C(S_ISGID); C(S_ISVTX);
  C(S_IRUSR); C(S_IWUSR); C(S_IXUSR); C(S_IRGRP); C(S_IWGRP); C(S_IXGRP);
  C(S_IROTH); C(S_IWOTH); C(S_IXOTH);
  /* wait */
  C(WNOHANG); C(WUNTRACED);
  /* Signale */
  C(SIGHUP); C(SIGINT); C(SIGQUIT); C(SIGILL); C(SIGTRAP); C(SIGABRT); C(SIGBUS);
  C(SIGFPE); C(SIGKILL); C(SIGUSR1); C(SIGSEGV); C(SIGUSR2); C(SIGPIPE); C(SIGALRM);
  C(SIGTERM); C(SIGCHLD); C(SIGCONT); C(SIGSTOP); C(SIGTSTP); C(SIGTTIN); C(SIGTTOU);
  C(SIGURG); C(SIGXCPU); C(SIGXFSZ); C(SIGVTALRM); C(SIGPROF); C(SIGWINCH);
  C(SIGIO); C(SIGSYS);
  C(SIG_BLOCK); C(SIG_UNBLOCK); C(SIG_SETMASK);
  C(FPE_INTDIV); C(FPE_INTOVF); C(FPE_FLTDIV); C(FPE_FLTOVF); C(FPE_FLTUND);
  C(FPE_FLTRES); C(FPE_FLTINV); C(FPE_FLTSUB);
  C(ILL_ILLOPC); C(SEGV_MAPERR); C(SEGV_ACCERR);
  C(SA_NOCLDSTOP); C(SA_RESTART); C(SA_SIGINFO); C(SA_NODEFER); C(SA_RESETHAND);
  C(SA_ONSTACK);
  C((long)SIG_DFL); C((long)SIG_IGN);
  /* mmap */
  C(PROT_READ); C(PROT_WRITE); C(PROT_EXEC); C(PROT_NONE);
  C(MAP_SHARED); C(MAP_PRIVATE); C(MAP_FIXED);
  /* poll */
  C(POLLIN); C(POLLPRI); C(POLLOUT); C(POLLERR); C(POLLHUP); C(POLLNVAL);
  /* dlopen */
  C(RTLD_LAZY); C(RTLD_NOW); C(RTLD_GLOBAL); C(RTLD_LOCAL);
  /* sonstiges */
  C(PATH_MAX); C(NAME_MAX); C(CLOCKS_PER_SEC); C(BUFSIZ); C(EOF);
  C(RLIMIT_CORE); C(RLIMIT_CPU); C(RLIMIT_DATA); C(RLIMIT_FSIZE); C(RLIMIT_NOFILE);
  C(RLIMIT_STACK); C(RLIMIT_AS); C(PRIO_PROCESS); C(PRIO_PGRP); C(PRIO_USER);
  C(TCSANOW); C(TCSADRAIN); C(TCSAFLUSH); C(CODESET); C(LC_ALL); C(LC_CTYPE);
  C(_SC_CLK_TCK); C(_SC_PAGESIZE);
  C(sizeof(long)); C(sizeof(void *)); C(sizeof(long double));
  return 0;
}
