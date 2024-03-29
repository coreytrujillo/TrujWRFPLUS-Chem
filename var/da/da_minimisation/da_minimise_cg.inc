subroutine da_minimise_cg(grid, config_flags,            &
                           it, cv_size, xbx, be, iv, &
                           j_grad_norm_target, xhat, cv, &
                           re, y, j_cost)

   !-------------------------------------------------------------------------
   ! Purpose:         Main Conjugate Gradient minimisation routine 
   !
   ! Here 
   !    cv   is updated in outer-loop.
   !    xhat is the control variable in inner-loop.
   !
   ! Called from da_solve
   !
   ! History: 12/12/08 - Split J and GradJ calculations (Tom Auligne)
   !          12/12/08 - Re-orthonormalization option   (Tom Auligne)
   !
   !          Sep. 2010 - Add Cloud control variables   (hongli Wang)
   !          09/06/12 - Allow for variable ntmax in each outerloop (Mike Kavulich)
   !-------------------------------------------------------------------------

   implicit none

   integer, intent(in)               :: it    ! external iteration.
   integer, intent(in)               :: cv_size          ! Total cv size
   type (xbx_type),intent(inout)     :: xbx   ! Header & non-gridded vars.
   type (be_type), intent(in)        :: be    ! background error structure.
   type (iv_type), intent(inout)     :: iv    ! ob. increment vector.
   real, intent(inout)               :: j_grad_norm_target ! Target norm.
   real, intent(inout)               :: xhat(1:cv_size)  ! control variable (local).
   real, intent(inout)               :: cv(1:cv_size)    ! control variable (local).
   type (y_type), intent(inout)      :: re    ! residual (o-a) structure.
   type (y_type), intent(inout)      :: y     ! y = H(x_inc) structure.

   type (j_type), intent(out)        :: j_cost                 ! cost function

   type(domain), intent(inout)       :: grid
   type(grid_config_rec_type), intent(inout) :: config_flags

   integer                           :: iter            
   integer                           :: jp_start, jp_end       ! Start/end indices of Jp.
#ifdef CLOUD_CV
   integer                           :: mz(13)
#else
   integer                           :: mz(7)
#endif
   real                              :: fhat(1:cv_size)        ! cv copy.
   real                              :: ghat(1:cv_size)        ! cv copy.
   real                              :: ghat0(1:cv_size)       ! cv copy.
   real                              :: phat(1:cv_size)        ! cv copy.
   type(qhat_type), allocatable      :: qhat(:)                ! cv copy.
   real                              :: apdotp,step,rrmold,rrmnew,ratio 
   real                              :: ob_grad, rrmnew_norm, gdot
   real                              :: j_total, j0_total
 
   ! Variables for Conjugate Gradient preconditioning
   real                              :: precon(1:cv_size)      ! cv copy.
   real                              :: g_total, g_partial, jo_partial                          
   integer                           :: i, ii, nv, nn, istart, iend
#ifdef CLOUD_CV
   integer                           ::  sz(11)
#else
   integer                           ::  sz(5)
#endif

   if (trace_use) call da_trace_entry("da_minimise_cg")

   write(unit=stdout,fmt='(A)') 'Minimize cost function using CG method'
   write(unit=stdout,fmt=*) ' '

   !-------------------------------------------------------------------------
   ! [1.0] Initialization:
   !-------------------------------------------------------------------------
#ifdef CLOUD_CV
   mz = (/ be%v1%mz, be%v2%mz, be%v3%mz, be%v4%mz, be%v5%mz, be%v6%mz, be%v7%mz,be%v8%mz,be%v9%mz,be%v10%mz,be%v11%mz, be%alpha%mz, be % ne /)
   sz = (/ be%cv%size1, be%cv%size2, be%cv%size3, be%cv%size4, be%cv%size5, be%cv%size6, be%cv%size7,be%cv%size8, be%cv%size9,be%cv%size10,be%cv%size11i /)
#else
   mz = (/ be%v1%mz, be%v2%mz, be%v3%mz, be%v4%mz, be%v5%mz, be%alpha%mz, be % ne /)
   sz = (/ be%cv%size1, be%cv%size2, be%cv%size3, be%cv%size4, be%cv%size5 /)
#endif   
   jp_start   = be % cv % size_jb + be % cv % size_je + 1
   jp_end     = be % cv % size_jb + be % cv % size_je + be % cv % size_jp

   call da_calculate_j(it, 0, cv_size, be%cv%size_jb, be%cv%size_je, be%cv%size_jp, &
                       be%cv%size_jl, xbx, be, iv, xhat, cv, re, y, j_cost, ghat, grid, config_flags)

   j0_total = j_cost%total
   if (j0_total == 0.0) then
      if (trace_use) call da_trace_exit("da_minimise_cg")
      return
   end if
   ghat0 = ghat
   
   ! [1.1] Preconditioning:
   !-----------------------
   precon  = 1.0
   
   if (precondition_cg) then
      g_total = da_dot(cv_size,ghat,ghat)
      
      iend    = 0
#ifdef CLOUD_CV
      do nv = 1, 11 
#else
      do nv = 1, 5
#endif
         nn = sz(nv) / mz(nv)
	 do ii = 1, mz(nv)
            istart     = iend + 1
            iend       = istart + nn - 1
	    g_partial  = da_dot(nn, ghat(istart:iend), ghat(istart:iend))
#ifdef CLOUD_CV
            jo_partial = j0_total / SUM(mz(1:10))
