!-----------------------------------------------------------------------------!
!   CP2K: A general program to perform molecular dynamics simulations         !
!   Copyright (C) 2000 - 2014  CP2K developers group                          !
!-----------------------------------------------------------------------------!

! *****************************************************************************
!> \brief multiplies a dbcsr matrix with a column vector like dbcsr matrix.
!>        v_out=beta*v_out+alpha*M*V
!>        IMPORTANT: vector have to be created via the vec create routines:
!>                   cp_dbcsr_create_col_vec_from_matrix,
!>                   cp_dbcsr_create_row_vec_from_matrix,
!>                   cp_dbcsr_create_rep_col_vec_from_matrix,
!>                   cp_dbcsr_create_rep_row_vec_from_matrix
!>        WARNING:   Do not filter the vectors as they are assumed to be non
!>                   sparse in the underlying routines. If your vector is
!>                   sparse, fill it!!!
!> \param matrix a dbcsr matrix
!> \param vec_in the vector to be multiplied (only available on proc_col 0)
!> \param vec_out the result vector (only available on proc_col 0)
!> \param alpha  as described in formula
!> \param beta  as described in formula
!> \param rep_row a work row vector replicated on all proc_cols. 
!> \param rep_col a work col vector replicated on all proc_rows. 
! *****************************************************************************
   SUBROUTINE cp_dbcsr_matrix_colvec_multiply_d(matrix,vec_in,vec_out,alpha,beta,&
                                                rep_row,rep_col)
    TYPE(cp_dbcsr_type), INTENT(IN)          :: matrix
    TYPE(cp_dbcsr_type), INTENT(IN)          :: vec_in
    TYPE(cp_dbcsr_type), INTENT(INOUT)       :: vec_out
    REAL(kind=real_8), INTENT(IN)                      :: alpha, beta
    TYPE(cp_dbcsr_type), INTENT(INOUT)       :: rep_row, rep_col

    CHARACTER(len=*), PARAMETER :: routineN = 'cp_dbcsr_matrix_colvec_mult_d', &
      routineP = moduleN//':'//routineN

    TYPE(dbcsr_error_type)                   :: dbcsr_error

    CALL dbcsr_matrix_colvec_multiply(matrix%matrix,vec_in%matrix,vec_out%matrix,&
                                  alpha,beta,rep_row%matrix,rep_col%matrix,dbcsr_error)

   END SUBROUTINE cp_dbcsr_matrix_colvec_multiply_d

! *****************************************************************************
!> \brief Encapsulates a given scalar value and makes it conformant to the
!>        type of the matrix.
!> \param scalar ...
!> \param matrix ...
!> \retval encapsulated ...
! *****************************************************************************
  FUNCTION make_conformant_scalar_d (scalar, matrix) RESULT (encapsulated)
    REAL(kind=real_8), INTENT(IN)                      :: scalar
    TYPE(cp_dbcsr_type), INTENT(IN)          :: matrix

    CHARACTER(len=*), PARAMETER :: routineN = 'make_conformant_scalar_d', &
      routineP = moduleN//':'//routineN

    TYPE(dbcsr_scalar_type)                  :: encapsulated
    INTEGER                                  :: data_type, scalar_data_type

    encapsulated = dbcsr_scalar (scalar)
    CALL dbcsr_scalar_fill_all (encapsulated)
    data_type = dbcsr_get_data_type (matrix%matrix)
    scalar_data_type = dbcsr_scalar_get_type(encapsulated)
    IF (scalar_data_type .EQ. dbcsr_type_complex_4 .OR.&
        scalar_data_type .EQ. dbcsr_type_complex_8) THEN
       IF(.NOT.(data_type .EQ. dbcsr_type_complex_4 .OR.&
            data_type .EQ. dbcsr_type_complex_8))&
            STOP "make_conformant_scalar_d: Can not conform a complex to a real number"
    END IF
    CALL dbcsr_scalar_set_type (encapsulated,data_type)
  END FUNCTION make_conformant_scalar_d


