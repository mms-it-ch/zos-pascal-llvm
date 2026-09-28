program pkgtest;
{ PF7: FPC-Packages auf z/OS (fcl-json, fcl-xml, generics.collections, syncobjs,
  process, hash, base64, paszlib, sockets/ssockets). Returncode = Anzahl Fehler. }
{$mode objfpc}{$H+}
uses
  cthreads, Classes, SysUtils,
  fpjson, jsonparser,
  DOM, XMLRead, XMLWrite,
  Generics.Collections,
  SyncObjs,
  Process,
  md5, sha1, base64,
  zstream, zosebcdic,
  Sockets, ssockets;

var
  errors: longint = 0;

procedure check(const what: string; ok: boolean);
begin
  if ok then writeln('OK      ', what)
  else begin writeln('FEHLER  ', what); inc(errors); end;
end;

procedure testjson;
var
  d: TJSONData;
  o: TJSONObject;
begin
  d := GetJSON('{"name": "z/OS", "zahlen": [1, 2, 3.5], "ok": true, "leer": null}');
  try
    o := d as TJSONObject;
    check('JSON: Name', o.Strings['name'] = 'z/OS');
    check('JSON: Array', (o.Arrays['zahlen'].Count = 3) and (o.Arrays['zahlen'].Floats[2] = 3.5));
    check('JSON: Boolean/Null', o.Booleans['ok'] and o.Nulls['leer']);
    o.Add('neu', 42);
    check('JSON: erzeugt', Pos('"neu" : 42', o.AsJSON) > 0);
  finally
    d.Free;
  end;
end;

procedure testxml;
var
  doc: TXMLDocument;
  s: TStringStream;
  n: TDOMNode;
  out: TStringStream;
begin
  s := TStringStream.Create('<?xml version="1.0"?><liste><e id="1">eins</e><e id="2">zwei</e></liste>');
  try
    ReadXMLFile(doc, s);
    try
      n := doc.DocumentElement.FirstChild.NextSibling;
      check('XML: Knoten', (n.NodeName = 'e') and (TDOMElement(n).GetAttribute('id') = '2')
        and (n.TextContent = 'zwei'));
      out := TStringStream.Create('');
      try
        WriteXMLFile(doc, out);
        check('XML: geschrieben', Pos('<e id="1">eins</e>', out.DataString) > 0);
      finally
        out.Free;
      end;
    finally
      doc.Free;
    end;
  finally
    s.Free;
  end;
end;

type
  TStrIntDict = specialize TDictionary<string, integer>;
  TIntList = specialize TList<integer>;

procedure testgenerics;
var
  d: TStrIntDict;
  l: TIntList;
  i, sum: integer;
begin
  d := TStrIntDict.Create;
  l := TIntList.Create;
  try
    for i := 1 to 100 do
      d.Add('k' + IntToStr(i), i);
    check('Generics: Dictionary', (d.Count = 100) and (d['k77'] = 77));
    for i := 10 downto 1 do
      l.Add(i);
    l.Sort;
    sum := 0;
    for i in l do
      sum := sum + i;
    check('Generics: List sortiert', (l[0] = 1) and (l[9] = 10) and (sum = 55));
  finally
    l.Free;
    d.Free;
  end;
end;

type
  TZaehler = class(TThread)
  protected
    procedure Execute; override;
  end;

var
  cs: TCriticalSection;
  ev: TEvent;
  zaehler: longint = 0;

procedure TZaehler.Execute;
var
  i: integer;
begin
  for i := 1 to 10000 do
    begin
      cs.Enter;
      inc(zaehler);
      cs.Leave;
    end;
  ev.SetEvent;
end;

procedure testsync;
var
  t: array[0..3] of TZaehler;
  i: integer;
begin
  cs := TCriticalSection.Create;
  ev := TEvent.Create(nil, false, false, '');
  for i := 0 to 3 do
    t[i] := TZaehler.Create(false);
  for i := 0 to 3 do
    begin
      t[i].WaitFor;
      t[i].Free;
    end;
  check('SyncObjs: 4 Threads x 10000', zaehler = 40000);
  check('SyncObjs: TEvent gesetzt', ev.WaitFor(1000) = wrSignaled);
  ev.Free;
  cs.Free;
end;

procedure testprocess;
var
  s: ansistring;
begin
  check('Process: /bin/echo', RunCommand('/bin/echo', ['hallo', 'z/OS'], s));
  { z/OS-UNIX-Kommandos schreiben EBCDIC }
  check('Process: Ausgabe (EBCDIC)', Trim(EbcdicToAscii(s)) = 'hallo z/OS');
end;

procedure testhash;
var
  enc: string;
begin
  check('MD5', MD5Print(MD5String('abc')) = '900150983cd24fb0d6963f7d28e17f72');
  check('SHA1', SHA1Print(SHA1String('abc')) = 'a9993e364706816aba3e25717850c26c9cd0d89d');
  enc := EncodeStringBase64('z/OS Pascal');
  check('Base64', (enc = 'ei9PUyBQYXNjYWw=') and (DecodeStringBase64(enc) = 'z/OS Pascal'));
end;

procedure testzlib;
var
  src, back: string;
  ms: TMemoryStream;
  c: TCompressionStream;
  d: TDecompressionStream;
begin
  src := StringOfChar('A', 5000) + 'Ende';
  ms := TMemoryStream.Create;
  try
    c := TCompressionStream.Create(clDefault, ms);
    c.WriteBuffer(src[1], length(src));
    c.Free;
    check('zlib: komprimiert', ms.Size < 200);
    ms.Position := 0;
    d := TDecompressionStream.Create(ms);
    SetLength(back, length(src));
    d.ReadBuffer(back[1], length(back));
    d.Free;
    check('zlib: zurück', back = src);
  finally
    ms.Free;
  end;
end;

type
  TServerThread = class(TThread)
  public
    server: TInetServer;
    procedure Execute; override;
    procedure OnConnect(Sender: TObject; Data: TSocketStream);
  end;

procedure TServerThread.OnConnect(Sender: TObject; Data: TSocketStream);
var
  buf: array[0..63] of char;
  n: integer;
begin
  n := Data.Read(buf, sizeof(buf));
  if n > 0 then
    Data.Write(buf, n);    { Echo }
  Data.Free;
  server.StopAccepting;
end;

procedure TServerThread.Execute;
begin
  server.StartAccepting;
end;

procedure testsockets;
var
  st: TServerThread;
  c: TInetSocket;
  msg: string;
  buf: array[0..63] of char;
  n: integer;
begin
  st := TServerThread.Create(true);
  st.server := TInetServer.Create('127.0.0.1', 47123);
  st.server.OnConnect := @st.OnConnect;
  st.Start;
  sleep(200);
  c := TInetSocket.Create('127.0.0.1', 47123);
  try
    msg := 'Echo über loopback';
    c.Write(msg[1], length(msg));
    n := c.Read(buf, sizeof(buf));
    check('Sockets: Echo', (n = length(msg)) and (copy(buf, 1, n) = msg));
  finally
    c.Free;
  end;
  st.WaitFor;
  st.server.Free;
  st.Free;
end;

begin
  testjson;
  testxml;
  testgenerics;
  testsync;
  testprocess;
  testhash;
  testzlib;
  try
    testsockets;
  except
    on e: Exception do
      check('Sockets: ' + e.ClassName + ': ' + e.Message, false);
  end;
  writeln('Fehler: ', errors);
  halt(errors);
end.
