; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --scrub-attributes --check-attributes
; RUN: opt -attributor -enable-new-pm=0 -attributor-manifest-internal  -attributor-max-iterations-verify -attributor-annotate-decl-cs -attributor-max-iterations=5 -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_CGSCC_NPM,NOT_CGSCC_OPM,NOT_TUNIT_NPM,IS__TUNIT____,IS________OPM,IS__TUNIT_OPM
; RUN: opt -aa-pipeline=basic-aa -passes=attributor -attributor-manifest-internal  -attributor-max-iterations-verify -attributor-annotate-decl-cs -attributor-max-iterations=5 -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_CGSCC_OPM,NOT_CGSCC_NPM,NOT_TUNIT_OPM,IS__TUNIT____,IS________NPM,IS__TUNIT_NPM
; RUN: opt -attributor-cgscc -enable-new-pm=0 -attributor-manifest-internal  -attributor-annotate-decl-cs -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_TUNIT_NPM,NOT_TUNIT_OPM,NOT_CGSCC_NPM,IS__CGSCC____,IS________OPM,IS__CGSCC_OPM
; RUN: opt -aa-pipeline=basic-aa -passes=attributor-cgscc -attributor-manifest-internal  -attributor-annotate-decl-cs -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_TUNIT_NPM,NOT_TUNIT_OPM,NOT_CGSCC_OPM,IS__CGSCC____,IS________NPM,IS__CGSCC_NPM


@x = global i32 0

declare void @test1_1(i8* %x1_1, i8* readonly %y1_1, ...)

; NOTE: readonly for %y1_2 would be OK here but not for the similar situation in test13.
;
define void @test1_2(i8* %x1_2, i8* %y1_2, i8* %z1_2) {
; CHECK-LABEL: define {{[^@]+}}@test1_2
; CHECK-SAME: (i8* [[X1_2:%.*]], i8* [[Y1_2:%.*]], i8* [[Z1_2:%.*]])
; CHECK-NEXT:    call void (i8*, i8*, ...) @test1_1(i8* [[X1_2]], i8* readonly [[Y1_2]], i8* [[Z1_2]])
; CHECK-NEXT:    store i32 0, i32* @x, align 4
; CHECK-NEXT:    ret void
;
  call void (i8*, i8*, ...) @test1_1(i8* %x1_2, i8* %y1_2, i8* %z1_2)
  store i32 0, i32* @x
  ret void
}

define i8* @test2(i8* %p) {
; IS__TUNIT____: Function Attrs: nofree nosync nounwind willreturn writeonly
; IS__TUNIT____-LABEL: define {{[^@]+}}@test2
; IS__TUNIT____-SAME: (i8* nofree readnone returned "no-capture-maybe-returned" [[P:%.*]])
; IS__TUNIT____-NEXT:    store i32 0, i32* @x, align 4
; IS__TUNIT____-NEXT:    ret i8* [[P]]
;
; IS__CGSCC____: Function Attrs: nofree norecurse nosync nounwind willreturn writeonly
; IS__CGSCC____-LABEL: define {{[^@]+}}@test2
; IS__CGSCC____-SAME: (i8* nofree readnone returned "no-capture-maybe-returned" [[P:%.*]])
; IS__CGSCC____-NEXT:    store i32 0, i32* @x, align 4
; IS__CGSCC____-NEXT:    ret i8* [[P]]
;
  store i32 0, i32* @x
  ret i8* %p
}

define i1 @test3(i8* %p, i8* %q) {
; IS__TUNIT____: Function Attrs: nofree nosync nounwind readnone willreturn
; IS__TUNIT____-LABEL: define {{[^@]+}}@test3
; IS__TUNIT____-SAME: (i8* nofree readnone [[P:%.*]], i8* nofree readnone [[Q:%.*]])
; IS__TUNIT____-NEXT:    [[A:%.*]] = icmp ult i8* [[P]], [[Q]]
; IS__TUNIT____-NEXT:    ret i1 [[A]]
;
; IS__CGSCC____: Function Attrs: nofree norecurse nosync nounwind readnone willreturn
; IS__CGSCC____-LABEL: define {{[^@]+}}@test3
; IS__CGSCC____-SAME: (i8* nofree readnone [[P:%.*]], i8* nofree readnone [[Q:%.*]])
; IS__CGSCC____-NEXT:    [[A:%.*]] = icmp ult i8* [[P]], [[Q]]
; IS__CGSCC____-NEXT:    ret i1 [[A]]
;
  %A = icmp ult i8* %p, %q
  ret i1 %A
}

