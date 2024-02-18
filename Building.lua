local class = {}

local Resource = assert(require("Resource"))

class.Types = {
    Base = 0,
    Hut = 1,
    House = 2,
    Turret = 3,
    Max = 3,
}

class.to_string = function(type)
    if type == nil then
        -- HACK: used to mean bridges
        return "bridge"
    elseif type == class.Types.House then
        return "house"
    elseif type == class.Types.Turret then
        return "turret"
    end
end

function class.new(type, pos)
    local state = {}
    state.type = type
    state.pos = pos -- relative to island

    if state.type == class.Types.Base then
        state.colour = { 0, 0, 1 }
        state.missing = nil
    elseif state.type == class.Types.House then
        state.colour = { 0.8, 0.8, 0.8 }
        state.missing = {
            [Resource.Types.Rock] = 20,
            [Resource.Types.Wood] = 30,
        }
    elseif state.type == class.Types.House then
        state.colour = { 1, 1, 1 }
        state.missing = {
            [Resource.Types.Rock] = 50,
            [Resource.Types.Wood] = 80,
            [Resource.Types.Yellow] = 40,
        }
    elseif state.type == class.Types.Turret then
        state.colour = { 0, 1, 1 }
        state.missing = {
            [Resource.Types.Rock] = 10,
            [Resource.Types.Wood] = 10,
            [Resource.Types.Yellow] = 50,
        }
    end

    state.is_built = function()
        return state.missing == nil
    end

    state.update = function(self, dt)
    end

    -- expects to be called from island
    state.draw = function(self, tile_size)
        love.graphics.setColor(self.colour)

        local inset = 0.1
        local size = tile_size * (1 - 2 * inset)
        love.graphics.rectangle("fill",
            tile_size * (self.pos.x + inset), tile_size * (self.pos.y + inset),
            size, size
        )

        if not self:is_built() then
            love.graphics.setColor(0, 0, 0)
            love.graphics.line(
                tile_size * (self.pos.x + inset), tile_size * (self.pos.y + inset),
                tile_size * (self.pos.x + 1 - inset), tile_size * (self.pos.y + 1 - inset)
            )
            love.graphics.line(
                tile_size * (self.pos.x + inset), tile_size * (self.pos.y + 1 - inset),
                tile_size * (self.pos.x + 1 - inset), tile_size * (self.pos.y + inset)
            )
        end
    end

    return state
end

return class
