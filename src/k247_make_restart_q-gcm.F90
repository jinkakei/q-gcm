!* make restart file (netcdf) for q-gcm (ocean_only mode)
! 
! how to compile & postprocess
!     > ln -s ~/mod_ifort/bessel_k247.o    ! for modon @2015-08-13
!     > ln -s ~/mod_ifort/bessel_k247.mod  ! for modon @2015-08-13
!     q-gcm*/src*: > ifort -warn all -o k247_make_restart_q-gcm.exe k247_make_restart_q-gcm.F90 bessel_k247.o -I/opt/cray/netcdf/4.2.0/intel/120/include -L/opt/cray/netcdf/4.2.0/intel/120/lib -lnetcdf -lnetcdff
!           ! for modon @2015-08-13
!     q-gcm*/src*: > ifort -warn all -o k247_make_restart_q-gcm.exe k247_make_restart_q-gcm.F90 -I/opt/cray/netcdf/4.2.0/intel/120/include -L/opt/cray/netcdf/4.2.0/intel/120/lib -lnetcdf -lnetcdff
!          コードを変更した場合は再コンパイル 
!                渦の設定周り（ p2_percent など）の変更はありうるか？
!     q-gcm*/src*: > qsub cntl_q-gcm
!          実行、リンクの貼り替えなどの設定は qsub スクリプト側で行う。
!          qsub スクリプトを使わない場合は手動で設定すること
!!! OLD: 2015-03-08
    ! how to compile & postprocess
    !     q-gcm*/src*: > ifort k247_make_restart_q-gcm.F90 -I/opt/cray/netcdf/4.2.0/intel/120/include -L/opt/cray/netcdf/4.2.0/intel/120/lib -lnetcdf -lnetcdff
    !     q-gcm*/src*: > ./a.out
    !     q-gcm*/src*: > ln -s ./????.nc restart.nc
!
! history
!  2015-02-23: create based on K247_make_restart_q-gcm.F90 ( q-gcm1.5/src_latest/k247_make_forcing_q-gcm.F90 -- 2015-02-16 11:38)
!  2015-03-07: モジュールを使用、ファイル名を変更
!        【未】変なエラーが出る：forrtl: severe (32): invalid logical unit number
!  2015-0-: 
!  201-  -  : 
! ToDo
!    大気側のデータ
!    【残件】q-gcm のモジュールを使う(参考： tavout <- timavge.F)
!    nxpo_arr,nypo_arr,nxto_arr,nyto_arr に値を入れる（q-gcm.F l780~ を見る限り不要）
!    k247_ncerr_lap
! Done
!    ファイル名に情報を付加（グリッドサイズとか）



! MAIN PART
program k247_make_restart_qgcm
        !    program k247_make_forcing_q-gcm
        !Syntax error, found '-' when expecting one of: <END-OF-STATEMENT> ;


        use netcdf
        USE parameters
        use bessel_k247 ! for modon @2015-08-13
        
        implicit none
        ! default (../examples/double_gyre_ocean_only/avges.nc.dg_oo)
        integer,parameter:: time=1
        double precision time_arr
        double precision nxto_arr(nxto),nyto_arr(nyto)
        double precision nxpo_arr(nxpo),nypo_arr(nypo),zo_arr(nlo)
        double precision sst(nxto,nyto), sstm(nxto,nyto)
        double precision po(nxpo,nypo,nlo),pom(nxpo, nypo,nlo)
        
        double precision nxta_arr(nxta),nyta_arr(nyta)
        double precision nxpa_arr(nxta),nypa_arr(nyta),za_arr(nla)
        double precision ast(nxta,nyta), astm(nxta,nyta)
        double precision hmixa(nxta,nyta), hmixam(nxta,nyta)
!        character(len=256):: casename ="none"
        ! for netcdf
!        character(len=256):: out_ncfn ="restart_eddy_oo.nc"
        character(len=256):: out_ncfn
!        integer out_ncfu
        integer ncstat, ncunit, varid
        integer dimtime
        integer dimnxto, dimnyto, dimto2d(2)
        integer dimnxpo, dimnypo, dimzo, dimpo3d(3)
        integer dimnxta, dimnyta, dimta2d(2)
        integer dimnxpa, dimnypa, dimza
        character(len=256):: nc_char
        ! for clock: 2014-09-07
        integer bgn_count, end_count, count_rate, count_max
