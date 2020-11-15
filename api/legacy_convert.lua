-----------------------
-- Legacy Conversion --
--------- 1.0 ---------

local ice_colors = draconis.ice_colors

local fire_colors = draconis.fire_colors

local random = math.random

-- Convert Mobs --

local old_ice_ents = {
    "draconis:ice_wyvern",
    "draconis:hatched_ice_wyvern"
}

local old_fire_ents = {
    "draconis:fire_dragon",
    "draconis:fire_wyvern",
    "draconis:hatched_fire_dragon",
    "draconis:hatched_fire_wyvern" 
}

for _, ent in pairs(old_ice_ents) do
    minetest.register_entity(":"..ent, {
        on_activate = function(self, staticdata)
            local pos = self.object:get_pos()
            minetest.add_entity(pos, "draconis:fire_dragon_egg_" .. fire_colors[random(1, 4)] .. "_ent")
            self.object:remove()
        end,
    })
end

for _, ent in pairs(old_fire_ents) do
    minetest.register_entity(":"..ent, {
        on_activate = function(self, staticdata)
            local pos = self.object:get_pos()
            minetest.add_entity(pos, "draconis:ice_dragon_egg_" .. ice_colors[random(1, 4)] .. "_ent")
            self.object:remove()
        end,
    })
end

-- Convert Items/Nodes --

local old_ice_nodes = {
    "draconis:ice_wyvern_egg",
    "draconis:ice_wyvern_nest"
}

local old_fire_nodes = {
    "draconis:fire_dragon_egg",
    "draconis:fire_wyvern_egg",
    "draconis:fire_wyvern_nest"
}

for _, ice in pairs(old_ice_nodes) do
    minetest.register_alias_force(ice, "draconis:egg_ice_dragon_" .. ice_colors[random(1, 4)])
end

for _, fire in pairs(old_fire_nodes) do
minetest.register_alias_force(fire, "draconis:egg_fire_dragon_" .. fire_colors[random(1, 4)])
end

minetest.register_alias_force("draconis:jungle_wyvern_egg", "")

minetest.register_alias_force("draconis:cold_ice", "draconis:ice_scale_brick_sapphire")
minetest.register_alias_force("draconis:hot_obsidian", "draconis:fire_scale_brick_red")

minetest.register_abm({
    label = "draconis:legacy_convert_fire",
    nodenames = old_fire_nodes,
    interval = 1,
    chance = 1,
    action = function(pos)
        minetest.add_entity(pos, "draconis:fire_dragon_egg_" .. fire_colors[random(1, 4)] .. "_ent")
        minetest.set_node(pos, {name = "air"})
    end,
})

minetest.register_abm({
    label = "draconis:legacy_convert_ice",
    nodenames = old_ice_nodes,
    interval = 1,
    chance = 1,
    action = function(pos)
        minetest.add_entity(pos, "draconis:ice_dragon_egg_" .. ice_colors[random(1, 4)] .. "_ent")
        minetest.set_node(pos, {name = "air"})
    end,
})

minetest.register_abm({
    label = "draconis:legacy_convert_jungle",
    nodenames = {
        "draconis:jungle_wyvern_egg"
    },
    interval = 1,
    chance = 1,
    action = function(pos)
        minetest.set_node(pos, {name = "air"})
    end,
})
