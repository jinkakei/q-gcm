#!/usr/bin/ruby
# -*- coding: utf-8 -*-

# load libraries
require_relative "lib_qgcm_k247"
include K247_qgcm_common

# ToDo
#   - update for separation of prepare class ( qgcm_prep_k247.rb )



class K247_qgcm_data

  attr_reader :nc_fn, :p, :q
  # set by init_coord (for convenience)
  #   ex. @xpcor = @p.coord("xp"); @xp = @xpcor.val; @nxp = @xp.length
  attr_reader :xp, :nxp, :xpcor, :yp, :nyp, :ypcor, :z, :nz, :zcor, \
              :zi, :nzi, :zicor, :t, :nt, :tcor, :tm, :ntm, :tmcor
  # from monit.nc
  attr_reader :ddtkeoc, :ddtpeoc, :emfroc, :et2moc, :etamoc, \
              :kealoc, :pkenoc, \
              :keocavg, :peocavg, :teocavg
  # parameters ( from input_parameters.m )
  #   I cannot avoid using variable names directly. @2015-09-01
  attr_reader :fnot, :beta, :dxo, :dto, :rhooc, :cpoc, \
              :l_spl, :c1_spl
  attr_reader :gpoc, :cphsoc, :rdefoc, :ah2oc, :ah4oc, :tabsoc, :hoc
  attr_reader :grav, :m_to_cm
  # from init_etc
  attr_reader :gcname, :cname, :dname
  # init_etc_additional_params
  attr_reader :rdxof0, :rdxof0_val, :rgpoc, :rgpoc_val
  # sshmax_set_with_ij
  attr_reader :hmax, :hmax_i, :hmax_j


# 2015-08 or 09: create
# 2015-09-10: modify argument ( nc_fn -> input: fname or casename)
## Todo
#   - consider filenames and directory structures
#   - consider necessary components of initialize
#
# arguments: argv -- casename or filename ( return of self.prep_unify_outdata )
# return   : none
# action   : set instance variables
def initialize( argv )
  if argv == "__testmode__"
    puts "test mode: initialize process is skipped"
    @testmode_flag = true
  else
    exit_with_msg( "input casename") if argv == nil
    @nc_fn = init_fname( argv )
    init_set_var
    init_params
    init_monit
    init_etc
  end
end # initialize

  def is_testmode?
    if @testmode_flag
      return true
    else
      return false
    end
  end




# methods index
## - instance methods for ssh decay
## - instance methods for check 
## - instance methods for initialzie
## - class methods for preparation ( unify outdata_*/* )



## - instance methods for ssh decay
##  - ( sshdec )
##    -- sshdec_tmp
##    -- sshdec_get
##  - ( sshmax )
##    -- sshmax_get_with_ij
##    -- sshmax_etc_ncout
##  - ( ugeos )
##    -- uvgeooc_calc_wrap( ij_range, k, t )
##    -- uvgeooc2d_calc( po2d )
##  - ke2d_calc( ij_range, k, t )
##    -- a 
##    -- a 
##    -- a 
##  - 
##  - 
##  - 
##  - 

# nary: NArray.sfloat( @nt )
def calc_grad_t( nary ) 
  grad = NArray.sfloat( @nt )
  for tn in 1..@nt-2
    grad[tn] = ( nary[ tn + 1 ] - nary[ tn - 1 ] ) / \
                ( @t[ tn + 1] - @t[tn - 1] )
  end
    grad[0] = grad[1]; grad[@nt - 1] = grad[@nt - 2]
  return grad
end

#here
def energy_sum_ncwrite
  @length_around_eddy = 240.0 * 1000.0 # [m]
  #@length_around_eddy = 20.0 * 1000.0 # [m]: for test
  ke_sum, pe_sum = energy_sum_around_eddy
  #te_sum = ke_sum + pe_sum
  nc_fu = NetCDF.create( "./eddy_energy.nc" ) # temporary
    grid_t = Grid.new( Axis.new.set_pos( @tcor ) )
    tmp_en_sum_gpwrite( nc_fu, grid_t, ke_sum, "ke_sum")
    tmp_en_sum_gpwrite( nc_fu, grid_t, pe_sum, "pe_sum")
    tmp_en_sum_gpwrite( nc_fu, grid_t, ke_sum+pe_sum, "te_sum")
    nc_fu.put_att( "length_around_eddy_km", \
                    @length_around_eddy / 1000.0)
  nc_fu.close
