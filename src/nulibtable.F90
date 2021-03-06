!-*-f90-*-
module nulibtable

  implicit none

  integer, save :: nulibtable_number_species
  integer, save :: nulibtable_number_groups
  
  real*8, allocatable,save :: nulibtable_logrho(:)
  real*8, allocatable,save :: nulibtable_logtemp(:)
  real*8, allocatable,save :: nulibtable_ye(:)
  real*8, allocatable,save :: nulibtable_logItemp(:)
  real*8, allocatable,save :: nulibtable_logIeta(:)
  
  real*8, allocatable,save :: nulibtable_energies(:)
  real*8, allocatable,save :: nulibtable_inv_energies(:)
  real*8, allocatable,save :: nulibtable_ewidths(:)
  real*8, allocatable,save :: nulibtable_ebottom(:)
  real*8, allocatable,save :: nulibtable_etop(:)
  real*8, allocatable,save :: nulibtable_logenergies(:)
  real*8, allocatable,save :: nulibtable_logetop(:)

  real*8, allocatable,save :: nulibtable_emissivities(:,:,:,:)
  real*8, allocatable,save :: nulibtable_absopacity(:,:,:,:)
  real*8, allocatable,save :: nulibtable_scatopacity(:,:,:,:)
  real*8, allocatable,save :: nulibtable_delta(:,:,:,:)

  real*8, allocatable,save :: nulibtable_Itable_Phi0(:,:,:)
  real*8, allocatable,save :: nulibtable_Itable_Phi1(:,:,:)

  real*8, allocatable,save :: nulibtable_epannihiltable_Phi0(:,:,:)
  real*8, allocatable,save :: nulibtable_epannihiltable_Phi1(:,:,:)

  integer, save :: nulibtable_nrho
  integer, save :: nulibtable_ntemp
  integer, save :: nulibtable_nye
  integer, save :: nulibtable_nItemp
  integer, save :: nulibtable_nIeta

  real*8, save :: nulibtable_logrho_min
  real*8, save :: nulibtable_logrho_max

  real*8, save :: nulibtable_logtemp_min
  real*8, save :: nulibtable_logtemp_max

  real*8, save :: nulibtable_ye_min
  real*8, save :: nulibtable_ye_max

  real*8, save :: nulibtable_logItemp_min
  real*8, save :: nulibtable_logItemp_max

  real*8, save :: nulibtable_logIeta_min
  real*8, save :: nulibtable_logIeta_max

  integer, save :: nulibtable_number_easvariables

end module nulibtable

module nulibtable_interface

  interface
     subroutine nulibtable_reader(filename,include_Ielectron,include_epannihil_kernels,include_scattering_delta)
       implicit none

       character(*) :: filename
       logical,optional :: include_Ielectron
       logical,optional :: include_epannihil_kernels
       logical,optional :: include_scattering_delta
     end subroutine nulibtable_reader
  end interface

end module nulibtable_interface

!this takes rho,temp,ye,species and energy and return eas
subroutine nulibtable_single_species_single_energy(xrho,xtemp,xye,lns,lng,eas,eas_n1)
  
  use nulibtable
  implicit none

  real*8, intent(in) :: xrho, xtemp, xye !inputs
  real*8 :: xlrho, xltemp !log versions
  integer, intent(in) :: lns, lng
  integer, intent(in) :: eas_n1
  real*8, intent(out) :: eas(eas_n1)
  integer :: startindex,endindex

  if (eas_n1.ne.nulibtable_number_easvariables) stop "supplied array dimensions (1) is not commensurate with table"
  
  xlrho = log10(xrho)
  xltemp = log10(xtemp)

  if (xlrho.lt.nulibtable_logrho_min) stop "density below nulib table minimum rho"
  if (xlrho.gt.nulibtable_logrho_max) stop "density above nulib table maximum rho"
  if (xltemp.lt.nulibtable_logtemp_min) stop "temperature below nulib table minimum temp"
  if (xltemp.gt.nulibtable_logtemp_max) stop "temperature above nulib table maximum temp"
  if (xye.lt.nulibtable_ye_min) stop "ye below nulib table minimum ye"
  if (xye.gt.nulibtable_ye_max) stop "ye above nulib table maximum ye"

  startindex = (lns-1)*nulibtable_number_groups+(lng-1)+1
  endindex = startindex

  call intp3d_many_mod(xlrho,xltemp,xye,eas(1), &
       nulibtable_emissivities(:,:,:,startindex:endindex),nulibtable_nrho, &
       nulibtable_ntemp,nulibtable_nye,1,nulibtable_logrho, &
       nulibtable_logtemp,nulibtable_ye)

  call intp3d_many_mod(xlrho,xltemp,xye,eas(2), &
       nulibtable_absopacity(:,:,:,startindex:endindex),nulibtable_nrho, &
       nulibtable_ntemp,nulibtable_nye,1,nulibtable_logrho, &
       nulibtable_logtemp,nulibtable_ye)

  call intp3d_many_mod(xlrho,xltemp,xye,eas(3), &
       nulibtable_scatopacity(:,:,:,startindex:endindex),nulibtable_nrho, &
       nulibtable_ntemp,nulibtable_nye,1,nulibtable_logrho, &
       nulibtable_logtemp,nulibtable_ye)

  eas(:) = 10.0d0**eas(:)

  if(eas_n1 == 4) then
     call intp3d_many_mod(xlrho,xltemp,xye,eas(4), &
          nulibtable_delta(:,:,:,startindex:endindex),nulibtable_nrho, &
          nulibtable_ntemp,nulibtable_nye,1,nulibtable_logrho, &
          nulibtable_logtemp,nulibtable_ye)
  endif


end subroutine nulibtable_single_species_single_energy

