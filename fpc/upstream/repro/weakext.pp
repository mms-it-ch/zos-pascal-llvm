program weakext;
{ weakexternal to a symbol that does not exist: the program must link and
  the address must be nil (FPC LLVM code generator: declared "external"
  instead of "extern_weak" -> undefined reference) }
{$mode objfpc}
procedure notthere; cdecl; weakexternal 'c' name 'fpc_test_symbol_that_does_not_exist';
var
  notthere_var: longint; weakexternal 'c' name 'fpc_test_var_that_does_not_exist';
begin
  if assigned(@notthere) or assigned(@notthere_var) then
    halt(1);
  writeln('ok');
end.
