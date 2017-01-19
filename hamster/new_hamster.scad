include <../configure.scad>
include <arduino.scad>
use <motor_mount.scad>

core_rad = 120;

axles_rad = 166.666; //radius of the axle mounting points - how far the wheels are from center.
wheel_lift = 10+wall;  //distance center of axle is above 0.

//motor variables
num_motors = 3; //could do a 3 wheel bot, too

motor_rad = 37/2;
motor_len = 33+26.5;
motor_shaft_offset = 7;
motor_num_screws = 6;
motor_screw_rad = m3_rad;
motor_screw_mount_rad = 31/2;
motor_shaft_rad = 6/2;
motor_shaft_len = 22; //measured frm the motor face
motor_shaft_bump_rad = 12/2;
motor_shaft_bump_len = 6.5;

flanged_bearing_rad = 13/2+slop;

motor_mount_arm_thick = motor_shaft_bump_len*2;
motor_mount_arm_height = 25;

wheel_rad = 50/2;
wheel_width = 30;

//the spines connect the motor arms
spine_thick = 10;
spine_height = 30;
spine_shorten_degrees = 20;
spine_angle = 360 / num_motors - spine_shorten_degrees;    //10 degrees between spines - this is where the motors join them together.
spine_inner_angle = 5;



$fn=64;
motor();
arm();
motor_mount_arm();

spine();
//spine_connectors(solid=-1, collar_extra=slop/2);

!hamster();

//the motor :-)  The z plane is at the face of the motor.
module motor(solid = 1, clearance = 0, screw_rad = motor_screw_rad){
    translate([0,motor_shaft_offset,0])
    union(){
        //body
        translate([0,0,-motor_len]) cylinder(r=motor_rad+clearance, h=motor_len);
        
        translate([0,-motor_shaft_offset,-.05]){
            //bump
            cylinder(r=motor_shaft_bump_rad+clearance, h=motor_shaft_bump_len+clearance+.1);
        
            //shaft
            cylinder(r=motor_shaft_rad+clearance, h=motor_shaft_len+.1);
        }
        
        //screwholes as bumps
        for(i=[0:360/motor_num_screws:359]) rotate([0,0,i]) translate([motor_screw_mount_rad,0,0]){
             cylinder(r=screw_rad, h=wall*3, center=true);
            
            //screw caps
            if(solid == -1)
            translate([0,0,motor_shaft_bump_len-m3_cap_height]) cylinder(r=m3_cap_rad, h=wall*3);
        }
    }
}

module arm(type="motor"){
    //draws the arms, with the axle in place.
    //They're permanently fixed.
    difference(){
        union(){
            //body
            hull(){
                //the back
                translate([0,core_rad,0]) cube([motor_mount_arm_thick,2,motor_mount_arm_height], center=true);
                
                //the motor plate
                translate([0,axles_rad,0]) 
                intersection(){
                    rotate([0,90,0]) cylinder(r=motor_rad, h=motor_mount_arm_thick, center=true);
                    cube([motor_mount_arm_thick,50,motor_mount_arm_height], center=true);
                }
            }
        }
        
        //draw in the motor
        translate([0,axles_rad,0]) rotate([0,-90,0]) rotate([0,0,-90]) motor(clearance = .5, solid = -1);
    }
}

module motor_mount_arm(){
    arm_width = 20; //width of each arm
    motor_arm_width = arm_width*2+wheel_width+2;
    width = 30;
    thick = motor_mount_arm_height;
    
    difference(){
        union(){
            //draw in the axle & wheel
            %translate([0,axles_rad, 0]){
                rotate([0,90,0]) cylinder(r=axle_rad, h=100, center=true);
                rotate([0,90,0]) cylinder(r=wheel_rad, h=wheel_width, center=true);
            }
            
            //there are two arms - the motor arm and the idler arm.
            translate([motor_arm_width/2,0,0]) arm(type="motor");
            mirror([1,0,0]) translate([motor_arm_width/2,0,0]) arm(type="bearing");
            
            
            //this connects the two
            intersection(){
                translate([0,core_rad,0]) cube([motor_arm_width,width*2,thick], center=true);
                
                cylinder(r=core_rad+spine_thick*2, h=thick, center=true);
            }
            
            //chamfer the edges a bit
            for(i=[0,1]) mirror([i,0,0]) translate([motor_arm_width/2-motor_mount_arm_thick/2,core_rad+spine_thick*1.75,0]) cylinder(r=wall, h=thick, center=true, $fn=4);
        }
        
        //cut out the core
        cylinder(r=core_rad+slop, h=100, center=true);
        
        //gussy it up a little
        translate([0,wheel_rad+wall+axles_rad-wheel_rad-wall,0]) 
            scale([.8,1,1]) sphere(r=wheel_rad+wall);
        //todo: make the wheel cutout a toroid :-)
        //cut out the wheel
        translate([0,axles_rad, 0]){
            rotate([0,90,0]) cylinder(r=wheel_rad+wall/2, h=wheel_width+wall/2, center=true);
        }
        
        //cut out the spines on either side
        #for(i=[-1,1]) rotate([0,0,360/num_motors*.75-i*360/num_motors/2]){
            spine(collar_extra=0);
            spine_connectors(solid=-1, collar_extra=slop/2);
        }
    }
}

module spine_connectors(solid = 1, collar_extra = 0){
    collar_rad = spine_height/4+collar_extra;
    inner_angle = spine_inner_angle;
    
