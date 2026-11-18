enum TitleMenuPage { Title, Settings, Load, Playing, Pause, ExitConfirm, SaveName }
enum TitleMenuButton { New, Load, Settings, Exit, Count }
enum SettingsSlider { Effects, Music, InterfaceSize }

panel_surface = -1;
panel_font = -1;
if (instance_number(obj_title_menu) > 1)
{
    var controller = instance_find(obj_title_menu, 0);
    if (controller == id) controller = instance_find(obj_title_menu, 1);
    controller.x = x;
    controller.y = y;
    instance_destroy();
    exit;
}

persistent = true;
menu_page = room == rm_title ? TitleMenuPage.Title : TitleMenuPage.Playing;
gameplay_input_blocked = false;
play_time_ms = 0;
pending_load = undefined;
menu_error = "";
legacy_save_files = ["progress_a.json", "progress_b.json"];
named_save_prefix = "progress_named_";
save_name_limit = 24;
save_name = "";
overwrite_name = "";
load_entries = [];
load_page = 0;
load_page_size = 4;
if (!variable_global_exists("windmill_return")) global.windmill_return = undefined;
hovered_button = -1;
dragged_slider = -1;

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

    var scale = ui_percent / 100;
    with (obj_main_chr_girl) inventory_scale = scale;
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
drag_start_scale = 1;
panel_scale = function()
{
    // Keep the track under the pointer until the user releases it.
    if (menu_page == TitleMenuPage.Settings && dragged_slider == SettingsSlider.InterfaceSize) return drag_start_scale;
    var base = min(display_get_gui_width() / 768, display_get_gui_height() / 432);
    return base * ui_percent / 100;
};
slider_left = 192;
slider_right = 345;
slider_y = [67, 105, 183];
slider_labels = ["효과음 크기", "배경음 크기", "인터페이스 크기"];
windowed_bounds = [178, 130, 270, 156];
fullscreen_bounds = [278, 130, 386, 156];
back_bounds = [166, 216, 258, 242];
pause_continue_bounds = [109, 63, 315, 101];
pause_settings_bounds = [109, 111, 315, 149];
pause_exit_bounds = [109, 159, 315, 197];
exit_save_bounds = [96, 70, 328, 108];
exit_discard_bounds = [96, 122, 328, 160];
save_name_bounds = [33, 86, 391, 124];
save_submit_bounds = [111, 165, 313, 201];
load_previous_bounds = [33, 216, 129, 242];
load_next_bounds = [295, 216, 391, 242];

load_row_bounds = function(_row)
{
    var top = 52 + _row * 39;
    return [33, top, 391, top + 34];
};

load_last_page = function()
{
    return max(0, ceil(array_length(load_entries) / load_page_size) - 1);
};

panel_left = function()
{
    return round((display_get_gui_width() - panel_width * panel_scale()) * 0.5);
};
panel_top = function()
{
    return round((display_get_gui_height() - panel_height * panel_scale()) * 0.5);
};

