include <../../configure.scad>




triangle = 5;


m6_tap_rad = 6/2-.5;
m6_rad = 6/2+.5;


face = 27;


washer_rad = 10.1/2+slop;
washer_thick = 1.05;
washer_angle = 9;

corner_tab_rad = 70;

assembled = true;
textured = false;

facets = 30;

%cube([200,200,.1], center=true);

//cone_face();
//rotate([0,0,22.5]) rotate([0,22.5,0]) translate([-rad,0,0]) rotate([0,-90,0]) corner_tab(printing = true);

cuboctahedron_points = [
    [1,1,0],    //0
    [1,-1,0],   //1
    [-1,1,0],   //2
    [-1,-1,0],  //3
    [1,0,1],   //4
    [1,0,-1],  //5
    [-1,0,1],  //6
    [-1,0,-1], //7
    [0,1,1],   //8
    [0,1,-1],  //9
    [0,-1,1],  //10
    [0,-1,-1], //11
    [0,0,0]
];
    


cuboctahedron();
!cuboctahedron_square();

module cuboctahedron_square(){
    %rotate([0,0,45]) cube([300,300,300], center=true);
    intersection(){
        difference(){
            sphere(r=250);
            sphere(r=240);
        }
        
        scale([300,300,300])
        polyhedron(points=cuboctahedron_points, faces=[
            [5,9,7],
            [11,5,7],  //-z bottom face
            [9,12,7],
            [5,12,9],
            [11,12,5],
            [7,12,11],
        ]);
    }
}

module cuboctahedron(){
    cuboctahedron_points = [
    [1,1,0],    //0
    [1,-1,0],   //1
    [-1,1,0],   //2
    [-1,-1,0],  //3
    [1,0,1],   //4
    [1,0,-1],  //5
    [-1,0,1],  //6
    [-1,0,-1], //7
    [0,1,1],   //8
    [0,1,-1],  //9
    [0,-1,1],  //10
    [0,-1,-1], //11
    [0,0,0]     //12
    ];
    
    polyhedron(
  points=cuboctahedron_points,         
  faces=[
    [7,9,5],
    [7,5,11],  //-z bottom face
    
    [6,8,4],
    [6,4,10],  //z top face
    
    [2,3,7],
    [2,6,3],  //-x left face
    
    [0,1,5],
    [0,4,1],  //x right face
    
    [1,3,10],
    [1,11,3],  //-y back face
    
    [0,2,8],
    [0,9,2]  //y front face
    
    //eight triangles
    
    ]
 );
}

if(face <= 25){
    if(assembled == false){
        //this is rotated for printing
        rotate([0,0,-5]) rhombioctahedron_printface(face=face, textured=textured);
    }else{
        //this is assembled as a sphere
        rhombioctahedron_face(face=face, textured=textured);
    }
}

if(face == 26)
    corner_tab(printing=true);

if(face == 27)
    assembly();

module assembly(){
    rhombioctahedron_face(face=7, textured=textured);
    rhombioctahedron_face(face=13, textured=textured);
    rhombioctahedron_face(face=15, textured=textured);
    rhombioctahedron_face(face=22, textured=textured);
    rhombioctahedron_face(face=23, textured=textured);
    rhombioctahedron_face(face=24, textured=textured);
    rhombioctahedron_face(face=25, textured=textured);
    corner_tab_array(printing=true);
    //rhombioctahedron_face(face=face, textured=textured);
    //rhombioctahedron_face(face=face, textured=textured);
}

module cone_face(){
    intersection(){
        cylinder(r=150, h = 500);
        
        bb8_texture_shallow();
    }
}

module screwhole(rad = m4_rad, nut_rad = m4_nut_rad){
    angle=45;
    
    inset = 5;
    straight = 10;
    flare = .75;
    
