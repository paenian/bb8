include <../configure.scad>
include <arduino.scad>
use <motor_mount.scad>

part = 5;

if(part == 0)
    motor_mount_arm();
if(part == 1)
    spine();
if(part == 2)
    idler_mount_arm();
if(part == 3)
    idler_lift_arm();
if(part == 4)
    motor_support_bearing();
if(part == 5)
    inside_hook();

if(part == 10)
    assembled();


//wheel variables
wheel_rad = 60/2;
wheel_width = 26;
wheel_center_width = 13;
wheel_inset = 6;//36 is the total length of wheel + adapter.  6 is measured, ish.

//idler_variables
idler_rad = 48/2;
idler_thick = 20;
idler_axle_rad = 10;

//how low the hamster sits.
hamster_drop = 120;

//these should be calculated from the drop - have to make sure the wheels touch perfectly!
hamster_lift = rad - wall - hamster_drop;
echo(hamster_lift);
body_rad_at_hamster = sqrt(hamster_lift * (2*rad - hamster_lift));
echo(body_rad_at_hamster);
axles_rad_calc = sqrt(pow((rad-wall-wheel_rad),2) - pow(hamster_drop,2));
echo(axles_rad_calc);

//old! axles_rad = 166.666; //radius of the axle mounting points - how far the wheels are from center.
axles_rad = axles_rad_calc;
core_rad = 120;

//idler is on the center line - so no fancy math.
idler_axles_rad = rad - wall - idler_rad;

//motor variables
num_motors = 3; //could do a 3 wheel bot, too

motor_rad = 37/2;
motor_len = 33+26.5;
motor_mount_screw_circle_rad = 31/2;
motor_mount_screw_rad = m3_rad;
motor_collar_rad = 12/2;
motor_collar_len = 6;
motor_shaft_rad = 6/2;
motor_shaft_len = 22;
motor_shaft_offset = 7;
motor_num_screws = 6;
motor_screw_rad = m3_rad;
motor_screw_mount_rad = 31/2;
motor_shaft_rad = 6/2;
motor_shaft_len = 22; //measured frm the motor face
motor_shaft_bump_rad = 12/2+slop*2;
motor_shaft_bump_len = 6.5;

flanged_bearing_rad = 13/2+slop;

motor_mount_arm_thick = motor_shaft_bump_len*2;
motor_mount_arm_height = 30;    //was 26
motor_shaft_d = 5.4 - motor_shaft_rad;

//wheel adapter variables
wheel_adapter_shaft_rad = 15/2;
wheel_adapter_shaft_len = 12;
wheel_adapter_plate_rad = 28/2;
wheel_adapter_plate_len = 4;



//the spines connect the motor arms
spine_thick = 10;
spine_height = 30;
spine_shorten_degrees = 20;
spine_angle = 360 / num_motors - spine_shorten_degrees;    //degrees between spines - this is where the motors join them together.
spine_inner_angle = 6;

//the spine accessory slot is where everything hooks up - the upper ring for the head, the center panel for the electronics and battery, maybe even electronics mounts.
spine_accessory_width = 5;
spine_accessory_length = 10;
spine_accessory_depth = spine_height/2; //so they start at the center.
spine_num_accessory_slots = 3;


$fn=64;

module assembled(){
    hamster();
    
    idler_lift_arms();
    
    %cube([200,200,rad], center=true);
    
    idler_ring();
    
    //head_mount();
            
    //sphere half, for sizeing
    translate([0,0,0]) intersection(){
        difference(){
            sphere(r=rad);
            sphere(r=rad-wall, $fn=180);
        }
        translate([300,0,0]) cube([600,600,600], center=true);
    }
}

module motor_support_bearing(){
    bearing_id = 6/2;
    bearing_od = 12/2;
    bearing_thick = 4;
    
    length = 32.5;
    base_thick = motor_mount_arm_thick/2;
    
    bump = .75;
    slot = 2;
    bump_len = 1;
    
