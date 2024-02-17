local class = {}

class.Types = {
    Wood = 1,
    Rock = 2,
}

function class.new(type, count, rate)
    local state = {}
    state.type = type
    state.count = count
    state.rate = rate

    state.update = function(self, dt)
    end

    state.draw = function(self)
    end

    return state
end

return class
