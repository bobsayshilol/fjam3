local class = {}

local MoveSpeed = 30
local IslandSpawnTime = 5
local MaxBridgeLength = 20

local Island
local Worker
local IslandGraph

local function vec_len2(vec)
	return vec.x * vec.x + vec.y * vec.y
end

local function clamp_camera(camera)
	local size = 300
	if camera.pos_x > size then camera.pos_x = size end
	if camera.pos_x < -size then camera.pos_x = -size end
	if camera.pos_y > size then camera.pos_y = size end
	if camera.pos_y < -size then camera.pos_y = -size end
end

local function update_camera(camera, dt)
	if love.keyboard.isDown("w", "up") then
		camera.pos_y = camera.pos_y - MoveSpeed * dt / (camera.scale_y / 10)
	end
	if love.keyboard.isDown("s", "down") then
		camera.pos_y = camera.pos_y + MoveSpeed * dt / (camera.scale_y / 10)
	end
	if love.keyboard.isDown("a", "left") then
		camera.pos_x = camera.pos_x - MoveSpeed * dt / (camera.scale_x / 10)
	end
	if love.keyboard.isDown("d", "right") then
		camera.pos_x = camera.pos_x + MoveSpeed * dt / (camera.scale_x / 10)
	end
	clamp_camera(camera)
end

local function try_hit(world, pos)
	local hit = nil
	world:queryBoundingBox(pos.x, pos.y, pos.x, pos.y,
		function(fixture)
			-- Just because the AABB overlaps doesn't mean that it's a hit
			if fixture:testPoint(pos.x, pos.y) then
				hit = fixture:getUserData()
				return false
			end
			return true
		end)
	return hit
end

local function spawn_island(self)
	local island = Island.new(300, 0, self.world)
	table.insert(self.islands, island)
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
			return { x = pos.x / self.scale_x + self.pos_x, y = pos.y / self.scale_y + self.pos_y }
		end
	}

	state.next_island_time = 0

	local BridgeStates = { Idle = 0, Started = 1 }
	state.current_bridge_state = BridgeStates.Idle
	state.bridge_start = nil
	state.bridge_island = nil
	state.bridge_allowed = false

	state.enter = function(self)
		-- Setup physics
		self.world = love.physics.newWorld()

		-- Create the initial island
		local center = self.camera:from_screen({
			x = love.graphics.getPixelWidth() / 2,
			y = love.graphics.getPixelHeight() / 2
		})
		self.islands[1] = Island.new(center.x, center.y, self.world, true)
		self.workers[1] = Worker.new(center.x, center.y)

		self.next_island_time = IslandSpawnTime

		spawn_island(self)
	end

	state.update = function(self, dt)
		-- Movement
		update_camera(self.camera, dt)
		self.world:update(dt)
		-- Update all physics
		for _, island in pairs(self.islands) do
			island:update(dt)
		end

		-- Update worker logic
		for _, worker in pairs(self.workers) do
			worker:update(dt)
		end

		-- Check bridge validity
		if self.bridge_start ~= nil then
			local stop_w = self.camera:from_screen({ x = love.mouse.getX(), y = love.mouse.getY() })
			local delta = { x = stop_w.x - self.bridge_start.x, y = stop_w.y - self.bridge_start.y }
			local hit = try_hit(self.world, stop_w)
			local valid_target = hit ~= nil and hit ~= self.bridge_island
			local size_ok = vec_len2(delta) < MaxBridgeLength * MaxBridgeLength
			self.bridge_allowed = valid_target and size_ok
		end

		-- Spawn any new islands
		self.next_island_time = self.next_island_time - dt
		if self.next_island_time < 0 then
			self.next_island_time = IslandSpawnTime
			spawn_island(self)
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

		-- Current construction
		if self.bridge_start ~= nil then
			if self.bridge_allowed then
				love.graphics.setColor(0, 0, 1)
			else
				love.graphics.setColor(1, 0, 0)
			end
			local start_s = self.camera:to_screen(self.bridge_start)
			local stop_s = { x = love.mouse.getX(), y = love.mouse.getY() }
			love.graphics.line(start_s.x, start_s.y, stop_s.x, stop_s.y)
		end
	end

	state.exit = function(self)
		self.islands = nil
		self.workers = nil
	end

	state.keypressed = function(self, key)
		--print(key)
	end

	state.mousepressed = function(self, x, y, button)
		if button ~= 1 then
			return
		end

		local pos = self.camera:from_screen({ x = x, y = y })
		local hit = try_hit(self.world, pos)

		if self.current_bridge_state == BridgeStates.Idle then
			-- TODO: mustn't be on the "main" land bit
			if hit ~= nil then
				self.bridge_start = pos
				self.bridge_island = hit
				self.current_bridge_state = BridgeStates.Started
			end
		elseif self.current_bridge_state == BridgeStates.Started then
			if hit ~= nil and hit ~= self.bridge_island then
				print("TODO: join islands")
			end
			self.bridge_start = nil
			self.bridge_island = nil
			self.current_bridge_state = BridgeStates.Idle
		end
	end

	state.mousemoved = function(self, x, y, dx, dy)
		if love.mouse.isDown(2) then
			self.camera.pos_x = self.camera.pos_x - dx / self.camera.scale_y
			self.camera.pos_y = self.camera.pos_y - dy / self.camera.scale_y
			clamp_camera(self.camera)
		end
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