!this takes rho,temp,ye,species and return eas over energy range
subroutine nulibtable_single_species_range_energy(xrho,xtemp,xye,lns,eas,eas_n1,eas_n2)
  
  use nulibtable
  implicit none

  real*8, intent(in) :: xrho, xtemp, xye !inputs
  real*8 :: xlrho, xltemp !log versions
  integer, intent(in) :: lns
  integer, intent(in) :: eas_n1,eas_n2
  real*8, intent(out) :: eas(eas_n1,eas_n2)
  integer :: ing
  real*8 :: xeas(eas_n1)
  integer :: startindex,endindex

  if(size(eas,1).ne.nulibtable_number_groups) then
     stop "nulibtable_single_species_range_energy: supplied array dimensions (2) is not commensurate with table"
  endif
  if(size(eas,2).ne.nulibtable_number_easvariables) then
     stop "nulibtable_single_species_range_energy: supplied array dimensions (1) is not commensurate with table"
  endif
  xlrho = log10(xrho)
  xltemp = log10(xtemp)

  if (xlrho.lt.nulibtable_logrho_min) stop "density below nulib table minimum rho"
  if (xlrho.gt.nulibtable_logrho_max) stop "density above nulib table maximum rho"
  if (xltemp.lt.nulibtable_logtemp_min) stop "temperature below nulib table minimum temp"
  if (xltemp.gt.nulibtable_logtemp_max) stop "temperature above nulib table maximum temp"
  if (xye.lt.nulibtable_ye_min) stop "ye below nulib table minimum ye"
  if (xye.gt.nulibtable_ye_max) stop "ye above nulib table maximum ye"

  startindex = (lns-1)*nulibtable_number_groups+1
  endindex = startindex + nulibtable_number_groups - 1

  xeas = 0.0d0
  call intp3d_many_mod(xlrho,xltemp,xye,xeas, &
       nulibtable_emissivities(:,:,:,startindex:endindex),nulibtable_nrho, &
       nulibtable_ntemp,nulibtable_nye,eas_n1,nulibtable_logrho, &
       nulibtable_logtemp,nulibtable_ye)
  
  eas(:,1) = 10.0d0**xeas(:)

  xeas = 0.0d0
  call intp3d_many_mod(xlrho,xltemp,xye,xeas, &
       nulibtable_absopacity(:,:,:,startindex:endindex),nulibtable_nrho, &
       nulibtable_ntemp,nulibtable_nye,eas_n1,nulibtable_logrho, &
       nulibtable_logtemp,nulibtable_ye)
  
  eas(:,2) = 10.0d0**xeas(:)

  xeas = 0.0d0
  call intp3d_many_mod(xlrho,xltemp,xye,xeas, &
       nulibtable_scatopacity(:,:,:,startindex:endindex),nulibtable_nrho, &
       nulibtable_ntemp,nulibtable_nye,eas_n1,nulibtable_logrho, &
       nulibtable_logtemp,nulibtable_ye)
  
  eas(:,3) = 10.0d0**xeas(:)

  if(eas_n2 == 4) then
     xeas = 0.0d0
     call intp3d_many_mod(xlrho,xltemp,xye,xeas, &
          nulibtable_delta(:,:,:,startindex:endindex),nulibtable_nrho, &
          nulibtable_ntemp,nulibtable_nye,eas_n1,nulibtable_logrho, &
          nulibtable_logtemp,nulibtable_ye)
     eas(:,4) = xeas(:)
  endif

end subroutine nulibtable_single_species_range_energy

!this takes rho,temp,ye,species and return eas over energy and species range
subroutine nulibtable_range_species_range_energy(xrho,xtemp,xye,eas,eas_n1,eas_n2,eas_n3)
  
  use nulibtable
  implicit none

  real*8, intent(in) :: xrho, xtemp, xye !inputs
  real*8 :: xlrho, xltemp !log versions
  integer, intent(in) :: eas_n1,eas_n2,eas_n3
  real*8, intent(out) :: eas(eas_n1,eas_n2,eas_n3)
  integer :: ins,ing
  real*8 :: xeas(eas_n1*eas_n2)
  integer :: index

  if(size(eas,1).ne.nulibtable_number_species) then
     stop "nulibtable_range_species_range_energy: supplied array dimensions (2) is not commensurate with table"
  endif
  if(size(eas,2).ne.nulibtable_number_groups) then
     stop "nulibtable_range_species_range_energy: supplied array dimensions (3) is not commensurate with table"
  endif  
  if(size(eas,3).ne.nulibtable_number_easvariables) then
     stop "nulibtable_range_species_range_energy: supplied array dimensions (1) is not commensurate with table"
  endif

  xlrho = log10(xrho)
  xltemp = log10(xtemp)

  if (xlrho.lt.nulibtable_logrho_min) stop "density below nulib table minimum rho"
  if (xlrho.gt.nulibtable_logrho_max) stop "density above nulib table maximum rho"
  if (xltemp.lt.nulibtable_logtemp_min) stop "temperature below nulib table minimum temp"
  if (xltemp.gt.nulibtable_logtemp_max) stop "temperature above nulib table maximum temp"
  if (xye.lt.nulibtable_ye_min) stop "ye below nulib table minimum ye"
  if (xye.gt.nulibtable_ye_max) stop "ye above nulib table maximum ye"

  xeas = 0.0d0
  call intp3d_many_mod(xlrho,xltemp,xye,xeas,nulibtable_emissivities,nulibtable_nrho, &
       nulibtable_ntemp,nulibtable_nye,eas_n1*eas_n2,nulibtable_logrho, &
       nulibtable_logtemp,nulibtable_ye)

  do ins=1,nulibtable_number_species
     do ing=1,nulibtable_number_groups
        index = (ins-1)*nulibtable_number_groups + (ing-1) + 1
        eas(ins,ing,1) = 10.0d0**xeas(index)
     enddo
  enddo

  xeas = 0.0d0
  call intp3d_many_mod(xlrho,xltemp,xye,xeas,nulibtable_absopacity,nulibtable_nrho, &
       nulibtable_ntemp,nulibtable_nye,eas_n1*eas_n2,nulibtable_logrho, &
       nulibtable_logtemp,nulibtable_ye)

  do ins=1,nulibtable_number_species
     do ing=1,nulibtable_number_groups
        index = (ins-1)*nulibtable_number_groups + (ing-1) + 1
        eas(ins,ing,2) = 10.0d0**xeas(index)
     enddo
  enddo

  xeas = 0.0d0
  call intp3d_many_mod(xlrho,xltemp,xye,xeas,nulibtable_scatopacity,nulibtable_nrho, &
       nulibtable_ntemp,nulibtable_nye,eas_n1*eas_n2,nulibtable_logrho, &
       nulibtable_logtemp,nulibtable_ye)

  do ins=1,nulibtable_number_species
     do ing=1,nulibtable_number_groups
        index = (ins-1)*nulibtable_number_groups + (ing-1) + 1
        eas(ins,ing,3) = 10.0d0**xeas(index)
     enddo
  enddo

  if(eas_n3 == 4) then
     xeas = 0.0d0
     call intp3d_many_mod(xlrho,xltemp,xye,xeas,nulibtable_delta,nulibtable_nrho, &
          nulibtable_ntemp,nulibtable_nye,eas_n1*eas_n2,nulibtable_logrho, &
          nulibtable_logtemp,nulibtable_ye)

     do ins=1,nulibtable_number_species
        do ing=1,nulibtable_number_groups
           index = (ins-1)*nulibtable_number_groups + (ing-1) + 1
           eas(ins,ing,4) = xeas(index)
        enddo
     enddo

  endif

