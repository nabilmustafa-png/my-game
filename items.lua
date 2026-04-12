-- items.lua
-- All gear definitions

local items = {}

items.all = {
    -- ─── Weapons ───────────────────────────────────────────────────────
    {
        id = "fists",
        name = "Fists",
        type = "weapon",
        damage = 1,
        kill_radius = 60,
        description = "Your bare hands. Weak.",
        equipped = false,
    },
    {
        id = "knife",
        name = "Rusty Knife",
        type = "weapon",
        damage = 2,
        kill_radius = 70,
        description = "Sharp enough. +1 dmg, +10 radius.",
        equipped = false,
    },
    {
        id = "sword",
        name = "Iron Sword",
        type = "weapon",
        damage = 3,
        kill_radius = 90,
        description = "Heavy but deadly. +2 dmg, +30 radius.",
        equipped = false,
    },
    {
        id = "spear",
        name = "Spear",
        type = "weapon",
        damage = 2,
        kill_radius = 120,
        description = "Long reach. +1 dmg, +60 radius.",
        equipped = false,
    },

    -- ─── Armor ─────────────────────────────────────────────────────────
    {
        id = "shirt",
        name = "Cloth Shirt",
        type = "armor",
        defense = 1,
        max_hp = 4,
        description = "Better than nothing. +1 HP.",
        equipped = false,
    },
    {
        id = "leather",
        name = "Leather Armor",
        type = "armor",
        defense = 2,
        max_hp = 6,
        description = "Decent protection. +3 HP.",
        equipped = false,
    },
    {
        id = "chainmail",
        name = "Chainmail",
        type = "armor",
        defense = 3,
        max_hp = 8,
        description = "Heavy but tough. +5 HP.",
        equipped = false,
    },

    -- ─── Consumables ───────────────────────────────────────────────────
    {
        id = "potion",
        name = "Health Potion",
        type = "consumable",
        effect = "heal",
        value = 2,
        description = "Restores 2 HP.",
        quantity = 0,
    },
    {
        id = "boost",
        name = "Damage Boost",
        type = "consumable",
        effect = "damage_boost",
        value = 2,
        duration = 10,
        description = "Doubles damage for 10 seconds.",
        quantity = 0,
    },
    {
        id = "speed",
        name = "Speed Brew",
        type = "consumable",
        effect = "speed_boost",
        value = 100,
        duration = 8,
        description = "+100 speed for 8 seconds.",
        quantity = 0,
    },
}

-- get item by id
function items.get(id)
    for _, item in ipairs(items.all) do
        if item.id == id then return item end
    end
    return nil
end

return items 