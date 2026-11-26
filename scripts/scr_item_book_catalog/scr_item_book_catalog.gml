/// 도감 항목과 획득 이력
// 해금 ID는 오브젝트 리소스 ID로 저장합니다. 인벤토리 지급 함수가 획득 시 자동으로 처리합니다.

/// @func scr_item_book_entries()
/// @desc 구버전 저장 데이터를 새 오브젝트 ID로 변환하고, 오브젝트 획득을 도감에 기록합니다.
// tag는 plant/condiment/meat/fish/food 중 하나이며 effects는 아이콘 데이터 최대 3개입니다.
function codex_discover(_object_id, _quality_id = "normal")
{
    var resolved_object = _object_id;
    if (is_string(_object_id)) resolved_object = asset_get_index(codex_object_key(_object_id));
    var key = object_exists(resolved_object) ? object_get_name(resolved_object) : "";
    if (key == "") return;
    if (!variable_global_exists("codex_discovered")) global.codex_discovered = [];
    if (!array_contains(global.codex_discovered, key)) array_push(global.codex_discovered, key);
    if (_quality_id == "high")
    {
        var high_key = key + "_quality_high";
        if (!array_contains(global.codex_discovered, high_key)) array_push(global.codex_discovered, high_key);
    }
}

function codex_was_found(_id)
{
    return variable_global_exists("codex_discovered") && array_contains(global.codex_discovered, codex_object_key(_id));
}

function codex_object_key(_value)
{
    if (is_numeric(_value) && object_exists(_value)) return object_get_name(_value);
    if (is_string(_value))
    {
        var item_id = fishing_migrate_item_id(_value);
        if (string_copy(item_id, 1, 4) == "hoe_") item_id = "obj_hoe";
        else if (string_copy(item_id, 1, 4) == "can_") item_id = "obj_watering_can";
        else if (string_copy(item_id, 1, 7) == "shovel_") item_id = "obj_shovel";
        else if (string_copy(item_id, 1, 7) == "sickle_") item_id = "obj_sickle";
        else if (string_copy(item_id, 1, 4) == "rod_") item_id = "obj_fishing_rod";
        else if (string_copy(item_id, 1, 9) == "obj_seed_") item_id = "obj_" + string_delete(item_id, 1, 9) + "_seed";
        else if (string_copy(item_id, 1, 5) == "spr_" && string_copy(item_id, string_length(item_id) - 4, 5) == "_seed")
            item_id = "obj_" + string_delete(item_id, 1, 4);
        else if (string_copy(item_id, 1, 9) == "obj_fish_") item_id = "obj_" + string_delete(item_id, 1, 9);
        else if (string_copy(item_id, 1, 9) == "obj_food_") item_id = "obj_" + string_delete(item_id, 1, 9);
        else if (string_copy(item_id, 1, 13) == "obj_prepared_") item_id = "obj_" + string_delete(item_id, 1, 13);
        if (string_copy(item_id, 1, 9) == "obj_crop_")
        {
            var crop_name = "";
            if (string_copy(item_id, string_length(item_id) - 6, 7) == "_normal")
                crop_name = string_copy(item_id, 10, string_length(item_id) - 16);
            else if (string_copy(item_id, string_length(item_id) - 4, 5) == "_high")
                crop_name = string_copy(item_id, 10, string_length(item_id) - 14);
            if (crop_name != "") item_id = "obj_" + crop_name;
        }
        if (string_copy(item_id, 1, 5) == "crop_")
        {
            var crop_end = string_pos("_", string_delete(item_id, 1, 5));
            var crop_name = string_copy(item_id, 6, crop_end - 1);
            item_id = "obj_" + crop_name;
        }
        else if (string_copy(item_id, 1, 5) == "fish_") item_id = "obj_" + string_delete(item_id, 1, 5);
        else if (string_copy(item_id, 1, 5) == "food_") item_id = "obj_" + string_delete(item_id, 1, 5);
        else if (string_copy(item_id, 1, 9) == "prepared_") item_id = "obj_" + string_delete(item_id, 1, 9);
        else if (string_copy(item_id, 1, 9) == "spr_seed_") item_id = "obj_" + string_delete(item_id, 1, 9) + "_seed";
        else if (item_id == "hoe_wood") item_id = "obj_hoe";
        else if (item_id == "can_wood") item_id = "obj_watering_can";
        else if (item_id == "shovel_wood") item_id = "obj_shovel";
        else if (item_id == "sickle_wood") item_id = "obj_sickle";
        else if (item_id == "rod_wood") item_id = "obj_fishing_rod";
        var object_name = item_id;
        var object_asset = asset_get_index(object_name);
        if (object_asset != -1 && object_exists(object_asset)) return object_get_name(object_asset);
        return item_id;
    }
    return "";
}

