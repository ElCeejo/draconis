----------------
-- Craftitems --
----------------

-- Local Math --

local function round(n, dec)
	local mult = 10^(dec or 0)
	return math.floor(n * mult + 0.5) / mult
end

-- Get Craft Items --

local ice_block = "default:ice"

minetest.register_on_mods_loaded(function()
	if minetest.registered_items[ice_block] then return end
	for name in pairs(minetest.registered_items) do
		if name:match(":ice") and minetest.get_item_group(name, "slippery") > 0 then
			ice_block = name
			break
		end
	end
end)

-- Local Utilities --

local dragon_drops = {}

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

local function get_binder_desc(self)
	local info = "Dragonbinder\n"..minetest.colorize("#a9a9a9", correct_name(self.name))
	if self.nametag == "" then
		info = info.."\n" .. infotext("Nameless Dragon")
	else
		info = info.."\n" .. infotext(self.nametag or "Nameless Dragon")
	end
	if self.age then
		info = info.."\n" .. infotext(self.age)
	end
	if self.color then
		info = info.."\n" .. infotext(self.color, true)
	end
	return info
end

-----------
-- Drops --
-----------

minetest.register_craftitem("draconis:dragon_bone", {
	description = "Dragon Bone",
	inventory_image = "draconis_dragon_bone.png",
	groups = {bone = 1}
})

table.insert(dragon_drops, "draconis:dragon_bone")

for color, hex in pairs(draconis.colors_fire) do
	minetest.register_craftitem("draconis:scales_fire_dragon_" .. color, {
		description = "Fire Dragon Scales \n" .. infotext(color, true),
		inventory_image = "draconis_dragon_scales.png^[multiply:#" .. hex,
		groups = {dragon_scales = 1}
	})
	table.insert(dragon_drops, "draconis:scales_fire_dragon_" .. color)
end

for color, hex in pairs(draconis.colors_ice) do
	minetest.register_craftitem("draconis:scales_ice_dragon_" .. color, {
		description = "Ice Dragon Scales \n" .. infotext(color, true),
		inventory_image = "draconis_dragon_scales.png^[multiply:#" .. hex,
		groups = {dragon_scales = 1}
	})
	table.insert(dragon_drops, "draconis:scales_ice_dragon_" .. color)
end

---------------
-- Materials --
---------------

minetest.register_craftitem("draconis:draconic_steel_ingot_fire", {
	description = "Fire-Forged Draconic Steel Ingot",
	inventory_image = "draconis_draconic_steel_ingot_fire.png",
	stack_max = 1
})

minetest.register_craftitem("draconis:draconic_steel_ingot_ice", {
	description = "Ice-Forged Draconic Steel Ingot",
	inventory_image = "draconis_draconic_steel_ingot_ice.png",
	stack_max = 1
})

----------
-- Eggs --
----------

local function egg_rightclick(self, clicker, item)
	if not minetest.is_creative_enabled(clicker) then
		local inv = clicker:get_inventory()
		if inv:room_for_item("main", {name = item}) then
			clicker:get_inventory():add_item("main", item)
		else
			local pos = self.object:get_pos()
			if not pos then return end
			pos.y = pos.y + 0.5
			minetest.add_item(pos, {name = item})
		end
	end
	self.object:remove()
end

local dragon_eggs = {}

