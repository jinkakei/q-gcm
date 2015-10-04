#!/usr/bin/ruby

#  generator of get_qgcm_params.F90

  qgcm_params = %w[ nxto nyto nxpo nypo nlo dxo gpoc hoc ]
  p qgcm_params

  # source code output
  #   ToDo: adjust positions of "="
  qgcm_params.each do | qp |
    puts "\t write(*,*) \"#{qp} = \", #{qp}"
  end


puts "#{$0} end"
