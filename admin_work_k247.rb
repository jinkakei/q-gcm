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
    check_subdirs
    @cp_files = ["../src/input.params", "../exec_qgcm.rb"]
      # ToDo?: relative path from work dir
  end

  def check_subdirs
    puts "check here is **/q-gcm"
    current_path = Dir::pwd
    ["src", "work", "log"].each do | d |
      exit_with_msg( "dir #{d} is necessary ( run at **/q-gcm/ )") \
        unless Dir::entries( current_path ).include?( d )
    end
    # for cleanup
      @bk_dname = "#{current_path}/log/work_log/#{time_now_str_sec}"
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
    src_path = "../src/"
    #src_path = "../src_test29/"
    link_files = ["*.F", "*.f",  \
             "make.macro", "make.config", "Makefile", \
             "cntl_q-gcm", "*.F90", \
             "fftpack/" ]
    link_files.each do | f |
      exec_command( "ln -s #{src_path}#{f} .")
    end
  end

  def copy_files
  # frequently changed files
    puts "copy several files from src"
    @cp_files.each do |cpf|
      exec_command("cp -p #{cpf} .")
    end
  end
  
# for cleanup
  def mk_backupdir
    exec_command("mkdir #{@bk_dname}")
  end
  
  def check_cpfiles
    puts "check copied files #{@cp_files}"
    @cp_files.each do |org_f|
      cpy_f = File.basename( org_f )
      #puts "original: #{org_f}, copied: #{cpy_f}"
      ret = popen3_wrap( "diff #{org_f} #{cpy_f}")
      if ret["o"][0] == 1
        puts "  no change"
      else
        show_stdoe( ret )
        if get_y_or_n("swap file? (y/n): ") == "y"
          puts "  swap files"
        else
          puts "  change is not saved"
        end
      end
    end
  end
end # class qgcm_workdir
