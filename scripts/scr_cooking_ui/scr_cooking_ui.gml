/// Shared native 960x540 restaurant/kitchen UI; the counter scrolls horizontally.
function cooking_input_blocked()
{
    return instance_exists(obj_title_menu) && obj_title_menu.gameplay_input_blocked;
}

function cooking_ui_layout()
{
    var scale=min(display_get_gui_width()/960,display_get_gui_height()/540);
    return {scale:scale,left:(display_get_gui_width()-960*scale)/2,top:(display_get_gui_height()-540*scale)/2};
}

function cooking_ui_pointer()
{
    var layout=cooking_ui_layout();
    return {x:(device_mouse_x_to_gui(0)-layout.left)/layout.scale,y:(device_mouse_y_to_gui(0)-layout.top)/layout.scale};
}

function cooking_ui_hit(_point,_bounds)
{
    return point_in_rectangle(_point.x,_point.y,_bounds[0],_bounds[1],_bounds[2],_bounds[3]);
}

function cooking_ui_inventory_at(_point)
{
    if(room!=rm_kitchen&&room!=rm_restaurant)return -1;
    var hero=instance_find(obj_main_chr_girl,0);if(hero==noone)return -1;
    var outer=cooking_ui_layout();var inv=hero.inventory_layout();
    for(var row=0;row<inv.rows;row++)for(var col=0;col<hero.inventory_columns;col++){
        var left=(inv.x+(hero.inventory_padding+col*hero.inventory_slot_step)*inv.scale-outer.left)/outer.scale;
        var top=(inv.y+hero.inventory_row_top(row,inv.first_top)*inv.scale-outer.top)/outer.scale;
        var size=hero.inventory_slot_size*inv.scale/outer.scale;
        var index=row*hero.inventory_columns+col;
        if(index<array_length(global.inventory_slots)&&cooking_ui_hit(_point,[left,top,left+size,top+size]))return index;
    }
    return -1;
}

function cooking_ui_station_bounds(_ui,_index)
{
    var entry=scr_cooking_station_entries()[_index];
    var left=48+entry.display_order*224-_ui.counter_scroll;
    return [left,118,left+176,238];
}

function cooking_ui_station_at(_ui,_point)
{
    if(!cooking_ui_hit(_point,[24,114,936,242]))return -1;
    for(var i=0;i<5;i++)if(cooking_ui_hit(_point,cooking_ui_station_bounds(_ui,i)))return i;
    return -1;
}

function cooking_ui_button(_bounds,_label,_enabled,_point)
{
    var hover=_enabled&&!cooking_input_blocked()&&cooking_ui_hit(_point,_bounds);
    draw_set_color(_enabled?make_color_rgb(174,124,67):make_color_rgb(78,65,50));
    draw_rectangle(_bounds[0],_bounds[1],_bounds[2],_bounds[3],false);
    draw_set_color(hover?make_color_rgb(79,104,55):make_color_rgb(60,44,30));
    draw_rectangle(_bounds[0]+2,_bounds[1]+2,_bounds[2]-2,_bounds[3]-2,false);
    draw_set_color(_enabled?make_color_rgb(248,222,177):make_color_rgb(132,121,102));
    draw_set_halign(fa_center);draw_set_valign(fa_middle);
    draw_text((_bounds[0]+_bounds[2])/2,(_bounds[1]+_bounds[3])/2+3,_label);
}

// Appliance imagery comes only from user-editable sprite resources.
function cooking_ui_draw_device(_entry,_cx,_cy,_frame_override=-1)
{
    if(!sprite_exists(_entry.sprite))return;
    var scale=min(148/sprite_get_width(_entry.sprite),56/sprite_get_height(_entry.sprite))*_entry.image_scale;
    var frame=_frame_override>=0?_frame_override:_entry.sprite_frame;
    frame=clamp(frame,0,sprite_get_number(_entry.sprite)-1);
    draw_sprite_ext(_entry.sprite,frame,
        _cx+_entry.offset_x+(sprite_get_xoffset(_entry.sprite)-sprite_get_width(_entry.sprite)/2)*scale,
        _cy+_entry.offset_y+(sprite_get_yoffset(_entry.sprite)-sprite_get_height(_entry.sprite)/2)*scale,
        scale,scale,0,c_white,1);
}

