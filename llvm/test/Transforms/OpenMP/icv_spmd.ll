; RUN: opt -S -openmpopt < %s | FileCheck %s
; RUN: opt -S -passes=openmpopt < %s | FileCheck %s

source_filename = "./example.c"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64"

%struct.ident_t = type { i32, i32, i32, i32, i8* }

@0 = private unnamed_addr constant [23 x i8] c";unknown;unknown;0;0;;\00", align 1
@1 = private unnamed_addr constant %struct.ident_t { i32 0, i32 2, i32 0, i32 0, i8* getelementptr inbounds ([23 x i8], [23 x i8]* @0, i32 0, i32 0) }, align 8
@__omp_offloading_10301_1083e1_caller_non_spmd_l11_exec_mode = weak constant i8 1
@2 = private unnamed_addr constant %struct.ident_t { i32 0, i32 2, i32 1, i32 0, i8* getelementptr inbounds ([23 x i8], [23 x i8]* @0, i32 0, i32 0) }, align 8
@__omp_offloading_10301_1083e1_caller_spmd_l23_exec_mode = weak constant i8 0
@3 = private unnamed_addr constant %struct.ident_t { i32 0, i32 2, i32 2, i32 0, i8* getelementptr inbounds ([23 x i8], [23 x i8]* @0, i32 0, i32 0) }, align 8
@llvm.compiler.used = appending global [2 x i8*] [i8* @__omp_offloading_10301_1083e1_caller_non_spmd_l11_exec_mode, i8* @__omp_offloading_10301_1083e1_caller_spmd_l23_exec_mode], section "llvm.metadata"

; Function Attrs: norecurse nounwind
define internal fastcc void @__omp_offloading_10301_1083e1_caller_non_spmd_l11_worker() unnamed_addr #0 {
  %1 = alloca i8*, align 8
  store i8* null, i8** %1, align 8
  br label %2

2:                                                ; preds = %10, %0
  call void @__kmpc_barrier_simple_spmd(%struct.ident_t* null, i32 0) #5
  %3 = call i1 @__kmpc_kernel_parallel(i8** nonnull %1) #3
  %4 = load i8*, i8** %1, align 8
  %5 = icmp eq i8* %4, null
  br i1 %5, label %11, label %6

6:                                                ; preds = %2
  br i1 %3, label %7, label %10

7:                                                ; preds = %6
  %8 = call i32 @__kmpc_global_thread_num(%struct.ident_t* nonnull @1)
  %9 = bitcast i8* %4 to void (i16, i32)*
  call void %9(i16 0, i32 %8) #3
  call void @__kmpc_kernel_end_parallel() #3
  br label %10

10:                                               ; preds = %7, %6
  call void @__kmpc_barrier_simple_spmd(%struct.ident_t* null, i32 0) #5
  br label %2

11:                                               ; preds = %2
  ret void
}

; Function Attrs: norecurse nounwind
define weak void @__omp_offloading_10301_1083e1_caller_non_spmd_l11() local_unnamed_addr #0 {
  %1 = call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !range !7
  %2 = add nsw i32 %1, -32
  %3 = call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !range !8
  %4 = icmp ult i32 %3, %2
  br i1 %4, label %5, label %6

5:                                                ; preds = %0
  call fastcc void @__omp_offloading_10301_1083e1_caller_non_spmd_l11_worker() #3
  br label %11

6:                                                ; preds = %0
  %7 = add nsw i32 %1, -1
  %8 = and i32 %7, -32
  %9 = icmp eq i32 %3, %8
  br i1 %9, label %10, label %11

10:                                               ; preds = %6
  call void @__kmpc_kernel_init(i32 %2, i16 1) #3
  call void @__kmpc_data_sharing_init_stack() #3
  call fastcc void @callee_non_spmd()
  call void @__kmpc_kernel_deinit(i16 1) #3
  call void @__kmpc_barrier_simple_spmd(%struct.ident_t* null, i32 0) #5
  br label %11

11:                                               ; preds = %10, %6, %5
  ret void
}

; Function Attrs: nounwind readnone
declare i32 @llvm.nvvm.read.ptx.sreg.ntid.x() #1

; Function Attrs: nounwind readnone
declare i32 @llvm.nvvm.read.ptx.sreg.tid.x() #1

declare void @__kmpc_kernel_init(i32, i16) local_unnamed_addr

declare void @__kmpc_data_sharing_init_stack() local_unnamed_addr

declare void @__kmpc_kernel_deinit(i16) local_unnamed_addr

; Function Attrs: convergent
declare void @__kmpc_barrier_simple_spmd(%struct.ident_t*, i32) local_unnamed_addr #2

declare i1 @__kmpc_kernel_parallel(i8**) local_unnamed_addr

; Function Attrs: nounwind
declare i32 @__kmpc_global_thread_num(%struct.ident_t*) local_unnamed_addr #3

declare void @__kmpc_kernel_end_parallel() local_unnamed_addr

