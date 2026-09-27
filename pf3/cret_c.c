/* C-Seite für cret.pas: Rückgabe kleiner Records (XPLINK: bis 24 Byte in GPR 3, 2, 1) */
struct r8 { int a, b; };
struct r16 { long a; long b; };
struct r24 { long a; long b; long c; };
struct r8 cret8(int x) { struct r8 r = { x, x + 1 }; return r; }
struct r16 cret16(long x) { struct r16 r = { x, -x }; return r; }
struct r24 cret24(long x) { struct r24 r = { x, 2 * x, 3 * x }; return r; }
/* Aufruf in Gegenrichtung: Pascal-Funktion (cdecl) aus C */
extern struct r16 pret16(long x);
long call_pret16(long x) { struct r16 r = pret16(x); return r.a * 1000 + r.b; }
