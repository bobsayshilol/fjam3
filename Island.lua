local class = {}

local TileSize = 5
local MinIslandSpeed = 10
local MaxIslandSpeed = 20

local DRAW_DEBUG = false

local Resource = assert(require("Resource"))
local Building = assert(require("Building"))

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
            {
                0 * TileSize, 0 * TileSize,
                3 * TileSize, 0 * TileSize,
                3 * TileSize, 3 * TileSize,
                0 * TileSize, 3 * TileSize,
            }
        }
    },
    Basic = {
        graphics = {
            { x = 0, y = 0 },
            { x = 1, y = 0 },
        },
        physics = {
            {
                0 * TileSize, 0 * TileSize,
                2 * TileSize, 0 * TileSize,
                2 * TileSize, 1 * TileSize,
                0 * TileSize, 1 * TileSize,
            }
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
            {
                0 * TileSize, 0 * TileSize,
                2 * TileSize, 0 * TileSize,
                2 * TileSize, 2 * TileSize,
                0 * TileSize, 2 * TileSize,
            }
        }
    },
    Wide = {
        graphics = {
            { x = 0, y = 0 },
            { x = 1, y = 0 },
            { x = 2, y = 0 },
            { x = 3, y = 0 },
        },
        physics = {
            {
                0 * TileSize, 0 * TileSize,
                4 * TileSize, 0 * TileSize,
                4 * TileSize, 1 * TileSize,
                0 * TileSize, 1 * TileSize,
            }
        }
    },
    L = {
        graphics = {
            { x = 0, y = 0 },
            { x = 1, y = 0 },
            { x = 2, y = 0 },
            { x = 2, y = 1 },
        },
        physics = {
            {
                0 * TileSize, 0 * TileSize,
                3 * TileSize, 0 * TileSize,
                3 * TileSize, 1 * TileSize,
                0 * TileSize, 1 * TileSize,
            },
            {
                2 * TileSize, 1 * TileSize,
                3 * TileSize, 1 * TileSize,
                3 * TileSize, 2 * TileSize,
                2 * TileSize, 2 * TileSize,
            }
        }
    },
    T = {
        graphics = {
            { x = 0, y = 0 },
            { x = 1, y = 0 },
            { x = 2, y = 0 },
            { x = 1, y = 1 },
            { x = 1, y = 2 },
        },
        physics = {
            {
                0 * TileSize, 0 * TileSize,
                3 * TileSize, 0 * TileSize,
                3 * TileSize, 1 * TileSize,
                0 * TileSize, 1 * TileSize,
            },
            {
                1 * TileSize, 1 * TileSize,
                2 * TileSize, 1 * TileSize,
                2 * TileSize, 3 * TileSize,
                1 * TileSize, 3 * TileSize,
            }
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
    state.angle = start and 0 or (love.math.random() * 2 * math.pi)
    state.shape = start and class.Shapes.StartingIsland or random_shape()
    state.locked = not not start
    state.speed_x = -love.math.random(MinIslandSpeed * 10, MaxIslandSpeed * 10) / 10
    state.speed_y = love.math.random(-MinIslandSpeed * 10, MinIslandSpeed * 10) / 20

    -- Physics
    local create_phys = function(self)
        self.body = love.physics.newBody(world, self.position.x, self.position.y, self.locked and "static" or "dynamic")
        self.fixtures = {}
        for _, phys in pairs(self.shape.physics) do
            assert(#phys <= 8)
            assert(love.math.isConvex(phys))
            local shape2d = love.physics.newPolygonShape(phys)
            local fixture = love.physics.newFixture(self.body, shape2d)
            fixture:setUserData(self)
            table.insert(self.fixtures, fixture)
        end
        self.body:setAngle(self.angle)
        self.body:setFixedRotation(self.locked)
    end
    create_phys(state)

    if not start then
        state.body:setAngularVelocity((love.math.random() - 0.5) * math.pi)
    end

    -- Add some resources
    if love.math.random() > 0.6 and not start then
        local type = love.math.random(1, Resource.Types.Max)
        local tile = state.shape.graphics[love.math.random(#state.shape.graphics)]
        local count = love.math.random(10)
        state.resource = Resource.new(type, count, 0, tile)
    else
        state.resource = nil
    end
    state.buildings = {}

    state.delete = function(self)
        self.body:destroy()
    end

    state.lock = function(self)
        self:delete()
        self.locked = true
        create_phys(self)
    end

    state.is_locked = function(self)
        return self.locked
    end

    state.draw = function(self, camera)
        if DRAW_DEBUG then
            love.graphics.setColor(1, 1, 1)
            for _, fixture in pairs(self.fixtures) do
                local x1, y1, x2, y2 = fixture:getBoundingBox()
                local p1 = camera:to_screen({ x = x1, y = y1 })
                local p2 = camera:to_screen({ x = x2, y = y2 })
                love.graphics.polygon("line", p1.x, p1.y, p1.x, p2.y, p2.x, p2.y, p2.x, p1.y)
            end
        end

        local tile_size = TileSize * camera.scale
        local origin = camera:to_screen({
            x = self.position.x,
            y = self.position.y,
        })
        love.graphics.push("transform")
        love.graphics.translate(origin.x, origin.y)
        love.graphics.rotate(self.angle)
        love.graphics.setColor(0, 0.7, 0)
        for _, tile_pos in pairs(self.shape.graphics) do
            love.graphics.rectangle("fill", tile_size * tile_pos.x, tile_size * tile_pos.y, tile_size, tile_size)
        end

        -- Draw the resources that we have
        if self.resource ~= nil then
            self.resource:draw(tile_size)
        end
        for _, building in pairs(self.buildings) do
            building:draw(tile_size)
        end
        love.graphics.pop()
    end

    state.update = function(self, dt)
        self.position.x = self.body:getX()
        self.position.y = self.body:getY()
        self.angle = self.body:getAngle()

        -- All newly spawned islands move to the left
        if not self.locked then
            self.body:setLinearVelocity(self.speed_x, state.speed_y)
        end
    end

    state.world_pos = function(self, resource)
        local transform = love.math.newTransform(0, 0, self.angle)
        local wx, wy = transform:transformPoint((resource.pos.x + 0.5) * TileSize, (resource.pos.y + 0.5) * TileSize)
        wx = wx + self.position.x
        wy = wy + self.position.y
        return { x = wx, y = wy }
    end

    state.try_build = function(self, type, pos)
        -- Map into our space
        local transform = love.math.newTransform(0, 0, -self.angle)
        local px, py = transform:transformPoint(pos.x - self.position.x, pos.y - self.position.y)

        -- Quantize
        px = math.floor(px / TileSize)
        py = math.floor(py / TileSize)
        pos = { x = px, y = py }

        -- Check that we can build it
        if self.resource ~= nil then
            if self.resource.pos.x == pos.x and self.resource.pos.y == pos.y then
                return false
            end
        end
        for _, building in pairs(self.buildings) do
            if building.pos.x == pos.x and building.pos.y == pos.y then
                return false
            end
        end

        -- Build it
        local building = Building.new(type, pos)
        table.insert(self.buildings, building)

        -- Return the center of where it was built in world space
        local wx, wy = transform:inverseTransformPoint((px + 0.5) * TileSize, (py + 0.5) * TileSize)
        wx = wx + self.position.x
        wy = wy + self.position.y
        return true, building, wx, wy
    end

    state.tile_size = function(self)
        return TileSize
    end

    state.hit_test = function(self, pt)
        for _, fixture in pairs(self.fixtures) do
            if fixture:testPoint(pt.x, pt.y) then
                return true
            end
        end
        return false
    end

    return state
end

return class