    difference(){
        union(){
            //mount plate
            translate([0,motor_shaft_offset,0]) cylinder(r=motor_rad, h=base_thick);
            
            //shaft
            cylinder(r=bearing_od, h=length-2);
            translate([0,0,length-2.05]) cylinder(r1=bearing_od, r2=bearing_id, h=2.05);
            
            //bearing clip
            translate([0,0,length-.1]) {
                cylinder(r=bearing_id, h=bearing_thick+.2);
                
                translate([0,0,bearing_thick-.1]) cylinder(r1=bearing_id, r2=bearing_id+bump, h=bump_len+.1);
                translate([0,0,bearing_thick+bump_len-.1]) cylinder(r=bearing_id+bump, h=bump_len+.1);
                translate([0,0,bearing_thick+bump_len*2-.1]) cylinder(r2=bearing_id, r1=bearing_id+bump, h=bump_len*2);
            }
        }
        
        //slot
        rotate([0,0,120]) translate([0,0,length+6/2]) cube([bearing_od*2,slot,12], center=true);
        
        //screwholes
        translate([0,motor_shaft_offset,0])
        for(i=[0:360/motor_num_screws:359]) rotate([0,0,i]) translate([motor_screw_mount_rad,0,0])
             cylinder(r=motor_screw_rad+slop, h=wall*3, center=true);
        
        //flatten the bottom
        rotate([0,0,30]) translate([0,27.5,0]) cube([50,50,100], center=true);
    }
}

module idler_ring(){
    //we've got three of the spine sections, and three idler mounts.
    //idler arms
    for(i=[0:360/num_motors:359]) rotate([0,0,i])
        idler_mount_arm();
    
    //connecting spines
    for(i=[0:360/num_motors:359]) rotate([0,0,i+360/num_motors/4])
        mirror([0,0,1]) spine();
}

//this is the assembled wheel bit
module hamster(){
    difference(){
        union(){
            translate([0,0,-hamster_drop])
            {
                //motor arms
                for(i=[0:360/num_motors:359]) rotate([0,0,i]) motor_mount_arm();
                
                //connecting spines
                for(i=[0:360/num_motors:359]) rotate([0,0,i+360/num_motors/4])
                    spine();
                
                //draw the wheels for good measure
                for(i=[0:360/num_motors:359]) rotate([0,0,i+360/num_motors/4])
                    translate([-axles_rad,0,0]) rotate([90,0,0]) 
                    cylinder(r=wheel_rad, h=wheel_center_width, center=true);
            
                //rough the arduino in someplace
                *rotate([0,0,30]) translate([120+10,-35,wall*2]) arduino();
            
                //batteries?
                *translate([0,0,0]) battery();
            }
        }
    }
}


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

//draws the motor plus a wheel.
//It's centered on the wheel - so the motor is offset and sticks out a bunch.
module motor_wheel(){
    num_screws = 6;
    translate([-motor_shaft_offset,0,-(motor_len+motor_collar_len+wheel_adapter_shaft_len+wheel_adapter_plate_len - wheel_inset)-wheel_width/2])
    union(){
        //////////motor!
        cylinder(r=motor_rad, h=motor_len);
        cylinder(r=motor_rad-1, h=32); //the back of the motor's a little smaller
        
        //the screwholes - we draw them in protruding.
        for(i=[0:360/num_screws:359]) rotate([0,0,i]) translate([motor_mount_screw_circle_rad,0,motor_len-.1])
            cylinder(r=motor_mount_screw_rad, h=3.1);
        
        //the collar sticking out
        translate([motor_shaft_offset,0,motor_len-.1]) cylinder(r=motor_collar_rad, h=motor_collar_len+.1);
        
        //the shaft - it's a D
        translate([motor_shaft_offset,0,motor_len-.1]) 
        difference(){
            cylinder(r=motor_shaft_rad, h=motor_shaft_len+.1);
            translate([25+motor_shaft_d,0,0]) cube([50,50,50], center=true);
        }
        
        //////////Wheel adapter
        translate([motor_shaft_offset,0,motor_len+motor_collar_len]){
            cylinder(r=wheel_adapter_shaft_rad, h=wheel_adapter_shaft_len);
            translate([0,0,wheel_adapter_shaft_len-.1]) cylinder(r=wheel_adapter_plate_rad, h=wheel_adapter_plate_len+.1);
        }
        
