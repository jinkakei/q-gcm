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
  # from init_etc
  attr_reader :gcname, :cname, :dname

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
    init_inparam
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
## - instance methods for check 
## - instance methods for initialzie
## - class methods for preparation ( unify outdata_*/* )



## - instance methods for check
# contents ( 2015-09-04 )
##  chk_energy_avg_stdout( input=nil)
##  chk_energy_avg_ncout( input=nil)
  
  # 2015-09-09
  # Check Area averaged energy
  # ToDo
  #   add zonally & meridionally averaged energies
  def chk_energy_avg_stdout( input=nil )
    puts "Check Area averaged energy (from monit.nc)"
    puts "  case: #{@gcname}-#{@cname}"
    ke = @keocavg
    pe = @peocavg
    te = @teocavg

    puts "  te change( te[-1]/te[0] )   : #{ te.val[-1] / te.val[0] }"
    puts "     check ( te.min/te.max )  : #{ te.val.min / te.val.max }"
    
    puts "  pe change( pe[-1]/pe[0] )   : #{ pe.val[-1] / pe.val[0] }"

    puts "  ke change"
    puts "    upper ( ke[0,-1]/ke[0,0] ): #{ ke.val[0,-1] / ke.val[0,0] }"
    if ke.val[1,0] > 0.0
      puts "    lower ( ke[1,-1]/ke[1,0] ): #{ ke.val[1,-1] / ke.val[1,0] }"
    else
      puts "    lower                     : initially at rest"
    end
    puts "    lower / upper"
    puts "      inital                  : #{ ke.val[1,0] / ke.val[0,0] }"
    puts "      final                   : #{ ke.val[1,-1] / ke.val[0,-1] }"
  end # def chk_energy_avg_stdout( input=nil)

  # 2015-09-09
  # Output Area averaged energy to NetCDF file
  # ToDo
  #   - create zonally & meridionally averaged energies
  #     ( another method)
  #   - refactoring ( abstract method )
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
##  init_inparam
##    init_inparam_nodim
##    init_inparam_zdim
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
    return self.class.prep_set_filenames( cname )["out_nf"]
  end

def init_set_var
  @p = GPhys::IO.open( @nc_fn, "p" )
  @q = nil # set by calc_q
end

# Create: 2015-09-01
## ToDo
#    - select variables
#    - refactoring: kill duplication
#    - refactoring: [calc pe & set warnig] -> move to prep
def init_monit
  @ddtkeoc = GPhys::IO.open( @nc_fn, "ddtkeoc")
  @ddtpeoc = GPhys::IO.open( @nc_fn, "ddtpeoc")
  @emfroc = GPhys::IO.open( @nc_fn, "emfroc")
  @ermaso = GPhys::IO.open( @nc_fn, "ermaso")
  @et2moc = GPhys::IO.open( @nc_fn, "et2moc")
  # calc potential energy
     #tmp = 0.5 * @rhooc * @gpoc *@et2moc # !Caution! "units" become wrong ( kg2 m-3 s-2 )
     @peocavg = ( @rhooc * @gpoc *@et2moc / 2.0 ).chg_gphys_k247( 
        {"name"=>"peocavg","long_name"=>"Averaged potential energy"} )
  @etamoc = GPhys::IO.open( @nc_fn, "etamoc")
  @kealoc = ( GPhys::IO.open( @nc_fn, "kealoc") ).chg_gphys_k247( {"units"=>"kg.s-2"})
    @keocavg = @kealoc
  #@pkenoc = GPhys::IO.open( @nc_fn, "pkenoc")
  # set warning
    @pkenoc = ( GPhys::IO.open( @nc_fn, "pkenoc") ).chg_gphys_k247( \
        {"comment_by_k247"=>"this data are considerted to be broken"} )
#  @oc = GPhys::IO.open( @nc_fn, "oc")
end # def init_monit( @nc_fn )


def init_inparam
  init_inparam_zdim
  init_inparam_nodim
end

  # Create: 2015-09-01
  ## ToDo : sophisticate
  def init_inparam_zdim
    @gpoc = GPhys::IO.open( @nc_fn, "gpoc" )
    @cphsoc = GPhys::IO.open( @nc_fn, "cphsoc" )
    @rdefoc = GPhys::IO.open( @nc_fn, "rdefoc" )
    @ah2oc = GPhys::IO.open( @nc_fn, "ah2oc" )
    @ah4oc = GPhys::IO.open( @nc_fn, "ah4oc" )
    @tabsoc = GPhys::IO.open( @nc_fn, "tabsoc" )
    @hoc = GPhys::IO.open( @nc_fn, "hoc" )
  end # def set_inparam_zdim( @nc_fn )
  
  
  ## Create: 2015-09-01
  def init_inparam_nodim
    nc_fu = NetCDF.open( @nc_fn )
    anames = nc_fu.att_names
    ## !caution! 
    anames_not_param = ["history", "original"]
      anames_not_param.each do | dname | anames.delete( dname ) end
    anames.each do | aname |
      att_line = nc_fu.att( aname ).get
      val, units, long_name = att_line.split(":")
      tna = NArray[ val.to_f ]
      va_tmp = VArray.new( tna, {"units"=>units, "long_name"=>long_name}, aname)
      instance_variable_set("@#{aname}", va_tmp)
      #puts "  in_para: #{aname}" # 
    end
    nc_fu.close
  end # set_inparam_nodim


