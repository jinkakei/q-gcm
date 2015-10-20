require_relative 'qgcm_k247'
require_relative "varray_proto_k247"

#va = VArray_Proto_K247.new( \
#       NArray.sfloat(10).indgen, {"units"=>"km"}, "xaxis")

watcher = K247_Main_Watch.new

outdir = "./outdata_nctest42/"
#outdir = "./outdata_nctest43/"
avgdir = "avg/"
flist  = Dir::glob( outdir + avgdir + "*.nc").sort
#  p flist[0]

nday = flist.length

# initial set ( @nxp, @nyp, @nz: qgcm_k247.rb )
  gp_p = GPhys::IO.open( flist[0], "p" )
  ptmp = gp_p.val
  nl = ptmp.shape
  psum_pre  = NArray.sfloat( nl[0], nl[1], nl[2] ).fill( 0.0 )
  psum_post = NArray.sfloat( nl[0], nl[1], nl[2] ).fill( 0.0 )
# prepare
  avgday = 5
  new_grid = K247_qgcm_data.prep_modify_po_grid_tmp( gp_p )
  pavg_attr = {"units"=>"m2.s-2", \
               "long_name"=>"Ocean Dynamic Pressure", \
               "avg_period"=>"#{2*avgday}"}
  vap_pavg = VArray_Proto_K247.new( nil, pavg_attr, "pavg", new_grid)

for t in 0..avgday
  psum_pre  += GPhys::IO.open( flist[0], "p" ).val
end
for t in avgday+1..10
  psum_post += GPhys::IO.open( flist[t], "p" ).val
  if ( t.modulo( avgday ) == 0 )
    str_day = sprintf( "%06d", t - avgday )
    fname = "#{outdir}ocpoavg_#{str_day}day.nc"
    pavg = ( psum_pre + psum_post ) / ( 2 * avgday + 1 ).to_f
    vap_pavg.chg_nary( pavg )
    vap_pavg.netcdf_write_create( fname )
    psum_pre  = psum_post.clone
    if ( t.modulo( 2 * avgday ) == 0 )
      psum_post = GPhys::IO.open( flist[t], "p" ).val
    else
      psum_post = 0.0
    end
  end
end
=begin
  p pavg.max
  p pavg.shape
  vap_pavg.chg_nary( pavg )
  vap_pavg.netcdf_write_create( "./test.nc" )
=end


watcher.end_process
