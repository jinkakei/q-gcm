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
  # arg == nil
    @na    = NArray.sfloat(1)
    @attr  = {}
    @name  = "undefined"
  # arg != nil
    @na    = chk_narray( nary ) unless nary == nil
    @attr  = chk_hash(   attr ) unless attr == nil
    @name  = chk_name(   name ) unless name == nil

    #@grid
=begin
    if nary == nil
      @na    = NArray.sfloat(1)
    else
      @na    = chk_narray( nary )
    end
    if attr == nil
      @attr  = {}
    else
      @attr  = chk_hash( attr )
    end
    if name == nil
      @name  = "unknown"
    else
      @name  = chk_name( name )
    end
=end
  end

    def chk_narray( var )
      return var if var.class == NArray or var.class == NArrayMiss
      return NArray.to_na( var ) if var.class == Array
      if var.class == Float or var.class == Fixnum
        ary = [ var ]
        return NArray.to_na( ary )
      end
      puts "chk_narray: value must be NArray, NArrayMiss,"
      puts "                          Array, Float, Fixnum."
      return false
    end

    def chk_hash( attr )
      if attr.class == Hash
        return attr 
      else
        puts "chk_attr: attr must be hash"
        return false
      end
    end

    def chk_name( name )
      if name.class == String
        return name
      else
        puts "chk_name: name must be string"
        return false
      end
    end

  def chg_na( na_new )
    @na = chk_narray( na_new ) 
  end

  def chg_attr( attr_new )
    @attr = chk_hash( attr_new ) 
  end

  def add_attr( attr_add )
    if attr_add.class == Hash
      attr_add.each do |key,val|
        if val.class == String
          @attr[key] = val
        else
          @attr[key] = [ val ]
        end
      end
    else
      puts "add_attr: argument must be hash."
      return false
    end
  end

  def chg_name( name_new )
    @name = chk_name( name_new ) 
  end

  def show
    puts @na.inspect
    puts @attr.inspect
    puts @name.inspect
  end

  def make_varray
    return VArray.new( @na, @attr, @name )
  end
end



if $0 == __FILE__ then
require 'minitest/autorun'

class Test_GPhys_Proto_K247 < MiniTest::Unit::TestCase
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

  def test_chk_narraya
    na = NArray.sfloat(1)
    obj = GPhys_Proto_K247.new( na )
    assert_equal NArray, obj.na.class
  end

    def test_chk_narrayb
      obj = GPhys_Proto_K247.new( 1.0 )
      assert_equal NArray, obj.na.class
    end
  
    def test_chk_narrayc
      obj = GPhys_Proto_K247.new( 1 )
      assert_equal NArray, obj.na.class
    end
  
    def test_chk_narrayd
      na_miss = NArrayMiss.sfloat( 1 )
      obj = GPhys_Proto_K247.new( na_miss )
      assert_equal NArrayMiss, obj.na.class
    end
  
    def test_chk_narraye
      refute @obj.chk_narray( "str" )
    end
  
    def test_chk_narrayf
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

  def test_add_attr
    @obj.add_attr( {"test"=>"tmp"} )
    assert_equal "tmp", @obj.attr["test"]
  end

    def test_add_attrb
      @obj.add_attr( {"test"=>1.0} )
      assert_equal [ 1.0 ], @obj.attr["test"]
    end

  def test_chg_na
    @obj.chg_na( 1.0 )
    na1 = NArray.to_na( [1.0] )
    assert_equal na1, @obj.na
  end

  def test_chg_attr
    hash_new = {"long_name"=>"test_test"}
    @obj.chg_attr( hash_new )
    assert_equal hash_new, @obj.attr
  end

  def test_chg_name
    name_new = "test"
    @obj.chg_name( name_new )
    assert_equal name_new, @obj.name
  end

  def test_make_varray
    assert_equal VArray, ( @obj.make_varray  ).class
  end

=begin
    def test_make_varrayb
      @obj.chg_na( 1.0 )
      va = @obj.make_varray
      puts va.inspect
    end
=end
=begin
=end
end
end # if $0 == __FILE__ then
