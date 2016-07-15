include <../../configure.scad>
use <bearing.scad>
use <motor_mount.scad>

cap_rad = 125;
cap_height = 50;
capcap_height = 15;


num_petals = 6;
petal_thick = 5;
petal_attach_rad = cap_rad - wall;


part = 10;
angle = 90+30;
textured = false;
flip = 0;
facets = 30;    //for rendering

$fn=facets;

*%hull(){
    translate([0,0,-rad]) cube([48*in,24*in,.1], center=true);
    translate([0,0,-rad+in*12]) cube([24*in,1*in,.1], center=true);
}
*%cube([600,300,400], center=true);
*%cube([200,200,1], center=true);

if(part == 0)
    cap(angle = angle, textured = textured);
if(part == 11)
    capcap(angle = angle, textured = textured);
if(part == 1)
    rotate([0,90,0]) petal(angle = angle, textured = textured);
if(part == 2)
    bus();
if(part == 3)
    mirror([0,0,flip]) motor_carrier();
if(part == 4)
    mirror([0,0,flip]) motor_gear();
if(part == 5)
    head_cage();

if(part == 10)
    assembled();


/*
m=round(number_of_planets);
np=round(number_of_teeth_on_planets);
ns1=approximate_number_of_teeth_on_sun;
k1=round(2/m*(ns1+np));
k= k1*m%2!=0 ? k1+1 : k1;
ns=k*m/2-np;
echo(ns);
nr=ns+2*np;
pitchD=0.9*D/(1+min(PI/(2*nr*tan(P)),PI*DR/nr));
pitch=pitchD*PI/nr;
echo(pitch);
helix_angle=atan(2*nTwist*pitch/T);
echo(helix_angle);
*/


//Gear variables
gear_drive_diameter = 150;
gear_drive_rad = gear_drive_diameter/2;

gear_motor_diameter = 30;   //this is guessed.
gear_motor_rad = gear_motor_diameter/2;

gear_drive_teeth = 67;
gear_motor_teeth = 13;
gear_thick = 12;
gear_clearance = .1;

capcap_rad = gear_drive_diameter/2;

motor_offset = gear_drive_diameter/2+gear_motor_diameter/2;

DR=0.6*1;   //this is the maximum depth ratio
P = 45;
nTwist = 1;
gear_pitchD = gear_drive_diameter/(1+min(PI/(2*gear_drive_teeth*tan(P)),PI*DR/gear_drive_teeth));
gear_pitch = gear_pitchD*PI/gear_drive_teeth;
gear_pressure_angle = P;
gear_depth_ratio = DR;
gear_angle = atan(2*nTwist*gear_pitch/gear_thick);



//head cage variables
head_length = 150;

//bus variables
motor_carrier_thick = 15;
motor_carrier_inset = 10;
motor_carrier_width = 100;
bus_width = 70; //the width of the dagu 4 motor shield, basically.
bus_length= rad - cap_height - head_length/2-motor_carrier_thick-motor_carrier_inset;
bus_drop = 50;
bus_screw_sep = 20;

%translate([0,0,-200]) cube([50,50,50]);

module assembled(){
    for(i=[0,1]) mirror([0,0,i])
        translate([0,0,rad+50]) capcap(textured=false);
    
    for(i=[0,1]) mirror([0,0,i])
        translate([0,0,rad-cap_height]) cap(textured=false);
    
    for(i=[180/num_petals:360/num_petals:180-1])
        petal(angle=i, textured=false);
    
    //this is drawn in by the motor carrier
    *for(i=[0,1]) mirror([0,0,i]){
        *%sphere(r=rad-wall, $fn=70);
        *%translate([0,0,rad-cap_height]) cylinder(r=gear_drive_rad, h=gear_motor_rad);
        
        translate([motor_offset,0,rad-cap_height]) motor_gear();
    }
    
    for(i=[0,1]) mirror([0,0,i]) translate([0,0,rad-cap_height-motor_carrier_inset])
        motor_carrier();
    
    for(i=[0,1]) mirror([0,0,i]) translate([bus_drop,0,rad-cap_height-motor_carrier_inset-motor_carrier_thick])
        rotate([0,90,0]) bus();
    
    head_cage();
}

//head cage is a delineator - it holds the space where the head will be mounted inside, and also provides a low, centered mount point for the tilt weights and gyroscope.
module head_cage(){
    side_width = 20;
    side_length = 100;
    
