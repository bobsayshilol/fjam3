local class = {}

function class.load()
end

function class.new()
	local state = {}
	state.next = nil
	state.nameText = nil
	state.nameText2 = nil
	state.bottomText = nil

	state.enter = function(self)
		local text = {
			{ 1, 0, 0 }, "GAME",
			{ 0, 0, 0 }, " ",
			{ 0, 1, 0 }, "JAME",
			{ 0, 0, 0 }, " ",
			{ 0, 0, 1 }, "GAME",
		}
		local font = love.graphics.getFont()
		font:setFilter("nearest")
		state.nameText = love.graphics.newText(font, text)
		state.nameText2 = love.graphics.newText(font, "3")
		state.bottomText = love.graphics.newText(font, "Press space to start")
	end

	state.update = function(self, dt)
		return "game"
		--return state.next
	end

	state.keypressed = function(self, key)
		if key == "space" or key == "return" then
			state.next = "menu"
		end
	end

	state.touchpressed = function(self)
		state.next = "intro"
	end

	state.draw = function(self)
		local sw, sh = love.graphics.getDimensions()
		local ns = 10
		local n2s = 20
		local bs = 4

		local nw, nh = state.nameText:getDimensions()
		local nw2, nh2 = state.nameText2:getDimensions()

		local nx = (sw - (ns * nw + n2s * nw2)) / 2
		local ny = (sh - ns * nh) * 1 / 3
		love.graphics.draw(state.nameText, nx, ny, 0, ns, ns)
		love.graphics.draw(state.nameText2, nx + ns * nw, ny - (n2s * nw2) / 2, 0, n2s, n2s)

		local bw, bh = state.bottomText:getDimensions()
		love.graphics.draw(state.bottomText, (sw - bs * bw) / 2, (sh - bs * bh) * 2 / 3, 0, bs, bs)
	end

	state.exit = function(self)
		state.nameText = nil
		state.bottomText = nil
	end

	return state
end

return class