function codex_effect_sprite(_effect)
{
    if (is_struct(_effect) && variable_struct_exists(_effect, "sprite")) return _effect.sprite;
    if (!is_string(_effect)) return noone;
    switch (_effect)
    {
        case "heal": return spr_heal;
        case "heal_speed": return spr_heal_speed;
        case "health_boost": return spr_health_boost;
        case "fire_resistance": return spr_fire_resistance;
    }
    return noone;
}

function codex_restore_history(_saved)
{
    global.codex_discovered = [];
    if (!is_array(_saved)) return;
    for (var i = 0; i < min(array_length(_saved), 4096); i++)
    {
        var key = _saved[i];
        if (!is_string(key) || string_length(key) == 0 || string_length(key) > 128) continue;
        if (string_copy(key, 1, 7) == "trowel_") key = "shovel_" + string_delete(key, 1, 7);
        if ((string_copy(key, 1, 9) == "obj_crop_" && string_copy(key, string_length(key) - 4, 5) == "_high")
            || (string_copy(key, 1, 5) == "crop_" && string_copy(key, string_length(key) - 4, 5) == "_high"))
        {
            var old_crop_object = asset_get_index(codex_object_key(key));
            if (old_crop_object != -1) codex_discover(old_crop_object, "high");
            continue;
        }
        if (string_copy(key, 1, 9) == "spr_seed_" || string_copy(key, 1, 9) == "obj_seed_")
        {
            var seed_object = asset_get_index(codex_object_key(key));
            if (seed_object != -1) codex_discover(seed_object);
            continue;
        }
        if (string_copy(key, 1, 4) == "obj_" && string_copy(key, string_length(key) - 12, 13) == "_quality_high")
        {
            var quality_name = string_delete(key, string_length(key) - 12, 13);
            var quality_object = asset_get_index(quality_name);
            if (quality_object != -1) codex_discover(quality_object, "high");
            continue;
        }
        var resolved_key = codex_object_key(key);
        var resolved_object = asset_get_index(resolved_key);
        if (resolved_object != -1) codex_discover(resolved_object);
    }
}

