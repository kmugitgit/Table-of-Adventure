/// Collision against the water family of ts_all.
function terrain_water_rectangle(_map, _left, _top, _right, _bottom)
{
    if (_map == -1 || tilemap_get_tileset(_map) != ts_all) return false;
    var tile_width = tilemap_get_tile_width(_map);
    var tile_height = tilemap_get_tile_height(_map);
    var map_x = tilemap_get_x(_map);
    var map_y = tilemap_get_y(_map);
    var first_x = max(0, floor((_left - map_x) / tile_width));
    var first_y = max(0, floor((_top - map_y) / tile_height));
    var last_x = min(tilemap_get_width(_map) - 1, floor((_right - map_x) / tile_width));
    var last_y = min(tilemap_get_height(_map) - 1, floor((_bottom - map_y) / tile_height));
    for (var row = first_y; row <= last_y; row++)
    {
        for (var col = first_x; col <= last_x; col++)
        {
            var index = tile_get_index(tilemap_get(_map, col, row));
            // The 47 water autotiles occupy this range in ts_all.
            if (index >= 145 && index <= 191) return true;
        }
    }
    return false;
}

function terrain_keep_on_land(_player)
{
    var map = _player.terrain_tilemap;
    var foot_offset = (sprite_get_bbox_bottom(_player.sprite_index)
        - sprite_get_yoffset(_player.sprite_index)) * _player.image_yscale;
    var feet_y = _player.y + foot_offset;
    var half_width = 6 * abs(_player.image_xscale);
    var foot_height = 4 * abs(_player.image_yscale);
    if (!terrain_water_rectangle(map, _player.x - half_width, feet_y - foot_height,
        _player.x + half_width, feet_y)) return;

    // Older saves may contain a position inside the pond. Find the nearest dry footing.
    var tile_width = tilemap_get_tile_width(map);
    var tile_height = tilemap_get_tile_height(map);
    var map_x = tilemap_get_x(map);
    var map_y = tilemap_get_y(map);
    var best_distance = 1000000000000000000;
    var best_x = _player.x;
    var best_y = _player.y;
    var origin_x = sprite_get_xoffset(_player.sprite_index);
    var origin_y = sprite_get_yoffset(_player.sprite_index);
    var left_margin = (origin_x - sprite_get_bbox_left(_player.sprite_index)) * _player.image_xscale;
    var right_margin = (sprite_get_bbox_right(_player.sprite_index) + 1 - origin_x) * _player.image_xscale;
    var top_margin = (origin_y - sprite_get_bbox_top(_player.sprite_index)) * _player.image_yscale;
    var bottom_margin = (sprite_get_bbox_bottom(_player.sprite_index) + 1 - origin_y) * _player.image_yscale;
    for (var row = 0; row < tilemap_get_height(map); row++)
    {
        for (var col = 0; col < tilemap_get_width(map); col++)
        {
            var candidate_x = map_x + (col + 0.5) * tile_width;
            var candidate_feet_y = map_y + (row + 0.5) * tile_height;
            var candidate_y = candidate_feet_y - foot_offset;
            var distance_squared = sqr(candidate_x - _player.x) + sqr(candidate_feet_y - feet_y);
            if (distance_squared >= best_distance || candidate_x < left_margin
                || candidate_x > room_width - right_margin || candidate_y < top_margin
                || candidate_y > room_height - bottom_margin) continue;
            if (terrain_water_rectangle(map, candidate_x - half_width, candidate_feet_y - foot_height,
                candidate_x + half_width, candidate_feet_y)) continue;
            if (collision_rectangle(candidate_x - half_width, candidate_feet_y - foot_height,
                candidate_x + half_width, candidate_feet_y, obj_windmill, false, true) != noone) continue;
            best_distance = distance_squared;
            best_x = candidate_x;
            best_y = candidate_y;
        }
    }
    _player.x = best_x;
    _player.y = best_y;
}