end

  def tmp_en_sum_gpwrite( nc_fu, grid_t, e_sum, vname )
    va_e = VArray.new( e_sum, \
             {"units"=>"kg.s-2", \
              "long_name"=>"#{vname}_around_eddy"}, \
              vname )
    GPhys::NetCDF_IO.write( nc_fu, GPhys.new( grid_t, va_e ) )

    # temporary@2015-10-14
    e_dec = NArray.sfloat( @nt )
    for tn in 1..nt-2
      e_dec[tn] = ( e_sum[ tn+1 ] - e_sum[ tn-1 ] ) / \
                    ( 2.0 * @dto.val[0] )
    end
    e_dec[0] = e_dec[1]; e_dec[@nt - 1] = e_dec[ @nt - 2 ]
    va_edec = VArray.new( e_dec, \
             {"units"=>"kg.s-2/day", \
              "long_name"=>"#{vname}_decayrate"}, \
              "#{vname}_dec" )
    GPhys::NetCDF_IO.write( nc_fu, GPhys.new( grid_t, va_edec ) )
  end

# checker: compair with monit.nc
def energy_sum_all_region
  nxy = @nxp * @nyp
  for tn in 0..@nt-1
    ij_r = { "xp"=>@xp[0..-1], "yp"=>@yp[0..-1] }
    ke_sum = ke2d_calc( ij_r, 0, tn ).sum / nxy
    puts "ke: #{ke_sum} (k=0,tn=#{tn})"
    ke_sum = ke2d_calc( ij_r, 1, tn ).sum / nxy
    puts "ke: #{ke_sum} (k=1,tn=#{tn})"
    pe_sum = pe2d_calc( ij_r, 0, tn ).sum / nxy
    puts "pe: #{pe_sum} (k=0,tn=#{tn})"
  end
end

def energy_sum_around_eddy
  ke_sum = NArray.sfloat( @nt )
  pe_sum = NArray.sfloat( @nt )
  hmax, ie, je = sshmax_get_with_ij
  wdh = ( @length_around_eddy / @dxo.val[0] ).to_i
    n_region = ( 2.0 * wdh.to_f + 1.0 )**2.0
  for tn in 0..@nt-1
    ij_r = { "xp"=>@xp[ie[tn]-wdh..ie[tn]+wdh], \
             "yp"=>@yp[je[tn]-wdh..je[tn]+wdh] }
    ke_sum[tn] = ke2d_calc( ij_r, 0, tn ).sum / n_region
    pe_sum[tn] = pe2d_calc( ij_r, 0, tn ).sum / n_region
  end
  return ke_sum, pe_sum
end

def pe2d_calc( ij_range, k, t )
  range         = ij_range
  range["z"]    = @z[k]
  range["time"] = @t[t]
  p_up   = @p.cut( range ).val 
  range["z"]    = @z[k+1]
  p_down = @p.cut( range ).val
  eta = @rgpoc.val[k] * ( p_down - p_up )
  pe  = 0.5 * @rhooc.val[k] * @gpoc.val[k] * eta**2.0
  return pe
end

def ke2d_calc( ij_range, k, t )
  ug, vg = uvgeooc_calc_wrap( ij_range, k, t )
  #  24sec: 1921x961x1x3 
  #  puts ug.max; puts vg.max
  
  keoc = 0.5 * @rhooc.val[0] * @hoc.val[k] * ( ug**2.0 + vg**2.0 )
  return keoc
end