    //%cube([head_length,head_length,head_length], center=true);
    difference(){
        union(){
            //arms
            for(i=[0,1]) mirror([0,0,i]) translate([0,0,-head_length/2]){
                //shaft mount
                rotate([0,0,0]) rotate([0,180,0]) translate([0,0,-motor_carrier_thick/2]) motor_mount(height = motor_carrier_thick, solid=0, motor_rad=22/2+slop, screw_sep=15);
                hull(){
                    translate([0,-side_width,0]) cube([bus_drop+10,side_width,motor_carrier_thick]);
                }
            }//end arms
            
            //attachment points for the bus
            for(j=[0,1]) mirror([0,0,j]) hull() for(i=[-bus_screw_sep/2,bus_screw_sep/2]) translate([bus_drop,i,-head_length/2]){
                cylinder(r=m4_cap_rad+wall/2, h=motor_carrier_thick);
            }
            
            //mount for the pendulum
            translate([side_length,0,0]) rotate([90,0,0]) rotate([0,0,-90]) motor_mount_solid(height = side_width*2, solid=0, motor_rad=22/2+slop, screw_sep=15);
            
            //base
            translate([0,0,0]) rotate([90,0,0]) difference(){
                intersection(){
                    cylinder(r=side_length, h=side_width);
                    cube([200,head_length,50], center=true);
                }
                translate([0,0,-1]) cylinder(r=side_length-motor_carrier_thick, h=side_width+2);
                translate([-50,0,0]) cube([100,head_length+2,50], center=true);
            }
        }
        
        //make the center pure hollow
        intersection(){
            rotate([90,0,0]) translate([0,0,-1]) cylinder(r=side_length-motor_carrier_thick, h=side_width*3, center=true);
            translate([0,0,0]) cube([200,head_length+25,50], center=true);
        }
        
        //hollow out the lower mount
        #translate([side_length,0,0]) rotate([90,0,0]) rotate([0,0,-90]) motor_mount_holes(height = side_width*3, solid=0, motor_rad=22/2+slop, screw_sep=15);
        
        //mount flanged bearings, two on each side
        cylinder(r=22/2+slop, h=head_length+10, center=true);
        
        
        //attachment for the bus
        for(j=[0,1]) mirror([0,0,j]) for(i=[-bus_screw_sep/2,bus_screw_sep/2]) translate([bus_drop,i,-head_length/2+motor_carrier_thick/2]){
            cylinder(r=m4_rad, h=50, center=true);
            cylinder(r=m4_cap_rad, h=50);
        }
        
        //flatten the printing side
        translate([0,-side_width-side_length*3/2,0]) cube([side_length*3,side_length*3,side_length*3], center=true);
    }
}

module bus_connectors(solid=1){
    if(solid==-1){
        
    }
}

//the bus holds the electronics, and braces between the ends of the sphere and the head cage.
//The head cage has the central swing weight, 
module bus(){
    difference(){
        union(){
            translate([0,-bus_width/2,-wall/2]) cube([bus_length,bus_width,wall]);
        }
    }
}

module motor_gear(){
    hub_rad = in/2;
    sprung_rad = gear_motor_rad-wall/3;
    
    spoke_thick = 1.6;
    spoke_rad = sprung_rad/2+hub_rad/2+spoke_thick/2;
    
    spoke_center_rad = spoke_rad-hub_rad;
    num_spokes = 6;
    
    mount_rad = 12/2+slop;
    mount_height = 4.5;
    mount_screw_center_rad = 9.5;
    mount_screw_rad = m3_rad+slop;
    mount_screws = 6;
    
    //herringbone drive gear]
    difference(){
        translate([0,0,gear_thick/2])
            mirror([0,1,0]) herringbone (
            number_of_teeth=gear_motor_teeth,
            circular_pitch=gear_pitch,
            pressure_angle=gear_pressure_angle,
            depth_ratio=gear_depth_ratio,
            clearance=gear_clearance,
            helix_angle=gear_angle,
            gear_thickness=gear_thick,
            flat=false);
        
        //shaft
        d_slot(height = gear_thick+2);
        
        //holes for the metal mount shaft
        translate([0,0,-.1]) cylinder(r = mount_rad, h=mount_height);
        for(i=[0:360/mount_screws:359]) rotate([0,0,i]) translate([mount_screw_center_rad,0,-.1])
            cylinder(r=mount_screw_rad, h=gear_thick+2);
        
        translate([0,0,-1]) difference(){
            cylinder(r=sprung_rad, h=gear_thick+2);
            
            //hub
            cylinder(r=hub_rad, h=gear_thick+2);
            
            //spokes
            for(i=[0:360/num_spokes:359]) rotate([0,0,i]) 
            difference(){
                translate([spoke_center_rad,0,0]) intersection(){
                    cylinder(r=spoke_rad, h=gear_thick+2);
                    translate([0,-50,0]) cube([100,100,100], center=true);
                }
                translate([spoke_center_rad,0,0]) cylinder(r=spoke_rad-spoke_thick, h=gear_thick+4);
            }
        }
    }
}