function scr_item_book_catalog()
{
    var market_entries = scr_market_entries();
    var seeds = [];
    for (var i = 0; i < array_length(market_entries); i++)
    {
        var seed = market_entries[i];
        if (seed.tab != "seed") continue;
        seed.object_id = seed.id;
        seed.id = inventory_seed_id(seed);
        seed.colour = c_white;
        array_push(seeds, seed);
    }

    var tier_names = ["나무", "구리", "철", "금", "티타늄"];
    var tier_ids = ["wood", "copper", "iron", "gold", "titanium"];
    var tool_names = ["괭이", "물뿌리개", "삽", "낫", "낚싯대"];
    // Keep IDs aligned with inventory and shop records (including existing saves).
    var tool_ids = ["hoe", "can", "shovel", "sickle", "rod"];
    var tool_objects = [obj_hoe, obj_watering_can, obj_shovel, obj_sickle, obj_fishing_rod];
    var tool_descriptions = [
        "땅을 갈아 경작지로 만듭니다.",
        "땅에 물을 뿌려 젖게 만듭니다.",
        "경작지를 땅으로 되돌리거나 작물을 씨앗으로 반환합니다.",
        "다 자란 작물을 수확하는 농기구입니다.",
        "물에 찌를 던져 물고기를 잡는 도구입니다."
    ];
    var tools = [];
    for (var tool = 0; tool < array_length(tool_names); tool++)
    {
        for (var tier = 0; tier < array_length(tier_names); tier++)
        {
            array_push(tools, {
                id: tool_objects[tool],
                inventory_id: tool_ids[tool] + "_" + tier_ids[tier],
                name: tier_names[tier] + " " + tool_names[tool],
                sprite_frame: tool_ids[tool] == "rod" ? tier * 2 : tier,
                description: tool_descriptions[tool],
                colour: c_white
            });
        }
    }
    return [seeds, tools];
}

function codex_draw_item(_item, _bounds, _found, _fit_slot = false)
{
    var item_sprite = _item.sprite;
    var centre_x = (_bounds[0] + _bounds[2]) * 0.5;
    var centre_y = (_bounds[1] + _bounds[3]) * 0.5;
    var available_size = _bounds[2] - _bounds[0] - (_fit_slot ? 2 : 8);
    if (item_sprite != noone && sprite_exists(item_sprite))
    {
        var source_width = sprite_get_width(item_sprite);
        var source_height = sprite_get_height(item_sprite);
        var scale = available_size / max(source_width, source_height);
        // Pixel art stays crisp when enlarged by whole source-pixel multiples.
        if (scale >= 1) scale = floor(scale);
        var icon_width = max(1, floor(source_width * scale));
        var icon_height = max(1, floor(source_height * scale));
        var previous_shader = shader_current();
        shader_set(sh_codex_grayscale);
        shader_set_uniform_f(shader_get_uniform(sh_codex_grayscale, "u_collected"), _found ? 1 : 0);
        var sprite_frame = 0;
        if (!_found) sprite_frame = 2;
        else if (variable_struct_exists(_item, "quality_id"))
            sprite_frame = _item.quality_id == "high" ? 1 : 0;
        else if (variable_struct_exists(_item, "sprite_frame"))
            sprite_frame = _item.sprite_frame;
        else if (is_numeric(_item.id))
            sprite_frame = codex_was_high_quality(_item.id) ? 1 : 0;
        sprite_frame = clamp(sprite_frame, 0, sprite_get_number(item_sprite) - 1);
        draw_sprite_stretched_ext(item_sprite, sprite_frame, round(centre_x - icon_width * 0.5),
            round(centre_y - icon_height * 0.5), icon_width, icon_height, _item.colour, 1);
        if (previous_shader == -1) shader_reset();
        else shader_set(previous_shader);
    }
    else
    {
        // Seed packets without an assigned asset use a neutral packet placeholder.
        draw_set_color(_found ? make_color_rgb(186, 143, 85) : make_color_rgb(133, 133, 133));
        draw_rectangle(centre_x - 8, centre_y - 11, centre_x + 8, centre_y + 11, false);
        draw_set_color(_found ? make_color_rgb(233, 204, 151) : make_color_rgb(190, 190, 190));
        draw_rectangle(centre_x - 6, centre_y - 9, centre_x + 6, centre_y + 9, false);
        draw_set_color(_found ? _item.accent : make_color_rgb(105, 105, 105));
        draw_ellipse(centre_x - 3, centre_y - 3, centre_x + 3, centre_y + 3, false);
    }
}

function codex_was_high_quality(_object_id)
{
    if (!variable_global_exists("codex_discovered") || !is_numeric(_object_id)) return false;
    if (!object_exists(_object_id)) return false;
    return array_contains(global.codex_discovered, object_get_name(_object_id) + "_quality_high");
}

