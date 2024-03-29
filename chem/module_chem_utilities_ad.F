!        Generated by TAPENADE     (INRIA, Tropics team)
!  Tapenade 3.6 (r4756) - 12 Feb 2013 10:43
!
MODULE A_MODULE_CHEM_UTILITIES
  USE module_domain
  USE module_model_constants
  USE module_state_description
  USE module_configure
  IMPLICIT NONE

CONTAINS
!  Differentiation of chem_prep in reverse (adjoint) mode (with options r8 noISIZE):
!   gradient     of useful results: v_phy z t8w rh t_phy p_phy
!                u_phy p8w z_at_w rho dz8w
!   with respect to varying inputs: v_phy p t u v z t8w rh t_phy
!                p_phy moist ph u_phy alt p8w z_at_w rho dz8w
!   RW status of diff variables: v_phy:in-out p:out t:out u:out
!                v:out z:in-out t8w:in-out rh:in-out t_phy:in-out
!                p_phy:in-out moist:out ph:out u_phy:in-out alt:out
!                p8w:in-out z_at_w:in-out rho:in-out dz8w:in-out
  SUBROUTINE A_CHEM_PREP(config_flags, u, a_u, v, a_v, p, a_p, pb, alt, &
&    a_alt, ph, a_ph, phb, t, a_t, moist, a_moist, n_moist, rho, a_rho, &
&    p_phy, a_p_phy, u_phy, a_u_phy, v_phy, a_v_phy, p8w, a_p8w, t_phy, &
&    a_t_phy, t8w, a_t8w, z, a_z, z_at_w, a_z_at_w, dz8w, a_dz8w, rh, &
&    a_rh, fzm, fzp, ids, ide, jds, jde, kds, kde, ims, ime, jms, jme, &
&    kms, kme, its, ite, jts, jte, kts, kte)
    IMPLICIT NONE
    TYPE(GRID_CONFIG_REC_TYPE), INTENT(IN) :: config_flags
    INTEGER, INTENT(IN) :: ids, ide, jds, jde, kds, kde, ims, ime, jms, &
&    jme, kms, kme, its, ite, jts, jte, kts, kte
    INTEGER, INTENT(IN) :: n_moist
    REAL, DIMENSION(ims:ime, kms:kme, jms:jme, n_moist), INTENT(IN) :: &
&    moist
    REAL, DIMENSION(ims:ime, kms:kme, jms:jme, n_moist) :: a_moist
    REAL, DIMENSION(ims:ime, kms:kme, jms:jme) :: u_phy, v_phy, p_phy, &
&    p8w, t_phy, t8w, rho, z, dz8w, rh, z_at_w
    REAL, DIMENSION(ims:ime, kms:kme, jms:jme) :: a_u_phy, a_v_phy, &
&    a_p_phy, a_p8w, a_t_phy, a_t8w, a_rho, a_z, a_dz8w, a_rh, a_z_at_w
    REAL, DIMENSION(ims:ime, kms:kme, jms:jme), INTENT(IN) :: pb, p, u, &
&    v, alt, ph, phb, t
    REAL, DIMENSION(ims:ime, kms:kme, jms:jme) :: a_p, a_u, a_v, a_alt, &
