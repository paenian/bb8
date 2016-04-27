@echo off
setlocal 

echo Compiling Square...
openscad -o printing/square_notexture.stl -D assembled=false -D textured=false -D face=0 sphere.scad

echo Compiling Triangle...
openscad -o printing/triangle_notexture.stl -D assembled=false -D textured=false -D face=19 sphere.scad


FOR /L %%A IN (0,1,25) DO (
  echo Compiling Face %%A
  openscad -o printing/face%%A.stl -D assembled=false -D textured=true -D face=%%A sphere.scad
)