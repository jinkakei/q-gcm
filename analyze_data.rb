require_relative "qgcm_k247"

watcher = K247_Main_Watch.new

#qgd = K247_qgcm_data.new( ARGV[0] )
qgd = K247_qgcm_data.new( "dx4km2y" ) # test@2015-10-12
#  p qgd
  p qgd.fnot
  p qgd.beta

# check energy
#  qgd.chk_energy_avg_stdout
#  qgd.chk_energy_avg_ncout

watcher.end_process
