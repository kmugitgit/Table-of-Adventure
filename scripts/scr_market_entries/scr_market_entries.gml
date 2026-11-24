/// @func scr_market_entries()
/// @desc 상점 상품 원본 목록. 각 상품은 이름, 탭, 스프라이트, 설명, 가격을 가집니다.
// tab: seed(씨앗), tool(도구), item(소모품), structure(구조물)
// 새 상품을 추가할 때 id, name, tab, sprite, description, price를 지정하세요.
function scr_market_entries()
{
    return [
        {
            id: "spr_seed_HeartBeet",
            name: "하트비트 씨앗",
            tab: "seed",
            sprite: spr_seed_HeartBeet,
            description: "하트비트를\n키울 수 있는 씨앗입니다.",
            price: 12
        },
        {
            id: "spr_seed_Hellapeno",
            name: "헬라피뇨 씨앗",
            tab: "seed",
            sprite: spr_seed_Hellapeno,
            description: "헬라피뇨를\n키울 수 있는 씨앗입니다.",
            price: 18
        },
        {
            id: "spr_seed_CloudPotato",
            name: "구름감자 씨앗",
            tab: "seed",
            sprite: spr_seed_CloudPotato,
            description: "구름감자를\n키울 수 있는 씨앗입니다.",
            price: 20
        },
        {
            id: "spr_seed_IceCarrot",
            name: "얼음당근 씨앗",
            tab: "seed",
            sprite: spr_seed_IceCarrot,
            description: "얼음당근을\n키울 수 있는 씨앗입니다.",
            price: 24
        },
        {
            id: "spr_seed_Magmato",
            name: "마그마토 씨앗",
            tab: "seed",
            sprite: spr_seed_Magmato,
            description: "마그마토를\n키울 수 있는 씨앗입니다.",
            price: 28
        },
        {
            id: "hoe",
            name: "괭이",
            tab: "tool",
            sprite: noone,
            description: "단단한 땅을 갈아\n이랑을 만들 때 씁니다.",
            price: 120
        },
        {
            id: "can",
            name: "물뿌리개",
            tab: "tool",
            sprite: noone,
            description: "씨앗과 작물에 물을\n고르게 뿌리는 도구입니다.",
            price: 140
        },
        {
            id: "shovel",
            name: "삽",
            tab: "tool",
            sprite: noone,
            description: "흙과 경작지를 정리하고\n심은 씨앗을 회수합니다.",
            price: 80
        },
        {
            id: "sickle",
            name: "낫",
            tab: "tool",
            sprite: noone,
            description: "다 자란 작물을 베어 수확합니다.",
            price: 100
        },
        {
            id: "rod",
            name: "낚싯대",
            tab: "tool",
            sprite: noone,
            description: "물에 좌클릭으로 찌를 던집니다.\n입질이 오면 표시된 WASD를 순서대로 누르세요.",
            price: 180
        },
        {
            id: "inventory_expansion",
            name: "가방 확장",
            tab: "tool",
            sprite: noone,
            description: "가방의 인벤토리 칸을\n한 줄 늘리는 업그레이드입니다.",
            price: 450
        }
    ];
}
