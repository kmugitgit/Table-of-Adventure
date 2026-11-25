/// Restaurant and cooking transactions. UI drag previews never remove inventory items.
function cooking_initialize()
{
    if (!variable_global_exists("cooking_recipes")) global.cooking_recipes = scr_cooking_entries();
    if (!variable_global_exists("cooking_state")) cooking_reset();
}

function cooking_empty_station(_kind)
{
    return { kind: _kind, state: "empty", recipe_id: "", step: -1, input_id: "", elapsed: 0 };
}

function cooking_reset()
{
    var stations = []; var entries = scr_cooking_station_entries();
    for (var i = 0; i < array_length(entries); i++) array_push(stations, cooking_empty_station(entries[i].id));
    global.cooking_state = { phase: "none", order_recipe: "", order_text: "", accepted: false,
        customer_number: 0, review_remaining: 0, review_text: "", notice: "", notice_remaining: 0,
        stations: stations, table_items: [], outside: undefined };
    global.restaurant_return = undefined;
}

function cooking_recipe(_id)
{
    cooking_initialize();
    for (var i = 0; i < array_length(global.cooking_recipes); i++)
        if (global.cooking_recipes[i].id == _id) return global.cooking_recipes[i];
    return undefined;
}

function cooking_recipe_is_ingredient(_recipe_id)
{
    for (var i = 0; i < array_length(global.cooking_recipes); i++)
        if (global.cooking_recipes[i].ingredient == _recipe_id) return true;
    return false;
}

function cooking_output_id(_recipe, _step)
{
    return (cooking_recipe_is_ingredient(_recipe.id) ? "prepared_" : "food_") + _recipe.id;
}

function cooking_migrate_item_id(_id)
{
    if (string_copy(_id, 1, 5) != "food_" && string_copy(_id, 1, 9) != "prepared_") return _id;
    var last_underscore = string_last_pos("_", _id);
    if (last_underscore > 0)
    {
        var grade = string_delete(_id, 1, last_underscore);
        if (grade == "normal" || grade == "fine" || grade == "excellent" || grade == "premium")
            _id = string_copy(_id, 1, last_underscore - 1);
    }
    var suffix = string_copy(_id, string_length(_id) - 2, 3);
    if (suffix == "_s0" || suffix == "_s1") _id = string_delete(_id, string_length(_id) - 2, 3);
    if (_id == "prepared_heartbeet_salad") return "prepared_heartbeet_chopped";
    if (_id == "prepared_icecarrot_pancake") return "prepared_icecarrot_shredded";
    return _id;
}

function cooking_recipe_ingredient_item_id(_recipe)
{
    farming_initialize();
    for (var i = 0; i < array_length(global.farming_rules.crops); i++)
        if (global.farming_rules.crops[i].product_id == _recipe.ingredient)
            return "crop_" + _recipe.ingredient + "_normal";
    var source_recipe = cooking_recipe(_recipe.ingredient);
    return is_undefined(source_recipe) ? "" : cooking_output_id(source_recipe, 0);
}

function cooking_register_items()
{
    cooking_initialize();
    for (var i = 0; i < array_length(global.cooking_recipes); i++)
    {
        var recipe = global.cooking_recipes[i];
        var final_dish = !cooking_recipe_is_ingredient(recipe.id);
        var item_id = cooking_output_id(recipe, 0);
        global.inventory_definitions[$ item_id] = {
            id: item_id, kind: final_dish ? "food" : "prepared", tab: "item",
            name: recipe.steps[0].name,
            sprite: recipe.sprite, sprite_frame: 0, colour: c_white,
            recipe_id: recipe.id, price: final_dish ? recipe.price : 0,
            effect_key: recipe.effect, effect_level: recipe.level,
            description: recipe.effect == " " ? recipe.name : recipe.effect + " LV" + string(recipe.level)
        };
    }
}

function cooking_is_open(_minutes)
{
    var hours = scr_cooking_hours(); var minute = _minutes mod 1440;
    return minute >= hours.open_hour * 60 && minute < hours.close_hour * 60;
}

function cooking_notice(_text)
{
    cooking_initialize(); global.cooking_state.notice = _text; global.cooking_state.notice_remaining = 3;
    if(instance_exists(obj_cooking_room))with(obj_cooking_room){inventory_error="";inventory_error_timer=0;}
}

