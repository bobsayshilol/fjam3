local class = {}

local buttons = {
	{ state = "intro", text = "Start" },
	{ state = "dummy", text = "Options" },
	{ state = "dummy", text = "Credits" },
	{ state = "quit",  text = "Quit" },
}

function class.load()
end

function class.new()
	local state = {}
	state.next = nil
	state.index = 1

	state.enter = function(self)
		local font = love.graphics.getFont()
		font:setFilter("nearest")
		state.allText = love.graphics.newText(font, "")
	end

	state.update = function(self, dt)
		return state.next
	end

	state.keypressed = function(self, key)
		if key == "space" or key == "return" then
			state.next = buttons[self.index].state
		elseif key == "up" then
			self.index = self.index - 1
		elseif key == "down" then
			self.index = self.index + 1
		end
		self.index = ((self.index - 1) % #buttons) + 1
	end

	state.draw = function(self)
		local text = ""
		for i, button in pairs(buttons) do
			if i == self.index then
				text = text .. " - "
			else
				text = text .. "   "
			end
			text = text .. button.text .. "\n"
		end

		-- Update the text
		state.allText:set(text)

		-- Draw it
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
