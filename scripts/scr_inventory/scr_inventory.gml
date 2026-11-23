/// 인벤토리 및 구매 처리
// 장비 가격은 상점의 기본 가격 × [나무, 구리, 철, 금, 티타늄] 배수입니다.
// 슬롯에는 { id, quantity }만 저장하고, 표시 정보는 카탈로그에서 가져옵니다.
function inventory_seed_id(_seed)
{
    return _seed.sprite != noone ? sprite_get_name(_seed.sprite) : "seed_" + _seed.name;
}

function inventory_initialize()
{
    if (!variable_global_exists("inventory_definitions"))
    {
        global.inventory_definitions = {};
        var market = scr_market_catalog();
        var codex = scr_codex_catalog();
        for (var i = 0; i < array_length(codex[0]); i++)
        {
            var seed = codex[0][i];
            seed.kind = "seed";
            global.inventory_definitions[$ seed.id] = seed;
        }
        var tool_ids = ["hoe", "can", "trowel"];
        var tier_prices = [1, 2, 4, 8, 16];
        for (var i = 0; i < array_length(codex[1]); i++)
        {
            var tool = codex[1][i];
            tool.kind = "tool";
            tool.tool_kind = tool_ids[i div 5];
            tool.tier = i mod 5;
            tool.icon = tool.tool_kind;
            tool.accent = tool.colour;
            var base_price = 0;
            for (var j = 0; j < array_length(market[1]); j++)
            {
                if (market[1][j].icon == tool.tool_kind) base_price = market[1][j].price;
            }
            tool.price = base_price * tier_prices[tool.tier];
            global.inventory_definitions[$ tool.id] = tool;
        }
        for (var i = 0; i < array_length(market[2]); i++)
        {
            var upgrade = market[2][i];
            if (upgrade.icon != "bag") continue;
            upgrade.id = "inventory_expansion";
            upgrade.kind = "bag";
            upgrade.colour = c_white;
            global.inventory_definitions[$ upgrade.id] = upgrade;
        }
    }
    if (!variable_global_exists("inventory_slots"))
    {
        global.inventory_slots = array_create(27, undefined);
        inventory_grant_starter_tools();
    }
    if (!variable_global_exists("player_gold")) global.player_gold = 10000;
}

function inventory_reset()
{
    inventory_initialize();
    global.inventory_slots = array_create(27, undefined);
    global.player_gold = 10000;
    codex_restore_history(undefined);
    inventory_grant_starter_tools();
}

function inventory_grant_starter_tools()
{
    var kinds = ["hoe", "can", "trowel"];
    for (var tool = 0; tool < array_length(kinds); tool++)
    {
        if (inventory_tool_slot(kinds[tool]) != -1) continue;
        var target = inventory_empty_slot();
        if (target == -1)
        {
            target = array_length(global.inventory_slots);
            array_resize(global.inventory_slots, target + 9);
            for (var slot = target; slot < target + 9; slot++) global.inventory_slots[slot] = undefined;
        }
        var item_id = kinds[tool] + "_wood";
        global.inventory_slots[target] = { id: item_id, quantity: 1 };
        codex_discover(item_id);
    }
}

function inventory_get_item(_id)
{
    return variable_struct_get(global.inventory_definitions, _id);
}

function inventory_tool_slot(_kind)
{
    var found = -1;
    var highest = -1;
    for (var i = 0; i < array_length(global.inventory_slots); i++)
    {
        var slot = global.inventory_slots[i];
        if (!is_struct(slot)) continue;
        var item = inventory_get_item(slot.id);
        if (is_undefined(item) || item.kind != "tool" || item.tool_kind != _kind) continue;
        if (item.tier > highest)
        {
            highest = item.tier;
            found = i;
        }
    }
    return found;
}

function inventory_empty_slot()
{
    for (var i = 0; i < array_length(global.inventory_slots); i++)
        if (is_undefined(global.inventory_slots[i])) return i;
    return -1;
}

function inventory_seed_slot(_id)
{
    for (var i = 0; i < array_length(global.inventory_slots); i++)
    {
        var slot = global.inventory_slots[i];
        if (is_struct(slot) && slot.id == _id) return i;
    }
    return -1;
}

function inventory_purchase_error(_id)
{
    var item = inventory_get_item(_id);
    if (is_undefined(item)) return "구매할 수 없는 품목입니다.";
    if (!is_numeric(item.price) || item.price < 0 || item.price != floor(item.price))
        return "가격 설정을 확인해 주세요.";
    var target = -1;
    if (item.kind == "tool")
    {
        target = inventory_tool_slot(item.tool_kind);
        var current_tier = target == -1 ? -1 : inventory_get_item(global.inventory_slots[target].id).tier;
        if (item.tier != current_tier + 1) return "다음 단계 장비를 선택하세요.";
    }
    if (global.player_gold < item.price) return "골드가 부족합니다.";
    if (item.kind == "bag") return "";
    if (item.kind == "seed") target = inventory_seed_slot(item.id);
    if (target == -1 && inventory_empty_slot() == -1) return "인벤토리가 가득 찼습니다.";
    return "";
}

