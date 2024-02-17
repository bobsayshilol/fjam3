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

	-- Clamp it
	local size = 300
	if camera.pos_x > size then camera.pos_x = size end
	if camera.pos_x < -size then camera.pos_x = -size end
	if camera.pos_y > size then camera.pos_y = size end
	if camera.pos_y < -size then camera.pos_y = -size end
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

	state.enter = function(self)
		-- Setup physics
		self.world = love.physics.newWorld()

		-- Create the initial island
		local center = self.camera:from_screen({
			x = love.graphics.getPixelWidth() / 2,
			y = love.graphics.getPixelHeight() / 2
		})
		state.islands[1] = Island.new(center.x, center.y, self.world, true)
		state.workers[1] = Worker.new(center.x, center.y)

		state.next_island_time = IslandSpawnTime

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
		if state.bridge_start ~= nil then
			local start_s = self.camera:to_screen(state.bridge_start)
			local stop_s = { x = love.mouse.getX(), y = love.mouse.getY() }
			local stop_w = self.camera:from_screen(stop_s)
			local delta = { x = stop_w.x - state.bridge_start.x, y = stop_w.y - state.bridge_start.y }
			if vec_len2(delta) > MaxBridgeLength * MaxBridgeLength then
				love.graphics.setColor(1, 0, 0)
			else
				love.graphics.setColor(0, 0, 1)
			end
			love.graphics.line(start_s.x, start_s.y, stop_s.x, stop_s.y)
		end
	end

	state.exit = function(self)
		self.islands = nil
		state.workers = nil
	end

	state.keypressed = function(self, key)
		--print(key)
	end

	state.mousepressed = function(self, x, y, button)
		local pos = self.camera:from_screen({ x = x, y = y })
		local try_hit = function()
			local hit = nil
			self.world:queryBoundingBox(pos.x, pos.y, pos.x, pos.y,
				function(fixture)
					-- Just because the AABB overlaps doesn't mean that it's a hit
					if fixture:testPoint(pos.x, pos.y) then
						hit = fixture:getUserData()
						return false
					end
					return true
				end)
			-- TODO: mustn't be on the "main" land bit
			return hit
		end

		if state.current_bridge_state == BridgeStates.Idle then
			local hit = try_hit()
			if hit ~= nil then
				state.bridge_start = pos
				state.bridge_island = hit
				state.current_bridge_state = BridgeStates.Started
			end
		elseif state.current_bridge_state == BridgeStates.Started then
			local hit = try_hit()
			if hit ~= nil and hit ~= state.bridge_island then
				print("TODO: join islands")
			end
			state.bridge_start = nil
			state.bridge_island = nil
			state.current_bridge_state = BridgeStates.Idle
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
