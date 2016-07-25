#!/bin/sh

openscad -o top.stl -D part=0 -D facets=120 controller.scad &
openscad -o bot.stl -D part=1 -D facets=120 controller.scad &