&    a_ph, a_t
    REAL, DIMENSION(kms:kme), INTENT(IN) :: fzm, fzp
    INTEGER :: i_start, i_end, j_start, j_end, k_start, k_end
    INTEGER :: i, j, k
    REAL :: w1, w2, z0, z1, z2
    REAL :: a_w1, a_w2, a_z0, a_z1, a_z2
    REAL :: tmp
    REAL :: tmp0
    REAL :: tmp1
    REAL :: tmp2
    REAL :: tmp3
    INTEGER :: branch
    REAL :: temp3
    REAL :: temp2
    REAL :: temp1
    REAL :: temp0
    REAL :: temp0b
    REAL :: tmp0b
    REAL :: tmp1b
    REAL :: temp4b
    REAL :: tmp2b
    REAL :: temp0b1
    REAL :: temp0b0
    REAL :: tmp3b
    REAL :: temp4b3
    REAL :: temp4b2
    REAL :: temp4b1
    REAL :: temp4b0
    REAL :: a_y2
    REAL :: a_y1
    REAL :: temp
    REAL :: y2
    REAL :: temp5
    REAL :: y1
    REAL :: tmpb
    REAL :: temp4
    i_start = its
    IF (ite .GT. ide - 1) THEN
      i_end = ide - 1
    ELSE
      i_end = ite
    END IF
    j_start = jts
    IF (jte .GT. jde - 1) THEN
      j_end = jde - 1
    ELSE
      j_end = jte
    END IF
    k_start = kts
    IF (kte .GT. kde - 1) THEN
      k_end = kde - 1
    ELSE
      k_end = kte
    END IF
    DO j=j_start,j_end
      DO k=k_start,k_end
        DO i=i_start,i_end
          p_phy(i, k, j) = p(i, k, j) + pb(i, k, j)
          t_phy(i, k, j) = (t(i, k, j)+t0)*(p_phy(i, k, j)/p1000mb)**rcp
        END DO
      END DO
    END DO
    DO j=j_start,j_end
      DO i=i_start,i_end
        tmp = p_phy(i, k_end, j)
        CALL PUSHREAL8(p_phy(i, kte, j))
        p_phy(i, kte, j) = tmp
        tmp0 = t_phy(i, k_end, j)
        t_phy(i, kte, j) = tmp0
      END DO
    END DO
    DO j=j_start,j_end
      DO k=k_start,kte
        DO i=i_start,i_end
          z_at_w(i, k, j) = (phb(i, k, j)+ph(i, k, j))/g
        END DO
      END DO
    END DO
    DO j=j_start,j_end
      DO k=k_start,k_end
        DO i=i_start,i_end
          z(i, k, j) = 0.5*(z_at_w(i, k, j)+z_at_w(i, k+1, j))
          y2 = moist(i, k, j, p_qv)/(3.80*EXP(17.27*(t_phy(i, k, j)-273.&
&            )/(t_phy(i, k, j)-36.))/(.01*p_phy(i, k, j)))
          IF (.95 .GT. y2) THEN
            y1 = y2
            CALL PUSHCONTROL1B(0)
          ELSE
            y1 = .95
            CALL PUSHCONTROL1B(1)
          END IF
          IF (.1 .LT. y1) THEN
            CALL PUSHCONTROL1B(0)
          ELSE
            CALL PUSHCONTROL1B(1)
          END IF
        END DO
      END DO
    END DO
    DO j=j_end,j_start,-1
      DO i=i_end,i_start,-1
        z0 = z_at_w(i, kte, j)
        z1 = z(i, k_end, j)
        z2 = z(i, k_end-1, j)
        w1 = (z0-z2)/(z1-z2)
        w2 = 1. - w1
        a_t_phy(i, kde-1, j) = a_t_phy(i, kde-1, j) + w1*a_t8w(i, kde, j&
&          )
        a_t_phy(i, kde-2, j) = a_t_phy(i, kde-2, j) + w2*a_t8w(i, kde, j&
&          )
        temp5 = LOG(p_phy(i, kde-2, j))
        temp4 = LOG(p_phy(i, kde-1, j))
        temp4b = EXP(w1*temp4+w2*temp5)*a_p8w(i, kde, j)
        a_w2 = temp5*temp4b + t_phy(i, kde-2, j)*a_t8w(i, kde, j)
        a_w1 = temp4*temp4b - a_w2 + t_phy(i, kde-1, j)*a_t8w(i, kde, &
&          j)
        a_t8w(i, kde, j) = 0.0_8
        a_p_phy(i, kde-1, j) = a_p_phy(i, kde-1, j) + w1*temp4b/p_phy(&
&          i, kde-1, j)
        a_p_phy(i, kde-2, j) = a_p_phy(i, kde-2, j) + w2*temp4b/p_phy(&
&          i, kde-2, j)
        a_p8w(i, kde, j) = 0.0_8
        temp4b0 = a_w1/(z1-z2)
        temp4b1 = -((z0-z2)*temp4b0/(z1-z2))
        a_z0 = temp4b0
        a_z2 = -temp4b1 - temp4b0
        a_z1 = temp4b1
        a_z(i, k_end-1, j) = a_z(i, k_end-1, j) + a_z2
        a_z(i, k_end, j) = a_z(i, k_end, j) + a_z1
        a_z_at_w(i, kte, j) = a_z_at_w(i, kte, j) + a_z0
        z0 = z_at_w(i, 1, j)
        z1 = z(i, 1, j)
        z2 = z(i, 2, j)
        w1 = (z0-z2)/(z1-z2)
        w2 = 1. - w1
        a_t_phy(i, 1, j) = a_t_phy(i, 1, j) + w1*a_t8w(i, 1, j)
        a_w2 = p_phy(i, 2, j)*a_p8w(i, 1, j) + t_phy(i, 2, j)*a_t8w(i, 1&
&          , j)
        a_w1 = p_phy(i, 1, j)*a_p8w(i, 1, j) - a_w2 + t_phy(i, 1, j)*&