declare void @test4_1(i8* nocapture) readonly

define void @test4_2(i8* %p) {
; CHECK: Function Attrs: readonly
; CHECK-LABEL: define {{[^@]+}}@test4_2
; CHECK-SAME: (i8* nocapture readonly [[P:%.*]])
; CHECK-NEXT:    call void @test4_1(i8* nocapture readonly [[P]])
; CHECK-NEXT:    ret void
;
  call void @test4_1(i8* %p)
  ret void
}

; Missed optz'n: we could make %q readnone, but don't break test6!
define void @test5(i8** %p, i8* %q) {
; IS__TUNIT____: Function Attrs: argmemonly nofree nosync nounwind willreturn writeonly
; IS__TUNIT____-LABEL: define {{[^@]+}}@test5
; IS__TUNIT____-SAME: (i8** nocapture nofree nonnull writeonly align 8 dereferenceable(8) [[P:%.*]], i8* nofree writeonly [[Q:%.*]])
; IS__TUNIT____-NEXT:    store i8* [[Q]], i8** [[P]], align 8
; IS__TUNIT____-NEXT:    ret void
;
; IS__CGSCC____: Function Attrs: argmemonly nofree norecurse nosync nounwind willreturn writeonly
; IS__CGSCC____-LABEL: define {{[^@]+}}@test5
; IS__CGSCC____-SAME: (i8** nocapture nofree nonnull writeonly align 8 dereferenceable(8) [[P:%.*]], i8* nofree writeonly [[Q:%.*]])
; IS__CGSCC____-NEXT:    store i8* [[Q]], i8** [[P]], align 8
; IS__CGSCC____-NEXT:    ret void
;
  store i8* %q, i8** %p
  ret void
}

declare void @test6_1()
; This is not a missed optz'n.
define void @test6_2(i8** %p, i8* %q) {
; CHECK-LABEL: define {{[^@]+}}@test6_2
; CHECK-SAME: (i8** nocapture nonnull writeonly align 8 dereferenceable(8) [[P:%.*]], i8* [[Q:%.*]])
; CHECK-NEXT:    store i8* [[Q]], i8** [[P]], align 8
; CHECK-NEXT:    call void @test6_1()
; CHECK-NEXT:    ret void
;
  store i8* %q, i8** %p
  call void @test6_1()
  ret void
}

; inalloca parameters are always considered written
define void @test7_1(i32* inalloca %a) {
; IS__TUNIT____: Function Attrs: nofree nosync nounwind readnone willreturn
; IS__TUNIT____-LABEL: define {{[^@]+}}@test7_1
; IS__TUNIT____-SAME: (i32* inalloca nocapture nofree writeonly [[A:%.*]])
; IS__TUNIT____-NEXT:    ret void
;
; IS__CGSCC____: Function Attrs: nofree norecurse nosync nounwind readnone willreturn
; IS__CGSCC____-LABEL: define {{[^@]+}}@test7_1
; IS__CGSCC____-SAME: (i32* inalloca nocapture nofree writeonly [[A:%.*]])
; IS__CGSCC____-NEXT:    ret void
;
  ret void
}

define i32* @test8_1(i32* %p) {
; IS__TUNIT____: Function Attrs: nofree nosync nounwind readnone willreturn
; IS__TUNIT____-LABEL: define {{[^@]+}}@test8_1
; IS__TUNIT____-SAME: (i32* nofree readnone returned "no-capture-maybe-returned" [[P:%.*]])
; IS__TUNIT____-NEXT:  entry:
; IS__TUNIT____-NEXT:    ret i32* [[P]]
;
; IS__CGSCC____: Function Attrs: nofree norecurse nosync nounwind readnone willreturn
; IS__CGSCC____-LABEL: define {{[^@]+}}@test8_1
; IS__CGSCC____-SAME: (i32* nofree readnone returned "no-capture-maybe-returned" [[P:%.*]])
; IS__CGSCC____-NEXT:  entry:
; IS__CGSCC____-NEXT:    ret i32* [[P]]
;
entry:
  ret i32* %p
}

