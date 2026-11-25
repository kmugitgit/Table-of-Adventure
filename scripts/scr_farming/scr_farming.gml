/// Farming configuration: game minutes, quality weights, and future cooking multipliers.
function farming_initialize()
{
    if (variable_global_exists("farming_rules")) return;
    global.farming_rules = {
        qualities: [
            { id: "normal", name: "일반", chance: 60, effect_multiplier: 1.0, colour: c_white },
            { id: "fine", name: "우수", chance: 25, effect_multiplier: 1.1, colour: make_color_rgb(190, 215, 225) },
            { id: "excellent", name: "특급", chance: 12, effect_multiplier: 1.25, colour: make_color_rgb(255, 206, 80) },
            { id: "premium", name: "최상급", chance: 3, effect_multiplier: 1.5, colour: make_color_rgb(205, 145, 255) }
        ],
        // Keep seed/product identities; only growth artwork currently shares HeartBeet.
        crops: [
            { seed_id: "spr_seed_HeartBeet", product_id: "HeartBeet", name: "하트비트", sprite: spr_HeartBeet, growth_sprite: spr_HeartBeet_crop, growth_minutes: 240 },
            { seed_id: "spr_seed_Hellapeno", product_id: "Hellapeno", name: "헬라피뇨", sprite: spr_Hellapeno, growth_sprite: spr_HeartBeet_crop, growth_minutes: 240 },
            { seed_id: "spr_seed_CloudPotato", product_id: "CloudPotato", name: "구름감자", sprite: spr_CloudPotato, growth_sprite: spr_HeartBeet_crop, growth_minutes: 240 },
            { seed_id: "spr_seed_IceCarrot", product_id: "IceCarrot", name: "얼음당근", sprite: spr_IceCarrot, growth_sprite: spr_HeartBeet_crop, growth_minutes: 240 },
            { seed_id: "spr_seed_Magmato", product_id: "Magmato", name: "마그마토", sprite: spr_Magmato, growth_sprite: spr_HeartBeet_crop, growth_minutes: 240 }
        ]
    };
}

function farming_definition(_seed)
{
    farming_initialize();
    var crops = global.farming_rules.crops;
    for (var i = 0; i < array_length(crops); i++) if (crops[i].seed_id == _seed) return crops[i];
    return crops[0];
}

function farming_register_items()
{
    farming_initialize();
    var crops = global.farming_rules.crops;
    var qualities = global.farming_rules.qualities;
    for (var i = 0; i < array_length(crops); i++)
    {
        var crop = crops[i];
        for (var rank = 0; rank < array_length(qualities); rank++)
        {
            var quality = qualities[rank];
            var item_id = "crop_" + crop.product_id + "_" + quality.id;
            global.inventory_definitions[$ item_id] = {
                id: item_id, kind: "crop", tab: "item", price: 0,
                name: crop.name + (rank > 0 ? " (" + quality.name + ")" : ""),
                sprite: crop.sprite, sprite_frame: 0, colour: c_white,
                description: quality.name + " 품질의 " + crop.name + "입니다. 요리 효과 배율: "
                    + string(quality.effect_multiplier),
                base_crop_id: crop.product_id, seed_id: crop.seed_id,
                quality_rank: rank, quality_id: quality.id,
                quality_colour: quality.colour, effect_multiplier: quality.effect_multiplier
            };
        }
    }
}

function farming_cell_watered(_col, _row)
{
    var hero = instance_find(obj_main_chr_girl, 0);
    if (room == rm_main && hero != noone && variable_instance_exists(hero, "terrain_tilemap") && hero.terrain_tilemap != -1)
        return terrain_family(tile_get_index(tilemap_get(hero.terrain_tilemap, _col, _row))) == 5;
    if (variable_global_exists("terrain_changes"))
    {
        for (var i = 0; i < array_length(global.terrain_changes); i++)
        {
            var cell = global.terrain_changes[i];
            if (cell.column == _col && cell.row == _row) return terrain_family(cell.index) == 5;
        }
    }
    return false;
}

function farming_new_crop(_col, _row, _seed, _watered)
{
    if (!variable_global_exists("farming_randomized")) { randomize(); global.farming_randomized = true; }
    return { column: _col, row: _row, seed_id: _seed, growth_minutes: 0,
        watered: _watered, quality_roll: random(100) };
}

