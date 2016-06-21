include <../configure.scad>

hub_rad = 40;
in = 25.4;


stand_base();
for(i=[0:120:359]) rotate([0,0,i]) 
    stand_arm();

$fn=60;

module stand_arm(){
    angle = 33;
    
    difference(){
        union(){
            hull(){
                cylinder(r=hub_rad, h=wall*2, $fn=3);
                translate([-155,0,0]) cylinder(r=in/2, h=.1);
                translate([0,0,rad+wall-2]) rotate([0,angle,0]) translate([0,0,-rad]) cylinder(r=in/2+wall/2, h=.1, center=true);
            }
        }
        
        //curve it up a bit
        translate([0,0,rad+wall-2]) sphere(r=rad, $fn=180);
        %translate([0,0,rad+wall-2+in*.4]) sphere(r=rad, $fn=180);
        
        //cut out the hub
        translate([0,0,-wall/3]) stand_base(holes=false, hub_rad=hub_rad+1);
        translate([0,0,wall/3]) stand_base(holes=false, hub_rad=hub_rad+1);
        
        //we gotta zip tie in :-)
        translate([-hub_rad/2-wall/3,0,0]) for(j=[-hub_rad/2, hub_rad/2]) translate([0,j,0]) {
            cube([2,6,wall*3], center=true);
            //clear a base channel
            translate([2,0,0]) cube([5,6,2], center=true);
        }
        
        //mount the rollers
        translate([0,0,rad+wall-2]) rotate([0,angle,0]) translate([0,0,-rad]){
            //cube([10,10,10], center=true);
            roller_mount();
        }
    }
}

module roller_mount(){
    union(){
        //sink the mount in a bit
        cylinder(r=in/2+.2, h=in, center=true);
        
        //flat back for the screws
        translate([0,0,-in-in*2/3-5]) cylinder(r=in, h=in+10, center=true);
        
        //and some screwholes
        for(i=[-in/8, in/8]) translate([i,0,0]) cylinder(r=1.8, h=100, center=true);
    }
}

//triangular mounting point for the arms
module stand_base(holes=true){
    difference(){
        cylinder(r=hub_rad, h=wall, $fn=3);
        
        if(holes==true){
            //zip tie holes
            for(i=[60:120:359]) rotate([0,0,i]) translate([hub_rad/2-wall/3,0,0]) {
                for(j=[-hub_rad/2, hub_rad/2]) translate([0,j,0]) {
                    cube([2,6,wall*3], center=true);
                    //clear a base channel
                    translate([2,0,0]) cube([5,6,2], center=true);
                }
            }
        }
    }
}