target datalayout = "E-S64-m:l-p1:32:32-i1:8:16-i8:8:16-i64:64-f128:64-v128:64-a:8:16-n32:64"
target triple = "s390x-ibm-zos"
; Begin asmlist al_begin
; Syms - Begin Staticsymtable
; Syms - End Staticsymtable
	%"typ.System.TextRec" = type <{ i32, i32, i64, i64, i64, i64, ptr, ptr, ptr, ptr, ptr, [32 x i8], [256 x i16], [4 x i8], [256 x i8], i16, i8, i8, ptr }>
	%"typ.bt.$ansistrrec1" = type <{ i16, i16, i32, i64, [2 x i8] }>
	%"typ.bt.$llvmstruct$d00000004i32" = type <{ ptr, i32 }>
	%"typ.bt.$ansistrrec15" = type <{ i16, i16, i32, i64, [16 x i8] }>
	%"typ.sysutils.Exception" = type <{ %"typ.System.TObject", ptr, i32, i8, i8, i8, i8 }>
	%"typ.System.TObject" = type <{ ptr }>
	%"typ.bt.$ansistrrec3" = type <{ i16, i16, i32, i64, [4 x i8] }>
	%"typ.bt.$ansistrrec8" = type <{ i16, i16, i32, i64, [9 x i8] }>
	%"typ.bt.$ansistrrec6" = type <{ i16, i16, i32, i64, [7 x i8] }>
	%"typ.bt.$ansistrrec10" = type <{ i16, i16, i32, i64, [11 x i8] }>
	%"typ.bt.$ansistrrec52" = type <{ i16, i16, i32, i64, [53 x i8] }>
	%"typ.sysutils.Exception.$vmtdef" = type <{ i64, i64, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr }>
	%"typ.System.FPC_Unwind_Exception" = type <{ i64, ptr, i64, i64, i64, i64, i64, i64 }>
	%"typ.bt.$ansistrrec60" = type <{ i16, i16, i32, i64, [61 x i8] }>
	%"typ.bt.00000021" = type <{ i64, i64, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr }>
	%"typ.bt.00000022" = type <{ i64, ptr }>
	%"typ.bt.00000023" = type <{ i64, ptr, ptr }>
	%"typ.bt.00000024" = type <{ i64 }>
	%"typ.bt.00000025" = type <{ i64 }>
	%"typ.bt.$rttidef$RTTI_$P$BT_$$_def00000009" = type <{ i8, [1 x i8], %"typ.bt.$rtti_normal_array$1" }>
	%"typ.bt.$rtti_normal_array$1" = type <{ ptr, %"typ.bt.$rtti_normal_array_inner$1" }>
	%"typ.bt.$rtti_normal_array_inner$1" = type <{ i64, i64, ptr, i8, ptr }>
	%"typ.bt.$rttidef$RTTI_$P$BT_$$_def00000015" = type <{ i8, [1 x i8], %"typ.bt.$rtti_normal_array$1" }>
	%"typ.bt.$rttidef$RTTI_$P$BT_$$_def00000019" = type <{ i8, [11 x i8], %"typ.bt.$rtti_normal_array$1" }>
	%"typ.bt.$rttidef$RTTI_$P$BT_$$_def0000001F" = type <{ i8, [1 x i8], %"typ.bt.$rtti_normal_array$1" }>
	%"typ.bt.$rttidef$RTTI_$P$BT_$$_def00000020" = type <{ i8, [1 x i8], %"typ.bt.$rtti_normal_array$1" }>
	%"typ.System.FPC_Unwind_Context" = type <{  }>
	%"typ.System.TVmt" = type <{ i64, i64, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr }>
	%"typ.System.tinterfacetable" = type <{ i64, [1 x %"typ.System.tinterfaceentry"] }>
	%"typ.System.TStringMessageTable" = type <{ i32, i8, i8, i8, i8, [1 x %"typ.System.TMsgStrTable"] }>
	%"typ.System.tinterfaceentry" = type <{ ptr, ptr, i64, i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i8 }>
	%"typ.System.TMsgStrTable" = type <{ ptr, ptr }>
	%"typ.System.TObject.$vmtdef" = type <{ i64, i64, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr }>
	%"typ.System.TGUID" = type <{ i32, i16, i16, [8 x i8] }>
; End asmlist al_begin
; Begin asmlist al_procedures
define hidden void @"P$BT_$$_CHECK$ANSISTRING$BOOLEAN"(ptr %p.what, i8 zeroext %p.ok) nobuiltin null_pointer_is_valid strictfp !dbg !6 {
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
	store ptr @zdbg.f.0, ptr %zdbg.fp, align 8
	%zdbg.vp.0 = getelementptr inbounds { ptr, ptr, i32, i32, [2 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 0
	store ptr %tmp.1, ptr %zdbg.vp.0, align 8
	%zdbg.vp.1 = getelementptr inbounds { ptr, ptr, i32, i32, [2 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 1
	store ptr %tmp.2, ptr %zdbg.vp.1, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r), !dbg !8
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 15), !dbg !8
	store ptr %p.what, ptr %tmp.1, align 8, !dbg !8
	store i8 %p.ok, ptr %tmp.2, align 8, !dbg !8
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 16), !dbg !13
	%reg.1_24 = load i8, ptr %tmp.2, align 8, !dbg !13
	%reg.1_25 = trunc i64 0 to i8, !dbg !13
	%reg.1_26 = icmp ne i8 %reg.1_24, %reg.1_25, !dbg !13
	br i1 %reg.1_26, label %.Lj7, label %.Lj9, !dbg !13
.Lj9:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 16), !dbg !13
	br label %.Lj8, !dbg !13
.Lj7:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 16), !dbg !14
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
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 17), !dbg !16
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
	%reg.1_72 = load i32, ptr @"TC_$P$BT_$$_ERRORS", align 4, !dbg !18
	store i32 %reg.1_72, ptr %tmp.5, align 4, !dbg !18
	%reg.1_73 = load i32, ptr %tmp.5, align 4, !dbg !18
	%reg.1_74 = add i32 %reg.1_73, 1, !dbg !18
	store i32 %reg.1_74, ptr %tmp.5, align 4, !dbg !18
	%reg.1_75 = load i32, ptr %tmp.5, align 4, !dbg !18
	store i32 %reg.1_75, ptr @"TC_$P$BT_$$_ERRORS", align 4, !dbg !18
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 16), !dbg !14
	br label %.Lj10, !dbg !14
.Lj10:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 18), !dbg !19
	br label %.Lj5, !dbg !19
.Lj5:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 18), !dbg !19
	%reg.1_69 = bitcast ptr %tmp.2 to ptr, !dbg !19
	call  void (i64, ptr) @llvm.lifetime.end (i64 1, ptr %reg.1_69), !dbg !19
	%reg.1_77 = bitcast ptr %tmp.5 to ptr, !dbg !19
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_77), !dbg !19
	ret void, !dbg !19
}
define hidden void @"P$BT_$$_CAPTURE_LINES$$ANSISTRING"(ptr sret(ptr) noalias nocapture %p.$result) nobuiltin null_pointer_is_valid strictfp personality ptr @"SYSTEM_$$__FPC_PSABIEH_PERSONALITY_V0$hhyOiwn8_zDM" !dbg !20 {
	%tmp.1 = alloca ptr, align 8, !dbg !21
	%tmp.2 = alloca [32 x ptr], align 8, !dbg !21
	%tmp.3 = alloca i32, align 4, !dbg !21
	%tmp.4 = alloca i32, align 4, !dbg !21
	%tmp.5 = alloca i64, align 8, !dbg !21
	%tmp.6 = alloca i32, align 4, !dbg !21
	%tmp.7 = alloca [3 x ptr], align 8, !dbg !21
	%tmp.8 = alloca ptr, align 8, !dbg !21
	%tmp.9 = alloca [256 x i8], align 1, !dbg !21
	%reg.1_17 = bitcast ptr %tmp.1 to ptr, !dbg !21
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_17), !dbg !21
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.1, metadata !22, metadata !4), !dbg !21
	%reg.1_22 = bitcast ptr %tmp.2 to ptr, !dbg !21
	call  void (i64, ptr) @llvm.lifetime.start (i64 256, ptr %reg.1_22), !dbg !21
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.2, metadata !23, metadata !3), !dbg !21
	%reg.1_27 = bitcast ptr %tmp.3 to ptr, !dbg !21
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_27), !dbg !21
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.3, metadata !25, metadata !3), !dbg !21
	%reg.1_32 = bitcast ptr %tmp.4 to ptr, !dbg !21
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_32), !dbg !21
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.4, metadata !27, metadata !3), !dbg !21
	store ptr %p.$result, ptr %tmp.1, align 8, !dbg !21
	%reg.1_109 = inttoptr i64 0 to ptr, !dbg !21
	store ptr %reg.1_109, ptr %tmp.8, align 8, !dbg !21
	%reg.1_37 = bitcast ptr %tmp.5 to ptr, !dbg !21
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_37), !dbg !21
	%reg.1_38 = bitcast i64 1 to i64, !dbg !21
	%zdbg.r = alloca { ptr, ptr, i32, i32, [4 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [4 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.1, ptr %zdbg.fp, align 8
	%zdbg.vp.0 = getelementptr inbounds { ptr, ptr, i32, i32, [4 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 0
	store ptr %tmp.1, ptr %zdbg.vp.0, align 8
	%zdbg.vp.1 = getelementptr inbounds { ptr, ptr, i32, i32, [4 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 1
	store ptr %tmp.2, ptr %zdbg.vp.1, align 8
	%zdbg.vp.2 = getelementptr inbounds { ptr, ptr, i32, i32, [4 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 2
	store ptr %tmp.3, ptr %zdbg.vp.2, align 8
	%zdbg.vp.3 = getelementptr inbounds { ptr, ptr, i32, i32, [4 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 3
	store ptr %tmp.4, ptr %zdbg.vp.3, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r), !dbg !21
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 25), !dbg !21
	store i64 %reg.1_38, ptr %tmp.5, align 8, !dbg !21
	invoke  void () @"SYSTEM_$$_FPC_DUMMYPOTENTIALRAISE" () to label %.Lj16 unwind label %.Lj15, !dbg !21
.Lj16:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 26), !dbg !28
	%reg.1_39 = getelementptr [32 x ptr], ptr %tmp.2, i32 0, i64 0, !dbg !28
	%reg.1_40 = bitcast ptr %reg.1_39 to ptr, !dbg !29
	%reg.1_41 = bitcast ptr %reg.1_40 to ptr, !dbg !30
	%reg.1_44 = invoke  i64 (i64, i64, ptr) @"SYSTEM_$$_CAPTUREBACKTRACE$INT64$INT64$PCODEPOINTER$$INT64" (i64 0, i64 32, ptr %reg.1_41) to label %.Lj18 unwind label %.Lj15, !dbg !30
.Lj18:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 26), !dbg !30
	%reg.1_45 = bitcast i64 %reg.1_44 to i64, !dbg !30
	%reg.1_47 = bitcast i64 %reg.1_45 to i64, !dbg !30
	%reg.1_46 = trunc i64 %reg.1_47 to i32, !dbg !30
	store i32 %reg.1_46, ptr %tmp.3, align 4, !dbg !31
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 27), !dbg !32
	%reg.1_48 = load ptr, ptr %tmp.1, align 8, !dbg !32
	%reg.1_49 = bitcast ptr %reg.1_48 to ptr, !dbg !33
	%reg.1_50 = inttoptr i64 0 to ptr, !dbg !33
	invoke  void (ptr, ptr) @"fpc_ansistr_assign" (ptr %reg.1_49, ptr %reg.1_50) to label %.Lj19 unwind label %.Lj15, !dbg !33
.Lj19:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 28), !dbg !34
	%reg.1_52 = bitcast ptr %tmp.6 to ptr, !dbg !34
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_52), !dbg !34
	%reg.1_53 = load i32, ptr %tmp.3, align 4, !dbg !35
	%reg.1_54 = sub i32 %reg.1_53, 1, !dbg !35
	store i32 %reg.1_54, ptr %tmp.6, align 4, !dbg !34
	%reg.1_55 = load i32, ptr %tmp.6, align 4, !dbg !34
	%reg.1_56 = icmp sge i32 %reg.1_55, 0, !dbg !34
	%reg.1_57 = zext i1 %reg.1_56 to i8, !dbg !34
	%reg.1_58 = trunc i64 0 to i8, !dbg !34
	%reg.1_59 = icmp ne i8 %reg.1_57, %reg.1_58, !dbg !34
	br i1 %reg.1_59, label %.Lj20, label %.Lj22, !dbg !34
.Lj22:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 28), !dbg !34
	br label %.Lj21, !dbg !34
.Lj20:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 28), !dbg !34
	store i32 -1, ptr %tmp.4, align 4, !dbg !34
	br label %.Lj23, !dbg !34
.Lj23:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 28), !dbg !34
	%reg.1_60 = load i32, ptr %tmp.4, align 4, !dbg !34
	%reg.1_61 = add i32 %reg.1_60, 1, !dbg !34
	store i32 %reg.1_61, ptr %tmp.4, align 4, !dbg !34
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 29), !dbg !36
	%reg.1_63 = load ptr, ptr %tmp.1, align 8, !dbg !36
	%reg.1_64 = load ptr, ptr %reg.1_63, align 8, !dbg !37
	store ptr %reg.1_64, ptr %tmp.7, align 8, !dbg !37
	%reg.1_66 = bitcast ptr %tmp.9 to ptr, !dbg !38
	call  void (i64, ptr) @llvm.lifetime.start (i64 256, ptr %reg.1_66), !dbg !38
	%reg.1_67 = bitcast ptr %tmp.4 to ptr, !dbg !39
	%reg.1_69 = load i32, ptr %reg.1_67, align 4, !dbg !40
	%reg.1_68 = zext i32 %reg.1_69 to i64, !dbg !40
	%reg.1_70 = getelementptr [32 x ptr], ptr %tmp.2, i32 0, i64 %reg.1_68, !dbg !40
	%reg.1_71 = load ptr, ptr %reg.1_70, align 8, !dbg !38
	%reg.1_72 = bitcast ptr %tmp.9 to ptr, !dbg !38
	%reg.1_73 = load ptr, ptr @"TC_$SYSTEM_$$_BACKTRACESTRFUNC", align 8, !dbg !38
	invoke  void (ptr, ptr) %reg.1_73 (ptr sret([256 x i8]) %reg.1_72, ptr %reg.1_71) to label %.Lj26 unwind label %.Lj15, !dbg !38
.Lj26:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 29), !dbg !38
	%reg.1_74 = bitcast ptr %tmp.9 to ptr, !dbg !38
	%reg.1_75 = bitcast ptr %tmp.8 to ptr, !dbg !38
	invoke  void (ptr, ptr, i16) @"fpc_shortstr_to_ansistr" (ptr sret(ptr) %reg.1_75, ptr %reg.1_74, i16 zeroext 0) to label %.Lj27 unwind label %.Lj15, !dbg !38
.Lj27:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 29), !dbg !38
	%reg.1_78 = bitcast ptr %tmp.9 to ptr, !dbg !38
	call  void (i64, ptr) @llvm.lifetime.end (i64 256, ptr %reg.1_78), !dbg !38
	%reg.1_79 = load ptr, ptr %tmp.8, align 8, !dbg !37
	%reg.1_80 = ptrtoint ptr %tmp.7 to i64, !dbg !37
	%reg.1_81 = add i64 %reg.1_80, 8, !dbg !37
	%reg.1_82 = inttoptr i64 %reg.1_81 to ptr, !dbg !37
	store ptr %reg.1_79, ptr %reg.1_82, align 8, !dbg !37
	%reg.1_84 = getelementptr %"typ.bt.$ansistrrec1", ptr @".Ld3", i32 0, i32 4, !dbg !41
	%reg.1_83 = bitcast ptr %reg.1_84 to ptr, !dbg !41
	%reg.1_85 = ptrtoint ptr %tmp.7 to i64, !dbg !37
	%reg.1_86 = add i64 %reg.1_85, 16, !dbg !37
	%reg.1_87 = inttoptr i64 %reg.1_86 to ptr, !dbg !37
	store ptr %reg.1_83, ptr %reg.1_87, align 8, !dbg !37
	%reg.1_88 = bitcast ptr %tmp.7 to ptr, !dbg !37
	%reg.1_89 = load ptr, ptr %tmp.1, align 8, !dbg !42
	%reg.1_90 = bitcast ptr %reg.1_89 to ptr, !dbg !37
	invoke  void (ptr, ptr, i64, i16) @"fpc_ansistr_concat_multi" (ptr %reg.1_90, ptr %reg.1_88, i64 2, i16 zeroext 0) to label %.Lj28 unwind label %.Lj15, !dbg !37
.Lj28:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 28), !dbg !34
	br label %.Lj24, !dbg !34
.Lj24:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 28), !dbg !34
	%reg.1_92 = load i32, ptr %tmp.6, align 4, !dbg !34
	%reg.1_93 = load i32, ptr %tmp.4, align 4, !dbg !34
	%reg.1_94 = icmp sle i32 %reg.1_92, %reg.1_93, !dbg !34
	%reg.1_95 = zext i1 %reg.1_94 to i8, !dbg !34
	%reg.1_96 = trunc i64 0 to i8, !dbg !34
	%reg.1_97 = icmp ne i8 %reg.1_95, %reg.1_96, !dbg !34
	br i1 %reg.1_97, label %.Lj25, label %.Lj29, !dbg !34
.Lj29:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 28), !dbg !34
	br label %.Lj23, !dbg !34
.Lj25:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 28), !dbg !34
	br label %.Lj21, !dbg !34
.Lj21:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 28), !dbg !34
	%reg.1_99 = bitcast ptr %tmp.6 to ptr, !dbg !34
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_99), !dbg !34
	invoke  void () @"SYSTEM_$$_FPC_DUMMYPOTENTIALRAISE" () to label %.Lj30 unwind label %.Lj15, !dbg !43
.Lj30:
	%reg.1_100 = bitcast i64 0 to i64
	store i64 %reg.1_100, ptr %tmp.5, align 8
	br label %.Lj31
.Lj31:
	%reg.1_102 = bitcast ptr %tmp.8 to ptr
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_102), !dbg !43
	%reg.1_103 = load i64, ptr %tmp.5, align 8
	%reg.1_104 = bitcast i64 0 to i64
	%reg.1_105 = icmp eq i64 %reg.1_103, %reg.1_104
	br i1 %reg.1_105, label %.Lj13, label %.Lj32
.Lj32:
	unreachable
	unreachable
.Lj15:
	%reg.1_101 = landingpad %"typ.bt.$llvmstruct$d00000004i32" 	cleanup

	br label %.Lj14
.Lj14:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 30), !dbg !44
	%reg.1_106 = bitcast ptr %tmp.8 to ptr, !dbg !44
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_106), !dbg !44
	resume %"typ.bt.$llvmstruct$d00000004i32" %reg.1_101
	%reg.1_108 = bitcast ptr %tmp.5 to ptr
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_108), !dbg !43
	br label %.Lj13