        //////////Wheel
        translate([motor_shaft_offset,0,motor_len+motor_collar_len+wheel_adapter_shaft_len+wheel_adapter_plate_len - wheel_inset]) difference(){
            cylinder(r=wheel_rad, h=wheel_width);
            
            //inset for the other side attachment
            translate([0,0,wheel_width-wheel_inset]) cylinder(r=wheel_adapter_plate_rad, h=wheel_inset*2);
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
        
        //cut out the motor
        #translate([0,axles_rad,0]) rotate([0,-90,0]) rotate([0,0,-90-60]) motor(clearance = .5, solid = -1);
    }
}

module idler_arm(bump = 2){
     difference(){
        union(){
            //body
            hull(){
                //the back
                translate([0,core_rad,0]) cube([motor_mount_arm_thick,2,motor_mount_arm_height], center=true);
                
                //the idler plate
                translate([0,idler_axles_rad,0]) 
                intersection(){
                    rotate([0,90,0]) cylinder(r=motor_mount_arm_height/2, h=motor_mount_arm_thick, center=true);
                    cube([motor_mount_arm_thick,50,motor_mount_arm_height], center=true);
                }
            }
            
            //bearing bump
            translate([0,idler_axles_rad,0]) rotate([0,90,0]) translate([0,0,-motor_mount_arm_thick/2-bump-slop]) cylinder(r2=m4_rad+wall/2, r1=m4_rad+1, h=bump+slop*2);
        }
        
        //cut out the idler hole - just an m4 axle.
        translate([0,idler_axles_rad,0]) rotate([0,-90,0]) rotate([0,0,-90-60]) cylinder(r=m4_rad, h=25, center=true);
    }
}



module idler_mount_arm(){
        arm_width = 20; //width of each arm
    bearing_bump = 2;
    arm_sep = motor_mount_arm_thick+idler_thick+2+bearing_bump*2;
    width = 30;
    thick = motor_mount_arm_height;
    
    spine_attach_width = 65+motor_mount_arm_thick+10;
    
    difference(){
        union(){
            //there are two arms - the motor arm and the idler arm.
            translate([arm_sep/2,0,0]) idler_arm(bump = bearing_bump);
            mirror([1,0,0]) translate([arm_sep/2,0,0]) idler_arm(bump = bearing_bump);
            
            
            //this connects the two
            intersection(){
                translate([0,core_rad,0]) cube([spine_attach_width,width*2,thick], center=true);
                
                cylinder(r=core_rad+spine_thick*2, h=thick, center=true);
            }
            
            //chamfer the edges a bit
            for(i=[0,1]) mirror([i,0,0]) translate([arm_sep/2-motor_mount_arm_thick/2,core_rad+spine_thick*1.75,0]) cylinder(r=wall, h=thick, center=true, $fn=4);
        }
        
        //idler
        %translate([0,idler_axles_rad,0]) rotate([0,90,0]) cylinder(r=idler_rad, h=idler_thick, center=true);
        //axle
        %translate([0,idler_axles_rad,0]) rotate([0,90,0]) cylinder(r=m4_rad, h=60, center=true);
        
        //cut out the core
        cylinder(r=core_rad+slop, h=100, center=true);
        
        //cut out the spines on either side
        for(i=[-1,1]) rotate([0,0,360/num_motors*.75-i*360/num_motors/2]){
            spine(collar_extra=0);
            spine_connectors(solid=-1, collar_extra=slop/2);
        }
    }
}

module motor_mount_arm(){
    arm_width = 20; //width of each arm
    motor_arm_width = 48+motor_mount_arm_thick+5;
    width = 30;
    thick = motor_mount_arm_height;
    
    spine_attach_width = motor_arm_width+motor_mount_arm_thick+10;
    