function cooking_new_customer()
{
    cooking_initialize();
    var state = global.cooking_state; var customer_recipes = [];
    for (var i = 0; i < array_length(global.cooking_recipes); i++)
    {
        var candidate = global.cooking_recipes[i];
        if (!cooking_recipe_is_ingredient(candidate.id) && candidate.price > 0) array_push(customer_recipes, candidate);
    }
    var count = array_length(customer_recipes);
    if (count <= 0) return;
    var index = irandom(max(0, count - 1));
    if (count > 1 && customer_recipes[index].id == state.order_recipe) index = (index + 1) mod count;
    var recipe = customer_recipes[index];
    state.order_recipe = recipe.id; state.order_text = customer_dialogue_for_recipe(recipe.id);
    state.phase = "offer"; state.accepted = false; state.customer_number++;
    state.review_remaining = 0; state.review_text = "";
}

function cooking_accept_order()
{
    cooking_initialize(); var state = global.cooking_state;
    if (state.phase != "offer") return false;
    state.accepted = true; state.phase = "accepted"; return true;
}

function cooking_try_enter(_player, _building)
{
    cooking_initialize();
    if(room!=rm_main||_player.inventory_open||_building==noone||cooking_input_blocked())return false;
    var feet_y=_player.y+(sprite_get_bbox_bottom(_player.sprite_index)-sprite_get_yoffset(_player.sprite_index))*_player.image_yscale;
    if(!_building.player_at_door(_player.x,feet_y))return false;
    var controller = instance_find(obj_title_menu, 0);
    if (controller == noone || !cooking_is_open(controller.game_minutes))
    {
        cooking_notice("현재 영업 시간이 아닙니다. (18:00 개장)"); return false;
    }
    global.cooking_state.notice_remaining = 0;
    global.cooking_state.outside = { room_name: room_get_name(room), x: _player.x, y: _player.y };
    with (_player) inventory_close();
    if (global.cooking_state.phase == "none") cooking_new_customer();
    room_goto(rm_restaurant); return true;
}

function cooking_leave()
{
    cooking_initialize(); var point = global.cooking_state.outside;
    var hero=instance_find(obj_main_chr_girl,0);if(hero!=noone)with(hero)inventory_close();
    var destination = rm_main; var px = 1440; var py = 396;
    if (is_struct(point)) { destination = asset_get_index(point.room_name); px = point.x; py = point.y; }
    if (!room_exists(destination) || destination == rm_restaurant || destination == rm_kitchen) destination = rm_main;
    global.restaurant_return = { room_id: destination, x: px, y: py };
    room_goto(destination);
}

function cooking_match_input(_item, _station)
{
    if (is_undefined(_item)) return undefined;
    cooking_initialize();
    for (var i = 0; i < array_length(global.cooking_recipes); i++)
    {
        var recipe = global.cooking_recipes[i];
        if (_item.kind == "crop" && _item.base_crop_id == recipe.ingredient && recipe.steps[0].station == _station)
            return { recipe: recipe, step: 0 };
        if (_item.kind == "prepared" && _item.recipe_id == recipe.ingredient && recipe.steps[0].station == _station)
            return { recipe: recipe, step: 0 };
    }
    return undefined;
}

function cooking_start_station(_station_index, _item_id)
{
    cooking_initialize(); var stations = global.cooking_state.stations;
    if (_station_index < 0 || _station_index >= array_length(stations)) return false;
    var station = stations[_station_index];
    if (station.state != "empty") return false;
    var match = cooking_match_input(inventory_get_item(_item_id), station.kind);
    if (is_undefined(match)) return false;
    var item = inventory_get_item(_item_id);
    station.state = "cooking"; station.recipe_id = match.recipe.id; station.step = match.step;
    station.input_id = item.id; station.elapsed = 0;
    return true;
}

function cooking_drop_inventory(_slot_index, _expected_id, _station_index)
{
    if (_slot_index < 0 || _slot_index >= array_length(global.inventory_slots)) return false;
    var slot = global.inventory_slots[_slot_index];
    if (!is_struct(slot) || slot.id != _expected_id || slot.quantity < 1) return false;
    if (!cooking_start_station(_station_index, slot.id)) return false;
    slot.quantity--; if (slot.quantity <= 0) global.inventory_slots[_slot_index] = undefined;
    return true;
}

