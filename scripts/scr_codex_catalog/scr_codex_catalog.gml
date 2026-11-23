/// 도감 항목과 획득 이력
// 아이템을 얻는 코드에서 codex_discover(spr_seed_HeartBeet)를 호출하세요.
// 농기구는 codex_discover("hoe_wood"), codex_discover("can_copper")처럼 기록합니다.
// 단계 ID는 wood, copper, iron, gold, titanium 순서입니다.
function codex_discover(_item)
{
    var key = is_string(_item) ? _item : sprite_get_name(_item);
    if (!variable_global_exists("codex_discovered")) global.codex_discovered = [];
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
        if (is_string(key) && string_length(key) > 0 && string_length(key) <= 128)
            codex_discover(key);
    }
}

function scr_codex_catalog()
{
    var market = scr_market_catalog();
    var seeds = market[0];
    for (var i = 0; i < array_length(seeds); i++)
    {
        var seed = seeds[i];
        seed.id = inventory_seed_id(seed);
        seed.colour = c_white;
    }

    var tier_names = ["나무", "구리", "철", "금", "티타늄"];
    var tier_ids = ["wood", "copper", "iron", "gold", "titanium"];
    var tool_names = ["괭이", "물뿌리개", "모종삽"];
    var tool_ids = ["hoe", "can", "trowel"];
    var tool_sprites = [spr_hoe, spr_watering_can, spr_shovel];
    var tool_descriptions = [
        "밭을 갈아 씨앗을 심을 땅을 만드는 농기구입니다.",
        "씨앗과 작물에 물을 뿌리는 농기구입니다.",
        "모종을 옮기거나 작은 구덩이를 파는 농기구입니다."
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
