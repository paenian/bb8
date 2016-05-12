include <../configure.scad>
use <pulley.scad>

axle_adapter(drive = true);

translate([0,0,50]) 
axle_adapter(drive = false, height=15);

pulley_teeth = 23;

$fn=64;

module axle_adapter(drive = true, height = 25, inset = 5){
    wing_height = 5;
    wing_extent = 10;
    wing_thick = 3;
    difference(){
        union(){
            cylinder(r=wheel_bore_rad, h=height);
            
            //wings
            for(i=[0:120:359]) translate([0,0,height-inset-wing_height]) rotate([0,0,i]) {
                hull(){
                    translate([wing_extent/2,0,wing_height/2]) cube([wing_extent, wing_thick, wing_height], center=true);
                    translate([0,0,0]) cube([wheel_bore_rad*2-.5, wing_thick, wing_height], center=true);
                }
            }
            
   //         pulley_t_ht = 12;	// length of toothed part of pulley, standard = 12
//pulley_b_ht = 0;		// pulley base height, standard = 8. Set to same as idler_ht if you want an idler but no pulley.
//pulley_b_dia = 20;
            
            if(drive == true){
                //pulley
                pulley ( "GT2 2mm" , tooth_spacing (2,0.254, teeth=pulley_teeth) , 0.764 , 1.494, pulley_t_ht=10, pulley_b_ht=3, pulley_b_dia=20, teeth=pulley_teeth);
            }
        }
        
        //axle
        %translate([0,0,-1]) cylinder(r=m4_rad, h=50, $fn=32);
        
        //bore - it's a square, designed to hold the bearings only, really.
        translate([0,0,-1]) cylinder(r=m4_bearing_race_rad/cos(180/4), h=50, $fn=4);
        
        //base bearing
        translate([0,0,-.1]) cylinder(r=m4_bearing_rad, h=m4_bearing_height+.5);
        translate([0,0,-.1]) cylinder(r1=m4_bearing_rad+.5, r2=m4_bearing_rad, h=.6);
        
        //top bearing
        translate([0,0,height+.1-m4_bearing_height]) cylinder(r=m4_bearing_rad, h=m4_bearing_height);
    }
}