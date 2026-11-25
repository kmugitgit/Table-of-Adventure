/// Cooking catalog. Keep IDs stable for saved food/orders/stations.
// station: board / pot / mortar / pan / plate. Times below are REAL seconds.
// Every recipe has one processing step. Intermediate recipes become ingredients for later recipes.
// Completed station items stay on the station until dragged out.
// Editing sprite replaces the temporary HeartBeet artwork for that recipe's outputs.
function scr_cooking_entries()
{
    return [
        { id: "heartbeet_chopped", name: "잘린 하트비트", ingredient: "HeartBeet", sprite: spr_HeartBeet,
          effect: " ", level: 0, price: 0,
          steps: [ { station: "board", seconds: 4, name: "잘린 하트비트" } ] },
        { id: "heartbeet_salad", name: "하트비트 샐러드", ingredient: "heartbeet_chopped", sprite: spr_HeartBeet,
          effect: " ", level: 1, price: 90,
          steps: [ { station: "plate", seconds: 3, name: "하트비트 샐러드" } ] },
        { id: "heartbeet_soup", name: "하트비트 수프", ingredient: "HeartBeet", sprite: spr_HeartBeet,
          effect: " ", level: 1, price: 60,
          steps: [ { station: "pot", seconds: 5, name: "하트비트 수프" } ] },
        { id: "hellapeno_sauce", name: "헬라피뇨 핫소스", ingredient: "Hellapeno", sprite: spr_Hellapeno,
          effect: " ", level: 1, price: 55,
          steps: [ { station: "mortar", seconds: 4, name: "헬라피뇨 핫소스" } ] },
        { id: "cloudpotato_soup", name: "구름감자 수프", ingredient: "CloudPotato", sprite: spr_CloudPotato,
          effect: " ", level: 1, price: 65,
          steps: [ { station: "pot", seconds: 5, name: "구름감자 수프" } ] },
        { id: "magmato_soup", name: "마그마토 수프", ingredient: "Magmato", sprite: spr_Magmato,
          effect: " ", level: 2, price: 80,
          steps: [ { station: "pot", seconds: 6, name: "마그마토 수프" } ] },
        { id: "icecarrot_shredded", name: "채 썬 얼음당근", ingredient: "IceCarrot", sprite: spr_IceCarrot,
          effect: " ", level: 0, price: 0,
          steps: [ { station: "board", seconds: 4, name: "채 썬 얼음당근" } ] },
        { id: "icecarrot_pancake", name: "얼음당근 전", ingredient: "icecarrot_shredded", sprite: spr_IceCarrot,
          effect: " ", level: 1, price: 110,
          steps: [ { station: "pan", seconds: 5, name: "얼음당근전" } ] }
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
