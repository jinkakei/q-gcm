require_relative 'qgcm_k247'
require_relative "varray_proto_k247"
# ToDo:
#    
#   - What is required? 
#    
#   - enhance methods and refactoring
#   - test 2day average ( aliasing? )
#   - 

def set_grid_day( nday )
  att_day = {"units"=>"days","long_name"=>"Time Axis"}
  na_day   = NArray.sfloat(nday).indgen + 0.5
  vap_day  = VArray_Proto_K247.new( na_day, att_day, "time")
  return vap_day.get_grid
end # def set_grid_day

def sshmax_get_with_ij_from_fname( fname )
# fname -- ./outdata_*/avg/ocavg_??????day.nc 
  # ToDo: check fname and set mode
# get 2d NArray 
  gp_p = GPhys::IO.open( fname, "p" )
    na_z = gp_p.coord("z").val
  na_p0 = gp_p.cut( "z"=>na_z[0]).val
# 
  pmax, i, j = na_max_with_index_k247( na_p0 )
  m_to_cm = 100.0; grav = 9.8
  hmax = pmax * m_to_cm / grav
  return hmax, i, j
end


watcher = K247_Main_Watch.new

#outdir = "./outdata_nctest44/" # raw: 2km, 481x481, 730day
#outdir = "./outdata_nctest46/" # raw: 4km, 481x481, 20day
#outdir = "./outdata_nctest47/" # daily average: 4km, 481x481, 20day
outdir = "./basic/" # daily average: 2km, 3841x1921, 730day
avgdir = "avg/"
flist  = Dir::glob( outdir + avgdir + "*.nc").sort
#  p flist[0]


nc_fu = NetCDF.create( "#{outdir}hmax_etc.nc" )
  nday = flist.length
  #nday = 10
  # set day grid
    grid_day = set_grid_day( nday )
      na_day = grid_day.coord(0).val # (kari)
  # set hmax
  hmax = NArray.sfloat( nday )
    hmax_i = NArray.int( nday )
    hmax_j = NArray.int( nday )
  for n in 0..nday-1
  #  hmax[n] = GPhys::IO.open( flist[n], "p" ).val.max / 9.8 * 100.0
    hmax[n], hmax_i[n], hmax_j[n] \
      = sshmax_get_with_ij_from_fname( flist[n])
  end
    attr_hmax = {"units"=>"cm","long_name"=>"SSH Max"}
    vap_hmax  = VArray_Proto_K247.new( hmax, attr_hmax, "hmax", grid_day )
    vap_hmax.netcdf_write( nc_fu )
    attr_hmax_i = {"units"=>"","long_name"=>"SSH Max X Position"}
    vap_hmax_i  = VArray_Proto_K247.new( hmax_i, attr_hmax_i, "hmax_i", grid_day )
    vap_hmax_i.netcdf_write( nc_fu )
    attr_hmax_j = {"units"=>"","long_name"=>"SSH Max Y Position"}
    vap_hmax_j  = VArray_Proto_K247.new( hmax_j, attr_hmax_j, "hmax_j", grid_day )
    vap_hmax_j.netcdf_write( nc_fu )
  # set hdec
  hdec = NArray.sfloat( nday )
    xspd = NArray.sfloat( nday )
    yspd = NArray.sfloat( nday )
      dxo = 2.0e5 # [cm], tmp
      day_to_sec = 24.0 * 3600.0
  for n in 1..nday-2
    hdec[n] = ( hmax[n+1] - hmax[n-1] ) / \
               ( na_day[n+1] - na_day[n-1] ) * 365.0
    #xspd[n] = dxo * ( hmax_i[n+1] - hmax_i[n-1] ) / \
    xspd[n] = dxo * ( hmax_i[n+1] - hmax_i[n-1] ).to_f / \
                ( ( na_day[n+1] - na_day[n-1] ) * day_to_sec )
    #yspd[n] = dxo * ( hmax_j[n+1] - hmax_j[n-1] ) / \
    yspd[n] = dxo * ( hmax_j[n+1] - hmax_j[n-1] ).to_f / \
                ( ( na_day[n+1] - na_day[n-1] ) * day_to_sec )
  end
    hdec[0] = hdec[1]; hdec[nday-1] = hdec[nday-2]
    attr_hdec = {"units"=>"cm/year","long_name"=>"SSH Max Decay Rate"}
    vap_hdec  = VArray_Proto_K247.new( hdec, attr_hdec, "hdec", grid_day )
    vap_hdec.netcdf_write( nc_fu )
    xspd[0] = xspd[1]; xspd[nday-1] = xspd[nday-2]
    attr_xspd = {"units"=>"cm/s", \
                 "long_name"=>"Zonal Translation Speed of SSH Max"}
    vap_xspd  = VArray_Proto_K247.new( xspd, attr_xspd, "xspd", grid_day )
    vap_xspd.netcdf_write( nc_fu )
    yspd[0] = yspd[1]; yspd[nday-1] = yspd[nday-2]
    attr_yspd = {"units"=>"cm/s", \
                 "long_name"=>"Meridional Translation Speed of SSH Max"}
    vap_yspd  = VArray_Proto_K247.new( yspd, attr_yspd, "yspd", grid_day )
    vap_yspd.netcdf_write( nc_fu )

nc_fu.close

watcher.end_process