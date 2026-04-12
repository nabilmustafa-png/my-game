-- constraints.lua
-- Fake PS2 Hardware Constraints

local constraints = {}

-- ─── GPU / Draw Call Budget ────────────────────────────────────────────────
constraints.DRAW_BUDGET = 64        -- PS2 could handle ~64 draw calls per frame
constraints.draws_used = 0

-- ─── VRAM Budget (PS2 had 4MB of VRAM) ────────────────────────────────────
constraints.VRAM_BUDGET = 4 * 1024 * 1024  -- 4MB
constraints.vram_used = 0
constraints.vram_allocations = {}

-- ─── CPU Budget (fake cycles per frame) ───────────────────────────────────
constraints.CPU_BUDGET = 10000      -- fake ops per frame
constraints.cpu_used = 0

-- ─── GPU Functions ─────────────────────────────────────────────────────────
function constraints.draw(drawfn)
    constraints.draws_used = constraints.draws_used + 1
    if constraints.draws_used > constraints.DRAW_BUDGET then
        error(string.format(
            "GPU OVERDRAW! Exceeded %d draw calls this frame!",
            constraints.DRAW_BUDGET
        ))
    end
    drawfn()
end

-- ─── VRAM Functions ────────────────────────────────────────────────────────
function constraints.vram_alloc(name, size)
    if constraints.vram_used + size > constraints.VRAM_BUDGET then
        error(string.format(
            "OUT OF VRAM! Tried to load '%s' (%dKB) but only %dKB left!",
            name, size/1024, (constraints.VRAM_BUDGET - constraints.vram_used)/1024
        ))
    end
    constraints.vram_used = constraints.vram_used + size
    constraints.vram_allocations[name] = size
    print(string.format("[VRAM] +%dKB '%s' | Used: %dKB / %dKB",
        size/1024, name, constraints.vram_used/1024, constraints.VRAM_BUDGET/1024))
end

function constraints.vram_free(name)
    if constraints.vram_allocations[name] then
        constraints.vram_used = constraints.vram_used - constraints.vram_allocations[name]
        constraints.vram_allocations[name] = nil
    end
end

-- ─── CPU Functions ─────────────────────────────────────────────────────────
function constraints.cpu_op(cost)
    cost = cost or 1
    constraints.cpu_used = constraints.cpu_used + cost
    if constraints.cpu_used > constraints.CPU_BUDGET then
        error(string.format(
            "CPU OVERLOAD! Exceeded %d ops this frame! (used %d)",
            constraints.CPU_BUDGET, constraints.cpu_used
        ))
    end
end

-- ─── Reset per frame ───────────────────────────────────────────────────────
function constraints.reset()
    constraints.draws_used = 0
    constraints.cpu_used = 0
end

-- ─── Stats ─────────────────────────────────────────────────────────────────
function constraints.stats()
    return string.format(
        "GPU: %d/%d draws | VRAM: %dKB/%dKB | CPU: %d/%d ops",
        constraints.draws_used, constraints.DRAW_BUDGET,
        constraints.vram_used/1024, constraints.VRAM_BUDGET/1024,
        constraints.cpu_used, constraints.CPU_BUDGET
    )
end

return constraints