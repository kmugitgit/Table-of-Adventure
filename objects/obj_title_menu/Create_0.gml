enum TitleMenuPage { Title, Settings, Load }
enum TitleMenuButton { New, Load, Settings, Exit, Count }
enum SettingsSlider { Effects, Music, InterfaceSize }

menu_page = TitleMenuPage.Title;
hovered_button = -1;
dragged_slider = -1;
panel_surface = -1;

volume_groups = [audiogroup_sfx, audiogroup_music];
ui_scale_min = 80;
ui_scale_max = 120;
settings_file = "settings.ini";

ini_open(settings_file);
volumes = [
    clamp(ini_read_real("audio", "sfx", 1), 0, 1),
    clamp(ini_read_real("audio", "music", 1), 0, 1)
];
// Older settings stored the index of the 80%, 100%, and 120% presets.
var old_size = clamp(round(ini_read_real("display", "ui_size", 1)), 0, 2);
ui_percent = clamp(round(ini_read_real("display", "ui_scale_percent", 80 + old_size * 20)),
    ui_scale_min, ui_scale_max);
var start_fullscreen = ini_read_real("display", "fullscreen", 0) != 0;
ini_close();

for (var i = 0; i < array_length(volume_groups); i++)
{
    audio_group_set_gain(volume_groups[i], volumes[i], 0);
}
if (window_get_fullscreen() != start_fullscreen)
{
    window_set_fullscreen(start_fullscreen);
}

save_settings = function()
{
    ini_open(settings_file);
    ini_write_real("audio", "sfx", volumes[0]);
    ini_write_real("audio", "music", volumes[1]);
    ini_write_real("display", "ui_scale_percent", ui_percent);
    ini_write_real("display", "fullscreen", window_get_fullscreen());
    ini_close();
};

button_sprite = spr_title_menu_buttons;
button_scale = 0.375;
button_spacing = 96;
button_y = function(_index)
{
    return y + _index * button_spacing;
};

var previous_font_aa = font_add_get_enable_aa();
font_add_enable_aa(false);
panel_font = font_add("Galmuri14.ttf", 11, false, false, 32, 126);
font_add_enable_aa(previous_font_aa);

// Panel controls are drawn and hit-tested in the same low-resolution coordinates.
panel_width = 424;
panel_height = 260;
panel_text_offset_y = 3;
panel_base_scale = 2.5;
drag_start_scale = panel_base_scale;
panel_scale = function()
{
    if (menu_page != TitleMenuPage.Settings) return panel_base_scale;
    // Keep the track under the pointer until the user releases it.
    if (dragged_slider == SettingsSlider.InterfaceSize) return drag_start_scale;
    return panel_base_scale * ui_percent / 100;
};
slider_left = 192;
slider_right = 345;
slider_y = [67, 105, 183];
slider_labels = ["효과음 크기", "배경음 크기", "인터페이스 크기"];
windowed_bounds = [178, 130, 270, 156];
fullscreen_bounds = [278, 130, 386, 156];
back_bounds = [166, 216, 258, 242];

panel_mouse_x = function()
{
    return (mouse_x - room_width * 0.5) / panel_scale() + panel_width * 0.5;
};
panel_mouse_y = function()
{
    return (mouse_y - room_height * 0.5) / panel_scale() + panel_height * 0.5;
};
over_control = function(_bounds)
{
    return point_in_rectangle(panel_mouse_x(), panel_mouse_y(),
        _bounds[0], _bounds[1], _bounds[2], _bounds[3]);
};
over_slider = function(_index)
{
    var row_y = slider_y[_index];
    return point_in_rectangle(panel_mouse_x(), panel_mouse_y(),
        slider_left - 7, row_y - 12, slider_right + 7, row_y + 12);
};

wood = make_color_rgb(47, 34, 26);
shadow = make_color_rgb(28, 21, 18);
bronze = make_color_rgb(159, 106, 57);
gold = make_color_rgb(231, 185, 111);
parchment = make_color_rgb(249, 222, 168);
moss = make_color_rgb(94, 109, 52);

// Stepped corners match the edges of the title button sprites.
draw_bevel = function(_left, _top, _right, _bottom, _step, _colour)
{
    draw_set_color(_colour);
    draw_rectangle(_left + _step, _top, _right - _step, _bottom, false);
    draw_rectangle(_left, _top + _step, _right, _bottom - _step, false);
};

draw_control = function(_bounds, _label, _selected)
{
    var left = _bounds[0];
    var top = _bounds[1];
    var right = _bounds[2];
    var bottom = _bounds[3];
    var hover = over_control(_bounds);

    draw_bevel(left, top + 2, right, bottom + 2, 3, shadow);
    draw_bevel(left, top, right, bottom, 3, hover || _selected ? gold : bronze);
    var fill = make_color_rgb(66, 46, 32);
    if (_selected) fill = moss;
    else if (hover) fill = make_color_rgb(99, 65, 39);
    draw_bevel(left + 2, top + 2, right - 2, bottom - 2, 2, fill);
    draw_set_color(parchment);
    draw_set_halign(fa_center);
    draw_text((left + right) * 0.5, (top + bottom) * 0.5 + panel_text_offset_y, _label);
};