    translate([0,-1.5,0]){
        translate([0,0,-.1]) cylinder(r=rad, h=wall, $fn=18);
        translate([0,0,inset]) rotate([0,0,angle]) cylinder(r1=nut_rad, r2=nut_rad+flare, h=straight, $fn=4);
        hull(){
            translate([0,0,straight+inset]) rotate([0,0,angle]) cylinder(r=nut_rad+flare, h=.2, $fn=4, center=true);
            translate([0,0,wall*2.5]) rotate([51,0,0]) translate([0,0,straight+inset]) rotate([0,0,angle]) cylinder(r=nut_rad+5, h=.2, $fn=4, center=true);
        }
        //translate([0,0,straight+inset-1]) rotate([30,0,0]) rotate([0,0,angle]) cylinder(r1=nut_rad+flare, r2=nut_rad+3, h=wall*3, $fn=4);
    }
}

module magnethole(rad = m4_rad, nut_rad = m4_nut_rad){
    angle=45;
    
    inset = 1;
    straight = 13;
    flare = .5;
    
    translate([0,-1.5,0]){
        translate([0,0,inset]) rotate([0,0,angle]) cylinder(r1=nut_rad, r2=nut_rad+flare, h=straight+1.4, $fn=4);
    }
}


module washer(){
    cylinder(r=washer_rad, h=washer_thick, center=true);
    hull(){
        translate([0,0,washer_thick/2]) cylinder(r1=washer_rad*.75, r2=1, h=washer_thick/3);
        rotate([180,0,0]) translate([0,0,washer_thick/2]) cylinder(r1=washer_rad*.75, r2=1, h=washer_thick/3);
    }
}

//STL of the full BB8, centered, rotated, scaled, sized, etc.
module bb8_texture(){
    s=6.41;
    //scale([s,s,s]) rotate([0,0,-27.5]) rotate([0,3.6,0]) rotate([29.25,0,0])import("bb8_union_rep_simplified.stl");
    
    scale([s,s,s]) import("body_solid.stl");
}

module bb8_texture_shallow(){
        s=6.41;
    //scale([s,s,s]) rotate([0,0,-27.5]) rotate([0,3.6,0]) rotate([29.25,0,0])import("bb8_union_rep_simplified.stl");

    rotate([12, 44, 111]) union(){
        scale([s,s,s]) import("body_solid.stl");
        sphere(r=rad-.5, $fn=facets);
    }
}

module rhombioctahedron_printface(face=0, textured=false){
    bottom = -rad+39;
    
    if(face >=0 && face <= 7)
        difference(){
            rotate([22.5,0,0])
            rotate([0,0,-45*face]) rhombioctahedron_face(face=face, textured=textured);
        }
    
    //meridianal faces
    if(face > 7 && face <= 10)
        if(face == 8 || face == 10){
            difference(){
                rotate([22.5,0,0])  rotate([-(face-7)*45,0,0]) rhombioctahedron_face(face=face, textured=textured);
            }
        }else{
            difference(){
                //translate([0,0,bottom]) 
                rotate([22.5,0,0]) rotate([-(face-7)*45,0,0]) rhombioctahedron_face(face=face, textured=textured);
                //a little bottom flattening
                translate([0,0,-100]) cube([200,200,200], center=true);
            }
        }
    if(face > 10 && face <= 13)
        if(face == 11 || face == 13){
            difference(){
                rotate([22.5,0,0]) rotate([0,90,0]) rotate([-(face-6)*45,0,0]) rhombioctahedron_face(face=face, textured=textured);
            }
        }else{
            difference(){
                rotate([22.5,0,0]) rotate([-(face-6)*45,0,0]) rhombioctahedron_face(face=face, textured=textured);
            }   
        }
    
    if(face > 13 && face <= 17)
        difference(){
            rotate([22.5,0,0]) rotate([0,0,-45-(face-13)*90]) rotate([-90,0,0]) rhombioctahedron_face(face=face, textured=textured);
        }
    
    //triangles
    if(face > 17 && face <= 21)
        difference(){
            //printing orientation: rotate([0,0,90*(face-18)]) triangle_face();
            rotate([-22.5,0,0]) rotate([0,0,45]) rotate([0,0,-90*(face-18)]) rhombioctahedron_face(face=face, textured=textured);
        }
    if(face == 22 || face == 24)
        {
            //rotate([-22.5,0,0]) rotate([0,0,45]) mirror([0,0,1]) rotate([0,0,-90*(face-18)]) rhombioctahedron_face(face=face, textured=textured);
            //printing orientation: rotate([180,0,0]) rotate([0,0,90*(face-19)]) triangle_face();
            echo(face);
            echo(90*(25-face));
            rotate([0,0,-90]) rotate([0,-22.5,0]) rotate([0,0,45]) rotate([-180,0,0]) rotate([0,0,90*(25-face)]) rhombioctahedron_face(face=face, textured=textured);
        }
        
