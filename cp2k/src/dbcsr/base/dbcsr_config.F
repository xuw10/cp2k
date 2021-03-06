!--------------------------------------------------------------------------------------------------!
!   CP2K: A general program to perform molecular dynamics simulations                              !
!   Copyright (C) 2000 - 2016  CP2K developers group                                               !
!--------------------------------------------------------------------------------------------------!

! **************************************************************************************************
!> \brief   Configuration options for DBCSR
!> \author  Urban Borstnik
!> \date    2011-04-05
!> \version 1.0
!>
!> <b>Modification history:</b>
!> - Created 2011-04-05
! **************************************************************************************************
MODULE dbcsr_config
   USE dbcsr_error_handling,            ONLY: dbcsr_assert,&
                                              dbcsr_fatal_level,&
                                              dbcsr_wrong_args_error
   USE kinds,                           ONLY: dp
#include "../../base/base_uses.f90"

!$ USE OMP_LIB, ONLY: omp_get_max_threads, omp_get_thread_num, omp_get_num_threads

   IMPLICIT NONE

   PRIVATE

   CHARACTER(len=*), PARAMETER, PRIVATE :: moduleN = 'dbcsr_config'

   PUBLIC :: dbcsr_set_default_config

   PUBLIC :: dbcsr_set_conf_mm_stacksize, dbcsr_get_conf_mm_stacksize

   PUBLIC :: dbcsr_get_conf_mpi_mem

   PUBLIC :: dbcsr_set_conf_mm_driver, dbcsr_get_conf_mm_driver, dbcsr_get_conf_avg_elements_images

   PUBLIC :: dbcsr_set_conf_avg_elements_images, dbcsr_set_conf_nstacks, dbcsr_get_conf_nstacks

   PUBLIC :: dbcsr_set_conf_use_mpi_exp, dbcsr_get_conf_use_mpi_exp
   PUBLIC :: dbcsr_set_conf_num_layers_3D, dbcsr_get_conf_num_layers_3D
   PUBLIC :: dbcsr_set_conf_use_mpi_filtering, dbcsr_get_conf_use_mpi_filtering
   PUBLIC :: dbcsr_set_conf_use_comm_thread, dbcsr_get_conf_use_comm_thread
   PUBLIC :: dbcsr_set_conf_comm_thread_load, dbcsr_get_conf_comm_thread_load
   PUBLIC :: dbcsr_get_conf_max_ele_block, dbcsr_set_conf_max_ele_block
   PUBLIC :: dbcsr_get_conf_randmat_seed, dbcsr_set_conf_randmat_seed

   ! These are for DBCSR internal use.
   !
   PUBLIC :: has_MPI
   PUBLIC :: has_acc
   PUBLIC :: mm_stack_size
   PUBLIC :: mm_driver, &
             mm_driver_auto, &
             mm_driver_blas, &
             mm_driver_matmul, &
             mm_driver_smm, &
             mm_driver_xsmm
   PUBLIC :: mm_name_auto, &
             mm_name_blas, &
             mm_name_matmul, &
             mm_name_smm, &
             mm_name_xsmm
   PUBLIC :: use_mpi_exp, use_mpi_filtering, use_comm_thread, comm_thread_load
   PUBLIC :: num_layers_3D
   PUBLIC :: max_elements_per_block, avg_elements_images
   !
   PUBLIC :: is_initialized

   PUBLIC :: accdrv_avoid_after_busy, accdrv_min_flop_process, &
             accdrv_min_flop_sort, accdrv_do_inhomogenous, &
             accdrv_binning_nbins, accdrv_binning_binsize, &
             accdrv_posterior_streams, accdrv_posterior_buffers, &
             accdrv_priority_streams, accdrv_priority_buffers

   PUBLIC :: multrec_limit
   PUBLIC :: default_resize_factor
   PUBLIC :: randmat_counter

   ! First the constants are declared.
   REAL(KIND=dp), PARAMETER             :: default_resize_factor = 1.2_dp

   ! Possible drivers to use for matrix multiplications
   INTEGER, PARAMETER :: mm_driver_auto = 0
   INTEGER, PARAMETER :: mm_driver_matmul = 1
   INTEGER, PARAMETER :: mm_driver_blas = 2
   INTEGER, PARAMETER :: mm_driver_smm = 3
   INTEGER, PARAMETER :: mm_driver_xsmm = 4

   CHARACTER(len=*), PARAMETER :: mm_name_auto = "AUTO", &
                                  mm_name_blas = "BLAS", &
                                  mm_name_matmul = "MATMUL", &
                                  mm_name_smm = "SMM", &
                                  mm_name_xsmm = "XSMM"

   INTEGER, SAVE :: mm_driver = mm_driver_blas

