!--------------------------------------------------------------------------------------------------!
!   CP2K: A general program to perform molecular dynamics simulations                              !
!   Copyright (C) 2000 - 2016  CP2K developers group                                               !
!--------------------------------------------------------------------------------------------------!

! **************************************************************************************************
!> \brief Does all kind of post scf calculations for SCPTB
!> \par History
!>      Started as a copy from the relevant part of qs_scf_post_gpw
!> \author Ralph Koitz (09.2013)
! **************************************************************************************************
MODULE qs_scf_post_scptb

   USE atomic_kind_types,               ONLY: atomic_kind_type
   USE cell_types,                      ONLY: cell_type
   USE cp_control_types,                ONLY: dft_control_type
   USE cp_dbcsr_interface,              ONLY: cp_dbcsr_p_type
   USE cp_dbcsr_output,                 ONLY: cp_dbcsr_write_sparse_matrix
   USE cp_log_handling,                 ONLY: cp_get_default_logger,&
                                              cp_logger_get_default_io_unit,&
                                              cp_logger_type
   USE cp_output_handling,              ONLY: cp_p_file,&
                                              cp_print_key_finished_output,&
                                              cp_print_key_should_output,&
                                              cp_print_key_unit_nr
   USE cp_para_types,                   ONLY: cp_para_env_type
   USE input_section_types,             ONLY: section_vals_get,&
                                              section_vals_get_subs_vals,&
                                              section_vals_type,&
                                              section_vals_val_get
   USE particle_list_types,             ONLY: particle_list_type
   USE particle_types,                  ONLY: particle_type
   USE population_analyses,             ONLY: mulliken_population_analysis
   USE qs_environment_types,            ONLY: get_qs_env,&
                                              qs_environment_type
   USE qs_rho_types,                    ONLY: qs_rho_get,&
                                              qs_rho_type
   USE qs_subsys_types,                 ONLY: qs_subsys_get,&
                                              qs_subsys_type
#include "./base/base_uses.f90"

   IMPLICIT NONE
   PRIVATE
   ! Global parameters
   CHARACTER(len=*), PARAMETER, PRIVATE :: moduleN = 'qs_scf_post_scptb'
   PUBLIC :: scf_post_calculation_scptb

CONTAINS

! **************************************************************************************************
!> \brief collects possible post - scf calculations and prints info / computes properties.
!> \param qs_env the qs_env in which the qs_env lives
!> \par History
!>        09.2013  Adapted from qs_scf_post_gpw.F
!> \author  Ralph Koitz
!> \note
! **************************************************************************************************
   SUBROUTINE scf_post_calculation_scptb(qs_env)

      TYPE(qs_environment_type), POINTER                 :: qs_env

      CHARACTER(len=*), PARAMETER :: routineN = 'scf_post_calculation_scptb', &
         routineP = moduleN//':'//routineN

      INTEGER                                            :: handle

      CALL timeset(routineN, handle)

      CALL write_scptb_mo_free_results(qs_env)

      CALL timestop(handle)
   END SUBROUTINE scf_post_calculation_scptb