! parameters from q-gcm for initialize
!        double precision,parameter:: dxo=5.0d3, dyo=5.0d3
! Settings of Early et al. 2011 JPO
!        double precision,parameter:: gpoc=0.01d0
  ! 2015-03-06: for using module parameters
        double precision dxo, dyo
        double precision gpoc
        double precision hoc(nlo) ! set in main
!   for initialize
        integer i,j
     ! initial postion of eddy center
!        integer,parameter:: i_e=480, j_e=480
        integer,parameter:: i_e=nxto/2, j_e=nyto/2
     ! range of signal
! for dxo=5.0D3
!        integer,parameter:: ini_ilen=40, ini_jlen=40
! for dxo=2.0D3
!        integer,parameter:: ini_ilen=100, ini_jlen=100
!  2015-04-10: src_test26 02b
!        integer,parameter:: ini_ilen=200, ini_jlen=200
!        integer,parameter:: ini_ilen=400, ini_jlen=400
!        integer,parameter:: ini_ilen=800, ini_jlen=800
        integer,parameter:: ini_ilen=nxto/2 - 1, ini_jlen=nyto/2 - 1
        double precision,parameter:: l_efold = 8.0d1 * 1.0d3
!!        double precision,parameter:: h_amp = 1.0d2 ! ssh = 10 cm (gpoc = 0.01)
!!        double precision,parameter:: h_amp = 1.5d2 ! ssh = 15 cm (gpoc = 0.01)
        ! 2015-02-24: ssh vs h0 in 2 or 1.5 layer 
        !    ssh = ( g' / g) * h0 ! h0: interface
!!        double precision h_interface(nxpo, nypo)
!*        double precision ssh_dist(nxpo, nypo) ! nomodon

        double precision,parameter:: grav=9.8
!        double precision,parameter:: ssh_amp=0.1D0 ! [m]
        double precision,parameter:: ssh_amp=0.15D0 ! [m]
!        double precision,parameter:: ssh_amp=0.3D0 ! [m]
!        double precision,parameter:: ssh_amp=-0.15D0 ! [m]
        double precision,parameter:: po2_percent=0.0D0
!        double precision,parameter:: po2_percent=-20.0D0

! for eddy pair @2015-07-31
!*        integer j_dist ! calculat from cnt_dist
        !double precision,parameter:: cnt_dist = 0.0d0 ! rate of l_efold
!*        double precision,parameter:: cnt_dist = 0.5d0 ! rate of l_efold ! nomodon
        !double precision,parameter:: cnt_dist = 0.75d0 ! rate of l_efold
        !double precision,parameter:: cnt_dist = 1.0d0 ! rate of l_efold
!*        double precision,parameter:: pair_amp = 0.0d0 ! rate of ssh_amp ! nomodon
!*        double precision,parameter:: pair_amp = -1.0d0 ! rate of ssh_amp !nomodon

!#ifdef NO_MODON
! for modon @2015-08-13
        double precision r_now, Rdef
    ! k = k1 from Table III in Flierl et al. 1980
!    double precision,parameter:: a=1.0d0, c=1.0d0, k=3.9974d0 ! q = 1.414 -> 1.5
!    double precision,parameter:: a=1.0d0, c=1.0d0/3.0d0, k=4.0732 ! q = 2.0
        ! 3.9974 + (4.0732-3.9947) * (0.23205/0.5)
!    double precision,parameter:: a=1.0d0, c=0.5d0, k=4.0326 ! q = 1.732o5
!    double precision,parameter:: a=5.0d0, c=1.d0/3.d0, k=4.6985 ! q = 10
    double precision,parameter:: a=4.0d0, q=10.0d0, k=4.6985d0
!    double precision,parameter:: a=4.0d0, q=1.0d0, k=3.9226d0
    double precision,parameter:: c = 1.0d0 / ( (q/a)**2.0d0 - 1.0d0 )
! stationary solution
!    double precision,parameter:: a=1.0d0, c=0.d0, k=5.1356 ! q = infinite
!    double precision,parameter:: a=4.0d0, c=0.d0, k=5.1356 ! test for high-resolution @2015-08-14
!    double precision,parameter:: a=6.0d0, c=0.d0, k=5.1356 ! test for high-resolution @2015-08-14
!    double precision,parameter:: a=6.0d0, c=0.d0, k=5.1356 ! test for high-resolution @2015-08-14
!    double precision,parameter:: a=10.0d0, c=0.d0, k=5.1356 ! bad ( too strong eddy -- 100 cm )
    double precision b1, r1, d1
!#endif ! ifdef NO_MODON

        ! set start time: 2014-09-07
        call system_clock(bgn_count, count_rate, count_max)

        write(*,*) 'start: k247_make_restart_q-gcm.F90'
        write(*,*) 
        write(*,*) 
        
! 2015-03-06: read input params (test case: k247_test_use_module.F90)
        call k247_read_in_param( dxo, gpoc, hoc )
        dyo = dxo
        
        call k247_set_fname_restart( out_ncfn, dxo, ssh_amp, l_efold, po2_percent)
        write(*,*) '  out_ncfilename: ', trim(adjustl(out_ncfn))
        write(*,*)
        write(*,*)

    ! set for initialize
        zo_arr(1) = 0.5d0 * hoc(1)
        zo_arr(2) = hoc(1) + 0.5d0 * hoc(2)
        do i = 1,nxpo
            nxpo_arr(i) = dxo * dble(i-1) * 1.0d-3
        enddo
        do j = 1,nypo
            nypo_arr(j) = dyo * dble(j-1) * 1.0d-3
        enddo
    ! 2015-02-23: based on set_ini in qg_rg.F90
        write(*,*) '  Initialize'

!#ifdef NO_MODON
!* 2015-08-13: for modon test ( cf. k247_make_modon_qgcm.F90 )
        write(*,*) "    Modon Solution"
        write(*,*) "      a = ", a
        write(*,*) "      c = ", c
        write(*,*) "      k = ", k
!        write(*,*) "Rdef = ", sqrt( gpoc * hoc(1) * hoc(2) &
!                       * fnot**-2.d0 / (hoc(1)+hoc(2)))
!        Rdef = sqrt( gpoc * hoc(1) * hoc(2) &
!                       * fnot**-2.d0 / (hoc(1)+hoc(2)))
!        write(*,*) "Rdef = ", Rdef
        Rdef = 4.7777485D+04 ! above calculation is unstable
        write(*,*) "      Rdef = ", Rdef
        write(*,*) "        !CAUTION! Rdef is not calculated!"
      !* set b1, r1, d1
        b1 = (1.0d0 + c)*a**3.0d0 / (k**2.0d0 * bessj1(k))
        r1 = (1.0d0 + c * ( (k/a)**2.0d0 + 1.0d0 )) / (k/a)**2.0d0
        d1 = - c * a / bessk1( a * sqrt(1.0d0 + 1.0d0 / c) )
!        do j = -ini_jlen, ini_jlen
!        do i = -ini_ilen, ini_ilen
! 2015-08-15: for 28_21preb : i_e = nxto/2, ini_ilen = nxto/2 - 1
        !write(*,*) "nxto = ",nxto,", nxpo = ", nxpo
        !write(*,*) "ini_ilen = ",ini_ilen, ", i_e = ",i_e
        do j = -ini_jlen, ini_jlen+2
        do i = -ini_ilen, ini_ilen+2
          r_now =  sqrt( ( dxo * dble(i) )**2.0 &
                       + ( dyo * dble(j) )**2.0 ) / Rdef
          if ( r_now < a ) then
          !* interior solution
              po(i+i_e,j+j_e, 1) &
                  = beta * Rdef**3.0d0 * fnot &
                      * ( b1 * bessj1( (k/a)*r_now ) - r1 * r_now ) &
                      * sin( atan2( dyo * dble(j), dxo * dble(i) )  )
          else
          !* exterior solution ( 0  if c = 0)
            if ( c /= 0.d0) then 
              po(i+i_e,j+j_e, 1) &
                  = beta * Rdef**3.0d0 * fnot &
                     * d1 * bessk1( sqrt(1.0d0+1.0d0/c) * r_now) &
                     * sin( atan2( dyo * dble(j), dxo * dble(i) )  )
            endif
          endif
        enddo ! do i = -ini_ilen, ini_ilen
        enddo ! do j = -ini_jlen, ini_jlen
     ! temporary! 29_26b @2015-08-23
     !   po(:,j_e,:) = 0.0d0 
     !    -> initial zero line is corrected, 
     !        but pmap seems to be same as 29_26a.
!#endif !#ifdef NO_MODON


#ifdef NOW_CUT ! 2015-08-13 for modon test
    ! 2017-07-31: for eddy pair
                j_dist = int( ( cnt_dist * l_efold ) / dyo )
        write(*,*) '    set eddy pair'
        write(*,*) '      ssh_amp:',ssh_amp,'[m]'
        write(*,*) '      pair_amp:',pair_amp,'[]'
        write(*,*) '      distance of center:', &
                    l_efold*cnt_dist,'[m]'
      ! initialize interface
!        h_interface(:,:) = 0.0
        ssh_dist(:,:) = 0.0D0
        do j = -ini_jlen, ini_jlen
        do i = -ini_ilen, ini_ilen
!            h_interface(i+i_e, j+j_e) = h_amp &
        !    ssh_dist(i+i_e, j+j_e) = ssh_amp &
        !        * exp( -1.0 * ( ( dxo * dble(i) )**2.0 &
        !                      + ( dyo * dble(j) )**2.0 ) &
        !                / l_efold**2.0 )
        ! 2015-07-31: for eddy pair
            ssh_dist(i+i_e, j+j_e+j_dist) = ssh_amp &
                * exp( -1.0 * ( ( dxo * dble(i) )**2.0 &
                              + ( dyo * dble(j) )**2.0 ) &
                        / l_efold**2.0 )
            ssh_dist(i+i_e, j+j_e-j_dist) = &
                ssh_dist(i+i_e, j+j_e-j_dist) &
                + pair_amp * ssh_amp &
                * exp( -1.0 * ( ( dxo * dble(i) )**2.0 &
                              + ( dyo * dble(j) )**2.0 ) &
                        / l_efold**2.0 )
        enddo ! do i = -ini_ilen, ini_ilen
        enddo ! do j = -ini_jlen, ini_jlen
!        write(*,*) '    h max: ', maxval( h_interface )
        write(*,*) '    ssh max: ', maxval( ssh_dist ), '[m]'
        write(*,*) '    ssh min: ', minval( ssh_dist ), '[m]'
      ! initialize po, pom
      ! no flow in 2nd layer -- eq. (2.23) (manual for 1.5.0)
    !    po(:,:,1) = - gpoc * h_interface(:,:)
        po(:,:,1) = grav * ssh_dist(:,:)
#endif ! 2015-08-13 for modon test
        po(:,:,2) = ( po2_percent / 100.0D0 ) * po(:,:,1)
        pom(:,:,:) = po(:,:,:)

    ! output NetCDF file
        ncstat=nf90_create(out_ncfn,NF90_CLOBBER,ncunit)
        call k247_ncerr_lap(ncstat, "nf90_create:")

        ! Start: Define attr, dim, var
        nc_char = 'made by k247_make_restart_q-gcm.F90'
        ncstat=nf90_put_att(ncunit,NF90_GLOBAL,'history',nc_char)
        call k247_ncerr_lap( ncstat, '  nf90_put_at(global):')
        
            ncstat=nf90_def_dim(ncunit,'time',time,dimtime)
            call k247_ncerr_lap( ncstat, '  nf90_def_dim(time):')
            ncstat=nf90_def_dim(ncunit,'xpo',nxpo,dimnxpo)
            call k247_ncerr_lap( ncstat, '  nf90_def_dim(nxpo):')
            dimpo3d(1)=dimnxpo
            ncstat=nf90_def_dim(ncunit,'ypo',nypo,dimnypo)
            call k247_ncerr_lap( ncstat, '  nf90_def_dim(nypo):')
            dimpo3d(2)=dimnypo
            ncstat=nf90_def_dim(ncunit,'zo',nlo,dimzo)
            call k247_ncerr_lap( ncstat, '  nf90_def_dim(zo):')
            dimpo3d(3)=dimzo
            ncstat=nf90_def_dim(ncunit,'xto',nxto,dimnxto)
            call k247_ncerr_lap( ncstat, '  nf90_def_dim(nxto):')
            dimto2d(1)=dimnxto
            ncstat=nf90_def_dim(ncunit,'yto',nyto,dimnyto)
            call k247_ncerr_lap( ncstat, '  nf90_def_dim(nyto):')
            dimto2d(2)=dimnyto
            
            ncstat=nf90_def_dim(ncunit,'xta',nxta,dimnxta)
            call k247_ncerr_lap( ncstat, '  nf90_def_dim(nxta):')
            dimta2d(1)=dimnxta
            ncstat=nf90_def_dim(ncunit,'yta',nyta,dimnyta)
            call k247_ncerr_lap( ncstat, '  nf90_def_dim(nyta):')
            dimta2d(2)=dimnyta
            ncstat=nf90_def_dim(ncunit,'xpa',nxpa,dimnxpa)
            call k247_ncerr_lap( ncstat, '  nf90_def_dim(nxpa):')
            ncstat=nf90_def_dim(ncunit,'ypa',nypa,dimnypa)
            call k247_ncerr_lap( ncstat, '  nf90_def_dim(nypa):')
            ncstat=nf90_def_dim(ncunit,'za',nla,dimza)
            call k247_ncerr_lap( ncstat, '  nf90_def_dim(nla):')
        
            ncstat=nf90_def_var(ncunit,'time',NF90_DOUBLE,dimtime,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(time):')
            ncstat=nf90_def_var(ncunit,'xpo',NF90_DOUBLE,dimnxpo,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(nxpo):')
            ncstat=nf90_def_var(ncunit,'ypo',NF90_DOUBLE,dimnypo,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(nypo):')
            ncstat=nf90_def_var(ncunit,'zo',NF90_DOUBLE,dimzo,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(nypo):')
            ncstat=nf90_def_var(ncunit,'xto',NF90_DOUBLE,dimnxto,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(nxto):')
            ncstat=nf90_def_var(ncunit,'yto',NF90_DOUBLE,dimnyto,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(nyto):')
            ncstat=nf90_def_var(ncunit,'xta',NF90_DOUBLE,dimnxta,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(nxta):')
            ncstat=nf90_def_var(ncunit,'yta',NF90_DOUBLE,dimnyta,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(nyta):')
            ncstat=nf90_def_var(ncunit,'xpa',NF90_DOUBLE,dimnxpa,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(nxpa):')
            ncstat=nf90_def_var(ncunit,'ypa',NF90_DOUBLE,dimnypa,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(nypa):')
            ncstat=nf90_def_var(ncunit,'za',NF90_DOUBLE,dimza,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(za):')
        
            ncstat=nf90_def_var(ncunit,'po',NF90_DOUBLE,dimpo3d,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(po):')
            ncstat=nf90_def_var(ncunit,'pom',NF90_DOUBLE,dimpo3d,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(pom):')
            ncstat=nf90_def_var(ncunit,'sst',NF90_DOUBLE,dimto2d,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(sst):')
            ncstat=nf90_def_var(ncunit,'sstm',NF90_DOUBLE,dimto2d,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(sstm):')

            ncstat=nf90_def_var(ncunit,'ast',NF90_DOUBLE,dimta2d,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(ast):')
            ncstat=nf90_def_var(ncunit,'astm',NF90_DOUBLE,dimta2d,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(astm):')
            ncstat=nf90_def_var(ncunit,'hmixa',NF90_DOUBLE,dimta2d,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(hmixa):')
            ncstat=nf90_def_var(ncunit,'hmixam',NF90_DOUBLE,dimta2d,varid)
            call k247_ncerr_lap( ncstat, '  nf90_def_var(hmixam):')
            
            ncstat=nf90_enddef(ncunit)
            call k247_ncerr_lap( ncstat, '  nf90_enddef:')
            
            ncstat = nf90_inq_varid(ncunit,'time',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(time):")
            ncstat = nf90_put_var( ncunit, varid, time_arr, start=(/ 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(time_arr):")
            ncstat = nf90_inq_varid(ncunit,'xpo',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(nxpo):")
            ncstat = nf90_put_var( ncunit, varid, nxpo_arr, start=(/ 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(nxpo_arr):")
            ncstat = nf90_inq_varid(ncunit,'ypo',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(nypo):")
            ncstat = nf90_put_var( ncunit, varid, nypo_arr, start=(/ 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(nypo_arr):")
            ncstat = nf90_inq_varid(ncunit,'zo',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(zo):")
            ncstat = nf90_put_var( ncunit, varid, zo_arr, start=(/ 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(zo_arr):")
            ncstat = nf90_inq_varid(ncunit,'xto',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(nxto):")
            ncstat = nf90_put_var( ncunit, varid, nxto_arr, start=(/ 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(nxto_arr):")
            ncstat = nf90_inq_varid(ncunit,'yto',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(nyto):")
            ncstat = nf90_put_var( ncunit, varid, nyto_arr, start=(/ 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(nyto_arr):")
            
            !po(:,:,:) = 0.0d0
            ncstat = nf90_inq_varid(ncunit,'po',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(po):")
            ncstat = nf90_put_var( ncunit, varid, po, start=(/ 1, 1, 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(po):")
            !pom(:,:,:) = 0.0d0
            ncstat = nf90_inq_varid(ncunit,'pom',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(pom):")
            ncstat = nf90_put_var( ncunit, varid, pom, start=(/ 1, 1, 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(pom):")
            sst(:,:) = 0.0d0
            ncstat = nf90_inq_varid(ncunit,'sst',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(sst):")
            ncstat = nf90_put_var( ncunit, varid, sst, start=(/ 1, 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(sst):")
            sstm(:,:) = 0.0d0
            ncstat = nf90_inq_varid(ncunit,'sstm',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(sstm):")
            ncstat = nf90_put_var( ncunit, varid, sstm, start=(/ 1, 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(sstm):")
            
            
            
            
            ncstat = nf90_inq_varid(ncunit,'xta',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(xta):")
            ncstat = nf90_put_var( ncunit, varid, nxta_arr, start=(/ 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(nxta_arr):")
            ncstat = nf90_inq_varid(ncunit,'yta',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(yta):")
            ncstat = nf90_put_var( ncunit, varid, nyta_arr, start=(/ 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(nyta_arr):")
            ncstat = nf90_inq_varid(ncunit,'xpa',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(xpa):")
            ncstat = nf90_put_var( ncunit, varid, nxpa_arr, start=(/ 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(nxpa_arr):")
            ncstat = nf90_inq_varid(ncunit,'ypa',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(ypa):")
            ncstat = nf90_put_var( ncunit, varid, nypa_arr, start=(/ 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(nypa_arr):")
            ncstat = nf90_inq_varid(ncunit,'za',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(za):")
            ncstat = nf90_put_var( ncunit, varid, za_arr, start=(/ 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(za_arr):")
            
            ast(:,:) = 0.0d0
            ncstat = nf90_inq_varid(ncunit,'ast',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(ast):")
            ncstat = nf90_put_var( ncunit, varid, ast, start=(/ 1, 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(ast):")
            astm(:,:) = 0.0d0
            ncstat = nf90_inq_varid(ncunit,'astm',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(astm):")
            ncstat = nf90_put_var( ncunit, varid, astm, start=(/ 1, 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(astm):")
            hmixa(:,:) = 1.0d3
            ncstat = nf90_inq_varid(ncunit,'hmixa',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(hmixa):")
            ncstat = nf90_put_var( ncunit, varid, hmixa, start=(/ 1, 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(hmixa):")
            hmixam(:,:) = 1.0d3
            ncstat = nf90_inq_varid(ncunit,'hmixam',varid)
            call k247_ncerr_lap( ncstat, "  nf90_inq_varid(hmixam):")
            ncstat = nf90_put_var( ncunit, varid, hmixam, start=(/ 1, 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(hmixam):")
            
            
        ncstat=nf90_close(ncunit)
        call k247_ncerr_lap(ncstat, "nf90_close:")
        
        
!        write(*,*) 'CHECK CODE'
        
        ! diplay time: 2014-09-07
        write(*,*) 
        call system_clock(end_count, count_rate, count_max)
        write(*,*) 'elapsed time = ', &
                (end_count - bgn_count) / count_rate, '[sec]'
        write(*,*) 'End of Program'
        write(*,*) 

end program k247_make_restart_qgcm
! END OF MAIN PART



SUBROUTINE k247_set_fname_restart ( o_fn, dxo, ssha, l_ef, p2p)

      USE parameters
      
      IMPLICIT NONE
      character(len=256):: o_fn
      double precision dxo, ssha, l_ef, p2p
      
      integer i_dxo
      character (len=80) :: c_dxo, c_nxto, c_nyto, c_nlo
      integer i_ssh_amp
      character (len=80) :: c_ssh_amp
      integer i_le
      character (len=80) :: c_le
      integer i_p2p
      character (len=80) :: c_p2p
      
      integer ipunit
      
      
      i_dxo = dxo * 1.0D-3
!      write(*,*) '  i_dxo  = ', i_dxo, 'km'
      write( c_dxo ,*) i_dxo
      write( c_nxto ,*) nxto
      write( c_nyto ,*) nyto
      write( c_nlo ,*) nlo
      i_ssh_amp = ssha * 1.0D2
      write( c_ssh_amp ,*) i_ssh_amp
      i_le = l_ef * 1.0D-3
      write( c_le ,*) i_le
      i_p2p = p2p
      write( c_p2p ,*) i_p2p
      
!      write(*,*) 'restart_dxo'//trim(adjustl(c_dxo))// &
      o_fn = 'restart_dxo'//trim(adjustl(c_dxo))// &
                  'km_x'//trim(adjustl(c_nxto))// &
                  'y'//trim(adjustl(c_nyto))// &
                  'z'//trim(adjustl(c_nlo))// &
                  '_modon.nc'
!                  '_EddyA'//trim(adjustl(c_ssh_amp))// &
!                  'Le'//trim(adjustl(c_le))// &
!                  'PII'//trim(adjustl(c_p2p))//'.nc'
! temp for modon @2015-08-13
      
      open (ipunit, file='./restart_fname.txt')
      write(ipunit,*) trim( adjustl( o_fn ) )
      close (ipunit)
      
END SUBROUTINE k247_set_fname_restart


! SUBROUTINES by K247
! 【未】2015-02-23： -warn all でコンパイル
!        引数 ncexp に与えた文字列が len=256 でないとエラーになる。
!        -warn all を使いたいこともあるんだが、どうしたもんかね
! 2014-08-17
subroutine k247_ncerr_lap( ncstat, ncexp )

        use netcdf
        implicit none

        ! argument
        integer ncstat
!        character(len=256):: ncexp
        character (len = *), intent( in) :: ncexp
        ! inner
        integer clen


        if (ncstat.ne.0)  then
                clen = scan( ncexp, ':')

                write(*,*)
                write(*,*)

                write(*,'(2A)')  &
                        ncexp(1:clen), " ", nf90_strerror(ncstat)

                write(*,*)
                write(*,*)
        endif

        return
end ! subroutine k247_ncerr_lap( ncstat, ncexp )



! from q-gcm.F for using parameters
SUBROUTINE k247_ipbget (buffer, iounit)

      IMPLICIT NONE
      
      character (len=80) :: buffer
      integer, INTENT(IN) :: iounit


  100 continue
      read (iounit, err=200, fmt='(a80)') buffer
      ! for check K247
      !    write(*,*) '    k247_ipbget:', buffer(1:40)
      if ( buffer(1:1).eq.'!' ) goto 100
      return

  200 continue
      print *,' Error reading character buffer from iounit = ',iounit
      print *,' Program terminates in k247_ipbget'
      stop

END SUBROUTINE k247_ipbget


! from in_param.F for using parameters
SUBROUTINE k247_read_in_param ( dxo, gpoc, hoc )

      USE parameters
      IMPLICIT NONE

      character (len=80) :: inpbuf
      integer ipunit
      double precision dxo
      double precision gpoc
      double precision hoc(nlo)

      !    write(*,*) '  k247_read_in_param: open'
      open (ipunit, file='./input.params')
      !    write(*,*) '  k247_read_in_param: open OK'
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) trun
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) dta
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) nstr
      call k247_ipbget (inpbuf, ipunit)
      read (inpbuf,*) dxo
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) delek
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) cdat
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) rhoat
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) rhooc
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) cpat
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) cpoc
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) bccoat
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) bccooc
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) xcexp
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) ycexp
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) valday
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) odiday
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) adiday
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) dgnday
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) prtday
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) resday
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) nsko
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) nska
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) dtavat
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) dtavoc
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) dtcovat
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) dtcovoc
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) xlamda
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) hmoc
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) st2d
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) st4d
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) hmat
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) hmamin
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) ahmd
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) at2d
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) at4d
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) hmadmp
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) fsbar
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) fspamp
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) zm
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) zopt
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) gamma
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) ah2oc
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) ah4oc
      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) tabsoc
      call k247_ipbget (inpbuf, ipunit)
      read (inpbuf,*) hoc
      call k247_ipbget (inpbuf, ipunit)
      read (inpbuf,*) gpoc
!      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) ah4at
!      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) tabsat
!      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) hat
!      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) gpat
!      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,'(A)') name
!      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,'(A)') topocname
!      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,'(A)') topatname
!      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) outfloc
!      call k247_ipbget (inpbuf, ipunit)
!      read (inpbuf,*) outflat
      close(ipunit)

END SUBROUTINE k247_read_in_param


        ! END OF FILE
