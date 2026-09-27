{ Minimal system unit for the first z/OS test (PF0) - not the real RTL.
  Only what the compiler needs for a program without strings, I/O or
  exceptions; output goes through the C runtime (puts). }
unit system;

interface

{$mode fpc}

type
  hresult = longint;
  sizeint = int64;
  sizeuint = qword;
  ptrint = int64;
  ptruint = qword;
  cardinal = longword;
  char = ansichar;
  pchar = ^char;
  ppchar = ^pchar;
  TTypeKind = (tkUnknown);
  jmp_buf = record
    regs: array[0..31] of int64;
  end;
  pjmp_buf = ^jmp_buf;
  TGUID = record
    D1: longword;
    D2: word;
    D3: word;
    D4: array[0..7] of byte;
  end;
  PExceptAddr = ^TExceptAddr;
  TExceptAddr = record
    buf: pjmp_buf;
    next: PExceptAddr;
    frametype: longint;
  end;

function puts(s: pchar): longint; cdecl; external 'c' name '@@A00304'; { ASCII variant of puts }
procedure c_exit(code: longint); cdecl; noreturn; external 'c' name 'exit';

{ LLVM intrinsics used by the code generator (from rtl/inc/llvmintr.inc) }
procedure llvm_memcpy64(dest, source: pointer; len: qword; align: cardinal; isvolatile: LLVMBool1); compilerproc; external name 'llvm.memcpy.p0i8.p0i8.i64';
procedure llvm_memcpy64_indivalign(dest, source: pointer; len: qword; isvolatile: LLVMBool1); compilerproc; external name 'llvm.memcpy.p0i8.p0i8.i64';
function llvm_frameaddress(level: longint): pointer; compilerproc; external name 'llvm.frameaddress';
function llvm_eh_typeid_for(sym: pointer): longint; compilerproc; external name 'llvm.eh.typeid.for';
procedure llvm_lifetime_start(size: int64; ptr: pointer); compilerproc; external name 'llvm.lifetime.start';
procedure llvm_lifetime_end(size: int64; ptr: pointer); compilerproc; external name 'llvm.lifetime.end';

procedure fpc_initializeunits; compilerproc;
procedure fpc_do_exit; compilerproc;

var
  exitcode: longint = 0;

implementation

procedure fpc_initializeunits; [public, alias: 'FPC_INITIALIZEUNITS']; compilerproc;
begin
end;

procedure fpc_do_exit; [public, alias: 'FPC_DO_EXIT']; compilerproc;
begin
  c_exit(exitcode);
end;

end.
