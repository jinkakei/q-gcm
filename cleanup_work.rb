#!/usr/bin/ruby
require "~/lib_k247/K247_basic.rb"

# How to use
#   q-gcm  [!] <- here is running place
#     |---- /src
#     |---- /work
#     |---- /log/work_log

class Admin_qgcm_workdir
  def initialize
    chk_init_path
  end

  def chk_init_path
    puts "check here is **/q-gcm"
    init_path = Dir::pwd
    ["src", "work", "log"].each do | d |
      exit_with_msg( "dir #{d} is necessary ( run at **/q-gcm/ )") \
        unless Dir::entries( init_path ).include?( d )
    end
  end

end # class qgcm_workdir

watcher = K247_Main_Watch.new


adm_work = Admin_qgcm_workdir.new

=begin
puts "cd work dir"
  Dir::chdir("work")
  puts "  check work dir is empth"
  work_entries = Dir::entries( Dir::pwd )
  chk_empty = [".", ".."]
  exit_with_msg("wokr dir is must be empty") \
      unless work_entries == chk_empty

puts "set links to src dir"
  src_path = "../src/"
  #src_path = "../src_test29/"
  link_files = ["*.F", "*.f",  \
           "make.macro", "make.config", "Makefile", \
           "cntl_q-gcm", "*.F90", \
           "fftpack/" ]
  
  link_files.each do | f |
    exec_command( "ln -s #{src_path}#{f} .")
  end

puts "copy several files from src"
  # change frequently
  cp_files = ["../src/input.params", "../exec_qgcm.rb"]
  cp_files.each do |cpf|
    exec_command("cp -p #{cpf} .")
  end
=end

watcher.end_process

