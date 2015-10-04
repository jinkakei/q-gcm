!* make forcing file (netcdf) for q-gcm (ocean_only mode)
! 
! how to compile & postprocess
!     q-gcm*/src*: > ifort -warn all -o k247_make_forcing_q-gcm.exe k247_make_forcing_q-gcm.F90 -I/opt/cray/netcdf/4.2.0/intel/120/include -L/opt/cray/netcdf/4.2.0/intel/120/lib -lnetcdf -lnetcdff
!          コードを変更した場合は再コンパイル
!     q-gcm*/src*: > qsub cntl_q-gcm
!          実行、リンクの貼り替えなどの設定は qsub スクリプト側で行う。
!          qsub スクリプトを使わない場合は手動で設定すること
!!! OLD: 2015-03-08
	! how to compile & postprocess
	!     q-gcm*/src*: > ifort k247_make_forcing_q-gcm.F90 -I/opt/cray/netcdf/4.2.0/intel/120/include -L/opt/cray/netcdf/4.2.0/intel/120/lib -lnetcdf -lnetcdff
	!     q-gcm*/src*: > ./a.out
	!     q-gcm*/src*: > ln -s ./forcing.nc avges.nc
!
! history
!  2015-02-15: create based on qg-rg.F90 (nishinak/data/test_qg/qg-rg.F90)
!  2015-03-07: use module & set out file name
!  201-  -  : 
! ToDo
!	q-gcm のモジュールを使う(参考： tavout <- timavge.F)
!		ファイル名に情報を付加（グリッドサイズとか）
!	フォーシングに値を入れる
!	nxpo_arr,nypo_arr,nxto_arr,nyto_arr に値を入れる（q-gcm.F l780~ を見る限り不要）

! MAIN PART
program k247_make_forcing_qgcm
        !    program k247_make_forcing_q-gcm
        !Syntax error, found '-' when expecting one of: <END-OF-STATEMENT> ;


        use netcdf
        USE parameters

        implicit none
        ! default (../examples/double_gyre_ocean_only/avges.nc.dg_oo)
        
!        integer,parameter:: nxpo=961,nypo=961,nxto=960,nyto=960
! 2015-03-04: for changing regional size ( src_test24 )
!        integer,parameter:: nxpo=1921,nypo=1921,nxto=1920,nyto=1920
! 2015-03-05: for changing regional size ( src_test24 / log04)
!        integer,parameter:: nxto=1920,nyto=960
!        integer,parameter:: nxpo=nxto+1,nypo=nyto+1
        double precision nxto_arr(nxto),nyto_arr(nyto),nxpo_arr(nxpo),nypo_arr(nypo)
        double precision tauxo(nxpo,nypo),tauyo(nxpo, nypo),fnetoc(nxto,nyto)
!        character(len=256):: casename ="none"
        ! for netcdf