.Lj13:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 30), !dbg !44
	br label %.Lj11, !dbg !44
.Lj11:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 30), !dbg !44
	%reg.1_111 = bitcast ptr %tmp.2 to ptr, !dbg !44
	call  void (i64, ptr) @llvm.lifetime.end (i64 256, ptr %reg.1_111), !dbg !44
	%reg.1_113 = bitcast ptr %tmp.3 to ptr, !dbg !44
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_113), !dbg !44
	%reg.1_115 = bitcast ptr %tmp.4 to ptr, !dbg !44
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_115), !dbg !44
	%reg.1_117 = bitcast ptr %tmp.1 to ptr, !dbg !44
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_117), !dbg !44
	ret void, !dbg !44
}
define hidden void @"P$BT_$$_LEVEL3$LONGINT"(i32 signext %p.mode) nobuiltin null_pointer_is_valid strictfp personality ptr @"SYSTEM_$$__FPC_PSABIEH_PERSONALITY_V0$hhyOiwn8_zDM" !dbg !45 {
	%tmp.1 = alloca i32, align 8, !dbg !46
	%tmp.2 = alloca i64, align 8, !dbg !46
	%tmp.3 = alloca ptr, align 8, !dbg !46
	%tmp.4 = alloca ptr, align 8, !dbg !46
	%reg.1_17 = bitcast ptr %tmp.1 to ptr, !dbg !46
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_17), !dbg !46
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.1, metadata !47, metadata !3), !dbg !46
	store i32 %p.mode, ptr %tmp.1, align 8, !dbg !46
	%reg.1_89 = inttoptr i64 0 to ptr, !dbg !46
	store ptr %reg.1_89, ptr %tmp.3, align 8, !dbg !46
	%reg.1_22 = bitcast ptr %tmp.2 to ptr, !dbg !46
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_22), !dbg !46
	%reg.1_23 = bitcast i64 1 to i64, !dbg !46
	%zdbg.r = alloca { ptr, ptr, i32, i32, [1 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [1 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.2, ptr %zdbg.fp, align 8
	%zdbg.vp.0 = getelementptr inbounds { ptr, ptr, i32, i32, [1 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 0
	store ptr %tmp.1, ptr %zdbg.vp.0, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r), !dbg !46
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 37), !dbg !46
	store i64 %reg.1_23, ptr %tmp.2, align 8, !dbg !46
	invoke  void () @"SYSTEM_$$_FPC_DUMMYPOTENTIALRAISE" () to label %.Lj38 unwind label %.Lj37, !dbg !46
.Lj38:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 38), !dbg !48
	%reg.1_24 = load i32, ptr %tmp.1, align 8, !dbg !48
	%reg.1_25 = trunc i64 0 to i32, !dbg !48
	%reg.1_26 = icmp eq i32 %reg.1_24, %reg.1_25, !dbg !48
	br i1 %reg.1_26, label %.Lj41, label %.Lj45, !dbg !48
.Lj45:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 38), !dbg !48
	%reg.1_27 = trunc i64 1 to i32, !dbg !48
	%reg.1_28 = icmp eq i32 %reg.1_24, %reg.1_27, !dbg !48
	br i1 %reg.1_28, label %.Lj42, label %.Lj46, !dbg !48
.Lj46:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 38), !dbg !48
	%reg.1_29 = trunc i64 2 to i32, !dbg !48
	%reg.1_30 = icmp eq i32 %reg.1_24, %reg.1_29, !dbg !48
	br i1 %reg.1_30, label %.Lj43, label %.Lj47, !dbg !48
.Lj47:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 38), !dbg !48
	%reg.1_31 = trunc i64 3 to i32, !dbg !48
	%reg.1_32 = icmp eq i32 %reg.1_24, %reg.1_31, !dbg !48
	br i1 %reg.1_32, label %.Lj44, label %.Lj48, !dbg !48
.Lj48:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 38), !dbg !48
	br label %.Lj40, !dbg !48
	br label %.Lj41, !dbg !48
.Lj41:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 39), !dbg !49
	%reg.1_33 = bitcast ptr %tmp.3 to ptr, !dbg !49
	invoke  void (ptr) @"P$BT_$$_CAPTURE_LINES$$ANSISTRING" (ptr sret(ptr) %reg.1_33) to label %.Lj49 unwind label %.Lj37, !dbg !49
.Lj49:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 39), !dbg !50
	%reg.1_34 = load ptr, ptr %tmp.3, align 8, !dbg !50
	%reg.1_35 = bitcast ptr @"U_$P$BT_$$_CAPTURED" to ptr, !dbg !50
	invoke  void (ptr, ptr) @"fpc_ansistr_assign" (ptr %reg.1_35, ptr %reg.1_34) to label %.Lj50 unwind label %.Lj37, !dbg !50
.Lj50:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 39), !dbg !50
	br label %.Lj40, !dbg !50
	br label %.Lj42, !dbg !50
.Lj42:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 40), !dbg !51
	br label %.Lj51, !dbg !51
.Lj51:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 40), !dbg !51
	%reg.1_37 = call  ptr (i32) @llvm.frameaddress (i32 signext 0), !dbg !51
	%reg.1_38 = bitcast ptr %reg.1_37 to ptr, !dbg !51
	%reg.1_39 = bitcast ptr %reg.1_38 to ptr, !dbg !51
	%reg.1_41 = getelementptr %"typ.bt.$ansistrrec15", ptr @".Ld4", i32 0, i32 4, !dbg !52
	%reg.1_40 = bitcast ptr %reg.1_41 to ptr, !dbg !52
	%reg.1_42 = bitcast ptr %reg.1_40 to ptr, !dbg !51
	%reg.1_43 = bitcast ptr @"VMT_$SYSUTILS_$$_EXCEPTION" to ptr, !dbg !53
	%reg.1_44 = bitcast ptr %reg.1_43 to ptr, !dbg !51
	%reg.1_45 = inttoptr i64 1 to ptr, !dbg !51
	%reg.1_46 = invoke  ptr (ptr, ptr, ptr) @"SYSUTILS$_$EXCEPTION_$__$$_CREATE$ANSISTRING$$EXCEPTION" (ptr %reg.1_44, ptr %reg.1_45, ptr %reg.1_42) to label %.Lj52 unwind label %.Lj37, !dbg !51
.Lj52:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 40), !dbg !51
	%reg.1_47 = bitcast ptr %reg.1_46 to ptr, !dbg !51
	%reg.1_48 = bitcast ptr %reg.1_47 to ptr, !dbg !51
	%reg.1_49 = bitcast 	ptr blockaddress(@"P$BT_$$_LEVEL3$LONGINT",%.Lj51) to ptr, !dbg !51
	%reg.1_50 = bitcast ptr %reg.1_49 to ptr, !dbg !51
	%reg.1_51 = inttoptr i64 1 to ptr, !dbg !51
	%reg.1_53 = ptrtoint ptr %reg.1_50 to i64, !dbg !51
	%reg.1_54 = ptrtoint ptr %reg.1_51 to i64, !dbg !51
	%reg.1_55 = add i64 %reg.1_54, %reg.1_53, !dbg !51
	%reg.1_52 = inttoptr i64 %reg.1_55 to ptr, !dbg !51
	%reg.1_56 = trunc i64 0 to i1, !dbg !51
	%reg.1_57 = bitcast ptr %reg.1_52 to ptr, !dbg !51
	invoke  void (ptr, ptr, ptr) @"fpc_raiseexception" (ptr %reg.1_48, ptr %reg.1_57, ptr %reg.1_39) to label %.Lj53 unwind label %.Lj37, !dbg !51
.Lj53:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 40), !dbg !51
	br label %.Lj40, !dbg !51
	br label %.Lj43, !dbg !51
.Lj43:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 41), !dbg !54
	%reg.1_59 = bitcast ptr %tmp.4 to ptr, !dbg !54
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_59), !dbg !54
	%reg.1_60 = invoke  ptr () @"fpc_get_output" () to label %.Lj54 unwind label %.Lj37, !dbg !54
.Lj54:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 41), !dbg !54
	%reg.1_61 = bitcast ptr %reg.1_60 to ptr, !dbg !54
	store ptr %reg.1_61, ptr %tmp.4, align 8, !dbg !54
	%reg.1_63 = load i32, ptr @"TC_$P$BT_$$_ZERO", align 4, !dbg !55
	%reg.1_62 = sext i32 %reg.1_63 to i64, !dbg !55
	%reg.1_64 = bitcast i64 10 to i64, !dbg !56
	%reg.1_65 = bitcast i64 %reg.1_62 to i64, !dbg !56
	%reg.1_66 = bitcast i64 0 to i64, !dbg !56
	%reg.1_67 = icmp ne i64 %reg.1_65, %reg.1_66, !dbg !56
	br i1 %reg.1_67, label %.Lj55, label %.Lj56, !dbg !56
.Lj56:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 41), !dbg !56
	invoke  void () @"fpc_divbyzero" () to label %.Lj57 unwind label %.Lj37, !dbg !56
.Lj57:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 41), !dbg !56
	br label %.Lj55, !dbg !56
.Lj55:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 41), !dbg !56
	%reg.1_68 = sdiv i64 %reg.1_64, %reg.1_65, !dbg !56
	%reg.1_69 = bitcast i64 %reg.1_68 to i64, !dbg !54
	%reg.1_70 = load ptr, ptr %tmp.4, align 8, !dbg !54
	%reg.1_71 = bitcast ptr %reg.1_70 to ptr, !dbg !54
	%reg.1_72 = bitcast ptr %reg.1_71 to ptr, !dbg !54
	invoke  void (i32, ptr, i64) @"fpc_write_text_sint" (i32 signext 0, ptr %reg.1_72, i64 %reg.1_69) to label %.Lj58 unwind label %.Lj37, !dbg !54
.Lj58:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 41), !dbg !54
	invoke  void () @"fpc_iocheck" () to label %.Lj59 unwind label %.Lj37, !dbg !54
.Lj59:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 41), !dbg !54
	%reg.1_74 = load ptr, ptr %tmp.4, align 8, !dbg !54
	%reg.1_75 = bitcast ptr %reg.1_74 to ptr, !dbg !54
	%reg.1_76 = bitcast ptr %reg.1_75 to ptr, !dbg !54
	invoke  void (ptr) @"fpc_writeln_end" (ptr %reg.1_76) to label %.Lj60 unwind label %.Lj37, !dbg !54
.Lj60:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 41), !dbg !54
	invoke  void () @"fpc_iocheck" () to label %.Lj61 unwind label %.Lj37, !dbg !54
.Lj61:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 41), !dbg !54
	%reg.1_78 = bitcast ptr %tmp.4 to ptr, !dbg !54
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_78), !dbg !54
	br label %.Lj40, !dbg !54
	br label %.Lj44, !dbg !54
.Lj44:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 42), !dbg !57
	invoke  void (i16) @"SYSTEM_$$_RUNERROR$WORD" (i16 zeroext 201) to label %.Lj62 unwind label %.Lj37, !dbg !57
.Lj62:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 42), !dbg !57
	br label %.Lj40, !dbg !57
	br label %.Lj40, !dbg !57
.Lj40:
	invoke  void () @"SYSTEM_$$_FPC_DUMMYPOTENTIALRAISE" () to label %.Lj63 unwind label %.Lj37, !dbg !58
.Lj63:
	%reg.1_80 = bitcast i64 0 to i64
	store i64 %reg.1_80, ptr %tmp.2, align 8
	br label %.Lj64
.Lj64:
	%reg.1_82 = bitcast ptr %tmp.3 to ptr
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_82), !dbg !58
	%reg.1_83 = load i64, ptr %tmp.2, align 8
	%reg.1_84 = bitcast i64 0 to i64
	%reg.1_85 = icmp eq i64 %reg.1_83, %reg.1_84
	br i1 %reg.1_85, label %.Lj35, label %.Lj65
.Lj65:
	unreachable
	unreachable
.Lj37:
	%reg.1_81 = landingpad %"typ.bt.$llvmstruct$d00000004i32" 	cleanup

	br label %.Lj36
.Lj36:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 44), !dbg !59
	%reg.1_86 = bitcast ptr %tmp.3 to ptr, !dbg !59
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_86), !dbg !59
	resume %"typ.bt.$llvmstruct$d00000004i32" %reg.1_81
	%reg.1_88 = bitcast ptr %tmp.2 to ptr
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_88), !dbg !58
	br label %.Lj35
.Lj35:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 44), !dbg !59
	br label %.Lj33, !dbg !59
.Lj33:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 44), !dbg !59
	%reg.1_91 = bitcast ptr %tmp.1 to ptr, !dbg !59
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_91), !dbg !59
	ret void, !dbg !59
}
define hidden void @"P$BT_$$_LEVEL2$LONGINT"(i32 signext %p.mode) nobuiltin null_pointer_is_valid strictfp !dbg !60 {
	%tmp.1 = alloca i32, align 8, !dbg !61
	%reg.1_17 = bitcast ptr %tmp.1 to ptr, !dbg !61
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_17), !dbg !61
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.1, metadata !62, metadata !3), !dbg !61
	%zdbg.r = alloca { ptr, ptr, i32, i32, [1 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [1 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.3, ptr %zdbg.fp, align 8
	%zdbg.vp.0 = getelementptr inbounds { ptr, ptr, i32, i32, [1 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 0
	store ptr %tmp.1, ptr %zdbg.vp.0, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r), !dbg !61
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 47), !dbg !61
	store i32 %p.mode, ptr %tmp.1, align 8, !dbg !61
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 48), !dbg !63
	%reg.1_22 = load i32, ptr %tmp.1, align 8, !dbg !63
	%reg.1_21 = sext i32 %reg.1_22 to i64, !dbg !63
	%reg.1_23 = trunc i64 %reg.1_21 to i32, !dbg !63
	call  void (i32) @"P$BT_$$_LEVEL3$LONGINT" (i32 signext %reg.1_23), !dbg !63
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 49), !dbg !64
	br label %.Lj66, !dbg !64
.Lj66:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 49), !dbg !64
	%reg.1_25 = bitcast ptr %tmp.1 to ptr, !dbg !64
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_25), !dbg !64
	ret void, !dbg !64
}
define hidden void @"P$BT_$$_LEVEL1$LONGINT"(i32 signext %p.mode) nobuiltin null_pointer_is_valid strictfp !dbg !65 {
	%tmp.1 = alloca i32, align 8, !dbg !66
	%reg.1_17 = bitcast ptr %tmp.1 to ptr, !dbg !66
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_17), !dbg !66
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.1, metadata !67, metadata !3), !dbg !66
	%zdbg.r = alloca { ptr, ptr, i32, i32, [1 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [1 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.4, ptr %zdbg.fp, align 8
	%zdbg.vp.0 = getelementptr inbounds { ptr, ptr, i32, i32, [1 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 0
	store ptr %tmp.1, ptr %zdbg.vp.0, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r), !dbg !66
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 52), !dbg !66
	store i32 %p.mode, ptr %tmp.1, align 8, !dbg !66
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 53), !dbg !68
	%reg.1_22 = load i32, ptr %tmp.1, align 8, !dbg !68
	%reg.1_21 = sext i32 %reg.1_22 to i64, !dbg !68
	%reg.1_23 = trunc i64 %reg.1_21 to i32, !dbg !68
	call  void (i32) @"P$BT_$$_LEVEL2$LONGINT" (i32 signext %reg.1_23), !dbg !68
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 54), !dbg !69
	br label %.Lj68, !dbg !69
.Lj68:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 54), !dbg !69
	%reg.1_25 = bitcast ptr %tmp.1 to ptr, !dbg !69
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_25), !dbg !69
	ret void, !dbg !69
}
define hidden void @"P$BT_$$_EXCEPTION_TRACE$$ANSISTRING"(ptr sret(ptr) noalias nocapture %p.$result) nobuiltin null_pointer_is_valid strictfp personality ptr @"SYSTEM_$$__FPC_PSABIEH_PERSONALITY_V0$hhyOiwn8_zDM" !dbg !70 {
	%tmp.1 = alloca ptr, align 8, !dbg !71
	%tmp.2 = alloca i32, align 4, !dbg !71
	%tmp.3 = alloca ptr, align 8, !dbg !71
	%tmp.4 = alloca i64, align 8, !dbg !71
	%tmp.5 = alloca [256 x i8], align 1, !dbg !71
	%tmp.6 = alloca [256 x i8], align 1, !dbg !71
	%tmp.7 = alloca i32, align 4, !dbg !71
	%tmp.8 = alloca [3 x ptr], align 8, !dbg !71
	%tmp.9 = alloca ptr, align 8, !dbg !71
	%tmp.10 = alloca [256 x i8], align 1, !dbg !71
	%reg.1_17 = bitcast ptr %tmp.1 to ptr, !dbg !71
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_17), !dbg !71
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.1, metadata !72, metadata !4), !dbg !71
	%reg.1_22 = bitcast ptr %tmp.2 to ptr, !dbg !71
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_22), !dbg !71
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.2, metadata !73, metadata !3), !dbg !71
	%reg.1_27 = bitcast ptr %tmp.3 to ptr, !dbg !71
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_27), !dbg !71
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.3, metadata !74, metadata !3), !dbg !71
	store ptr %p.$result, ptr %tmp.1, align 8, !dbg !71
	%reg.1_118 = inttoptr i64 0 to ptr, !dbg !71
	store ptr %reg.1_118, ptr %tmp.9, align 8, !dbg !71
	%reg.1_32 = bitcast ptr %tmp.4 to ptr, !dbg !71
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_32), !dbg !71
	%reg.1_33 = bitcast i64 1 to i64, !dbg !71
	%zdbg.r = alloca { ptr, ptr, i32, i32, [3 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [3 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.5, ptr %zdbg.fp, align 8
	%zdbg.vp.0 = getelementptr inbounds { ptr, ptr, i32, i32, [3 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 0
	store ptr %tmp.1, ptr %zdbg.vp.0, align 8
	%zdbg.vp.1 = getelementptr inbounds { ptr, ptr, i32, i32, [3 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 1
	store ptr %tmp.2, ptr %zdbg.vp.1, align 8
	%zdbg.vp.2 = getelementptr inbounds { ptr, ptr, i32, i32, [3 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 2
	store ptr %tmp.3, ptr %zdbg.vp.2, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r), !dbg !71
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 60), !dbg !71
	store i64 %reg.1_33, ptr %tmp.4, align 8, !dbg !71
	invoke  void () @"SYSTEM_$$_FPC_DUMMYPOTENTIALRAISE" () to label %.Lj75 unwind label %.Lj74, !dbg !71
.Lj75:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 61), !dbg !76
	%reg.1_35 = bitcast ptr %tmp.5 to ptr, !dbg !76
	call  void (i64, ptr) @llvm.lifetime.start (i64 256, ptr %reg.1_35), !dbg !76
	%reg.1_36 = bitcast ptr @".Ld5" to ptr, !dbg !76
	%reg.1_37 = bitcast ptr %reg.1_36 to ptr, !dbg !76
	%reg.1_39 = bitcast ptr %tmp.6 to ptr, !dbg !77
	call  void (i64, ptr) @llvm.lifetime.start (i64 256, ptr %reg.1_39), !dbg !77
	%reg.1_40 = invoke  ptr () @"SYSUTILS_$$_EXCEPTADDR$$POINTER" () to label %.Lj77 unwind label %.Lj74, !dbg !78
.Lj77:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 61), !dbg !78
	%reg.1_41 = bitcast ptr %reg.1_40 to ptr, !dbg !78
	%reg.1_42 = bitcast ptr %reg.1_41 to ptr, !dbg !76
	%reg.1_43 = bitcast ptr %tmp.6 to ptr, !dbg !76
	%reg.1_44 = load ptr, ptr @"TC_$SYSTEM_$$_BACKTRACESTRFUNC", align 8, !dbg !76
	invoke  void (ptr, ptr) %reg.1_44 (ptr sret([256 x i8]) %reg.1_43, ptr %reg.1_42) to label %.Lj78 unwind label %.Lj74, !dbg !76
.Lj78:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 61), !dbg !76
	%reg.1_45 = bitcast ptr %tmp.6 to ptr, !dbg !76
	%reg.1_46 = bitcast ptr %tmp.5 to ptr, !dbg !76
	invoke  void (ptr, i64, ptr, ptr) @"fpc_shortstr_concat" (ptr %reg.1_46, i64 255, ptr %reg.1_45, ptr %reg.1_37) to label %.Lj79 unwind label %.Lj74, !dbg !76
.Lj79:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 61), !dbg !76
	%reg.1_49 = bitcast ptr %tmp.6 to ptr, !dbg !76
	call  void (i64, ptr) @llvm.lifetime.end (i64 256, ptr %reg.1_49), !dbg !76
	%reg.1_50 = bitcast ptr %tmp.5 to ptr, !dbg !76
	%reg.1_51 = load ptr, ptr %tmp.1, align 8, !dbg !79
	%reg.1_52 = bitcast ptr %reg.1_51 to ptr, !dbg !76
	invoke  void (ptr, ptr, i16) @"fpc_shortstr_to_ansistr" (ptr sret(ptr) %reg.1_52, ptr %reg.1_50, i16 zeroext 0) to label %.Lj80 unwind label %.Lj74, !dbg !76
.Lj80:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 61), !dbg !76
	%reg.1_55 = bitcast ptr %tmp.5 to ptr, !dbg !76
	call  void (i64, ptr) @llvm.lifetime.end (i64 256, ptr %reg.1_55), !dbg !76
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 62), !dbg !80
	%reg.1_56 = invoke  ptr () @"SYSUTILS_$$_EXCEPTFRAMES$$PCODEPOINTER" () to label %.Lj81 unwind label %.Lj74, !dbg !80
.Lj81:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 62), !dbg !80
	%reg.1_57 = bitcast ptr %reg.1_56 to ptr, !dbg !80
	store ptr %reg.1_57, ptr %tmp.3, align 8, !dbg !81
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 63), !dbg !82
	%reg.1_59 = bitcast ptr %tmp.7 to ptr, !dbg !82
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_59), !dbg !82
	%reg.1_60 = invoke  i32 () @"SYSUTILS_$$_EXCEPTFRAMECOUNT$$LONGINT" () to label %.Lj82 unwind label %.Lj74, !dbg !83
