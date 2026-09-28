/* PF5: C-ABI (XPLINK-64) für Records als Ergebnis und als Wertparameter.
 * Jede Funktion baut aus x einen Record; die Prüffunktionen nehmen einen
 * Record als Wert und geben eine Prüfsumme zurück. */
struct s1 { char a; };
struct s2 { short a; };
struct s3 { char a, b, c; };
struct s4 { int a; };
struct s5 { char a[5]; };
struct s6 { short a, b, c; };
struct s7 { char a[7]; };
struct s12 { int a, b, c; };
struct s20 { int a[5]; };
struct s32 { long a[4]; };
struct f1 { float a; };
struct f2 { float a, b; };
struct d1 { double a; };
struct d2 { double a, b; };
struct fd { float a; double b; };

struct s1 rs1(int x) { struct s1 r = { x }; return r; }
struct s2 rs2(int x) { struct s2 r = { x }; return r; }
struct s3 rs3(int x) { struct s3 r = { x, x + 1, x + 2 }; return r; }
struct s4 rs4(int x) { struct s4 r = { x }; return r; }
struct s5 rs5(int x) { struct s5 r; for (int i = 0; i < 5; i++) r.a[i] = x + i; return r; }
struct s6 rs6(int x) { struct s6 r = { x, x + 1, x + 2 }; return r; }
struct s7 rs7(int x) { struct s7 r; for (int i = 0; i < 7; i++) r.a[i] = x + i; return r; }
struct s12 rs12(int x) { struct s12 r = { x, x + 1, x + 2 }; return r; }
struct s20 rs20(int x) { struct s20 r; for (int i = 0; i < 5; i++) r.a[i] = x + i; return r; }
struct s32 rs32(int x) { struct s32 r; for (int i = 0; i < 4; i++) r.a[i] = x + i; return r; }
struct f1 rf1(int x) { struct f1 r = { x }; return r; }
struct f2 rf2(int x) { struct f2 r = { x, x + 1 }; return r; }
struct d1 rd1(int x) { struct d1 r = { x }; return r; }
struct d2 rd2(int x) { struct d2 r = { x, x + 1 }; return r; }
struct fd rfd(int x) { struct fd r = { x, x + 1 }; return r; }

long ps1(struct s1 r) { return r.a; }
long ps3(struct s3 r) { return r.a * 10000 + r.b * 100 + r.c; }
long ps5(struct s5 r) { long s = 0; for (int i = 0; i < 5; i++) s = s * 100 + r.a[i]; return s; }
long ps6(struct s6 r) { return r.a * 10000 + r.b * 100 + r.c; }
long ps12(struct s12 r) { return r.a * 10000 + r.b * 100 + r.c; }
long ps20(struct s20 r) { long s = 0; for (int i = 0; i < 5; i++) s = s * 100 + r.a[i]; return s; }
long ps32(struct s32 r) { return r.a[0] * 1000 + r.a[3]; }
long pf2(struct f2 r) { return (long)(r.a * 100 + r.b); }
long pd2(struct d2 r) { return (long)(r.a * 100 + r.b); }
long pfd(struct fd r) { return (long)(r.a * 100 + r.b); }
/* gemischt: Record nach int, Record nach Record */
long pmix(int i, struct s3 r, struct d2 d) { return i * 1000000 + r.a * 10000 + (long)(d.a * 100 + d.b); }

/* Gegenrichtung: C ruft Pascal-Funktionen (cdecl, in abi.pas) */
extern struct s3 qrs3(int x);
extern struct s12 qrs12(int x);
extern struct s20 qrs20(int x);
extern struct f2 qrf2(int x);
extern struct d2 qrd2(int x);
extern struct fd qrfd(int x);
extern long qps1(struct s1 r);
extern long qps3(struct s3 r);
extern long qps12(struct s12 r);
extern long qpd2(struct d2 r);
extern long qpmix(int i, struct s3 r, struct d2 d);
/* Anzahl Fehler; Bit n = Prüfung n */
long c_calls_pascal(void)
{
  long bad = 0;
  struct s3 a = qrs3(10);
  if (a.a != 10 || a.b != 11 || a.c != 12) bad |= 1 << 0;
  struct s12 b = qrs12(10);
  if (b.a != 10 || b.b != 11 || b.c != 12) bad |= 1 << 1;
  struct s20 c = qrs20(10);
  for (int i = 0; i < 5; i++) if (c.a[i] != 10 + i) bad |= 1 << 2;
  struct f2 d = qrf2(10);
  if (d.a != 10 || d.b != 11) bad |= 1 << 3;
  struct d2 e = qrd2(10);
  if (e.a != 10 || e.b != 11) bad |= 1 << 4;
  struct fd f = qrfd(10);
  if (f.a != 10 || f.b != 11) bad |= 1 << 5;
  struct s1 g = { 7 };
  if (qps1(g) != 7) bad |= 1 << 6;
  struct s3 h = { 1, 2, 3 };
  if (qps3(h) != 10203) bad |= 1 << 7;
  struct s12 k = { 1, 2, 3 };
  if (qps12(k) != 10203) bad |= 1 << 8;
  struct d2 m = { 5, 6 };
  if (qpd2(m) != 506) bad |= 1 << 9;
  if (qpmix(4, h, m) != 4010506) bad |= 1 << 10;
  return bad;
}
