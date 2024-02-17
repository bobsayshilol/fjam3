local class = {}

function class.load()
end

function class.new()
	local state = {}

	state.enter = function(self)
		love.event.quit()
	end

	state.update = function(self, dt)
		return nil
	end

	return state
end

return class