function cooking_station_item(_index)
{
    var station = global.cooking_state.stations[_index];
    var recipe = cooking_recipe(station.recipe_id);
    return is_undefined(recipe) ? undefined : inventory_get_item(cooking_output_id(recipe, station.step));
}

function cooking_transfer_station(_from, _to)
{
    if (_from == _to) return false;
    var stations = global.cooking_state.stations;
    if (_from < 0 || _from >= array_length(stations) || stations[_from].state != "ready") return false;
    var item = cooking_station_item(_from);
    if (is_undefined(item) || !cooking_start_station(_to, item.id)) return false;
    global.cooking_state.stations[_from] = cooking_empty_station(stations[_from].kind);
    return true;
}

function cooking_collect(_index)
{
    var stations = global.cooking_state.stations;
    if (_index < 0 || _index >= array_length(stations) || stations[_index].state != "ready") return false;
    var item = cooking_station_item(_index);
    if (is_undefined(item) || inventory_stack_add(item.id, 1) != 0) { cooking_notice("인벤토리가 가득 찼습니다. 칸을 비워 주세요."); return false; }
    inventory_notify_gain(item.id, 1); codex_discover(item.id);
    global.cooking_state.stations[_index] = cooking_empty_station(stations[_index].kind);
    return true;
}

function cooking_advance(_seconds)
{
    if (!variable_global_exists("cooking_state") || _seconds <= 0) return;
    var state = global.cooking_state;
    state.notice_remaining = max(0, state.notice_remaining - _seconds);
    if (state.phase == "review")
    {
        state.review_remaining -= _seconds;
        if (state.review_remaining <= 0) cooking_new_customer();
    }
    for (var i = 0; i < array_length(state.stations); i++)
    {
        var station = state.stations[i];
        if (station.state == "cooking")
        {
            var recipe = cooking_recipe(station.recipe_id);
            station.elapsed = min(recipe.steps[station.step].seconds, station.elapsed + _seconds);
            if (station.elapsed >= recipe.steps[station.step].seconds) station.state = "ready";
        }
    }
}

function cooking_has_food()
{
    for (var i = 0; i < array_length(global.inventory_slots); i++)
    {
        var slot = global.inventory_slots[i];
        if (is_struct(slot)) { var item = inventory_get_item(slot.id); if (!is_undefined(item) && item.kind == "food") return true; }
    }
    return false;
}

function cooking_order_matches(_item)
{
    if (is_undefined(_item) || _item.kind != "food") return false;
    var requested = cooking_recipe(global.cooking_state.order_recipe);
    if (is_undefined(requested)) return false;
    return _item.recipe_id == requested.id;
}

function cooking_serve(_slot_index, _expected_id)
{
    var state = global.cooking_state;
    if (state.phase != "accepted" || !state.accepted || _slot_index < 0 || _slot_index >= array_length(global.inventory_slots)) return false;
    var slot = global.inventory_slots[_slot_index];
    if (!is_struct(slot) || slot.id != _expected_id || slot.quantity < 1) return false;
    var item = inventory_get_item(slot.id);
    if (item.kind != "food") { cooking_notice("완성된 요리만 손님에게 건넬 수 있습니다."); return false; }
    var correct = cooking_order_matches(item);
    slot.quantity--; if (slot.quantity <= 0) global.inventory_slots[_slot_index] = undefined;
    state.phase = "review"; state.accepted = false; state.review_remaining = 1.8;
    if (correct)
    {
        var recipe = cooking_recipe(item.recipe_id);
        var reward = recipe.price;
        global.player_gold += reward;
        state.review_text = customer_dialogue_after_serving(true, reward);
    }
    else state.review_text = customer_dialogue_after_serving(false, 0);
    return true;
}

function cooking_snapshot() { cooking_initialize(); return global.cooking_state; }