end subroutine nulibtable_range_species_range_energy

!this takes temp,eta, and return phi0/1 over energy (both in and out) and species range
subroutine nulibtable_inelastic_range_species_range_energy(xtemp,xeta, &
     eas,eas_n1,eas_n2,eas_n3,eas_n4)

  use nulibtable
  implicit none

  real*8, intent(in) :: xtemp, xeta !inputs
  real*8 :: xltemp, xleta !log versions
  integer, intent(in) :: eas_n1,eas_n2,eas_n3,eas_n4
  real*8, intent(out) :: eas(eas_n1,eas_n2,eas_n3,eas_n4)
  integer :: ins,ing_in,ing_out
  real*8 :: xeas(eas_n1*eas_n2*(eas_n2+1)/2)
  integer :: index

  if(size(eas,1).ne.nulibtable_number_species) then
     stop "nulibtable_inelastic_range_species_range_energy: supplied array dimensions (1) is not commensurate with table"
  endif
  if(size(eas,2).ne.nulibtable_number_groups) then
     stop "nulibtable_inelastic_range_species_range_energy: supplied array dimensions (2) is not commensurate with table"
  endif  
  if(size(eas,3).ne.nulibtable_number_groups) then
     stop "nulibtable_inelastic_range_species_range_energy: supplied array dimensions (3) is not commensurate with table"
  endif
  if(size(eas,4).ne.2) then
     stop "nulibtable_inelastic_range_species_range_energy: supplied array dimensions (4) is not commensurate with table"
  endif

  xltemp = log10(xtemp)
  xleta = log10(xeta)

  if (xltemp.lt.nulibtable_logItemp_min) stop "temp below nulib inelastic table minimum temp"
  if (xltemp.gt.nulibtable_logItemp_max) stop "temp above nulib inelastic table maximum temp"
  if (xleta.lt.nulibtable_logIeta_min) stop "eta below nulib inelastic table minimum eta"
  if (xleta.gt.nulibtable_logIeta_max) stop "eta above nulib inelastic table maximum eta"

  if (allocated(nulibtable_Itable_Phi0).eqv..false.) stop "You need to read in inelastic data"

  xeas = 0.0d0
  call intp2d_many_mod(xltemp,xleta,xeas,nulibtable_Itable_Phi0,nulibtable_nItemp, &
       nulibtable_nIeta,eas_n1*eas_n2*(eas_n2+1)/2,nulibtable_logItemp, &
       nulibtable_logIeta)

  index = 0
  do ins=1,nulibtable_number_species
     !interpolate half of the E,Eprime points
     do ing_in=1,nulibtable_number_groups
        do ing_out=1,ing_in
           index = index + 1
           eas(ins,ing_in,ing_out,1) = 10.0d0**xeas(index)
        enddo
     enddo
     !apply cernohorsky 94 on the rest
     !also, this assumes nulibtable_energies are in MeV
     do ing_in=1,nulibtable_number_groups
        do ing_out=ing_in+1,nulibtable_number_groups
           eas(ins,ing_in,ing_out,1) =  &
                exp(-(nulibtable_energies(ing_out)-nulibtable_energies(ing_in))/ &
                xtemp)*eas(ins,ing_out,ing_in,1)
        enddo
     enddo
  enddo

  xeas = 0.0d0
  call intp2d_many_mod(xltemp,xleta,xeas,nulibtable_Itable_Phi1,nulibtable_nItemp, &
       nulibtable_nIeta,eas_n1*eas_n2*(eas_n2+1)/2,nulibtable_logItemp, &
       nulibtable_logIeta)

  index = 0
  do ins=1,nulibtable_number_species
     !interpolate half of the E,Eprime points
     do ing_in=1,nulibtable_number_groups
        do ing_out=1,ing_in
           index = index + 1
           !this way because we interpolate \phi1/\phi0
           eas(ins,ing_in,ing_out,2) = xeas(index)*eas(ins,ing_in,ing_out,1)
        enddo
     enddo
     !apply cernohorsky 94 on the rest
     !also, this assumes nulibtable_energies are in MeV  
     do ing_in=1,nulibtable_number_groups
        do ing_out=ing_in+1,nulibtable_number_groups
           eas(ins,ing_in,ing_out,2) =  &
                exp(-(nulibtable_energies(ing_out)-nulibtable_energies(ing_in))/ &
                xtemp)*eas(ins,ing_out,ing_in,2)
        enddo
     enddo
  enddo  

end subroutine nulibtable_inelastic_range_species_range_energy

