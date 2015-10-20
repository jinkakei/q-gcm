require_relative 'qgcm_k247'
require_relative "varray_proto_k247"

#va = VArray_Proto_K247.new( \
#       NArray.sfloat(10).indgen, {"units"=>"km"}, "xaxis")

watcher = K247_Main_Watch.new

outdir = "./outdata_nctest42/"
avgdir = "avg/"
flist  = Dir::glob( outdir + avgdir + "*.nc").sort
#  p flist[0]

# initial set ( @nxp, @nyp, @nz: qgcm_k247.rb )
  gp_p = GPhys::IO.open( flist[0], "p" )
  ptmp = gp_p.val
  nl = ptmp.shape
  psum_pre  = NArray.sfloat( nl[0], nl[1], nl[2] )
  psum_post = NArray.sfloat( nl[0], nl[1], nl[2] ).fill( 0.0 )
  new_grid = K247_qgcm_data.prep_modify_po_grid_tmp( gp_p )

avgday = 5
for t in 0..10
  psum_post += GPhys::IO.open( flist[t], "p" ).val
  if ( t.modulo( avgday ) == 0 )
    puts "t = #{t}"
    pavg = ( psum_pre + psum_post ) / ( 2 * avgday + 1 ).to_f
    psum_pre  = psum_post.clone
    psum_post = 0.0 if ( t.modulo(     avgday ) == 0 )
    psum_post = GPhys::IO.open( flist[t], "p" ).val \
      if ( t.modulo( 2 * avgday ) == 0 )
  end
end
  p pavg.max
  p pavg.shape
  va_pavg = pavg
  va_pavg = VArray_Proto_K247.new( \
       pavg, {"units"=>"m2.s-2", "long_name"=>"Ocean Dynamic Pressure"}, \
       "pavg").get_varray
  gp_pavg = GPhys.new( new_grid, va_pavg)
  nc_fu = NetCDF.create( "./test.nc" )
  #  GPhys::NetCDF_IO.write( nc_fu, va_pavg.get_varray )
    GPhys::NetCDF_IO.write( nc_fu, gp_pavg )
  nc_fu.close

#flist.each do | nc_fn |
#  gp_p = GPhys::IO.open( nc_fn, "p" )
#  na_p = gp_p.val
#end


watcher.end_process
