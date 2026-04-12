-- player.lua
local items = require("items")

local sprite = nil
local SCALE = 2  -- 32x32 * 2 = 64x64 on screen

local player = {
    x = 400, y = 240,
    speed = 150,
    size = 16,
    kill_radius = 60,
    hp = 6769420,
    max_hp = 6769420,
    damage = 1,
    buffs = {},
    weapon = nil,
    armor = nil,
    effective_damage = 1,
}

function player.load()
    sprite = love.graphics.newImage("player.png")
    sprite:setFilter("nearest", "nearest") -- keeps pixel art crisp, no blurring
end

function player.equip(item)
    if item.type == "weapon" then
        if player.weapon then
            player.weapon.equipped = false
            player.kill_radius = 60
            player.damage = 1
        end
        player.weapon = item
        item.equipped = true
        player.damage = item.damage
        player.kill_radius = item.kill_radius
    elseif item.type == "armor" then
        if player.armor then
            player.armor.equipped = false
            player.max_hp = 3
            player.hp = math.min(player.hp, player.max_hp)
        end
        player.armor = item
        item.equipped = true
        player.max_hp = item.max_hp
        player.hp = player.max_hp
    end
end

function player.use_consumable(item)
    if item.quantity <= 0 then return false end
    item.quantity = item.quantity - 1
    if item.effect == "heal" then
        player.hp = math.min(player.max_hp, player.hp + item.value)
    elseif item.effect == "damage_boost" then
        table.insert(player.buffs, {
            type = "damage_boost",
            value = item.value,
            timer = item.duration,
        })
    elseif item.effect == "speed_boost" then
        table.insert(player.buffs, {
            type = "speed_boost",
            value = item.value,
            timer = item.duration,
        })
    end
    return true
end

function player.update(dt)
    local active = {}
    local bonus_damage = 0
    local bonus_speed = 0
    for _, b in ipairs(player.buffs) do
        b.timer = b.timer - dt
        if b.timer > 0 then
            table.insert(active, b)
            if b.type == "damage_boost" then bonus_damage = bonus_damage + b.value end
            if b.type == "speed_boost" then bonus_speed = bonus_speed + b.value end
        end
    end
    player.buffs = active
    player.effective_damage = player.damage + bonus_damage

    local spd = player.speed + bonus_speed
    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
        player.y = player.y - spd * dt
    end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
        player.y = player.y + spd * dt
    end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        player.x = player.x - spd * dt
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        player.x = player.x + spd * dt
    end

    -- map_w and map_h should be passed from main.lua
    local mw = player.map_w or 800
    local mh = player.map_h or 480
    player.x = math.max(player.size, math.min(mw - player.size, player.x))
    player.y = math.max(player.size, math.min(mh - player.size, player.y))
end

function player.draw()
    local sw = sprite:getWidth() * SCALE
    local sh = sprite:getHeight() * SCALE

    -- kill radius
    love.graphics.setColor(1, 1, 0, 0.15)
    love.graphics.circle("fill", player.x, player.y, player.kill_radius)
    love.graphics.setColor(1, 1, 0, 0.4)
    love.graphics.circle("line", player.x, player.y, player.kill_radius)

    -- draw sprite centered, scaled up, pixel perfect
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(sprite, player.x - sw/2, player.y - sh/2, 0, SCALE, SCALE)

    -- health bar
    local bar_w = 40
    local bar_h = 6
    local bar_x = player.x - bar_w / 2
    local bar_y = player.y - sh/2 - 10
    love.graphics.setColor(0.3, 0, 0, 1)
    love.graphics.rectangle("fill", bar_x, bar_y, bar_w, bar_h)
    love.graphics.setColor(0.2, 0.9, 0.2, 1)
    love.graphics.rectangle("fill", bar_x, bar_y, bar_w * (player.hp / player.max_hp), bar_h)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", bar_x, bar_y, bar_w, bar_h)

    -- buff timers
    local bx = player.x - 20
    for _, b in ipairs(player.buffs) do
        love.graphics.setColor(1, 0.8, 0, 1)
        love.graphics.print(string.format("%.1fs", b.timer), bx, player.y + sh/2 + 2)
        bx = bx + 30
    end
end

return player