    difference(){
        union(){
            //draw in the axle & wheel
            *translate([0,axles_rad, 0]) rotate([0,90,0]) {
                rotate([0,0,60]) motor_wheel();
            }
            
            //there are two arms - the motor arm and the idler arm.
            translate([motor_arm_width/2,0,0]) arm(type="motor");
            mirror([1,0,0]) translate([motor_arm_width/2,0,0]) arm(type="bearing");
            
            
            //this connects the two
            intersection(){
                translate([0,core_rad,0]) cube([spine_attach_width,width*2,thick], center=true);
                
                cylinder(r=core_rad+spine_thick*2, h=thick, center=true);
            }
            
            //chamfer the edges a bit
            for(i=[0,1]) mirror([i,0,0]) translate([motor_arm_width/2-motor_mount_arm_thick/2,core_rad+spine_thick*1.75,0]) cylinder(r=wall, h=thick, center=true, $fn=4);
        }
        
        //cut out the core
        cylinder(r=core_rad+slop, h=100, center=true);
        
        //todo: make the wheel cutout a toroid :-)
        //cut out the wheel
        translate([0,axles_rad, 0]){
            rotate([0,90,0]) cylinder(r=wheel_rad+wall/2, h=wheel_width+wall/2, center=true);
        }
        
        //cut out the spines on either side
        for(i=[-1,1]) rotate([0,0,360/num_motors*.75-i*360/num_motors/2]){
            spine(collar_extra=0);
            spine_connectors(solid=-1, collar_extra=slop/2);
        }
    }
}

module idler_lift_arms(){
    translate([0,0,-hamster_drop]) 
    for(i=[60:360/num_motors:359]) rotate([0,0,i]){
        idler_lift_arm();
    }
}

module accessory_end(solid=1){
    if(solid == 1){
        difference(){
            cube([spine_accessory_length, spine_accessory_width, spine_accessory_depth], center=true);
            rotate([90,0,0]) cylinder(r=m4_rad, h=20, center=true);
        }
    }else{
        //the slot
        cube([spine_accessory_length+slop*2, spine_accessory_width+slop*2, spine_accessory_depth+slop*2], center=true);
            
        //this lets you tighten down on the accessory, while keeping it centered
        cube([spine_accessory_length*2, 1, spine_accessory_depth+4], center=true);
            
        //screwhole to mount the accessory
        rotate([90,0,0]){
            cylinder(r=m4_rad, h=20, center=true);
            translate([0,0,-spine_thick/2-m4_nut_height/2+.5]) hull(){
                rotate([0,0,360/8]) cylinder(r=m4_square_nut_rad+slop, h=m4_nut_height+.5, center=true, $fn=4);
                translate([0,wall,-.5]) rotate([0,0,360/8]) cylinder(r=m4_square_nut_rad+slop*3, h=m4_nut_height+.5+1, center=true, $fn=4);
            }
            translate([0,0,spine_thick/2+m4_nut_height/2-.5]) cylinder(r=m4_cap_rad+slop*2, h=m4_nut_height, center=true);
        }
    }
}

module idler_ends(solid = 1){
    translate([0,0,spine_accessory_depth/2]) accessory_end(solid = solid);
    translate([0,0,hamster_drop-spine_accessory_depth/2]) mirror([0,0,1]) accessory_end(solid = solid);
}

//a vertical arm to lift up the idler ring.
module idler_lift_arm(){
    lift_arm_thick = spine_thick;
    lift_arm_length = 25;
    
    num_holes = 4;
    
