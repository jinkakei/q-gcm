#!/usr/bin/ruby
require_relative "admin_work_k247"

# How to use
#   q-gcm  [!] <- here is running place
#     |---- /src
#     |---- /work
#     |---- /log/work_log


admin = Admin_work_k247.new
admin.cd_work
  #admin.mk_backupdir
  admin.check_cpfiles

=begin
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


admin.finish
