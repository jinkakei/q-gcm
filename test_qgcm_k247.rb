# ambivalence: merge original file?



require 'minitest/autorun'
require '~/lib_k247/minitest_unit_k247'

require_relative 'qgcm_k247.rb'


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
    @dpath = "./outdata_#{@cname}/"
    system("mkdir #{@dpath}")
    ["ocpo.nc", "monit.nc", "input_parameters.m"].each do |fname|
      system("touch #{@dpath+fname}")
    end
  end

  def teardown
    system("rm #{@goal_fname}")
    system("rm -f #{@dpath}*")
    system("rmdir #{@dpath}")
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

  def test_dpath_has_elements
    assert K247_qgcm_data.prep_dpath_has_elements?( @dpath )
    refute K247_qgcm_data.prep_dpath_has_elements?( "./nil_path/" )
  end
#here
  def test_set_unified_fname_with_check
    assert K247_qgcm_data.prep_unified_file_exist?
  end
=begin
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








