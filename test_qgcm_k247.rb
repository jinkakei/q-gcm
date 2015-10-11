require 'minitest/autorun'
require_relative 'qgcm_k247.rb'
require_relative 'lib_k247_for_qgcm.rb'


# plan
#   prep
#   init ( init __testmode__ )
#   normal ( with full initialize )
#
class Test_K247_qgcm_prep < MiniTest::Unit::TestCase
  def setup
    @cname = "test"
    @gcname = "test"
    @goal_fname = "Goal__#{@gcname}__.txt"
    system("touch #{@goal_fname}")
  # ToDo: What should be the format of data?
    @dpath_empty = "./outdata_#{@cname}/"
    system("mkdir #{@dpath_empty}")
    ["ocpo.nc", "monit.nc", "input_parameters.m"].each do |fname|
      system("touch #{@dpath_empty+fname}")
    end
  # Dir has some data
    # ToDo: must rename @ 2015-10-07
    @dpath_dummy = "./log/test_qgcm_k247/"
      @ocpo_path  = @dpath_dummy + "ocpo.nc"
      @monit_path = @dpath_dummy + "monit.nc"
  end

  def teardown
    system("rm #{@goal_fname}")
    system("rm -f #{@dpath_empty}*")
    system("rmdir #{@dpath_empty}")
  end

  def test_exist_class
    assert K247_qgcm_data.exist_class?
  end

  def test_set_dpath
    assert_equal "./outdata_#{@cname}/", \
                 K247_qgcm_data.prep_set_dpath( @cname )
  end

  def test_set_greater_cname
    gcname = K247_qgcm_data.prep_set_greater_cname
    assert_equal @gcname, gcname
  end

  def test_set_unified_fpath
    answer = "./outdata_#{@cname}/q-gcm_#{@gcname}_#{@cname}_out.nc"
    assert_equal answer, K247_qgcm_data.prep_set_unified_fpath( @cname )
  end

  def test_dpath_has_elements_true
    assert K247_qgcm_data.prep_dpath_has_elements?( @dpath_empty )
  end

  def test_dpath_has_elements_false
    refute K247_qgcm_data.prep_dpath_has_elements?( "./nil_path/" )
  end

  def test_prep_ocpo_has_po?
    assert K247_qgcm_data.prep_ocpo_has_po?( @dpath_dummy + "ocpo.nc" )
  end

  def test_prep_calc_po_size
    assert_equal 961*961*2*2, K247_qgcm_data.prep_calc_po_size( @dpath_dummy + "ocpo.nc" )
  end
  
  def test_prep_modify_po_xy
    axes_parts = GPhys::IO.open( @ocpo_path, 'p' ).get_axes_parts_k247
    upd_xy = K247_qgcm_data.prep_modify_po_xy( axes_parts['xp'] )
    assert_equal 0, ( upd_xy['val'][0] + upd_xy['val'][-1])
  end

  def test_prep_modify_po_time
    axes_parts = GPhys::IO.open( @ocpo_path, 'p' ).get_axes_parts_k247
    upd_time = K247_qgcm_data.prep_modify_po_time( axes_parts['time'] )
    assert_equal "days", upd_time['atts']['units']
  end

  #def test_prep_read_monit_all
  #  p K247_qgcm_data.prep_read_monit_all( @dpath_dummy )
  #end

  def test_prep_read_input_params
    lines = K247_qgcm_data.prep_read_input_params( @dpath_dummy )
    assert_equal 114, lines.length, "check when change input_parmeters.m"
  end
  def test_prep_params_del_comments
    lines = K247_qgcm_data.prep_read_input_params( @dpath_dummy )
    K247_qgcm_data.prep_params_del_comments( lines )
    assert_equal 110, lines.length
  end
  def self.prep_params_get_nlo
    lines = K247_qgcm_data.prep_read_input_params( @dpath_dummy )
    assert_equal 2, K247_qgcm_data.prep_params_get_nlo( lines )
      # fail when nlo is change
  end

  def test_prep_params_get_nodim
    lines    = K247_qgcm_data.prep_read_input_params( @dpath_dummy )
    pno_hash = K247_qgcm_data.prep_params_get_nodim ( lines )
    #  p pno_hash
    assert_equal 8, pno_hash["name"].length
  end

  def test_prep_params_get_z
    lines = K247_qgcm_data.prep_read_input_params( @dpath_dummy )
    pz_hash = K247_qgcm_data.prep_params_get_z( lines )
    #  p pz_hash
    assert_equal 5, pz_hash["name"].length
  end

  def test_prep_params_get_zi
    lines    = K247_qgcm_data.prep_read_input_params( @dpath_dummy )
    pzi_hash = K247_qgcm_data.prep_params_get_zi( lines )
    #  p pzi_hash
    assert_equal 3, pzi_hash["name"].length
  end

  def test_prep_params_get_wrap
    lines    = K247_qgcm_data.prep_read_input_params( @dpath_dummy )
    para_hash = K247_qgcm_data.prep_params_get_wrap( lines )
    #  p para_hash
    assert_equal 16, para_hash["name"].length
  end
  
  def test_prep_params_conv_line_z
    line = "ah4oc= [ah4oc   0.00000E+00]; %% Layers 2,n"
    val = K247_qgcm_data.prep_params_conv_line_z( line )
    assert_equal " 0.00000E+00", val
  end

  def test_prep_get_params
    para_hash = K247_qgcm_data.prep_get_params( @dpath_dummy )
    assert_equal 16, para_hash["name"].length
  end
#here
  def test_prep_write_para
    out_fu = NetCDF.create( "./tmp_qgcm.nc")
    p_hash = K247_qgcm_data.prep_get_params( @dpath_dummy )
    K247_qgcm_data.prep_write_para_nodim( out_fu, p_hash )
    out_fu.close
  end
=begin
=end
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
end # Test_K247_qgcm_prep

=begin
class Test_K247_qgcm_data < MiniTest::Unit::TestCase
  def test_testmode
    obj = K247_qgcm_data.new("__testmode__")
    assert obj.is_testmode?
  end
end # Test_K247_qgcm_data
=end