for color in pairs(draconis.colors_fire) do
	minetest.register_node("draconis:egg_fire_" .. color, {
		description = "Fire Dragon Egg \n" .. infotext(color, true),
		drawtype = "mesh",
		paramtype = "light",
		sunlight_propagates = true,
		mesh = "draconis_egg.obj",
		inventory_image = "draconis_fire_dragon_egg_" .. color .. ".png",
		tiles = {"draconis_fire_dragon_egg_mesh_" .. color .. ".png"},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.25, -0.5, -0.25, 0.25, 0.1, 0.25},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.25, -0.5, -0.25, 0.25, 0.1, 0.25},
			},
		},
		groups = {cracky = 3, level = 1},
		sounds = draconis.sounds.stone,
		on_construct = function(pos)
			local timer = minetest.get_node_timer(pos)
			timer:start(6)
		end,
		on_timer = function(pos)
			local nest_n = 0
			local nest_check = {
				vector.add(pos, {x = 0, y = -1, z = 0}),
				vector.add(pos, {x = 1, y = -1, z = 0}),
				vector.add(pos, {x = 1, y = -1, z = 1}),
				vector.add(pos, {x = 0, y = -1, z = 1}),
				vector.add(pos, {x = -1, y = -1, z = 1}),
				vector.add(pos, {x = -1, y = -1, z = 0}),
				vector.add(pos, {x = -1, y = -1, z = -1}),
				vector.add(pos, {x = 0, y = -1, z = -1}),
				vector.add(pos, {x = 1, y = -1, z = -1})
			}
			for i = 1, #nest_check do
				local node = minetest.get_node(nest_check[i])
				local name = node.name
				if name == "draconis:bone_pile_scorched" then
					nest_n = nest_n + 1
				end
				if nest_n > 8 then
					pos.y = pos.y - 0.49
					minetest.add_entity(pos, "draconis:egg_fire_dragon_" .. color)
					minetest.remove_node(pos)
					break
				end
			end
			return true
		end
	})

	table.insert(dragon_eggs, "draconis:egg_fire_" .. color)

	creatura.register_mob("draconis:egg_fire_dragon_" .. color, {
		-- Stats
		max_health = 10,
		armor_groups = {immortal = 1},
		despawn_after = false,
		-- Entity Physics
		stepheight = 1.1,
		max_fall = 0,
		-- Visuals
		mesh = "draconis_egg.b3d",
		hitbox = {
			width = 0.25,
			height = 0.6
		},
		visual_size = {x = 10, y = 10},
		textures = {"draconis_fire_dragon_egg_mesh_" .. color .. ".png"},
		animations = {
			idle = {range = {x = 0, y = 0}, speed = 1, frame_blend = 0.3, loop = false},
			hatching = {range = {x = 70, y = 130}, speed = 15, frame_blend = 0.3, loop = true},
		},
		-- Function
		activate_func = function(self)
			self.progress = self:recall("progress") or 0
			self.owner_name = self:recall("owner_name") or ""
			self.color = color
			if color == "black" then
				self.tex_no = 1
			elseif color == "bronze" then
				self.tex_no = 2
			elseif color == "green" then
				self.tex_no = 3
			elseif color == "red" then
				self.tex_no = 4
			elseif color == "gold" then
				self.tex_no = 5
			end
		end,
		step_func = function(self, dtime)
			local pos = self.object:get_pos()
			if not pos then return end
			if not self.owner_name
			or self:timer(10) then
				for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 6)) do
					if obj and obj:is_player() then
						minetest.after(1.5, function()
							self.owner_name = self:memorize("owner_name", obj:get_player_name())
						end)
					end
				end
			end
			local name = creatura.get_node_def(pos).name
			local progress = self.progress or 0
			if minetest.get_item_group(name, "fire") > 0 then
				progress = progress + dtime
				if not self.hatching then
					self.hatching = true
					self.object:set_animation({x = 1, y = 40}, 30, 0)
				end
				if progress >= 1000 then
					local object = minetest.add_entity(pos, "draconis:fire_dragon")
					local ent = object:get_luaentity()
					ent.age = ent:memorize("age", 1)
					ent.growth_scale = 0.03
					ent:memorize("growth_scale", 0.03)
					ent.growth_stage = ent:memorize("growth_stage", 1)
					ent.texture_no = self.tex_no
					ent:set_scale(0.03)
					if self.owner_name ~= "" then ent.owner = ent:memorize("owner", self.owner_name) end
					minetest.remove_node(pos)
					self.object:remove()
					return
				end
			else
				progress = 0
				self.hatching = false
				self.object:set_animation({x = 0, y = 0}, 0, 0)
			end
			self.progress = self:memorize("progress", progress)
		end,
		on_rightclick = function(self, clicker)
			egg_rightclick(self, clicker, "draconis:egg_fire_" .. color)
		end
	})
end

-- Ice Eggs --

