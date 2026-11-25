if (room == rm_market) exit;

var previous_filter = gpu_get_texfilter();
gpu_set_texfilter(false);
terrain_draw_held_tool(id, true);
fishing_draw_world(id);
draw_sprite_ext(sprite_index, image_index, x, y,
    image_xscale, image_yscale, image_angle, image_blend, image_alpha);
terrain_draw_held_tool(id, false);
gpu_set_texfilter(previous_filter);
