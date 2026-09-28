target datalayout = "E-S64-m:l-p1:32:32-i1:8:16-i8:8:16-i64:64-f128:64-v128:64-a:8:16-n32:64"
target triple = "s390x-ibm-zos"
; Begin asmlist al_begin
; Syms - Begin Staticsymtable
; Syms - End Staticsymtable
	%"typ.System.TextRec" = type <{ i32, i32, i64, i64, i64, i64, ptr, ptr, ptr, ptr, ptr, [32 x i8], [256 x i16], [4 x i8], [256 x i8], i16, i8, i8, ptr }>
	%"typ.asmtest.TRec" = type <{ i32, i32, [8 x i8] }>
	%"typ.asmtest.$llvmstruct$d00000004i32" = type <{ ptr, i32 }>
	%"typ.asmtest.$ansistrrec13" = type <{ i16, i16, i32, i64, [14 x i8] }>
	%"typ.asmtest.$ansistrrec14" = type <{ i16, i16, i32, i64, [15 x i8] }>
	%"typ.asmtest.$ansistrrec24" = type <{ i16, i16, i32, i64, [25 x i8] }>
	%"typ.asmtest.$ansistrrec20" = type <{ i16, i16, i32, i64, [21 x i8] }>
	%"typ.asmtest.$ansistrrec12" = type <{ i16, i16, i32, i64, [13 x i8] }>
	%"typ.asmtest.$ansistrrec11" = type <{ i16, i16, i32, i64, [12 x i8] }>
	%"typ.asmtest.$ansistrrec43" = type <{ i16, i16, i32, i64, [44 x i8] }>
	%"typ.asmtest.00000015" = type <{ i64, i64, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr }>
	%"typ.asmtest.00000016" = type <{ i64, ptr }>
	%"typ.asmtest.00000017" = type <{ i64 }>
	%"typ.asmtest.00000018" = type <{ i64 }>
	%"typ.asmtest.00000019" = type <{ i64 }>
	%"typ.System.FPC_Unwind_Exception" = type <{ i64, ptr, i64, i64, i64, i64, i64, i64 }>
	%"typ.System.FPC_Unwind_Context" = type <{  }>
; End asmlist al_begin
; Begin asmlist al_pure_assembler
define hidden signext i32 @"P$ASMTEST_$$_PURE3$LONGINT$LONGINT$$LONGINT"(i32 signext %p.a, i32 signext %p.b) noinline nobuiltin null_pointer_is_valid strictfp naked !dbg !148 {
	%zdbg.r = alloca { ptr, ptr, i32, i32, [1 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [1 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.0, ptr %zdbg.fp, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r)
	call void asm sideeffect " AR 1,2\0A LGFR 3,1\0A B 2(7)","~{memory},~{fpsr},~{flags}"()
	unreachable
}
; End asmlist al_pure_assembler
; Begin asmlist al_procedures
define hidden void @"P$ASMTEST_$$_CHECK$ANSISTRING$BOOLEAN"(ptr %p.what, i8 zeroext %p.ok) nobuiltin null_pointer_is_valid strictfp !dbg !6 {
	%tmp.1 = alloca ptr, align 8, !dbg !8
	%tmp.2 = alloca i8, align 8, !dbg !8
	%tmp.3 = alloca ptr, align 8, !dbg !8
	%tmp.4 = alloca ptr, align 8, !dbg !8
	%tmp.5 = alloca i32, align 4, !dbg !8
	%reg.1_71 = bitcast ptr %tmp.5 to ptr, !dbg !8
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_71), !dbg !8
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.1, metadata !9, metadata !3), !dbg !8
	%reg.1_20 = bitcast ptr %tmp.2 to ptr, !dbg !8
	call  void (i64, ptr) @llvm.lifetime.start (i64 1, ptr %reg.1_20), !dbg !8
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.2, metadata !11, metadata !3), !dbg !8
	%zdbg.r = alloca { ptr, ptr, i32, i32, [2 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [2 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.1, ptr %zdbg.fp, align 8
	%zdbg.vp.0 = getelementptr inbounds { ptr, ptr, i32, i32, [2 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 0
	store ptr %tmp.1, ptr %zdbg.vp.0, align 8
	%zdbg.vp.1 = getelementptr inbounds { ptr, ptr, i32, i32, [2 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 1
	store ptr %tmp.2, ptr %zdbg.vp.1, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r), !dbg !8
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 22), !dbg !8
	store ptr %p.what, ptr %tmp.1, align 8, !dbg !8
	store i8 %p.ok, ptr %tmp.2, align 8, !dbg !8
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 23), !dbg !13
	%reg.1_24 = load i8, ptr %tmp.2, align 8, !dbg !13
	%reg.1_25 = trunc i64 0 to i8, !dbg !13
	%reg.1_26 = icmp ne i8 %reg.1_24, %reg.1_25, !dbg !13
	br i1 %reg.1_26, label %.Lj7, label %.Lj9, !dbg !13
.Lj9:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 23), !dbg !13
	br label %.Lj8, !dbg !13
.Lj7:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 23), !dbg !14
	%reg.1_28 = bitcast ptr %tmp.3 to ptr, !dbg !14
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_28), !dbg !14
	%reg.1_29 = call  ptr () @"fpc_get_output" (), !dbg !14
	%reg.1_30 = bitcast ptr %reg.1_29 to ptr, !dbg !14
	store ptr %reg.1_30, ptr %tmp.3, align 8, !dbg !14
	%reg.1_31 = load ptr, ptr %tmp.3, align 8, !dbg !14
	%reg.1_32 = bitcast ptr %reg.1_31 to ptr, !dbg !14
	%reg.1_33 = bitcast ptr %reg.1_32 to ptr, !dbg !14
	%reg.1_34 = bitcast ptr @".Ld1" to ptr, !dbg !15
	%reg.1_35 = bitcast ptr %reg.1_34 to ptr, !dbg !14
	call  void (i32, ptr, ptr) @"fpc_write_text_shortstr" (i32 signext 0, ptr %reg.1_33, ptr %reg.1_35), !dbg !14
	call  void () @"fpc_iocheck" (), !dbg !14
	%reg.1_37 = load ptr, ptr %tmp.3, align 8, !dbg !14
	%reg.1_38 = bitcast ptr %reg.1_37 to ptr, !dbg !14
	%reg.1_39 = bitcast ptr %reg.1_38 to ptr, !dbg !14
	%reg.1_40 = load ptr, ptr %tmp.1, align 8, !dbg !14
	call  void (i32, ptr, ptr) @"fpc_write_text_ansistr" (i32 signext 0, ptr %reg.1_39, ptr %reg.1_40), !dbg !14
	call  void () @"fpc_iocheck" (), !dbg !14
	%reg.1_42 = load ptr, ptr %tmp.3, align 8, !dbg !14
	%reg.1_43 = bitcast ptr %reg.1_42 to ptr, !dbg !14
	%reg.1_44 = bitcast ptr %reg.1_43 to ptr, !dbg !14
	call  void (ptr) @"fpc_writeln_end" (ptr %reg.1_44), !dbg !14
	call  void () @"fpc_iocheck" (), !dbg !14
	%reg.1_46 = bitcast ptr %tmp.3 to ptr, !dbg !14
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_46), !dbg !14
	br label %.Lj10, !dbg !14
	br label %.Lj8, !dbg !14
.Lj8:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 24), !dbg !16
	%reg.1_48 = bitcast ptr %tmp.4 to ptr, !dbg !16
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_48), !dbg !16
	%reg.1_49 = call  ptr () @"fpc_get_output" (), !dbg !16
	%reg.1_50 = bitcast ptr %reg.1_49 to ptr, !dbg !16
	store ptr %reg.1_50, ptr %tmp.4, align 8, !dbg !16
	%reg.1_51 = load ptr, ptr %tmp.4, align 8, !dbg !16
	%reg.1_52 = bitcast ptr %reg.1_51 to ptr, !dbg !16
	%reg.1_53 = bitcast ptr %reg.1_52 to ptr, !dbg !16
	%reg.1_54 = bitcast ptr @".Ld2" to ptr, !dbg !17
	%reg.1_55 = bitcast ptr %reg.1_54 to ptr, !dbg !16
	call  void (i32, ptr, ptr) @"fpc_write_text_shortstr" (i32 signext 0, ptr %reg.1_53, ptr %reg.1_55), !dbg !16
	call  void () @"fpc_iocheck" (), !dbg !16
	%reg.1_57 = load ptr, ptr %tmp.4, align 8, !dbg !16
	%reg.1_58 = bitcast ptr %reg.1_57 to ptr, !dbg !16
	%reg.1_59 = bitcast ptr %reg.1_58 to ptr, !dbg !16
	%reg.1_60 = load ptr, ptr %tmp.1, align 8, !dbg !16
	call  void (i32, ptr, ptr) @"fpc_write_text_ansistr" (i32 signext 0, ptr %reg.1_59, ptr %reg.1_60), !dbg !16
	call  void () @"fpc_iocheck" (), !dbg !16
	%reg.1_62 = load ptr, ptr %tmp.4, align 8, !dbg !16
	%reg.1_63 = bitcast ptr %reg.1_62 to ptr, !dbg !16
	%reg.1_64 = bitcast ptr %reg.1_63 to ptr, !dbg !16
	call  void (ptr) @"fpc_writeln_end" (ptr %reg.1_64), !dbg !16
	call  void () @"fpc_iocheck" (), !dbg !16
	%reg.1_66 = bitcast ptr %tmp.4 to ptr, !dbg !16
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_66), !dbg !16
	%reg.1_72 = load i32, ptr @"TC_$P$ASMTEST_$$_ERRORS", align 4, !dbg !18
	store i32 %reg.1_72, ptr %tmp.5, align 4, !dbg !18
	%reg.1_73 = load i32, ptr %tmp.5, align 4, !dbg !18
	%reg.1_74 = add i32 %reg.1_73, 1, !dbg !18
	store i32 %reg.1_74, ptr %tmp.5, align 4, !dbg !18
	%reg.1_75 = load i32, ptr %tmp.5, align 4, !dbg !18
	store i32 %reg.1_75, ptr @"TC_$P$ASMTEST_$$_ERRORS", align 4, !dbg !18
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 23), !dbg !14
	br label %.Lj10, !dbg !14
.Lj10:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 25), !dbg !19
	br label %.Lj5, !dbg !19