.Lj82:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 63), !dbg !83
	%reg.1_61 = bitcast i32 %reg.1_60 to i32, !dbg !83
	%reg.1_62 = sub i32 %reg.1_61, 1, !dbg !84
	store i32 %reg.1_62, ptr %tmp.7, align 4, !dbg !82
	%reg.1_63 = load i32, ptr %tmp.7, align 4, !dbg !82
	%reg.1_64 = icmp sge i32 %reg.1_63, 0, !dbg !82
	%reg.1_65 = zext i1 %reg.1_64 to i8, !dbg !82
	%reg.1_66 = trunc i64 0 to i8, !dbg !82
	%reg.1_67 = icmp ne i8 %reg.1_65, %reg.1_66, !dbg !82
	br i1 %reg.1_67, label %.Lj83, label %.Lj85, !dbg !82
.Lj85:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 63), !dbg !82
	br label %.Lj84, !dbg !82
.Lj83:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 63), !dbg !82
	store i32 -1, ptr %tmp.2, align 4, !dbg !82
	br label %.Lj86, !dbg !82
.Lj86:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 63), !dbg !82
	%reg.1_68 = load i32, ptr %tmp.2, align 4, !dbg !82
	%reg.1_69 = add i32 %reg.1_68, 1, !dbg !82
	store i32 %reg.1_69, ptr %tmp.2, align 4, !dbg !82
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 64), !dbg !85
	%reg.1_71 = load ptr, ptr %tmp.1, align 8, !dbg !85
	%reg.1_72 = load ptr, ptr %reg.1_71, align 8, !dbg !86
	store ptr %reg.1_72, ptr %tmp.8, align 8, !dbg !86
	%reg.1_74 = bitcast ptr %tmp.10 to ptr, !dbg !87
	call  void (i64, ptr) @llvm.lifetime.start (i64 256, ptr %reg.1_74), !dbg !87
	%reg.1_75 = load ptr, ptr %tmp.3, align 8, !dbg !88
	%reg.1_76 = bitcast ptr %reg.1_75 to ptr, !dbg !88
	%reg.1_78 = load i32, ptr %tmp.2, align 4, !dbg !89
	%reg.1_77 = sext i32 %reg.1_78 to i64, !dbg !89
	%reg.1_79 = getelementptr [1152921504606846975 x ptr], ptr %reg.1_76, i32 0, i64 %reg.1_77, !dbg !90
	%reg.1_80 = load ptr, ptr %reg.1_79, align 8, !dbg !87
	%reg.1_81 = bitcast ptr %tmp.10 to ptr, !dbg !87
	%reg.1_82 = load ptr, ptr @"TC_$SYSTEM_$$_BACKTRACESTRFUNC", align 8, !dbg !87
	invoke  void (ptr, ptr) %reg.1_82 (ptr sret([256 x i8]) %reg.1_81, ptr %reg.1_80) to label %.Lj89 unwind label %.Lj74, !dbg !87
.Lj89:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 64), !dbg !87
	%reg.1_83 = bitcast ptr %tmp.10 to ptr, !dbg !87
	%reg.1_84 = bitcast ptr %tmp.9 to ptr, !dbg !87
	invoke  void (ptr, ptr, i16) @"fpc_shortstr_to_ansistr" (ptr sret(ptr) %reg.1_84, ptr %reg.1_83, i16 zeroext 0) to label %.Lj90 unwind label %.Lj74, !dbg !87
.Lj90:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 64), !dbg !87
	%reg.1_87 = bitcast ptr %tmp.10 to ptr, !dbg !87
	call  void (i64, ptr) @llvm.lifetime.end (i64 256, ptr %reg.1_87), !dbg !87
	%reg.1_88 = load ptr, ptr %tmp.9, align 8, !dbg !86
	%reg.1_89 = ptrtoint ptr %tmp.8 to i64, !dbg !86
	%reg.1_90 = add i64 %reg.1_89, 8, !dbg !86
	%reg.1_91 = inttoptr i64 %reg.1_90 to ptr, !dbg !86
	store ptr %reg.1_88, ptr %reg.1_91, align 8, !dbg !86
	%reg.1_93 = getelementptr %"typ.bt.$ansistrrec1", ptr @".Ld3", i32 0, i32 4, !dbg !91
	%reg.1_92 = bitcast ptr %reg.1_93 to ptr, !dbg !91
	%reg.1_94 = ptrtoint ptr %tmp.8 to i64, !dbg !86
	%reg.1_95 = add i64 %reg.1_94, 16, !dbg !86
	%reg.1_96 = inttoptr i64 %reg.1_95 to ptr, !dbg !86
	store ptr %reg.1_92, ptr %reg.1_96, align 8, !dbg !86
	%reg.1_97 = bitcast ptr %tmp.8 to ptr, !dbg !86
	%reg.1_98 = load ptr, ptr %tmp.1, align 8, !dbg !92
	%reg.1_99 = bitcast ptr %reg.1_98 to ptr, !dbg !86
	invoke  void (ptr, ptr, i64, i16) @"fpc_ansistr_concat_multi" (ptr %reg.1_99, ptr %reg.1_97, i64 2, i16 zeroext 0) to label %.Lj91 unwind label %.Lj74, !dbg !86
.Lj91:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 63), !dbg !82
	br label %.Lj87, !dbg !82
.Lj87:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 63), !dbg !82
	%reg.1_101 = load i32, ptr %tmp.7, align 4, !dbg !82
	%reg.1_102 = load i32, ptr %tmp.2, align 4, !dbg !82
	%reg.1_103 = icmp sle i32 %reg.1_101, %reg.1_102, !dbg !82
	%reg.1_104 = zext i1 %reg.1_103 to i8, !dbg !82
	%reg.1_105 = trunc i64 0 to i8, !dbg !82
	%reg.1_106 = icmp ne i8 %reg.1_104, %reg.1_105, !dbg !82
	br i1 %reg.1_106, label %.Lj88, label %.Lj92, !dbg !82
.Lj92:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 63), !dbg !82
	br label %.Lj86, !dbg !82
.Lj88:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 63), !dbg !82
	br label %.Lj84, !dbg !82
.Lj84:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 63), !dbg !82
	%reg.1_108 = bitcast ptr %tmp.7 to ptr, !dbg !82
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_108), !dbg !82
	invoke  void () @"SYSTEM_$$_FPC_DUMMYPOTENTIALRAISE" () to label %.Lj93 unwind label %.Lj74, !dbg !93
.Lj93:
	%reg.1_109 = bitcast i64 0 to i64
	store i64 %reg.1_109, ptr %tmp.4, align 8
	br label %.Lj94
.Lj94:
	%reg.1_111 = bitcast ptr %tmp.9 to ptr
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_111), !dbg !93
	%reg.1_112 = load i64, ptr %tmp.4, align 8
	%reg.1_113 = bitcast i64 0 to i64
	%reg.1_114 = icmp eq i64 %reg.1_112, %reg.1_113
	br i1 %reg.1_114, label %.Lj72, label %.Lj95
.Lj95:
	unreachable
	unreachable
.Lj74:
	%reg.1_110 = landingpad %"typ.bt.$llvmstruct$d00000004i32" 	cleanup

	br label %.Lj73
.Lj73:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 65), !dbg !94
	%reg.1_115 = bitcast ptr %tmp.9 to ptr, !dbg !94
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_115), !dbg !94
	resume %"typ.bt.$llvmstruct$d00000004i32" %reg.1_110
	%reg.1_117 = bitcast ptr %tmp.4 to ptr
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_117), !dbg !93
	br label %.Lj72
.Lj72:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 65), !dbg !94
	br label %.Lj70, !dbg !94
.Lj70:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 65), !dbg !94
	%reg.1_120 = bitcast ptr %tmp.2 to ptr, !dbg !94
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_120), !dbg !94
	%reg.1_122 = bitcast ptr %tmp.3 to ptr, !dbg !94
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_122), !dbg !94
	%reg.1_124 = bitcast ptr %tmp.1 to ptr, !dbg !94
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_124), !dbg !94
	ret void, !dbg !94
}
define hidden zeroext i8 @"P$BT_$$_HAS_ORDER$ANSISTRING$array_of_ANSISTRING$$BOOLEAN"(ptr %p.s, ptr nocapture %p.names, i64 %p.$highNAMES) nobuiltin null_pointer_is_valid strictfp !dbg !95 {
	%tmp.1 = alloca ptr, align 8, !dbg !96
	%tmp.2 = alloca ptr, align 8, !dbg !96
	%tmp.3 = alloca i64, align 8, !dbg !96
	%tmp.4 = alloca i8, align 4, !dbg !96
	%tmp.5 = alloca i32, align 4, !dbg !96
	%tmp.6 = alloca i32, align 4, !dbg !96
	%tmp.7 = alloca i32, align 4, !dbg !96
	%tmp.8 = alloca i32, align 4, !dbg !96
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.1, metadata !97, metadata !3), !dbg !96
	%reg.1_20 = bitcast ptr %tmp.2 to ptr, !dbg !96
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_20), !dbg !96
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.2, metadata !98, metadata !4), !dbg !96
	%reg.1_25 = bitcast ptr %tmp.3 to ptr, !dbg !96
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_25), !dbg !96
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.3, metadata !100, metadata !3), !dbg !96
	%reg.1_30 = bitcast ptr %tmp.4 to ptr, !dbg !96
	call  void (i64, ptr) @llvm.lifetime.start (i64 1, ptr %reg.1_30), !dbg !96
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.4, metadata !102, metadata !3), !dbg !96
	%reg.1_35 = bitcast ptr %tmp.5 to ptr, !dbg !96
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_35), !dbg !96
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.5, metadata !103, metadata !3), !dbg !96
	%reg.1_40 = bitcast ptr %tmp.6 to ptr, !dbg !96
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_40), !dbg !96
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.6, metadata !104, metadata !3), !dbg !96
	%reg.1_45 = bitcast ptr %tmp.7 to ptr, !dbg !96
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_45), !dbg !96
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.7, metadata !105, metadata !3), !dbg !96
	store ptr %p.s, ptr %tmp.1, align 8, !dbg !96
	store ptr %p.names, ptr %tmp.2, align 8, !dbg !96
	store i64 %p.$highNAMES, ptr %tmp.3, align 8, !dbg !96
	store i8 1, ptr %tmp.4, align 4, !dbg !106
	store i32 0, ptr %tmp.6, align 4, !dbg !107
	%reg.1_50 = bitcast ptr %tmp.8 to ptr, !dbg !108
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_50), !dbg !108
	%reg.1_51 = bitcast ptr %tmp.3 to ptr, !dbg !109
	%zdbg.r = alloca { ptr, ptr, i32, i32, [7 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [7 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.6, ptr %zdbg.fp, align 8
	%zdbg.vp.0 = getelementptr inbounds { ptr, ptr, i32, i32, [7 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 0
	store ptr %tmp.1, ptr %zdbg.vp.0, align 8
	%zdbg.vp.1 = getelementptr inbounds { ptr, ptr, i32, i32, [7 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 1
	store ptr %tmp.2, ptr %zdbg.vp.1, align 8
	%zdbg.vp.2 = getelementptr inbounds { ptr, ptr, i32, i32, [7 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 2
	store ptr %tmp.3, ptr %zdbg.vp.2, align 8
	%zdbg.vp.3 = getelementptr inbounds { ptr, ptr, i32, i32, [7 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 3
	store ptr %tmp.4, ptr %zdbg.vp.3, align 8
	%zdbg.vp.4 = getelementptr inbounds { ptr, ptr, i32, i32, [7 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 4
	store ptr %tmp.5, ptr %zdbg.vp.4, align 8
	%zdbg.vp.5 = getelementptr inbounds { ptr, ptr, i32, i32, [7 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 5
	store ptr %tmp.6, ptr %zdbg.vp.5, align 8
	%zdbg.vp.6 = getelementptr inbounds { ptr, ptr, i32, i32, [7 x ptr] }, ptr %zdbg.r, i32 0, i32 4, i32 6
	store ptr %tmp.7, ptr %zdbg.vp.6, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r), !dbg !96
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 73), !dbg !108
	%reg.1_53 = ptrtoint ptr %reg.1_51 to i64, !dbg !108
	%reg.1_54 = add i64 %reg.1_53, 4, !dbg !108
	%reg.1_55 = inttoptr i64 %reg.1_54 to ptr, !dbg !108
	%reg.1_52 = load i32, ptr %reg.1_55, align 4, !dbg !108
	store i32 %reg.1_52, ptr %tmp.8, align 4, !dbg !108
	%reg.1_56 = load i32, ptr %tmp.8, align 4, !dbg !108
	%reg.1_57 = icmp sge i32 %reg.1_56, 0, !dbg !108
	%reg.1_58 = zext i1 %reg.1_57 to i8, !dbg !108
	%reg.1_59 = trunc i64 0 to i8, !dbg !108
	%reg.1_60 = icmp ne i8 %reg.1_58, %reg.1_59, !dbg !108
	br i1 %reg.1_60, label %.Lj98, label %.Lj100, !dbg !108
.Lj100:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 73), !dbg !108
	br label %.Lj99, !dbg !108
.Lj98:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 73), !dbg !108
	store i32 -1, ptr %tmp.5, align 4, !dbg !108
	br label %.Lj101, !dbg !108
.Lj101:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 73), !dbg !108
	%reg.1_61 = load i32, ptr %tmp.5, align 4, !dbg !108
	%reg.1_62 = add i32 %reg.1_61, 1, !dbg !108
	store i32 %reg.1_62, ptr %tmp.5, align 4, !dbg !108
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 75), !dbg !110
	%reg.1_63 = load ptr, ptr %tmp.2, align 8, !dbg !110
	%reg.1_65 = load i32, ptr %tmp.5, align 4, !dbg !111
	%reg.1_64 = sext i32 %reg.1_65 to i64, !dbg !111
	%reg.1_66 = getelementptr [0 x ptr], ptr %reg.1_63, i32 0, i64 %reg.1_64, !dbg !112
	%reg.1_67 = load ptr, ptr %reg.1_66, align 8, !dbg !113
	%reg.1_69 = load ptr, ptr %tmp.1, align 8, !dbg !113
	%reg.1_70 = call  i64 (ptr, ptr, i64) @"SYSTEM_$$_POS$RAWBYTESTRING$RAWBYTESTRING$INT64$$INT64" (ptr %reg.1_67, ptr %reg.1_69, i64 1), !dbg !113
	%reg.1_71 = bitcast i64 %reg.1_70 to i64, !dbg !113
	%reg.1_73 = bitcast i64 %reg.1_71 to i64, !dbg !113
	%reg.1_72 = trunc i64 %reg.1_73 to i32, !dbg !113
	store i32 %reg.1_72, ptr %tmp.7, align 4, !dbg !114
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 76), !dbg !115
	%reg.1_74 = load i32, ptr %tmp.7, align 4, !dbg !115
	%reg.1_75 = icmp eq i32 %reg.1_74, 0, !dbg !115
	%reg.1_76 = zext i1 %reg.1_75 to i8, !dbg !115
	%reg.1_77 = trunc i64 0 to i8, !dbg !115
	%reg.1_78 = icmp ne i8 %reg.1_76, %reg.1_77, !dbg !115
	br i1 %reg.1_78, label %.Lj104, label %.Lj106, !dbg !115
.Lj106:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 76), !dbg !115
	br label %.Lj105, !dbg !115
.Lj105:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 76), !dbg !116
	%reg.1_79 = load i32, ptr %tmp.7, align 4, !dbg !116
	%reg.1_80 = load i32, ptr %tmp.6, align 4, !dbg !116
	%reg.1_81 = icmp slt i32 %reg.1_79, %reg.1_80, !dbg !116
	%reg.1_82 = zext i1 %reg.1_81 to i8, !dbg !116
	%reg.1_83 = trunc i64 0 to i8, !dbg !116
	%reg.1_84 = icmp ne i8 %reg.1_82, %reg.1_83, !dbg !116
	br i1 %reg.1_84, label %.Lj104, label %.Lj108, !dbg !116
.Lj108:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 76), !dbg !116
	br label %.Lj107, !dbg !116
.Lj104:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 77), !dbg !117
	store i8 0, ptr %tmp.4, align 4, !dbg !117
	br label %.Lj96, !dbg !118
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 76), !dbg !119
	br label %.Lj107, !dbg !119
.Lj107:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 78), !dbg !120
	%reg.1_85 = load i32, ptr %tmp.7, align 4, !dbg !120
	store i32 %reg.1_85, ptr %tmp.6, align 4, !dbg !120
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 73), !dbg !108
	br label %.Lj102, !dbg !108
.Lj102:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 73), !dbg !108
	%reg.1_86 = load i32, ptr %tmp.8, align 4, !dbg !108
	%reg.1_87 = load i32, ptr %tmp.5, align 4, !dbg !108
	%reg.1_88 = icmp sle i32 %reg.1_86, %reg.1_87, !dbg !108
	%reg.1_89 = zext i1 %reg.1_88 to i8, !dbg !108
	%reg.1_90 = trunc i64 0 to i8, !dbg !108
	%reg.1_91 = icmp ne i8 %reg.1_89, %reg.1_90, !dbg !108
	br i1 %reg.1_91, label %.Lj103, label %.Lj109, !dbg !108
