/// F5 developer tools. Runtime switches are session-only; edited gameplay data uses normal saves.
function developer_initialize()
{
    if(!variable_global_exists("planted_crops"))global.planted_crops=[];
    if(variable_global_exists("developer"))return;
    global.developer={open:false,tab:0,surface:-1,edit:"",buffer:"",message:"",
        clock_rate:1,noclip:false,speed_override:-1,category:0,item_page:0,item_id:"",quantity:1,
        slot:0,tool_tier:0,recipe:0,fish:0,teleport_x:0,teleport_y:0};
}
function developer_hero(){return instance_find(obj_main_chr_girl,0);}
function developer_pointer()
{
    var scale=min(display_get_gui_width()/960,display_get_gui_height()/540);
    return {x:(device_mouse_x_to_gui(0)-(display_get_gui_width()-960*scale)/2)/scale,
        y:(device_mouse_y_to_gui(0)-(display_get_gui_height()-540*scale)/2)/scale};
}
function developer_hit(_p,_x,_y,_w,_h){return point_in_rectangle(_p.x,_p.y,_x,_y,_x+_w,_y+_h);}
function developer_items()
{
    inventory_initialize();var result=[];var keys=variable_struct_get_names(global.inventory_definitions);
    var kinds=["seed","tool","crop","prepared","food","fish","item"];
    var kind=kinds[global.developer.category];
    if(kind=="crop"){
        // Explicit display order: struct key enumeration is not ordered.
        var crop_order=["HeartBeet","Hellapeno","CloudPotato","IceCarrot","Magmato"];
        var quality_order=["normal","high"];
        for(var crop_index=0;crop_index<array_length(crop_order);crop_index++){
            for(var quality_index=0;quality_index<array_length(quality_order);quality_index++){
                var item_id="crop_"+crop_order[crop_index]+"_"+quality_order[quality_index];
                if(!is_undefined(inventory_get_item(item_id)))array_push(result,item_id);
            }
        }
        return result;
    }
    for(var i=0;i<array_length(keys);i++){
        var item=inventory_get_item(keys[i]);if(item.kind==kind)array_push(result,item.id);
    }return result;
}
function developer_refresh_shop()
{
    with(obj_market){market_catalog=market_stock_catalog();market_select(0);}
}
function developer_give(_item_id,_amount)
{
    var item=inventory_get_item(_item_id);if(is_undefined(item)){global.developer.message="지급할 아이템을 선택하세요.";return 0;}
    var added=0;
    if(item.kind=="tool"){
        var slot=inventory_tool_slot(item.tool_kind);if(slot==-1)slot=inventory_empty_slot();
        if(slot!=-1){global.inventory_slots[slot]=inventory_make_slot(item.id,1);added=1;
            for(var i=0;i<array_length(global.inventory_slots);i++){
                if(i==slot||!is_struct(global.inventory_slots[i]))continue;
                var other_item=inventory_get_item(global.inventory_slots[i].id);
                if(!is_undefined(other_item)&&other_item.kind=="tool"&&other_item.tool_kind==item.tool_kind)global.inventory_slots[i]=undefined;
            }
            if(item.tool_kind=="can")global.inventory_slots[slot].water=inventory_water_capacity(global.inventory_slots[slot]);
        }
    }else added=_amount-inventory_stack_add(_item_id,_amount);
    if(added>0){codex_discover(item.object_id,variable_struct_exists(item,"quality_id")?item.quality_id:"normal");inventory_notify_gain(_item_id,added);}
    global.developer.message=item.name+" "+string(added)+"개 지급"+(added<_amount&&item.kind!="tool"?" (가방 공간 부족)":"");
    developer_refresh_shop();return added;
}
function developer_number(_key)
{
    var d=global.developer;var c=instance_find(obj_title_menu,0);var h=developer_hero();
    switch(_key){
        case "gold":return global.player_gold;
        case "day":return floor(c.game_minutes/1440)+1;
        case "hour":return floor(c.game_minutes/60) mod 24;
        case "minute":return floor(c.game_minutes) mod 60;
        case "rate":return d.clock_rate;
        case "speed":return h!=noone?h.move_speed*game_get_speed(gamespeed_fps):(d.speed_override<0?70:d.speed_override);
        case "x":return d.teleport_x;case "y":return d.teleport_y;
        case "quantity":return d.quantity;case "slot":return d.slot+1;
        case "price":return cooking_recipe(global.cooking_recipes[d.recipe].id).price;
        case "duration":return global.cooking_recipes[d.recipe].steps[0].seconds;
    }return 0;
}
function developer_set_number(_key,_value)
{
    var d=global.developer;var c=instance_find(obj_title_menu,0);var h=developer_hero();
    switch(_key){
        case "gold":global.player_gold=clamp(floor(_value),0,999999999);break;
        case "day":c.game_minutes=(clamp(floor(_value),1,999998)-1)*1440+c.game_minutes mod 1440;break;
        case "hour":c.game_minutes=floor(c.game_minutes/1440)*1440+clamp(floor(_value),0,23)*60+floor(c.game_minutes) mod 60;break;
        case "minute":c.game_minutes=floor(c.game_minutes/60)*60+clamp(floor(_value),0,59);break;
        case "rate":d.clock_rate=clamp(_value,0,100);break;
        case "speed":d.speed_override=clamp(_value,1,1000);if(h!=noone)h.move_speed=d.speed_override/game_get_speed(gamespeed_fps);break;
        case "x":d.teleport_x=clamp(_value,0,99999);break;case "y":d.teleport_y=clamp(_value,0,99999);break;
        case "quantity":d.quantity=clamp(floor(_value),1,99);break;
        case "slot":d.slot=clamp(floor(_value)-1,0,array_length(global.inventory_slots)-1);break;
        case "price":global.cooking_recipes[d.recipe].price=clamp(floor(_value),0,999999);cooking_register_items();break;
        case "duration":global.cooking_recipes[d.recipe].steps[0].seconds=clamp(_value,0.1,3600);break;
    }
}
function developer_rows()
{
    var d=global.developer;var h=developer_hero();var rows=[];
    switch(d.tab){
        case 0:
            rows=[ ["골드", "gold", "number"],["날짜 (1일부터)","day","number"],
                ["시 (0~23)","hour","number"],["분 (0~59)","minute","number"],
                ["시간 배속 (0=정지)","rate","number"],["이동 속도 (px/초)","speed","number"],
                ["이동할 X 좌표","x","number"],["이동할 Y 좌표","y","number"],
                ["입력한 좌표로 이동","teleport","action"],["충돌 무시: "+(d.noclip?"켜짐":"꺼짐"),"noclip","action"],
                ["메인 필드로","main","action"],["상점으로","market","action"],
                ["식당으로 (시간 무시)","restaurant","action"],["주방으로 (주문 수락)","kitchen","action"],
                ["18:00으로 설정","evening","action"],["개발자 배속·이속·충돌 초기화","defaults","action"] ];break;
        case 2:
            rows=[["전체 작물 물주기","water_crops","action"],["전체 작물 즉시 성장","grow","action"],
                ["성장한 작물 모두 수확","harvest","action"],["게임 시간 +4시간 (성장 포함)","advance","action"],
                ["물뿌리개 물 최대 충전","refill","action"],["모든 씨앗 9개씩 지급","seeds","action"],
                ["전체 작물 일반 품질로 설정","crop_normal","action"],["전체 작물 고품질로 설정","crop_high","action"],
                ["주변 3x3 경작지 만들기","till","action"],["주변 3x3 젖은 경작지","wet","action"]];break;
        case 3:
            var recipe=global.cooking_recipes[d.recipe];
            rows=[["이전 요리","recipe_prev","action"],["다음 요리","recipe_next","action"],
                ["선택한 요리로 주문 지정","order","action"],["현재 주문 수락","accept","action"],
                ["선택 요리의 재료 9개 지급","ingredient","action"],["선택 요리 완성품 지급","dish","action"],
                ["모든 조리 즉시 완료","finish","action"],
                ["완료된 요리 모두 받기","collect","action"],["새 손님 부르기","customer","action"],
                ["선택 요리 판매 가격","price","number"],["첫 조리 단계 시간 (초)","duration","number"],
                ["현재 주문 정답 요리 지급","answer","action"],["현재 주문 정답 제출","serve","action"]];break;
        case 4:
            var entry=global.fishing_entries[d.fish];var status=h==noone?"없음":h.fishing.state;
            rows=[["이전 물고기","fish_prev","action"],["다음 물고기","fish_next","action"],
                ["선택 물고기 지급","fish_give","action"],["즉시 입질 (대기 중)","bite","action"],
                ["낚시 성공 (입력 도전 중)","catch","action"],["낚시 취소","cancel_fish","action"],
                ["나무 낚싯대 지급","rod","action"],["낚싯대 티타늄으로","rod_max","action"]];break;
    }return rows;
}
function developer_room(_destination)
{
    var h=developer_hero();if(h!=noone){with(h)inventory_close();if(fishing_busy(h))fishing_result(h,"개발자 이동",false);}
    if(room==rm_main&&h!=noone){
        global.cooking_state.outside={room_name:room_get_name(room),x:h.x,y:h.y};
        global.windmill_return={room_id:room,x:h.x,y:h.y};
    }
    if(_destination==rm_restaurant||_destination==rm_kitchen){
        if(global.cooking_state.phase=="none")cooking_new_customer();
        if(_destination==rm_kitchen){if(global.cooking_state.phase!="accepted")global.cooking_state.phase="offer";cooking_accept_order();}
    }
    if(_destination==rm_main&&room!=rm_main){
        var point=global.cooking_state.outside;
        global.restaurant_return={room_id:rm_main,x:is_struct(point)?point.x:1440,y:is_struct(point)?point.y:400};
    }
    global.developer.open=false;global.developer.edit="";room_goto(_destination);
}
function developer_action(_key)
{
    var d=global.developer;var c=instance_find(obj_title_menu,0);var h=developer_hero();
    var recipe=global.cooking_recipes[d.recipe];
    d.message="적용했습니다.";
    switch(_key){
        case "noclip":d.noclip=!d.noclip;if(!d.noclip&&room==rm_main&&h!=noone)terrain_keep_on_land(h);break;
        case "defaults":d.clock_rate=1;d.noclip=false;d.speed_override=-1;if(h!=noone){h.move_speed=70/game_get_speed(gamespeed_fps);if(room==rm_main)terrain_keep_on_land(h);}break;
        case "evening":developer_set_number("hour",18);developer_set_number("minute",0);break;
        case "teleport":if(room==rm_main&&h!=noone){h.x=clamp(d.teleport_x,16,room_width-16);h.y=clamp(d.teleport_y,32,room_height-16);if(!d.noclip)terrain_keep_on_land(h);h.depth=-round(h.y+(sprite_get_bbox_bottom(h.sprite_index)-sprite_get_yoffset(h.sprite_index))*h.image_yscale);}else d.message="좌표 이동은 메인 필드에서 가능합니다.";break;
        case "main":developer_room(rm_main);break;case "market":developer_room(rm_market);break;
        case "restaurant":developer_room(rm_restaurant);break;case "kitchen":developer_room(rm_kitchen);break;
        case "grow":for(var i=0;i<array_length(global.planted_crops);i++){var crop=global.planted_crops[i];crop.watered=true;crop.growth_minutes=farming_definition(crop.seed_id).growth_minutes;}break;
        case "water_crops":for(var i=0;i<array_length(global.planted_crops);i++)global.planted_crops[i].watered=true;break;
        case "harvest":var total=0;for(var i=array_length(global.planted_crops)-1;i>=0;i--)if(farming_harvest(i))total++;d.message=string(total)+"개 수확 (성장 및 가방 공간 필요)";break;
        case "advance":c.game_minutes+=240;farming_advance(240);break;
        case "refill":for(var i=0;i<array_length(global.inventory_slots);i++){var slot=global.inventory_slots[i];if(is_struct(slot)){var item=inventory_get_item(slot.id);if(item.kind=="tool"&&item.tool_kind=="can")slot.water=inventory_water_capacity(slot);}}break;
        case "seeds":var crops=global.farming_rules.crops;for(var i=0;i<array_length(crops);i++)developer_give(crops[i].seed_id,9);break;
        case "crop_normal":for(var i=0;i<array_length(global.planted_crops);i++)global.planted_crops[i].quality_roll=50;break;
        case "crop_high":for(var i=0;i<array_length(global.planted_crops);i++)global.planted_crops[i].quality_roll=99;break;
        case "till":case "wet":
            if(room==rm_main&&h!=noone&&h.terrain_tilemap!=-1){
                var map=h.terrain_tilemap;var tw=tilemap_get_tile_width(map);var th=tilemap_get_tile_height(map);
                var col=floor((h.x-tilemap_get_x(map))/tw);var row=floor((h.y+(sprite_get_bbox_bottom(h.sprite_index)-sprite_get_yoffset(h.sprite_index))*h.image_yscale-tilemap_get_y(map))/th);
                for(var xx=col-1;xx<=col+1;xx++)for(var yy=row-1;yy<=row+1;yy++){
                    if(xx<0||yy<0||xx>=tilemap_get_width(map)||yy>=tilemap_get_height(map))continue;
                    var family=terrain_family(tile_get_index(tilemap_get(map,xx,yy)));
                    if(array_contains([0,1,2,4,5],family))terrain_change_cell(map,xx,yy,_key=="wet"?246:198);
                }
            }else d.message="메인 필드에서 사용하세요.";break;
        case "recipe_prev":d.recipe=(d.recipe+array_length(global.cooking_recipes)-1) mod array_length(global.cooking_recipes);break;
        case "recipe_next":d.recipe=(d.recipe+1) mod array_length(global.cooking_recipes);break;
        case "order":global.cooking_state.order_recipe=recipe.id;global.cooking_state.order_text=customer_dialogue_for_recipe(recipe.id);global.cooking_state.phase="offer";global.cooking_state.accepted=false;global.cooking_state.review_remaining=0;break;
        case "accept":cooking_accept_order();break;
        case "ingredient":developer_give(cooking_recipe_ingredient_item_id(recipe),9);break;
        case "dish":developer_give(cooking_output_id(recipe,array_length(recipe.steps)-1),d.quantity);break;
        case "finish":for(var i=0;i<array_length(global.cooking_state.stations);i++){var job=global.cooking_state.stations[i];if(job.state=="cooking"){job.state="ready";var dish=cooking_recipe(job.recipe_id);job.elapsed=dish.steps[job.step].seconds;}}break;
        case "collect":for(var i=0;i<array_length(global.cooking_state.stations);i++)if(global.cooking_state.stations[i].state=="ready")cooking_collect(i);break;
        case "customer":cooking_new_customer();break;
        case "answer":case "serve":
            var answer=cooking_recipe(global.cooking_state.order_recipe);
            if(is_undefined(answer)){d.message="주문이 없습니다.";break;}
            var food_id=cooking_output_id(answer,array_length(answer.steps)-1);
            if(_key=="answer")developer_give(food_id,1);
            else {var found=-1;for(var i=0;i<array_length(global.inventory_slots);i++)if(is_struct(global.inventory_slots[i])&&cooking_order_matches(inventory_get_item(global.inventory_slots[i].id))){found=i;break;}
                if(found!=-1&&cooking_serve(found,global.inventory_slots[found].id))d.message="정답 요리를 제출했습니다.";else d.message="주문 수락과 정답 요리 보유가 필요합니다.";}break;
        case "fish_prev":d.fish=(d.fish+array_length(global.fishing_entries)-1) mod array_length(global.fishing_entries);break;
        case "fish_next":d.fish=(d.fish+1) mod array_length(global.fishing_entries);break;
        case "fish_give":developer_give(object_get_name(global.fishing_entries[d.fish].id),d.quantity);break;
        case "bite":if(h!=noone&&h.fishing.state=="waiting"){h.fishing.wait_remaining=0;fishing_start_challenge(h);}else d.message="찌를 던진 뒤 입질 대기 중 사용하세요.";break;
        case "catch":if(h!=noone&&h.fishing.state=="challenge"){h.fishing.key_index=array_length(h.fishing.sequence);fishing_complete(h);}else d.message="입질 후 입력 도전 중에 사용하세요.";break;
        case "cancel_fish":if(h!=noone)fishing_result(h,"낚시를 취소했습니다.",false);break;
        case "rod":developer_give("rod_wood",1);break;case "rod_max":developer_give("rod_titanium",1);break;
        case "give":developer_give(d.item_id,d.quantity);break;
        case "bag":var old=array_length(global.inventory_slots);if(old<45){array_resize(global.inventory_slots,45);for(var i=old;i<45;i++)global.inventory_slots[i]=undefined;}developer_refresh_shop();break;
        case "delete_slot":global.inventory_slots[d.slot]=undefined;developer_refresh_shop();break;
        case "select_slot":if(h!=noone)h.inventory_selected_slot=d.slot;break;
        case "tools":var tiers=["wood","copper","iron","gold","titanium"];var kinds=["hoe","can","shovel","sickle","rod"];for(var i=0;i<5;i++)developer_give(kinds[i]+"_"+tiers[d.tool_tier],1);break;
        case "tier":d.tool_tier=(d.tool_tier+1) mod 5;break;
        case "book":var keys=variable_struct_get_names(global.inventory_definitions);for(var i=0;i<array_length(keys);i++)codex_discover(inventory_get_item(keys[i]).object_id);break;
    }
}
function developer_commit()
{
    var d=global.developer;if(d.edit=="")return;
    var valid=string_length(d.buffer)>0&&string_count(".",d.buffer)<=1;
    for(var i=1;i<=string_length(d.buffer);i++)if(string_pos(string_char_at(d.buffer,i),"0123456789.")==0)valid=false;
    if(valid&&d.buffer!="."){developer_set_number(d.edit,real(d.buffer));d.message="적용했습니다.";}else d.message="올바른 숫자를 입력하세요.";
    d.edit="";
}
function developer_step(_controller)
{
    developer_initialize();var d=global.developer;
    if(keyboard_check_pressed(vk_f5)){
        if(d.open){developer_commit();d.open=false;}else{
            d.open=true;d.message="숫자 클릭 → 입력 → Enter 적용 / Esc 취소 / F5 닫기";
            var h=developer_hero();if(h!=noone){with(h)inventory_close();d.teleport_x=round(h.x);d.teleport_y=round(h.y);}
            with(obj_cooking_room)drag=undefined;
        }
        _controller.gameplay_input_blocked=true;return true;
    }
    if(!d.open)return false;
    _controller.gameplay_input_blocked=true;
    if(keyboard_check_pressed(vk_escape)){
        if(d.edit!="")d.edit="";else d.open=false;return true;
    }
    if(d.edit!=""){
        d.buffer=keyboard_string;
        if(keyboard_check_pressed(vk_enter))developer_commit();return true;
    }
    var point=developer_pointer();var click=mouse_check_button_pressed(mb_left);
    if(!click)return true;
    if(developer_hit(point,882,18,54,28)){d.open=false;return true;}
    for(var i=0;i<5;i++)if(developer_hit(point,24+i*184,60,176,32)){d.tab=i;return true;}
    if(d.tab==1){
        for(var i=0;i<7;i++)if(developer_hit(point,28+i*130,108,124,28)){d.category=i;d.item_page=0;d.item_id="";return true;}
        var items=developer_items();var pages=max(1,ceil(array_length(items)/9));d.item_page=clamp(d.item_page,0,pages-1);
        for(var i=0;i<9;i++)if(d.item_page*9+i<array_length(items)&&developer_hit(point,28,146+i*34,480,30)){d.item_id=items[d.item_page*9+i];return true;}
        if(developer_hit(point,28,458,90,28)){d.item_page=max(0,d.item_page-1);return true;}
        if(developer_hit(point,418,458,90,28)){d.item_page=min(pages-1,d.item_page+1);return true;}
        var controls=[["quantity",true],["give",false],["slot",true],["select_slot",false],["delete_slot",false],["bag",false],["tier",false],["tools",false],["refill",false],["book",false]];
        for(var i=0;i<array_length(controls);i++)if(developer_hit(point,530,146+i*34,400,30)){
            if(controls[i][1]){d.edit=controls[i][0];d.buffer=string(developer_number(d.edit));keyboard_string=d.buffer;}
            else developer_action(controls[i][0]);return true;
        }
    }else{
        var rows=developer_rows();var start_y=d.tab>=3?157:112;
        for(var i=0;i<array_length(rows);i++)if(developer_hit(point,28+(i mod 2)*458,start_y+(i div 2)*44,440,36)){
            var row=rows[i];if(row[2]=="number"){d.edit=row[1];d.buffer=string(developer_number(d.edit));keyboard_string=d.buffer;}
            else developer_action(row[1]);return true;
        }
    }return true;
}
function developer_button(_x,_y,_w,_h,_text,_selected)
{
    var point=developer_pointer();var hover=developer_hit(point,_x,_y,_w,_h);
    draw_set_color(_selected?make_color_rgb(212,168,85):make_color_rgb(108,83,56));draw_rectangle(_x,_y,_x+_w,_y+_h,false);
    draw_set_color(hover?make_color_rgb(60,85,53):make_color_rgb(40,33,28));draw_rectangle(_x+2,_y+2,_x+_w-2,_y+_h-2,false);
    draw_set_color(make_color_rgb(245,221,179));draw_set_halign(fa_left);draw_set_valign(fa_middle);draw_text(_x+10,_y+_h/2+3,_text);
}
function developer_draw()
{
    var d=global.developer;var c=instance_find(obj_title_menu,0);
    var colour=draw_get_color();var alpha=draw_get_alpha();var font=draw_get_font();var halign=draw_get_halign();var valign=draw_get_valign();var filter=gpu_get_texfilter();
    if(!surface_exists(d.surface))d.surface=surface_create(960,540);
    if(surface_set_target(d.surface)){
        gpu_set_texfilter(false);draw_set_alpha(1);draw_clear_alpha(make_color_rgb(24,24,22),1);draw_set_font(c.panel_font);
        draw_set_color(make_color_rgb(255,220,145));draw_set_halign(fa_left);draw_set_valign(fa_middle);
        draw_text(28,32,"개발자 모드 · F5 / ESC 닫기 · 게임 일시정지");
        developer_button(882,18,54,28,"닫기",false);
        var tabs=["세계 · 이동","아이템","농사","식당 · 조리","낚시"];
        for(var i=0;i<5;i++)developer_button(24+i*184,60,176,32,tabs[i],d.tab==i);
        if(d.tab==1){
            var kinds=["씨앗","농기구","수확 작물","손질 재료","완성 요리","물고기","기타"];
            for(var i=0;i<7;i++)developer_button(28+i*130,108,124,28,kinds[i],d.category==i);
            var items=developer_items();var pages=max(1,ceil(array_length(items)/9));d.item_page=clamp(d.item_page,0,pages-1);
            for(var i=0;i<9;i++)if(d.item_page*9+i<array_length(items)){
                var item=inventory_get_item(items[d.item_page*9+i]);developer_button(28,146+i*34,480,30,"     "+item.name,d.item_id==item.id);
                codex_draw_item(item,[34,147+i*34,62,175+i*34],true);
            }
            developer_button(28,458,90,28,"이전",false);developer_button(418,458,90,28,"다음",false);
            draw_set_halign(fa_center);draw_set_color(c_white);draw_text(268,475,string(d.item_page+1)+" / "+string(pages));
            var tiers=["나무","구리","철","금","티타늄"];
            var labels=["지급 수량: "+string(d.quantity),"선택 아이템 지급","슬롯 번호: "+string(d.slot+1),"해당 슬롯을 손에 선택","해당 슬롯 아이템 삭제","가방 45칸 해금","장비 단계: "+tiers[d.tool_tier],"모든 농기구를 선택 단계로 교체","물뿌리개 충전","도감 전체 발견 처리"];
            for(var i=0;i<array_length(labels);i++)developer_button(530,146+i*34,400,30,labels[i],false);
        }else{
            if(d.tab==3){draw_set_color(c_white);draw_set_halign(fa_left);draw_text(30,120,"선택 요리: "+global.cooking_recipes[d.recipe].name+" / 주문: "+global.cooking_state.phase);}
            if(d.tab==4){var entry=global.fishing_entries[d.fish];var h=developer_hero();draw_set_color(c_white);draw_set_halign(fa_left);draw_text(30,120,"선택: "+entry.name+" / "+string(entry.tier)+"티어 / 상태: "+(h==noone?"없음":h.fishing.state));}
            var rows=developer_rows();var start_y=d.tab>=3?157:112;
            for(var i=0;i<array_length(rows);i++){var row=rows[i];developer_button(28+(i mod 2)*458,start_y+(i div 2)*44,440,36,row[0]+(row[2]=="number"?": "+string(developer_number(row[1])):""),false);}
        }
        draw_set_color(make_color_rgb(202,180,143));draw_set_halign(fa_left);draw_set_valign(fa_middle);draw_text_ext(28,514,d.message,14,902);
        if(d.edit!=""){
            draw_set_alpha(0.85);draw_set_color(c_black);draw_rectangle(0,0,960,540,false);draw_set_alpha(1);
            developer_button(230,205,500,110,"숫자 입력: "+d.buffer+"_",true);draw_text(245,292,"Enter 적용 / Esc 취소 (Backspace로 지우기)");
        }
        surface_reset_target();
    }
    var scale=min(display_get_gui_width()/960,display_get_gui_height()/540);
    draw_set_alpha(1);draw_set_color(c_white);gpu_set_texfilter(false);draw_surface_stretched(d.surface,(display_get_gui_width()-960*scale)/2,(display_get_gui_height()-540*scale)/2,960*scale,540*scale);
    draw_set_color(colour);draw_set_alpha(alpha);draw_set_font(font);draw_set_halign(halign);draw_set_valign(valign);gpu_set_texfilter(filter);
}
