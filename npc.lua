local quest = require("quest")
local ui = require("ui")

local npc = {}

npc.x = 400
npc.y = 240
npc.size = 16
npc.nearby = false
npc.talking = false
npc.dialogue_index = 1
npc.quest_given = false
npc.name = "Lilak"

npc.dialogue = {
    {
        lines = {
            "Hey there Towd!",
            "Could you help me out?",
            "My friend has been missing for a while now...",
            "I think he dropped his room key somewhere along the Plains.",
            "One of the beasts out there might have stolen it.",
            "Could you head to the Plains and find it for me?",
            "Just fight the beasts until one of them drops it.",
        },
        on_end = function()
            npc.quest_given = true
            quest.start("find_key")
        end
    },
    {
        lines = {
            "Still out there Towd?",
            "The key should be somewhere on the Plains.",
            "Keep fighting those beasts, one of them has it for sure.",
        },
        on_end = function() end
    },
    {
        lines = {
            "You found it! Thank you so much Towd.",
            "Now maybe I can finally find out what happened to my friend...",
        },
        on_end = function() end
    },
}

function npc.load() end

function npc.get_dialogue()
    if not npc.quest_given then
        return npc.dialogue[1]
    elseif quest.key_dropped then
        return npc.dialogue[3]
    else
        return npc.dialogue[2]
    end
end

function npc.interact()
    if not npc.talking then
        npc.talking = true
        npc.dialogue_index = 1
    end
end

function npc.next_line()
    local d = npc.get_dialogue()
    npc.dialogue_index = npc.dialogue_index + 1
    if npc.dialogue_index > #d.lines then
        npc.talking = false
        npc.dialogue_index = 1
        d.on_end()
    end
end

function npc.update(px, py)
    local dx = px - npc.x
    local dy = py - npc.y
    local dist = math.sqrt(dx*dx + dy*dy)
    npc.nearby = dist < 50
end

function npc.draw()
    love.graphics.setColor(1, 0.8, 0.3, 1)
    love.graphics.circle("fill", npc.x, npc.y, npc.size)
    ui.set(ui.col.border)
    love.graphics.circle("line", npc.x, npc.y, npc.size)

    ui.set(ui.col.title)
    love.graphics.print(npc.name, npc.x - 15, npc.y - 30)

    if npc.nearby and not npc.talking then
        ui.dim("[E] Talk", npc.x - 20, npc.y - 44)
    end

    if npc.talking then
        local d = npc.get_dialogue()
        local line = d.lines[npc.dialogue_index]

        ui.panel(40, 330, 720, 120, 6)

        ui.set(ui.col.title)
        love.graphics.print(npc.name, 60, 346)

        ui.divider(55, 364, 745)

        ui.set(ui.col.text)
        love.graphics.printf(line, 60, 372, 680, "left")

        ui.dim("[E] Continue", 650, 428)
    end
end

return npc