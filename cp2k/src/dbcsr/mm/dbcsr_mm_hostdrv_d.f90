!-----------------------------------------------------------------------------!
!   CP2K: A general program to perform molecular dynamics simulations         !
!   Copyright (C) 2000 - 2015  CP2K developers group                          !
!-----------------------------------------------------------------------------!

! *****************************************************************************
!> \brief Processes MM stack and issues BLAS xGEMM calls
!>
!> \param[in] params           Stack of MM parameters
!> \param[in] stack_size       Number of parameters
!> \param[in] a_data           Left-matrix data
!> \param[in] b_data           Right-matrix data
!> \param[in,out] c_data       Product data
! *****************************************************************************
  SUBROUTINE blas_process_mm_stack_d(params,&
       stack_size,&
       a_data, b_data, c_data)
    INTEGER, INTENT(IN)                       :: stack_size
    INTEGER, DIMENSION(dbcsr_ps_width,1:stack_size), &
      INTENT(IN)                              :: params
    REAL(kind=real_8), DIMENSION(*), INTENT(IN)         :: a_data, &
                                                 b_data
    REAL(kind=real_8), DIMENSION(*), INTENT(INOUT)      :: c_data

    CHARACTER(len=*), PARAMETER :: routineN = 'blas_process_mm_stack_d', &
      routineP = moduleN//':'//routineN

    INTEGER                                   :: sp

!   ---------------------------------------------------------------------------

    DO sp = 1, stack_size
       CALL DGEMM('N',&
            'N',&
            params(p_m,sp), params(p_n,sp),& !m, n
            params(p_k,sp),& ! k
            1.0_real_8,& ! alpha
            a_data(params(p_a_first,sp)),& ! A
            params(p_m,sp),& !lda
            b_data(params(p_b_first,sp)),& ! B
            params(p_k,sp),& !ldb
            1.0_real_8,& ! beta
            c_data(params(p_c_first,sp)), params(p_m,sp))
    ENDDO
  END SUBROUTINE blas_process_mm_stack_d

! *****************************************************************************
!> \brief Processes MM stack and issues internal MM calls.
!>
!> \param[in] params           Stack of MM parameters
!> \param[in] stack_size       Number of parameters
!> \param[in] a_data           Left-matrix data
!> \param[in] b_data           Right-matrix data
!> \param[in,out] c_data       Product data
! *****************************************************************************
  SUBROUTINE internal_process_mm_stack_d(params, stack_size,&
       a_data, b_data, c_data)
    INTEGER, INTENT(IN)                       :: stack_size
    INTEGER, DIMENSION(dbcsr_ps_width,1:stack_size), &
      INTENT(IN)                              :: params
    REAL(kind=real_8), DIMENSION(*), INTENT(IN)         :: a_data, &
                                                 b_data
    REAL(kind=real_8), DIMENSION(*), INTENT(INOUT)      :: c_data

    CHARACTER(len=*), PARAMETER :: routineN = 'internal_process_mm_stack_d', &
      routineP = moduleN//':'//routineN

    INTEGER                                   :: sp

!   ---------------------------------------------------------------------------

    DO sp = 1, stack_size
       CALL internal_mm_d_nn(&
            params(p_m,sp),&
            params(p_n,sp),&
            params(p_k,sp),&
            a_data(params(p_a_first,sp)),&
            b_data(params(p_b_first,sp)),&
            c_data(params(p_c_first,sp)))
    ENDDO
  END SUBROUTINE internal_process_mm_stack_d


! *****************************************************************************
!> \brief Processes MM stack and issues SMM library calls
!>
!> \param stack_descr ...
!> \param[in] params           Stack of MM parameters
!> \param[in] stack_size       Number of parameters
!> \param[in] a_data           Left-matrix data
!> \param[in] b_data           Right-matrix data
!> \param[in,out] c_data       Product data
! *****************************************************************************
  SUBROUTINE smm_process_mm_stack_d(stack_descr, params,&
       stack_size,&
       a_data, b_data, c_data)
    INTEGER, INTENT(IN)                       :: stack_size
    TYPE(stack_descriptor_type), INTENT(IN)   :: stack_descr
    INTEGER, DIMENSION(dbcsr_ps_width,1:stack_size), &
      INTENT(IN)                              :: params
    REAL(kind=real_8), DIMENSION(*), INTENT(IN)         :: a_data, &
                                                 b_data
    REAL(kind=real_8), DIMENSION(*), INTENT(INOUT)      :: c_data

    CHARACTER(len=*), PARAMETER :: routineN = 'smm_process_mm_stack_d', &
      routineP = moduleN//':'//routineN

#if defined(__HAS_smm_dnn)

   INTEGER                                   :: sp

#if defined(__HAS_smm_vec)
    IF(stack_descr%defined_mnk) THEN
       CALL smm_vec_dnn (stack_descr%m, stack_descr%n, stack_descr%k, &
         a_data, b_data, c_data, stack_size, &
         dbcsr_ps_width, params, p_a_first, p_b_first, p_c_first)
       RETURN
    ENDIF
#endif

    DO sp = 1, stack_size
       CALL smm_dnn(&
            params(p_m,sp),&
            params(p_n,sp),&
            params(p_k,sp),&
            a_data(params(p_a_first,sp)),&
            b_data(params(p_b_first,sp)),&
            c_data(params(p_c_first,sp)))
    ENDDO