!this takes temp,eta, and returns phi0/1 over energy (both in and out) range for a single species, use symmetry to get other kernels
subroutine nulibtable_inelastic_single_species_range_energy(xtemp,xeta, &
     lns,eas,eas_n1,eas_n2,eas_n3)

  use nulibtable
  implicit none

  real*8, intent(in) :: xtemp, xeta !inputs
  real*8 :: xltemp, xleta !log versions
  integer, intent(in) :: lns,eas_n1,eas_n2,eas_n3
  real*8, intent(out) :: eas(eas_n1,eas_n2,eas_n3)
  integer :: ing_in,ing_out
  real*8 :: xeas(eas_n1*(eas_n1+1)/2)
  integer :: index
  integer :: startindex,endindex

  if(size(eas,1).ne.nulibtable_number_groups) then
     stop "nulibtable_inelastic_single_species_range_energy: supplied array dimensions (1) is not commensurate with table"
  endif  
  if(size(eas,2).ne.nulibtable_number_groups) then
     stop "nulibtable_inelastic_single_species_range_energy: supplied array dimensions (2) is not commensurate with table"
  endif
  if(size(eas,3).ne.2) then
     stop "nulibtable_inelastic_single_species_range_energy: supplied array dimensions (3) is not commensurate with table"
  endif

  xltemp = log10(xtemp)
  xleta = log10(xeta)

  if (xltemp.lt.nulibtable_logItemp_min) stop "temp below nulib inelastic table minimum temp"
  if (xltemp.gt.nulibtable_logItemp_max) stop "temp above nulib inelastic table maximum temp"
  if (xleta.lt.nulibtable_logIeta_min) stop "eta below nulib inelastic table minimum eta"
  if (xleta.gt.nulibtable_logIeta_max) stop "eta above nulib inelastic table maximum eta"

  if (allocated(nulibtable_Itable_Phi0).eqv..false.) stop "You need to read in inelastic data"

  startindex = (lns-1)*nulibtable_number_groups*(nulibtable_number_groups+1)/2+1
  endindex = startindex + nulibtable_number_groups*(nulibtable_number_groups+1)/2 - 1

  xeas = 0.0d0
  call intp2d_many_mod(xltemp,xleta,xeas,nulibtable_Itable_Phi0(:,:,startindex:endindex), &
       nulibtable_nItemp,nulibtable_nIeta,eas_n1*(eas_n1+1)/2, &
       nulibtable_logItemp,nulibtable_logIeta)

  index = 0
  !interpolate half of the E,Eprime points
  do ing_in=1,nulibtable_number_groups
     do ing_out=1,ing_in
        index = index + 1
        eas(ing_in,ing_out,1) = 10.0d0**xeas(index)
     enddo
  enddo
  !apply cernohorsky 94 on the rest
  !also, this assumes nulibtable_energies are in MeV
  do ing_in=1,nulibtable_number_groups
     do ing_out=ing_in+1,nulibtable_number_groups
        eas(ing_in,ing_out,1) =  &
             exp(-(nulibtable_energies(ing_out)-nulibtable_energies(ing_in))/ &
             xtemp)*eas(ing_out,ing_in,1)
     enddo
  enddo

  xeas = 0.0d0
  call intp2d_many_mod(xltemp,xleta,xeas,nulibtable_Itable_Phi1(:,:,startindex:endindex), &
       nulibtable_nItemp,nulibtable_nIeta,eas_n1*(eas_n1+1)/2, &
       nulibtable_logItemp,nulibtable_logIeta)

  index = 0
  !interpolate half of the E,Eprime points
  do ing_in=1,nulibtable_number_groups
     do ing_out=1,ing_in
        index = index + 1
        !this way because we interpolate \phi1/\phi0
        eas(ing_in,ing_out,2) = xeas(index)*eas(ing_in,ing_out,1)
     enddo
  enddo

  !apply cernohorsky 94 on the rest
  !also, this assumes nulibtable_energies are in MeV
  do ing_in=1,nulibtable_number_groups
     do ing_out=ing_in+1,nulibtable_number_groups
        eas(ing_in,ing_out,2) =  &
             exp(-(nulibtable_energies(ing_out)-nulibtable_energies(ing_in))/ &
             xtemp)*eas(ing_out,ing_in,2)
     enddo
  enddo

end subroutine nulibtable_inelastic_single_species_range_energy

