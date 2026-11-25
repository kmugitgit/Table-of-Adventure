enum TitleMenuPage { Title, Settings, Load, Playing, Pause, ExitConfirm, SaveName, DeleteSave, Codex }
enum TitleMenuButton { New, Load, Settings, Exit, Count }
enum SettingsSlider { Effects, Music, InterfaceSize }

panel_surface = -1;
game_hud_surface = -1;
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
developer_initialize();
menu_page = room == rm_title ? TitleMenuPage.Title : TitleMenuPage.Playing;
gameplay_input_blocked = false;
item_book_open = false;
item_book_entries = scr_item_book_entries();
item_book_tags = ["plant", "condiment", "meat", "fish", "food"];
item_book_tag_index = 0;
item_book_found_only = false;
item_book_scroll_row = 0;
item_book_selected_index = 0;
item_book_dragging_scrollbar = false;
item_book_scroll_drag_offset = 0;
play_time_ms = 0;
game_minutes = 6 * 60;
game_minutes_per_second = 1;
pending_load = undefined;
menu_error = "";
legacy_save_files = ["progress_a.json", "progress_b.json"];
named_save_prefix = "progress_named_";
save_name_limit = 24;
restore_fullscreen_after_save_name = false;
save_name = "";
overwrite_name = "";
load_entries = [];
load_page = 0;
load_page_size = 4;
delete_entry = undefined;
inventory_initialize();
codex_catalog = scr_item_book_catalog();
codex_tabs = ["씨앗", "농기구"];
codex_tiers = ["나무", "구리", "철", "금", "티타늄"];
codex_tool_names = ["괭이", "물뿌리개", "삽"];
codex_category = 0;
codex_selected = 0;
codex_page = 0;
if (!variable_global_exists("codex_discovered")) global.codex_discovered = [];

codex_columns = function() { return codex_category == 0 ? 9 : 5; };
codex_page_size = function() { return codex_columns() * 3; };
codex_tab_bounds = function(_index)
{
    var left = 73 + _index * 146;
    return [left, 52, left + 132, 77];
};
codex_slot_bounds = function(_slot)
{
    var columns = codex_columns();
    var col = _slot mod columns;
    var row = _slot div columns;
    if (codex_category == 0)
    {
        var left = 34 + col * 40;
        var top = 86 + row * 40;
        return [left, top, left + 36, top + 36];
    }
    var left = 124 + col * 54;
    var top = 105 + row * 34;
    return [left, top, left + 32, top + 32];
};
codex_last_page = function()
{
    return max(0, ceil(array_length(codex_catalog[codex_category]) / codex_page_size()) - 1);
};
codex_select = function(_index)
{
    codex_selected = _index;
    codex_page = _index div codex_page_size();
};
codex_set_category = function(_category)
{
    codex_category = (_category + array_length(codex_tabs)) mod array_length(codex_tabs);
    codex_select(0);
};
codex_set_page = function(_page)
{
    codex_select(clamp(_page, 0, codex_last_page()) * codex_page_size());
};

if (!variable_global_exists("windmill_return")) global.windmill_return = undefined;
if (!variable_global_exists("player_gold")) global.player_gold = 100;
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
if (os_type == os_windows) window_enable_borderless_fullscreen(true);
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
delete_cancel_bounds = [67, 162, 197, 198];
delete_submit_bounds = [227, 162, 357, 198];

load_row_bounds = function(_row)
{
    var top = 52 + _row * 39;
    return [33, top, 313, top + 34];
};

