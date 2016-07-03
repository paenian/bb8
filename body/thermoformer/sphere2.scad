include <../../configure.scad>
use <bearing.scad>

cap_rad = rad/2;
cap_height = 45;

num_petals = 6;
petal_thick = 3;
petal_attach_rad = cap_rad - wall;


part = 10;
$fn=30;     //for rendering
//$fn=120;    //for printing


%cube([600,300,.1], center=true);
%cube([200,200,1], center=true);

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
gear_drive_diameter = 60;
gear_drive_teeth = 17;
gear_motor_teeth = 11;
gear_thick = 15;
gear_clearance = .1;

DR=0.5*1;   //this is the maximum depth ratio
P = 45;
nTwist = 1;
gear_pitchD = 0.9*gear_drive_diameter/(1+min(PI/(2*gear_drive_teeth*tan(P)),PI*DR/gear_drive_teeth));
gear_pitch = gear_pitchD*PI/gear_drive_teeth;
gear_pressure_angle = P;
gear_depth_ratio = DR;
gear_angle = atan(2*nTwist*gear_pitch/gear_thick);


module assembled(){
    for(i=[0,1]) mirror([0,0,i])
        translate([0,0,rad-cap_height]) cap(textured=false);
    
    for(i=[180/num_petals:360/num_petals:180-1])
        petal(angle=i, textured=false);
}

//the holes for the petals - all of them.
module petal_holes(){
    angle = 30;
    hole_sep = 90;
    
    for(i=[180/num_petals:360/num_petals:360-1]) rotate([0,0,i])
        rotate([angle,0,0]) translate([0,0,rad-wall-2]) {
            for(j=[-hole_sep/2, hole_sep/2]) translate([j,0,0]) {
                cylinder(r=m4_rad, h=wall+4);
                translate([0,0,wall-petal_thick+2]) cylinder(r1=m4_rad, r2=m4_rad+wall, h=wall);
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
            bb8_body();
        }
    }
}

module cap(textured = false){
    difference(){
        union(){
            //cap exterior
            translate([0,0,-rad+cap_height])
            intersection(){
                difference(){
                    sphere(r=rad);
                    sphere(r=rad-wall);
                }
               
                union(){
                    cylinder(r=petal_attach_rad/cos(180/6), h=rad+1, $fn=num_petals);
                
                    //petal attachment ring
                    intersection(){
                        cylinder(r=cap_rad/cos(180/6), h=rad+1, $fn=num_petals);
                        sphere(r=rad-petal_thick);
                    }
                }
                
                //texture it?
                if(textured == true){
                    bb8_body();
                }
            }
            
            //extra ring of material for petal screws?
            
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
            
            //connect the gear to the sphere
            hull(){
                translate([0,0,gear_thick]) cylinder(r=gear_drive_diameter/3, h=.1);
                translate([0,0,cap_height-wall+1]) cylinder(r=gear_drive_diameter*.75, h=.1);
            }
        }
        
        //central axle hole
        translate([0,0,-1]) cylinder(r=axle_rad, h=cap_height-wall+1);
        
        //holes to attach the petals
        translate([0,0,-rad+cap_height]) rotate([0,0,180/num_petals]) petal_holes();
        
        //flatten the bottom for easy printing
        translate([0,0,-rad]) cube([rad*2, rad*2, rad*2], center=true);
    }
}