subroutine nulibtable_epannihil_range_species_range_energy(xtemp,xeta, &
     eas,eas_n1,eas_n2,eas_n3,eas_n4)

  use nulibtable
  implicit none

  real*8, intent(in) :: xtemp, xeta !inputs
  real*8 :: xltemp, xleta !log versions
  integer, intent(in) :: eas_n1,eas_n2,eas_n3,eas_n4
  real*8, intent(out) :: eas(eas_n1,eas_n2,eas_n3,eas_n4)
  integer :: ins,ing_this,ing_that
  real*8 :: xeas(eas_n1*eas_n2*eas_n3)
  integer :: index

  if(size(eas,1).ne.nulibtable_number_species) then
     stop "nulibtable_epannihil_range_species_range_energy: supplied array dimensions (1) is not commensurate with table"
  endif
  if(size(eas,2).ne.nulibtable_number_groups) then
     stop "nulibtable_epannihil_range_species_range_energy: supplied array dimensions (2) is not commensurate with table"
  endif  
  if(size(eas,3).ne.nulibtable_number_groups) then
     stop "nulibtable_enannihil_range_species_range_energy: supplied array dimensions (3) is not commensurate with table"
  endif
  if(size(eas,4).ne.4) then
     stop "nulibtable_epannihil_range_species_range_energy: supplied array dimensions (4) is not commensurate with table"
  endif

  xltemp = log10(xtemp)
  xleta = log10(xeta)

  if (xltemp.lt.nulibtable_logItemp_min) stop "temp below nulib epannihil table minimum temp"
  if (xltemp.gt.nulibtable_logItemp_max) stop "temp above nulib epannihil table maximum temp"
  if (xleta.lt.nulibtable_logIeta_min) stop "eta below nulib epannihil table minimum eta"
  if (xleta.gt.nulibtable_logIeta_max) stop "eta above nulib epannihil table maximum eta"

  if (allocated(nulibtable_epannihiltable_Phi0).eqv..false.) stop "You need to read in ep-annihilation data"

  !note, no symmetries are used here, for inelastic electron
  !scattering these symmetries were crucial so that may be needed here
  !too, there is really only need for 1/4 of the coefficients, there
  !is a detailed balence symmetry and a in/out symmetry, for \nu
  !\nubar annihilation R(\nu,\nu^prime)_\mathrm{species} =
  !R(\nu^\prime,\nu)_\mathrm{antispecies} (note the antispecies relation)
  
  xeas = 0.0d0
  call intp2d_many_mod(xltemp,xleta,xeas,nulibtable_epannihiltable_Phi0,nulibtable_nItemp, &
       nulibtable_nIeta,eas_n1*eas_n2*eas_n2,nulibtable_logItemp, &
       nulibtable_logIeta)

  index = 0
  do ins=1,nulibtable_number_species
     do ing_this=1,nulibtable_number_groups
        do ing_that=1,nulibtable_number_groups
           index = index + 1
           eas(ins,ing_this,ing_that,2) = 10.0d0**xeas(index) !annihilation

           !use this if you want to impose detailed balance between
           !production and annihilation after interpolation, could use
           !to cut down interpolation by half... - confirm the expression
           !also, this assumes nulibtable_energies are in MeV
           eas(ins,ing_this,ing_that,1) = eas(ins,ing_this,ing_that,2)* &
                exp(-(nulibtable_energies(ing_this)+nulibtable_energies(ing_that))/xtemp) !production

        enddo
     enddo
  enddo

  xeas = 0.0d0
  call intp2d_many_mod(xltemp,xleta,xeas,nulibtable_epannihiltable_Phi1,nulibtable_nItemp, &
       nulibtable_nIeta,eas_n1*eas_n2*eas_n2,nulibtable_logItemp, &
       nulibtable_logIeta)

  index = 0
  do ins=1,nulibtable_number_species
     do ing_this=1,nulibtable_number_groups
        do ing_that=1,nulibtable_number_groups
           !this way because we interpolate \phi1/\phi0
           index = index + 1
           eas(ins,ing_this,ing_that,4) = xeas(index)*eas(ins,ing_this,ing_that,2) !annihilation

           !use this if you want to impose detailed balance between
           !production and annihilation after interpolation, could use
           !to cut down interpolation by half... - confirm the expression
           !also, this assumes nulibtable_energies are in MeV
           eas(ins,ing_this,ing_that,3) = eas(ins,ing_this,ing_that,4)* &
                exp(-(nulibtable_energies(ing_this)+nulibtable_energies(ing_that))/xtemp) !production
        enddo
     enddo
  enddo  

end subroutine nulibtable_epannihil_range_species_range_energy

subroutine nulibtable_epannihil_single_species_range_energy(xtemp,xeta, &
     lns,eas,eas_n1,eas_n2,eas_n3)

  use nulibtable
  implicit none

  real*8, intent(in) :: xtemp, xeta !inputs
  real*8 :: xltemp, xleta !log versions
  integer, intent(in) :: lns,eas_n1,eas_n2,eas_n3
  real*8, intent(out) :: eas(eas_n1,eas_n2,eas_n3)
  integer :: ing_this,ing_that
  real*8 :: xeas(eas_n1*eas_n2)
  integer :: index
  integer :: startindex,endindex

  if(size(eas,1).ne.nulibtable_number_groups) then
     stop "nulibtable_epannihil_single_species_range_energy: supplied array dimensions (1) is not commensurate with table"
  endif  
  if(size(eas,2).ne.nulibtable_number_groups) then
     stop "nulibtable_epannihil_single_species_range_energy: supplied array dimensions (2) is not commensurate with table"
  endif
  if(size(eas,3).ne.4) then
     stop "nulibtable_epannihil_single_species_range_energy: supplied array dimensions (3) is not commensurate with table"
  endif

  xltemp = log10(xtemp)
  xleta = log10(xeta)

  if (xltemp.lt.nulibtable_logItemp_min) stop "temp below nulib epannihil table minimum temp"
  if (xltemp.gt.nulibtable_logItemp_max) stop "temp above nulib epannihil table maximum temp"
  if (xleta.lt.nulibtable_logIeta_min) stop "eta below nulib epannihil table minimum eta"
  if (xleta.gt.nulibtable_logIeta_max) stop "eta above nulib epannihil table maximum eta"

  if (allocated(nulibtable_epannihiltable_Phi0).eqv..false.) stop "You need to read in ep-annihilation data"

  startindex = (lns-1)*nulibtable_number_groups*nulibtable_number_groups+1
  endindex = startindex + nulibtable_number_groups*nulibtable_number_groups - 1

  !note, no symmetries are used here, for inelastic electron
  !scattering these symmetries were crucial so that may be needed here
  !too, there is really only need for 1/4 of the coefficients, there
  !is a detailed balence symmetry and a in/out symmetry, for \nu
  !\nubar annihilation R(\nu,\nu^prime)_\mathrm{species} =
  !R(\nu^\prime,\nu)_\mathrm{antispecies}

  xeas = 0.0d0
  call intp2d_many_mod(xltemp,xleta,xeas,nulibtable_epannihiltable_Phi0(:,:,startindex:endindex), &
       nulibtable_nItemp,nulibtable_nIeta,eas_n1*eas_n2,nulibtable_logItemp,nulibtable_logIeta)

  index = 0
  do ing_this=1,nulibtable_number_groups
     do ing_that=1,nulibtable_number_groups
        index = index + 1
        eas(ing_this,ing_that,2) = 10.0d0**xeas(index) !annihilation

        !use this if you want to impose detailed balance between
        !production and annihilation after interpolation, could use to
        !cut down interpolation by half... - confirm the expression
        !also, this assumes nulibtable_energies are in MeV
        eas(ing_this,ing_that,1) = eas(ing_this,ing_that,2)* &
             exp(-(nulibtable_energies(ing_this)+nulibtable_energies(ing_that))/xtemp) !production

     enddo
  enddo

  xeas = 0.0d0
  call intp2d_many_mod(xltemp,xleta,xeas,nulibtable_epannihiltable_Phi1(:,:,startindex:endindex), &
       nulibtable_nItemp,nulibtable_nIeta,eas_n1*eas_n2,nulibtable_logItemp,nulibtable_logIeta)

  index = 0
  do ing_this=1,nulibtable_number_groups
     do ing_that=1,nulibtable_number_groups
        !this way because we interpolate \phi1/\phi0
        index = index + 1
        eas(ing_this,ing_that,4) = xeas(index)*eas(ing_this,ing_that,2)

        !use this if you want to impose detailed balance between
        !production and annihilation after interpolation, could use to
        !cut down interpolation by half... - confirm the expression
        !also, this assumes nulibtable_energies are in MeV
        eas(ing_this,ing_that,3) = eas(ing_this,ing_that,4)* &
             exp(-(nulibtable_energies(ing_this)+nulibtable_energies(ing_that))/xtemp) !production

     enddo
  enddo
  
