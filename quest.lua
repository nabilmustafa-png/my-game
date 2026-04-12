local ui = require("ui")

local quest = {}

quest.active = nil
quest.completed = {}
quest.key_dropped = false

quest.list = {
    find_key = {
        id = "find_key",
        title = "The Friend's Key",
        giver = "Lilak",
        objective = "The key to Lilak's missing friend's room was stolen by beasts. Recover it from the Whispering Plains.",
        status = "inactive",
        progress = 0,
        goal = 1,
    }
}

function quest.start(id)
    local q = quest.list[id]
    if q then
        q.status = "active"
        quest.active = q
        local travel = require("travel")
        travel.unlock("dungeon")
    end
end

function quest.complete(id)
    local q = quest.list[id]
    if q then
        q.status = "complete"
        table.insert(quest.completed, q)
        quest.active = nil
    end
end

function quest.check_key_drop()
    if quest.active and quest.active.id == "find_key" then
        quest.active.progress = quest.active.progress + 1
        if quest.active.progress >= quest.active.goal then
            quest.key_dropped = true
            quest.complete("find_key")
            return true
        end
    end
    return false
end

function quest.draw()
    if not quest.active then return end

    local x = SW - 240
    local y = 10
    local w = 230
    local h = 95

    ui.panel(x, y, w, h, 6)

    ui.title("◈ " .. quest.active.title, x + 10, y + 10)
    ui.divider(x + 8, y + 28, x + w - 8)

    ui.set(ui.col.text)
    love.graphics.printf(quest.active.objective, x + 10, y + 34, w - 20, "left")

    ui.set(ui.col.green)
    love.graphics.print(quest.active.progress .. " / " .. quest.active.goal, x + 10, y + 74)
end

return quest