.Lj5:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 25), !dbg !19
	%reg.1_69 = bitcast ptr %tmp.2 to ptr, !dbg !19
	call  void (i64, ptr) @llvm.lifetime.end (i64 1, ptr %reg.1_69), !dbg !19
	%reg.1_77 = bitcast ptr %tmp.5 to ptr, !dbg !19
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_77), !dbg !19
	ret void, !dbg !19
}
define hidden signext i32 @"P$ASMTEST_$$_ADD1$LONGINT$$LONGINT"(i32 signext %p.x) nobuiltin null_pointer_is_valid strictfp !dbg !20 {
	%tmp.1 = alloca i32, align 8, !dbg !21
	%tmp.2 = alloca i32, align 4, !dbg !21
	%reg.1_17 = bitcast ptr %tmp.1 to ptr, !dbg !21
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_17), !dbg !21
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.1, metadata !22, metadata !3), !dbg !21
	%reg.1_22 = bitcast ptr %tmp.2 to ptr, !dbg !21
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_22), !dbg !21
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.2, metadata !24, metadata !3), !dbg !21
	%zdbg.r = alloca { ptr, ptr, i32, i32, [2 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [2 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.2, ptr %zdbg.fp, align 8
	%zdbg.vp.0 = getelementptr inbounds { ptr, ptr, i32, i32, [2 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 0
	store ptr %tmp.1, ptr %zdbg.vp.0, align 8
	%zdbg.vp.1 = getelementptr inbounds { ptr, ptr, i32, i32, [2 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 1
	store ptr %tmp.2, ptr %zdbg.vp.1, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r), !dbg !21
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 28), !dbg !21
	store i32 %p.x, ptr %tmp.1, align 8, !dbg !21
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 29), !dbg !25
	call void asm sideeffect " L 1,0($0)\0A AHI 1,1\0A ST 1,0($1)","a,a,~{memory},~{fpsr},~{flags},~{r1}"(ptr %tmp.1, ptr %tmp.2), !dbg !25
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 34), !dbg !26
	br label %.Lj11, !dbg !26
.Lj11:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 34), !dbg !26
	%reg.1_27 = bitcast ptr %tmp.1 to ptr, !dbg !26
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_27), !dbg !26
	%reg.1_3 = load i32, ptr %tmp.2, align 4, !dbg !26
	%reg.1_29 = bitcast ptr %tmp.2 to ptr, !dbg !26
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_29), !dbg !26
	ret i32 %reg.1_3, !dbg !26
}
define hidden signext i32 @"P$ASMTEST_$$_SUMTO$LONGINT$$LONGINT"(i32 signext %p.n) nobuiltin null_pointer_is_valid strictfp !dbg !27 {
	%tmp.1 = alloca i32, align 8, !dbg !28
	%tmp.2 = alloca i32, align 4, !dbg !28
	%tmp.3 = alloca i32, align 4, !dbg !28
	%reg.1_17 = bitcast ptr %tmp.1 to ptr, !dbg !28
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_17), !dbg !28
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.1, metadata !29, metadata !3), !dbg !28
	%reg.1_22 = bitcast ptr %tmp.2 to ptr, !dbg !28
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_22), !dbg !28
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.2, metadata !30, metadata !3), !dbg !28
	%reg.1_27 = bitcast ptr %tmp.3 to ptr, !dbg !28
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_27), !dbg !28
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.3, metadata !31, metadata !3), !dbg !28
	%zdbg.r = alloca { ptr, ptr, i32, i32, [3 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [3 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.3, ptr %zdbg.fp, align 8
	%zdbg.vp.0 = getelementptr inbounds { ptr, ptr, i32, i32, [3 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 0
	store ptr %tmp.1, ptr %zdbg.vp.0, align 8
	%zdbg.vp.1 = getelementptr inbounds { ptr, ptr, i32, i32, [3 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 1
	store ptr %tmp.2, ptr %zdbg.vp.1, align 8
	%zdbg.vp.2 = getelementptr inbounds { ptr, ptr, i32, i32, [3 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 2
	store ptr %tmp.3, ptr %zdbg.vp.2, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r), !dbg !28
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 39), !dbg !28
	store i32 %p.n, ptr %tmp.1, align 8, !dbg !28
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 40), !dbg !32
	store i32 0, ptr %tmp.3, align 4, !dbg !32
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 41), !dbg !33
	call void asm sideeffect " L 1,0($0)\0A SR 2,2\0ALOOP${:uid} AR 2,1\0A BRCT 1,LOOP${:uid}\0A ST 2,0($1)","a,a,~{memory},~{fpsr},~{flags},~{r2},~{r1}"(ptr %tmp.1, ptr %tmp.3), !dbg !33
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 49), !dbg !34
	%reg.1_31 = load i32, ptr %tmp.3, align 4, !dbg !34
	store i32 %reg.1_31, ptr %tmp.2, align 4, !dbg !34
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 50), !dbg !35
	br label %.Lj13, !dbg !35
.Lj13:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 50), !dbg !35
	%reg.1_33 = bitcast ptr %tmp.3 to ptr, !dbg !35
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_33), !dbg !35
	%reg.1_35 = bitcast ptr %tmp.1 to ptr, !dbg !35
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_35), !dbg !35
	%reg.1_3 = load i32, ptr %tmp.2, align 4, !dbg !35
	%reg.1_37 = bitcast ptr %tmp.2 to ptr, !dbg !35
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_37), !dbg !35
	ret i32 %reg.1_3, !dbg !35
}
define hidden void @"P$ASMTEST_$$_INCGLOBAL"() nobuiltin null_pointer_is_valid strictfp !dbg !36 {
	%zdbg.r = alloca { ptr, ptr, i32, i32, [1 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [1 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.4, ptr %zdbg.fp, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r), !dbg !37
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 54), !dbg !37
	call void asm sideeffect " L 1,0($0)\0A AHI 1,5\0A ST 1,0($1)","a,a,~{memory},~{fpsr},~{flags},~{r1}"(ptr @"TC_$P$ASMTEST_$$_G", ptr @"TC_$P$ASMTEST_$$_G"), !dbg !37
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 59), !dbg !38
	br label %.Lj15, !dbg !38
.Lj15:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 59), !dbg !38
	ret void, !dbg !38
}
define hidden void @"P$ASMTEST_$$_SETB$TREC"(ptr nocapture dereferenceable_or_null(16) %p.r) nobuiltin null_pointer_is_valid strictfp !dbg !39 {
	%tmp.1 = alloca ptr, align 8, !dbg !40
	%reg.1_17 = bitcast ptr %tmp.1 to ptr, !dbg !40
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_17), !dbg !40
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.1, metadata !41, metadata !4), !dbg !40
	%zdbg.r = alloca { ptr, ptr, i32, i32, [1 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [1 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.5, ptr %zdbg.fp, align 8
	%zdbg.vp.0 = getelementptr inbounds { ptr, ptr, i32, i32, [1 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 0
	store ptr %tmp.1, ptr %zdbg.vp.0, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r), !dbg !40
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 62), !dbg !40
	store ptr %p.r, ptr %tmp.1, align 8, !dbg !40
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 63), !dbg !43
	call void asm sideeffect " LG 1,0($0)\0A L 2,4(1)\0A AHI 2,5\0A ST 2,4(1)","a,~{memory},~{fpsr},~{flags},~{r2},~{r1}"(ptr %tmp.1), !dbg !43
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 69), !dbg !44
	br label %.Lj17, !dbg !44
.Lj17:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 69), !dbg !44
	%reg.1_22 = bitcast ptr %tmp.1 to ptr, !dbg !44
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_22), !dbg !44
	ret void, !dbg !44
}
define hidden void @"P$ASMTEST_$$_FIELDS$ANSISTRING"(ptr nocapture dereferenceable_or_null(8) %p.res) nobuiltin null_pointer_is_valid strictfp personality ptr @"SYSTEM_$$__FPC_PSABIEH_PERSONALITY_V0$hhyOiwn8_zDM" !dbg !45 {
	%tmp.1 = alloca ptr, align 8, !dbg !46
	%tmp.2 = alloca %"typ.asmtest.TRec", align 4, !dbg !46
	%tmp.3 = alloca [8 x i8], align 4, !dbg !46
	%tmp.4 = alloca ptr, align 8, !dbg !46
	%tmp.5 = alloca i64, align 8, !dbg !46
	%tmp.6 = alloca ptr, align 8, !dbg !46
	%tmp.7 = alloca i64, align 8, !dbg !46
	%tmp.8 = alloca [256 x i8], align 1, !dbg !46
	%tmp.9 = alloca ptr, align 8, !dbg !46
	%tmp.10 = alloca ptr, align 8, !dbg !46
	%tmp.11 = alloca [256 x i8], align 1, !dbg !46
	%tmp.12 = alloca [256 x i8], align 1, !dbg !46
	%reg.1_17 = bitcast ptr %tmp.1 to ptr, !dbg !46
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_17), !dbg !46
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.1, metadata !47, metadata !4), !dbg !46
	%reg.1_22 = bitcast ptr %tmp.2 to ptr, !dbg !46
	call  void (i64, ptr) @llvm.lifetime.start (i64 16, ptr %reg.1_22), !dbg !46
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.2, metadata !48, metadata !3), !dbg !46
	%reg.1_27 = bitcast ptr %tmp.3 to ptr, !dbg !46
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_27), !dbg !46
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.3, metadata !49, metadata !3), !dbg !46
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.4, metadata !51, metadata !3), !dbg !46
	store ptr %p.res, ptr %tmp.1, align 8, !dbg !46
	%reg.1_34 = load ptr, ptr %tmp.1, align 8, !dbg !46
	%reg.1_35 = inttoptr i64 0 to ptr, !dbg !46
	store ptr %reg.1_35, ptr %reg.1_34, align 1, !dbg !46
	%reg.1_36 = inttoptr i64 0 to ptr, !dbg !46
	store ptr %reg.1_36, ptr %tmp.4, align 8, !dbg !46
	%reg.1_118 = inttoptr i64 0 to ptr, !dbg !46
	store ptr %reg.1_118, ptr %tmp.10, align 8, !dbg !46
	%reg.1_119 = inttoptr i64 0 to ptr, !dbg !46
	store ptr %reg.1_119, ptr %tmp.9, align 8, !dbg !46
	%reg.1_38 = bitcast ptr %tmp.5 to ptr, !dbg !46
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_38), !dbg !46
	%reg.1_39 = bitcast i64 1 to i64, !dbg !46
	%zdbg.r = alloca { ptr, ptr, i32, i32, [4 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [4 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.6, ptr %zdbg.fp, align 8
	%zdbg.vp.0 = getelementptr inbounds { ptr, ptr, i32, i32, [4 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 0
	store ptr %tmp.1, ptr %zdbg.vp.0, align 8
	%zdbg.vp.1 = getelementptr inbounds { ptr, ptr, i32, i32, [4 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 1
	store ptr %tmp.2, ptr %zdbg.vp.1, align 8
	%zdbg.vp.2 = getelementptr inbounds { ptr, ptr, i32, i32, [4 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 2
	store ptr %tmp.3, ptr %zdbg.vp.2, align 8
	%zdbg.vp.3 = getelementptr inbounds { ptr, ptr, i32, i32, [4 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 3
	store ptr %tmp.4, ptr %zdbg.vp.3, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r), !dbg !46
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 76), !dbg !46
	store i64 %reg.1_39, ptr %tmp.5, align 8, !dbg !46
	invoke  void () @"SYSTEM_$$_FPC_DUMMYPOTENTIALRAISE" () to label %.Lj24 unwind label %.Lj23, !dbg !46
.Lj24:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 77), !dbg !52
	%reg.1_40 = bitcast ptr @".Ld3" to ptr, !dbg !52
	%reg.1_41 = load [8 x i8], ptr %reg.1_40, align 8, !dbg !53
	store [8 x i8] %reg.1_41, ptr %tmp.3, align 4, !dbg !53
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 78), !dbg !54
	%reg.1_42 = bitcast ptr %tmp.2 to ptr, !dbg !54
	%reg.1_43 = getelementptr %"typ.asmtest.TRec", ptr %reg.1_42, i32 0, i32 0, !dbg !54
	store i32 0, ptr %reg.1_43, align 4, !dbg !55
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 79), !dbg !56
	call void asm sideeffect " MVC 8(8,$0),0($1)\0A MVI 15($2),90\0A LA 1,0($2)\0A MVHI 0(1),42","a,a,a,~{memory},~{fpsr},~{flags},~{r1}"(ptr %tmp.2, ptr %tmp.3, ptr %tmp.2), !dbg !56
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 85), !dbg !57
	%reg.1_45 = bitcast ptr %tmp.6 to ptr, !dbg !57
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_45), !dbg !57
	%reg.1_46 = bitcast ptr %tmp.4 to ptr, !dbg !57
	store ptr %reg.1_46, ptr %tmp.6, align 8, !dbg !57
	%reg.1_47 = load ptr, ptr %tmp.6, align 8, !dbg !57
	%reg.1_48 = bitcast ptr %reg.1_47 to ptr, !dbg !57
	invoke  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_48) to label %.Lj26 unwind label %.Lj23, !dbg !57
.Lj26:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 76), !dbg !46
	%reg.1_50 = bitcast ptr %tmp.7 to ptr, !dbg !46
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_50), !dbg !46
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 85), !dbg !58
	%reg.1_51 = bitcast ptr %tmp.2 to ptr, !dbg !58
	%reg.1_52 = getelementptr %"typ.asmtest.TRec", ptr %reg.1_51, i32 0, i32 0, !dbg !58
	%reg.1_54 = load i32, ptr %reg.1_52, align 4, !dbg !58
	%reg.1_53 = sext i32 %reg.1_54 to i64, !dbg !58
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 76), !dbg !46
	store i64 %reg.1_53, ptr %tmp.7, align 8, !dbg !46
	%reg.1_56 = bitcast ptr %tmp.8 to ptr, !dbg !46
	call  void (i64, ptr) @llvm.lifetime.start (i64 256, ptr %reg.1_56), !dbg !46
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 85), !dbg !57
	%reg.1_58 = bitcast ptr %tmp.8 to ptr, !dbg !57
	%reg.1_59 = load i64, ptr %tmp.7, align 8, !dbg !57
	invoke  void (i64, i64, ptr, i64) @"fpc_shortstr_sint" (i64 %reg.1_59, i64 -1, ptr %reg.1_58, i64 255) to label %.Lj28 unwind label %.Lj23, !dbg !57
