require_relative "qgcm_k247"
#require_relative "lib_k247_for_qgcm"
#require "~/lib_k247/K247_qgcm"

#watcher = K247_Main_Watch.new

#qgd = K247_qgcm_data.new( ARGV[0] )
qgd = K247_qgcm_data.new( "dx4km2y" ) # test@2015-10-12

# check energy
  qgd.chk_energy_avg_stdout

#watcher.end_process
