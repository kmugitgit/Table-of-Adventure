var axle = windmill_point(66);
var turn_duration_ms = 20000;
var clock = instance_exists(obj_title_menu) ? obj_title_menu.play_time_ms : current_time;
var rotor_angle = image_angle - frac(clock / turn_duration_ms) * 360;

var previous_filter = gpu_get_texfilter();
gpu_set_texfilter(false);
draw_self();
var rotor_scale = abs(image_yscale);
draw_sprite_ext(spr_windmill_rotor, 0, axle.x, axle.y,
    rotor_scale, rotor_scale, rotor_angle, image_blend, image_alpha);
gpu_set_texfilter(previous_filter);