.Lj28:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 85), !dbg !57
	%reg.1_61 = bitcast ptr %tmp.8 to ptr, !dbg !57
	%reg.1_62 = bitcast ptr %tmp.9 to ptr, !dbg !57
	invoke  void (ptr, ptr, i16) @"fpc_shortstr_to_ansistr" (ptr sret(ptr) %reg.1_62, ptr %reg.1_61, i16 zeroext 0) to label %.Lj29 unwind label %.Lj23, !dbg !57
.Lj29:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 85), !dbg !57
	%reg.1_64 = load ptr, ptr %tmp.9, align 8, !dbg !57
	%reg.1_65 = load ptr, ptr %tmp.6, align 8, !dbg !57
	%reg.1_66 = bitcast ptr %reg.1_65 to ptr, !dbg !57
	invoke  void (ptr, ptr) @"fpc_ansistr_assign" (ptr %reg.1_66, ptr %reg.1_64) to label %.Lj30 unwind label %.Lj23, !dbg !57
.Lj30:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 85), !dbg !57
	%reg.1_67 = load ptr, ptr %tmp.6, align 8, !dbg !57
	%reg.1_68 = bitcast ptr %reg.1_67 to ptr, !dbg !57
	invoke  void (ptr, i16, i8) @"SYSTEM_$$_SETCODEPAGE$RAWBYTESTRING$WORD$BOOLEAN" (ptr %reg.1_68, i16 zeroext 0, i8 zeroext 0) to label %.Lj31 unwind label %.Lj23, !dbg !57
.Lj31:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 85), !dbg !57
	br label %.Lj27, !dbg !57
.Lj27:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 76), !dbg !46
	%reg.1_72 = bitcast ptr %tmp.7 to ptr, !dbg !46
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_72), !dbg !46
	%reg.1_74 = bitcast ptr %tmp.8 to ptr, !dbg !46
	call  void (i64, ptr) @llvm.lifetime.end (i64 256, ptr %reg.1_74), !dbg !46
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 85), !dbg !57
	%reg.1_76 = bitcast ptr %tmp.6 to ptr, !dbg !57
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_76), !dbg !57
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 86), !dbg !59
	%reg.1_79 = bitcast ptr %tmp.11 to ptr, !dbg !59
	call  void (i64, ptr) @llvm.lifetime.start (i64 256, ptr %reg.1_79), !dbg !59
	%reg.1_80 = bitcast ptr @".Ld4" to ptr, !dbg !59
	%reg.1_81 = bitcast ptr %reg.1_80 to ptr, !dbg !59
	%reg.1_83 = bitcast ptr %tmp.12 to ptr, !dbg !60
	call  void (i64, ptr) @llvm.lifetime.start (i64 256, ptr %reg.1_83), !dbg !60
	%reg.1_86 = bitcast ptr %tmp.2 to ptr, !dbg !60
	%reg.1_87 = getelementptr %"typ.asmtest.TRec", ptr %reg.1_86, i32 0, i32 2, !dbg !60
	%reg.1_88 = bitcast ptr %reg.1_87 to ptr, !dbg !60
	%reg.1_89 = bitcast ptr %tmp.12 to ptr, !dbg !60
	invoke  void (ptr, i64, ptr, i64, i8) @"fpc_chararray_to_shortstr" (ptr %reg.1_89, i64 255, ptr %reg.1_88, i64 7, i8 zeroext 1) to label %.Lj32 unwind label %.Lj23, !dbg !60
.Lj32:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 86), !dbg !59
	%reg.1_91 = bitcast ptr %tmp.12 to ptr, !dbg !59
	%reg.1_92 = bitcast ptr %tmp.11 to ptr, !dbg !59
	invoke  void (ptr, i64, ptr, ptr) @"fpc_shortstr_concat" (ptr %reg.1_92, i64 255, ptr %reg.1_91, ptr %reg.1_81) to label %.Lj33 unwind label %.Lj23, !dbg !59
.Lj33:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 86), !dbg !59
	%reg.1_95 = bitcast ptr %tmp.12 to ptr, !dbg !59
	call  void (i64, ptr) @llvm.lifetime.end (i64 256, ptr %reg.1_95), !dbg !59
	%reg.1_96 = bitcast ptr %tmp.11 to ptr, !dbg !61
	%reg.1_97 = bitcast ptr %tmp.10 to ptr, !dbg !61
	invoke  void (ptr, ptr, i16) @"fpc_shortstr_to_ansistr" (ptr sret(ptr) %reg.1_97, ptr %reg.1_96, i16 zeroext 0) to label %.Lj34 unwind label %.Lj23, !dbg !61
.Lj34:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 86), !dbg !61
	%reg.1_100 = bitcast ptr %tmp.11 to ptr, !dbg !61
	call  void (i64, ptr) @llvm.lifetime.end (i64 256, ptr %reg.1_100), !dbg !61
	%reg.1_101 = load ptr, ptr %tmp.10, align 8, !dbg !61
	%reg.1_102 = load ptr, ptr %tmp.4, align 8, !dbg !61
	%reg.1_103 = load ptr, ptr %tmp.1, align 8, !dbg !61
	%reg.1_104 = bitcast ptr %reg.1_103 to ptr, !dbg !61
	invoke  void (ptr, ptr, ptr, i16) @"fpc_ansistr_concat" (ptr %reg.1_104, ptr %reg.1_101, ptr %reg.1_102, i16 zeroext 0) to label %.Lj35 unwind label %.Lj23, !dbg !61
.Lj35:
	invoke  void () @"SYSTEM_$$_FPC_DUMMYPOTENTIALRAISE" () to label %.Lj36 unwind label %.Lj23, !dbg !62
.Lj36:
	%reg.1_105 = bitcast i64 0 to i64
	store i64 %reg.1_105, ptr %tmp.5, align 8
	br label %.Lj37
.Lj37:
	%reg.1_107 = bitcast ptr %tmp.10 to ptr
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_107), !dbg !62
	%reg.1_108 = bitcast ptr %tmp.9 to ptr
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_108), !dbg !62
	%reg.1_109 = bitcast ptr %tmp.4 to ptr
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_109), !dbg !62
	%reg.1_110 = load i64, ptr %tmp.5, align 8
	%reg.1_111 = bitcast i64 0 to i64
	%reg.1_112 = icmp eq i64 %reg.1_110, %reg.1_111
	br i1 %reg.1_112, label %.Lj21, label %.Lj38
.Lj38:
	unreachable
	unreachable
.Lj23:
	%reg.1_106 = landingpad %"typ.asmtest.$llvmstruct$d00000004i32" 	cleanup

	br label %.Lj22
.Lj22:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 87), !dbg !63
	%reg.1_113 = bitcast ptr %tmp.10 to ptr, !dbg !63
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_113), !dbg !63
	%reg.1_114 = bitcast ptr %tmp.9 to ptr, !dbg !63
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_114), !dbg !63
	%reg.1_115 = bitcast ptr %tmp.4 to ptr, !dbg !63
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_115), !dbg !63
	resume %"typ.asmtest.$llvmstruct$d00000004i32" %reg.1_106
	%reg.1_117 = bitcast ptr %tmp.5 to ptr
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_117), !dbg !62
	br label %.Lj21
.Lj21:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 87), !dbg !63
	br label %.Lj19, !dbg !63
.Lj19:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 87), !dbg !63
	%reg.1_121 = bitcast ptr %tmp.2 to ptr, !dbg !63
	call  void (i64, ptr) @llvm.lifetime.end (i64 16, ptr %reg.1_121), !dbg !63
	%reg.1_123 = bitcast ptr %tmp.3 to ptr, !dbg !63
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_123), !dbg !63
	%reg.1_125 = bitcast ptr %tmp.1 to ptr, !dbg !63
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_125), !dbg !63
	ret void, !dbg !63
}
define hidden void @"P$ASMTEST_$$_EMPTY"() nobuiltin null_pointer_is_valid strictfp !dbg !64 {
	%zdbg.r = alloca { ptr, ptr, i32, i32, [1 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [1 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.7, ptr %zdbg.fp, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r), !dbg !65
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 99), !dbg !65
	call void asm sideeffect "","~{memory},~{fpsr},~{flags},~{r0},~{r1},~{r2},~{r3},~{r4},~{r5},~{r6},~{r7}"(), !dbg !65
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 101), !dbg !66
	br label %.Lj41, !dbg !66
.Lj41:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 101), !dbg !66
	ret void, !dbg !66
}
define hidden void @"main"(i32 signext %p.ARGC, ptr %p.ARGV, ptr %p.ARGP) nobuiltin null_pointer_is_valid strictfp !dbg !67 {
	%tmp.1 = alloca i32, align 8
	%tmp.2 = alloca ptr, align 8
	%tmp.3 = alloca ptr, align 8
	%reg.1_17 = bitcast ptr %tmp.1 to ptr
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_17), !dbg !68
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.1, metadata !69, metadata !3), !dbg !68
	%reg.1_22 = bitcast ptr %tmp.2 to ptr
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_22), !dbg !68
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.2, metadata !70, metadata !3), !dbg !68
	%reg.1_27 = bitcast ptr %tmp.3 to ptr
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_27), !dbg !68
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.3, metadata !72, metadata !3), !dbg !68
	%zdbg.r = alloca { ptr, ptr, i32, i32, [3 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [3 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.8, ptr %zdbg.fp, align 8
	%zdbg.vp.0 = getelementptr inbounds { ptr, ptr, i32, i32, [3 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 0
	store ptr %tmp.1, ptr %zdbg.vp.0, align 8
	%zdbg.vp.1 = getelementptr inbounds { ptr, ptr, i32, i32, [3 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 1
	store ptr %tmp.2, ptr %zdbg.vp.1, align 8
	%zdbg.vp.2 = getelementptr inbounds { ptr, ptr, i32, i32, [3 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 2
	store ptr %tmp.3, ptr %zdbg.vp.2, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r)
	store i32 %p.ARGC, ptr %tmp.1, align 8
	store ptr %p.ARGV, ptr %tmp.2, align 8
	store ptr %p.ARGP, ptr %tmp.3, align 8
	%reg.1_31 = load ptr, ptr %tmp.3, align 8
	%reg.1_32 = load ptr, ptr %tmp.2, align 8
	%reg.1_34 = load i32, ptr %tmp.1, align 8
	%reg.1_33 = sext i32 %reg.1_34 to i64
	%reg.1_35 = trunc i64 %reg.1_33 to i32
	call  void (i32, ptr, ptr) @"FPC_SYSTEMMAIN" (i32 signext %reg.1_35, ptr %reg.1_32, ptr %reg.1_31), !dbg !68
	br label %.Lj43
.Lj43:
	%reg.1_37 = bitcast ptr %tmp.1 to ptr
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_37), !dbg !68
	%reg.1_39 = bitcast ptr %tmp.2 to ptr
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_39), !dbg !68
	%reg.1_41 = bitcast ptr %tmp.3 to ptr
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_41), !dbg !68
	ret void
}
define hidden void @"PASCALMAIN"() nobuiltin noreturn null_pointer_is_valid strictfp personality ptr @"SYSTEM_$$__FPC_PSABIEH_PERSONALITY_V0$hhyOiwn8_zDM" !dbg !73 {
	%tmp.1 = alloca i64, align 8, !dbg !74
	%tmp.2 = alloca ptr, align 8, !dbg !74
	%tmp.3 = alloca ptr, align 8, !dbg !74
	%tmp.4 = alloca ptr, align 8, !dbg !74
	%tmp.5 = alloca i8, align 1, !dbg !74
	%reg.1_146 = bitcast ptr %tmp.5 to ptr, !dbg !74
	call  void (i64, ptr) @llvm.lifetime.start (i64 1, ptr %reg.1_146), !dbg !74
	call  void () @"fpc_initializeunits" (), !dbg !74
	%reg.1_144 = inttoptr i64 0 to ptr, !dbg !74
	store ptr %reg.1_144, ptr %tmp.3, align 8, !dbg !74
	%reg.1_17 = bitcast ptr %tmp.1 to ptr, !dbg !74
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_17), !dbg !74
	%reg.1_18 = bitcast i64 1 to i64, !dbg !74
	%zdbg.r = alloca { ptr, ptr, i32, i32, [1 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [1 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.9, ptr %zdbg.fp, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r), !dbg !74
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 106), !dbg !74
	store i64 %reg.1_18, ptr %tmp.1, align 8, !dbg !74
	invoke  void () @"SYSTEM_$$_FPC_DUMMYPOTENTIALRAISE" () to label %.Lj52 unwind label %.Lj51, !dbg !74
.Lj52:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 107), !dbg !75
	%reg.1_20 = invoke  i32 (i32) @"P$ASMTEST_$$_ADD1$LONGINT$$LONGINT" (i32 signext 41) to label %.Lj54 unwind label %.Lj51, !dbg !75
.Lj54:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 107), !dbg !75
	%reg.1_21 = bitcast i32 %reg.1_20 to i32, !dbg !75
	%reg.1_22 = icmp eq i32 %reg.1_21, 42, !dbg !76
	%reg.1_23 = zext i1 %reg.1_22 to i8, !dbg !76
	%reg.1_24 = zext i8 %reg.1_23 to i64, !dbg !77
	%reg.1_26 = getelementptr %"typ.asmtest.$ansistrrec13", ptr @".Ld5", i32 0, i32 4, !dbg !78
	%reg.1_25 = bitcast ptr %reg.1_26 to ptr, !dbg !78
	%reg.1_27 = bitcast ptr %reg.1_25 to ptr, !dbg !77
	%reg.1_28 = trunc i64 %reg.1_24 to i8, !dbg !77
	invoke  void (ptr, i8) @"P$ASMTEST_$$_CHECK$ANSISTRING$BOOLEAN" (ptr %reg.1_27, i8 zeroext %reg.1_28) to label %.Lj55 unwind label %.Lj51, !dbg !77
.Lj55:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 108), !dbg !79
	%reg.1_30 = invoke  i32 (i32) @"P$ASMTEST_$$_SUMTO$LONGINT$$LONGINT" (i32 signext 10) to label %.Lj56 unwind label %.Lj51, !dbg !79
.Lj56:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 108), !dbg !79
	%reg.1_31 = bitcast i32 %reg.1_30 to i32, !dbg !79
	%reg.1_32 = icmp eq i32 %reg.1_31, 55, !dbg !80
	%reg.1_33 = zext i1 %reg.1_32 to i8, !dbg !80
	%reg.1_34 = zext i8 %reg.1_33 to i64, !dbg !81
	%reg.1_36 = getelementptr %"typ.asmtest.$ansistrrec14", ptr @".Ld6", i32 0, i32 4, !dbg !82
	%reg.1_35 = bitcast ptr %reg.1_36 to ptr, !dbg !82
	%reg.1_37 = bitcast ptr %reg.1_35 to ptr, !dbg !81
	%reg.1_38 = trunc i64 %reg.1_34 to i8, !dbg !81
	invoke  void (ptr, i8) @"P$ASMTEST_$$_CHECK$ANSISTRING$BOOLEAN" (ptr %reg.1_37, i8 zeroext %reg.1_38) to label %.Lj57 unwind label %.Lj51, !dbg !81
.Lj57:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 109), !dbg !83
	invoke  void () @"P$ASMTEST_$$_INCGLOBAL" () to label %.Lj58 unwind label %.Lj51, !dbg !83
