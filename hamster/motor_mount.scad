include <../configure.scad>

motor_mount();
$fn=72;
module motor_mount(height=25, screw_sep = motor_mount_screw_sep){
    wall = 5;
    clamp_height = 12;
    difference(){
        union(){
            hull(){
                //motor
                cylinder(r=motor_rad+wall, h=height, center=true);
            
                //base
                translate([0,-motor_rad-wall-wall/2,0]) for(i=[0,1])mirror([i,0,0])
                translate([screw_sep/2,0,0]) rotate([-90,0,0]) rotate([0,0,22.5]) cylinder(r=(height/2)/cos(180/8), h=wall, $fn=8);
            }
            hull(){
                //motor
                cylinder(r=motor_rad+wall, h=height, center=true);
                
                //clamp material
                translate([0,motor_rad+clamp_height/2,0]) cube([wall*5,clamp_height,height], center=true);
            }
        }
        
        //motor hole
        cylinder(r=motor_rad, h=height+1, center=true);
        
        //base holes
        translate([0,-motor_rad-wall-wall/2,0]) for(i=[0,1]) mirror([i,0,0]) {
            translate([screw_sep/2,-1,0]) rotate([-90,0,0]) cylinder(r=m4_rad, h=height*2);
            translate([screw_sep/2,wall,0]) rotate([-90,0,0]) cylinder(r1=m4_cap_rad, r2=m4_cap_rad+2, h=height*2);
        }
        
        //clamp slit
        translate([0,motor_rad,0]) cube([wall/2, height*2, motor_rad*2], center=true);
        
        //clamp holes
        translate([0,motor_rad+clamp_height/2]){
            rotate([0,90,0]) cylinder(r=m4_rad, h=height*2, center=true);
            rotate([0,90,0]) translate([0,0,wall]) cylinder(r1=m4_cap_rad, r2=m4_cap_rad+1, h=height);
            rotate([0,-90,0]) translate([0,0,wall]) cylinder(r1=m4_square_nut_rad, r2=m4_square_nut_rad+1, h=height, $fn=4);
        }
        
        
    }
}