! *****************************************************************************
!> \brief ...
!> \param matrix ...
!> \param row ...
!> \param col ...
!> \param block ...
!> \param transposed ...
!> \param existed ...
! *****************************************************************************
  SUBROUTINE cp_dbcsr_reserve_block2d_d (matrix, row, col, block,&
       transposed, existed) 
    TYPE(cp_dbcsr_type), INTENT(INOUT)       :: matrix
    INTEGER, INTENT(IN)                      :: row, col
    REAL(kind=real_8), DIMENSION(:, :), POINTER        :: block
    LOGICAL, INTENT(IN), OPTIONAL            :: transposed
    LOGICAL, INTENT(OUT), OPTIONAL           :: existed

    CHARACTER(len=*), PARAMETER :: routineN = 'cp_dbcsr_reserve_block2d_d', &
      routineP = moduleN//':'//routineN

    CALL dbcsr_reserve_block2d(matrix%matrix, row, col, block,&
         transposed, existed)

  END SUBROUTINE cp_dbcsr_reserve_block2d_d


! *****************************************************************************
!> \brief ...
!> \param iterator ...
!> \param row ...
!> \param column ...
!> \param block ...
!> \param block_number ...
!> \param row_size ...
!> \param col_size ...
!> \param row_offset ...
!> \param col_offset ...
! *****************************************************************************
  SUBROUTINE cp_iterator_next_2d_block_d (iterator, row, column,&
       block,&
       block_number, row_size, col_size, row_offset, col_offset)
    TYPE(cp_dbcsr_iterator), INTENT(INOUT)   :: iterator
    INTEGER, INTENT(OUT)                     :: row, column
    REAL(kind=real_8), DIMENSION(:, :), POINTER        :: block
    INTEGER, INTENT(OUT), OPTIONAL           :: block_number, row_size, &
                                                col_size, row_offset, &
                                                col_offset

    CHARACTER(len=*), PARAMETER :: routineN = 'cp_iterator_next_2d_block_d', &
      routineP = moduleN//':'//routineN

    LOGICAL                                  :: transposed

    CALL dbcsr_iterator_next_block (iterator, row, column,&
       block, transposed,&
       block_number, row_size, col_size, row_offset, col_offset)
    IF(transposed) STOP "cp_iterator_next_2d_block_d: CP2K does not handle transposed blocks."

  END SUBROUTINE cp_iterator_next_2d_block_d


! *****************************************************************************
!> \brief ...
!> \param iterator ...
!> \param row ...
!> \param column ...
!> \param block ...
!> \param block_number ...
!> \param row_size ...
!> \param col_size ...
!> \param row_offset ...
!> \param col_offset ...
! *****************************************************************************
  SUBROUTINE cp_iterator_next_1d_block_d (iterator, row, column, block,&
       block_number, row_size, col_size, row_offset, col_offset)
    TYPE(cp_dbcsr_iterator), INTENT(INOUT)    :: iterator
    INTEGER, INTENT(OUT)                      :: row, column
    REAL(kind=real_8), DIMENSION(:), POINTER            :: block
    INTEGER, INTENT(OUT), OPTIONAL            :: block_number, row_size, &
                                                 col_size, row_offset, &
                                                 col_offset

    CHARACTER(len=*), PARAMETER :: routineN = 'cp_iterator_next_1d_block_d', &
      routineP = moduleN//':'//routineN

    LOGICAL                                   :: transposed

    CALL dbcsr_iterator_next_block (iterator, row, column, block,&
       transposed, block_number, row_size, col_size, row_offset, col_offset)
    IF(transposed) STOP "cp_iterator_next_1d_block_d: CP2K does not handle transposed blocks."

  END SUBROUTINE cp_iterator_next_1d_block_d


