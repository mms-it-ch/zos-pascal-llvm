; Legt der z/OS-Binder Datenparts eines Moduls in Eingabereihenfolge ab?
target datalayout = "E-S64-m:l-p1:32:32-i1:8:16-i8:8:16-i64:64-f128:64-v128:64-a:8:16-n32:64"
target triple = "s390x-ibm-zos"

@START = global [3 x i64] [i64 1, i64 2, i64 3], section "RESSTR", align 8
@ITEM_B = global [3 x i64] [i64 4, i64 5, i64 6], section "RESSTR", align 8
@ITEM_A = global [3 x i64] [i64 7, i64 8, i64 9], section "RESSTR", align 8
@END = global [0 x i64] zeroinitializer, section "RESSTR", align 8

@fmt = private constant [30 x i8] c"%p %p %p %p\0A\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00"

declare i32 @"@@A00118"(ptr, ...)

define i32 @main() {
  %r = call i32 (ptr, ...) @"@@A00118"(ptr @fmt, ptr @START, ptr @ITEM_B, ptr @ITEM_A, ptr @END)
  ret i32 0
}