#if defined (__HAS_smm_dnn)
   LOGICAL, PARAMETER :: has_smm = .TRUE.
#else
   LOGICAL, PARAMETER :: has_smm = .FALSE.
#endif

#if defined(__HAS_smm_vec)
   LOGICAL, PARAMETER :: has_smm_vec = .TRUE.
#else
   LOGICAL, PARAMETER :: has_smm_vec = .FALSE.
#endif

#if defined(__LIBXSMM)
   LOGICAL, PARAMETER :: has_xsmm = .TRUE.
#else
   LOGICAL, PARAMETER :: has_xsmm = .FALSE.
#endif

#if defined (__DBCSR_ACC)
   LOGICAL, PARAMETER :: has_acc = .TRUE.
#else
   LOGICAL, PARAMETER :: has_acc = .FALSE.
#endif

#if defined (__parallel)
   LOGICAL, PARAMETER :: has_MPI = .TRUE.
#else
   LOGICAL, PARAMETER :: has_MPI = .FALSE.
#endif

   LOGICAL, PARAMETER :: has_omp_2_5 = .TRUE.

   ! Now the fallback defaults are defined.  The defaults should be set
   ! by calling the dbcsr_init_conf() subroutine.

   ! Use MPI-allocated memory.
   LOGICAL, SAVE :: use_MPI_memory = has_MPI

   ! Stack size to use for multiplication parameters
#if defined(__HAS_smm_vec) || defined (__DBCSR_ACC)
   INTEGER, SAVE :: mm_stack_size = 30000
#else
   INTEGER, SAVE :: mm_stack_size = 1000
#endif

   ! Default blocking parameter
   INTEGER, SAVE :: max_elements_per_block = 32

   ! Maximum number of elements for each image
   INTEGER, SAVE :: avg_elements_images = -1

   ! Number of stacks to use
   INTEGER, SAVE :: nm_stacks = 3
   INTEGER, SAVE :: nn_stacks = 3
   INTEGER, SAVE :: nk_stacks = 3

   ! RMA algorithm
   LOGICAL, SAVE :: use_mpi_exp = .FALSE.

   ! RMA MPI filtering
   LOGICAL, SAVE :: use_mpi_filtering = .TRUE.

   ! 3D layers
   INTEGER, SAVE :: num_layers_3D = 1

   ! Configuration of an MPI progress thread
   LOGICAL, SAVE :: use_comm_thread = .TRUE.
   INTEGER, SAVE :: comm_thread_load = 100

   LOGICAL, SAVE :: is_initialized = .FALSE.

   INTEGER, SAVE :: multrec_limit = 512

   INTEGER, SAVE :: accdrv_priority_streams = 4
   INTEGER, SAVE :: accdrv_priority_buffers = 40
   INTEGER, SAVE :: accdrv_posterior_streams = 4
   INTEGER, SAVE :: accdrv_posterior_buffers = 80
   LOGICAL, SAVE :: accdrv_avoid_after_busy = .FALSE.
   INTEGER, SAVE :: accdrv_min_flop_process = 0
   INTEGER, SAVE :: accdrv_min_flop_sort = 4000
   LOGICAL, SAVE :: accdrv_do_inhomogenous = .TRUE.
   INTEGER, SAVE :: accdrv_binning_nbins = 4096
   INTEGER, SAVE :: accdrv_binning_binsize = 16

   ! a counter used to generate different random matrices from call to call
   INTEGER, SAVE :: randmat_counter = 12341313