function cooking_ui_station(_ui,_index,_point)
{
    var station=global.cooking_state.stations[_index];var bounds=cooking_ui_station_bounds(_ui,_index);
    var entries=scr_cooking_station_entries();draw_set_halign(fa_center);draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(247,222,176));draw_text((bounds[0]+bounds[2])/2,106,entries[_index].name);
    var cx=(bounds[0]+bounds[2])/2;
    var device_frame=entries[_index].sprite_frame;
    if(entries[_index].id=="board")
        device_frame=station.state=="cooking"?floor(current_time/100) mod 9:6;
    cooking_ui_draw_device(entries[_index],cx,172,device_frame);
    if(station.state!="empty")
    {
        var recipe=cooking_recipe(station.recipe_id);var item=cooking_station_item(_index);
        if(!(is_struct(_ui.drag)&&_ui.drag.moved&&_ui.drag.kind=="station"&&_ui.drag.source==_index))
            codex_draw_item(item,[cx-40,130,cx+40,210],true);
        var fraction=station.state=="ready"?1:station.elapsed/recipe.steps[station.step].seconds;
        draw_set_color(make_color_rgb(251,224,178));draw_set_halign(fa_center);draw_set_valign(fa_middle);draw_text(cx,221,item.name);
        draw_set_color(make_color_rgb(43,31,24));draw_rectangle(bounds[0]+12,231,bounds[2]-12,238,false);
        draw_set_color(station.state=="ready"?make_color_rgb(113,164,89):make_color_rgb(227,185,87));
        draw_rectangle(bounds[0]+13,232,bounds[0]+13+(bounds[2]-bounds[0]-26)*fraction,237,false);
    }
}

