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
  gp_ocpo   = self.prep_get_updated_po( dpath )
#here
  monit_gps = self.prep_read_monit_all( dpath )
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
        puts "  #{f} exist"
      else
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

#
#
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


# here
def self.prep_read_monit_all( dpath )
  nf_name = dpath + "monit.nc"
  monit_vname_out = [ \
    'ddtkeoc', 'ddtpeoc', 'emfroc', 'ermaso', \
    'et2moc' , 'etamoc' , 'kealoc', 'pkenoc']
  monit_gp_out = {}

  monit_vname_out.each do | v |
    monit_gp_out[ v ] = self.prep_read_monit_var( nf_name, v)
  end

  return monit_gp_out
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


# 2015-08-30
# ToDo
#   - too long!
#
#   wrapper of K247_qgcm_read_inpara
#   arguments: out_fu:    outfile unit
#              inpara_fn: filename of input paramters
#              ocpo_fn:   filename of ocpo
def self.prep_write_inpara( input )
  out_fu = input["out_fu"]
  inpara_fn = input["inpara_fn"]
  i_hash = self.prep_read_inpara( { "inp_fn"=>inpara_fn} )
    i_val = i_hash["val"]; i_com = i_hash["comment"]
    i_okeyno = i_hash["out_keyno"]; i_okeyzi = i_hash["out_keyzi"]
    i_okeyz  = i_hash["out_keyz"]
    i_okey   = i_okeyno[0..-1] + i_okeyzi[0..-1] + i_okeyz[0..-1]
    i_ounit = i_hash["out_units"]
  
  ocpo_fn = input["ocpo_fn"] 
  grid_z = GPhys::IO.open( ocpo_fn, 'z').grid_copy
  grid_zi = GPhys::IO.open( ocpo_fn, 'zi').grid_copy
  
  i_okey.each do | oky |
    if i_okeyz.include?(oky) || i_okeyzi.include?(oky)
      attr_tmp = {"units"=>i_ounit[oky], "long_name"=>i_com[oky]}
      gp_tmp = GPhys.new( grid_zi, VArray.new( i_val[oky], attr_tmp, oky ) ) if i_okeyzi.include?(oky)
      gp_tmp = GPhys.new( grid_z, VArray.new( i_val[oky], attr_tmp, oky ) ) if i_okeyz.include?(oky)
      GPhys::NetCDF_IO.write( out_fu, gp_tmp )
    else
      out_fu.put_att(oky, i_val[oky].to_s  + ":" \
                    + i_ounit[oky] + ":" + i_com[oky] )
    end # if i_okeyz.include?(oky) || i_okeyzi.include?(oky)
  end # i_okey.each do | oky |
  
