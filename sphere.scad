rad=125;
wall=10;

triangle = 5;


slop = .2;

//standard screw variables
m3_nut_rad = 6.01/2+slop;
m3_nut_height = 2.4;
m3_rad = 3/2+slop;
m3_cap_rad = 3.25;
m3_cap_height = 2;


!difference(){
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