function inventory_buy(_id)
{
    inventory_initialize();
    var error = inventory_purchase_error(_id);
    if (error != "") return error;

    var item = inventory_get_item(_id);
    if (item.kind == "bag")
    {
        var old_size = array_length(global.inventory_slots);
        array_resize(global.inventory_slots, old_size + 9);
        for (var i = old_size; i < old_size + 9; i++) global.inventory_slots[i] = undefined;
    }
    else
    {
        var target = item.kind == "seed" ? inventory_seed_slot(item.id) : inventory_tool_slot(item.tool_kind);
        if (target == -1) target = inventory_empty_slot();
        if (item.kind == "seed" && is_struct(global.inventory_slots[target]))
        {
            global.inventory_slots[target].quantity++;
        }
        else
        {
            // A tool upgrade replaces the old tool in its current slot.
            global.inventory_slots[target] = { id: item.id, quantity: 1 };
            if (item.kind == "tool")
            {
                for (var i = 0; i < array_length(global.inventory_slots); i++)
                {
                    if (i == target || !is_struct(global.inventory_slots[i])) continue;
                    var other_item = inventory_get_item(global.inventory_slots[i].id);
                    if (other_item.kind == "tool" && other_item.tool_kind == item.tool_kind)
                        global.inventory_slots[i] = undefined;
                }
            }
        }
        codex_discover(item.id);
    }
    global.player_gold -= item.price;
    return "";
}

function inventory_move(_source, _destination)
{
    var count = array_length(global.inventory_slots);
    if (_source < 0 || _source >= count || _destination < 0 || _destination >= count
        || _source == _destination) return false;
    var source = global.inventory_slots[_source];
    var destination = global.inventory_slots[_destination];
    if (!is_struct(source)) return false;
    var item = inventory_get_item(source.id);
    if (is_struct(destination) && source.id == destination.id && item.kind == "seed")
    {
        destination.quantity += source.quantity;
        global.inventory_slots[_source] = undefined;
    }
    else
    {
        global.inventory_slots[_destination] = source;
        global.inventory_slots[_source] = destination;
    }
    return true;
}

function inventory_snapshot()
{
    var result = array_create(array_length(global.inventory_slots), undefined);
    for (var i = 0; i < array_length(result); i++)
    {
        var slot = global.inventory_slots[i];
        if (is_struct(slot)) result[i] = { id: slot.id, quantity: slot.quantity };
    }
    return result;
}

function inventory_restore(_saved)
{
    inventory_initialize();
    var count = is_array(_saved) ? max(27, ceil(array_length(_saved) / 9) * 9) : 27;
    global.inventory_slots = array_create(count, undefined);
    if (!is_array(_saved))
    {
        inventory_grant_starter_tools();
        return;
    }
    for (var i = 0; i < array_length(_saved); i++)
    {
        var saved = _saved[i];
        if (!is_struct(saved)) continue;
        var item_id = variable_struct_get(saved, "id");
        var quantity = variable_struct_get(saved, "quantity");
        if (!is_string(item_id) || !is_numeric(quantity) || quantity < 1) continue;
        var item = inventory_get_item(item_id);
        if (is_undefined(item) || item.kind == "bag") continue;
        global.inventory_slots[i] = {
            id: item_id, quantity: item.kind == "seed" ? floor(quantity) : 1
        };
        codex_discover(item_id);
    }
    // Keep only the highest tier if an imported save contains duplicate tools.
    var kinds = ["hoe", "can", "trowel"];
    for (var tool = 0; tool < array_length(kinds); tool++)
    {
        var keep = inventory_tool_slot(kinds[tool]);
        for (var i = 0; i < count; i++)
        {
            if (i == keep || !is_struct(global.inventory_slots[i])) continue;
            var item = inventory_get_item(global.inventory_slots[i].id);
            if (item.kind == "tool" && item.tool_kind == kinds[tool])
                global.inventory_slots[i] = undefined;
        }
    }
    inventory_grant_starter_tools();
}

function market_stock_catalog()
{
    inventory_initialize();
    var base = scr_market_catalog();
    var seeds = [];
    for (var i = 0; i < array_length(base[0]); i++)
        array_push(seeds, inventory_get_item(inventory_seed_id(base[0][i])));
    var tools = [];
    var tier_ids = ["wood", "copper", "iron", "gold", "titanium"];
    for (var i = 0; i < array_length(base[1]); i++)
    {
        var kind = base[1][i].icon;
        var owned_slot = inventory_tool_slot(kind);
        var tier = owned_slot == -1 ? 1 : inventory_get_item(global.inventory_slots[owned_slot].id).tier + 1;
        if (tier < array_length(tier_ids))
        {
            var next = inventory_get_item(kind + "_" + tier_ids[tier]);
            if (!is_undefined(next)) array_push(tools, next);
        }
    }
    var upgrades = [];
    var bag = inventory_get_item("inventory_expansion");
    if (!is_undefined(bag)) array_push(upgrades, bag);
    return [seeds, tools, upgrades];
}