.Lj58:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 110), !dbg !84
	%reg.1_39 = load i32, ptr @"TC_$P$ASMTEST_$$_G", align 4, !dbg !84
	%reg.1_40 = icmp eq i32 %reg.1_39, 12, !dbg !84
	%reg.1_41 = zext i1 %reg.1_40 to i8, !dbg !84
	%reg.1_42 = zext i8 %reg.1_41 to i64, !dbg !85
	%reg.1_44 = getelementptr %"typ.asmtest.$ansistrrec24", ptr @".Ld7", i32 0, i32 4, !dbg !86
	%reg.1_43 = bitcast ptr %reg.1_44 to ptr, !dbg !86
	%reg.1_45 = bitcast ptr %reg.1_43 to ptr, !dbg !85
	%reg.1_46 = trunc i64 %reg.1_42 to i8, !dbg !85
	invoke  void (ptr, i8) @"P$ASMTEST_$$_CHECK$ANSISTRING$BOOLEAN" (ptr %reg.1_45, i8 zeroext %reg.1_46) to label %.Lj59 unwind label %.Lj51, !dbg !85
.Lj59:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 111), !dbg !87
	%reg.1_47 = bitcast ptr @"U_$P$ASMTEST_$$_R" to ptr, !dbg !87
	%reg.1_48 = getelementptr %"typ.asmtest.TRec", ptr %reg.1_47, i32 0, i32 0, !dbg !87
	store i32 1, ptr %reg.1_48, align 4, !dbg !88
	%reg.1_49 = bitcast ptr @"U_$P$ASMTEST_$$_R" to ptr, !dbg !89
	%reg.1_50 = getelementptr %"typ.asmtest.TRec", ptr %reg.1_49, i32 0, i32 1, !dbg !89
	store i32 37, ptr %reg.1_50, align 4, !dbg !90
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 112), !dbg !91
	%reg.1_51 = bitcast ptr @"U_$P$ASMTEST_$$_R" to ptr, !dbg !91
	invoke  void (ptr) @"P$ASMTEST_$$_SETB$TREC" (ptr %reg.1_51) to label %.Lj60 unwind label %.Lj51, !dbg !91
.Lj60:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 113), !dbg !92
	%reg.1_52 = bitcast ptr @"U_$P$ASMTEST_$$_R" to ptr, !dbg !92
	%reg.1_53 = getelementptr %"typ.asmtest.TRec", ptr %reg.1_52, i32 0, i32 1, !dbg !92
	%reg.1_54 = load i32, ptr %reg.1_53, align 4, !dbg !93
	%reg.1_55 = icmp eq i32 %reg.1_54, 42, !dbg !93
	%reg.1_56 = zext i1 %reg.1_55 to i8, !dbg !93
	%reg.1_57 = trunc i64 0 to i8, !dbg !93
	%reg.1_58 = icmp ne i8 %reg.1_56, %reg.1_57, !dbg !93
	br i1 %reg.1_58, label %.Lj61, label %.Lj63, !dbg !93
.Lj63:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 113), !dbg !93
	br label %.Lj62, !dbg !93
.Lj61:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 113), !dbg !94
	%reg.1_59 = bitcast ptr @"U_$P$ASMTEST_$$_R" to ptr, !dbg !94
	%reg.1_60 = getelementptr %"typ.asmtest.TRec", ptr %reg.1_59, i32 0, i32 0, !dbg !94
	%reg.1_61 = load i32, ptr %reg.1_60, align 4, !dbg !95
	%reg.1_62 = icmp eq i32 %reg.1_61, 1, !dbg !95
	%reg.1_63 = zext i1 %reg.1_62 to i8, !dbg !95
	%reg.1_64 = trunc i64 0 to i8, !dbg !95
	%reg.1_65 = icmp ne i8 %reg.1_63, %reg.1_64, !dbg !95
	br i1 %reg.1_65, label %.Lj64, label %.Lj65, !dbg !95
.Lj65:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 113), !dbg !95
	br label %.Lj62, !dbg !95
.Lj64:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 113), !dbg !96
	%reg.1_147 = trunc i64 1 to i8, !dbg !96
	store i8 %reg.1_147, ptr %tmp.5, align 1, !dbg !96
	br label %.Lj66, !dbg !96
.Lj62:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 113), !dbg !96
	%reg.1_148 = trunc i64 0 to i8, !dbg !96
	store i8 %reg.1_148, ptr %tmp.5, align 1, !dbg !96
	br label %.Lj66, !dbg !96
.Lj66:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 113), !dbg !96
	%reg.1_149 = load i8, ptr %tmp.5, align 1, !dbg !96
	%reg.1_66 = zext i8 %reg.1_149 to i64, !dbg !96
	%reg.1_69 = getelementptr %"typ.asmtest.$ansistrrec20", ptr @".Ld8", i32 0, i32 4, !dbg !97
	%reg.1_68 = bitcast ptr %reg.1_69 to ptr, !dbg !97
	%reg.1_70 = bitcast ptr %reg.1_68 to ptr, !dbg !96
	%reg.1_71 = trunc i64 %reg.1_66 to i8, !dbg !96
	invoke  void (ptr, i8) @"P$ASMTEST_$$_CHECK$ANSISTRING$BOOLEAN" (ptr %reg.1_70, i8 zeroext %reg.1_71) to label %.Lj67 unwind label %.Lj51, !dbg !96
.Lj67:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 114), !dbg !98
	%reg.1_73 = bitcast ptr %tmp.2 to ptr, !dbg !98
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_73), !dbg !98
	%reg.1_74 = bitcast ptr @"U_$P$ASMTEST_$$_S" to ptr, !dbg !98
	store ptr %reg.1_74, ptr %tmp.2, align 8, !dbg !98
	%reg.1_75 = load ptr, ptr %tmp.2, align 8, !dbg !98
	%reg.1_76 = bitcast ptr %reg.1_75 to ptr, !dbg !98
	invoke  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_76) to label %.Lj68 unwind label %.Lj51, !dbg !98
.Lj68:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 114), !dbg !98
	%reg.1_77 = load ptr, ptr %tmp.2, align 8, !dbg !98
	%reg.1_78 = bitcast ptr %reg.1_77 to ptr, !dbg !98
	invoke  void (ptr) @"P$ASMTEST_$$_FIELDS$ANSISTRING" (ptr %reg.1_78) to label %.Lj69 unwind label %.Lj51, !dbg !98
.Lj69:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 114), !dbg !98
	%reg.1_80 = bitcast ptr %tmp.2 to ptr, !dbg !98
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_80), !dbg !98
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 115), !dbg !99
	%reg.1_81 = bitcast ptr %tmp.3 to ptr, !dbg !99
	invoke  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_81) to label %.Lj70 unwind label %.Lj51, !dbg !99
.Lj70:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 115), !dbg !99
	%reg.1_83 = load ptr, ptr @"U_$P$ASMTEST_$$_S", align 8, !dbg !99
	%reg.1_85 = getelementptr %"typ.asmtest.$ansistrrec12", ptr @".Ld9", i32 0, i32 4, !dbg !99
	%reg.1_84 = bitcast ptr %reg.1_85 to ptr, !dbg !99
	%reg.1_86 = bitcast ptr %reg.1_84 to ptr, !dbg !99
	%reg.1_87 = bitcast ptr %tmp.3 to ptr, !dbg !99
	invoke  void (ptr, ptr, ptr, i16) @"fpc_ansistr_concat" (ptr %reg.1_87, ptr %reg.1_86, ptr %reg.1_83, i16 zeroext 0) to label %.Lj71 unwind label %.Lj51, !dbg !99
.Lj71:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 115), !dbg !100
	%reg.1_88 = load ptr, ptr %tmp.3, align 8, !dbg !100
	%reg.1_90 = getelementptr %"typ.asmtest.$ansistrrec11", ptr @".Ld10", i32 0, i32 4, !dbg !101
	%reg.1_89 = bitcast ptr %reg.1_90 to ptr, !dbg !101
	%reg.1_91 = bitcast ptr %reg.1_89 to ptr, !dbg !101
	%reg.1_92 = load ptr, ptr @"U_$P$ASMTEST_$$_S", align 8, !dbg !101
	%reg.1_93 = invoke  i64 (ptr, ptr) @"fpc_ansistr_compare_equal" (ptr %reg.1_92, ptr %reg.1_91) to label %.Lj72 unwind label %.Lj51, !dbg !101
.Lj72:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 115), !dbg !101
	%reg.1_94 = bitcast i64 %reg.1_93 to i64, !dbg !101
	%reg.1_95 = icmp eq i64 %reg.1_94, 0, !dbg !101
	%reg.1_96 = zext i1 %reg.1_95 to i8, !dbg !101
	%reg.1_97 = zext i8 %reg.1_96 to i64, !dbg !100
	%reg.1_98 = trunc i64 %reg.1_97 to i8, !dbg !100
	invoke  void (ptr, i8) @"P$ASMTEST_$$_CHECK$ANSISTRING$BOOLEAN" (ptr %reg.1_88, i8 zeroext %reg.1_98) to label %.Lj73 unwind label %.Lj51, !dbg !100
