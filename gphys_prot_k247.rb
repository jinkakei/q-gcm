# load libraries
require_relative "lib_k247_for_qgcm"

# 2015-10-16
# ToDo
#   - set Grid
#   - restore GPhys
#   - setup GPhys and NetCDF write
#   - 
#   - 
class GPhys_Proto_K247
  attr_reader :na, :attr, :name
  
  def initialize( nary=nil, attr=nil, name=nil )
    if nary == nil
      @na    = NArray.sfloat(1)
    else
      @na    = conv_narray( nary )
    end
    if attr == nil
      @attr  = {}
    else
      @attr  = chk_hash( attr )
    end
    if name == nil
      @name  = "unknown"
    else
      @name  = chk_string( name )
    end

    #@grid
  end

    def conv_narray( var )
      return var if var.class == NArray or var.class == NArrayMiss
      return NArray.to_na( var ) if var.class == Array
      if var.class == Float or var.class == Fixnum
        ary = [ var ]
        return NArray.to_na( ary )
      end
      return false
    end

    def chk_hash( attr )
      if attr.class == Hash
        return attr 
      else
        return false
      end
    end

    def chk_name( name )
      if name.class == String
        return name
      else
        return false
      end
    end

  def chg_na( na_new )
    @na = na_new
  end

  def show
    puts @na.inspect
    puts @attr.inspect
    puts @name.inspect
  end
end



if $0 == __FILE__ then
require 'minitest/autorun'

class Test_GPhys_Proto_K246 < MiniTest::Unit::TestCase
  def setup
  #  @obj = GPhys_Proto_K247.new( NArray.sfloat(1).indgen )
    @obj = GPhys_Proto_K247.new
  end

  def teardown
    #
  end

  def test_init_na
    assert_equal NArray, @obj.na.class
  end

  def test_init_attr
    assert_equal Hash, @obj.attr.class
  end

  def test_init_name
    assert_equal String, @obj.name.class
  end

  def test_conv_narraya
    na = NArray.sfloat(1)
    obj = GPhys_Proto_K247.new( na )
    assert_equal NArray, obj.na.class
  end

  def test_conv_narrayb
    obj = GPhys_Proto_K247.new( 1.0 )
    assert_equal NArray, obj.na.class
  end

  def test_conv_narrayc
    obj = GPhys_Proto_K247.new( 1 )
    assert_equal NArray, obj.na.class
  end

  def test_conv_narrayd
    na_miss = NArrayMiss.sfloat( 1 )
    obj = GPhys_Proto_K247.new( na_miss )
    assert_equal NArrayMiss, obj.na.class
  end

  def test_conv_narraye
    refute @obj.conv_narray( "str" )
  end

  def test_conv_narrayf
    obj = GPhys_Proto_K247.new( "str" )
    refute obj.na
  end

  def test_chk_hash    
    assert_equal Hash, ( @obj.chk_hash( {"units"=>"m.s-1"} ) ).class
  end

  def test_chk_hashb    
    refute @obj.chk_hash( "test" )
  end

  def test_chk_name
    assert_equal String, ( @obj.chk_name( "test" ) ).class
  end

  def test_chk_nameb
    refute @obj.chk_name( 1 )
  end
=begin
=end
end
end # if $0 == __FILE__ then
