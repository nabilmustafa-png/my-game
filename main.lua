local memory = require("memory")
local constraints = require("constraints")
local player = require("player")
local enemy = require("enemy")
local inventory = require("inventory")
local rooms = require("rooms")
local npc = require("npc")
local quest = require("quest")
local travel = require("travel")
local ui = require("ui")
local camera = require("camera")

local score = 0
local maps = {}
local gameState = "menu" -- "menu" or "play"
local menuSelected = 1
local menuOptions = {"ENTER REALM", "EXIT"}

SW = 800
SH = 480

local function load_room()
    local room = rooms.get()
    if not maps[rooms.current] then
        maps[rooms.current] = love.graphics.newImage(room.map)
        maps[rooms.current]:setFilter("nearest", "nearest")
    end
    
    local map = maps[rooms.current]
    local mw, mh = map:getDimensions()
    
    player.map_w = math.max(SW, mw)
    player.map_h = math.max(SH, mh)

    if not room.enemies then
        enemy.clear()
    else
        enemy.spawn_batch(8)
    end
    player.x = player.map_w / 2
    player.y = player.map_h / 2
    
    camera.x = player.x - SW/2
    camera.y = player.y - SH/2
end

function love.load()
    love.window.setTitle("ARCANE RPG")
    love.window.setMode(SW, SH)
    math.randomseed(os.time())

    memory.alloc("player", 64 * 1024)
    memory.alloc("enemies", 512 * 1024)
    memory.alloc("inventory", 256 * 1024)
    memory.alloc("maps", 2 * 1024 * 1024)

    constraints.vram_alloc("player_texture", 128 * 1024)
    constraints.vram_alloc("enemy_texture", 256 * 1024)
    constraints.vram_alloc("map_texture", 512 * 1024)

    player.load()
    enemy.load()
    load_room()
end

function love.update(dt)
    if gameState == "menu" then
        return
    end

    if inventory.open or travel.open then return end
    constraints.reset()

    player.update(dt)
    enemy.update(dt, player.x, player.y)
    camera.update(dt, player.x, player.y, SW, SH, player.map_w, player.map_h)

    if rooms.current == "hub" then
        npc.update(player.x, player.y)
    end

    if rooms.get().enemies then
        if player.hp <= 0 then
            gameState = "menu" -- Back to menu on death
            player.hp = player.max_hp
            load_room()
        end
    end
end

function love.keypressed(key)
    if key == "escape" then 
        if gameState == "play" then
            gameState = "menu"
        else
            love.event.quit() 
        end
    end

    if gameState == "menu" then
        if key == "up" or key == "w" then
            menuSelected = math.max(1, menuSelected - 1)
        elseif key == "down" or key == "s" then
            menuSelected = math.min(#menuOptions, menuSelected + 1)
        elseif key == "return" or key == "space" or key == "e" then
            if menuSelected == 1 then
                gameState = "play"
            elseif menuSelected == 2 then
                love.event.quit()
            end
        end
        return
    end

    if travel.open then
        local dest = travel.keypressed(key)
        if dest then
            rooms.switch(dest)
            load_room()
        end
        return
    end

    if key == "m" then
        travel.toggle()
        return
    end

    if key == "tab" or key == "i" then
        inventory.toggle()
    end

    inventory.keypressed(key)

    if key == "e" and rooms.current == "hub" then
        if npc.nearby and not npc.talking then
            npc.interact()
        elseif npc.talking then
            npc.next_line()
        end
    end

    if not inventory.open then
        if key == "space" then
            local e = enemy.get_closest(player.x, player.y, player.kill_radius)
            if e then
                local dmg = player.effective_damage or player.damage
                local drop = enemy.damage(e, dmg)
                if drop and drop ~= "key" then
                    inventory.add(drop)
                end
                if not e.alive then
                    score = score + 1
                    enemy.spawn()
                end
            end
        end
    end
end

function love.mousepressed(mx, my, button)
    if gameState ~= "play" then return end
    if inventory.open or travel.open then return end
    
    local wx = mx + camera.x
    local wy = my + camera.y

    if button == 1 then
        local enemies = enemy.get_list()
        for _, e in ipairs(enemies) do
            if e.alive then
                local dx = wx - e.x
                local dy = wy - e.y
                if math.sqrt(dx*dx + dy*dy) < e.size + 10 then
                    local dmg = player.effective_damage or player.damage
                    local drop = enemy.damage(e, dmg)
                    if drop and drop ~= "key" then
                        inventory.add(drop)
                    end
                    if not e.alive then
                        score = score + 1
                        enemy.spawn()
                    end
                end
            end
        end
    end
end

local function draw_menu()
    -- Draw blurred/darkened hub map as background
    local map = maps["hub"]
    if map then
        love.graphics.setColor(0.2, 0.1, 0.3, 1)
        love.graphics.draw(map, 0, 0, 0, SW/map:getWidth(), SH/map:getHeight())
    end

    -- Title
    local title = "ARCANE DEPTHS"
    local dx, dy = ui.get_drift(10)
    ui.title(title, SW/2 - 140 + dx, 120 + dy)

    -- Floating Sigil
    local t = love.timer.getTime()
    ui.set(ui.col.title)
    love.graphics.push()
    love.graphics.translate(SW/2, 220 + dy)
    love.graphics.rotate(t * 0.5)
    love.graphics.polygon("line", 0, -30, 30, 0, 0, 30, -30, 0)
    love.graphics.pop()

    -- Buttons
    for i, opt in ipairs(menuOptions) do
        ui.button(opt, SW/2 - 100, 280 + (i-1) * 60, 200, 45, menuSelected == i)
    end

    ui.set(ui.col.dim)
    love.graphics.print("WASD NAVIGATE    SPACE/ENTER SELECT", SW/2 - 130, 440)
end

function love.draw()
    if gameState == "menu" then
        draw_menu()
        return
    end

    local map = maps[rooms.current]
    camera.apply()

    if map then
        love.graphics.setColor(1, 1, 1, 1)
        local sx = math.max(1, SW/map:getWidth())
        local sy = math.max(1, SH/map:getHeight())
        love.graphics.draw(map, 0, 0, 0, sx, sy)
    end

    if rooms.get().enemies then
        enemy.draw()
    end

    player.draw()

    if rooms.current == "hub" then
        npc.draw()
    end
    
    camera.detach()

    inventory.draw()
    quest.draw()
    travel.draw()

    -- HUD
    ui.panel(8, 8, 200, 55, 5)
    ui.set(ui.col.title)
    love.graphics.print("TOWD", 20, 14)
    ui.health_bar(20, 32, 175, 14, player.hp, player.max_hp)
    ui.set(ui.col.text)
    love.graphics.print(player.hp .. "/" .. player.max_hp, 95, 32)
    ui.set(ui.col.border)
    love.graphics.print("Score  " .. score, 20, 50)

    ui.set(ui.col.dim)
    love.graphics.print("WASD  |  SPACE  |  TAB  |  E  |  M", 10, SH - 18)
end