for color in pairs(draconis.colors_ice) do
	minetest.register_node("draconis:egg_ice_" .. color, {
		description = "Ice Dragon Egg \n" .. infotext(color, true),
		drawtype = "mesh",
		paramtype = "light",
		sunlight_propagates = true,
		mesh = "draconis_egg.obj",
		inventory_image = "draconis_ice_dragon_egg_" .. color .. ".png",
		tiles = {"draconis_ice_dragon_egg_mesh_" .. color .. ".png"},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.25, -0.5, -0.25, 0.25, 0.1, 0.25},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.25, -0.5, -0.25, 0.25, 0.1, 0.25},
			},
		},
		groups = {cracky = 1, level = 3},
		sounds = draconis.sounds.stone,
		on_construct = function(pos)
			local timer = minetest.get_node_timer(pos)
			timer:start(6)
		end,
		on_timer = function(pos)
			local nest_n = 0
			local nest_check = {
				vector.add(pos, {x = 0, y = -1, z = 0}),
				vector.add(pos, {x = 1, y = -1, z = 0}),
				vector.add(pos, {x = 1, y = -1, z = 1}),
				vector.add(pos, {x = 0, y = -1, z = 1}),
				vector.add(pos, {x = -1, y = -1, z = 1}),
				vector.add(pos, {x = -1, y = -1, z = 0}),
				vector.add(pos, {x = -1, y = -1, z = -1}),
				vector.add(pos, {x = 0, y = -1, z = -1}),
				vector.add(pos, {x = 1, y = -1, z = -1})
			}
			for i = 1, #nest_check do
				local node = minetest.get_node(nest_check[i])
				local name = node.name
				if name == "draconis:bone_pile_frozen" then
					nest_n = nest_n + 1
				end
				if nest_n > 8 then
					pos.y = pos.y - 0.49
					minetest.add_entity(pos, "draconis:egg_ice_dragon_" .. color)
					minetest.remove_node(pos)
					break
				end
			end
			return true
		end
	})

	table.insert(dragon_eggs, "draconis:egg_ice_" .. color)

	creatura.register_mob("draconis:egg_ice_dragon_" .. color, {
		-- Stats
		max_health = 10,
		armor_groups = {immortal = 1},
		despawn_after = false,
		-- Entity Physics
		stepheight = 1.1,
		max_fall = 0,
		-- Visuals
		mesh = "draconis_egg.b3d",
		hitbox = {
			width = 0.25,
			height = 0.6
		},
		visual_size = {x = 10, y = 10},
		textures = {"draconis_ice_dragon_egg_mesh_" .. color .. ".png"},
		animations = {
			idle = {range = {x = 0, y = 0}, speed = 1, frame_blend = 0.3, loop = false},
			hatching = {range = {x = 70, y = 130}, speed = 15, frame_blend = 0.3, loop = true},
		},
		-- Function
		activate_func = function(self)
			self.progress = self:recall("progress") or 0
			self.owner_name = self:recall("owner_name") or ""
			if color == "light_blue" then
				self.tex_no = 1
			elseif color == "sapphire" then
				self.tex_no = 2
			elseif color == "slate" then
				self.tex_no = 3
			elseif color == "white" then
				self.tex_no = 4
			elseif color == "silver" then
				self.tex_no = 5
			end
		end,
		step_func = function(self, dtime)
			local pos = self.object:get_pos()
			if not pos then return end
			if not self.owner_name
			or self:timer(10) then
				for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 6)) do
					if obj and obj:is_player() then
						minetest.after(1.5, function()
							self.owner_name = self:memorize("owner_name", obj:get_player_name())
						end)
					end
				end
			end
			local name = creatura.get_node_def(pos).name
			local progress = self.progress or 0
			if minetest.get_item_group(name, "water") > 0
			or (progress > 0 and name == ice_block) then
				if minetest.get_item_group(name, "water") > 0 then
					minetest.set_node(pos, {name = ice_block})
				end
				progress = progress + dtime
				if not self.hatching then
					self.hatching = true
					self.object:set_animation({x = 1, y = 40}, 30, 0)
				end
				if progress >= 1000 then
					local object = minetest.add_entity(pos, "draconis:ice_dragon")
					local ent = object:get_luaentity()
					ent.age = ent:memorize("age", 1)
					ent.growth_scale = 0.03
					ent:memorize("growth_scale", 0.03)
					ent.growth_stage = ent:memorize("growth_stage", 1)
					ent.texture_no = self.tex_no
					ent:set_scale(0.03)
					if self.owner_name ~= "" then ent.owner = ent:memorize("owner", self.owner_name) end
					minetest.remove_node(pos)
					self.object:remove()
					return
				end
			else
				progress = 0
				self.hatching = false
				self.object:set_animation({x = 0, y = 0}, 0, 0)
			end
			self.progress = self:memorize("progress", progress)
		end,
		on_rightclick = function(self, clicker)
			egg_rightclick(self, clicker, "draconis:egg_ice_" .. color)
		end
	})
end

--------------------
-- Dragon Storage --
--------------------

-- API --

local function capture(player, ent)
	if not player:is_player()
	or not player:get_inventory() then
		return false
	end
	local stack = player:get_wielded_item()
	local meta = stack:get_meta()
	if not meta:get_string("staticdata")
	or meta:get_string("staticdata") == "" then
		if not ent.dragon_id then return end
		local stored_aging = meta:get_int("stored_aging") or 0
		draconis.set_color_string(ent)
		meta:set_string("mob", ent.name)
		meta:set_string("dragon_id", ent.dragon_id)
		meta:set_string("staticdata", ent:get_staticdata())
		meta:set_string("nametag", ent.nametag or "Nameless Dragon")
		meta:set_string("description", get_binder_desc(ent))
		if stored_aging > 0 then
			meta:set_int("timestamp", os.time())
		end
		player:set_wielded_item(stack)
		draconis.dragons[ent.dragon_id].stored_in_item = true
		ent.object:remove()
		draconis.force_storage_save = true
		return stack
	else
		minetest.chat_send_player(player:get_player_name(), "This Dragonbinder already contains a Dragon")
		return false
	end
end

local function get_dragon_by_id(dragon_id)
	for _, ent in pairs(minetest.luaentities) do
		if ent.dragon_id
		and ent.dragon_id == dragon_id then
			return ent
		end
	end
end

-- Items --