// Persist only changed cells; the original room remains the source for neighbour_family tiles.
function terrain_restore_changes(_saved)
{
    global.terrain_changes = [];
    if (!is_array(_saved)) return;
    for (var i = 0; i < min(array_length(_saved), 160 * 90); i++)
    {
        var cell = _saved[i];
        if (!is_struct(cell)) continue;
        var col = variable_struct_get(cell, "column");
        var row = variable_struct_get(cell, "row");
        var index = variable_struct_get(cell, "index");
        if (!is_numeric(col) || !is_numeric(row) || !is_numeric(index)) continue;
        if (col != floor(col) || row != floor(row) || index != floor(index)
            || col < 0 || row < 0 || col >= 160 || row >= 90
            || index < 1 || index > 287 || index mod 48 == 0) continue;
        array_push(global.terrain_changes, { column: col, row: row, index: index });
    }
}

function terrain_apply_changes(_map)
{
    if (!variable_global_exists("terrain_changes")) global.terrain_changes = [];
    if (room != rm_main || _map == -1 || tilemap_get_tileset(_map) != ts_all) return;
    for (var i = 0; i < array_length(global.terrain_changes); i++)
    {
        var cell = global.terrain_changes[i];
        if (cell.column < tilemap_get_width(_map) && cell.row < tilemap_get_height(_map))
            tilemap_set(_map, cell.index, cell.column, cell.row);
    }
    // Repair old saves that stored only a centre tile, before runtime autotiling existed.
    var changed_count = array_length(global.terrain_changes);
    for (var i = 0; i < changed_count; i++)
    {
        var cell = global.terrain_changes[i];
        terrain_retile_area(_map, cell.column, cell.row);
    }
}

function terrain_write_cell(_map, _col, _row, _index)
{
    tilemap_set(_map, _index, _col, _row);
    if (!variable_global_exists("terrain_changes")) global.terrain_changes = [];
    for (var i = 0; i < array_length(global.terrain_changes); i++)
    {
        var cell = global.terrain_changes[i];
        if (cell.column == _col && cell.row == _row)
        {
            cell.index = _index;
            return;
        }
    }
    array_push(global.terrain_changes, { column: _col, row: _row, index: _index });
}

function terrain_use_tool_cell(_player, _target, _refill)
{
    if (room != rm_main || _player.inventory_open || is_undefined(_target) || !_target.within_reach) return false;
    if (instance_exists(obj_title_menu) && obj_title_menu.gameplay_input_blocked) return false;
    var slot = global.inventory_slots[_player.inventory_selected_slot];
    if (!is_struct(slot)) return false;
    var item = inventory_get_item(slot.id);
    if (is_undefined(item)) return false;
    var map = _player.terrain_tilemap;
    if (map == -1 || tilemap_get_tileset(map) != ts_all) return false;
    if (collision_rectangle(_target.x, _target.y, _target.x + _target.width - 0.01,
        _target.y + _target.height - 0.01, obj_windmill, false, true) != noone) return false;
    var index = tile_get_index(tilemap_get(map, _target.column, _target.row));
    if (!terrain_item_allows_tile(item, index)) return false;
    if (!_refill && item.kind == "seed")
    {
        var family = terrain_family(index);
        if ((family != 4 && family != 5) || terrain_crop_index(_target.column, _target.row) != -1) return false;
        array_push(global.planted_crops, { column: _target.column, row: _target.row, seed_id: slot.id });
        slot.quantity--;
        if (slot.quantity <= 0) global.inventory_slots[_player.inventory_selected_slot] = undefined;
        return true;
    }
    if (item.kind != "tool") return false;
    if (_refill)
    {
        if (item.tool_kind != "can" || index < 145 || index > 191) return false;
        slot.water = inventory_water_capacity(slot);
    }
    else if (item.tool_kind == "hoe")
    {
        if (!((index >= 1 && index <= 47) || (index >= 49 && index <= 95))) return false;
        terrain_change_cell(map, _target.column, _target.row, 198);
    }
    else if (item.tool_kind == "can")
    {
        var water = inventory_water_amount(slot);
        if (water <= 0 || index < 193 || index > 239) return false;
        terrain_change_cell(map, _target.column, _target.row, index + 48);
        slot.water = water - 1;
    }
    else if (item.tool_kind == "shovel")
    {
        var crop_index = terrain_crop_index(_target.column, _target.row);
        if (crop_index != -1)
        {
            // Return the seed first; a full inventory leaves the planted crop untouched.
            var crop = global.planted_crops[crop_index];
            if (!inventory_return_seed(crop.seed_id)) return false;
            array_delete(global.planted_crops, crop_index, 1);
        }
        else
        {
            var family = terrain_family(index);
            if (family == 4 || family == 5) terrain_change_cell(map, _target.column, _target.row, 54);
            else if (family == 1 || family == 2) terrain_change_cell(map, _target.column, _target.row, 6);
            else return false;
        }
    }
    else return false;
    _player.tool_use_duration = max(1, round(game_get_speed(gamespeed_fps)
        * (item.tool_kind == "can" ? 0.5 : 0.38)));
    _player.tool_use_timer = _player.tool_use_duration;
    _player.tool_use_item_id = slot.id;
    return true;
}

