# load libraries
require "numru/gphys"
include NumRu

# 2015-10-16
# ToDo
#   - restore VArray
#   - 
#   - 
class VArray_Proto_K247
  attr_reader :nary, :attr, :name
  attr_reader :grid
  
  def initialize( nary=nil, attr=nil, name=nil, grid=nil )
  # arguments == nil
    @nary  = NArray.sfloat(1)
    @attr  = {"units"=>"none"}
    @name  = "undefined"
    @grid  = nil
  # arguments != nil
    @nary  = chk_narray( nary ) unless nary == nil
    @attr  = chk_hash(   attr ) unless attr == nil
    @name  = chk_name(   name ) unless name == nil
    @grid  = chk_grid(   grid ) unless grid == nil

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

    def chk_grid( grid )
      if grid.class == Grid
        return grid
      else
        puts "chk_grid: grid must be Grid class"
        return false
      end
    end

  def chg_nary( na_new )
    @nary = chk_narray( na_new ) 
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

  def set_units( unit )
    if unit.class == String
      @attr["units"] = unit
    else
      puts "set_units: unit must be String"
      return false
    end
  end

  def set_long_name( lname )
    if lname.class == String
      @attr["long_name"] = lname
    else
      puts "set_long_name: long_name must be String"
      return false
    end
  end

  def chg_name( name_new )
    @name = chk_name( name_new ) 
  end

  def show
    puts @nary.inspect
    puts @attr.inspect
    puts @name.inspect
  end

  def val
    @nary
  end

  def get_varray
    return VArray.new( @nary, @attr, @name )
  end

  def get_grid
    return Grid.new( Axis.new.set_pos( get_varray ) )
  end

  def get_gphys( grid=nil )
    if grid.class != Grid and @grid == nil
      puts "get_gphys: object does not have grid."
      return false
    end
    return GPhys.new( grid, get_varray )
  end

  def netcdf_write( nc_fu, grid=nil )
    if grid == nil and @grid == nil
      return false
    end
    GPhys::NetCDF_IO.write( nc_fu, GPhys.new( grid, get_varray ) )
    return true
  end
end



if $0 == __FILE__ then
require 'minitest/autorun'
require '~/lib_k247/minitest_unit_k247'

class Test_VArray_Proto_K247 < MiniTest::Unit::TestCase
  def setup
  #  @obj = VArray_Proto_K247.new( NArray.sfloat(1).indgen )
    @obj = VArray_Proto_K247.new
  end

  def teardown
    #
  end


  def test_init_na
    assert_equal NArray, @obj.nary.class
  end

  def test_init_attr
    assert_equal Hash, @obj.attr.class
  end

  def test_init_name
    assert_equal String, @obj.name.class
  end

  def test_init_grid
    refute @obj.grid
  end

  def test_chk_narraya
    nary = NArray.sfloat(1)
    obj = VArray_Proto_K247.new( nary )
    assert_equal NArray, obj.nary.class
  end

    def test_chk_narrayb
      obj = VArray_Proto_K247.new( 1.0 )
      assert_equal NArray, obj.nary.class
    end
  
    def test_chk_narrayc
      obj = VArray_Proto_K247.new( 1 )
      assert_equal NArray, obj.nary.class
    end
  
    def test_chk_narrayd
      na_miss = NArrayMiss.sfloat( 1 )
      obj = VArray_Proto_K247.new( na_miss )
      assert_equal NArrayMiss, obj.nary.class
    end
  
    def test_chk_narraye
      refute @obj.chk_narray( "str" )
    end
  
    def test_chk_narrayf
      obj = VArray_Proto_K247.new( "str" )
      refute obj.nary
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

  def test_chk_grid
    refute @obj.chk_grid( 1 )
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
    @obj.chg_nary( 1.0 )
    na1 = NArray.to_na( [1.0] )
    assert_equal na1, @obj.nary
  end

  def test_chg_attr
    hash_new = {"long_name"=>"test_test"}
    @obj.chg_attr( hash_new )
    assert_equal hash_new, @obj.attr
  end

    def test_set_units
      @obj.set_units( "km" )
      assert_equal "km", @obj.attr["units"]
    end

    def test_set_unitsb
      refute @obj.set_units( 1.0 )
    end

    def test_set_long_name
      @obj.set_long_name( "long_name" )
      assert_equal "long_name", @obj.attr["long_name"]
    end

    def test_set_long_nameb
      refute @obj.set_long_name( 1 )
    end

  def test_chg_name
    name_new = "test"
    @obj.chg_name( name_new )
    assert_equal name_new, @obj.name
  end

  def test_val
    assert_equal NArray, (@obj.val).class
  end

  def test_get_varray
    assert_equal VArray, ( @obj.get_varray  ).class
  end

    def test_get_varrayb
      va = @obj.get_varray
      p va.val
      p va.att_names
      p va.name
      assert true
    end
  
  def test_get_grid
    assert_equal Grid, ( @obj.get_grid ).class
  end
  
  def test_get_gphys
    refute @obj.get_gphys
  end
  
    def test_get_gphysb
      grid = @obj.get_grid
      assert_equal GPhys, ( @obj.get_gphys( grid ) ).class 
    end
  
  def test_netcdf_write
    nc_fu = NetCDF.create( "./test.nc" )
    grid = @obj.get_grid
    @obj.chg_name( "var")
      # var name must be different from grid name
    ret = @obj.netcdf_write( nc_fu, grid )
    nc_fu.close
    assert ret
  end
=begin
    def test_get_varrayc
      @obj.chg_nary( 1.0 )
      va = @obj.get_varray
      puts va.inspect
    end
=end
=begin
=end
end
end # if $0 == __FILE__ then
