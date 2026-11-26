/// @func scr_item_book_entries()
/// @desc id 오브젝트의 스프라이트를 자동 사용합니다. 같은 오브젝트를 얻으면 도감이 해금됩니다.
function scr_item_book_entries()
{
    var entries = [
        {
            id: obj_HeartBeet,
            name: "하트비트",
            tag: "plant",
            description: "붉은 뿌리를 가진 작물입니다.",
            effects: ["heal_speed"],
            cultivated_land: "dirt"
        },
        {
            id: obj_Hellapeno,
            name: "헬라피뇨",
            tag: "plant",
            description: "매콤한 열매가 열리는 작물입니다.",
            effects: ["fire_resistance"],
            cultivated_land: "dirt"
        },
        {
            id: obj_CloudPotato,
            name: "구름감자",
            tag: "plant",
            description: "구름처럼 폭신한 감자 작물입니다.",
            effects: [],
            cultivated_land: "dirt"
        },
        {
            id: obj_IceCarrot,
            name: "얼음당근",
            tag: "plant",
            description: "차가운 기운을 품은 당근입니다.",
            effects: [],
            cultivated_land: "dirt"
        },
        {
            id: obj_Magmato,
            name: "마그마토",
            tag: "plant",
            description: "뜨거운 마그마의 힘을 품은 작물입니다.",
            effects: ["fire_resistance"],
            cultivated_land: "dirt"
        },
        {
            id: obj_HeartBeet_salad,
            name: "하트비트 샐러드",
            tag: "food",
            description: "하트비트로 만든 샐러드입니다.",
            effects: ["heal_speed"],
            cultivated_land: " "
        },
		{
            id: obj_HeartBeet_pancake,
            name: "하트비트 전",
            tag: "food",
            description: "하트비트로 만든 전입니다.",
            effects: ["heal_speed"],
            cultivated_land: " "
        },
		{
            id: obj_HeartBeet_soup,
            name: "하트비트 수프",
            tag: "food",
            description: "하트비트로 만든 수프입니다.",
            effects: ["heal_speed"],
            cultivated_land: " "
        }
    ];

    entries = fishing_book_entries(entries);
    for (var i = 0; i < array_length(entries); i++)
    {
        var entry_sprite = object_get_sprite(entries[i].id);
        entries[i].sprite = entry_sprite == -1 ? noone : entry_sprite;
    }
    return entries;
}

