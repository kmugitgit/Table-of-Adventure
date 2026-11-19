// Measure landmarks from the sprite's bottom centre, independently of its origin.
windmill_point = function(_height_above_base, _sideways = 0)
{
    var local_x = ((sprite_get_width(sprite_index) - 1) * 0.5
        + _sideways - sprite_get_xoffset(sprite_index)) * image_xscale;
    var local_y = (sprite_get_height(sprite_index) - 1 - _height_above_base
        - sprite_get_yoffset(sprite_index)) * image_yscale;
    return {
        x: x + local_x * dcos(image_angle) + local_y * dsin(image_angle),
        y: y - local_x * dsin(image_angle) + local_y * dcos(image_angle)
    };
};

depth = -round(windmill_point(0).y);

player_at_door = function(_player_x, _player_y)
{
    var entrance = windmill_point(0);
    var offset_x = _player_x - entrance.x;
    var offset_y = _player_y - entrance.y;
    var front = image_angle - 90;
    var forward = offset_x * dcos(front) - offset_y * dsin(front);
    var sideways = offset_x * dcos(image_angle) - offset_y * dsin(image_angle);
    return abs(sideways) <= 17 * abs(image_xscale)
        && forward >= 0 && forward <= 34 * abs(image_yscale);
};
