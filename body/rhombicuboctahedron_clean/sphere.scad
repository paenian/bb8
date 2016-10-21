include <../../configure.scad>




triangle = 5;


m6_tap_rad = 6/2-.5;
m6_rad = 6/2+.5;


face = 2;

washer_rad = 10.1/2+slop;
washer_thick = 1.05;
washer_angle = 9;

assembled = false;
textured = false;

%cube([200,200,.1], center=true);

//cone_face();

if(assembled == false){
    //this is rotated for printing
    rotate([0,0,-5]) rhombioctahedron_printface(face=face, textured=textured);
}else{
    //this is assembled as a sphere
    rhombioctahedron_face(face=face, textured=textured);
}

module cone_face(){
    intersection(){
        cylinder(r=150, h = 500);
        
        bb8_texture();
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
    s=6.51;
    //scale([s,s,s]) rotate([0,0,-27.5]) rotate([0,3.6,0]) rotate([29.25,0,0])import("bb8_union_rep_simplified.stl");
    
    scale([s,s,s]) import("body_solid.stl");
}

//rhombioctahedron();

module rhombioctahedron_printface(face=0, textured=false){
    if(face >=0 && face <= 7)
        translate([0,0,-rad+40]) rotate([90,0,0]) rotate([0,0,-45*face]) rhombioctahedron_face(face=face, textured=textured);
    
    //meridianal faces
    if(face > 7 && face <= 10)
        if(face == 8 || face == 10){
            rotate([22.5,0,0]) rotate([0,90,0])  rotate([-(face-7)*45,0,0]) rhombioctahedron_face(face=face, textured=textured);
        }else{
            rotate([22.5,0,0]) rotate([-(face-7)*45,0,0]) rhombioctahedron_face(face=face, textured=textured);
        }
    if(face > 10 && face <= 13)
        if(face == 11 || face == 13){
            rotate([22.5,0,0]) rotate([0,90,0]) rotate([-(face-6)*45,0,0]) rhombioctahedron_face(face=face, textured=textured);
        }else{
            rotate([22.5,0,0]) rotate([-(face-6)*45,0,0]) rhombioctahedron_face(face=face, textured=textured);
        }
    
    if(face > 13 && face <= 17)
        rotate([22.5,0,0]) rotate([0,0,-45-(face-13)*90]) rotate([-90,0,0]) rhombioctahedron_face(face=face, textured=textured);
    
    //triangles
    if(face > 17 && face <= 21)
        rotate([-22.5,0,0]) rotate([0,0,45]) rotate([0,0,-90*(face-18)]) rhombioctahedron_face(face=face, textured=textured);
    if(face > 21 && face <= 25)
        rotate([-22.5,0,0]) rotate([0,0,45]) mirror([0,0,1]) rotate([0,0,-90*(face-18)]) rhombioctahedron_face(face=face, textured=textured);
}

module rhombioctahedron_face(face=0, textured=false){
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
            if(face > 21 && face <= 25)
                mirror([0,0,1]) rotate([0,0,90*(face-18)]) triangle_face();
        }
        
        if(textured==true){
            bb8_texture();
        }else{
            sphere(r=rad, $fn=180);
        }

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
        
        bb8_texture();

    }
}

module screw_tab(tab=1, solid=1){
    tab_rad = wall;
    facets = 6;
    
    tap_rad = 6/2;
    screw_rad = 7/2;
    screw_cap_rad = 11/2;
    
    intersection(){
        cube([side, side, wall], center=true);
    }
    
    if(tab == 1){
        if(solid == 1){
            rotate([0,0,0/facets]) cylinder(r=tab_rad, h=wall, $fn=facets, center=true);
        }
        if(solid == 0){
            //small screwhole
            translate([0,-tab_rad/2,-.1]) cylinder(r=tap_rad, h=wall*5, center=true);
        }
    }
    
