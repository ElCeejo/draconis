-------------
--- Mapgen --
-------------
-- Ver 1.1 --

local function add_spawn_node(pos, name, age)
    minetest.set_node(pos, {name = "draconis:spawn_node"})
    local meta = minetest.get_meta(pos)
    meta:set_string("name", name)
    meta:set_int("age", age)
end

-----------------
-- Content IDs --
-----------------

local function get_content_id(name)
    if not minetest.registered_nodes[name] then
        return nil
    else
        return minetest.get_content_id(name)
    end
end

-- Fire --

local fire_ores = {
    get_content_id("default:stone_with_diamond"),
    get_content_id("default:stone_with_gold"),
    get_content_id("default:stone_with_iron")
}

local fire_loot = get_content_id("default:goldblock")

-- Ice --

local ice_ores = {
    get_content_id("default:stone_with_diamond"),
    get_content_id("default:stone_with_tin"),
    get_content_id("default:stone_with_iron")
}

local ice_loot = minetest.get_content_id("default:steelblock")

-- Mod Compatibility --

if minetest.get_modpath("underch") then
    fire_ores = {
        minetest.get_content_id("underch:emerald_ore"),
        minetest.get_content_id("default:stone_with_gold"),
        minetest.get_content_id("default:stone_with_iron")
    }
    ice_ores = {
        minetest.get_content_id("underch:saphire_ore"),
        minetest.get_content_id("default:stone_with_tin"),
        minetest.get_content_id("default:stone_with_iron")
    }
end

if minetest.get_modpath("moreores") then
    ice_loot = minetest.get_content_id("moreores:silver_block")
end

--------------
-- Settings --
--------------

local nest_spawn_rate = tonumber(minetest.settings:get("nest_spawn_rate")) or 64

local roost_spawn_rate = tonumber(minetest.settings:get("roost_spawn_rate")) or 32

local cavern_spawn_rate = tonumber(minetest.settings:get("cavern_spawn_rate")) or 64

------------
-- Locals --
------------

local random = math.random

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

local function G(name, group)
    if minetest.get_item_group(name, group) > 0 then return true end
    return false
end

local function dist_2d(pos1, pos2)
    local a = vector.new(pos1.x, 0, pos1.z)
    local b = vector.new(pos2.x, 0, pos2.z)
    return vector.distance(a, b)
end

-------------------
-- Nest Spawning --
-------------------

if minetest.settings:get_bool("nest_spawning") then

local np_nest = {
    offset = 0,
    scale = 1,
    spread = {x = 16, y = 3, z = 16},
    seed = 5900033,
    octaves = 2,
    persist = 0.5
}

local nest_radius = 8

local nest_noise_amp = 0.12

local function get_terrain_flatness(pos)
    local pos1 = vector.new(pos.x - 16, pos.y, pos.z - 16)
    local pos2 = vector.new(pos.x + 16, pos.y, pos.z + 16)
    local ground = minetest.find_nodes_in_area(pos1, pos2, mob_core.walkable_nodes)
    return #ground
end