local function dragonbinder_use(itemstack, player, pointed_thing)
	local meta = itemstack:get_meta()
	local staticdata = meta:get_string("staticdata")
	if staticdata ~= "" then return end -- Skip func if Horn contains Dragon
	local mob = meta:get_string("mob")
	local id = meta:get_string("dragon_id")
	local stored_aging = meta:get_int("stored_aging") or 0
	if player:get_player_control().sneak then
		if stored_aging < 1 then
			meta:set_int("stored_aging", 1)
			minetest.chat_send_player(player:get_player_name(), "Your Dragon will age while stored.")
		else
			meta:set_int("stored_aging", 0)
			minetest.chat_send_player(player:get_player_name(), "Your Dragon will not age while stored.")
		end
		player:set_wielded_item(itemstack)
		return itemstack
	end
	if id ~= "" then -- If the horn has a linked Dragon
		if not draconis.dragons[id] then -- Clear data if linked Dragon is dead
			meta:set_string("mob", nil)
			meta:set_string("dragon_id", nil)
			meta:set_string("staticdata", nil)
			meta:set_string("description", "Dragonbinder")
			player:set_wielded_item(itemstack)
			return itemstack
		end
		local ent = pointed_thing.ref and pointed_thing.ref:get_luaentity()
		if ent
		and ent.name:match("^draconis:")
		and ent.dragon_id
		and ent.dragon_id == id
		and not ent.rider then -- Store Dragon if linked to Horn
			return capture(player, ent)
		end
		-- Teleport linked Dragon if not pointed
		local last_pos = draconis.dragons[id].last_pos
		ent = get_dragon_by_id(id)
		if draconis.dragons[id].stored_in_item then return itemstack end
		if not ent then
			table.insert(draconis.dragons[id].removal_queue, last_pos)
			minetest.add_entity(player:get_pos(), mob, draconis.dragons[id].staticdata)
		else
			ent.object:set_pos(player:get_pos())
		end
		minetest.chat_send_player(player:get_player_name(), "Teleporting Dragon")
	else -- Link Dragon to Horn
		local ent = pointed_thing.ref and pointed_thing.ref:get_luaentity()
		if ent
		and ent.name:match("^draconis:")
		and ent.dragon_id
		and ent.owner
		and ent.owner == player:get_player_name()
		and not ent.rider then
			return capture(player, ent)
		end
	end
	return itemstack
end

local function dragonbinder_place(itemstack, player, pointed_thing)
	local meta = itemstack:get_meta()
	local pos = pointed_thing.above
	local under = pointed_thing.type == "node" and pointed_thing.under
	local node_def = creatura.get_node_def(under)
	if node_def.on_rightclick then
		return node_def.on_rightclick(under, minetest.get_node(under), player, itemstack)
	end
	if pos
	and not minetest.is_protected(pos, player:get_player_name()) then
		pos.y = pos.y + 3
		local mob = meta:get_string("mob")
		local staticdata = meta:get_string("staticdata")
		local nametag = meta:get_string("nametag") or "Nameless Dragon"
		local id = meta:get_string("dragon_id")
		if not draconis.dragons[id] then -- Clear data if linked Dragon is dead
			meta:set_string("mob", nil)
			meta:set_string("dragon_id", nil)
			meta:set_string("staticdata", nil)
			meta:set_string("description", "Dragonbinder")
			player:set_wielded_item(itemstack)
			return itemstack
		end
		if staticdata == ""
		and id ~= ""
		and draconis.dragons[id]
		and draconis.dragons[id].stored_in_item then
			staticdata = draconis.dragons[id].staticdata
		end
		if staticdata ~= "" then
			local ent = minetest.add_entity(pos, mob, staticdata)
			if id ~= ""
			and draconis.dragons[id] then
				draconis.dragons[id].stored_in_item = false
			end
			draconis.force_storage_save = true
			local desc = "Dragonbinder\n" .. minetest.colorize("#a9a9a9", correct_name(mob))
			if nametag ~= "" then
				desc = desc .. "\n"..infotext(nametag)
			end
			meta:set_string("staticdata", nil)
			meta:set_string("description", desc)
			if meta:get_int("timestamp") > 0 then
				local time = meta:get_int("timestamp")
				local diff = os.time() - time
				ent:get_luaentity().time_in_horn = diff
				meta:set_int("timestamp", os.time())
			end
			return itemstack
		end
	end
end

minetest.register_craftitem("draconis:dragonbinder", {
	description = "Dragonbinder",
	inventory_image = "draconis_dragonbinder.png",
	stack_max = 1,
	on_place = dragonbinder_place,
	on_secondary_use = dragonbinder_use
})

minetest.register_alias("draconis:dragon_horn", "draconis:dragonbinder")
minetest.register_alias("draconis:dragon_flute", "draconis:dragonbinder")

--------------
-- Crucible --
--------------

minetest.register_craftitem("draconis:dragonstone_crucible", {
	description = "Dragonstone Crucible",
	inventory_image = "draconis_dragonstone_crucible.png",
	stack_max = 1
})

minetest.register_craftitem("draconis:dragonstone_crucible_full", {
	description = "Dragonstone Crucible (Full)",
	inventory_image = "draconis_dragonstone_crucible_full.png",
	stack_max = 1,
	groups = {not_in_creative_inventory = 1}
})

-----------
-- Tools --
-----------

-- Dragonhide --

