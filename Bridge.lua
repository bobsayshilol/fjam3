local class = {}

local BridgeWidth = 0.8

class.draw = function(camera, pt1_s, pt2_s, allowed)
    if allowed then
        love.graphics.setColor(0, 0, 0.8)
    else
        love.graphics.setColor(0.8, 0, 0)
    end

    local t = { x = -(pt2_s.y - pt1_s.y), y = pt2_s.x - pt1_s.x }
    local l = math.sqrt(t.x * t.x + t.y * t.y)
    if l < 0.1 then return end
    t.x = t.x / l
    t.y = t.y / l

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
