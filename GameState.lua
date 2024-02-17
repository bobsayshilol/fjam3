local class = {}

local MoveSpeed = 30

local Island
local Worker
local IslandGraph

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

	state.enter = function(self)
		local center = self.camera:from_screen({
			x = love.graphics.getPixelWidth() / 2,
			y = love.graphics.getPixelHeight() / 2
		})
		state.islands[1] = Island.new(center.x, center.y, Island.Shapes.StartingIsland)
		state.workers[1] = Worker.new(center.x, center.y)
	end

	state.update = function(self, dt)
		-- Movement
		if love.keyboard.isDown("w", "up") then
			self.camera.pos_y = self.camera.pos_y - MoveSpeed * dt
		end
		if love.keyboard.isDown("s", "down") then
			self.camera.pos_y = self.camera.pos_y + MoveSpeed * dt
		end
		if love.keyboard.isDown("a", "left") then
			self.camera.pos_x = self.camera.pos_x - MoveSpeed * dt
		end
		if love.keyboard.isDown("d", "right") then
			self.camera.pos_x = self.camera.pos_x + MoveSpeed * dt
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

	return state
end

return class
