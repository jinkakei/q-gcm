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
  # pseudo test
  def test_prep_read_monit_all
    K247_qgcm_data.prep_read_monit_all( @dpath_dummy )
  end
#here
=begin
  def test_prep_modify_monit_grid
    axes_parts = GPhys::IO.open( @monit_path, 'ddtpeoc' )
    K247_qgcm_data.prep_modify_monit_grid( gp_monv )
  end
    #gp_po = GPhys::IO.open( @dpath_dummy + "ocpo.nc", 'p' )
=end
end # Test_K247_qgcm_prep

=begin
class Test_K247_qgcm_data < MiniTest::Unit::TestCase
  def test_testmode
    obj = K247_qgcm_data.new("__testmode__")
    assert obj.is_testmode?
  end
end # Test_K247_qgcm_data
=end



