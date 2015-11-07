require_relative 'qgcm_k247'
include K247_qgcm_common
require_relative "varray_proto_k247"

#va = VArray_Proto_K247.new( \
#       NArray.sfloat(10).indgen, {"units"=>"km"}, "xaxis")

def read_hmax_for_cuteddy( fname )
  hmax_i = GPhys::IO.open( fname, "hmax_i" ).val 
  hmax_j = GPhys::IO.open( fname, "hmax_j" ).val
  na_day = GPhys::IO.open( fname, "hmax_i" ).coord( "time" ).val
  return hmax_i, hmax_j, na_day
end

def get_gridinfo( fname )
  xp = GPhys::IO.open( fname, "p" ).coord( "xp" ).val
  dx = xp[1] - xp[0]
  zp = GPhys::IO.open( fname, "p" ).coord(  "z" ).val
  nz = zp.length
  return dx, zp, nz
end

def get_gridval( fname )
  gp_p = GPhys::IO.open( fname, "p" )
  xp = gp_p.coord( "xp" ).val
  yp = gp_p.coord( "yp" ).val
  zp  = gp_p.coord( "z" ).val
  return xp, yp, zp
end


def cuteddy_set_newgrid( xprel, zp, na_day, nday=nil)
  nday = na_day.length if nday == nil # for test

  yprel = xprel.clone
  axes_parts = cuteddy_def_axparts
    axes_parts["xprel"]["val"] = xprel
    axes_parts["yprel"]["val"] = yprel
    axes_parts[  "z"  ]["val"] = zp
    axes_parts["time" ]["val"] = na_day[0..nday-1]

  return GPhys::restore_grid_k247( axes_parts )
end #def cuteddy_set_grid( elen_km, dx, zp, na_day, nday=nil)

  # for GPhys::restore_grid_k247
  # ToDo:
  #   - refactoring 
  def cuteddy_def_axparts
  
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
  end # def cuteddy_def_axparts

def cuteddy_set_vaproto( newgrid )
  pcut_attr = {"units"=>"m2.s-2", \
               "long_name"=>"Ocean Dynamic Pressure near pmax", \
               "radius"=>elen_km.to_s \
              }
  return VArray_Proto_K247.new( nil, pcut_attr, "p", newgrid )
end

watcher = K247_Main_Watch.new

# required resources for each elen_km
## dxo=2km, nday=730
  # 240km:  106~248 sec,  324M
  # 360km:  104     sec,  726M

# check precondition
  K247_qgcm_common::cd_qgcm_work
  #outdir = "outdata_#{cname}/"
  outdir = "basic/" # symbolic link 
  Dir::chdir( outdir )
  hmax_fname =  "hmax_etc.nc"
  #p File.exist?( hmax_fname )


# set out file name
  out_fname = "test_pcut.nc"

# read hmax, i, j
  hmax_i, hmax_j, na_day = read_hmax_for_cuteddy( hmax_fname)
#  nday = na_day.length
nday = 10 # tmp

# get original file
  orgdir = "avg/"
  flist  = Dir::glob( orgdir + "*.nc").sort

# initial setting
  dx, zp, nz = get_gridinfo( flist[0] )
  # calc region length
    elen_km = 240.0 # default
    #elen_km = 360.0 # no problem
    #elen_km = 400.0 # nomemory error when NetCDFWrite
    #elen_km = 480.0 # no memory error when cuteddy (for 730day)
    elen = ( elen_km / dx ).to_i
    nxr = 2 * elen + 1
  # set new grid
    xprel = dx * NArray.sfloat( nxr ).indgen - dx * elen
    newgrid = cuteddy_set_newgrid( xprel, zp, na_day, nday )
  # set VArray Proto
    vap_pcut = cuteddy_set_vaproto( newgrid )

# read and output
  pcut = NArray.sfloat( nxr, nxr, nz, nday )
  info_day = 10
  for tn in 0..nday-1
    puts "#{tn} / #{nday}" if ( tn % info_day ) == 0
    gp_p = GPhys::IO.open( flist[tn], "p" )
    pcut[ 0..-1, 0..-1, 0..-1, tn ] = \
          gp_p.val[ hmax_i[tn]-elen..hmax_i[tn]+elen, hmax_j[tn]-elen..hmax_j[tn]+elen, 0..-1 ]
    # ??? subset ( by "cut" ) cannot convert NArray ( by "val" )???
    #      gp_p.cut( \
    #                "xp"=>xp[hmax_i[tn]-elen..hmax_i[tn]+elen], \
    #                "yp"=>yp[hmax_j[tn]-elen..hmax_j[tn]+elen], \
    #                "z"=>zp[0..-1] ).data.val
  end
  vap_pcut.chg_nary( pcut )
  vap_pcut.netcdf_write_create( out_fname )


watcher.end_process
