/* I've got motors with a 4mm shaft, and wheels with a 12mm hole.
 *
 * The motors have flats, so I figure screw onto those, so nut trap.  Then friction fit the wheels?
 * Should probably have a shoulder, 
 *
 * 
 * This design is now obsolete - adding a proper axle for the wheels, because I'm worried about the force.  Hamster needs to be heavy, so let's do this right.
 * 
 */

motor_adapter();

slop = .2;

$fn=32;

module motor_adapter(hub_rad = 6.2, hub_height=60, shaft_rad = 2, shaft_height=10){
    shoulder = 5;
    shoulder_height = 7;
    m3_sq_nut_rad = 5.5/2*sqrt(2)+.1;
    m3_rad = 3/2+slop;
    
    m5_thread_rad = 5/2-.5;
    
    difference(){
        union(){
            //shoulder
            cylinder(r=hub_rad+shoulder, h=shoulder_height);
            
            //wheel hub
            difference(){
                cylinder(r=hub_rad, h=hub_height);
                //split for friction mount
                cube([2, 30, 200], center=true);
                translate([0,0,shaft_height]) cylinder(r=m5_thread_rad, h=hub_height);
            }
        }
        
        //shaft holw
        translate([0,0,-.1]) cylinder(r=shaft_rad+slop, h=hub_height*2);
        
        //set screw mounting
        translate([0,0,shoulder_height/2-.5]) rotate([0,90,0]) {
            translate([0,0,3]) rotate([0,0,45]) cylinder(r1=m3_sq_nut_rad+.25, r2=m3_sq_nut_rad, h=3, $fn=4);
            
            hull(){
                translate([m3_sq_nut_rad*1.25,0,3]) rotate([0,0,45]) cylinder(r1=m3_sq_nut_rad+.25, r2=m3_sq_nut_rad, h=3, $fn=4);
                translate([m3_sq_nut_rad*2,0,3-.25]) rotate([0,0,45]) cylinder(r1=m3_sq_nut_rad+1, r2=m3_sq_nut_rad+.5, h=3.5, $fn=4);
            }
            
            cylinder(r=m3_rad,  h=shoulder*3);
        }
        
        
    }
}