! *****************************************************************************
!> \brief ...
!> \param matrix ...
!> \param row ...
!> \param col ...
!> \param block ...
!> \param summation ...
!> \param scale ...
! *****************************************************************************
  SUBROUTINE cp_dbcsr_put_block2d_d (matrix, row, col, block,&
       summation, scale)
    TYPE(cp_dbcsr_type), INTENT(INOUT)       :: matrix
    INTEGER, INTENT(IN)                      :: row, col
    REAL(kind=real_8), DIMENSION(:, :), INTENT(IN)     :: block
    LOGICAL, INTENT(IN), OPTIONAL            :: summation
    REAL(kind=real_8), INTENT(IN), OPTIONAL            :: scale

    CHARACTER(len=*), PARAMETER :: routineN = 'cp_dbcsr_put_block2d_d', &
      routineP = moduleN//':'//routineN

    CALL dbcsr_put_block(matrix%matrix, row, col, block,&
       summation=summation, scale=scale)

  END SUBROUTINE cp_dbcsr_put_block2d_d


! *****************************************************************************
!> \brief ...
!> \param matrix ...
!> \param row ...
!> \param col ...
!> \param block ...
!> \param summation ...
!> \param scale ...
! *****************************************************************************
  SUBROUTINE cp_dbcsr_put_block_d (matrix, row, col, block,&
       summation, scale)
    TYPE(cp_dbcsr_type), INTENT(INOUT)       :: matrix
    INTEGER, INTENT(IN)                      :: row, col
    REAL(kind=real_8), DIMENSION(:), INTENT(IN)        :: block
    LOGICAL, INTENT(IN), OPTIONAL            :: summation
    REAL(kind=real_8), INTENT(IN), OPTIONAL            :: scale

    CHARACTER(len=*), PARAMETER :: routineN = 'cp_dbcsr_put_block_d', &
      routineP = moduleN//':'//routineN

    CALL dbcsr_put_block(matrix%matrix, row, col, block,&
       summation=summation, scale=scale)

  END SUBROUTINE cp_dbcsr_put_block_d


! *****************************************************************************
!> \brief ...
!> \param matrix ...
!> \param row ...
!> \param col ...
!> \param block ...
!> \param found ...
!> \param row_size ...
!> \param col_size ...
! *****************************************************************************
  SUBROUTINE cp_dbcsr_get_block_d (matrix,row,col,block,found,&
       row_size, col_size)
    TYPE(cp_dbcsr_type), INTENT(IN)          :: matrix
    INTEGER, INTENT(IN)                      :: row, col
    REAL(kind=real_8), DIMENSION(:), INTENT(OUT)      :: block
    LOGICAL, INTENT(OUT)                     :: found
    INTEGER, INTENT(OUT), OPTIONAL           :: row_size, col_size

    CHARACTER(len=*), PARAMETER :: routineN = 'cp_dbcsr_get_block_d', &
      routineP = moduleN//':'//routineN

    LOGICAL                                  :: tr

    tr=.FALSE.
    CALL dbcsr_get_block(matrix%matrix,row,col,block,tr,found,&
       row_size, col_size)

  END SUBROUTINE cp_dbcsr_get_block_d


! *****************************************************************************
!> \brief ...
!> \param matrix ...
!> \param row ...
!> \param col ...
!> \param block ...
!> \param found ...
!> \param row_size ...
!> \param col_size ...
! *****************************************************************************
  SUBROUTINE cp_dbcsr_get_2d_block_p_d (matrix,row,col,block,found,&
       row_size, col_size)
    TYPE(cp_dbcsr_type), INTENT(INOUT)       :: matrix
    INTEGER, INTENT(IN)                      :: row, col
    REAL(kind=real_8), DIMENSION(:, :), POINTER        :: block
    LOGICAL, INTENT(OUT)                     :: found
    INTEGER, INTENT(OUT), OPTIONAL           :: row_size, col_size

    CHARACTER(len=*), PARAMETER :: routineN = 'cp_dbcsr_get_2d_block_p_d', &
      routineP = moduleN//':'//routineN

    LOGICAL                                  :: tr

    CALL dbcsr_get_block_p(matrix%matrix,row,col,block,tr,found,&
         row_size, col_size)
    IF(tr) STOP "cp_dbcsr_get_2d_block_p_d: CP2K does not handle transposed blocks."
  END SUBROUTINE cp_dbcsr_get_2d_block_p_d


