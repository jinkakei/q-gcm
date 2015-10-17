require_relative "gphys_prot_k247.rb"

gp_pro = GPhys_Proto_K247.new
p gp_pro.val
gp_pro.val[0] = 1.0
p gp_pro.val