#else
            jo_partial = j0_total / SUM(mz(1:5))
#endif
	    precon(istart:iend)=  1 / &
	       (1 + precondition_factor*(g_partial/g_total)/(jo_partial/j0_total)) 
	 end do
      end do
   end if
   
   phat  = - precon * ghat

   rrmold = da_dot_cv(cv_size, -phat, ghat, grid, mz, jp_start, jp_end)
   j_grad_norm_target = sqrt (rrmold)

   if (orthonorm_gradient) then
      allocate(qhat(0:ntmax(it)))
      allocate(qhat(0)%values(1:cv_size))
      qhat(0)%values = ghat / sqrt(rrmold)
   end if

   write(unit=stdout,fmt='("Starting outer iteration : ",i3)') it
   write(unit=stdout,fmt=11) j0_total, sqrt(rrmold), eps(it)*j_grad_norm_target
11 format('Starting cost function: ' ,1PD22.15,', Gradient= ',1PD22.15,/,&
          'For this outer iteration gradient target is:       ',1PD22.15)
   write(unit=stdout,fmt='(A)') &
      '----------------------------------------------------------------------'
   write(unit=stdout,fmt='(A)') &
      '              Loop Iter     Cost Function              Gradient                   Step'

   write(unit=stdout,fmt=12) " minimize_cg ", it, 0, j0_total, sqrt(rrmold), 0.0

   !-------------------------------------------------------------------------
   ! [2.0] iteratively solve for minimum of cost function:
   !-------------------------------------------------------------------------

   do iter=1, ntmax(it)
      if (rrmold == 0.0) exit

      call da_calculate_gradj(it,iter,cv_size,be%cv%size_jb,be%cv%size_je,be%cv%size_jp, &
                              be%cv%size_jl,xbx,be,iv,phat,y,fhat,grid,config_flags)				 
      
      apdotp = da_dot_cv(cv_size, fhat, phat, grid, mz, jp_start, jp_end)

      step = 0.0
      if (apdotp .gt. 0.0) step = rrmold/apdotp
      
      ghat = ghat + step * fhat
      xhat = xhat + step * phat
      
    ! Orthonormalize new gradient (using modified Gramm-Schmidt algorithm)
      if (orthonorm_gradient) then
         do i = iter-1, 0, -1
            gdot = da_dot_cv(cv_size, ghat, qhat(i)%values, grid, mz, jp_start, jp_end)
            ghat = ghat - gdot * qhat(i)%values
         end do
      end if
      
      rrmnew = da_dot_cv (cv_size, precon*ghat, ghat, grid, mz, jp_start, jp_end)
      rrmnew_norm = sqrt(rrmnew)

      ratio = 0.0
      if (rrmold .gt. 0.0) ratio = rrmnew/rrmold

      if (orthonorm_gradient) then
         allocate(qhat(iter)%values(1:cv_size))
         qhat(iter)%values = ghat / rrmnew_norm
      end if

      phat         = - precon * ghat       + ratio * phat

      rrmold=rrmnew

    ! Print Gradient (and Cost Function)
    !-----------------------------------

      if (calculate_cg_cost_fn) then
         call da_calculate_j(it, iter, cv_size, be%cv%size_jb, be%cv%size_je, be%cv%size_jp, &
	                     be%cv%size_jl, xbx, be, iv, xhat, cv, re, y, j_cost, fhat, grid, config_flags)
         j_total = j_cost%total
      else
         j_total = j0_total + 0.5 * da_dot_cv(cv_size,ghat0,xhat,grid,mz,jp_start,jp_end)
      endif

      write(unit=stdout,fmt=12) " minimize_cg ", it, iter, j_total, rrmnew_norm, step         	 
      if (rrmnew_norm  < eps(it) * j_grad_norm_target) exit

12    format(a13,1x,i3,1x,i4,5x,1PD22.15,5x,1PD22.15,5x,1PD22.15)

   end do

   !-------------------------------------------------------------------------
   ! End of the minimization of cost function
   !-------------------------------------------------------------------------
   iter = MIN(iter, ntmax(it))

   ! Free memory used for reorthonormalization
   !------------------------------------------
   if (orthonorm_gradient) then
      do i = iter-1, 0, -1
         if (allocated(qhat(i)%values)) deallocate(qhat(i)%values)
      end do
      deallocate(qhat)
   end if
   
   write(unit=stdout,fmt='(A)') &
      '----------------------------------------------------------------------'
   write(unit=stdout,fmt='(A)') " "
   write(unit=stdout, &
      fmt='("Inner iteration stopped after ",i4," iterations")') iter
   write(unit=stdout,fmt='(A)') " "

   call da_calculate_j(it, iter, cv_size, be%cv%size_jb, be%cv%size_je, be%cv%size_jp, &
                       be%cv%size_jl, xbx, be, iv, xhat, cv, re, y, j_cost, ghat, grid, config_flags)

   rrmnew_norm = SQRT(da_dot_cv(cv_size,ghat,ghat,grid,mz,jp_start,jp_end))

    write(unit=stdout,fmt=15) iter, j_cost%total , rrmnew_norm
15  format('Final: ',I3,' iter, J=',1PD22.15,', g=',1PD22.15)
    write(unit=stdout,fmt='(A)') &
      '----------------------------------------------------------------------'

   if (trace_use) call da_trace_exit("da_minimise_cg")

end subroutine da_minimise_cg