.Lj73:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 116), !dbg !102
	%reg.1_101 = invoke  i32 (i32, i32) @"P$ASMTEST_$$_PURE3$LONGINT$LONGINT$$LONGINT" (i32 signext 40, i32 signext 2) to label %.Lj74 unwind label %.Lj51, !dbg !102
.Lj74:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 116), !dbg !102
	%reg.1_102 = bitcast i32 %reg.1_101 to i32, !dbg !102
	%reg.1_103 = icmp eq i32 %reg.1_102, 42, !dbg !103
	%reg.1_104 = zext i1 %reg.1_103 to i8, !dbg !103
	%reg.1_105 = zext i8 %reg.1_104 to i64, !dbg !104
	%reg.1_107 = getelementptr %"typ.asmtest.$ansistrrec43", ptr @".Ld11", i32 0, i32 4, !dbg !105
	%reg.1_106 = bitcast ptr %reg.1_107 to ptr, !dbg !105
	%reg.1_108 = bitcast ptr %reg.1_106 to ptr, !dbg !104
	%reg.1_109 = trunc i64 %reg.1_105 to i8, !dbg !104
	invoke  void (ptr, i8) @"P$ASMTEST_$$_CHECK$ANSISTRING$BOOLEAN" (ptr %reg.1_108, i8 zeroext %reg.1_109) to label %.Lj75 unwind label %.Lj51, !dbg !104
.Lj75:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 117), !dbg !106
	invoke  void () @"P$ASMTEST_$$_EMPTY" () to label %.Lj76 unwind label %.Lj51, !dbg !106
.Lj76:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 118), !dbg !107
	%reg.1_111 = bitcast ptr %tmp.4 to ptr, !dbg !107
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_111), !dbg !107
	%reg.1_112 = invoke  ptr () @"fpc_get_output" () to label %.Lj77 unwind label %.Lj51, !dbg !107
.Lj77:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 118), !dbg !107
	%reg.1_113 = bitcast ptr %reg.1_112 to ptr, !dbg !107
	store ptr %reg.1_113, ptr %tmp.4, align 8, !dbg !107
	%reg.1_114 = load ptr, ptr %tmp.4, align 8, !dbg !107
	%reg.1_115 = bitcast ptr %reg.1_114 to ptr, !dbg !107
	%reg.1_116 = bitcast ptr %reg.1_115 to ptr, !dbg !107
	%reg.1_117 = bitcast ptr @".Ld12" to ptr, !dbg !108
	%reg.1_118 = bitcast ptr %reg.1_117 to ptr, !dbg !107
	invoke  void (i32, ptr, ptr) @"fpc_write_text_shortstr" (i32 signext 0, ptr %reg.1_116, ptr %reg.1_118) to label %.Lj78 unwind label %.Lj51, !dbg !107
.Lj78:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 118), !dbg !107
	invoke  void () @"fpc_iocheck" () to label %.Lj79 unwind label %.Lj51, !dbg !107
.Lj79:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 118), !dbg !109
	%reg.1_121 = load i32, ptr @"TC_$P$ASMTEST_$$_ERRORS", align 4, !dbg !109
	%reg.1_120 = sext i32 %reg.1_121 to i64, !dbg !109
	%reg.1_122 = bitcast i64 %reg.1_120 to i64, !dbg !107
	%reg.1_123 = load ptr, ptr %tmp.4, align 8, !dbg !107
	%reg.1_124 = bitcast ptr %reg.1_123 to ptr, !dbg !107
	%reg.1_125 = bitcast ptr %reg.1_124 to ptr, !dbg !107
	invoke  void (i32, ptr, i64) @"fpc_write_text_sint" (i32 signext 0, ptr %reg.1_125, i64 %reg.1_122) to label %.Lj80 unwind label %.Lj51, !dbg !107
.Lj80:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 118), !dbg !107
	invoke  void () @"fpc_iocheck" () to label %.Lj81 unwind label %.Lj51, !dbg !107
.Lj81:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 118), !dbg !107
	%reg.1_127 = load ptr, ptr %tmp.4, align 8, !dbg !107
	%reg.1_128 = bitcast ptr %reg.1_127 to ptr, !dbg !107
	%reg.1_129 = bitcast ptr %reg.1_128 to ptr, !dbg !107
	invoke  void (ptr) @"fpc_writeln_end" (ptr %reg.1_129) to label %.Lj82 unwind label %.Lj51, !dbg !107
.Lj82:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 118), !dbg !107
	invoke  void () @"fpc_iocheck" () to label %.Lj83 unwind label %.Lj51, !dbg !107
.Lj83:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 118), !dbg !107
	%reg.1_131 = bitcast ptr %tmp.4 to ptr, !dbg !107
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_131), !dbg !107
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 119), !dbg !110
	%reg.1_133 = load i32, ptr @"TC_$P$ASMTEST_$$_ERRORS", align 4, !dbg !110
	%reg.1_132 = sext i32 %reg.1_133 to i64, !dbg !110
	%reg.1_134 = trunc i64 %reg.1_132 to i32, !dbg !110
	invoke  void (i32) @"SYSTEM_$$_HALT$LONGINT" (i32 signext %reg.1_134) to label %.Lj84 unwind label %.Lj51, !dbg !110
.Lj84:
	invoke  void () @"SYSTEM_$$_FPC_DUMMYPOTENTIALRAISE" () to label %.Lj85 unwind label %.Lj51, !dbg !111
.Lj85:
	%reg.1_135 = bitcast i64 0 to i64
	store i64 %reg.1_135, ptr %tmp.1, align 8
	br label %.Lj86
.Lj86:
	%reg.1_137 = bitcast ptr %tmp.3 to ptr
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_137), !dbg !111
	%reg.1_138 = load i64, ptr %tmp.1, align 8
	%reg.1_139 = bitcast i64 0 to i64
	%reg.1_140 = icmp eq i64 %reg.1_138, %reg.1_139
	br i1 %reg.1_140, label %.Lj49, label %.Lj87
.Lj87:
	unreachable
	unreachable
.Lj51:
	%reg.1_136 = landingpad %"typ.asmtest.$llvmstruct$d00000004i32" 	cleanup

	br label %.Lj50
.Lj50:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 120), !dbg !112
	%reg.1_141 = bitcast ptr %tmp.3 to ptr, !dbg !112
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_141), !dbg !112
	resume %"typ.asmtest.$llvmstruct$d00000004i32" %reg.1_136
	%reg.1_143 = bitcast ptr %tmp.1 to ptr
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_143), !dbg !111
	br label %.Lj49
.Lj49:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 120), !dbg !112
	br label %.Lj3, !dbg !112
