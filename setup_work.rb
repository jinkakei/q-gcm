#!/usr/bin/ruby

# How to use
#   q-gcm
#     |---- /src
#     |---- /work [!] <- here is running place


# q-gcm path
qgmc_path = "/LARGE0/gr10056/t51063/"
  # ToDo: use file

target_dir = "../src/"
#target_dir = "../src_test29/"
work_dir = "."
files = ["*.F", "*.f", "input.params", \
         "make.macro", "make.config", "Makefile", \
         "cntl_q-gcm", "*.F90", \
         "fftpack/" ]

#=begin
files.each do | f |
  cmd_str =  "ln -s #{target_dir}#{f} #{work_dir}"
  p cmd_str
  ret = system( cmd_str )
end
#=end


