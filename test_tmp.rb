require_relative "varray_proto_k247"

va = VArray_Proto_K247.new( \
       NArray.sfloat(10).indgen, {"units"=>"km"}, "xaxis")
#puts va.methods.sort
#p va.val.length

#grid = va.get_grid
#gp = va.get_gphys( grid )
#p gp.class

#p va.methods.sort
p va
p va.clone


=begin
grid = Grid.new( Axis.new.set_pos( va.get_varray ))
p grid
#puts grid.methods.sort
p grid.shape[0]

vay = VArray_Proto_K247.new( \
       NArray.sfloat(10).indgen, {"units"=>"km"}, "yaxis")
xygrid = Grid.new( Axis.new.set_pos( va.get_varray ), \
                    Axis.new.set_pos( vay.get_varray ) )
p xygrid.shape
xaxis = Axis.new.set_pos( va.get_varray )
p xaxis.class
xgrid = Grid.new( xaxis )
p xgrid
p xgrid.class
puts "test"  if xgrid.class == Grid
puts "test2" if xgrid.class == NumRu::Grid
=end