    for(i=[-1, 1]) {
        //the end is a single screw
        rotate([0,0,i*spine_angle/2]) translate([core_rad+spine_thick/2,0,0]) rotate([0,90,0]) {
            if(solid == 1){
                cylinder(r=collar_rad, h=spine_thick, center=true);
            }
            if(solid == -1){
                //screwhole
                cylinder(r=m4_rad+collar_extra/2, h=spine_thick*3, center=true);
                
                //nut trap - out the back
                translate([0,0,spine_thick*3/2])
                hull(){
                    rotate([0,0,360/8]) cylinder(r=m4_square_nut_rad, h=m4_nut_height, center=true, $fn=4);
                    hull(){
                        translate([0,0,m4_nut_height/2]) rotate([0,0,360/8]) cylinder(r=m4_square_nut_rad+.25, h=m4_nut_height+1, center=true, $fn=4);
                        translate([0,0,wall]) rotate([0,0,360/8]) cylinder(r=m4_square_nut_rad+1, h=m4_nut_height+1, center=true, $fn=4);
                    }
                }
                
                //inset the screw a tiny bit
                translate([0,0,-spine_thick/2]) cylinder(r=m4_cap_rad+slop+collar_extra/2, h=m4_cap_height+collar_extra, center=true);
            }
        }
        
        //two screws on the arms
        for(j=[0,1]) mirror([0,0,j]){
            rotate([0,0,i*spine_angle/2-inner_angle*i]) translate([core_rad+spine_thick/2,0,spine_height/2-collar_rad+collar_extra]) rotate([0,90,0]) {
                if(solid == 1){
                    cylinder(r=collar_rad, h=spine_thick, center=true);
                }
                if(solid == -1){
                    //screwhole
                    cylinder(r=m4_rad+collar_extra/2, h=spine_thick*3, center=true);
                    //nut trap - one up one down
                    translate([0,0,spine_thick*3/2]){
                        rotate([0,0,360/8]) cylinder(r=m4_square_nut_rad, h=m4_nut_height, center=true, $fn=4);
                        hull(){
                            translate([-m4_square_nut_rad,0,0]) rotate([0,0,360/8]) cylinder(r=m4_square_nut_rad, h=m4_nut_height, center=true, $fn=4);
                            translate([-wall-m4_square_nut_rad,0,.5]) rotate([0,0,360/8]) cylinder(r=m4_square_nut_rad+.75, h=m4_nut_height+1, center=true, $fn=4);
                        }
                    }
                    
                    //inset the screw a tiny bit
                    translate([0,0,-spine_thick/2]) cylinder(r=m4_cap_rad+slop+collar_extra/2, h=m4_cap_height+collar_extra, center=true);
                }
            }
        }
    }
}

//this is a roughed-in test - it's just drawing a connecting arc.
//todo: the spine needs ends that'll screw into the motor arms, making a rigid motor mounting ring.
//This will be the entire structure - so strong is the name of the game.
//There will be another ring above, for the head pivot area.
module spine(collar_extra = 0){
    angle = 360/num_motors/2-spine_shorten_degrees/2-spine_inner_angle;
    
    difference(){
        union(){
            //this is the main spine body
            intersection(){
                cylinder(r=core_rad+spine_thick, h=spine_height, center=true);
                //this defines the arc
                rotate([0,0,90-angle]) translate([200,0,0]) cube([400,400,spine_height], center=true);
                rotate([0,0,-90+angle]) translate([200,0,0]) cube([400,400,spine_height], center=true);
            }
            hull(){
                spine_connectors(solid=1, collar_extra=collar_extra);
            }
        }
        
        //cutout the center
        cylinder(r=core_rad, h=spine_height+1, center=true);
        
        //nut holes
        spine_connectors(solid=-1, collar_extra=collar_extra);
    }
    

}

module hamster(){
    
    difference(){
        union(){
            //motor arms
            for(i=[0:360/num_motors:359]) rotate([0,0,i]) motor_mount_arm();
                
            //connecting spines
            for(i=[0:360/num_motors:359]) rotate([0,0,i+360/num_motors/4])
                spine();
            
            //rough the arduino in someplace
            %rotate([0,0,30]) translate([120+10,-35,wall*2]) arduino();
            
            //batteries?
            translate([0,0,0]) battery();
            
            //sphere bottom, for sizeing
            translate([0,0,0]) intersection(){
                translate([0,0,130]) difference(){
                    sphere(r=508/2);
                    sphere(r=508/2-10, $fn=180);
                }
                translate([0,0,-300]) cube([600,600,600], center=true);
            }
        }
        
    }
}

module battery(){
    //could probably fit two of these in...
    //%translate([0,0,-1.25*in]) cube([3.7*in, 5.9*in, 2.5*in], center=true);
    
    //FRC battery:
    %translate([0,0,-1.5*in]) cube([7.1*in, 6.6*in, 3.0*in], center=true);
    //http://www.andymark.com/product-p/am-0844.htm
    //$89 for two batteries, $100 for the charger:
    //
    
    //%translate([0,0,-2*in]) cube([7*in, 7*in, 3.5*in], center=true);
 //http://www.amazon.com/ExpertPower-EXP1290-Volt-Rechargeable-battery/dp/B00A82A3QG/ref=sr_1_9?ie=UTF8&qid=1462559752&sr=8-9&keywords=12+battery
}