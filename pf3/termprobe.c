/* termios auf z/OS: Struktur und Konstanten (Vergleich mit rtl/zos/termios.inc) */
#include <termios.h>
#include <sys/ioctl.h>
#include <stdio.h>
#include <stddef.h>
#define C(x) printf("%-10s = $%08x\n", #x, (unsigned)(x))
int main(void)
{
  printf("sizeof(termios) %d NCCS %d c_cc@%d tcflag_t %d cc_t %d speed_t %d\n",
         (int)sizeof(struct termios), NCCS, (int)offsetof(struct termios, c_cc),
         (int)sizeof(tcflag_t), (int)sizeof(cc_t), (int)sizeof(speed_t));
  printf("offsets iflag %d oflag %d cflag %d lflag %d\n",
         (int)offsetof(struct termios, c_iflag), (int)offsetof(struct termios, c_oflag),
         (int)offsetof(struct termios, c_cflag), (int)offsetof(struct termios, c_lflag));
  C(TCSANOW); C(TCSADRAIN); C(TCSAFLUSH);
  C(VINTR); C(VQUIT); C(VERASE); C(VKILL); C(VEOF); C(VEOL); C(VMIN); C(VTIME); C(VSTART); C(VSTOP); C(VSUSP);
  C(IGNBRK); C(BRKINT); C(IGNPAR); C(PARMRK); C(INPCK); C(ISTRIP); C(INLCR); C(IGNCR); C(ICRNL);
  C(IXON); C(IXOFF); C(IXANY);
  C(OPOST); C(ONLCR);
  C(CSIZE); C(CS5); C(CS8); C(CSTOPB); C(CREAD); C(PARENB); C(HUPCL); C(CLOCAL);
  C(ISIG); C(ICANON); C(ECHO); C(ECHOE); C(ECHOK); C(ECHONL); C(NOFLSH); C(TOSTOP); C(IEXTEN);
  C(B0); C(B9600); C(B38400);
  C(TIOCGWINSZ);
  C(TCIFLUSH); C(TCOFLUSH); C(TCIOFLUSH); C(TCOOFF); C(TCOON);
  return 0;
}
