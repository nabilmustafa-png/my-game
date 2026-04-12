local ui = require("ui")

local travel = {}
travel.open = false
travel.selected = 1

-- Atlas of Realms with screen coordinates
travel.locations = {
    {
        id = "hub",
        name = "ETERNAL BASTION",
        description = "A sanctuary between worlds. No blood shall be spilled here.",
        unlocked = true,
        x = 400, y = 240,
    },
    {
        id = "dungeon",
        name = "WHISPERING PLAINS",
        description = "The spirits of the fallen roam these fields. Guard your soul.",
        unlocked = true,
        x = 620, y = 180,
    },
    {
        id = "void",
        name = "THE ABYSSAL GATE",
        description = "A tear in reality leading to the shadow realm. High danger.",
        unlocked = false,
        x = 180, y = 120,
    },
}

function travel.unlock(id)
    for _, loc in ipairs(travel.locations) do
        if loc.id == id then
            loc.unlocked = true
        end
    end
end

function travel.toggle()
    travel.open = not travel.open
    travel.selected = 1
end

function travel.keypressed(key)
    if not travel.open then return end
    if key == "left" then
        travel.selected = math.max(1, travel.selected - 1)
    elseif key == "right" then
        travel.selected = math.min(#travel.locations, travel.selected + 1)
    elseif key == "return" or key == "e" then
        local loc = travel.locations[travel.selected]
        if loc and loc.unlocked then
            travel.open = false
            return loc.id
        end
    elseif key == "m" then
        travel.open = false
    end
end

function travel.draw()
    if not travel.open then return end

    local dx, dy = ui.get_drift(8)
    local t = love.timer.getTime()
    
    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, 800, 480)

    -- Draw Leylines (Magical connections)
    love.graphics.setLineWidth(1)
    for i = 1, #travel.locations - 1 do
        local l1 = travel.locations[i]
        local l2 = travel.locations[i+1]
        local alpha = 0.2 + math.sin(t * 2) * 0.1
        ui.set({ui.col.border[1], ui.col.border[2], ui.col.border[3], alpha})
        love.graphics.line(l1.x + dx, l1.y + dy, l2.x + dx, l2.y + dy)
    end

    -- Draw Realm Sigils
    for i, loc in ipairs(travel.locations) do
        local lx, ly = loc.x + dx, loc.y + dy
        local is_sel = (i == travel.selected)
        
        -- Magical Sigil (Diamond shape)
        if loc.unlocked then
            ui.set(is_sel and ui.col.title or ui.col.border)
        else
            ui.set(ui.col.locked)
        end
        
        love.graphics.push()
        love.graphics.translate(lx, ly)
        love.graphics.rotate(t * 0.5 * (is_sel and 2 or 1))
        love.graphics.polygon(is_sel and "fill" or "line", 0, -8, 8, 0, 0, 8, -8, 0)
        love.graphics.pop()
        
        -- Pulse Effect for selected
        if is_sel then
            local p = (t * 2) % 1
            ui.set({ui.col.title[1], ui.col.title[2], ui.col.title[3], 1-p})
            love.graphics.circle("line", lx, ly, 10 + p * 20)
        end

        -- Realm Name
        if is_sel or not loc.unlocked then
            ui.set(is_sel and ui.col.title or ui.col.locked)
            love.graphics.print(loc.name, lx + 18, ly - 8)
        end
    end

    -- Realm Information (Arcane Panel)
    local sel_loc = travel.locations[travel.selected]
    if sel_loc then
        local px, py = 500, 320
        ui.panel(px, py, 280, 130)
        
        local pdx, pdy = ui.get_drift(5)
        local tx, ty = px + 20 + pdx, py + 15 + pdy
        
        ui.title(sel_loc.name, tx, ty)
        ui.set(ui.col.text)
        love.graphics.printf(sel_loc.description, tx, ty + 35, 240)
        
        if not sel_loc.unlocked then
            ui.set(ui.col.red)
            love.graphics.print("REALM SEALED", tx, ty + 90)
        else
            ui.set(ui.col.green)
            love.graphics.print("BEGIN EXPEDITION [E]", tx, ty + 90)
        end
    end

    -- Header
    ui.title("ATLAS OF REALMS", 20, 20)

    -- Navigation hints
    ui.set(ui.col.dim)
    love.graphics.print("LEFT/RIGHT SELECT    E ENTER    M CLOSE", 20, 450)
end

return travel