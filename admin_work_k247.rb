#!/usr/bin/ruby
require "~/lib_k247/K247_basic.rb"

# How to use
#   q-gcm  [!] <- here is running place
#     |---- /src
#     |---- /work         ( gitignored)
#     |---- /log/work_log ( gitignored)

class Admin_work_k247
# common
  def initialize
    @watcher = K247_Main_Watch.new
    @bgn_time = time_now_str_sec
    check_subdirs
    @cp_files =  \
      [ "../exec_qgcm.rb", \
        "../src/input.params", "../src/parameters_data.F", \
        "../src/make.config" \
      ]
    #@ln_files = ["*.F", "*.f", "make.macro", \
    #               "Makefile", "cntl_q-gcm", "*.F90", "fftpack"]
    @ln_files =  \
      { :src_dir => \
          ["*.F", "*.f", "fftpack", \
           "Makefile", "make.macro", \
           "cntl_q-gcm", \
           "*.F90" \
          ], \
        :qg_home => \
          [ "qgcm_k247.rb", "lib_k247_for_qgcm.rb", \
            "varray_proto_k247.rb", \
          ] \
      }
      # CAUTION!: fftpack is directory, 
      #           "$ rm -rf fftpack/" is remove original directory
      #           "$ rm -f fftpack" is remove symbolic link file
  end

  def check_subdirs
    puts "check here is **/q-gcm"
    current_path = Dir::pwd
    ["src", "work", "log"].each do | d |
      exit_with_msg( "dir #{d} is necessary ( run at **/q-gcm/ )") \
        unless Dir::entries( current_path ).include?( d )
    end
    # for cleanup
      @bk_dname = "#{current_path}/log/work_log/#{@bgn_time}"
  end

  def finish
    @watcher.end_process
  end

  def cd_work
    puts "cd to work"
    Dir::chdir("work")
  end

# for setup
  def check_empty
    puts "  check work dir is empty"
    work_entries = Dir::entries( Dir::pwd )
    chk_empty = [".", ".."]
    exit_with_msg("wokr dir is must be empty") \
        unless work_entries == chk_empty
  end

  def set_links
    puts "set links to src files"
    @ln_files[:src_dir].each do | f |
      exec_command( "ln -s ../src/#{f} .")
    end
    @ln_files[:qg_home].each do | f |
      exec_command( "ln -s ../#{f} .")
    end
  end

  def copy_files
    # frequently changed files ( git commit when cleanup )
    puts "copy several files from src"
    @cp_files.each do |cpf|
      exec_command("cp -p #{cpf} .")
    end
  end

  def set_goal
    print "\nInput the Goal of this work dir: "
    gnow = gets.chomp
    File.open("Goal__#{gnow}__.txt", 'w') do | f |
      f.puts "create: #{@bgn_time}"
    end
  end
  
# for cleanup
  def mk_backupdir
    exec_command("mkdir #{@bk_dname}")
  end
  
  def check_cpfiles
    puts "check copied files #{@cp_files}"
    @cp_files.each do |org_f|
      fname = File.basename( org_f )
      ret = popen3_wrap( "diff #{org_f} ./#{fname}")
      if ret["o"][0] == 1
        puts "  no change"
      else
        show_stdoe( ret )
        if get_y_or_n("swap file? (y/n): ") == "y"
          puts "swap files"
          exec_command( "mv #{org_f} ./#{fname}.before" )
          exec_command( "cp -p ./#{fname} #{org_f}" )
        else
          puts "  change is not saved"
        end
      end
    end
  end

  def make_clean
    exec_command("make clean")
  end

  def rm_f_links
    puts "remove links"
    @ln_files[:src_dir].each do | f |
      exec_command( "rm -f #{f}" )
    end
    @ln_files[:qg_home].each do | f |
      exec_command( "rm -f #{f}" )
    end
  end

  def mv_allfiles
    if get_y_or_n("mv all files at work? (y/n): ") == "y"
        exec_command("mv ./* #{@bk_dname}/")
    end
  end
end # class qgcm_workdir