; Function Attrs: norecurse nounwind
define weak void @__omp_offloading_10301_1083e1_caller_spmd_l23() local_unnamed_addr #0 {
  %1 = call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !range !7
  call void @__kmpc_spmd_kernel_init(i32 %1, i16 1, i16 0) #3
  call void @__kmpc_data_sharing_init_stack_spmd() #3
  %2 = call i32 @__kmpc_global_thread_num(%struct.ident_t* nonnull @2)
  call fastcc void @callee_spmd() #3
  call void @__kmpc_spmd_kernel_deinit_v2(i16 1) #3
  ret void
}

declare void @__kmpc_spmd_kernel_init(i32, i16, i16) local_unnamed_addr

declare void @__kmpc_data_sharing_init_stack_spmd() local_unnamed_addr

declare void @__kmpc_spmd_kernel_deinit_v2(i16) local_unnamed_addr

; Function Attrs: norecurse nounwind
define internal fastcc void @callee_non_spmd() unnamed_addr #0 {
  %1 = call i32 @__kmpc_global_thread_num(%struct.ident_t* nonnull @3)
  %2 = call i16 @__kmpc_parallel_level(%struct.ident_t* nonnull @3, i32 %1) #3
  %3 = call i8 @__kmpc_is_spmd_exec_mode() #3
  %.not = icmp eq i8 %3, 0
  br i1 %.not, label %4, label %8

4:                                                ; preds = %0
  %5 = icmp eq i16 %2, 0
  %6 = select i1 %5, i64 4, i64 128
  %7 = call i8* @__kmpc_data_sharing_coalesced_push_stack(i64 %6, i16 0) #3
  br label %8

8:                                                ; preds = %0, %4
  %9 = phi i8* [ %7, %4 ], [ null, %0 ]
  br i1 %.not, label %10, label %11

10:                                               ; preds = %8
  call void @__kmpc_data_sharing_pop_stack(i8* %9) #3
  br label %11

11:                                               ; preds = %10, %8
  ret void
}

declare i16 @__kmpc_parallel_level(%struct.ident_t*, i32) local_unnamed_addr

declare i8 @__kmpc_is_spmd_exec_mode() local_unnamed_addr

declare i8* @__kmpc_data_sharing_coalesced_push_stack(i64, i16) local_unnamed_addr

; Function Attrs: norecurse nounwind readnone
define hidden void @use(i8* nocapture %0) local_unnamed_addr #4 {
  ret void
}

declare void @__kmpc_data_sharing_pop_stack(i8*) local_unnamed_addr

; Function Attrs: norecurse nounwind
define internal fastcc void @callee_spmd() unnamed_addr #0 {
  %1 = call i32 @__kmpc_global_thread_num(%struct.ident_t* nonnull @3)
  %2 = call i16 @__kmpc_parallel_level(%struct.ident_t* nonnull @3, i32 %1) #3
  %3 = call i8 @__kmpc_is_spmd_exec_mode() #3
  %.not = icmp eq i8 %3, 0
  br i1 %.not, label %4, label %8

4:                                                ; preds = %0
  %5 = icmp eq i16 %2, 0
  %6 = select i1 %5, i64 4, i64 128
  %7 = call i8* @__kmpc_data_sharing_coalesced_push_stack(i64 %6, i16 0) #3
  br label %8

8:                                                ; preds = %0, %4
  %9 = phi i8* [ %7, %4 ], [ null, %0 ]
  br i1 %.not, label %10, label %11

10:                                               ; preds = %8
  call void @__kmpc_data_sharing_pop_stack(i8* %9) #3
  br label %11

11:                                               ; preds = %10, %8
  ret void
}

attributes #0 = { norecurse nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_35" "target-features"="+ptx32,+sm_35" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readnone }
attributes #2 = { convergent }
attributes #3 = { nounwind }
attributes #4 = { norecurse nounwind readnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_35" "target-features"="+ptx32,+sm_35" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #5 = { convergent nounwind }

!omp_offload.info = !{!0, !1}
!nvvm.annotations = !{!2, !3}
!llvm.module.flags = !{!4, !5}
!llvm.ident = !{!6}

!0 = !{i32 0, i32 66305, i32 1082337, !"caller_non_spmd", i32 11, i32 0}
!1 = !{i32 0, i32 66305, i32 1082337, !"caller_spmd", i32 23, i32 1}
!2 = !{void ()* @__omp_offloading_10301_1083e1_caller_non_spmd_l11, !"kernel", i32 1}
!3 = !{void ()* @__omp_offloading_10301_1083e1_caller_spmd_l23, !"kernel", i32 1}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 7, !"PIC Level", i32 2}
!6 = !{!"clang version 12.0.0 (https://github.com/llvm/llvm-project.git caee15a0ed52471bd329d01dc253ec9be3936c6d)"}
!7 = !{i32 1, i32 1025}
!8 = !{i32 0, i32 1024}
