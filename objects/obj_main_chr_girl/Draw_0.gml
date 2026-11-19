if (room == rm_market) exit;

var previous_filter = gpu_get_texfilter();
gpu_set_texfilter(false);
var draw_x = round(x);
var draw_y = round(y);
draw_sprite_ext(sprite_index, image_index, draw_x, draw_y,
    image_xscale, image_yscale, image_angle, image_blend, image_alpha);
gpu_set_texfilter(previous_filter);
