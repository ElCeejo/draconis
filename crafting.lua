-----------------------
-- Craftting Recipes --
-----------------------
------- Ver 1.0 -------

-- Get Craft Items --

local gold_block = "default:goldblock"
local steel_block = "default:steelblock"
local diamond = "default:diamond"
local steel_ingot = "default:steel_ingot"
local book = "default:book"
local furnace = "default:furnace"
local red_dye = "dye:red"

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_items) do
		if name:find("gold") and name:find("block") then
			gold_block = name
		end
        if (name:find("steel") or name:find("iron")) and name:find("block") then
			steel_block = name
		end
        if name:match(":diamond") then
			diamond = name
		end
        if name:match(":steel_ingot") or name:match(":ingot_steel")
		or name:match(":iron_ingot") or name:match(":ingot_iron") then
			steel_ingot = name
		end
        if name:match(":book") then
			book = name
		end
        if name:match(":furnace") then
			furnace = name
		end
        if minetest.get_item_group(name, "dye") > 0
        and name:find("red") then
            red_dye = name
        end
	end
end)


local ice_colors = {
    ["light_blue"] = "9df8ff",
    ["sapphire"] = "001fea",
    ["silver"] = "c5e4ed",
    ["slate"] = "4c646b",
    ["white"] = "e4e4e4"
}

local fire_colors = {
    ["black"] = "393939",
    ["bronze"] = "ff6d00",
    ["gold"] = "ffa300",
    ["green"] = "0abc00",
    ["red"] = "b10000"
}

--------------
-- Crafting --
--------------

minetest.register_craft({
	output = "draconis:dragon_flute",
	recipe = {
		{"", "", "draconis:dragon_bone"},
		{"", "draconis:dragon_bone", "draconis:dragon_bone"},
		{steel_block, "draconis:dragon_bone", ""},
	}
})

minetest.register_craft({
	output = "draconis:dragon_horn",
	recipe = {
		{"", "", gold_block},
		{"", "draconis:dragon_bone", gold_block},
		{"draconis:dragon_bone", "draconis:dragon_bone", ""},
	}
})

minetest.register_craft({
	output = "draconis:summoning_gem",
	recipe = {
		{"", "group:dragon_scales", ""},
		{"group:dragon_scales", diamond, "group:dragon_scales"},
		{"", "group:dragon_scales", ""},
	}
})

minetest.register_craft({
	output = "draconis:libri_draconis",
	recipe = {
		{"", "", ""},
		{"group:dragon_scales", "", ""},
		{"group:book", "group:color_red", ""},
	}
})

minetest.register_craft({
	output = "draconis:libri_draconis",
	recipe = {
		{"", "", ""},
		{"group:dragon_scales", "", ""},
		{"group:book", "group:unicolor_red", ""},
	}
})

minetest.register_craft({
	output = "draconis:draconic_steel_forge_ice",
	recipe = {
		{"draconis:frozen_stone", "draconis:frozen_stone", "draconis:frozen_stone"},
		{"draconis:frozen_stone", "default:furnace", "draconis:frozen_stone"},
		{"draconis:frozen_stone", "draconis:frozen_stone", "draconis:frozen_stone"},
	}
})

minetest.register_craft({
	output = "draconis:draconic_steel_forge_fire",
	recipe = {
		{"draconis:scorched_stone", "draconis:scorched_stone", "draconis:scorched_stone"},
		{"draconis:scorched_stone", "default:furnace", "draconis:scorched_stone"},
		{"draconis:scorched_stone", "draconis:scorched_stone", "draconis:scorched_stone"},
	}
})

for string in pairs(fire_colors) do
    minetest.register_craft({
        output = "draconis:fire_scale_block_" .. string,
        recipe = {
            {"draconis:scales_fire_dragon_" .. string, "draconis:scales_fire_dragon_" .. string, "draconis:scales_fire_dragon_" .. string},
            {"draconis:scales_fire_dragon_" .. string, "draconis:scales_fire_dragon_" .. string, "draconis:scales_fire_dragon_" .. string},
            {"draconis:scales_fire_dragon_" .. string, "draconis:scales_fire_dragon_" .. string, "draconis:scales_fire_dragon_" .. string},
        }
    })
end

for string in pairs(ice_colors) do
    minetest.register_craft({
        output = "draconis:ice_scale_block_" .. string,
        recipe = {
            {"draconis:scales_ice_dragon_" .. string, "draconis:scales_ice_dragon_" .. string, "draconis:scales_ice_dragon_" .. string},
            {"draconis:scales_ice_dragon_" .. string, "draconis:scales_ice_dragon_" .. string, "draconis:scales_ice_dragon_" .. string},
            {"draconis:scales_ice_dragon_" .. string, "draconis:scales_ice_dragon_" .. string, "draconis:scales_ice_dragon_" .. string},
        }
    })
end

minetest.register_craft({
    output = "draconis:dragonstone_bricks_fire 5",
    recipe = {
        {"draconis:stone_bricks_scorched", "group:fire_dragon_scale_block", "draconis:stone_bricks_scorched"},
        {"group:fire_dragon_scale_block", "draconis:stone_bricks_scorched", "group:fire_dragon_scale_block"},
        {"draconis:stone_bricks_scorched", "group:fire_dragon_scale_block", "draconis:stone_bricks_scorched"},
    }
})

minetest.register_craft({
    output = "draconis:dragonstone_bricks_ice 5",
    recipe = {
        {"draconis:stone_bricks_frozen", "group:ice_dragon_scale_block", "draconis:stone_bricks_frozen"},
        {"group:ice_dragon_scale_block", "draconis:stone_bricks_frozen", "group:ice_dragon_scale_block"},
        {"draconis:stone_bricks_frozen", "group:ice_dragon_scale_block", "draconis:stone_bricks_frozen"},
    }
})