function cooking_ui_draw(_ui)
{
    cooking_initialize();var point=cooking_ui_pointer();var state=global.cooking_state;
    var hero=instance_find(obj_main_chr_girl,0);if(hero==noone)return;
    draw_set_font(hero.inventory_font);draw_set_alpha(1);gpu_set_texfilter(false);
    if(room==rm_restaurant)
    {
        draw_clear_alpha(c_black,1);draw_set_halign(fa_center);draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(210,184,138));draw_text(480,118,"손님 "+string(state.customer_number)+" · 주문");
        draw_set_color(make_color_rgb(249,235,209));
        var text=state.phase=="review"?state.review_text:state.order_text;
        draw_text_ext_transformed(480,166,text,18,350,2,2,0);
        if(state.phase=="offer")cooking_ui_button([370,286,590,328],"주문 수락",true,point);
        if(state.phase=="accepted")
        {
            draw_set_color(make_color_rgb(80,65,43));draw_rectangle(250,280,710,354,true);
            draw_set_color(make_color_rgb(211,185,141));draw_text(480,320,"완성된 음식을 이곳에 드래그해 주세요");
        }
        cooking_ui_button([768,380,936,414],"주방으로",state.accepted&&state.phase=="accepted",point);
        cooking_ui_button([24,380,168,414],"밖으로",true,point);
    }
    else
    {
        draw_clear_alpha(make_color_rgb(41,37,29),1);
        cooking_ui_button([24,20,136,50],"밖으로",true,point);
        draw_set_halign(fa_left);draw_set_valign(fa_middle);draw_set_color(make_color_rgb(245,220,173));draw_text(300,36,"주방");
        cooking_ui_button([148,20,284,50],"식당으로",true,point);
        var table_bottom=520;
        draw_set_color(make_color_rgb(111,77,45));draw_rectangle(16,110,944,table_bottom,false);
        draw_set_color(make_color_rgb(151,106,62));draw_rectangle(20,114,940,table_bottom-4,true);
        draw_set_color(make_color_rgb(91,62,38));
        for(var grain=0;grain<11;grain++){
            var gx=grain*120-_ui.counter_scroll;
            if(gx>20&&gx<940)draw_line(gx,115,gx,table_bottom-5);
        }
        draw_set_halign(fa_left);draw_set_valign(fa_bottom);draw_set_color(make_color_rgb(238,210,163));
        draw_text_transformed(30,510,"테이블을 잡고 좌우로 드래그",0.78,0.78,0);
        var scissor=gpu_get_scissor();gpu_set_scissor(24,70,912,240);
        for(var i=0;i<array_length(state.stations);i++)cooking_ui_station(_ui,i,point);
        gpu_set_scissor(24,280,912,table_bottom-280);
        for(var i=0;i<array_length(state.table_items);i++){
            if(is_struct(_ui.drag)&&_ui.drag.kind=="table"&&_ui.drag.source==i
                &&(_ui.drag.moved||mouse_check_button(mb_left)))continue;
            var table_item=state.table_items[i];var tx=table_item.x-_ui.counter_scroll;
            codex_draw_item(inventory_get_item(table_item.id),[tx-48,table_item.y-48,tx+48,table_item.y+48],true);

        }
        gpu_set_scissor(scissor);
    }
    if(state.notice_remaining>0)
    {
        draw_set_halign(fa_center);draw_set_valign(fa_middle);draw_set_color(make_color_rgb(255,223,152));
        draw_text(480,room==rm_kitchen?96:365,state.notice);
    }
    if(room==rm_kitchen&&_ui.inventory_error_timer>0){
        draw_set_halign(fa_center);draw_set_valign(fa_middle);draw_set_font(hero.inventory_font);
        draw_set_color(c_black);draw_text(481,68,_ui.inventory_error);
        draw_set_color(make_color_rgb(255,72,62));draw_text(480,67,_ui.inventory_error);
    }
    if(room!=rm_kitchen&&room!=rm_restaurant&&is_struct(_ui.drag)&&_ui.drag.moved&&!cooking_input_blocked())
    {
        var item=inventory_get_item(_ui.drag.id);if(!is_undefined(item))codex_draw_item(item,[point.x-22,point.y-22,point.x+22,point.y+22],true);
    }
}