! *****************************************************************************
!> \brief ...
!> \param matrix ...
!> \param row ...
!> \param col ...
!> \param block ...
!> \param found ...
!> \param row_size ...
!> \param col_size ...
! *****************************************************************************
  SUBROUTINE cp_dbcsr_get_block_p_d (matrix,row,col,block,found,&
       row_size, col_size)
    TYPE(cp_dbcsr_type), INTENT(IN)           :: matrix
    INTEGER, INTENT(IN)                       :: row, col
    REAL(kind=real_8), DIMENSION(:), POINTER            :: block
    LOGICAL, INTENT(OUT)                      :: found
    INTEGER, INTENT(OUT), OPTIONAL            :: row_size, col_size

    CHARACTER(len=*), PARAMETER :: routineN = 'cp_dbcsr_get_block_p_d', &
      routineP = moduleN//':'//routineN

    LOGICAL                                   :: tr

    CALL dbcsr_get_block_p(matrix%matrix,row,col,block,tr,found,&
       row_size, col_size)
    IF(tr) STOP "cp_dbcsr_get_block_p_d: CP2K does not handle transposed blocks."

  END SUBROUTINE cp_dbcsr_get_block_p_d


! *****************************************************************************
!> \brief ...
!> \param matrix_a ...
!> \param trace ...
! *****************************************************************************
  SUBROUTINE cp_dbcsr_trace_a_d (matrix_a, trace)
    TYPE(cp_dbcsr_type), INTENT(INOUT)       :: matrix_a
    REAL(kind=real_8), INTENT(OUT)                     :: trace

    CHARACTER(len=*), PARAMETER :: routineN = 'cp_dbcsr_trace_a_d', &
      routineP = moduleN//':'//routineN

    TYPE(dbcsr_error_type)                   :: dbcsr_error
    TYPE(dbcsr_scalar_type)                  :: trace_scalar

    trace_scalar = dbcsr_scalar_zero (cp_dbcsr_get_data_type(matrix_a))
    CALL dbcsr_trace(matrix_a%matrix, trace_scalar, dbcsr_error)
    CALL dbcsr_scalar_fill_all (trace_scalar)
    CALL dbcsr_scalar_get_value (trace_scalar, trace)
  END SUBROUTINE cp_dbcsr_trace_a_d


! *****************************************************************************
!> \brief ...
!> \param matrix_a ...
!> \param matrix_b ...
!> \param trace ...
!> \param trans_a ...
!> \param trans_b ...
!> \param local_sum ...
! *****************************************************************************
  SUBROUTINE cp_dbcsr_trace_ab_d (matrix_a, matrix_b, trace, trans_a, trans_b, local_sum)
    TYPE(cp_dbcsr_type), INTENT(INOUT)       :: matrix_a, matrix_b
    REAL(kind=real_8), INTENT(INOUT)                   :: trace
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL   :: trans_a, trans_b
    LOGICAL, INTENT(IN), OPTIONAL            :: local_sum

    CHARACTER(len=*), PARAMETER :: routineN = 'cp_dbcsr_trace_ab_d', &
      routineP = moduleN//':'//routineN

    TYPE(dbcsr_error_type)                   :: dbcsr_error

    CALL dbcsr_trace(matrix_a%matrix, matrix_b%matrix, trace, trans_a, trans_b, local_sum, dbcsr_error)
  END SUBROUTINE cp_dbcsr_trace_ab_d


