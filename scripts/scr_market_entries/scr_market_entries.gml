/// @func scr_market_entries()
/// @desc 상점 상품 원본. id는 오브젝트 리소스이며 아이콘은 해당 오브젝트에서 자동으로 가져옵니다.
// tab: seed(씨앗), tool(도구), item(소모품), structure(구조물)
function scr_market_entries()
{
    return [
        {
            id: obj_HeartBeet_seed,
            name: "하트비트 씨앗",
            tab: "seed",
            description: "하트비트를\n키울 수 있는 씨앗입니다.",
            price: 12
        },
        {
            id: obj_Hellapeno_seed,
            name: "헬라피뇨 씨앗",
            tab: "seed",
            description: "헬라피뇨를\n키울 수 있는 씨앗입니다.",
            price: 18
        },
        {
            id: obj_CloudPotato_seed,
            name: "구름감자 씨앗",
            tab: "seed",
            description: "구름감자를\n키울 수 있는 씨앗입니다.",
            price: 20
        },
        {
            id: obj_IceCarrot_seed,
            name: "얼음당근 씨앗",
            tab: "seed",
            description: "얼음당근을\n키울 수 있는 씨앗입니다.",
            price: 24
        },
        {
            id: obj_Magmato_seed,
            name: "마그마토 씨앗",
            tab: "seed",
            description: "마그마토를\n키울 수 있는 씨앗입니다.",
            price: 28
        },
        {
            id: obj_hoe,
            name: "괭이",
            tab: "tool",
            tool_kind: "hoe",
            description: "단단한 땅을 갈아\n이랑을 만들 때 씁니다.",
            price: 120
        },
        {
            id: obj_watering_can,
            name: "물뿌리개",
            tab: "tool",
            tool_kind: "can",
            description: "씨앗과 작물에 물을\n고르게 뿌리는 도구입니다.",
            price: 140
        },
        {
            id: obj_shovel,
            name: "삽",
            tab: "tool",
            tool_kind: "shovel",
            description: "흙과 경작지를 정리하고\n심은 씨앗을 회수합니다.",
            price: 80
        },
        {
            id: obj_sickle,
            name: "낫",
            tab: "tool",
            tool_kind: "sickle",
            description: "다 자란 작물을 베어 수확합니다.",
            price: 100
        },
        {
            id: obj_fishing_rod,
            name: "낚싯대",
            tab: "tool",
            tool_kind: "rod",
            description: "물에 좌클릭으로 찌를 던집니다.\n입질이 오면 표시된 WASD를 순서대로 누르세요.",
            price: 180
        },
        {
            id: obj_inventory_expansion,
            name: "가방 확장",
            tab: "tool",
            description: "가방의 인벤토리 칸을\n한 줄 늘리는 업그레이드입니다.",
            price: 450
        }
    ];
}