local function create_ice_nest(pos, minp, maxp)
    local y0 = minp.y
    local y1 = maxp.y

    local x0 = minp.x
    local x1 = maxp.x
    local z0 = minp.z
    local z1 = maxp.z
    local ccenx = math.floor((x0 + x1) / 2)
    local cceny = math.floor((y0 + y1) / 2)
    local ccenz = math.floor((z0 + z1) / 2)

    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
    local data = vm:get_data()

    local c_air = minetest.get_content_id("air")
    local c_tree = minetest.get_content_id("draconis:frozen_tree")
    local c_soil = minetest.get_content_id("draconis:frozen_soil")
    local c_stone = minetest.get_content_id("draconis:frozen_stone")
    local c_loot = ice_loot

    local sidelen = x1 - x0 + 1
    local chulens = {x = sidelen, y = sidelen, z = sidelen}
    local minposxyz = {x = x0, y = y0, z = z0}

    local force_loaded = {}

    local nvals_nest =
        minetest.get_perlin_map(np_nest, chulens):get3dMap_flat(minposxyz)

    local nixyz = 1
    for z = z0, z1 do
        for y = y0, y1 do
            local vi = area:index(x0, y, z)
            for x = x0, x1 do
                minetest.forceload_block({x=x, y=y, z=z}, false)
                table.insert(force_loaded, {x=x, y=y, z=z})
                local n_nest = nvals_nest[nixyz]
                local nodrad = ((x - ccenx) ^ 2 + (y - cceny) ^ 0.75 + (z - ccenz) ^ 2) ^ 0.5
                local blob = ((nest_radius + ((y - cceny) * 0.5)) - nodrad) / nest_radius + n_nest * nest_noise_amp
                if blob >= 0 then
                    data[vi] = c_air
                    local bi = area:index(x, y - 1, z) -- Below current index
                    if data[bi] ~= c_air and data[vi] == c_air then
                        if random(32) == 1 then
                            data[vi] = c_loot
                        end
                    end
                elseif blob >= -0.1 then
                    local c_name = minetest.get_name_from_content_id(data[vi])
                    if G(c_name, "soil") then
                        data[vi] = c_soil
                    end
                    if G(c_name, "stone") then
                        data[vi] = c_stone
                    end
                    if G(c_name, "tree") and data[vi] ~= c_tree then
                        data[vi] = c_air
                    end
                    if G(c_name, "leaves") then
                        data[vi] = c_air
                    end
                    if G(c_name, "flora") then
                        data[vi] = c_air
                    end
                end
                nixyz = nixyz + 1
                vi = vi + 1
            end
        end
    end

    vm:set_data(data)
    vm:set_lighting({day = 0, night = 0})
    vm:calc_lighting()
    vm:write_to_map(data)

    local s_pos = pos
    while minetest.registered_nodes[minetest.get_node(pos).name].walkable do
        s_pos.y = s_pos.y + 1
    end
    s_pos.y = s_pos.y + 3
    add_spawn_node(s_pos, "draconis:ice_dragon", random(30, 75))
end

local function create_fire_nest(pos, minp, maxp)
    local y0 = minp.y
    local y1 = maxp.y

    local x0 = minp.x
    local x1 = maxp.x
    local z0 = minp.z
    local z1 = maxp.z
    local ccenx = math.floor((x0 + x1) / 2)
    local cceny = math.floor((y0 + y1) / 2)
    local ccenz = math.floor((z0 + z1) / 2)

    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
    local data = vm:get_data()

    local c_air = minetest.get_content_id("air")
    local c_tree = minetest.get_content_id("draconis:scorched_tree")
    local c_soil = minetest.get_content_id("draconis:scorched_soil")
    local c_stone = minetest.get_content_id("draconis:scorched_stone")
    local c_loot = fire_loot

    local sidelen = x1 - x0 + 1
    local chulens = {x = sidelen, y = sidelen, z = sidelen}
    local minposxyz = {x = x0, y = y0, z = z0}

    local force_loaded = {}

    local nvals_nest =
        minetest.get_perlin_map(np_nest, chulens):get3dMap_flat(minposxyz)

    local nixyz = 1
    for z = z0, z1 do
        for y = y0, y1 do
            local vi = area:index(x0, y, z)
            for x = x0, x1 do
                minetest.forceload_block({x=x, y=y, z=z}, false)
                table.insert(force_loaded, {x=x, y=y, z=z})
                local n_nest = nvals_nest[nixyz]
                local nodrad = ((x - ccenx) ^ 2 + (y - cceny) ^ 0.75 + (z - ccenz) ^ 2) ^ 0.5
                local blob = ((nest_radius + ((y - cceny) * 0.5)) - nodrad) / nest_radius + n_nest * nest_noise_amp
                if blob >= 0 then
                    data[vi] = c_air
                    local bi = area:index(x, y - 1, z) -- Below current index
                    if data[bi] ~= c_air and data[vi] == c_air then
                        if random(32) == 1 then
                            data[vi] = c_loot
                        end
                    end
                elseif blob >= -0.1 then
                    local c_name = minetest.get_name_from_content_id(data[vi])
                    if G(c_name, "soil") then
                        data[vi] = c_soil
                    end
                    if G(c_name, "stone") then
                        data[vi] = c_stone
                    end
                    if G(c_name, "tree") and data[vi] ~= c_tree then
                        data[vi] = c_air
                    end
                    if G(c_name, "leaves") then
                        data[vi] = c_air
                    end
                    if G(c_name, "flora") then
                        data[vi] = c_air
                    end
                end
                nixyz = nixyz + 1
                vi = vi + 1
            end
        end
    end

    vm:set_data(data)
    vm:set_lighting({day = 0, night = 0})
    vm:calc_lighting()
    vm:write_to_map(data)

    local s_pos = pos
    while minetest.registered_nodes[minetest.get_node(pos).name].walkable do
        s_pos.y = s_pos.y + 1
    end
    s_pos.y = s_pos.y + 3
    add_spawn_node(s_pos, "draconis:fire_dragon", random(30, 75))
