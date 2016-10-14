
base_gap = 5;
wall = 3;

bb8_scale = .10;
bb8_head = 300;
bb8_body = 500;

top();

//top
module top(){
    union(){
        base_top();
        
        translate([0,0,wall-.1]) intersection(){
            scale([bb8_scale,bb8_scale,bb8_scale]) bb8_texture();
            translate([0,0,100]) cube([200,200,200], center=true);
        }
    }
}

module base_top(){
    difference(){
        minkowski(){
            linear_extrude(height = .1){
                projection(cut = true) scale([bb8_scale,bb8_scale,bb8_scale]) bb8();
            }
            cylinder(r=base_gap+wall, h=bb8_body*bb8_scale/2+wall*2);
        }
        
        translate([0,0,wall]) minkowski(){
            linear_extrude(height = .1){
                projection(cut = true) scale([bb8_scale,bb8_scale,bb8_scale]) bb8();
            }
            cylinder(r=base_gap, h=bb8_body*bb8_scale/2+wall*2);
        }
    }
}

module bb8_texture(){
    s=.66;
    scale([s,s,s])
    //rotate([0,90,0])
    union(){
        import("body.stl");
        rotate([0,20,0]) translate([4,550,15]) import("head.stl");
    }
}

module bb8(){
    sphere(r=bb8_body/2);
    translate([0,bb8_body/2+25,0]) sphere(r=bb8_head/2);
}