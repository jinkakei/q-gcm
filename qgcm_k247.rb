#!/usr/bin/ruby
# -*- coding: utf-8 -*-

# load libraries
require_relative "lib_k247_for_qgcm"


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
##    -- sshmax_write
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

def energy_sum_ncwrite
  @length_arround_eddy = 240.0 * 1000.0 # [m]
  #@length_arround_eddy = 20.0 * 1000.0 # [m]: for test
  ke_sum, pe_sum = energy_sum_around_eddy
  te_sum = ke_sum + pe_sum
  nc_fu = NetCDF.create( "./eddy_energy.nc" ) # temporary
    grid_t = Grid.new( Axis.new.set_pos( @tcor ) )
    tmp_en_sum_gpwrite( nc_fu, grid_t, ke_sum, "ke_sum")
    tmp_en_sum_gpwrite( nc_fu, grid_t, pe_sum, "pe_sum")
    tmp_en_sum_gpwrite( nc_fu, grid_t, te_sum, "te_sum")
  nc_fu.close
end

  def tmp_en_sum_gpwrite( nc_fu, grid_t, e_sum, vname )
    va_e = VArray.new( e_sum, \
             {"units"=>"kg.s-2", \
              "long_name"=>"#{vname}_around_eddy"}, \
              vname )
    GPhys::NetCDF_IO.write( nc_fu, GPhys.new( grid_t, va_e ) )
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
  wdh = ( @length_arround_eddy / @dxo.val[0] ).to_i
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



def sshdec_tmp
  hdec = sshdec_get
  grid_t = Grid.new( Axis.new.set_pos( @tcor ) )
  nc_fu = NetCDF.create( "./test20151013.nc" )
    va_h = VArray.new( hdec, {"units"=>"cm/year", "long_name"=>"ssh_decay"}, "hdec")
    gp_h = GPhys.new( grid_t, va_h )
    GPhys::NetCDF_IO.write( nc_fu, gp_h )
  nc_fu.close
end

  def sshdec_get
    hmax, imax, jmax = sshmax_get_with_ij
    hdec = NArray.sfloat( @nt )
    for tn in 1..@nt-2
    # cm/day
    #  hdec[tn] = ( hmax[ tn + 1 ] - hmax[ tn - 1 ] ) / \
    # cm/year
      hdec[tn] = ( hmax[ tn + 1 ] - hmax[ tn - 1 ] ) * 365.0 / \
          ( @t[ tn + 1] - @t[tn - 1] )
    end
      hdec[0] = hdec[1]; hdec[ @nt - 1] = hdec[ @nt - 2]
    return hdec
  end

  def sshmax_write
    hmax, imax, jmax = sshmax_get_with_ij
    grid_t = Grid.new( Axis.new.set_pos( @tcor ) )
    nc_fu = NetCDF.create( "./test_tmp.nc" )
      va_h = VArray.new( hmax, {"units"=>"cm", "long_name"=>"ssh_max"}, "hmax")
      gp_h = GPhys.new( grid_t, va_h )
      GPhys::NetCDF_IO.write( nc_fu, gp_h )
    nc_fu.close
  end

  def sshmax_get_with_ij
    ssh = @p.cut( "z" => @z[0] ) * @m_to_cm / @grav 
    hmax   = NArray.sfloat( @nt )
      imax = NArray.sfloat( @nt )
      jmax = NArray.sfloat( @nt )
    for tn in 0..@nt-1
      hmax[tn], imax[tn], jmax[tn] = \
        na_max_with_index_k247( ssh.cut( "time" => @t[tn]).val )
    end

    return hmax, imax, jmax
  end
=begin
  def sshmax_get_with_ij
    @ssh = @p.cut( "z" => @z[0] ) * @m_to_cm / @grav
    hmax   = NArray.sfloat( @nt )
      imax = NArray.sfloat( @nt )
      jmax = NArray.sfloat( @nt )
    for tn in 0..@nt-1
      hmax[tn], imax[tn], jmax[tn] = \
        na_max_with_index_k247( @ssh.cut( "time" => @t[tn]).val )
      #puts hmax[tn] #, imax[tn], jmax[tn]
    end

    return hmax, imax, jmax
  end
=end