end

minetest.register_on_generated(function(minp, maxp)

    if maxp.y > 1 and random(nest_spawn_rate) < 2 then

        local heightmap = minetest.get_mapgen_object("heightmap")
        if not heightmap then return end

        local pos = {
            x = minp.x + math.floor((maxp.x - minp.x) / 2),
            y = minp.y,
            z = minp.z + math.floor((maxp.z - minp.z) / 2)
        }

        local hm_i = (pos.x - minp.x + 1) + (((pos.z - minp.z)) * 80)
        pos.y = heightmap[hm_i]

        if pos.y > 80
        and is_surface_node(pos)
        and get_terrain_flatness(pos) >= 48 then
            if minetest.registered_biomes[draconis.get_biome_name(pos)].heat_point <= 33 then
                create_ice_nest(pos, minp, maxp)
            else
                create_fire_nest(pos, minp, maxp)
            end
        end
    end
end)

end

---------------------------
-- Ice and Fire Spawning --
---------------------------

if minetest.settings:get_bool("i_f_spawning") then

----------------------
-- Noise Parameters --
----------------------

local np_roost = {
    offset = 0,
    scale = 1,
    spread = {x = 32, y = 16, z = 32},
    seed = 5900033,
    octaves = 2,
    persist = 0.5
}

local roost_radius = 16

local roost_noise_amp = 0.33

local np_cavern = {
    offset = 0,
    scale = 1,
    spread = {x = 32, y = 32, z = 32},
    seed = 5900033,
    octaves = 2,
    persist = 0.5
}

local cavern_radius = 32

local outer_thresh = -0.2

local cavern_noise_amp = 0.12

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

