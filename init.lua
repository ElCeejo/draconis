--------------
-- Draconis --
--------------

draconis = {
	wyverns = {},
	force_storage_save = false
}

local path = minetest.get_modpath("draconis")

-- Global Tables --

local storage = dofile(path.."/storage.lua")

draconis.dragons = storage.dragons
draconis.bonded_dragons = storage.bonded_dragons
draconis.aux_key_setting = storage.aux_key_setting
draconis.attack_blacklist = storage.attack_blacklist
draconis.libri_font_size = storage.libri_font_size

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

draconis.colors_fire = {
    ["black"] = "393939",
    ["bronze"] = "ff6d00",
    ["gold"] = "ffa300",
    ["green"] = "0abc00",
    ["red"] = "b10000"
}

draconis.colors_ice = {
    ["light_blue"] = "9df8ff",
    ["sapphire"] = "001fea",
    ["silver"] = "c5e4ed",
    ["slate"] = "4c646b",
    ["white"] = "e4e4e4"
}

draconis.global_nodes = {}

draconis.global_nodes["flame"] = "fire:basic_flame"
draconis.global_nodes["ice"] = "default:ice"
draconis.global_nodes["steel_blockj"] = "default:steelblock"

minetest.register_on_mods_loaded(function()
    for name, def in pairs(minetest.registered_nodes) do
        -- Flame
        if not (draconis.global_nodes["flame"]
        or not minetest.registered_nodes[draconis.global_nodes["flame"]])
        and (name:find("flame") or name:find("fire"))
        and def.drawtype == "firelike" then
            draconis.global_nodes["flame"] = name
        end
        -- Ice
        if not (draconis.global_nodes["ice"]
        or not minetest.registered_nodes[draconis.global_nodes["ice"]])
        and name:find(":ice")
        and minetest.get_item_group(name, "slippery") > 0 then
            draconis.global_nodes["ice"] = name
        end
        -- Steel Block
        if not (draconis.global_nodes["steel_blockj"]
        or not minetest.registered_nodes[draconis.global_nodes["steel_blockj"]])
        and (name:find(":steel")
        or name:find(":iron"))
        and name:find("block") then
            draconis.global_nodes["steel_blockj"] = name
        end
    end
end)

local clear_objects = minetest.clear_objects

function minetest.clear_objects(options)
    clear_objects(options)
    for id, dragon in pairs(draconis.dragons) do
        if not dragon.stored_in_item then
            draconis.dragons[id] = nil
            if draconis.bonded_dragons[id] then
                draconis.bonded_dragons[id] = nil
            end
        end
    end
end

-- Load Files --

dofile(path.."/api/api.lua")
dofile(path.."/api/mount.lua")
dofile(path.."/api/behaviors.lua")
dofile(path.."/mobs/ice_dragon.lua")
dofile(path.."/mobs/fire_dragon.lua")
dofile(path.."/mobs/jungle_wyvern.lua")
dofile(path.."/nodes.lua")
dofile(path.."/craftitems.lua")
dofile(path.."/api/libri.lua")

if minetest.get_modpath("3d_armor") then
    dofile(path.."/armor.lua")
end

-- Spawning --

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

local simple_spawning = minetest.settings:get_bool("simple_spawning") or false

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

-- Aliases --

minetest.register_alias("draconis:dracolily_fire", "air")
minetest.register_alias("draconis:dracolily_ice", "air")

minetest.register_alias("draconis:blood_fire_dragon", "")
minetest.register_alias("draconis:blood_ice_dragon", "")

minetest.register_alias("draconis:manuscript", "")

for color in pairs(draconis.colors_ice) do
    minetest.register_alias("draconis:egg_ice_dragon_" .. color, "draconis:egg_ice_" .. color)
end

for color in pairs(draconis.colors_fire) do
    minetest.register_alias("draconis:egg_fire_dragon_" .. color, "draconis:egg_fire_" .. color)
end

minetest.register_entity("draconis:ice_eyes", {
    on_activate = function(self)
        self.object:remove()
    end
})

minetest.register_entity("draconis:fire_eyes", {
    on_activate = function(self)
        self.object:remove()
    end
})

minetest.register_node("draconis:spawn_node", {
    drawtype = "airlike"
})

minetest.register_abm({
    label = "Fix Spawn Nodes",
    nodenames = {"draconis:spawn_node"},
    interval = 10,
    chance = 1,
    action = function(pos)
        local meta = minetest.get_meta(pos)
        local mob = meta:get_string("name")
        minetest.set_node(pos, {name = "creatura:spawn_node"})
        if mob ~= "" then
            meta:set_string("mob", mob)
        end
    end,
})

minetest.log("action", "[MOD] Draconis [2.0] loaded")
