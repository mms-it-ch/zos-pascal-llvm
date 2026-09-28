**Title:** Internally generated code: interface wrappers call the wrong method / emit a hint as error; call-through redirects use a hidden program name

### Summary

Three problems in code that the compiler generates from Pascal source strings (`symcreat.pas`, `ncgvmt.pas`):

1. **High-level interface wrappers (LLVM):** the wrapper for an interface method that is implemented by a method of a parent class calls the method by name. If the implementing class has a method of the same name (overload/other signature), that one is taken: `tw9306a`, `tw9306b` fail to compile ("Incompatible types: got "LongInt" expected "ShortString"/"AnsiString""). The wrappers are also not marked internal, so `tw39736` (which turns this hint into an error with `{$warn 5028 error}`) fails with "Local proc "WRPR_..." is not used" as an error. The patch calls the parent method via a typecast of `self` and marks the wrappers internal.
2. **Call-through of external redirects:** the generated call is prefixed with the program/unit name, which can be hidden by a same-named identifier (`program test; var test: integer;`, `tw11619`, `tw37322`). The redirect name is unique anyway, so the prefix is dropped. This only matters on targets that create such redirects (in our case the main program stub of a new target; also Darwin and AIX according to the code) - on x86_64-linux `tw37322` compiles without the patch.
3. The name of the redirect is made a valid identifier even if the external name is not (external name `'?Dummy'`, `uw20456`).

### Reproduction (x86_64-linux, compiler built with `LLVM=1` from main)

| test | main | with patch |
|---|---|---|
| webtbs/tw9306a | compile error (see above) | runs, exit 0 |
| webtbs/tw9306b | compile error | runs, exit 0 |
| webtbs/tw39736 | compile error (hint "not used") | runs, exit 0 |

### Patch

`0003-compiler-fixes-for-internally-generated-code-call-th.patch` (`compiler/symcreat.pas`, `compiler/ncgvmt.pas`).

---
*Drafted with the help of Claude Code (Anthropic). The results above were produced with the attached patch and the FPC testsuite.*