## - instance methods for check
# contents ( 2015-09-04 )
##  chk_energy_avg_stdout( input=nil )
##  chk_energy_avg_ncout(  input=nil )
  
  # Check Area averaged energy
  # ToDo
  #   - zonally & meridionally averaged energies ( add new method? )
  #   - update for 3 or more layer @ 2015-10-12
  def chk_energy_avg_stdout( input=nil )
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
  end # def chk_energy_avg_stdout( input=nil)

  # Output Area averaged energy to NetCDF file
  # ToDo
  #   - create zonally & meridionally averaged energies
  #     ( another method)
  #   - refactoring ( abstract method )
  #   - update for 3 or more layer @ 2015-10-12
  def chk_energy_avg_ncout( input=nil)
    out_fname = "#{@dname}energy_check.nc" 
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
  end # def chk_energy_avg_ncout( input=nil)



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




## - class methods for preparation ( unify outdata_*/* )
##  contents@2015-09-02
##   - self.prep_unify_outdata( cname )
##   - self.prep_set_filename( cname )
##     --  self.prep_set_greater_cname( arg=nil)
##   - self.prep_write_monit( input )
##   - self.prep_write_inpara( input )
##     -- self.prep_read_inpara( input )
##          !Caution! too long & complicate!! @2015-09-10
##   - self.prep_modify_grid( apts )


# Create: 2015-08 or 09
# modify: 2015-09-10 ( argument & import prep_set_filenames )
#
# ToDo: 
    # treat large datasize
    # kill out_flag
#
# argument: cname -- casename ( String, donot include "_" )
# action  : read outdata_YY/??? & write outdata_YY/qgcm_XX_YY_out.nc
# return  : none
def self.prep_unify_outdata( cname=nil )
  puts "beginning of unite outdata files"

  exit_with_msg("input case name") if cname==nil
  dpath     = self.prep_set_dpath_with_check( cname )
  out_nf    = self.prep_set_unified_fpath_with_check( cname )
    gp_ocpo    = self.prep_get_updated_po( dpath )
    hash_monit = self.prep_read_monit_all( dpath )
    hash_para  = self.prep_get_params( dpath ) 
  out_fu = NetCDF.create( out_nf )
    GPhys::NetCDF_IO.write(       out_fu, gp_ocpo )
    self.prep_write_para(  dpath, out_fu, hash_para  )
    self.prep_write_monit(        out_fu, hash_monit )
    self.prep_write_misc(         out_fu, cname  )
  out_fu.close

  puts "end of unite outdata files"
  return true # temporary for test
end # def self.prep_unify_outdata



## prepare

# Goal: reduce type
#   ToDo: change place
#   memo: error message should be displayed @ 2015-10-07
def self.check_case( cname )
  exit_with_msg("input case name") if cname==nil
end

def check_case( cname )
  exit_with_msg("input case name") if cname==nil
end


  def self.prep_set_dpath( cname )
    self.check_case(cname)
    return "./outdata_#{cname}/"
  end

  def self.prep_set_dpath_with_check( cname )
     dpath = self.prep_set_dpath( cname )
     if self.prep_dpath_has_elements?( dpath )
       return dpath
     else
       exit_with_msg( "#{dpath} lack element files")
     end
  end

  def self.prep_dpath_has_elements?( dpath )
    ofpaths = self.prep_set_original_fpaths( dpath )
    current_fpaths = Dir::glob( dpath + "*" )
    ofpaths.each do | f |
      if current_fpaths.include?( f )
        #puts "  #{f} exist"
      else
        puts "  #{f} does not exist"
        return false 
      end
    end
    return true
  end
    
  def self.prep_set_original_fpaths( dpath )
    fnames = ["ocpo.nc", "monit.nc", "input_parameters.m"]
    fpaths = []
    fnames.each do | fn |
      fpaths.push( dpath + fn )
    end
    return fpaths
  end


def self.prep_set_unified_fpath_with_check( cname )
  fpath = self.prep_set_unified_fpath( cname )
  if File.exist?( fpath )
    exit_with_msg( "outfile: #{fpath} is already exist")
  else
    return fpath
  end
end

def self.prep_set_unified_fpath( cname )
  dpath = self.prep_set_dpath( cname )
  gcname = self.prep_set_greater_cname
  return "#{dpath}q-gcm_#{gcname}_#{cname}_out.nc"
end

  def self.prep_set_greater_cname( arg=nil)
  # ver. 2015-10-06: use ./Goal__*__.txt
    goal_file = Dir::glob("./Goal__*__.txt")
    if goal_file.length > 1
      p goal_file
      exit_with_msg("Test Goal must be one and only")
    end
    exit_with_msg("Goal__*__.txt is not exist") if goal_file[0] == nil
    return goal_file[0].split("__")[1]
  end



