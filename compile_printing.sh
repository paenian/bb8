#!/bin/sh

face=0;
faces=26;

while [ $face -lt $faces ]
do
	echo $face

	openscad -o printing/face${face}.stl -D face=${face} sphere.scad

	face=`expr $face + 1`
done