define void @test8_2(i32* %p) {
; IS__TUNIT____: Function Attrs: nofree nosync nounwind willreturn writeonly
; IS__TUNIT____-LABEL: define {{[^@]+}}@test8_2
; IS__TUNIT____-SAME: (i32* nocapture nofree writeonly [[P:%.*]])
; IS__TUNIT____-NEXT:  entry:
; IS__TUNIT____-NEXT:    [[CALL:%.*]] = call i32* @test8_1(i32* noalias nofree readnone "no-capture-maybe-returned" [[P]])
; IS__TUNIT____-NEXT:    store i32 10, i32* [[CALL]], align 4
; IS__TUNIT____-NEXT:    ret void
;
; IS__CGSCC____: Function Attrs: argmemonly nofree norecurse nosync nounwind willreturn writeonly
; IS__CGSCC____-LABEL: define {{[^@]+}}@test8_2
; IS__CGSCC____-SAME: (i32* nofree writeonly [[P:%.*]])
; IS__CGSCC____-NEXT:  entry:
; IS__CGSCC____-NEXT:    [[CALL:%.*]] = call align 4 i32* @test8_1(i32* noalias nofree readnone [[P]])
; IS__CGSCC____-NEXT:    store i32 10, i32* [[CALL]], align 4
; IS__CGSCC____-NEXT:    ret void
;
entry:
  %call = call i32* @test8_1(i32* %p)
  store i32 10, i32* %call, align 4
  ret void
}

; CHECK: declare void @llvm.masked.scatter
declare void @llvm.masked.scatter.v4i32.v4p0i32(<4 x i32>%val, <4 x i32*>, i32, <4 x i1>)

; CHECK-NOT: readnone
; CHECK-NOT: readonly
define void @test9(<4 x i32*> %ptrs, <4 x i32>%val) {
; CHECK: Function Attrs: nofree nosync nounwind willreturn
; CHECK-LABEL: define {{[^@]+}}@test9
; CHECK-SAME: (<4 x i32*> [[PTRS:%.*]], <4 x i32> [[VAL:%.*]])
; CHECK-NEXT:    call void @llvm.masked.scatter.v4i32.v4p0i32(<4 x i32> [[VAL]], <4 x i32*> [[PTRS]], i32 4, <4 x i1> <i1 true, i1 false, i1 true, i1 false>)
; CHECK-NEXT:    ret void
;
  call void @llvm.masked.scatter.v4i32.v4p0i32(<4 x i32>%val, <4 x i32*> %ptrs, i32 4, <4 x i1><i1 true, i1 false, i1 true, i1 false>)
  ret void
}

; CHECK: declare <4 x i32> @llvm.masked.gather
declare <4 x i32> @llvm.masked.gather.v4i32.v4p0i32(<4 x i32*>, i32, <4 x i1>, <4 x i32>)
define <4 x i32> @test10(<4 x i32*> %ptrs) {
; CHECK: Function Attrs: nofree nosync nounwind readonly willreturn
; CHECK-LABEL: define {{[^@]+}}@test10
; CHECK-SAME: (<4 x i32*> [[PTRS:%.*]])
; CHECK-NEXT:    [[RES:%.*]] = call <4 x i32> @llvm.masked.gather.v4i32.v4p0i32(<4 x i32*> [[PTRS]], i32 4, <4 x i1> <i1 true, i1 false, i1 true, i1 false>, <4 x i32> undef)
; CHECK-NEXT:    ret <4 x i32> [[RES]]
;
  %res = call <4 x i32> @llvm.masked.gather.v4i32.v4p0i32(<4 x i32*> %ptrs, i32 4, <4 x i1><i1 true, i1 false, i1 true, i1 false>, <4 x i32>undef)
  ret <4 x i32> %res
}

