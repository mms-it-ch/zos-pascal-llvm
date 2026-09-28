**Title:** LLVM code generator: anonymous functions in routines with nested routines crash (capturer in parentfpstruct)

### Summary

With the LLVM code generator (which passes the locals used by nested routines in a `parentfpstruct`), routines that create anonymous functions / function references and also contain nested routines crash. Two separate problems, both around the capturer variable:

1. **Loads type checked before the move (tanonfunc27, 56, 60, 69, tstatementexpr39):** a local variable is moved to the parentfpstruct when a nested routine accesses it; loads are redirected in `pass_typecheck`. The capturer only becomes accessed by nested routines when captured variables are converted, after the code creating the function reference was type checked. That load kept the original (never written) location while the stores went to the struct, so the function reference was loaded from an uninitialised temp.
2. **Nested routines generated after the parent (tfuncref26, tfuncref48):** the parent keeps the capturer in its own local, the nested routines access it through the parentfpstruct - their accesses are only type checked when their code is generated, after the parent. The field in the parentfpstruct is never set.

### Reproduction (x86_64-linux, compiler built with `LLVM=1` from main)

FPC testsuite, run directly (script `run-x64.sh` in the attachment):

| test | main | with patches |
|---|---|---|
| test/tanonfunc27 | exit 216 | 0 |
| test/tanonfunc56 | exit 216 | 0 |
| test/tanonfunc60 | exit 216 | 0 |
| test/tanonfunc69 | exit 216 | 0 |
| test/tfuncref26 | exit 3 | 0 |
| test/tfuncref48 | exit 3 | 0 |

(`tstatementexpr39` changes from 216 to 217 in this setup, see the note below.)

### Patches

- `0002-compiler-redirect-loads-of-variables-moved-to-the-pa.patch` (`compiler/ncgnstld.pas`): check again in `pass_1` and redirect loads of variables that were moved to the parentfpstruct after they were type checked.
- `0004-compiler-big-endian-bitpacked-int64-constants-captur.patch`, second part (`psub.pas`, `procdefutil.pas`): `tcgprocinfo.move_capturer_to_parentfpstruct` moves the capturer and its keep-alive variable to the parentfpstruct before the parent's code is generated (only for targets with a parentfpstruct: LLVM, JVM). The first part of this patch is a separate big endian fix, see the big endian issue.

### Note on the test environment

On this x86_64-linux system, ld.bfd refused to link programs of the LLVM code generator with `--eh-frame-hdr` ("overlapping FDEs"); for the runs above the option was removed from `ppas.sh`, which may also be why `tstatementexpr39` (exceptions) ends with 217. This is unrelated to the patches: the same programs were run on s390x/z/OS (LLVM only, own unwinder), where all six tests and `tstatementexpr39` pass with the patches.

---
*Drafted with the help of Claude Code (Anthropic). The results above were produced with the attached patches and the FPC testsuite.*
