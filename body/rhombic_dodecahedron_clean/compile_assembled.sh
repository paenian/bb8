#!/bin/sh

face=0;
faces=26;

while [ $face -lt $faces ]
do
	echo $face
	openscad -o assembled/face${face}.stl -D face=${face} -D textured=true -D assembled=true -D facets=180 sphere.scad &
	face=`expr $face + 1`

        echo $face
        openscad -o assembled/face${face}.stl -D face=${face} -D textured=true -D assembled=true -D facets=180 sphere.scad &
        face=`expr $face + 1`

        echo $face
        openscad -o assembled/face${face}.stl -D face=${face} -D textured=true -D assembled=true -D facets=180 sphere.scad &
        face=`expr $face + 1`

        echo $face
        openscad -o assembled/face${face}.stl -D face=${face} -D textured=true -D assembled=true -D facets=180 sphere.scad
        face=`expr $face + 1`

done
