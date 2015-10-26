require 'minitest/autorun'
require_relative 'qgcm_k247.rb'
require_relative "lib_qgcm_k247"
include K247_qgcm_common

class K247_qgcm_preprocess
# 2015-10-26: separate from K247_qgcm_data ( qgcm_k247.rb )
  attr_reader :cname, :gcname, :dpath, :p_fpath

# basic methods
def false_with_msg( msg )
  puts msg
  return false
end

## - class methods for preparation ( unify outdata_*/* )
##  contents@2015-09-02
##   - unify_outdata( cname )
##   - set_filename( cname )
##     --  set_greater_cname( arg=nil)
##   - write_monit( input )
##   - write_inpara( input )
##     -- read_inpara( input )
##   - modify_grid( apts )

  def initialize( cname )
    @cname = cname
  # setup
    cd_qgcm_work
    init_settings
  end

  def init_settings
    set_dpath
    set_greater_cname
    set_para_fpath
  end

  def set_para_fpath
    @p_fpath = @dpath + "parameters_#{@gcname}_#{@cname}.nc"
  end

  def exist?
    return true
  end

# ToDo: 
    # treat large datasize
    # kill out_flag
  #
  # argument: cname -- casename ( String, donot include "_" )
  # action  : read outdata_YY/??? & write outdata_YY/qgcm_XX_YY_out.nc
  # return  : none
  def unify_outdata( cname=nil )
    puts "beginning of unite outdata files"
  
    false_with_msg("input case name") if cname==nil
    dpath     = set_dpath_with_check( cname )
    out_nf    = set_unified_fpath_with_check( cname )
      gp_ocpo    = get_updated_po( dpath )
      hash_monit = read_monit_all( dpath )
      hash_para  = get_params( dpath ) 
    out_fu = NetCDF.create( out_nf )
      GPhys::NetCDF_IO.write(       out_fu, gp_ocpo )
      write_para(  dpath, out_fu, hash_para  )
      write_monit(        out_fu, hash_monit )
      write_misc(         out_fu, cname  )
    out_fu.close
  
    puts "end of unite outdata files"
    return true # temporary for test
  end # def unify_outdata
  
  
  
  ## prepare
    def set_dpath
      @dpath = "./outdata_#{@cname}/"
    end
  
    def set_dpath_with_check( cname )
       set_dpath( cname )
       if dpath_has_elements?( dpath )
         return true
       else
         return false
       end
    end
  
    def dpath_has_elements?( dpath )
      ofpaths = set_original_fpaths( dpath )
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
      
    def set_original_fpaths( dpath )
      fnames = ["ocpo.nc", "monit.nc", "input_parameters.m"]
      fpaths = []
      fnames.each do | fn |
        fpaths.push( dpath + fn )
      end
      return fpaths
    end
  
  
  def set_unified_fpath_with_check( cname )
    fpath = set_unified_fpath( cname )
    if File.exist?( fpath )
      false_with_msg( "outfile: #{fpath} is already exist")
    else
      return fpath
    end
  end

  def set_unified_fpath( cname )
    dpath = set_dpath( cname )
    gcname = set_greater_cname
    return "#{dpath}q-gcm_#{gcname}_#{cname}_out.nc"
  end
  
    def set_greater_cname
    # ver. 2015-10-06: use ./Goal__*__.txt
      goal_file = Dir::glob("./Goal__*__.txt")
      if goal_file.length > 1
        p goal_file
        false_with_msg("Test Goal must be one and only")
      end
      false_with_msg("Goal__*__.txt is not exist") if goal_file[0] == nil
      @gcname = goal_file[0].split("__")[1]
    end
  
  
  
  ## write monit
  def write_monit( out_fu, hash_monit )
    hash_monit.each_value do |item|
      GPhys::NetCDF_IO.write( out_fu, item )
    end
    return true
  end
  
  
  # write misc
  def write_misc( out_fu, cname )
    gcname = set_greater_cname
    out_fu.put_att( "cname" ,  cname )
    out_fu.put_att( "gcname", gcname )
  end
  
  
  
  # write parameters
  def write_para( dpath, out_fu, hash_para )
    write_para_nodim(     out_fu, hash_para )
    write_para_z(  dpath, out_fu, hash_para )
    write_para_zi( dpath, out_fu, hash_para )
    return true # temporary
  end
  
    def write_para_zi( dpath, out_fu, p_hash )
      vname      = params_get_vname( "zi" )
      unit       = params_get_units( "zi" )
      grid       = GPhys::IO.open( dpath + "ocpo.nc", 'zi').grid_copy
      val        = p_hash["val"]
      comment    = p_hash["comment"]
      vname.each do |vn|
        attr_tmp = {"units"=>unit[vn], "long_name"=>comment[vn]}
        nary     = conv_ary_str_to_nary( val[vn] )
        gp_tmp   = GPhys.new( grid, VArray.new( nary, attr_tmp, vn) )
        GPhys::NetCDF_IO.write( out_fu, gp_tmp )
      end
    end
  
    def write_para_z( dpath, out_fu, p_hash )
      vname      = params_get_vname( "z" )
      unit       = params_get_units( "z" )
      val        = p_hash["val"]
      comment    = p_hash["comment"]
      grid       = GPhys::IO.open( dpath + "ocpo.nc", 'z').grid_copy
      vname.each do |vn|
        attr_tmp = {"units"=>unit[vn], "long_name"=>comment[vn]}
        nary     = conv_ary_str_to_nary( val[vn] )
        gp_tmp   = GPhys.new( grid, VArray.new( nary, attr_tmp, vn) )
        GPhys::NetCDF_IO.write( out_fu, gp_tmp )
      end
    end
  
      def conv_ary_str_to_nary( ary )
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
  
    def write_para_nodim( out_fu, p_hash )
      vname_no = params_get_vname( "nodim" )
      unit = params_get_units( "nodim" )
      val = p_hash["val"]
      comment = p_hash["comment"]
      vname_no.each do |vn|
        out_fu.put_att( vn, "#{val[vn]}:#{unit[vn]}:#{comment[vn]}")
      end
    end
  
    def params_get_units( type )
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
    def get_updated_po( dpath )
      fpath = dpath + "ocpo.nc"
      check_ocpo( fpath )
      gp_po = GPhys::IO.open( fpath, 'p')
      new_grid = modify_po_grid( gp_po )
      return GPhys.new( new_grid, gp_po.data)
    end
  
      def check_ocpo( fpath )
        #GPhys::IO.is_a_NetCDF?( fpath ) # NoMethod?
        exit_if_ocpo_lack_po( fpath )
        check_po_size( fpath )
      end
  
        def exit_if_ocpo_lack_po( fpath )
          unless ocpo_has_po?( fpath )
            false_with_msg("#{fpath} does not include p") 
          end
        end
  
          def ocpo_has_po?( fpath )
            return GPhys::IO.var_names( fpath ).include?("p")
          end
        
        def check_po_size( fpath )
          size_criterion = 960 * 960 * 2 * 36
          current_size = calc_po_size( fpath )
          msg = "\n\n  INFO: Writing Huge Data ( please wait)\n\n"
          print msg if current_size >= size_criterion
        end
  
          def calc_po_size( fpath )
            gp_po = GPhys::IO.open( fpath, 'p')
            nxp   = gp_po.coord("xp"  ).val.length
            nyp   = gp_po.coord("yp"  ).val.length
            nz    = gp_po.coord("z"   ).val.length
            ntime = gp_po.coord("time").val.length
            return nxp*nyp*nz*ntime
          end
  
      # 2015-10-20: tmp
      def modify_po_grid_tmp( gp_po )
        origin = gp_po.get_axes_parts_k247
        modified = origin.clone
        puts "  ocpo.nc@p: replace X,Y Axis ( 0 at center)"
          modified['xp']   = modify_po_xy( origin['xp'] )
          modified['yp']   = modify_po_xy( origin['yp'] )
        return gp_po.restore_grid_k247( modified )
      end # def modify_grid( apts )
  
      # argument: gp_po -- gphys object of ocpo.nc@p (*) 
      #                    (*) q-gcm/src/outdata_*/ocpo.nc@p
      def modify_po_grid( gp_po )
        origin = gp_po.get_axes_parts_k247
        modified = origin.clone
        puts "  ocpo.nc@p: replace X,Y Axis ( 0 at center)"
        puts "  ocpo.nc@p: convert unit of TIME Axis to [days]"
          modified['xp']   = modify_po_xy( origin['xp'] )
          modified['yp']   = modify_po_xy( origin['yp'] )
          modified['time'] = modify_po_time( origin['time'] )
        return gp_po.restore_grid_k247( modified )
      end # def modify_grid( apts )
        
        def modify_po_xy( xy_hash )
          n = xy_hash['val'].length
          d = xy_hash['val'][1] - xy_hash['val'][0]
          xy_hash['val'] -= d * ( n - 1 ).to_f / 2.0
          return xy_hash
        end
      
        def modify_po_time( time_hash )
          time_hash['val'] *= 365.0
          time_hash['atts']['units'] = 'days'
          return time_hash
        end
  
  
  
  ## read & modify monit.nc
  def read_monit_all( dpath )
    nf_name = dpath + "monit.nc"
    monit_gp_out = {}
    (monit_get_vname).each do | v |
      monit_gp_out[ v ] = read_monit_var( nf_name, v)
    end
    return monit_gp_out
  end
  
    def monit_get_vname
      return ['ddtkeoc', 'ddtpeoc', 'emfroc', 'ermaso', \
              'et2moc' , 'etamoc' , 'kealoc', 'pkenoc']
    end
  
    def read_monit_var( nf_name, vname )
      gp_monv_org = GPhys::IO.open( nf_name, vname)
        new_grid     = modify_monit_grid( gp_monv_org )
        gp_monv_data = modify_monit_data( gp_monv_org )
      return GPhys.new( new_grid, gp_monv_data )
    end
  
      def modify_monit_data( gp_monv_org )
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
  
      def modify_monit_grid( gp_monv )
        origin   = gp_monv.get_axes_parts_k247
        modified = origin.clone
          modified["time"] = modify_monit_time( origin["time"] )
          modify_monit_z( modified )
        return gp_monv.restore_grid_k247( modified )
      end
  
        def modify_monit_time( time_hash )
          time_hash["name"]           = "time_monitor"
          time_hash["val" ]          *= 365.0
          time_hash["atts"]["units"]  = "days"
          return time_hash
        end
  
        def modify_monit_z( axes_parts )
          axes_parts["zo" ]["name"] = "z"  if axes_parts.has_key?('zo')
          axes_parts["zom"]["name"] = "zi" if axes_parts.has_key?('zom')
          ## adjust vertical axis name with ocpo.nc
        end
  
  
  
  ## read & modify input_parameters.m
    def get_params( dpath )
      para_lines = read_input_params( dpath )
      params_del_comments( para_lines )
      return params_get_wrap( para_lines )
    end
  
      def params_get_wrap( lines )
        pno = params_get_nodim( lines )
        pz  = params_get_z(     lines )
        pzi = params_get_zi(    lines )
        return params_merge_hash( pno, pz, pzi )
      end
  
        def params_merge_hash( pno, pz, pzi )
          para_hash = {}
          para_hash["name"] = pno["name"] + pz ["name"] + pzi["name"]
          [ "val", "comment" ].each do |key|
            para_hash[key] = pno[key].merge( pz[key].merge( pzi[key] ) )
          end
          return para_hash
        end
  
      def params_get_common( lines, vname )
        val = {}; com = {}
        vname.each do |v|
          idx = ary_get_include_index( lines, v )
          kn = idx.length
          if kn > 1
            ary =[]
            dummy, ary[0], com[v] = params_conv_line(lines[idx[0]])
            for k in 1..kn-1
              ary[k] = params_conv_line_z( lines[idx[k]] )
            end
            val[v] = ary
          else
            dummy, val[v], com[v] = params_conv_line(lines[idx[0]])
          end
        end
        para = {}
          para["name"]    = vname
          para["val"]     = val
          para["comment"] = com
        return para
      end
        
      def params_get_vname( type )
        return [ "gpoc", "cphsoc", "rdefoc"] if type == "zi"
        return [ "fnot", "beta", "dxo","dto", "rhooc", \
                "cpoc", "l_spl", "c1_spl"] if type == "nodim"
        return [ "ah2oc", "ah4oc", "tabsoc", "tocc", "hoc" ] if type == "z"
      end
  
      def params_get_zi( lines )
        vname_zi = params_get_vname( "zi" )
        return params_get_common( lines, vname_zi )
      end
  
      def params_get_z( lines )
        vname_z  = params_get_vname( "z" )
        return params_get_common( lines, vname_z  )
      end
  
      def params_get_nodim( lines )
        vname_no = params_get_vname( "nodim" )
        return params_get_common( lines, vname_no )
      end
  
      def params_conv_line( line )
        name, tmp1    = line.split("=")
        val , tmp2    = tmp1.split(";")
        left, comment = tmp2.split("%% ")
        return name, val, comment
      end
  
      def params_conv_line_z( line )
        tmp1 , dummy    = line.split("];")
        dummy, tmp2     = tmp1.split("= ")
        dummy, val = tmp2.split("  ")
        return val
      end
  
      def params_get_nlo( lines )
        i_nlo = 0
        lines.each_with_index do | l,n |
          i_nlo = n if l.include?("nlo")
        end
        name, nlo_str, comment = params_conv_line( lines[i_nlo] )
        return nlo_str.to_i
      end
  
      def read_input_params( dpath )
        lines = []
        fu = File.open( dpath + "input_parameters.m",'r' )
        while l = fu.gets
          lines.push( l.chomp ) 
        end
        fu.close
        return lines
      end
  
      def params_del_comments( lines )
        del_lines = [ "%%Matlab script to read in parameters", \
                      "%%Derived parameters", \
                      " ", "%%Parameters added by K247"]
        del_lines.each do |d|
          lines.delete( d  )
        end
      end