// Keep the grip fixed while the tool head swings down, then eases back to rest.
function terrain_held_tool_pose(_player, _item)
{
    var tool_scale = abs(_player.image_yscale) * 0.65;
    var left_hand = _player.facing == HeroFacing.Left;
    var mirror = left_hand ? -1 : 1;
    var hand_x = _player.x + (left_hand ? -8 : 8) * abs(_player.image_xscale);
    var hand_y = _player.y + 9 * abs(_player.image_yscale);
    var is_shovel = _item.tool_kind == "shovel";
    var is_can = _item.tool_kind == "can";
    var handle_x = is_shovel ? 24 : (is_can ? 11 : 8);
    var handle_y = is_shovel ? 8 : (is_can ? 15 : 24);
    var swing = 0;
    if (_player.tool_use_timer > 0 && _player.tool_use_item_id == _item.id)
    {
        var progress = clamp(1 - _player.tool_use_timer / max(1, _player.tool_use_duration), 0, 1);
        if (is_can)
        {
            // Tilt the spout, hold briefly to pour, then lift it upright.
            var amount = progress < 0.25 ? progress / 0.25
                : (progress < 0.7 ? 1 : (1 - progress) / 0.3);
            amount = clamp(amount, 0, 1);
            swing = -45 * amount * amount * (3 - 2 * amount);
        }
        else
        {
            // Short wind-up, a decisive downstroke, and a slower recovery.
            var start_angle = 0;
            var end_angle = 12;
            var amount = progress / 0.18;
            if (progress >= 0.18 && progress < 0.48)
            {
                start_angle = 12; end_angle = -85;
                amount = (progress - 0.18) / 0.3;
            }
            else if (progress >= 0.48 && progress < 0.6)
            {
                start_angle = -85; end_angle = -85; amount = 1;
            }
            else if (progress >= 0.6)
            {
                start_angle = -85; end_angle = 0;
                amount = (progress - 0.6) / 0.4;
            }
            amount = clamp(amount, 0, 1);
            swing = lerp(start_angle, end_angle, amount * amount * (3 - 2 * amount));
        }
    }
    // The shovel source points opposite to the hoe. Mirror the swing with the hand.
    var tool_angle = (is_shovel ? 180 : 0) + swing * mirror;
    var grip_offset_x = (sprite_get_xoffset(_item.sprite) - handle_x) * tool_scale * mirror;
    var grip_offset_y = (sprite_get_yoffset(_item.sprite) - handle_y) * tool_scale;
    var cosine = dcos(tool_angle);
    var sine = dsin(tool_angle);
    return {
        x: hand_x + grip_offset_x * cosine + grip_offset_y * sine,
        y: hand_y - grip_offset_x * sine + grip_offset_y * cosine,
        xscale: tool_scale * mirror, yscale: tool_scale, angle: tool_angle,
        hand_x: hand_x, hand_y: hand_y, handle_x: handle_x, handle_y: handle_y
    };
}

