gravelsieve.sieve = {}
local S = gravelsieve.S
local settings = gravelsieve.settings
local api = gravelsieve.api

-- Pipeworks support
local pipeworks_after_dig
local pipeworks_after_place

if minetest.get_modpath("pipeworks") and pipeworks ~= nil then
    pipeworks_after_dig = pipeworks.after_dig
    pipeworks_after_place = pipeworks.after_place
end

local sieve_formspec = "size[8,8]" ..
        default.gui_bg ..
        default.gui_bg_img ..
        default.gui_slots ..
        "list[context;src;1,1.5;1,1;]" ..
        "image[3,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]" ..
        "list[context;dst;4,0;4,4;]" ..
        "list[current_player;main;0,4.2;8,4;]" ..
        "listring[context;dst]" ..
        "listring[current_player;main]" ..
        "listring[context;src]" ..
        "listring[current_player;main]"

function gravelsieve.sieve.allow_metadata_inventory_put(pos, listname, index, stack, player)
    if minetest.is_protected(pos, player:get_player_name()) then
        return 0
    end

    if listname == "src" then
        return stack:get_count()
    end

    return 0
end

function gravelsieve.sieve.allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local stack = inv:get_stack(from_list, from_index)
    return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

function gravelsieve.sieve.allow_metadata_inventory_take(pos, listname, index, stack, player)
    if minetest.is_protected(pos, player:get_player_name()) then
        return 0
    end
    return stack:get_count()
end

local function aging(pos, meta)
    if settings.aging_level1 then
        local cnt = meta:get_int("tubelib_aging") + 1
        meta:set_int("tubelib_aging", cnt)
        if cnt > settings.aging_level1 and math.random(settings.aging_level2) == 1 then
            minetest.get_node_timer(pos):stop()
            minetest.swap_node(pos, { name = "gravelsieve:sieve_defect" })
        end
    end
end

-- handle the sieve animation
function gravelsieve.sieve.step_node(pos, meta, start)
    local node = minetest.get_node(pos)
    local idx = meta:get_int("idx")
    if start then
        if idx == 3 then
            idx = 0
        end
    else
        idx = (idx + 1) % 4
    end
    meta:set_int("idx", idx)
    node.name = meta:get_string("node_name") .. idx
    minetest.swap_node(pos, node)
    return idx == 3
end


local function dynamic_args_generator(args)
    local dynamic_args = {}
    local player_name = args.meta:get_string("player_name")
    if player_name then
        local player = minetest.get_player_by_name(player_name)
        if not player then return {} end -- player is not logged in, this shouldn't happen
        dynamic_args = {player_name=player_name,player=player,sieve_count=api.count.get(player)}
    end
    return dynamic_args
end

-- move gravel and ores to dst
local function process_output(meta, pos, inv, output)
    local output_item = ItemStack(output)
    if inv:room_for_item("dst", output_item) then
        inv:add_item("dst", output_item)
        aging(pos, meta)
        return true
    end
    meta:set_string("blocked_item", output)
    return false
end

-- take gravel from input
local function process_input(meta, pos, inv, input_name)
    local input_stack = ItemStack(input_name)
    if inv:contains_item("src", input_stack) then
        local is_done = gravelsieve.sieve.step_node(pos, meta, false)
        if is_done then
            -- time to move one item?
            inv:remove_item("src", input_stack)
            local output = api.get_random_output(input_name, dynamic_args_generator, {meta=meta})
            process_output(meta, pos, inv, output)
        end
        return true  -- process finished
    end
    return false -- process still running
end


