; Minimaltest: bindet ein Objekt mit LSDA (Landing Pad) auf z/OS?
; llc -mtriple=s390x-ibm-zos -filetype=obj ehbind.ll -o ehbind.o ; zos-ld exe ...
target datalayout = "E-S64-m:l-p1:32:32-i1:8:16-i8:8:16-i64:64-f128:64-v128:64-a:8:16-n32:64"
target triple = "s390x-ibm-zos"

define void @may_throw() {
  ret void
}
define i32 @_FPC_psabieh_personality_v0() {
  ret i32 0
}


define i32 @with_lpad() personality ptr @_FPC_psabieh_personality_v0 {
entry:
  invoke void @may_throw()
          to label %ok unwind label %lpad
ok:
  ret i32 42
lpad:
  %lp = landingpad { ptr, i32 } cleanup
  ret i32 1
}

define i32 @main() {
  %r = call i32 @with_lpad()
  ret i32 %r
}
