/// Fishing state machine. Editing catalog/probabilities belongs in scr_fishing_entries.
function fishing_initialize()
{
    if (variable_global_exists("fishing_entries")) return;
    global.fishing_entries = scr_fishing_entries();
    global.fishing_rods = scr_fishing_rod_profiles();
    global.fishing_time_limits = scr_fishing_time_limits();
    if (!variable_global_exists("fishing_randomized")) { randomize(); global.fishing_randomized = true; }
}

function fishing_migrate_item_id(_id)
{
    if (!is_string(_id)) return _id;
    var old_prefixes = ["fish_river_", "fish_lake_", "fish_sea_"];
    for (var i = 0; i < array_length(old_prefixes); i++)
    {
        var prefix = old_prefixes[i];
        if (string_copy(_id, 1, string_length(prefix)) == prefix)
            return "fish_" + string_delete(_id, 1, string_length(prefix));
    }
    return _id;
}

function fishing_habitat_name(_habitat)
{
    if (is_array(_habitat))
    {
        var label = "";
        for (var i = 0; i < array_length(_habitat); i++) label += (i > 0 ? ", " : "") + fishing_habitat_name(_habitat[i]);
        return label;
    }
    if (_habitat == "water") return "물";
    return string(_habitat);
}

function fishing_register_items()
{
    fishing_initialize();
    for (var i = 0; i < array_length(global.fishing_entries); i++)
    {
        var entry = global.fishing_entries[i];
        var item_id = "fish_" + entry.id;
        global.inventory_definitions[$ item_id] = {
            id: item_id, kind: "fish", tab: "item", name: entry.name,
            sprite: entry.sprite, sprite_frame: 0, colour: c_white, price: 0,
            habitat: entry.habitat, fish_tier: entry.tier,
            description: "서식지: " + fishing_habitat_name(entry.habitat) + " / " + string(entry.tier) + "티어"
        };
    }
}

function fishing_book_entries(_base)
{
    fishing_initialize();
    for (var i = 0; i < array_length(global.fishing_entries); i++)
    {
        var entry = global.fishing_entries[i];
        array_push(_base, { id: "fish_" + entry.id, name: entry.name, sprite: entry.sprite,
            tag: "fish", effects: [], cultivated_land: "water",
            description: "서식지: " + fishing_habitat_name(entry.habitat) + " / " + string(entry.tier) + "티어" });
    }
    return _base;
}

function fishing_habitat_at(_room, _col, _row)
{
    return "water";
}

function fishing_probability_pool(_habitat, _rod_tier)
{
    fishing_initialize();
    var eligible = [];
    var counts = [0, 0, 0, 0, 0];
    for (var i = 0; i < array_length(global.fishing_entries); i++)
    {
        var entry = global.fishing_entries[i];
        if (!is_numeric(entry.tier) || entry.tier != floor(entry.tier) || entry.tier < 1 || entry.tier > 5) continue;
        var matches = is_array(entry.habitat) ? array_contains(entry.habitat, _habitat) : entry.habitat == _habitat;
        if (!matches) continue;
        array_push(eligible, entry); counts[entry.tier - 1]++;
    }
    var profile = global.fishing_rods[clamp(floor(_rod_tier), 0, array_length(global.fishing_rods) - 1)];
    var total = 0;
    for (var tier = 0; tier < 5; tier++) if (counts[tier] > 0) total += max(0, profile.tier_weights[tier]);
    var pool = [];
    if (total <= 0) return pool;
    for (var i = 0; i < array_length(eligible); i++)
    {
        var entry = eligible[i];
        var probability = max(0, profile.tier_weights[entry.tier - 1]) / total / counts[entry.tier - 1];
        if (probability > 0) array_push(pool, { entry: entry, probability: probability });
    }
    return pool;
}

function fishing_choose_entry(_pool, _roll)
{
    if (array_length(_pool) == 0) return undefined;
    var point = clamp(_roll, 0, 0.999999999);
    var total = 0;
    for (var i = 0; i < array_length(_pool); i++) { total += _pool[i].probability; if (point < total) return _pool[i].entry; }
    return _pool[array_length(_pool) - 1].entry;
}

function fishing_new_state()
{
    return { state: "idle", elapsed: 0, bobber_x: 0, bobber_y: 0, target_x: 0, target_y: 0,
        from_x: 0, from_y: 0, rod_id: "", rod_tier: 0, entry: undefined,
        sequence: [], key_index: 0, time_limit: 0, remaining: 0,
        wait_remaining: 0, reward_granted: false, message: "", success: false,
        origin_x: 0, origin_y: 0, camera: -1, camera_width: 0, camera_height: 0, camera_zoom: 1, camera_zoom_target: 1 };
}

