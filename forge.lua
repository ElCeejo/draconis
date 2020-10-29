-------------
--- Forges --
-------------
-- Ver 1.0 --

local function is_forge_complete(pos, seg1_block, seg2_block)
	local complete = nil
	local seg1 = {
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
		{x = 0, y = -1, z = 1}
	}
	local seg2 = {
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
	for i = 1, 12 do
		local node = minetest.get_node(vector.add(pos, seg1[i]))
		if not node.name:match("^"..seg1_block) then
			return false
		end
		complete = true
	end
	for i = 1, 10 do
		local node = minetest.get_node(vector.add(pos, seg2[i]))
		if node.name ~= seg2_block then
			return false
		end
		complete = true
	end
	if complete then
		return true
	end
	return false
end

--------------
-- Formspec --
--------------

local function forge_formspec(progress, meta)
	local formspec
	if progress > 0 and progress <= 100 then
		local item_percent = math.floor(progress / 60 * 100)
		formspec = table.concat({
			"formspec_version[3]",
			"size[12.75,10.5]",
			"image[5.75,1.5;1,2;draconis_forge_formspec_fire_bg.png^[lowpart:"..
			(item_percent)..":draconis_forge_formspec_fire_fg.png]",
			"list[current_player;main;1.5,5;8,4;]",
			"list[context;input;5.75,0.5;1,1;]",
			"list[context;fuel;5.75,3.75;1,1;]",
			"list[context;output;7.75,1.5;1,1;]",
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
			"size[12.75,10.5]",
			"image[5.75,1.5;1,2;draconis_forge_formspec_fire_bg.png]",
			"list[current_player;main;1.5,5;8,4;]",
			"list[context;input;5.75,0.5;1,1;]",
			"list[context;fuel;5.75,3.75;1,1;]",
			"list[context;output;7.75,1.5;1,1;]",
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

---------------
-- Functions --
---------------

function draconis.register_forge(name, def)

	local function smelt(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local input = inv:get_stack("input", 1)
		local fuel = inv:get_stack("fuel", 1)

		if input:get_name() ~= "default:steel_ingot"
		or not inv:room_for_item("output", def.output)  then
			minetest.get_node_timer(pos):stop()
			forge_formspec(0, meta)
		elseif fuel:get_name() ~= def.fuel
		or not inv:room_for_item("output", def.output)  then
			minetest.get_node_timer(pos):stop()
			forge_formspec(0, meta)
		else
			input:take_item(1)
			inv:set_stack("input", 1, input)
			fuel:take_item(1)
			inv:set_stack("fuel", 1, fuel)
			inv:add_item("output", def.output)
			return input, fuel
		end
	end

	minetest.register_node(name, {
		description = def.description,
		tiles = def.tiles,
		paramtype2 = "facedir",
		groups = {cracky = 2},
		legacy_facedir_simple = true,
		is_ground_content = false,
		sounds = default.node_sound_stone_defaults(),
		drawtype = "node",

		on_construct = function(pos)
			if is_forge_complete(pos, def.seg1_block, def.seg2_block) then
				local meta = minetest.get_meta(pos)
				forge_formspec(0, meta)
				local inv = meta:get_inventory()
				inv:set_size("input", 1)
				inv:set_size("fuel", 1)
				inv:set_size("output", 1)
			end
		end,

		can_dig = function(pos)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:is_empty("input") and inv:is_empty("fuel") and inv:is_empty("output")
		end,

		on_fired = function(pos)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			local timer = minetest.get_node_timer(pos)
			local input = inv:get_stack("input", 1)
			local fuel = inv:get_stack("fuel", 1)
			local smelting_time = meta:get_int("smelting_time") or 0
			if input:get_name() ~= "default:steel_ingot" then
				forge_formspec(0, meta)
				return
			end

			if fuel:get_name() ~= def.fuel then
				forge_formspec(0, meta)
				return
			end
			if not timer:is_started()
			and is_forge_complete(pos, def.seg1_block, def.seg2_block) then
				timer:start(1)
				meta:set_int("smelting_time", smelting_time + 1)
				return
			end
		end,

		allow_metadata_inventory_put = function(pos, listname, _, stack, player)
			if minetest.is_protected(pos, player:get_player_name()) then
				return 0
			end
			if listname == "input" then
				return stack:get_name() == "default:steel_ingot" and stack:get_count() or 0
			end
			if listname == "fuel" then
				return stack:get_name() == def.fuel and stack:get_count() or 0
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

			if not inv:room_for_item("output", def.output) then
				timer:stop()
				return
			end

			local smelting_time = meta:get_int("smelting_time") or 0

			if smelting_time < 1 then
				forge_formspec(0, meta)
			end
		end,

		on_metadata_inventory_take = function(pos)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			local input = inv:get_stack("input", 1)
			local fuel = inv:get_stack("fuel", 1)
			local timer = minetest.get_node_timer(pos)
			local smelting_time = meta:get_int("smelting_time") or 0

			if input:get_name() ~= "default:steel_ingot" then
				timer:stop()
				forge_formspec(0, meta)
				if smelting_time > 0 then
					meta:set_int("smelting_time", 0)
				end
				return
			end

			if fuel:get_name() ~= def.fuel then
				timer:stop()
				forge_formspec(0, meta)
				if smelting_time > 0 then
					meta:set_int("smelting_time", 0)
				end
				return
			end

			if smelting_time < 1 then
				forge_formspec(0, meta)
			end
		end,

		on_timer = function(pos)
			local meta = minetest.get_meta(pos)
			local smelting_time = meta:get_int("smelting_time") or 0

			if smelting_time >= 60 then
				smelt(pos)
				smelting_time = 0
			end

			forge_formspec(smelting_time, meta)

			meta:set_int("smelting_time", smelting_time)
		end,

		on_blast = function(pos)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			local input = inv:get_stack("input", 1)
			local fuel = inv:get_stack("fuel", 1)
			local output = inv:get_stack("output", 1)
			if input:get_count() > 0 then
				minetest.add_item(pos, input:get_name().." "..input:get_count())
			end
			if fuel:get_count() > 0 then
				minetest.add_item(pos, fuel:get_name().." "..fuel:get_count())
			end
			if output:get_count() > 0 then
				minetest.add_item(pos, output:get_name().." "..output:get_count())
			end
			minetest.add_item(pos, name)
			minetest.remove_node(pos)
		end,
	})
end

draconis.register_forge("draconis:draconic_steel_forge_fire", {
	description = "Draconic Steel Forge",
	tiles = {
		"draconis_scorched_stone_brick.png",
		"draconis_scorched_stone_brick.png",
		"draconis_draconic_steel_forge_fire.png",
		"draconis_draconic_steel_forge_fire.png",
		"draconis_draconic_steel_forge_fire.png",
		"draconis_draconic_steel_forge_fire.png"
	},
	fuel = "draconis:blood_fire_dragon",
	output = "draconis:draconic_steel_ingot_fire",
	seg1_block = "draconis:fire_scale_brick",
	seg2_block = "draconis:scorched_stone_brick"
})

draconis.register_forge("draconis:draconic_steel_forge_ice", {
	description = "Draconic Steel Forge",
	tiles = {
		"draconis_frozen_stone_brick.png",
		"draconis_frozen_stone_brick.png",
		"draconis_draconic_steel_forge_ice.png",
		"draconis_draconic_steel_forge_ice.png",
		"draconis_draconic_steel_forge_ice.png",
		"draconis_draconic_steel_forge_ice.png"
	},
	fuel = "draconis:blood_ice_dragon",
	output = "draconis:draconic_steel_ingot_ice",
	seg1_block = "draconis:ice_scale_brick",
	seg2_block = "draconis:frozen_stone_brick"
})