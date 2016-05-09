include <../configure.scad>
include <arduino.scad>

axle_rad = 180; //radius of the axle mounting points - how far the motors are from center.
plate_rad = axle_rad+20;

in = 25.4;

wall = 5;

//150 rad gives 136mm below the center of the sphere
//175 rad gives 102mm below the center of the sphere
//180 rad gives 95mm below the center of the sphere
//185 rad gives 85mm below the center of the sphere
//190 rad gives 73mm below the center of the sphere
//195 rad gives 57mm below the center of the sphere
//200 rad gives 30mm below the center of the sphere; would be hard to get the universal joint for the head centered.

wheel_rad = 80/2;
wheel_thick = 60;
wheel_lift = 10+wall;  //distance center of axle is above 0.

motor_rad = 37/2;
motor_len = 33+26.5;

//sphere bottom, for sizeing
%translate([00,0,0]) intersection(){
    translate([0,0,95]) difference(){
        sphere(r=508/2);
        sphere(r=508/2-10, $fn=180);
    }
    translate([0,0,-300]) cube([600,600,600], center=true);
}


translate([0,0,-wheel_lift]) hamster();

module hamster(){
    difference(){
        union(){
            //main support plate
            rotate([0,0,22.5]) cylinder(r=100/cos(180/8), h=wall, $fn=8);
            
            //rough the arduino in
            translate([10,-35,wall*2]) arduino();
            
            //rough the motor controller in
            translate([-10,55,wall*2]) rotate([0,0,180]) color([0,0,255]) cube([70, 110, 2]);
            
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
            #translate([0,0,0]) battery();
        }
    }
}

module motor_arm(){
    bearing_rad = 16/2;
    wall = 10;
    
    difference(){
        union(){
            cube([wheel_thick+wall*2,bearing_rad*2+wall,wall], center=true);
        }
    }
}

translate([0,0,100]) motor_arm();

//a clamp to hold the motor - printed separate, so it can lie down for strength
module motor_mount(height=25, screw_sep = 50){
    wall = 5;
    screw_len = 15;
    difference(){
        hull(){
            //base plate
            translate([0,wall/2,0]) cube([screw_sep+wall*2+m4_rad*2, wall, height], center=true);
            
            //cylinder clamp
            translate([0,motor_rad+wall,0]) cylinder(r=motor_rad+wall, h=height, center=true);
            
            //material for the screw
            translate([0,motor_rad*2+wall*2.5+m4_rad,0]) cube([screw_len, m4_rad*2+wall, height], center=true);
        }
        
        //mounting screws
        for(i=[-1,1]) translate([i*screw_sep/2, -1, 0]) rotate([-90,0,0]) {
            cylinder(r=m4_rad, h=25);
            translate([0,0,wall]) cylinder(r1=m4_cap_rad, r2=m4_cap_rad+1, h=50);
        }
        
        //motor hole
        translate([0,motor_rad+wall,0]) cylinder(r=motor_rad, h=height+1, center=true);
        
        //gap
        translate([0,50,0]) cube([wall, 50, height+1], center=true);
        
        //clamp screw
        translate([0,motor_rad*2+wall*2.5+m4_rad,0]) rotate([0,90,0]) {
            cylinder(r=m4_rad, h=50, center=true);
            translate([0,0,wall]) cylinder(r1=m4_cap_rad, r2=m4_cap_rad+1, h=10);
            rotate([180,0,0]) translate([0,0,wall]) cylinder(r1=m4_nut_rad, r2=m4_nut_rad+1, h=10, $fn=4);
        }
    }
}

module battery(){
    //could probably fit two of these in...
    translate([0,0,-1.25*in]) cube([3.7*in, 5.9*in, 2.5*in], center=true);
 //http://www.amazon.com/ExpertPower-EXP1290-Volt-Rechargeable-battery/dp/B00A82A3QG/ref=sr_1_9?ie=UTF8&qid=1462559752&sr=8-9&keywords=12+battery
}