local function create_fire_roost(pos, minp, maxp)
    local y0 = minp.y
    local y1 = maxp.y

    local x0 = minp.x
    local x1 = maxp.x
    local z0 = minp.z
    local z1 = maxp.z
    local ccenx = math.floor((x0 + x1) / 2)
    local cceny = math.floor((y0 + y1) / 2)
    local ccenz = math.floor((z0 + z1) / 2)

    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
    local data = vm:get_data()

    local c_air = minetest.get_content_id("air")
    local c_tree = minetest.get_content_id("draconis:scorched_tree")
    local c_soil = minetest.get_content_id("draconis:scorched_soil")
    local c_stone = minetest.get_content_id("draconis:scorched_stone")
    local c_loot = fire_loot

    local sidelen = x1 - x0 + 1
    local chulens = {x = sidelen, y = sidelen, z = sidelen}
    local minposxyz = {x = x0, y = y0, z = z0}

    local force_loaded = {}

    local nvals_roost =
        minetest.get_perlin_map(np_roost, chulens):get3dMap_flat(minposxyz)

    local nixyz = 1
    for z = z0, z1 do
        for y = y0, y1 do
            local vi = area:index(x0, y, z)
            for x = x0, x1 do
                minetest.forceload_block({x=x, y=y, z=z}, false)
                table.insert(force_loaded, {x=x, y=y, z=z})
                local n_roost = nvals_roost[nixyz]
                local nodrad =
                    ((x - ccenx) ^ 2 + (y - cceny) ^ 2 + (z - ccenz) ^ 2) ^ 0.5
                local blob = (roost_radius - nodrad) / roost_radius + n_roost *
                                 roost_noise_amp
                if blob >= -0.2 then
                    local c_name = minetest.get_name_from_content_id(data[vi])
                    if G(c_name, "soil") then
                        data[vi] = c_soil
                    end
                    if G(c_name, "stone") then
                        data[vi] = c_stone
                    end
                    if G(c_name, "tree") and data[vi] ~= c_tree then
                        data[vi] = c_air
                    end
                    if G(c_name, "leaves") then
                        data[vi] = c_air
                    end
                    if G(c_name, "flora") then
                        data[vi] = c_air
                    end
                    local bi = area:index(x, y - 1, z) -- Below current index
                    if data[bi] ~= c_air and data[vi] == c_air then
                        if random(32) == 1 then
                            data[vi] = c_loot
                        elseif random(64) == 1 then
                            local len = random(3, 6)
                            for i = -1, len do
                                local vi_pos = area:position(vi)
                                if dist_2d(pos, vi_pos) > 12 then
                                    local si =
                                        area:index(vi_pos.x, vi_pos.y + i,
                                                   vi_pos.z)
                                    data[si] = c_tree
                                end
                            end
                        end
                    end
                end
                nixyz = nixyz + 1
                vi = vi + 1
            end
        end
    end

    vm:set_data(data)
    vm:set_lighting({day = 0, night = 0})
    vm:calc_lighting()
    vm:write_to_map(data)

    local s_pos = pos
    while minetest.registered_nodes[minetest.get_node(pos).name].walkable do
        s_pos.y = s_pos.y + 1
    end
    s_pos.y = s_pos.y + 3
    add_spawn_node(s_pos, "draconis:fire_dragon", random(30, 75))
end

local function create_ice_roost(pos, minp, maxp)
    local y0 = minp.y
    local y1 = maxp.y

    local x0 = minp.x
    local x1 = maxp.x
    local z0 = minp.z
    local z1 = maxp.z
    local ccenx = math.floor((x0 + x1) / 2)
    local cceny = math.floor((y0 + y1) / 2)
    local ccenz = math.floor((z0 + z1) / 2)

    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
    local data = vm:get_data()

    local c_air = minetest.get_content_id("air")
    local c_tree = minetest.get_content_id("draconis:frozen_tree")
    local c_soil = minetest.get_content_id("draconis:frozen_soil")
    local c_stone = minetest.get_content_id("draconis:frozen_stone")
    local c_loot = ice_loot

    local sidelen = x1 - x0 + 1
    local chulens = {x = sidelen, y = sidelen, z = sidelen}
    local minposxyz = {x = x0, y = y0, z = z0}

    local force_loaded = {}

    local nvals_roost =
        minetest.get_perlin_map(np_roost, chulens):get3dMap_flat(minposxyz)

    local nixyz = 1
    for z = z0, z1 do
        for y = y0, y1 do
            local vi = area:index(x0, y, z)
            for x = x0, x1 do
                minetest.forceload_block({x=x, y=y, z=z}, false)
                table.insert(force_loaded, {x=x, y=y, z=z})
                local n_roost = nvals_roost[nixyz]
                local nodrad =
                    ((x - ccenx) ^ 2 + (y - cceny) ^ 2 + (z - ccenz) ^ 2) ^ 0.5
                local blob = (roost_radius - nodrad) / roost_radius + n_roost *
                                 roost_noise_amp
                if blob >= -0.2 then
                    local c_name = minetest.get_name_from_content_id(data[vi])
                    if G(c_name, "soil") then
                        data[vi] = c_soil
                    end
                    if G(c_name, "stone") then
                        data[vi] = c_stone
                    end
                    if G(c_name, "tree") and data[vi] ~= c_tree then
                        data[vi] = c_air
                    end
                    if G(c_name, "leaves") then
                        data[vi] = c_air
                    end
                    if G(c_name, "flora") then
                        data[vi] = c_air
                    end
                    local bi = area:index(x, y - 1, z) -- Below current index
                    if data[bi] ~= c_air and data[vi] == c_air then
                        if random(32) == 1 then
                            data[vi] = c_loot
                        elseif random(64) == 1 then
                            local len = random(3, 6)
                            for i = -1, len do
                                local vi_pos = area:position(vi)
                                if dist_2d(pos, vi_pos) > 12 then
                                    local si =
                                        area:index(vi_pos.x, vi_pos.y + i,
                                                   vi_pos.z)
                                    data[si] = c_tree
                                end
                            end
                        end
                    end
                end
                nixyz = nixyz + 1
                vi = vi + 1
            end
        end
    end

    vm:set_data(data)
    vm:set_lighting({day = 0, night = 0})
    vm:calc_lighting()
    vm:write_to_map(data)

    local s_pos = pos
    while minetest.registered_nodes[minetest.get_node(pos).name].walkable do
        s_pos.y = s_pos.y + 1
    end
    add_spawn_node(s_pos, "draconis:ice_dragon", random(30, 75))
