require "~/lib_k247/K247_qgcm"

watcher = K247_Main_Watch.new

qgd = K247_qgcm_data.new( ARGV[0] )

watcher.end_process