.Lj3:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 120), !dbg !112
	call  void () @"fpc_do_exit" (), !dbg !112
	%reg.1_151 = bitcast ptr %tmp.5 to ptr, !dbg !112
	call  void (i64, ptr) @llvm.lifetime.end (i64 1, ptr %reg.1_151), !dbg !112
	ret void, !dbg !112
}
@"INIT$_$P$ASMTEST" = hidden alias  void (), ptr @"P$ASMTEST_$$_init_implicit$"
define hidden void @"P$ASMTEST_$$_init_implicit$"() nobuiltin null_pointer_is_valid strictfp !dbg !113 {
	%zdbg.r = alloca { ptr, ptr, i32, i32, [1 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [1 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.10, ptr %zdbg.fp, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r)
	br label %.Lj45
.Lj45:
	ret void
}
@"FINALIZE$_$P$ASMTEST" = hidden alias  void (), ptr @"P$ASMTEST_$$_finalize_implicit$"
@"PASCALFINALIZE" = hidden alias  void (), ptr @"P$ASMTEST_$$_finalize_implicit$"
define hidden void @"P$ASMTEST_$$_finalize_implicit$"() nobuiltin null_pointer_is_valid strictfp personality ptr @"SYSTEM_$$__FPC_PSABIEH_PERSONALITY_V0$hhyOiwn8_zDM" !dbg !114 {
	%zdbg.r = alloca { ptr, ptr, i32, i32, [1 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [1 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.11, ptr %zdbg.fp, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r)
	br label %.Lj47
.Lj47:
	%reg.1_16 = bitcast ptr @"U_$P$ASMTEST_$$_S" to ptr
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_16), !dbg !115
	ret void
}
declare void @llvm.lifetime.start(i64, ptr) null_pointer_is_valid strictfp
declare void @llvm.dbg.declare(metadata, metadata, metadata) null_pointer_is_valid strictfp
declare ptr @"fpc_get_output"() nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_write_text_shortstr"(i32 signext, ptr nocapture dereferenceable_or_null(896), ptr nocapture readonly dereferenceable(256)) nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_iocheck"() nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_write_text_ansistr"(i32 signext, ptr nocapture dereferenceable_or_null(896), ptr) nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_writeln_end"(ptr nocapture dereferenceable_or_null(896)) nobuiltin null_pointer_is_valid strictfp
declare void @llvm.lifetime.end(i64, ptr) null_pointer_is_valid strictfp
declare signext i32 @"SYSTEM_$$__FPC_PSABIEH_PERSONALITY_V0$hhyOiwn8_zDM"(i32 signext, i32 signext, i64, ptr, ptr) nobuiltin null_pointer_is_valid strictfp
declare void @"SYSTEM_$$_FPC_DUMMYPOTENTIALRAISE"() noinline nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_ansistr_decr_ref"(ptr nocapture dereferenceable_or_null(8)) inlinehint nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_shortstr_sint"(i64, i64, ptr nocapture dereferenceable_or_null(1), i64) nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_shortstr_to_ansistr"(ptr sret(ptr) noalias nocapture, ptr nocapture readonly dereferenceable(256), i16 zeroext) nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_ansistr_assign"(ptr nocapture dereferenceable_or_null(8), ptr) nobuiltin null_pointer_is_valid strictfp
declare void @"SYSTEM_$$_SETCODEPAGE$RAWBYTESTRING$WORD$BOOLEAN"(ptr nocapture dereferenceable_or_null(8), i16 zeroext, i8 zeroext) nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_chararray_to_shortstr"(ptr nocapture dereferenceable_or_null(1), i64, ptr nocapture, i64, i8 zeroext) nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_shortstr_concat"(ptr nocapture dereferenceable_or_null(1), i64, ptr nocapture readonly dereferenceable(256), ptr nocapture readonly dereferenceable(256)) nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_ansistr_concat"(ptr nocapture dereferenceable_or_null(8), ptr, ptr, i16 zeroext) nobuiltin null_pointer_is_valid strictfp
declare void @"FPC_SYSTEMMAIN"(i32 signext, ptr, ptr) nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_initializeunits"() nobuiltin null_pointer_is_valid strictfp
declare i64 @"fpc_ansistr_compare_equal"(ptr, ptr) nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_write_text_sint"(i32 signext, ptr nocapture dereferenceable_or_null(896), i64) nobuiltin null_pointer_is_valid strictfp
declare void @"SYSTEM_$$_HALT$LONGINT"(i32 signext) nobuiltin noreturn null_pointer_is_valid strictfp
declare void @"fpc_do_exit"() nobuiltin null_pointer_is_valid strictfp
; End asmlist al_procedures
; Begin asmlist al_globals
@"U_$P$ASMTEST_$$_R" = hidden global %"typ.asmtest.TRec" zeroinitializer, align 4, !dbg !122
@"U_$P$ASMTEST_$$_S" = hidden global ptr zeroinitializer, align 8, !dbg !124
@".Ld13" = internal unnamed_addr constant [7 x i8] c"\06System", align 8
@".Ld14" = internal unnamed_addr constant [7 x i8] c"\06objpas", align 8
@".Ld15" = internal unnamed_addr constant [8 x i8] c"\07asmtest", align 8
@"INITFINAL" = hidden global %"typ.asmtest.00000015" <{i64 3, i64 zeroinitializer, ptr @"INIT$_$SYSTEM", ptr zeroinitializer, ptr @".Ld13", ptr zeroinitializer, ptr @"FINALIZE$_$OBJPAS", ptr @".Ld14", ptr @"INIT$_$P$ASMTEST", ptr @"FINALIZE$_$P$ASMTEST", ptr @".Ld15" }>, align 8
@"FPC_THREADVARTABLES" = hidden global %"typ.asmtest.00000016" <{i64 1, ptr @"THREADVARLIST_$SYSTEM$indirect" }>, align 8
@"FPC_RESOURCESTRINGTABLES" = hidden constant %"typ.asmtest.00000017" <{i64 zeroinitializer }>, align 8
@"FPC_WIDEINITTABLES" = hidden global %"typ.asmtest.00000018" <{i64 zeroinitializer }>, align 8
@"FPC_RESSTRINITTABLES" = hidden global %"typ.asmtest.00000019" <{i64 zeroinitializer }>, align 8
@"__fpc_ident" = internal global [38 x i8] c"FPC 3.3.1 [2026/09/28] for s390x - zos", align 8
@"__stklen" = hidden global i64 1048576, align 8
@"__heapsize" = hidden global i64 zeroinitializer, align 8
@"__fpc_valgrind" = hidden global i8 zeroinitializer, align 8
@llvm.compiler.used = appending hidden global [2 x ptr] [ptr @"TC_$P$ASMTEST_$$_G", ptr @"__fpc_ident"], section "llvm.metadata"
declare void @"INIT$_$SYSTEM"() nobuiltin null_pointer_is_valid strictfp
declare void @"FINALIZE$_$OBJPAS"() nobuiltin null_pointer_is_valid strictfp
@"THREADVARLIST_$SYSTEM$indirect" = external global ptr, align 8
; End asmlist al_globals
; Begin asmlist al_typedconsts
@"TC_$P$ASMTEST_$$_ERRORS" = hidden global i32 zeroinitializer, align 4, !dbg !117
@"TC_$P$ASMTEST_$$_G" = hidden global i32 7, align 4, !dbg !119
@".Ld1" = internal unnamed_addr constant [10 x i8] c"\08OK      \00", align 8
@".Ld2" = internal unnamed_addr constant [10 x i8] c"\08FEHLER  \00", align 8
@".Ld3" = internal unnamed_addr constant [9 x i8] c"ABCDEFGH\00", align 8
@".Ld4" = internal unnamed_addr constant [3 x i8] c"\01/\00", align 8
@".Ld5" = internal unnamed_addr constant %"typ.asmtest.$ansistrrec13" <{i16 zeroinitializer, i16 1, i32 -1, i64 13, [14 x i8] c"add1(41) = 42\00" }>, align 8
@".Ld6" = internal unnamed_addr constant %"typ.asmtest.$ansistrrec14" <{i16 zeroinitializer, i16 1, i32 -1, i64 14, [15 x i8] c"sumto(10) = 55\00" }>, align 8
@".Ld7" = internal unnamed_addr constant %"typ.asmtest.$ansistrrec24" <{i16 zeroinitializer, i16 1, i32 -1, i64 24, [25 x i8] c"globale Variable: g = 12\00" }>, align 8
@".Ld8" = internal unnamed_addr constant %"typ.asmtest.$ansistrrec20" <{i16 zeroinitializer, i16 1, i32 -1, i64 20, [21 x i8] c"var-Record: r.b = 42\00" }>, align 8
@".Ld9" = internal unnamed_addr constant %"typ.asmtest.$ansistrrec12" <{i16 zeroinitializer, i16 1, i32 -1, i64 12, [13 x i8] c"MVC/MVI/LA: \00" }>, align 8
@".Ld10" = internal unnamed_addr constant %"typ.asmtest.$ansistrrec11" <{i16 zeroinitializer, i16 1, i32 -1, i64 11, [12 x i8] c"ABCDEFGZ/42\00" }>, align 8
@".Ld11" = internal unnamed_addr constant %"typ.asmtest.$ansistrrec43" <{i16 zeroinitializer, i16 1, i32 -1, i64 43, [44 x i8] c"reine Assembler-Funktion: pure3(40, 2) = 42\00" }>, align 8
@".Ld12" = internal unnamed_addr constant [10 x i8] c"\08Fehler: \00", align 8
; End asmlist al_typedconsts
; Begin asmlist al_rotypedconsts
!llvm.module.flags = !{!257, !258}
!257 = !{i32 2, !"Debug Info Version", i32 3}
!258 = !{i32 2, !"Dwarf Version", i32 3}
; End asmlist al_rotypedconsts
; Begin asmlist al_dwarf_info
!9 = !DILocalVariable(name: "WHAT", arg: 10, scope: !6, file: !7, line: 21, type: !10)
!11 = !DILocalVariable(name: "OK", arg: 20, scope: !6, file: !7, line: 21, type: !12)
!22 = !DILocalVariable(name: "X", arg: 10, scope: !20, file: !7, line: 27, type: !23)
!24 = !DILocalVariable(name: "result", scope: !20, file: !7, line: 27, type: !23)
!29 = !DILocalVariable(name: "N", arg: 10, scope: !27, file: !7, line: 36, type: !23)
!30 = !DILocalVariable(name: "result", scope: !27, file: !7, line: 36, type: !23)
!31 = !DILocalVariable(name: "S", scope: !27, file: !7, line: 38, type: !23)
!41 = !DILocalVariable(name: "R", arg: 10, scope: !39, file: !7, line: 61, type: !42)
!47 = !DILocalVariable(name: "RES", arg: 10, scope: !45, file: !7, line: 71, type: !10)
!48 = !DILocalVariable(name: "R", scope: !45, file: !7, line: 73, type: !42)
!49 = !DILocalVariable(name: "SRC", scope: !45, file: !7, line: 74, type: !50)
!51 = !DILocalVariable(name: "T", scope: !45, file: !7, line: 75, type: !10)
!69 = !DILocalVariable(name: "ARGC", arg: 1, scope: !67, file: !7, line: 8, type: !23)
!70 = !DILocalVariable(name: "ARGV", arg: 2, scope: !67, file: !7, line: 8, type: !71)
!72 = !DILocalVariable(name: "ARGP", arg: 3, scope: !67, file: !7, line: 8, type: !71)
; Syms - Begin Staticsymtable
; Symbol SYSTEM
; Symbol OBJPAS
; Symbol ASMTEST
; Symbol main
; Symbol __FPC_IMPL_EXTERNAL_REDIRECT_FPC_SYSTEMMAIN
; Symbol PASCALMAIN
; Symbol TREC
; Symbol K
; Symbol ERRORS
!116 = distinct !DIGlobalVariable(name: "ERRORS", scope: !5, file: !7, line: 18, type: !23, isDefinition: true, isLocal: true)
!117 = !DIGlobalVariableExpression(var: !116, expr: !3)
; Symbol G
!118 = distinct !DIGlobalVariable(name: "G", scope: !5, file: !7, line: 19, type: !23, isDefinition: true, isLocal: true)
!119 = !DIGlobalVariableExpression(var: !118, expr: !3)
; Symbol CHECK
; Symbol ADD1
; Symbol SUMTO
; Symbol INCGLOBAL
; Symbol SETB
; Symbol FIELDS
; Symbol llvmstruct$d00000004i32
; Symbol PURE3
; Symbol EMPTY
; Symbol R
!121 = distinct !DIGlobalVariable(name: "R", scope: !5, file: !7, line: 104, type: !42, isDefinition: true, isLocal: true)
!122 = !DIGlobalVariableExpression(var: !121, expr: !3)
; Symbol S
!123 = distinct !DIGlobalVariable(name: "S", scope: !5, file: !7, line: 105, type: !10, isDefinition: true, isLocal: true)
!124 = !DIGlobalVariableExpression(var: !123, expr: !3)
; Symbol P$ASMTEST_$$_init_implicit$
; Symbol P$ASMTEST_$$_finalize_implicit$
; Symbol ansistrrec13
; Symbol ansistrrec14
; Symbol ansistrrec24
; Symbol ansistrrec20
; Symbol ansistrrec12
; Symbol ansistrrec11
; Symbol ansistrrec43
; Syms - End Staticsymtable
!67 = distinct !DISubprogram(name: "main", scope: !7, file: !7, line: 8, spFlags: DISPFlagDefinition, unit: !5, type: !132)
!133 = !{null, !23, !71, !71}
!132 = !DISubroutineType(types: !133)
!73 = distinct !DISubprogram(scopeLine: 106, name: "PASCALMAIN", scope: !7, file: !7, line: 8, spFlags: DISPFlagDefinition|DISPFlagMainSubprogram, unit: !5, type: !134)
!135 = !{null}
!134 = !DISubroutineType(types: !135)
!6 = distinct !DISubprogram(scopeLine: 22, name: "CHECK", scope: !7, file: !7, line: 21, spFlags: DISPFlagDefinition, unit: !5, type: !136)
!137 = !{null, !10, !12}
!136 = !DISubroutineType(types: !137)
!20 = distinct !DISubprogram(scopeLine: 28, name: "ADD1", scope: !7, file: !7, line: 27, spFlags: DISPFlagDefinition, unit: !5, type: !138)
!139 = !{!23, !23}
!138 = !DISubroutineType(types: !139)
!27 = distinct !DISubprogram(scopeLine: 39, name: "SUMTO", scope: !7, file: !7, line: 36, spFlags: DISPFlagDefinition, unit: !5, type: !140)
!141 = !{!23, !23}
!140 = !DISubroutineType(types: !141)
!36 = distinct !DISubprogram(scopeLine: 54, name: "INCGLOBAL", scope: !7, file: !7, line: 52, spFlags: DISPFlagDefinition, unit: !5, type: !142)
!143 = !{null}
!142 = !DISubroutineType(types: !143)
!39 = distinct !DISubprogram(scopeLine: 62, name: "SETB", scope: !7, file: !7, line: 61, spFlags: DISPFlagDefinition, unit: !5, type: !144)
!145 = !{null, !42}
!144 = !DISubroutineType(types: !145)
!45 = distinct !DISubprogram(scopeLine: 76, name: "FIELDS", scope: !7, file: !7, line: 71, spFlags: DISPFlagDefinition, unit: !5, type: !146)
!147 = !{null, !10}
!146 = !DISubroutineType(types: !147)
!148 = distinct !DISubprogram(name: "PURE3", scope: !7, file: !7, line: 91, spFlags: DISPFlagDefinition, unit: !5, type: !149)
!150 = !{!23, !23, !23}
!149 = !DISubroutineType(types: !150)
!64 = distinct !DISubprogram(scopeLine: 99, name: "EMPTY", scope: !7, file: !7, line: 97, spFlags: DISPFlagDefinition, unit: !5, type: !151)
!152 = !{null}
!151 = !DISubroutineType(types: !152)
!113 = distinct !DISubprogram(name: "P$ASMTEST_$$_init_implicit$", scope: !7, file: !7, line: 120, spFlags: DISPFlagDefinition, unit: !5, type: !153)
!154 = !{null}
!153 = !DISubroutineType(types: !154)
!114 = distinct !DISubprogram(name: "P$ASMTEST_$$_finalize_implicit$", scope: !7, file: !7, line: 120, spFlags: DISPFlagDefinition, unit: !5, type: !155)
!156 = !{null}
!155 = !DISubroutineType(types: !156)
; Defs - Begin unit SYSTEM has index 2
!157 = !DIBasicType(size: 32, encoding: DW_ATE_signed)
!23 = !DIDerivedType(tag: DW_TAG_typedef, name: "LONGINT", file: !158, line: 23, baseType: !157)
!159 = !DIBasicType(size: 8, encoding: DW_ATE_boolean)
!12 = !DIDerivedType(tag: DW_TAG_typedef, name: "BOOLEAN", file: !158, line: 23, baseType: !159)
!160 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !161)
!10 = !DIDerivedType(tag: DW_TAG_typedef, name: "ANSISTRING", file: !158, line: 23, baseType: !160)
!162 = !DIBasicType(size: 8, encoding: DW_ATE_unsigned_char)
!161 = !DIDerivedType(tag: DW_TAG_typedef, name: "ANSICHAR", file: !158, line: 23, baseType: !162)
; Defs - End unit SYSTEM has index 2
; Defs - Begin unit OBJPAS has index 3
; Defs - End unit OBJPAS has index 3
; Defs - Begin Staticsymtable
!71 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !163)
!164 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "TREC", file: !7, line: 9, size: 128, elements: !165)
!165 = !{!166, !167, !168}
!166 = !DIDerivedType(tag: DW_TAG_member, name: "A", scope: !164, file: !7, line: 10, baseType: !23, size: 32)
!167 = !DIDerivedType(tag: DW_TAG_member, name: "B", scope: !164, file: !7, line: 10, baseType: !23, size: 32, offset: 32)
!168 = !DIDerivedType(tag: DW_TAG_member, name: "C", scope: !164, file: !7, line: 11, baseType: !169, size: 64, offset: 64)
!42 = !DIDerivedType(tag: DW_TAG_typedef, name: "TREC", file: !7, line: 9, baseType: !164)
!170 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$LLVMSTRUCT$D00000004I32", file: !7, line: 87, size: 96, elements: !171)
!171 = !{!172, !174}
!172 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !170, file: !7, line: 87, baseType: !173, size: 64, flags: DIFlagArtificial)
!174 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !170, file: !7, line: 87, baseType: !175, size: 32, offset: 64, flags: DIFlagArtificial)
!120 = !DIDerivedType(tag: DW_TAG_typedef, name: "llvmstruct$d00000004i32", file: !7, line: 87, baseType: !170)
!176 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$ANSISTRREC13", size: 240, elements: !177)
!177 = !{!178, !180, !181, !182, !184}
!178 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !176, baseType: !179, size: 16, flags: DIFlagArtificial)
!180 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !176, baseType: !179, size: 16, offset: 16, flags: DIFlagArtificial)
!181 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !176, baseType: !23, size: 32, offset: 32, flags: DIFlagArtificial)
!182 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !176, baseType: !183, size: 64, offset: 64, flags: DIFlagArtificial)
!184 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !176, baseType: !185, size: 112, offset: 128, flags: DIFlagArtificial)
!125 = !DIDerivedType(tag: DW_TAG_typedef, name: "ansistrrec13", baseType: !176)
!186 = !{!187}
!187 = !DISubrange(count: 14, lowerBound: 0)
!185 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !161, elements: !186, size: 112)
!188 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$ANSISTRREC14", size: 248, elements: !189)
!189 = !{!190, !191, !192, !193, !194}
!190 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !188, baseType: !179, size: 16, flags: DIFlagArtificial)
!191 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !188, baseType: !179, size: 16, offset: 16, flags: DIFlagArtificial)
!192 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !188, baseType: !23, size: 32, offset: 32, flags: DIFlagArtificial)
!193 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !188, baseType: !183, size: 64, offset: 64, flags: DIFlagArtificial)
!194 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !188, baseType: !195, size: 120, offset: 128, flags: DIFlagArtificial)
!126 = !DIDerivedType(tag: DW_TAG_typedef, name: "ansistrrec14", baseType: !188)
!196 = !{!197}
!197 = !DISubrange(count: 15, lowerBound: 0)
!195 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !161, elements: !196, size: 120)
!198 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$ANSISTRREC24", size: 328, elements: !199)
!199 = !{!200, !201, !202, !203, !204}
!200 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !198, baseType: !179, size: 16, flags: DIFlagArtificial)
!201 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !198, baseType: !179, size: 16, offset: 16, flags: DIFlagArtificial)
!202 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !198, baseType: !23, size: 32, offset: 32, flags: DIFlagArtificial)
!203 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !198, baseType: !183, size: 64, offset: 64, flags: DIFlagArtificial)
!204 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !198, baseType: !205, size: 200, offset: 128, flags: DIFlagArtificial)
!127 = !DIDerivedType(tag: DW_TAG_typedef, name: "ansistrrec24", baseType: !198)
!206 = !{!207}
!207 = !DISubrange(count: 25, lowerBound: 0)
!205 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !161, elements: !206, size: 200)
!208 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$ANSISTRREC20", size: 296, elements: !209)
!209 = !{!210, !211, !212, !213, !214}
!210 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !208, baseType: !179, size: 16, flags: DIFlagArtificial)
!211 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !208, baseType: !179, size: 16, offset: 16, flags: DIFlagArtificial)
!212 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !208, baseType: !23, size: 32, offset: 32, flags: DIFlagArtificial)
!213 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !208, baseType: !183, size: 64, offset: 64, flags: DIFlagArtificial)
!214 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !208, baseType: !215, size: 168, offset: 128, flags: DIFlagArtificial)
!128 = !DIDerivedType(tag: DW_TAG_typedef, name: "ansistrrec20", baseType: !208)
!216 = !{!217}
!217 = !DISubrange(count: 21, lowerBound: 0)
!215 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !161, elements: !216, size: 168)
!218 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$ANSISTRREC12", size: 232, elements: !219)
!219 = !{!220, !221, !222, !223, !224}
!220 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !218, baseType: !179, size: 16, flags: DIFlagArtificial)
!221 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !218, baseType: !179, size: 16, offset: 16, flags: DIFlagArtificial)
!222 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !218, baseType: !23, size: 32, offset: 32, flags: DIFlagArtificial)
!223 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !218, baseType: !183, size: 64, offset: 64, flags: DIFlagArtificial)
!224 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !218, baseType: !225, size: 104, offset: 128, flags: DIFlagArtificial)
!129 = !DIDerivedType(tag: DW_TAG_typedef, name: "ansistrrec12", baseType: !218)
!226 = !{!227}
!227 = !DISubrange(count: 13, lowerBound: 0)
!225 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !161, elements: !226, size: 104)
!228 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$ANSISTRREC11", size: 224, elements: !229)
!229 = !{!230, !231, !232, !233, !234}
!230 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !228, baseType: !179, size: 16, flags: DIFlagArtificial)
!231 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !228, baseType: !179, size: 16, offset: 16, flags: DIFlagArtificial)
!232 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !228, baseType: !23, size: 32, offset: 32, flags: DIFlagArtificial)
!233 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !228, baseType: !183, size: 64, offset: 64, flags: DIFlagArtificial)
!234 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !228, baseType: !235, size: 96, offset: 128, flags: DIFlagArtificial)
!130 = !DIDerivedType(tag: DW_TAG_typedef, name: "ansistrrec11", baseType: !228)
!236 = !{!237}
!237 = !DISubrange(count: 12, lowerBound: 0)
!235 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !161, elements: !236, size: 96)
!238 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$ANSISTRREC43", size: 480, elements: !239)
!239 = !{!240, !241, !242, !243, !244}
!240 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !238, baseType: !179, size: 16, flags: DIFlagArtificial)
!241 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !238, baseType: !179, size: 16, offset: 16, flags: DIFlagArtificial)
!242 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !238, baseType: !23, size: 32, offset: 32, flags: DIFlagArtificial)
!243 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !238, baseType: !183, size: 64, offset: 64, flags: DIFlagArtificial)
!244 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !238, baseType: !245, size: 352, offset: 128, flags: DIFlagArtificial)
!131 = !DIDerivedType(tag: DW_TAG_typedef, name: "ansistrrec43", baseType: !238)
!246 = !{!247}
!247 = !DISubrange(count: 44, lowerBound: 0)
!245 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !161, elements: !246, size: 352)
; Defs - End Staticsymtable
!248 = !{!249}
!249 = !DISubrange(count: 8, lowerBound: 0)
!50 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !161, elements: !248, size: 64)
!250 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !161)
!163 = !DIDerivedType(tag: DW_TAG_typedef, name: "char_pointer", file: !158, line: 23, baseType: !250)
!251 = !{!252}
!252 = !DISubrange(count: 8, lowerBound: 0)
!169 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !161, elements: !251, size: 64)
!253 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null)
!173 = !DIDerivedType(tag: DW_TAG_typedef, name: "POINTER", file: !158, line: 23, baseType: !253)
!254 = !DIBasicType(size: 32, encoding: DW_ATE_unsigned)
!175 = !DIDerivedType(tag: DW_TAG_typedef, name: "LONGWORD", file: !158, line: 23, baseType: !254)
!255 = !DIBasicType(size: 16, encoding: DW_ATE_unsigned)
!179 = !DIDerivedType(tag: DW_TAG_typedef, name: "WORD", file: !158, line: 23, baseType: !255)
!256 = !DIBasicType(size: 64, encoding: DW_ATE_signed)
!183 = !DIDerivedType(tag: DW_TAG_typedef, name: "INT64", file: !158, line: 23, baseType: !256)
!2 = !{!117, !119, !122, !124}
!3 = !DIExpression()
!4 = !DIExpression(DW_OP_deref)
!5 = distinct !DICompileUnit(language: DW_LANG_Pascal83, file: !7, producer: "Free Pascal Compiler 3.3.1", isOptimized: false, emissionKind: FullDebug, enums: null, retainedTypes: null, globals: !2)
!llvm.dbg.cu = !{!5}
; End asmlist al_dwarf_info
; Begin asmlist al_dwarf_line
!7 = !DIFile(filename: "asmtest.pas", directory: "/mnt/c/Users/marce/Documents/GitHub/zos-pascal-llvm/pf5")
!8 = !DILocation(line: 22, column: 1, scope: !6)
!13 = !DILocation(line: 23, column: 6, scope: !6)
!14 = !DILocation(line: 23, column: 14, scope: !6)
!15 = !DILocation(line: 23, column: 32, scope: !6)
!16 = !DILocation(line: 24, column: 14, scope: !6)
!17 = !DILocation(line: 24, column: 32, scope: !6)
!18 = !DILocation(line: 24, column: 41, scope: !6)
!19 = !DILocation(line: 25, column: 1, scope: !6)
!21 = !DILocation(line: 28, column: 1, scope: !20)
!25 = !DILocation(line: 29, column: 3, scope: !20)
!26 = !DILocation(line: 34, column: 1, scope: !20)
!28 = !DILocation(line: 39, column: 1, scope: !27)
!32 = !DILocation(line: 40, column: 3, scope: !27)
!33 = !DILocation(line: 41, column: 3, scope: !27)
!34 = !DILocation(line: 49, column: 3, scope: !27)
!35 = !DILocation(line: 50, column: 1, scope: !27)
!37 = !DILocation(line: 54, column: 3, scope: !36)
!38 = !DILocation(line: 59, column: 1, scope: !36)
!40 = !DILocation(line: 62, column: 1, scope: !39)
!43 = !DILocation(line: 63, column: 3, scope: !39)
!44 = !DILocation(line: 69, column: 1, scope: !39)
!46 = !DILocation(line: 76, column: 1, scope: !45)
!52 = !DILocation(line: 77, column: 10, scope: !45)
!53 = !DILocation(line: 77, column: 3, scope: !45)
!54 = !DILocation(line: 78, column: 4, scope: !45)
!55 = !DILocation(line: 78, column: 3, scope: !45)
!56 = !DILocation(line: 79, column: 3, scope: !45)
!57 = !DILocation(line: 85, column: 3, scope: !45)
!58 = !DILocation(line: 85, column: 10, scope: !45)
!59 = !DILocation(line: 86, column: 14, scope: !45)
!60 = !DILocation(line: 86, column: 11, scope: !45)
!61 = !DILocation(line: 86, column: 20, scope: !45)
!62 = !DILocation(line: 0, scope: !45)
!63 = !DILocation(line: 87, column: 1, scope: !45)
!65 = !DILocation(line: 99, column: 3, scope: !64)
!66 = !DILocation(line: 101, column: 1, scope: !64)
!68 = !DILocation(line: 0, scope: !67)
!74 = !DILocation(line: 106, column: 1, scope: !73)
!75 = !DILocation(line: 107, column: 26, scope: !73)
!76 = !DILocation(line: 107, column: 39, scope: !73)
!77 = !DILocation(line: 107, column: 3, scope: !73)
!78 = !DILocation(line: 107, column: 24, scope: !73)
!79 = !DILocation(line: 108, column: 27, scope: !73)
!80 = !DILocation(line: 108, column: 41, scope: !73)
!81 = !DILocation(line: 108, column: 3, scope: !73)
!82 = !DILocation(line: 108, column: 25, scope: !73)
!83 = !DILocation(line: 109, column: 3, scope: !73)
!84 = !DILocation(line: 110, column: 43, scope: !73)
!85 = !DILocation(line: 110, column: 3, scope: !73)
!86 = !DILocation(line: 110, column: 35, scope: !73)
!87 = !DILocation(line: 111, column: 4, scope: !73)
!88 = !DILocation(line: 111, column: 3, scope: !73)
!89 = !DILocation(line: 111, column: 14, scope: !73)
!90 = !DILocation(line: 111, column: 13, scope: !73)
!91 = !DILocation(line: 112, column: 3, scope: !73)
!92 = !DILocation(line: 113, column: 35, scope: !73)
!93 = !DILocation(line: 113, column: 33, scope: !73)
!94 = !DILocation(line: 113, column: 50, scope: !73)
!95 = !DILocation(line: 113, column: 48, scope: !73)
!96 = !DILocation(line: 113, column: 3, scope: !73)
!97 = !DILocation(line: 113, column: 31, scope: !73)
!98 = !DILocation(line: 114, column: 3, scope: !73)
!99 = !DILocation(line: 115, column: 27, scope: !73)
!100 = !DILocation(line: 115, column: 3, scope: !73)
!101 = !DILocation(line: 115, column: 46, scope: !73)
!102 = !DILocation(line: 116, column: 56, scope: !73)
!103 = !DILocation(line: 116, column: 73, scope: !73)
!104 = !DILocation(line: 116, column: 3, scope: !73)
!105 = !DILocation(line: 116, column: 54, scope: !73)
!106 = !DILocation(line: 117, column: 3, scope: !73)
!107 = !DILocation(line: 118, column: 3, scope: !73)
!108 = !DILocation(line: 118, column: 21, scope: !73)
!109 = !DILocation(line: 118, column: 29, scope: !73)
!110 = !DILocation(line: 119, column: 3, scope: !73)
!111 = !DILocation(line: 0, scope: !73)
!112 = !DILocation(line: 120, column: 1, scope: !73)
!115 = !DILocation(line: 0, scope: !114)
!158 = !DIFile(filename: "system.pp", directory: "/mnt/c/Users/marce/Documents/GitHub/zos-pascal-llvm/pf5")
; End asmlist al_dwarf_line