for color in pairs(draconis.colors_fire) do
	-- Pick
	minetest.register_tool("draconis:pick_dragonhide_fire_" .. color, {
		description = "Dragonhide Pickaxe",
		inventory_image = "draconis_dragonhide_pick_" .. color .. ".png",
		wield_scale = {x = 1.5, y = 1.5, z = 1},
		tool_capabilities = {
			full_punch_interval = 0.6,
			max_drop_level = 3,
			groupcaps = {
				cracky = {
					times = {[1] = 1.2, [2] = 0.8, [3] = 0.6},
					uses = 40,
					maxlevel = 3
				}
			},
			damage_groups = {fleshy = 4}
		},
		sound = {breaks = "default_tool_breaks"},
		groups = {pickaxe = 1}
	})
	if color ~= "red" then
		local item = "draconis:pick_dragonhide_fire_" .. color
		minetest.registered_tools[item].groups = {pickaxe = 1, not_in_creative_inventory = 1}
	end
	-- Shovel
	minetest.register_tool("draconis:shovel_dragonhide_fire_" .. color, {
		description = "Dragonhide Shovel",
		inventory_image = "draconis_dragonhide_shovel_" .. color .. ".png",
		wield_scale = {x = 1.5, y = 1.5, z = 1},
		tool_capabilities = {
			full_punch_interval = 0.6,
			max_drop_level = 1,
			groupcaps = {
				crumbly = {
					times = {[1] = 0.8, [2] = 0.6, [3] = 0.4},
					uses = 40,
					maxlevel = 3
				}
			},
			damage_groups = {fleshy = 4}
		},
		sound = {breaks = "default_tool_breaks"},
		groups = {shovel = 1}
	})
	if color ~= "red" then
		local item = "draconis:shovel_dragonhide_fire_" .. color
		minetest.registered_tools[item].groups = {shovel = 1, not_in_creative_inventory = 1}
	end
	-- Axe
	minetest.register_tool("draconis:axe_dragonhide_fire_" .. color, {
		description = "Dragonhide Axe",
		inventory_image = "draconis_dragonhide_axe_" .. color .. ".png",
		wield_scale = {x = 1.5, y = 1.5, z = 1},
		tool_capabilities = {
			full_punch_interval = 0.6,
			max_drop_level = 1,
			groupcaps = {
				choppy = {
					times = {[1] = 1.2, [2] = 0.8, [3] = 0.6},
					uses = 40,
					maxlevel = 3
				}
			},
			damage_groups = {fleshy = 6}
		},
		sound = {breaks = "default_tool_breaks"},
		groups = {axe = 1}
	})
	if color ~= "red" then
		local item = "draconis:axe_dragonhide_fire_" .. color
		minetest.registered_tools[item].groups = {axe = 1, not_in_creative_inventory = 1}
	end
	-- Sword
	minetest.register_tool("draconis:sword_dragonhide_fire_" .. color, {
		description = "Dragonhide Sword",
		inventory_image = "draconis_dragonhide_sword_" .. color .. ".png",
		wield_scale = {x = 1.5, y = 1.5, z = 1},
		tool_capabilities = {
			full_punch_interval = 0.1,
			max_drop_level = 1,
			groupcaps = {
				snappy = {
					times = {[1] = 0.4, [2] = 0.2, [3] = 0.1},
					uses = 40,
					maxlevel = 3
				}
			},
			damage_groups = {fleshy = 12}
		},
		range = 6,
		sound = {breaks = "default_tool_breaks"},
		groups = {sword = 1}
	})
	if color ~= "red" then
		local item = "draconis:sword_dragonhide_fire_" .. color
		minetest.registered_tools[item].groups = {sword = 1, not_in_creative_inventory = 1}
	end
end

for color in pairs(draconis.colors_ice) do
	-- Pickaxe
	minetest.register_tool("draconis:pick_dragonhide_ice_" .. color, {
		description = "Dragonhide Pickaxe",
		inventory_image = "draconis_dragonhide_pick_" .. color .. ".png",
		wield_scale = {x = 1.5, y = 1.5, z = 1},
		tool_capabilities = {
			full_punch_interval = 0.6,
			max_drop_level = 3,
			groupcaps = {
				cracky = {
					times = {[1] = 1.2, [2] = 0.8, [3] = 0.6},
					uses = 40,
					maxlevel = 3
				}
			},
			damage_groups = {fleshy = 4}
		},
		sound = {breaks = "default_tool_breaks"},
		groups = {pickaxe = 1}
	})
	if color ~= "sapphire" then
		local item = "draconis:pick_dragonhide_ice_" .. color
		minetest.registered_tools[item].groups = {pickaxe = 1, not_in_creative_inventory = 1}
	end
	-- Shovel
	minetest.register_tool("draconis:shovel_dragonhide_ice_" .. color, {
		description = "Dragonhide Shovel",
		inventory_image = "draconis_dragonhide_shovel_" .. color .. ".png",
		wield_scale = {x = 1.5, y = 1.5, z = 1},
		tool_capabilities = {
			full_punch_interval = 0.6,
			max_drop_level = 1,
			groupcaps = {
				crumbly = {
					times = {[1] = 0.8, [2] = 0.6, [3] = 0.4},
					uses = 40,
					maxlevel = 3
				}
			},
			damage_groups = {fleshy = 4}
		},
		sound = {breaks = "default_tool_breaks"},
		groups = {shovel = 1}
	})
	if color ~= "sapphire" then
		local item = "draconis:shovel_dragonhide_ice_" .. color
		minetest.registered_tools[item].groups = {shovel = 1, not_in_creative_inventory = 1}
	end
	-- Axe
	minetest.register_tool("draconis:axe_dragonhide_ice_" .. color, {
		description = "Dragonhide Axe",
		inventory_image = "draconis_dragonhide_axe_" .. color .. ".png",
		wield_scale = {x = 1.5, y = 1.5, z = 1},
		tool_capabilities = {
			full_punch_interval = 0.6,
			max_drop_level = 1,
			groupcaps = {
				choppy = {
					times = {[1] = 1.2, [2] = 0.8, [3] = 0.6},
					uses = 40,
					maxlevel = 3
				}
			},
			damage_groups = {fleshy = 6}
		},
		sound = {breaks = "default_tool_breaks"},
		groups = {axe = 1}
	})
	if color ~= "sapphire" then
		local item = "draconis:axe_dragonhide_ice_" .. color
		minetest.registered_tools[item].groups = {axe = 1, not_in_creative_inventory = 1}
	end
	-- Sword
	minetest.register_tool("draconis:sword_dragonhide_ice_" .. color, {
		description = "Dragonhide Sword",
		inventory_image = "draconis_dragonhide_sword_" .. color .. ".png",
		wield_scale = {x = 1.5, y = 1.5, z = 1},
		tool_capabilities = {
			full_punch_interval = 0.1,
			max_drop_level = 1,
			groupcaps = {
				snappy = {
					times = {[1] = 0.4, [2] = 0.2, [3] = 0.1},
					uses = 40,
					maxlevel = 3
				}
			},
			damage_groups = {fleshy = 12}
		},
		range = 6,
		sound = {breaks = "default_tool_breaks"},
		groups = {sword = 1}
	})
	if color ~= "sapphire" then
		local item = "draconis:sword_dragonhide_ice_" .. color
		minetest.registered_tools[item].groups = {sword = 1, not_in_creative_inventory = 1}
	end