function cooking_ui_inventory_layout()
{
    var hero=instance_find(obj_main_chr_girl,0);
    if(hero==noone)return {top:0};
    var outer=cooking_ui_layout();var inv=hero.inventory_layout();
    return {top:(inv.y-outer.top)/outer.scale};
}
function cooking_ui_inventory_contains(_point)
{
    if(room!=rm_kitchen&&room!=rm_restaurant)return false;
    var hero=instance_find(obj_main_chr_girl,0);if(hero==noone)return false;
    var outer=cooking_ui_layout();var inv=hero.inventory_layout();
    var left=(inv.x-outer.left)/outer.scale;var top=(inv.y-outer.top)/outer.scale;
    var right=(inv.x+inv.width*inv.scale-outer.left)/outer.scale;
    var bottom=(inv.y+inv.height*inv.scale-outer.top)/outer.scale;
    return cooking_ui_hit(_point,[left,top,right,bottom]);
}
function cooking_ui_hotbar_scrollbar_bounds()
{
    var hero=instance_find(obj_main_chr_girl,0);
    if(hero==noone||hero.inventory_open)return [0,0,0,0];
    var outer=cooking_ui_layout();var inv=hero.inventory_layout();
    var gui_left=outer.left+24*outer.scale;
    var gui_right=outer.left+936*outer.scale;
    var gui_top=inv.y+(inv.height+2)*inv.scale;
    var gui_bottom=gui_top+5*inv.scale;
    return [(gui_left-outer.left)/outer.scale,(gui_top-outer.top)/outer.scale,
        (gui_right-outer.left)/outer.scale,(gui_bottom-outer.top)/outer.scale];
}
function cooking_ui_table_at(_ui,_point)
{
    if(!cooking_ui_hit(_point,[24,280,936,512])||cooking_ui_inventory_contains(_point))return -1;
    var items=global.cooking_state.table_items;
    for(var i=array_length(items)-1;i>=0;i--)if(point_distance(_point.x+_ui.counter_scroll,_point.y,items[i].x,items[i].y)<50)return i;
    return -1;
}
function cooking_ui_table_drop(_ui,_drag,_point)
{
    if(!cooking_ui_hit(_point,[24,280,936,512])||cooking_ui_inventory_contains(_point))return false;
    var item=inventory_get_item(_drag.id);if(is_undefined(item)||!array_contains(["crop","prepared","food"],item.kind))return false;
    var offset_x=variable_struct_exists(_drag,"offset_x")?_drag.offset_x:0;
    var offset_y=variable_struct_exists(_drag,"offset_y")?_drag.offset_y:0;
    var px=clamp(_point.x+_ui.counter_scroll+offset_x,48,1096);var py=clamp(_point.y+offset_y,310,472);
    if(_drag.kind=="table"){
        global.cooking_state.table_items[_drag.source].x=px;global.cooking_state.table_items[_drag.source].y=py;return true;
    }
    if(array_length(global.cooking_state.table_items)>=60)return false;
    if(_drag.kind=="station"){
        var job=global.cooking_state.stations[_drag.source];if(job.state=="empty")return false;
        global.cooking_state.stations[_drag.source]=cooking_empty_station(job.kind);
    }else return false;
    array_push(global.cooking_state.table_items,{id:item.id,x:px,y:py});return true;
}
function cooking_ui_table_store_inventory(_ui,_table_index,_slot_index)
{
    var items=global.cooking_state.table_items;
    if(_table_index<0||_table_index>=array_length(items)||_slot_index<0||_slot_index>=array_length(global.inventory_slots))return false;
    var table_item=items[_table_index];var target=global.inventory_slots[_slot_index];
    var definition=inventory_get_item(table_item.id);if(is_undefined(definition))return false;
    if(!is_struct(target)){
        global.inventory_slots[_slot_index]=inventory_make_slot(table_item.id,1);array_delete(items,_table_index,1);
        inventory_notify_gain(table_item.id,1);return true;
    }
    if(target.id==table_item.id&&inventory_item_stackable(definition)&&target.quantity<99){
        target.quantity++;array_delete(items,_table_index,1);inventory_notify_gain(table_item.id,1);return true;
    }
    if(target.quantity==1){
        var gained_id=table_item.id;
        global.inventory_slots[_slot_index]=inventory_make_slot(gained_id,1);table_item.id=target.id;
        inventory_notify_gain(gained_id,1);return true;
    }
    return false;
}
// Transfer a ready station output directly into the exact inventory slot under the cursor.
// Do not clear the station until placement succeeds; rejected drops leave both sides intact.
function cooking_ui_station_store_inventory(_station_index,_slot_index,_expected_id)
{
    var stations=global.cooking_state.stations;
    if(_station_index<0||_station_index>=array_length(stations)||_slot_index<0||_slot_index>=array_length(global.inventory_slots))return false;
    var job=stations[_station_index];if(job.state!="ready")return false;
    var item=cooking_station_item(_station_index);
    if(is_undefined(item)||item.id!=_expected_id)return false;
    var target=global.inventory_slots[_slot_index];
    if(!is_struct(target))global.inventory_slots[_slot_index]=inventory_make_slot(item.id,1);
    else if(target.id==item.id&&inventory_item_stackable(item)&&target.quantity<99)target.quantity++;
    else return false;
    global.cooking_state.stations[_station_index]=cooking_empty_station(job.kind);
    inventory_notify_gain(item.id,1);
    return true;
}
function cooking_ui_step(_ui)
{
    if(cooking_input_blocked()){_ui.drag=undefined;_ui.table_drag=undefined;return;}
    cooking_initialize();var point=cooking_ui_pointer();var state=global.cooking_state;var hero=instance_find(obj_main_chr_girl,0);
    _ui.inventory_error_timer=max(0,_ui.inventory_error_timer-delta_time/1000000);
    if(room==rm_restaurant&&state.phase=="none")cooking_new_customer();
    // Inventory owns wheel input. The counter pans only via a left-button tabletop drag.
    if(mouse_check_button_pressed(mb_right)){_ui.drag=undefined;_ui.table_drag=undefined;return;}
    if(room==rm_restaurant&&mouse_check_button_released(mb_left)
        &&state.accepted&&state.phase=="accepted"&&is_struct(hero.inventory_held_stack)
        &&cooking_ui_hit(point,[250,280,710,354])){
        var served_id=hero.inventory_held_stack.id;
        var served_item=inventory_get_item(served_id);
        if(!is_undefined(served_item)&&served_item.kind=="food"){
            var source=hero.inventory_held_source;
            if(source>=0&&source<array_length(global.inventory_slots)&&inventory_hold_left(hero,source))
                cooking_serve(source,served_id);
        }else cooking_notice("완성된 요리만 손님에게 건넬 수 있습니다.");
        return;
    }
    // The player inventory picks up an item on mouse press. Place it only on release,
    // otherwise that same click is seen by both Step events and immediately cancels pickup.
    if(room==rm_kitchen&&mouse_check_button_released(mb_left)&&is_struct(hero.inventory_held_stack)
        &&cooking_ui_inventory_at(point)==-1&&!cooking_ui_inventory_contains(point)
        &&!cooking_ui_hit(point,cooking_ui_hotbar_scrollbar_bounds())){
        _ui.drag=undefined;_ui.table_drag=undefined;
        var held=hero.inventory_held_stack;var held_item=inventory_get_item(held.id);
        if(!is_undefined(held_item)&&array_contains(["crop","prepared","food"],held_item.kind)){
            var target_station=cooking_ui_station_at(_ui,point);
            if(target_station!=-1){
                if(cooking_start_station(target_station,held.id)){
                    held.quantity--;if(held.quantity<=0){hero.inventory_held_stack=undefined;hero.inventory_held_source=-1;}
                    return;
                }
                state.notice_remaining=0;_ui.inventory_error="이 재료는 이 조리기구에 사용할 수 없습니다.";_ui.inventory_error_timer=2.5;
                return;
            }
            if(array_length(state.table_items)>=60){cooking_notice("작업대가 가득 찼습니다.");return;}
            var place_x=point.x+_ui.counter_scroll;var place_y=point.y;
            if(!cooking_ui_hit(point,[24,280,936,512])){place_x=480+_ui.counter_scroll;place_y=390;}
            array_push(state.table_items,{id:held.id,x:clamp(place_x,48,1096),y:clamp(place_y,310,472)});
            _ui.table_selected=array_length(state.table_items)-1;
            held.quantity--;if(held.quantity<=0){hero.inventory_held_stack=undefined;hero.inventory_held_source=-1;}
        }else{
            var source=hero.inventory_held_source;
            if(!inventory_hold_left(hero,source)){
                var remaining=inventory_stack_add(held.id,held.quantity);held.quantity=remaining;
                if(remaining<=0){hero.inventory_held_stack=undefined;hero.inventory_held_source=-1;}
            }
        global.cooking_state.notice_remaining=0;
        _ui.inventory_error="테이블에 놓을 수 없는 아이템입니다.";_ui.inventory_error_timer=2.5;
        }
        return;
    }
    if(is_struct(_ui.table_drag)){
        var drag_delta=_ui.table_drag.x-point.x;
        if(variable_struct_exists(_ui.table_drag,"kind")&&_ui.table_drag.kind=="scrollbar")
            drag_delta*=232/max(1,_ui.table_drag.travel);
        _ui.counter_scroll=clamp(_ui.table_drag.scroll+drag_delta,0,232);
        if(mouse_check_button_released(mb_left))_ui.table_drag=undefined;
        return;
    }
    if(mouse_check_button_pressed(mb_left)){
        if(cooking_ui_hit(point,room==rm_kitchen?[24,20,136,50]:[24,380,168,414])){_ui.drag=undefined;cooking_leave();return;}
        if(room==rm_restaurant){
            if(state.phase=="offer"&&cooking_ui_hit(point,[370,286,590,328])){cooking_accept_order();return;}
            if(state.accepted&&state.phase=="accepted"&&cooking_ui_hit(point,[768,380,936,414])){with(hero)inventory_close();room_goto(rm_kitchen);return;}
        }else if(room==rm_kitchen&&cooking_ui_hit(point,[148,20,284,50])){with(hero)inventory_close();room_goto(rm_restaurant);return;}
        if(room==rm_kitchen&&!is_struct(hero.inventory_held_stack)){
            if(!hero.inventory_open){
                var hotbar_bar=cooking_ui_hotbar_scrollbar_bounds();
                if(cooking_ui_hit(point,hotbar_bar)){
                    _ui.table_drag={kind:"scrollbar",x:point.x,scroll:_ui.counter_scroll,
                        travel:(hotbar_bar[2]-hotbar_bar[0])*(1-912/1144)};
                    return;
                }
            }
            var station=cooking_ui_station_at(_ui,point);var table_index=cooking_ui_table_at(_ui,point);
            if(station!=-1&&state.stations[station].state!="empty"){
                var station_job=state.stations[station];var station_item=cooking_station_item(station);
                if(station_job.state=="cooking"){
                    var input_id=station_job.input_id;
                    if (!is_string(input_id) || is_undefined(inventory_get_item(input_id)))
                        input_id=cooking_recipe_ingredient_item_id(cooking_recipe(station_job.recipe_id));
                    station_item=inventory_get_item(input_id);
                }
                _ui.drag={kind:"station",source:station,id:station_item.id,start_x:point.x,start_y:point.y,moved:false};
            }
            else if(table_index!=-1){
                // Array order is the table's draw order; move the picked item to the end
                // so overlapping items render with the one being picked on top.
                var picked_item=state.table_items[table_index];
                array_delete(state.table_items,table_index,1);
                array_push(state.table_items,picked_item);
                table_index=array_length(state.table_items)-1;
                _ui.table_selected=table_index;
                var held_table_item=state.table_items[table_index];
                _ui.drag={kind:"table",source:table_index,id:held_table_item.id,start_x:point.x,start_y:point.y,moved:false,
                    offset_x:held_table_item.x-(point.x+_ui.counter_scroll),offset_y:held_table_item.y-point.y};
            }
            else if(cooking_ui_hit(point,[24,280,936,512])&&!cooking_ui_inventory_contains(point))_ui.table_drag={x:point.x,scroll:_ui.counter_scroll};
        }
    }
    if(is_struct(_ui.drag)){
        if(point_distance(point.x,point.y,_ui.drag.start_x,_ui.drag.start_y)>3)_ui.drag.moved=true;
        if(mouse_check_button_released(mb_left)){
            var drag=_ui.drag;_ui.drag=undefined;
            if(room==rm_kitchen){
                var station=cooking_ui_station_at(_ui,point);var success=false;
                var target_slot=cooking_ui_inventory_at(point);
                if(drag.kind=="table"&&target_slot!=-1)success=cooking_ui_table_store_inventory(_ui,drag.source,target_slot);
                else if(drag.kind=="station"){
                    if(target_slot!=-1)success=cooking_ui_station_store_inventory(drag.source,target_slot,drag.id);
                    else if(station!=-1&&station!=drag.source)success=cooking_transfer_station(drag.source,station);
                }else if(drag.kind=="table"){
                    if(station!=-1&&cooking_start_station(station,drag.id)){array_delete(global.cooking_state.table_items,drag.source,1);success=true;}

                    else if(!drag.moved){
                        var double_click=_ui.table_last_click==drag.source&&current_time-_ui.table_last_click_time<=350;
                        if(double_click){
                            if(inventory_stack_add(drag.id,1)==0){array_delete(global.cooking_state.table_items,drag.source,1);success=true;}
                            else cooking_notice("인벤토리가 가득 찼습니다.");
                            _ui.table_last_click=-1;_ui.table_last_click_time=-1000;
                        }else{_ui.table_last_click=drag.source;_ui.table_last_click_time=current_time;}
                    }
                }
                if(!success&&drag.moved)success=cooking_ui_table_drop(_ui,drag,point);
                if(drag.moved){_ui.table_last_click=-1;_ui.table_last_click_time=-1000;}
                if(success&&drag.kind=="table")_ui.table_selected=-1;
                if(!success&&drag.moved){state.notice_remaining=0;_ui.inventory_error="이 재료를 놓을 수 없는 곳입니다.";_ui.inventory_error_timer=2.5;}
            }
        }
    }
}

