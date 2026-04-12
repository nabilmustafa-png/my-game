-- memory.lua
-- Fake PS2 Memory Manager

local memory = {}

-- PS2 had 32MB of RAM, we reserve some for engine
memory.BUDGET = 24 * 1024 * 1024  -- 24MB for game assets
memory.used = 0

-- Track what's using memory
memory.allocations = {}

function memory.alloc(name, size)
    if memory.used + size > memory.BUDGET then
        error(string.format(
            "OUT OF MEMORY! Tried to allocate '%s' (%dKB) but only %dKB left!",
            name, size/1024, (memory.BUDGET - memory.used)/1024
        ))
    end
    memory.used = memory.used + size
    memory.allocations[name] = size
    print(string.format("[MEM] +%dKB '%s' | Used: %dKB / %dKB",
        size/1024, name, memory.used/1024, memory.BUDGET/1024))
end

function memory.free(name)
    if memory.allocations[name] then
        memory.used = memory.used - memory.allocations[name]
        print(string.format("[MEM] freed '%s' | Used: %dKB / %dKB",
            name, memory.used/1024, memory.BUDGET/1024))
        memory.allocations[name] = nil
    end
end

function memory.stats()
    return string.format("MEM: %dKB / %dKB (%.1f%%)",
        memory.used/1024,
        memory.BUDGET/1024,
        (memory.used/memory.BUDGET)*100)
end

return memory