    if(tab == 0){
        if(solid == 0){
            rotate([0,0,0/facets]) cylinder(r=tab_rad+slop*2, h=wall+slop, $fn=facets, center=true);
        }
        if(solid == 0){
            
            //big screwhole, plus a nice conic cap
            translate([0,tab_rad/2,-.1]) cylinder(r=screw_rad, h=wall*2, center=true);
            translate([0,tab_rad/2,-wall+1]) cylinder(r2=screw_rad, r1=screw_cap_rad, h=wall/4, center=true);
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
            
            for(i=[0:90:359]) for(j=[0:1]) mirror([j,0,0]) rotate([0,i,0]) rotate([-22.5,0,0]) rotate([0,0,washer_angle]) translate([0,rad-wall,0]) rotate([90,0,0]) screw_tab(solid=1, tab=j);
        }
        //hollow out the inside
        sphere(r=rad-wall, $fn=180);
        
        //print the inset tab
        for(i=[0:90:359]) for(j=[0:1]) mirror([j,0,0]) rotate([0,i,0]) rotate([-22.5,0,0]) rotate([0,0,washer_angle]) translate([0,rad-wall,0]) rotate([90,0,0]) screw_tab(tab=j, solid=0);
        
        
        
        //screwholes
        /*for(i=[0:90:359]) rotate([0,i,0])
            rotate([-22.5,0,0]) translate([0,rad-wall/2,-.1]) screwhole();
        */
        
        //washer slots - two per face, in the corners.
        /*for(k=[0,1]) for(j=[-1,1]) for(i=[0,1]) rotate([0,90*k,0]) rotate([0,90*j,0])mirror([i,0,0]) {
            rotate([-22.5,0,0]) rotate([0,0,washer_angle]) translate([0,rad-wall/2,0]) screwhole(); //rotate([90,0,0]) washer();
        }*/
        
        
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
        sphere(r=rad-wall, $fn=180);
        
        //screwholes
        /*
        rotate([0,0,-45])  
        rotate([45,0,0])
        rotate([-22.5,0,0]) translate([0,rad-wall/2,-.1]) screwhole();
        
        rotate([45,0,0])
        rotate([0,-90,0])
        rotate([-22.5,0,0]) mirror([0,0,1]) translate([0,rad-wall/2,-.1]) magnethole();
        
        rotate([0,-45,0])
        rotate([0,0,-90])
        rotate([0,90,0])
        rotate([-22.5,0,0]) mirror([0,0,1]) translate([0,rad-wall/2,-.1]) magnethole();
        */
        
        //washer slots in the triangles?  Probably shouldn't put them in.., then the triangles become the access holes?
        for(i=[0,1]) rotate([0,0,-45]) rotate([45,0,0]) mirror([i,0,0]) rotate([-22.5,0,0]) rotate([0,0,washer_angle]) translate([0,rad-wall/2,0]) magnethole();  //rotate([90,0,0]) washer();
        
        for(i=[0,1]) rotate([45,0,0]) rotate([0,-90,0]) mirror([i,0,0]) rotate([-22.5,0,0]) rotate([0,0,washer_angle]) translate([0,rad-wall/2,0]) mirror([0,0,1]) magnethole();  //rotate([90,0,0]) washer();
            
        for(i=[0,1]) rotate([0,-45,0]) rotate([0,0,-90]) rotate([0,90,0]) mirror([i,0,0]) rotate([-22.5,0,0]) rotate([0,0,washer_angle]) translate([0,rad-wall/2,0]) mirror([0,0,1]) magnethole();  //rotate([90,0,0]) washer();
    }
}

*difference(){
    rotate([116.565+5.1-slop,0,0]) dodecasphere();
    translate([0,0,-100]) cube([2000,2000,200], center=true);
}

*tetrasphere();

