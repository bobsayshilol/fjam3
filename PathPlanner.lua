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

function class.build(graph, plan, src_island, dst_island, building)
    -- Find a path from src to resource
    local resource_island = plan.resource_to_building[1]
    local is_resource = function(node)
        return node == resource_island
    end
    local src_to_resource = graph:search_for(src_island, is_resource)
    assert(src_to_resource)

    -- Build the paths
    -- TODO: proper traversal
    local to_res = {}
    for _, island in pairs(src_to_resource) do
        table.insert(to_res, { x = island.position.x, y = island.position.y })
    end
    local to_dst = {}
    for _, island in pairs(plan.resource_to_building) do
        table.insert(to_dst, { x = island.position.x, y = island.position.y })
    end

    -- Reserve space for what we'll take
    local count = resource_island.resource:try_reserve(plan.count)
    assert(count == plan.count)
    local type = resource_island.resource.type
    building:setup_request(type, count)

    return {
        to_res = to_res,
        resource = resource_island.resource,
        type = type,
        count = count,
        to_dst = to_dst,
        destination = dst_island,
        building = building,
    }
end

return class
