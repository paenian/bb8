include <../../configure.scad>



//this is a rhombic dodecahedron.

//polygon([[0,0],[100,0],[130,50],[30,50]], paths=[[0,1,2,3]]);

dodecahedron_points = [
    [1,1,1],    //0
    [1,1,-1],   //1
    [1,-1,1],   //2
    [1,-1,-1],  //3
    [-1,1,1],   //4
    [-1,1,-1],  //5
    [-1,-1,1],  //6
    [-1,-1,-1], //7
    [0,0,2],    //8
    [0,0,-2],   //9
    [0,2,0],    //10
    [0,-2,0],   //11
    [2,0,0],    //12
    [-2,0,0],   //13
    [0,0,0]     //14
    ];

$fn=120;

translate([0,-5,0]) dodecahedron();

rotate([0,0,45]) translate([0,0,-170]) rotate([45,0,0]) scale([250,250,250]) dodecasphere();


%cube([300,600,.1], center=true);
%cube([300,300,.2], center=true);

module dodecahedron(face=0){
polyhedron(
  points=dodecahedron_points, 
        /*[
        [1,1,1],
        [0,2,0],
        [0,0,2],
        [-1,1,1],     // the four points of the rhombis
        [0,0,0]  ],    // the apex point */
        
  faces=[
    [0,10,14],
    [10,4,14],
    [4,8,14],
    [8,0,14],              // each triangle side
    [0,4,10],
    [0,8,4]
    ]                         // two triangles for square base
 );
}

module dodecasphere(face = 0){
    intersection(){
        difference(){
            sphere(r=1);
            sphere(r=.9);
        }
        
        dodecahedron(face = face);
    }
}