include <../configure.scad>
include <arduino.scad>
use <motor_mount.scad>



axle_rad = 175; //radius of the axle mounting points - how far the motors are from center.
plate_rad = 90;
motor_mount_rad = 118;
arm_width=wheel_clearance+wall*2;

in = 25.4;

//wall = 5;

//150 rad gives 136mm below the center of the sphere
//175 rad gives 102mm below the center of the sphere
//180 rad gives 95mm below the center of the sphere
//185 rad gives 85mm below the center of the sphere
//190 rad gives 73mm below the center of the sphere
//195 rad gives 57mm below the center of the sphere
//200 rad gives 30mm below the center of the sphere; would be hard to get the universal joint for the head centered.

wheel_lift = 10+wall;  //distance center of axle is above 0.

motor_rad = 37/2;
motor_len = 33+26.5;

$fn=64;

//sphere bottom, for sizeing
*translate([00,0,0]) intersection(){
    translate([0,0,104]) difference(){
        sphere(r=508/2);
        sphere(r=508/2-10, $fn=180);
    }
    translate([0,0,-300]) cube([600,600,600], center=true);
}


//translate([0,0,-wheel_lift])
mirror([0,0,1])
hamster();

//translate([0,0,0]) motor_arm();

module center_plate_holes(){
            for(i=[0:90:359]) rotate([0,0,i]) {
                translate([plate_rad-m4_cap_rad*2,0,0]) cylinder(r=m4_rad, h = 50, center=true);
                for(i=[0,1]) mirror([0,i,0]) translate([plate_rad-arm_width/4,arm_width/3,0]) cylinder(r=m4_rad, h = 50, center=true);
            }
}

module center_plate(solid=1){
    difference(){
        union(){
            rotate([0,0,22.5]) cylinder(r=plate_rad/cos(180/8), h=wall, $fn=8);
        }
        
        for(i=[0:90:359]) rotate([0,0,i]) {            
            if(solid==1){
                //subtract out the side bits
                translate([0,0,wall/2-.1]) motor_arm();
                translate([25,0,wall/2-.1]) motor_arm();
            }
        }
    }
}

module hamster(){
    difference(){
        union(){
            //main support plate
            center_plate();
            
            //rough the arduino in
            %translate([10,-35,wall*2]) arduino();
            
            //rough the motor controller in
            %translate([-10,55,wall*2]) rotate([0,0,180]) color([0,0,255]) cube([70, 110, 2]);
            
            //draw the wheels in
            %for(i=[0:90:359]) rotate([0,0,i]) translate([axle_rad,0,wheel_lift]) rotate([90,0,0]){
                //wheel
                cylinder(r=wheel_rad, h=wheel_thick, center=true);
                
                //motor: side mount
                //translate([0,0,wheel_thick/2]) cylinder(r=motor_rad, h=motor_len);
                
                //motor: parallel mount
                //hide the motor underneath :-)
                translate([-wheel_rad-motor_rad,-motor_rad-wheel_lift,-motor_len/2]) cylinder(r=motor_rad, h=motor_len);
            }
            
            //batteries?
            translate([0,0,0]) battery();
        }
        
        center_plate_holes();
    }
}

module motor_arm(){
    bearing_rad = 16/2;
    wall = 10;
    
    difference(){
        union(){
            hull(){
                //wheel mount
                translate([axle_rad,0,wall/2]) rotate([90,0,0]) cylinder(r=wall, h=arm_width, center=true);
                
                //wheel sloper body
                translate([axle_rad-(wheel_rad+wall)/2,0,0]) cube([wheel_rad+wall,arm_width, wall], center=true);
            }
            
            hull(){
                //copy the wheel sloper
                translate([axle_rad-(wheel_rad+wall)/2,0,0]) cube([wheel_rad+wall,arm_width, wall], center=true);
                
                //and add the interface chunk
                translate([plate_rad,0,0]) rotate([0,0,22.5]) cylinder(r=(arm_width/2)/cos(180/8), h=wall, $fn=8, center=true);
            }
            
        }
        
        //wheel cutout
        translate([axle_rad,0,wall/2]) rotate([90,0,0]) difference(){
            cylinder(r=wheel_rad, h=wheel_clearance+1, center=true);
            
            //always add a little bearing cap
            for(i=[0,1]) mirror([0,0,i]) translate([0,0,(wheel_clearance+1)/2-1]) 
                cylinder(r1=m4_rad+1, r2=wall, h=1.1);
        }
        
        //axle mount
        translate([axle_rad,0,wall/2]) rotate([90,0,0]){
            %cylinder(r=m4_rad, h=100, center=true);
            cylinder(r=m4_rad, h=wheel_clearance+wall*3, center=true);
            translate([0,0,wheel_clearance/2+wall/2]) cylinder(r=m4_cap_rad, h=wall*3);
            mirror([0,0,1]) translate([0,0,wheel_clearance/2+wall/2]) cylinder(r1=m4_square_nut_rad, r2=m4_square_nut_rad+1, h=wall*3, $fn=4);
        }
        
        //cutout for the motor mount
        translate([motor_mount_rad, 0, motor_rad+wall*1.5-.25]) rotate([90,0,0]) rotate([0,180,0]) motor_mount(height=25+slop, solid=-1);
        
        //plate interface
        center_plate(solid=-1);
        
        center_plate_holes();
    }
}



module battery(){
    //could probably fit two of these in...
    %translate([0,0,-1.25*in]) cube([3.7*in, 5.9*in, 2.5*in], center=true);
    
    //FRC battery:
    %translate([0,0,-1.5*in]) cube([7.1*in, 6.6*in, 3.0*in], center=true);
    //http://www.andymark.com/product-p/am-0844.htm
    //$89 for two batteries, $100 for the charger:
    //
    
    %translate([0,0,-2*in]) cube([7*in, 7*in, 3.5*in], center=true);
 //http://www.amazon.com/ExpertPower-EXP1290-Volt-Rechargeable-battery/dp/B00A82A3QG/ref=sr_1_9?ie=UTF8&qid=1462559752&sr=8-9&keywords=12+battery
}