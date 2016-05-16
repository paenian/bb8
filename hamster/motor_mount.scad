include <../configure.scad>

motor_mount();
$fn=72;
module motor_mount(height=20, screw_sep = motor_mount_screw_sep, solid=1){
    wall = 5;
    clamp_height = 12;
    offset = 2;
    difference(){
        union(){
            hull(){
                //motor
                translate([offset,0,0]) cylinder(r=motor_rad+wall-1, h=height, center=true);
            
                //base
                translate([0,-motor_rad-wall-wall,0]) for(i=[0,1])
                translate([i*screw_sep/2,0,0]) rotate([-90,0,0]) scale([.5,1,1]) rotate([0,0,22.5]) cylinder(r=(height/2)/cos(180/8), h=wall*2, $fn=8);
            }
            translate([offset,0,0]) hull(){
                //motor
                cylinder(r=motor_rad+wall-1, h=height, center=true);
                
                //clamp material
                translate([0,motor_rad+clamp_height/2,0]) cube([wall*5,clamp_height,height], center=true);
            }
            
            if(solid==-1){
                //base holes
                translate([0,-motor_rad-wall*2,0]) for(i=[0,1]) {
                    translate([i*screw_sep/2,-1,0]) rotate([-90,0,0]) cylinder(r=m4_rad, h=height*2, center=true);
                    translate([i*screw_sep/2,wall,0]) rotate([-90,0,0]) cylinder(r1=m4_cap_rad, r2=m4_cap_rad+2, h=height*2);
                    
                    translate([i*screw_sep/2,-wall,0]) rotate([90,0,0]) cylinder(r1=m4_square_nut_rad, r2=m4_square_nut_rad+2, h=height*2, $fn=4);
                }
            }
        }
        
        //motor hole
        translate([offset,0,0]) cylinder(r=motor_rad, h=height+1, center=true);
        
        //base holes
        if(solid==1){
            translate([0,-motor_rad-wall*2,0]) for(i=[0,1]) {
                translate([i*screw_sep/2,-1,0]) rotate([-90,0,0]) cylinder(r=m4_rad, h=height);
                translate([i*screw_sep/2,wall,0]) rotate([-90,0,0]) cylinder(r1=m4_cap_rad, r2=m4_cap_rad+2, h=height);
            }
        }
        
        //clamp slit
        translate([offset,motor_rad,0]) cube([wall/2, height*2, motor_rad*2], center=true);
        
        //clamp holes
        translate([offset,motor_rad+clamp_height/2]){
            rotate([0,90,0]) cylinder(r=m4_rad, h=height*2, center=true);
            rotate([0,90,0]) translate([0,0,wall]) cylinder(r1=m4_cap_rad, r2=m4_cap_rad+1, h=height);
            rotate([0,-90,0]) translate([0,0,wall]) cylinder(r1=m4_square_nut_rad, r2=m4_square_nut_rad+1, h=height, $fn=4);
        }
        
        
    }
}