!        character(len=256):: out_ncfn ="forcing.nc"
! 2015-03-04: for changing regional size ( src_test24 )
!        character(len=256):: out_ncfn ="forcing_no_1920x1920.nc"
!        character(len=256):: out_ncfn ="forcing_no_1920x0960.nc"
        character(len=256):: out_ncfn
        integer ncstat, ncunit, varid
        integer dimnxto, dimnyto, dimto(2), dimnxpo, dimnypo, dimpo(2)
        character(len=256):: nc_char
        ! for clock: 2014-09-07
        integer bgn_count, end_count, count_rate, count_max


        ! set start time: 2014-09-07
        call system_clock(bgn_count, count_rate, count_max)
        
        write(*,*) 'start: k247_make_forcing_q-gcm.F90'
        write(*,*) 
        write(*,*) 
        
        call k247_set_fname_forcing( out_ncfn )
        write(*,*) '  out_ncfn: ', trim( adjustl( out_ncfn ) )

        ncstat=nf90_create(out_ncfn,NF90_CLOBBER,ncunit)
        call k247_ncerr_lap(ncstat, "nf90_create:")

        ! Start: Define attr, dim, var
        nc_char = 'made by k247_make_forcing_q-gcm.F90'
        ncstat=nf90_put_att(ncunit,NF90_GLOBAL,'history',nc_char)
        call k247_ncerr_lap( ncstat, '  nf90_put_at(global):')
		
	        ncstat=nf90_def_dim(ncunit,'xpo',nxpo,dimnxpo)
	        call k247_ncerr_lap( ncstat, '  nf90_def_dim(nxpo):')
	        dimpo(1)=dimnxpo
	        ncstat=nf90_def_dim(ncunit,'ypo',nypo,dimnypo)
	        call k247_ncerr_lap( ncstat, '  nf90_def_dim(nypo):')
	        dimpo(2)=dimnypo
	        ncstat=nf90_def_dim(ncunit,'xto',nxto,dimnxto)
	        call k247_ncerr_lap( ncstat, '  nf90_def_dim(nxto):')
	        dimto(1)=dimnxto
	        ncstat=nf90_def_dim(ncunit,'yto',nyto,dimnyto)
	        call k247_ncerr_lap( ncstat, '  nf90_def_dim(nyto):')
	        dimto(2)=dimnyto
        
	        ncstat=nf90_def_var(ncunit,'xpo',NF90_DOUBLE,dimnxpo,varid)
	        call k247_ncerr_lap( ncstat, '  nf90_def_var(nxpo):')
	        ncstat=nf90_def_var(ncunit,'ypo',NF90_DOUBLE,dimnypo,varid)
	        call k247_ncerr_lap( ncstat, '  nf90_def_var(nypo):')
	        ncstat=nf90_def_var(ncunit,'xto',NF90_DOUBLE,dimnxto,varid)
	        call k247_ncerr_lap( ncstat, '  nf90_def_var(nxto):')
	        ncstat=nf90_def_var(ncunit,'yto',NF90_DOUBLE,dimnyto,varid)
	        call k247_ncerr_lap( ncstat, '  nf90_def_var(nyto):')
        
	        ncstat=nf90_def_var(ncunit,'tauxo',NF90_DOUBLE,dimpo,varid)
	        call k247_ncerr_lap( ncstat, '  nf90_def_var(tauxo):')
	        ncstat=nf90_def_var(ncunit,'tauyo',NF90_DOUBLE,dimpo,varid)
	        call k247_ncerr_lap( ncstat, '  nf90_def_var(tauyo):')
	        ncstat=nf90_def_var(ncunit,'fnetoc',NF90_DOUBLE,dimto,varid)
	        call k247_ncerr_lap( ncstat, '  nf90_def_var(fnetoc):')
	        
	        ncstat=nf90_enddef(ncunit)
	        call k247_ncerr_lap( ncstat, '  nf90_enddef:')
	        
	        ncstat = nf90_inq_varid(ncunit,'xpo',varid)
	        call k247_ncerr_lap( ncstat, "  nf90_inq_varid(nxpo):")
	        ncstat = nf90_put_var( ncunit, varid, nxpo_arr, start=(/ 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(nxpo_arr):")
	        ncstat = nf90_inq_varid(ncunit,'ypo',varid)
	        call k247_ncerr_lap( ncstat, "  nf90_inq_varid(nypo):")
	        ncstat = nf90_put_var( ncunit, varid, nypo_arr, start=(/ 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(nypo_arr):")
	        ncstat = nf90_inq_varid(ncunit,'xto',varid)
	        call k247_ncerr_lap( ncstat, "  nf90_inq_varid(nxto):")
	        ncstat = nf90_put_var( ncunit, varid, nxto_arr, start=(/ 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(nxto_arr):")
	        ncstat = nf90_inq_varid(ncunit,'yto',varid)
	        call k247_ncerr_lap( ncstat, "  nf90_inq_varid(nyto):")
	        ncstat = nf90_put_var( ncunit, varid, nyto_arr, start=(/ 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(nyto_arr):")
	        
	        tauxo(:,:) = 0.0d0
	        ncstat = nf90_inq_varid(ncunit,'tauxo',varid)
	        call k247_ncerr_lap( ncstat, "  nf90_inq_varid(tauxo):")
	        ncstat = nf90_put_var( ncunit, varid, tauxo, start=(/ 1, 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(tauxo):")
	        tauyo(:,:) = 0.0d0
	        ncstat = nf90_inq_varid(ncunit,'tauyo',varid)
	        call k247_ncerr_lap( ncstat, "  nf90_inq_varid(tauyo):")
	        ncstat = nf90_put_var( ncunit, varid, tauyo, start=(/ 1, 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(tauyo):")
	        fnetoc(:,:) = 0.0d0
	        ncstat = nf90_inq_varid(ncunit,'fnetoc',varid)
	        call k247_ncerr_lap( ncstat, "  nf90_inq_varid(fnetoc):")
	        ncstat = nf90_put_var( ncunit, varid, fnetoc, start=(/ 1, 1 /))
            call k247_ncerr_lap( ncstat, "  nf90_put_var(fnetoc):")
	        
	        
	        
	        
        ncstat=nf90_close(ncunit)
        call k247_ncerr_lap(ncstat, "nf90_close:")
        
        ! diplay time: 2014-09-07
        call system_clock(end_count, count_rate, count_max)
        write(*,*) 
        write(*,*) 'elapsed time = ', &
                (end_count - bgn_count) / count_rate, '[sec]'
        write(*,*) 'End of Program'
        write(*,*) 

end program k247_make_forcing_qgcm
! END OF MAIN PART



SUBROUTINE k247_set_fname_forcing ( o_fn )

      USE parameters
      
      IMPLICIT NONE
      character(len=256):: o_fn
      
      character (len=80) :: c_nxto, c_nyto
      
      integer ipunit
      
      
      write( c_nxto ,*) nxto
      write( c_nyto ,*) nyto
      
!      write(*,*) 'restart_dxo'//trim(adjustl(c_dxo))// &
      o_fn = 'forcing_x'//trim(adjustl(c_nxto))// &
                  'y'//trim(adjustl(c_nyto))// &
                  '_no.nc'
      ! 2015-03-08: no 無強制
      
      open (ipunit, file='./forcing_fname.txt')
      write(ipunit,*) trim( adjustl( o_fn ) )
      close (ipunit)
      
END SUBROUTINE k247_set_fname_forcing


! SUBROUTINES by K247
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



        ! END OF FILE
