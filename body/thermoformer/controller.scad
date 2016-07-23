include <../configure.scad>
include <../../configure.scad>

dog_rad = 30;
dog_sep = 120;

keypad_width = 60;

top_thick = 10;

wall = 3;
$fn=60;


controller();

module controller(){
    //dogbone :-)
    difference(){
        union(){
            dogbone(rad = dog_rad, sep = dog_sep, thick = top_thick);
        }
        
        //hollow out the bone
        translate([0,0,-wall])
        difference(){
            dogbone(rad = dog_rad-wall, sep = dog_sep, thick = top_thick, keypad_width = keypad_width-wall*2);
        
            //mounting lugs for the various components
            translate([-dog_sep/2,0,0]) mount2Axis(solid = 1);
            translate([dog_sep/2,0,0]) mount3Axis(solid = 1);
            mountButtons(solid = 1);
            mountPro(solid = 1);
        }
        
        //mounting holes for the various components
        translate([-dog_sep/2,0,0]) mount2Axis(solid = 0);
        translate([dog_sep/2,0,0]) mount3Axis(solid = 0);
        mountButtons(solid = 0);
        mountPro(solid = 0);
    }
}

module dogbone(rad = 30, sep = 60, thick = 6){
    chamfer = 2.5;
    for(i=[0,1]) mirror([i,0,0]) translate([sep/2,0,0]){
        cylinder(r=rad, h=thick-chamfer);
        translate([0,0,thick-chamfer-.1]) cylinder(r1=rad, r2=rad-chamfer, h=chamfer+.1);
    }
    
    //connect 'em up
    hull(){
      translate([0,0,(thick-chamfer)/2]) cube([sep,rad,thick-chamfer],center=true);
      translate([0,0,(thick-chamfer)/2]) cube([keypad_width+wall*2,keypad_width+wall*2,thick-chamfer],center=true);
        
      //translate([0,0,thick-chamfer]) cube([sep-chamfer*2,rad,chamfer],center=true);
      translate([0,0,thick-chamfer/2-.5]) cube([keypad_width+wall*2,keypad_width+wall*2-chamfer*2,chamfer],center=true);  
    }
}

module mount2Axis(solid = 0){
    stick_rad = 10;
    stick_screw_sep = 20;
    
    if(solid == 0){
        cylinder(r=stick_rad, h=top_thick*2);
    }
    
    for(i=[0,1]) for(j=[0,1]) mirror([i,0,0]) mirror([0,j,0]) translate([stick_screw_sep/2, stick_screw_sep/2, 0]){
        if(solid == 1){
            translate([0,0,wall+1]) cylinder(r=m3_cap_rad, h=top_thick);
        }
        if(solid == 0){
            cylinder(r=m3_rad, h=top_thick+wall+.1);
        }
    }
}

module mount3Axis(solid = 0){
    stick_rad = 14;
    stick_screw_sep = 25;
    
    if(solid == 0){
        cylinder(r=stick_rad, h=top_thick*2);
    }
    
    for(i=[0,1]) for(j=[0,1]) mirror([i,0,0]) mirror([0,j,0]) translate([stick_screw_sep/2, stick_screw_sep/2, 0]){
        if(solid == 1){
            translate([0,0,wall+1]) cylinder(r=m3_cap_rad, h=top_thick);
        }
        if(solid == 0){
            cylinder(r=m3_rad, h=top_thick+wall+.1);
        }
    }
}

module mountButtons(solid = 0){
    //keypad is 60x60
    button_width = 9;
    button_gap = 4.5;
    
    if(solid == 0) translate([-keypad_width/2,-keypad_width/2,0]) {
        //cube([keypad_width,keypad_width,keypad_width], center=true);
        for(i=[0:3]) for(j=[0:3]) translate([(button_gap+button_width/2)+(button_gap+button_width)*i, (button_gap+button_width/2) + (button_gap+button_width)*j,0]){
            cube([button_width, button_width, top_thick*3], center=true);
        }
    }
}