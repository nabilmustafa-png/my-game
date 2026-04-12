-- camera.lua
local camera = {}

camera.x = 0
camera.y = 0
camera.target_x = 0
camera.target_y = 0
camera.smoothing = 5 -- Lower is smoother, higher is more instant

function camera.update(dt, player_x, player_y, sw, sh, map_w, map_h)
    -- Target the center of the player
    camera.target_x = player_x - sw / 2
    camera.target_y = player_y - sh / 2

    -- Clamp camera to map boundaries so we don't see the "void"
    camera.target_x = math.max(0, math.min(map_w - sw, camera.target_x))
    camera.target_y = math.max(0, math.min(map_h - sh, camera.target_y))

    -- Interpolate for smooth following
    camera.x = camera.x + (camera.target_x - camera.x) * camera.smoothing * dt
    camera.y = camera.y + (camera.target_y - camera.y) * camera.smoothing * dt
end

function camera.apply()
    love.graphics.push()
    love.graphics.translate(-math.floor(camera.x), -math.floor(camera.y))
end

function camera.detach()
    love.graphics.pop()
end

return camera