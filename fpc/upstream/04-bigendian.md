**Title:** Big endian: bitpacked int64 constants, fmtbcd Int128 conversions, SetToArray with small sets

### Summary

Three independent problems on big endian targets, found while porting FPC to s390x (z/OS). They are not specific to that target, but we could only verify them there (no other big endian system available here).

1. **Typed constants of bitpacked records (compiler, `ngtcon.pas`):** a field of `AIntBits` bits, e.g. an `int64` on a 64 bit CPU, is dropped from the constant: the condition for the big endian ("left-aligned") case is `bp.packedbitsize < AIntBits`. With `<=` the field is stored (shifting by 0 keeps the value). Test: `webtbs/tw36156`.
2. **fmtbcd: Int128ToBCD / BCDToInt128 (`packages/rtl-objpas/src/inc/fmtbcd.pp`):** the helpers `DivMod` and `MulAdd` treat `DWords[0]` of `Int128Rec` as the least significant dword ("// little endian"). On big endian targets it is the most significant one, so numbers beyond 64 bits are converted wrongly: `test/units/fmtbcd/tfmtbcd` reports "Int128<->BCD failed" for 18446744073709551615, 2^127-1 and -2^127.
3. **typinfo: SetToArray(TypeInfo, LongInt) (`rtl/objpas/typinfo.pp`):** `SetToString` adjusts packed sets that are smaller than 32 bits on big endian targets, `SetToArray(TypeInfo, LongInt)` did not, so the elements of 1 and 2 byte sets were taken from the wrong bytes of the LongInt. Test: `test/trtti24`.

### Patches

- `0004-compiler-big-endian-bitpacked-int64-constants-captur.patch`, first part (`ngtcon.pas`, one condition). The second part of this patch belongs to the LLVM capturer issue.
- `0005-fmtbcd-Int128-conversions-on-big-endian-targets.patch`
- `0006-typinfo-SetToArray-TypeInfo-LongInt-on-big-endian-ta.patch`

On s390x all three tests pass with the patches (tfmtbcd: the Int128 errors are gone; three remaining differences there come from the test's `extended` literals on a target without x87 extended). On x86_64 the changed code is either not compiled (`{$if defined(FPC_BIG_ENDIAN)}`, big endian branch) or index-mapped to the same order, so little endian targets are not affected.

---
*Drafted with the help of Claude Code (Anthropic). The results above were produced with the attached patches on s390x (z/OS).*