function cooking_restore(_saved)
{
    cooking_reset();
    if (!is_struct(_saved)) return;
    var state = global.cooking_state;
    var order = variable_struct_get(_saved, "order_recipe");
    if (is_string(order) && !is_undefined(cooking_recipe(order)))
    {
        state.order_recipe = order;
        state.phase = variable_struct_get(_saved, "phase");
        if (!array_contains(["offer","accepted","review"], state.phase)) state.phase = "offer";
        state.accepted = state.phase == "accepted";
        var text = variable_struct_get(_saved, "order_text");
        state.order_text = is_string(text) ? text : customer_dialogue_for_recipe(order);
        var review = variable_struct_get(_saved, "review_text"); state.review_text = is_string(review) ? review : "";
        var remaining = variable_struct_get(_saved, "review_remaining");state.review_remaining = is_numeric(remaining) ? clamp(remaining,0,1.8) : 0;
    }
    var customer = variable_struct_get(_saved, "customer_number");state.customer_number = is_numeric(customer) ? max(0,floor(customer)) : 0;
    var outside = variable_struct_get(_saved, "outside");
    if (is_struct(outside))
    {
        var name = variable_struct_get(outside,"room_name"); var px=variable_struct_get(outside,"x");var py=variable_struct_get(outside,"y");
        if (is_string(name) && is_numeric(px) && is_numeric(py) && room_exists(asset_get_index(name)) && asset_get_index(name)==rm_main)
            state.outside={room_name:name,x:clamp(px,0,2560),y:clamp(py,0,1440)};
    }
    var table_saved=variable_struct_get(_saved,"table_items");
    if(is_array(table_saved))for(var i=0;i<min(60,array_length(table_saved));i++){
        var saved_item=table_saved[i];if(!is_struct(saved_item))continue;
        var item_id=variable_struct_get(saved_item,"id");var px=variable_struct_get(saved_item,"x");var py=variable_struct_get(saved_item,"y");
        if (is_string(item_id)) item_id = cooking_migrate_item_id(item_id);
        var definition=is_string(item_id)?inventory_get_item(item_id):undefined;
        if(!is_undefined(definition)&&array_contains(["crop","prepared","food"],definition.kind)&&is_numeric(px)&&is_numeric(py))
            array_push(state.table_items,{id:item_id,x:clamp(px,32,1112),y:clamp(py,286,438)});
    }
    var jobs = variable_struct_get(_saved,"stations");
    if (!is_array(jobs)) return;
    for (var i=0;i<min(array_length(jobs),array_length(state.stations));i++)
    {
        var job=jobs[i];if(!is_struct(job))continue;
        var saved_recipe_id=variable_struct_get(job,"recipe_id");
        var recipe=cooking_recipe(saved_recipe_id);
        if(is_undefined(recipe))continue;
        // Each recipe now has one step. Map old multi-step jobs to the new standalone prep recipes.
        if (recipe.id == "heartbeet_salad" && state.stations[i].kind == "board") recipe = cooking_recipe("heartbeet_chopped");
        else if (recipe.id == "icecarrot_pancake" && state.stations[i].kind == "board") recipe = cooking_recipe("icecarrot_shredded");
        if (is_undefined(recipe) || recipe.steps[0].station != state.stations[i].kind) continue;
        var status=variable_struct_get(job,"state");if(status!="cooking"&&status!="ready")continue;
        var elapsed=variable_struct_get(job,"elapsed");if(!is_numeric(elapsed))elapsed=0;
        var input_id = variable_struct_get(job,"input_id");
        if (is_string(input_id)) input_id = cooking_migrate_item_id(input_id);
        if (!is_string(input_id) || is_undefined(inventory_get_item(input_id))) input_id = cooking_recipe_ingredient_item_id(recipe);
        state.stations[i]={kind:state.stations[i].kind,state:status,recipe_id:recipe.id,step:0,input_id:input_id,
            elapsed:clamp(elapsed,0,recipe.steps[0].seconds)};
    }
}

function cooking_building_blocks(_left,_top,_right,_bottom)
{
    for(var i=0;i<instance_number(obj_restaurant);i++)
    {
        var building=instance_find(obj_restaurant,i);var a=building.restaurant_point(20,170);var b=building.restaurant_point(146,201);
        if(_left<=max(a.x,b.x)&&_right>=min(a.x,b.x)&&_top<=max(a.y,b.y)&&_bottom>=min(a.y,b.y))return true;
    }
    return false;
}
