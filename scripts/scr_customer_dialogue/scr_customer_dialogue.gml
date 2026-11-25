/// Customer request dialogue, kept separate from cooking recipe data.
function customer_dialogue_for_recipe(_recipe_id)
{
    var entries = [
        { recipe_id: "heartbeet_salad", lines: ["체력 회복에 좋은 차가운 음식을 주세요.", "지친 몸을 회복할 수 있는 시원한 샐러드가 먹고 싶어요."] },
        { recipe_id: "heartbeet_soup", lines: ["체력 회복에 좋은 따뜻한 음식을 주세요.", "기운을 되찾을 수 있는 따뜻한 수프를 부탁해요."] },
        { recipe_id: "hellapeno_sauce", lines: ["화염 저항에 도움이 되는 매콤한 소스를 주세요.", "약한 불길을 견딜 수 있게 해주는 소스가 필요해요."] },
        { recipe_id: "cloudpotato_soup", lines: ["발걸음이 빨라지는 따뜻한 음식을 부탁해요.", "긴 여행길을 더 빠르게 걸을 수 있는 수프가 먹고 싶어요."] },
        { recipe_id: "magmato_soup", lines: ["강한 불길도 견딜 수 있는 따뜻한 음식을 주세요.", "화염 저항이 강한 2단계 수프를 부탁해요."] },
        { recipe_id: "icecarrot_pancake", lines: ["추위를 견디게 해주는 따뜻한 전을 부탁해요.", "빙결 저항에 도움이 되는 바삭한 전이 먹고 싶어요."] }
    ];
    for (var i = 0; i < array_length(entries); i++)
    {
        if (entries[i].recipe_id == _recipe_id && array_length(entries[i].lines) > 0)
            return entries[i].lines[irandom(array_length(entries[i].lines) - 1)];
    }
    return "요리를 부탁해요.";
}

function customer_dialogue_after_serving(_correct, _reward)
{
    if (_correct)
    {
        var thanks = ["주문한 음식이네요. 잘 먹겠습니다!", "기다리던 요리예요. 맛있게 먹을게요!"];
        return thanks[irandom(array_length(thanks) - 1)] + " +" + string(_reward) + " G";
    }
    var decline = ["제가 주문한 음식이 아니네요. 다음에 오겠습니다.", "원한 요리가 아니에요. 다음에 다시 올게요."];
    return decline[irandom(array_length(decline) - 1)];
}
