-------------
--- Mapgen --
-------------
-- Ver 1.0 --

local ice_cavern_data = {
    outer_id = minetest.get_content_id("draconis:frozen_stone"),
    loot_id = minetest.get_content_id("default:steelblock"),
    ore_table = {
        minetest.get_content_id("default:stone_with_diamond"),
        minetest.get_content_id("default:stone_with_tin"),
        minetest.get_content_id("default:stone_with_iron")
    }
}

local fire_cavern_data = {
    outer_id = minetest.get_content_id("draconis:scorched_stone"),
    loot_id = minetest.get_content_id("default:goldblock"),
    ore_table = {
        minetest.get_content_id("default:stone_with_diamond"),
        minetest.get_content_id("default:stone_with_gold"),
        minetest.get_content_id("default:stone_with_iron")
    }
}

local ice_roost_data = {
    soil_id = minetest.get_content_id("draconis:frozen_soil"),
    stone_id = minetest.get_content_id("draconis:frozen_stone"),
    tree_id = minetest.get_content_id("draconis:frozen_tree"),
    leaves_id = minetest.get_content_id("air"),
    flora_id = minetest.get_content_id("air"),
    loot_id = minetest.get_content_id("default:steelblock")
}

local fire_roost_data = {
    soil_id = minetest.get_content_id("draconis:scorched_soil"),
    stone_id = minetest.get_content_id("draconis:scorched_stone"),
    tree_id = minetest.get_content_id("draconis:scorched_tree"),
    leaves_id = minetest.get_content_id("air"),
    flora_id = minetest.get_content_id("air"),
    loot_id = minetest.get_content_id("default:goldblock")
}

if minetest.get_modpath("underch") then
    ice_cavern_data.loot_id = minetest.get_content_id("underch:saphire_block")
    fire_cavern_data.loot_id = minetest.get_content_id("underch:emerald_block")
    table.insert(ice_cavern_data.ore_table, minetest.get_content_id("underch:saphire_ore"))
    table.insert(fire_cavern_data.ore_table, minetest.get_content_id("underch:emerald_ore"))
    ice_roost_data.loot_id = minetest.get_content_id("underch:saphire_block")
    fire_roost_data.loot_id = minetest.get_content_id("underch:emerald_block")
end

if minetest.get_modpath("moreores") then
    ice_cavern_data.loot_id = minetest.get_content_id("moreores:silver_block")
    ice_roost_data.loot_id = minetest.get_content_id("moreores:silver_block")
end

local roost_spawn_rate = minetest.settings:get("roost_spawn_rate") or 64

local cavern_spawn_rate = minetest.settings:get("cavern_spawn_rate") or 256

local random = math.random

local walkable_ids = {}

minetest.register_on_mods_loaded(function()
    for name in pairs(minetest.registered_nodes) do
        if name ~= "air" and name ~= "ignore" then
            if minetest.registered_nodes[name].walkable then
                local c_name = minetest.get_content_id(name)
                table.insert(walkable_ids, c_name)
            end
        end
    end
end)

local lava_ids = {}

minetest.register_on_mods_loaded(function()
    for name in pairs(minetest.registered_nodes) do
        if name ~= "air" and name ~= "ignore" then
            if minetest.registered_nodes[name].groups.lava
            and minetest.registered_nodes[name].groups.lava >= 1 then
                local c_name = minetest.get_content_id(name)
                table.insert(lava_ids, c_name)
            end
        end
    end
end)

local function is_surface_node(pos)
    local dirs = {
        {x = 1, y = 0, z = 0}, {x = -1, y = 0, z = 0}, {x = 0, y = 1, z = 0},
        {x = 0, y = -1, z = 0}, {x = 0, y = 0, z = 1}, {x = 0, y = 0, z = -1}
    }
    for i = 1, 6 do
        local node = minetest.get_node(vector.add(pos, dirs[i]))
        if node and
            (node.name == "air" or
                not minetest.registered_nodes[node.name].walkable) then
            return true
        end
    end
    return false
end

local function find_clear_pos(pos)
    local pos1 = vector.new(pos.x - 8, pos.y - 8, pos.z - 8)
    local pos2 = vector.new(pos.x + 8, pos.y + 8, pos.z + 8)
    local clear = pos
    for x = pos1.x, pos2.x do
        for y = pos1.y, pos2.y do
            for z = pos1.z, pos2.z do
                local npos = vector.new(x, y, z)
                local node = minetest.get_node(npos)
                if node.name == "air" then
                    clear = npos
                    break
                end
            end
        end
    end
    return clear
end

-- Ice Cavern Spawn --

