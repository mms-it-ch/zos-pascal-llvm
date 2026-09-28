program webtest;
{ PF7: fcl-web auf z/OS: HTTP-Server (TFPHttpServer) in einem Thread, Client
  (TFPHTTPClient) über loopback: GET mit Text, POST mit JSON, 404.
  Returncode = Anzahl Fehler. }
{$mode objfpc}{$H+}
uses
  cthreads, Classes, SysUtils, fphttpserver, fphttpclient, httpdefs, fpjson, jsonparser;

var
  errors: longint = 0;

procedure check(const what: string; ok: boolean);
begin
  if ok then writeln('OK      ', what)
  else begin writeln('FEHLER  ', what); inc(errors); end;
end;

type
  THandler = class
    procedure Request(Sender: TObject; var ARequest: TFPHTTPConnectionRequest;
      var AResponse: TFPHTTPConnectionResponse);
  end;

  TServerThread = class(TThread)
    server: TFPHttpServer;
    procedure Execute; override;
  end;

procedure THandler.Request(Sender: TObject; var ARequest: TFPHTTPConnectionRequest;
  var AResponse: TFPHTTPConnectionResponse);
var
  j: TJSONData;
  o: TJSONObject;
begin
  if ARequest.URI = '/hallo' then
    begin
      AResponse.ContentType := 'text/plain';
      AResponse.Content := 'Hallo von z/OS';
    end
  else if ARequest.URI = '/summe' then
    begin
      j := GetJSON(ARequest.Content);
      o := TJSONObject.Create;
      try
        o.Add('summe', (j as TJSONObject).Integers['a'] + (j as TJSONObject).Integers['b']);
        AResponse.ContentType := 'application/json';
        AResponse.Content := o.AsJSON;
      finally
        o.Free;
        j.Free;
      end;
    end
  else
    begin
      AResponse.Code := 404;
      AResponse.Content := 'nicht gefunden';
    end;
end;

procedure TServerThread.Execute;
begin
  server.Active := true;
end;

var
  h: THandler;
  st: TServerThread;
  c: TFPHTTPClient;
  s: string;
  j: TJSONData;
begin
  h := THandler.Create;
  st := TServerThread.Create(true);
  st.server := TFPHttpServer.Create(nil);
  st.server.Port := 47124;
  st.server.OnRequest := @h.Request;
  st.Start;
  sleep(300);
  c := TFPHTTPClient.Create(nil);
  try
    s := c.Get('http://127.0.0.1:47124/hallo');
    { TResponse.Content hängt ein Zeilenende an (FPC, nicht z/OS-spezifisch) }
    check('GET /hallo: ' + Trim(s), (c.ResponseStatusCode = 200) and (Trim(s) = 'Hallo von z/OS'));
    c.RequestBody := TStringStream.Create('{"a": 20, "b": 22}');
    c.AddHeader('Content-Type', 'application/json');
    s := c.Post('http://127.0.0.1:47124/summe');
    c.RequestBody.Free;
    c.RequestBody := nil;
    j := GetJSON(s);
    check('POST /summe (JSON): ' + Trim(s), (j as TJSONObject).Integers['summe'] = 42);
    j.Free;
    try
      c.Get('http://127.0.0.1:47124/gibtsnicht');
    except
      on EHTTPClient do ;
    end;
    check('404', c.ResponseStatusCode = 404);
  finally
    c.Free;
  end;
  st.server.Active := false;
  { der Server wartet in accept: eine letzte Verbindung löst ihn }
  try
    TFPHTTPClient.SimpleGet('http://127.0.0.1:47124/ende');
  except
  end;
  st.WaitFor;
  writeln('Fehler: ', errors);
  halt(errors);
end.
