local class = {}

class.Types = {
    Wood = 1,
    Rock = 2,

    Max = 2,
}

local fonts = {}
local function get_font(height)
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

    state.update = function(self, dt)
    end

    -- expects to be called from island
    state.draw = function(self, tile_size)
        if self.type == class.Types.Wood then
            love.graphics.setColor(0.6, 0.3, 0)
        elseif self.type == class.Types.Rock then
            love.graphics.setColor(0.4, 0.4, 0.4)
        end

        local inset = 0.1
        local size = tile_size * (1 - 2 * inset)
        love.graphics.rectangle("fill",
            tile_size * (self.pos.x + inset), tile_size * (self.pos.y + inset),
            size, size
        )

        local text = get_text(size, self.count)
        love.graphics.setColor(0, 0, 0)
        love.graphics.draw(text, tile_size * (self.pos.x + inset), tile_size * (self.pos.y + inset))
    end

    return state
end

return class
