local class = {}

local TileSize = 5

class.Shapes = {
    StartingIsland = {
        graphics = {
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
        physics = {
            0 * TileSize, 0 * TileSize,
            3 * TileSize, 0 * TileSize,
            3 * TileSize, 3 * TileSize,
            0 * TileSize, 3 * TileSize,
        }
    },
    Basic = {
        graphics = {
            { x = 0, y = 0 },
            { x = 1, y = 0 },
        },
        physics = {
            0 * TileSize, 0 * TileSize,
            2 * TileSize, 0 * TileSize,
            2 * TileSize, 1 * TileSize,
            0 * TileSize, 1 * TileSize,
        }
    },
    Square = {
        graphics = {
            { x = 0, y = 0 },
            { x = 0, y = 1 },
            { x = 1, y = 0 },
            { x = 1, y = 1 },
        },
        physics = {
            0 * TileSize, 0 * TileSize,
            2 * TileSize, 0 * TileSize,
            2 * TileSize, 2 * TileSize,
            0 * TileSize, 2 * TileSize,
        }
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

function class.new(x, y, world, start)
    local state = {}
    state.position = { x = x, y = y }
    state.shape = start and class.Shapes.StartingIsland or random_shape()

    -- Physics
    state.body = love.physics.newBody(world, x, y, "dynamic")
    local shape2d = love.physics.newPolygonShape(state.shape.physics)
    state.fixture = love.physics.newFixture(state.body, shape2d)
    state.fixture:setUserData(state)

    -- All newly spawned islands move to the left
    if not start then
        state.body:setLinearVelocity(-5, 0)
    end

    state.draw = function(self, camera)
        local tile_size = {
            x = TileSize * camera.scale_x,
            y = TileSize * camera.scale_y,
        }
        for _, tile_pos in pairs(self.shape.graphics) do
            local origin = camera:to_screen({
                x = self.position.x + TileSize * tile_pos.x,
                y = self.position.y + TileSize * tile_pos.y,
            })
            love.graphics.setColor(0, 0.7, 0)
            love.graphics.rectangle("fill", origin.x, origin.y, tile_size.x, tile_size.y)
        end
    end

    state.update = function(self, dt)
        state.position.x = state.body:getX()
        state.position.y = state.body:getY()
    end

    return state
end

return class
