program abi;
{ PF5: C-ABI (XPLINK-64) - Records als Ergebnis und als Wertparameter von C-Funktionen
  (cdecl), alle Größen- und Typklassen. Gegenstück: abi_c.c. Returncode = Anzahl Fehler. }
{$mode objfpc}{$H+}
{$L abi_c.o}
{$packrecords c}
type
  s1 = record a: shortint; end;
  s2 = record a: smallint; end;
  s3 = record a, b, c: shortint; end;
  s4 = record a: longint; end;
  s5 = record a: array[0..4] of shortint; end;
  s6 = record a, b, c: smallint; end;
  s7 = record a: array[0..6] of shortint; end;
  s12 = record a, b, c: longint; end;
  s20 = record a: array[0..4] of longint; end;
  s32 = record a: array[0..3] of int64; end;
  f1 = record a: single; end;
  f2 = record a, b: single; end;
  d1 = record a: double; end;
  d2 = record a, b: double; end;
  fd = record a: single; b: double; end;

function rs1(x: longint): s1; cdecl; external;
function rs2(x: longint): s2; cdecl; external;
function rs3(x: longint): s3; cdecl; external;
function rs4(x: longint): s4; cdecl; external;
function rs5(x: longint): s5; cdecl; external;
function rs6(x: longint): s6; cdecl; external;
function rs7(x: longint): s7; cdecl; external;
function rs12(x: longint): s12; cdecl; external;
function rs20(x: longint): s20; cdecl; external;
function rs32(x: longint): s32; cdecl; external;
function rf1(x: longint): f1; cdecl; external;
function rf2(x: longint): f2; cdecl; external;
function rd1(x: longint): d1; cdecl; external;
function rd2(x: longint): d2; cdecl; external;
function rfd(x: longint): fd; cdecl; external;

function ps1(r: s1): int64; cdecl; external;
function ps3(r: s3): int64; cdecl; external;
function ps5(r: s5): int64; cdecl; external;
function ps6(r: s6): int64; cdecl; external;
function ps12(r: s12): int64; cdecl; external;
function ps20(r: s20): int64; cdecl; external;
function ps32(r: s32): int64; cdecl; external;
function pf2(r: f2): int64; cdecl; external;
function pd2(r: d2): int64; cdecl; external;
function pfd(r: fd): int64; cdecl; external;
function pmix(i: longint; r: s3; d: d2): int64; cdecl; external;

{ Gegenrichtung: von C gerufene Pascal-Funktionen }
function qrs3(x: longint): s3; cdecl; public name 'qrs3';
begin result.a := x; result.b := x + 1; result.c := x + 2; end;
function qrs12(x: longint): s12; cdecl; public name 'qrs12';
begin result.a := x; result.b := x + 1; result.c := x + 2; end;
function qrs20(x: longint): s20; cdecl; public name 'qrs20';
var i: longint;
begin for i := 0 to 4 do result.a[i] := x + i; end;
function qrf2(x: longint): f2; cdecl; public name 'qrf2';
begin result.a := x; result.b := x + 1; end;
function qrd2(x: longint): d2; cdecl; public name 'qrd2';
begin result.a := x; result.b := x + 1; end;
function qrfd(x: longint): fd; cdecl; public name 'qrfd';
begin result.a := x; result.b := x + 1; end;
function qps1(r: s1): int64; cdecl; public name 'qps1';
begin result := r.a; end;
function qps3(r: s3): int64; cdecl; public name 'qps3';
begin result := r.a * 10000 + r.b * 100 + r.c; end;
function qps12(r: s12): int64; cdecl; public name 'qps12';
begin result := r.a * 10000 + r.b * 100 + r.c; end;
function qpd2(r: d2): int64; cdecl; public name 'qpd2';
begin result := trunc(r.a * 100 + r.b); end;
function qpmix(i: longint; r: s3; d: d2): int64; cdecl; public name 'qpmix';
begin result := int64(i) * 1000000 + r.a * 10000 + trunc(d.a * 100 + d.b); end;

