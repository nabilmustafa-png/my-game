-- rooms.lua
local rooms = {}

rooms.current = "hub"

rooms.data = {
    hub = {
        map = "hub.png",
        enemies = false,
        music = nil,
    },
    dungeon = {
        map = "map.png",
        enemies = true,
        music = nil,
    },
}

function rooms.switch(name)
    rooms.current = name
end

function rooms.get()
    return rooms.data[rooms.current]
end

return rooms