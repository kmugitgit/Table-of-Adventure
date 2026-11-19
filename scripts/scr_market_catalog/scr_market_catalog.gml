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
            market_item("하트비트 씨앗", noone, "둥글고 하얀 순무를\n키울 수 있는 씨앗입니다.", 12, "seed", make_color_rgb(223, 153, 183)),
            market_item("당근 씨앗", noone, "선명한 주황빛 당근을\n키울 수 있는 씨앗입니다.", 18, "seed", make_color_rgb(238, 145, 62)),
            market_item("밀 씨앗", noone, "황금빛 밀 이삭을\n키울 수 있는 씨앗입니다.", 20, "seed", make_color_rgb(244, 191, 81)),
            market_item("양배추 씨앗", noone, "잎이 단단히 여무는\n양배추의 씨앗입니다.", 24, "seed", make_color_rgb(144, 178, 79)),
            market_item("감자 씨앗", noone, "흙 속에서 감자를\n키울 수 있는 씨감자입니다.", 28, "seed", make_color_rgb(198, 142, 91)),
            market_item("토마토 씨앗", noone, "붉게 익는 토마토를\n키울 수 있는 씨앗입니다.", 32, "seed", make_color_rgb(219, 90, 68)),
            market_item("딸기 씨앗", noone, "작고 달콤한 딸기를\n키울 수 있는 씨앗입니다.", 38, "seed", make_color_rgb(237, 114, 132)),
            market_item("호박 씨앗", noone, "크고 둥근 호박을\n키울 수 있는 씨앗입니다.", 42, "seed", make_color_rgb(239, 160, 75)),
			market_item("이주영 씨앗", noone, "크고 사나운 드래곤을 키울 수 있는 씨앗입니다.", 50000, "seed", make_color_rgb(255, 0, 0))
        ],
        [ // 농기구
            market_item("괭이", noone, "단단한 땅을 갈아\n이랑을 만들 때 씁니다.", 120, "hoe", make_color_rgb(165, 179, 177)),
            market_item("물뿌리개", noone, "씨앗과 작물에 물을\n고르게 뿌리는 도구입니다.", 140, "can", make_color_rgb(128, 164, 177)),
            market_item("모종삽", noone, "작은 구덩이를 파거나\n모종을 옮길 때 씁니다.", 80, "trowel", make_color_rgb(171, 182, 178))
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
