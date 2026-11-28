/// 요리 설정. id와 ingredient는 완성 아이템 오브젝트를 가리킵니다.
/// 출력 아이콘은 id 오브젝트의 스프라이트에서 자동으로 가져옵니다.
function scr_cooking_entries()
{
    return [
        {
            id: obj_HeartBeet_chopped,
            name: "잘린 하트비트",
            ingredient: obj_HeartBeet,
            effect: " ",
            level: 0,
            price: 0,
            steps: [
                {
                    station: "board",
                    seconds: 4
                }
            ]
        },
        {
            id: obj_HeartBeet_shredded,
            name: "채 썬 하트비트",
            ingredient: obj_HeartBeet_chopped,
            effect: " ",
            level: 0,
            price: 0,
            steps: [
                {
                    station: "board",
                    seconds: 4
                }
            ]
        },
        {
            id: obj_HeartBeet_salad,
            name: "하트비트 샐러드",
            ingredient: obj_HeartBeet_chopped,
            effect: " ",
            level: 1,
            price: 90,
            steps: [
                {
                    station: "plate",
                    seconds: 3
                }
            ]
        },
        {
            id: obj_HeartBeet_pancake,
            name: "하트비트 전",
            ingredient: obj_HeartBeet_shredded,
            effect: " ",
            level: 1,
            price: 90,
            steps: [
                {
                    station: "pan",
                    seconds: 5
                }
            ]
        },
        {
            id: obj_HeartBeet_soup,
            name: "하트비트 수프",
            ingredient: obj_HeartBeet,
            effect: " ",
            level: 1,
            price: 60,
            steps: [
                {
                    station: "pot",
                    seconds: 5
                }
            ]
        },
        {
            id: obj_hellapeno_sauce,
            name: "헬라피뇨 핫소스",
            ingredient: obj_Hellapeno,
            effect: " ",
            level: 1,
            price: 55,
            steps: [
                {
                    station: "mortar",
                    seconds: 4
                }
            ]
        },
        {
            id: obj_cloudpotato_soup,
            name: "구름감자 수프",
            ingredient: obj_CloudPotato,
            effect: " ",
            level: 1,
            price: 65,
            steps: [
                {
                    station: "pot",
                    seconds: 5
                }
            ]
        },
        {
            id: obj_magmato_soup,
            name: "마그마토 수프",
            ingredient: obj_Magmato,
            effect: " ",
            level: 2,
            price: 80,
            steps: [
                {
                    station: "pot",
                    seconds: 6
                }
            ]
        },
        {
            id: obj_icecarrot_shredded,
            name: "채 썬 얼음당근",
            ingredient: obj_IceCarrot,
            effect: " ",
            level: 0,
            price: 0,
            steps: [
                {
                    station: "board",
                    seconds: 4
                }
            ]
        },
        {
            id: obj_icecarrot_pancake,
            name: "얼음당근 전",
            ingredient: obj_icecarrot_shredded,
            effect: " ",
            level: 1,
            price: 110,
            steps: [
                {
                    station: "pan",
                    seconds: 5
                }
            ]
        }
    ];
}

function scr_cooking_station_entries()
{
    return [
        {
            id: "board",
            name: "도마",
            sprite: spr_kitchen_board,
            sprite_frame: 6,
            display_order: 1,
            image_scale: 3,
            offset_x: 0,
            offset_y: 0
        },
        {
            id: "pot",
            name: "냄비",
            sprite: spr_kitchen_pot,
            sprite_frame: 0,
            display_order: 4,
            image_scale: 3,
            offset_x: 0,
            offset_y: 0
        },
        {
            id: "mortar",
            name: "절구",
            sprite: spr_kitchen_mortar,
            sprite_frame: 0,
            display_order: 2,
            image_scale: 3,
            offset_x: 0,
            offset_y: 0
        },
        {
            id: "pan",
            name: "후라이팬",
            sprite: spr_kitchen_pan,
            sprite_frame: 0,
            display_order: 3,
            image_scale: 3,
            offset_x: 0,
            offset_y: 0
        },
        {
            id: "plate",
            name: "접시",
            sprite: spr_kitchen_plate,
            sprite_frame: 0,
            display_order: 0,
            image_scale: 3,
            offset_x: 0,
            offset_y: 0
        }
    ];
}

function scr_cooking_hours()
{
    return {
        open_hour: 18,
        close_hour: 24
    };
}
