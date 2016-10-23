#!/bin/sh

openscad -o printing/square.stl -D face=0 -D textured=false -D assembled=false sphere.scad &

openscad -o printing/triangle.stl -D face=19 -D textured=false -D assembled=false sphere.scad &

face=0;
faces=26;

while [ $face -lt $faces ]
do
	echo $face
	openscad -o printing/face${face}.stl -D face=${face} -D textured=true -D assembled=false sphere.scad &
	face=`expr $face + 1`

        echo $face
        openscad -o printing/face${face}.stl -D face=${face} -D textured=true -D assembled=false sphere.scad &
        face=`expr $face + 1`

        echo $face
        openscad -o printing/face${face}.stl -D face=${face} -D textured=true -D assembled=false sphere.scad
        face=`expr $face + 1`

        echo $face
        openscad -o printing/face${face}.stl -D face=${face} -D textured=true -D assembled=false sphere.scad
        face=`expr $face + 1`

done
