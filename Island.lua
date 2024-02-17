local class = {}

local TileSize = 5

class.Shapes = {
    StartingIsland = {
        { x = 0, y = 0 },
        { x = 0, y = 1 },
        { x = 0, y = 2 },
        { x = 1, y = 0 },
        { x = 1, y = 1 },
        { x = 1, y = 2 },
        { x = 2, y = 0 },
        { x = 2, y = 1 },
        { x = 2, y = 2 },
    },
    Basic = {
        { x = 0, y = 0 },
        { x = 1, y = 0 },
    },
    Square = {
        { x = 0, y = 0 },
        { x = 0, y = 1 },
        { x = 1, y = 0 },
        { x = 1, y = 1 },
    },
}

local function random_shape()
    local count = 0
    for k, v in pairs(class.Shapes) do
        count = count + 1
    end
    local idx = love.math.random(count - 1)
    for k, v in pairs(class.Shapes) do
        if v ~= class.Shapes.StartingIsland then
            idx = idx - 1
            if idx == 0 then
                return v
            end
        end
    end
end

function class.new(x, y, shape)
    local state = {}
    state.position = { x = x, y = y }
    state.shape = shape or random_shape()

    state.draw = function(self, camera)
        local tile_size = {
            x = TileSize * camera.scale_x,
            y = TileSize * camera.scale_y,
        }
        for _, tile_pos in pairs(self.shape) do
            local origin = camera:to_screen({
                x = self.position.x + TileSize * tile_pos.x,
                y = self.position.y + TileSize * tile_pos.y,
            })
            love.graphics.setColor(0, 0.7, 0)
            love.graphics.rectangle("fill", origin.x, origin.y, tile_size.x, tile_size.y)
        end
    end

    return state
end

return class
