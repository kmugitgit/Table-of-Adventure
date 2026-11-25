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

function cooking_ui_inventory_at(_ui,_point)
{
    var panel=cooking_ui_inventory_layout();
    for(var row=0;row<panel.rows;row++)for(var col=0;col<9;col++)
    {
        var left=240+col*54;var top=panel.top+10+row*panel.step;
        var index=(_ui.inventory_scroll_row+row)*9+col;
        if(index<array_length(global.inventory_slots)&&cooking_ui_hit(_point,[left,top,left+44,top+panel.slot_height]))return index;
    }
    return -1;
}

function cooking_ui_station_bounds(_ui,_index)
{
    var entry=scr_cooking_station_entries()[_index];
    var left=48+entry.display_order*224-_ui.counter_scroll;
    return [left,98,left+176,218];
}

function cooking_ui_station_at(_ui,_point)
{
    if(!cooking_ui_hit(_point,[24,94,936,222]))return -1;
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

// Measure and wrap at character boundaries, including Korean words without spaces.
// Use the regular Galmuri font at its native size; never shrink Korean labels to the quantity font.
function cooking_ui_label_measure(_text,_max_width)
{
    var lines=[];var line="";var width=0;
    for(var i=1;i<=string_length(_text);i++){
        var ch=string_char_at(_text,i);
        if(ch=="\n"){array_push(lines,line);width=max(width,string_width(line));line="";continue;}
        if(line!=""&&string_width(line+ch)>_max_width-12){
            array_push(lines,line);width=max(width,string_width(line));line="";
        }
        line+=ch;
    }
    array_push(lines,line);width=max(width,string_width(line));
    var step=ceil(string_height("가"))+2;
    return {lines:lines,width:min(_max_width,ceil(width)+12),height:array_length(lines)*step+8,step:step};
}
function cooking_ui_label(_text,_cx,_top,_max_width,_bounds)
{
    var label=cooking_ui_label_measure(_text,_max_width);
    var left=round(clamp(_cx-label.width/2,_bounds[0],_bounds[2]-label.width));
    var top=round(clamp(_top,_bounds[1],_bounds[3]-label.height));
    draw_set_color(make_color_rgb(18,14,11));draw_rectangle(left+2,top+2,left+label.width+2,top+label.height+2,false);
    draw_set_color(make_color_rgb(175,132,77));draw_rectangle(left,top,left+label.width,top+label.height,false);
    draw_set_color(make_color_rgb(40,29,21));draw_rectangle(left+1,top+1,left+label.width-1,top+label.height-1,false);
    draw_set_color(make_color_rgb(255,233,190));draw_set_halign(fa_left);draw_set_valign(fa_top);
    for(var i=0;i<array_length(label.lines);i++)draw_text(left+6,top+4+i*label.step,label.lines[i]);
    return {left:left,top:top,right:left+label.width,bottom:top+label.height};
}

function cooking_ui_inventory(_ui,_point)
{
    var panel=cooking_ui_inventory_layout();
    draw_set_color(make_color_rgb(27,21,17));draw_rectangle(16,panel.top,944,534,false);
    draw_set_color(make_color_rgb(122,84,48));draw_rectangle(18,panel.top+2,942,532,true);
    draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_color(make_color_rgb(238,213,171));
    draw_text(30,panel.top+6,"인벤토리 · Tab");
    // The collapsed bar has room for one short instruction, not a wrapped paragraph.
    var help=panel.rows==1?"재료 드래그":(room==rm_kitchen?"재료를 조리 기구로\n드래그하세요.":"완성된 음식을 손님에게\n드래그하세요.");
    if(_ui.inventory_name!=""){
        if(panel.rows==1)cooking_ui_label(_ui.inventory_name,166,panel.top-48,284,[24,262,936,panel.top-6]);
        else cooking_ui_label(_ui.inventory_name,124,panel.top+32,188,[24,panel.top+28,222,528]);
    }else{
        var saved_scissor=gpu_get_scissor();gpu_set_scissor(24,panel.top+28,198,502-panel.top);
        draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_color(make_color_rgb(238,213,171));
        draw_text_ext(30,panel.top+28,help,-1,188);gpu_set_scissor(saved_scissor);
    }
    var hover=cooking_input_blocked()?-1:cooking_ui_inventory_at(_ui,_point);
    var hero=instance_find(obj_main_chr_girl,0);
    for(var row=0;row<panel.rows;row++)for(var col=0;col<9;col++)
    {
        var index=(_ui.inventory_scroll_row+row)*9+col;if(index>=array_length(global.inventory_slots))continue;
        var left=240+col*54;var top=panel.top+10+row*panel.step;var selected=hero!=noone&&hero.inventory_selected_slot==index;
        draw_set_color(selected?make_color_rgb(238,190,100):make_color_rgb(109,77,46));draw_rectangle(left,top,left+44,top+panel.slot_height,false);
        draw_set_color(index==hover?make_color_rgb(68,96,50):make_color_rgb(43,32,25));draw_rectangle(left+2,top+2,left+42,top+panel.slot_height-2,false);
        var slot=global.inventory_slots[index];
        if(is_struct(slot))
        {
            var item=inventory_get_item(slot.id);
            var preview=is_struct(_ui.drag)&&_ui.drag.moved&&_ui.drag.kind=="inventory"&&_ui.drag.source==index;
            var shown=slot.quantity-(preview?1:0);
            if(shown>0)codex_draw_item(item,[left+3,top+1,left+42,top+panel.slot_height-3],true);
            if(shown>1){draw_set_halign(fa_right);draw_set_valign(fa_bottom);draw_set_color(make_color_rgb(252,229,185));draw_text(left+41,top+panel.slot_height,string(shown));}
        }
    }
    var rows=ceil(array_length(global.inventory_slots)/9);
    if(room==rm_kitchen||panel.rows==1)return;
    cooking_ui_button([766,442,810,478],"<",_ui.inventory_scroll_row>0,_point);
    cooking_ui_button([868,442,912,478],">",_ui.inventory_scroll_row<max(0,rows-2),_point);
    draw_set_halign(fa_center);draw_set_valign(fa_middle);draw_set_color(make_color_rgb(229,199,150));
    draw_text(840,499,string(_ui.inventory_scroll_row+1)+"~"+string(min(rows,_ui.inventory_scroll_row+2))+" / "+string(rows));
}

// Appliance imagery comes only from user-editable sprite resources.
function cooking_ui_draw_device(_entry,_cx,_cy)
{
    if(!sprite_exists(_entry.sprite))return;
    var scale=min(148/sprite_get_width(_entry.sprite),56/sprite_get_height(_entry.sprite))*_entry.image_scale;
    draw_sprite_ext(_entry.sprite,_entry.sprite_frame,
        _cx+_entry.offset_x+(sprite_get_xoffset(_entry.sprite)-sprite_get_width(_entry.sprite)/2)*scale,
        _cy+_entry.offset_y+(sprite_get_yoffset(_entry.sprite)-sprite_get_height(_entry.sprite)/2)*scale,
        scale,scale,0,c_white,1);
}

function cooking_ui_station(_ui,_index,_point)
{
    var station=global.cooking_state.stations[_index];var bounds=cooking_ui_station_bounds(_ui,_index);
    var hover=!cooking_input_blocked()&&cooking_ui_station_at(_ui,_point)==_index;
    draw_set_color(hover?make_color_rgb(178,135,72):make_color_rgb(110,76,45));draw_rectangle(bounds[0],bounds[1],bounds[2],bounds[3],false);
    draw_set_color(make_color_rgb(119,84,49));draw_rectangle(bounds[0]+3,bounds[1]+3,bounds[2]-3,bounds[3]-3,false);
    var entries=scr_cooking_station_entries();draw_set_halign(fa_center);draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(247,222,176));draw_text((bounds[0]+bounds[2])/2,112,entries[_index].name);
    var cx=(bounds[0]+bounds[2])/2;cooking_ui_draw_device(entries[_index],cx,152);
    if(station.state!="empty")
    {
        var recipe=cooking_recipe(station.recipe_id);var item=cooking_station_item(_index);
        if(!(is_struct(_ui.drag)&&_ui.drag.moved&&_ui.drag.kind=="station"&&_ui.drag.source==_index))
            codex_draw_item(item,[cx-16,136,cx+16,168],true);
        var fraction=station.state=="ready"?1:station.elapsed/recipe.steps[station.step].seconds;
        draw_set_color(make_color_rgb(43,31,24));draw_rectangle(bounds[0]+12,196,bounds[2]-12,202,false);
        draw_set_color(station.state=="ready"?make_color_rgb(227,185,87):make_color_rgb(113,164,89));
        draw_rectangle(bounds[0]+13,197,bounds[0]+13+(bounds[2]-bounds[0]-26)*fraction,201,false);
        draw_set_color(make_color_rgb(251,224,178));draw_set_halign(fa_center);draw_set_valign(fa_middle);draw_text(cx,184,item.name);
        var instruction=station.state=="cooking"?"조리 중...":(item.kind=="prepared"&&!recipe.steps[station.step].auto_collect?"접시로 드래그":"클릭하여 받기");
        draw_text(cx,211,instruction);
    }
    else{draw_set_color(make_color_rgb(226,199,152));draw_text(cx,205,"재료를 드래그하세요");}
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
        draw_set_halign(fa_left);draw_set_valign(fa_middle);draw_set_color(make_color_rgb(245,220,173));draw_text(162,36,"주방");
        draw_set_valign(fa_top);draw_text_ext(24,72,state.order_text,16,650);
        if(cooking_has_food())cooking_ui_button([550,20,718,50],"식당으로",true,point);
        var panel=cooking_ui_inventory_layout();
        draw_set_color(make_color_rgb(111,77,45));draw_rectangle(16,230,944,panel.top-4,false);
        draw_set_color(make_color_rgb(151,106,62));draw_rectangle(20,234,940,panel.top-8,true);
        draw_set_color(make_color_rgb(91,62,38));
        for(var grain=0;grain<11;grain++){
            var gx=grain*120-_ui.counter_scroll;
            if(gx>20&&gx<940)draw_line(gx,235,gx,panel.top-9);
        }
        draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_color(make_color_rgb(238,210,163));
        draw_text(30,240,"R 도감 · 작업대의 빈 곳을 잡고 좌우로 드래그");
        var scissor=gpu_get_scissor();gpu_set_scissor(24,94,912,128);
        for(var i=0;i<array_length(state.stations);i++)cooking_ui_station(_ui,i,point);
        gpu_set_scissor(24,262,912,max(1,panel.top-266));
        for(var i=0;i<array_length(state.table_items);i++){
            if(is_struct(_ui.drag)&&_ui.drag.moved&&_ui.drag.kind=="table"&&_ui.drag.source==i)continue;
            var table_item=state.table_items[i];var tx=table_item.x-_ui.counter_scroll;
            codex_draw_item(inventory_get_item(table_item.id),[tx-24,table_item.y-24,tx+24,table_item.y+24],true);

        }
        gpu_set_scissor(scissor);
        var selected=_ui.table_selected;
        if(selected>=0&&selected<array_length(state.table_items)){
            var selected_item=state.table_items[selected];var tx=selected_item.x-_ui.counter_scroll;
            var dragging=is_struct(_ui.drag)&&_ui.drag.moved&&_ui.drag.kind=="table"&&_ui.drag.source==selected;
            if(!dragging&&tx>=24&&tx<=936&&selected_item.y>=262&&selected_item.y<panel.top-8){
                draw_set_font(hero.inventory_font);
                cooking_ui_label(inventory_get_item(selected_item.id).name,tx,selected_item.y+27,260,[24,262,936,panel.top-10]);
            }
        }
        var thumb=912*912/1144;var offset=(912-thumb)*_ui.counter_scroll/232;
        draw_set_color(make_color_rgb(50,35,24));draw_rectangle(24,224,936,228,false);
        draw_set_color(make_color_rgb(191,145,78));draw_rectangle(24+offset,224,24+offset+thumb,228,false);
    }
    cooking_ui_inventory(_ui,point);
    if(state.notice_remaining>0)
    {
        draw_set_halign(fa_center);draw_set_valign(fa_middle);draw_set_color(make_color_rgb(255,223,152));
        draw_text(480,room==rm_kitchen?96:365,state.notice);
    }
    if(is_struct(_ui.drag)&&_ui.drag.moved&&!cooking_input_blocked())
    {
        var item=inventory_get_item(_ui.drag.id);if(!is_undefined(item))codex_draw_item(item,[point.x-22,point.y-22,point.x+22,point.y+22],true);
    }
}