function terrain_draw_held_tool(_player, _behind)
{
    if ((_player.facing == HeroFacing.Up) != _behind) return;
    var slot = global.inventory_slots[_player.inventory_selected_slot];
    if (!is_struct(slot)) return;
    var item = inventory_get_item(slot.id);
    if (is_undefined(item) || item.kind != "tool" || !sprite_exists(item.sprite)) return;
    var pose = terrain_held_tool_pose(_player, item);
    draw_sprite_ext(item.sprite, item.sprite_frame, pose.x, pose.y,
        pose.xscale, pose.yscale, pose.angle, c_white, _player.image_alpha);
}


// Match the IDE's 47-tile template: N, NE, E, SE, S, SW, W, NW.
function terrain_autotile_initialize()
{
    if (variable_global_exists("terrain_autotile_lookup")) return;
    var masks = [255, 127, 253, 125, 247, 119, 245, 117, 223, 95, 221, 93, 215, 87, 213, 85, 31, 29, 23, 21, 124, 116, 92, 84, 241, 209, 113, 81, 199, 71, 197, 69, 17, 68, 28, 20, 112, 80, 193, 65, 7, 5, 16, 4, 1, 64, 0];
    var families = [[6, 29, 24, 39, 23, 43, 26, 46, 28, 31, 42, 44, 38, 45, 47, 41, 2, 19, 18, 21, 5, 22, 27, 37, 10, 33, 34, 36, 7, 30, 25, 40, 14, 8, 1, 17, 9, 32, 11, 35, 3, 20, 13, 4, 15, 12, 16], [54, 77, 72, 87, 71, 91, 74, 94, 76, 79, 90, 92, 86, 93, 95, 89, 50, 67, 66, 69, 53, 70, 75, 85, 58, 81, 82, 84, 55, 78, 73, 88, 62, 56, 49, 65, 57, 80, 59, 83, 51, 68, 61, 52, 63, 60, 64], [102, 125, 120, 135, 119, 139, 122, 142, 124, 127, 138, 140, 134, 141, 143, 137, 98, 115, 114, 117, 101, 118, 123, 133, 106, 129, 130, 132, 103, 126, 121, 136, 110, 104, 97, 113, 105, 128, 107, 131, 99, 116, 109, 100, 111, 108, 112], [150, 173, 168, 183, 167, 187, 170, 190, 172, 175, 186, 188, 182, 189, 191, 185, 146, 163, 162, 165, 149, 166, 171, 181, 154, 177, 178, 180, 151, 174, 169, 184, 158, 152, 145, 161, 153, 176, 155, 179, 147, 164, 157, 148, 159, 156, 160], [198, 221, 216, 231, 215, 235, 218, 238, 220, 223, 234, 236, 230, 237, 239, 233, 194, 211, 210, 213, 197, 214, 219, 229, 202, 225, 226, 228, 199, 222, 217, 232, 206, 200, 193, 209, 201, 224, 203, 227, 195, 212, 205, 196, 207, 204, 208], [246, 269, 264, 279, 263, 283, 266, 286, 268, 271, 282, 284, 278, 285, 287, 281, 242, 259, 258, 261, 245, 262, 267, 277, 250, 273, 274, 276, 247, 270, 265, 280, 254, 248, 241, 257, 249, 272, 251, 275, 243, 260, 253, 244, 255, 252, 256]];
    global.terrain_autotile_lookup = array_create(256, 0);
    for (var i = 0; i < 47; i++) global.terrain_autotile_lookup[masks[i]] = i;
    global.terrain_autotile_families = families;
}

function terrain_family(_index)
{
    return _index > 0 && _index < 288 && _index mod 48 != 0 ? _index div 48 : -1;
}

