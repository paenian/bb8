include <../configure.scad>
use <pulley.scad>

offcenter=0;

axle_adapter(drive = true, offcenter = offcenter);

//translate([0,0,wheel_clearance]) mirror([0,0,1])
translate([20,0,0]) axle_adapter(drive = false, offcenter = -offcenter);

%translate([0,0,(wheel_clearance-wheel_thick)/2+offcenter]) cylinder(r=wheel_rad, h=wheel_thick);

pulley_teeth = 41;
pulley_base_rad = 27;

$fn=64;

module axle_adapter(drive = true, height = wheel_clearance/2-.5){
    wing_height = 3.5;
    wing_extent = 25.4/2;
    wing_thick = 4-slop;
    wing_overlap = 3;
    wing_inset = (wheel_clearance-wheel_thick)/2+offcenter+wing_overlap;
    
    
    difference(){
        union(){
            cylinder(r=wheel_bore_rad, h=height);
            
            //wings
            %translate([0,0,wing_inset]) cylinder(r=10, h=.1);
            for(i=[0:120:359]) translate([0,0,wing_inset-wing_height]) rotate([0,0,i]) {
                intersection(){
                    hull(){
                        
                        translate([wing_extent/2,0,wing_height/2]) cube([wing_extent, wing_thick, wing_height], center=true);
                        translate([0,0,-wing_height/2]) cube([wheel_bore_rad*2-.5, wing_thick, wing_height], center=true);
                    }
                    
                    //this slopes the top
                    hull(){
                        translate([0,0,-wing_height]) cylinder(r=wing_extent, h=.1);
                        translate([0,0,wing_height-1]) cylinder(r1=wing_extent, r2 = 10, h=1);
                    }
                }
            }
            
            if(drive == true){
                //bottom flange
                %translate([0,0,.5+.5]) cylinder(r=pulley_base_rad/2, h=6);
                cylinder(r=pulley_base_rad/2, h=.51);
                translate([0,0,.5]) cylinder(r1=pulley_base_rad/2, r2=pulley_base_rad/2-1, h=.5);
                
                //pulley
                pulley ( "GT2 2mm" , tooth_spacing (2,0.254, teeth=pulley_teeth) , 0.764 , 1.494, pulley_t_ht=8, pulley_b_ht=0, pulley_b_dia=pulley_base_rad, teeth=pulley_teeth);
                %translate([0,0,7.5]) cylinder(r=pulley_base_rad/3, h=4);
                
                //top flange
                translate([0,0,.5+.5+7]) mirror([0,0,1]){
                    cylinder(r=pulley_base_rad/2, h=.51);
                    translate([0,0,.5]) cylinder(r1=pulley_base_rad/2, r2=pulley_base_rad/2-1, h=.5);
                }
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