end

minetest.register_alias("draconis:pick_dragonbone", "draconis:pick_dragonhide_fire_black")
minetest.register_alias("draconis:shovel_dragonbone", "draconis:shovel_dragonhide_fire_black")
minetest.register_alias("draconis:axe_dragonbone", "draconis:axe_dragonhide_fire_black")
minetest.register_alias("draconis:sword_dragonbone", "draconis:sword_dragonhide_fire_black")

-- Draconic Steel --

local function draconic_step(itemstack, player, pointed_thing)
	local meta = itemstack:get_meta()
	local name = itemstack:get_name()
	local dragon_id = meta:get_string("dragon_id")
	local def = minetest.registered_tools[name]
	local toolcaps = table.copy(def.tool_capabilities)
	local current_caps = itemstack:get_tool_capabilities()
	-- Play Swing
	if name:find("sword") then
		minetest.sound_play(
			{name = "draconis_draconic_steel_swing", pitch = math.random(-3, 3) * 0.1},
			{pos = player:get_pos(), gain = 1.0, max_hear_distance = 12}
		)
		if pointed_thing.under then
			local node = minetest.get_node(pointed_thing.under)
			if minetest.get_item_group(node.name, "snappy") > 0 then
				minetest.dig_node(pointed_thing.under)
			end
		end
	end
	-- Destroy Tool if Dragon is not alive
	if dragon_id ~= ""
	and not draconis.dragons[dragon_id] then
		itemstack:set_wear(65536)
		minetest.sound_play(
			{name = "draconis_draconic_steel_shatter", pitch = math.random(-5, 5) * 0.1},
			{pos = player:get_pos(), gain = 1.0, max_hear_distance = 48}
		)
		return itemstack
	end
	-- Get distance to Dragon
	local dragon_data = draconis.dragons[dragon_id]
	local pos = player:get_pos()
	local dist2dragon
	if dragon_id ~= ""
	and not dragon_data.stored_in_item then
		local dragon_pos = dragon_data.last_pos
		dist2dragon = vector.distance(pos, dragon_pos)
	else
		dist2dragon = 200
	end
	-- Adjust Power Level based on distance
	local speed_offset = dist2dragon * 0.01
	local damage_offset = dist2dragon * 0.015
	local update = false
	if dist2dragon > 200 then
		speed_offset = 2
	elseif dist2dragon < 25 then
		speed_offset = 0
	end
	speed_offset = round(speed_offset, 0.1)
	for k, v in pairs(toolcaps.groupcaps) do
		for i = 1, 3 do
			local def_time = v.times[i]
			local current_time = round(current_caps.groupcaps[k].times[i], 0.1)
			local time_diff = math.abs((def_time + speed_offset) - current_time)
			if time_diff > 0.1 then
				update = true
			end
			v.times[i] = def_time + speed_offset
		end
	end
	if toolcaps.damage_groups then
		toolcaps.damage_groups.fleshy = toolcaps.damage_groups.fleshy - damage_offset
	end
	if pointed_thing.ref then
		pointed_thing.ref:punch(player, nil, toolcaps)
		if dist2dragon < 30 then
			if name:find("fire") then
				draconis.burn_object(pointed_thing.ref)
			else
				draconis.freeze_object(pointed_thing.ref)
			end
		end
	end
	if update then
		meta:set_tool_capabilities(toolcaps)
		return itemstack
	end
end

local elements = {"ice", "fire"}

for _, element in pairs(elements) do