; z/OS-Debugger (zdbg-instrument.py)
declare void @FPC_ZOS_DBG_ENTER(ptr)
declare void @FPC_ZOS_DBG_LINE(ptr, i32)
@zdbg.s.0 = internal global [2 x i8] c"R\00", align 1
@zdbg.s.1 = internal global [2 x i8] c"A\00", align 1
@zdbg.s.2 = internal global [8 x i8] c"LONGINT\00", align 1
@zdbg.t.23 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.2, i32 1, i32 4, ptr null, i32 0, i32 0, ptr null }, align 8
@zdbg.s.3 = internal global [2 x i8] c"B\00", align 1
@zdbg.s.4 = internal global [2 x i8] c"C\00", align 1
@zdbg.s.5 = internal global [9 x i8] c"ANSICHAR\00", align 1
@zdbg.t.161 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.5, i32 5, i32 1, ptr null, i32 0, i32 0, ptr null }, align 8
@zdbg.s.6 = internal global [2 x i8] c"?\00", align 1
@zdbg.t.169 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.6, i32 8, i32 8, ptr @zdbg.t.161, i32 8, i32 0, ptr null }, align 8
@zdbg.t.42.f = internal global [3 x { ptr, i32, i32, ptr, i64 }] [{ ptr, i32, i32, ptr, i64 } { ptr @zdbg.s.1, i32 0, i32 0, ptr @zdbg.t.23, i64 0 }, { ptr, i32, i32, ptr, i64 } { ptr @zdbg.s.3, i32 4, i32 0, ptr @zdbg.t.23, i64 0 }, { ptr, i32, i32, ptr, i64 } { ptr @zdbg.s.4, i32 8, i32 0, ptr @zdbg.t.169, i64 0 }], align 8
@zdbg.s.7 = internal global [5 x i8] c"TREC\00", align 1
@zdbg.t.42 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.7, i32 7, i32 16, ptr null, i32 3, i32 0, ptr @zdbg.t.42.f }, align 8
@zdbg.s.8 = internal global [2 x i8] c"S\00", align 1
@zdbg.s.9 = internal global [11 x i8] c"ANSISTRING\00", align 1
@zdbg.t.10 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.9, i32 9, i32 0, ptr null, i32 0, i32 0, ptr null }, align 8
@zdbg.s.10 = internal global [7 x i8] c"ERRORS\00", align 1
@zdbg.s.11 = internal global [2 x i8] c"G\00", align 1
@zdbg.globals = internal global [4 x { ptr, ptr, ptr }] [{ ptr, ptr, ptr } { ptr @zdbg.s.0, ptr @"U_$P$ASMTEST_$$_R", ptr @zdbg.t.42 }, { ptr, ptr, ptr } { ptr @zdbg.s.8, ptr @"U_$P$ASMTEST_$$_S", ptr @zdbg.t.10 }, { ptr, ptr, ptr } { ptr @zdbg.s.10, ptr @"TC_$P$ASMTEST_$$_ERRORS", ptr @zdbg.t.23 }, { ptr, ptr, ptr } { ptr @zdbg.s.11, ptr @"TC_$P$ASMTEST_$$_G", ptr @zdbg.t.23 }], align 8
@zdbg.module = internal global { i32, ptr } { i32 4, ptr @zdbg.globals }, align 8
@zdbg.v.0 = internal global [0 x { ptr, ptr, i32, i32 }] [], align 8
@zdbg.s.12 = internal global [6 x i8] c"PURE3\00", align 1
@zdbg.s.13 = internal global [12 x i8] c"asmtest.pas\00", align 1
@zdbg.f.0 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.12, ptr @zdbg.s.13, i32 0, i32 0, ptr @zdbg.v.0, ptr @zdbg.module }, align 8
@zdbg.s.14 = internal global [5 x i8] c"WHAT\00", align 1
@zdbg.s.15 = internal global [3 x i8] c"OK\00", align 1
@zdbg.s.16 = internal global [8 x i8] c"BOOLEAN\00", align 1
@zdbg.t.12 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.16, i32 4, i32 1, ptr null, i32 0, i32 0, ptr null }, align 8
@zdbg.v.1 = internal global [2 x { ptr, ptr, i32, i32 }] [{ ptr, ptr, i32, i32 } { ptr @zdbg.s.14, ptr @zdbg.t.10, i32 1, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.15, ptr @zdbg.t.12, i32 1, i32 0 }], align 8
@zdbg.s.17 = internal global [6 x i8] c"CHECK\00", align 1
@zdbg.f.1 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.17, ptr @zdbg.s.13, i32 2, i32 0, ptr @zdbg.v.1, ptr @zdbg.module }, align 8
@zdbg.s.18 = internal global [2 x i8] c"X\00", align 1
@zdbg.s.19 = internal global [7 x i8] c"result\00", align 1
@zdbg.v.2 = internal global [2 x { ptr, ptr, i32, i32 }] [{ ptr, ptr, i32, i32 } { ptr @zdbg.s.18, ptr @zdbg.t.23, i32 1, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.19, ptr @zdbg.t.23, i32 0, i32 0 }], align 8
@zdbg.s.20 = internal global [5 x i8] c"ADD1\00", align 1
@zdbg.f.2 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.20, ptr @zdbg.s.13, i32 2, i32 0, ptr @zdbg.v.2, ptr @zdbg.module }, align 8
@zdbg.s.21 = internal global [2 x i8] c"N\00", align 1
@zdbg.v.3 = internal global [3 x { ptr, ptr, i32, i32 }] [{ ptr, ptr, i32, i32 } { ptr @zdbg.s.21, ptr @zdbg.t.23, i32 1, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.19, ptr @zdbg.t.23, i32 0, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.8, ptr @zdbg.t.23, i32 0, i32 0 }], align 8
@zdbg.s.22 = internal global [6 x i8] c"SUMTO\00", align 1
@zdbg.f.3 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.22, ptr @zdbg.s.13, i32 3, i32 0, ptr @zdbg.v.3, ptr @zdbg.module }, align 8
@zdbg.v.4 = internal global [0 x { ptr, ptr, i32, i32 }] [], align 8
@zdbg.s.23 = internal global [10 x i8] c"INCGLOBAL\00", align 1
@zdbg.f.4 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.23, ptr @zdbg.s.13, i32 0, i32 0, ptr @zdbg.v.4, ptr @zdbg.module }, align 8
@zdbg.v.5 = internal global [1 x { ptr, ptr, i32, i32 }] [{ ptr, ptr, i32, i32 } { ptr @zdbg.s.0, ptr @zdbg.t.42, i32 1, i32 0 }], align 8
@zdbg.s.24 = internal global [5 x i8] c"SETB\00", align 1
@zdbg.f.5 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.24, ptr @zdbg.s.13, i32 1, i32 0, ptr @zdbg.v.5, ptr @zdbg.module }, align 8
@zdbg.s.25 = internal global [4 x i8] c"RES\00", align 1
@zdbg.s.26 = internal global [4 x i8] c"SRC\00", align 1
@zdbg.t.50 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.6, i32 8, i32 8, ptr @zdbg.t.161, i32 8, i32 0, ptr null }, align 8
@zdbg.s.27 = internal global [2 x i8] c"T\00", align 1
@zdbg.v.6 = internal global [4 x { ptr, ptr, i32, i32 }] [{ ptr, ptr, i32, i32 } { ptr @zdbg.s.25, ptr @zdbg.t.10, i32 1, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.0, ptr @zdbg.t.42, i32 0, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.26, ptr @zdbg.t.50, i32 0, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.27, ptr @zdbg.t.10, i32 0, i32 0 }], align 8
@zdbg.s.28 = internal global [7 x i8] c"FIELDS\00", align 1
@zdbg.f.6 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.28, ptr @zdbg.s.13, i32 4, i32 0, ptr @zdbg.v.6, ptr @zdbg.module }, align 8
@zdbg.v.7 = internal global [0 x { ptr, ptr, i32, i32 }] [], align 8
@zdbg.s.29 = internal global [6 x i8] c"EMPTY\00", align 1
@zdbg.f.7 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.29, ptr @zdbg.s.13, i32 0, i32 0, ptr @zdbg.v.7, ptr @zdbg.module }, align 8
@zdbg.s.30 = internal global [5 x i8] c"ARGC\00", align 1
@zdbg.s.31 = internal global [5 x i8] c"ARGV\00", align 1
@zdbg.s.32 = internal global [13 x i8] c"char_pointer\00", align 1
@zdbg.t.163 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.32, i32 6, i32 8, ptr @zdbg.t.161, i32 0, i32 0, ptr null }, align 8
@zdbg.t.71 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.6, i32 6, i32 8, ptr @zdbg.t.163, i32 0, i32 0, ptr null }, align 8
@zdbg.s.33 = internal global [5 x i8] c"ARGP\00", align 1
@zdbg.v.8 = internal global [3 x { ptr, ptr, i32, i32 }] [{ ptr, ptr, i32, i32 } { ptr @zdbg.s.30, ptr @zdbg.t.23, i32 1, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.31, ptr @zdbg.t.71, i32 1, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.33, ptr @zdbg.t.71, i32 1, i32 0 }], align 8
@zdbg.s.34 = internal global [5 x i8] c"main\00", align 1
@zdbg.f.8 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.34, ptr @zdbg.s.13, i32 3, i32 0, ptr @zdbg.v.8, ptr @zdbg.module }, align 8
@zdbg.v.9 = internal global [0 x { ptr, ptr, i32, i32 }] [], align 8
@zdbg.s.35 = internal global [11 x i8] c"PASCALMAIN\00", align 1
@zdbg.f.9 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.35, ptr @zdbg.s.13, i32 0, i32 0, ptr @zdbg.v.9, ptr @zdbg.module }, align 8
@zdbg.v.10 = internal global [0 x { ptr, ptr, i32, i32 }] [], align 8
@zdbg.s.36 = internal global [28 x i8] c"P$ASMTEST_$$_init_implicit$\00", align 1
@zdbg.f.10 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.36, ptr @zdbg.s.13, i32 0, i32 0, ptr @zdbg.v.10, ptr @zdbg.module }, align 8
@zdbg.v.11 = internal global [0 x { ptr, ptr, i32, i32 }] [], align 8
@zdbg.s.37 = internal global [32 x i8] c"P$ASMTEST_$$_finalize_implicit$\00", align 1
@zdbg.f.11 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.37, ptr @zdbg.s.13, i32 0, i32 0, ptr @zdbg.v.11, ptr @zdbg.module }, align 8