CONTAINS

! **************************************************************************************************
!> \brief ...
!> \param driver ...
! **************************************************************************************************
   SUBROUTINE dbcsr_set_conf_mm_driver(driver)
      INTEGER, INTENT(IN)                                :: driver

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_set_conf_mm_driver', &
         routineP = moduleN//':'//routineN

      INTEGER                                            :: error_handle

!   ---------------------------------------------------------------------------
!defaults

      CALL timeset(routineN, error_handle)

      SELECT CASE (driver)
      CASE (mm_driver_auto)
         IF (has_xsmm) THEN
            mm_driver = mm_driver_xsmm
         ELSEIF (has_smm) THEN
            mm_driver = mm_driver_smm
         ELSE
            mm_driver = mm_driver_blas ! always available
         ENDIF
      CASE (mm_driver_matmul)
         mm_driver = mm_driver_matmul ! always available
      CASE (mm_driver_blas)
         mm_driver = mm_driver_blas ! always available
      CASE (mm_driver_smm)
         IF (.NOT. has_smm) CPABORT("Support for libsmm not compiled in.")
         mm_driver = mm_driver_smm
      CASE (mm_driver_xsmm)
         IF (.NOT. has_xsmm) CPABORT("Support for libxsmm not compiled in.")
         mm_driver = mm_driver_xsmm
      CASE DEFAULT
         CPABORT("Unkown MM driver")
      END SELECT
      CALL timestop(error_handle)
   END SUBROUTINE dbcsr_set_conf_mm_driver

! **************************************************************************************************
!> \brief ...
!> \retval driver ...
! **************************************************************************************************
   FUNCTION dbcsr_get_conf_mm_driver() RESULT(driver)
      INTEGER                                            :: driver

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_get_conf_mm_driver', &
         routineP = moduleN//':'//routineN

      driver = mm_driver
   END FUNCTION dbcsr_get_conf_mm_driver

! **************************************************************************************************
!> \brief ...
!> \param use_mpi_mem ...
! **************************************************************************************************
   SUBROUTINE dbcsr_set_conf_mpi_mem(use_mpi_mem)
      LOGICAL, INTENT(IN)                                :: use_mpi_mem

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_set_conf_mpi_mem', &
         routineP = moduleN//':'//routineN

      INTEGER                                            :: error_handle

      CALL timeset(routineN, error_handle)
      use_MPI_memory = use_mpi_mem
      CALL timestop(error_handle)
   END SUBROUTINE dbcsr_set_conf_mpi_mem

! **************************************************************************************************
!> \brief ...
!> \retval use_mpi_mem ...
! **************************************************************************************************
   FUNCTION dbcsr_get_conf_mpi_mem() RESULT(use_mpi_mem)
      LOGICAL                                            :: use_mpi_mem

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_get_conf_mpi_mem', &
         routineP = moduleN//':'//routineN

      use_mpi_mem = use_MPI_memory
   END FUNCTION dbcsr_get_conf_mpi_mem

! **************************************************************************************************
!> \brief ...
!> \param use_mm_stacksize ...
! **************************************************************************************************
   SUBROUTINE dbcsr_set_conf_mm_stacksize(use_mm_stacksize)
      INTEGER, INTENT(IN)                                :: use_mm_stacksize

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_set_conf_mm_stacksize', &
         routineP = moduleN//':'//routineN

      INTEGER                                            :: error_handle

      CALL timeset(routineN, error_handle)
      mm_stack_size = use_mm_stacksize
      CALL timestop(error_handle)
   END SUBROUTINE dbcsr_set_conf_mm_stacksize

! **************************************************************************************************
!> \brief ...
!> \retval use_mm_stacksize ...
! **************************************************************************************************
   FUNCTION dbcsr_get_conf_mm_stacksize() RESULT(use_mm_stacksize)
      INTEGER                                            :: use_mm_stacksize

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_get_conf_mm_stacksize', &
         routineP = moduleN//':'//routineN

      use_mm_stacksize = mm_stack_size
   END FUNCTION dbcsr_get_conf_mm_stacksize