end



# for test code
if $0 == __FILE__ then
# move test code to test_qgcm_k247.rb
require 'minitest/autorun'
require_relative "lib_qgcm_k247"

class Test_K247_qgcm_preprocess < MiniTest::Unit::TestCase
  def setup
    @cname = "test"
    @obj = K247_qgcm_preprocess.new( @cname )
    cd_testdir
    @gcname = "test"
    @goal_fname = "Goal__#{@gcname}__.txt"
    system("touch #{@goal_fname}")
  # ToDo: What should be the format of data?
    @dpath_empty = "./outdata_#{@cname}/"
    system("mkdir #{@dpath_empty}")
    ["ocpo.nc", "monit.nc", "input_parameters.m"].each do |fname|
      system("touch #{@dpath_empty+fname}")
    end
#  # Dir has some data
#    # ToDo: must rename @ 2015-10-07
#    @dpath_dummy = "./log/test_qgcm_k247/"
#      @ocpo_path  = @dpath_dummy + "ocpo.nc"
#      @monit_path = @dpath_dummy + "monit.nc"
    @obj.init_settings
  end

    def cd_testdir
      Dir::chdir( QGCM_HOME_PATH + "testdir" )
    end

  def teardown
    system("rm #{@goal_fname}")
    system("rm -f #{@dpath_empty}*")
    system("rmdir #{@dpath_empty}")
  end

  def test_instance_defined
    assert @obj.exist?
  end

  def test_init_position
    qg_workdir = "/LARGE0/gr10056/t51063/q-gcm/work"
    # for KUDPC
    ins = K247_qgcm_preprocess.new( "tmp" )
    assert_equal qg_workdir, Dir::pwd
    cd_testdir # for teardown
  end

  def test_set_dpath
    assert_equal "./outdata_#{@cname}/", @obj.dpath
  end

  def test_set_greater_cname
  #  @obj.set_greater_cname
    assert_equal @gcname, @obj.gcname
  end

  def test_set_para_fpath
    answer = "./outdata_#{@cname}/parameters_#{@gcname}_#{@cname}.nc"
    assert_equal answer, @obj.p_fpath
  end