.Lj109:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 73), !dbg !108
	br label %.Lj101, !dbg !108
.Lj103:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 73), !dbg !108
	br label %.Lj99, !dbg !108
.Lj99:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 73), !dbg !108
	%reg.1_93 = bitcast ptr %tmp.8 to ptr, !dbg !108
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_93), !dbg !108
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 80), !dbg !121
	br label %.Lj96, !dbg !121
.Lj96:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 80), !dbg !121
	%reg.1_95 = bitcast ptr %tmp.5 to ptr, !dbg !121
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_95), !dbg !121
	%reg.1_97 = bitcast ptr %tmp.6 to ptr, !dbg !121
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_97), !dbg !121
	%reg.1_99 = bitcast ptr %tmp.7 to ptr, !dbg !121
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_99), !dbg !121
	%reg.1_101 = bitcast ptr %tmp.2 to ptr, !dbg !121
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_101), !dbg !121
	%reg.1_103 = bitcast ptr %tmp.3 to ptr, !dbg !121
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_103), !dbg !121
	%reg.1_3 = load i8, ptr %tmp.4, align 4, !dbg !121
	%reg.1_105 = bitcast ptr %tmp.4 to ptr, !dbg !121
	call  void (i64, ptr) @llvm.lifetime.end (i64 1, ptr %reg.1_105), !dbg !121
	ret i8 %reg.1_3, !dbg !121
}
define hidden void @"main"(i32 signext %p.ARGC, ptr %p.ARGV, ptr %p.ARGP) nobuiltin null_pointer_is_valid strictfp !dbg !122 {
	%tmp.1 = alloca i32, align 8
	%tmp.2 = alloca ptr, align 8
	%tmp.3 = alloca ptr, align 8
	%reg.1_17 = bitcast ptr %tmp.1 to ptr
	call  void (i64, ptr) @llvm.lifetime.start (i64 4, ptr %reg.1_17), !dbg !123
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.1, metadata !124, metadata !3), !dbg !123
	%reg.1_22 = bitcast ptr %tmp.2 to ptr
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_22), !dbg !123
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.2, metadata !125, metadata !3), !dbg !123
	%reg.1_27 = bitcast ptr %tmp.3 to ptr
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_27), !dbg !123
	call  void (metadata, metadata, metadata) @llvm.dbg.declare (metadata ptr %tmp.3, metadata !127, metadata !3), !dbg !123
	%zdbg.r = alloca { ptr, ptr, i32, i32, [3 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [3 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.7, ptr %zdbg.fp, align 8
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
	call  void (i32, ptr, ptr) @"FPC_SYSTEMMAIN" (i32 signext %reg.1_35, ptr %reg.1_32, ptr %reg.1_31), !dbg !123
	br label %.Lj110
.Lj110:
	%reg.1_37 = bitcast ptr %tmp.1 to ptr
	call  void (i64, ptr) @llvm.lifetime.end (i64 4, ptr %reg.1_37), !dbg !123
	%reg.1_39 = bitcast ptr %tmp.2 to ptr
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_39), !dbg !123
	%reg.1_41 = bitcast ptr %tmp.3 to ptr
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_41), !dbg !123
	ret void
}
define hidden void @"PASCALMAIN"() nobuiltin noreturn null_pointer_is_valid strictfp personality ptr @"SYSTEM_$$__FPC_PSABIEH_PERSONALITY_V0$hhyOiwn8_zDM" !dbg !128 {
	%tmp.1 = alloca i64, align 8, !dbg !129
	%tmp.2 = alloca ptr, align 8, !dbg !129
	%tmp.3 = alloca ptr, align 8, !dbg !129
	%tmp.4 = alloca ptr, align 8, !dbg !129
	%tmp.5 = alloca [4 x ptr], align 8, !dbg !129
	%tmp.6 = alloca i64, align 8, !dbg !129
	%tmp.7 = alloca ptr, align 8, !dbg !129
	%tmp.8 = alloca i64, align 8, !dbg !129
	%tmp.9 = alloca ptr, align 8, !dbg !129
	%tmp.10 = alloca ptr, align 8, !dbg !129
	%tmp.11 = alloca [4 x ptr], align 8, !dbg !129
	%tmp.12 = alloca ptr, align 8, !dbg !129
	call  void () @"fpc_initializeunits" (), !dbg !129
	%reg.1_208 = inttoptr i64 0 to ptr, !dbg !129
	store ptr %reg.1_208, ptr %tmp.9, align 8, !dbg !129
	%reg.1_209 = inttoptr i64 0 to ptr, !dbg !129
	store ptr %reg.1_209, ptr %tmp.3, align 8, !dbg !129
	%reg.1_210 = inttoptr i64 0 to ptr, !dbg !129
	store ptr %reg.1_210, ptr %tmp.2, align 8, !dbg !129
	%reg.1_17 = bitcast ptr %tmp.1 to ptr, !dbg !129
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_17), !dbg !129
	%reg.1_18 = bitcast i64 1 to i64, !dbg !129
	%zdbg.r = alloca { ptr, ptr, i32, i32, [1 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [1 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.8, ptr %zdbg.fp, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r), !dbg !129
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 82), !dbg !129
	store i64 %reg.1_18, ptr %tmp.1, align 8, !dbg !129
	invoke  void () @"SYSTEM_$$_FPC_DUMMYPOTENTIALRAISE" () to label %.Lj119 unwind label %.Lj118, !dbg !129
.Lj119:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 83), !dbg !130
	%reg.1_19 = bitcast ptr %tmp.2 to ptr, !dbg !130
	invoke  void (ptr, i32) @"OBJPAS_$$_PARAMSTR$LONGINT$$ANSISTRING" (ptr sret(ptr) %reg.1_19, i32 signext 1) to label %.Lj121 unwind label %.Lj118, !dbg !130
.Lj121:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 83), !dbg !130
	%reg.1_21 = load ptr, ptr %tmp.2, align 8, !dbg !130
	%reg.1_23 = getelementptr %"typ.bt.$ansistrrec3", ptr @".Ld6", i32 0, i32 4, !dbg !130
	%reg.1_22 = bitcast ptr %reg.1_23 to ptr, !dbg !130
	%reg.1_24 = bitcast ptr %reg.1_22 to ptr, !dbg !130
	%reg.1_25 = invoke  i64 (ptr, ptr) @"fpc_ansistr_compare_equal" (ptr %reg.1_21, ptr %reg.1_24) to label %.Lj122 unwind label %.Lj118, !dbg !130
.Lj122:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 83), !dbg !130
	%reg.1_26 = bitcast i64 %reg.1_25 to i64, !dbg !130
	%reg.1_27 = icmp eq i64 %reg.1_26, 0, !dbg !130
	%reg.1_28 = zext i1 %reg.1_27 to i8, !dbg !130
	%reg.1_29 = trunc i64 0 to i8, !dbg !130
	%reg.1_30 = icmp ne i8 %reg.1_28, %reg.1_29, !dbg !130
	br i1 %reg.1_30, label %.Lj123, label %.Lj125, !dbg !130
.Lj125:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 83), !dbg !130
	br label %.Lj124, !dbg !130
.Lj123:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 84), !dbg !131
	invoke  void (i32) @"P$BT_$$_LEVEL1$LONGINT" (i32 signext 2) to label %.Lj126 unwind label %.Lj118, !dbg !131
.Lj126:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 84), !dbg !131
	br label %.Lj127, !dbg !131
	br label %.Lj124, !dbg !131
.Lj124:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 85), !dbg !132
	%reg.1_32 = bitcast ptr %tmp.3 to ptr, !dbg !132
	invoke  void (ptr, i32) @"OBJPAS_$$_PARAMSTR$LONGINT$$ANSISTRING" (ptr sret(ptr) %reg.1_32, i32 signext 1) to label %.Lj128 unwind label %.Lj118, !dbg !132
.Lj128:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 85), !dbg !132
	%reg.1_34 = load ptr, ptr %tmp.3, align 8, !dbg !132
	%reg.1_36 = getelementptr %"typ.bt.$ansistrrec8", ptr @".Ld7", i32 0, i32 4, !dbg !132
	%reg.1_35 = bitcast ptr %reg.1_36 to ptr, !dbg !132
	%reg.1_37 = bitcast ptr %reg.1_35 to ptr, !dbg !132
	%reg.1_38 = invoke  i64 (ptr, ptr) @"fpc_ansistr_compare_equal" (ptr %reg.1_34, ptr %reg.1_37) to label %.Lj129 unwind label %.Lj118, !dbg !132
.Lj129:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 85), !dbg !132
	%reg.1_39 = bitcast i64 %reg.1_38 to i64, !dbg !132
	%reg.1_40 = icmp eq i64 %reg.1_39, 0, !dbg !132
	%reg.1_41 = zext i1 %reg.1_40 to i8, !dbg !132
	%reg.1_42 = trunc i64 0 to i8, !dbg !132
	%reg.1_43 = icmp ne i8 %reg.1_41, %reg.1_42, !dbg !132
	br i1 %reg.1_43, label %.Lj130, label %.Lj132, !dbg !132
.Lj132:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 85), !dbg !132
	br label %.Lj131, !dbg !132
.Lj130:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 86), !dbg !133
	invoke  void (i32) @"P$BT_$$_LEVEL1$LONGINT" (i32 signext 3) to label %.Lj133 unwind label %.Lj118, !dbg !133
.Lj133:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 86), !dbg !133
	br label %.Lj134, !dbg !133
	br label %.Lj131, !dbg !133
.Lj131:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 89), !dbg !134
	invoke  void (i32) @"P$BT_$$_LEVEL1$LONGINT" (i32 signext 0) to label %.Lj135 unwind label %.Lj118, !dbg !134
.Lj135:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 90), !dbg !135
	%reg.1_47 = bitcast ptr %tmp.4 to ptr, !dbg !135
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_47), !dbg !135
	%reg.1_48 = invoke  ptr () @"fpc_get_output" () to label %.Lj136 unwind label %.Lj118, !dbg !135
.Lj136:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 90), !dbg !135
	%reg.1_49 = bitcast ptr %reg.1_48 to ptr, !dbg !135
	store ptr %reg.1_49, ptr %tmp.4, align 8, !dbg !135
	%reg.1_50 = load ptr, ptr %tmp.4, align 8, !dbg !135
	%reg.1_51 = bitcast ptr %reg.1_50 to ptr, !dbg !135
	%reg.1_52 = bitcast ptr %reg.1_51 to ptr, !dbg !135
	%reg.1_53 = load ptr, ptr @"U_$P$BT_$$_CAPTURED", align 8, !dbg !135
	invoke  void (i32, ptr, ptr) @"fpc_write_text_ansistr" (i32 signext 0, ptr %reg.1_52, ptr %reg.1_53) to label %.Lj137 unwind label %.Lj118, !dbg !135
.Lj137:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 90), !dbg !135
	invoke  void () @"fpc_iocheck" () to label %.Lj138 unwind label %.Lj118, !dbg !135
.Lj138:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 90), !dbg !135
	%reg.1_55 = load ptr, ptr %tmp.4, align 8, !dbg !135
	%reg.1_56 = bitcast ptr %reg.1_55 to ptr, !dbg !135
	%reg.1_57 = bitcast ptr %reg.1_56 to ptr, !dbg !135
	invoke  void (ptr) @"fpc_write_end" (ptr %reg.1_57) to label %.Lj139 unwind label %.Lj118, !dbg !135
.Lj139:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 90), !dbg !135
	invoke  void () @"fpc_iocheck" () to label %.Lj140 unwind label %.Lj118, !dbg !135
.Lj140:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 90), !dbg !135
	%reg.1_59 = bitcast ptr %tmp.4 to ptr, !dbg !135
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_59), !dbg !135
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 92), !dbg !136
	%reg.1_61 = getelementptr %"typ.bt.$ansistrrec6", ptr @".Ld8", i32 0, i32 4, !dbg !136
	%reg.1_60 = bitcast ptr %reg.1_61 to ptr, !dbg !136
	store ptr %reg.1_60, ptr %tmp.5, align 8, !dbg !137
	%reg.1_63 = getelementptr %"typ.bt.$ansistrrec6", ptr @".Ld9", i32 0, i32 4, !dbg !138
	%reg.1_62 = bitcast ptr %reg.1_63 to ptr, !dbg !138
	%reg.1_64 = ptrtoint ptr %tmp.5 to i64, !dbg !137
	%reg.1_65 = add i64 %reg.1_64, 8, !dbg !137
	%reg.1_66 = inttoptr i64 %reg.1_65 to ptr, !dbg !137
	store ptr %reg.1_62, ptr %reg.1_66, align 8, !dbg !137
	%reg.1_68 = getelementptr %"typ.bt.$ansistrrec6", ptr @".Ld10", i32 0, i32 4, !dbg !139
	%reg.1_67 = bitcast ptr %reg.1_68 to ptr, !dbg !139
	%reg.1_69 = ptrtoint ptr %tmp.5 to i64, !dbg !137
	%reg.1_70 = add i64 %reg.1_69, 16, !dbg !137
	%reg.1_71 = inttoptr i64 %reg.1_70 to ptr, !dbg !137
	store ptr %reg.1_67, ptr %reg.1_71, align 8, !dbg !137
	%reg.1_73 = getelementptr %"typ.bt.$ansistrrec10", ptr @".Ld11", i32 0, i32 4, !dbg !140
	%reg.1_72 = bitcast ptr %reg.1_73 to ptr, !dbg !140
	%reg.1_74 = ptrtoint ptr %tmp.5 to i64, !dbg !137
	%reg.1_75 = add i64 %reg.1_74, 24, !dbg !137
	%reg.1_76 = inttoptr i64 %reg.1_75 to ptr, !dbg !137
	store ptr %reg.1_72, ptr %reg.1_76, align 8, !dbg !137
	%reg.1_77 = bitcast ptr %tmp.5 to ptr, !dbg !141
	%reg.1_78 = load ptr, ptr @"U_$P$BT_$$_CAPTURED", align 8, !dbg !141
	%reg.1_80 = invoke  i8 (ptr, ptr, i64) @"P$BT_$$_HAS_ORDER$ANSISTRING$array_of_ANSISTRING$$BOOLEAN" (ptr %reg.1_78, ptr %reg.1_77, i64 3) to label %.Lj141 unwind label %.Lj118, !dbg !141
.Lj141:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 92), !dbg !141
	%reg.1_81 = bitcast i8 %reg.1_80 to i8, !dbg !141
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 91), !dbg !142
	%reg.1_82 = zext i8 %reg.1_81 to i64, !dbg !142
	%reg.1_84 = getelementptr %"typ.bt.$ansistrrec52", ptr @".Ld12", i32 0, i32 4, !dbg !143
	%reg.1_83 = bitcast ptr %reg.1_84 to ptr, !dbg !143
	%reg.1_85 = bitcast ptr %reg.1_83 to ptr, !dbg !142
	%reg.1_86 = trunc i64 %reg.1_82 to i8, !dbg !142
	invoke  void (ptr, i8) @"P$BT_$$_CHECK$ANSISTRING$BOOLEAN" (ptr %reg.1_85, i8 zeroext %reg.1_86) to label %.Lj142 unwind label %.Lj118, !dbg !142
.Lj142:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 93), !dbg !144
	%reg.1_88 = bitcast ptr %tmp.6 to ptr, !dbg !144
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_88), !dbg !144
	%reg.1_89 = bitcast i64 1 to i64, !dbg !144
	store i64 %reg.1_89, ptr %tmp.6, align 8, !dbg !144
	invoke  void () @"SYSTEM_$$_FPC_DUMMYPOTENTIALRAISE" () to label %.Lj148 unwind label %.Lj147, !dbg !144
.Lj148:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 94), !dbg !145
	invoke  void (i32) @"P$BT_$$_LEVEL1$LONGINT" (i32 signext 1) to label %.Lj149 unwind label %.Lj147, !dbg !145
.Lj149:
	invoke  void () @"SYSTEM_$$_FPC_DUMMYPOTENTIALRAISE" () to label %.Lj150 unwind label %.Lj147, !dbg !146
.Lj150:
	%reg.1_91 = bitcast i64 0 to i64
	store i64 %reg.1_91, ptr %tmp.6, align 8
	br label %.Lj145
	unreachable
.Lj147:
	%reg.1_92 = landingpad %"typ.bt.$llvmstruct$d00000004i32" 	catch ptr @"VMT_$SYSUTILS_$$_EXCEPTION" 	catch ptr null 


	%reg.1_93 = load i64, ptr %tmp.6, align 8
	%reg.1_94 = bitcast i64 0 to i64
	%reg.1_95 = icmp eq i64 %reg.1_93, %reg.1_94
	br i1 %reg.1_95, label %.Lj145, label %.Lj151
.Lj151:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 97), !dbg !147
	%reg.1_98 = call  i32 (ptr) @llvm.eh.typeid.for (ptr @"VMT_$SYSUTILS_$$_EXCEPTION"), !dbg !147
	%reg.1_99 = bitcast i32 %reg.1_98 to i32, !dbg !147
	%reg.1_96 = extractvalue %"typ.bt.$llvmstruct$d00000004i32" %reg.1_92, 1, !dbg !147
	%reg.1_100 = icmp eq i32 %reg.1_96, %reg.1_99, !dbg !147
	br i1 %reg.1_100, label %.Lj153, label %.Lj154, !dbg !147
.Lj154:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 97), !dbg !147
	br label %.Lj152, !dbg !147
