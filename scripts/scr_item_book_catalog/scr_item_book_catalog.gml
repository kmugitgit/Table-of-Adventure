/// 도감 항목과 획득 이력
// 작물 아이템을 얻을 때 codex_discover("crop_HeartBeet_normal")처럼 기록합니다.
// 농기구는 codex_discover("hoe_wood"), codex_discover("shovel_copper")처럼 기록합니다.
// 단계 ID는 wood, copper, iron, gold, titanium 순서입니다.

/// @func scr_item_book_entries()
/// @desc 도감 아이템 목록. 새 항목을 추가할 때 아래 배열에 항목 구조체를 추가합니다.
// 형식: {id, name, tag, sprite, description, effects, cultivated_land}
// tag는 plant/condiment/meat/fish/food 중 하나이며 effects는 아이콘 데이터 최대 3개입니다.
function codex_discover(_item)
{
    var key = is_string(_item) ? _item : sprite_get_name(_item);
    if (!variable_global_exists("codex_discovered")) global.codex_discovered = [];
    if (string_copy(key, 1, 5) == "crop_" && string_copy(key, string_length(key) - 4, 5) == "_high")
    {
        var base_key = string_copy(key, 1, string_length(key) - 4) + "normal";
        if (!array_contains(global.codex_discovered, base_key)) array_push(global.codex_discovered, base_key);
    }
    if (!array_contains(global.codex_discovered, key)) array_push(global.codex_discovered, key);
}

function codex_was_found(_id)
{
    return variable_global_exists("codex_discovered") && array_contains(global.codex_discovered, _id);
}

function codex_restore_history(_saved)
{
    global.codex_discovered = [];
    if (!is_array(_saved)) return;
    for (var i = 0; i < min(array_length(_saved), 4096); i++)
    {
        var key = _saved[i];
        if (is_string(key) && string_copy(key, 1, 7) == "trowel_")
            key = "shovel_" + string_delete(key, 1, 7);
        key = fishing_migrate_item_id(key);
        if (is_string(key) && string_length(key) > 0 && string_length(key) <= 128)
            codex_discover(key);
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
        seed.id = inventory_seed_id(seed);
        seed.colour = c_white;
        array_push(seeds, seed);
    }

    var tier_names = ["나무", "구리", "철", "금", "티타늄"];
    var tier_ids = ["wood", "copper", "iron", "gold", "titanium"];
    var tool_names = ["괭이", "물뿌리개", "삽", "낫", "낚싯대"];
    // Keep IDs aligned with inventory and shop records (including existing saves).
    var tool_ids = ["hoe", "can", "shovel", "sickle", "rod"];
    var tool_sprites = [spr_hoe, spr_watering_can, spr_shovel, spr_sickle, fishing_rod];
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
                id: tool_ids[tool] + "_" + tier_ids[tier],
                name: tier_names[tier] + " " + tool_names[tool],
                sprite: tool_sprites[tool],
                sprite_frame: tier,
                description: tool_descriptions[tool],
                colour: c_white
            });
        }
    }
    return [seeds, tools];
}

function codex_draw_quality_overlay(_item, _centre_x, _centre_y, _scale_x, _scale_y)
{
    if (!variable_struct_exists(_item, "quality_id") || _item.quality_id != "high") return;
    var overlay_x = _centre_x + (sprite_get_xoffset(spr_high_quality) - sprite_get_width(spr_high_quality) * 0.5) * _scale_x;
    var overlay_y = _centre_y + (sprite_get_yoffset(spr_high_quality) - sprite_get_height(spr_high_quality) * 0.5) * _scale_y;
    draw_sprite_ext(spr_high_quality, 0, overlay_x, overlay_y, _scale_x, _scale_y, 0, c_white, 1);
}

function codex_draw_item(_item, _bounds, _found)
{
    var centre_x = (_bounds[0] + _bounds[2]) * 0.5;
    var centre_y = (_bounds[1] + _bounds[3]) * 0.5;
    var available_size = _bounds[2] - _bounds[0] - 8;
    if (_item.sprite != noone && sprite_exists(_item.sprite))
    {
        var source_width = sprite_get_width(_item.sprite);
        var source_height = sprite_get_height(_item.sprite);
        var scale = available_size / max(source_width, source_height);
        if (scale >= 1) scale = floor(scale);
        var icon_width = max(1, floor(source_width * scale));
        var icon_height = max(1, floor(source_height * scale));
        var previous_shader = shader_current();
        shader_set(sh_codex_grayscale);
        shader_set_uniform_f(shader_get_uniform(sh_codex_grayscale, "u_collected"), _found ? 1 : 0);
        var sprite_frame = variable_struct_exists(_item, "sprite_frame") ? _item.sprite_frame : 0;
        draw_sprite_stretched_ext(_item.sprite, sprite_frame, round(centre_x - icon_width * 0.5),
            round(centre_y - icon_height * 0.5), icon_width, icon_height, _item.colour, 1);
        codex_draw_quality_overlay(_item, centre_x, centre_y,
            icon_width / sprite_get_width(spr_high_quality), icon_height / sprite_get_height(spr_high_quality));
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

