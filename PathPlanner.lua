local class = {}

function class.try_plan(graph, building_island, building)
    local resources = building:missing_resources()
    for type, count in pairs(resources) do
        -- Search for a node that has the resources
        -- TODO: should probably use a cache here rather than a full search
        local has_resource = function(node)
            local island_res = node.resource
            return
                island_res ~= nil and
                island_res.type == type and
                island_res:available() > 0
        end
        -- We want the reverse so that we end on the building
        local resource_to_building = graph:search_for(building_island, has_resource, true)
        if resource_to_building ~= nil then
            -- Save the type and amount to grab
            local resource_island = resource_to_building[1]
            return {
                resource_to_building = resource_to_building,
                count = math.min(resource_island.resource:available(), count)
            }
        end
    end
    return nil
end

local make_path = function(graph, islands)
    assert(#islands >= 1)

    local prev_island = islands[1]
    table.remove(islands, 1)

    local path = {}
    for _, island in pairs(islands) do
        -- Look for the bridges between this island the previous one
        local info = graph:bridge_info(prev_island, island)
        assert(info)
        prev_island = island
        -- Add the 2 points
        table.insert(path, { x = info.pos1.x, y = info.pos1.y })
        table.insert(path, { x = info.pos2.x, y = info.pos2.y })
    end
    return path
end

function class.build(graph, plan, src_island, dst_island, building)
    -- Find a path from src to resource
    local resource_island = plan.resource_to_building[1]
    local is_resource = function(node)
        return node == resource_island
    end
    local src_to_resource = graph:search_for(src_island, is_resource)
    assert(src_to_resource)
    local resource = resource_island.resource

    -- Build the paths
    local to_res = make_path(graph, src_to_resource)
    table.insert(to_res, resource_island:world_pos(resource))
    local to_dst = make_path(graph, plan.resource_to_building)
    table.insert(to_dst, dst_island:world_pos(building))

    -- Reserve space for what we'll take
    local count = resource:try_reserve(plan.count)
    assert(count == plan.count)
    local type = resource.type
    building:setup_request(type, count)

    return {
        to_res = to_res,
        resource = resource,
        type = type,
        count = count,
        to_dst = to_dst,
        destination = dst_island,
        building = building,
    }
end

return class