# default value
def uvgeooc_calc_wrap( ij_range = { "xp"=>@xp[@nxc-60..@nxc+60], "yp"=>@yp[@nyc-60..@nyc+60] } , k = 0, t = 0 )
  range         = ij_range
  range["z"]    = @z[k]
  range["time"] = @t[t]
  return uvgeooc2d_calc( @p.cut( range ).val )
end

# ToDo: 
#   - calc by GPhys object? or NArray
#   - ! generalize ! 2015-10-12 for z = 0 only 
#   - 
# modify from monit_diag.F: 
#   ugeos = -rdxof0*( po(i,j+1,k) - po(i,j,k))
#   vgeos =  rdxof0*( po(i+1,j,k) - po(i,j,k))
def uvgeooc2d_calc( po2d ) # NArray ( for calculation of energy around eddy )
  po = po2d # alias
  nx, ny = po.shape
  ugeooc = NArray.sfloat( nx, ny )
  vgeooc = NArray.sfloat( nx, ny )
  ugeooc[1..nx-2, 1..ny-2] = - 0.5 * @rdxof0_val \
    * ( po[1..nx-2, 2..ny-1] - po[1..nx-2, 0..ny-3] )
  vgeooc[1..nx-2, 1..ny-2] =   0.5 * @rdxof0_val \
    * ( po[2..nx-1, 1..ny-2] - po[0..nx-3, 1..ny-2] )
=begin
  for i in 1..nx-2
  for j in 1..ny-2
    ugeooc[i,j] = - 0.5 * @rdxof0_val \
      * ( po[i, j+1] - po[i, j-1] )
    vgeooc[i,j] =   0.5 * @rdxof0_val \
      * ( po[i+1, j] - po[i-1, j] )
  end
  end
=end
  #puts ugeooc.inspect
  #puts ugeooc.max; puts vgeooc.max
  return ugeooc, vgeooc
end
=begin
  # behavoir of units class
    puts @dxo.units   # m
    rdxo = 1.0 / @dxo
    puts rdxo.units   # 1
    rdxo = @dxo**-1
    puts rdxo.units   # m-1
=end




# ToDo: use varray_proto in submethods
def sshmax_etc_ncout
  sshmax_set_with_ij
  out_fname = "#{@dname}sshmax_etc.nc" 
  puts "Output hmax information to #{out_fname}"
  puts "  case: #{@gcname}-#{@cname}"
  nc_fu = NetCDF.create( out_fname )
    hmax_ncwrite_wrap( nc_fu )
    hdec_ncwrite_wrap( nc_fu )
  nc_fu.close
  return true # for test
