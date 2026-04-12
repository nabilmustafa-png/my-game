-- enemy.lua
local items = require("items")

local enemy = {}
local list = {}

local SPEED = 60
local FRAME_W = 64
local FRAME_H = 64
local SCALE = 1.5

local sprites = {}

local drop_table = {"knife", "sword", "spear", "shirt", "leather", "chainmail", "potion", "boost", "speed"}

local function random_drop()
    if math.random() < 0.5 then
        return drop_table[math.random(#drop_table)]
    end
    return nil
end

function enemy.load()
    sprites.idle = love.graphics.newImage("Enemy3-Idle.png")
    sprites.fly  = love.graphics.newImage("Enemy3-Fly.png")
    sprites.hit  = love.graphics.newImage("Enemy3-Hit.png")
    sprites.die  = love.graphics.newImage("Enemy3-Die.png")
    sprites.smash_start = love.graphics.newImage("Enemy3-AttackSmashStart.png")
    sprites.smash_loop  = love.graphics.newImage("Enemy3-AttackSmashLoop.png")
    sprites.smash_end   = love.graphics.newImage("Enemy3-SmashEnd.png")
    for _, s in pairs(sprites) do
        s:setFilter("nearest", "nearest")
    end
end

local function new_anim(sprite, frame_count, fps)
    return {
        sprite = sprite,
        frame_count = frame_count,
        fps = fps,
        frame = 1,
        timer = 0,
        done = false,
    }
end

local function update_anim(anim, dt)
    anim.timer = anim.timer + dt
    if anim.timer >= 1 / anim.fps then
        anim.timer = 0
        anim.frame = anim.frame + 1
        if anim.frame > anim.frame_count then
            anim.frame = 1
            anim.done = true
        end
    end
end

local function draw_anim(anim, x, y, alpha)
    alpha = alpha or 1
    local quad = love.graphics.newQuad(
        (anim.frame - 1) * FRAME_W, 0,
        FRAME_W, FRAME_H,
        anim.sprite:getWidth(), anim.sprite:getHeight()
    )
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(
        anim.sprite, quad,
        x - (FRAME_W * SCALE) / 2,
        y - (FRAME_H * SCALE) / 2,
        0, SCALE, SCALE
    )
end

function enemy.spawn()
    local mw = (require("player")).map_w or 800
    local mh = (require("player")).map_h or 480
    table.insert(list, {
        x = math.random(20, mw - 20),
        y = math.random(80, mh - 40),
        size = 20,
        alive = true,
        hp = 3,
        max_hp = 3,
        damage = 1,
        state = "idle",
        anim = new_anim(sprites.idle, 8, 8),
        -- aggro
        aggro_radius = 250,
        attack_range = 70,
        -- pathfinding
        path_timer = 0,
        target_x = nil,
        target_y = nil,
        -- death fade
        alpha = 1,
        dying = false,
    })
end

function enemy.clear()
    list = {}
end

function enemy.spawn_batch(count)
    list = {}
    for i = 1, count do
        enemy.spawn()
    end
end

function enemy.get_list()
    return list
end

function enemy.damage(e, amount)
    e.hp = e.hp - amount
    if e.hp <= 0 then
        e.alive = false
        e.dying = true
        e.state = "die"
        e.anim = new_anim(sprites.die, 17, 10)
        local quest = require("quest")
        if quest.active and quest.active.id == "find_key" then
            local dropped = quest.check_key_drop()
            if dropped then
                return "key"
            end
        end
        return random_drop()
    else
        e.state = "hit"
        e.anim = new_anim(sprites.hit, 4, 12)
    end
    return nil
end

function enemy.get_closest(px, py, radius)
    local closest = nil
    local closest_dist = math.huge
    for _, e in ipairs(list) do
        if e.alive then
            local dx = px - e.x
            local dy = py - e.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < radius and dist < closest_dist then
                closest = e
                closest_dist = dist
            end
        end
    end
    return closest
end

function enemy.update(dt, px, py)
    local player = require("player")
    for _, e in ipairs(list) do
        update_anim(e.anim, dt)

        if e.dying then
            -- fade out after die animation finishes
            if e.anim.done then
                e.alpha = e.alpha - dt * 2
            end
        elseif e.alive then
            -- after hit go back to fly
            if e.state == "hit" and e.anim.done then
                e.state = "fly"
                e.anim = new_anim(sprites.fly, 8, 8)
            end

            -- check aggro distance
            local dx = px - e.x
            local dy = py - e.y
            local dist = math.sqrt(dx*dx + dy*dy)

            if e.state == "smash_start" then
                if e.anim.done then
                    e.state = "smash_loop"
                    e.anim = new_anim(sprites.smash_loop, 3, 10)
                    -- Deal damage to player if they are still in range
                    if dist < e.attack_range + 20 then
                        player.hp = player.hp - e.damage
                        -- Simple knockback
                        local kdx = px - e.x
                        local kdy = py - e.y
                        local kd = math.sqrt(kdx*kdx + kdy*kdy)
                        if kd > 0 then
                            player.x = player.x + (kdx/kd) * 50
                            player.y = player.y + (kdy/kd) * 50
                        end
                    end
                end
            elseif e.state == "smash_loop" then
                if e.anim.done then
                    e.state = "smash_end"
                    e.anim = new_anim(sprites.smash_end, 8, 10)
                end
            elseif e.state == "smash_end" then
                if e.anim.done then
                    e.state = "fly"
                    e.anim = new_anim(sprites.fly, 8, 8)
                end
            elseif dist < e.aggro_radius then
                -- if close enough, smash!
                if dist < e.attack_range then
                    e.state = "smash_start"
                    e.anim = new_anim(sprites.smash_start, 12, 12)
                else
                    -- move towards player
                    e.path_timer = e.path_timer + dt
                    if e.path_timer >= 0.5 then
                        e.path_timer = 0
                        e.target_x = px + math.random(-20, 20)
                        e.target_y = py + math.random(-20, 20)
                    end

                    if e.target_x then
                        local tdx = e.target_x - e.x
                        local tdy = e.target_y - e.y
                        local tdist = math.sqrt(tdx*tdx + tdy*tdy)
                        if tdist > 5 then
                            e.x = e.x + (tdx/tdist) * SPEED * dt
                            e.y = e.y + (tdy/tdist) * SPEED * dt
                        end
                    end

                    if e.state == "idle" then
                        e.state = "fly"
                        e.anim = new_anim(sprites.fly, 8, 8)
                    end
                end
            else
                -- stay idle if too far
                if e.state ~= "idle" then
                    e.state = "idle"
                    e.anim = new_anim(sprites.idle, 8, 8)
                end
            end
        end
    end

    -- remove fully faded enemies
    local alive = {}
    for _, e in ipairs(list) do
        if e.alpha > 0 then
            table.insert(alive, e)
        end
    end
    list = alive
end

function enemy.draw()
    for _, e in ipairs(list) do
        draw_anim(e.anim, e.x, e.y, e.alpha)

        if e.alive then
            local bar_w = 40
            local bar_h = 5
            local bar_x = e.x - bar_w / 2
            local bar_y = e.y - (FRAME_H * SCALE) / 2 - 10
            love.graphics.setColor(0.3, 0, 0, 1)
            love.graphics.rectangle("fill", bar_x, bar_y, bar_w, bar_h)
            local ratio = e.hp / e.max_hp
            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.rectangle("fill", bar_x, bar_y, bar_w * ratio, bar_h)
            love.graphics.setColor(1, 1, 1, 0.4)
            love.graphics.rectangle("line", bar_x, bar_y, bar_w, bar_h)
        end
    end
end

return enemy