function terrain_connects(_map, _col, _row, _family)
{
    if (_col < 0 || _row < 0 || _col >= tilemap_get_width(_map) || _row >= tilemap_get_height(_map)) return false;
    var neighbour_family = terrain_family(tile_get_index(tilemap_get(_map, _col, _row)));
    // Both sides of a material change need a border. Treating wet cells as dry
    // neighbours keeps the surrounding dry tiles on their old interior frames.
    return neighbour_family == _family;
}

function terrain_autotile_index(_map, _col, _row)
{
    var original = tile_get_index(tilemap_get(_map, _col, _row));
    var family = terrain_family(original);
    if (family == -1) return original;
    terrain_autotile_initialize();
    var north = terrain_connects(_map, _col, _row - 1, family);
    var east = terrain_connects(_map, _col + 1, _row, family);
    var south = terrain_connects(_map, _col, _row + 1, family);
    var west = terrain_connects(_map, _col - 1, _row, family);
    var mask = (north ? 1 : 0) | (east ? 4 : 0) | (south ? 16 : 0) | (west ? 64 : 0);
    if (north && east && terrain_connects(_map, _col + 1, _row - 1, family)) mask |= 2;
    if (east && south && terrain_connects(_map, _col + 1, _row + 1, family)) mask |= 8;
    if (south && west && terrain_connects(_map, _col - 1, _row + 1, family)) mask |= 32;
    if (west && north && terrain_connects(_map, _col - 1, _row - 1, family)) mask |= 128;
    return global.terrain_autotile_families[family][global.terrain_autotile_lookup[mask]];
}

function terrain_retile_area(_map, _col, _row)
{
    for (var row = max(0, _row - 1); row <= min(tilemap_get_height(_map) - 1, _row + 1); row++)
    {
        for (var col = max(0, _col - 1); col <= min(tilemap_get_width(_map) - 1, _col + 1); col++)
        {
            var index = terrain_autotile_index(_map, col, row);
            if (index != tilemap_get(_map, col, row)) terrain_write_cell(_map, col, row, index);
        }
    }
}

function terrain_change_cell(_map, _col, _row, _index)
{
    terrain_write_cell(_map, _col, _row, _index);
    terrain_retile_area(_map, _col, _row);
}

function terrain_crop_index(_col, _row)
{
    if (!variable_global_exists("planted_crops")) global.planted_crops = [];
    for (var i = 0; i < array_length(global.planted_crops); i++)
    {
        var crop = global.planted_crops[i];
        if (crop.column == _col && crop.row == _row) return i;
    }
    return -1;
}

function terrain_restore_crops(_saved)
{
    global.planted_crops = [];
    if (!is_array(_saved)) return;
    for (var i = 0; i < min(array_length(_saved), 160 * 90); i++)
    {
        var crop = _saved[i];
        if (!is_struct(crop)) continue;
        var col = variable_struct_get(crop, "column");
        var row = variable_struct_get(crop, "row");
        var seed = variable_struct_get(crop, "seed_id");
        if (!is_numeric(col) || !is_numeric(row) || !is_string(seed)) continue;
        if (col != floor(col) || row != floor(row) || col < 0 || row < 0 || col >= 160 || row >= 90) continue;
        var item = inventory_get_item(seed);
        if (is_undefined(item) || item.kind != "seed" || terrain_crop_index(col, row) != -1) continue;
        array_push(global.planted_crops, { column: col, row: row, seed_id: seed });
    }
}

