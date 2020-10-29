draconis = {}

draconis.fire_colors = {"black", "bronze", "green", "red"}

draconis.ice_colors = {"light_blue", "sapphire", "slate", "white"}

draconis.global_meat = {}

local common_meat_names = {
	"beef",
	"chicken",
	"mutton",
	"porkchop",
	"meat"
}

minetest.register_on_mods_loaded(function()
	for name in pairs(minetest.registered_items) do
		for _,i in ipairs(common_meat_names) do
			if (name:match(i)
			and (name:match("raw") or name:match("uncooked")))
			or minetest.registered_items[name].groups.food_meat_raw then
				table.insert(draconis.global_meat, name)
			end
		end
	end
end)

draconis.walkable_nodes = {}

draconis.all_stone = {}

draconis.all_soil = {}

draconis.all_ice = {}

draconis.all_trees = {}

draconis.all_leaves = {}

draconis.all_flora = {}

draconis.all_lava = {}

minetest.register_on_mods_loaded(function()
	for name in pairs(minetest.registered_nodes) do
		if name ~= "air" and name ~= "ignore" then
			if minetest.registered_nodes[name].walkable then
				table.insert(draconis.walkable_nodes, name)
			end
			if minetest.registered_nodes[name].groups.stone == 1 then
				table.insert(draconis.all_stone, name)
			end
			if minetest.registered_nodes[name].groups.soil == 1 then
				table.insert(draconis.all_soil, name)
			end
			if (minetest.registered_nodes[name].groups.snowy == 1
			and not minetest.registered_nodes[name].groups.soil == 1)
			or (minetest.registered_nodes[name].groups.cools_lava == 1
			and name:match("ice")) then
				table.insert(draconis.all_ice, name)
			end
			if minetest.registered_nodes[name].groups.tree == 1 then
				table.insert(draconis.all_trees, name)
			end
			if minetest.registered_nodes[name].groups.leaves == 1 then
				table.insert(draconis.all_leaves, name)
			end
			if minetest.registered_nodes[name].groups.flora == 1 then
				table.insert(draconis.all_flora, name)
			end
		end
	end
end)


draconis.warm_biomes = {}

draconis.cold_biomes = {}

minetest.register_on_mods_loaded(function()
    for name in pairs(minetest.registered_biomes) do
		if minetest.registered_biomes[name].heat_point >= 75 then
			table.insert(draconis.warm_biomes, name)
		end
		if minetest.registered_biomes[name].heat_point <= 25 then
			table.insert(draconis.cold_biomes, name)
		end
    end
end)

draconis.warm_biome_nodes = {}

draconis.cold_biome_nodes = {}

minetest.register_on_mods_loaded(function()
    for _, name in ipairs(draconis.warm_biomes) do
        if minetest.registered_biomes[name].node_top then
			table.insert(draconis.warm_biome_nodes,
			minetest.registered_biomes[name].node_top)
        end
	end
	for _, name in ipairs(draconis.cold_biomes) do
        if minetest.registered_biomes[name].node_top then
			table.insert(draconis.cold_biome_nodes,
			minetest.registered_biomes[name].node_top)
        end
    end
end)

function draconis.find_value_in_table(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

local function all_first_to_upper(str)
	str = string.gsub(" "..str, "%W%l", string.upper):sub(2)
    return str
end

local function underscore_to_space(str)
    return (str:gsub("_", " "))
end

function draconis.string_format(str)
	if str then
		if str:match(":") then
			str = str:split(":")[2]
		end
		str = all_first_to_upper(str)
		str = underscore_to_space(str)
		return str
	end
end

local path = minetest.get_modpath("draconis")
local storage = dofile(path.."/storage.lua")

draconis.bonded_dragons = storage.bonded_dragons
draconis.ice_cavern_spawns = storage.ice_caverns
draconis.fire_cavern_spawns = storage.fire_caverns
draconis.ice_roost_spawns = storage.ice_roosts
draconis.fire_roost_spawns = storage.fire_roosts

dofile(path.."/api/api.lua")
dofile(path.."/api/hq_lq.lua")
dofile(path.."/api/mount.lua")
dofile(path.."/api/pathfinding.lua")
dofile(path.."/api/spawning.lua")
dofile(path.."/api/legacy_convert.lua")
dofile(path.."/mobs/fire_dragon.lua")
dofile(path.."/mobs/ice_dragon.lua")
dofile(path.."/craftitems.lua")
dofile(path.."/crafting.lua")
dofile(path.."/forge.lua")
dofile(path.."/tools.lua")
dofile(path.."/nodes.lua")

if minetest.get_modpath("3d_armor") then
	dofile(path.."/armor.lua")
end

if not minetest.settings:get_bool("simple_spawning") then
	dofile(path.."/mapgen.lua")
end

minetest.log("action", "[MOD] Draconis v1.0 Dev loaded")