local class = {}

local IdleTime = 0.5
local WanderTime = 2.5
local MoveSpeed = 5
local WorkerSize = 1

local function change_state(self, new)
    self.action = new
    if new.enter then
        new.enter(self)
    end
end

local function vec_sub(lhs, rhs)
    return {
        x = lhs.x - rhs.x,
        y = lhs.y - rhs.y,
    }
end

local function vec_len(vec)
    return math.sqrt(vec.x * vec.x + vec.y * vec.y)
end

local function vec_norm(vec)
    local len = vec_len(vec)
    if len == 0 then
        return vec
    else
        return { x = vec.x / len, y = vec.y / len }
    end
end

local PlanSteps = {
    Moving = 1,
    AtRes = 2,
    AtDest = 3,
}

local plan_move_to = function(self, queue)
    self.plan_step = PlanSteps.Moving
    self.plan_current_dest = queue[1]
    self.move_direction = vec_norm(vec_sub(self.plan_current_dest, self.position))
    -- Remove that position from the plan
    table.remove(queue, 1)
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
    FollowPlan = {
        enter = function(self)
            self.current_island = nil
            -- Start executing the plan
            plan_move_to(self, self.plan.to_res)
        end,
        update = function(self, dt)
            if self.plan_step == PlanSteps.Moving then
                -- See if we're there
                local dist = vec_len(vec_sub(self.plan_current_dest, self.position))
                if dist < 0.5 then
                    if #self.plan.to_res ~= 0 then
                        plan_move_to(self, self.plan.to_res)
                    elseif self.plan.resource ~= nil then
                        self.plan_step = PlanSteps.AtRes
                    elseif #self.plan.to_dst ~= 0 then
                        plan_move_to(self, self.plan.to_dst)
                    else
                        self.plan_step = PlanSteps.AtDest
                    end
                end
            elseif self.plan_step == PlanSteps.AtRes then
                -- Take the resources
                self.plan.resource:take(self.plan.count)
                self.plan.resource = nil
                -- Keep moving
                plan_move_to(self, self.plan.to_dst)
            elseif self.plan_step == PlanSteps.AtDest then
                -- Add our stuff
                self.plan.building:fill_request(self.plan.type, self.plan.count)
                self.current_island = self.plan.destination
                -- Reset to normal
                self.plan_step = nil
                self.plan = nil
                change_state(self, class.Action.Idle)
            end
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

    state.plan = nil
    state.plan_current_dest = { x = 0, y = 0 }
    state.plan_step = nil

    state.update = function(self, dt)
        -- Movement
        local new_pos = {
            x = self.position.x + self.move_direction.x * MoveSpeed * dt,
            y = self.position.y + self.move_direction.y * MoveSpeed * dt
        }
        -- Clamp to current island if we're not following a path
        local can_move = true
        if self.current_island ~= nil then
            -- TODO: this doesn't handle concave parts of T/L
            for x = 0, 1 do
                for y = 0, 1 do
                    local corner = { x = new_pos.x + x * WorkerSize, y = new_pos.y + y * WorkerSize }
                    if not self.current_island:hit_test(corner) then
                        can_move = false
                    end
                end
            end
        end
        if can_move then
            self.position = new_pos
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

    state.can_take_order = function(self)
        return self.action == class.Action.Idle
    end

    -- consumes the plan
    state.perform_plan = function(self, plan)
        self.plan = plan
        change_state(self, class.Action.FollowPlan)
    end

    state.island = function(self)
        return self.current_island
    end

    return state
end

return class