&          a_t8w(i, 1, j)
        a_t_phy(i, 2, j) = a_t_phy(i, 2, j) + w2*a_t8w(i, 1, j)
        a_t8w(i, 1, j) = 0.0_8
        a_p_phy(i, 1, j) = a_p_phy(i, 1, j) + w1*a_p8w(i, 1, j)
        a_p_phy(i, 2, j) = a_p_phy(i, 2, j) + w2*a_p8w(i, 1, j)
        a_p8w(i, 1, j) = 0.0_8
        temp4b2 = a_w1/(z1-z2)
        temp4b3 = -((z0-z2)*temp4b2/(z1-z2))
        a_z0 = temp4b2
        a_z2 = -temp4b3 - temp4b2
        a_z1 = temp4b3
        a_z(i, 2, j) = a_z(i, 2, j) + a_z2
        a_z(i, 1, j) = a_z(i, 1, j) + a_z1
        a_z_at_w(i, 1, j) = a_z_at_w(i, 1, j) + a_z0
      END DO
    END DO
    DO j=j_end,j_start,-1
      DO k=k_end,2,-1
        DO i=i_end,i_start,-1
          a_t_phy(i, k, j) = a_t_phy(i, k, j) + fzm(k)*a_t8w(i, k, j)
          a_t_phy(i, k-1, j) = a_t_phy(i, k-1, j) + fzp(k)*a_t8w(i, k, j&
&            )
          a_t8w(i, k, j) = 0.0_8
          a_p_phy(i, k, j) = a_p_phy(i, k, j) + fzm(k)*a_p8w(i, k, j)
          a_p_phy(i, k-1, j) = a_p_phy(i, k-1, j) + fzp(k)*a_p8w(i, k, j&
&            )
          a_p8w(i, k, j) = 0.0_8
        END DO
      END DO
    END DO
    DO j=j_end,j_start,-1
      DO k=k_end,k_start,-1
        DO i=i_end,i_start,-1
          CALL POPCONTROL1B(branch)
          IF (branch .EQ. 0) THEN
            a_y1 = a_rh(i, k, j)
            a_rh(i, k, j) = 0.0_8
          ELSE
            a_rh(i, k, j) = 0.0_8
            a_y1 = 0.0_8
          END IF
          CALL POPCONTROL1B(branch)
          IF (branch .EQ. 0) THEN
            a_y2 = a_y1
          ELSE
            a_y2 = 0.0_8
          END IF
          temp3 = t_phy(i, k, j) - 36.
          temp0 = (t_phy(i, k, j)-273.)/temp3
          temp2 = 3.80*EXP(17.27*temp0)
          temp1 = moist(i, k, j, p_qv)
          temp0b0 = .01*a_y2/temp2
          temp0b1 = -(17.27*EXP(17.27*temp0)*3.80*temp1*p_phy(i, k, j)&
&            *temp0b0/(temp2*temp3))
          a_moist(i, k, j, p_qv) = a_moist(i, k, j, p_qv) + p_phy(i, k, &
&            j)*temp0b0
          a_p_phy(i, k, j) = a_p_phy(i, k, j) + temp1*temp0b0
          a_t_phy(i, k, j) = a_t_phy(i, k, j) + (1.0-temp0)*temp0b1
          a_z_at_w(i, k, j) = a_z_at_w(i, k, j) + 0.5*a_z(i, k, j)
          a_z_at_w(i, k+1, j) = a_z_at_w(i, k+1, j) + 0.5*a_z(i, k, j)
          a_z(i, k, j) = 0.0_8
        END DO
      END DO
    END DO
    DO j=j_end,j_start,-1
      DO i=i_end,i_start,-1
        a_dz8w(i, kte, j) = 0.0_8
      END DO
    END DO
    DO j=j_end,j_start,-1
      DO k=kte-1,k_start,-1
        DO i=i_end,i_start,-1
          a_z_at_w(i, k+1, j) = a_z_at_w(i, k+1, j) + a_dz8w(i, k, j)
          a_z_at_w(i, k, j) = a_z_at_w(i, k, j) - a_dz8w(i, k, j)
          a_dz8w(i, k, j) = 0.0_8
        END DO
      END DO
    END DO
    DO j=j_end,j_start,-1
      DO k=kte,k_start,-1
        DO i=i_end,i_start,-1
          a_ph(i, k, j) = a_ph(i, k, j) + a_z_at_w(i, k, j)/g
          a_z_at_w(i, k, j) = 0.0_8
        END DO
      END DO
    END DO
    DO j=j_end,j_start,-1
      DO i=i_end,i_start,-1
        tmp3b = a_v_phy(i, kte, j)
        a_v_phy(i, kte, j) = 0.0_8
        a_v_phy(i, k_end, j) = a_v_phy(i, k_end, j) + tmp3b
        tmp2b = a_u_phy(i, kte, j)
        a_u_phy(i, kte, j) = 0.0_8
        a_u_phy(i, k_end, j) = a_u_phy(i, k_end, j) + tmp2b
        tmp1b = a_rho(i, kte, j)
        a_rho(i, kte, j) = 0.0_8
        a_rho(i, k_end, j) = a_rho(i, k_end, j) + tmp1b
        tmp0b = a_t_phy(i, kte, j)
        a_t_phy(i, kte, j) = 0.0_8
        a_t_phy(i, k_end, j) = a_t_phy(i, k_end, j) + tmp0b
        CALL POPREAL8(p_phy(i, kte, j))
        tmpb = a_p_phy(i, kte, j)
        a_p_phy(i, kte, j) = 0.0_8
        a_p_phy(i, k_end, j) = a_p_phy(i, k_end, j) + tmpb
      END DO
    END DO
    DO j=j_end,j_start,-1
      DO k=k_end,k_start,-1
        DO i=i_end,i_start,-1
          a_v(i, k, j) = a_v(i, k, j) + 0.5*a_v_phy(i, k, j)
          a_v(i, k, j+1) = a_v(i, k, j+1) + 0.5*a_v_phy(i, k, j)
          a_v_phy(i, k, j) = 0.0_8
          a_u(i, k, j) = a_u(i, k, j) + 0.5*a_u_phy(i, k, j)
          a_u(i+1, k, j) = a_u(i+1, k, j) + 0.5*a_u_phy(i, k, j)
          a_u_phy(i, k, j) = 0.0_8
          temp0b = a_rho(i, k, j)/alt(i, k, j)
          a_moist(i, k, j, p_qv) = a_moist(i, k, j, p_qv) + temp0b
          a_alt(i, k, j) = a_alt(i, k, j) - (moist(i, k, j, p_qv)+1.)*&
&            temp0b/alt(i, k, j)
          a_rho(i, k, j) = 0.0_8
          temp = p_phy(i, k, j)/p1000mb
          a_t(i, k, j) = a_t(i, k, j) + temp**rcp*a_t_phy(i, k, j)
          IF (.NOT.(temp .LE. 0.0_8 .AND. (rcp .EQ. 0.0_8 .OR. rcp .NE. &
&              INT(rcp)))) a_p_phy(i, k, j) = a_p_phy(i, k, j) + rcp*temp&
&              **(rcp-1)*(t0+t(i, k, j))*a_t_phy(i, k, j)/p1000mb
          a_t_phy(i, k, j) = 0.0_8
          a_p(i, k, j) = a_p(i, k, j) + a_p_phy(i, k, j)
          a_p_phy(i, k, j) = 0.0_8
        END DO
      END DO
    END DO
  END SUBROUTINE A_CHEM_PREP
END MODULE A_MODULE_CHEM_UTILITIES
