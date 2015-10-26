# load libraries
require "numru/gphys"
include NumRu

# 2015-10-16
# ToDo
#   - set Grid
#   - restore GPhys
#   - setup GPhys and NetCDF write
#   - 
#   - 
class GPhys_Proto_K247
  attr_reader :nary, :attr, :name
  attr_reader :grid
  attr_reader :va_proto
  
  def initialize( nary=nil, attr=nil, name=nil, grid=nil )
  # arguments == nil
    @va_proto = VArray_Proto_K247.new( nary, attr, name )
    @grid     = grid
  # arguments != nil
  #  @name  = chk_name(   name ) unless name == nil

    #@grid
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
    return VArray.new( @na, @attr, @name )
  end
end



if $0 == __FILE__ then
require 'minitest/autorun'
require '~/lib_k247/minitest_unit_k247'

class Test_GPhys_Proto_K247 < MiniTest::Unit::TestCase
  def setup
  #  @obj = GPhys_Proto_K247.new( NArray.sfloat(1).indgen )
    @obj = GPhys_Proto_K247.new
  end

  def teardown
    #
  end

=begin
=end
end
end # if $0 == __FILE__ then