function fishing_busy(_player)
{
    if (!variable_instance_exists(_player, "fishing")) return false;
    var state = _player.fishing.state;
    return state == "casting" || state == "waiting" || state == "challenge" || state == "reeling";
}

function fishing_result(_player, _message, _success)
{
    var action = _player.fishing;
    action.state = "result"; action.elapsed = 0; action.message = _message; action.success = _success;
    action.camera_zoom_target = 1;
}

function fishing_update_camera(_action, _seconds)
{
    if (_action.camera == -1 || _action.camera_width <= 0 || _action.camera_height <= 0) return;
    _action.camera_zoom = lerp(_action.camera_zoom, _action.camera_zoom_target,
        clamp(_seconds * 7, 0, 1));
    if (abs(_action.camera_zoom - _action.camera_zoom_target) < 0.002)
        _action.camera_zoom = _action.camera_zoom_target;
    camera_set_view_size(_action.camera,
        _action.camera_width * _action.camera_zoom,
        _action.camera_height * _action.camera_zoom);
}

function fishing_object_particle(_name)
{
    var syllable = ord(string_char_at(_name, string_length(_name)));
    if (syllable >= 44032 && syllable <= 55203 && ((syllable - 44032) mod 28) != 0)
        return "을";
    return "를";
}

function fishing_rod_tip(_player)
{
    var action = _player.fishing;
    var item = inventory_get_item(action.rod_id);
    if (is_undefined(item)) return { x: _player.x, y: _player.y };
    var pose = terrain_held_tool_pose(_player, item);
    var dx = (27 - sprite_get_xoffset(item.sprite)) * pose.xscale;
    var dy = (2 - sprite_get_yoffset(item.sprite)) * pose.yscale;
    return { x: pose.x + dx * dcos(pose.angle) + dy * dsin(pose.angle),
        y: pose.y - dx * dsin(pose.angle) + dy * dcos(pose.angle) };
}

function fishing_cast(_player, _target)
{
    fishing_initialize();
    if (room != rm_main || _player.inventory_open || _player.fishing.state != "idle" || is_undefined(_target)) return false;
    if (instance_exists(obj_title_menu) && obj_title_menu.gameplay_input_blocked) return false;
    var slot = global.inventory_slots[_player.inventory_selected_slot];
    var item = is_struct(slot) ? inventory_get_item(slot.id) : undefined;
    if (is_undefined(item) || item.kind != "tool" || item.tool_kind != "rod") return false;
    var selector = instance_find(obj_tile_select, 0);
    if (selector == noone) return false;
    var target = selector.selection_target(_player, _target.x + _target.width / 2, _target.y + _target.height / 2);
    if (is_undefined(target) || !target.can_interact || terrain_family(tile_get_index(tilemap_get(
        _player.terrain_tilemap, target.column, target.row))) != 3) return false;
    if (inventory_empty_slot() == -1) return false;
    var habitat = fishing_habitat_at(room, target.column, target.row);
    var entry = fishing_choose_entry(fishing_probability_pool(habitat, item.tier), random(1));
    if (is_undefined(entry)) return false;
    var action = fishing_new_state();
    _player.fishing = action;
    action.origin_x = _player.x; action.origin_y = _player.y;
    action.state = "casting"; action.rod_id = slot.id; action.rod_tier = item.tier; action.entry = entry;
    action.target_x = target.x + target.width / 2; action.target_y = target.y + target.height / 2;
    var feet_y = _player.y + (sprite_get_bbox_bottom(_player.sprite_index) - sprite_get_yoffset(_player.sprite_index)) * _player.image_yscale;
    var dx = action.target_x - _player.x; var dy = action.target_y - feet_y;
    _player.facing = abs(dx) >= abs(dy) ? (dx >= 0 ? HeroFacing.Right : HeroFacing.Left)
        : (dy >= 0 ? HeroFacing.Down : HeroFacing.Up);
    _player.image_index = _player.idle_frames[_player.facing];
    var tip = fishing_rod_tip(_player);
    action.from_x = tip.x; action.from_y = tip.y; action.bobber_x = tip.x; action.bobber_y = tip.y;
    var profile = global.fishing_rods[item.tier];
    action.wait_remaining = random_range(profile.bite_min, max(profile.bite_min, profile.bite_max));
    if (view_camera[0] != -1)
    {
        action.camera = view_camera[0];
        action.camera_width = camera_get_view_width(action.camera);
        action.camera_height = camera_get_view_height(action.camera);
    }
    return true;
}

