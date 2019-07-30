subroutine ph_lanczos_iter(j, npwx_npol, nbnd_occ, nksq, qj, Aqj, SAqj, qjold, n_ipol, u, alpha, beta, gamma, zeta)
   !
   !! Pseudo-Hermitian Lanczos algorithm 
   !! 
   !! $$ g(w) =\sum_j (u,q_j){q_j,(w-A)^(-1)q}
   !! Algorithm 2 in "Computer Physics Communications 185 (2014) 2080-2089"
   !!
   !! this subroutine generates alpha, beta and gamma coefficients (the
   !! tridiagonal matrix elements), z = (u,q_j) elements. And update 
   !! Lanczos vectors
   !!  
   !
   USE kinds,                    ONLY : dp
   !
   INTEGER, INTENT(IN)               :: j
   !! iteration index
   INTEGER, INTENT(IN)               :: npwx_npol
   !! firts dimension of qj, Aqj, SAqj, qjold, u in qe npwx*npol
   INTEGER, INTENT(IN)               :: nbnd_occ
   !! second dimension of qj, Aqj, SAqj, qjold, n_ipol, u in qe nbnd
   INTEGER, INTENT(IN)               :: nksq
   !! third dimension of qj, Aqj, SAqj, qjold, n_ipol, u in qe nksq
   INTEGER, INTENT(IN)               :: n_ipol
   !! polarization, forth dimension of u and dimension of zeta
   COMPLEX(kind=dp), INTENT(IN)      :: Aqj(npwx_npol,nbnd_occ,nksq)
   !! operator applied to qj vector 
   COMPLEX(kind=dp), INTENT(IN)      :: u(npwx_npol,nbnd_occ,nksq,n_ipol)
   !! second lanczos vector, in qe d0psi (dopsi2 for eels)
   COMPLEX(kind=dp), INTENT(IN)      :: SAqj(npwx_npol,nbnd_occ,nksq)
   !! S operator applied to Aqj vector only for USPP, otherwise a copy of Aqj
   COMPLEX(kind=dp), INTENT(INOUT)   :: qj(npwx_npol,nbnd_occ,nksq)
   !! qj vector, become qj+1 vector
   COMPLEX(kind=dp), INTENT(INOUT)   :: qjold(npwx_npol,nbnd_occ,nksq)
   !! qj-1 vector, become qj vector
   REAL(kind=dp),    INTENT(OUT)     :: alpha
   !! diagonal cofficient of the tridiagonal matrix
   REAL(kind=dp),    INTENT(OUT)     :: beta
   !! lower coefficient of the tridiagonal matrix
   REAL(kind=dp),    INTENT(OUT)     :: gamma
   !! upper coefficient of the tridiagonal matrix
   COMPLEX(kind=dp), INTENT(OUT)     :: zeta(n_ipol)
   !! (u,q_j) products
   !
   COMPLEX(kind=dp),EXTERNAL :: lr_dot
   !
   INTEGER                :: size_evc, ip
   !   
   size_evc = npwx_npol*nbnd_occ*nksq
   !
   ! By construction <p|Lq>=0 should be 0, forcing this both conserves 
   ! resources and increases stability.
   !
   alpha = 0.0d0
   !
   ! Orthogonality requirement: <v|\bar{L}|v> = 1
   !
   beta = dble(lr_dot(qj(:,:,:), SAqj(:,:,:)))
   !
   IF ( beta<0.0d0 ) THEN
      !
      beta = sqrt(-beta)
      gamma = -beta
      !
   ELSEIF ( beta>0.0d0 ) THEN
      !
      ! X. Ge: Actually, this is the only case in the pseudo-Hermitian
      ! algorithm.
      !
      beta = sqrt(beta)
      gamma = beta
      !
   ENDIF
   !
   ! Renormalize q(i) and Lq(i)
   !
   CALL zscal(size_evc,cmplx(1.0d0/beta,0.0d0,kind=dp),qj(1,1,1),1)
   CALL zscal(size_evc,cmplx(1.0d0/beta,0.0d0,kind=dp),Aqj(1,1,1),1)
   !
   ! Calculation of zeta coefficients.
   ! See Eq.(35) in Malcioglu et al., Comput. Phys. Commun. 182, 1744 (2011).
   !
   IF (mod(j,2)==0) THEN
      !
      DO ip = 1, n_ipol
         !
         ! Optics: In the ultrasoft case, the S operator was already
         ! applied to d0psi, so we have <S*d0psi|evc1>.
         !
         zeta(ip) = lr_dot(u(:,:,:,ip),qj(:,:,:))
         !
      ENDDO
      !
   ELSE
      !
      DO ip = 1, n_ipol
         !
         zeta(ip) = (0.0d0,0.0d0)
         !
      ENDDO
      !
   ENDIF
   !
   ! X. Ge: q(i+1) = Lq(i) - beta(i)*q(i-1); 
   ! Renormalization will be done in the begining of the next iteration.
   ! In the non-Hermitian case, similar operation needs to be done also for p(i).
   !
   CALL zaxpy(size_evc,-cmplx(gamma,0.0d0,kind=dp),qjold(1,1,1),1,Aqj(1,1,1),1)
   !
   ! X. Ge: Throw away q(i-1), and make q(i+1) to be the current vector,
   ! be ready for the next iteration. Aqj will be free again after this
   ! step
   !
   CALL zcopy(size_evc,qj(1,1,1),1,qjold(1,1,1),1)    ! qjold = qj
   CALL zcopy(size_evc,Aqj(1,1,1),1,qj(1,1,1),1)      ! qj = Aqj
   !
end subroutine ph_lanczos_iter
