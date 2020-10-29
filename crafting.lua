-----------------------
-- Craftting Recipes --
-----------------------
------- Ver 1.0 -------

--------------
-- Crafting --
--------------

minetest.register_craft({
	output = "draconis:lectern",
	recipe = {
		{"stairs:slab_wood", "stairs:slab_wood", "stairs:slab_wood"},
		{"", "default:wood", ""},
		{"stairs:slab_wood", "stairs:slab_wood", "stairs:slab_wood"},
	}
})

minetest.register_craft({
	output = "draconis:dragon_flute",
	recipe = {
		{"", "", "draconis:dragon_bone"},
		{"", "draconis:dragon_bone", "draconis:dragon_bone"},
		{"draconis:dragon_bone", "draconis:dragon_bone", ""},
	}
})

minetest.register_craft({
	output = "draconis:growth_essence_fire",
	recipe = {
		{"draconis:dracolily_fire", "draconis:blood_fire_dragon", "draconis:dracolily_fire"},
		{"draconis:blood_fire_dragon", "vessels:glass_bottle", "draconis:blood_fire_dragon"},
		{"draconis:dracolily_fire", "draconis:blood_fire_dragon", "draconis:dracolily_fire"},
	}
})

minetest.register_craft({
	output = "draconis:growth_essence_ice",
	recipe = {
		{"draconis:dracolily_ice", "draconis:blood_ice_dragon", "draconis:dracolily_ice"},
		{"draconis:blood_ice_dragon", "vessels:glass_bottle", "draconis:blood_ice_dragon"},
		{"draconis:dracolily_ice", "draconis:blood_ice_dragon", "draconis:dracolily_ice"},
	}
})

minetest.register_craft({
	output = "draconis:summoning_gem",
	recipe = {
		{"", "group:dragon_blood", ""},
		{"group:dragon_blood", "default:diamond", "group:dragon_blood"},
		{"", "group:dragon_blood", ""},
	}
})

minetest.register_craft({
	output = "draconis:summoning_gem",
	recipe = {
		{"", "draconis:blood_fire_dragon", ""},
		{"draconis:blood_fire_dragon", "default:diamond", "draconis:blood_fire_dragon"},
		{"", "draconis:blood_fire_dragon", ""},
	}
})

minetest.register_craft({
	output = "draconis:bestiary",
	recipe = {
		{"", "", ""},
		{"group:dragon_scales", "", ""},
		{"default:book", "group:color_red", ""},
	}
})

for _, fire_color in pairs(draconis.fire_colors) do
    local scales = "draconis:scales_fire_dragon_"..fire_color
    local bricks = "default:stonebrick"
    minetest.register_craft({
        output = "draconis:fire_scale_brick_"..fire_color.." 4",
        recipe = {
            {bricks, scales, bricks},
            {scales, scales, scales},
            {bricks, scales, bricks},
        }
    })
end

for _, ice_color in pairs(draconis.ice_colors) do
    local scales = "draconis:scales_ice_dragon_"..ice_color
    local bricks = "default:stonebrick"
    minetest.register_craft({
        output = "draconis:ice_scale_brick_"..ice_color.." 4",
        recipe = {
            {bricks, scales, bricks},
            {scales, scales, scales},
            {bricks, scales, bricks},
        }
    })
end

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
    handle = "default:steel_ingot",
    material = "draconis:dragon_bone",
    output = "draconis:pick_dragonbone"
})

craft_shovel({
    handle = "default:steel_ingot",
    material = "draconis:dragon_bone",
    output = "draconis:shovel_dragonbone"
})

craft_axe({
    handle = "default:steel_ingot",
    material = "draconis:dragon_bone",
    output = "draconis:axe_dragonbone"
})

craft_sword({
    handle = "default:steel_ingot",
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