require "numru/gphys"
require "numru/ggraph"
include NumRu
# Info
#   these method may be out of date.
#   orginal methods are in ~/lib_k247/*.


def exit_with_msg( msg )
  print "\n\n!ERROR! #{msg}!\n\nexit\n\n"
  exit -1
end


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
