#!/usr/bin/ruby
require_relative 'lib_k247_for_qgcm'

# How to use
# $ exec_qgcm casename

# ToDo
#   - continue run

#   - merge gen_get_qgpara.rb
#
#   - 
#   - 
#   - 



watcher = K247_Main_Watch.new

#=begin # temporary comment out
# prepare
  exefname = "q-gcm"
  exit_with_msg ("The executable file #{exefname} is not exist") \
    unless File.exist?( exefname )
  
  exit_with_msg ("no casename") unless ARGV[0]
  cname = ARGV[0]
  
  odir = "./outdata_#{cname}"
  exit_with_msg("outdir #{odir} already exists") if File.exist?( odir )
  
  exec_command( "mkdir #{odir}" )
  File.open( "outdata.dat", 'w' ) do | f | f.puts "#{odir}" end
  exec_command( "mkdir #{odir}/avg" ) # for averaged data
#=end


# get qgcm paramters -> see below

# Fortran options
  ncdf_path = "/opt/cray/netcdf/4.2.0/intel/120"
  op_ncdf = "-I#{ncdf_path}/include -L#{ncdf_path}/lib -lnetcdf -lnetcdff"
  op_w = "-warn all"

#=begin # temporary comment out
# set boundary condition
  qfor = "k247_make_forcing_q-gcm"
  qfor_e = "#{qfor}.exe"
  #qfor_f =  "~/bin_k247/#{qfor}.F90"
  qfor_f =  "#{qfor}.F90"
  exec_command( "ifort #{op_w} -o #{qfor_e} #{qfor_f} #{op_ncdf}" )
  pret = popen3_wrap( "./#{qfor_e}" )
    show_stdoe( pret )
  forc_fname = ""; f_fname = "./forcing_fname.txt"
    File.open( f_fname, 'r') do |fu| forc_fname = fu.gets.chomp end
  forc_link = "avges.nc"
    exec_command("mv #{forc_link} #{forc_link+time_now_str_sec}~") \
        if File.exist?( forc_link )
  exec_command("ln -s #{forc_fname} #{forc_link}")
#=end # temporary comment out


# set initial condition
  qres = "k247_make_restart_q-gcm"
  qres_e = "#{qres}.exe"
  qres_f = "#{qres}.F90"
  bes_dir = "~/mod_ifort/"; bes_fhead = "bessel_k247"
    bes_o = "#{bes_fhead}.o"; bes_m = "#{bes_fhead}.mod"
    exec_command( "ln -s #{bes_dir+bes_o} .") unless File.exist?( bes_o )
    exec_command( "ln -s #{bes_dir+bes_m} .") unless File.exist?( bes_m )
  op_bes = bes_o
  #op_modon = "-Duse_modon"
  op_modon = "" # not modon mode
  exec_command( "ifort #{op_w} -o #{qres_e} #{qres_f} \
                  #{op_bes} #{op_ncdf} #{op_modon}" )
  pret = popen3_wrap( "./#{qres_e}" )
    show_stdoe( pret )
  restart_fname = ""; r_fname = "./restart_fname.txt"
    File.open( r_fname, 'r') do |fu| restart_fname = fu.gets.chomp end
  res_link ="restart.nc"
    exec_command("mv #{res_link} #{res_link+time_now_str_sec}~") \
        if File.exist?( res_link )
  exec_command("ln -s #{restart_fname} #{res_link}")


# exec command
  #cmd_str = "qsub cntl_q-gcm"
  exec_command( "qsub < cntl_q-gcm" )
  #exec_command( "qsub cntl_q-gcm" )
  # Error @ 2015-10-04
  #   Mandatory parameter [-q] is not specified.

watcher.end_process


=begin # get qgcm paramters
# get qgcm paramters
# ToDo: refactoring, or establish
  # show parameters from Fortran Program
    qpara = "get_qgcm_params"
    qp_op = "-warn all"
    qp_e = "#{qpara}.exe"
    qp_f =  "~/bin_k247/#{qpara}.F90"
    exec_command( "ifort #{qp_op} -o #{qp_e} #{qp_f}")
    pret = popen3_wrap( "./#{qp_e}" )
      show_stdoe( pret )
  
  # prepare
    #qpara_all    = %w[ nxto nyto nxpo nypo nlo dxo gpoc hoc ]
    #  qpara_i    = %w[ nxto nyto nxpo nypo nlo ]
    qpara_all    = %w[ nxto nyto nxpo nypo dxo gpoc hoc ]
      qpara_i    = %w[ nxto nyto nxpo nypo ]
      qpara_f    = %w[ dxo ]
      qpara_f_zi = %w[ gpoc ]
      qpara_f_z  = %w[ hoc ]
    qp_hash = {}
    qp_line = pret["o"].clone
  # get & define nlo ( for qpara_f_z )
    for n in 0..qp_line.length-1
      if qp_line[n].include?("nlo")
        nlo = qp_line[n].chomp.split("=")[1].to_i
        qp_line.delete_at( n )
        break
      end
    end
  # set hash
    #pret["o"].each do | l |
    qp_line.each do | l |
      #p line.chomp.split("=")[1].to_f
      # I cannot use eval() @ 2015-10-03
      qpara_i.each do | qp |
        qp_hash[qp] = l.chomp.split("=")[1].to_i  if l.include?( qp )
      end
      qpara_f.each do | qp |
        qp_hash[qp] = l.chomp.split("=")[1].to_f  if l.include?( qp )
      end
      qpara_f_zi.each do | qp |
        qp_hash[qp] = l.chomp.split("=")[1].to_f  if l.include?( qp )
      end
      qpara_f_z.each do | qp |
        if l.include?( qp )
          nums = l.chomp.split("=")[1]
          tary = []
          for k in 0..nlo-1
            tary[k] = nums.split("      ")[k].to_f
          end
          qp_hash[qp] = tary
        end
      end
    end
  # define parameters
    # code generator
      #qpara_all.each do | q |
      #  puts "#{q} = qp_hash[\"#{q}\"]"
      #  puts "p #{q}"
      #end
    nxto = qp_hash["nxto"]
    nyto = qp_hash["nyto"]
    nxpo = qp_hash["nxpo"]
    nypo = qp_hash["nypo"]
    dxo  = qp_hash["dxo"]
    gpoc = qp_hash["gpoc"]
    hoc  = qp_hash["hoc"]
=end # get qgcm paramters