! *****************************************************************************
!> \brief ...
!> \param transa ...
!> \param transb ...
!> \param alpha ...
!> \param matrix_a ...
!> \param matrix_b ...
!> \param beta ...
!> \param matrix_c ...
!> \param first_row ...
!> \param last_row ...
!> \param first_column ...
!> \param last_column ...
!> \param first_k ...
!> \param last_k ...
!> \param retain_sparsity ...
!> \param filter_eps ...
!> \param flop ...
! *****************************************************************************
  SUBROUTINE cp_dbcsr_multiply_d (transa, transb,&
       alpha, matrix_a, matrix_b, beta, matrix_c,&
       first_row, last_row, first_column, last_column, first_k, last_k,&
       retain_sparsity, &
       filter_eps,&
       flop)
    CHARACTER(LEN=1), INTENT(IN)             :: transa, transb
    REAL(kind=real_8), INTENT(IN)                      :: alpha
    TYPE(cp_dbcsr_type), INTENT(IN)          :: matrix_a, matrix_b
    REAL(kind=real_8), INTENT(IN)                      :: beta
    TYPE(cp_dbcsr_type), INTENT(INOUT)       :: matrix_c
    INTEGER, INTENT(IN), OPTIONAL            :: first_row, last_row, &
                                                first_column, last_column, &
                                                first_k, last_k
    LOGICAL, INTENT(IN), OPTIONAL            :: retain_sparsity
    REAL(kind=real_8), INTENT(IN), OPTIONAL :: filter_eps
    INTEGER(int_8), INTENT(OUT), OPTIONAL    :: flop

    CHARACTER(len=*), PARAMETER :: routineN = 'cp_dbcsr_multiply_d', &
      routineP = moduleN//':'//routineN
    LOGICAL, PARAMETER                       :: prnt = .FALSE., &
                                                verify = .FALSE.

    CHARACTER(LEN=1)                         :: shape_a, shape_b, trans_a, &
                                                trans_b
    LOGICAL                                  :: new_a_is_new, new_b_is_new
    REAL(kind=real_8)                       :: cs_b, cs_c
    TYPE(cp_dbcsr_type)                      :: new_a, new_b
    TYPE(dbcsr_error_type)                   :: dbcsr_error

    trans_a = transa
    trans_b = transb
    CALL uppercase(trans_a)
    CALL uppercase(trans_b)
    shape_a='R'
    IF(cp_dbcsr_nfullcols_total(matrix_a).EQ.cp_dbcsr_nfullrows_total(matrix_a)) shape_a='S'
    shape_b='R'
    IF(cp_dbcsr_nfullcols_total(matrix_b).EQ.cp_dbcsr_nfullrows_total(matrix_b)) shape_b='S'
    CALL matrix_match_sizes (matrix_c, matrix_a, transa, matrix_b, transb,&
         new_a, new_b, new_a_is_new, new_b_is_new)
    CALL dbcsr_multiply(transa, transb,&
         alpha, new_a%matrix, new_b%matrix, beta, matrix_c%matrix,&
         first_row, last_row, first_column, last_column, first_k, last_k,&
         retain_sparsity, &
         filter_eps=filter_eps,&
         error=dbcsr_error, flop=flop)
    IF (new_a_is_new) THEN
       CALL cp_dbcsr_release (new_a)
    ENDIF
    IF (new_b_is_new) THEN
       CALL cp_dbcsr_release (new_b)
    ENDIF
    IF (prnt) THEN
       CALL cp_dbcsr_print (matrix_c, matlab_format=.TRUE.,&
            variable_name="mpo")
    ENDIF
    IF (verify) cs_b = cp_dbcsr_checksum (matrix_c)

    IF (verify) THEN
       WRITE(*,'(A,4(1X,E9.3))')routineN//" checksums", cs_c, cs_b,&
            cs_c-cs_b, ABS(cs_c-cs_b)/cs_b
       WRITE(*,*)routineN//" multiply type",&
            trans_a//shape_a//'_'&
            //trans_b//shape_b

       IF (ABS(cs_c-cs_b) .GT. 0.00001) STOP "Bad multiply"
    ENDIF
  END SUBROUTINE cp_dbcsr_multiply_d