! **************************************************************************************************
!> \brief Write QS results always available in SCPTB calculation
!> \param qs_env the qs_env in which the qs_env lives
!> \par History 09.2013 adapted from qs_scf_post_gpw.F. [RK]
! **************************************************************************************************
   SUBROUTINE write_scptb_mo_free_results(qs_env)
      TYPE(qs_environment_type), POINTER                 :: qs_env

      CHARACTER(len=*), PARAMETER :: routineN = 'write_scptb_mo_free_results', &
         routineP = moduleN//':'//routineN

      INTEGER                                            :: after, handle, ispin, iw, output_unit, &
                                                            print_level, unit_nr
      LOGICAL                                            :: explicit, omit_headers, print_it
      TYPE(atomic_kind_type), DIMENSION(:), POINTER      :: atomic_kind_set
      TYPE(cell_type), POINTER                           :: cell
      TYPE(cp_dbcsr_p_type), DIMENSION(:), POINTER       :: rho_ao
      TYPE(cp_logger_type), POINTER                      :: logger
      TYPE(cp_para_env_type), POINTER                    :: para_env
      TYPE(dft_control_type), POINTER                    :: dft_control
      TYPE(particle_list_type), POINTER                  :: particles
      TYPE(particle_type), DIMENSION(:), POINTER         :: particle_set
      TYPE(qs_rho_type), POINTER                         :: rho
      TYPE(qs_subsys_type), POINTER                      :: subsys
      TYPE(section_vals_type), POINTER                   :: dft_section, input, print_key, &
                                                            print_section, wfn_mix_section

      CALL timeset(routineN, handle)
      NULLIFY (dft_control, rho, input, para_env, rho_ao)
      logger => cp_get_default_logger()
      output_unit = cp_logger_get_default_io_unit(logger)

      CPASSERT(ASSOCIATED(qs_env))
      CALL get_qs_env(qs_env, &
                      dft_control=dft_control, &
                      atomic_kind_set=atomic_kind_set, &
                      particle_set=particle_set, &
                      rho=rho, &
                      input=input, &
                      cell=cell, &
                      subsys=subsys, &
                      para_env=para_env)

      dft_section => section_vals_get_subs_vals(input, "DFT")
      print_section => section_vals_get_subs_vals(dft_section, "PRINT")
      CALL qs_subsys_get(subsys, particles=particles)

      ! Dipole Moments
      print_key => section_vals_get_subs_vals(print_section, "MOMENTS")
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_key), cp_p_file)) THEN
         CALL cp_warn(__LOCATION__, &
                      "Multipole moments from SCPTB calculation currently "// &
                      "not supported")
      END IF

      ! Print the total density (electronic + core charge)
      ! Not implemented so far.
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_section, &
                                           "TOT_DENSITY_CUBE"), cp_p_file)) THEN
         CALL cp_warn(__LOCATION__, &
                      "Printing of cube files from SCPTB calculation currently "// &
                      "not supported")
      END IF

      ! Write cube file with electron density
      ! Not implemented so far.
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_section, &
                                           "E_DENSITY_CUBE"), cp_p_file)) THEN
         CALL cp_warn(__LOCATION__, &
                      "Printing of cube files from SCPTB calculation currently "// &
                      "not supported")
      END IF ! print key

      ! Print the hartree potential
      ! Not implemented so far.
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_section, &
                                           "V_HARTREE_CUBE"), cp_p_file)) THEN
         CALL cp_warn(__LOCATION__, &
                      "Printing of cube files from SCPTB calculation currently "// &
                      "not supported")
      ENDIF

      ! Print the Electrical Field Components
      ! Not implemented so far.
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_section, &
                                           "EFIELD_CUBE"), cp_p_file)) THEN

         CALL cp_warn(__LOCATION__, &
                      "Printing of cube files from SCPTB calculation currently "// &
                      "not supported")
      END IF

      ! Write the density matrices
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_section, &
                                           "AO_MATRICES/DENSITY"), cp_p_file)) THEN
         iw = cp_print_key_unit_nr(logger, input, "AO_MATRICES/DENSITY", &
                                   extension=".Log")
         CALL section_vals_val_get(input, "DFT%PRINT%AO_MATRICES%NDIGITS", i_val=after)
         after = MIN(MAX(after, 1), 16)
         CALL qs_rho_get(rho, rho_ao=rho_ao)
         CALL section_vals_val_get(qs_env%input, "DFT%PRINT%AO_MATRICES%OMIT_HEADERS", l_val=omit_headers)
         DO ispin = 1, dft_control%nspins
            CALL cp_dbcsr_write_sparse_matrix(rho_ao(ispin)%matrix, 4, after, qs_env, &
                                              para_env, output_unit=iw, omit_headers=omit_headers)
         END DO
         CALL cp_print_key_finished_output(iw, logger, input, "AO_MATRICES/DENSITY")
      END IF

      ! Compute the Mulliken charges
      print_key => section_vals_get_subs_vals(print_section, "MULLIKEN")
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_key), cp_p_file)) THEN
         unit_nr = cp_print_key_unit_nr(logger, print_section, "MULLIKEN", extension=".mulliken", &
                                        middle_name="", log_filename=.FALSE.)
         print_level = 1
         CALL section_vals_val_get(print_key, "PRINT_GOP", l_val=print_it)
         IF (print_it) print_level = 2
         CALL section_vals_val_get(print_key, "PRINT_ALL", l_val=print_it)
         IF (print_it) print_level = 3
         CALL mulliken_population_analysis(qs_env, unit_nr, print_level)
         CALL cp_print_key_finished_output(unit_nr, logger, print_section, "MULLIKEN")
      END IF

      ! Hirshfeld charges
      print_key => section_vals_get_subs_vals(print_section, "HIRSHFELD")
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_key), cp_p_file)) THEN
         CPWARN("Hirshfeld charges not available for SCPTB method.")
      END IF

      ! MAO
      print_key => section_vals_get_subs_vals(print_section, "MAO_ANALYSIS")
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_key), cp_p_file)) THEN
         CPWARN("MAO analysis not available for SCPTB method.")
      END IF

      ! KINETIC ENERGY
      print_key => section_vals_get_subs_vals(print_section, "KINETIC_ENERGY")
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_key), cp_p_file)) THEN
         CPWARN("Kinetic energy not available for SCPTB method.")
      END IF

      ! Xray diffraction spectrum
      print_key => section_vals_get_subs_vals(print_section, "XRAY_DIFFRACTION_SPECTRUM")
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_key), cp_p_file)) THEN
         CPWARN("Xray diffraction spectrum not implemented for SCPTB method.")
      END IF

      ! Electric field gradients
      print_key => section_vals_get_subs_vals(print_section, "ELECTRIC_FIELD_GRADIENT")
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_key), cp_p_file)) THEN
         CPWARN("Electric field gradient not implemented for SCPTB method.")
      END IF

      ! STM
      print_key => section_vals_get_subs_vals(print_section, "STM")
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_key), cp_p_file)) THEN
         CPWARN("STM not implemented for SCPTB method.")
      END IF

      ! MO
      print_key => section_vals_get_subs_vals(print_section, "MO")
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_key), cp_p_file)) THEN
         CPWARN("Printing of MO properties not implemented for SCPTB method.")
      END IF

      ! MO CUBES
      print_key => section_vals_get_subs_vals(print_section, "MO_CUBES")
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_key), cp_p_file)) THEN
         CPWARN("Printing of MO cube files not implemented for SCPTB method.")
      END IF

      ! Wavefunction mixing
      wfn_mix_section => section_vals_get_subs_vals(dft_section, "PRINT%WFN_MIX")
      CALL section_vals_get(wfn_mix_section, explicit=explicit)
      IF (explicit .AND. .NOT. qs_env%run_rtp) THEN
         CPWARN("Wavefunction mixing not implemented for SCPTB method.")
      END IF

      ! PLUS_U
      print_key => section_vals_get_subs_vals(print_section, "PLUS_U")
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_key), cp_p_file)) THEN
         CPWARN("DFT+U method not implemented for SCPTB method.")
      END IF

      ! PDOS
      print_key => section_vals_get_subs_vals(print_section, "PDOS")
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_key), cp_p_file)) THEN
         CPWARN("Projected DOS not implemented for SCPTB method.")
      END IF

      ! V_XC CUBE FILE
      print_key => section_vals_get_subs_vals(print_section, "V_XC_CUBE")
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_key), cp_p_file)) THEN
         CPWARN("XC potential cube file not available for SCPTB method.")
      END IF

      ! ELF
      print_key => section_vals_get_subs_vals(print_section, "ELF_CUBE")
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_key), cp_p_file)) THEN
         CPWARN("ELF not implemented for SCPTB method.")
      END IF

      ! EPR Hyperfine Coupling
      print_key => section_vals_get_subs_vals(print_section, "HYPERFINE_COUPLING_TENSOR")
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_key), cp_p_file)) THEN
         CPWARN("Hyperfine Coupling not implemented for SCPTB method.")
      END IF

      ! Lowdin
      print_key => section_vals_get_subs_vals(print_section, "LOWDIN")
      IF (BTEST(cp_print_key_should_output(logger%iter_info, print_key), cp_p_file)) THEN
         CPWARN("Lowdin population analysis not implemented for SCPTB method.")
      END IF

      CALL timestop(handle)

   END SUBROUTINE write_scptb_mo_free_results

END MODULE qs_scf_post_scptb
