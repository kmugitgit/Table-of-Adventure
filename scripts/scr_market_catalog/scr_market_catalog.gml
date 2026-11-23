/// 상점 품목 설정
// market_item(이름, 스프라이트, 설명, 가격, 기본 아이콘, 기본 아이콘 색상)
// 이미지에 사용할 PNG를 스프라이트로 가져온 뒤 noone을 에셋 이름(예: spr_seed_potato)으로 바꾸세요.
// 지정한 스프라이트의 첫 프레임을 표시합니다. noone이면 기본 아이콘을 사용합니다. 설명에 \n을 넣으면 원하는 곳에서 줄을 바꿀 수 있습니다.
// 가격은 G 단위의 숫자로 입력하세요.
// 각 분류 안에서 품목 줄을 추가하거나 지울 수 있습니다. 한 페이지에 5개씩 표시됩니다.
function scr_market_catalog()
{
    return [
        [ // 씨앗
            market_item("하트비트 씨앗", spr_seed_HeartBeet, "하트비트를\n키울 수 있는 씨앗입니다.", 12, "seed", make_color_rgb(223, 153, 183)),
            market_item("헬라피뇨 씨앗", spr_seed_Hellapeno, "헬라피뇨를\n키울 수 있는 씨앗입니다.", 18, "seed", make_color_rgb(238, 145, 62)),
            market_item("구름감자 씨앗", spr_seed_CloudPotato, "구름감자를\n키울 수 있는 씨앗입니다.", 20, "seed", make_color_rgb(244, 191, 81)),
            market_item("얼음당근 씨앗", spr_seed_IceCarrot, "얼음당근을\n키울 수 있는 씨앗입니다.", 24, "seed", make_color_rgb(144, 178, 79)),
            market_item("마그마토 씨앗", spr_seed_Magmato, "마그마토를\n키울 수 있는 씨감자입니다.", 28, "seed", make_color_rgb(198, 142, 91))
            
        ],
        [ // 농기구
            market_item("괭이", noone, "단단한 땅을 갈아\n이랑을 만들 때 씁니다.", 120, "hoe", make_color_rgb(165, 179, 177)),
            market_item("물뿌리개", noone, "씨앗과 작물에 물을\n고르게 뿌리는 도구입니다.", 140, "can", make_color_rgb(128, 164, 177)),
            market_item("삽", noone, "작은 구덩이를 파거나\n모종을 옮길 때 씁니다.", 80, "trowel", make_color_rgb(171, 182, 178))
        ],
        [ // 업그레이드
            market_item("가방 확장", noone, "가방의 인벤토리 칸을\n한 줄 늘리는 업그레이드입니다.", 450, "bag", make_color_rgb(201, 151, 88))
        ]
    ];
}

function market_item(_name, _sprite, _description, _price, _icon = "seed", _accent = c_white)
{
    return {
        name: _name,
        sprite: _sprite,
        description: _description,
        price: _price,
        icon: _icon,
        accent: _accent
    };
}
