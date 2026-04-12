local items = require("items")
local player = require("player")
local ui = require("ui")

local inventory = {}
inventory.open = false
inventory.selected = 1
inventory.tab = "weapon"

inventory.owned = {
    items.get("fists"),
}

local tabs = {"weapon", "armor", "consumable"}
local tab_labels = {weapon = "WEAPONS", armor = "ARMOR", consumable = "CONSUMABLES"}

local function get_tab_items()
    local result = {}
    for _, item in ipairs(inventory.owned) do
        if item.type == inventory.tab then
            table.insert(result, item)
        end
    end
    return result
end

function inventory.add(id)
    local item = items.get(id)
    if not item then return end
    if item.type == "consumable" then
        for _, owned in ipairs(inventory.owned) do
            if owned.id == id then
                owned.quantity = owned.quantity + 1
                return
            end
        end
        local copy = {}
        for k, v in pairs(item) do copy[k] = v end
        copy.quantity = 1
        table.insert(inventory.owned, copy)
    else
        for _, owned in ipairs(inventory.owned) do
            if owned.id == id then return end
        end
        table.insert(inventory.owned, item)
    end
end

function inventory.toggle()
    inventory.open = not inventory.open
    inventory.selected = 1
end

function inventory.keypressed(key)
    if not inventory.open then return end
    if key == "left" or key == "right" then
        local idx = 1
        for i, t in ipairs(tabs) do
            if t == inventory.tab then idx = i end
        end
        if key == "right" then
            idx = (idx % #tabs) + 1
        else
            idx = ((idx - 2) % #tabs) + 1
        end
        inventory.tab = tabs[idx]
        inventory.selected = 1
        return
    end
    local tab_items = get_tab_items()
    if key == "up" then
        inventory.selected = math.max(1, inventory.selected - 1)
    elseif key == "down" then
        inventory.selected = math.min(#tab_items, inventory.selected + 1)
    elseif key == "return" or key == "e" then
        local item = tab_items[inventory.selected]
        if item then
            if item.type == "weapon" or item.type == "armor" then
                player.equip(item)
            elseif item.type == "consumable" then
                player.use_consumable(item)
            end
        end
    end
end

function inventory.draw()
    if not inventory.open then return end

    local x = SW/2 - 300
    local y = SH/2 - 190
    local w = 600
    local h = 380

    ui.panel(x, y, w, h, 8)

    ui.title("I N V E N T O R Y", x + w/2 - 70, y + 12)
    ui.divider(x + 15, y + 34, x + w - 15)

    local tab_cols = {
        weapon     = ui.col.weapon_col,
        armor      = ui.col.armor_col,
        consumable = ui.col.consumable_col,
    }
    local tab_w = 160
    local tab_gap = (w - 3 * tab_w) / 4
    local tab_xs = {
        x + tab_gap,
        x + tab_gap * 2 + tab_w,
        x + tab_gap * 3 + tab_w * 2,
    }

    for i, t in ipairs(tabs) do
        local col = tab_cols[t]
        if t == inventory.tab then
            love.graphics.setColor(col[1], col[2], col[3], 0.25)
            love.graphics.rectangle("fill", tab_xs[i], y + 40, tab_w, 24, 4)
            love.graphics.setColor(col[1], col[2], col[3], 1)
            love.graphics.rectangle("line", tab_xs[i], y + 40, tab_w, 24, 4)
        else
            love.graphics.setColor(col[1], col[2], col[3], 0.1)
            love.graphics.rectangle("fill", tab_xs[i], y + 40, tab_w, 24, 4)
            love.graphics.setColor(col[1], col[2], col[3], 0.4)
        end
        love.graphics.print(tab_labels[t], tab_xs[i] + 35, y + 44)
    end

    ui.divider(x + 15, y + 70, x + w - 15)

    local wname = player.weapon and player.weapon.name or "None"
    local aname = player.armor and player.armor.name or "None"
    ui.set(ui.col.border)
    love.graphics.print("Weapon: " .. wname, x + 20, y + 76)
    love.graphics.print("Armor: " .. aname, x + 250, y + 76)

    ui.divider(x + 15, y + 96, x + w - 15)

    local tab_items = get_tab_items()
    local start_y = y + 104

    if #tab_items == 0 then
        ui.dim("Nothing here yet — kill enemies to get drops!", x + 150, y + 200)
    else
        for i, item in ipairs(tab_items) do
            local iy = start_y + (i - 1) * 44
            local col = tab_cols[item.type]

            if i == inventory.selected then
                ui.highlight_row(x + 10, iy - 3, w - 20, 38)
                ui.set(ui.col.border)
                love.graphics.rectangle("line", x + 10, iy - 3, w - 20, 38, 4)
            end

            love.graphics.setColor(col[1], col[2], col[3], 1)
            local name = item.name
            if item.equipped then name = name .. "  [EQUIPPED]" end
            if item.type == "consumable" then name = name .. "  x" .. item.quantity end
            love.graphics.print(name, x + 20, iy)
            ui.dim(item.description, x + 20, iy + 18)
        end
    end

    ui.divider(x + 15, y + h - 44, x + w - 15)
    ui.set(ui.col.border)
    love.graphics.printf(
        string.format("HP  %d/%d     DMG  %d     RADIUS  %d     SPD  %d",
            player.hp, player.max_hp, player.damage, player.kill_radius, player.speed),
        x + 20, y + h - 36, w - 40, "left"
    )
    ui.divider(x + 15, y + h - 20, x + w - 15)
    ui.dim("LEFT/RIGHT tab    UP/DOWN navigate    E equip/use    TAB close", x + 140, y + h - 16)
end

return inventory