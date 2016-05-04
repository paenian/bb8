@echo off
setlocal 

FOR /L %%A IN (0,1,25) DO (
  echo Compiling Face %%A
  openscad -o printing/face%%A_notexture.stl -D assembled=true -D textured=true -D face=%%A sphere.scad
)


FOR /L %%A IN (0,1,25) DO (
  echo Compiling Face %%A
  openscad -o printing/face%%A.stl -D assembled=true -D textured=true -D face=%%A sphere.scad
)