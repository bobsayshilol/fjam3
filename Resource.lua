local class = {}

class.Types = {
    Wood = 1,
    Rock = 2,
    Yellow = 3,
    Max = 3,
}

local fonts = {}
local function get_font(height)
    height = math.floor(height * 2) / 2
    local font = fonts[height]
    if font == nil then
        font = love.graphics.newFont(height)
        fonts[height] = font
    end
    return font
end
local texts = {}
local function get_text(height, count)
    local key = height .. "_" .. count
    local text = texts[key]
    if text == nil then
        local font = get_font(height)
        text = love.graphics.newText(font, count)
        texts[key] = text
    end
    return text
end


function class.new(type, count, rate, pos)
    local state = {}
    state.type = type
    state.count = count
    --state.rate = rate
    state.pos = pos -- relative to island

    if state.type == class.Types.Wood then
        state.colour = { 0.6, 0.3, 0 }
    elseif state.type == class.Types.Rock then
        state.colour = { 0.4, 0.4, 0.4 }
    elseif state.type == class.Types.Yellow then
        state.colour = { 1, 1, 0.6 }
    end

    state.update = function(self, dt)
    end

    -- expects to be called from island
    state.draw = function(self, tile_size)
        love.graphics.setColor(self.colour)

        local inset = 0.1
        local size = tile_size * (1 - 2 * inset)
        love.graphics.rectangle("fill",
            tile_size * (self.pos.x + inset), tile_size * (self.pos.y + inset),
            size, size
        )

        local text = get_text(size * 0.75, self.count)
        love.graphics.setColor(0, 0, 0)
        love.graphics.draw(text, tile_size * (self.pos.x + inset), tile_size * (self.pos.y + inset))
    end

    return state
end

return class