end

  def hdec_ncwrite_wrap( nc_fu )
    hdec_ncwrite( nc_fu )
    zspd_ncwrite( nc_fu )
    mspd_ncwrite( nc_fu )
  end

  def hdec_ncwrite( nc_fu )
    exit_with_msg("hmax must be prepaired") if @hmax == nil
    hdec = calc_grad_t( @hmax ) * 365.0
      # cm/day -> cm/year
    va = VArray.new( hdec, \
                    {"units"=>"cm/year", \
                     "long_name"=>"SSH_Max_Decay_Rate"}, \
                    "hdec")
    gp = GPhys.new( @grid_t, va )
    GPhys::NetCDF_IO.write( nc_fu, gp )
  end

  def zspd_ncwrite( nc_fu )
    exit_with_msg("hmax_i must be prepaired") if @hmax_i == nil
    hmax_x = @xp[ @hmax_i ]
    zspd = calc_grad_t( hmax_x ) * @km_to_cm.val[0] / @day_to_sec.val[0]
    va = VArray.new( zspd, \
                    {"units"=>"cm/s", "long_name"=>"SSH_Max_Zonal_Speed"}, \
                     "zspd")
    gp = GPhys.new( @grid_t, va )
    GPhys::NetCDF_IO.write( nc_fu, gp )
  end

  def mspd_ncwrite( nc_fu )
    exit_with_msg("hmax_j must be prepaired") if @hmax_j == nil
    hmax_y = @yp[ @hmax_j ]
    mspd = calc_grad_t( hmax_y ) * @km_to_cm.val[0] / @day_to_sec.val[0]
    va = VArray.new( mspd, \
                    {"units"=>"cm/s", "long_name"=>"SSH_Max_Meridional_Speed"}, \
                     "mspd")
    gp = GPhys.new( @grid_t, va )
    GPhys::NetCDF_IO.write( nc_fu, gp )
  end

  def hmax_ncwrite_wrap( nc_fu )
    hmax_ncwrite(   nc_fu )
    hmax_x_ncwrite( nc_fu )
    hmax_y_ncwrite( nc_fu )
  end

  def hmax_ncwrite( nc_fu )
    exit_with_msg("hmax must be prepaired") if @hmax == nil
    va = VArray.new( @hmax, \
                    {"units"=>"cm", "long_name"=>"SSH_Max"}, \
                    "hmax")
    gp = GPhys.new( @grid_t, va )
    GPhys::NetCDF_IO.write( nc_fu, gp )
  end

  def hmax_x_ncwrite( nc_fu )
    exit_with_msg("hmax_i must be prepaired") if @hmax_i == nil
    hmax_x = @xp[ @hmax_i ]
    va = VArray.new( hmax_x, \
                    {"units"=>"km", "long_name"=>"SSH_Max_Position_X"}, \
                     "hmax_x")
    gp = GPhys.new( @grid_t, va )
    GPhys::NetCDF_IO.write( nc_fu, gp )
  end

  def hmax_y_ncwrite( nc_fu )
    exit_with_msg("hmax_j must be prepaired") if @hmax_j == nil
    hmax_y = @yp[ @hmax_j ]
    va = VArray.new( hmax_y, \
                    {"units"=>"km", "long_name"=>"SSH_Max_Position_Y"}, \
                     "hmax_y")
    gp = GPhys.new( @grid_t, va )
    GPhys::NetCDF_IO.write( nc_fu, gp )
  end
  
  # ToDo: absorb sshmax_get_with_ij
  def sshmax_set_with_ij
    if @hmax == nil
      pmax   = NArray.sfloat( @nt )
        hmax_i = NArray.sfloat( @nt )
        hmax_j = NArray.sfloat( @nt )
      for tn in 0..@nt-1
        pmax[tn], hmax_i[tn], hmax_j[tn] = \
          na_max_with_index_k247( \
            @p.cut( "z" => @z[0], "time" => @t[tn] ).val )
      end
      @hmax = pmax[0..-1] * @m_to_cm.val[0] / @grav.val[0]
        @hmax_i = hmax_i; @hmax_j = hmax_j
    end # unless @hmax == nil
  end

  # ToDo: replace to sshmax_set_with_ij
  def sshmax_get_with_ij
    pmax   = NArray.sfloat( @nt )
      hmax_i = NArray.sfloat( @nt )
      hmax_j = NArray.sfloat( @nt )
    for tn in 0..@nt-1
      pmax[tn], hmax_i[tn], hmax_j[tn] = \
        na_max_with_index_k247( \
          @p.cut( "z" => @z[0], "time" => @t[tn] ).val )
    end
    hmax = pmax[0..-1] * @m_to_cm.val[0] / @grav.val[0]
    return hmax, hmax_i, hmax_j
  end
=begin
  def sshmax_get_with_ij
  # failed to allocate memory ( 1920x960x2x72)
  #  ssh = ( @p.cut( "z" => @z[0] ) * @m_to_cm / @grav ).val
    @ssh = @p.cut( "z" => @z[0] ) * @m_to_cm / @grav
    hmax   = NArray.sfloat( @nt )
      hmax_i = NArray.sfloat( @nt )
      hmax_j = NArray.sfloat( @nt )
    for tn in 0..@nt-1
      hmax[tn], hmax_i[tn], hmax_j[tn] = \
        na_max_with_index_k247( @ssh.cut( "time" => @t[tn]).val )
      #puts hmax[tn] #, hmax_i[tn], hmax_j[tn]
    end

    return hmax, hmax_i, hmax_j
  end
