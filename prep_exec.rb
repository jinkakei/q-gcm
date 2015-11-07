require_relative "qgcm_prep_k247"

watcher = K247_Main_Watch.new

cname = ARGV[0]
k247_qgcm_preprocess_wrapper( cname )

watcher.end_process
