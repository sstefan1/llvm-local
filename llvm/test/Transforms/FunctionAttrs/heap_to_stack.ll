; RUN: opt -passes=attributor --attributor-disable=false -enable-heap-to-stack-conversion=true -S < %s | FileCheck %s

declare noalias i8* @malloc(i64)

declare void @nocapture_func_frees_pointer(i8* nocapture)

declare void @func_throws(...)

declare void @sync_func(i8* %p)

declare void @sync_will_return(i8* %p) willreturn

declare void @no_sync_func(i8* %p) nofree nosync willreturn

declare void @nofree_func(i8* %p) nofree  nosync willreturn

declare void @foo(i32* %p)

declare i32 @no_return_call() noreturn

declare void @free(i8* nocapture)

; TEST 1 - negative, pointer freed in another function.

define void @test1() {
  %1 = tail call noalias i8* @malloc(i64 4)
  ; CHECK: @malloc(i64 4)
  ; CHECK-NEXT: @nocapture_func_frees_pointer(i8* %1)
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
  ; CHECK: %1 = alloca i8, i64 4
  ; CHECK-NEXT: @no_sync_func(i8* %1)
  tail call void @no_sync_func(i8* %1)
  ; CHECK-NOT: @free(i8* %1)
  tail call void @free(i8* %1)
  ret void
}

; TEST 4 - negative, no call to free

define void @test4() {
  %1 = tail call noalias i8* @malloc(i64 4)
  ; CHECK: %1 = alloca i8, i64 4
  ; CHECK-NEXT: @nofree_func(i8* %1)
  tail call void @nofree_func(i8* %1)
  ret void
}

; TEST 5 - not all exit paths have a call to free

define void @test5(i32) {
  %2 = tail call noalias i8* @malloc(i64 4)
  ; CHECK: %2 = alloca i8, i64 4
  ; CHECK-NEXT: icmp eq i32 %0, 0
  %3 = icmp eq i32 %0, 0
  br i1 %3, label %5, label %4

4:                                                ; preds = %1
  tail call void @nofree_func(i8* %2)
  br label %6

5:                                                ; preds = %1
  tail call void @free(i8* %2)
  ; CHECK-NOT: @free(i8* %2)
  br label %6

6:                                                ; preds = %5, %4
  ret void
}

; TEST 6 - all exit paths have a call to free

define void @test6(i32) {
  %2 = tail call noalias i8* @malloc(i64 4)
  ; CHECK: %2 = alloca i8, i64 4
  ; CHECK-NEXT: icmp eq i32 %0, 0
  %3 = icmp eq i32 %0, 0
  br i1 %3, label %5, label %4

4:                                                ; preds = %1
  tail call void @nofree_func(i8* %2)
  tail call void @free(i8* %2)
  ; CHECK-NOT: @free(i8* %2)
  br label %5

5:                                                ; preds = %1
  tail call void @free(i8* %2)
  ; CHECK-NOT: @free(i8* %2)
  br label %6

6:                                                ; preds = %5, %4
  ret void
}

; TEST 7 - free is dead.

define void @test7() {
  %1 = tail call noalias i8* @malloc(i64 4)
  ; CHECK: @alloca(i64 4)
  ; CHECK-NEXT: call i32 @no_return_call()
  tail call i32 @no_return_call()
  ; this free is dead. So malloc cannot be transformed.
  ; CHECK-NOT: @free(i8* %1)
  tail call void @free(i8* %1)
  ret void
}

; TEST 8 - Negative: bitcast pointer used in capture function

define void @test8() {
  %1 = tail call noalias i8* @malloc(i64 4)
  ; CHECK: %1 = tail call noalias i8* malloc (i64 4)
  ; CHECK-NEXT: @no_sync_func(i8* %1)
  tail call void @no_sync_func(i8* %1)
  %2 = bitcast i8* %1 to i32*
  store i32 10, i32* %2
  %3 = load i32, i32* %2
  tail call void @foo(i32* %2)
  ; CHECK: @free(i8* %1)
  tail call void @free(i8* %1)
  ret void
}

; TEST 9 - 1 malloc, 1 free

define i32 @test9() {
  %1 = tail call noalias i8* @malloc(i64 4)
  ; CHECK: %1 = alloca i8, i64 4
  ; CHECK-NEXT: @no_sync_func(i8* %1)
  tail call void @no_sync_func(i8* %1)
  %2 = bitcast i8* %1 to i32*
  store i32 10, i32* %2
  %3 = load i32, i32* %2
  ; CHECK-NOT: @free(i8* %1)
  tail call void @free(i8* %1)
  ret i32 %3
}

; TEST 10 
; FIXME: should be ok

define void @test10() {
  %1 = tail call noalias i8* @malloc(i64 4)
  ; CHECK: @malloc(i64 4)
  ; CHECK-NEXT: @sync_func(i8* %1)
  tail call void @sync_will_return(i8* %1)
  tail call void @free(i8* %1)
  ret void
}
