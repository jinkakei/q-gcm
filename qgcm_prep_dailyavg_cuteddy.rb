require_relative 'qgcm_k247'
include K247_qgcm_common
require_relative "varray_proto_k247"

#va = VArray_Proto_K247.new( \
#       NArray.sfloat(10).indgen, {"units"=>"km"}, "xaxis")

# for GPhys::restore_grid_k247
def def_axparts_cuteddy
  axes_parts = {"names" => [ "xprel", "yprel", "z", "time" ]}
  hash_xpr = { "name"=> nil, "atts"=>nil, "val"=>nil}
		  hash_xpr["name"] = "xprel"
		  hash_xpr["atts"] = { "units"=>"km", \
                           "long_name"=>"X distance from pmax (p-grid)"}
  axes_parts["xprel"] = hash_xpr
  hash_ypr = { "name"=> nil, "atts"=>nil, "val"=>nil}
		  hash_ypr["name"] = "yprel"
		  hash_ypr["atts"] = { "units"=>"km", \
                           "long_name"=>"Y distance from pmax (p-grid)"}
  axes_parts["yprel"] = hash_ypr
  hash_z = { "name"=> nil, "atts"=>nil, "val"=>nil}
		  hash_z["name"] = "z"
		  hash_z["atts"] = { "units"=>"km", \
                         "long_name"=>"Ocean mid-layer depth axis"}
  axes_parts["z"] = hash_z
  hash_t = { "name"=> nil, "atts"=>nil, "val"=>nil}
		  hash_t["name"] = "time"
		  hash_t["atts"] = { "units"=>"days", \
                         "long_name"=>"Time Axis"}
  axes_parts["time"] = hash_t
  return axes_parts
end # def def_axparts_cuteddy



watcher = K247_Main_Watch.new

# check precondition
  K247_qgcm_common::cd_qgcm_work
  #outdir = "outdata_/"
  outdir = "basic/" # symbolic link 
  Dir::chdir( outdir )
  hmax_fname =  "hmax_etc.nc"
  #p File.exist?( hmax_fname )

# read hmax, i, j
  hmax_i = GPhys::IO.open( hmax_fname, "hmax_i" ).val 
  hmax_j = GPhys::IO.open( hmax_fname, "hmax_j" ).val
  na_day = GPhys::IO.open( hmax_fname, "hmax_i" ).coord( "time" ).val


# get original file
  orgdir = "avg/"
  flist  = Dir::glob( orgdir + "*.nc").sort

# initial setting
  gp_p = GPhys::IO.open( flist[0], "p" )
  #p gp_p
  xp = gp_p.coord( "xp" ).val
  yp = gp_p.coord( "yp" ).val
  # calc region length
    dx = xp[1] - xp[0]
    elen_km = 240.0
    elen = ( elen_km / dx ).to_i
  # 
    xprel = dx * NArray.sfloat( 2*elen + 1 ).indgen - dx * elen
    yprel = xprel.clone
    axes_parts = def_axparts_cuteddy
    axes_parts["xprel"]["val"] = xprel
    axes_parts["yprel"]["val"] = yprel
    axes_parts[  "z"  ]["val"] = gp_p.coord( "z" ).val
    axes_parts["time" ]["val"] = na_day
    p axes_parts
    #origrid = gp_p.get_axes_parts_k247
    #p origrid["names"]

=begin
# test output
  #p gp_p.cut( "xp" => xp[hmax_i[0]-elen..hmax_i[0]+elen], \
  #            "yp" => yp[hmax_j[0]-elen..hmax_j[0]+elen] )
  #gp_pcut = gp_p.cut( "xp" => xp[hmax_i[0]-elen..hmax_i[0]+elen], \
  #                    "yp" => yp[hmax_j[0]-elen..hmax_j[0]+elen] )
    
  nc_fu = NetCDF.create( "test.nc" )
  # tmp
    z = gp_p.coord( "z" ).val
  GPhys::NetCDF_IO.write( nc_fu, \
                          gp_p.cut( "z"=>z[0] ) )
  # Error? @2015-11-06
#  GPhys::NetCDF_IO.write( nc_fu, \
#    gp_p.cut( "xp" => xp[hmax_i[0]-elen..hmax_i[0]+elen],  \
#              "yp" => yp[hmax_j[0]-elen..hmax_j[0]+elen] ) )  
  nc_fu.close


## OLD
#nday = flist.length
nday = 30

# initial set ( @nxp, @nyp, @nz: qgcm_k247.rb )
  gp_p = GPhys::IO.open( flist[0], "p" )
  ptmp = gp_p.val
  nl = ptmp.shape
  psum_pre  = NArray.sfloat( nl[0], nl[1], nl[2] ).fill( 0.0 )
  psum_post = NArray.sfloat( nl[0], nl[1], nl[2] ).fill( 0.0 )
# prepare
  avgday = 10 
  avgdir = "avg#{avgday}day/"
  exec_command( "mkdir #{outdir + avgdir}" )
  new_grid = K247_qgcm_data.prep_modify_po_grid_tmp( gp_p )
  pavg_attr = {"units"=>"m2.s-2", \
               "long_name"=>"Ocean Dynamic Pressure", \
               "avg_period"=>"#{2*avgday}"}
  vap_pavg = VArray_Proto_K247.new( nil, pavg_attr, "pavg", new_grid )
for t in 1..avgday
  psum_pre  += GPhys::IO.open( flist[t-1], "p" ).val
end
for t in avgday+1..nday
  psum_post += GPhys::IO.open( flist[t-1], "p" ).val
  if ( t.modulo( avgday ) == 0 )
    puts "outdata: #{t}"
    puts "  #{flist[t-1]}"
    str_day = sprintf( "%06d", t - avgday )
    fname = "#{outdir+avgdir}poavg_#{str_day}day.nc"
    pavg = ( psum_pre + psum_post ) / ( 2 * avgday ).to_f
    vap_pavg.chg_nary( pavg )
    vap_pavg.netcdf_write_create( fname )
    psum_pre  = psum_post.clone
    psum_post = 0.0
  end
end
# postprocess
# [!] ToDo: Use ocpo.nc
  na_p0 = GPhys::IO.open( "#{outdir}ocpo.nc", "p" ).cut( "time"=> 0.0 ).val
  vap_pavg.chg_nary( na_p0 )
  avgday0 = sprintf( "%06d", 0 )
  fname0 = "#{outdir+avgdir}poavg_#{avgday0}day.nc"
  vap_pavg.netcdf_write_create( fname0 )

=end


watcher.end_process