! *****************************************************************************
!> \brief ...
!> \param matrix_a ...
!> \param alpha ...
!> \param side ...
! *****************************************************************************
  SUBROUTINE cp_dbcsr_scale_by_vector_d (matrix_a, alpha, side)
    TYPE(cp_dbcsr_type), INTENT(INOUT)        :: matrix_a
    REAL(kind=real_8), DIMENSION(:), INTENT(IN), TARGET :: alpha
    CHARACTER(LEN=*), INTENT(IN)              :: side

    CHARACTER(len=*), PARAMETER :: routineN = 'cp_dbcsr_scale_by_vector_d ', &
      routineP = moduleN//':'//routineN

    TYPE(dbcsr_error_type)                    :: dbcsr_error

    CALL dbcsr_scale_by_vector(matrix_a%matrix, alpha, side, dbcsr_error)
  END SUBROUTINE cp_dbcsr_scale_by_vector_d


! *****************************************************************************
!> \brief ...
!> \param matrix_a ...
!> \param alpha_scalar ...
!> \param last_column ...
! *****************************************************************************
  SUBROUTINE cp_dbcsr_scale_d (matrix_a, alpha_scalar, last_column)
    TYPE(cp_dbcsr_type), INTENT(INOUT)       :: matrix_a
    REAL(kind=real_8), INTENT(IN)                      :: alpha_scalar
    INTEGER, INTENT(IN), OPTIONAL            :: last_column

    CHARACTER(len=*), PARAMETER :: routineN = 'cp_dbcsr_scale_d', &
      routineP = moduleN//':'//routineN

    TYPE(dbcsr_error_type)                   :: dbcsr_error

    CALL dbcsr_scale(matrix_a%matrix, alpha_scalar, last_column, dbcsr_error)
  END SUBROUTINE cp_dbcsr_scale_d


! *****************************************************************************
!> \brief ...
!> \param matrix ...
!> \param alpha ...
! *****************************************************************************
  SUBROUTINE cp_dbcsr_set_d (matrix, alpha)
    TYPE(cp_dbcsr_type), INTENT(INOUT)       :: matrix
    REAL(kind=real_8), INTENT(IN)                      :: alpha

    CHARACTER(len=*), PARAMETER :: routineN = 'cp_dbcsr_set_d', &
      routineP = moduleN//':'//routineN

    TYPE(dbcsr_error_type)                   :: dbcsr_error

    CALL dbcsr_set(matrix%matrix, cp_dbcsr_conform_scalar(alpha, matrix), dbcsr_error)
  END SUBROUTINE cp_dbcsr_set_d


! *****************************************************************************
!> \brief ...
!> \param matrix_a ...
!> \param matrix_b ...
!> \param alpha_scalar ...
!> \param beta_scalar ...
! *****************************************************************************
  SUBROUTINE cp_dbcsr_add_d (matrix_a, matrix_b, alpha_scalar, beta_scalar)
    TYPE(cp_dbcsr_type), INTENT(INOUT)       :: matrix_a
    TYPE(cp_dbcsr_type), INTENT(IN)          :: matrix_b
    REAL(kind=real_8), INTENT(IN)                      :: alpha_scalar, beta_scalar

    CHARACTER(len=*), PARAMETER :: routineN = 'cp_dbcsr_add_d', &
      routineP = moduleN//':'//routineN

    TYPE(dbcsr_error_type)                   :: dbcsr_error

    CALL dbcsr_add(matrix_a%matrix, matrix_b%matrix, alpha_scalar, beta_scalar, dbcsr_error)
  END SUBROUTINE cp_dbcsr_add_d
