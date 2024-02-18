local class = {}

local IdleTime = 0.5
local WanderTime = 2.5
local MoveSpeed = 2
local WorkerSize = 1

local function change_state(self, new)
    self.action = new
    if new.enter then
        new.enter(self)
    end
end

class.Action = {
    Idle = {
        enter = function(self)
            self.idle_timer = IdleTime
            self.move_direction = { x = 0, y = 0 }
        end,
        update = function(self, dt)
            self.idle_timer = self.idle_timer - dt
            if self.idle_timer < 0 then
                -- TODO: detect what to do next
                change_state(self, class.Action.Wander)
            end
        end,
    },
    Wander = {
        enter = function(self)
            self.idle_timer = WanderTime
            local angle = love.math.random() * 2 * math.pi
            self.move_direction = {
                x = math.cos(angle),
                y = math.sin(angle)
            }
        end,
        update = function(self, dt)
            self.idle_timer = self.idle_timer - dt
            if self.idle_timer < 0 then
                change_state(self, class.Action.Idle)
            end
        end,
    },
    FollowPath = {
        update = function(self, dt)

        end,
    },
}

function class.new(x, y, island)
    local state = {}
    state.position = { x = x, y = y } -- world space
    state.action = class.Action.Idle

    state.current_island = island
    state.idle_timer = 0 -- should trigger a state change immediately
    state.move_direction = { x = 0, y = 0 }
    state.holding_type = nil
    state.holding_count = nil

    state.update = function(self, dt)
        -- Movement
        local new_pos = {
            x = self.position.x + self.move_direction.x * MoveSpeed * dt,
            y = self.position.y + self.move_direction.y * MoveSpeed * dt
        }
        -- Clamp to current island if we're not following a path
        if self.current_island ~= nil then
            local corner = { x = new_pos.x + WorkerSize, y = new_pos.y + WorkerSize }
            if self.current_island:hit_test(new_pos) and self.current_island:hit_test(corner) then
                self.position = new_pos
            end
        end

        self.action.update(self, dt)
    end

    state.draw = function(self, camera)
        local size = WorkerSize * camera.scale
        local pos = camera:to_screen({
            x = self.position.x,
            y = self.position.y,
        })
        love.graphics.setColor(0.9, 0.9, 0.2)
        love.graphics.rectangle("fill", pos.x, pos.y, size, size)
    end

    return state
end

return class