.Lj153:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 97), !dbg !147
	%reg.1_101 = extractvalue %"typ.bt.$llvmstruct$d00000004i32" %reg.1_92, 0, !dbg !147
	%reg.1_102 = bitcast ptr %reg.1_101 to ptr, !dbg !147
	%reg.1_103 = invoke  ptr (ptr) @"fpc_psabi_begin_catch" (ptr %reg.1_102) to label %.Lj155 unwind label %.Lj118, !dbg !147
.Lj155:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 97), !dbg !147
	%reg.1_104 = bitcast ptr %reg.1_103 to ptr, !dbg !147
	%reg.1_106 = bitcast ptr %tmp.7 to ptr, !dbg !147
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_106), !dbg !147
	%reg.1_107 = bitcast ptr %reg.1_104 to ptr, !dbg !147
	store ptr %reg.1_107, ptr %tmp.7, align 8, !dbg !147
	%reg.1_109 = bitcast ptr %tmp.8 to ptr, !dbg !147
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_109), !dbg !147
	%reg.1_110 = bitcast i64 1 to i64, !dbg !147
	store i64 %reg.1_110, ptr %tmp.8, align 8, !dbg !147
	invoke  void () @"SYSTEM_$$_FPC_DUMMYPOTENTIALRAISE" () to label %.Lj157 unwind label %.Lj156, !dbg !147
.Lj157:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 97), !dbg !148
	%reg.1_111 = bitcast ptr %tmp.9 to ptr, !dbg !148
	invoke  void (ptr) @"P$BT_$$_EXCEPTION_TRACE$$ANSISTRING" (ptr sret(ptr) %reg.1_111) to label %.Lj159 unwind label %.Lj156, !dbg !148
.Lj159:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 97), !dbg !149
	%reg.1_112 = load ptr, ptr %tmp.9, align 8, !dbg !149
	%reg.1_113 = bitcast ptr @"U_$P$BT_$$_EXCEPTTRACE" to ptr, !dbg !149
	invoke  void (ptr, ptr) @"fpc_ansistr_assign" (ptr %reg.1_113, ptr %reg.1_112) to label %.Lj160 unwind label %.Lj156, !dbg !149
.Lj160:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 97), !dbg !147
	invoke  void () @"SYSTEM_$$_FPC_DUMMYPOTENTIALRAISE" () to label %.Lj162 unwind label %.Lj156, !dbg !147
.Lj162:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 97), !dbg !147
	%reg.1_114 = bitcast i64 0 to i64, !dbg !147
	store i64 %reg.1_114, ptr %tmp.8, align 8, !dbg !147
	br label %.Lj161, !dbg !147
	unreachable, !dbg !147
.Lj156:
	%reg.1_115 = landingpad %"typ.bt.$llvmstruct$d00000004i32" 	catch ptr null 
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 97), !dbg !147
, !dbg !147
	%reg.1_116 = load i64, ptr %tmp.8, align 8
	%reg.1_117 = bitcast i64 0 to i64
	%reg.1_118 = icmp eq i64 %reg.1_116, %reg.1_117
	br i1 %reg.1_118, label %.Lj161, label %.Lj163
.Lj163:
	invoke  void () @"fpc_raise_nested" () to label %.Lj164 unwind label %.Lj118, !dbg !146
.Lj164:
	br label %.Lj161
.Lj161:
	%reg.1_120 = bitcast ptr %tmp.7 to ptr
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_120), !dbg !146
	invoke  void () @"fpc_psabi_end_catch" () to label %.Lj165 unwind label %.Lj118, !dbg !146
.Lj165:
	br label %.Lj145
	%reg.1_122 = bitcast ptr %tmp.8 to ptr
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_122), !dbg !146
	br label %.Lj152
.Lj152:
	br label %.Lj146
.Lj146:
	%reg.1_123 = extractvalue %"typ.bt.$llvmstruct$d00000004i32" %reg.1_92, 0
	%reg.1_124 = bitcast ptr %reg.1_123 to ptr
	%reg.1_125 = invoke  ptr (ptr) @"fpc_psabi_begin_catch" (ptr %reg.1_124) to label %.Lj166 unwind label %.Lj118, !dbg !146
.Lj166:
	%reg.1_126 = bitcast ptr %reg.1_125 to ptr
	invoke  void () @"fpc_reraise" () to label %.Lj167 unwind label %.Lj118, !dbg !146
.Lj167:
	%reg.1_128 = bitcast ptr %tmp.6 to ptr
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_128), !dbg !146
	br label %.Lj145
.Lj145:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 99), !dbg !150
	%reg.1_130 = bitcast ptr %tmp.10 to ptr, !dbg !150
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_130), !dbg !150
	%reg.1_131 = invoke  ptr () @"fpc_get_output" () to label %.Lj168 unwind label %.Lj118, !dbg !150
.Lj168:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 99), !dbg !150
	%reg.1_132 = bitcast ptr %reg.1_131 to ptr, !dbg !150
	store ptr %reg.1_132, ptr %tmp.10, align 8, !dbg !150
	%reg.1_133 = load ptr, ptr %tmp.10, align 8, !dbg !150
	%reg.1_134 = bitcast ptr %reg.1_133 to ptr, !dbg !150
	%reg.1_135 = bitcast ptr %reg.1_134 to ptr, !dbg !150
	%reg.1_136 = load ptr, ptr @"U_$P$BT_$$_EXCEPTTRACE", align 8, !dbg !150
	invoke  void (i32, ptr, ptr) @"fpc_write_text_ansistr" (i32 signext 0, ptr %reg.1_135, ptr %reg.1_136) to label %.Lj169 unwind label %.Lj118, !dbg !150
.Lj169:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 99), !dbg !150
	invoke  void () @"fpc_iocheck" () to label %.Lj170 unwind label %.Lj118, !dbg !150
.Lj170:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 99), !dbg !150
	%reg.1_138 = load ptr, ptr %tmp.10, align 8, !dbg !150
	%reg.1_139 = bitcast ptr %reg.1_138 to ptr, !dbg !150
	%reg.1_140 = bitcast ptr %reg.1_139 to ptr, !dbg !150
	invoke  void (ptr) @"fpc_write_end" (ptr %reg.1_140) to label %.Lj171 unwind label %.Lj118, !dbg !150
.Lj171:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 99), !dbg !150
	invoke  void () @"fpc_iocheck" () to label %.Lj172 unwind label %.Lj118, !dbg !150
.Lj172:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 99), !dbg !150
	%reg.1_142 = bitcast ptr %tmp.10 to ptr, !dbg !150
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_142), !dbg !150
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 101), !dbg !151
	%reg.1_144 = getelementptr %"typ.bt.$ansistrrec6", ptr @".Ld8", i32 0, i32 4, !dbg !151
	%reg.1_143 = bitcast ptr %reg.1_144 to ptr, !dbg !151
	store ptr %reg.1_143, ptr %tmp.11, align 8, !dbg !152
	%reg.1_146 = getelementptr %"typ.bt.$ansistrrec6", ptr @".Ld9", i32 0, i32 4, !dbg !153
	%reg.1_145 = bitcast ptr %reg.1_146 to ptr, !dbg !153
	%reg.1_147 = ptrtoint ptr %tmp.11 to i64, !dbg !152
	%reg.1_148 = add i64 %reg.1_147, 8, !dbg !152
	%reg.1_149 = inttoptr i64 %reg.1_148 to ptr, !dbg !152
	store ptr %reg.1_145, ptr %reg.1_149, align 8, !dbg !152
	%reg.1_151 = getelementptr %"typ.bt.$ansistrrec6", ptr @".Ld10", i32 0, i32 4, !dbg !154
	%reg.1_150 = bitcast ptr %reg.1_151 to ptr, !dbg !154
	%reg.1_152 = ptrtoint ptr %tmp.11 to i64, !dbg !152
	%reg.1_153 = add i64 %reg.1_152, 16, !dbg !152
	%reg.1_154 = inttoptr i64 %reg.1_153 to ptr, !dbg !152
	store ptr %reg.1_150, ptr %reg.1_154, align 8, !dbg !152
	%reg.1_156 = getelementptr %"typ.bt.$ansistrrec10", ptr @".Ld11", i32 0, i32 4, !dbg !155
	%reg.1_155 = bitcast ptr %reg.1_156 to ptr, !dbg !155
	%reg.1_157 = ptrtoint ptr %tmp.11 to i64, !dbg !152
	%reg.1_158 = add i64 %reg.1_157, 24, !dbg !152
	%reg.1_159 = inttoptr i64 %reg.1_158 to ptr, !dbg !152
	store ptr %reg.1_155, ptr %reg.1_159, align 8, !dbg !152
	%reg.1_160 = bitcast ptr %tmp.11 to ptr, !dbg !156
	%reg.1_161 = load ptr, ptr @"U_$P$BT_$$_EXCEPTTRACE", align 8, !dbg !156
	%reg.1_163 = invoke  i8 (ptr, ptr, i64) @"P$BT_$$_HAS_ORDER$ANSISTRING$array_of_ANSISTRING$$BOOLEAN" (ptr %reg.1_161, ptr %reg.1_160, i64 3) to label %.Lj173 unwind label %.Lj118, !dbg !156
.Lj173:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 101), !dbg !156
	%reg.1_164 = bitcast i8 %reg.1_163 to i8, !dbg !156
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 100), !dbg !157
	%reg.1_165 = zext i8 %reg.1_164 to i64, !dbg !157
	%reg.1_167 = getelementptr %"typ.bt.$ansistrrec60", ptr @".Ld13", i32 0, i32 4, !dbg !158
	%reg.1_166 = bitcast ptr %reg.1_167 to ptr, !dbg !158
	%reg.1_168 = bitcast ptr %reg.1_166 to ptr, !dbg !157
	%reg.1_169 = trunc i64 %reg.1_165 to i8, !dbg !157
	invoke  void (ptr, i8) @"P$BT_$$_CHECK$ANSISTRING$BOOLEAN" (ptr %reg.1_168, i8 zeroext %reg.1_169) to label %.Lj174 unwind label %.Lj118, !dbg !157
.Lj174:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 102), !dbg !159
	%reg.1_171 = bitcast ptr %tmp.12 to ptr, !dbg !159
	call  void (i64, ptr) @llvm.lifetime.start (i64 8, ptr %reg.1_171), !dbg !159
	%reg.1_172 = invoke  ptr () @"fpc_get_output" () to label %.Lj175 unwind label %.Lj118, !dbg !159
.Lj175:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 102), !dbg !159
	%reg.1_173 = bitcast ptr %reg.1_172 to ptr, !dbg !159
	store ptr %reg.1_173, ptr %tmp.12, align 8, !dbg !159
	%reg.1_174 = load ptr, ptr %tmp.12, align 8, !dbg !159
	%reg.1_175 = bitcast ptr %reg.1_174 to ptr, !dbg !159
	%reg.1_176 = bitcast ptr %reg.1_175 to ptr, !dbg !159
	%reg.1_177 = bitcast ptr @".Ld14" to ptr, !dbg !160
	%reg.1_178 = bitcast ptr %reg.1_177 to ptr, !dbg !159
	invoke  void (i32, ptr, ptr) @"fpc_write_text_shortstr" (i32 signext 0, ptr %reg.1_176, ptr %reg.1_178) to label %.Lj176 unwind label %.Lj118, !dbg !159
.Lj176:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 102), !dbg !159
	invoke  void () @"fpc_iocheck" () to label %.Lj177 unwind label %.Lj118, !dbg !159
.Lj177:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 102), !dbg !161
	%reg.1_181 = load i32, ptr @"TC_$P$BT_$$_ERRORS", align 4, !dbg !161
	%reg.1_180 = sext i32 %reg.1_181 to i64, !dbg !161
	%reg.1_182 = bitcast i64 %reg.1_180 to i64, !dbg !159
	%reg.1_183 = load ptr, ptr %tmp.12, align 8, !dbg !159
	%reg.1_184 = bitcast ptr %reg.1_183 to ptr, !dbg !159
	%reg.1_185 = bitcast ptr %reg.1_184 to ptr, !dbg !159
	invoke  void (i32, ptr, i64) @"fpc_write_text_sint" (i32 signext 0, ptr %reg.1_185, i64 %reg.1_182) to label %.Lj178 unwind label %.Lj118, !dbg !159
.Lj178:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 102), !dbg !159
	invoke  void () @"fpc_iocheck" () to label %.Lj179 unwind label %.Lj118, !dbg !159
.Lj179:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 102), !dbg !159
	%reg.1_187 = load ptr, ptr %tmp.12, align 8, !dbg !159
	%reg.1_188 = bitcast ptr %reg.1_187 to ptr, !dbg !159
	%reg.1_189 = bitcast ptr %reg.1_188 to ptr, !dbg !159
	invoke  void (ptr) @"fpc_writeln_end" (ptr %reg.1_189) to label %.Lj180 unwind label %.Lj118, !dbg !159
.Lj180:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 102), !dbg !159
	invoke  void () @"fpc_iocheck" () to label %.Lj181 unwind label %.Lj118, !dbg !159
.Lj181:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 102), !dbg !159
	%reg.1_191 = bitcast ptr %tmp.12 to ptr, !dbg !159
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_191), !dbg !159
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 103), !dbg !162
	%reg.1_193 = load i32, ptr @"TC_$P$BT_$$_ERRORS", align 4, !dbg !162
	%reg.1_192 = sext i32 %reg.1_193 to i64, !dbg !162
	%reg.1_194 = trunc i64 %reg.1_192 to i32, !dbg !162
	invoke  void (i32) @"SYSTEM_$$_HALT$LONGINT" (i32 signext %reg.1_194) to label %.Lj182 unwind label %.Lj118, !dbg !162
.Lj182:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 86), !dbg !133
	br label %.Lj134, !dbg !133
.Lj134:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 84), !dbg !131
	br label %.Lj127, !dbg !131
.Lj127:
	invoke  void () @"SYSTEM_$$_FPC_DUMMYPOTENTIALRAISE" () to label %.Lj183 unwind label %.Lj118, !dbg !146
.Lj183:
	%reg.1_195 = bitcast i64 0 to i64
	store i64 %reg.1_195, ptr %tmp.1, align 8
	br label %.Lj184
.Lj184:
	%reg.1_197 = bitcast ptr %tmp.9 to ptr
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_197), !dbg !146
	%reg.1_198 = bitcast ptr %tmp.3 to ptr
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_198), !dbg !146
	%reg.1_199 = bitcast ptr %tmp.2 to ptr
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_199), !dbg !146
	%reg.1_200 = load i64, ptr %tmp.1, align 8
	%reg.1_201 = bitcast i64 0 to i64
	%reg.1_202 = icmp eq i64 %reg.1_200, %reg.1_201
	br i1 %reg.1_202, label %.Lj116, label %.Lj185
.Lj185:
	unreachable
	unreachable
.Lj118:
	%reg.1_196 = landingpad %"typ.bt.$llvmstruct$d00000004i32" 	cleanup

	br label %.Lj117
.Lj117:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 105), !dbg !163
	%reg.1_203 = bitcast ptr %tmp.9 to ptr, !dbg !163
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_203), !dbg !163
	%reg.1_204 = bitcast ptr %tmp.3 to ptr, !dbg !163
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_204), !dbg !163
	%reg.1_205 = bitcast ptr %tmp.2 to ptr, !dbg !163
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_205), !dbg !163
	resume %"typ.bt.$llvmstruct$d00000004i32" %reg.1_196
	%reg.1_207 = bitcast ptr %tmp.1 to ptr
	call  void (i64, ptr) @llvm.lifetime.end (i64 8, ptr %reg.1_207), !dbg !146
	br label %.Lj116
.Lj116:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 105), !dbg !163
	br label %.Lj3, !dbg !163
