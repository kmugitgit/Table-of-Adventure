if (room == rm_market || (instance_exists(obj_title_menu) && obj_title_menu.gameplay_input_blocked))
{
    walk_phase = 0;
    image_index = idle_frames[facing];
    exit;
}

if (keyboard_check_pressed(vk_tab))
{
    if (inventory_open) inventory_close();
    else inventory_open = true;
}

var wheel_direction = mouse_wheel_down() - mouse_wheel_up();
if (wheel_direction != 0)
{
    var slot_count = inventory_columns * (inventory_open ? inventory_rows : 1);
    inventory_selected_slot = (inventory_selected_slot + wheel_direction + slot_count) mod slot_count;
}
for (var slot_index = 0; slot_index < inventory_columns; slot_index++)
{
    if (keyboard_check_pressed(ord("1") + slot_index))
    {
        inventory_selected_slot = slot_index;
        break;
    }
}

if (inventory_open)
{
    var direction_x = keyboard_check_pressed(vk_right) - keyboard_check_pressed(vk_left);
    var direction_y = keyboard_check_pressed(vk_down) - keyboard_check_pressed(vk_up);
    var selected_row = inventory_selected_slot div inventory_columns;
    var selected_column = inventory_selected_slot mod inventory_columns;
    selected_row = clamp(selected_row + direction_y, 0, inventory_rows - 1);
    selected_column = clamp(selected_column + direction_x, 0, inventory_columns - 1);
    inventory_selected_slot = selected_row * inventory_columns + selected_column;

    if (mouse_check_button_pressed(mb_left))
    {
        var layout = inventory_layout();
        var mouse_in_grid_x = (device_mouse_x_to_gui(0) - layout.x) / layout.scale - inventory_padding;
        var mouse_in_panel_y = (device_mouse_y_to_gui(0) - layout.y) / layout.scale;
        var column = floor(mouse_in_grid_x / inventory_slot_step);
        if (column >= 0 && column < inventory_columns
            && mouse_in_grid_x - column * inventory_slot_step < inventory_slot_size)
        {
            for (var row = 0; row < layout.rows; row++)
            {
                var top = inventory_row_top(row, layout.first_top);
                if (mouse_in_panel_y >= top && mouse_in_panel_y < top + inventory_slot_size)
                {
                    inventory_selected_slot = row * inventory_columns + column;
                    break;
                }
            }
        }
    }

    walk_phase = 0;
    image_index = idle_frames[facing];
    exit;
}

if (keyboard_check_pressed(ord("F")))
{
    var windmill = instance_nearest(x, y, obj_windmill);
    if (windmill != noone && windmill.player_at_door(x, y))
    {
        global.windmill_return = { room_id: room, x: x, y: y };
        room_goto(rm_market);
        exit;
    }
}

var move_x = (keyboard_check(vk_right) || keyboard_check(ord("D")))
    - (keyboard_check(vk_left) || keyboard_check(ord("A")));
// Horizontal input takes priority when both axes are pressed.
var move_y = 0;
if (move_x == 0)
{
    move_y = (keyboard_check(vk_down) || keyboard_check(ord("S")))
        - (keyboard_check(vk_up) || keyboard_check(ord("W")));
}

if (move_x != 0 || move_y != 0)
{
    if (move_x > 0) facing = HeroFacing.Right;
    else if (move_x < 0) facing = HeroFacing.Left;
    else if (move_y < 0) facing = HeroFacing.Up;
    else facing = HeroFacing.Down;

    // Keep the visible sprite inside the room, including its head and feet.
    var origin_x = sprite_get_xoffset(sprite_index);
    var origin_y = sprite_get_yoffset(sprite_index);
    var left_margin = (origin_x - sprite_get_bbox_left(sprite_index)) * image_xscale;
    var right_margin = (sprite_get_bbox_right(sprite_index) + 1 - origin_x) * image_xscale;
    var top_margin = (origin_y - sprite_get_bbox_top(sprite_index)) * image_yscale;
    var bottom_margin = (sprite_get_bbox_bottom(sprite_index) + 1 - origin_y) * image_yscale;
    var next_x = clamp(x + move_x * move_speed, left_margin, room_width - right_margin);
    var next_y = clamp(y + move_y * move_speed, top_margin, room_height - bottom_margin);

    // Use only the hero's feet to test the solid tower, not the head or the rotor.
    var feet_y = next_y + (sprite_get_bbox_bottom(sprite_index) - origin_y) * image_yscale;
    var feet_half_width = 6 * abs(image_xscale);
    if ((next_x != x || next_y != y) && collision_rectangle(
        next_x - feet_half_width, feet_y - 4 * abs(image_yscale),
        next_x + feet_half_width, feet_y, obj_windmill, false, true) == noone)
    {
        x = next_x;
        y = next_y;
        if (depth != -round(y)) depth = -round(y);
        image_index = walk_start_frames[facing] + floor(walk_phase);
        walk_phase += walk_frames_per_step;
        if (walk_phase >= walk_frame_count) walk_phase -= walk_frame_count;
        exit;
    }
}

walk_phase = 0;
image_index = idle_frames[facing];
