
local y_spread = math.max(1 + gravelsieve.settings.ore_max_elevation - gravelsieve.settings.ore_min_elevation, 1)
local function calculate_probability(item)
    local ymax = math.min(item.y_max, gravelsieve.settings.ore_max_elevation)
    local ymin = math.max(item.y_min, gravelsieve.settings.ore_min_elevation)
    return item.clust_scarcity / (item.clust_num_ores * ((ymax - ymin) / y_spread))
end

local function parse_drop(drop)
    local d, count = drop:match("^%s*(%S+)%s+(%d+)%s*$")
    if d and count then
        return d, count
    end
    d, count = drop:match("%s*craft%s+\"?([^%s\"]+)\"?%s+(%d+)%s*")
    if d and count then
        return d, count
    end
    return drop, 1
end

-- collect all registered ores and calculate the probability
function gravelsieve.api.get_ore_frequencies()
    local ore_frequencies = {}
    for _,item in  pairs(minetest.registered_ores) do
        if minetest.registered_nodes[item.ore] then
            local drop = minetest.registered_nodes[item.ore].drop
            if type(drop) == "string"
            and drop ~= item.ore
            and drop ~= ""
            and item.ore_type == "scatter"
            and item.wherein == "default:stone"
            and item.clust_scarcity ~= nil and item.clust_scarcity > 0
            and item.clust_num_ores ~= nil and item.clust_num_ores > 0
            and item.y_max ~= nil and item.y_min ~= nil then
                local count
                drop, count = parse_drop(drop)

                local probability = calculate_probability(item)
                if probability > 0 then
                    local probabilityFraction = count / probability
                    local cur_probability = ore_frequencies[drop]
                    if cur_probability then
                        ore_frequencies[drop] = cur_probability+probabilityFraction
                    else
                        ore_frequencies[drop] = probabilityFraction
                    end
                end
            end
        end
    end
    return ore_frequencies
end

local function pairs_by_values(t, f)
    if not f then
        f = function(a, b) return a > b end
    end
    local s = {}
    for k, v in pairs(t) do
        table.insert(s, {k, v})
    end
    table.sort(s, function(a, b)
        return f(a[2], b[2])
    end)
    local i = 0
    return function()
        i = i + 1
        local v = s[i]
        if v then
            return unpack(v)
        else
            return nil
        end
    end
end

function gravelsieve.api.report_probabilities(probabilities)
    gravelsieve.log("action", "ore probabilities:")
    local overall_probability = 0.0
    for name,probability in pairs_by_values(probabilities) do
        gravelsieve.log("action", "%-32s: 1 / %.02f", name, 1.0/probability)
        overall_probability = overall_probability + probability
    end
    gravelsieve.log("action", "Overall probability %f", overall_probability)
end

-- The following functions actually work for any table of numbers... perhaps this could be more generic?
function gravelsieve.api.sum_probabilities(probabilities)
    local sum = 0.0
    for _,probability in pairs(probabilities) do
        sum = sum + probability
    end
    return sum
end

function gravelsieve.api.scale_probabilities_to_fill(probabilities, fill_to)
    local sum = gravelsieve.api.sum_probabilities(probabilities)
    local scale_factor = fill_to / sum
    return gravelsieve.api.scale_probabilities(probabilities, scale_factor)
end

function gravelsieve.api.scale_probabilities(probabilities, scale_factor)
    local scaled_probabilities = {}
    for name,probability in pairs(probabilities) do
        scaled_probabilities[name] = probability * scale_factor
    end
    return scaled_probabilities
end

function gravelsieve.api.merge_probabilities( ... )
    local merged_probabilities = {}
    for _,probabilities in pairs({...}) do
        for name,probability in pairs(probabilities) do
            merged_probabilities[name] = (merged_probabilities[name] or 0) + probability
        end
    end
    return merged_probabilities
end