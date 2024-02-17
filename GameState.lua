local class = {}

function class.load()
end

function class.new()
	local state = {}
	state.next = nil

	state.enter = function(self)
	end

	state.update = function(self, dt)
		return self.next
	end

	state.mousemoved = function(self, x, y)
		self.mouse = { x = x, y = y }
	end

	state.touchmoved = function(self, id, x, y)
		self.mouse = { x = x, y = y }
	end

	state.touchpressed = function(self)
	end

	state.draw = function(self)
		love.graphics.print("Game goes here", 10, 10)
	end

	state.exit = function(self)
		self.grid = nil
	end

	return state
end

return class
