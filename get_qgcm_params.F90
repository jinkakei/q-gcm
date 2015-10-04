! create: 2015-09-30

program get_parameters 
      use parameters
      implicit none
      double precision dxo !, dyo
      double precision gpoc
      double precision hoc(nlo) ! set in main

      call k247_read_in_param( dxo, gpoc, hoc )
! this codes made by gen_get_qgpara.rb
!   match indent: select lines (Shift + V) -> type =
!#ifdef Now_Cut
      write(*,*) "nxto = ", nxto
      write(*,*) "nyto = ", nyto
      write(*,*) "nxpo = ", nxpo
      write(*,*) "nypo = ", nypo
      write(*,*) "nlo = ", nlo
      write(*,*) "dxo = ", dxo
      write(*,*) "gpoc = ", gpoc
!#endif ! #ifdef Now_Cut
      write(*,*) "hoc = ", hoc

end program get_parameters



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
!      integer ipunit
! 2015-10-03: modify for error "severe (32):Invalid logical unit number"
      integer,parameter:: ipunit=10
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
