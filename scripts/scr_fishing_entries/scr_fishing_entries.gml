/// Fish catalog. Keep id stable for saves. Replace sprites when fish artwork is ready.
// habitat: river / lake / sea, or an array such as ["river", "lake"].
// tier: 5 easiest (one key), 1 hardest (five keys).
// Optional time_limit overrides the default total WASD time for this particular fish.
function scr_fishing_entries()
{
    return [
        { id: "river_crucian", name: "붕어", sprite: spr_HeartBeet, habitat: "river", tier: 5 },
        { id: "river_minnow", name: "피라미", sprite: spr_HeartBeet, habitat: "river", tier: 5 },
        { id: "river_loach", name: "미꾸라지", sprite: spr_HeartBeet, habitat: "river", tier: 5 },
        { id: "river_carp", name: "잉어", sprite: spr_HeartBeet, habitat: "river", tier: 4 },
        { id: "river_catfish", name: "메기", sprite: spr_HeartBeet, habitat: "river", tier: 4 },
        { id: "river_perch", name: "쏘가리", sprite: spr_HeartBeet, habitat: "river", tier: 3 },
        { id: "river_golden_carp", name: "황금잉어", sprite: spr_HeartBeet, habitat: "river", tier: 2 },
        { id: "river_king", name: "강의 왕", sprite: spr_HeartBeet, habitat: "river", tier: 1 },
        { id: "lake_smelt", name: "빙어", sprite: spr_HeartBeet, habitat: "lake", tier: 5 },
        { id: "lake_minifish", name: "송사리", sprite: spr_HeartBeet, habitat: "lake", tier: 5 },
        { id: "lake_bass", name: "배스", sprite: spr_HeartBeet, habitat: "lake", tier: 4 },
        { id: "lake_bluegill", name: "블루길", sprite: spr_HeartBeet, habitat: "lake", tier: 4 },
        { id: "lake_snakehead", name: "가물치", sprite: spr_HeartBeet, habitat: "lake", tier: 3 },
        { id: "lake_silver_smelt", name: "은빛빙어", sprite: spr_HeartBeet, habitat: "lake", tier: 2 },
        { id: "lake_guardian", name: "호수의 수호자", sprite: spr_HeartBeet, habitat: "lake", tier: 1 },
        { id: "sea_anchovy", name: "멸치", sprite: spr_HeartBeet, habitat: "sea", tier: 5 },
        { id: "sea_goby", name: "망둑어", sprite: spr_HeartBeet, habitat: "sea", tier: 5 },
        { id: "sea_mackerel", name: "고등어", sprite: spr_HeartBeet, habitat: "sea", tier: 4 },
        { id: "sea_flatfish", name: "가자미", sprite: spr_HeartBeet, habitat: "sea", tier: 4 },
        { id: "sea_bream", name: "도미", sprite: spr_HeartBeet, habitat: "sea", tier: 3 },
        { id: "sea_tuna", name: "참치", sprite: spr_HeartBeet, habitat: "sea", tier: 2 },
        { id: "sea_ancient", name: "고대어", sprite: spr_HeartBeet, habitat: "sea", tier: 1 }
    ];
}

// tier_weights order is [tier 1, tier 2, tier 3, tier 4, tier 5].
// Weights are split equally between fish of the same tier in the current habitat.
// Wood in a river: three tier-5 fish each get 75/3=25%, two tier-4 fish each 25/2=12.5%.
// A tier with no fish in this habitat is omitted and the remaining weights normalize.
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

// Inclusive TILE coordinates, not world pixels. First matching region wins.
// Only actual water tiles can be fished, even inside one of these rectangles.
// The current map has a narrow stream and a large pond; other water defaults to lake.
// To add sea water, add { room_id: rm_main, habitat: "sea", tile_bounds: [x1,y1,x2,y2] }.
function scr_fishing_water_regions()
{
    return [
        { room_id: rm_main, habitat: "river", tile_bounds: [84, 29, 85, 32] },
        { room_id: rm_main, habitat: "lake", tile_bounds: [71, 10, 92, 19] }
    ];
}
