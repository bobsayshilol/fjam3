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
    elseif type == class.Types.Hut then
        return "hut"
    elseif type == class.Types.House then
        return "house"
    elseif type == class.Types.Turret then
        return "turret"
    end
    assert("forgot " .. type)
end

function class.new(type, pos)
    local state = {}
    state.type = type
    state.pos = pos -- relative to island

    if state.type == class.Types.Base then
        state.colour = { 0, 0, 1 }
        state.missing = {}
    elseif state.type == class.Types.Hut then
        state.colour = { 0.8, 0.8, 0.5 }
        state.missing = {
            [Resource.Types.Rock] = { remain = 20, reserved = 0 },
            [Resource.Types.Wood] = { remain = 30, reserved = 0 },
        }
    elseif state.type == class.Types.House then
        state.colour = { 1, 1, 1 }
        state.missing = {
            [Resource.Types.Rock] = { remain = 50, reserved = 0 },
            [Resource.Types.Wood] = { remain = 80, reserved = 0 },
            [Resource.Types.Yellow] = { remain = 40, reserved = 0 },
        }
    elseif state.type == class.Types.Turret then
        state.colour = { 0, 1, 1 }
        state.missing = {
            [Resource.Types.Rock] = { remain = 10, reserved = 0 },
            [Resource.Types.Wood] = { remain = 10, reserved = 0 },
            [Resource.Types.Yellow] = { remain = 50, reserved = 0 },
        }
    end

    state.is_built = function(self)
        if self.missing ~= nil then
            for res, counts in pairs(self.missing) do
                return false
            end
        end
        return true
    end

    state.needs_resources = function(self)
        if self.missing ~= nil then
            for res, counts in pairs(self.missing) do
                local needed = counts.remain - counts.reserved
                if needed > 0 then
                    return true
                end
            end
        end
        return false
    end

    state.missing_resources = function(self)
        local resources = {}
        if self.missing ~= nil then
            for res, counts in pairs(self.missing) do
                local needed = counts.remain - counts.reserved
                if needed > 0 then
                    resources[res] = needed
                end
            end
        end
        return resources
    end

    state.setup_request = function(self, res, count)
        -- Decrement count
        local info = self.missing[res]
        assert(info ~= nil)
        assert(info.remain >= info.reserved + count)
        info.reserved = info.reserved + count
    end

    state.fill_request = function(self, res, count)
        -- Decrement count
        local info = self.missing[res]
        assert(info ~= nil)
        assert(info.remain >= count)
        assert(info.reserved >= count)
        info.remain = info.remain - count
        info.reserved = info.reserved - count

        -- Remove it if it's been fulfilled
        if info.remain == 0 then
            self.missing[res] = nil
        end
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