## write monit
def self.prep_write_monit( out_fu, hash_monit )
  hash_monit.each_value do |item|
    GPhys::NetCDF_IO.write( out_fu, item )
  end
  return true
end


# write misc
def self.prep_write_misc( out_fu, cname )
  gcname = self.prep_set_greater_cname
  out_fu.put_att( "cname" ,  cname )
  out_fu.put_att( "gcname", gcname )
end



# write parameters
def self.prep_write_para( dpath, out_fu, hash_para )
  self.prep_write_para_nodim(     out_fu, hash_para )
  self.prep_write_para_z(  dpath, out_fu, hash_para )
  self.prep_write_para_zi( dpath, out_fu, hash_para )
  return true # temporary
end

  def self.prep_write_para_zi( dpath, out_fu, p_hash )
    vname      = self.prep_params_get_vname( "zi" )
    unit       = self.prep_params_get_units( "zi" )
    grid       = GPhys::IO.open( dpath + "ocpo.nc", 'zi').grid_copy
    val        = p_hash["val"]
    comment    = p_hash["comment"]
    vname.each do |vn|
      attr_tmp = {"units"=>unit[vn], "long_name"=>comment[vn]}
      nary     = self.prep_conv_ary_str_to_nary( val[vn] )
      gp_tmp   = GPhys.new( grid, VArray.new( nary, attr_tmp, vn) )
      GPhys::NetCDF_IO.write( out_fu, gp_tmp )
    end
  end

  def self.prep_write_para_z( dpath, out_fu, p_hash )
    vname      = self.prep_params_get_vname( "z" )
    unit       = self.prep_params_get_units( "z" )
    val        = p_hash["val"]
    comment    = p_hash["comment"]
    grid       = GPhys::IO.open( dpath + "ocpo.nc", 'z').grid_copy
    vname.each do |vn|
      attr_tmp = {"units"=>unit[vn], "long_name"=>comment[vn]}
      nary     = self.prep_conv_ary_str_to_nary( val[vn] )
      gp_tmp   = GPhys.new( grid, VArray.new( nary, attr_tmp, vn) )
      GPhys::NetCDF_IO.write( out_fu, gp_tmp )
    end
  end

    def self.prep_conv_ary_str_to_nary( ary )
    #  if ary.class == "Array"
      if ary.class == Array
        n = ary.length
        nary = NArray.sfloat( n )
        ary.each_with_index do |item, n|
          nary[n] = item.to_f
        end
      else
        nary    = NArray.sfloat(1)
        nary[0] = ary.to_f
      end
      return nary
    end

  def self.prep_write_para_nodim( out_fu, p_hash )
    vname_no = self.prep_params_get_vname( "nodim" )
    unit = self.prep_params_get_units( "nodim" )
    val = p_hash["val"]
    comment = p_hash["comment"]
    vname_no.each do |vn|
      out_fu.put_att( vn, "#{val[vn]}:#{unit[vn]}:#{comment[vn]}")
    end
  end

  def self.prep_params_get_units( type )
    case type
    when "nodim"
      return { "fnot"=>"s-1", "beta"=>"s-1.m-1", \
               "dxo"=>"m", "dto"=>"s", \
               "rhooc"=>"kg.m-3", "cpoc"=>"J.kg-1.K-1", \
               "l_spl"=>"m", "c1_spl"=>" "}
    when "z"
      return { "tabsoc"=>"K", "tocc"=>"degC", "hoc"=>"m", \
               "ah2oc"=>"m2.s-1", "ah4oc"=>"m4.s-1"}
    when "zi"
      return {"cphsoc"=>"cm.s-1", "gpoc"=>"m.s-2", "rdefoc"=>"m"}
    else
      puts "!ERROR! prep_params_get_units: wrong argument!" 
    end
  end