panel_mouse_x = function()
{
    return (device_mouse_x_to_gui(0) - panel_left()) / panel_scale();
};
panel_mouse_y = function()
{
    return (device_mouse_y_to_gui(0) - panel_top()) / panel_scale();
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
read_progress_file = function(_filename)
{
    if (!file_exists(_filename)) return undefined;

    var handle = -1;
    try
    {
        handle = file_text_open_read(_filename);
        if (handle == -1) return undefined;
        var contents = file_text_read_string(handle);
        file_text_close(handle);
        handle = -1;
        var data = json_parse(contents, undefined, true);
        if (!is_struct(data) || (data.version != 1 && data.version != 2) || !is_numeric(data.revision)
            || data.revision < 1 || data.revision != floor(data.revision)
            || !is_string(data.room_name) || !is_numeric(data.x) || !is_numeric(data.y)
            || !is_numeric(data.facing) || !is_numeric(data.selected_slot))
        {
            return undefined;
        }

        if (data.version == 2 && (!is_string(data.name)
            || string_length(data.name) < 1 || string_length(data.name) > save_name_limit
            || !is_numeric(data.saved_at) || !(data.saved_at > 0 && data.saved_at < 3000000)))
        {
            return undefined;
        }

        var saved_room = asset_get_index(data.room_name);
        if (!room_exists(saved_room) || saved_room == rm_title
            || !(data.x >= 0 && data.x < 1000000 && data.y >= 0 && data.y < 1000000))
        {
            return undefined;
        }
        return data;
    }
    catch (_error)
    {
        if (handle != -1) file_text_close(handle);
        return undefined;
    }
};

save_name_key = function(_name)
{
    return md5_string_utf8(string_lower(_name));
};

named_save_files = function(_key)
{
    var base = named_save_prefix + _key;
    return [base + "_a.json", base + "_b.json"];
};

latest_progress = function(_files, _version)
{
    var latest = undefined;
    for (var i = 0; i < array_length(_files); i++)
    {
        var data = read_progress_file(_files[i]);
        if (is_struct(data) && data.version == _version
            && (is_undefined(latest) || data.revision > latest.data.revision))
        {
            latest = { slot: i, data: data };
        }
    }
    return latest;
};

refresh_load_entries = function()
{
    load_entries = [];
    load_page = 0;
    var keys = {};
    var saw_file = false;
    var filename = file_find_first(named_save_prefix + "*.json", fa_none);
    while (filename != "")
    {
        saw_file = true;
        var data = read_progress_file(filename);
        if (is_struct(data) && data.version == 2)
        {
            var key = save_name_key(data.name);
            var files = named_save_files(key);
            if (filename == files[0] || filename == files[1])
            {
                var index = variable_struct_get(keys, key);
                if (is_undefined(index))
                {
                    variable_struct_set(keys, key, array_length(load_entries));
                    array_push(load_entries, { name: data.name, saved_at: data.saved_at, data: data });
                }
                else if (data.revision > load_entries[index].data.revision)
                {
                    load_entries[index] = { name: data.name, saved_at: data.saved_at, data: data };
                }
            }
        }
        filename = file_find_next();
    }
    file_find_close();

    var legacy = latest_progress(legacy_save_files, 1);
    if (is_struct(legacy))
    {
        array_push(load_entries, { name: "이전 저장", saved_at: 0, data: legacy.data });
    }
    array_sort(load_entries, function(_a, _b) { return sign(_b.saved_at - _a.saved_at); });
    saw_file = saw_file || file_exists(legacy_save_files[0]) || file_exists(legacy_save_files[1]);
    menu_error = saw_file ? "저장 파일을 읽을 수 없습니다." : "저장된 게임이 없습니다.";
};

clean_save_input = function(_input)
{
    var clean = "";
    for (var i = 1; i <= string_length(_input) && string_length(clean) < save_name_limit; i++)
    {
        var codepoint = string_ord_at(_input, i);
        if (codepoint == 9 || codepoint == 10 || codepoint == 13) clean += " ";
        else if (codepoint >= 32 && codepoint != 127) clean += string_char_at(_input, i);
    }
    return clean;
};

write_progress = function(_name, _files, _previous)
{
    var player = instance_find(obj_main_chr_girl, 0);
    if (player == noone) return false;

    var previous = _previous;
    var slot = is_undefined(previous) ? 0 : 1 - previous.slot;
    var revision = is_undefined(previous) ? 1 : previous.data.revision + 1;
    var entrance = undefined;
    if (is_struct(global.windmill_return))
    {
        var point = global.windmill_return;
        entrance = { room_name: room_get_name(point.room_id), x: point.x, y: point.y };
    }
    var data = {
        version: 2, revision: revision, name: _name, saved_at: date_current_datetime(), room_name: room_get_name(room),
        x: player.x, y: player.y, facing: player.facing,
        selected_slot: player.inventory_selected_slot, entrance: entrance
    };

    // Write to the other slot so a failed write leaves the last valid save intact.
    var filename = _files[slot];
    var handle = -1;
    try
    {
        var contents = json_stringify(data);
        handle = file_text_open_write(filename);
        if (handle == -1) return false;
        file_text_write_string(handle, contents);
        file_text_close(handle);
        handle = -1;
    }
    catch (_error)
    {
        if (handle != -1) file_text_close(handle);
        return false;
    }

    var written = read_progress_file(filename);
    return is_struct(written) && written.revision == revision && written.name == _name;
};

return_to_title = function()
{
    global.windmill_return = undefined;
    room_goto(rm_title);
};
