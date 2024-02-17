local class = {}

function class.new(x, y)
    local state = {}
    state.position = { x = x, y = y }
    state.shape = {}
    state.bridges = {}

    state.draw = function(self)

    end

    return state
end

return class