    difference(){
        translate([0,core_rad+spine_thick/2,0])
        union(){
            //ends
            #idler_ends();
            
            //body
            //cube([spine_accessory_length, spine_accessory_width, spine_accessory_depth], center=true);
            
            translate([-lift_arm_length/2,-lift_arm_thick+spine_accessory_width/2,spine_accessory_depth-.01]) cube([lift_arm_length, lift_arm_thick, hamster_drop-spine_accessory_depth*2+.02]);
        }
        
        //zip tie/screw slots for mounting things
        translate([0,core_rad+spine_thick/2,0])
        for(i=[0:num_holes-1]) translate([0,0,spine_accessory_depth + (i+.5)*((hamster_drop-spine_accessory_depth*2)/(num_holes))])
            for(j=[0:1]) mirror([j,0,0])
                translate([lift_arm_length/4,0,0]) rotate([90,0,0]) cylinder(r=m4_rad, h=30, center=true);
        
        //round the inside to make it a tiny bit interesting
        cylinder(r=core_rad, h=rad*2, center=true);
    }
}

//this is a hook model for accessories to sit inside the ring.  It's meant to be used by the head
//and the battery, not by itself.
module inside_hook(length = 50, drop = spine_height+spine_accessory_width){
    overhook_len = spine_thick-spine_accessory_width/2+spine_accessory_width;
    chamfer = drop/2;
    difference(){
        union(){
            //insert into the accessory slot
            translate([0,-spine_accessory_width/2,spine_accessory_depth/2+spine_accessory_width-.1]) accessory_end(solid = 1);
            
            %translate([0,-spine_accessory_width/2,spine_height/2]) cube([20,spine_thick, spine_height], center=true);
            
            //drape over top of the spine
            translate([0,-overhook_len/2,spine_accessory_width/2]) cube([spine_accessory_length, overhook_len,spine_accessory_width], center=true);
            translate([0,-overhook_len+spine_accessory_width/2-.1,drop/2]) cube([spine_accessory_length,spine_accessory_width,drop], center=true);
            
            
            //base of the arm
            translate([0,-overhook_len-length/2+spine_accessory_width,-spine_accessory_width/2+drop]) cube([spine_accessory_length,length, spine_accessory_width], center=true);
            
            //chamfer for strength
            translate([0,-overhook_len, -spine_accessory_width+drop]) intersection(){
                rotate([0,90,0]) cylinder(r=chamfer, h=spine_accessory_length, $fn=4, center=true);
                translate([-25,-49,-49]) cube([50,50,50]);
            }
        }
        
        //screwhole + cap
        translate([0,0,spine_accessory_depth/2+spine_accessory_width]){
            rotate([90,0,0]) cylinder(r=m4_rad+slop, h=50);
            translate([0,-overhook_len+spine_accessory_width/2,0])  rotate([90,0,0]) cylinder(r=m4_cap_rad+slop, h=50);
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
                
                //inside nut trap - out the top
                translate([0,0,spine_thick/2+spine_thick/2])
                hull(){
                    rotate([0,0,360/8]) cylinder(r=m4_square_nut_rad, h=m4_nut_height+slop, center=true, $fn=4);
                    hull(){
                        translate([-m4_nut_height/2,0,0]) rotate([0,0,360/8]) cylinder(r=m4_square_nut_rad+.25, h=m4_nut_height+1+slop, center=true, $fn=4);
                        translate([-wall-5,0,0]) rotate([0,0,360/8]) cylinder(r=m4_square_nut_rad+1, h=m4_nut_height+1+slop, center=true, $fn=4);
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
                    translate([0,0,spine_thick/2+spine_thick/2]){
                        rotate([0,0,360/8]) cylinder(r=m4_square_nut_rad, h=m4_nut_height+slop, center=true, $fn=4);
                        hull(){
                            translate([-m4_square_nut_rad/2,0,0]) rotate([0,0,360/8]) cylinder(r=m4_square_nut_rad, h=m4_nut_height+slop, center=true, $fn=4);
                            translate([-wall-m4_square_nut_rad,0,.5]) rotate([0,0,360/8]) cylinder(r=m4_square_nut_rad+.75, h=m4_nut_height+1+slop, center=true, $fn=4);
                        }
                    }
                    
                    //inset the screw a tiny bit
                    translate([0,0,-spine_thick/2]) cylinder(r=m4_cap_rad+slop+collar_extra/2, h=m4_cap_height+collar_extra, center=true);
                }
            }
        }
    }
    
    //accessory slots in the spine
    if(solid == -1){
        for(i=[0:360/12:359]) rotate([0,0,i]) translate([0,core_rad+spine_thick/2,spine_height/2-spine_accessory_depth/2]) {
            accessory_end(solid=-1);
        }
    }
    
    //some axial screwholes, what for mounting the head gizmos
    if(solid == -1){
        for(i=[0:360/12:359]) rotate([0,0,i+360/24]) translate([0,core_rad+spine_thick/2,0]) {
            rotate([90,0,0]) cylinder(r=m4_rad+slop, h=50, center=true);
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