function fishing_start_challenge(_player)
{
    var action = _player.fishing;
    var entry = action.entry;
    action.sequence = [];
    var letters = ["W", "A", "S", "D"];
    for (var i = 0; i < 6 - entry.tier; i++) array_push(action.sequence, letters[irandom(3)]);
    var custom_time = variable_struct_get(entry, "time_limit");
    action.time_limit = is_numeric(custom_time) && custom_time > 0 ? custom_time : global.fishing_time_limits[entry.tier - 1];
    action.remaining = action.time_limit; action.key_index = 0; action.elapsed = 0; action.state = "challenge";
    action.camera_zoom_target = 0.86;
}

function fishing_complete(_player)
{
    var action = _player.fishing;
    if (action.state != "challenge" || action.reward_granted || action.key_index < array_length(action.sequence)) return false;
    var item_id = "fish_" + action.entry.id;
    if (inventory_stack_add(item_id, 1) != 0) { fishing_result(_player, "물고기를 놓쳤다!", false); return false; }
    action.reward_granted = true; codex_discover(item_id); inventory_notify_gain(item_id, 1);
    action.state = "reeling"; action.elapsed = 0;
    action.from_x = action.bobber_x; action.from_y = action.bobber_y;
    return true;
}

// Returns true while fishing owns movement and WASD input.
function fishing_step(_player, _seconds, _input)
{
    var action = _player.fishing;
    if (action.state == "idle") return false;
    if (instance_exists(obj_title_menu) && obj_title_menu.gameplay_input_blocked) return fishing_busy(_player);
    var seconds = clamp(_seconds, 0, 0.25);
    if (action.state != "result")
    {
        var selected_slot = global.inventory_slots[_player.inventory_selected_slot];
        if (!is_struct(selected_slot) || selected_slot.id != action.rod_id)
        {
            action.state = "result";
            action.elapsed = 2.5;
            action.message = "";
            action.camera_zoom_target = 1;
            fishing_update_camera(action, seconds);
            return false;
        }
    }
    if (action.state == "result")
    {
        fishing_update_camera(action, seconds);
        action.elapsed += seconds;
        if (action.elapsed >= 2.5) action.state = "idle";
        return false;
    }
    fishing_update_camera(action, seconds);
    // Cancel silently if the player walks more than three tiles from the casting point.
    if (point_distance(_player.x, _player.y, action.origin_x, action.origin_y) > 3 * 32)
    {
        action.state = "result";
        action.elapsed = 2.5;
        action.message = "";
        action.camera_zoom_target = 1;
        return false;
    }
    if (_input.tab || _input.cancel)
    {
        fishing_result(_player, "", false);
        return false;
    }
    action.elapsed += seconds;
    var profile = global.fishing_rods[action.rod_tier];
    switch (action.state)
    {
        case "casting":
            var progress = clamp(action.elapsed / max(0.1, profile.cast_seconds), 0, 1);
            var arc = max(6, point_distance(action.from_x, action.from_y, action.target_x, action.target_y) * 0.35);
            action.bobber_x = lerp(action.from_x, action.target_x, progress);
            action.bobber_y = lerp(action.from_y, action.target_y, progress) - sin(progress * pi) * arc;
            if (progress >= 1) { action.state = "waiting"; action.elapsed = 0; }
            break;
        case "waiting":
            action.bobber_x = action.target_x;
            action.bobber_y = action.target_y + sin(action.elapsed * 3) * 0.5;
            action.wait_remaining -= seconds;
            if (action.wait_remaining <= 0) fishing_start_challenge(_player);
            break;
        case "challenge":
            var dip = clamp(action.elapsed / 0.12, 0, 1);
            action.bobber_y = action.target_y + 3 * dip;
            action.remaining = max(0, action.remaining - seconds);
            if (action.remaining <= 0) { fishing_result(_player, "물고기를 놓쳤다!", false); break; }
            if (_input.count > 0)
            {
                if (_input.count != 1 || _input.key != action.sequence[action.key_index])
                    fishing_result(_player, "물고기를 놓쳤다!", false);
                else
                {
                    action.key_index++;
                    if (action.key_index >= array_length(action.sequence)) fishing_complete(_player);
                }
            }
            break;
        case "reeling":
            var progress = clamp(action.elapsed / max(0.1, profile.reel_seconds), 0, 1);
            var tip = fishing_rod_tip(_player);
            action.bobber_x = lerp(action.from_x, tip.x, progress);
            action.bobber_y = lerp(action.from_y, tip.y, progress) - sin(progress * pi) * 7;
            if (progress >= 1)
                fishing_result(_player, action.entry.name + fishing_object_particle(action.entry.name) + " 낚았다.", true);
            break;
    }
    return action.state == "challenge" || action.state == "reeling";
}