; CHECK: declare <4 x i32> @test11_1
declare <4 x i32> @test11_1(<4 x i32*>) argmemonly nounwind readonly
define <4 x i32> @test11_2(<4 x i32*> %ptrs) {
; CHECK: Function Attrs: argmemonly nounwind readonly
; CHECK-LABEL: define {{[^@]+}}@test11_2
; CHECK-SAME: (<4 x i32*> [[PTRS:%.*]])
; CHECK-NEXT:    [[RES:%.*]] = call <4 x i32> @test11_1(<4 x i32*> [[PTRS]])
; CHECK-NEXT:    ret <4 x i32> [[RES]]
;
  %res = call <4 x i32> @test11_1(<4 x i32*> %ptrs)
  ret <4 x i32> %res
}

declare <4 x i32> @test12_1(<4 x i32*>) argmemonly nounwind
; CHECK-NOT: readnone
define <4 x i32> @test12_2(<4 x i32*> %ptrs) {
; CHECK: Function Attrs: argmemonly nounwind
; CHECK-LABEL: define {{[^@]+}}@test12_2
; CHECK-SAME: (<4 x i32*> [[PTRS:%.*]])
; CHECK-NEXT:    [[RES:%.*]] = call <4 x i32> @test12_1(<4 x i32*> [[PTRS]])
; CHECK-NEXT:    ret <4 x i32> [[RES]]
;
  %res = call <4 x i32> @test12_1(<4 x i32*> %ptrs)
  ret <4 x i32> %res
}

define i32 @volatile_load(i32* %p) {
; IS__TUNIT____: Function Attrs: argmemonly nofree nounwind willreturn
; IS__TUNIT____-LABEL: define {{[^@]+}}@volatile_load
; IS__TUNIT____-SAME: (i32* nofree align 4 [[P:%.*]])
; IS__TUNIT____-NEXT:    [[LOAD:%.*]] = load volatile i32, i32* [[P]], align 4
; IS__TUNIT____-NEXT:    ret i32 [[LOAD]]
;
; IS__CGSCC____: Function Attrs: argmemonly nofree norecurse nounwind willreturn
; IS__CGSCC____-LABEL: define {{[^@]+}}@volatile_load
; IS__CGSCC____-SAME: (i32* nofree align 4 [[P:%.*]])
; IS__CGSCC____-NEXT:    [[LOAD:%.*]] = load volatile i32, i32* [[P]], align 4
; IS__CGSCC____-NEXT:    ret i32 [[LOAD]]
;
  %load = load volatile i32, i32* %p
  ret i32 %load
}

declare void @escape_readnone_ptr(i8** %addr, i8* readnone %ptr)
declare void @escape_readonly_ptr(i8** %addr, i8* readonly %ptr)

; The argument pointer %escaped_then_written cannot be marked readnone/only even
; though the only direct use, in @escape_readnone_ptr/@escape_readonly_ptr,
; is marked as readnone/only. However, the functions can write the pointer into
; %addr, causing the store to write to %escaped_then_written.
;
define void @unsound_readnone(i8* %ignored, i8* %escaped_then_written) {
; CHECK-LABEL: define {{[^@]+}}@unsound_readnone
; CHECK-SAME: (i8* nocapture nofree readnone [[IGNORED:%.*]], i8* [[ESCAPED_THEN_WRITTEN:%.*]])
; CHECK-NEXT:    [[ADDR:%.*]] = alloca i8*, align 8
; CHECK-NEXT:    call void @escape_readnone_ptr(i8** nonnull align 8 dereferenceable(8) [[ADDR]], i8* noalias readnone [[ESCAPED_THEN_WRITTEN]])
; CHECK-NEXT:    [[ADDR_LD:%.*]] = load i8*, i8** [[ADDR]], align 8
; CHECK-NEXT:    store i8 0, i8* [[ADDR_LD]], align 1
; CHECK-NEXT:    ret void
;
  %addr = alloca i8*
  call void @escape_readnone_ptr(i8** %addr, i8* %escaped_then_written)
  %addr.ld = load i8*, i8** %addr
  store i8 0, i8* %addr.ld
  ret void
}

