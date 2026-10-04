library call64lib;
{ PF8: Pascal-DLL (AMODE 64), die ein COBOL-Programm (AMODE 31) über ZP64CALL/CEL4RO64
  aufruft (pf8/zpcob2.cbl). Der Satz kommt als Zeiger auf den COBOL-Speicher (31 Bit);
  Pascal liest und ändert ihn über die erzeugten Zugriffe aus pf8/cb_kunde.pas.
  KUNDE_PRUEFEN: Saldo > Limit -> Status S (gesperrt), Ergebnis 8; sonst Status A,
  Ergebnis 0; Punkte + 1. Auf z/OS noch nicht getestet. }
{$mode objfpc}{$H+}
uses
  sysutils, zosdecimal, cb_kunde;

function KUNDE_PRUEFEN(k: PKUNDE_SATZ): longint; cdecl;
begin
  try
    Set_KUNDE_PUNKTE(k^,Get_KUNDE_PUNKTE(k^)+1);
    if Get_KUNDE_SALDO(k^)>Get_KUNDE_LIMIT(k^) then
      begin
        Set_KUNDE_STATUS(k^,'S');
        result:=8;
      end
    else
      begin
        Set_KUNDE_AKTIV(k^);
        result:=0;
      end;
  except
    { keine Ausnahme über die AMODE-Grenze: ungültige Daten (S0C7) -> 12 }
    on EDecimalDataError do result:=12;
    on Exception do result:=16;
  end;
end;

exports
  KUNDE_PRUEFEN;

end.