angle = -116.565/2-5.1;
*translate([1000,0,0]){
    dodecasphere();
    rotate([angle,0,0]) rotate([0,0,72/2]) dodecasphere();
    rotate([0,0,72]) rotate([angle,0,0]) rotate([0,0,72/2]) dodecasphere();
    rotate([0,0,72*2]) rotate([angle,0,0]) rotate([0,0,72/2]) dodecasphere();
    rotate([0,0,72*3]) rotate([angle,0,0]) rotate([0,0,72/2]) dodecasphere();
    rotate([0,0,72*4]) rotate([angle,0,0]) rotate([0,0,72/2]) dodecasphere();
    
    *rotate([0,0,72/2]) mirror([0,0,1]) {
        dodecasphere();
        rotate([angle,0,0]) rotate([0,0,72/2]) dodecasphere();
        rotate([0,0,72]) rotate([angle,0,0]) rotate([0,0,72/2]) dodecasphere();
        rotate([0,0,72*2]) rotate([angle,0,0]) rotate([0,0,72/2]) dodecasphere();
        rotate([0,0,72*3]) rotate([angle,0,0]) rotate([0,0,72/2]) dodecasphere();
        rotate([0,0,72*4]) rotate([angle,0,0]) rotate([0,0,72/2]) dodecasphere();
    }
}

module tetrasphere(){
    trad = 500+200;
    
    intersection(){
        difference(){
            sphere(r=rad, $fn=90);
            sphere(r=rad-wall, $fn=90);
        }
    
        angle = -109.4712;
        
        a2 = 70.5288/2;
    
        //tetrahedron?
        union(){
            
            *cylinder(r1=0, r2=trad, h=rad, $fn=3);
        *rotate([0,angle,0]) rotate([0,0,60]) cylinder(r1=0, r2=trad, h=rad, $fn=3);
        *rotate([0,0,-120]) rotate([0,angle,0]) rotate([0,0,60]) cylinder(r1=0, r2=trad, h=rad, $fn=3);
        *rotate([0,0,120]) rotate([0,angle,0]) rotate([0,0,60]) cylinder(r1=0, r2=trad, h=rad, $fn=3);
        
        //better tetrahedral section: three cubes intersected
        intersection(){
            rotate([a2,0,0]) translate([0,0,-500]) cube([1000,1000,1000], center=true);
            rotate([0,0,120]) rotate([a2,0,0]) translate([0,0,-500]) cube([1000,1000,1000], center=true);
            rotate([0,0,-120])rotate([a2,0,0]) translate([0,0,-500]) cube([1000,1000,1000], center=true);
        }
        
    }
    }
}

module dodecasphere(){
    difference(){
        intersection(){
            difference(){
                sphere(r=rad, $fn=90);
                sphere(r=rad-wall, $fn=90);
            }
    
        
            angle = 116.565/2;
    
            //better tetrahedral section: three cubes intersected
            intersection(){
                rotate([0,0,0]) rotate([angle+slop,0,0]) translate([0,0,-500]) cube([1000,1000,1000], center=true);
                rotate([0,0,360/5]) rotate([angle+slop,0,0]) translate([0,0,-500]) cube([1000,1000,1000], center=true);
                rotate([0,0,360/5*2]) rotate([angle+slop,0,0]) translate([0,0,-500]) cube([1000,1000,1000], center=true);
                rotate([0,0,360/5*3]) rotate([angle+slop,0,0]) translate([0,0,-500]) cube([1000,1000,1000], center=true);
                rotate([0,0,360/5*4]) rotate([angle+slop,0,0]) translate([0,0,-500]) cube([1000,1000,1000], center=true);
            }
        }
        
        //screwholes
        for(i=[0:72:359]) rotate([0,0,i]) {
            rotate([angle/2,0,0]) translate([0,0,-rad+wall/2]) rotate([-90,0,0]){
                cylinder(r=m3_rad, h=50, center=true, $fn=36);
                #rotate([0,0,30]) translate([0,0,wall]) cylinder(r1=m3_nut_rad, r2=m3_nut_rad+1, h=40, $fn=6);
                %rotate([0,0,30]) translate([0,0,-wall]) cylinder(r1=m3_nut_rad, r2=m3_nut_rad+.5, h=40, $fn=6);
            }
        }
    }
}
