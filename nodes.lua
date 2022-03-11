-----------
-- Nodes --
-----------

-- Sounds --

-- Get Craft Items --

local steel_ingot = "default:steel_ingot"

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_items) do
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
	table.insert(stair_queue, name)
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

register_node("draconis:dragonstone_bricks_ice", {
	description = "Ice Dragonstone Bricks",
	tiles = {"draconis_dragonstone_bricks_ice.png"},
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

for color, hex in pairs(draconis.colors_fire) do
	register_node("draconis:fire_scale_block_" .. color, {
		description = "Fire Dragon Scale Block \n" .. infotext(color, true),
		tiles = {"draconis_dragon_scale_block.png^[multiply:#" .. hex,},
		paramtype2 = "facedir",
		place_param2 = 0,
		is_ground_content = false,
		groups = {cracky = 1, level = 3, fire_dragon_scale_block = 1},
		sounds = draconis.sounds.stone
	})
end

for color, hex in pairs(draconis.colors_ice) do
	register_node("draconis:ice_scale_block_" .. color, {
		description = "Ice Dragon Scale Block \n" .. infotext(color, true),
		tiles = {"draconis_dragon_scale_block.png^[multiply:#" .. hex,},
		paramtype2 = "facedir",
		place_param2 = 0,
		is_ground_content = false,
		groups = {cracky = 1, level = 3, ice_dragon_scale_block = 1},
		sounds = draconis.sounds.stone
	})
end

--------------------------
-- Draconic Steel Forge --
--------------------------

local forge_materials = {
	["draconis:draconic_forge_fire"] = "draconis:dragonstone_bricks_fire",
	["draconis:draconic_forge_ice"] = "draconis:dragonstone_bricks_ice"
}

local forge_fuels = {
	["draconis:draconic_steel_ingot_fire"] = "draconis:log_scorched",
	["draconis:draconic_steel_ingot_ice"] = "draconis:log_frozen"
}

local function update_forge_form(progress, meta)
	local formspec
	if progress > 0 and progress <= 100 then
		local item_percent = math.floor(progress / 32 * 100)
		formspec = table.concat({
			"formspec_version[3]",
			"size[11,10]",
			"image[0,0;11,10;draconis_form_forge_bg.png]",
			"image[4.1,0.7;3,3;draconis_form_smelt_empty.png^[lowpart:"..
			(item_percent)..":draconis_form_smelt_full.png]",
			"list[current_player;main;0.65,5;8,4;]",
			"list[context;input;1.7,1.7;1,1;]",
			"list[context;fuel;4.95,3.75;1,1;]",
			"list[context;output;8.1,1.7;1,1;]",
			"listring[current_player;main]",
			"listring[context;input]",
			"listring[current_player;main]",
			"listring[context;fuel]",
			"listring[current_player;main]",
			"listring[context;output]",
			"listring[current_player;main]"
		}, "")
	else
		formspec = table.concat({
			"formspec_version[3]",
			"size[11,10]",
			"image[0,0;11,10;draconis_form_forge_bg.png]",
			"image[4.1,0.7;3,3;draconis_form_smelt_empty.png]",
			"list[current_player;main;0.65,5;8,4;]",
			"list[context;input;1.7,1.7;1,1;]",
			"list[context;fuel;4.95,3.75;1,1;]",
			"list[context;output;8.1,1.7;1,1;]",
			"listring[current_player;main]",
			"listring[context;input]",
			"listring[current_player;main]",
			"listring[context;fuel]",
			"listring[current_player;main]",
			"listring[context;output]",
			"listring[current_player;main]"
		}, "")
	end
	meta:set_string("formspec", formspec)
end

local function get_forge_structure(pos) -- Check if structure around forge is complete
	local node = minetest.get_node(pos)
	local name = node.name
	local material = forge_materials[name]
	local structure_v = {
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
		{x = 0, y = 1, z = 0},
		{x = 0, y = -1, z = 0}
	}
	for i = 1, 22 do
		local node = minetest.get_node(vector.add(pos, structure_v[i]))
		if node.name ~= material then
			return false
		end
	end
	return true
end

local function initiate_forge(pos)
	if get_forge_structure(pos) then
		local meta = minetest.get_meta(pos)
		update_forge_form(0, meta)
		local inv = meta:get_inventory()
		inv:set_size("input", 1)
		inv:set_size("fuel", 1)
		inv:set_size("output", 1)
	end
end

local function add_ingot(pos, ingot)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local input = inv:get_stack("input", 1)
	local fuel = inv:get_stack("fuel", 1)
	local output = inv:get_stack("output", 1)
	if input:get_name() ~= steel_ingot
	or fuel:get_name() ~= forge_fuels[ingot]
	or fuel:get_count() < 11
	or not inv:room_for_item("output", ingot) then
		minetest.get_node_timer(pos):stop()
		update_forge_form(0, meta)
	else
		input:take_item(1)
		inv:set_stack("input", 1, input)
		fuel:take_item(11)
		inv:set_stack("fuel", 1, fuel)
		inv:add_item("output", ingot)
	end
end

local function ice_forge_step(pos)
	local meta = minetest.get_meta(pos)
	local progress = meta:get_int("progress") or 0

	if progress >= 60 then
		add_ingot(pos, "draconis:draconic_steel_ingot_ice")
		progress = 0
	end

	local smelt = meta:get_int("smelt") or 0

	update_forge_form(progress, meta)

	meta:set_int("progress", progress)
end

local function fire_forge_step(pos)
	local meta = minetest.get_meta(pos)
	local progress = meta:get_int("progress") or 0

	if progress >= 60 then
		add_ingot(pos, "draconis:draconic_steel_ingot_fire")
		progress = 0
	end

	local smelt = meta:get_int("smelt") or 0

	update_forge_form(progress, meta)

	meta:set_int("progress", progress)
end

minetest.register_node("draconis:draconic_forge_fire", {
	description = "Fire Draconic Steel Forge",
	tiles = {"draconis_draconic_forge_fire_top.png", "draconis_draconic_forge_fire_top.png", "draconis_draconic_forge_fire.png"},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	groups = {cracky = 1, level = 2},
	sounds = draconis.sounds.stone,
	on_construct = initiate_forge,

	can_dig = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("input") and inv:is_empty("fuel") and inv:is_empty("output")
	end,

	allow_metadata_inventory_put = function(pos, listname, _, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end
		if listname == "fuel" then
			return stack:get_name() == "draconis:log_scorched" and stack:get_count() or 0
		end
		if listname == "input" then
			return stack:get_name() == steel_ingot and stack:get_count() or 0
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

	on_metadata_inventory_put = function(pos) -- Recalculate on_put
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local timer = minetest.get_node_timer(pos)

		if not inv:room_for_item("output", "draconis:draconic_steel_ingot_fire") then
			timer:stop()
			return
		end

		local progress = meta:get_int("progress") or 0

		if progress < 1 then
			update_forge_form(0, meta)
		end
	end,

	on_metadata_inventory_take = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local input = inv:get_stack("input", 1)
		local fuel = inv:get_stack("fuel", 1)
		local timer = minetest.get_node_timer(pos)
		local progress = meta:get_int("progress") or 0

		if input:get_name() ~= steel_ingot then
			timer:stop()
			update_forge_form(0, meta)
			if progress > 0 then
				meta:set_int("progress", 0)
			end
			return
		end

		if fuel:get_name() ~= "draconis:log_scorched" then
			timer:stop()
			update_forge_form(0, meta)
			if progress > 0 then
				meta:set_int("progress", 0)
			end
			return
		end

		if progress < 1 then
			update_forge_form(0, meta)
		end
	end,

	on_timer = fire_forge_step,

	on_breath = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local timer = minetest.get_node_timer(pos)
		local input = inv:get_stack("input", 1)
		local fuel = inv:get_stack("fuel", 1)
		local progress = meta:get_int("progress") or 0

		if input:get_name() ~= steel_ingot
		or fuel:get_name() ~= forge_fuels["draconis:draconic_steel_ingot_fire"] then
			update_forge_form(0, meta)
			return
		end

		if not timer:is_started()
		and get_forge_structure(pos) then
			timer:start(1)
			meta:set_int("progress", progress + 30)
		end

		local dirs = {
			{x = 1, y = 0, z = 0},
			{x = 0, y = 0, z = 1},
			{x = -1, y = 0, z = 0},
			{x = 0, y = 0, z = -1}
		}

		for i = 1, 4 do
			local dir = dirs[i]
			minetest.add_particlespawner({
				amount = 2,
				time = 0.25,
				minpos = vector.add(pos, dir),
				maxpos = vector.add(pos, dir),
				minvel = vector.multiply(dir, 2),
				maxvel = vector.multiply(dir, 3),
				minacc = {x = 0, y = 2, z = 0},
				maxacc = {x = 0, y = 6, z = 0},
				minexptime = 0.5,
				maxexptime = 1.5,
				minsize = 5,
				maxsize = 8,
				collisiondetection = false,
				vertical = false,
				glow = 16,
				texture = "fire_basic_flame.png"
			})
		end
	end
})

minetest.register_node("draconis:draconic_forge_ice", {
	description = "Ice Draconic Steel Forge",
	tiles = {"draconis_draconic_forge_ice_top.png", "draconis_draconic_forge_ice_top.png", "draconis_draconic_forge_ice.png"},
	paramtype2 = "facedir",
	place_param2 = 0,
	is_ground_content = false,
	groups = {cracky = 1, level = 2},
	sounds = draconis.sounds.stone,
	on_construct = initiate_forge,

	can_dig = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("input") and inv:is_empty("fuel") and inv:is_empty("output")
	end,

	allow_metadata_inventory_put = function(pos, listname, _, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end
		if listname == "fuel" then
			return stack:get_name() == "draconis:log_frozen" and stack:get_count() or 0
		end
		if listname == "input" then
			return stack:get_name() == steel_ingot and stack:get_count() or 0
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

	on_metadata_inventory_put = function(pos) -- Recalculate on_put
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local timer = minetest.get_node_timer(pos)

		if not inv:room_for_item("output", "draconis:draconic_steel_ingot_ice") then
			timer:stop()
			return
		end

		local progress = meta:get_int("progress") or 0

		if progress < 1 then
			update_forge_form(0, meta)
		end
	end,

	on_metadata_inventory_take = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local input = inv:get_stack("input", 1)
		local fuel = inv:get_stack("fuel", 1)
		local timer = minetest.get_node_timer(pos)
		local progress = meta:get_int("progress") or 0

		if input:get_name() ~= steel_ingot then
			timer:stop()
			update_forge_form(0, meta)
			if progress > 0 then
				meta:set_int("progress", 0)
			end
			return
		end

		if fuel:get_name() ~= "draconis:log_frozen" then
			timer:stop()
			update_forge_form(0, meta)
			if progress > 0 then
				meta:set_int("progress", 0)
			end
			return
		end

		if progress < 1 then
			update_forge_form(0, meta)
		end
	end,

	on_timer = ice_forge_step,

	on_breath = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local timer = minetest.get_node_timer(pos)
		local input = inv:get_stack("input", 1)
		local fuel = inv:get_stack("fuel", 1)
		local progress = meta:get_int("progress") or 0

		if input:get_name() ~= steel_ingot
		or fuel:get_name() ~= forge_fuels["draconis:draconic_steel_ingot_ice"] then
			update_forge_form(0, meta)
			return
		end

		if not timer:is_started()
		and get_forge_structure(pos) then
			timer:start(1)
			meta:set_int("progress", progress + 30)
		end

		local dirs = {
			{x = 1, y = 0, z = 0},
			{x = 0, y = 0, z = 1},
			{x = -1, y = 0, z = 0},
			{x = 0, y = 0, z = -1}
		}

		for i = 1, 4 do
			local dir = dirs[i]
			minetest.add_particlespawner({
				amount = 2,
				time = 0.25,
				minpos = vector.add(pos, dir),
				maxpos = vector.add(pos, dir),
				minvel = vector.multiply(dir, 2),
				maxvel = vector.multiply(dir, 3),
				minacc = {x = 0, y = 2, z = 0},
				maxacc = {x = 0, y = 6, z = 0},
				minexptime = 0.5,
				maxexptime = 1.5,
				minsize = 3,
				maxsize = 6,
				collisiondetection = false,
				vertical = false,
				glow = 16,
				texture = "draconis_ice_particle_" .. math.random(1, 3) .. ".png"
			})
		end
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