function terrain_draw_crops()
{
    if (room != rm_main || !variable_global_exists("planted_crops")) return;
    var hero = instance_find(obj_main_chr_girl, 0);
    if (hero == noone || hero.terrain_tilemap == -1) return;
    var map = hero.terrain_tilemap;
    for (var i = 0; i < array_length(global.planted_crops); i++)
    {
        var crop = global.planted_crops[i];
        var item = inventory_get_item(crop.seed_id);
        var sprite = asset_get_index(string_replace(crop.seed_id, "spr_seed_", "spr_"));
        if (!sprite_exists(sprite)) sprite = item.sprite;
        if (!sprite_exists(sprite)) continue;
        var size = min(tilemap_get_tile_width(map), tilemap_get_tile_height(map)) * 0.75;
        var scale = size / max(sprite_get_width(sprite), sprite_get_height(sprite));
        var px = tilemap_get_x(map) + (crop.column + 0.5) * tilemap_get_tile_width(map);
        var py = tilemap_get_y(map) + (crop.row + 0.5) * tilemap_get_tile_height(map);
        draw_sprite_stretched(sprite, 0, px - sprite_get_width(sprite) * scale / 2,
            py - sprite_get_height(sprite) * scale / 2, sprite_get_width(sprite) * scale, sprite_get_height(sprite) * scale);
    }
}


// Shared by the cursor colour and click handling, including stale cursor targets.
function terrain_item_allows_tile(_item, _index)
{
    if (terrain_family(_index) != 3) return true;
    return _item.kind == "tool" && _item.tool_kind == "can";
}


// Footprint dimensions are independent of the player's unchanged interaction radius.
// The preview and action share these freshly measured targets; no tile can bypass reach.
function terrain_tool_targets(_player, _target, _refill)
{
    var cells = [];
    if (is_undefined(_target)) return cells;
    var selector = instance_find(obj_tile_select, 0);
    if (selector == noone) return cells;
    var anchor = selector.selection_target(_player, _target.x + _target.width * 0.5,
        _target.y + _target.height * 0.5);
    if (is_undefined(anchor)) return cells;
    var slot = global.inventory_slots[_player.inventory_selected_slot];
    var shape = _refill ? { width: 1, height: 1 } : inventory_tool_area_shape(slot);
    var feet_y = _player.y + (sprite_get_bbox_bottom(_player.sprite_index)
        - sprite_get_yoffset(_player.sprite_index)) * _player.image_yscale;
    var aim_x = anchor.x + anchor.width * 0.5 - _player.x;
    var aim_y = anchor.y + anchor.height * 0.5 - feet_y;
    var horizontal = abs(aim_x) > abs(aim_y);
    if (abs(aim_x) + abs(aim_y) < 0.001)
        horizontal = _player.facing == HeroFacing.Left || _player.facing == HeroFacing.Right;
    var columns = horizontal ? shape.height : shape.width;
    var rows = horizontal ? shape.width : shape.height;
    var first_col = anchor.column - floor((columns - 1) * 0.5);
    var first_row = anchor.row - floor((rows - 1) * 0.5);
    // An even-length brush extends back toward the player rather than past the aim.
    if (columns mod 2 == 0 && aim_x >= 0) first_col--;
    if (rows mod 2 == 0 && aim_y >= 0) first_row--;
    for (var row = first_row; row < first_row + rows; row++)
    {
        for (var col = first_col; col < first_col + columns; col++)
        {
            var cell = selector.selection_target(_player,
                anchor.x + (col - anchor.column + 0.5) * anchor.width,
                anchor.y + (row - anchor.row + 0.5) * anchor.height);
            if (is_undefined(cell)) continue;
            cell.can_interact = anchor.can_interact && cell.can_interact;
            cell.area_distance = sqr(col - anchor.column) + sqr(row - anchor.row);
            array_push(cells, cell);
        }
    }
    // Process the aimed tile first if inventory limits permit only part of a batch.
    array_sort(cells, function(_a, _b) { return sign(_a.area_distance - _b.area_distance); });
    return cells;
}

function terrain_use_tool(_player, _target, _refill)
{
    var cells = terrain_tool_targets(_player, _target, _refill);
    var changed = false;
    for (var i = 0; i < array_length(cells); i++)
    {
        var cell = cells[i];
        if (cell.can_interact && terrain_use_tool_cell(_player, cell, _refill)) changed = true;
    }
    return changed;
}
