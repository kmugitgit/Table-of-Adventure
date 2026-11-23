depth = -100000;
selection_active = false;
selection_in_range = false;

selection_target = function(_player, _mouse_room_x, _mouse_room_y)
{
    if (_player == noone || _player.inventory_open || room != rm_main) return undefined;
    if (instance_exists(obj_title_menu) && obj_title_menu.gameplay_input_blocked) return undefined;
    var selected = global.inventory_slots[_player.inventory_selected_slot];
    if (!is_struct(selected)) return undefined;
    var item = inventory_get_item(selected.id);
    if (is_undefined(item) || item.kind != "tool") return undefined;
    var map = _player.terrain_tilemap;
    if (map == -1) return undefined;

    var feet_y = _player.y + (sprite_get_bbox_bottom(_player.sprite_index)
        - sprite_get_yoffset(_player.sprite_index)) * _player.image_yscale;
    var centre_col = tilemap_get_cell_x_at_pixel(map, _player.x, feet_y);
    var centre_row = tilemap_get_cell_y_at_pixel(map, _player.x, feet_y);
    var mouse_col = tilemap_get_cell_x_at_pixel(map, _mouse_room_x, _mouse_room_y);
    var mouse_row = tilemap_get_cell_y_at_pixel(map, _mouse_room_x, _mouse_room_y);
    if (centre_col < 0 || centre_row < 0 || mouse_col < 0 || mouse_row < 0) return undefined;
    var within_reach = abs(mouse_col - centre_col) <= 1 && abs(mouse_row - centre_row) <= 1;
    if (tile_get_index(tilemap_get(map, mouse_col, mouse_row)) == 0) return undefined;
    var tile_width = tilemap_get_tile_width(map);
    var tile_height = tilemap_get_tile_height(map);
    var tile_x = tilemap_get_x(map) + mouse_col * tile_width;
    var tile_y = tilemap_get_y(map) + mouse_row * tile_height;
    return {
        column: mouse_col, row: mouse_row,
        within_reach: within_reach,
        x: tile_x,
        y: tile_y,
        width: tile_width, height: tile_height
    };
};

// Resolve the hovered tile using the current camera.
pointer_target = function(_player)
{
    // Resolve the mouse after the following camera has updated for this draw.
    if (room != rm_main || view_camera[view_current] == -1) return undefined;
    var camera = view_camera[view_current];
    var application_rect = application_get_position();
    var pointer_x = window_mouse_get_x();
    var pointer_y = window_mouse_get_y();
    if (!point_in_rectangle(pointer_x, pointer_y, application_rect[0], application_rect[1],
    application_rect[2] - 1, application_rect[3] - 1)) return undefined;
    var room_mouse_x = camera_get_view_x(camera) + (pointer_x - application_rect[0])
    * camera_get_view_width(camera) / (application_rect[2] - application_rect[0]);
    var room_mouse_y = camera_get_view_y(camera) + (pointer_y - application_rect[1])
    * camera_get_view_height(camera) / (application_rect[3] - application_rect[1]);
    return selection_target(_player, room_mouse_x, room_mouse_y);
};
