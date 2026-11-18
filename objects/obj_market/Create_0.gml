market_category = 0;
market_page = 0;
market_selected = 0;
market_desc_scroll = 0;
market_desc_scroll_max = 0;
market_desc_text_bounds = [425, 217, 591, 270];
market_desc_line_spacing = 16;
market_rows_per_page = 5;
market_width = 640;
market_height = 360;
market_surface = -1;

var previous_aa = font_add_get_enable_aa();
font_add_enable_aa(false);
market_font = font_add("Galmuri14.ttf", 11, false, false, 32, 126);
font_add_enable_aa(previous_aa);

market_background = make_color_rgb(38, 25, 20);
market_shade = make_color_rgb(38, 26, 20);
market_wood = make_color_rgb(83, 53, 37);
market_wood_dark = make_color_rgb(62, 40, 30);
market_grain = make_color_rgb(104, 65, 43);
market_row_fill = make_color_rgb(91, 59, 39);
market_bronze = make_color_rgb(164, 112, 61);
market_gold = make_color_rgb(231, 182, 103);
market_text = make_color_rgb(249, 222, 163);
market_muted = make_color_rgb(186, 156, 117);
market_green = make_color_rgb(77, 84, 49);
market_green_dark = make_color_rgb(55, 61, 37);
market_green_light = make_color_rgb(111, 114, 66);

market_tabs = ["씨앗", "농기구", "업그레이드"];
market_tab_bounds = [[30, 14, 130, 46], [138, 14, 238, 46], [246, 14, 366, 46]];
market_wallet_bounds = [380, 14, 516, 40];
market_leave_bounds = [526, 14, 611, 40];
market_preview_bounds = [414, 71, 604, 203];
market_desc_bounds = [414, 213, 604, 273];
market_price_bounds = [414, 286, 503, 325];
market_buy_bounds = [515, 286, 604, 325];

market_catalog = scr_market_catalog();

market_icons = {
    seed: [
        "..kkkkkk..", ".kllllllk.", ".kbddddbk.", ".kbdadabk.", ".kbaaaabk.",
        ".kbdadabk.", ".kbddddbk.", ".kbbbbbsk.", ".ksbssssk.", "..kkkkkk.."
    ],
    hoe: [
        "......kkk.", ".....kllak", "....kbbakk", "...kbbkaak",
        "..kbbk.kk.", ".kbbk.....", "kbbk......", "kbk.......", ".k........"
    ],
    can: [
        "....kkk...", "...k...k.k", ".kkkaak.kk", "klkaaalka.",
        "k.kaaakak.", "klkaaaakk.", ".kkaaalak.", "..ksaaaak.", "...kkkkk.."
    ],
    trowel: [
        ".......kk.", "......klak", ".....klaak", "....klakak",
        "...kkakkk.", "..kbbk....", ".kbsk.....", "kbsk......", ".kk......."
    ],
    bag: [
        "....kk....", "...k..k...", "..kkkkkk..", ".klalaaak.", "klalalaask",
        "kssbbssssk", "kaabbaaask", "kalallaask", "ksssssbbsk", ".kkkkkkkk."
    ]
};
market_icon_colors = {
    k: make_color_rgb(36, 27, 23),
    l: make_color_rgb(249, 224, 170),
    b: make_color_rgb(180, 125, 73),
    d: make_color_rgb(226, 178, 111),
    s: make_color_rgb(103, 66, 46)
};

market_scale = function()
{
    return min(display_get_gui_width() / market_width, display_get_gui_height() / market_height);
};

market_left = function()
{
    return (display_get_gui_width() - market_width * market_scale()) * 0.5;
};
market_top = function()
{
    return (display_get_gui_height() - market_height * market_scale()) * 0.5;
};
market_input_blocked = function()
{
    return instance_exists(obj_title_menu) && obj_title_menu.gameplay_input_blocked;
};

market_hit = function(_bounds)
{
    if (market_input_blocked()) return false;
    var scale = market_scale();
    var pointer_x = (device_mouse_x_to_gui(0) - market_left()) / scale;
    var pointer_y = (device_mouse_y_to_gui(0) - market_top()) / scale;
    return point_in_rectangle(pointer_x, pointer_y, _bounds[0], _bounds[1], _bounds[2], _bounds[3]);
};