=end

## - instance methods for check
# contents ( 2015-09-04 )
##  chk_monit_energy_stdout( input=nil )
##  chk_monit_energy_ncout(  input=nil )
  
  # Check Area averaged energy
  # ToDo
  #   - update for 3 or more layer @ 2015-10-12
  #   - sophisticate format
  def chk_monit_energy_stdout( input=nil )
    puts "Check Area averaged energy (from monit.nc)"
    puts "  case: #{@gcname}-#{@cname}"
    puts "  te: toal, pe: potential, ke: kinetic energy"; puts
    ke = @keocavg
    pe = @peocavg
    te = @teocavg

    puts "  te change( fin / ini    )   : #{ te.val[-1] / te.val[0] }"
    puts "     check ( min / max    )   : #{ te.val.min / te.val.max }"
    
    puts "  pe change( fin / ini )      : #{ pe.val[-1] / pe.val[0] }"

    puts "  ke change"
    puts "    upper ( fin / ini )       : #{ ke.val[0,-1] / ke.val[0,0] }"
    if ke.val[1,0] > 0.0
      puts "    lower ( fin / ini )       : #{ ke.val[1,-1] / ke.val[1,0] }"
    else
      puts "    lower                     : initially at rest"
    end
    puts "    lower / upper"
    puts "      inital                  : #{ ke.val[1,0] / ke.val[0,0] }"
    puts "      final                   : #{ ke.val[1,-1] / ke.val[0,-1] }"
    puts
    puts "  ke / pe"
    puts "      inital                  : #{ ke.val[0, 0] / pe.val[0, 0] }"
    puts "      final                   : #{ ke.val[0,-1] / pe.val[0,-1] }"
  end # def chk_monit_energy_stdout( input=nil)

  # Output Area averaged energy to NetCDF file
  # ToDo
  #   - create zonally & meridionally averaged energies
  #     ( another method)
  #   - refactoring ( abstract method )
  #   - update for 3 or more layer @ 2015-10-12
  def chk_monit_energy_ncout( input=nil)
    out_fname = "#{@dname}monit_energy.nc" 
    puts "Output area averaged energy to #{out_fname}"
    puts "  case: #{@gcname}-#{@cname}"
    ke = @keocavg
    pe = @peocavg
    te = @teocavg
    nc_fu = NetCDF.create( out_fname )
      GPhys::NetCDF_IO.write( nc_fu, te )
      sum_ke = 0
      for k in 0..@nz-1
        sum_ke = sum_ke + ke.cut("z"=>@z[k])
        GPhys::NetCDF_IO.write( nc_fu, \
               ke.cut("z"=>@z[k]).chg_gphys_k247( \
                {"name"=>"keocavg#{k}"}) )
      end
      sum_pe = 0
      for k in 0..@nzi-1
        sum_pe = sum_pe + pe.cut("zi"=>@zi[k])
        GPhys::NetCDF_IO.write( nc_fu, \
               pe.cut("zi"=>@zi[k]).chg_gphys_k247( \
                {"name"=>"peocavg#{k}"}) )
      end
      GPhys::NetCDF_IO.write( nc_fu, \
              sum_ke.chg_gphys_k247({"name"=>"ke_sum"}) )
      GPhys::NetCDF_IO.write( nc_fu, \
              sum_pe.chg_gphys_k247({"name"=>"pe_sum"}) )
    nc_fu.close
  end # def chk_monit_energy_ncout( input=nil)



## - instance methods for initialzie
# contents ( 2015-10-06 )
##
##  init_fname
##  init_set_var
##  init_monit
##  init_params
##    init_params_nodim
##    init_params_zdim
##  init_etc
##    init_coord
##    init_teocavg
##    init_casename
##      init_dname
##

# Create: 2015-09-10
#
def init_fname( input )
  if input.include?(".nc")
    nc_fn = input
  else # casename
    nc_fn = conv_cname_to_fname( input )
  end
  exit_with_msg("No Such File #{nc_fn}") unless File.exist?( nc_fn )
  puts "unified filename: #{nc_fn}"
  return nc_fn