define void @unsound_readonly(i8* %ignored, i8* %escaped_then_written) {
; CHECK-LABEL: define {{[^@]+}}@unsound_readonly
; CHECK-SAME: (i8* nocapture nofree readnone [[IGNORED:%.*]], i8* [[ESCAPED_THEN_WRITTEN:%.*]])
; CHECK-NEXT:    [[ADDR:%.*]] = alloca i8*, align 8
; CHECK-NEXT:    call void @escape_readonly_ptr(i8** nonnull align 8 dereferenceable(8) [[ADDR]], i8* readonly [[ESCAPED_THEN_WRITTEN]])
; CHECK-NEXT:    [[ADDR_LD:%.*]] = load i8*, i8** [[ADDR]], align 8
; CHECK-NEXT:    store i8 0, i8* [[ADDR_LD]], align 1
; CHECK-NEXT:    ret void
;
  %addr = alloca i8*
  call void @escape_readonly_ptr(i8** %addr, i8* %escaped_then_written)
  %addr.ld = load i8*, i8** %addr
  store i8 0, i8* %addr.ld
  ret void
}

; Byval but not readonly/none tests
;
;{
declare void @escape_i8(i8* %ptr)

define void @byval_not_readonly_1(i8* byval %written) readonly {
; CHECK: Function Attrs: readonly
; CHECK-LABEL: define {{[^@]+}}@byval_not_readonly_1
; CHECK-SAME: (i8* noalias nonnull byval dereferenceable(1) [[WRITTEN:%.*]])
; CHECK-NEXT:    call void @escape_i8(i8* nonnull dereferenceable(1) [[WRITTEN]])
; CHECK-NEXT:    ret void
;
  call void @escape_i8(i8* %written)
  ret void
}

define void @byval_not_readonly_2(i8* byval %written) readonly {
; IS__TUNIT____: Function Attrs: nofree nosync nounwind readnone willreturn
; IS__TUNIT____-LABEL: define {{[^@]+}}@byval_not_readonly_2
; IS__TUNIT____-SAME: (i8* noalias nocapture nofree nonnull writeonly byval dereferenceable(1) [[WRITTEN:%.*]])
; IS__TUNIT____-NEXT:    store i8 0, i8* [[WRITTEN]], align 1
; IS__TUNIT____-NEXT:    ret void
;
; IS__CGSCC____: Function Attrs: nofree norecurse nosync nounwind readnone willreturn
; IS__CGSCC____-LABEL: define {{[^@]+}}@byval_not_readonly_2
; IS__CGSCC____-SAME: (i8* noalias nocapture nofree nonnull writeonly byval dereferenceable(1) [[WRITTEN:%.*]])
; IS__CGSCC____-NEXT:    store i8 0, i8* [[WRITTEN]], align 1
; IS__CGSCC____-NEXT:    ret void
;
  store i8 0, i8* %written
  ret void
}

define void @byval_not_readnone_1(i8* byval %written) readnone {
; CHECK: Function Attrs: readnone
; CHECK-LABEL: define {{[^@]+}}@byval_not_readnone_1
; CHECK-SAME: (i8* noalias nonnull byval dereferenceable(1) [[WRITTEN:%.*]])
; CHECK-NEXT:    call void @escape_i8(i8* nonnull dereferenceable(1) [[WRITTEN]])
; CHECK-NEXT:    ret void
;
  call void @escape_i8(i8* %written)
  ret void
}

define void @byval_not_readnone_2(i8* byval %written) readnone {
; IS__TUNIT____: Function Attrs: nofree nosync nounwind readnone willreturn
; IS__TUNIT____-LABEL: define {{[^@]+}}@byval_not_readnone_2
; IS__TUNIT____-SAME: (i8* noalias nocapture nofree nonnull writeonly byval dereferenceable(1) [[WRITTEN:%.*]])
; IS__TUNIT____-NEXT:    store i8 0, i8* [[WRITTEN]], align 1
; IS__TUNIT____-NEXT:    ret void
;
; IS__CGSCC____: Function Attrs: nofree norecurse nosync nounwind readnone willreturn
; IS__CGSCC____-LABEL: define {{[^@]+}}@byval_not_readnone_2
; IS__CGSCC____-SAME: (i8* noalias nocapture nofree nonnull writeonly byval dereferenceable(1) [[WRITTEN:%.*]])
; IS__CGSCC____-NEXT:    store i8 0, i8* [[WRITTEN]], align 1
; IS__CGSCC____-NEXT:    ret void
;
  store i8 0, i8* %written
  ret void
}

define void @byval_no_fnarg(i8* byval %written) {
; IS__TUNIT____: Function Attrs: nofree nosync nounwind readnone willreturn
; IS__TUNIT____-LABEL: define {{[^@]+}}@byval_no_fnarg
; IS__TUNIT____-SAME: (i8* noalias nocapture nofree nonnull writeonly byval dereferenceable(1) [[WRITTEN:%.*]])
; IS__TUNIT____-NEXT:    store i8 0, i8* [[WRITTEN]], align 1
; IS__TUNIT____-NEXT:    ret void
;
; IS__CGSCC____: Function Attrs: nofree norecurse nosync nounwind readnone willreturn
; IS__CGSCC____-LABEL: define {{[^@]+}}@byval_no_fnarg
; IS__CGSCC____-SAME: (i8* noalias nocapture nofree nonnull writeonly byval dereferenceable(1) [[WRITTEN:%.*]])
; IS__CGSCC____-NEXT:    store i8 0, i8* [[WRITTEN]], align 1
; IS__CGSCC____-NEXT:    ret void
;
  store i8 0, i8* %written
  ret void
}

define void @testbyval(i8* %read_only) {
; IS__TUNIT____-LABEL: define {{[^@]+}}@testbyval
; IS__TUNIT____-SAME: (i8* nocapture readonly [[READ_ONLY:%.*]])
; IS__TUNIT____-NEXT:    call void @byval_not_readonly_1(i8* nocapture readonly [[READ_ONLY]])
; IS__TUNIT____-NEXT:    call void @byval_not_readnone_1(i8* noalias nocapture readnone [[READ_ONLY]])
; IS__TUNIT____-NEXT:    ret void
;
; IS__CGSCC____: Function Attrs: readonly
; IS__CGSCC____-LABEL: define {{[^@]+}}@testbyval
; IS__CGSCC____-SAME: (i8* nocapture nonnull readonly dereferenceable(1) [[READ_ONLY:%.*]])
; IS__CGSCC____-NEXT:    call void @byval_not_readonly_1(i8* noalias nocapture nonnull readonly dereferenceable(1) [[READ_ONLY]])
; IS__CGSCC____-NEXT:    call void @byval_not_readnone_1(i8* noalias nocapture nonnull readnone dereferenceable(1) [[READ_ONLY]])
; IS__CGSCC____-NEXT:    ret void
;
  call void @byval_not_readonly_1(i8* %read_only)
  call void @byval_not_readonly_2(i8* %read_only)
  call void @byval_not_readnone_1(i8* %read_only)
  call void @byval_not_readnone_2(i8* %read_only)
  call void @byval_no_fnarg(i8* %read_only)
  ret void
}
;}

declare i8* @maybe_returned_ptr(i8* readonly %ptr) readonly nounwind
declare i8 @maybe_returned_val(i8* %ptr) readonly nounwind
declare void @val_use(i8 %ptr) readonly nounwind

define void @ptr_uses(i8* %ptr) {
; CHECK: Function Attrs: nounwind readonly
; CHECK-LABEL: define {{[^@]+}}@ptr_uses
; CHECK-SAME: (i8* nocapture readonly [[PTR:%.*]])
; CHECK-NEXT:    ret void
;
  %call_ptr = call i8* @maybe_returned_ptr(i8* %ptr)
  %call_val = call i8 @maybe_returned_val(i8* %call_ptr)
  call void @val_use(i8 %call_val)
  ret void
}
