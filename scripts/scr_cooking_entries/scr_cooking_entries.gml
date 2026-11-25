/// Cooking catalog. Keep IDs stable for saved food/orders/stations.
// station: board / pot / mortar / pan / plate. Times below are REAL seconds.
// The first step accepts the ingredient crop; later steps accept the previous output.
// Completed station items stay on the station until dragged out.
// Editing sprite replaces the temporary HeartBeet artwork for that recipe's outputs.
function scr_cooking_entries()
{
    return [
        { 
			id: "heartbeet_salad",
			name: "하트비트 샐러드",
			ingredient: "HeartBeet",
			sprite: spr_HeartBeet,
			effect: "health_regen",
			effect_name: "체력 회복 증진",
			level: 1, temperature: "cold",
			dish_type: "salad",
			price: 90,
			orders: ["체력 회복에 좋은 차가운 음식을 주세요.", "지친 몸을 회복할 수 있는 시원한 샐러드가 먹고 싶어요."],
			steps: [ { station: "board", seconds: 4, name: "잘린 하트비트", auto_collect: false },
                   { station: "plate", seconds: 3, name: "하트비트 샐러드", auto_collect: false } ] },
        { id: "heartbeet_soup", name: "하트비트 수프", ingredient: "HeartBeet", sprite: spr_HeartBeet,
          effect: "health_regen", effect_name: "체력 회복 증진", level: 1, temperature: "warm", dish_type: "soup", price: 60,
          orders: ["체력 회복에 좋은 따뜻한 음식을 주세요.", "기운을 되찾을 수 있는 따뜻한 수프를 부탁해요."],
          steps: [ { station: "pot", seconds: 5, name: "하트비트 수프", auto_collect: false } ] },
        { id: "hellapeno_sauce", name: "헬라피뇨 핫소스", ingredient: "Hellapeno", sprite: spr_Hellapeno,
          effect: "fire_resist", effect_name: "화염 저항", level: 1, temperature: "cold", dish_type: "sauce", price: 55,
          orders: ["화염 저항에 도움이 되는 매콤한 소스를 주세요.", "약한 불길을 견딜 수 있게 해주는 소스가 필요해요."],
          steps: [ { station: "mortar", seconds: 4, name: "헬라피뇨 핫소스", auto_collect: false } ] },
        { id: "cloudpotato_soup", name: "구름감자 수프", ingredient: "CloudPotato", sprite: spr_CloudPotato,
          effect: "move_speed", effect_name: "이동속도 증가", level: 1, temperature: "warm", dish_type: "soup", price: 65,
          orders: ["발걸음이 빨라지는 따뜻한 음식을 부탁해요.", "긴 여행길을 더 빠르게 걸을 수 있는 수프가 먹고 싶어요."],
          steps: [ { station: "pot", seconds: 5, name: "구름감자 수프", auto_collect: false } ] },
        { id: "magmato_soup", name: "마그마토 수프", ingredient: "Magmato", sprite: spr_Magmato,
          effect: "fire_resist", effect_name: "화염 저항", level: 2, temperature: "warm", dish_type: "soup", price: 80,
          orders: ["강한 불길도 견딜 수 있는 따뜻한 음식을 주세요.", "화염 저항이 강한 2단계 수프를 부탁해요."],
          steps: [ { station: "pot", seconds: 6, name: "마그마토 수프", auto_collect: false } ] },
        { id: "icecarrot_pancake", name: "얼음당근전", ingredient: "IceCarrot", sprite: spr_IceCarrot,
          effect: "freeze_resist", effect_name: "빙결 저항", level: 1, temperature: "warm", dish_type: "pancake", price: 110,
          orders: ["추위를 견디게 해주는 따뜻한 전을 부탁해요.", "빙결 저항에 도움이 되는 바삭한 전이 먹고 싶어요."],
          steps: [ { station: "board", seconds: 4, name: "채 썬 얼음당근", auto_collect: false },
                   { station: "pan", seconds: 5, name: "얼음당근전", auto_collect: false } ] }
    ];
}

function scr_cooking_station_entries()
{
    // Keep this array's ID order stable: saved cooking stations use these indices.
    // display_order controls only the visual order. Edit/import images in these sprites.
    // sprite_frame selects a frame; image_scale and offset_x/y adjust the image inside its slot.
    return [
        { id:"board", name:"도마", sprite:spr_kitchen_board, sprite_frame:0, display_order:1, image_scale:1, offset_x:0, offset_y:0 },
        { id:"pot", name:"냄비", sprite:spr_kitchen_pot, sprite_frame:0, display_order:4, image_scale:1, offset_x:0, offset_y:0 },
        { id:"mortar", name:"절구", sprite:spr_kitchen_mortar, sprite_frame:0, display_order:2, image_scale:1, offset_x:0, offset_y:0 },
        { id:"pan", name:"후라이팬", sprite:spr_kitchen_pan, sprite_frame:0, display_order:3, image_scale:1, offset_x:0, offset_y:0 },
        { id:"plate", name:"접시", sprite:spr_kitchen_plate, sprite_frame:0, display_order:0, image_scale:1, offset_x:0, offset_y:0 }
    ];
}

function scr_cooking_hours() { return { open_hour: 18, close_hour: 24 }; }