end

  def conv_cname_to_fname( cname )
  #here
  #  return self.class.prep_set_filenames( cname )["out_nf"]
    return self.class.prep_set_unified_fpath( cname )
  end




def init_set_var
  @p = GPhys::IO.open( @nc_fn, "p" )
  @q = nil # set by calc_q
end


def init_monit
  self.class.prep_monit_get_vname.each do | vn |
    instance_variable_set( \
      "@#{vn}", GPhys::IO.open( @nc_fn, vn ) )
  end
  @keocavg = @kealoc
  @peocavg = ( @rhooc * @gpoc * @et2moc / 2.0 ).chg_gphys_k247(
     {"name"=>"peocavg","long_name"=>"Averaged potential energy"} )
#  @oc = GPhys::IO.open( @nc_fn, "oc")
end # def init_monit( @nc_fn )


def init_params
  init_params_zdim
  init_params_nodim
  init_params_etc
end

  def init_params_etc
    nary = NArray.sfloat( 1 )
    
    nary[0] = 9.8
    @grav = VArray.new( nary.clone, { "units" => "m.s-2" }, "grav" )

    nary[0] = 100.0
    @m_to_cm = VArray.new( nary.clone, { "units" => "m-1.cm" }, "m_to_cm" )

    nary[0] = 1000.0 * 100.0
    @km_to_cm = VArray.new( nary.clone, { "units" => "km-1.cm" }, "km_to_cm" )

    nary[0] = 24.0 * 3600.0
    @day_to_sec = VArray.new( nary.clone, { "units" => "day-1.s" }, "day_to_sec" )


  end

  def init_params_zdim
    [ "z", "zi" ].each do | dim |
      self.class.prep_params_get_vname( dim ).each do | aname |
        instance_variable_set( \
          "@#{aname}", GPhys::IO.open( @nc_fn, aname ) )
      end
    end
  end # def set_inparam_zdim 
  
  def init_params_nodim
    nc_fu = NetCDF.open( @nc_fn )
    self.class.prep_params_get_vname( "nodim" ).each do | aname |
      vary = init_set_varray_param( nc_fu, aname )
      instance_variable_set("@#{aname}", vary)
      #puts "  in_para: #{aname}" # 
    end
    nc_fu.close
  end # set_inparam_nodim

    def init_set_varray_param( nc_fu, aname )
      att_line = nc_fu.att( aname ).get
      val, units, long_name = att_line.split(":")
      tna = NArray[ val.to_f ]
      return VArray.new( tna, {"units"=>units, "long_name"=>long_name}, aname)
    end


def init_etc
  init_coord
  init_etc_additional_params
  init_teocavg
  init_casename
  init_etc_defvar
