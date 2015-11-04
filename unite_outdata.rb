require_relative "qgcm_prep_k247"

cname = ARGV[0]
qg_prep = k247_qgcm_preprocess_wrapper( cname )
  unless qg_prep.orgfile_exist?
    puts "!Error! original file is not exist!"
    exit
  end
  qg_prep.para_ncout
  qg_prep.monit_ncout
