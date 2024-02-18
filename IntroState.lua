local class = {}

local intro = {
	"Your people are stranded on a floating island",
	"Build bridges to gather resources",
	"Be wary of monsters",
	"Good luck!"
}

function class.load()
end

function class.new()
	local state = {}
	state.line = 1

	state.enter = function(self)
		local font = love.graphics.getFont()
		font:setFilter("nearest")
		state.allText = love.graphics.newText(font, "")
	end

	state.update = function(self, dt)
		if self.line > #intro then
			return "game"
		else
			return nil
		end
	end

	state.keypressed = function(self, key)
		if key == "space" or key == "return" then
			self.line = self.line + 1
		end
	end

	state.touchpressed = function(self)
		self.line = self.line + 1
	end

	state.draw = function(self)
		state.allText:set(intro[self.line])

		local sw, sh = love.graphics.getDimensions()
		local scale = 4
		local w, h = state.allText:getDimensions()
		love.graphics.draw(state.allText, (sw - scale * w) / 2, (sh - scale * h) / 2, 0, scale, scale)
	end

	state.exit = function(self)
		state.allText = nil
	end

	return state
end

return class