market_row = function(_index)
{
    var top = 71 + _index * 43;
    return [35, top, 383, top + 35];
};
market_last_page = function()
{
    return max(0, ceil(array_length(market_catalog[market_category]) / market_rows_per_page) - 1);
};

market_visible_page_count = function()
{
    return min(5, market_last_page() + 1);
};
market_first_visible_page = function()
{
    return clamp(market_page - 2, 0, max(0, market_last_page() - 4));
};
market_page_button = function(_offset)
{
    var left = 209 - (market_visible_page_count() * 37 - 5) * 0.5 + _offset * 37;
    return [round(left), 304, round(left) + 32, 331];
};
market_set_page = function(_page)
{
    var next = clamp(_page, 0, market_last_page());
    if (next == market_page) return;
    market_select(next * market_rows_per_page);
};

market_select = function(_index)
{
    market_selected = _index;
    market_page = floor(_index / market_rows_per_page);
    market_desc_scroll = 0;
    market_desc_scroll_max = 0;
};

market_panel = function(_bounds, _fill, _edge)
{
    var left = _bounds[0];
    var top = _bounds[1];
    var right = _bounds[2];
    var bottom = _bounds[3];
    draw_set_color(market_shade);
    draw_rectangle(left + 2, top + 3, right + 1, bottom + 3, false);
    draw_set_color(_edge);
    draw_rectangle(left + 3, top, right - 3, bottom, false);
    draw_rectangle(left, top + 3, right, bottom - 3, false);
    draw_set_color(_fill);
    draw_rectangle(left + 3, top + 2, right - 3, bottom - 2, false);
};

market_button = function(_bounds, _label, _selected, _enabled)
{
    var hover = _enabled && market_hit(_bounds);
    var fill = _selected ? market_green : (hover ? market_row_fill : market_wood_dark);
    market_panel(_bounds, fill, _selected || hover ? market_gold : market_bronze);
    draw_set_color(_enabled ? market_text : market_muted);
    draw_set_halign(fa_center);
    draw_text((_bounds[0] + _bounds[2]) * 0.5, (_bounds[1] + _bounds[3]) * 0.5 + 2, _label);
};

market_draw_icon = function(_item, _x, _y, _scale)
{
    var item_sprite = _item.sprite;
    if (item_sprite != noone && sprite_exists(item_sprite))
    {
        var source_width = sprite_get_width(item_sprite);
        var source_height = sprite_get_height(item_sprite);
        var scale = 10 * _scale / max(source_width, source_height);
        if (scale >= 1) scale = floor(scale);
        var icon_width = max(1, floor(source_width * scale));
        var icon_height = max(1, floor(source_height * scale));
        draw_sprite_stretched(item_sprite, 0, round(_x - icon_width * 0.5),
            round(_y - icon_height * 0.5), icon_width, icon_height);
        return;
    }

    var pattern = variable_struct_get(market_icons, _item.icon);
    var left = round(_x) - 5 * _scale;
    var top = round(_y) - floor(array_length(pattern) * _scale / 2);
    for (var row = 0; row < array_length(pattern); row++)
    {
        for (var col = 0; col < string_length(pattern[row]); col++)
        {
            var pixel = string_char_at(pattern[row], col + 1);
            if (pixel == ".") continue;
            var colour = pixel == "a" ? _item.accent : variable_struct_get(market_icon_colors, pixel);
            draw_set_color(colour);
            draw_rectangle(left + col * _scale, top + row * _scale,
                left + (col + 1) * _scale, top + (row + 1) * _scale, false);
        }
    }
};

market_fit_text = function(_text, _width)
{
    if (string_width(_text) <= _width) return _text;

    var length = string_length(_text);
    while (length > 0)
    {
        var shortened = string_copy(_text, 1, length) + "...";
        if (string_width(shortened) <= _width) return shortened;
        length--;
    }
    return "...";
};
