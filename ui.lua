-- ui.lua
local ui = {}

-- Load the RPG font
ui.font_title = love.graphics.newFont("Medieval_Sorcerer_Ornamental.ttf", 28)
ui.font_main = love.graphics.getFont()

ui.col = {
    bg          = {0.08, 0.05, 0.12, 0.85}, -- Deep Shadow Purple
    bg_inner    = {0.12, 0.08, 0.18, 0.85},
    border      = {0.85, 0.65, 0.2,  1   }, -- Arcane Gold
    border_dim  = {0.5,  0.35, 0.1,  1   },
    border_dark = {0.2,  0.1,  0.05, 1   },
    title       = {1.0,  0.8,  0.4,  1   },
    text        = {0.95, 0.9,  0.8,  1   },
    dim         = {0.5,  0.45, 0.4,  1   },
    highlight   = {0.85, 0.65, 0.2,  0.15},
    green       = {0.4,  0.9,  0.5,  1   },
    red         = {0.9,  0.3,  0.3,  1   },
    locked      = {0.3,  0.25, 0.2,  1   },
    weapon_col     = {1,    0.45, 0.45, 1},
    armor_col      = {0.45, 0.75, 1,    1},
    consumable_col = {0.45, 1,    0.55, 1},
}

-- Returns dx, dy for a "breathing" floating effect
function ui.get_drift(intensity)
    intensity = intensity or 4
    local t = love.timer.getTime()
    local dx = math.sin(t * 0.7) * intensity
    local dy = math.cos(t * 0.5) * (intensity * 1.5)
    return dx, dy
end

function ui.set(col)
    love.graphics.setColor(col[1], col[2], col[3], col[4] or 1)
end

-- draws a magical floating panel based on 'rpg ui.png'
function ui.panel(x, y, w, h, r)
    r = r or 0 -- Square corners for this specific style
    local dx, dy = ui.get_drift(5)
    x, y = x + dx, y + dy

    -- Soft Glow
    ui.set({ui.col.border[1], ui.col.border[2], ui.col.border[3], 0.1})
    love.graphics.rectangle("fill", x - 4, y - 4, w + 8, h + 8)

    -- Main background (Deep Blue Gradient feel)
    ui.set(ui.col.bg)
    love.graphics.rectangle("fill", x, y, w, h)
    
    -- Inner light gradient overlay
    ui.set({1, 1, 1, 0.03})
    love.graphics.rectangle("fill", x + 2, y + 2, w - 4, h / 2)

    -- Double Border (The 'RPG UI' style)
    ui.draw_ornamental_border(x, y, w, h)
end

function ui.draw_ornamental_border(x, y, w, h)
    local gap = 3
    love.graphics.setLineWidth(1)
    
    -- Outer Gold Line
    ui.set(ui.col.border)
    love.graphics.rectangle("line", x, y, w, h)
    
    -- Inner Gold Line
    ui.set(ui.col.border_dim)
    love.graphics.rectangle("line", x + gap, y + gap, w - gap*2, h - gap*2)

    -- Center Diamonds
    ui.set(ui.col.border)
    local s = 6 -- Diamond size
    
    -- Top center
    ui.diamond(x + w/2, y, s)
    -- Bottom center
    ui.diamond(x + w/2, y + h, s)
    -- Left center
    ui.diamond(x, y + h/2, s)
    -- Right center
    ui.diamond(x + w, y + h/2, s)
    
    -- Corner accents
    ui.set(ui.col.border)
    local cs = 10
    -- Top Left
    love.graphics.line(x - 2, y + cs, x - 2, y - 2, x + cs, y - 2)
    -- Top Right
    love.graphics.line(x + w - cs, y - 2, x + w + 2, y - 2, x + w + 2, y + cs)
    -- Bottom Left
    love.graphics.line(x - 2, y + h - cs, x - 2, y + h + 2, x + cs, y + h + 2)
    -- Bottom Right
    love.graphics.line(x + w - cs, y + h + 2, x + w + 2, y + h + 2, x + w + 2, y + h - cs)
end

function ui.diamond(x, y, s)
    love.graphics.polygon("fill", x, y - s, x + s, y, x, y + s, x - s, y)
    -- Outline for sharpness
    ui.set(ui.col.border_dark)
    love.graphics.polygon("line", x, y - s, x + s, y, x, y + s, x - s, y)
    ui.set(ui.col.border)
end

function ui.title(text, x, y)
    love.graphics.setFont(ui.font_title)
    -- shadow
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.print(text, x + 2, y + 2)
    ui.set(ui.col.title)
    love.graphics.print(text, x, y)
    love.graphics.setFont(ui.font_main)
end

function ui.text(text, x, y)
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.print(text, x + 1, y + 1)
    ui.set(ui.col.text)
    love.graphics.print(text, x, y)
end

function ui.dim(text, x, y)
    ui.set(ui.col.dim)
    love.graphics.print(text, x, y)
end

function ui.divider(x1, y, x2)
    -- dark line
    ui.set(ui.col.border_dark)
    love.graphics.line(x1, y + 1, x2, y + 1)
    -- gold line
    ui.set(ui.col.border_dim)
    love.graphics.line(x1, y, x2, y)
    -- small center diamond
    local mx = (x1 + x2) / 2
    ui.set(ui.col.border)
    love.graphics.polygon("fill", mx, y - 3, mx + 3, y, mx, y + 3, mx - 3, y)
end

function ui.highlight_row(x, y, w, h)
    -- gold highlight with border
    ui.set(ui.col.highlight)
    love.graphics.rectangle("fill", x, y, w, h, 3)
    ui.set(ui.col.border_dim)
    love.graphics.rectangle("line", x, y, w, h, 3)
end

function ui.button(text, x, y, w, h, is_selected)
    local dx, dy = ui.get_drift(3)
    x, y = x + dx, y + dy

    if is_selected then
        ui.highlight_row(x, y, w, h)
        -- Pulsing border for selection
        local p = math.sin(love.timer.getTime() * 5) * 2
        ui.set(ui.col.title)
        love.graphics.rectangle("line", x - p, y - p, w + p*2, h + p*2, 4)
    else
        ui.set(ui.col.bg_inner)
        love.graphics.rectangle("fill", x, y, w, h, 2)
        ui.set(ui.col.border_dark)
        love.graphics.rectangle("line", x, y, w, h, 2)
    end

    ui.set(is_selected and ui.col.title or ui.col.text)
    local font = love.graphics.getFont()
    local tw = font:getWidth(text)
    local th = font:getHeight()
    love.graphics.print(text, x + w/2 - tw/2, y + h/2 - th/2)
end

function ui.health_bar(x, y, w, h, current, max)
    -- outer border
    ui.set(ui.col.border_dark)
    love.graphics.rectangle("fill", x - 1, y - 1, w + 2, h + 2, 3)

    -- background
    love.graphics.setColor(0.05, 0.02, 0.02, 1)
    love.graphics.rectangle("fill", x, y, w, h, 3)

    -- fill color shifts red to green
    local ratio = math.max(0, current / max)
    local r = 0.15 + (1 - ratio) * 0.75
    local g = 0.75 * ratio
    love.graphics.setColor(r, g, 0.05, 1)
    love.graphics.rectangle("fill", x, y, w * ratio, h, 3)

    -- shine on top
    love.graphics.setColor(1, 1, 1, 0.08)
    love.graphics.rectangle("fill", x, y, w * ratio, h / 2, 3)

    -- gold border
    ui.set(ui.col.border_dim)
    love.graphics.rectangle("line", x, y, w, h, 3)
end

return ui