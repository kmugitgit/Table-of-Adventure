if (room == rm_market || room == rm_restaurant || room == rm_kitchen || (instance_exists(obj_title_menu) && obj_title_menu.gameplay_input_blocked))
{
    walk_phase = 0;
    if (!fishing_busy(id)) facing = HeroFacing.Down;
    image_index = idle_frames[facing];
    exit;
}

if (tool_cooldown_timer > 0) tool_cooldown_timer--;

if (fishing_handle_input(id))
{
    walk_phase = 0;
    image_index = idle_frames[facing];
    exit;
}

inventory_rows = array_length(global.inventory_slots) div inventory_columns;

if (keyboard_check_pressed(vk_tab))
{
    if (inventory_open) inventory_close();
    else inventory_open = true;
}

var wheel_direction = mouse_wheel_down() - mouse_wheel_up();
if (wheel_direction != 0)
{
    var wheel_slot = global.inventory_slots[inventory_selected_slot];
    var wheel_item = is_struct(wheel_slot) ? inventory_get_item(wheel_slot.id) : undefined;
    if (keyboard_check(vk_shift) && !is_undefined(wheel_item) && wheel_item.kind == "tool")
        inventory_adjust_tool_area(wheel_slot, -wheel_direction);
    else
    {
        var slot_count = inventory_columns * (inventory_open ? inventory_rows : 1);
        inventory_selected_slot = (inventory_selected_slot + wheel_direction + slot_count) mod slot_count;
    }
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

    var layout = inventory_layout();
    var mouse_in_grid_x = (device_mouse_x_to_gui(0) - layout.x) / layout.scale - inventory_padding;
    var mouse_in_panel_y = (device_mouse_y_to_gui(0) - layout.y) / layout.scale;
    var column = floor(mouse_in_grid_x / inventory_slot_step);
    var pointer_slot = -1;
    if (column >= 0 && column < inventory_columns
        && mouse_in_grid_x - column * inventory_slot_step < inventory_slot_size)
    {
        for (var row = 0; row < layout.rows; row++)
        {
            var top = inventory_row_top(row, layout.first_top);
            if (mouse_in_panel_y >= top && mouse_in_panel_y < top + inventory_slot_size)
            {
                pointer_slot = row * inventory_columns + column;
                break;
            }
        }
    }

    var left_pressed = mouse_check_button_pressed(mb_left);
    var right_pressed = mouse_check_button_pressed(mb_right);
    var left_released = mouse_check_button_released(mb_left);
    var right_released = mouse_check_button_released(mb_right);
    var has_held_item = is_struct(inventory_held_stack);
    var double_click = left_pressed && pointer_slot == inventory_last_click_slot
        && current_time - inventory_last_click_time <= 400
        && has_held_item && inventory_held_stack.id == inventory_last_click_id;

    if (pointer_slot >= 0 && (left_pressed || right_pressed))
    {
        inventory_selected_slot = pointer_slot;
        var click_handled = false;
        if (double_click)
        {
            inventory_collect_matching(id, inventory_last_click_id);
            inventory_last_click_time = -1000;
            inventory_last_click_slot = -1;
            click_handled = true;
        }
        if (!click_handled && keyboard_check(vk_shift) && !has_held_item)
        {
            inventory_quick_move(pointer_slot);
            inventory_last_click_time = -1000;
            click_handled = true;
        }
        if (!click_handled && left_pressed)
        {
            if (has_held_item)
            {
                inventory_drag_mode = "left";
                inventory_drag_slots = [pointer_slot];
                inventory_drag_baseline = {
                    id: inventory_held_stack.id,
                    quantity: inventory_held_stack.quantity
                };
                inventory_drag_snapshots = [inventory_drag_snapshot(pointer_slot)];
                inventory_last_click_time = -1000;
            }
            else
            {
                var clicked_stack = global.inventory_slots[pointer_slot];
                if (is_struct(clicked_stack))
                {
                    inventory_last_click_slot = pointer_slot;
                    inventory_last_click_id = clicked_stack.id;
                    inventory_last_click_time = current_time;
                    inventory_pickup(id, pointer_slot, false);
                }
                else inventory_last_click_time = -1000;
            }
        }
        else if (!click_handled && right_pressed)
        {
            inventory_last_click_time = -1000;
            inventory_last_click_slot = -1;
            if (has_held_item)
            {
                inventory_drag_mode = "right";
                inventory_drag_slots = [pointer_slot];
                inventory_hold_right(id, pointer_slot);
            }
            else if (inventory_pickup(id, pointer_slot, true))
            {
                inventory_drag_mode = "right";
                // The clicked stack was picked up; don't place back into that cell.
                inventory_drag_slots = [pointer_slot];
            }
        }
    }

    if (inventory_drag_mode != "" && pointer_slot >= 0)
        inventory_drag_add_slot(id, pointer_slot);

    if (left_released && inventory_drag_mode == "left")
    {
        if (pointer_slot >= 0) inventory_drag_add_slot(id, pointer_slot);
        if (array_length(inventory_drag_slots) > 1)
        {
            var dragged_item = inventory_get_item(inventory_drag_baseline.id);
            if (!inventory_item_stackable(dragged_item))
                inventory_distribute_held(id, inventory_drag_slots);
        }
        else if (array_length(inventory_drag_slots) == 1)
            inventory_hold_left(id, inventory_drag_slots[0]);
        inventory_drag_mode = "";
        inventory_drag_slots = [];
        inventory_drag_baseline = undefined;
        inventory_drag_snapshots = [];
    }
    if (right_released && inventory_drag_mode == "right")
    {
        inventory_drag_mode = "";
        inventory_drag_slots = [];
    }

    walk_phase = 0;
    facing = HeroFacing.Down;
    image_index = idle_frames[facing];
    exit;
}