function cooking_draw_exterior_hint(_player)
{
    if(room!=rm_main)return;
    var building=instance_nearest(_player.x,_player.y,obj_restaurant);
    var feet_y=_player.y+(sprite_get_bbox_bottom(_player.sprite_index)-sprite_get_yoffset(_player.sprite_index))*_player.image_yscale;
    if(building==noone||_player.inventory_open||cooking_input_blocked())return;
    var camera=view_camera[0];if(camera==-1)return;
    var sx=display_get_gui_width()/camera_get_view_width(camera);var sy=display_get_gui_height()/camera_get_view_height(camera);
    var old_colour=draw_get_color();var old_alpha=draw_get_alpha();var old_font=draw_get_font();var old_h=draw_get_halign();var old_v=draw_get_valign();var old_filter=gpu_get_texfilter();
    gpu_set_texfilter(false);draw_set_alpha(1);draw_set_font(_player.inventory_font);
    if(building.player_at_door(_player.x,feet_y))
    {
        var point=building.restaurant_point(80,180);
        var left=round((point.x-camera_get_view_x(camera))*sx);var top=round((point.y-camera_get_view_y(camera))*sy);
        var pixels=55;draw_set_color(make_color_rgb(49,35,24));draw_rectangle(left,top,left+pixels,top+pixels,false);
        draw_set_color(make_color_rgb(250,222,163));draw_rectangle(left,top,left+pixels,top+pixels,true);
        draw_set_halign(fa_left);draw_set_valign(fa_top);
        draw_text_transformed(left+_player.interaction_key_x,top+_player.interaction_key_y,"F",_player.interaction_key_scale,_player.interaction_key_scale,0);
    }
    if(global.cooking_state.notice_remaining>0)
    {
        var scale=max(1,floor(min(display_get_gui_width()/960,display_get_gui_height()/540)));
        var cx=round((_player.x-camera_get_view_x(camera))*sx);var top=round((_player.y-sprite_get_yoffset(_player.sprite_index)*_player.image_yscale-camera_get_view_y(camera))*sy)-22*scale;
        draw_set_halign(fa_center);draw_set_valign(fa_middle);draw_set_color(make_color_rgb(255,221,170));
        draw_text_transformed(cx,top,global.cooking_state.notice,scale,scale,0);
    }
    gpu_set_texfilter(old_filter);draw_set_color(old_colour);draw_set_alpha(old_alpha);draw_set_font(old_font);draw_set_halign(old_h);draw_set_valign(old_v);
}