        if(face == 23 || face == 25)
        {
            //rotate([-22.5,0,0]) rotate([0,0,45]) mirror([0,0,1]) rotate([0,0,-90*(face-18)]) rhombioctahedron_face(face=face, textured=textured);
            //printing orientation: rotate([180,0,0]) rotate([0,0,90*(face-19)]) triangle_face();
            echo(face);
            echo(90*(25-face));
            rotate([0,0,90]) rotate([0,22.5,0]) rotate([0,0,45]) rotate([-180,0,0]) rotate([0,0,90*(25-face)]) rhombioctahedron_face(face=face, textured=textured);
        }
}

module rhombioctahedron_face(face=0, textured=false){
    difference(){
    intersection(){
        union(){
            //equatorial faces
            if(face >=0 && face <= 7)
                rotate([0,0,45*face]) square_face();
            
            //meridianal faces
            if(face > 7 && face <= 10)
                rotate([(face-7)*45,0,0]) square_face();
            if(face > 10 && face <= 13)
                rotate([(face-6)*45,0,0]) square_face();
            
            if(face > 13 && face <= 17)
                rotate([90,0,0]) rotate([0,0,45+(face-13)*90]) square_face();
        
            //triangles
            if(face > 17 && face <= 21)
                rotate([0,0,90*(face-18)]) triangle_face();
            if(face > 21 && face <= 25){
                rotate([180,0,0]) rotate([0,0,90*(face-22)]) triangle_face();
                echo(90*(face-22));
            }
        }
        
        if(textured==true){
            bb8_texture_shallow();
        }else{
            sphere(r=rad, $fn=facets);
        }
    }
    
    //to ensure global hole matching, we subtract ALL holes here.
    corner_tab_array();
    }
}

module rhombioctahedron(){
    //%cylinder(r=150, h=600, center=true);
    %cube([200,200,600], center=true);
    intersection(){
        union(){
            for(i=[0:45:359]) rotate([0,0,i]) 
                 translate([0,1,0]) square_face();
            for(i=[45:45:179]) rotate([i,0,0]) 
                translate([0,1,0]) square_face();
            for(i=[225:45:359]) rotate([i,0,0]) 
                translate([0,1,0]) square_face();
            for(i=[45:90:359]) rotate([90,0,0]) rotate([0,0,i]) 
                translate([0,1,0]) square_face();
        
            //triangles
            for(i=[0:90:359]) rotate([0,0,i])
                translate([1,1,1]) triangle_face();
            for(i=[0:90:359]) mirror([0,0,1]) rotate([0,0,i])
                translate([1,1,1]) triangle_face();
        }
        
        bb8_texture_shallow();

    }
}

module corner_tab_array(printing=false){
    //these hit the corners of panels 0, 2, 4 and 6
    for(i=[0:90:359]) rotate([0,0,i]) {
        rotate(a=30, v=[1,0,1]) translate([0,rad,0]) rotate([-90,0,0]) corner_tab(printing=printing);
        rotate(a=30, v=[-1,0,-1]) translate([0,rad,0]) rotate([-90,0,0]) corner_tab(printing=printing);
        rotate(a=30, v=[1,0,-1]) translate([0,rad,0]) rotate([-90,0,0]) corner_tab(printing=printing);
        rotate(a=30, v=[-1,0,1]) translate([0,rad,0]) rotate([-90,0,0]) corner_tab(printing=printing);
    }
    
    //this does the top and bottom
    for(i=[90:180:359]) rotate([i,0,0]) {
        rotate(a=30, v=[1,0,1]) translate([0,rad,0]) rotate([-90,0,0]) corner_tab(printing=printing);
        rotate(a=30, v=[-1,0,-1]) translate([0,rad,0]) rotate([-90,0,0]) corner_tab(printing=printing);
        rotate(a=30, v=[1,0,-1]) translate([0,rad,0]) rotate([-90,0,0]) corner_tab(printing=printing);
        rotate(a=30, v=[-1,0,1]) translate([0,rad,0]) rotate([-90,0,0]) corner_tab(printing=printing);
    }
    
}

