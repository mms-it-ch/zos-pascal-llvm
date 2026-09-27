program htrc;
{ PF3: heaptrc (Speicherleck-Verfolgung) auf z/OS }
uses heaptrc;
var
  p: pointer;
begin
  writeln('Start'); flush(output);
  getmem(p, 100);
  freemem(p);
  getmem(p, 33);  { absichtliches Leck: heaptrc muss 1 Block melden }
  writeln('ok');
end.