function fishing_handle_input(_player)
{
    if (_player.fishing.state == "idle") return false;
    var input = { tab: keyboard_check_pressed(vk_tab), cancel: mouse_check_button_pressed(mb_right) || keyboard_check_pressed(ord("F")), key: "", count: 0 };
    var letters = ["W", "A", "S", "D"];
    for (var i = 0; i < 4; i++) if (keyboard_check_pressed(ord(letters[i]))) { input.key = letters[i]; input.count++; }
    return fishing_step(_player, delta_time / 1000000, input);
}

function fishing_draw_world(_player)
{
    if (!fishing_busy(_player)) return;
    var old_colour = draw_get_color(); var old_alpha = draw_get_alpha();
    var action = _player.fishing; var tip = fishing_rod_tip(_player);
    draw_set_alpha(0.9); draw_set_color(make_color_rgb(230, 216, 179));
    var middle_x = (tip.x + action.bobber_x) / 2; var middle_y = (tip.y + action.bobber_y) / 2 + 1.5;
    draw_line(tip.x, tip.y, middle_x, middle_y); draw_line(middle_x, middle_y, action.bobber_x, action.bobber_y);
    draw_set_alpha(1);
    if (action.state == "reeling")
    {
        var sprite = action.entry.sprite; var size = 8;
        draw_sprite_stretched(sprite, 0, action.bobber_x - size / 2, action.bobber_y - size / 2, size, size);
    }
    else
    {
        if (action.state != "casting")
        {
            draw_set_alpha(0.55); draw_set_color(make_color_rgb(165, 220, 230));
            var radius = 2 + (action.elapsed * 2 mod 2);
            draw_ellipse(action.bobber_x - radius, action.target_y - 1, action.bobber_x + radius, action.target_y + 1, true);
            if (action.state == "challenge")
            {
                draw_set_alpha(0.9);
                draw_set_color(make_color_rgb(220, 248, 250));
                var bite_radius = 3 + 2 * abs(sin(current_time * 0.7));
                draw_ellipse(action.bobber_x - bite_radius, action.target_y,
                    action.bobber_x + bite_radius, action.target_y + 2, true);
            }
            draw_set_alpha(1);
        }
        draw_set_color(make_color_rgb(55, 37, 29)); draw_rectangle(action.bobber_x - 1.5, action.bobber_y - 3.5, action.bobber_x + 1.5, action.bobber_y + 2.5, false);
        draw_set_color(make_color_rgb(221, 91, 61)); draw_rectangle(action.bobber_x - 1, action.bobber_y - 3, action.bobber_x + 1, action.bobber_y - 0.5, false);
        draw_set_color(make_color_rgb(247, 227, 183)); draw_rectangle(action.bobber_x - 1, action.bobber_y, action.bobber_x + 1, action.bobber_y + 2, false);
    }
    draw_set_color(old_colour); draw_set_alpha(old_alpha);
}

