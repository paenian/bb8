axle_rad = 150; //radius of the axle mounting points - how far the motors are from center.
plate_rad = axle_rad+20;

in = 25.4;

wall = 5;

wheel_rad = 80/2;
wheel_thick = 60;
wheel_lift = 10+wall;  //distance center of axle is above 0.

motor_rad = 37/2;
motor_len = 33+26.5;

//sphere bottom, for sizeing
*%translate([00,0,0]) intersection(){
    translate([0,0,152]) difference(){
        sphere(r=508/2);
        sphere(r=508/2-10, $fn=180);
    }
    translate([0,0,-300]) cube([600,600,600], center=true);
}


hamster();

module hamster(){
    difference(){
        union(){
            //main support plate
            rotate([0,0,22.5]) cylinder(r=100/cos(180/8), h=wall, $fn=8);
            
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

module battery(){
    translate([0,0,-1.25*in]) cube([3.7*in, 5.9*in, 2.5*in], center=true);//http://www.amazon.com/ExpertPower-EXP1290-Volt-Rechargeable-battery/dp/B00A82A3QG/ref=sr_1_9?ie=UTF8&qid=1462559752&sr=8-9&keywords=12+battery
}