function cooking_ui_inventory_layout()
{
    var hero=instance_find(obj_main_chr_girl,0);
    var expanded=room!=rm_kitchen||(hero!=noone&&hero.inventory_open);
    if(room!=rm_kitchen)return {top:422,rows:2,step:48,slot_height:42};
    var rows=expanded?ceil(array_length(global.inventory_slots)/9):1;
    return {top:expanded?534-(rows*36+10):478,rows:rows,step:expanded?36:48,slot_height:expanded?32:42};
}
function cooking_ui_table_at(_ui,_point)
{
    var panel=cooking_ui_inventory_layout();if(!cooking_ui_hit(_point,[24,262,936,panel.top-8]))return -1;
    var items=global.cooking_state.table_items;
    for(var i=array_length(items)-1;i>=0;i--)if(point_distance(_point.x+_ui.counter_scroll,_point.y,items[i].x,items[i].y)<25)return i;
    return -1;
}
function cooking_ui_table_drop(_ui,_drag,_point)
{
    var panel=cooking_ui_inventory_layout();if(!cooking_ui_hit(_point,[24,262,936,panel.top-8]))return false;
    var item=inventory_get_item(_drag.id);if(is_undefined(item)||!array_contains(["crop","prepared","food"],item.kind))return false;
    var px=clamp(_point.x+_ui.counter_scroll,48,1096);var py=clamp(_point.y,286,min(438,panel.top-36));
    if(_drag.kind=="table"){
        global.cooking_state.table_items[_drag.source].x=px;global.cooking_state.table_items[_drag.source].y=py;return true;
    }
    if(array_length(global.cooking_state.table_items)>=60)return false;
    if(_drag.kind=="inventory"){
        var slot=global.inventory_slots[_drag.source];if(!is_struct(slot)||slot.id!=_drag.id||slot.quantity<1)return false;
        slot.quantity--;if(slot.quantity==0)global.inventory_slots[_drag.source]=undefined;
    }else if(_drag.kind=="station"){
        var job=global.cooking_state.stations[_drag.source];if(job.state!="ready")return false;
        global.cooking_state.stations[_drag.source]=cooking_empty_station(job.kind);
    }else return false;
    array_push(global.cooking_state.table_items,{id:item.id,x:px,y:py});return true;
}
function cooking_ui_step(_ui)
{
    if(cooking_input_blocked()){_ui.drag=undefined;_ui.table_drag=undefined;return;}
    cooking_initialize();var point=cooking_ui_pointer();var state=global.cooking_state;var hero=instance_find(obj_main_chr_girl,0);
    if(room==rm_restaurant&&state.phase=="none")cooking_new_customer();
    if(room==rm_kitchen&&keyboard_check_pressed(vk_tab)){
        if(hero.inventory_open)with(hero)inventory_close();else hero.inventory_open=true;
        _ui.drag=undefined;_ui.table_drag=undefined;_ui.inventory_scroll_row=0;
    }
    var panel=cooking_ui_inventory_layout();var wheel=mouse_wheel_down()-mouse_wheel_up();var rows=ceil(array_length(global.inventory_slots)/9);
    if(room==rm_kitchen||panel.rows==1)_ui.inventory_scroll_row=0;
    if(room!=rm_kitchen&&point.y>=panel.top&&panel.rows>1)_ui.inventory_scroll_row=clamp(_ui.inventory_scroll_row+wheel,0,max(0,rows-2));
    else if(room==rm_kitchen&&point.y<panel.top)_ui.counter_scroll=clamp(_ui.counter_scroll+wheel*64,0,232);
    if(room==rm_kitchen&&!is_struct(_ui.drag)){
        var move=(keyboard_check_pressed(ord("D"))||keyboard_check_pressed(vk_right))-(keyboard_check_pressed(ord("A"))||keyboard_check_pressed(vk_left));
        _ui.counter_scroll=clamp(_ui.counter_scroll+move*116,0,232);
    }
    if(mouse_check_button_pressed(mb_right)){_ui.drag=undefined;_ui.table_drag=undefined;return;}
    if(is_struct(_ui.table_drag)){
        _ui.counter_scroll=clamp(_ui.table_drag.scroll+_ui.table_drag.x-point.x,0,232);
        if(mouse_check_button_released(mb_left))_ui.table_drag=undefined;
        return;
    }
    if(mouse_check_button_pressed(mb_left)){
        if(cooking_ui_hit(point,room==rm_kitchen?[24,20,136,50]:[24,380,168,414])){_ui.drag=undefined;cooking_leave();return;}
        if(room!=rm_kitchen&&panel.rows>1&&cooking_ui_hit(point,[766,442,810,478])){_ui.inventory_scroll_row=max(0,_ui.inventory_scroll_row-1);return;}
        if(room!=rm_kitchen&&panel.rows>1&&cooking_ui_hit(point,[868,442,912,478])){_ui.inventory_scroll_row=min(max(0,rows-2),_ui.inventory_scroll_row+1);return;}
        if(room==rm_restaurant){
            if(state.phase=="offer"&&cooking_ui_hit(point,[370,286,590,328])){cooking_accept_order();return;}
            if(state.accepted&&state.phase=="accepted"&&cooking_ui_hit(point,[768,380,936,414])){room_goto(rm_kitchen);return;}
        }else if(cooking_has_food()&&cooking_ui_hit(point,[550,20,718,50])){room_goto(rm_restaurant);return;}
        var slot_index=cooking_ui_inventory_at(_ui,point);
        if(slot_index!=-1&&is_struct(global.inventory_slots[slot_index])){
            _ui.drag={kind:"inventory",source:slot_index,id:global.inventory_slots[slot_index].id,start_x:point.x,start_y:point.y,moved:false};
            hero.inventory_selected_slot=slot_index;
            _ui.inventory_name=inventory_get_item(global.inventory_slots[slot_index].id).name;
        }else if(room==rm_kitchen){
            var station=cooking_ui_station_at(_ui,point);var table_index=cooking_ui_table_at(_ui,point);
            if(station!=-1&&state.stations[station].state=="ready")_ui.drag={kind:"station",source:station,id:cooking_station_item(station).id,start_x:point.x,start_y:point.y,moved:false};
            else if(table_index!=-1){
                _ui.table_selected=table_index;
                _ui.drag={kind:"table",source:table_index,id:state.table_items[table_index].id,start_x:point.x,start_y:point.y,moved:false};
            }
            else if(cooking_ui_hit(point,[24,230,936,panel.top-8]))_ui.table_drag={x:point.x,scroll:_ui.counter_scroll};
        }
    }
    if(is_struct(_ui.drag)){
        if(point_distance(point.x,point.y,_ui.drag.start_x,_ui.drag.start_y)>3)_ui.drag.moved=true;
        if(mouse_check_button_released(mb_left)){
            var drag=_ui.drag;_ui.drag=undefined;
            if(room==rm_kitchen){
                var station=cooking_ui_station_at(_ui,point);var success=false;
                if(drag.kind=="inventory"&&station!=-1)success=cooking_drop_inventory(drag.source,drag.id,station);
                else if(drag.kind=="station"){
                    if(station!=-1&&station!=drag.source)success=cooking_transfer_station(drag.source,station);
                    else if(!drag.moved){var job=state.stations[drag.source];var recipe=cooking_recipe(job.recipe_id);
                        if(job.step==array_length(recipe.steps)-1||recipe.steps[job.step].auto_collect)success=cooking_collect(drag.source);}
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
                if(!success&&drag.moved)cooking_notice("이 재료를 놓을 수 없는 곳입니다.");
            }else if(drag.kind=="inventory"&&cooking_ui_hit(point,[250,280,710,354]))cooking_serve(drag.source,drag.id);
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
