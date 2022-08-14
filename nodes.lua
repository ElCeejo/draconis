-----------
-- Nodes --
-----------

local random = math.random

-- Sounds --

-- Get Craft Items --

local steel_ingot = "default:steel_ingot"

minetest.register_on_mods_loaded(function()
	for name in pairs(minetest.registered_items) do
		if name:match(":steel_ingot") or name:match(":ingot_steel")
		or name:match(":iron_ingot") or name:match(":ingot_iron") then
			steel_ingot = name
			break
		end
	end
end)

-- Local Utilities --

local function correct_name(str)
	if str then
		if str:match(":") then str = str:split(":")[2] end
		return (string.gsub(" " .. str, "%W%l", string.upper):sub(2):gsub("_", " "))
	end
end

local function infotext(str, format)
	if format then
		return minetest.colorize("#a9a9a9", correct_name(str))
	end
	return minetest.colorize("#a9a9a9", str)
end

local stair_queue = {}

local function register_node(name, def, register_stair)
	minetest.register_node(name, def)
	if register_stair then
		table.insert(stair_queue, name)
	end
end

-- Logs --

register_node("draconis:log_scorched", {
	description = "Scorched Log",
	tiles = {"draconis_log_scorched_top.png", "draconis_log_scorched_top.png", "draconis_log_scorched.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2},
	sounds = draconis.sounds.wood,
	on_place = minetest.rotate_node
}, true)

register_node("draconis:log_frozen", {
	description = "Frozen Log",
	tiles = {"draconis_log_frozen_top.png", "draconis_log_frozen_top.png", "draconis_log_frozen.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2},
	sounds = draconis.sounds.wood,
	on_place = minetest.rotate_node
}, true)

-- Stone --

register_node("draconis:stone_scorched", {
	description = "Scorched Stone",
	tiles = {"draconis_stone_scorched.png"},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	groups = {cracky = 1, level = 3},
	sounds = draconis.sounds.stone
}, true)

register_node("draconis:stone_frozen", {
	description = "Frozen Stone",
	tiles = {"draconis_stone_frozen.png"},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	groups = {cracky = 1, level = 3},
	sounds = draconis.sounds.stone
}, true)

-- Soil --

register_node("draconis:soil_scorched", {
	description = "Scorched Soil",
	tiles = {"draconis_soil_scorched.png"},
	groups = {crumbly = 3, soil = 1},
	sounds = draconis.sounds.dirt
})

register_node("draconis:soil_frozen", {
	description = "Frozen Soil",
	tiles = {"draconis_soil_frozen.png"},
	groups = {crumbly = 3, soil = 1},
	sounds = draconis.sounds.dirt
})

-- Wood Planks

register_node("draconis:wood_planks_scorched", {
	description = "Scorched Wood Planks",
	tiles = {"draconis_wood_planks_scorched.png"},
	is_ground_content = false,
	groups = {tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2},
	sounds = draconis.sounds.wood,
}, true)

register_node("draconis:wood_planks_frozen", {
	description = "Frozen Wood Planks",
	tiles = {"draconis_wood_planks_frozen.png"},
	is_ground_content = false,
	groups = {tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2},
	sounds = draconis.sounds.wood,
}, true)

-- Stone Bricks --

register_node("draconis:dragonstone_bricks_fire", {
	description = "Fire Dragonstone Bricks",
	tiles = {"draconis_dragonstone_bricks_fire.png"},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	groups = {cracky = 1, level = 2},
	sounds = draconis.sounds.stone
}, true)

register_node("draconis:dragonstone_block_fire", {
	description = "Fire Dragonstone Block",
	tiles = {"draconis_dragonstone_block_fire.png"},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	groups = {cracky = 1, level = 2},
	sounds = draconis.sounds.stone
}, true)

register_node("draconis:dragonstone_bricks_ice", {
	description = "Ice Dragonstone Bricks",
	tiles = {"draconis_dragonstone_bricks_ice.png"},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	groups = {cracky = 1, level = 2},
	sounds = draconis.sounds.stone
}, true)

register_node("draconis:dragonstone_block_ice", {
	description = "Ice Dragonstone Block",
	tiles = {"draconis_dragonstone_block_ice.png"},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	groups = {cracky = 1, level = 2},
	sounds = draconis.sounds.stone
}, true)

register_node("draconis:stone_bricks_scorched", {
	description = "Scorched Stone Brick",
	tiles = {"draconis_stone_brick_scorched.png"},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	groups = {cracky = 1, level = 3},
	sounds = draconis.sounds.stone
}, true)

register_node("draconis:stone_bricks_frozen", {
	description = "Frozen Stone Brick",
	tiles = {"draconis_stone_brick_frozen.png"},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	groups = {cracky = 1, level = 3},
	sounds = draconis.sounds.stone
}, true)

------------------
-- Scale Blocks --
------------------

for color in pairs(draconis.colors_fire) do
	register_node("draconis:dragonhide_block_fire_" .. color, {
		description = "Fire Dragonhide Block \n" .. infotext(color, true),
		tiles = {
			"draconis_dragonhide_block_" .. color .. "_top.png",
			"draconis_dragonhide_block_" .. color .. "_top.png",
			"draconis_dragonhide_block_" .. color .. ".png"
		},
		paramtype2 = "facedir",
		place_param2 = 0,
		is_ground_content = false,
		groups = {cracky = 1, level = 3, fire_dragonhide_block = 1},
		sounds = draconis.sounds.stone
	})
end

for color in pairs(draconis.colors_ice) do
	register_node("draconis:dragonhide_block_ice_" .. color, {
		description = "Ice Dragonhide Block \n" .. infotext(color, true),
		tiles = {
			"draconis_dragonhide_block_" .. color .. "_top.png",
			"draconis_dragonhide_block_" .. color .. "_top.png",
			"draconis_dragonhide_block_" .. color .. ".png"
		},
		paramtype2 = "facedir",
		place_param2 = 0,
		is_ground_content = false,
		groups = {cracky = 1, level = 3, ice_dragonhide_block = 1},
		sounds = draconis.sounds.stone
	})
end

-- Bone Pile --

register_node("draconis:bone_pile_scorched", {
	description = "Scorched Bone Pile",
	tiles = {
		"draconis_bone_pile_scorched.png",
	},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	groups = {cracky = 3, level = 1, flammable = 1},
	sounds = draconis.sounds.wood
})

register_node("draconis:bone_pile_frozen", {
	description = "Frozen Bone Pile",
	tiles = {
		"draconis_bone_pile_frozen.png",
	},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	groups = {cracky = 3, level = 1, slippery = 1},
	sounds = draconis.sounds.wood
})

--------------------------
-- Draconic Steel Forge --
--------------------------

local stack_size = minetest.registered_items[steel_ingot].stack_max or 99

local forge_core = {
	["draconis:draconic_forge_fire"] = "draconis:dragonstone_block_fire",
	["draconis:draconic_forge_ice"] = "draconis:dragonstone_block_ice"
}

local forge_shell = {
	["draconis:draconic_forge_fire"] = "draconis:dragonstone_bricks_fire",
	["draconis:draconic_forge_ice"] = "draconis:dragonstone_bricks_ice"
}

local function update_fire_form(meta)
	local melt_perc = meta:get_int("melt_perc") or 0
	local cool_perc = meta:get_int("cool_perc") or 0
	local formspec
	if melt_perc > 0 and melt_perc <= 100
	or cool_perc > 0 and cool_perc <= 100 then
		-- Melting Formspec
		local melt = "image[3.475,1.3;1.56,0.39;draconis_form_fire_empty.png^[transformR270]"
		if melt_perc > 0 then
			melt = "image[3.475,1.3;1.56,0.39;draconis_form_fire_empty.png^[lowpart:"..
			melt_perc..":draconis_form_fire_full.png^[transformR270]]"
		end
		-- Cooling Formspec
		local elbow_up = "image[6.35,1.325;1.95,0.39;draconis_form_fire_elbow_up_empty.png^[transformR270]"
		local elbow_down = "image[7.91,1.7;0.39,1.69;draconis_form_fire_elbow_down_empty.png^[transformFY]]"
		if cool_perc > 0 then
			local elbow_p1 = math.floor((cool_perc * 2) / 100 * 100)
			local elbow_p2 = elbow_p1 - 100
			if elbow_p1 > 100 then
				elbow_p1 = 100
			else
				elbow_p2 = 0
			end
			if elbow_p2 > 100 then
				elbow_p2 = 100
			end
			elbow_up = "image[6.35,1.325;1.95,0.39;draconis_form_fire_elbow_up_empty.png^[lowpart:"..
			elbow_p1..":draconis_form_fire_elbow_up_full.png^[transformR270]]"
			if elbow_p2 > 0 then
				elbow_down = "image[7.91,1.7;0.39,1.69;draconis_form_fire_elbow_down_empty.png^[lowpart:"..
				elbow_p2..":draconis_form_fire_elbow_down_full.png^[transformFY]]"
			end
		end
		formspec = table.concat({
			"formspec_version[3]",
			"size[11,10]",
			"image[0,0;11,10;draconis_form_forge_bg.png]",
			-- Melting Percentage
			melt,
			-- Cooling Percentage
			elbow_up,
			-- Cooling Percentage P2
			elbow_down,
			"list[current_player;main;0.65,5;8,4;]",
			"list[context;input;2.325,1.05;1,1;]",
			"list[context;crucible;5.175,1.05;1,1;]",
			"list[context;output;7.65,3.5;1,1;]",
			"listring[current_player;main]",
			"listring[context;input]",
			"listring[current_player;main]",
			"listring[context;crucible]",
			"listring[current_player;main]",
			"listring[context;output]",
			"listring[current_player;main]"
		}, "")
	else
		formspec = table.concat({
			"formspec_version[3]",
			"size[11,10]",
			"image[0,0;11,10;draconis_form_forge_bg.png]",
			"image[3.475,1.3;1.56,0.39;draconis_form_fire_empty.png^[transformR270]",
			"image[6.35,1.325;1.95,0.39;draconis_form_fire_elbow_up_empty.png^[transformR270]",
			"image[7.91,1.7;0.39,1.69;draconis_form_fire_elbow_down_empty.png^[transformFY]]",
			"list[current_player;main;0.65,5;8,4;]",
			"list[context;input;2.325,1.05;1,1;]",
			"list[context;crucible;5.175,1.05;1,1;]",
			"list[context;output;7.65,3.5;1,1;]",
			"listring[current_player;main]",
			"listring[context;input]",
			"listring[current_player;main]",
			"listring[context;crucible]",
			"listring[current_player;main]",
			"listring[context;output]",
			"listring[current_player;main]"
		}, "")
	end
	meta:set_string("formspec", formspec)
end

local function update_ice_form(meta)
	local cool_perc = meta:get_int("cool_perc") or 0
	local formspec
	if cool_perc > 0 and cool_perc <= 100 then
		-- Cooling Formspec
		local elbow_up = "image[6.35,1.325;1.95,0.39;draconis_form_fire_elbow_up_empty.png^[transformR270]"
		local elbow_down = "image[7.91,1.7;0.39,1.69;draconis_form_fire_elbow_down_empty.png^[transformFY]]"
		if cool_perc > 0 then
			local elbow_p1 = math.floor((cool_perc * 2) / 100 * 100)
			local elbow_p2 = elbow_p1 - 100
			if elbow_p1 > 100 then
				elbow_p1 = 100
			else
				elbow_p2 = 0
			end
			if elbow_p2 > 100 then
				elbow_p2 = 100
			end
			elbow_up = "image[6.35,1.325;1.95,0.39;draconis_form_fire_elbow_up_empty.png^[lowpart:"..
			elbow_p1..":draconis_form_fire_elbow_up_full.png^[transformR270]]"
			if elbow_p2 > 0 then
				elbow_down = "image[7.91,1.7;0.39,1.69;draconis_form_fire_elbow_down_empty.png^[lowpart:"..
				elbow_p2..":draconis_form_fire_elbow_down_full.png^[transformFY]]"
			end
		end
		formspec = table.concat({
			"formspec_version[3]",
			"size[11,10]",
			"image[0,0;11,10;draconis_form_forge_bg.png]",
			-- Cooling Percentage
			elbow_up,
			-- Cooling Percentage P2
			elbow_down,
			"list[current_player;main;0.65,5;8,4;]",
			"list[context;crucible;5.175,1.05;1,1;]",
			"list[context;output;7.65,3.5;1,1;]",
			"listring[current_player;main]",
			"listring[context;crucible]",
			"listring[current_player;main]",
			"listring[context;output]",
			"listring[current_player;main]"
		}, "")
	else
		formspec = table.concat({
			"formspec_version[3]",
			"size[11,10]",
			"image[0,0;11,10;draconis_form_forge_bg.png]",
			"image[6.35,1.325;1.95,0.39;draconis_form_fire_elbow_up_empty.png^[transformR270]",
			"image[7.91,1.7;0.39,1.69;draconis_form_fire_elbow_down_empty.png^[transformFY]]",
			"list[current_player;main;0.65,5;8,4;]",
			"list[context;crucible;5.175,1.05;1,1;]",
			"list[context;output;7.65,3.5;1,1;]",
			"listring[current_player;main]",
			"listring[context;crucible]",
			"listring[current_player;main]",
			"listring[context;output]",
			"listring[current_player;main]"
		}, "")
	end
	meta:set_string("formspec", formspec)
end

local core_v = {
	-- Center
	{x = 1, y = 0, z = -1},
	{x = 1, y = 0, z = 1},
	{x = -1, y = 0, z = -1},
	{x = -1, y = 0, z = 1},
	{x = -1, y = 1, z = 0},
	{x = 1, y = 1, z = 0},
	{x = 0, y = 1, z = -1},
	{x = 0, y = 1, z = 1},
	{x = -1, y = -1, z = 0},
	{x = 1, y = -1, z = 0},
	{x = 0, y = -1, z = -1},
	{x = 0, y = -1, z = 1},
	{x = 1, y = 1, z = -1},
	{x = 1, y = 1, z = 1},
	{x = -1, y = 1, z = -1},
	{x = -1, y = 1, z = 1},
	{x = 1, y = -1, z = -1},
	{x = 1, y = -1, z = 1},
	{x = -1, y = -1, z = -1},
	{x = -1, y = -1, z = 1},
	{x = 0, y = -1, z = 0},
	-- Chimney
	{x = 1, y = 2, z = -1},
	{x = 1, y = 2, z = 1},
	{x = -1, y = 2, z = -1},
	{x = -1, y = 2, z = 1},
	{x = 1, y = 3, z = -1},
	{x = 1, y = 3, z = 1},
	{x = -1, y = 3, z = -1},
	{x = -1, y = 3, z = 1},
	-- Outer Frame
	{x = 2, y = 0, z = -2},
	{x = 2, y = 0, z = 2},
	{x = -2, y = 0, z = -2},
	{x = -2, y = 0, z = 2},
	{x = 2, y = 1, z = -2},
	{x = 2, y = 1, z = 2},
	{x = -2, y = 1, z = -2},
	{x = -2, y = 1, z = 2},
	{x = 2, y = -1, z = -2},
	{x = 2, y = -1, z = 2},
	{x = -2, y = -1, z = -2},
	{x = -2, y = -1, z = 2},
	{x = 2, y = -2, z = -2},
	{x = 2, y = -2, z = 2},
	{x = -2, y = -2, z = -2},
	{x = -2, y = -2, z = 2}
}

local shell_v = {
	-- Chimney
	{x = 1, y = 2, z = 0},
	{x = 0, y = 2, z = 1},
	{x = 0, y = 2, z = -1},
	{x = -1, y = 2, z = 0},
	{x = 1, y = 3, z = 0},
	{x = 0, y = 3, z = 1},
	{x = 0, y = 3, z = -1},
	{x = -1, y = 3, z = 0},
	-- Walls
	{x = 1, y = 1, z = -2},
	{x = 1, y = 1, z = 2},
	{x = -1, y = 1, z = -2},
	{x = -1, y = 1, z = 2},
	{x = 2, y = 1, z = -1},
	{x = 2, y = 1, z = 1},
	{x = -2, y = 1, z = -1},
	{x = -2, y = 1, z = 1},
	{x = 2, y = 1, z = 0},
	{x = 0, y = 1, z = 2},
	{x = -2, y = 1, z = 0},
	{x = 0, y = 1, z = -2},

	{x = 1, y = 0, z = -2},
	{x = 1, y = 0, z = 2},
	{x = -1, y = 0, z = -2},
	{x = -1, y = 0, z = 2},
	{x = 2, y = 0, z = -1},
	{x = 2, y = 0, z = 1},
	{x = -2, y = 0, z = -1},
	{x = -2, y = 0, z = 1},

	{x = 1, y = -1, z = -2},
	{x = 1, y = -1, z = 2},
	{x = -1, y = -1, z = -2},
	{x = -1, y = -1, z = 2},
	{x = 2, y = -1, z = -1},
	{x = 2, y = -1, z = 1},
	{x = -2, y = -1, z = -1},
	{x = -2, y = -1, z = 1},
	{x = 2, y = -1, z = 0},
	{x = 0, y = -1, z = 2},
	{x = -2, y = -1, z = 0},
	{x = 0, y = -1, z = -2},
	-- Shell Bottom
	{x = -1, y = -2, z = 0},
	{x = 1, y = -2, z = 0},
	{x = 0, y = -2, z = -1},
	{x = 0, y = -2, z = 1},
	{x = 1, y = -2, z = -1},
	{x = 1, y = -2, z = 1},
	{x = -1, y = -2, z = -1},
	{x = -1, y = -2, z = 1},
	{x = 0, y = -2, z = 0}
}

local function get_forge_structure(pos) -- Check if structure around forge is complete
	local node = minetest.get_node(pos)
	local name = node.name
	local core_material = forge_core[name]
	for i = 1, #core_v do
		local node_v = minetest.get_node(vector.add(pos, core_v[i]))
		if node_v.name ~= core_material then
			return false
		end
	end
	local shell_material = forge_shell[name]
	for i = 1, #shell_v do
		local node_v = minetest.get_node(vector.add(pos, shell_v[i]))
		if node_v.name ~= shell_material then
			return false
		end
	end
	local empty_v = {
		-- Chimney
		{x = 0, y = 1, z = 0},
		{x = 0, y = 2, z = 0},
		{x = 0, y = 3, z = 0},
		-- Walls
		{x = 1, y = -2, z = -2},
		{x = 1, y = -2, z = 2},
		{x = -1, y = -2, z = -2},
		{x = -1, y = -2, z = 2},
		{x = 2, y = -2, z = -1},
		{x = 2, y = -2, z = 1},
		{x = -2, y = -2, z = -1},
		{x = -2, y = -2, z = 1},
		{x = 2, y = -2, z = 0},
		{x = 0, y = -2, z = 2},
		{x = -2, y = -2, z = 0},
		{x = 0, y = -2, z = -2},
	}
	for i = 1, #empty_v do
		local node_v = minetest.get_node(vector.add(pos, empty_v[i]))
		if creatura.get_node_def(node_v.name).walkable then
			return false
		end
	end
	return true
end

local function remove_forge_structure(pos) -- Removes Forge Structure
	for i = 1, #core_v do
		minetest.remove_node(vector.add(pos, core_v[i]))
	end
	for i = 1, #shell_v do
		minetest.remove_node(vector.add(pos, shell_v[i]))
	end
end

-- Fire Forge Funcs

local function forge_particle(pos, texture, animation)
	local flame_dir = {x = 0, y = 1, z = 0}
	minetest.add_particlespawner({
		amount = 6,
		time = 1,
		minpos = vector.add(pos, flame_dir),
		maxpos = vector.add(pos, flame_dir),
		minvel = vector.multiply(flame_dir, 2),
		maxvel = vector.multiply(flame_dir, 3),
		minacc = {x = random(-3, 3), y = 2, z = random(-3, 3)},
		maxacc = {x = random(-3, 3), y = 6, z = random(-3, 3)},
		minexptime = 0.5,
		maxexptime = 1.5,
		minsize = 5,
		maxsize = 8,
		collisiondetection = false,
		vertical = false,
		glow = 16,
		texture = texture,
		animation = animation,
	})
end

local function melt_ingots(pos, dragon_id)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local input = inv:get_stack("input", 1)
	local crucible = inv:get_stack("crucible", 1)
	if input:get_name() ~= steel_ingot
	or input:get_count() < stack_size
	or crucible:get_name() ~= "draconis:dragonstone_crucible" then
		minetest.get_node_timer(pos):stop()
		update_fire_form(meta)
	else
		input:take_item(stack_size)
		inv:set_stack("input", 1, input)
		local full_crucible = ItemStack("draconis:dragonstone_crucible_full")
		full_crucible:get_meta():set_string("dragon_id", dragon_id)
		inv:set_stack("crucible", 1, full_crucible)
	end
end

local function cool_crucible(pos, ingot)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local crucible = inv:get_stack("crucible", 1)
	local node = minetest.get_node(pos)
	local name = node.name
	if crucible:get_name() ~= "draconis:dragonstone_crucible_full" then
		minetest.get_node_timer(pos):stop()
	else
		local dragon_id = crucible:get_meta():get_string("dragon_id")
		if name:find("ice") then
			dragon_id = meta:get_string("dragon_id")
		end
		inv:set_stack("crucible", 1, "draconis:dragonstone_crucible")
		local draconic_ingot = ItemStack(ingot)
		local ingot_meta = draconic_ingot:get_meta()
		local ingot_desc = minetest.registered_items[ingot].description
		local dragon_name = "Unnamed Dragon"
		if draconis.dragons[dragon_id]
		and draconis.dragons[dragon_id].name then
			dragon_name = draconis.dragons[dragon_id].name
		end
		ingot_meta:set_string("dragon_id", dragon_id)
		ingot_meta:set_string("description", ingot_desc .. "\n(Forged by " .. dragon_name .. ")")
		inv:set_stack("output", 1, draconic_ingot)
		meta:set_int("cool_perc", 0)
	end
	if name:find("ice") then
		update_ice_form(meta)
	else
		update_fire_form(meta)
	end
end

minetest.register_node("draconis:draconic_forge_fire", {
	description = "Fire Draconic Steel Forge",
	tiles = {
		"draconis_dragonstone_block_fire.png",
		"draconis_dragonstone_block_fire.png",
		"draconis_draconic_forge_fire.png"
	},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	groups = {cracky = 1, level = 2},
	sounds = draconis.sounds.stone,
	on_construct = function(pos)
		if get_forge_structure(pos) then
			local meta = minetest.get_meta(pos)
			update_fire_form(meta)
			local inv = meta:get_inventory()
			inv:set_size("input", 1)
			inv:set_size("crucible", 1)
			inv:set_size("output", 1)
		end
	end,

	can_dig = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("input") and inv:is_empty("crucible") and inv:is_empty("output")
	end,

	on_dig = function(pos, node, player)
		local structure = get_forge_structure(pos)
		if minetest.node_dig(pos, node, player) then
			if player:get_player_control().sneak
			and structure then
				local inv = player:get_inventory()
				local bricks = ItemStack(forge_shell[node.name] .. " " .. #shell_v)
				local blocks = ItemStack(forge_core[node.name] .. " " .. #core_v)
				if inv:room_for_item("main", bricks)
				and inv:room_for_item("main", blocks) then
					remove_forge_structure(pos)
					inv:add_item("main", bricks)
					inv:add_item("main", blocks)
				end
			end
			return true
		end
	end,

	allow_metadata_inventory_put = function(pos, listname, _, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end
		if listname == "input"
		and stack:get_name() == steel_ingot then
			return stack:get_count() or 0
		end
		if listname == "crucible"
		and stack:get_name():match("^draconis:dragonstone_crucible") then
			return stack:get_count() or 0
		end
		return 0
	end,

	allow_metadata_inventory_move = function() return 0 end,

	allow_metadata_inventory_take = function (pos, _, _, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end
		return stack:get_count()
	end,

	on_metadata_inventory_put = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local timer = minetest.get_node_timer(pos)

		if not inv:room_for_item("output", "draconis:draconic_steel_ingot_fire") then
			timer:stop()
			return
		end

		local crucible = inv:get_stack("crucible", 1)
		local melt_perc = meta:get_int("melt_perc") or 0

		if melt_perc < 1 then
			update_fire_form(meta)
		end

		if crucible:get_name() == "draconis:dragonstone_crucible_full" then
			timer:start(1)
		end
	end,

	on_metadata_inventory_take = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local input = inv:get_stack("input", 1)
		local crucible = inv:get_stack("crucible", 1)
		local timer = minetest.get_node_timer(pos)
		local melt_perc = meta:get_int("melt_perc") or 0
		local cool_perc = meta:get_int("cool_perc") or 0

		if not crucible:get_name():match("^draconis:dragonstone_crucible") then
			if melt_perc > 0 then
				meta:set_int("melt_perc", 0)
			end
			if cool_perc > 0 then
				meta:set_int("cool_perc", 0)
			end
			timer:stop()
			update_fire_form(meta)
			return
		end

		if input:get_name() ~= steel_ingot then
			if melt_perc > 0 then
				meta:set_int("last_perc", melt_perc)
				meta:set_int("melt_perc", 0)
			end
			if cool_perc < 1 then
				timer:stop()
			end
			update_fire_form(meta)
			return
		end

		if melt_perc < 1 then
			update_fire_form(meta)
		end
	end,

	on_timer = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local crucible = inv:get_stack("crucible", 1)
		local dragon_id = meta:get_string("dragon_id") ~= ""
		local melt_perc = meta:get_int("melt_perc") or 0
		local last_perc = melt_perc
		local cool_perc = meta:get_int("cool_perc") or 0


		-- If melting has reached end, melt input
		if melt_perc >= 100
		and dragon_id then
			melt_perc = 0
			melt_ingots(pos, meta:get_string("dragon_id"))
		end

		-- If cooling has reached end, cool crucible
		if cool_perc >= 100 then
			cool_perc = 0
			cool_crucible(pos, "draconis:draconic_steel_ingot_fire")
			crucible = inv:get_stack("crucible", 1)
		end

		-- If a Dragon is breathing into forge, increase melting progress
		if dragon_id
		and melt_perc < 100 then
			melt_perc = melt_perc + 5
			meta:set_string("dragon_id", "")
		-- If the Dragon has stopped breathing into forge, undo melting progress
		elseif melt_perc > 0 then
			melt_perc = melt_perc - 5
		end

		-- If the crucible is full, and no breath is applied, begin cooling
		if crucible:get_name() == "draconis:dragonstone_crucible_full"
		and inv:room_for_item("output", "draconis:draconic_steel_ingot_fire") then
			forge_particle(pos, "creatura_smoke_particle.png", {
				type = 'vertical_frames',
				aspect_w = 4,
				aspect_h = 4,
				length = 1,
			})
			cool_perc = cool_perc + 5
		end

		meta:set_int("last_perc", last_perc)
		meta:set_int("melt_perc", melt_perc)
		meta:set_int("cool_perc", cool_perc)

		update_fire_form(meta)
		if (melt_perc > 0
		and melt_perc <= last_perc)
		or crucible:get_name() == "draconis:dragonstone_crucible_full"
		or dragon_id then
			--meta:set_string("dragon_id", "")
			return true
		end
	end,

	on_breath = function(pos, id)
		if not get_forge_structure(pos) then return end
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local timer = minetest.get_node_timer(pos)
		local input = inv:get_stack("input", 1)
		local crucible = inv:get_stack("crucible", 1)

		if input:get_name() ~= steel_ingot
		or crucible:get_name() ~= "draconis:dragonstone_crucible" then
			update_fire_form(meta)
			forge_particle(pos, "creatura_smoke_particle.png", {
				type = 'vertical_frames',
				aspect_w = 4,
				aspect_h = 4,
				length = 1,
			})
			return
		end

		if not timer:is_started()
		and get_forge_structure(pos) then
			timer:start(1)
		end

		meta:set_string("dragon_id", id)

		forge_particle(pos, "fire_basic_flame.png")
	end
})

minetest.register_node("draconis:draconic_forge_ice", {
	description = "Ice Draconic Steel Forge",
	tiles = {
		"draconis_dragonstone_block_ice.png",
		"draconis_dragonstone_block_ice.png",
		"draconis_draconic_forge_ice.png"
	},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	groups = {cracky = 1, level = 2},
	sounds = draconis.sounds.stone,
	on_construct = function(pos)
		if get_forge_structure(pos) then
			local meta = minetest.get_meta(pos)
			update_ice_form(meta)
			local inv = meta:get_inventory()
			inv:set_size("crucible", 1)
			inv:set_size("output", 1)
		end
	end,

	can_dig = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("crucible") and inv:is_empty("output")
	end,

	on_dig = function(pos, node, player)
		local structure = get_forge_structure(pos)
		if minetest.node_dig(pos, node, player) then
			if player:get_player_control().sneak
			and structure then
				local inv = player:get_inventory()
				local bricks = ItemStack(forge_shell[node.name] .. " " .. #shell_v)
				local blocks = ItemStack(forge_core[node.name] .. " " .. #core_v)
				if inv:room_for_item("main", bricks)
				and inv:room_for_item("main", blocks) then
					remove_forge_structure(pos)
					inv:add_item("main", bricks)
					inv:add_item("main", blocks)
				end
			end
			return true
		end
	end,

	allow_metadata_inventory_put = function(pos, listname, _, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end
		if listname == "crucible" then
			return stack:get_count() or 0
		end
		return 0
	end,

	allow_metadata_inventory_move = function() return 0 end,

	allow_metadata_inventory_take = function (pos, _, _, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end
		return stack:get_count()
	end,

	on_metadata_inventory_put = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local timer = minetest.get_node_timer(pos)

		if not inv:room_for_item("output", "draconis:draconic_steel_ingot_ice") then
			timer:stop()
			return
		end

		local cool_perc = meta:get_int("cool_perc") or 0

		if cool_perc < 1 then
			update_ice_form(meta)
		end
	end,

	on_metadata_inventory_take = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local crucible = inv:get_stack("crucible", 1)
		local timer = minetest.get_node_timer(pos)
		local cool_perc = meta:get_int("cool_perc") or 0

		if not crucible:get_name():match("^draconis:dragonstone_crucible") then
			if cool_perc > 0 then
				meta:set_int("cool_perc", 0)
			end
			timer:stop()
			update_ice_form(meta)
			return
		end

		if cool_perc < 1 then
			update_ice_form(meta)
		end
	end,

	on_timer = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local crucible = inv:get_stack("crucible", 1)
		local cooling_init = meta:get_string("cooling_init") ~= ""
		local cool_perc = meta:get_int("cool_perc") or 0
		local last_perc = cool_perc

		-- If cooling has reached end, freeze input
		if cool_perc >= 100 then
			cool_perc = 0
			cool_crucible(pos, "draconis:draconic_steel_ingot_ice")
		end

		-- If a Dragon is breathing into forge, increase freezing progress
		if cooling_init then
			cool_perc = cool_perc + 5
			meta:set_string("cooling_init", "")
		-- If the Dragon has stopped breathing into forge, undo freezing progress
		elseif cool_perc > 0 then
			cool_perc = cool_perc - 5
		end

		meta:set_int("last_perc", last_perc)
		meta:set_int("cool_perc", cool_perc)

		update_ice_form(meta)
		if crucible:get_name() == "draconis:dragonstone_crucible_full" then
			meta:set_string("cooling_init", "")
			return true
		end
	end,

	on_breath = function(pos, id)
		if not get_forge_structure(pos) then return end
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local timer = minetest.get_node_timer(pos)
		local crucible = inv:get_stack("crucible", 1)

		if crucible:get_name() ~= "draconis:dragonstone_crucible_full" then
			update_ice_form(meta)
			forge_particle(pos, "creatura_smoke_particle.png", {
				type = 'vertical_frames',
				aspect_w = 4,
				aspect_h = 4,
				length = 1,
			})
			return
		end

		if not timer:is_started()
		and get_forge_structure(pos) then
			timer:start(1)
		end

		meta:set_string("cooling_init", "true")
		meta:set_string("dragon_id", id)

		forge_particle(pos, "draconis_ice_particle_1.png")
	end
})

------------
-- Stairs --
------------

local register_stairs = minetest.settings:get_bool("register_stairs")

if minetest.get_modpath("stairs")
and register_stairs then
	for i = 1, #stair_queue do
		local name = stair_queue[i]
		local def = minetest.registered_nodes[name]
		stairs.register_stair_and_slab(
			name:split(":")[2],
			name,
			def.groups,
			def.tiles,
			def.description .. " Stairs",
			def.description .. " Slab",
			def.sounds,
			false,
			def.description .. " Stairs Outer",
			def.description .. " Stairs Inner"
		)
	end
end

--------------
-- Aliasing --
--------------

for color in pairs(draconis.colors_ice) do
	minetest.register_alias_force("draconis:ice_scale_brick_" .. color, "draconis:stone_bricks_frozen")
	minetest.register_alias_force("draconis:egg_ice_" .. color, "draconis:egg_ice_" .. color)
end

for color in pairs(draconis.colors_fire) do
	minetest.register_alias_force("draconis:fire_scale_brick_" .. color, "draconis:stone_bricks_scorched")
	minetest.register_alias_force("draconis:egg_fire_" .. color, "draconis:egg_fire_" .. color)
end

minetest.register_alias_force("draconis:dracolily_ice", "")
minetest.register_alias_force("draconis:dracolily_fire", "")
minetest.register_alias_force("draconis:growth_essence_ice", "")
minetest.register_alias_force("draconis:growth_essence_fire", "")
minetest.register_alias_force("draconis:blood_ice_dragon", "")
minetest.register_alias_force("draconis:blood_fire_dragon", "")
minetest.register_alias_force("draconis:manuscript", "")

minetest.register_alias_force("draconis:frozen_soil", "draconis:soil_frozen")
minetest.register_alias_force("draconis:frozen_stone", "draconis:stone_frozen")
minetest.register_alias_force("draconis:frozen_tree", "draconis:log_frozen")
minetest.register_alias_force("draconis:frozen_wood", "draconis:wood_planks_frozen")
minetest.register_alias_force("draconis:frozen_stone_brick", "draconis:stone_bricks_frozen")
minetest.register_alias_force("draconis:frozen_stone_block", "draconis:stone_frozen")
minetest.register_alias_force("draconis:draconic_steel_forge_ice", "draconis:draconic_forge_ice")

minetest.register_alias_force("draconis:scorched_soil", "draconis:soil_scorched")
minetest.register_alias_force("draconis:scorched_stone", "draconis:stone_scorched")
minetest.register_alias_force("draconis:scorched_tree", "draconis:log_scorched")
minetest.register_alias_force("draconis:scorched_wood", "draconis:wood_planks_scorched")
minetest.register_alias_force("draconis:scorched_stone_brick", "draconis:stone_bricks_scorched")
minetest.register_alias_force("draconis:scorched_stone_block", "draconis:stone_scorched")
minetest.register_alias_force("draconis:draconic_steel_forge_fire", "draconis:draconic_forge_fire")