! **************************************************************************************************
!> \brief ...
!> \param max_ele_block ...
! **************************************************************************************************
   SUBROUTINE dbcsr_set_conf_max_ele_block(max_ele_block)
      INTEGER, INTENT(IN)                                :: max_ele_block

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_set_conf_max_ele_block', &
         routineP = moduleN//':'//routineN

      INTEGER                                            :: error_handle

      CALL timeset(routineN, error_handle)
      max_elements_per_block = max_ele_block
      CALL timestop(error_handle)
   END SUBROUTINE dbcsr_set_conf_max_ele_block

! **************************************************************************************************
!> \brief ...
!> \retval max_ele_block ...
! **************************************************************************************************
   FUNCTION dbcsr_get_conf_max_ele_block() RESULT(max_ele_block)
      INTEGER                                            :: max_ele_block

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_get_conf_max_ele_block', &
         routineP = moduleN//':'//routineN

      max_ele_block = max_elements_per_block
   END FUNCTION dbcsr_get_conf_max_ele_block

! **************************************************************************************************
!> \brief ...
!> \param randmat_seed ...
! **************************************************************************************************
   SUBROUTINE dbcsr_set_conf_randmat_seed(randmat_seed)
      INTEGER, INTENT(IN)                                :: randmat_seed

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_set_conf_randmat_seed', &
         routineP = moduleN//':'//routineN

      INTEGER                                            :: error_handle

      CALL timeset(routineN, error_handle)
      randmat_counter = randmat_seed
      CALL timestop(error_handle)
   END SUBROUTINE dbcsr_set_conf_randmat_seed

! **************************************************************************************************
!> \brief ...
!> \retval max_ele_block ...
! **************************************************************************************************
   FUNCTION dbcsr_get_conf_randmat_seed() RESULT(randmat_seed)
      INTEGER                                            :: randmat_seed

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_get_conf_randmat_seed', &
         routineP = moduleN//':'//routineN

      randmat_seed = randmat_counter
   END FUNCTION dbcsr_get_conf_randmat_seed

! **************************************************************************************************
!> \brief ...
!> \param new_avg_elements_images ...
! **************************************************************************************************
   SUBROUTINE dbcsr_set_conf_avg_elements_images(new_avg_elements_images)
      INTEGER, INTENT(IN)                                :: new_avg_elements_images

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_set_conf_avg_elements_images', &
         routineP = moduleN//':'//routineN

      INTEGER                                            :: error_handle

      CALL timeset(routineN, error_handle)
      avg_elements_images = new_avg_elements_images
      CALL timestop(error_handle)
   END SUBROUTINE dbcsr_set_conf_avg_elements_images

! **************************************************************************************************
!> \brief ...
!> \retval dbcsr_get_conf_avg_elements_images ...
! **************************************************************************************************
   FUNCTION dbcsr_get_conf_avg_elements_images()
      INTEGER :: dbcsr_get_conf_avg_elements_images

      dbcsr_get_conf_avg_elements_images = avg_elements_images
   END FUNCTION dbcsr_get_conf_avg_elements_images

! **************************************************************************************************
!> \brief ...
!> \param nstacks ...
! **************************************************************************************************
   SUBROUTINE dbcsr_set_conf_nstacks(nstacks)
      INTEGER, INTENT(IN)                                :: nstacks(:)

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_set_conf_nstacks', &
         routineP = moduleN//':'//routineN

      INTEGER                                            :: error_handle

      CALL timeset(routineN, error_handle)
      CALL dbcsr_assert(SIZE(nstacks), "EQ", 3, &
                        dbcsr_fatal_level, dbcsr_wrong_args_error, routineN, &
                        "ntacks size must be 3", __LINE__)
      nm_stacks = nstacks(1)
      nn_stacks = nstacks(2)
      nk_stacks = nstacks(3)
      CALL timestop(error_handle)
   END SUBROUTINE dbcsr_set_conf_nstacks

