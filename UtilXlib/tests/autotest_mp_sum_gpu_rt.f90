#if defined(__CUDA)
PROGRAM test_mp_sum_rt_gpu
!
! Simple program to check the functionalities of test_mp_sum_i1.
!
    USE cudafor
#if defined(__MPI)
    USE MPI
#endif
    USE mp, ONLY : mp_sum
    USE mp_world, ONLY : mp_world_start, mp_world_end, mpime, &
                          root, nproc, world_comm
    USE tester
    IMPLICIT NONE
    !
    TYPE(tester_t) :: test
    INTEGER :: world_group = 0, valid_sum, rnk
    INTEGER, PARAMETER :: datasize = 10
    ! test variable
    REAL(8), DEVICE :: rt_d(datasize,datasize,datasize)
    REAL(8) :: rt_h(datasize,datasize,datasize)
    REAL(8) :: aux_h(datasize,datasize,datasize)
    !    
    CALL test%init()
    
#if defined(__MPI)    
    world_group = MPI_COMM_WORLD
#endif
    CALL mp_world_start(world_group)
    rt_h = mpime
    rt_d = rt_h
    CALL mp_sum(rt_d, world_comm)
    rt_h = rt_d
    !
    ! The sum of n rank is (zero based)
    !  sum = (n-1)*n*0.5
    !
    ! For a rank N matrix is 2^N * sum
    !
    rnk = SIZE(SHAPE(rt_h))
    valid_sum = (10**rnk) * (nproc-1)*nproc/2
    !
    CALL test%assert_equal(INT(SUM(rt_h )) , valid_sum )
    !
    ! Validate against CPU implementation
    
    !
    CALL print_results(test)
    !
    CALL mp_world_end()
    !
END PROGRAM test_mp_sum_rt_gpu
#else
PROGRAM test_mp_sum_rt_gpu
    CALL no_test()
END PROGRAM test_mp_sum_rt_gpu
#endif
