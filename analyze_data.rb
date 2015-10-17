require_relative "qgcm_k247"

watcher = K247_Main_Watch.new

#qgd = K247_qgcm_data.new( ARGV[0] )
qgd = K247_qgcm_data.new( "dx4km2y" ) # test@2015-10-12
#  p qgd
#  p qgd.fnot

## check energy
#  qgd.chk_monit_energy_stdout
#  qgd.chk_monit_energy_ncout

## check ssh max
#  qgd.sshdec_tmp
#    qgd.sshmax_set_with_ij # 1920x960x73 -> 5 sec?

## check ke sum around eddy
#  qgd.energy_sum_ncwrite


watcher.end_process
