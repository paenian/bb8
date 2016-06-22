include <../../configure.scad>

in = 25.4;

rad = 250;
ring_rad = 150;         //the radius of the orange rings
center_rad = 100;       //radius of the inside of the orange ring
cap_rad = 125;          //radius of our cap

slice_wall = .25*in;

cap(textured = false, printing=false, num_slices = 6);

*print_slice(num_slices = 6);
*thermo_slice(num_slices = 6);
cap_slice(num_slices = 6);

$fn=30;

module thermo_slice(rad = rad-slice_wall-.1, num_slices = 6){
    hull(){
        translate([0,0,-center_rad]) 
        rotate([0,-90,0]) cap_slice(rad = rad, num_slices = num_slices);
    }
}

module print_slice(rad = rad, num_slices = 6){
    rotate([90,0,0]) rotate([0,0,360/(num_slices*2)]) cap_slice(rad = rad, num_slices = num_slices);
}

//a slice of lemon shape, without the domed ends.
//This is what will be thermoformed.
//radius = rad;     //print the panels full size
//radius = rad - slice_wall;    //print the panel ready for thermoforming
module cap_slice(rad = rad, num_slices = 8){
    
    support_height = rad/2;
    support_rad = sqrt(support_height * (2*rad - support_height));
    
    difference(){
        sphere(r=rad);
        
        //the slice
        for(i=[-1,1]) rotate([0,0,i*90 + i*(360/(num_slices*2))]) translate([0,-500,-500])
            cube([1000,1000,1000]);
        
        //remove the caps
        for(i=[0:1]) mirror([0,0,i])
            cap(rad = rad, textured = false, printing = false);
            
        //hollow it out
        difference(){
            sphere(r=rad - slice_wall+.1);
            
            //ribs for strength/joining the middle
            for(i=[0,1]) mirror([0,0,i]) translate([0,0,support_height]) {
                rotate_extrude(){
                    hull(){
                        translate([support_rad,0,0]) square([slice_wall*2,slice_wall*2], center=true);
                        translate([support_rad,0,0]) square([slice_wall*5,slice_wall*2], center=true);
                    }
                }
            }
        }
        //zip tie slots in the ribs - go through everything
        for(i=[0,1]) mirror([0,0,i]) translate([0,0,support_height]) {
            for(j=[0,1]) mirror([0,j,0]) rotate([0,0,360/(num_slices*2)]) translate([support_rad-12-10,0,0]){
                scale([1,2,1]) rotate_extrude(){
                    translate([4,0,0]) square([2.5,6],center=true);
                }
            }
        }
        
        //make some screwholes to mount the panels
        panel_screws(num_slices = num_slices);
    }
}

//a dome-shaped section of a sphere
module cap_section(big_rad = 250, lil_rad = 150){
    height = big_rad-sqrt(big_rad*big_rad-lil_rad*lil_rad);
    translate([0,0,big_rad-height]) 
    intersection(){
        translate([0,0,height-big_rad]) sphere(r=big_rad);
        translate([0,0,250]) cube([500,500,500],center=true);
    }
}

//the cap 
module cap(textured = false, printing = true, num_slices = 6){
    inner_rad = rad - slice_wall;
    
    inner_height = inner_rad-sqrt(inner_rad*inner_rad-ring_rad*ring_rad);
    
    %cylinder(r=ring_rad, h=10);
    
    translate([0,0,printing?inner_height-inner_rad:0])
    intersection(){
        difference(){
            union(){
                //the base, upon which the body panels mount
                cap_section(big_rad = inner_rad, lil_rad = ring_rad);
        
                //the outside top
                hull(){
                    //#translate([0,0,slice_wall])
                    cap_section(big_rad = rad, lil_rad = cap_rad);
                sphere(r=.1);
                }
            }
       
            //hollow out the inside - have to make this smarter, avoid using all the support
            sphere(r=rad-wall);
            
            //make some screwholes to mount the panels
            panel_screws(num_slices = num_slices);
            
            //make some screwholes to mount the drive system
            //drive_screws();
        }
        
        //texture it
        if(textured == true)
            bb8_texture();
        
        rotate([0,0,360/(num_slices*2)]) cylinder(r=ring_rad, h=600, $fn=num_slices*2);
    }
}

module panel_screws(num_slices = 6){
    for(i=[180/(num_slices*2):360/(num_slices*2):359]) rotate([0,0,i]) {
        rotate([0,-57.5,0]) translate([rad,0,0]) rotate([0,90,0]){
            //cap
            translate([0,0,0]) cylinder(r=m5_cap_rad, h=m5_cap_height, center=true);
            translate([0,0,1-m5_cap_height]) cylinder(r1=m5_rad, r2=m5_cap_rad, h=m5_cap_height, center=true);
            
            //screw
            cylinder(r=m5_rad, h=25, center=true);
        }
    }
}

//STL of the full BB8, centered, rotated, scaled, sized, etc.
module bb8_texture(){
    s=6.4;
    //scale([s,s,s]) rotate([0,0,-27.5]) rotate([0,3.6,0]) rotate([29.25,0,0])import("bb8_union_rep_simplified.stl");
    
    scale([s,s,s]) import("body_solid.stl");
}