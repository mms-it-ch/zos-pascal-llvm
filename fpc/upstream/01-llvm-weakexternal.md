**Title:** LLVM code generator: weakexternal declarations are emitted as normal external declarations

### Summary

With the LLVM code generator, functions and variables declared `weakexternal` are written to the LLVM IR as `declare ...` / `... = external global ...` without `extern_weak`. LLVM therefore emits strong references, and a program that refers to a weak symbol that does not exist cannot be linked.

### Reproducer (x86_64-linux, LLVM code generator)

```pascal
program weakext;
{$mode objfpc}
procedure notthere; cdecl; weakexternal 'c' name 'fpc_test_symbol_that_does_not_exist';
var
  notthere_var: longint; weakexternal 'c' name 'fpc_test_var_that_does_not_exist';
begin
  if assigned(@notthere) or assigned(@notthere_var) then
    halt(1);
  writeln('ok');
end.
```

Observed (compiler built with `LLVM=1` from main):

```
weakext.ll:(.text+0xc): undefined reference to `fpc_test_symbol_that_does_not_exist'
weakext.ll:(.text+0x25): undefined reference to `fpc_test_var_that_does_not_exist'
```

Expected: the program links and prints `ok`, as with the native code generator.

### Cause

`WriteLinkageVibilityFlags` (local to `TLLVMAssember.WriteTai`) writes ` external` for every declaration (`is_definition = false`) without looking at the binding, and the `declare` of functions never writes a linkage at all. `AB_WEAK_EXTERNAL` only becomes `extern_weak` for definitions, which never happens.

### Patch

Attached: `0001-compiler-llvm-declare-weakexternal-symbols-as-extern.patch` (`compiler/llvm/agllvm.pas`): write `extern_weak` for declarations of symbols bound as `AB_WEAK_EXTERNAL`, both for variables and for `declare` of functions. With it the reproducer links and prints `ok` (x86_64-linux, LLVM code generator). Found while porting FPC to a new target (s390x/z/OS, LLVM only), where `test/tweaklib2` failed for the same reason.

Note: a function that is called before it is referenced as weak (e.g. `_test` in `tweaklib2`) still gets a normal declaration, because the call creates the asm symbol as `AB_EXTERNAL` first; this is not changed by the patch.

---
*Drafted with the help of Claude Code (Anthropic). The results above were produced with the attached reproducer and patch.*
