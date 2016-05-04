@echo off
setlocal 

echo Compiling Square...
openscad.exe -o body/printing2/square_notexture.stl -D assembled=false -D textured=false -D face=0 body/sphere2.scad

echo Compiling Triangle...
openscad.exe -o body/printing2/triangle_notexture.stl -D assembled=false -D textured=false -D face=19 body/sphere2.scad


FOR /L %%A IN (0,1,25) DO (
  echo Compiling Face %%A
  openscad.exe -o body/printing2/face%%A.stl -D assembled=false -D textured=true -D face=%%A body/sphere2.scad
)
