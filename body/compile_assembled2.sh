face=0;
faces=26;

while [ $face -lt $faces ]
do
  echo Compiling Face $face
  openscad -o assembled2/face${face}.stl -D assembled=true -D textured=true -D face=${face} sphere2.scad

  face=`expr $face + 1`

done
