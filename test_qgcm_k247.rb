require 'minitest/autorun'
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
    @dpath_empty = "./outdata_#{@cname}/"
    system("mkdir #{@dpath_empty}")
    ["ocpo.nc", "monit.nc", "input_parameters.m"].each do |fname|
      system("touch #{@dpath_empty+fname}")
    end
  # Dir has some data
    # ToDo: must rename @ 2015-10-07
    @dpath_dummy = "./log/test_qgcm_k247/"
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

  def test_dpath_has_elements
    assert K247_qgcm_data.prep_dpath_has_elements?( @dpath_empty )
    refute K247_qgcm_data.prep_dpath_has_elements?( "./nil_path/" )
  end

#here
  def test_prep_ocpo_has_po?
    assert K247_qgcm_data.prep_ocpo_has_po?( @dpath_dummy + "ocpo.nc" )
  end
  def test_prep_calc_po_size
    assert_equal 961*961*2*2, K247_qgcm_data.prep_calc_po_size( @dpath_dummy + "ocpo.nc" )
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




# from ~/lib_k247/minitest_unit_k247.rb
require "minitest/unit"
# Add Colored Anounce@ 2015-10-03
module MiniTest
  class Unit
    alias :status_orginal :status

    def status
      status_orginal
      stat_color_k247
      puts_encourages
    end

      def stat_color_k247
        puts_failures
        puts_errors
        puts_skips
        puts_assertion_count
      end
        # ToDo: refactoring
        def puts_failures
          f = failures
          puts_color( "\e[1mFailure(#{f}): #{putstar(f)} " , "red") if f  > 0
        end
        def puts_errors
          e = errors
          puts_color( "\e[1mError(#{e}): #{putstar(e)} " , "red") if e  > 0
        end
        def puts_skips
          s = skips
          puts_color( "\e[1mSkip(#{s}): #{putstar(s)} " , "yellow") if s  > 0
        end
        def puts_assertion_count
          a = assertion_count
          puts_color( "\e[1mAssert(#{a}): #{putstar(a)} " , "green") if a  > 0
        end
        def puts_encourages
          puts
          puts "\e[1mMistake is the Key to Success, Go Forward!\e[0m" if ( failures + errors ) > 0
          puts_color("\e[1mSystem All Green!!", "green")  if (failures + errors) == 0
          puts_color("\e[1mPerfect!!!", "blue") if (failures + errors + skips) == 0
        end
        
        def putstar( num )
          return "*" * num
        end

        # 2015-10-01: http://qiita.com/khotta/items/9233a9ffeae68b58d84f
        def puts_color( msg, color=nil )
          color_set( color ); puts msg; color_end
        end
        def color_set( color=nil )
          case color
            when "red"
              print "\e[31m"
            when "green"
              print "\e[32m"
            when "yellow"
              print "\e[33m"
            when "blue"
              print "\e[34m"
            when nil
              print "please set color\n"
            else
              print "sorry, the color is not yet implemented\n"
          end
        end
        def color_end
          print "\e[0m"
        end

  end
end
