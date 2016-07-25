rad=508/2;
wall=10;

slop = .2;

in = 25.4;

//wheel and axle variables
wheel_bore_rad = 12/2;
wheel_rad = 84/2;
wheel_thick = 64;
wheel_clearance = 81;

m4_bearing_rad = 9/2+slop;
m4_bearing_height = 4;
m4_bearing_race_rad = (9+4)/4;

axle_rad = 10/2+slop;

//motor variables
motor_rad = 37/2;
motor_mount_screw_sep = 50;
motor_shaft_rad = 6/2;
motor_shaft_dflat = .25;

//standard screw variables
m3_nut_rad = 6.01/2+slop;
m3_nut_height = 2.4;
m3_rad = 3/2+slop;
m3_cap_rad = 3.25;
m3_cap_height = 2;
m3_square_nut_rad = 6*sqrt(2)/2;
m3_sq_nut_rad = m3_square_nut_rad;

m4_nut_rad = 7*sqrt(2)/2+slop;
m4_nut_height = 3;
m4_rad = 4/2+slop+.1;
m4_cap_rad = 4.25;
m4_cap_height = 2;
m4_square_nut_rad = 11.0/2;
m4_tap_rad = 4/2-slop;

m5_nut_rad = 8*sqrt(2)/2+slop;
m5_nut_height = 3.5;
m5_rad = 5/2+slop+.1;
m5_cap_rad = 5.25;
m5_cap_height = 3;

module d_slot(shaft=motor_shaft_rad*2, height=10, tolerance = slop, dflat=motor_shaft_dflat, double_d=false){
    translate([0,0,-.1]){
       difference(){ 
           cylinder(r=shaft/2+tolerance, h=height+.01);
           translate([-shaft/2,shaft/2-dflat,0]) cube([shaft, shaft, height+.01]);
           if(double_d==true){
               mirror([0,1,0]) translate([-shaft/2,shaft/2-dflat,0]) cube([shaft, shaft, height+.01]);
           }
       }
    }
}
