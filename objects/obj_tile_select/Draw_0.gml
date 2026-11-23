terrain_draw_crops();
selection_active = false;
selection_in_range = false;
if (room != rm_main || view_camera[view_current] == -1) exit;
var player = instance_find(obj_main_chr_girl, 0);
if (player == noone) exit;

var target = pointer_target(player);
if (is_undefined(target)) exit;

selection_active = true;
selection_in_range = target.within_reach;
x = target.x;
y = target.y;
var previous_filter = gpu_get_texfilter();
gpu_set_texfilter(false);
var cells = terrain_tool_targets(player, target, false);
for (var i = 0; i < array_length(cells); i++)
{
    var cell = cells[i];
    draw_sprite_stretched(sprite_index, cell.can_interact ? 0 : 1,
        cell.x, cell.y, cell.width, cell.height);
}
gpu_set_texfilter(previous_filter);
