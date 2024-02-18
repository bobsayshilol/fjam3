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
            local vx = love.math.random() - 0.5
            local sy = (love.math.random() > 0.5) and -1 or 1
            self.move_direction = {
                x = vx,
                y = sy * math.sqrt(1 - vx * vx)
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

function class.new(x, y)
    local state = {}
    state.position = { x = x, y = y } -- world space
    state.action = class.Action.Idle

    state.idle_timer = 0 -- should trigger a state change immediately
    state.move_direction = { x = 0, y = 0 }
    state.holding_type = nil
    state.holding_count = nil

    state.update = function(self, dt)
        -- Movement
        self.position = {
            x = self.position.x + self.move_direction.x * MoveSpeed * dt,
            y = self.position.y + self.move_direction.y * MoveSpeed * dt
        }

        -- TODO: Clamp to current island

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
