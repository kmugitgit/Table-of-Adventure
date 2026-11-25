/// 인벤토리 및 구매 처리
// 장비 가격은 상점의 기본 가격 × [나무, 구리, 철, 금, 티타늄] 배수입니다.
// 슬롯에는 id, quantity, 물뿌리개의 water, 도구의 area_level을 저장합니다.
function inventory_seed_id(_seed)
{
    return _seed.sprite != noone ? sprite_get_name(_seed.sprite) : "seed_" + _seed.name;
}

function inventory_initialize()
{
    if (!variable_global_exists("inventory_gain_notices")) global.inventory_gain_notices = [];
    if (!variable_global_exists("inventory_definitions"))
    {
        global.inventory_definitions = {};
        var market_entries = scr_market_entries();
        var codex = scr_item_book_catalog();
        for (var i = 0; i < array_length(codex[0]); i++)
        {
            var seed = codex[0][i];
            seed.kind = "seed";
            global.inventory_definitions[$ seed.id] = seed;
        }
        var tool_ids = ["hoe", "can", "shovel", "sickle", "rod"];
        var tier_prices = [1, 2, 4, 8, 16];
        for (var i = 0; i < array_length(codex[1]); i++)
        {
            var tool = codex[1][i];
            tool.kind = "tool";
            tool.tool_kind = tool_ids[i div 5];
            tool.tier = i mod 5;
            var base_price = 0;
            var base_description = tool.description;
            for (var j = 0; j < array_length(market_entries); j++)
            {
                var market_entry = market_entries[j];
                if (market_entry.tab == "tool" && market_entry.id == tool.tool_kind)
                {
                    base_price = market_entry.price;
                    base_description = market_entry.description;
                }
            }
            tool.price = base_price * tier_prices[tool.tier];
            tool.description = base_description;
            global.inventory_definitions[$ tool.id] = tool;
        }
        for (var i = 0; i < array_length(market_entries); i++)
        {
            var upgrade = market_entries[i];
            if (upgrade.id != "inventory_expansion") continue;
            upgrade.id = "inventory_expansion";
            upgrade.kind = "bag";
            global.inventory_definitions[$ upgrade.id] = upgrade;
        }
        for (var i = 0; i < array_length(market_entries); i++)
        {
            var extra_entry = market_entries[i];
            if (extra_entry.tab != "item" && extra_entry.tab != "structure") continue;
            extra_entry.kind = extra_entry.tab;
            extra_entry.colour = c_white;
            global.inventory_definitions[$ extra_entry.id] = extra_entry;
        }
        fishing_register_items();
        cooking_register_items();
    }
    if (!variable_struct_exists(global.inventory_definitions, "crop_HeartBeet_normal")) farming_register_items();
    if (!variable_global_exists("inventory_slots"))
    {
        global.inventory_slots = array_create(18, undefined);
        inventory_grant_starter_tools();
    }
    if (!variable_global_exists("player_gold")) global.player_gold = 10000;
}

function inventory_notify_gain(_id, _quantity)
{
    if (_quantity <= 0) return;
    if (!variable_global_exists("inventory_gain_notices")) global.inventory_gain_notices = [];
    var item = inventory_get_item(_id);
    if (is_undefined(item)) return;
    var notices = global.inventory_gain_notices;
    // Update the existing line when the same item is gained before its notice disappears.
    for (var i = 0; i < array_length(notices); i++)
    {
        if (notices[i].id == _id && notices[i].age < 2.5)
        {
            notices[i].quantity += _quantity;
            notices[i].age = 0;
            notices[i].overflow_age = -1;
            return;
        }
    }
    if (array_length(notices) >= 3)
        notices[array_length(notices) - 3].overflow_age = 0;
    array_push(notices, { id: _id, name: item.name, quantity: _quantity, age: 0, overflow_age: -1 });
}

function inventory_reset()
{
    inventory_initialize();
    global.inventory_gain_notices = [];
    global.inventory_slots = array_create(18, undefined);
    global.player_gold = 10000;
    codex_restore_history(undefined);
    global.terrain_changes = [];
    global.planted_crops = [];
    cooking_reset();
    inventory_grant_starter_tools();
}