minetest.register_globalstep(function()
    for _, plyr in ipairs(minetest.get_connected_players()) do
        local func = function(name)
            local player = minetest.get_player_by_name(name)
            if player then
                local pos = player:get_pos()
                if #draconis.ice_cavern_spawns >= 1 then
                    for i = 1, #draconis.ice_cavern_spawns do
                        if draconis.ice_cavern_spawns[i] and
                            minetest.get_node(draconis.ice_cavern_spawns[i])
                                .name == "air" and
                            vector.distance(pos, draconis.ice_cavern_spawns[i]) <
                            32 then
                            if draconis.spawn_dragon(
                                draconis.ice_cavern_spawns[i],
                                "draconis:ice_dragon", true, 200) then
                                table.remove(draconis.ice_cavern_spawns, i)
                            end
                        end
                    end
                end
                if #draconis.fire_cavern_spawns >= 1 then
                    for i = 1, #draconis.fire_cavern_spawns do
                        if draconis.fire_cavern_spawns[i] and
                            minetest.get_node(draconis.fire_cavern_spawns[i])
                                .name == "air" and
                            vector.distance(pos, draconis.fire_cavern_spawns[i]) <
                            32 then
                            if draconis.spawn_dragon(
                                draconis.fire_cavern_spawns[i],
                                "draconis:fire_dragon", true, 200) then
                                table.remove(draconis.fire_cavern_spawns, i)
                            end
                        end
                    end
                end
                if #draconis.ice_roost_spawns >= 1 then
                    for i = 1, #draconis.ice_roost_spawns do
                        if draconis.ice_roost_spawns[i] and
                            minetest.get_node(draconis.ice_roost_spawns[i]).name ~=
                            "ignore" and
                            vector.distance(pos, draconis.ice_roost_spawns[i]) <
                            32 then
                            if draconis.spawn_dragon(
                                draconis.ice_roost_spawns[i],
                                "draconis:ice_dragon", false, random(30, 75)) then
                                table.remove(draconis.ice_roost_spawns, i)
                            end
                        end
                    end
                end
                if #draconis.fire_roost_spawns >= 1 then
                    for i = 1, #draconis.fire_roost_spawns do
                        if draconis.fire_roost_spawns[i] and
                            minetest.get_node(draconis.fire_roost_spawns[i])
                                .name ~= "ignore" and
                            vector.distance(pos, draconis.fire_roost_spawns[i]) <
                            32 then
                            if draconis.spawn_dragon(
                                draconis.fire_roost_spawns[i],
                                "draconis:fire_dragon", false, random(30, 75)) then
                                table.remove(draconis.fire_roost_spawns, i)
                            end
                        end
                    end
                end
            end
        end
        minetest.after(0, func, plyr:get_player_name())
    end
end)

------------
-- Roosts --
------------

local function can_spawn_ice_roost(pos)
    if draconis.find_value_in_table(draconis.cold_biomes,
                                    draconis.get_biome_name(pos)) and
        is_surface_node(pos) then return true end
    return false
end

local function can_spawn_fire_roost(pos)
    if draconis.find_value_in_table(draconis.warm_biomes,
                                    draconis.get_biome_name(pos)) and
        is_surface_node(pos) then return true end
    return false
end

local function G(name, group)
    if minetest.get_item_group(name, group) > 0 then return true end
    return false
end

local function can_place_loot(pos)
    pos.y = pos.y - 1
    local name = minetest.get_node(pos).name
    if minetest.registered_nodes[name].walkable then return true end
    return false
end

local function create_roost(pos, loot_id, soil_id, stone_id, tree_id, leaves_id,
                            flora_id, name)
    local pos1 = {x = pos.x - 18, y = pos.y - 9, z = pos.z - 18}
    local pos2 = {x = pos.x + 18, y = pos.y + 9, z = pos.z + 18}
    -- LVM
    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(pos1, pos2)
    local a = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
    local data = vm:get_data()
    for z = pos1.z, pos2.z do
        for y = pos1.y, pos2.y do
            for x = pos1.x, pos2.x do
                local vi = a:index(x, y, z)
                local dist = vector.distance(pos, a:position(vi))
                if dist < 16 then
                    local c_name = minetest.get_name_from_content_id(data[vi])
                    if G(c_name, "soil") then
                        data[vi] = soil_id
                    end
                    if G(c_name, "stone") then
                        data[vi] = stone_id
                    end
                    if G(c_name, "tree") then
                        data[vi] = tree_id
                    end
                    if G(c_name, "leaves") then
                        data[vi] = leaves_id
                    end
                    if G(c_name, "flora") then
                        data[vi] = flora_id
                    end
                    if can_place_loot(a:position(vi)) then
                        if random(1, 32) == 1 then
                            data[vi] = loot_id
                        end
                    end
                end
            end
        end
    end
    if name == "draconis:ice_dragon" then
        table.insert(draconis.ice_roost_spawns, find_clear_pos(pos))
    elseif name == "draconis:fire_dragon" then
        table.insert(draconis.fire_roost_spawns, find_clear_pos(pos))
    end
    vm:set_data(data)
    vm:write_to_map(true)
end

-------------
-- Caverns --
-------------

local air = minetest.get_content_id("air")

local function can_spawn_ice_cavern(pos)
    if draconis.find_value_in_table(draconis.cold_biomes,
                                    draconis.get_biome_name(pos)) then
        return true
    end
    return false
end