module corner_tab_holes(tap = true){
    side = corner_tab_rad;
    screw_rad = (tap)?4/2+slop:5/2+slop;
    screw_cap_rad = 10/2;
    screw_cap_height = 2.25;
    cap_offset = 1-.5;
    
    for(i=[0:1]) for(j=[0:1]) mirror([i,0,0]) mirror([0,j,0]) translate([side/3.75, side/3.75,0]){
        cylinder(r=screw_rad, h=wall*3, center=true, $fn=facets);
        
        //cap
        translate([0,0,cap_offset]){
            cylinder(r1=screw_rad, r2=screw_cap_rad, h=screw_cap_height, $fn=facets);
            translate([0,0,screw_cap_height-.01]) cylinder(r=screw_cap_rad, h=wall, $fn=facets);
        }
    }
}

module corner_tab(printing = 1){
    side = corner_tab_rad;
    inset = -wall-1;
    height = wall/2+abs(inset/2);
    slope = 5;
    
    if(printing == true){
        difference(){
            union(){
                translate([0,0,inset]) cylinder(r1=side/2+slope, r2=side/2, h=height, center=true, $fn = facets);
                translate([0,0,inset]) cylinder(r1=side/2+slope+slope, r2=side/2+slope, h=height, center=true, $fn = 3);
            }
            
            //curve the inner side
            translate([0,0,-rad]) sphere(r=rad-wall, $fn=facets);
            
            translate([0,0,inset+height/2]) corner_tab_holes(tap = true, side=side);
        }
    }else{
        union(){
            difference(){
                union(){
                    translate([0,0,inset]) cylinder(r1=side/2+slope+slop*2, r2=side/2+slop*2, h=height+slop*2, center=true, $fn = facets);
                    translate([0,0,inset]) cylinder(r1=side/2+slope+slope+slop*2, r2=side/2+slope+slop*2, h=height, center=true, $fn = 3);
                }
                
                //curve the inner side
                translate([0,0,-rad-wall]) sphere(r = rad-wall, $fn = facets);
            }
            translate([0,0,inset+height/2]) corner_tab_holes(tap = false, side=side);
        }
    }
}

module square_face(){
    face = rad;
    difference(){
        union(){
            intersection(){
                rotate([-45/2,0,0]) translate([-face/2,0,0]) cube([face,face,face]);
                rotate([-135/2,0,0]) translate([-face/2,0,0]) cube([face,face,face]);
                rotate([0,90,0]) rotate([-45/2,0,0]) translate([-face/2,0,0]) cube([face,face,face]);
                rotate([0,90,0]) rotate([-135/2,0,0]) translate([-face/2,0,0]) cube([face,face,face]);
            }
            
            *for(i=[0:90:359]) for(j=[0:1]) mirror([j,0,0]) rotate([0,i,0]) rotate([-22.5,0,0]) rotate([0,0,washer_angle]) translate([0,rad-wall,0]) rotate([90,0,0]) screw_tab(solid=1, tab=j);
        }
        //hollow out the inside
        sphere(r=rad-wall, $fn=facets);
    }
}

module triangle_face(){
    face = rad;
    difference(){
        intersection(){
            rotate([45,0,0]) rotate([0,0,-45])
                rotate([0,90,0]) rotate([-45/2,0,0]) translate([-face/2,0,0]) cube([face,face,face]);
        
            rotate([0,0,-45]) rotate([45,0,0])
                rotate([-45/2,0,0]) translate([-face/2,0,0]) cube([face,face,face]);
        
            rotate([0,0,-45-45]) rotate([45,0,0]) rotate([0,0,45]) 
                rotate([0,90,0]) rotate([-135/2,0,0]) translate([-face/2,0,0]) cube([face,face,face]);
        }
        
        //hollow out the inside
        sphere(r=rad-wall, $fn=facets);
    }
}