; RUN: opt -attributor --attributor-disable=false -S < %s | FileCheck %s

declare noalias i8* @malloc(i64)

declare void @nocapture_func_frees_pointer(i8* nocapture)

declare void @func_throws(...)

declare void @sync_func(i8* %p)

declare void @nofree_func(i8* %p) nofree

declare i32 @no_return_call() noreturn

declare void @free(i8* nocapture)

; TEST 1 - negative, pointer freed in another function.

define void @test1() {
  %1 = tail call noalias i8* @malloc(i64 4)
  ; CHECK: @malloc(i64 4)
  tail call void @nocapture_func_frees_pointer(i8* %1)
  tail call void (...) @func_throws()
  tail call void @free(i8* %1)
  ret void
}

; TEST 2 - negative, call to a sync function.

define void @test2() {
  %1 = tail call noalias i8* @malloc(i64 4)
  ; CHECK: @malloc(i64 4)
  ; CHECK-NEXT: @sync_func(i8* %1)
  tail call void @sync_func(i8* %1)
  tail call void @free(i8* %1)
  ret void
}

; TEST 3 - 1 malloc, 1 free

define void @test3() {
  %1 = tail call noalias i8* @malloc(i64 4)
  ; FIXME: this should be transformed to alloca.
  tail call void @sync_func(i8* %1)
  tail call void @free(i8* %1)
  ; FIXME: this free should be removed.
  ret void
}

; TEST 4 - negative, no call to free

define void @test4() {
  %1 = tail call noalias i8* @malloc(i64 4)
  tail call void @nofree_func(i8* %1)
  ret void
}

; TEST 5 - not all exit paths have a call to free

define void @test5(i32) {
  %2 = tail call noalias i8* @malloc(i64 4)
  ; CHECK: @malloc(i64 4)
  ; CHECK-NEXT: icmp eq i32 %0, 0
  %3 = icmp eq i32 %0, 0
  br i1 %3, label %5, label %4

4:                                                ; preds = %1
  tail call void @nofree_func(i8* %2)
  br label %6

5:                                                ; preds = %1
  tail call void @free(i8* %2)
  ; CHECK: @free(i8* %2)
  br label %6

6:                                                ; preds = %5, %4
  ret void
}

; TEST 6 - all exit paths have a call to free

define void @test6(i32) {
  %2 = tail call noalias i8* @malloc(i64 4)
  ; FIXME: malloc should be transformed to alloca.
  %3 = icmp eq i32 %0, 0
  br i1 %3, label %5, label %4

4:                                                ; preds = %1
  tail call void @nofree_func(i8* %2)
  tail call void @free(i8* %2)
  ; FIXME: call to free should be deleted
  br label %5

5:                                                ; preds = %1
  tail call void @free(i8* %2)
  ; FIXME: call to free should be deleted
  br label %6

6:                                                ; preds = %5, %4
  ret void
}

; TEST 7 - free is dead.

define void @test7() {
  %1 = tail call noalias i8* @malloc(i64 4)
  ; CHECK: @malloc(i64 4)
  ; CHECK-NEXT: call i32 @no_return_call(i8* %1)
  tail call i32 @no_return_call()
  ; this free is dead. So malloc cannot be transformed.
  tail call void @free(i8* %1)
  ret void
}
