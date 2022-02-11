--------------
-- Draconis --
--------------

draconis = {}

local path = minetest.get_modpath("draconis")

local storage = dofile(path.."/storage.lua")

draconis.dragons = storage.dragons
draconis.bonded_dragons = storage.bonded_dragons
draconis.objects_last_cleared = storage.objects_last_cleared
draconis.aux_key_setting = storage.aux_key_setting

draconis.sounds = {
    wood = {},
    stone = {},
    dirt = {}
}

if minetest.get_modpath("default") then
    if default.node_sound_wood_defaults then
        draconis.sounds.wood = default.node_sound_wood_defaults()
    end
    if default.node_sound_stone_defaults then
        draconis.sounds.stone = default.node_sound_stone_defaults()
    end
    if default.node_sound_dirt_defaults then
        draconis.sounds.dirt = default.node_sound_dirt_defaults()
    end
end

local clear_objects = minetest.clear_objects

function minetest.clear_objects(options)
    clear_objects(options)
    draconis.objects_last_cleared = os.time()
end

dofile(path.."/api/api.lua")
dofile(path.."/api/mount.lua")
dofile(path.."/api/behaviors.lua")
dofile(path.."/mobs/ice_dragon.lua")
dofile(path.."/mobs/fire_dragon.lua")
dofile(path.."/nodes.lua")
dofile(path.."/items.lua")
dofile(path.."/crafting.lua")

if minetest.get_modpath("3d_armor") then
    dofile(path.."/armor.lua")
end

draconis.cold_biomes = {}
draconis.warm_biomes = {}

minetest.register_on_mods_loaded(function()
	for name in pairs(minetest.registered_biomes) do
        local biome = minetest.registered_biomes[name]
		local heat = biome.heat_point or 0
		if heat < 40 then
            table.insert(draconis.cold_biomes, name)
        else
            table.insert(draconis.warm_biomes, name)
        end
	end
end)

dofile(path.."/mapgen.lua")

local simple_spawning = minetest.settings:get_bool("simple_spawning") or true

local spawn_rate = tonumber(minetest.settings:get("simple_spawn_rate")) or 512

if simple_spawning then
    creatura.register_mob_spawn("draconis:ice_dragon", {
        chance = spawn_rate,
        min_group = 1,
        max_group = 1,
        biomes = draconis.cold_biomes,
        nodes = {"air"}
    })
    creatura.register_mob_spawn("draconis:fire_dragon", {
        chance = spawn_rate,
        min_group = 1,
        max_group = 1,
        biomes = draconis.warm_biomes,
        nodes = {"air"}
    })
end