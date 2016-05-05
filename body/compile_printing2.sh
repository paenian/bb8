echo Compiling Square...
openscad -o printing2/square_notexture.stl -D assembled=false -D textured=false -D face=0 sphere2.scad &

echo Compiling Triangle...
openscad -o printing2/triangle_notexture.stl -D assembled=false -D textured=false -D face=19 sphere2.scad &

face=0;
faces=26;

while [ $face -lt $faces ]
do
  echo Compiling Face $face
  openscad -o printing2/face${face}.stl -D assembled=false -D textured=true -D face=${face} sphere2.scad

  face=`expr $face + 1`

done