=begin
  def test_dpath_has_elements_true
    assert @obj.prep_dpath_has_elements?( @dpath_empty )
  end

  def test_dpath_has_elements_false
    refute @obj.prep_dpath_has_elements?( "./nil_path/" )
  end

  def test_prep_ocpo_has_po?
    assert @obj.prep_ocpo_has_po?( @dpath_dummy + "ocpo.nc" )
  end

  def test_prep_calc_po_size
    assert_equal 961*961*2*2, @obj.prep_calc_po_size( @dpath_dummy + "ocpo.nc" )
  end
  
  def test_prep_modify_po_xy
    axes_parts = GPhys::IO.open( @ocpo_path, 'p' ).get_axes_parts_k247
    upd_xy = @obj.prep_modify_po_xy( axes_parts['xp'] )
    assert_equal 0, ( upd_xy['val'][0] + upd_xy['val'][-1])
  end

  def test_prep_modify_po_time
    axes_parts = GPhys::IO.open( @ocpo_path, 'p' ).get_axes_parts_k247
    upd_time = @obj.prep_modify_po_time( axes_parts['time'] )
    assert_equal "days", upd_time['atts']['units']
  end

  #def test_prep_read_monit_all
  #  p @obj.prep_read_monit_all( @dpath_dummy )
  #end

  def test_prep_read_input_params
    lines = @obj.prep_read_input_params( @dpath_dummy )
    assert_equal 114, lines.length, "check when change input_parmeters.m"
  end

  def test_prep_params_del_comments
    lines = @obj.prep_read_input_params( @dpath_dummy )
    @obj.prep_params_del_comments( lines )
    assert_equal 110, lines.length
  end

  def params_get_nlo
    lines = @obj.prep_read_input_params( @dpath_dummy )
    assert_equal 2, @obj.prep_params_get_nlo( lines )
      # fail when nlo is change
  end

  def test_prep_params_get_nodim
    lines    = @obj.prep_read_input_params( @dpath_dummy )
    pno_hash = @obj.prep_params_get_nodim ( lines )
    #  p pno_hash
    assert_equal 8, pno_hash["name"].length
  end

  def test_prep_params_get_z
    lines = @obj.prep_read_input_params( @dpath_dummy )
    pz_hash = @obj.prep_params_get_z( lines )
    #  p pz_hash
    assert_equal 5, pz_hash["name"].length
  end

  def test_prep_params_get_zi
    lines    = @obj.prep_read_input_params( @dpath_dummy )
    pzi_hash = @obj.prep_params_get_zi( lines )
    #  p pzi_hash
    assert_equal 3, pzi_hash["name"].length
  end

  def test_prep_params_get_wrap
    lines    = @obj.prep_read_input_params( @dpath_dummy )
    para_hash = @obj.prep_params_get_wrap( lines )
    #  p para_hash
    assert_equal 16, para_hash["name"].length
  end
  
  def test_prep_params_conv_line_z
    line = "ah4oc= [ah4oc   0.00000E+00]; %% Layers 2,n"
    val = @obj.prep_params_conv_line_z( line )
    assert_equal " 0.00000E+00", val
  end

  def test_prep_get_params
    para_hash = @obj.prep_get_params( @dpath_dummy )
    assert_equal 16, para_hash["name"].length
  end

  def test_prep_write_para
    out_fu = NetCDF.create( @dpath_dummy + "qgcm_para.nc" )
    p_hash = @obj.prep_get_params( @dpath_dummy )
    ret    = @obj.prep_write_para( @dpath_dummy, out_fu, p_hash )
    out_fu.close
    assert ret
  end

  def test_prep_write_monit
    out_fu = NetCDF.create( @dpath_dummy + "qgcm_monit.nc" )
    m_hash = @obj.prep_read_monit_all( @dpath_dummy )
    ret    = @obj.prep_write_monit( out_fu, m_hash )
    out_fu.close
    assert ret
  end
# not member of qgcm
  def test_get_include
    ary = ["ab", "acx", "ad"]
    ret = ary.find do | item | item.include?("c") end
    assert_equal "acx", ret
  end
  def test_ary_get_include_index_single
    ary = ["ab", "acx", "ad"]
    idx = ary_get_include_index( ary, "c" )
    assert_equal 1, idx[0]
  end
  def test_ary_get_include_index_double
    ary = ["ab", "acx", "ad", "ca"]
    idx = ary_get_include_index( ary, "c" )
    assert_equal [1,3], idx
  end
=end
end # Test_K247_qgcm_prep


end # if $0 == __FILE__ then