## read & modify ocpo.nc
  def self.prep_get_updated_po( dpath )
    fpath = dpath + "ocpo.nc"
    self.prep_check_ocpo( fpath )
    gp_po = GPhys::IO.open( fpath, 'p')
    new_grid = self.prep_modify_po_grid( gp_po )
    return GPhys.new( new_grid, gp_po.data)
  end

    def self.prep_check_ocpo( fpath )
      #GPhys::IO.is_a_NetCDF?( fpath ) # NoMethod?
      self.prep_exit_if_ocpo_lack_po( fpath )
      self.prep_check_po_size( fpath )
    end

      def self.prep_exit_if_ocpo_lack_po( fpath )
        unless self.prep_ocpo_has_po?( fpath )
          exit_with_msg("#{fpath} does not include p") 
        end
      end

        def self.prep_ocpo_has_po?( fpath )
          return GPhys::IO.var_names( fpath ).include?("p")
        end
      
      def self.prep_check_po_size( fpath )
        size_criterion = 960 * 960 * 2 * 36
        current_size = self.prep_calc_po_size( fpath )
        msg = "\n\n  INFO: Writing Huge Data ( please wait)\n\n"
        print msg if current_size >= size_criterion
      end

        def self.prep_calc_po_size( fpath )
          gp_po = GPhys::IO.open( fpath, 'p')
          nxp   = gp_po.coord("xp"  ).val.length
          nyp   = gp_po.coord("yp"  ).val.length
          nz    = gp_po.coord("z"   ).val.length
          ntime = gp_po.coord("time").val.length
          return nxp*nyp*nz*ntime
        end

    # argument: gp_po -- gphys object of ocpo.nc@p (*) 
    #                    (*) q-gcm/src/outdata_*/ocpo.nc@p
    def self.prep_modify_po_grid( gp_po )
      origin = gp_po.get_axes_parts_k247
      modified = origin.clone
      puts "  ocpo.nc@p: replace X,Y Axis ( 0 at center)"
      puts "  ocpo.nc@p: convert unit of TIME Axis to [days]"
        modified['xp']   = self.prep_modify_po_xy( origin['xp'] )
        modified['yp']   = self.prep_modify_po_xy( origin['yp'] )
        modified['time'] = self.prep_modify_po_time( origin['time'] )
      return gp_po.restore_grid_k247( modified )
    end # def self.prep_modify_grid( apts )
      
      def self.prep_modify_po_xy( xy_hash )
        n = xy_hash['val'].length
        d = xy_hash['val'][1] - xy_hash['val'][0]
        xy_hash['val'] -= d * ( n - 1 ).to_f / 2.0
        return xy_hash
      end
    
      def self.prep_modify_po_time( time_hash )
        time_hash['val'] *= 365.0
        time_hash['atts']['units'] = 'days'
        return time_hash
      end



## read & modify monit.nc
def self.prep_read_monit_all( dpath )
  nf_name = dpath + "monit.nc"
  monit_gp_out = {}
  (self.prep_monit_get_vname).each do | v |
    monit_gp_out[ v ] = self.prep_read_monit_var( nf_name, v)
  end
  return monit_gp_out
end

  def self.prep_monit_get_vname
    return ['ddtkeoc', 'ddtpeoc', 'emfroc', 'ermaso', \
            'et2moc' , 'etamoc' , 'kealoc', 'pkenoc']
  end

  def self.prep_read_monit_var( nf_name, vname )
    gp_monv_org = GPhys::IO.open( nf_name, vname)
      new_grid     = self.prep_modify_monit_grid( gp_monv_org )
      gp_monv_data = self.prep_modify_monit_data( gp_monv_org )
    return GPhys.new( new_grid, gp_monv_data )
  end

    def self.prep_modify_monit_data( gp_monv_org )
      case gp_monv_org.name
      when "et2moc"
        return gp_monv_org.chg_varray_k247( {"units"=>"m2", \
          "comment_by_k247"=>"units corrected from W/m^2"} )
      when "kealoc"
        return gp_monv_org.chg_varray_k247( {"units"=>"kg.s-2", \
          "comment_by_k247"=>"units corrected from J/m^2"} )
      when "pkenoc"
        return gp_monv_org.chg_varray_k247( \
          {"comment_by_k247"=>"this variable is broken"} )
      else
        return gp_monv_org.data
      end
    end

    def self.prep_modify_monit_grid( gp_monv )
      origin   = gp_monv.get_axes_parts_k247
      modified = origin.clone
        modified["time"] = self.prep_modify_monit_time( origin["time"] )
        self.prep_modify_monit_z( modified )
      return gp_monv.restore_grid_k247( modified )
    end

      def self.prep_modify_monit_time( time_hash )
        time_hash["name"]           = "time_monitor"
        time_hash["val" ]          *= 365.0
        time_hash["atts"]["units"]  = "days"
        return time_hash
      end

      def self.prep_modify_monit_z( axes_parts )
        axes_parts["zo" ]["name"] = "z"  if axes_parts.has_key?('zo')
        axes_parts["zom"]["name"] = "zi" if axes_parts.has_key?('zom')
        ## adjust vertical axis name with ocpo.nc
      end