end subroutine nulibtable_epannihil_single_species_range_energy


!!!! ROUTINES FOR COMPATIBILITY WITH GR1D !!!!

!this takes temp,eta, and return phi0/1 over energy (both in and out) and species range
subroutine nulibtable_inelastic_range_species_range_energy2(xtemp,xeta, &
     eas,eas_n1,eas_n2,eas_n3,eas_n4)

  use nulibtable
  implicit none

  real*8, intent(in) :: xtemp, xeta !inputs
  real*8 :: xltemp, xleta !log versions
  integer, intent(in) :: eas_n1,eas_n2,eas_n3,eas_n4
  real*8, intent(out) :: eas(eas_n1,eas_n2,eas_n3,eas_n4)
  integer :: ins,ing_in,ing_out
  real*8 :: xeas(eas_n1*eas_n2*(eas_n2+1)/2)
  integer :: index
  real*8 :: energy_conversion = 1.60217733d-6*5.59424238d-55


  if(size(eas,1).ne.nulibtable_number_species) then
     stop "nulibtable_inelastic_range_species_range_energy: supplied array dimensions (1) is not commensurate with table"
  endif
  if(size(eas,2).ne.nulibtable_number_groups) then
     stop "nulibtable_inelastic_range_species_range_energy: supplied array dimensions (2) is not commensurate with table"
  endif  
  if(size(eas,3).ne.nulibtable_number_groups) then
     stop "nulibtable_inelastic_range_species_range_energy: supplied array dimensions (3) is not commensurate with table"
  endif
  if(size(eas,4).ne.2) then
     stop "nulibtable_inelastic_range_species_range_energy: supplied array dimensions (4) is not commensurate with table"
  endif

  xltemp = log10(xtemp)
  xleta = log10(xeta)

  if (xltemp.lt.nulibtable_logItemp_min) stop "temp below nulib inelastic table minimum temp"
  if (xltemp.gt.nulibtable_logItemp_max) stop "temp above nulib inelastic table maximum temp"
  if (xleta.lt.nulibtable_logIeta_min) stop "eta below nulib inelastic table minimum eta"
  if (xleta.gt.nulibtable_logIeta_max) stop "eta above nulib inelastic table maximum eta"

  xeas = 0.0d0
  call intp2d_many_mod(xltemp,xleta,xeas,nulibtable_Itable_Phi0,nulibtable_nItemp, &
       nulibtable_nIeta,eas_n1*eas_n2*(eas_n2+1)/2,nulibtable_logItemp, &
       nulibtable_logIeta)

  index = 0
  do ins=1,nulibtable_number_species
     do ing_in=1,nulibtable_number_groups
        do ing_out=1,ing_in
           index = index + 1
           eas(ins,ing_in,ing_out,1) = 10.0d0**xeas(index)
        enddo
     enddo
     do ing_in=1,nulibtable_number_groups
        do ing_out=ing_in+1,nulibtable_number_groups
           eas(ins,ing_in,ing_out,1) =  &
                exp(-(nulibtable_energies(ing_out)-nulibtable_energies(ing_in))/ &
                (xtemp*energy_conversion))*eas(ins,ing_out,ing_in,1) !cernohorsky 94
        enddo
     enddo
  enddo

  xeas = 0.0d0
  call intp2d_many_mod(xltemp,xleta,xeas,nulibtable_Itable_Phi1,nulibtable_nItemp, &
       nulibtable_nIeta,eas_n1*eas_n2*(eas_n2+1)/2,nulibtable_logItemp, &
       nulibtable_logIeta)

  index = 0
  do ins=1,nulibtable_number_species
     do ing_in=1,nulibtable_number_groups
        do ing_out=1,ing_in
           index = index + 1
           !this way because we interpolate \phi1/\phi0
           eas(ins,ing_in,ing_out,2) = xeas(index)*eas(ins,ing_in,ing_out,1)
        enddo
     enddo
     do ing_in=1,nulibtable_number_groups
        do ing_out=ing_in+1,nulibtable_number_groups
           eas(ins,ing_in,ing_out,2) =  &
                exp(-(nulibtable_energies(ing_out)-nulibtable_energies(ing_in))/ &
                (xtemp*energy_conversion))*eas(ins,ing_out,ing_in,2) !cernohorsky 94
        enddo
     enddo
  enddo  

  
  
end subroutine nulibtable_inelastic_range_species_range_energy2