function c_calls_pascal: int64; cdecl; external;

var
  errors: longint = 0;

procedure check(const what: string; ok: boolean);
begin
  if ok then writeln('OK      ', what)
  else begin writeln('FEHLER  ', what); inc(errors); end;
end;

function arr5(const a: array of shortint): boolean;
var i: longint;
begin
  result := true;
  for i := 0 to high(a) do
    if a[i] <> 10 + i then result := false;
end;

var
  i: longint;
  ok: boolean;
  v1: s1; v3: s3; v5: s5; v6: s6; v12: s12; v20: s20; v32: s32;
  vf2: f2; vd2: d2; vfd: fd;
begin
  { Ergebnisse }
  check('rs1', rs1(10).a = 10);
  check('rs2', rs2(1000).a = 1000);
  v3 := rs3(10);
  check('rs3', (v3.a = 10) and (v3.b = 11) and (v3.c = 12));
  check('rs4', rs4(123456).a = 123456);
  check('rs5', arr5(rs5(10).a));
  v6 := rs6(10);
  check('rs6', (v6.a = 10) and (v6.b = 11) and (v6.c = 12));
  check('rs7', arr5(rs7(10).a));
  v12 := rs12(10);
  check('rs12', (v12.a = 10) and (v12.b = 11) and (v12.c = 12));
  v20 := rs20(10);
  ok := true;
  for i := 0 to 4 do if v20.a[i] <> 10 + i then ok := false;
  check('rs20', ok);
  v32 := rs32(10);
  check('rs32', (v32.a[0] = 10) and (v32.a[3] = 13));
  check('rf1', rf1(10).a = 10.0);
  vf2 := rf2(10);
  check('rf2 (complex-like)', (vf2.a = 10.0) and (vf2.b = 11.0));
  check('rd1', rd1(10).a = 10.0);
  vd2 := rd2(10);
  check('rd2 (complex-like)', (vd2.a = 10.0) and (vd2.b = 11.0));
  vfd := rfd(10);
  check('rfd', (vfd.a = 10.0) and (vfd.b = 11.0));

  { Wertparameter }
  v1.a := 7;
  check('ps1', ps1(v1) = 7);
  v3.a := 1; v3.b := 2; v3.c := 3;
  check('ps3', ps3(v3) = 10203);
  for i := 0 to 4 do v5.a[i] := i + 1;
  check('ps5', ps5(v5) = 102030405);
  v6.a := 1; v6.b := 2; v6.c := 3;
  check('ps6', ps6(v6) = 10203);
  v12.a := 1; v12.b := 2; v12.c := 3;
  check('ps12', ps12(v12) = 10203);
  for i := 0 to 4 do v20.a[i] := i + 1;
  check('ps20', ps20(v20) = 102030405);
  v32.a[0] := 5; v32.a[1] := 0; v32.a[2] := 0; v32.a[3] := 9;
  check('ps32', ps32(v32) = 5009);
  vf2.a := 3; vf2.b := 4;
  check('pf2 (complex-like)', pf2(vf2) = 304);
  vd2.a := 5; vd2.b := 6;
  check('pd2 (complex-like)', pd2(vd2) = 506);
  vfd.a := 7; vfd.b := 8;
  check('pfd', pfd(vfd) = 708);
  { i * 1000000 + r.a * 10000 + d.a * 100 + d.b }
  check('pmix', pmix(4, v3, vd2) = 4010506);

  { C ruft Pascal }
  i := c_calls_pascal;
  if i <> 0 then writeln('C ruft Pascal, fehlgeschlagene Prüfungen (Bits): ', hexstr(i, 4));
  check('C ruft Pascal (11 Prüfungen)', i = 0);
  writeln('Fehler: ', errors);
  halt(errors);
end.