## read & modify input_parameters.m
  def self.prep_get_params( dpath )
    para_lines = self.prep_read_input_params( dpath )
    self.prep_params_del_comments( para_lines )
    return self.prep_params_get_wrap( para_lines )
  end

    def self.prep_params_get_wrap( lines )
      pno = self.prep_params_get_nodim( lines )
      pz  = self.prep_params_get_z(     lines )
      pzi = self.prep_params_get_zi(    lines )
      return self.prep_params_merge_hash( pno, pz, pzi )
    end

      def self.prep_params_merge_hash( pno, pz, pzi )
        para_hash = {}
        para_hash["name"] = pno["name"] + pz ["name"] + pzi["name"]
        [ "val", "comment" ].each do |key|
          para_hash[key] = pno[key].merge( pz[key].merge( pzi[key] ) )
        end
        return para_hash
      end

    def self.prep_params_get_common( lines, vname )
      val = {}; com = {}
      vname.each do |v|
        idx = ary_get_include_index( lines, v )
        kn = idx.length
        if kn > 1
          ary =[]
          dummy, ary[0], com[v] = self.prep_params_conv_line(lines[idx[0]])
          for k in 1..kn-1
            ary[k] = self.prep_params_conv_line_z( lines[idx[k]] )
          end
          val[v] = ary
        else
          dummy, val[v], com[v] = self.prep_params_conv_line(lines[idx[0]])
        end
      end
      para = {}
        para["name"]    = vname
        para["val"]     = val
        para["comment"] = com
      return para
    end
      
    def self.prep_params_get_vname( type )
      return [ "gpoc", "cphsoc", "rdefoc"] if type == "zi"
      return [ "fnot", "beta", "dxo","dto", "rhooc", \
              "cpoc", "l_spl", "c1_spl"] if type == "nodim"
      return [ "ah2oc", "ah4oc", "tabsoc", "tocc", "hoc" ] if type == "z"
    end

    def self.prep_params_get_zi( lines )
      vname_zi = self.prep_params_get_vname( "zi" )
      return self.prep_params_get_common( lines, vname_zi )
    end

    def self.prep_params_get_z( lines )
      vname_z  = self.prep_params_get_vname( "z" )
      return self.prep_params_get_common( lines, vname_z  )
    end

    def self.prep_params_get_nodim( lines )
      vname_no = self.prep_params_get_vname( "nodim" )
      return self.prep_params_get_common( lines, vname_no )
    end

    def self.prep_params_conv_line( line )
      name, tmp1    = line.split("=")
      val , tmp2    = tmp1.split(";")
      left, comment = tmp2.split("%% ")
      return name, val, comment
    end

    def self.prep_params_conv_line_z( line )
      tmp1 , dummy    = line.split("];")
      dummy, tmp2     = tmp1.split("= ")
      dummy, val = tmp2.split("  ")
      return val
    end

    def self.prep_params_get_nlo( lines )
      i_nlo = 0
      lines.each_with_index do | l,n |
        i_nlo = n if l.include?("nlo")
      end
      name, nlo_str, comment = self.prep_params_conv_line( lines[i_nlo] )
      return nlo_str.to_i
    end

    def self.prep_read_input_params( dpath )
      lines = []
      fu = File.open( dpath + "input_parameters.m",'r' )
      while l = fu.gets
        lines.push( l.chomp ) 
      end
      fu.close
      return lines
    end

    def self.prep_params_del_comments( lines )
      del_lines = [ "%%Matlab script to read in parameters", \
                    "%%Derived parameters", \
                    " ", "%%Parameters added by K247"]
      del_lines.each do |d|
        lines.delete( d  )
      end
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
require_relative "lib_k247_for_qgcm"

class Test_K247_qgcm_E8 < MiniTest::Unit::TestCase
  def setup
  #  @obj = K247_qgcm_data.new( "dx4km2y" ) # temporary @ 2015-10-12
    @obj = K247_qgcm_data.new( "test" ) # temporary @ 2015-10-12
  end

  def teardown
    #
  end

  def test_sshmax_get_with_ij
    hmax, imax, jmax = @obj.sshmax_get_with_ij
    assert_equal NArray, hmax.class
  end

  def test_sshdec_get
    hdec = @obj.sshdec_get
    assert_equal NArray, hdec.class
  end

#  def test_sshdec_get_tmp
#    @obj.sshdec_tmp
#    assert true
#  end

#  def test_uvgeooc_calc
#    @obj.uvgeooc_calc_wrap
#    assert true
#  end

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

  def test_energy_sum_ncwrite
    @obj2 = K247_qgcm_data.new( "dx4km2y" )
    @obj2.energy_sum_ncwrite
    assert true
  end

=begin
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
