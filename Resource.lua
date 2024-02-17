local class = {}

class.Types = {
    Wood = 1,
    Rock = 2,
}

function class.new(type, count, rate, pos)
    local state = {}
    state.type = type
    state.count = count
    --state.rate = rate
    state.pos = pos -- relative to island

    state.update = function(self, dt)
    end

    -- expects to be called from island
    state.draw = function(self, tile_size)
        if self.type == class.Types.Wood then
            love.graphics.setColor(0.6, 0.3, 0)
        elseif self.type == class.Types.Rock then
            love.graphics.setColor(0.4, 0.4, 0.4)
        end
        local inset = 0.1
        love.graphics.rectangle("fill",
            tile_size * (self.pos.x + inset), tile_size * (self.pos.y + inset),
            tile_size * (1 - 2 * inset), tile_size * (1 - 2 * inset)
        )
    end

    return state
end

return class
