#!/bin/sh

face=0;
faces=26;

while [ $face -lt $faces ]
do
	echo $face

	openscad -o assembled/face${face}.stl -D assembled=true -D textured=true -D face=${face} sphere.scad

	face=`expr $face + 1`
done
