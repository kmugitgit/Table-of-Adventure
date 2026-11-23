menu_page = room == rm_title ? TitleMenuPage.Title : TitleMenuPage.Playing;
gameplay_input_blocked = false;
dragged_slider = -1;
hovered_button = -1;
menu_error = "";

if (room == rm_title) global.windmill_return = undefined;
if (!is_struct(pending_load)) exit;

var data = pending_load;
pending_load = undefined;
codex_restore_history(variable_struct_get(data, "codex_discovered"));
inventory_restore(variable_struct_get(data, "inventory"));
with (obj_market)
{
    market_catalog = market_stock_catalog();
    market_select(0);
}
var saved_gold = variable_struct_get(data, "gold");
global.player_gold = is_numeric(saved_gold) && saved_gold >= 0 ? floor(saved_gold) : 100;
var player = instance_find(obj_main_chr_girl, 0);
if (player == noone) exit;

player.x = clamp(data.x, 0, room_width - 1);
player.y = clamp(data.y, 0, room_height - 1);
player.facing = clamp(round(data.facing), 0, array_length(player.idle_frames) - 1);
player.image_index = player.idle_frames[player.facing];
player.inventory_selected_slot = clamp(round(data.selected_slot), 0, player.inventory_columns - 1);
terrain_keep_on_land(player);
player.depth = -round(player.y + (sprite_get_bbox_bottom(player.sprite_index)
    - sprite_get_yoffset(player.sprite_index)) * player.image_yscale);

global.windmill_return = undefined;
var entrance = variable_struct_get(data, "entrance");
if (!is_struct(entrance)) exit;

var outside_name = variable_struct_get(entrance, "room_name");
var outside_x = variable_struct_get(entrance, "x");
var outside_y = variable_struct_get(entrance, "y");
if (!is_string(outside_name) || !is_numeric(outside_x) || !is_numeric(outside_y)) exit;

var outside_room = asset_get_index(outside_name);
if (room_exists(outside_room) && outside_room != rm_title && outside_room != rm_market
    && outside_x >= 0 && outside_x < 1000000 && outside_y >= 0 && outside_y < 1000000)
{
    global.windmill_return = { room_id: outside_room, x: outside_x, y: outside_y };
}
