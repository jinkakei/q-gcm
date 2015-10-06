require "~/lib_k247/K247_qgcm"

watcher = K247_Main_Watch.new

if ARGV[0] != nil
  qgd = K247_qgcm_data.new( ARGV[0] )
  #qgd.chk_energy_avg_ncout
  # test methods  ( temporary@ 2015-10-06 )
  #K247_qgcm_data.prep_set_greater_cname
else
  exit_with_msg("input case name")
end

watcher.end_process
