#!/bin/sh

openscad -o printing/leftcap.stl -D part=0 -D textured=true -D angle=0 -D assembled=false sphere2.scad &
openscad -o printing/rightcap.stl -D part=0 -D textured=true -D angle=180 -D assembled=false sphere2.scad &

petal=0;
petals=6;

while [ $petal -lt $petals ]
do
	echo $petal

	openscad -o printing/petal${petal}.stl -D part=1 -D angle=${petal}*60 -D textured=true -D assembled=false sphere2.scad &

	petal=`expr $petal + 1`
done
