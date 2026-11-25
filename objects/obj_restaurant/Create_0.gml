restaurant_point = function(_local_x,_local_y)
{
 var dx=(_local_x-sprite_get_xoffset(sprite_index))*image_xscale;
 var dy=(_local_y-sprite_get_yoffset(sprite_index))*image_yscale;
 return {x:x+dx*dcos(image_angle)+dy*dsin(image_angle),y:y-dx*dsin(image_angle)+dy*dcos(image_angle)};
};
player_at_door = function(_px,_py)
{
 var door=restaurant_point(53,203);var dx=_px-door.x;var dy=_py-door.y;
 var sideways=dx*dcos(image_angle)-dy*dsin(image_angle);
 var forward=dx*dsin(image_angle)+dy*dcos(image_angle);
 return abs(sideways)<=18*abs(image_xscale)&&forward>=0&&forward<=36*abs(image_yscale);
};
depth=-round(restaurant_point(80,201).y);