local function choose_input_item(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    for i = 1, inv:get_size("src") do
        local input_stack = inv:get_stack("src", i)
        local input_name = input_stack:get_name()
        if api.can_process(input_name) then
            return input_name
        end
    end
end

-- timer callback, alternatively called by on_punch
local function sieve_node_timer(pos, elapsed)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local blocked_output = meta:get_string("blocked_item")
    if blocked_output and blocked_output ~= "" then
        local item_output = process_output(meta, pos, inv, blocked_output)
        if not item_output then
            return true
        else
            meta:set_string("blocked_item", "")
        end
    end
    local input_name = choose_input_item(pos)
    if input_name then
        if process_input(meta, pos, inv, input_name) then
            return true
        end
    end

    minetest.get_node_timer(pos):stop()
    return false
end

for automatic = 0, 1 do
    for idx = 0, 4 do
        local nodebox_data = {
            { -8 / 16, -8 / 16, -8 / 16, 8 / 16, 4 / 16, -6 / 16 },
            { -8 / 16, -8 / 16, 6 / 16, 8 / 16, 4 / 16, 8 / 16 },
            { -8 / 16, -8 / 16, -8 / 16, -6 / 16, 4 / 16, 8 / 16 },
            { 6 / 16, -8 / 16, -8 / 16, 8 / 16, 4 / 16, 8 / 16 },
            { -6 / 16, -2 / 16, -6 / 16, 6 / 16, 8 / 16, 6 / 16 },
        }
        nodebox_data[5][5] = (8 - 2 * idx) / 16

        local node_name
        local description
        local tiles_data
        local tube_info
        if automatic == 0 then
            node_name = "gravelsieve:sieve"
            description = S("Gravel Sieve")
            tiles_data = {
                -- up, down, right, left, back, front
                "gravelsieve_gravel.png",
                "gravelsieve_gravel.png",
                "gravelsieve_sieve.png",
                "gravelsieve_sieve.png",
                "gravelsieve_sieve.png",
                "gravelsieve_sieve.png",
            }
        else
            node_name = "gravelsieve:auto_sieve"
            description = S("Automatic Gravel Sieve")
            tiles_data = {
                -- up, down, right, left, back, front
                "gravelsieve_gravel.png",
                "gravelsieve_gravel.png",
                "gravelsieve_auto_sieve.png",
                "gravelsieve_auto_sieve.png",
                "gravelsieve_auto_sieve.png",
                "gravelsieve_auto_sieve.png",
            }

            -- Pipeworks support
            tube_info = {
                insert_object = function(pos, node, stack, direction)
                    local meta = minetest.get_meta(pos)
                    local inv = meta:get_inventory()
                    if automatic == 0 then
                        local meta = minetest.get_meta(pos)
                        gravelsieve.sieve.step_node(pos, meta, true)
                    else
                        minetest.get_node_timer(pos):start(settings.step_delay)
                    end
                    return inv:add_item("src", stack)
                end,
                can_insert = function(pos, node, stack, direction)
                    local meta = minetest.get_meta(pos)
                    local inv = meta:get_inventory()
                    return inv:room_for_item("src", stack)
                end,
                input_inventory = "dst",
                connect_sides = { left = 1, right = 1, front = 1, back = 1, bottom = 1, top = 1 }
            }
        end

        local not_in_creative_inventory
        if idx == 3 then
            tiles_data[1] = "gravelsieve_top.png"
            not_in_creative_inventory = 0
        else
            not_in_creative_inventory = 1
        end

        minetest.register_node(node_name .. idx, {
            description = description,
            tiles = tiles_data,
            drawtype = "nodebox",
            drop = node_name,

            tube = tube_info, --  NEW

            node_box = {
                type = "fixed",
                fixed = nodebox_data,
            },
            selection_box = {
                type = "fixed",
                fixed = { -8 / 16, -8 / 16, -8 / 16, 8 / 16, 4 / 16, 8 / 16 },
            },

            on_timer = sieve_node_timer,

            on_construct = function(pos)
                local meta = minetest.get_meta(pos)
                meta:set_int("idx", idx)        -- for the 4 sieve phases
                meta:set_string("node_name", node_name)
                meta:set_string("formspec", sieve_formspec)
                local inv = meta:get_inventory()
                inv:set_size('src', 1)
                inv:set_size('dst', 16)
            end,

            after_dig_node = function (pos, oldnode, oldmetadata, digger)
                api.count.del(pos, digger)
                -- Pipeworks support
                if pipeworks_after_dig then
                    pipeworks_after_dig(pos, oldnode, oldmetadata, digger)
                end
            end,

            after_place_node = function(pos, placer)
                local meta = minetest.get_meta(pos)
                meta:set_string("infotext", "Gravel Sieve")
                meta:set_string("player_name", placer:get_player_name())
                api.count.add(pos, placer)

                -- Pipeworks support
                if pipeworks_after_place then
                    pipeworks_after_place(pos, placer)
                end
            end,

            on_metadata_inventory_move = function(pos)
                if automatic == 0 then
                    local meta = minetest.get_meta(pos)
                    gravelsieve.sieve.step_node(pos, meta, true)
                else
                    minetest.get_node_timer(pos):start(settings.step_delay)
                end
            end,

            on_metadata_inventory_take = function(pos)
                if automatic == 0 then
                    local meta = minetest.get_meta(pos)
                    local inv = meta:get_inventory()
                    if inv:is_empty("src") then
                        -- sieve should be empty
                        meta:set_int("idx", 2)
                        gravelsieve.sieve.step_node(pos, meta, false)
                    end
                else
                    minetest.get_node_timer(pos):start(settings.step_delay)
                end
            end,

            on_metadata_inventory_put = function(pos)
                if automatic == 0 then
                    local meta = minetest.get_meta(pos)
                    gravelsieve.sieve.step_node(pos, meta, true)
                else
                    minetest.get_node_timer(pos):start(settings.step_delay)
                end
            end,

            on_punch = function(pos, node, puncher, pointed_thing)
                local meta = minetest.get_meta(pos)
                local inv = meta:get_inventory()
                if inv:is_empty("dst") and inv:is_empty("src") then
                    minetest.node_punch(pos, node, puncher, pointed_thing)
                else
                    sieve_node_timer(pos, 0)
                end
            end,

            on_dig = function(pos, node, puncher, pointed_thing)
                local meta = minetest.get_meta(pos)
                local inv = meta:get_inventory()
                if inv:is_empty("dst") and inv:is_empty("src") then
                    minetest.node_dig(pos, node, puncher, pointed_thing)
                end
            end,

            allow_metadata_inventory_put = gravelsieve.sieve.allow_metadata_inventory_put,
            allow_metadata_inventory_move = gravelsieve.sieve.allow_metadata_inventory_move,
            allow_metadata_inventory_take = gravelsieve.sieve.allow_metadata_inventory_take,

            paramtype = "light",
            sounds = default.node_sound_wood_defaults(),
            paramtype2 = "facedir",
            sunlight_propagates = true,
            is_ground_content = false,
            groups = { choppy = 2, cracky = 1, not_in_creative_inventory = not_in_creative_inventory, tubedevice = 1, tubedevice_receiver = 1 },
            drop = node_name .. "3",
        })
    end
end
