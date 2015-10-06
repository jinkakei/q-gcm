require "~/lib_k247/K247_qgcm"

if ARGV[0] != nil
  K247_qgcm_data.prep_integrate_outdata( ARGV[0] )
  # test methods prep_* ( temporary@ 2015-10-06 )
  #K247_qgcm_data.prep_set_greater_cname
else
  exit_with_msg("input case name")
end
