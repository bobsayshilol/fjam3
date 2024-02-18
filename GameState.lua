local class = {}

local MoveSpeed = 30
local IslandSpawnTime = 0.8

local Island
local Worker
local Bridge
local Building
local IslandGraph
local PathPlanner

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
		camera.pos_y = camera.pos_y - MoveSpeed * dt / (camera.scale / 10)
	end
	if love.keyboard.isDown("s", "down") then
		camera.pos_y = camera.pos_y + MoveSpeed * dt / (camera.scale / 10)
	end
	if love.keyboard.isDown("a", "left") then
		camera.pos_x = camera.pos_x - MoveSpeed * dt / (camera.scale / 10)
	end
	if love.keyboard.isDown("d", "right") then
		camera.pos_x = camera.pos_x + MoveSpeed * dt / (camera.scale / 10)
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

local function is_bridge_allowed(self, hit, stop_w)
	local valid_target = hit ~= nil and hit ~= self.bridge_island and not hit:is_locked()
	local delta = { x = stop_w.x - self.bridge_start.x, y = stop_w.y - self.bridge_start.y }
	local size_ok = vec_len2(delta) < Bridge.MaxBridgeLength * Bridge.MaxBridgeLength
	return valid_target and size_ok
end

local function spawn_island(self)
	-- TODO: search space should extend as stuff gets added
	-- TODO: query for sections above and below our current bit
	local y = love.math.random(-100, 100)
	local island = Island.new(300, y, self.world)
	table.insert(self.islands, island)
end

function class.load()
	Island = assert(require("Island"))
	Worker = assert(require("Worker"))
	Bridge = assert(require("Bridge"))
	Building = assert(require("Building"))
	IslandGraph = assert(require("IslandGraph"))
	PathPlanner = assert(require("PathPlanner"))
end