end # def self.prep_write_inpara( input )


  # Convert English for KUDPC
  # 2015-07-25 -- Create
  #   read input_parameters.m for unify qgcm outdata
  # 2015-08-24 -- edit
  #  Comment: layered parameters are difficult to read.
  #
  # ToDo: sophisticate (too long, over 100 lines)
  #
  # argument: input -- hash ( filename )
  # return  : inp_hash{ "vname" => val}, inp_com = {"vname" => "comment"
  #                     etc.. (for prep_write_inpara) }
  def self.prep_read_inpara( input )

    print "\n\n\n  #{self}.prep_read_inpara \n"
    print "  !!WARNING!! too long and complicate to improve!!\n\n\n"
    
    inp_fn = input[ "inp_fn" ]
    inp_fu = open( inp_fn, "r")
      lnum = 0; inp_txt = Array.new; inp_txt2 = Array.new
      cini = 0; clen = 1 
      while line = inp_fu.gets
        if ( line[cini,clen] =~ /[a-z]/) # first 1 character is alphabet
          inp_txt[lnum],tmp = line.split(";")
          tmp2, inp_txt2[lnum] = tmp.split("%% ")
          lnum += 1
        end
      end
    inp_fu.close

    inp_val = { "readme"=> "This hash is values of input_parameters.m"}
    inp_com = { "readme"=> "This hash is comments of input_parameters.m"}
      flag_bgn = 1; flag_end = 7
      for n in flag_bgn..flag_end
        vname, val = inp_txt[n].split(" =")
        inp_val.store( vname, val.to_i )
        inp_com.store( vname, inp_txt2[n].chomp )
      end
      para_bgn = 8
        vname_z = [ "zopt", "gpoc", "ah2oc", "ah4oc", "tabsoc", \
              "tocc", "hoc", "gpat", "ah4at", "tabsat", \
              "tat", "hat", "cphsoc", "rdefoc", "cphsat", \
              "rdefat", "aface"]
          flg_z = { "tmp"=>0}
        vname_nlo = [ "ah2oc", "ah4oc", "tabsoc", "tocc", "hoc",  ]
          flg_nlo = { "tmp"=>0}
        vname_nlo0 = [ "gpoc", "cphsoc", "rdefoc"]
          flg_nlo0 = { "tmp"=>0}
        vname_nla = [ "zopt", "ah4at", "tabsat", "tat", "hat" ]
          flg_nla = { "tmp"=>0}
        vname_nla0 = [ "gpat", "cphsat", "rdefat", "aface" ]
          flg_nla0 = { "tmp"=>0}
      for n in para_bgn..lnum-1
        vname, val = inp_txt[n].split("=")
        case vname
        when "%%Derived parameters\n"
          # 
        when "name"
          inp_val.store( vname, val )
          inp_com.store( vname, inp_txt2[n].chomp )
        when "outfloc", "outflat" # p val # ex. " [ 1 1 1 1 1 1 1]"
          tmp, tar = val.split( "[ "); tar2, tmp = tar.split("]")
          tval_arr = tar2.split(" ") # p tval_arr # ex. ["1", "1", "0", "1", "0", "0", "0"]
          val_arr = NArray.int( tval_arr.size )
          for n2 in 0..val_arr.size-1
            val_arr[n2] = tval_arr[n2].to_i
          end
          inp_com.store( vname, inp_txt2[n].chomp )
          inp_val.store( vname, val_arr )
        when *vname_z
          if flg_z[vname] == nil then
            case vname
            when *vname_nlo
              nl = inp_val["nlo"].to_i
            when *vname_nlo0
              nl = inp_val["nlo"].to_i - 1
            when *vname_nla
              nl = inp_val["nla"].to_i
            when *vname_nla0
              nl = inp_val["nla"].to_i - 1
            else
              print "\n\n !WARNING! \n\n"
            end
            nl_arr = NArray.sfloat( nl )
            for n2 in 0..nl-1
              if n2 > 0 then
              # ex. zopt= [zopt   2.00000E+04]
              tmp,val0 = inp_txt[n+n2].split("["+vname)
              val,tmp2 = val0.split("]")
              end
              nl_arr[n2] = val.to_f
            end
            inp_val.store( vname, nl_arr )
            inp_com.store( vname, inp_txt2[n].chomp )
            flg_z.store( vname, 1)
          end
        else
          if ( inp_txt2[n] != nil) 
            inp_val.store( vname, val.to_f )
            inp_com.store( vname, inp_txt2[n].chomp )
          end
        end
      end
    
  # set output paramters (ver. 0.0.1 @2015-08-30)
    inp_okeyno = [ "fnot", "beta", "dxo","dto", "rhooc", \
                   "cpoc", "l_spl", "c1_spl"]
    inp_okeyzi = [ "gpoc", "cphsoc", "rdefoc"]
    inp_okeyz  = [ "ah2oc", "ah4oc", "tabsoc", "hoc"]
    inp_okey = inp_okeyno[0..-1] + inp_okeyzi[0..-1] + inp_okeyz[0..-1]
    inp_ounit = { "fnot"=>"s-1", "beta"=>"s-1.m-1", "dxo"=>"m", "dto"=>"s", \
                  "rhooc"=>"kg.m-3", "cpoc"=>"J.kg-1.K-1", "l_spl"=>"m", \
                  "c1_spl"=>" ", "gpoc"=>"m.s-2", "cphsoc"=>"cm.s-1", \
                  "rdefoc"=>"m", "tabsoc"=>"K", "hoc"=>"m", \
                  "ah2oc"=>"m2.s-1", "ah4oc"=>"m4.s-1"}

    inp_okey.each do | ky |
      inp_com[ky].sub!( /layer 1/, "layer n" )
      inp_com[ky].sub!( /mode 1/, "mode n" )
    end

    inp_hash = {"val"=>inp_val, "comment"=>inp_com, \
                "out_units"=>inp_ounit, \
                "out_keyno"=>inp_okeyno, "out_keyz"=>inp_okeyz, \
                "out_keyzi"=>inp_okeyzi, 
                }
    return inp_hash
  end # def self.prep_read_inpara( input )


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
