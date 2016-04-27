rad=508/2;
wall=10;

triangle = 5;


slop = .2;

//standard screw variables
m3_nut_rad = 6.01/2+slop;
m3_nut_height = 2.4;
m3_rad = 3/2+slop;
m3_cap_rad = 3.25;
m3_cap_height = 2;

s=6.51;

face = 18;

assembled = true;



if(assembled == false){
    //this is rotated for printing
    rhombioctahedron_printface(face=face);
}else{
    //this is assembled as a sphere
    rhombioctahedron_face(face=face);
}



//rhombioctahedron();

module rhombioctahedron_printface(face=0){
    if(face >=0 && face <= 7)
        rotate([22.5,0,0]) rotate([0,0,-45*face]) rhombioctahedron_face(face=face);
    
    //meridianal faces
    if(face > 7 && face <= 10)
        rotate([22.5,0,0]) rotate([-(face-7)*45,0,0]) rhombioctahedron_face(face=face);
    if(face > 10 && face <= 13)
        rotate([22.5,0,0]) rotate([-(face-6)*45,0,0]) rhombioctahedron_face(face=face);
    
    if(face > 13 && face <= 17)
        rotate([22.5,0,0]) rotate([0,0,-45-(face-13)*90]) rotate([-90,0,0]) rhombioctahedron_face(face=face);
    
    //triangles
    if(face > 17 && face <= 21)
        rotate([-22.5,0,0]) rotate([0,0,45]) rotate([0,0,-90*(face-18)]) rhombioctahedron_face(face=face);
    if(face > 21 && face <= 25)
        rotate([-22.5,0,0]) rotate([0,0,45]) mirror([0,0,1]) rotate([0,0,-90*(face-18)]) rhombioctahedron_face(face=face);
}

module rhombioctahedron_face(face=0){
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
        
        scale([s,s,s]) rotate([0,0,-27.5]) rotate([0,3.6,0]) rotate([29.25,0,0])import("bb8_union_rep.stl");

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
        
        scale([s,s,s]) rotate([0,0,-27.5]) rotate([0,3.6,0]) rotate([29.25,0,0])import("bb8_union_rep.stl");

    }
}

module square_face(){
    face = rad;
    difference(){
        intersection(){
            rotate([-45/2,0,0]) translate([-face/2,0,0]) cube([face,face,face]);
            rotate([-135/2,0,0]) translate([-face/2,0,0]) cube([face,face,face]);
            rotate([0,90,0]) rotate([-45/2,0,0]) translate([-face/2,0,0]) cube([face,face,face]);
            rotate([0,90,0]) rotate([-135/2,0,0]) translate([-face/2,0,0]) cube([face,face,face]);
        }
        sphere(r=rad-wall, $fn=90);
        
        //screwholes
        for(i=[0:90:359]) rotate([0,i,0])
            rotate([-22.5,0,0]) translate([0,rad-wall/2,-.1]){
                cylinder(r=m3_rad, h=wall, $fn=18);
                translate([0,0,wall/2]) cylinder(r1=m3_nut_rad, r2=m3_nut_rad+1, h=wall*1.25, $fn=4);
                translate([0,0,wall*1.5]) rotate([-15,0,0]) cylinder(r1=m3_nut_rad+1, r2=m3_nut_rad+2, h=wall*3, $fn=4);
            }
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
        sphere(r=rad-wall, $fn=90);
        
        //screwholes
        #rotate([0,0,0]) rotate([0,0,-45]) rotate([45,0,0]) for(i=[0:120:359]) rotate([0,i,0])
            rotate([-15.5,0,0]) translate([0,rad-wall/2,-.1]){
                cylinder(r=m3_rad, h=wall, $fn=18);
                translate([0,0,wall/2]) cylinder(r1=m3_nut_rad, r2=m3_nut_rad+1, h=wall*1.25, $fn=4);
                translate([0,0,wall*1.5]) rotate([-15,0,0]) cylinder(r1=m3_nut_rad+1, r2=m3_nut_rad+2, h=wall*3, $fn=4);
            }
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