minetest.register_craft({
    output = "draconis:stone_bricks_frozen 4",
    recipe = {
        {"draconis:stone_frozen", "draconis:stone_frozen"},
        {"draconis:stone_frozen", "draconis:stone_frozen"}
    }
})

minetest.register_craft({
    output = "draconis:stone_bricks_scorched 4",
    recipe = {
        {"draconis:stone_scorched", "draconis:stone_scorched"},
        {"draconis:stone_scorched", "draconis:stone_scorched"}
    }
})

---------------------------
-- Quick Craft Functions --
---------------------------

local function craft_pick(def)
    minetest.register_craft({
        output = def.output,
        recipe = {
            {def.material, def.material, def.material},
            {"", def.handle, ""},
            {"", def.handle, ""}
        }
    })
end

local function craft_shovel(def)
    minetest.register_craft({
        output = def.output,
        recipe = {
            {def.material},
            {def.handle},
            {def.handle}
        }
    })
end

local function craft_axe(def)
    minetest.register_craft({
        output = def.output,
        recipe = {
            {def.material, def.material},
            {def.material, def.handle},
            {"", def.handle}
        }
    })
end

local function craft_sword(def)
    minetest.register_craft({
        output = def.output,
        recipe = {
            {def.material},
            {def.material},
            {def.handle}
        }
    })
end

local function craft_helmet(def)
    minetest.register_craft({
		output = def.output,
		recipe = {
			{def.material, def.material, def.material},
			{def.material, "", def.material},
			{"", "", ""},
		},
	})
end

local function craft_chestplate(def)
    minetest.register_craft({
		output = def.output,
		recipe = {
			{def.material, "", def.material},
			{def.material, def.material, def.material},
			{def.material, def.material, def.material},
		},
	})
end

local function craft_leggings(def)
    minetest.register_craft({
		output = def.output,
		recipe = {
			{def.material, def.material, def.material},
			{def.material, "", def.material},
			{def.material, "", def.material},
		},
	})
end

local function craft_boots(def)
    minetest.register_craft({
		output = def.output,
		recipe = {
			{"", "", ""},
			{def.material, "", def.material},
			{def.material, "", def.material},
		},
	})
end

-----------
-- Tools --
-----------

-- Dragon Bone Tools --

craft_pick({
    handle = steel_ingot,
    material = "draconis:dragon_bone",
    output = "draconis:pick_dragonbone"
})

craft_shovel({
    handle = steel_ingot,
    material = "draconis:dragon_bone",
    output = "draconis:shovel_dragonbone"
})

craft_axe({
    handle = steel_ingot,
    material = "draconis:dragon_bone",
    output = "draconis:axe_dragonbone"
})

craft_sword({
    handle = steel_ingot,
    material = "draconis:dragon_bone",
    output = "draconis:sword_dragonbone"
})

-- Fire-Forged Draconic Steel Tools --

craft_pick({
    handle = "draconis:dragon_bone",
    material = "draconis:draconic_steel_ingot_fire",
    output = "draconis:pick_fire_draconic_steel"
})

craft_shovel({
    handle = "draconis:dragon_bone",
    material = "draconis:draconic_steel_ingot_fire",
    output = "draconis:shovel_fire_draconic_steel"
})

craft_axe({
    handle = "draconis:dragon_bone",
    material = "draconis:draconic_steel_ingot_fire",
    output = "draconis:axe_fire_draconic_steel"
})

craft_sword({
    handle = "draconis:dragon_bone",
    material = "draconis:draconic_steel_ingot_fire",
    output = "draconis:sword_fire_draconic_steel"
})

-- Ice-Forged Draconic Steel Tools --

craft_pick({
    handle = "draconis:dragon_bone",
    material = "draconis:draconic_steel_ingot_ice",
    output = "draconis:pick_ice_draconic_steel"
})

craft_shovel({
    handle = "draconis:dragon_bone",
    material = "draconis:draconic_steel_ingot_ice",
    output = "draconis:shovel_ice_draconic_steel"
})

craft_axe({
    handle = "draconis:dragon_bone",
    material = "draconis:draconic_steel_ingot_ice",
    output = "draconis:axe_ice_draconic_steel"
})

craft_sword({
    handle = "draconis:dragon_bone",
    material = "draconis:draconic_steel_ingot_ice",
    output = "draconis:sword_ice_draconic_steel"
})

-----------
-- Armor --
-----------

-- Fire-Forged Draconic Steel Armor --

craft_helmet({
    output = "draconis:helmet_fire_draconic_steel",
    material = "draconis:draconic_steel_ingot_fire"
})

craft_chestplate({
    output = "draconis:chestplate_fire_draconic_steel",
    material = "draconis:draconic_steel_ingot_fire"
})

craft_leggings({
    output = "draconis:leggings_fire_draconic_steel",
    material = "draconis:draconic_steel_ingot_fire"
})

craft_boots({
    output = "draconis:boots_fire_draconic_steel",
    material = "draconis:draconic_steel_ingot_fire"
})

-- Ice-Forged Draconic Steel Armor --

craft_helmet({
    output = "draconis:helmet_ice_draconic_steel",
    material = "draconis:draconic_steel_ingot_ice"
})

craft_chestplate({
    output = "draconis:chestplate_ice_draconic_steel",
    material = "draconis:draconic_steel_ingot_ice"
})

craft_leggings({
    output = "draconis:leggings_ice_draconic_steel",
    material = "draconis:draconic_steel_ingot_ice"
})

craft_boots({
    output = "draconis:boots_ice_draconic_steel",
    material = "draconis:draconic_steel_ingot_ice"
})