function farming_restore_crop(_saved, _col, _row, _seed)
{
    var definition = farming_definition(_seed);
    var growth = variable_struct_get(_saved, "growth_minutes");
    var watered = variable_struct_get(_saved, "watered");
    var roll = variable_struct_get(_saved, "quality_roll");
    return {
        column: _col, row: _row, seed_id: _seed,
        growth_minutes: is_numeric(growth) ? clamp(growth, 0, definition.growth_minutes) : 0,
        watered: is_bool(watered) ? watered : farming_cell_watered(_col, _row),
        // Stable legacy fallback prevents rerolling quality every time an old save loads.
        quality_roll: is_numeric(roll) && roll >= 0 && roll < 100 ? roll
            : (_col * 37 + _row * 61 + string_length(_seed) * 17) mod 100
    };
}

function farming_advance(_minutes)
{
    if (_minutes <= 0 || !variable_global_exists("planted_crops")) return;
    for (var i = 0; i < array_length(global.planted_crops); i++)
    {
        var crop = global.planted_crops[i];
        if (!crop.watered) continue;
        var definition = farming_definition(crop.seed_id);
        crop.growth_minutes = min(definition.growth_minutes, crop.growth_minutes + _minutes);
    }
}

function farming_growth_frame(_crop)
{
    var definition = farming_definition(_crop.seed_id);
    var last_frame = max(0, sprite_get_number(definition.growth_sprite) - 1);
    return min(last_frame, floor(clamp(_crop.growth_minutes / definition.growth_minutes, 0, 1) * last_frame));
}

function farming_ready(_crop)
{
    return _crop.growth_minutes >= farming_definition(_crop.seed_id).growth_minutes;
}

function farming_cell_ready(_col, _row)
{
    var index = terrain_crop_index(_col, _row);
    return index != -1 && farming_ready(global.planted_crops[index]);
}

function farming_water_crop(_col, _row)
{
    var index = terrain_crop_index(_col, _row);
    if (index != -1) global.planted_crops[index].watered = true;
}

function farming_quality_rank(_roll)
{
    farming_initialize();
    var qualities = global.farming_rules.qualities;
    var total = 0;
    for (var i = 0; i < array_length(qualities); i++) total += qualities[i].chance;
    var point = clamp(_roll, 0, 99.999999) / 100 * total;
    var weight = 0;
    for (var i = 0; i < array_length(qualities); i++)
    {
        weight += qualities[i].chance;
        if (point < weight) return i;
    }
    return array_length(qualities) - 1;
}

function farming_harvest(_crop_index)
{
    if (_crop_index < 0 || _crop_index >= array_length(global.planted_crops)) return false;
    var crop = global.planted_crops[_crop_index];
    if (!farming_ready(crop)) return false;
    var definition = farming_definition(crop.seed_id);
    var quality = global.farming_rules.qualities[farming_quality_rank(crop.quality_roll)];
    var item_id = "crop_" + definition.product_id + "_" + quality.id;
    // Adding one item is atomic: a full bag leaves the crop, age and quality intact.
    if (inventory_stack_add(item_id, 1) != 0) return false;
    inventory_notify_gain(item_id, 1);
    codex_discover(crop.seed_id);
    codex_discover(item_id);
    array_delete(global.planted_crops, _crop_index, 1);
    return true;
}

function farming_draw_quality_badge(_item, _bounds)
{
    if (!variable_struct_exists(_item, "quality_rank") || _item.quality_rank <= 0) return;
    var old_colour = draw_get_color();
    var cx = floor(_bounds[2] - 4);
    var cy = floor(_bounds[1] + 5);
    draw_set_color(make_color_rgb(40, 29, 23));
    draw_rectangle(cx - 4, cy - 4, cx + 4, cy + 4, false);
    draw_set_color(_item.quality_colour);
    draw_line(cx, cy - 3, cx, cy + 3);
    draw_line(cx - 3, cy, cx + 3, cy);
    draw_line(cx - 2, cy - 2, cx + 2, cy + 2);
    draw_line(cx - 2, cy + 2, cx + 2, cy - 2);
    draw_set_color(old_colour);
}