load_delete_bounds = function(_row)
{
    var bounds = load_row_bounds(_row);
    return [bounds[2] + 9, bounds[1], 391, bounds[3]];
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

delete_progress = function(_entry)
{
    var version = _entry.data.version;
    var files = version == 1 ? legacy_save_files : named_save_files(save_name_key(_entry.name));
    var latest = latest_progress(files, version);
    // Remove the older copy first so it cannot reappear as the latest save.
    var first = is_undefined(latest) ? 0 : 1 - latest.slot;
    try
    {
        for (var i = 0; i < array_length(files); i++)
        {
            var filename = files[(first + i) mod array_length(files)];
            if (!file_exists(filename)) continue;
            file_delete(filename);
            if (file_exists(filename)) return false;
        }
    }
    catch (_error)
    {
        return false;
    }
    return true;
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

begin_save_name_input = function()
{
    // The Windows runtime leaves fullscreen when an IME starts composing.
    restore_fullscreen_after_save_name = os_type == os_windows && window_get_fullscreen()
        && !window_get_borderless_fullscreen();
    if (restore_fullscreen_after_save_name) window_set_fullscreen(false);
    keyboard_string = "";
};

end_save_name_input = function()
{
    keyboard_string = "";
    if (!restore_fullscreen_after_save_name) return;

    restore_fullscreen_after_save_name = false;
    window_set_fullscreen(true);
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
    if (!variable_global_exists("terrain_changes")) global.terrain_changes = [];
    if (!variable_global_exists("planted_crops")) global.planted_crops = [];
    var data = {
        version: 2, revision: revision, name: _name, saved_at: date_current_datetime(), room_name: room_get_name(room),
        x: player.x, y: player.y, facing: player.facing,
        game_minutes: game_minutes,
        selected_slot: player.inventory_selected_slot, gold: global.player_gold, entrance: entrance,
        codex_discovered: global.codex_discovered,
        inventory: inventory_snapshot(),
        terrain_changes: global.terrain_changes,
        planted_crops: global.planted_crops,
        cooking_state: cooking_snapshot()
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
    return is_struct(written) && written.revision == revision && written.name == _name
        && variable_struct_get(written, "gold") == data.gold;
};

return_to_title = function()
{
    global.windmill_return = undefined;
    room_goto(rm_title);
};


// One real second advances one game minute. Days roll over at midnight.
game_clock_advance = function(_seconds)
{
    if (room == rm_title || menu_page != TitleMenuPage.Playing || gameplay_input_blocked || item_book_open) return;
    _seconds *= global.developer.clock_rate;
    game_minutes += max(0, _seconds) * game_minutes_per_second;
    farming_advance(max(0, _seconds) * game_minutes_per_second);
    cooking_advance(max(0,_seconds));
};

game_clock_restore = function(_saved)
{
    game_minutes = is_numeric(_saved) && _saved >= 0 && _saved < 1440 * 999999 ? _saved : 6 * 60;
};

game_clock_read = function()
{
    var whole_minutes = floor(game_minutes);
    var minute_of_day = whole_minutes mod 1440;
    var hours = minute_of_day div 60;
    var minutes = minute_of_day mod 60;
    return {
        day: whole_minutes div 1440 + 1,
        hours: hours, minutes: minutes,
        time_text: (hours < 10 ? "0" : "") + string(hours) + ":"
            + (minutes < 10 ? "0" : "") + string(minutes)
    };
};

draw_game_hud = function()
{
    if (room != rm_main && room != rm_restaurant && room != rm_kitchen) return;
    if (!surface_exists(game_hud_surface)) game_hud_surface = surface_create(216, 84);
    if (!surface_exists(game_hud_surface)) return;
    var old_filter = gpu_get_texfilter();
    var old_colour = draw_get_color();
    var old_alpha = draw_get_alpha();
    var old_font = draw_get_font();
    var old_halign = draw_get_halign();
    var old_valign = draw_get_valign();
    gpu_set_texfilter(false);
    draw_set_alpha(1);
    if (surface_set_target(game_hud_surface))
    {
        var kitchen_hud = room == rm_kitchen;
        var hud_bottom = kitchen_hud ? 48 : 80;
        draw_clear_alpha(c_black, 0);
        draw_set_color(make_color_rgb(31, 22, 18));
        draw_rectangle(2, 3, 215, hud_bottom + 3, false);
        draw_set_color(make_color_rgb(163, 112, 61));
        draw_rectangle(0, 0, 212, hud_bottom, false);
        draw_set_color(make_color_rgb(76, 47, 29));
        draw_rectangle(2, 2, 210, hud_bottom - 2, false);
        draw_set_color(make_color_rgb(98, 65, 39));
        draw_rectangle(5, 5, 207, hud_bottom - 5, false);
        if (!kitchen_hud)
        {
            draw_set_color(make_color_rgb(119, 81, 46));
            draw_line(7, 49, 205, 49);
            draw_line(10, 72, 47, 72);
            draw_line(154, 72, 202, 72);
        }
        draw_set_color(make_color_rgb(42, 56, 34));
        draw_rectangle(7, 7, 205, 44, false);
        draw_set_font(panel_font);
        draw_set_valign(fa_middle);
        draw_set_halign(fa_left);
        draw_set_color(make_color_rgb(248, 224, 177));
        var clock = game_clock_read();
        draw_text(14, 26, string(clock.day) + "일차");
        draw_set_halign(fa_right);
        draw_text_transformed(199, 30, clock.time_text, 2, 2, 0);
        if (!kitchen_hud)
        {
            draw_set_color(make_color_rgb(236, 188, 103));
            draw_circle(17, 62, 5, false);
            draw_set_color(make_color_rgb(255, 221, 131));
            draw_line(16, 59, 16, 64);
            draw_set_halign(fa_left);
            draw_set_color(make_color_rgb(238, 214, 174));
            draw_text(28, 63, "보유 골드");
            draw_set_halign(fa_right);
            draw_set_color(make_color_rgb(255, 220, 133));
            var gold_label = string(global.player_gold) + " G";
            var gold_scale = min(1, 111 / max(1, string_width(gold_label)));
            draw_text_transformed(199, 63, gold_label, gold_scale, gold_scale, 0);
        }
        surface_reset_target();
        var gui_width = display_get_gui_width();
        var gui_height = display_get_gui_height();
        var scale = min(gui_width / 960, gui_height / 540) * ui_percent / 100;
        scale = min(scale, gui_width / 240, gui_height / 108);
        var margin = max(6, round(12 * scale));
        draw_surface_ext(game_hud_surface, round(gui_width - margin - 216 * scale), margin,
            scale, scale, 0, c_white, 1);
    }
    gpu_set_texfilter(old_filter);
    draw_set_color(old_colour);
    draw_set_alpha(old_alpha);
    draw_set_font(old_font);
    draw_set_halign(old_halign);
    draw_set_valign(old_valign);
};