local function can_spawn_fire_cavern(pos)
    if draconis.find_value_in_table(draconis.warm_biomes,
                                    draconis.get_biome_name(pos)) then
        return true
    end
    return false
end

local data = {}

local function create_cavern(pos, outer_id, loot_id, ore_table, name)
    local pos1 = {x = pos.x - 34, y = pos.y - 9, z = pos.z - 34}
    local pos2 = {x = pos.x + 34, y = pos.y + 34, z = pos.z + 34}
    local vm = minetest.get_mapgen_object("voxelmanip")
    local emin, emax = vm:read_from_map(pos1, pos2)
    local a = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
    vm:get_data(data)
    for i = 1, #walkable_ids do
        for z = pos1.z, pos2.z do
            for y = pos1.y, pos2.y do
                for x = pos1.x, pos2.x do
                    local vi = a:index(x, y, z)
                    if data[vi] == walkable_ids[i] then
                        local dist = vector.distance(pos, a:position(vi))
                        if dist < 28 then
                            data[vi] = air
                            if a:position(vi).y == pos1.y + 1 then
                                if random(1, 32) == 1 then
                                    data[vi] = loot_id
                                end
                            end
                        end
                        if (dist > 28 and dist < 32) or
                            (dist < 28 and a:position(vi).y < pos1.y + 1) then
                            data[vi] = outer_id
                            if random(1, 32) == 1 then
                                data[vi] = ore_table[random(1, #ore_table)]
                            end
                        end
                        for n = 1, #lava_ids do
                            if data[vi] == lava_ids[n] then
                                data[vi] = air
                            end
                        end
                    end
                end
            end
        end
    end
    if name == "draconis:ice_dragon" then
        table.insert(draconis.ice_cavern_spawns, pos)
    elseif name == "draconis:fire_dragon" then
        table.insert(draconis.fire_cavern_spawns, pos)
    end
    vm:set_data(data)
    vm:write_to_map(true)
end

minetest.register_on_generated(function(minp, maxp, blockseed)

    local height_min = -128
    local height_max = -32
    local pr = PseudoRandom(blockseed)

    if minp.y < height_max and maxp.y > height_min and
        random(1, cavern_spawn_rate) == 1 then

        local buffer = 5

        local y = pr:next(minp.y + buffer, maxp.y - buffer)
        y = math.floor(math.max(height_min + buffer,
                                math.min(height_max - buffer, y)))

        local pos = {
            x = minp.x + math.floor((maxp.x - minp.x) / 2),
            y = y,
            z = minp.z + math.floor((maxp.z - minp.z) / 2)
        }

        if can_spawn_ice_cavern(pos) then
            create_cavern(pos, ice_cavern_data.outer_id,
                          ice_cavern_data.loot_id, ice_cavern_data.ore_table,
                          "draconis:ice_dragon")
        end
        if can_spawn_fire_cavern(pos) then
            create_cavern(pos, fire_cavern_data.outer_id,
                          fire_cavern_data.loot_id, fire_cavern_data.ore_table,
                          "draconis:fire_dragon")
        end
    end

    if maxp.y > 1 and random(1, roost_spawn_rate) == 1 then

        local heightmap = minetest.get_mapgen_object("heightmap")
        if not heightmap then return end
        local y = 0

        local index = 0
        for _ = minp.z, maxp.z do
            for _ = minp.x, maxp.x do
                index = index + 1
                local height = heightmap[index]
                height = math.floor(height + 0.5)
                y = height
            end
        end

        local pos = {
            x = minp.x + math.floor((maxp.x - minp.x) / 2),
            y = y,
            z = minp.z + math.floor((maxp.z - minp.z) / 2)
        }

        if pos.y < 0 then return end

        if can_spawn_ice_roost(pos) then
            create_roost(pos, ice_roost_data.loot_id, ice_roost_data.soil_id,
                         ice_roost_data.stone_id, ice_roost_data.tree_id,
                         ice_roost_data.leaves_id, ice_roost_data.flora_id,
                         "draconis:ice_dragon")
        end
        if can_spawn_fire_roost(pos) then
            create_roost(pos, fire_roost_data.loot_id, fire_roost_data.soil_id,
                         fire_roost_data.stone_id, fire_roost_data.tree_id,
                         fire_roost_data.leaves_id, fire_roost_data.flora_id,
                         "draconis:fire_dragon")
        end
    end
end)

-----------------
-- Decorations --
-----------------

minetest.register_decoration({
    deco_type = "simple",
    place_on = {"default:dry_dirt_with_dry_grass", "default:desert_sand"},
	biomes = {"desert", "savanna"},
	sidelen = 16,
	fill_ratio = 0.00001,
	y_min = 10,
	y_max = 90,
	decoration = "draconis:dracolily_fire"
})

minetest.register_decoration({
    deco_type = "simple",
    place_on = "default:dirt_with_snowy_grass",
	biomes = {"snowy_grassland", "taiga"},
	sidelen = 16,
	fill_ratio = 0.00001,
	y_min = 10,
	y_max = 90,
	decoration = "draconis:dracolily_ice"
})
