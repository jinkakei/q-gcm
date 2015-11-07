require "numru/gphys"
require "numru/ggraph"
include NumRu


# for qgcm
module K247_qgcm_common
  QGCM_HOME_PATH = "/LARGE0/gr10056/t51063/q-gcm/"

  module Updfile
    Param = "param_k247.nc"
    Monit = "monit_k247.nc"
    Hmax  = "hmax_etc.nc"
  end

  def cd_qgcm_home
    Dir::chdir( QGCM_HOME_PATH )
  end

  def cd_qgcm_work
    cd_qgcm_home
    Dir::chdir( "work" )
  end
  
  def cd_outdata( cname )
    cd_qgcm_work
    Dir::chdir( "outdata_#{cname}")
  end

  def chk_goalfile_here
    goal_file = Dir::glob("./Goal__*__.txt")
    if goal_file.length > 1
      p goal_file
      false_with_msg("The Goal must be one and only")
    end
    false_with_msg("Goal__*__.txt is not exist") if goal_file[0] == nil
    return goal_file
  end

end # module K247_qgcm_common



# ToDo: join ~/lib_k247
def false_with_msg( msg )
  puts msg
  return false
end

# Caution
#   methods below are copied from ~/lib_k247/*,
#   and may be out of date.
def exit_with_msg( msg )
  print "\n\n!ERROR! #{msg}!\n\nexit\n\n"
  exit -1
end

def ary_get_include_index( ary, kwd )
  idx = []
  for i in 0..ary.length-1
    idx.push( i ) if ary[i].include?( kwd )
  end
  if idx != []
    return idx
  else
    return false 
  end
end

def exec_command( cmd )
  #print "\n"
  ret = system(cmd)
  puts "#{ret} : #{cmd}"
  #print "\n\n"
end

def popen3_wrap( cmd )
  require "open3"

  puts "popen3: #{cmd}"
  o_str = Array(1); e_str = Array(1)
  Open3.popen3( cmd ) do | stdin, stdout, stderr, wait_thread|
    stdout.each_with_index do |line,n| o_str[n] = line end
    stderr.each_with_index do |line,n| e_str[n] = line end
  end
  ret = {"key_meaning"=>"i: stdin, o: stdout, e: stderr, w: wait_thread"}
    ret["o"] = o_str; ret["e"] = e_str
  return ret
end

  def show_stdoe( p3w_ret )
    puts "  STDOUT:"
      p3w_ret["o"].each do |line| puts "  #{line}" end
    puts "  STDERR:"
      p3w_ret["e"].each do |line| puts "  #{line}" end
  end

  
def time_now_str_sec
  return Time.now.strftime("%Y%m%d_%H%M_%S")
end



##  NArray operator
# ToDo
#   - treat dimension other than 2D
def na_max_with_index_k247( na )
  max_val = na.max
  ij= na.eq( max_val ).where 
  ni = na.shape[0]
  max_i = ij[0] % ni; max_j = ij[0] / ni
  #  puts "test: #{na[ max_i, max_j ] } "
  return max_val, max_i, max_j
end
##  END: NArray operator



class K247_Main_Watch
  # access
  attr_accessor :begin_time

  def initialize()
    print "Program ", $0, " Start \n\n"
    @begin_time = Time.now
  end # def initialize()
  
  def show_time()
    print "elapsed time = #{(Time.now) - @begin_time}sec\n"
  end # def show_elapsed()
  
  def end_process()
    end_time = Time.now
    print "\n\n"
    print "Program End : #{end_time - @begin_time}sec\n"
  end # def end_process
  
end # class K247_Main_Watch



# extension of gphys and varray
#   ver. 2015-10-10: lib_k247/K247_basic.rb
class NumRu::GPhys
	
	def get_attall_k247
		self.data.get_attall_k247 # added method for VArray
	end
	
	def get_filename_k247
		self.data.get_filename_k247 # added method for VArrayNetCDF
	end
  
  # ToDo: import change grid
  def chg_gphys_k247( chg_hash )
    return GPhys.new( self.grid, self.chg_varray_k247( chg_hash ) )
  end

	def chg_varray_k247( chg_hash )
		self.data.chg_varray_k247( chg_hash ) # added method for VArray
	end # def chg_varray_k247( chg_hash )
		
		def chg_data_k247( chg_hash )
			self.chg_varray_k247( chg_hash )
		end # def chg_data_k247( chg_hash )

	
	# ToDo: improve
	#def get_axparts_k247
	def get_axes_parts_k247
		axis_names = self.axnames
		axes_parts = { "names" => axis_names}
			# need for restore ( hash doesnot have order )
		axis_names.each{ | aname |
			ax = self.coord( aname )
			ax_parts = { "name"=> nil, "atts"=>nil, "val"=>nil}
			  ax_parts["name"] = ax.name
			  ax_parts["atts"] = ax.get_attall_k247
			  ax_parts["val"] = ax.val
			axes_parts[aname] = ax_parts
		}
		return axes_parts
	end # get_axparts_k247
	
	# axes_parts: return of get_axparts_k247
  # ToDo: change class method?
	def restore_grid_k247( axes_parts )
    self.class::restore_grid_k247( axes_parts )
  end # def restore_grid_k247( axes_parts )

	def self.restore_grid_k247( axes_parts )
		nax = axes_parts["names"].length
		anames = axes_parts["names"]
		ax = {}
		for n in 0..nax-1
			ax[n] = Axis.new.set_pos( VArray.new( axes_parts[anames[n]]["val"], axes_parts[anames[n]]["atts"], axes_parts[anames[n]]["name"] ) )
		end
		rgrid = Grid.new( ax[0] ) if nax == 1
		rgrid = Grid.new( ax[0], ax[1] ) if nax == 2
		rgrid = Grid.new( ax[0], ax[1], ax[2] ) if nax == 3
		rgrid = Grid.new( ax[0], ax[1], ax[2], ax[3] ) if nax == 4

		return rgrid
	end # def K247_gphys_restore_grid( axes_parts )
	
	
end # class NumRu::GPhys


# VArray にメソッドを追加
class NumRu::VArray

	def get_attall_k247
		att_names = self.att_names
		if att_names == nil
			puts "\n\n  no attribute \n\n"
			return nil
		end
		att_all = {}
		att_names.each do | aname |
			att_all[ aname ] = self.get_att( aname )
		end
		return att_all
	end

	def chg_varray_k247( chg_hash )

		unless chg_hash["name"] == nil
			new_name = chg_hash[ "name" ]; chg_hash.delete( "name" )
		else
			new_name = self.name
		end

		unless chg_hash["val"] == nil
			new_val = chg_hash[ "name" ]; chg_hash.delete( "val" )
		else
			new_val = self.val
		end
		
		new_att =  self.get_attall_k247
		chg_hash.keys.each do | k |
			new_att[ k ] = chg_hash[ k ]
		end

		return VArray.new( new_val, new_att, new_name )
	end # def chg_varray_k247( chg_hash )

end # class NumRu::VArray
	

class NumRu::VArrayNetCDF

	def get_filename_k247
		info = self.inspect # ex. "<'p' in './q-gcm_29_24a_ocpo.nc'  sfloat[961, 961, 2, 3]>"
		  #p info.class # String
		return info.split( " in '" )[1].split( "'" )[0]
	end
	
end # class NumRu::VArrayNetCDF

# End: extension of gphys and varray








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
