local class = {}

function class.new()
    local state = {}
    state.position = { x = 0, y = 0 }

    state.update = function(self, dt)
    end

    state.draw = function(self, camera)
    end

    return state
end

return class