minetest.register_tool("draconis:pick_"..element.."_draconic_steel", {
	description = correct_name(element).."-Forged Draconic Steel Pickaxe",
	inventory_image = "draconis_"..element.."_draconic_steel_pick.png",
	wield_scale = {x = 2, y = 2, z = 1},
	tool_capabilities = {
		full_punch_interval = 4,
		max_drop_level = 3,
		groupcaps = {
			cracky = {
				times={[1]=0.3, [2]=0.15, [3]=0.075},
				uses=0,
				maxlevel=3},
			crumbly = {
				times={[1]=0.5, [2]=0.25, [3]=0.2},
				uses=0,
				maxlevel=3
			},
		},
		damage_groups = {fleshy = 35}
	},
	range = 6,
	sound = {breaks = "default_tool_breaks"},
	groups = {pickaxe = 1},
	after_use = draconic_step
})

minetest.register_tool("draconis:shovel_"..element.."_draconic_steel", {
	description = correct_name(element).."-Forged Draconic Steel Shovel",
	inventory_image = "draconis_"..element.."_draconic_steel_shovel.png",
	wield_scale = {x = 2, y = 2, z = 1},
	tool_capabilities = {
		full_punch_interval = 5.5,
		max_drop_level = 1,
		groupcaps = {
			crumbly = {
				times = {[1] = 0.4, [2] = 0.2, [3] = 0.1},
				uses = 0,
				maxlevel = 3
			}
		},
		damage_groups = {fleshy = 30}
	},
	range = 6,
	sound = {breaks = "default_tool_breaks"},
	groups = {shovel = 1},
	after_use = draconic_step
})

minetest.register_tool("draconis:axe_"..element.."_draconic_steel", {
	description = correct_name(element).."-Forged Draconic Steel Axe",
	inventory_image = "draconis_"..element.."_draconic_steel_axe.png",
	wield_scale = {x = 2, y = 2, z = 1},
	tool_capabilities = {
		full_punch_interval = 3,
		max_drop_level = 1,
		groupcaps = {
			choppy = {
				times={[1]=0.3, [2]=0.15, [3]=0.075},
				uses = 0,
				maxlevel = 3
			}
		},
		damage_groups = {fleshy = 55}
	},
	range = 6,
	sound = {breaks = "default_tool_breaks"},
	groups = {axe = 1},
	after_use = draconic_step
})

minetest.register_tool("draconis:sword_"..element.."_draconic_steel", {
	description = correct_name(element).."-Forged Draconic Steel Sword",
	inventory_image = "draconis_"..element.."_draconic_steel_sword.png",
	wield_scale = {x = 2, y = 2, z = 1},
	tool_capabilities = {
		full_punch_interval = 1.2,
		max_drop_level = 1,
		groupcaps = {
			snappy = {
				times = {[1] = 0.05, [2] = 0.025, [3] = 0.01},
				uses = 0,
				maxlevel = 3
			}
		},
		damage_groups = {fleshy = 60}
	},
	range = 6,
	sound = {breaks = "default_tool_breaks"},
	groups = {sword = 1},
	on_use = draconic_step
})
end

--------------
-- Crafting --
--------------

minetest.register_alias_force("draconis:bestiary", "draconis:libri_draconis")
minetest.register_alias_force("draconis:lectern", "draconis:log_scorched") -- We do a little trolling

-- Get Craft Items --

local gold_block = "default:goldblock"
local steel_block = "default:steelblock"

minetest.register_on_mods_loaded(function()
	for name in pairs(minetest.registered_items) do
		if name:find("gold") and name:find("block") then
			gold_block = name
		end
		if (name:find("steel") or name:find("iron")) and name:find("block") then
			steel_block = name
		end
	end
end)

-------------
-- Recipes --
-------------

minetest.register_craft({
	output = "draconis:dragon_flute",
	recipe = {
		{"", "", "draconis:dragon_bone"},
		{"", "draconis:dragon_bone", "draconis:dragon_bone"},
		{steel_block, "draconis:dragon_bone", ""},
	}
})

