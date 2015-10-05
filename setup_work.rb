#!/usr/bin/ruby
require_relative "admin_work_k247"

# How to use
#   q-gcm  [!] <- here is running place
#     |---- /src
#     |---- /work

admin = Admin_work_k247.new
admin.cd_work
  admin.check_empty
  admin.set_links
  admin.copy_files

admin.finish