//mounts one or two motors, ready to drive BB8.
module motor_carrier(){   
    screw_sep=15;
    
    motor_angle = 23;
    
    %for(i=[-motor_angle,motor_angle]) rotate([0,0,i]) translate([motor_offset,0,motor_carrier_thick/2])motor_gear();
    
    translate([0,0,-motor_carrier_thick])
    difference(){
        union(){
            for(i=[-motor_angle,motor_angle]) rotate([0,0,i]) translate([motor_offset,0,motor_carrier_thick/2])
                rotate([0,0,-90]) motor_mount(height = motor_carrier_thick, solid=0, screw_sep=screw_sep);
            
            hull() for(i=[-motor_angle,motor_angle]) rotate([0,0,i]) translate([motor_offset,0,motor_carrier_thick/2])
            for(j=[-screw_sep/2,screw_sep/2]) translate([-motor_rad,j,0]) rotate([0,-90,0]) scale([1,.5,1]) rotate([0,0,22.5]) cylinder(r=motor_carrier_thick/2/cos(180/8), h=motor_offset-motor_rad, $fn=8);
            
        
            translate([0,0,motor_carrier_thick/2]) rotate([0,0,90]) rotate([0,180,0]) motor_mount(height = motor_carrier_thick, solid=0, motor_rad=22/2+slop, screw_sep=screw_sep);
            
            *hull() for(i=[-screw_sep/2,screw_sep/2]) translate([motor_offset/2,i,motor_carrier_thick/2]) rotate([0,90,0]) scale([1,.5,1]) rotate([0,0,22.5]) cylinder(r=motor_carrier_thick/2/cos(180/8), h=20, $fn=8, center=true);
            
            *hull(){
                #cylinder(r=22/2+5, h=motor_carrier_thick);
                translate([motor_offset-motor_rad,0,motor_carrier_thick/2]) cube([.1,wall,motor_carrier_thick], center=true);
            }
        }
        
        //attachment for the bus
        for(i=[-bus_screw_sep/2,bus_screw_sep/2]) translate([bus_drop,i,motor_carrier_thick/2]){
            cylinder(r=m4_rad, h=50, center=true);
            cylinder(r=m4_cap_rad, h=50);
        }
        
        //mount two flanged bearings
        cylinder(r=22/2+slop, h=motor_carrier_thick*3, center=true);
    }
}

//the holes for the petals - all of them.
module petal_holes(screw_rad = m3_rad){
    angle = 29.2;
    hole_sep = 15;
    
    for(i=[180/num_petals:360/num_petals:360-1]) rotate([0,0,i])
        rotate([angle,0,0]) {
            for(j=[-hole_sep/2, hole_sep/2]) rotate([0,j,0]) translate([0,0,rad-wall*2]) {
                cylinder(r=screw_rad+slop, h=wall*3);
                translate([0,0,wall*2-petal_thick]) cylinder(r1=screw_rad+slop, r2=screw_rad+wall, h=wall);
            }
        }
}

module petal(angle = 0, textured = false){
    intersection(){
        rotate([0,0,angle]) difference(){
            difference(){
                sphere(r=rad);
                sphere(r=rad-petal_thick);
        
                //the endcap
                rotate([0,0,180/num_petals]) cylinder(r=petal_attach_rad/cos(180/6)+slop, h=rad*2+1, center=true, $fn=num_petals);
            }
        
            //cut it into a slice
            for(i=[1,-1]) rotate([0,0,(90+180/(num_petals) - slop)*i]) translate([0,-rad,-rad-.5]) cube([rad*2, rad*2, rad*2+1]);
        
            petal_holes();
        }
        
        if(textured == true){
            bb8_texture_shallow();
        }
    }
}

module capcap_screws(num_screws=3, screw_rad = m3_rad){
    for(i=[0:360/num_screws:359]) rotate([0,0,i]) translate([0,capcap_rad-wall/2.5,-wall*2+2]){
        cylinder(r=screw_rad+slop, h=wall*8, center=true);
        translate([0,0,wall*2]) cylinder(r1=screw_rad+slop, r2=screw_rad+wall, h=wall);
        //translate([-m3_nut_rad*2,0,wall]) cube([m3_nut_rad*4, m3_nut_rad*2, 4], center=true);
    }
}