function class.new()
	local state = {}
	state.islands = {}
	state.bridges = {}
	state.workers = {}
	state.resources = {}
	state.orders = {}
	state.turrets = {}
	state.monsters = {}
	state.camera = {
		pos_x = 0,
		pos_y = 0,
		scale = 10,
		to_screen = function(self, pos)
			return { x = self.scale * (pos.x - self.pos_x), y = self.scale * (pos.y - self.pos_y) }
		end,
		from_screen = function(self, pos)
			return { x = pos.x / self.scale + self.pos_x, y = pos.y / self.scale + self.pos_y }
		end
	}

	state.next_island_time = 0

	local MouseStates = {
		Idle = 0,
		Bridge = 1,
		Building = 2,
	}
	state.current_mouse_state = MouseStates.Idle

	state.bridge_start = nil
	state.bridge_island = nil
	state.bridge_allowed = false

	state.building_type = nil

	state.enter = function(self)
		-- Setup physics
		self.world = love.physics.newWorld()

		-- Move the camera to the center
		local center = self.camera:from_screen({
			x = love.graphics.getPixelWidth() / 2,
			y = love.graphics.getPixelHeight() / 2
		})
		self.camera.pos_x = -center.x
		self.camera.pos_y = -center.y

		-- Create the initial island
		local base = Island.new(0, 0, self.world, true)
		table.insert(self.islands, base)
		local did_build = base:try_build(Building.Types.Base, { x = 0, y = 0 })
		assert(did_build)
		-- Add some workers to it
		for i = 1, 5 do
			table.insert(self.workers, Worker.new(1, 1, base))
		end

		-- Spawn some floating ones
		for i = 1, 5 do
			spawn_island(self)
		end
		self.next_island_time = IslandSpawnTime

		-- Setup the graph
		self.graph = IslandGraph.new(self.islands[1])
	end

	state.update = function(self, dt)
		-- Movement
		update_camera(self.camera, dt)
		self.world:update(dt)
		-- Update all physics
		local to_clear = {}
		for key, island in pairs(self.islands) do
			island:update(dt)
			if island.position.x < -300 then
				table.insert(to_clear, key)
			end
		end

		-- Cleanup islands
		for _, key in pairs(to_clear) do
			local island = self.islands[key]
			island:delete()
			self.islands[key] = nil
		end

		-- Update worker logic
		for _, worker in pairs(self.workers) do
			worker:update(dt)
		end

		-- Update turrets logic
		for _, turret in pairs(self.turrets) do
			--turret:update(dt)
		end

		-- Remove any completed orders from the order list
		local remove_buildings = {}
		for building, island in pairs(self.orders) do
			if not building:needs_resources() then
				table.insert(remove_buildings, building)
				-- Trigger any on-built stuff
				local pos = island:world_pos(building)
				if building.type == Building.Types.Hut then
					-- Spawn a worker with each hut
					table.insert(self.workers, Worker.new(pos.x, pos.y, island))
				elseif building.type == Building.Types.House then
					-- Spawn 4 workers for each house
					for _ = 1, 4 do
						table.insert(self.workers, Worker.new(pos.x, pos.y, island))
					end
				elseif building.type == Building.Types.Turret then
					table.insert(self.turrets, building)
				end
			end
		end
		for _, building in pairs(remove_buildings) do
			self.orders[building] = nil
		end

		-- TODO: optimise this - we should be caching what resources need to go where, only rebuilding on bridge build
		--
		-- See if we can issue new orders
		for building, island in pairs(self.orders) do
			local plan = PathPlanner.try_plan(self.graph, island, building)
			if plan ~= nil then
				-- TODO: this will pick a random one rather than the most appropriate one, ah well
				for _, worker in pairs(self.workers) do
					if worker:can_take_order() then
						local built_plan = PathPlanner.build(self.graph, plan, worker:island(), island, building)
						worker:perform_plan(built_plan)
						break
					end
				end
			end
		end

		-- Check bridge validity
		if self.bridge_start ~= nil then
			local stop_w = self.camera:from_screen({ x = love.mouse.getX(), y = love.mouse.getY() })
			local hit = try_hit(self.world, stop_w)
			self.bridge_allowed = is_bridge_allowed(self, hit, stop_w)
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
		-- Draw back to front
		for _, island in pairs(self.islands) do
			island:draw(self.camera)
		end
		for _, bridge in pairs(self.bridges) do
			bridge:draw(self.camera)
		end
		for _, worker in pairs(self.workers) do
			worker:draw(self.camera)
		end

		-- Current construction
		if self.bridge_start ~= nil then
			local start_s = self.camera:to_screen(self.bridge_start)
			local stop_s = { x = love.mouse.getX(), y = love.mouse.getY() }
			Bridge.draw(self.camera, start_s, stop_s, self.bridge_allowed)
		end

		-- TODO: stats
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Currently building: " .. Building.to_string(state.building_type), 10, 10)
		love.graphics.print("Num workers: " .. #self.workers, 10, 25)

		-- TODO: UI for building things
	end

	state.exit = function(self)
		for _, island in pairs(self.islands) do
			island:delete()
		end
		self.islands = nil
		self.bridge = nil
		self.workers = nil
		self.resources = nil
		self.graph = nil

		-- Finally destroy the world
		self.world:destroy()
	end

	state.keypressed = function(self, key)
		--print(key)

		-- Pick between type
		if self.current_mouse_state == MouseStates.Idle or self.current_mouse_state == MouseStates.Building then
			if key == "1" then
				self.current_mouse_state = MouseStates.Idle
				state.building_type = nil
			elseif key == "2" then
				self.current_mouse_state = MouseStates.Building
				self.building_type = Building.Types.Hut
			elseif key == "3" then
				self.current_mouse_state = MouseStates.Building
				self.building_type = Building.Types.House
			elseif key == "4" then
				self.current_mouse_state = MouseStates.Building
				self.building_type = Building.Types.Turret
			end
		end
	end

	state.mousepressed = function(self, x, y, button)
		-- TODO: may need to handle other input
		if button ~= 1 then
			return
		end

		local pos = self.camera:from_screen({ x = x, y = y })
		local hit = try_hit(self.world, pos)
		local did_build = false

		if self.current_mouse_state == MouseStates.Idle then
			-- Must be locked (ie on the "main" land bit)
			if hit ~= nil and hit:is_locked() then
				self.bridge_start = pos
				self.bridge_island = hit
				self.current_mouse_state = MouseStates.Bridge
			end
		elseif self.current_mouse_state == MouseStates.Bridge then
			local deselect = hit == nil
			if is_bridge_allowed(self, hit, pos) then
				hit:lock()
				table.insert(self.bridges, Bridge.new(self.bridge_start, pos))
				self.graph:add_bridge(self.bridge_island, self.bridge_start, hit, pos)
				deselect = true
				did_build = true
			end
			if deselect then
				self.bridge_start = nil
				self.bridge_island = nil
				self.current_mouse_state = MouseStates.Idle
			end
		elseif self.current_mouse_state == MouseStates.Building then
			if hit ~= nil and hit:is_locked() then
				local built, building, wx, wy = hit:try_build(self.building_type, pos)
				if built then
					self.orders[building] = hit
					did_build = true
				end
			end
		end

		if did_build then
			-- TOOD: could trigger workers here
		end
	end

	state.mousemoved = function(self, x, y, dx, dy)
		-- Pan with right click
		if love.mouse.isDown(2) then
			self.camera.pos_x = self.camera.pos_x - dx / self.camera.scale
			self.camera.pos_y = self.camera.pos_y - dy / self.camera.scale
			clamp_camera(self.camera)
		end
	end

	state.wheelmoved = function(self, x, y)
		-- Zoom
		local speed = 0.4
		local min = 8
		local max = 15
		local scale = self.camera.scale + y * speed
		if scale < min then scale = min end
		if scale > max then scale = max end
		self.camera.scale = scale
		self.camera.scale = scale
	end

	return state
end

return class