# 2015-09-04
def init_etc
  init_coord
  init_teocavg
  init_casename
end # def init_etc

  # ToDo
  #   - refactoring: kill dupliction
  def init_coord
    @xpcor = @p.coord("xp"); @xp = @xpcor.val; @nxp = @xp.length
    @ypcor = @p.coord("yp"); @yp = @ypcor.val; @nyp = @yp.length
    @zcor = @p.coord("z"); @z = @zcor.val; @nz = @z.length
    @zicor = @et2moc.coord("zi"); @zi = @zicor.val; @nzi = @zi.length
    @tcor = @p.coord("time"); @t = @tcor.val; @nt = @t.length
    @tmcor = @et2moc.coord("time_monitor"); @tm = @tmcor.val; @ntm = @tm.length
  end # def init_coord

  # 2015-09-04
  # ToDo
  #   - use iterater
  #   - sum up peoc for 3 or more layer model
  def init_teocavg
    total_ke = @keocavg.cut( "z"=>@z[0] )
    for k in 1..@nz-1
      total_ke = total_ke + @keocavg.cut( "z"=>@z[k])
    end
    @teocavg = ( @peocavg + total_ke ).chg_gphys_k247( \
                  {"name"=>"teocavg", "long_name"=>"Averaged total energy"})
  end # def init_teocavg

  # 2015-09-09
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
    @dname = conv_cname_to_dname( cname ) # !CAUTION!
  end
    def conv_cname_to_dname( cname )
      return self.class.prep_set_filenames( cname )["dname"]
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
  out_fu.close
=begin
    ocpo_nf = dpath + "ocpo.nc"
    monit_nf = dpath + "monit.nc"
    inpara_nf = dpath + "input_parameters.m"
  if ( File.exist?(ocpo_nf) ) && ( ! File.exist?(out_nf) ) then
    puts "Create #{out_nf}"
    out_fu = NetCDF.create( out_nf )
    vnames = GPhys::IO.var_names( ocpo_nf )
    if (vnames.include?('p') == true) 
      gp_p = GPhys::IO.open( ocpo_nf, 'p')
        apts = gp_p.get_axes_parts_k247()
        self.prep_modify_grid( apts )
        self.prep_check_size( apts ) # 2015-09-11 add
        pgrid_new = gp_p.restore_grid_k247( apts )
        gp_p2 = GPhys.new( pgrid_new, gp_p.data)
         
      # 2015-09-11: change for huge data
        #GPhys::NetCDF_IO.write( out_fu, gp_p2 )
        GPhys::NetCDF_IO.each_along_dims_write( gp_p2, out_fu, -1) \
          do |sub| [sub] end
    else
      exit_with_msg("#{ocpo_nf} does not have p!")
    end # if (vnames.include?('p') == true) 
      self.prep_write_monit( { "out_fu"=>out_fu, "monit_fn"=>monit_nf } ) 
      out_fu.put_att("original", ocpo_nf)
      self.prep_write_inpara( { "out_fu"=>out_fu, "ocpo_fn"=>ocpo_nf, \
                                "inpara_fn"=>inpara_nf} )
    out_fu.close
=end
  puts "end of unite outdata files"
  return true # temporary for test
end # def self.prep_unify_outdata



def self.prep_write_monit( out_fu, hash_monit )
  hash_monit.each_value do |item|
    GPhys::NetCDF_IO.write( out_fu, item )
  end
  return true
end



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
end # def self.prep_set_filenames( cname )

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



# read & modify ocpo.nc
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
        purint msg if current_size >= size_criterion
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
      return gp_p.restore_grid_k247( modified )
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



# read & modify monit.nc
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
      if gp_monv_org.name == "et2moc"
        return gp_monv_org.chg_varray_k247( {"units"=>"m2"} )
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



# read & modify input_parameters.m
  def self.prep_get_params( dpath )
    para_lines = self.prep_read_input_params( dpath )
    self.prep_params_del_comments( para_lines )
    return self.prep_params_get_wrap( para_lines )
  end

    def self.prep_params_get_wrap( lines )
      pno = self.prep_params_get_nodim( lines )
      pz  = self.prep_params_get_z    ( lines )
      pzi = self.prep_params_get_zi   ( lines )
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
#if $0 == __FILE__ then
# move test code to test_qgcm_k247.rb
#end # if $0 == __FILE__ then
