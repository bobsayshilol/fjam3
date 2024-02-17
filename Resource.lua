local class = {}

class.Types = {
    Wood = 1,
    Rock = 2,
}

function class.new(type, count, rate, pos)
    local state = {}
    state.type = type
    state.count = count
    state.rate = rate
    state.pos = pos -- relative to island

    state.update = function(self, dt)
    end

    -- expects to be called from island
    state.draw = function(self)
    end

    return state
end

return class