!this takes temp,eta, and return phi0/1 over energy (both in and out) range for a single species
subroutine nulibtable_inelastic_single_species_range_energy2(xtemp,xeta, &
     lns,eas,eas_n1,eas_n2,eas_n3)

  use nulibtable
  implicit none

  real*8, intent(in) :: xtemp, xeta !inputs
  real*8 :: xltemp, xleta !log versions
  integer, intent(in) :: lns,eas_n1,eas_n2,eas_n3
  real*8, intent(out) :: eas(eas_n1,eas_n2,eas_n3)
  integer :: ing_in,ing_out
  real*8 :: xeas(eas_n1*(eas_n1+1)/2)
  integer :: index
  real*8 :: energy_conversion = 1.60217733d-6*5.59424238d-55
  integer :: startindex,endindex

  if(size(eas,1).ne.nulibtable_number_groups) then
     stop "nulibtable_inelastic_single_species_range_energy: supplied array dimensions (1) is not commensurate with table"
  endif  
  if(size(eas,2).ne.nulibtable_number_groups) then
     stop "nulibtable_inelastic_single_species_range_energy: supplied array dimensions (2) is not commensurate with table"
  endif
  if(size(eas,3).ne.2) then
     stop "nulibtable_inelastic_single_species_range_energy: supplied array dimensions (3) is not commensurate with table"
  endif

  xltemp = log10(xtemp)
  xleta = log10(xeta)

  if (xltemp.lt.nulibtable_logItemp_min) stop "temp below nulib inelastic table minimum temp"
  if (xltemp.gt.nulibtable_logItemp_max) stop "temp above nulib inelastic table maximum temp"
  if (xleta.lt.nulibtable_logIeta_min) stop "eta below nulib inelastic table minimum eta"
  if (xleta.gt.nulibtable_logIeta_max) stop "eta above nulib inelastic table maximum eta"

  startindex = (lns-1)*nulibtable_number_groups*(nulibtable_number_groups+1)/2+1
  endindex = startindex + nulibtable_number_groups*(nulibtable_number_groups+1)/2 - 1

  xeas = 0.0d0
  call intp2d_many_mod(xltemp,xleta,xeas,nulibtable_Itable_Phi0(:,:,startindex:endindex), &
       nulibtable_nItemp,nulibtable_nIeta,eas_n1*(eas_n1+1)/2, &
       nulibtable_logItemp,nulibtable_logIeta)

  index = 0
  do ing_in=1,nulibtable_number_groups
     do ing_out=1,ing_in
        index = index + 1
        eas(ing_in,ing_out,1) = 10.0d0**xeas(index)
     enddo
  enddo
  do ing_in=1,nulibtable_number_groups
     do ing_out=ing_in+1,nulibtable_number_groups
        eas(ing_in,ing_out,1) =  &
             exp(-(nulibtable_energies(ing_out)-nulibtable_energies(ing_in))/ &
             (xtemp*energy_conversion))*eas(ing_out,ing_in,1) !cernohorsky 94
     enddo
  enddo

  xeas = 0.0d0
  call intp2d_many_mod(xltemp,xleta,xeas,nulibtable_Itable_Phi1(:,:,startindex:endindex), &
       nulibtable_nItemp,nulibtable_nIeta,eas_n1*(eas_n1+1)/2, &
       nulibtable_logItemp,nulibtable_logIeta)

  index = 0
  do ing_in=1,nulibtable_number_groups
     do ing_out=1,ing_in
        index = index + 1
        !this way because we interpolate \phi1/\phi0
        eas(ing_in,ing_out,2) = xeas(index)*eas(ing_in,ing_out,1)
     enddo
  enddo
  do ing_in=1,nulibtable_number_groups
     do ing_out=ing_in+1,nulibtable_number_groups
        eas(ing_in,ing_out,2) =  &
             exp(-(nulibtable_energies(ing_out)-nulibtable_energies(ing_in))/ &
             (xtemp*energy_conversion))*eas(ing_out,ing_in,2) !cernohorsky 94
     enddo
  enddo

  
  
end subroutine nulibtable_inelastic_single_species_range_energy2

!this takes temp,eta, and return phi0/1 for ep-annihilation over energy (both neutrinos) and species range
subroutine nulibtable_epannihil_range_species_range_energy2(xtemp,xeta, &
     eas,eas_n1,eas_n2,eas_n3,eas_n4)

  use nulibtable
  implicit none

  real*8, intent(in) :: xtemp, xeta !inputs
  real*8 :: xltemp, xleta !log versions
  integer, intent(in) :: eas_n1,eas_n2,eas_n3,eas_n4
  real*8, intent(out) :: eas(eas_n1,eas_n2,eas_n3,eas_n4)
  integer :: ins,ing_this,ing_that
  real*8 :: xeas(eas_n1*eas_n2*eas_n3*2)
  integer :: index
  real*8 :: energy_conversion = 1.60217733d-6*5.59424238d-55


  if(size(eas,1).ne.nulibtable_number_species) then
     stop "nulibtable_epannihil_range_species_range_energy: supplied array dimensions (1) is not commensurate with table"
  endif
  if(size(eas,2).ne.nulibtable_number_groups) then
     stop "nulibtable_epannihil_range_species_range_energy: supplied array dimensions (2) is not commensurate with table"
  endif  
  if(size(eas,3).ne.nulibtable_number_groups) then
     stop "nulibtable_enannihil_range_species_range_energy: supplied array dimensions (3) is not commensurate with table"
  endif
  if(size(eas,4).ne.4) then
     stop "nulibtable_epannihil_range_species_range_energy: supplied array dimensions (4) is not commensurate with table"
  endif

  xltemp = log10(xtemp)
  xleta = log10(xeta)

  if (xltemp.lt.nulibtable_logItemp_min) stop "temp below nulib epannihil table minimum temp"
  if (xltemp.gt.nulibtable_logItemp_max) stop "temp above nulib epannihil table maximum temp"
  if (xleta.lt.nulibtable_logIeta_min) stop "eta below nulib epannihil table minimum eta"
  if (xleta.gt.nulibtable_logIeta_max) stop "eta above nulib epannihil table maximum eta"

  xeas = 0.0d0
  call intp2d_many_mod(xltemp,xleta,xeas,nulibtable_epannihiltable_Phi0,nulibtable_nItemp, &
       nulibtable_nIeta,eas_n1*eas_n2*eas_n2*2,nulibtable_logItemp, &
       nulibtable_logIeta)

  index = 0
  do ins=1,nulibtable_number_species
     do ing_this=1,nulibtable_number_groups
        do ing_that=1,nulibtable_number_groups
           index = index + 1
           eas(ins,ing_this,ing_that,1) = 10.0d0**xeas(index)
           index = index + 1
           eas(ins,ing_this,ing_that,2) = 10.0d0**xeas(index)
