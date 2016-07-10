#!/bin/sh

openscad -o printing/leftcap.stl -D part=0 -D textured=true -D angle=0 -D assembled=false -D facets=360 sphere2.scad &
openscad -o printing/rightcap.stl -D part=0 -D textured=true -D angle=180 -D assembled=false -D facets=360 sphere2.scad &

openscad -o printing/leftcapcap.stl -D part=11 -D textured=true -D angle=0 -D assembled=false -D facets=360 sphere2.scad &
openscad -o printing/rightcapcap.stl -D part=11 -D textured=true -D angle=180 -D assembled=false -D facets=360 sphere2.scad &

openscad -o printing/leftgear.stl -D part=4 -D textured=true -D angle=0 -D assembled=false -D facets=360 sphere2.scad &
openscad -o printing/rightgear.stl -D part=4 -D textured=true -D angle=0 -D flip=1 -D assembled=false -D facets=360 sphere2.scad &

openscad -o printing/leftmotor_carrier.stl -D part=3 -D textured=true -D angle=0 -D assembled=false -D facets=360 sphere2.scad &
openscad -o printing/rightmotor_carrier.stl -D part=3 -D textured=true -D angle=0 -D flip=1 -D assembled=false -D facets=360 sphere2.scad &

openscad -o printing/bus.stl -D part=2 -D facets=360 sphere2.scad &
openscad -o printing/head_cage.stl -D part=5 -D facets=360 sphere2.scad &


petal=0;
petals=6;

while [ $petal -lt $petals ]
do
	openscad -o printing/petal${petal}.stl -D part=1 -D angle=${petal}*60 -D textured=true -D assembled=false -D facets=360 sphere2.scad &

	petal=`expr $petal + 1`
done
