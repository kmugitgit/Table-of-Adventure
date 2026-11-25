/// Fish catalog. IDs use only the species name; habitat is currently shared water.
// Replace placeholder sprites when fish artwork is ready.
// habitat is currently "water" for every fish; future water tile types can specialize it.
// tier: 5 easiest (one key), 1 hardest (five keys).
// Optional time_limit overrides the default total WASD time for this particular fish.
function scr_fishing_entries()
{
    return [
        {
            id: "crucian",
            name: "붕어",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 5
        },
        {
            id: "minnow",
            name: "피라미",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 5
        },
        {
            id: "loach",
            name: "미꾸라지",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 5
        },
        {
            id: "carp",
            name: "잉어",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 4
        },
        {
            id: "catfish",
            name: "메기",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 4
        },
        {
            id: "perch",
            name: "쏘가리",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 3
        },
        {
            id: "golden_carp",
            name: "황금잉어",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 2
        },
        {
            id: "king",
            name: "강의 왕",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 1
        },
        {
            id: "smelt",
            name: "빙어",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 5
        },
        {
            id: "minifish",
            name: "송사리",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 5
        },
        {
            id: "bass",
            name: "배스",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 4
        },
        {
            id: "bluegill",
            name: "블루길",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 4
        },
        {
            id: "snakehead",
            name: "가물치",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 3
        },
        {
            id: "silver_smelt",
            name: "은빛빙어",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 2
        },
        {
            id: "guardian",
            name: "호수의 수호자",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 1
        },
        {
            id: "anchovy",
            name: "멸치",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 5
        },
        {
            id: "goby",
            name: "망둑어",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 5
        },
        {
            id: "mackerel",
            name: "고등어",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 4
        },
        {
            id: "flatfish",
            name: "가자미",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 4
        },
        {
            id: "bream",
            name: "도미",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 3
        },
        {
            id: "tuna",
            name: "참치",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 2
        },
        {
            id: "ancient",
            name: "고대어",
            sprite: spr_HeartBeet,
            habitat: "water",
            tier: 1
        }
    ];
}

// tier_weights order is [tier 1, tier 2, tier 3, tier 4, tier 5].
// Weights are split equally between fish of the same tier in any water tile.
function scr_fishing_rod_profiles()
{
    return [
        { name: "나무", tier_weights: [0, 0, 0, 25, 75], bite_min: 2, bite_max: 5, cast_seconds: 0.5, reel_seconds: 0.45 },
        { name: "구리", tier_weights: [0, 0, 10, 30, 60], bite_min: 2, bite_max: 5, cast_seconds: 0.5, reel_seconds: 0.45 },
        { name: "철", tier_weights: [0, 10, 20, 30, 40], bite_min: 2, bite_max: 5, cast_seconds: 0.5, reel_seconds: 0.45 },
        { name: "금", tier_weights: [5, 15, 25, 25, 30], bite_min: 2, bite_max: 5, cast_seconds: 0.5, reel_seconds: 0.45 },
        { name: "티타늄", tier_weights: [15, 20, 25, 20, 20], bite_min: 2, bite_max: 5, cast_seconds: 0.5, reel_seconds: 0.45 }
    ];
}

// Total seconds, ordered [tier 1, tier 2, tier 3, tier 4, tier 5].
function scr_fishing_time_limits() { return [5, 4.5, 4, 3.5, 3]; }
