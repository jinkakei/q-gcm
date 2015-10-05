#!/usr/bin/ruby
require_relative "admin_work_k247"

# How to use
#   q-gcm  [!] <- here is running place
#     |---- /src
#     |---- /work
#     |---- /log/work_log


admin = Admin_work_k247.new
admin.cd_work
  admin.mk_backupdir
  admin.check_cpfiles
  admin.make_clean
  admin.rm_f_links
  admin.mv_allfiles
admin.finish
