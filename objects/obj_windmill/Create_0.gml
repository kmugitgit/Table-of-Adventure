depth = -round(y);

player_at_door = function(_player_x, _player_y)
{
    var offset_x = _player_x - x;
    var offset_y = _player_y - y;
    var front = image_angle - 90;
    var forward = offset_x * dcos(front) - offset_y * dsin(front);
    var sideways = offset_x * dcos(image_angle) - offset_y * dsin(image_angle);
    return abs(sideways) <= 17 * abs(image_xscale)
        && forward >= 0 && forward <= 34 * abs(image_yscale);
};
