// The axle is 66 pixels above the bottom-center origin of the tower.
var axle_distance = 66 * image_yscale;
var axle_direction = image_angle + 90;
var axle_x = x + lengthdir_x(axle_distance, axle_direction);
var axle_y = y + lengthdir_y(axle_distance, axle_direction);
var turn_duration_ms = 20000;
var clock = instance_exists(obj_title_menu) ? obj_title_menu.play_time_ms : current_time;
var rotor_angle = image_angle - frac(clock / turn_duration_ms) * 360;

var previous_filter = gpu_get_texfilter();
gpu_set_texfilter(false);
draw_self();
var rotor_scale = abs(image_yscale);
draw_sprite_ext(spr_windmill_rotor, 0, axle_x, axle_y,
    rotor_scale, rotor_scale, rotor_angle, image_blend, image_alpha);
gpu_set_texfilter(previous_filter);

var player = instance_nearest(x, y, obj_main_chr_girl);
if (player != noone && player_at_door(player.x, player.y))
{
    var previous_colour = draw_get_color();
    var previous_font = draw_get_font();
    var previous_halign = draw_get_halign();
    var previous_valign = draw_get_valign();
    var hint_y = y - 132 * image_yscale;

    draw_set_color(make_color_rgb(49, 35, 24));
    draw_rectangle(x - 10, hint_y - 10, x + 10, hint_y + 10, false);
    draw_set_color(make_color_rgb(250, 222, 163));
    draw_rectangle(x - 10, hint_y - 10, x + 10, hint_y + 10, true);
    draw_set_font(-1);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(x, hint_y, "F");

    draw_set_valign(previous_valign);
    draw_set_halign(previous_halign);
    draw_set_font(previous_font);
    draw_set_color(previous_colour);
}
