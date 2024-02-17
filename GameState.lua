local class = {}

local MoveSpeed = 30
local IslandSpawnTime = 3

local Island
local Worker
local IslandGraph

local function update_camera(camera, dt)
	if love.keyboard.isDown("w", "up") then
		camera.pos_y = camera.pos_y - MoveSpeed * dt
	end
	if love.keyboard.isDown("s", "down") then
		camera.pos_y = camera.pos_y + MoveSpeed * dt
	end
	if love.keyboard.isDown("a", "left") then
		camera.pos_x = camera.pos_x - MoveSpeed * dt
	end
	if love.keyboard.isDown("d", "right") then
		camera.pos_x = camera.pos_x + MoveSpeed * dt
	end

	-- Clamp it
	local size = 300
	if camera.pos_x > size then camera.pos_x = size end
	if camera.pos_x < -size then camera.pos_x = -size end
	if camera.pos_y > size then camera.pos_y = size end
	if camera.pos_y < -size then camera.pos_y = -size end
end

local function spawn_island(self)
	self.islands[#self.islands + 1] = Island.new(100, 0)
end

function class.load()
	Island = assert(require("Island"))
	Worker = assert(require("Worker"))
end

function class.new()
	local state = {}
	state.islands = {}
	state.bridges = {}
	state.workers = {}
	state.resources = {}
	state.camera = {
		pos_x = 0,
		pos_y = 0,
		scale_x = 10,
		scale_y = 10,
		to_screen = function(self, pos)
			return { x = self.scale_x * (pos.x - self.pos_x), y = self.scale_y * (pos.y - self.pos_y) }
		end,
		from_screen = function(self, pos)
			return { x = pos.x / self.scale_x + self.pos_x, y = pos.y / self.scale_y - self.pos_y }
		end
	}

	state.next_island_time = 0

	state.enter = function(self)
		local center = self.camera:from_screen({
			x = love.graphics.getPixelWidth() / 2,
			y = love.graphics.getPixelHeight() / 2
		})
		state.islands[1] = Island.new(center.x, center.y, Island.Shapes.StartingIsland)
		state.workers[1] = Worker.new(center.x, center.y)

		state.next_island_time = IslandSpawnTime
	end

	state.update = function(self, dt)
		-- Movement
		update_camera(self.camera, dt)

		-- Spawn any new islands
		self.next_island_time = self.next_island_time - dt
		if self.next_island_time < 0 then
			self.next_island_time = IslandSpawnTime
			spawn_island(self)
		end

		-- Logic
		for _, worker in pairs(self.workers) do
			worker:update(dt)
		end

		return nil
	end

	state.draw = function(self)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Game goes here", 10, 10)

		-- Draw back to front
		for _, island in pairs(self.islands) do
			island:draw(self.camera)
		end
		for _, bridge in pairs(self.bridges) do
			--draw_bridge(bridge)
		end
		for _, worker in pairs(self.workers) do
			worker:draw(self.camera)
		end
	end

	state.exit = function(self)
		self.islands = nil
		state.workers = nil
	end

	state.keypressed = function(self, key)
		--print(key)
	end

	state.wheelmoved = function(self, x, y)
		local speed = 0.4
		local min = 3
		local max = 15
		local scale = self.camera.scale_x + y * speed
		if scale < min then scale = min end
		if scale > max then scale = max end
		self.camera.scale_x = scale
		self.camera.scale_y = scale
	end

	return state
end

return class