! **************************************************************************************************
!> \brief ...
!> \param nstacks ...
! **************************************************************************************************
   SUBROUTINE dbcsr_get_conf_nstacks(nstacks)
      INTEGER, INTENT(OUT)                               :: nstacks(:)

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_get_conf_nstacks', &
         routineP = moduleN//':'//routineN

      INTEGER                                            :: error_handle

      CALL timeset(routineN, error_handle)
      CALL dbcsr_assert(SIZE(nstacks), "EQ", 3, &
                        dbcsr_fatal_level, dbcsr_wrong_args_error, routineN, &
                        "ntacks size must be 3", __LINE__)
      nstacks(1) = nm_stacks
      nstacks(2) = nn_stacks
      nstacks(3) = nk_stacks
      CALL timestop(error_handle)
   END SUBROUTINE dbcsr_get_conf_nstacks

! **************************************************************************************************
!> \brief ...
!> \param mpi_exp ...
! **************************************************************************************************
   SUBROUTINE dbcsr_set_conf_use_mpi_exp(mpi_exp)
      LOGICAL, INTENT(IN)                                :: mpi_exp

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_set_conf_use_mpi_exp', &
         routineP = moduleN//':'//routineN

      INTEGER                                            :: error_handle

      CALL timeset(routineN, error_handle)
      use_mpi_exp = mpi_exp
      CALL timestop(error_handle)
   END SUBROUTINE dbcsr_set_conf_use_mpi_exp

! **************************************************************************************************
!> \brief ...
!> \retval mpi_exp ...
! **************************************************************************************************
   FUNCTION dbcsr_get_conf_use_mpi_exp() RESULT(mpi_exp)
      LOGICAL                                            :: mpi_exp

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_get_conf_use_mpi_exp', &
         routineP = moduleN//':'//routineN

      mpi_exp = use_mpi_exp
   END FUNCTION dbcsr_get_conf_use_mpi_exp

! **************************************************************************************************
!> \brief ...
!> \param nlayers ...
! **************************************************************************************************
   SUBROUTINE dbcsr_set_conf_num_layers_3D(nlayers)
      INTEGER, INTENT(IN)                                :: nlayers

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_set_conf_num_layers_3D', &
         routineP = moduleN//':'//routineN

      INTEGER                                            :: error_handle

      CALL timeset(routineN, error_handle)
      num_layers_3D = nlayers
      CALL timestop(error_handle)
   END SUBROUTINE dbcsr_set_conf_num_layers_3D

! **************************************************************************************************
!> \brief ...
!> \retval nlayers ...
! **************************************************************************************************
   FUNCTION dbcsr_get_conf_num_layers_3D() RESULT(nlayers)
      INTEGER                                            :: nlayers

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_get_conf_num_layers_3D', &
         routineP = moduleN//':'//routineN

      nlayers = num_layers_3D
   END FUNCTION dbcsr_get_conf_num_layers_3D

! **************************************************************************************************
!> \brief ...
!> \param mpi_filtering ...
! **************************************************************************************************
   SUBROUTINE dbcsr_set_conf_use_mpi_filtering(mpi_filtering)
      LOGICAL, INTENT(IN)                                :: mpi_filtering

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_set_conf_use_mpi_filtering', &
         routineP = moduleN//':'//routineN

      INTEGER                                            :: error_handle

      CALL timeset(routineN, error_handle)
      use_mpi_filtering = mpi_filtering
      CALL timestop(error_handle)
   END SUBROUTINE dbcsr_set_conf_use_mpi_filtering

! **************************************************************************************************
!> \brief ...
!> \retval mpi_filtering ...
! **************************************************************************************************
   FUNCTION dbcsr_get_conf_use_mpi_filtering() RESULT(mpi_filtering)
      LOGICAL                                            :: mpi_filtering

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_get_conf_use_mpi_filtering', &
         routineP = moduleN//':'//routineN

      mpi_filtering = use_mpi_filtering
   END FUNCTION dbcsr_get_conf_use_mpi_filtering