if (tool_use_timer > 0) tool_use_timer--;
if (mouse_check_button_pressed(mb_left) || mouse_check_button_pressed(mb_right))
{
    var layout = inventory_layout();
    var over_hotbar = point_in_rectangle(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0),
        layout.x, layout.y, layout.x + layout.width * layout.scale, layout.y + layout.height * layout.scale);
    var selector = instance_find(obj_tile_select, 0);
    var active_action_slot = global.inventory_slots[inventory_selected_slot];
    var active_action_item = is_struct(active_action_slot)
        ? inventory_get_item(active_action_slot.id) : undefined;
    var cooldown_ready = is_undefined(active_action_item)
        || active_action_item.kind != "tool" || tool_cooldown_timer <= 0;
    if (!over_hotbar && selector != noone && cooldown_ready)
    {
        var action_succeeded = terrain_use_tool(id, selector.pointer_target(id),
            mouse_check_button_pressed(mb_right));
        if (action_succeeded && !is_undefined(active_action_item)
            && active_action_item.kind == "tool")
        {
            var cooldown_seconds = max(0.1, 0.8 - clamp(floor(active_action_item.tier), 0, 4) * 0.1);
            tool_cooldown_timer = max(1, round(game_get_speed(gamespeed_fps) * cooldown_seconds));
        }
    }
}

if (keyboard_check_pressed(ord("F")))
{
    var restaurant=instance_nearest(x,y,obj_restaurant);
    var restaurant_feet=y+(sprite_get_bbox_bottom(sprite_index)-sprite_get_yoffset(sprite_index))*image_yscale;
    if(restaurant!=noone&&restaurant.player_at_door(x,restaurant_feet))
    {
        cooking_try_enter(id,restaurant);exit;
    }
    var windmill = instance_nearest(x, y, obj_windmill);
    var player_feet_y = y + (sprite_get_bbox_bottom(sprite_index)
        - sprite_get_yoffset(sprite_index)) * image_yscale;
    if (windmill != noone && windmill.player_at_door(x, player_feet_y))
    {
        global.windmill_return = { room_id: room, x: x, y: y };
        room_goto(rm_market);
        exit;
    }
}

var move_x = (keyboard_check(vk_right) || keyboard_check(ord("D")))
    - (keyboard_check(vk_left) || keyboard_check(ord("A")));
var move_y = (keyboard_check(vk_down) || keyboard_check(ord("S")))
    - (keyboard_check(vk_up) || keyboard_check(ord("W")));

// Normalize diagonal input so it doesn't move faster than a single direction.
var move_length = point_distance(0, 0, move_x, move_y);
if (move_length > 0)
{
    move_x /= move_length;
    move_y /= move_length;
}

if (move_x != 0 || move_y != 0)
{
    // On diagonal movement, keep the horizontal facing direction.
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
    var current_feet_y = y + (sprite_get_bbox_bottom(sprite_index) - origin_y) * image_yscale;
    var crosses_water = terrain_water_rectangle(terrain_tilemap,
        min(x, next_x) - feet_half_width,
        min(current_feet_y, feet_y) - 4 * abs(image_yscale),
        max(x, next_x) + feet_half_width, max(current_feet_y, feet_y));
    if ((next_x != x || next_y != y) && (global.developer.noclip || (!crosses_water && collision_rectangle(
        next_x - feet_half_width, feet_y - 4 * abs(image_yscale),
        next_x + feet_half_width, feet_y, obj_windmill, false, true) == noone
        && !cooking_building_blocks(next_x-feet_half_width,feet_y-4*abs(image_yscale),next_x+feet_half_width,feet_y))))
    {
        x = next_x;
        y = next_y;
        var feet_depth = -round(feet_y);
        if (depth != feet_depth) depth = feet_depth;
        image_index = walk_start_frames[facing] + floor(walk_phase);
        // Modulo avoids an epsilon comparison wrapping a near-final frame below zero.
        walk_phase = (walk_phase + walk_frames_per_step) mod walk_frame_count;
        exit;
    }
}

facing = HeroFacing.Down;
image_index = idle_frames[facing];
// Keep the gait phase moving while idle so quick taps don't restart on the same pose.
walk_phase = (walk_phase + walk_frames_per_step) mod walk_frame_count;