!           eas(ins,ing_this,ing_that,1) = eas(ins,ing_this,ing_that,2)* &
!                exp(-(nulibtable_energies(ing_this)+nulibtable_energies(ing_that))/(xtemp*energy_conversion))

        enddo
     enddo
  enddo

  xeas = 0.0d0
  call intp2d_many_mod(xltemp,xleta,xeas,nulibtable_epannihiltable_Phi1,nulibtable_nItemp, &
       nulibtable_nIeta,eas_n1*eas_n2*eas_n2*2,nulibtable_logItemp, &
       nulibtable_logIeta)

  index = 0
  do ins=1,nulibtable_number_species
     do ing_this=1,nulibtable_number_groups
        do ing_that=1,nulibtable_number_groups
           !this way because we interpolate \phi1/\phi0
           index = index + 1
           eas(ins,ing_this,ing_that,3) = xeas(index)*eas(ins,ing_this,ing_that,1)
           index = index + 1
           eas(ins,ing_this,ing_that,4) = xeas(index)*eas(ins,ing_this,ing_that,2)
!           eas(ins,ing_this,ing_that,3) = eas(ins,ing_this,ing_that,4)* &
!                exp(-(nulibtable_energies(ing_this)+nulibtable_energies(ing_that))/(xtemp*energy_conversion))
        enddo
     enddo
  enddo  

  
  
end subroutine nulibtable_epannihil_range_species_range_energy2

!this takes temp,eta, and return epannihilation phi0/1 over energy (both nus) range for a single species
subroutine nulibtable_epannihil_single_species_range_energy2(xtemp,xeta, &
     lns,eas,eas_n1,eas_n2,eas_n3)

  use nulibtable
  implicit none

  real*8, intent(in) :: xtemp, xeta !inputs
  real*8 :: xltemp, xleta !log versions
  integer, intent(in) :: lns,eas_n1,eas_n2,eas_n3
  real*8, intent(out) :: eas(eas_n1,eas_n2,eas_n3)
  integer :: ing_this,ing_that
  real*8 :: xeas(eas_n1*eas_n2*2)
  integer :: index
  real*8 :: energy_conversion = 1.60217733d-6*5.59424238d-55
  integer :: startindex,endindex

  if(size(eas,1).ne.nulibtable_number_groups) then
     stop "nulibtable_epannihil_single_species_range_energy: supplied array dimensions (1) is not commensurate with table"
  endif  
  if(size(eas,2).ne.nulibtable_number_groups) then
     stop "nulibtable_epannihil_single_species_range_energy: supplied array dimensions (2) is not commensurate with table"
  endif
  if(size(eas,3).ne.4) then
     stop "nulibtable_epannihil_single_species_range_energy: supplied array dimensions (3) is not commensurate with table"
  endif

  xltemp = log10(xtemp)
  xleta = log10(xeta)

  if (xltemp.lt.nulibtable_logItemp_min) stop "temp below nulib epannihil table minimum temp"
  if (xltemp.gt.nulibtable_logItemp_max) stop "temp above nulib epannihil table maximum temp"
  if (xleta.lt.nulibtable_logIeta_min) stop "eta below nulib epannihil table minimum eta"
  if (xleta.gt.nulibtable_logIeta_max) stop "eta above nulib epannihil table maximum eta"

  startindex = (lns-1)*nulibtable_number_groups*nulibtable_number_groups*2+1
  endindex = startindex + nulibtable_number_groups*nulibtable_number_groups*2 - 1

  xeas = 0.0d0
  call intp2d_many_mod(xltemp,xleta,xeas,nulibtable_epannihiltable_Phi0(:,:,startindex:endindex), &
       nulibtable_nItemp,nulibtable_nIeta,eas_n1*eas_n2*2,nulibtable_logItemp,nulibtable_logIeta)

  index = 0
  do ing_this=1,nulibtable_number_groups
     do ing_that=1,nulibtable_number_groups
        index = index + 1
        eas(ing_this,ing_that,1) = 10.0d0**xeas(index)
        index = index + 1
        eas(ing_this,ing_that,2) = 10.0d0**xeas(index)
!        eas(ing_this,ing_that,1) = eas(ing_this,ing_that,2)* &
!             (exp(-(nulibtable_energies(ing_this)+nulibtable_energies(ing_that))/(xtemp*energy_conversion)))
     enddo
  enddo

  xeas = 0.0d0
  call intp2d_many_mod(xltemp,xleta,xeas,nulibtable_epannihiltable_Phi1(:,:,startindex:endindex), &
       nulibtable_nItemp,nulibtable_nIeta,eas_n1*eas_n2*2,nulibtable_logItemp,nulibtable_logIeta)

  index = 0
  do ing_this=1,nulibtable_number_groups
     do ing_that=1,nulibtable_number_groups
        index = index + 1
        !this way because we interpolate \phi1/\phi0
        eas(ing_this,ing_that,3) = xeas(index)*eas(ing_this,ing_that,1)
        index = index + 1
        eas(ing_this,ing_that,4) = xeas(index)*eas(ing_this,ing_that,2)
!        eas(ing_this,ing_that,3) = eas(ing_this,ing_that,4)*&
!             (exp(-(nulibtable_energies(ing_this)+nulibtable_energies(ing_that))/(xtemp*energy_conversion)))
     enddo
  enddo
  
end subroutine nulibtable_epannihil_single_species_range_energy2