.Lj3:
	call void @FPC_ZOS_DBG_LINE(ptr %zdbg.r, i32 signext 105), !dbg !163
	call  void () @"fpc_do_exit" (), !dbg !163
	ret void, !dbg !163
}
@"INIT$_$P$BT" = hidden alias  void (), ptr @"P$BT_$$_init_implicit$"
define hidden void @"P$BT_$$_init_implicit$"() nobuiltin null_pointer_is_valid strictfp !dbg !164 {
	%zdbg.r = alloca { ptr, ptr, i32, i32, [1 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [1 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.9, ptr %zdbg.fp, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r)
	br label %.Lj112
.Lj112:
	ret void
}
@"FINALIZE$_$P$BT" = hidden alias  void (), ptr @"P$BT_$$_finalize_implicit$"
@"PASCALFINALIZE" = hidden alias  void (), ptr @"P$BT_$$_finalize_implicit$"
define hidden void @"P$BT_$$_finalize_implicit$"() nobuiltin null_pointer_is_valid strictfp personality ptr @"SYSTEM_$$__FPC_PSABIEH_PERSONALITY_V0$hhyOiwn8_zDM" !dbg !165 {
	%zdbg.r = alloca { ptr, ptr, i32, i32, [1 x ptr] }, align 8
	%zdbg.fp = getelementptr inbounds { ptr, ptr, i32, i32, [1 x ptr] }, ptr %zdbg.r, i32 0, i32 1
	store ptr @zdbg.f.10, ptr %zdbg.fp, align 8
	call void @FPC_ZOS_DBG_ENTER(ptr %zdbg.r)
	br label %.Lj114
.Lj114:
	%reg.1_16 = bitcast ptr @"U_$P$BT_$$_CAPTURED" to ptr
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_16), !dbg !166
	%reg.1_17 = bitcast ptr @"U_$P$BT_$$_EXCEPTTRACE" to ptr
	call  void (ptr) @"fpc_ansistr_decr_ref" (ptr %reg.1_17), !dbg !166
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
declare i64 @"SYSTEM_$$_CAPTUREBACKTRACE$INT64$INT64$PCODEPOINTER$$INT64"(i64, i64, ptr) nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_ansistr_assign"(ptr nocapture dereferenceable_or_null(8), ptr) nobuiltin null_pointer_is_valid strictfp
@"TC_$SYSTEM_$$_BACKTRACESTRFUNC" = external global ptr, align 8
declare void @"fpc_shortstr_to_ansistr"(ptr sret(ptr) noalias nocapture, ptr nocapture readonly dereferenceable(256), i16 zeroext) nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_ansistr_concat_multi"(ptr nocapture dereferenceable_or_null(8), ptr nocapture, i64, i16 zeroext) nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_ansistr_decr_ref"(ptr nocapture dereferenceable_or_null(8)) inlinehint nobuiltin null_pointer_is_valid strictfp
declare ptr @llvm.frameaddress(i32 signext) null_pointer_is_valid strictfp
@"VMT_$SYSUTILS_$$_EXCEPTION" = external global ptr, align 8
declare ptr @"SYSUTILS$_$EXCEPTION_$__$$_CREATE$ANSISTRING$$EXCEPTION"(ptr, ptr, ptr) nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_raiseexception"(ptr, ptr, ptr) nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_divbyzero"() nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_write_text_sint"(i32 signext, ptr nocapture dereferenceable_or_null(896), i64) nobuiltin null_pointer_is_valid strictfp
declare void @"SYSTEM_$$_RUNERROR$WORD"(i16 zeroext) nobuiltin noreturn null_pointer_is_valid strictfp
declare ptr @"SYSUTILS_$$_EXCEPTADDR$$POINTER"() nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_shortstr_concat"(ptr nocapture dereferenceable_or_null(1), i64, ptr nocapture readonly dereferenceable(256), ptr nocapture readonly dereferenceable(256)) nobuiltin null_pointer_is_valid strictfp
declare ptr @"SYSUTILS_$$_EXCEPTFRAMES$$PCODEPOINTER"() nobuiltin null_pointer_is_valid strictfp
declare signext i32 @"SYSUTILS_$$_EXCEPTFRAMECOUNT$$LONGINT"() nobuiltin null_pointer_is_valid strictfp
declare i64 @"SYSTEM_$$_POS$RAWBYTESTRING$RAWBYTESTRING$INT64$$INT64"(ptr, ptr, i64) nobuiltin null_pointer_is_valid strictfp
declare void @"FPC_SYSTEMMAIN"(i32 signext, ptr, ptr) nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_initializeunits"() nobuiltin null_pointer_is_valid strictfp
declare void @"OBJPAS_$$_PARAMSTR$LONGINT$$ANSISTRING"(ptr sret(ptr) noalias nocapture, i32 signext) nobuiltin null_pointer_is_valid strictfp
declare i64 @"fpc_ansistr_compare_equal"(ptr, ptr) nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_write_end"(ptr nocapture dereferenceable_or_null(896)) nobuiltin null_pointer_is_valid strictfp
declare signext i32 @llvm.eh.typeid.for(ptr) null_pointer_is_valid strictfp
declare ptr @"fpc_psabi_begin_catch"(ptr) nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_raise_nested"() nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_psabi_end_catch"() nobuiltin null_pointer_is_valid strictfp
declare void @"fpc_reraise"() nobuiltin null_pointer_is_valid strictfp
declare void @"SYSTEM_$$_HALT$LONGINT"(i32 signext) nobuiltin noreturn null_pointer_is_valid strictfp
declare void @"fpc_do_exit"() nobuiltin null_pointer_is_valid strictfp
; End asmlist al_procedures
; Begin asmlist al_globals
@"U_$P$BT_$$_CAPTURED" = hidden global ptr zeroinitializer, align 8, !dbg !172
@"U_$P$BT_$$_EXCEPTTRACE" = hidden global ptr zeroinitializer, align 8, !dbg !174
@".Ld15" = internal unnamed_addr constant [7 x i8] c"\06System", align 8
@".Ld16" = internal unnamed_addr constant [7 x i8] c"\06objpas", align 8
@".Ld17" = internal unnamed_addr constant [5 x i8] c"\04Unix", align 8
@".Ld18" = internal unnamed_addr constant [9 x i8] c"\08sysutils", align 8
@".Ld19" = internal unnamed_addr constant [3 x i8] c"\02bt", align 8
@"INITFINAL" = hidden global %"typ.bt.00000021" <{i64 5, i64 zeroinitializer, ptr @"INIT$_$SYSTEM", ptr zeroinitializer, ptr @".Ld15", ptr zeroinitializer, ptr @"FINALIZE$_$OBJPAS", ptr @".Ld16", ptr @"INIT$_$UNIX", ptr @"FINALIZE$_$UNIX", ptr @".Ld17", ptr @"INIT$_$SYSUTILS", ptr @"FINALIZE$_$SYSUTILS", ptr @".Ld18", ptr @"INIT$_$P$BT", ptr @"FINALIZE$_$P$BT", ptr @".Ld19" }>, align 8
@"FPC_THREADVARTABLES" = hidden global %"typ.bt.00000022" <{i64 1, ptr @"THREADVARLIST_$SYSTEM$indirect" }>, align 8
@"FPC_RESOURCESTRINGTABLES" = hidden constant %"typ.bt.00000023" <{i64 1, ptr @"RESSTR_$SYSCONST_$$_PTRLIST", ptr @"RESSTR_$SYSCONST_$$_PTRLIST" }>, align 8
@"FPC_WIDEINITTABLES" = hidden global %"typ.bt.00000024" <{i64 zeroinitializer }>, align 8
@"FPC_RESSTRINITTABLES" = hidden global %"typ.bt.00000025" <{i64 zeroinitializer }>, align 8
@"__fpc_ident" = internal global [38 x i8] c"FPC 3.3.1 [2026/09/28] for s390x - zos", align 8
@"__stklen" = hidden global i64 1048576, align 8
@"__heapsize" = hidden global i64 zeroinitializer, align 8
@"__fpc_valgrind" = hidden global i8 zeroinitializer, align 8
@llvm.compiler.used = appending hidden global [1 x ptr] [ptr @"__fpc_ident"], section "llvm.metadata"
declare void @"INIT$_$SYSTEM"() nobuiltin null_pointer_is_valid strictfp
declare void @"FINALIZE$_$OBJPAS"() nobuiltin null_pointer_is_valid strictfp
declare void @"INIT$_$UNIX"() nobuiltin null_pointer_is_valid strictfp
declare void @"FINALIZE$_$UNIX"() nobuiltin null_pointer_is_valid strictfp
declare void @"INIT$_$SYSUTILS"() nobuiltin null_pointer_is_valid strictfp
declare void @"FINALIZE$_$SYSUTILS"() nobuiltin null_pointer_is_valid strictfp
@"THREADVARLIST_$SYSTEM$indirect" = external global ptr, align 8
@"RESSTR_$SYSCONST_$$_PTRLIST" = external global ptr, align 8
; End asmlist al_globals
; Begin asmlist al_typedconsts
@"TC_$P$BT_$$_ERRORS" = hidden global i32 zeroinitializer, align 4, !dbg !168
@".Ld1" = internal unnamed_addr constant [10 x i8] c"\08OK      \00", align 8
@".Ld2" = internal unnamed_addr constant [10 x i8] c"\08FEHLER  \00", align 8
@".Ld3" = internal unnamed_addr constant %"typ.bt.$ansistrrec1" <{i16 zeroinitializer, i16 1, i32 -1, i64 1, [2 x i8] c"\0A\00" }>, align 8
@"TC_$P$BT_$$_ZERO" = hidden global i32 zeroinitializer, align 4, !dbg !176
@".Ld4" = internal unnamed_addr constant %"typ.bt.$ansistrrec15" <{i16 zeroinitializer, i16 1, i32 -1, i64 15, [16 x i8] c"Test aus LEVEL3\00" }>, align 8
@".Ld5" = internal unnamed_addr constant [3 x i8] c"\01\0A\00", align 8
@".Ld6" = internal unnamed_addr constant %"typ.bt.$ansistrrec3" <{i16 zeroinitializer, i16 1, i32 -1, i64 3, [4 x i8] c"div\00" }>, align 8
@".Ld7" = internal unnamed_addr constant %"typ.bt.$ansistrrec8" <{i16 zeroinitializer, i16 1, i32 -1, i64 8, [9 x i8] c"runerror\00" }>, align 8
@".Ld8" = internal unnamed_addr constant %"typ.bt.$ansistrrec6" <{i16 zeroinitializer, i16 1, i32 -1, i64 6, [7 x i8] c"LEVEL3\00" }>, align 8
@".Ld9" = internal unnamed_addr constant %"typ.bt.$ansistrrec6" <{i16 zeroinitializer, i16 1, i32 -1, i64 6, [7 x i8] c"LEVEL2\00" }>, align 8
@".Ld10" = internal unnamed_addr constant %"typ.bt.$ansistrrec6" <{i16 zeroinitializer, i16 1, i32 -1, i64 6, [7 x i8] c"LEVEL1\00" }>, align 8
@".Ld11" = internal unnamed_addr constant %"typ.bt.$ansistrrec10" <{i16 zeroinitializer, i16 1, i32 -1, i64 10, [11 x i8] c"PASCALMAIN\00" }>, align 8
@".Ld12" = internal unnamed_addr constant %"typ.bt.$ansistrrec52" <{i16 zeroinitializer, i16 1, i32 -1, i64 52, [53 x i8] c"CaptureBacktrace: LEVEL3, LEVEL2, LEVEL1, PASCALMAIN\00" }>, align 8
@".Ld13" = internal unnamed_addr constant %"typ.bt.$ansistrrec60" <{i16 zeroinitializer, i16 1, i32 -1, i64 60, [61 x i8] c"Ausnahme: Adresse in LEVEL3, dann LEVEL2, LEVEL1, PASCALMAIN\00" }>, align 8
@".Ld14" = internal unnamed_addr constant [10 x i8] c"\08Fehler: \00", align 8
; End asmlist al_typedconsts
; Begin asmlist al_rotypedconsts
!llvm.module.flags = !{!361, !362}
!361 = !{i32 2, !"Debug Info Version", i32 3}
!362 = !{i32 2, !"Dwarf Version", i32 3}
; End asmlist al_rotypedconsts
; Begin asmlist al_rtti
@"RTTI_$P$BT_$$_def00000009" = hidden constant %"typ.bt.$rttidef$RTTI_$P$BT_$$_def00000009" <{i8 12, [1 x i8] [i8 zeroinitializer], %"typ.bt.$rtti_normal_array$1" <{ptr zeroinitializer, %"typ.bt.$rtti_normal_array_inner$1" <{i64 24, i64 3, ptr @"RTTI_$SYSTEM_$$_RAWBYTESTRING$indirect", i8 1, ptr @"RTTI_$SYSTEM_$$_LONGINT$indirect" }> }> }>, align 8
@"RTTI_$P$BT_$$_def00000015" = hidden constant %"typ.bt.$rttidef$RTTI_$P$BT_$$_def00000015" <{i8 12, [1 x i8] [i8 zeroinitializer], %"typ.bt.$rtti_normal_array$1" <{ptr zeroinitializer, %"typ.bt.$rtti_normal_array_inner$1" <{i64 24, i64 3, ptr @"RTTI_$SYSTEM_$$_RAWBYTESTRING$indirect", i8 1, ptr @"RTTI_$SYSTEM_$$_LONGINT$indirect" }> }> }>, align 8
@"RTTI_$P$BT_$$_def00000019" = hidden constant %"typ.bt.$rttidef$RTTI_$P$BT_$$_def00000019" <{i8 12, [11 x i8] c"\0AAnsiString", %"typ.bt.$rtti_normal_array$1" <{ptr zeroinitializer, %"typ.bt.$rtti_normal_array_inner$1" <{i64 zeroinitializer, i64 zeroinitializer, ptr @"RTTI_$SYSTEM_$$_ANSISTRING$indirect", i8 1, ptr @"RTTI_$SYSTEM_$$_INT64$indirect" }> }> }>, align 8
@"RTTI_$P$BT_$$_def0000001F" = hidden constant %"typ.bt.$rttidef$RTTI_$P$BT_$$_def0000001F" <{i8 12, [1 x i8] [i8 zeroinitializer], %"typ.bt.$rtti_normal_array$1" <{ptr zeroinitializer, %"typ.bt.$rtti_normal_array_inner$1" <{i64 32, i64 4, ptr @"RTTI_$SYSTEM_$$_ANSISTRING$indirect", i8 1, ptr @"RTTI_$SYSTEM_$$_LONGINT$indirect" }> }> }>, align 8
@"RTTI_$P$BT_$$_def00000020" = hidden constant %"typ.bt.$rttidef$RTTI_$P$BT_$$_def00000020" <{i8 12, [1 x i8] [i8 zeroinitializer], %"typ.bt.$rtti_normal_array$1" <{ptr zeroinitializer, %"typ.bt.$rtti_normal_array_inner$1" <{i64 32, i64 4, ptr @"RTTI_$SYSTEM_$$_ANSISTRING$indirect", i8 1, ptr @"RTTI_$SYSTEM_$$_LONGINT$indirect" }> }> }>, align 8
@"RTTI_$SYSTEM_$$_RAWBYTESTRING$indirect" = external global ptr, align 8
@"RTTI_$SYSTEM_$$_LONGINT$indirect" = external global ptr, align 8
@"RTTI_$SYSTEM_$$_ANSISTRING$indirect" = external global ptr, align 8
@"RTTI_$SYSTEM_$$_INT64$indirect" = external global ptr, align 8
; End asmlist al_rtti
; Begin asmlist al_indirectglobals
@"RTTI_$P$BT_$$_def00000009$indirect" = hidden constant ptr @"RTTI_$P$BT_$$_def00000009", align 8
@"RTTI_$P$BT_$$_def00000015$indirect" = hidden constant ptr @"RTTI_$P$BT_$$_def00000015", align 8
@"RTTI_$P$BT_$$_def00000019$indirect" = hidden constant ptr @"RTTI_$P$BT_$$_def00000019", align 8
@"RTTI_$P$BT_$$_def0000001F$indirect" = hidden constant ptr @"RTTI_$P$BT_$$_def0000001F", align 8
@"RTTI_$P$BT_$$_def00000020$indirect" = hidden constant ptr @"RTTI_$P$BT_$$_def00000020", align 8
; End asmlist al_indirectglobals
; Begin asmlist al_dwarf_info
!9 = !DILocalVariable(name: "WHAT", arg: 10, scope: !6, file: !7, line: 14, type: !10)
!11 = !DILocalVariable(name: "OK", arg: 20, scope: !6, file: !7, line: 14, type: !12)
!22 = !DILocalVariable(name: "result", arg: 5, scope: !20, file: !7, line: 21, type: !10)
!23 = !DILocalVariable(name: "FRAMES", scope: !20, file: !7, line: 23, type: !24)
!25 = !DILocalVariable(name: "N", scope: !20, file: !7, line: 24, type: !26)
!27 = !DILocalVariable(name: "I", scope: !20, file: !7, line: 24, type: !26)
!47 = !DILocalVariable(name: "MODE", arg: 10, scope: !45, file: !7, line: 36, type: !26)
!62 = !DILocalVariable(name: "MODE", arg: 10, scope: !60, file: !7, line: 46, type: !26)
!67 = !DILocalVariable(name: "MODE", arg: 10, scope: !65, file: !7, line: 51, type: !26)
!72 = !DILocalVariable(name: "result", arg: 5, scope: !70, file: !7, line: 56, type: !10)
!73 = !DILocalVariable(name: "I", scope: !70, file: !7, line: 58, type: !26)
!74 = !DILocalVariable(name: "FRAMES", scope: !70, file: !7, line: 59, type: !75)
!97 = !DILocalVariable(name: "S", arg: 10, scope: !95, file: !7, line: 67, type: !10)
!98 = !DILocalVariable(name: "NAMES", arg: 20, scope: !95, file: !7, line: 67, type: !99)
!100 = !DILocalVariable(name: "highNAMES", arg: 21, scope: !95, file: !7, line: 68, type: !101)
!102 = !DILocalVariable(name: "result", scope: !95, file: !7, line: 67, type: !12)
!103 = !DILocalVariable(name: "I", scope: !95, file: !7, line: 69, type: !26)
!104 = !DILocalVariable(name: "P", scope: !95, file: !7, line: 69, type: !26)
!105 = !DILocalVariable(name: "Q", scope: !95, file: !7, line: 69, type: !26)
!124 = !DILocalVariable(name: "ARGC", arg: 1, scope: !122, file: !7, line: 11, type: !26)
!125 = !DILocalVariable(name: "ARGV", arg: 2, scope: !122, file: !7, line: 11, type: !126)
!127 = !DILocalVariable(name: "ARGP", arg: 3, scope: !122, file: !7, line: 11, type: !126)
; Syms - Begin Staticsymtable
; Symbol SYSTEM
; Symbol OBJPAS
; Symbol SYSUTILS
; Symbol BT
; Symbol main
; Symbol __FPC_IMPL_EXTERNAL_REDIRECT_FPC_SYSTEMMAIN
; Symbol PASCALMAIN
; Symbol ERRORS
!167 = distinct !DIGlobalVariable(name: "ERRORS", scope: !5, file: !7, line: 12, type: !26, isDefinition: true, isLocal: true)
!168 = !DIGlobalVariableExpression(var: !167, expr: !3)
; Symbol CHECK
; Symbol CAPTURE_LINES
; Symbol ansistrrec1
; Symbol llvmstruct$d00000004i32
; Symbol CAPTURED
!171 = distinct !DIGlobalVariable(name: "CAPTURED", scope: !5, file: !7, line: 33, type: !10, isDefinition: true, isLocal: true)
!172 = !DIGlobalVariableExpression(var: !171, expr: !3)
; Symbol EXCEPTTRACE
!173 = distinct !DIGlobalVariable(name: "EXCEPTTRACE", scope: !5, file: !7, line: 33, type: !10, isDefinition: true, isLocal: true)
!174 = !DIGlobalVariableExpression(var: !173, expr: !3)
; Symbol ZERO
!175 = distinct !DIGlobalVariable(name: "ZERO", scope: !5, file: !7, line: 34, type: !26, isDefinition: true, isLocal: true)
!176 = !DIGlobalVariableExpression(var: !175, expr: !3)
; Symbol LEVEL3
; Symbol ansistrrec15
; Symbol LEVEL2
; Symbol LEVEL1
; Symbol EXCEPTION_TRACE
; Symbol HAS_ORDER
; Symbol P$BT_$$_init_implicit$
; Symbol P$BT_$$_finalize_implicit$
; Symbol ansistrrec3
; Symbol ansistrrec8
; Symbol ansistrrec6
; Symbol ansistrrec10
; Symbol ansistrrec52
; Symbol ansistrrec60
; Symbol rttidef$RTTI_$P$BT_$$_def00000009
; Symbol rtti_normal_array$1
; Symbol rtti_normal_array_inner$1
; Symbol rttidef$RTTI_$P$BT_$$_def00000015
; Symbol rttidef$RTTI_$P$BT_$$_def00000019
; Symbol rttidef$RTTI_$P$BT_$$_def0000001F
; Symbol rttidef$RTTI_$P$BT_$$_def00000020
; Syms - End Staticsymtable
!122 = distinct !DISubprogram(name: "main", scope: !7, file: !7, line: 11, spFlags: DISPFlagDefinition, unit: !5, type: !191)
!192 = !{null, !26, !126, !126}
!191 = !DISubroutineType(types: !192)
!128 = distinct !DISubprogram(scopeLine: 82, name: "PASCALMAIN", scope: !7, file: !7, line: 11, spFlags: DISPFlagDefinition|DISPFlagMainSubprogram, unit: !5, type: !193)
!194 = !{null}
!193 = !DISubroutineType(types: !194)
!6 = distinct !DISubprogram(scopeLine: 15, name: "CHECK", scope: !7, file: !7, line: 14, spFlags: DISPFlagDefinition, unit: !5, type: !195)
!196 = !{null, !10, !12}
!195 = !DISubroutineType(types: !196)
!20 = distinct !DISubprogram(scopeLine: 25, name: "CAPTURE_LINES", scope: !7, file: !7, line: 21, spFlags: DISPFlagDefinition, unit: !5, type: !197)
!198 = !{!10, !10}
!197 = !DISubroutineType(types: !198)
!45 = distinct !DISubprogram(scopeLine: 37, name: "LEVEL3", scope: !7, file: !7, line: 36, spFlags: DISPFlagDefinition, unit: !5, type: !199)
!200 = !{null, !26}
!199 = !DISubroutineType(types: !200)
!60 = distinct !DISubprogram(scopeLine: 47, name: "LEVEL2", scope: !7, file: !7, line: 46, spFlags: DISPFlagDefinition, unit: !5, type: !201)
!202 = !{null, !26}
!201 = !DISubroutineType(types: !202)
!65 = distinct !DISubprogram(scopeLine: 52, name: "LEVEL1", scope: !7, file: !7, line: 51, spFlags: DISPFlagDefinition, unit: !5, type: !203)
!204 = !{null, !26}
!203 = !DISubroutineType(types: !204)
!70 = distinct !DISubprogram(scopeLine: 60, name: "EXCEPTION_TRACE", scope: !7, file: !7, line: 56, spFlags: DISPFlagDefinition, unit: !5, type: !205)
!206 = !{!10, !10}
!205 = !DISubroutineType(types: !206)
!95 = distinct !DISubprogram(scopeLine: 70, name: "HAS_ORDER", scope: !7, file: !7, line: 67, spFlags: DISPFlagDefinition, unit: !5, type: !207)
!208 = !{!12, !10, !99, !101}
!207 = !DISubroutineType(types: !208)
!164 = distinct !DISubprogram(name: "P$BT_$$_init_implicit$", scope: !7, file: !7, line: 105, spFlags: DISPFlagDefinition, unit: !5, type: !209)
!210 = !{null}
!209 = !DISubroutineType(types: !210)
!165 = distinct !DISubprogram(name: "P$BT_$$_finalize_implicit$", scope: !7, file: !7, line: 105, spFlags: DISPFlagDefinition, unit: !5, type: !211)
!212 = !{null}
!211 = !DISubroutineType(types: !212)
; Defs - Begin unit SYSTEM has index 2
!213 = !DIBasicType(size: 32, encoding: DW_ATE_signed)
!26 = !DIDerivedType(tag: DW_TAG_typedef, name: "LONGINT", file: !214, line: 23, baseType: !213)
!215 = !DIBasicType(size: 64, encoding: DW_ATE_signed)
!101 = !DIDerivedType(tag: DW_TAG_typedef, name: "INT64", file: !214, line: 23, baseType: !215)
!216 = !DIBasicType(size: 8, encoding: DW_ATE_boolean)
!12 = !DIDerivedType(tag: DW_TAG_typedef, name: "BOOLEAN", file: !214, line: 23, baseType: !216)
!217 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !218)
!10 = !DIDerivedType(tag: DW_TAG_typedef, name: "ANSISTRING", file: !214, line: 23, baseType: !217)
!219 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !220)
!75 = !DIDerivedType(tag: DW_TAG_typedef, name: "PCODEPOINTER", file: !221, line: 636, baseType: !219)
!222 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null)
!220 = !DIDerivedType(tag: DW_TAG_typedef, name: "POINTER", file: !214, line: 23, baseType: !222)
!223 = !DIBasicType(size: 8, encoding: DW_ATE_unsigned_char)
!218 = !DIDerivedType(tag: DW_TAG_typedef, name: "ANSICHAR", file: !214, line: 23, baseType: !223)
; Defs - End unit SYSTEM has index 2
; Defs - Begin unit OBJPAS has index 3
; Defs - End unit OBJPAS has index 3
; Defs - Begin unit UNIXTYPE has index 9
; Defs - End unit UNIXTYPE has index 9
; Defs - Begin unit BASEUNIX has index 5
; Defs - End unit BASEUNIX has index 5
; Defs - Begin unit UNIX has index 6
; Defs - End unit UNIX has index 6
; Defs - Begin unit ERRORS has index 7
; Defs - End unit ERRORS has index 7
; Defs - Begin unit SYSCONST has index 8
; Defs - End unit SYSCONST has index 8
; Defs - Begin unit CTYPES has index 12
; Defs - End unit CTYPES has index 12
; Defs - Begin unit INITC has index 10
; Defs - End unit INITC has index 10
; Defs - Begin unit UNIXUTIL has index 11
; Defs - End unit UNIXUTIL has index 11
; Defs - Begin unit SYSUTILS has index 4
; Defs - End unit SYSUTILS has index 4
; Defs - Begin Staticsymtable
!126 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !224)
!225 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$ANSISTRREC1", file: !7, line: 30, size: 144, elements: !226)
!226 = !{!227, !229, !230, !231, !232}
!227 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !225, file: !7, line: 30, baseType: !228, size: 16, flags: DIFlagArtificial)
!229 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !225, file: !7, line: 30, baseType: !228, size: 16, offset: 16, flags: DIFlagArtificial)
!230 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !225, file: !7, line: 30, baseType: !26, size: 32, offset: 32, flags: DIFlagArtificial)
!231 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !225, file: !7, line: 30, baseType: !101, size: 64, offset: 64, flags: DIFlagArtificial)
!232 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !225, file: !7, line: 30, baseType: !233, size: 16, offset: 128, flags: DIFlagArtificial)
!169 = !DIDerivedType(tag: DW_TAG_typedef, name: "ansistrrec1", file: !7, line: 30, baseType: !225)
!234 = !{!235}
!235 = !DISubrange(count: 2, lowerBound: 0)
!233 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !218, elements: !234, size: 16)
!236 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$LLVMSTRUCT$D00000004I32", file: !7, line: 30, size: 96, elements: !237)
!237 = !{!238, !239}
!238 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !236, file: !7, line: 30, baseType: !220, size: 64, flags: DIFlagArtificial)
!239 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !236, file: !7, line: 30, baseType: !240, size: 32, offset: 64, flags: DIFlagArtificial)
!170 = !DIDerivedType(tag: DW_TAG_typedef, name: "llvmstruct$d00000004i32", file: !7, line: 30, baseType: !236)
!241 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$ANSISTRREC15", file: !7, line: 44, size: 256, elements: !242)
!242 = !{!243, !244, !245, !246, !247}
!243 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !241, file: !7, line: 44, baseType: !228, size: 16, flags: DIFlagArtificial)
!244 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !241, file: !7, line: 44, baseType: !228, size: 16, offset: 16, flags: DIFlagArtificial)
!245 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !241, file: !7, line: 44, baseType: !26, size: 32, offset: 32, flags: DIFlagArtificial)
!246 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !241, file: !7, line: 44, baseType: !101, size: 64, offset: 64, flags: DIFlagArtificial)
!247 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !241, file: !7, line: 44, baseType: !248, size: 128, offset: 128, flags: DIFlagArtificial)
!177 = !DIDerivedType(tag: DW_TAG_typedef, name: "ansistrrec15", file: !7, line: 44, baseType: !241)
!249 = !{!250}
!250 = !DISubrange(count: 16, lowerBound: 0)
!248 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !218, elements: !249, size: 128)
!251 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$ANSISTRREC3", size: 160, elements: !252)
!252 = !{!253, !254, !255, !256, !257}
!253 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !251, baseType: !228, size: 16, flags: DIFlagArtificial)
!254 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !251, baseType: !228, size: 16, offset: 16, flags: DIFlagArtificial)
!255 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !251, baseType: !26, size: 32, offset: 32, flags: DIFlagArtificial)
!256 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !251, baseType: !101, size: 64, offset: 64, flags: DIFlagArtificial)
!257 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !251, baseType: !258, size: 32, offset: 128, flags: DIFlagArtificial)
!178 = !DIDerivedType(tag: DW_TAG_typedef, name: "ansistrrec3", baseType: !251)
!259 = !{!260}
!260 = !DISubrange(count: 4, lowerBound: 0)
!258 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !218, elements: !259, size: 32)
!261 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$ANSISTRREC8", size: 200, elements: !262)
!262 = !{!263, !264, !265, !266, !267}
!263 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !261, baseType: !228, size: 16, flags: DIFlagArtificial)
!264 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !261, baseType: !228, size: 16, offset: 16, flags: DIFlagArtificial)
!265 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !261, baseType: !26, size: 32, offset: 32, flags: DIFlagArtificial)
!266 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !261, baseType: !101, size: 64, offset: 64, flags: DIFlagArtificial)
!267 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !261, baseType: !268, size: 72, offset: 128, flags: DIFlagArtificial)
!179 = !DIDerivedType(tag: DW_TAG_typedef, name: "ansistrrec8", baseType: !261)
!269 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$ANSISTRREC6", size: 184, elements: !270)
!270 = !{!271, !272, !273, !274, !275}
!271 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !269, baseType: !228, size: 16, flags: DIFlagArtificial)
!272 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !269, baseType: !228, size: 16, offset: 16, flags: DIFlagArtificial)
!273 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !269, baseType: !26, size: 32, offset: 32, flags: DIFlagArtificial)
!274 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !269, baseType: !101, size: 64, offset: 64, flags: DIFlagArtificial)
!275 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !269, baseType: !276, size: 56, offset: 128, flags: DIFlagArtificial)
!180 = !DIDerivedType(tag: DW_TAG_typedef, name: "ansistrrec6", baseType: !269)
!277 = !{!278}
!278 = !DISubrange(count: 7, lowerBound: 0)
!276 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !218, elements: !277, size: 56)
!279 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$ANSISTRREC10", size: 216, elements: !280)
!280 = !{!281, !282, !283, !284, !285}
!281 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !279, baseType: !228, size: 16, flags: DIFlagArtificial)
!282 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !279, baseType: !228, size: 16, offset: 16, flags: DIFlagArtificial)
!283 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !279, baseType: !26, size: 32, offset: 32, flags: DIFlagArtificial)
!284 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !279, baseType: !101, size: 64, offset: 64, flags: DIFlagArtificial)
!285 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !279, baseType: !286, size: 88, offset: 128, flags: DIFlagArtificial)
!181 = !DIDerivedType(tag: DW_TAG_typedef, name: "ansistrrec10", baseType: !279)
!287 = !{!288}
!288 = !DISubrange(count: 11, lowerBound: 0)
!286 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !218, elements: !287, size: 88)
!289 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$ANSISTRREC52", size: 552, elements: !290)
!290 = !{!291, !292, !293, !294, !295}
!291 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !289, baseType: !228, size: 16, flags: DIFlagArtificial)
!292 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !289, baseType: !228, size: 16, offset: 16, flags: DIFlagArtificial)
!293 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !289, baseType: !26, size: 32, offset: 32, flags: DIFlagArtificial)
!294 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !289, baseType: !101, size: 64, offset: 64, flags: DIFlagArtificial)
!295 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !289, baseType: !296, size: 424, offset: 128, flags: DIFlagArtificial)
!182 = !DIDerivedType(tag: DW_TAG_typedef, name: "ansistrrec52", baseType: !289)
!297 = !{!298}
!298 = !DISubrange(count: 53, lowerBound: 0)
!296 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !218, elements: !297, size: 424)
!299 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$ANSISTRREC60", size: 616, elements: !300)
!300 = !{!301, !302, !303, !304, !305}
!301 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !299, baseType: !228, size: 16, flags: DIFlagArtificial)
!302 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !299, baseType: !228, size: 16, offset: 16, flags: DIFlagArtificial)
!303 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !299, baseType: !26, size: 32, offset: 32, flags: DIFlagArtificial)
!304 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !299, baseType: !101, size: 64, offset: 64, flags: DIFlagArtificial)
!305 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !299, baseType: !306, size: 488, offset: 128, flags: DIFlagArtificial)
!183 = !DIDerivedType(tag: DW_TAG_typedef, name: "ansistrrec60", baseType: !299)
!307 = !{!308}
!308 = !DISubrange(count: 61, lowerBound: 0)
!306 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !218, elements: !307, size: 488)
!309 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$RTTIDEF$RTTI_$P$BT_$$_DEF00000009", file: !7, line: 106, size: 344, elements: !310)
!310 = !{!311, !313, !315}
!311 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !309, file: !7, line: 106, baseType: !312, size: 8, flags: DIFlagArtificial)
!313 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !309, file: !7, line: 106, baseType: !314, size: 8, offset: 8, flags: DIFlagArtificial)
!315 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !309, file: !7, line: 106, baseType: !185, size: 328, offset: 16, flags: DIFlagArtificial)
!184 = !DIDerivedType(tag: DW_TAG_typedef, name: "rttidef$RTTI_$P$BT_$$_def00000009", file: !7, line: 106, baseType: !309)
!316 = !{!317}
!317 = !DISubrange(count: 1, lowerBound: 0)
!314 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !218, elements: !316, size: 8)
!318 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$RTTI_NORMAL_ARRAY$1", file: !7, line: 106, size: 328, elements: !319)
!319 = !{!320, !321}
!320 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !318, file: !7, line: 106, baseType: !220, size: 64, flags: DIFlagArtificial)
!321 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !318, file: !7, line: 106, baseType: !186, size: 264, offset: 64, flags: DIFlagArtificial)
!185 = !DIDerivedType(tag: DW_TAG_typedef, name: "rtti_normal_array$1", file: !7, line: 106, baseType: !318)
!322 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$RTTI_NORMAL_ARRAY_INNER$1", file: !7, line: 106, size: 264, elements: !323)
!323 = !{!324, !326, !327, !328, !329}
!324 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !322, file: !7, line: 106, baseType: !325, size: 64, flags: DIFlagArtificial)
!326 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !322, file: !7, line: 106, baseType: !325, size: 64, offset: 64, flags: DIFlagArtificial)
!327 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !322, file: !7, line: 106, baseType: !220, size: 64, offset: 128, flags: DIFlagArtificial)
!328 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !322, file: !7, line: 106, baseType: !312, size: 8, offset: 192, flags: DIFlagArtificial)
!329 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !322, file: !7, line: 106, baseType: !220, size: 64, offset: 200, flags: DIFlagArtificial)
!186 = !DIDerivedType(tag: DW_TAG_typedef, name: "rtti_normal_array_inner$1", file: !7, line: 106, baseType: !322)
!330 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$RTTIDEF$RTTI_$P$BT_$$_DEF00000015", file: !7, line: 106, size: 344, elements: !331)
!331 = !{!332, !333, !334}
!332 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !330, file: !7, line: 106, baseType: !312, size: 8, flags: DIFlagArtificial)
!333 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !330, file: !7, line: 106, baseType: !314, size: 8, offset: 8, flags: DIFlagArtificial)
!334 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !330, file: !7, line: 106, baseType: !185, size: 328, offset: 16, flags: DIFlagArtificial)
!187 = !DIDerivedType(tag: DW_TAG_typedef, name: "rttidef$RTTI_$P$BT_$$_def00000015", file: !7, line: 106, baseType: !330)
!335 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$RTTIDEF$RTTI_$P$BT_$$_DEF00000019", file: !7, line: 106, size: 424, elements: !336)
!336 = !{!337, !338, !339}
!337 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !335, file: !7, line: 106, baseType: !312, size: 8, flags: DIFlagArtificial)
!338 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !335, file: !7, line: 106, baseType: !286, size: 88, offset: 8, flags: DIFlagArtificial)
!339 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !335, file: !7, line: 106, baseType: !185, size: 328, offset: 96, flags: DIFlagArtificial)
!188 = !DIDerivedType(tag: DW_TAG_typedef, name: "rttidef$RTTI_$P$BT_$$_def00000019", file: !7, line: 106, baseType: !335)
!340 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$RTTIDEF$RTTI_$P$BT_$$_DEF0000001F", file: !7, line: 106, size: 344, elements: !341)
!341 = !{!342, !343, !344}
!342 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !340, file: !7, line: 106, baseType: !312, size: 8, flags: DIFlagArtificial)
!343 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !340, file: !7, line: 106, baseType: !314, size: 8, offset: 8, flags: DIFlagArtificial)
!344 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !340, file: !7, line: 106, baseType: !185, size: 328, offset: 16, flags: DIFlagArtificial)
!189 = !DIDerivedType(tag: DW_TAG_typedef, name: "rttidef$RTTI_$P$BT_$$_def0000001F", file: !7, line: 106, baseType: !340)
!345 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "$RTTIDEF$RTTI_$P$BT_$$_DEF00000020", file: !7, line: 106, size: 344, elements: !346)
!346 = !{!347, !348, !349}
!347 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !345, file: !7, line: 106, baseType: !312, size: 8, flags: DIFlagArtificial)
!348 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !345, file: !7, line: 106, baseType: !314, size: 8, offset: 8, flags: DIFlagArtificial)
!349 = !DIDerivedType(tag: DW_TAG_member, name: "", scope: !345, file: !7, line: 106, baseType: !185, size: 328, offset: 16, flags: DIFlagArtificial)
!190 = !DIDerivedType(tag: DW_TAG_typedef, name: "rttidef$RTTI_$P$BT_$$_def00000020", file: !7, line: 106, baseType: !345)
!350 = !{!351}
!351 = !DISubrange(count: 9, lowerBound: 0)
!268 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !218, elements: !350, size: 72)
; Defs - End Staticsymtable
!352 = !{!353}
!353 = !DISubrange(count: 32, lowerBound: 0)
!24 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !220, elements: !352, size: 2048)
!354 = !DISubrange(lowerBound: 0, count: 2)
!355 = !{!354}
!99 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !10, size: 128, elements: !355)
!356 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !218)
!224 = !DIDerivedType(tag: DW_TAG_typedef, name: "char_pointer", file: !214, line: 23, baseType: !356)
!357 = !DIBasicType(size: 16, encoding: DW_ATE_unsigned)
!228 = !DIDerivedType(tag: DW_TAG_typedef, name: "WORD", file: !214, line: 23, baseType: !357)
!358 = !DIBasicType(size: 32, encoding: DW_ATE_unsigned)
!240 = !DIDerivedType(tag: DW_TAG_typedef, name: "LONGWORD", file: !214, line: 23, baseType: !358)
!359 = !DIBasicType(size: 8, encoding: DW_ATE_unsigned)
!312 = !DIDerivedType(tag: DW_TAG_typedef, name: "BYTE", file: !214, line: 23, baseType: !359)
!360 = !DIBasicType(size: 64, encoding: DW_ATE_unsigned)
!325 = !DIDerivedType(tag: DW_TAG_typedef, name: "QWORD", file: !214, line: 23, baseType: !360)
!2 = !{!168, !172, !174, !176}
!3 = !DIExpression()
!4 = !DIExpression(DW_OP_deref)
!5 = distinct !DICompileUnit(language: DW_LANG_Pascal83, file: !7, producer: "Free Pascal Compiler 3.3.1", isOptimized: false, emissionKind: FullDebug, enums: null, retainedTypes: null, globals: !2)
!llvm.dbg.cu = !{!5}
; End asmlist al_dwarf_info
; Begin asmlist al_dwarf_line
!7 = !DIFile(filename: "bt.pas", directory: "/mnt/c/Users/marce/Documents/GitHub/zos-pascal-llvm/pf5")
!8 = !DILocation(line: 15, column: 1, scope: !6)
!13 = !DILocation(line: 16, column: 6, scope: !6)
!14 = !DILocation(line: 16, column: 14, scope: !6)
!15 = !DILocation(line: 16, column: 32, scope: !6)
!16 = !DILocation(line: 17, column: 14, scope: !6)
!17 = !DILocation(line: 17, column: 32, scope: !6)
!18 = !DILocation(line: 17, column: 41, scope: !6)
!19 = !DILocation(line: 18, column: 1, scope: !6)
!21 = !DILocation(line: 25, column: 1, scope: !20)
!28 = !DILocation(line: 26, column: 51, scope: !20)
!29 = !DILocation(line: 26, column: 54, scope: !20)
!30 = !DILocation(line: 26, column: 8, scope: !20)
!31 = !DILocation(line: 26, column: 3, scope: !20)
!32 = !DILocation(line: 27, column: 10, scope: !20)
!33 = !DILocation(line: 27, column: 3, scope: !20)
!34 = !DILocation(line: 28, column: 3, scope: !20)
!35 = !DILocation(line: 28, column: 19, scope: !20)
!36 = !DILocation(line: 29, column: 22, scope: !20)
!37 = !DILocation(line: 29, column: 52, scope: !20)
!38 = !DILocation(line: 29, column: 40, scope: !20)
!39 = !DILocation(line: 29, column: 48, scope: !20)
!40 = !DILocation(line: 29, column: 50, scope: !20)
!41 = !DILocation(line: 29, column: 54, scope: !20)
!42 = !DILocation(line: 29, column: 12, scope: !20)
!43 = !DILocation(line: 0, scope: !20)
!44 = !DILocation(line: 30, column: 1, scope: !20)
!46 = !DILocation(line: 37, column: 1, scope: !45)
!48 = !DILocation(line: 38, column: 3, scope: !45)
!49 = !DILocation(line: 39, column: 20, scope: !45)
!50 = !DILocation(line: 39, column: 8, scope: !45)
!51 = !DILocation(line: 40, column: 8, scope: !45)
!52 = !DILocation(line: 40, column: 48, scope: !45)
!53 = !DILocation(line: 40, column: 14, scope: !45)
!54 = !DILocation(line: 41, column: 8, scope: !45)
!55 = !DILocation(line: 41, column: 23, scope: !45)
!56 = !DILocation(line: 41, column: 27, scope: !45)
!57 = !DILocation(line: 42, column: 8, scope: !45)
!58 = !DILocation(line: 0, scope: !45)
!59 = !DILocation(line: 44, column: 1, scope: !45)
!61 = !DILocation(line: 47, column: 1, scope: !60)
!63 = !DILocation(line: 48, column: 3, scope: !60)
!64 = !DILocation(line: 49, column: 1, scope: !60)
!66 = !DILocation(line: 52, column: 1, scope: !65)
!68 = !DILocation(line: 53, column: 3, scope: !65)
!69 = !DILocation(line: 54, column: 1, scope: !65)
!71 = !DILocation(line: 60, column: 1, scope: !70)
!76 = !DILocation(line: 61, column: 42, scope: !70)
!77 = !DILocation(line: 61, column: 29, scope: !70)
!78 = !DILocation(line: 61, column: 40, scope: !70)
!79 = !DILocation(line: 61, column: 10, scope: !70)
!80 = !DILocation(line: 62, column: 13, scope: !70)
!81 = !DILocation(line: 62, column: 3, scope: !70)
!82 = !DILocation(line: 63, column: 3, scope: !70)
!83 = !DILocation(line: 63, column: 17, scope: !70)
!84 = !DILocation(line: 63, column: 34, scope: !70)
!85 = !DILocation(line: 64, column: 22, scope: !70)
!86 = !DILocation(line: 64, column: 52, scope: !70)
!87 = !DILocation(line: 64, column: 40, scope: !70)
!88 = !DILocation(line: 64, column: 41, scope: !70)
!89 = !DILocation(line: 64, column: 48, scope: !70)
!90 = !DILocation(line: 64, column: 50, scope: !70)
!91 = !DILocation(line: 64, column: 54, scope: !70)
!92 = !DILocation(line: 64, column: 12, scope: !70)
!93 = !DILocation(line: 0, scope: !70)
!94 = !DILocation(line: 65, column: 1, scope: !70)
!96 = !DILocation(line: 70, column: 1, scope: !95)
!106 = !DILocation(line: 71, column: 3, scope: !95)
!107 = !DILocation(line: 72, column: 3, scope: !95)
!108 = !DILocation(line: 73, column: 3, scope: !95)
!109 = !DILocation(line: 73, column: 29, scope: !95)
!110 = !DILocation(line: 75, column: 16, scope: !95)
!111 = !DILocation(line: 75, column: 22, scope: !95)
!112 = !DILocation(line: 75, column: 24, scope: !95)
!113 = !DILocation(line: 75, column: 12, scope: !95)
!114 = !DILocation(line: 75, column: 7, scope: !95)
!115 = !DILocation(line: 76, column: 10, scope: !95)
!116 = !DILocation(line: 76, column: 21, scope: !95)
!117 = !DILocation(line: 77, column: 20, scope: !95)
!118 = !DILocation(line: 77, column: 9, scope: !95)
!119 = !DILocation(line: 76, column: 7, scope: !95)
!120 = !DILocation(line: 78, column: 7, scope: !95)
!121 = !DILocation(line: 80, column: 1, scope: !95)
!123 = !DILocation(line: 0, scope: !122)
!129 = !DILocation(line: 82, column: 1, scope: !128)
!130 = !DILocation(line: 83, column: 18, scope: !128)
!131 = !DILocation(line: 84, column: 5, scope: !128)
!132 = !DILocation(line: 85, column: 23, scope: !128)
!133 = !DILocation(line: 86, column: 5, scope: !128)
!134 = !DILocation(line: 89, column: 7, scope: !128)
!135 = !DILocation(line: 90, column: 7, scope: !128)
!136 = !DILocation(line: 92, column: 30, scope: !128)
!137 = !DILocation(line: 92, column: 73, scope: !128)
!138 = !DILocation(line: 92, column: 40, scope: !128)
!139 = !DILocation(line: 92, column: 50, scope: !128)
!140 = !DILocation(line: 92, column: 60, scope: !128)
!141 = !DILocation(line: 92, column: 74, scope: !128)
!142 = !DILocation(line: 91, column: 7, scope: !128)
!143 = !DILocation(line: 91, column: 67, scope: !128)
!144 = !DILocation(line: 93, column: 7, scope: !128)
!145 = !DILocation(line: 94, column: 9, scope: !128)
!146 = !DILocation(line: 0, scope: !128)
!147 = !DILocation(line: 97, column: 41, scope: !128)
!148 = !DILocation(line: 97, column: 26, scope: !128)
!149 = !DILocation(line: 97, column: 11, scope: !128)
!150 = !DILocation(line: 99, column: 7, scope: !128)
!151 = !DILocation(line: 101, column: 33, scope: !128)
!152 = !DILocation(line: 101, column: 76, scope: !128)
!153 = !DILocation(line: 101, column: 43, scope: !128)
!154 = !DILocation(line: 101, column: 53, scope: !128)
!155 = !DILocation(line: 101, column: 63, scope: !128)
!156 = !DILocation(line: 101, column: 77, scope: !128)
!157 = !DILocation(line: 100, column: 7, scope: !128)
!158 = !DILocation(line: 100, column: 75, scope: !128)
!159 = !DILocation(line: 102, column: 7, scope: !128)
!160 = !DILocation(line: 102, column: 25, scope: !128)
!161 = !DILocation(line: 102, column: 33, scope: !128)
!162 = !DILocation(line: 103, column: 7, scope: !128)
!163 = !DILocation(line: 105, column: 1, scope: !128)
!166 = !DILocation(line: 0, scope: !165)
!214 = !DIFile(filename: "system.pp", directory: "/mnt/c/Users/marce/Documents/GitHub/zos-pascal-llvm/pf5")
!221 = !DIFile(filename: "systemh.inc", directory: "/mnt/c/Users/marce/Documents/GitHub/zos-pascal-llvm/pf5")
; End asmlist al_dwarf_line



