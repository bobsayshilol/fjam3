local class = {}

function class.new(root)
    local state = {}
    state.neighbours = {}

    --[[ Graph's non-cyclic, so no need for A*
    state.add_node = function(self, island)
        for idx, node in pairs(self.nodes) do
            if node == island then
                return idx
            end
        end
        table.insert(self.nodes, island)
        return #self.nodes
    end
    state:add_node(root)

    state.add_bridge = function(self, island1, pos1, island2, pos2)
        -- Find locations of the islands
        local idx1 = self:add_node(island1)
        local idx2 = self:add_node(island2)

        -- Save info about the bridge between them
        local info = {
            pos1 = pos1,
            pos2 = pos2,
            dist = (pos1.x - pos2.x) * (pos1.x - pos2.x) + (pos1.y - pos2.y) * (pos1.y - pos2.y)
        }
        local key1 = idx1 .. "_" .. idx2
        local key2 = idx2 .. "_" .. idx1
        state.distances[key1] = info
        state.distances[key2] = info
    end
    --]]

    state.add_node = function(self, node)
        local info = self.neighbours[node]
        if info == nil then
            self.neighbours[node] = {}
        end
    end
    state:add_node(root)

    state.add_bridge = function(self, island1, pos1, island2, pos2)
        assert(island1 ~= island2)

        -- Add new nodes
        self:add_node(island1)
        self:add_node(island2)

        -- Save info about the bridge between them
        self.neighbours[island1][island2] = {
            pos1 = pos1,
            pos2 = pos2
        }
        self.neighbours[island2][island1] = {
            pos1 = pos2,
            pos2 = pos1
        }
    end

    -- Breadth first search
    local build_list = function(neighbours, visited, current_visits)
        local new_visits = {}
        for current, path in pairs(current_visits) do
            for island, info in pairs(neighbours[current]) do
                if visited[island] == nil then
                    visited[island] = true
                    new_visits[island] = { prev = path, current = island }
                end
            end
        end
        return new_visits
    end
    local search_internal = function(neighbours, start, callback)
        local visited = {}
        visited[start] = true

        -- Build the initial list of places to look
        local current_visits = build_list(neighbours, visited, { [start] = { prev = nil, current = start } })

        while true do
            -- Process the current list
            local did_process = false
            for island, path in pairs(current_visits) do
                did_process = true
                local matches = callback(island)
                if matches then
                    return true, path
                end
            end

            if not did_process then
                break
            end

            -- Build the next set of lists
            current_visits = build_list(neighbours, visited, current_visits)
        end

        return false, nil
    end

    -- callback(island) -> matches
    state.search_for = function(self, from, callback, reverse)
        local found, linked_path = search_internal(self.neighbours, from, callback)
        if not found then
            return nil
        end
        -- Squash it
        local path = {}
        while linked_path ~= nil do
            table.insert(path, linked_path.current)
            linked_path = linked_path.prev
        end
        -- Reverse the order
        if not reverse then
            local len = #path
            for i = 0, (len - 1) / 2 do
                local tmp = path[i + 1]
                path[i + 1] = path[len - i]
                path[len - i] = tmp
            end
        end
        return path
    end

    state.get_bridge_info = function(self, island1, island2)
        local info = self.neighbours[island1][island2]
        assert(info ~= nil)
        return info.pos1, info.pos2
    end

    return state
end

--[[

--      |----root----|
--  |-left-|    |--right---|
--  n1    n2   asd      rightright
local root = { name = "root" }
local left = { name = "left" }
local right = { name = "right" }
local rightright = { name = "rightright" }
local asd = { name = "asd" }
local n1 = { name = "n1" }
local n2 = { name = "n2" }
local graph = class.new(root)
graph:add_bridge(root, nil, left, nil)
graph:add_bridge(root, nil, right, nil)
graph:add_bridge(left, nil, n1, nil)
graph:add_bridge(left, nil, n2, nil)
graph:add_bridge(right, nil, asd, nil)
graph:add_bridge(right, nil, rightright, nil)

local function test(from, to)
    local matches = function(island)
        return island.name == to.name
    end
    local path = graph:search_for(from, matches)
    print("Path from " .. from.name .. " to " .. to.name .. ":")
    if path == nil then
        print("\tNo path")
    else
        for _, node in pairs(path) do
            print("\t" .. node.name)
        end
    end
end
test(root, left)
test(root, right)
test(root, n1)
test(root, n2)
test(root, asd)
test(root, rightright)
test(left, right)
test(n1, rightright)
test(n1, asd)
test(root, root)
test(n2, right)
test(n2, n1)

love.event.quit()

--]]

return class