end # def init_etc

  # ToDo
  #   - refactoring: kill dupliction
  #       instance_variable_set("@#{aname}", va_tmp)
  def init_coord
    @xpcor = @p.coord("xp"); @xp = @xpcor.val; @nxp = @xp.length
      @nxc = ( @nxp - 1 ) / 2
    @ypcor = @p.coord("yp"); @yp = @ypcor.val; @nyp = @yp.length
      @nyc = ( @nyp - 1 ) / 2
    @zcor = @p.coord("z"); @z = @zcor.val; @nz = @z.length
    @zicor = @et2moc.coord("zi"); @zi = @zicor.val; @nzi = @zi.length
    @tcor = @p.coord("time"); @t = @tcor.val; @nt = @t.length
      @grid_t = Grid.new( Axis.new.set_pos( @tcor) )
    @tmcor = @et2moc.coord("time_monitor"); @tm = @tmcor.val; @ntm = @tm.length
  end # def init_coord

  def init_etc_additional_params
    @rdxof0 = ( @dxo * @fnot )**-1.0
      @rdxof0_val = @rdxof0.val[0]
    @rgpoc = ( @gpoc )**-1.0
      @rgpoc_val = @rgpoc.val
  end

  # 2015-09-04
  # ToDo
  #   - use iterater
  #   - sum up peoc for 3 or more layer model
  def init_teocavg
    total_ke = @keocavg.cut( "z"=>@z[0] )
    for k in 1..@nz-1
      total_ke = total_ke + @keocavg.cut( "z"=>@z[k])
    end
    @teocavg = \
       ( @peocavg + total_ke ).chg_gphys_k247( \
          {"name"=>"teocavg", "long_name"=>"Averaged total energy"})
  end # def init_teocavg

  # ToDo: assumption of filename as ".../outdata_YY/q-gcm_XX_YY_out.nc"
  def init_casename
    tmp = @nc_fn.split("q-gcm_")[1] # XX_YY_out.nc
    tmp2 = tmp.split("_out")[0] # XX_YY
    # for change of directory structure ( 2015-10-06 )
    #@gcname, @cname = tmp2.split("_")
    @gcname = self.class.prep_set_greater_cname
    @cname = tmp2.split( "#{@gcname}_" )[1]
    init_dname( @cname )
  end # def init_casename
  
  def init_dname( cname )
    @dname = conv_cname_to_dname( cname )
  end

    def conv_cname_to_dname( cname )
      return self.class.prep_set_dpath( cname )
    end

  def init_etc_defvar
    @hmax = nil
      @hmax_i = nil; @hmax_j = nil
  end




def self.exist_class?
  return true
end

## End: class methods for prepare

# end_of_class
end # class K247_qgcm_data


=begin
## how to use: K247_qgcm_data
nc_fn = "./outdata_tmp/q-gcm_29_tmp_out.nc"
tmp = K247_qgcm_data.new( nc_fn )

vnames = tmp.instance_variables
vnames.each do | vn |
  p tmp.instance_variable_get( vn )
#  p tmp.instance_variable_get( vn ).get_att("long_name")
end
=end

# for test code
if $0 == __FILE__ then
# move test code to test_qgcm_k247.rb
require 'minitest/autorun'
require_relative "lib_qgcm_k247"

class Test_K247_qgcm_E8 < MiniTest::Unit::TestCase
  def setup
  #  @obj = K247_qgcm_data.new( "dx4km2y" ) # temporary @ 2015-10-12
    @obj = K247_qgcm_data.new( "test" ) # temporary @ 2015-10-12
  end

  def teardown
    #
  end

  def test_sshmax_get_with_ij
    hmax, hmax_i, hmax_j = @obj.sshmax_get_with_ij
    assert_equal NArray, hmax.class
  end
  
  def test_sshmax_set
    @obj.sshmax_set_with_ij
    assert_equal NArray, @obj.hmax.class
  end

  def test_sshmax_etc_ncout
    assert @obj.sshmax_etc_ncout
  end

  def test_ke2d_calc
    @obj.ke2d_calc( { "xp"=>[-8.0, -4.0, 0.0, 4.0, 8.0], \
                      "yp"=>[-8.0, -4.0, 0.0, 4.0, 8.0] }, 0, 0 )
    assert true
  end

  def test_pe2d_calc
    @obj.pe2d_calc( { "xp"=>[-8.0, -4.0, 0.0, 4.0, 8.0], \
                      "yp"=>[-8.0, -4.0, 0.0, 4.0, 8.0] }, 0, 0 )
    assert true
  end

  #def
  #  #  
  #end

=begin

  def test_gp_proto
    GPhys_Prototype.new
  end
  def test_energy_sum_ncwrite
    @obj.energy_sum_ncwrite
    assert true
  end
  def test_energy_sum_all_region
    @obj.energy_sum_all_region
    assert true
  end
# heavy
  def test_ke_sum_around_eddy
    ke_sum = @obj.ke_sum_around_eddy
    puts ke_sum.inspect
    assert true
  end
=end
end # class Test_K247_qgcm_E8 < MiniTest::Unit::TestCase

end # if $0 == __FILE__ then