; z/OS-Debugger (zdbg-instrument.py)
declare void @FPC_ZOS_DBG_ENTER(ptr)
declare void @FPC_ZOS_DBG_LINE(ptr, i32 signext)
@zdbg.s.0 = internal global [9 x i8] c"CAPTURED\00", align 1
@zdbg.s.1 = internal global [11 x i8] c"ANSISTRING\00", align 1
@zdbg.t.10 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.1, i32 9, i32 0, ptr null, i32 0, i32 0, ptr null }, align 8
@zdbg.s.2 = internal global [12 x i8] c"EXCEPTTRACE\00", align 1
@zdbg.s.3 = internal global [7 x i8] c"ERRORS\00", align 1
@zdbg.s.4 = internal global [8 x i8] c"LONGINT\00", align 1
@zdbg.t.26 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.4, i32 1, i32 4, ptr null, i32 0, i32 0, ptr null }, align 8
@zdbg.s.5 = internal global [5 x i8] c"ZERO\00", align 1
@zdbg.globals = internal global [4 x { ptr, ptr, ptr }] [{ ptr, ptr, ptr } { ptr @zdbg.s.0, ptr @"U_$P$BT_$$_CAPTURED", ptr @zdbg.t.10 }, { ptr, ptr, ptr } { ptr @zdbg.s.2, ptr @"U_$P$BT_$$_EXCEPTTRACE", ptr @zdbg.t.10 }, { ptr, ptr, ptr } { ptr @zdbg.s.3, ptr @"TC_$P$BT_$$_ERRORS", ptr @zdbg.t.26 }, { ptr, ptr, ptr } { ptr @zdbg.s.5, ptr @"TC_$P$BT_$$_ZERO", ptr @zdbg.t.26 }], align 8
@zdbg.module = internal global { i32, ptr } { i32 4, ptr @zdbg.globals }, align 8
@zdbg.s.6 = internal global [5 x i8] c"WHAT\00", align 1
@zdbg.s.7 = internal global [3 x i8] c"OK\00", align 1
@zdbg.s.8 = internal global [8 x i8] c"BOOLEAN\00", align 1
@zdbg.t.12 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.8, i32 4, i32 1, ptr null, i32 0, i32 0, ptr null }, align 8
@zdbg.v.0 = internal global [2 x { ptr, ptr, i32, i32 }] [{ ptr, ptr, i32, i32 } { ptr @zdbg.s.6, ptr @zdbg.t.10, i32 1, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.7, ptr @zdbg.t.12, i32 1, i32 0 }], align 8
@zdbg.s.9 = internal global [6 x i8] c"CHECK\00", align 1
@zdbg.s.10 = internal global [7 x i8] c"bt.pas\00", align 1
@zdbg.f.0 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.9, ptr @zdbg.s.10, i32 2, i32 0, ptr @zdbg.v.0, ptr @zdbg.module }, align 8
@zdbg.s.11 = internal global [7 x i8] c"result\00", align 1
@zdbg.s.12 = internal global [7 x i8] c"FRAMES\00", align 1
@zdbg.s.13 = internal global [8 x i8] c"POINTER\00", align 1
@zdbg.t.220 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.13, i32 6, i32 8, ptr null, i32 0, i32 0, ptr null }, align 8
@zdbg.s.14 = internal global [2 x i8] c"?\00", align 1
@zdbg.t.24 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.14, i32 8, i32 256, ptr @zdbg.t.220, i32 32, i32 0, ptr null }, align 8
@zdbg.s.15 = internal global [2 x i8] c"N\00", align 1
@zdbg.s.16 = internal global [2 x i8] c"I\00", align 1
@zdbg.v.1 = internal global [4 x { ptr, ptr, i32, i32 }] [{ ptr, ptr, i32, i32 } { ptr @zdbg.s.11, ptr @zdbg.t.10, i32 1, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.12, ptr @zdbg.t.24, i32 0, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.15, ptr @zdbg.t.26, i32 0, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.16, ptr @zdbg.t.26, i32 0, i32 0 }], align 8
@zdbg.s.17 = internal global [14 x i8] c"CAPTURE_LINES\00", align 1
@zdbg.f.1 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.17, ptr @zdbg.s.10, i32 4, i32 0, ptr @zdbg.v.1, ptr @zdbg.module }, align 8
@zdbg.s.18 = internal global [5 x i8] c"MODE\00", align 1
@zdbg.v.2 = internal global [1 x { ptr, ptr, i32, i32 }] [{ ptr, ptr, i32, i32 } { ptr @zdbg.s.18, ptr @zdbg.t.26, i32 1, i32 0 }], align 8
@zdbg.s.19 = internal global [7 x i8] c"LEVEL3\00", align 1
@zdbg.f.2 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.19, ptr @zdbg.s.10, i32 1, i32 0, ptr @zdbg.v.2, ptr @zdbg.module }, align 8
@zdbg.v.3 = internal global [1 x { ptr, ptr, i32, i32 }] [{ ptr, ptr, i32, i32 } { ptr @zdbg.s.18, ptr @zdbg.t.26, i32 1, i32 0 }], align 8
@zdbg.s.20 = internal global [7 x i8] c"LEVEL2\00", align 1
@zdbg.f.3 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.20, ptr @zdbg.s.10, i32 1, i32 0, ptr @zdbg.v.3, ptr @zdbg.module }, align 8
@zdbg.v.4 = internal global [1 x { ptr, ptr, i32, i32 }] [{ ptr, ptr, i32, i32 } { ptr @zdbg.s.18, ptr @zdbg.t.26, i32 1, i32 0 }], align 8
@zdbg.s.21 = internal global [7 x i8] c"LEVEL1\00", align 1
@zdbg.f.4 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.21, ptr @zdbg.s.10, i32 1, i32 0, ptr @zdbg.v.4, ptr @zdbg.module }, align 8
@zdbg.s.22 = internal global [13 x i8] c"PCODEPOINTER\00", align 1
@zdbg.t.75 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.22, i32 6, i32 8, ptr @zdbg.t.220, i32 0, i32 0, ptr null }, align 8
@zdbg.v.5 = internal global [3 x { ptr, ptr, i32, i32 }] [{ ptr, ptr, i32, i32 } { ptr @zdbg.s.11, ptr @zdbg.t.10, i32 1, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.16, ptr @zdbg.t.26, i32 0, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.12, ptr @zdbg.t.75, i32 0, i32 0 }], align 8
@zdbg.s.23 = internal global [16 x i8] c"EXCEPTION_TRACE\00", align 1
@zdbg.f.5 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.23, ptr @zdbg.s.10, i32 3, i32 0, ptr @zdbg.v.5, ptr @zdbg.module }, align 8
@zdbg.s.24 = internal global [2 x i8] c"S\00", align 1
@zdbg.s.25 = internal global [6 x i8] c"NAMES\00", align 1
@zdbg.t.99 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.14, i32 8, i32 16, ptr @zdbg.t.10, i32 2, i32 0, ptr null }, align 8
@zdbg.s.26 = internal global [10 x i8] c"highNAMES\00", align 1
@zdbg.s.27 = internal global [6 x i8] c"INT64\00", align 1
@zdbg.t.101 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.27, i32 1, i32 8, ptr null, i32 0, i32 0, ptr null }, align 8
@zdbg.s.28 = internal global [2 x i8] c"P\00", align 1
@zdbg.s.29 = internal global [2 x i8] c"Q\00", align 1
@zdbg.v.6 = internal global [7 x { ptr, ptr, i32, i32 }] [{ ptr, ptr, i32, i32 } { ptr @zdbg.s.24, ptr @zdbg.t.10, i32 1, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.25, ptr @zdbg.t.99, i32 1, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.26, ptr @zdbg.t.101, i32 1, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.11, ptr @zdbg.t.12, i32 0, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.16, ptr @zdbg.t.26, i32 0, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.28, ptr @zdbg.t.26, i32 0, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.29, ptr @zdbg.t.26, i32 0, i32 0 }], align 8
@zdbg.s.30 = internal global [10 x i8] c"HAS_ORDER\00", align 1
@zdbg.f.6 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.30, ptr @zdbg.s.10, i32 7, i32 0, ptr @zdbg.v.6, ptr @zdbg.module }, align 8
@zdbg.s.31 = internal global [5 x i8] c"ARGC\00", align 1
@zdbg.s.32 = internal global [5 x i8] c"ARGV\00", align 1
@zdbg.s.33 = internal global [9 x i8] c"ANSICHAR\00", align 1
@zdbg.t.218 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.33, i32 5, i32 1, ptr null, i32 0, i32 0, ptr null }, align 8
@zdbg.s.34 = internal global [13 x i8] c"char_pointer\00", align 1
@zdbg.t.224 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.34, i32 6, i32 8, ptr @zdbg.t.218, i32 0, i32 0, ptr null }, align 8
@zdbg.t.126 = internal global { ptr, i32, i32, ptr, i32, i32, ptr } { ptr @zdbg.s.14, i32 6, i32 8, ptr @zdbg.t.224, i32 0, i32 0, ptr null }, align 8
@zdbg.s.35 = internal global [5 x i8] c"ARGP\00", align 1
@zdbg.v.7 = internal global [3 x { ptr, ptr, i32, i32 }] [{ ptr, ptr, i32, i32 } { ptr @zdbg.s.31, ptr @zdbg.t.26, i32 1, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.32, ptr @zdbg.t.126, i32 1, i32 0 }, { ptr, ptr, i32, i32 } { ptr @zdbg.s.35, ptr @zdbg.t.126, i32 1, i32 0 }], align 8
@zdbg.s.36 = internal global [5 x i8] c"main\00", align 1
@zdbg.f.7 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.36, ptr @zdbg.s.10, i32 3, i32 0, ptr @zdbg.v.7, ptr @zdbg.module }, align 8
@zdbg.v.8 = internal global [0 x { ptr, ptr, i32, i32 }] [], align 8
@zdbg.s.37 = internal global [11 x i8] c"PASCALMAIN\00", align 1
@zdbg.f.8 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.37, ptr @zdbg.s.10, i32 0, i32 0, ptr @zdbg.v.8, ptr @zdbg.module }, align 8
@zdbg.v.9 = internal global [0 x { ptr, ptr, i32, i32 }] [], align 8
@zdbg.s.38 = internal global [23 x i8] c"P$BT_$$_init_implicit$\00", align 1
@zdbg.f.9 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.38, ptr @zdbg.s.10, i32 0, i32 0, ptr @zdbg.v.9, ptr @zdbg.module }, align 8
@zdbg.v.10 = internal global [0 x { ptr, ptr, i32, i32 }] [], align 8
@zdbg.s.39 = internal global [27 x i8] c"P$BT_$$_finalize_implicit$\00", align 1
@zdbg.f.10 = internal global { ptr, ptr, i32, i32, ptr, ptr } { ptr @zdbg.s.39, ptr @zdbg.s.10, i32 0, i32 0, ptr @zdbg.v.10, ptr @zdbg.module }, align 8