function fishing_draw_gui(_player)
{
    if (room != rm_main || _player.inventory_open || _player.fishing.state == "idle" || view_camera[0] == -1) return;
    var action = _player.fishing;
    if (action.state == "casting" || action.state == "reeling") return;
    if (action.state == "result" && action.message == "") return;
    var old_colour = draw_get_color(); var old_alpha = draw_get_alpha(); var old_font = draw_get_font();
    var old_halign = draw_get_halign(); var old_valign = draw_get_valign(); var old_filter = gpu_get_texfilter();
    gpu_set_texfilter(false); draw_set_alpha(1); draw_set_font(_player.inventory_font);
    var gui_width = display_get_gui_width(); var gui_height = display_get_gui_height();
    var scale = max(1, floor(min(gui_width / 960, gui_height / 540)));
    var camera = view_camera[0];
    var centre_x = (_player.x - camera_get_view_x(camera)) * gui_width / camera_get_view_width(camera);
    var head_y = _player.y - sprite_get_yoffset(_player.sprite_index) * abs(_player.image_yscale);
    var top_y = (head_y - camera_get_view_y(camera)) * gui_height / camera_get_view_height(camera);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    if (action.state == "challenge")
    {
        var count = array_length(action.sequence);
        var panel_width = max(128, count * 24 + 16);
        var panel_height = 58;
        var left = round(clamp(centre_x - panel_width * scale / 2, 6, max(6, gui_width - panel_width * scale - 6)));
        var top = round(clamp(top_y - 68 * scale, 6, max(6, gui_height - panel_height * scale - 6)));
        draw_set_color(make_color_rgb(158, 107, 59));
        draw_rectangle(left, top, left + panel_width * scale, top + panel_height * scale, false);
        draw_set_color(make_color_rgb(54, 37, 26));
        draw_rectangle(left + 2 * scale, top + 2 * scale,
            left + (panel_width - 2) * scale, top + (panel_height - 2) * scale, false);
        var first = (panel_width - count * 24 + 4) / 2;
        for (var i = 0; i < count; i++)
        {
            var key_left = left + (first + i * 24) * scale;
            var key_centre_x = key_left + 10 * scale;
            var key_centre_y = top + 23 * scale;
            var active = i == action.key_index;
            var pulse = active ? 1 + 0.08 * sin(current_time * 0.5) : 1;
            var key_width = 20 * scale * pulse;
            var key_height = 22 * scale * pulse;
            if (active)
            {
                draw_set_alpha((current_time mod 500) < 250 ? 1 : 0.35);
                draw_set_color(c_white);
                draw_rectangle(key_centre_x - key_width * 0.5 - scale,
                    key_centre_y - key_height * 0.5 - scale,
                    key_centre_x + key_width * 0.5 + scale,
                    key_centre_y + key_height * 0.5 + scale, false);
                draw_set_alpha(1);
            }
            draw_set_color(active ? make_color_rgb(238, 188, 94) : make_color_rgb(133, 91, 51));
            draw_rectangle(key_centre_x - key_width * 0.5, key_centre_y - key_height * 0.5,
                key_centre_x + key_width * 0.5, key_centre_y + key_height * 0.5, false);
            draw_set_color(i < action.key_index ? make_color_rgb(53, 96, 60) : make_color_rgb(40, 31, 25));
            draw_rectangle(key_centre_x - key_width * 0.5 + scale,
                key_centre_y - key_height * 0.5 + scale,
                key_centre_x + key_width * 0.5 - scale,
                key_centre_y + key_height * 0.5 - scale, false);
            draw_set_color(i < action.key_index ? make_color_rgb(153, 186, 135) : make_color_rgb(255, 230, 181));
            draw_text_transformed(key_centre_x, key_centre_y + 2 * scale,
                action.sequence[i], scale, scale, 0);
        }
        draw_set_color(make_color_rgb(27, 24, 22));
        draw_rectangle(left + 8 * scale, top + 45 * scale,
            left + (panel_width - 8) * scale, top + 53 * scale, false);
        var fraction = clamp(action.remaining / action.time_limit, 0, 1);
        draw_set_color(fraction > 0.5 ? make_color_rgb(109, 165, 100) : (fraction > 0.25 ? make_color_rgb(224, 176, 73) : make_color_rgb(209, 85, 63)));
        if (fraction > 0) draw_rectangle(left + 9 * scale, top + 46 * scale,
            left + (9 + (panel_width - 18) * fraction) * scale, top + 52 * scale, false);
    }
    else if (action.state == "waiting" || action.state == "result")
    {
        var label = action.message;
        if (action.state == "waiting")
        {
            var dot_count = 1 + floor((current_time mod 900) / 300);
            var dots = dot_count == 1 ? "." : (dot_count == 2 ? ". ." : ". . .");
            label = "입질 대기 " + dots;
        }
        var text_width = string_width(label);
        var text_x = clamp(centre_x, text_width * scale / 2 + 4,
            max(text_width * scale / 2 + 4, gui_width - text_width * scale / 2 - 4));
        var text_y = max(14 * scale, top_y - 17 * scale);
        draw_set_color(action.state == "result" && !action.success ? make_color_rgb(235, 164, 132) : make_color_rgb(248, 223, 170));
        draw_text_transformed(round(text_x), round(text_y + 3 * scale), label, scale, scale, 0);
    }
    draw_set_color(old_colour); draw_set_alpha(old_alpha); draw_set_font(old_font);
    draw_set_halign(old_halign); draw_set_valign(old_valign); gpu_set_texfilter(old_filter);
}