minetest.register_craft({
	output = "draconis:dragonbinder",
	recipe = {
		{"", "", gold_block},
		{"", "draconis:dragon_bone", gold_block},
		{"draconis:dragon_bone", "draconis:dragon_bone", ""},
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
	output = "draconis:wood_planks_frozen",
	recipe = {
		{"draconis:log_frozen"}
	}
})

minetest.register_craft({
	output = "draconis:wood_planks_scorched",
	recipe = {
		{"draconis:log_scorched"}
	}
})

minetest.register_craft({
	output = "draconis:draconic_steel_forge_ice",
	recipe = {
		{"draconis:stone_frozen", "draconis:stone_frozen", "draconis:stone_frozen"},
		{"draconis:stone_frozen", "default:furnace", "draconis:stone_frozen"},
		{"draconis:stone_frozen", "draconis:stone_frozen", "draconis:stone_frozen"},
	}
})

minetest.register_craft({
	output = "draconis:draconic_steel_forge_fire",
	recipe = {
		{"draconis:stone_scorched", "draconis:stone_scorched", "draconis:stone_scorched"},
		{"draconis:stone_scorched", "default:furnace", "draconis:stone_scorched"},
		{"draconis:stone_scorched", "draconis:stone_scorched", "draconis:stone_scorched"},
	}
})

for color in pairs(draconis.colors_fire) do
	minetest.register_craft({
		output = "draconis:dragonhide_block_fire_" .. color,
		recipe = {
			{"draconis:dragon_bone", "draconis:scales_fire_dragon_" .. color, "draconis:dragon_bone"},
			{"draconis:dragon_bone", "draconis:scales_fire_dragon_" .. color, "draconis:dragon_bone"},
			{"draconis:dragon_bone", "draconis:scales_fire_dragon_" .. color, "draconis:dragon_bone"},
		}
	})
end

for color in pairs(draconis.colors_ice) do
	minetest.register_craft({
		output = "draconis:dragonhide_block_ice_" .. color,
		recipe = {
			{"draconis:dragon_bone", "draconis:scales_ice_dragon_" .. color, "draconis:dragon_bone"},
			{"draconis:dragon_bone", "draconis:scales_ice_dragon_" .. color, "draconis:dragon_bone"},
			{"draconis:dragon_bone", "draconis:scales_ice_dragon_" .. color, "draconis:dragon_bone"},
		}
	})
end

minetest.register_craft({
	output = "draconis:dragonstone_bricks_fire 4",
	recipe = {
		{"draconis:dragonstone_block_fire", "draconis:dragonstone_block_fire"},
		{"draconis:dragonstone_block_fire", "draconis:dragonstone_block_fire"},
	}
})

minetest.register_craft({
	output = "draconis:dragonstone_bricks_ice 4",
	recipe = {
		{"draconis:dragonstone_block_ice", "draconis:dragonstone_block_ice"},
		{"draconis:dragonstone_block_ice", "draconis:dragonstone_block_ice"},
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

minetest.register_craft({
	output = "draconis:dragonstone_crucible",
	recipe = {
		{"draconis:dragonstone_block_fire", "", "draconis:dragonstone_block_fire"},
		{"draconis:dragonstone_block_fire", "", "draconis:dragonstone_block_fire"},
		{"", "draconis:dragonstone_block_fire", ""},
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

for color in pairs(draconis.colors_fire) do
	craft_pick({
		handle = "draconis:dragon_bone",
		material = "draconis:scales_fire_dragon_" .. color,
		output = "draconis:pick_dragonhide_fire_" .. color
	})

	craft_shovel({
		handle = "draconis:dragon_bone",
		material = "draconis:scales_fire_dragon_" .. color,
		output = "draconis:shovel_dragonhide_fire_" .. color
	})

	craft_axe({
		handle = "draconis:dragon_bone",
		material = "draconis:scales_fire_dragon_" .. color,
		output = "draconis:axe_dragonhide_fire_" .. color
	})

	craft_sword({
		handle = "draconis:dragon_bone",
		material = "draconis:scales_fire_dragon_" .. color,
		output = "draconis:sword_dragonhide_fire_" .. color
	})
end

for color in pairs(draconis.colors_ice) do
	craft_pick({
		handle = "draconis:dragon_bone",
		material = "draconis:scales_ice_dragon_" .. color,
		output = "draconis:pick_dragonhide_ice_" .. color
	})

	craft_shovel({
		handle = "draconis:dragon_bone",
		material = "draconis:scales_ice_dragon_" .. color,
		output = "draconis:shovel_dragonhide_ice_" .. color
	})

	craft_axe({
		handle = "draconis:dragon_bone",
		material = "draconis:scales_ice_dragon_" .. color,
		output = "draconis:axe_dragonhide_ice_" .. color
	})

	craft_sword({
		handle = "draconis:dragon_bone",
		material = "draconis:scales_ice_dragon_" .. color,
		output = "draconis:sword_dragonhide_ice_" .. color
	})
end

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

----------------------------------
-- Draconic Steel Tool On-Craft --
----------------------------------

minetest.register_on_craft(function(itemstack, player, old_craft_grid)
	if itemstack:get_name():find("draconic_steel") then
		local last_id
		local itemlist = {}
		local shatter = false
		for _, stack in pairs(old_craft_grid) do
			if stack:get_meta():get_string("dragon_id") ~= "" then
				local current_id = stack:get_meta():get_string("dragon_id")
				if not last_id then
					last_id = current_id
				end
				if last_id ~= current_id then
					shatter = true
				else
					last_id = current_id
				end
			end
			table.insert(itemlist, stack)
		end
		if shatter then
			itemstack = ItemStack()
			local pos = player:get_pos()
			pos.y = pos.y + 1.6
			for n = 1, #itemlist do
				minetest.add_item(pos, itemlist[n])
			end
			return itemstack
		else
			local meta = itemstack:get_meta()
			local name = itemstack:get_name()
			local desc = minetest.registered_items[name].description
			meta:set_string("dragon_id", last_id)
			local dragon_name = "Unnamed Dragon"
			if draconis.dragons[last_id]
			and draconis.dragons[last_id].name then
				dragon_name = draconis.dragons[last_id].name
			end
			meta:set_string("description", desc .. "\n(Forged by " .. dragon_name .. ")")
		end
		return itemstack
	end
end)