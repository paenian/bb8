rad=250;
wall=10;

triangle = 5;



tetrasphere();

module tetrasphere(){
    trad = 500+200;
    
    intersection(){
        difference(){
            sphere(r=rad);
            sphere(r=rad-wall);
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

translate([1000,0,0]){
    dodecasphere();
    
    rotate([-116.565/2,0,0]) rotate([0,0,72/2]) dodecasphere();
    rotate([0,0,72]) rotate([-72,0,0]) rotate([0,0,72/2]) dodecasphere();
    rotate([0,0,72*2]) rotate([-72,0,0]) rotate([0,0,72/2]) dodecasphere();
    rotate([0,0,72*3]) rotate([-72,0,0]) rotate([0,0,72/2]) dodecasphere();
    rotate([0,0,72*4]) rotate([-72,0,0]) rotate([0,0,72/2]) dodecasphere();
    
    #rotate([0,0,72]) rotate([-72,0,0]) rotate([0,0,72/2]) dodecasphere();
    
}

module dodecasphere(){
    trad = 500+200;
    
    intersection(){
        difference(){
            sphere(r=rad);
            sphere(r=rad-wall);
        }
    
        
        angle = 116.565/2;
    
        //better tetrahedral section: three cubes intersected
        intersection(){
            //for(i=[0:360/5:100]){
            rotate([0,0,0]) rotate([angle,0,0]) translate([0,0,-500]) cube([1000,1000,1000], center=true);
            rotate([0,0,360/5]) rotate([angle,0,0]) translate([0,0,-500]) cube([1000,1000,1000], center=true);
            rotate([0,0,360/5*2]) rotate([angle,0,0]) translate([0,0,-500]) cube([1000,1000,1000], center=true);
            rotate([0,0,360/5*3]) rotate([angle,0,0]) translate([0,0,-500]) cube([1000,1000,1000], center=true);
            rotate([0,0,360/5*4]) rotate([angle,0,0]) translate([0,0,-500]) cube([1000,1000,1000], center=true);
        //}
        
    }
    }
}