module capcap(textured = false){
    difference(){
        union(){
            //cap exterior
            translate([0,0,-rad+capcap_height])
            intersection(){
                difference(){
                    sphere(r=rad);
                    sphere(r=rad-wall);
                }
                
                cylinder(r=capcap_rad, h=rad*3, center=true);
                
                //texture it?
                if(textured == true){
                    rotate([angle,0,0]) bb8_texture_shallow();
                }
            }
        }
        
        //screwholes
        capcap_screws();
        
        //the central rod
        translate([0,0,-rad+capcap_height]) cylinder(r=axle_rad, h=500, center=true);
        
        //flatten the bottom for easy printing
        translate([0,0,-rad]) cube([rad*2, rad*2, rad*2], center=true);
    }
}

module cap(angle = 0, textured = false){
    
    num_braces = 3;
    
    difference(){
        union(){
            //some stiffening ribs
            intersection(){
                for(i=[0:360/num_braces/2:359]) rotate([0,0,i]) translate([-2,0,gear_thick+1]) cube([4,rad,cap_height-gear_thick-1]);
                translate([0,0,-rad+cap_height]) sphere(r=rad-wall/2);
            }
                            
            //cap exterior
            translate([0,0,-rad+cap_height])
            intersection(){
                difference(){
                    sphere(r=rad);
                    
                    difference(){
                        intersection(){
                            sphere(r=rad-wall);
                            //an extra thick area for the panel screws to go into.
                            cylinder(r=cap_rad-wall, h=600, center=true);
                        }
                        
                        
                    }
                }
               
                union(){
                    cylinder(r=petal_attach_rad/cos(180/6), h=rad+1, $fn=num_petals);
                
                    //petal attachment indent
                    intersection(){
                        cylinder(r=cap_rad/cos(180/6), h=rad+1, $fn=num_petals);
                        sphere(r=rad-petal_thick);
                    }
                }
                
                //texture it?
                if(textured == true){
                    rotate([angle,0,0]) bb8_texture_shallow();
                }
            }
            
            //herringbone drive gear
            translate([0,0,gear_thick/2])
            herringbone (
                number_of_teeth=gear_drive_teeth,
                circular_pitch=gear_pitch,
                pressure_angle=gear_pressure_angle,
                depth_ratio=gear_depth_ratio,
                clearance=gear_clearance,
                helix_angle=gear_angle,
                gear_thickness=gear_thick,
                flat=false);
            %cylinder(r=gear_drive_diameter/2, h=gear_thick);
            
            //connect the gear to the sphere
            intersection(){
                hull(){
                    translate([0,0,gear_thick]) cylinder(r=gear_drive_diameter/2-1, h=.1);
                    translate([0,0,cap_height-wall+1]) cylinder(r=gear_drive_diameter*.75, h=.1);
                }
                translate([0,0,-rad+cap_height]) sphere(r=rad-1);
            }
        }
        
        //capcap screws
        translate([0,0,cap_height-capcap_height]) capcap_screws(screw_rad = m3_rad-slop);
        
        //central axle hole
        translate([0,0,-1]) cylinder(r=axle_rad, h=cap_height+2);
        
        //holes to attach the petals
        translate([0,0,-rad+cap_height]) rotate([0,0,180/num_petals]) petal_holes(screw_rad = m3_rad-slop);
        
        //hollow out the insides
        difference(){
            intersection(){
                translate([0,0,-1]) cylinder(r=gear_drive_diameter/2-wall*.75, h=100);
                //translate([0,0,-rad+cap_height]) sphere(r=rad-wall);
                
                //todo: make the top removable :-)
                //The top will hold in the rod.
            }
            
            //center rod
            cylinder(r=axle_rad+wall/2, h=50);
            
            //stiffeners
            for(i=[0:360/num_braces:359]) rotate([0,0,i]) translate([-2,0,0]) cube([4,100,100]);
        }
        
        //inset for the capcap
        difference(){
            translate([0,0,cap_height-capcap_height]) cylinder(r=capcap_rad+slop, h=rad*3);
            translate([0,0,-rad+cap_height]) sphere(r=rad-wall);
        }
        
        //flatten the bottom for easy printing
        translate([0,0,-rad]) cube([rad*2, rad*2, rad*2], center=true);
    }
}

//STL of the full BB8, centered, rotated, scaled, sized, etc.
module bb8_texture(){
    s=6.51;
    //scale([s,s,s]) rotate([0,0,-27.5]) rotate([0,3.6,0]) rotate([29.25,0,0])import("bb8_union_rep_simplified.stl");

    scale([s,s,s]) import("body_solid.stl");
}

module bb8_texture_shallow(){
        s=6.51;
    //scale([s,s,s]) rotate([0,0,-27.5]) rotate([0,3.6,0]) rotate([29.25,0,0])import("bb8_union_rep_simplified.stl");

    rotate([12, 44, 111]) union(){
        scale([s,s,s]) import("body_solid.stl");
        sphere(r=rad-.5);
    }
}
    