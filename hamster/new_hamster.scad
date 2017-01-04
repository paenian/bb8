include <../configure.scad>
include <arduino.scad>
use <motor_mount.scad>

core_rad = 120;

axles_rad = 166.666; //radius of the axle mounting points - how far the wheels are from center.
wheel_lift = 10+wall;  //distance center of axle is above 0.

//motor variables
num_motors = 4; //could do a 3 wheel bot, too

motor_rad = 37/2;
motor_len = 33+26.5;
motor_shaft_offset = 7;

wheel_rad = 50/2;
wheel_width = 30;

spine_thick = 10;
spine_height = 20;


$fn=64;

hamster();

module arm(type="motor"){
    //draws the arms, with the axle in place.
    //They're permanently fixed, 
}

module motor_arm(){
    arm_width = 10; //width of each arm
    motor_arm_width = arm_width*2+wheel_width+2;
    spine_width = 50;
    
    difference(){
        union(){
            //draw in the axle & wheel
            %translate([0,axles_rad, 0]){
                rotate([0,90,0]) cylinder(r=axle_rad, h=100, center=true);
                rotate([0,90,0]) cylinder(r=wheel_rad, h=wheel_width, center=true);
            }
            
            //there are two arms - the motor arm and the idler arm.
            translate([0,core_rad,0]) cube([motor_arm_width,spine_width*2,10], center=true);
        }
        
        //cut out the core
        cylinder(r=core_rad, h=100, center=true);
        
        //gussy it up a little
        translate([0,core_rad+axles_rad-wheel_rad-wall,0]) cylinder(r=core_rad, h=100, center=true);
        
        //cut out the wheel
        translate([0,axles_rad, 0]){
            rotate([0,90,0]) cylinder(r=wheel_rad+wall/2, h=wheel_width+wall/2, center=true);
        }
    }
}

//this is a roughed-in test - it's just drawing a connecting arc.
//todo: the spine needs ends that'll screw into the motor arms, making a rigid motor mounting ring.
//This will be the entire structure - so strong is the name of the game.
//There will be another ring above, for the head pivot area.
module spine(){
    angle = 360/num_motors/2+10;
    
    difference(){
        intersection(){
            cylinder(r=core_rad+spine_thick, h=spine_height, center=true);
            
            //this defines the arc
            rotate([0,0,angle]) translate([200,0,0]) cube([400,400,spine_height], center=true);
            rotate([0,0,-angle]) translate([200,0,0]) cube([400,400,spine_height], center=true);
        }
        
        //cutout the center
        cylinder(r=core_rad, h=spine_height+1, center=true);
    }
    

}

module hamster(){
    
    difference(){
        union(){
            //motor arms
            for(i=[0:360/num_motors:359]) rotate([0,0,i]) motor_arm();
                
            //connecting spines
            for(i=[0:360/num_motors:359]) rotate([0,0,i+360/num_motors/2])
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