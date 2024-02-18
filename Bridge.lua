local class = {}

local MaxBridgeLength = 20
class.MaxBridgeLength = MaxBridgeLength

local BridgeWidth = 0.8

local function vec_len(vec)
    return math.sqrt(vec.x * vec.x + vec.y * vec.y)
end

class.draw = function(camera, pt1_s, pt2_s, allowed)
    if allowed then
        love.graphics.setColor(0, 0, 0.8)
    else
        love.graphics.setColor(0.8, 0, 0)
    end

    local delta = { x = pt2_s.x - pt1_s.x, y = pt2_s.y - pt1_s.y }
    local len = vec_len(delta)
    if len == 0 then
        return
    end
    delta.x = delta.x / len
    delta.y = delta.y / len

    -- If we're too big then don't draw it
    local max_len = MaxBridgeLength * camera.scale
    if len > max_len then
        --assert(not allowed)
        pt2_s = {
            x = pt1_s.x + delta.x * max_len,
            y = pt1_s.y + delta.y * max_len,
        }
    end

    local t = { x = -delta.y, y = delta.x }

    local width = BridgeWidth * camera.scale
    love.graphics.polygon("fill",
        pt1_s.x + width * t.x, pt1_s.y + width * t.y,
        pt1_s.x - width * t.x, pt1_s.y - width * t.y,
        pt2_s.x - width * t.x, pt2_s.y - width * t.y,
        pt2_s.x + width * t.x, pt2_s.y + width * t.y
    )
end

function class.new(pt1, pt2)
    local state = {}
    state.pt1 = pt1
    state.pt2 = pt2

    state.draw = function(self, camera)
        local pt1_s = camera:to_screen(self.pt1)
        local pt2_s = camera:to_screen(self.pt2)
        love.graphics.setColor(0, 0, 0.8)
        class.draw(camera, pt1_s, pt2_s, true)
    end

    return state
end

return class
