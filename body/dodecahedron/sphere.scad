gold = (1 + sqrt(5))/2;

dodecahedron_points = [  [0,0,0],
            [1,1,1],    //1
            [1,1,-1],   //2
            [1,-1,1],   //3
            [1,-1,-1],  //4
            [-1,1,1],   //5
            [-1,1,-1],  //6
            [-1,-1,1],  //7
            [-1,-1,-1], //8
            
            [0,gold,1/gold],    //9
            [0,gold,-1/gold],   //10
            [0,-gold,1/gold],   //11
            [0,-gold,-1/gold],  //12
            
            [1/gold,0,gold],    //13
            [1/gold,0,-gold],   //14
            [-1/gold,0,gold],   //15
            [-1/gold,0,-gold],  //16
            
            [gold,1/gold,0],    //17
            [gold,-1/gold,0],   //18
            [-gold,1/gold,0],   //19
            [-gold,-1/gold,0]];  //20
            
dodecahedron();
mirror([0,1,0]) dodecahedron(); 

rad = 250;
wall = 10;
$fn=60;


!face();

module face(){
    difference(){
        intersection(){
            sphere(r=rad);
            scale([rad+1, rad+1, rad+1]) dodecahedron();

        }
            
        //sphere(r=rad-wall);
    }
}

 module dodecahedron(){
     polyhedron( points = dodecahedron_points, faces = [
        //[7,15,13,3,11],
     
        [7,15,13],
        [7,13,3],
        [7,3,13],
        [7,3,11],
     
        [0,7,15],
        [0,15,13],
        [0,13,3],
        [0,3,11],
        [0,11,7],
     ], convexity = 10);
 }