! **************************************************************************************************
!> \brief ...
!> \param comm_thread ...
! **************************************************************************************************
   SUBROUTINE dbcsr_set_conf_use_comm_thread(comm_thread)
      LOGICAL, INTENT(IN)                                :: comm_thread

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_set_conf_use_comm_thread', &
         routineP = moduleN//':'//routineN

      INTEGER                                            :: error_handle

      CALL timeset(routineN, error_handle)
      use_comm_thread = comm_thread
      CALL timestop(error_handle)
   END SUBROUTINE dbcsr_set_conf_use_comm_thread

! **************************************************************************************************
!> \brief ...
!> \retval comm_thread ...
! **************************************************************************************************
   FUNCTION dbcsr_get_conf_use_comm_thread() RESULT(comm_thread)
      LOGICAL                                            :: comm_thread

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_get_conf_use_comm_thread', &
         routineP = moduleN//':'//routineN

      comm_thread = use_comm_thread
   END FUNCTION dbcsr_get_conf_use_comm_thread

! **************************************************************************************************
!> \brief ...
!> \param load ...
! **************************************************************************************************
   SUBROUTINE dbcsr_set_conf_comm_thread_load(load)
      INTEGER, INTENT(IN)                                :: load

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_set_conf_comm_thread_load', &
         routineP = moduleN//':'//routineN

      INTEGER                                            :: error_handle, nthreads

      CALL timeset(routineN, error_handle)
      nthreads = 1
!$    nthreads = OMP_GET_MAX_THREADS()
      comm_thread_load = MAX(0, 90-(30*nthreads)/8)
      IF (load >= 0) &
         comm_thread_load = load
      CALL timestop(error_handle)
   END SUBROUTINE dbcsr_set_conf_comm_thread_load

! **************************************************************************************************
!> \brief ...
!> \retval load ...
! **************************************************************************************************
   FUNCTION dbcsr_get_conf_comm_thread_load() RESULT(load)
      INTEGER                                            :: load

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_get_conf_comm_thread_load', &
         routineP = moduleN//':'//routineN

      load = comm_thread_load
   END FUNCTION dbcsr_get_conf_comm_thread_load

! **************************************************************************************************
!> \brief Configure DBCSR driver with default values.
!>
!> Basically it reads the default values and reset them.
! **************************************************************************************************
   SUBROUTINE dbcsr_set_default_config()

      CHARACTER(len=*), PARAMETER :: routineN = 'dbcsr_set_default_config', &
         routineP = moduleN//':'//routineN

      INTEGER                                            :: comm_thread_load, handle, max_ele_block, &
                                                            mm_driver, mm_ss
      INTEGER, DIMENSION(3)                              :: nstacks
      LOGICAL                                            :: use_comm_thread, use_mpi_mem

      CALL timeset(routineN, handle)

      use_mpi_mem = dbcsr_get_conf_mpi_mem()
      mm_ss = -1
      mm_driver = dbcsr_get_conf_mm_driver()
      max_ele_block = dbcsr_get_conf_max_ele_block()
      nstacks(1:3) = -1
      use_comm_thread = dbcsr_get_conf_use_comm_thread()
      comm_thread_load = -1

      randmat_counter = 12341313

      CALL dbcsr_set_conf_mm_driver(mm_driver)
      CALL dbcsr_set_conf_mpi_mem(use_mpi_mem)
      CALL dbcsr_set_conf_max_ele_block(max_ele_block)
      IF (mm_ss > 0) CALL dbcsr_set_conf_mm_stacksize(mm_ss)
      IF (nstacks(1) > 0) CALL dbcsr_set_conf_nstacks(nstacks)

      CALL dbcsr_set_conf_use_comm_thread(use_comm_thread)
      CALL dbcsr_set_conf_comm_thread_load(comm_thread_load)

      CALL timestop(handle)

   END SUBROUTINE dbcsr_set_default_config

END MODULE dbcsr_config
