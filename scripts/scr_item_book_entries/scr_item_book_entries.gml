/// @func scr_item_book_entries()
/// @desc 도감 아이템 목록. 새 항목은 이 카탈로그 배열에 추가합니다.
// 항목 형식: {id, name, tag, sprite, description, effects, cultivated_land}
// tag는 plant/condiment/meat/fish/food 중 하나이며 effects는 아이콘 데이터 최대 3개입니다.
function scr_item_book_entries()
{
    return [
        {
            id: "crop_HeartBeet_normal",
            high_quality_id: "crop_HeartBeet_high",
            name: "하트비트",
            tag: "plant",
            sprite: spr_HeartBeet,
            description: "붉은 뿌리를 가진 작물입니다.",
            effects: [],
            cultivated_land: "dirt"
        },
        {
            id: "crop_Hellapeno_normal",
            high_quality_id: "crop_Hellapeno_high",
            name: "헬라피뇨",
            tag: "plant",
            sprite: spr_Hellapeno,
            description: "매콤한 열매가 열리는 작물입니다.",
            effects: [],
            cultivated_land: "dirt"
        },
        {
            id: "crop_CloudPotato_normal",
            high_quality_id: "crop_CloudPotato_high",
            name: "구름감자",
            tag: "plant",
            sprite: spr_CloudPotato,
            description: "구름처럼 폭신한 감자 작물입니다.",
            effects: [],
            cultivated_land: "dirt"
        },
        {
            id: "crop_IceCarrot_normal",
            high_quality_id: "crop_IceCarrot_high",
            name: "얼음당근",
            tag: "plant",
            sprite: spr_IceCarrot,
            description: "차가운 기운을 품은 당근 작물입니다.",
            effects: [],
            cultivated_land: "dirt"
        },
        {
            id: "crop_Magmato_normal",
            high_quality_id: "crop_Magmato_high",
            name: "마그마토",
            tag: "plant",
            sprite: spr_Magmato,
            description: "뜨거운 마그마의 힘을 품은 작물입니다.",
            effects: [],
            cultivated_land: "dirt"
        }
    ];
}
