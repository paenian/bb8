include <../configure.scad>

dog_rad = 40;
dog_sep = 140;

keypad_width = 60;

top_thick = 15;
bot_thick = 20;

wall = 3;
facets = 60;
$fn=facets;

part = 10;

if(part == 0)
    controller();
if(part == 1)
    bottom_right();

if(part == 10){
    controller();
    translate([0,100,0]) bottom_right();
}

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
            
            connectors(solid=1);
        
            //mounting lugs for the various components
            translate([-dog_sep/2,0,0]) mount2Axis(solid = 1);
            translate([dog_sep/2,0,0]) mount3Axis(solid = 1);
            mountButtons(solid = 1);
            mountPro(solid = 1);
        }
        
        connectors(solid=0, height=top_thick);
        
        //mounting holes for the various components
        translate([-dog_sep/2,0,0]) mount2Axis(solid = 0);
        translate([dog_sep/2,0,0]) mount3Axis(solid = 0);
        mountButtons(solid = 0);
        mountPro(solid = 0);
    }
}

module bottom_right(){
    offset = 15;
    charge_height = 10;
    charge_screwhole = 1.1;
    charge_screw_sep = .65*25.4;
    
    switch_rad = 16/2+.2;
    switch_nut_rad = 18/2+.5;
    switch_flat = .3;
    
    difference(){
        union(){
            dogbone(rad = dog_rad, sep = dog_sep, thick = bot_thick);
            

        }
        
        connectors(solid=0, height = bot_thick, end=1);
        
        translate([0,0,-wall]) difference(){
            dogbone(rad = dog_rad-wall, sep = dog_sep, thick = bot_thick, keypad_width = keypad_width-wall*2);
            
            connectors(solid=1, height = bot_thick);
            
            //standoffs for the battery mount - needs to be screwed down
            difference(){
                translate([offset,keypad_width/2-wall,bot_thick-charge_height+wall]) hull(){
                    for(i=[-1,1]) translate([charge_screw_sep*i/2,0,0]) {
                        cylinder(r=wall, h=charge_height);
                    }
                    translate([0,-charge_screw_sep,0])
                    cylinder(r=wall, h=charge_height);
                }
                
                //holes for the battery mount
                translate([offset,keypad_width/2-wall,bot_thick-charge_height+wall-1]){
                    for(i=[-1,1]) translate([charge_screw_sep*i/2,0,0]) {
                        cylinder(r=charge_screwhole, h=charge_height+.5);
                     }
                  }
            }
        }
        
        //usb hole
        translate([offset,keypad_width/2-wall,bot_thick-charge_height+wall-6.5]) hull(){
            for(i=[-1,1]) translate([5*i,0,0]) {
                rotate([90,0,0]) cylinder(r=3.25, h=bot_thick, center=true);
             }
         }
         
         //switch hole
         translate([-offset,keypad_width/2,switch_nut_rad-1]) rotate([90,0,0]) union(){
             //the switch hole
             difference(){
                cylinder(r=switch_rad, h=bot_thick, center=true);
                for(i=[-1,1]) translate([(25+switch_rad-switch_flat)*i,0,0]) cube([50,50,50], center=true);
             }
             
             //flat for the nut to tighten
             cylinder(r=switch_nut_rad, h=keypad_width/2);
         }
    }
}

module connectors(solid = 1, height=10, end=0){
    for(i=[0,1]) mirror([i,0,0]){
        for(j=[0,1]) mirror([0,j,0]) translate([keypad_width/2+m3_cap_rad+wall/2,keypad_width/2-wall,0]){
            //screws around the keypad
            if(solid == 1){
                cylinder(r=m3_rad+wall/2, h=bot_thick);
            }else{
                translate([0,0,-4.7]) cylinder(r=m3_rad, h=height);
                if(end == 0){
                    //cone
                    translate([0,0,height-2]) cylinder(r1=m3_rad, r2=m3_rad+3, h=3);
                    cylinder(r=m3_rad, h=height);
                }
                if(end == 1){
                    //nut
                    translate([0,0,height-4.5]) cylinder(r1=m3_sq_nut_rad, r2=m3_sq_nut_rad+.5, h=5, $fn=4);
                }
            }
        }
        
    //end screws
    translate([dog_rad+dog_sep/2 - wall*2,0,0]){
        //screws around the keypad
        if(solid == 1){
            cylinder(r=m3_rad+wall, h=bot_thick);
        }else{
            translate([0,0,-4.7]) cylinder(r=m3_rad, h=height);
            if(end == 0){
                //cone
                translate([0,0,height-2]) cylinder(r1=m3_rad, r2=m3_rad+3, h=3);
                cylinder(r=m3_rad, h=height);
            }
            if(end == 1){
                //nut
                translate([0,0,height-4.5]) cylinder(r1=m3_sq_nut_rad, r2=m3_sq_nut_rad+.5, h=5, $fn=4);
            }
       }
    }
}}

module dogbone(rad = 30, sep = 60, thick = 6){
    chamfer = 3;
    for(i=[0,1]) mirror([i,0,0]) translate([sep/2,0,0]){
        cylinder(r=rad, h=thick-chamfer);
        translate([0,0,thick-chamfer-.1]) cylinder(r1=rad, r2=rad-chamfer, h=chamfer+.1);
    }
    
    //connect 'em up
    hull(){
      #translate([0,0,(thick-chamfer*4.5)/2]) cube([sep,rad,thick-chamfer*4.5],center=true);
      #translate([0,0,(thick-chamfer)/2]) cube([keypad_width+wall*2,keypad_width+wall*2,thick-chamfer],center=true);
        
      //translate([0,0,thick-chamfer]) cube([sep-chamfer*2,rad,chamfer],center=true);
      translate([0,0,thick-chamfer/2]) cube([keypad_width+wall*2,keypad_width+wall*2-chamfer*2,chamfer],center=true);  
    }
}

module mount2Axis(solid = 0){
    stick_rad = 29/2;
    stick_screw_sep = 30;
    
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
    stick_rad = 39/2;
    stick_screw_sep = 33;
    
    if(solid == 0){
        cylinder(r=stick_rad, h=top_thick*2);
    }
    
    for(i=[0,1]) for(j=[0,1]) mirror([i,0,0]) mirror([0,j,0]) translate([stick_screw_sep/2, stick_screw_sep/2, 0]){
        if(solid == 1){
            //translate([0,0,wall+1]) cylinder(r=m3_cap_rad, h=top_thick);
        }
        if(solid == 0){
            cylinder(r=m3_rad, h=top_thick+wall+.1);
        }
    }
}

module mountButtons(solid = 0){
    //keypad is 60x60
    button_width = 10;
    button_gap = 5;
    slop = 1;
    
    if(solid == 0) translate([-keypad_width/2+button_gap/2-slop/2,-keypad_width/2+button_gap/2-slop/2,-1]) {
        translate([-button_gap/2,-button_gap/2,0]) cube([keypad_width+slop,keypad_width+slop,top_thick-wall+1]);
        
        for(i=[0:3]) for(j=[0:3]) translate([(button_width/2)+(button_gap+button_width)*i+slop/2, (button_width/2) + (button_gap+button_width)*j+slop/2,0]){
            cube([button_width+slop, button_width+slop, top_thick*3], center=true);
        }
    }
}