end

-------------
-- Caverns --
-------------

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

local function create_fire_cavern(pos, minp, maxp)
    local y0 = minp.y
    local y1 = maxp.y

    local x0 = minp.x
    local x1 = maxp.x
    local z0 = minp.z
    local z1 = maxp.z
    local ccenx = math.floor((x0 + x1) / 2)
    local cceny = math.floor((y0 + y1) / 2)
    local ccenz = math.floor((z0 + z1) / 2)

    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
    local data = vm:get_data()

    local c_air = minetest.get_content_id("air")
    local c_stone = minetest.get_content_id("draconis:scorched_stone")
    local c_ore = fire_ores
    local c_loot = fire_loot

    local sidelen = x1 - x0 + 1
    local chulens = {x = sidelen, y = sidelen, z = sidelen}
    local minposxyz = {x = x0, y = y0, z = z0}

    local force_loaded = {}

    local nvals_cavern =
        minetest.get_perlin_map(np_cavern, chulens):get3dMap_flat(minposxyz)

    local nixyz = 1
    for z = z0, z1 do
        for y = y0, y1 do
            local vi = area:index(x0, y, z)
            for x = x0, x1 do
                minetest.forceload_block({x=x, y=y, z=z}, false)
                table.insert(force_loaded, {x=x, y=y, z=z})
                local n_cavern = nvals_cavern[nixyz]
                local nodrad =
                    ((x - ccenx) ^ 2 + (y - cceny) ^ 2 + (z - ccenz) ^ 2) ^ 0.5
                local oily =
                    (cavern_radius - nodrad) / cavern_radius + n_cavern *
                        cavern_noise_amp
                if oily >= 0 and area:position(vi).y > y0 + 12 then
                    data[vi] = c_air
                elseif oily >= outer_thresh then
                    data[vi] = c_stone
                    local vi_pos = area:position(vi)
                    local above = area:index(vi_pos.x, vi_pos.y + 1, vi_pos.z)
                    if data[above] == c_air then
                        if random(24) == 1 then
                            data[above] = c_loot
                        end
                    end
                    if random(48) == 1 then
                        data[vi] = c_ore[random(#c_ore)]
                    end
                end
                local bi = area:index(x, y - 1, z) -- Below current index
                if data[bi] == c_stone and data[vi] == c_air then
                    if random(24) == 1 then data[vi] = c_loot end
                end
                if data[vi] == c_stone and data[bi] == c_air then
                    if random(18) == 1 then
                        local len = random(3, 6)
                        for i = 1, len do
                            local vi_pos = area:position(vi)
                            local si = area:index(vi_pos.x, vi_pos.y - i,
                                                  vi_pos.z)
                            data[si] = c_stone
                        end
                    end
                end
                nixyz = nixyz + 1
                vi = vi + 1
            end
        end
    end

    vm:set_data(data)
    vm:set_lighting({day = 0, night = 0})
    vm:calc_lighting()
    vm:write_to_map(data)

    add_spawn_node(vector.new(pos.x, minp.y + 20, pos.z), "draconis:fire_dragon", 200)
end

local function create_ice_cavern(pos, minp, maxp)
    local y0 = minp.y
    local y1 = maxp.y

    local x0 = minp.x
    local x1 = maxp.x
    local z0 = minp.z
    local z1 = maxp.z
    local ccenx = math.floor((x0 + x1) / 2)
    local cceny = math.floor((y0 + y1) / 2)
    local ccenz = math.floor((z0 + z1) / 2)

    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
    local data = vm:get_data()

    local c_air = minetest.get_content_id("air")
    local c_stone = minetest.get_content_id("draconis:frozen_stone")
    local c_ore = ice_ores
    local c_loot = ice_loot

    local sidelen = x1 - x0 + 1
    local chulens = {x = sidelen, y = sidelen, z = sidelen}
    local minposxyz = {x = x0, y = y0, z = z0}

    local force_loaded = {}

    local nvals_cavern =
        minetest.get_perlin_map(np_cavern, chulens):get3dMap_flat(minposxyz)

    local nixyz = 1
    for z = z0, z1 do
        for y = y0, y1 do
            local vi = area:index(x0, y, z)
            for x = x0, x1 do
                minetest.forceload_block({x=x, y=y, z=z}, false)
                table.insert(force_loaded, {x=x, y=y, z=z})
                local n_cavern = nvals_cavern[nixyz]
                local nodrad =
                    ((x - ccenx) ^ 2 + (y - cceny) ^ 2 + (z - ccenz) ^ 2) ^ 0.5
                local oily =
                    (cavern_radius - nodrad) / cavern_radius + n_cavern *
                        cavern_noise_amp
                if oily >= 0 and area:position(vi).y > y0 + 12 then
                    data[vi] = c_air
                elseif oily >= outer_thresh then
                    data[vi] = c_stone
                    local vi_pos = area:position(vi)
                    local above = area:index(vi_pos.x, vi_pos.y + 1, vi_pos.z)
                    if data[above] == c_air then
                        if random(24) == 1 then
                            data[above] = c_loot
                        end
                    end
                    if random(48) == 1 then
                        data[vi] = c_ore[random(#c_ore)]
                    end
                end
                local bi = area:index(x, y - 1, z) -- Below current index
                if data[bi] == c_stone and data[vi] == c_air then
                    if random(24) == 1 then data[vi] = c_loot end
                end
                if data[vi] == c_stone and data[bi] == c_air then
                    if random(18) == 1 then
                        local len = random(3, 6)
                        for i = 1, len do
                            local vi_pos = area:position(vi)
                            local si = area:index(vi_pos.x, vi_pos.y - i,
                                                  vi_pos.z)
                            data[si] = c_stone
                        end
                    end
                end
                nixyz = nixyz + 1
                vi = vi + 1
            end
        end
    end

    vm:set_data(data)
    vm:set_lighting({day = 0, night = 0})
    vm:calc_lighting()
    vm:write_to_map(data)

    add_spawn_node(vector.new(pos.x, minp.y + 20, pos.z), "draconis:ice_dragon", 200)
end

----------------
-- Generation --
----------------

minetest.register_on_generated(function(minp, maxp, blockseed)

    local height_min = -128
    local height_max = -32
    local pr = PseudoRandom(blockseed)

    if minp.y < height_max and maxp.y > height_min and random(cavern_spawn_rate) <
        2 then

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
            create_ice_cavern(pos, minp, maxp)
        end
        if can_spawn_fire_cavern(pos) then
            create_fire_cavern(pos, minp, maxp)
        end
    end

    if maxp.y > 1 and random(roost_spawn_rate) < 2 then

        local heightmap = minetest.get_mapgen_object("heightmap")
        if not heightmap then return end

        local pos = {
            x = minp.x + math.floor((maxp.x - minp.x) / 2),
            y = minp.y,
            z = minp.z + math.floor((maxp.z - minp.z) / 2)
        }

        local hm_i = (pos.x - minp.x + 1) + (((pos.z - minp.z)) * 80)
        pos.y = heightmap[hm_i]

        if pos.y < 0 then return end
        if can_spawn_ice_roost(pos) then
            create_ice_roost(pos, minp, maxp)
        end
        if can_spawn_fire_roost(pos) then
            create_fire_roost(pos, minp, maxp)
        end
    end
end)
end

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