#else
    ! We do not want to abort here, fall back to BLAS.
    CALL blas_process_mm_stack_d(params, stack_size,a_data, b_data, c_data)
#endif

    MARK_USED(stack_descr)
  END SUBROUTINE smm_process_mm_stack_d


! *****************************************************************************
!> \brief Processes MM stack and issues libxsmm calls
!>
!> \param stack_descr ...
!> \param[in] params           Stack of MM parameters
!> \param[in] stack_size       Number of parameters
!> \param[in] a_data           Left-matrix data
!> \param[in] b_data           Right-matrix data
!> \param[in,out] c_data       Product data
! *****************************************************************************
  SUBROUTINE xsmm_process_mm_stack_d(stack_descr, params,&
       stack_size, a_data, b_data, c_data)

#if defined(__LIBXSMM) && 1
    USE libxsmm,                           ONLY: libxsmm_function  => libxsmm_dmm_function,&
                                                 libxsmm_dispatch  => libxsmm_ddispatch_mnk,&
                                                 libxsmm_available => libxsmm_davailable,&
                                                 libxsmm_call      => libxsmm_dcall_prf,&
                                                 libxsmm_mm        => libxsmm_dmm,&
                                                 LIBXSMM_PREFETCH_NONE
#endif

    INTEGER, INTENT(IN)                       :: stack_size
    TYPE(stack_descriptor_type), INTENT(IN)   :: stack_descr
    INTEGER, DIMENSION(dbcsr_ps_width,1:stack_size), &
      INTENT(IN)                              :: params
    REAL(kind=real_8), DIMENSION(*), TARGET, INTENT(IN) :: a_data, &
                                                 b_data
    REAL(kind=real_8), DIMENSION(*), TARGET, &
      INTENT(INOUT)                           :: c_data

    CHARACTER(len=*), PARAMETER :: routineN = 'libxsmm_process_mm_stack_d', &
      routineP = moduleN//':'//routineN

#if defined(__LIBXSMM) && 1
    REAL(real_8), PARAMETER                  :: one = 1.0_real_8
    INTEGER                                   :: fa, fb, fc, pa, pb, pc, m, n, k, sp
    REAL(real_8), DIMENSION(:,:), POINTER    :: a_ptr, b_ptr, c_ptr
    TYPE(libxsmm_function)                    :: func


    IF(stack_descr%defined_mnk) THEN
       WRITE (*,*) "OLE: trying dispatch"
       CALL libxsmm_dispatch(func,&
                             m=stack_descr%m, n=stack_descr%n, k=stack_descr%k,&
                             alpha=one, beta=one, flags=LIBXSMM_PREFETCH_NONE)
       IF (libxsmm_available(func)) THEN
          WRITE (*,*) "OLE: dispatched"
          DO sp = 1, stack_size
             fa = params(p_a_first,sp)
             fb = params(p_b_first,sp)
             fc = params(p_c_first,sp)
             IF(sp < stack_size) THEN ! prefetch next blocks
                pa = params(p_a_first,sp+1)
                pb = params(p_b_first,sp+1)
                pc = params(p_c_first,sp+1)
             ENDIF
             CALL libxsmm_call(func, a=a_data(fa), b=b_data(fb), c=c_data(fc),&
                               pa=a_data(pa), pb=b_data(pb), pc=c_data(pc))
          ENDDO
          RETURN
       ENDIF
    ENDIF

    WRITE (*,*) "OLE: regular"
    ! dispatch interface was not used, call regular interface.
    DO sp = 1, stack_size
       m = params(p_m,sp)
       n = params(p_n,sp)
       k = params(p_k,sp)
       fa = params(p_a_first,sp)
       fb = params(p_b_first,sp)
       fc = params(p_c_first,sp)
       a_ptr(1:m,1:k) => a_data(fa:fa+(m*k))
       b_ptr(1:k,1:n) => b_data(fb:fb+(k*n))
       c_ptr(1:m,1:n) => c_data(fc:fc+(m*n))
       IF(sp < stack_size) THEN ! prefetch next blocks
          pa = params(p_a_first,sp+1)
          pb = params(p_b_first,sp+1)
          pc = params(p_c_first,sp+1)
       ENDIF
       CALL libxsmm_mm(m=m, n=n, k=k,&
                       a=a_ptr, b=b_ptr, c=c_ptr,&
                       pa=a_data(pa), pb=b_data(pb), pc=c_data(pc),&
                       flags=LIBXSMM_PREFETCH_NONE, alpha=one, beta=one)
    ENDDO

#else
    MARK_USED(stack_descr)
    ! We do not want to abort here, fall back to BLAS.
    CALL blas_process_mm_stack_d(params, stack_size,a_data, b_data, c_data)
#endif

  END SUBROUTINE xsmm_process_mm_stack_d

! *****************************************************************************
!> \brief ...
!> \param M ...
!> \param N ...
!> \param K ...
!> \param A ...
!> \param B ...
!> \param C ...
! *****************************************************************************
  PURE SUBROUTINE internal_mm_d_nn(&
       M,N,K,A,B,C)
    INTEGER, INTENT(IN)                      :: M, N, K
    REAL(kind=real_8), INTENT(INOUT)                   :: C(M,N)
    REAL(kind=real_8), INTENT(IN)                      :: B(K,N)
    REAL(kind=real_8), INTENT(IN)                      :: A(M,K)
    C(:,:) = C(:,:) + MATMUL (A, B)
  END SUBROUTINE internal_mm_d_nn
