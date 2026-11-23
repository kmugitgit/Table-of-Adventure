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