function inventory_grant_starter_tools()
{
    var kinds = ["hoe", "can", "shovel", "sickle"];
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

function inventory_stack_slot(_id)
{
    for (var i = 0; i < array_length(global.inventory_slots); i++)
    {
        var slot = global.inventory_slots[i];
        if (is_struct(slot) && slot.id == _id && slot.quantity < 99) return i;
    }
    return -1;
}

function inventory_seed_slot(_id)
{
    return inventory_stack_slot(_id);
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
    if (item.kind == "bag")
    {
        if (array_length(global.inventory_slots) >= 45)
            return "가방 확장은 최대 3회까지 구매할 수 있습니다.";
        return "";
    }
    if (inventory_item_stackable(item)) target = inventory_stack_slot(item.id);
    else if (item.kind == "tool") target = inventory_tool_slot(item.tool_kind);
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
        if (old_size >= 45) return "가방 확장은 최대 3회까지 구매할 수 있습니다.";
        array_resize(global.inventory_slots, old_size + 9);
        for (var i = old_size; i < old_size + 9; i++) global.inventory_slots[i] = undefined;
    }
    else
    {
        var target = -1;
        if (inventory_item_stackable(item)) target = inventory_stack_slot(item.id);
        else if (item.kind == "tool") target = inventory_tool_slot(item.tool_kind);
        if (target == -1) target = inventory_empty_slot();
        if (inventory_item_stackable(item) && is_struct(global.inventory_slots[target]))
        {
            global.inventory_slots[target].quantity++;
        }
        else
        {
            // A tool upgrade replaces the old tool in its current slot.
            var water = item.kind == "tool" && item.tool_kind == "can"
                && is_struct(global.inventory_slots[target]) ? inventory_water_amount(global.inventory_slots[target]) : 6;
            global.inventory_slots[target] = { id: item.id, quantity: 1 };
            if (item.kind == "tool" && item.tool_kind == "can") global.inventory_slots[target].water = water;
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
    if (is_struct(destination) && source.id == destination.id
        && inventory_item_stackable(item))
    {
        var moved = min(99 - destination.quantity, source.quantity);
        if (moved <= 0) return false;
        destination.quantity += moved;
        source.quantity -= moved;
        if (source.quantity <= 0) global.inventory_slots[_source] = undefined;
    }
    else
    {
        global.inventory_slots[_destination] = source;
        global.inventory_slots[_source] = destination;
    }
    return true;
}

function inventory_item_stackable(_item)
{
    return !is_undefined(_item) && _item.kind != "tool" && _item.kind != "bag";
}

function inventory_stack_add(_id, _quantity)
{
    var item = inventory_get_item(_id);
    var stackable = inventory_item_stackable(item);
    var remaining = max(0, floor(_quantity));
    if (stackable)
    {
        for (var i = 0; i < array_length(global.inventory_slots) && remaining > 0; i++)
        {
            var slot = global.inventory_slots[i];
            if (!is_struct(slot) || slot.id != _id || slot.quantity >= 99) continue;
            var moved = min(99 - slot.quantity, remaining);
            slot.quantity += moved;
            remaining -= moved;
        }
    }
    while (remaining > 0)
    {
        var empty = inventory_empty_slot();
        if (empty == -1) break;
        var placed = stackable ? min(99, remaining) : 1;
        global.inventory_slots[empty] = { id: _id, quantity: placed };
        remaining -= placed;
    }
    return remaining;
}

function inventory_quick_move(_source_index)
{
    if (_source_index < 0 || _source_index >= array_length(global.inventory_slots)) return false;
    var source = global.inventory_slots[_source_index];
    if (!is_struct(source)) return false;
    var item = inventory_get_item(source.id);
    if (is_undefined(item)) return false;
    var stackable = inventory_item_stackable(item);
    var first = _source_index < 9 ? 9 : 0;
    var last = _source_index < 9 ? array_length(global.inventory_slots) : min(9, array_length(global.inventory_slots));
    var remaining = source.quantity;
    if (stackable)
    {
        for (var i = first; i < last && remaining > 0; i++)
        {
            var target = global.inventory_slots[i];
            if (!is_struct(target) || target.id != source.id || target.quantity >= 99) continue;
            var moved = min(99 - target.quantity, remaining);
            target.quantity += moved;
            remaining -= moved;
        }
    }
    for (var i = first; i < last && remaining > 0; i++)
    {
        if (!is_undefined(global.inventory_slots[i])) continue;
        var placed = stackable ? min(99, remaining) : 1;
        global.inventory_slots[i] = { id: source.id, quantity: placed };
        remaining -= placed;
    }

    // If the hotbar has no room, compact a quick-moved item to the first
    // matching stack or empty cell in the main inventory, starting top-left.
    if (_source_index >= 9 && remaining > 0)
    {
        if (stackable)
        {
            for (var i = 9; i < array_length(global.inventory_slots) && remaining > 0; i++)
            {
                if (i == _source_index) continue;
                var target = global.inventory_slots[i];
                if (!is_struct(target) || target.id != source.id || target.quantity >= 99) continue;
                var moved = min(99 - target.quantity, remaining);
                target.quantity += moved;
                remaining -= moved;
            }
        }
        for (var i = 9; i < array_length(global.inventory_slots) && remaining > 0; i++)
        {
            if (i == _source_index || !is_undefined(global.inventory_slots[i])) continue;
            var placed = stackable ? min(99, remaining) : 1;
            global.inventory_slots[i] = { id: source.id, quantity: placed };
            remaining -= placed;
        }
    }
    if (remaining == source.quantity) return false;
    if (remaining <= 0) global.inventory_slots[_source_index] = undefined;
    else source.quantity = remaining;
    return true;
}

function inventory_pickup(_player, _slot_index, _take_half)
{
    if (_slot_index < 0 || _slot_index >= array_length(global.inventory_slots)) return false;
    var slot = global.inventory_slots[_slot_index];
    if (!is_struct(slot)) return false;
    var item = inventory_get_item(slot.id);
    if (is_undefined(item)) return false;
    var quantity = slot.quantity;
    if (_take_half && inventory_item_stackable(item) && quantity > 1)
    {
        quantity = ceil(quantity * 0.5);
        slot.quantity -= quantity;
    }
    else global.inventory_slots[_slot_index] = undefined;
    _player.inventory_held_stack = { id: slot.id, quantity: quantity };
    _player.inventory_held_source = _slot_index;
    return true;
}

function inventory_hold_left(_player, _slot_index)
{
    if (!is_struct(_player.inventory_held_stack)
        || _slot_index < 0 || _slot_index >= array_length(global.inventory_slots)) return false;
    var held = _player.inventory_held_stack;
    var target = global.inventory_slots[_slot_index];
    if (!is_struct(target))
    {
        global.inventory_slots[_slot_index] = held;
        _player.inventory_held_stack = undefined;
        _player.inventory_held_source = -1;
        return true;
    }
    var held_item = inventory_get_item(held.id);
    if (target.id == held.id && inventory_item_stackable(held_item))
    {
        var moved = min(99 - target.quantity, held.quantity);
        if (moved <= 0) return false;
        target.quantity += moved;
        held.quantity -= moved;
        if (held.quantity <= 0)
        {
            _player.inventory_held_stack = undefined;
            _player.inventory_held_source = -1;
        }
        return true;
    }
    global.inventory_slots[_slot_index] = held;
    _player.inventory_held_stack = target;
    _player.inventory_held_source = _slot_index;
    return true;
}

function inventory_hold_right(_player, _slot_index)
{
    if (!is_struct(_player.inventory_held_stack)
        || _slot_index < 0 || _slot_index >= array_length(global.inventory_slots)) return false;
    var held = _player.inventory_held_stack;
    var item = inventory_get_item(held.id);
    if (is_undefined(item)) return false;
    var target = global.inventory_slots[_slot_index];
    if (!inventory_item_stackable(item))
    {
        if (is_undefined(target)) return inventory_hold_left(_player, _slot_index);
        return false;
    }
    if (is_undefined(target))
    {
        global.inventory_slots[_slot_index] = { id: held.id, quantity: 1 };
    }
    else if (target.id == held.id && target.quantity < 99)
    {
        target.quantity++;
    }
    else return false;
    held.quantity--;
    if (held.quantity <= 0)
    {
        _player.inventory_held_stack = undefined;
        _player.inventory_held_source = -1;
    }
    return true;
}

function inventory_distribute_held(_player, _slot_indices)
{
    if (!is_struct(_player.inventory_held_stack) || array_length(_slot_indices) == 0) return false;
    var held = _player.inventory_held_stack;
    var item = inventory_get_item(held.id);
    if (is_undefined(item)) return false;
    if (!inventory_item_stackable(item)) return inventory_hold_left(_player, _slot_indices[0]);

    var valid_slots = [];
    var smallest_room = 99;
    for (var i = 0; i < array_length(_slot_indices); i++)
    {
        var slot_index = _slot_indices[i];
        var target = global.inventory_slots[slot_index];
        if (is_undefined(target))
        {
            array_push(valid_slots, slot_index);
        }
        else if (target.id == held.id && target.quantity < 99)
        {
            array_push(valid_slots, slot_index);
            smallest_room = min(smallest_room, 99 - target.quantity);
        }
    }
    var count = array_length(valid_slots);
    if (count == 0) return false;
    var each = min(floor(held.quantity / count), smallest_room);
    if (each <= 0) return false;
    for (var i = 0; i < count; i++)
    {
        var slot_index = valid_slots[i];
        var target = global.inventory_slots[slot_index];
        if (is_undefined(target)) global.inventory_slots[slot_index] = { id: held.id, quantity: each };
        else target.quantity += each;
    }
    held.quantity -= each * count;
    if (held.quantity <= 0)
    {
        _player.inventory_held_stack = undefined;
        _player.inventory_held_source = -1;
    }
    return true;
}

function inventory_collect_matching(_player, _id)
{
    if (!is_struct(_player.inventory_held_stack) || _player.inventory_held_stack.id != _id) return false;
    var item = inventory_get_item(_id);
    if (!inventory_item_stackable(item)) return false;
    var held = _player.inventory_held_stack;
    var remaining_capacity = max(0, 99 - held.quantity);
    // Prefer scattered, incomplete stacks; only collect full 99-stacks last.
    for (var pass = 0; pass < 2 && remaining_capacity > 0; pass++)
    {
        for (var i = 0; i < array_length(global.inventory_slots) && remaining_capacity > 0; i++)
        {
            var slot = global.inventory_slots[i];
            if (!is_struct(slot) || slot.id != _id) continue;
            var is_full_stack = slot.quantity >= 99;
            if ((pass == 0 && is_full_stack) || (pass == 1 && !is_full_stack)) continue;
            var moved = min(slot.quantity, remaining_capacity);
            slot.quantity -= moved;
            held.quantity += moved;
            remaining_capacity -= moved;
            if (slot.quantity <= 0) global.inventory_slots[i] = undefined;
        }
    }
    return true;
}

function inventory_drag_snapshot(_slot_index)
{
    var slot = global.inventory_slots[_slot_index];
    if (!is_struct(slot)) return { index: _slot_index, occupied: false };
    return {
        index: _slot_index,
        occupied: true,
        id: slot.id,
        quantity: slot.quantity
    };
}

function inventory_drag_restore_preview(_player)
{
    if (!is_struct(_player.inventory_drag_baseline)) return;
    for (var i = 0; i < array_length(_player.inventory_drag_snapshots); i++)
    {
        var snapshot = _player.inventory_drag_snapshots[i];
        if (snapshot.occupied)
            global.inventory_slots[snapshot.index] = { id: snapshot.id, quantity: snapshot.quantity };
        else global.inventory_slots[snapshot.index] = undefined;
    }
    _player.inventory_held_stack = {
        id: _player.inventory_drag_baseline.id,
        quantity: _player.inventory_drag_baseline.quantity
    };
}

function inventory_drag_add_slot(_player, _slot_index)
{
    if (_slot_index < 0 || array_contains(_player.inventory_drag_slots, _slot_index)) return false;
    if (_player.inventory_drag_mode == "left")
    {
        var item = inventory_get_item(_player.inventory_drag_baseline.id);
        if (inventory_item_stackable(item))
        {
            inventory_drag_restore_preview(_player);
            array_push(_player.inventory_drag_snapshots, inventory_drag_snapshot(_slot_index));
        }
        array_push(_player.inventory_drag_slots, _slot_index);
        if (inventory_item_stackable(item) && array_length(_player.inventory_drag_slots) > 1)
            inventory_distribute_held(_player, _player.inventory_drag_slots);
    }
    else if (_player.inventory_drag_mode == "right")
    {
        array_push(_player.inventory_drag_slots, _slot_index);
        inventory_hold_right(_player, _slot_index);
    }
    return true;
}

function inventory_cancel_hold(_player)
{
    if (!is_struct(_player.inventory_held_stack)) return;
    var held = _player.inventory_held_stack;
    var source_index = _player.inventory_held_source;
    if (source_index >= 0 && source_index < array_length(global.inventory_slots))
    {
        var source = global.inventory_slots[source_index];
        if (is_undefined(source))
        {
            global.inventory_slots[source_index] = held;
            _player.inventory_held_stack = undefined;
            _player.inventory_held_source = -1;
            return;
        }
        if (is_struct(source) && source.id == held.id)
        {
            var item = inventory_get_item(held.id);
            if (inventory_item_stackable(item))
            {
                var moved = min(99 - source.quantity, held.quantity);
                source.quantity += moved;
                held.quantity -= moved;
            }
        }
    }
    var left = inventory_stack_add(held.id, held.quantity);
    if (left <= 0)
    {
        _player.inventory_held_stack = undefined;
        _player.inventory_held_source = -1;
    }
    else held.quantity = left;
}

function inventory_snapshot()
{
    var result = array_create(array_length(global.inventory_slots), undefined);
    for (var i = 0; i < array_length(result); i++)
    {
        var slot = global.inventory_slots[i];
        if (is_struct(slot))
        {
            result[i] = { id: slot.id, quantity: slot.quantity };
            var item = inventory_get_item(slot.id);
            if (item.kind == "tool" && item.tool_kind == "can") result[i].water = inventory_water_amount(slot);
            if (item.kind == "tool") result[i].area_level = inventory_tool_area_level(slot);
        }
    }
    return result;
}

function inventory_restore(_saved)
{
    inventory_initialize();
    // Keep every slot from an existing save; new inventories start with two rows.
    var count = is_array(_saved)
        ? max(18, ceil(array_length(_saved) / 9) * 9) : 18;
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
        if (string_copy(item_id, 1, 7) == "trowel_")
            item_id = "shovel_" + string_delete(item_id, 1, 7);
        item_id = fishing_migrate_item_id(item_id);
        // Fold old crop grades into the two-grade system and old dish grades into one item.
        if (string_copy(item_id, 1, 5) == "crop_")
        {
            var last_underscore = string_last_pos("_", item_id);
            if (last_underscore > 0)
            {
                var old_grade = string_delete(item_id, 1, last_underscore);
                if (old_grade == "fine" || old_grade == "excellent" || old_grade == "premium")
                    item_id = string_copy(item_id, 1, last_underscore - 1) + "_high";
            }
        }
        else if (string_copy(item_id, 1, 5) == "food_" || string_copy(item_id, 1, 9) == "prepared_")
        {
            var last_underscore = string_last_pos("_", item_id);
            if (last_underscore > 0)
            {
                var old_grade = string_delete(item_id, 1, last_underscore);
                if (old_grade == "normal" || old_grade == "fine" || old_grade == "excellent" || old_grade == "premium")
                    item_id = string_copy(item_id, 1, last_underscore - 1);
            }
        }
        var item = inventory_get_item(item_id);
        if (is_undefined(item) || item.kind == "bag") continue;
        var restore_slot = -1;
        if (inventory_item_stackable(item))
        {
            inventory_stack_add(item_id, floor(quantity));
        }
        else
        {
            restore_slot = inventory_empty_slot();
            if (restore_slot != -1) global.inventory_slots[restore_slot] = { id: item_id, quantity: 1 };
        }
        if (item.kind == "tool" && item.tool_kind == "can" && restore_slot != -1)
            global.inventory_slots[restore_slot].water = inventory_water_amount(saved);
        if (item.kind == "tool" && restore_slot != -1)
        {
            var saved_area = variable_struct_get(saved, "area_level");
            if (is_numeric(saved_area))
                global.inventory_slots[restore_slot].area_level = clamp(floor(saved_area), 0, item.tier);
        }
        codex_discover(item_id);
    }
    // Keep only the highest tier if an imported save contains duplicate tools.
    var kinds = ["hoe", "can", "shovel", "sickle", "rod"];
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
    var base = scr_market_entries();
    var seeds = [];
    var tools = [];
    var items = [];
    var structures = [];
    var tier_ids = ["wood", "copper", "iron", "gold", "titanium"];
    var tier_names = ["나무", "구리", "철", "금", "티타늄"];
    for (var i = 0; i < array_length(base); i++)
    {
        var entry = base[i];
        if (entry.tab == "seed")
        {
            var seed = inventory_get_item(entry.id);
            if (!is_undefined(seed)) array_push(seeds, seed);
        }
        else if (entry.id == "inventory_expansion")
        {
            var bag = inventory_get_item(entry.id);
            if (!is_undefined(bag)) array_push(tools, bag);
        }
        else if (entry.tab == "tool")
        {
            var kind = entry.id;
            var owned_slot = inventory_tool_slot(kind);
            var tier = owned_slot == -1 ? (kind == "rod" ? 0 : 1) : inventory_get_item(global.inventory_slots[owned_slot].id).tier + 1;
            if (tier < array_length(tier_ids))
            {
                var next = inventory_get_item(kind + "_" + tier_ids[tier]);
                if (!is_undefined(next))
                {
                    var market_tool = {
                        id: next.id,
                        name: tier_names[tier] + " " + entry.name,
                        tab: entry.tab,
                        sprite: entry.sprite != noone ? entry.sprite : next.sprite,
                        sprite_frame: variable_struct_exists(entry, "sprite_frame")
                            ? entry.sprite_frame : next.sprite_frame,
                        description: entry.description,
                        price: next.price,
                        kind: next.kind,
                        tier: next.tier
                    };
                    array_push(tools, market_tool);
                }
            }
        }
        else if (entry.tab == "item")
        {
            var market_item_entry = inventory_get_item(entry.id);
            if (!is_undefined(market_item_entry)) array_push(items, market_item_entry);
        }
        else if (entry.tab == "structure")
        {
            var market_structure_entry = inventory_get_item(entry.id);
            if (!is_undefined(market_structure_entry)) array_push(structures, market_structure_entry);
        }
        else
        {
            var fallback_market_entry = inventory_get_item(entry.id);
            if (!is_undefined(fallback_market_entry)) array_push(items, fallback_market_entry);
        }
    }
    return [seeds, tools, items, structures];
}


function inventory_water_capacity(_slot)
{
    var item = inventory_get_item(_slot.id);
    var tier = !is_undefined(item) && item.kind == "tool" && item.tool_kind == "can"
        ? clamp(item.tier, 0, 4) : 0;
    var capacities = [6, 12, 18, 24, 36];
    return capacities[tier];
}

function inventory_water_amount(_slot)
{
    var water = variable_struct_get(_slot, "water");
    var capacity = inventory_water_capacity(_slot);
    return is_numeric(water) ? clamp(floor(water), 0, capacity) : capacity;
}


function inventory_return_seed(_id)
{
    var item = inventory_get_item(_id);
    if (is_undefined(item) || item.kind != "seed") return false;
    var slot = inventory_seed_slot(_id);
    if (slot != -1) global.inventory_slots[slot].quantity++;
    else
    {
        slot = inventory_empty_slot();
        if (slot == -1) return false;
        global.inventory_slots[slot] = { id: _id, quantity: 1 };
    }
    codex_discover(_id);
    return true;
}


// Count all stacks of one seed across every inventory slot.
function inventory_seed_count(_id)
{
    var total = 0;
    for (var i = 0; i < array_length(global.inventory_slots); i++)
    {
        var slot = global.inventory_slots[i];
        if (is_struct(slot) && slot.id == _id) total += slot.quantity;
    }
    return total;
}


function inventory_tool_area_level(_slot)
{
    if (!is_struct(_slot)) return 0;
    var item = inventory_get_item(_slot.id);
    if (is_undefined(item) || item.kind != "tool") return 0;
    var saved_level = variable_struct_get(_slot, "area_level");
    if (is_numeric(saved_level)) return clamp(floor(saved_level), 0, item.tier);
    return clamp(floor(item.tier), 0, 4);
}

function inventory_tool_area_shape(_slot)
{
    var item = is_struct(_slot) ? inventory_get_item(_slot.id) : undefined;
    if (!is_undefined(item) && item.kind == "tool" && item.tool_kind == "rod") return { width: 1, height: 1 };
    var size = inventory_tool_area_level(_slot) + 1;
    return { width: size, height: size };
}

function inventory_adjust_tool_area(_slot, _change)
{
    if (!is_struct(_slot) || _change == 0) return;
    var item = inventory_get_item(_slot.id);
    if (is_undefined(item) || item.kind != "tool" || item.tool_kind == "rod") return;
    _slot.area_level = clamp(inventory_tool_area_level(_slot) + sign(_change), 0, item.tier);
}
