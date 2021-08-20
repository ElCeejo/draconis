-----------------
-- Craft Items --
-----------------
---- Ver 1.0 ----

local SF = draconis.string_format

local function infotext(str, format)
	if format then
		return minetest.colorize("#a9a9a9", SF(str))
	end
	return minetest.colorize("#a9a9a9", str)
end

-----------------
-- Basic Items --
-----------------

minetest.register_craftitem("draconis:dragon_bone", {
	description = "Dragon Bone",
	inventory_image = "draconis_dragon_bone.png",
	groups = {bone = 1}
})

minetest.register_craftitem("draconis:draconic_steel_ingot_fire", {
	description = "Fire-Forged Draconic Steel Ingot",
	inventory_image = "draconis_fire_draconic_steel_ingot.png",
	stack_max = 8,
	groups = {draconic_steel_ingot = 1}
})

minetest.register_craftitem("draconis:draconic_steel_ingot_ice", {
	description = "Ice-Forged Draconic Steel Ingot",
	inventory_image = "draconis_ice_draconic_steel_ingot.png",
	stack_max = 8,
	groups = {draconic_steel_ingot = 1}
})

local fire_colors = draconis.fire_colors

local ice_colors = draconis.ice_colors

for _, fire_color in pairs(fire_colors) do
	minetest.register_craftitem("draconis:scales_fire_dragon_"..fire_color, {
		description = "Fire Dragon Scales \n"..infotext(fire_color, true),
		inventory_image = "draconis_fire_scales_".. fire_color ..".png",
		groups = {dragon_scales = 1}
	})
end

for _, ice_color in pairs(ice_colors) do
	minetest.register_craftitem("draconis:scales_ice_dragon_"..ice_color, {
		description = "Ice Dragon Scales \n"..infotext(ice_color, true),
		inventory_image = "draconis_ice_scales_".. ice_color ..".png",
		groups = {dragon_scales = 1}
	})
end

------------------
-- Dragon Flute --
------------------

local function get_info_flute(self)
	local info = "Dragon Flute\n"..minetest.colorize("#a9a9a9", mob_core.get_name_proper(self.name))
	if self.nametag ~= "" then
		info = info.."\n"..infotext(self.nametag)
	end
	if self.age then
		info = info.."\n"..infotext(self.age)
	end
	if self.color then
		info = info.."\n"..infotext(self.color, true)
	end
	return info
end


local function get_info_horn(self)
	local info = "Dragon Horn\n"..minetest.colorize("#a9a9a9", mob_core.get_name_proper(self.name))
	if self.nametag ~= "" then
		info = info.."\n"..infotext(self.nametag)
	end
	if self.age then
		info = info.."\n"..infotext(self.age)
	end
	if self.color then
		info = info.."\n"..infotext(self.color, true)
	end
	return info
end

local function get_info_gem(self)
	local info = "Dragon Summoning Gem\n"..minetest.colorize("#a9a9a9", mob_core.get_name_proper(self.name))
	if self.nametag ~= "" then
		info = info.."\n"..infotext(self.nametag)
	end
	if self.color then
		info = info.."\n"..infotext(self.color, true)
	end
	return info
end

local function get_line(a, b)
    local steps = vector.distance(a, b)
    local index = {}
    for i = 0, steps do
        local c

        if steps > 0 then
            c = {
                x = a.x + (b.x - a.x) * (i / steps),
                y = a.y + (b.y - a.y) * (i / steps),
                z = a.z + (b.z - a.z) * (i / steps)
            }
        else
            c = a
        end

        table.insert(index, c)
    end
    return index
end

local function pointed_dragon(player, range)
	local dir, pos = player:get_look_dir(), player:get_pos()
	pos.y = pos.y + player:get_properties().eye_height or 1.625
	pos = vector.add(pos, vector.multiply(dir, 1))
	local dist = 1
	local dest = vector.add(pos, vector.multiply(dir, range))
	local line = get_line(pos, dest)
	local ent
	while dist < #line and not ent do
		local objects = minetest.get_objects_inside_radius(line[dist], 8)
		if objects then
			for _, object in ipairs(objects) do
				if object:get_luaentity() then
					local luaent = object:get_luaentity()
					if (luaent.name == "draconis:ice_dragon"
					or luaent.name == "draconis:fire_dragon")
					and luaent.tamed
					and luaent.owner == player:get_player_name()
					and not luaent.driver then
						ent = luaent
						break
					end
				end
			end
		end
		dist = dist + 1
	end
	if ent then
		return ent
	end
end

local function capture(clicker, ent, type)
	if not clicker:is_player()
	or not clicker:get_inventory() then
		return false
	end
	local stack = clicker:get_wielded_item()
	local meta = stack:get_meta()
	if not meta:get_string("mob")
	or meta:get_string("mob") == "" then
		draconis.set_color_string(ent)
		meta:set_string("mob", ent.name)
		meta:set_string("staticdata", ent:get_staticdata())
		local info
		if type == "horn" then
			meta:set_int("timestamp", os.time())
			info = get_info_horn(ent)
		else
			info = get_info_flute(ent)
		end
		meta:set_string("description", info)
		clicker:set_wielded_item(stack)
		ent.object:remove()
		return stack
	else
		minetest.chat_send_player(clicker, "This Dragon ".. SF(type)  " already contains a Dragon")
		return false
	end
end

minetest.register_craftitem("draconis:dragon_flute", {
	description = "Dragon Flute",
	inventory_image = "draconis_dragon_flute.png",
	stack_max = 1,
	on_place = function(itemstack, placer, pointed_thing)
		local meta = itemstack:get_meta()
		local pos = pointed_thing.above
		local under = minetest.get_node(pointed_thing.under)
		local node = minetest.registered_nodes[under.name]
		if node and node.on_rightclick then
			return node.on_rightclick(pointed_thing.under, under, placer, itemstack)
		end
		if pos
		and not minetest.is_protected(pos, placer:get_player_name()) then
			pos.y = pos.y + 3
			local mob = meta:get_string("mob")
			local staticdata = meta:get_string("staticdata")
			if mob ~= "" then
				minetest.add_entity(pos, mob, staticdata)
				meta:set_string("mob", nil)
				meta:set_string("staticdata", nil)
				meta:set_string("description", "Dragon Flute")
			end
		end
		return itemstack
	end,
	on_secondary_use = function(itemstack, player)
		local meta = itemstack:get_meta()
		local mob = meta:get_string("mob")
		if mob ~= "" then return end
		local ent = pointed_dragon(player, 40)
		if not ent then
			return
		end
		if vector.distance(player:get_pos(), ent.object:get_pos()) < 14 then
			return capture(player, ent, "flute")
		else
			mobkit.clear_queue_high(ent)
			if not ent.isonground then
				ent.order = mobkit.remember(ent, "order", "follow")
				draconis.hq_follow(ent, 22, player)
			end
		end
	end
})

minetest.register_craftitem("draconis:dragon_horn", {
	description = "Dragon Horn",
	inventory_image = "draconis_dragon_horn.png",
	stack_max = 1,
	on_place = function(itemstack, placer, pointed_thing)
		local meta = itemstack:get_meta()
		local pos = pointed_thing.above
		local under = minetest.get_node(pointed_thing.under)
		local node = minetest.registered_nodes[under.name]
		if node and node.on_rightclick then
			return node.on_rightclick(pointed_thing.under, under, placer, itemstack)
		end
		if pos
		and not minetest.is_protected(pos, placer:get_player_name()) then
			pos.y = pos.y + 3
			local mob = meta:get_string("mob")
			local staticdata = meta:get_string("staticdata")
			if mob ~= "" then
				local ent = minetest.add_entity(pos, mob, staticdata)
				meta:set_string("mob", nil)
				meta:set_string("staticdata", nil)
				meta:set_string("description", "Dragon Horn")
				if meta:get_int("timestamp") then
					local time = meta:get_int("timestamp")
					local diff = os.time() - time
					ent:get_luaentity().time_in_horn = diff
					meta:set_int("timestamp", os.time())
				end
			end
		end
		return itemstack
	end,
	on_secondary_use = function(itemstack, player)
		local meta = itemstack:get_meta()
		local mob = meta:get_string("mob")
		if mob ~= "" then return end
		local ent = pointed_dragon(player, 80)
		if not ent
		or not ent.dragon_id then
			return
		end
		if not meta:get_string("id")
		or meta:get_string("id") == "" then
			meta:set_string("id", ent.dragon_id)
			return itemstack
		elseif meta:get_string("id") ~= ""
		and meta:get_string("id") ~= ent.dragon_id then
			return
		end
		if vector.distance(player:get_pos(), ent.object:get_pos()) < 14 then
			return capture(player, ent, "horn")
		else
			mobkit.clear_queue_high(ent)
			if not ent.isonground then
				ent.order = mobkit.remember(ent, "order", "follow")
				draconis.hq_follow(ent, 22, player)
			end
		end
	end
})

-------------------
-- Summoning Gem --
-------------------

minetest.register_craftitem("draconis:summoning_gem", {
	description = "Dragon Summoning Gem",
	inventory_image = "draconis_summoning_gem.png",
	stack_max = 1,
	on_secondary_use = function(itemstack, player, pointed_thing)
		local meta = itemstack:get_meta()
		local name = player:get_player_name()
		if pointed_thing.type == "object"
		and meta:get_string("id") == "" then
			local ent = pointed_thing.ref:get_luaentity()
			if ent.name
			and (ent.name == "draconis:fire_dragon"
			or ent.name == "draconis:ice_dragon") then
				if not mobkit.is_alive(ent) then return end
				local owner = ent.owner
				local dragon_id = ent.dragon_id
				if owner
				and owner == name
				and dragon_id then
					meta:set_string("id", dragon_id)
					local info = get_info_gem(ent)
					meta:set_string("description", info)
					return itemstack
				end
			end
		elseif meta:get_string("id") ~= "" then
			local id = meta:get_string("id")
			local last_pos = draconis.dragons[id].last_pos
			minetest.chat_send_player(name, "Attempting to teleport Dragon, wait 4 seconds before attempting again.")
			minetest.after(3.5, function()
				local can_summon, object = draconis.load_dragon(id)
				if can_summon then
					minetest.chat_send_player(name, "Dragon teleported from: "..minetest.pos_to_string(last_pos))
					local ppos = player:get_pos()
					ppos.y = ppos.y + 3
					object:set_pos(player:get_pos())
					return
				end
				minetest.chat_send_player(name, "Could not be teleported. Last seen at: "
				..minetest.pos_to_string(last_pos)..
				"\n Try again a couple more times.")
			end)
		end
	end,
	on_place = function(itemstack, player, pointed_thing)
		local meta = itemstack:get_meta()
		local name = player:get_player_name()
		if pointed_thing.type == "object"
		and not meta:get_string("id") then
			local ent = pointed_thing.ref:get_luaentity()
			if ent.name
			and (ent.name == "draconis:fire_dragon"
			or ent.name == "draconis:ice_dragon") then
				if not mobkit.is_alive(ent) then return end
				local owner = ent.owner
				local dragon_id = ent.dragon_id
				if owner
				and owner == name
				and dragon_id then
					meta:set_string("id", dragon_id)
					local info = get_info_gem(ent)
					meta:set_string("description", info)
				end
			end
		elseif meta:get_string("id") ~= "" then
			local id = meta:get_string("id")
			local last_pos = draconis.dragons[id].last_pos
			minetest.chat_send_player(name, "Attempting to teleport Dragon, wait 4 seconds before attempting again.")
			local can_summon, object = draconis.load_dragon(id)
			minetest.after(3.5, function()
				if can_summon then
					minetest.chat_send_player(name, "Dragon teleported from: "..minetest.pos_to_string(last_pos))
					local ppos = player:get_pos()
					ppos.y = ppos.y + 3
					object:set_pos(player:get_pos())
					return
				end
				minetest.chat_send_player(name, "Could not be teleported. Last seen at: "
				..minetest.pos_to_string(last_pos)..
				"\n Try again a couple more times.")
			end)
		end
	end
})


--------------
-- Bestiary --
--------------


local function bestiary_formspec(player, meta)
    local basic_form = table.concat({
        "formspec_version[3]",
        "size[16,10]",
        "background[-0.7,-0.5;17.5,11.5;draconis_bestiary_bg.png]"
	}, "")
	local pages = minetest.deserialize(meta:get_string("pages"))
	if pages[1] then
		basic_form = basic_form.."button[1.75,1.5;4,1;"..pages[1].."]"
	end
	if pages[2] then
		basic_form = basic_form.."button[1.75,3.5;4,1;"..pages[2].."]"
	end
	if pages[3] then
		basic_form = basic_form.."button[1.75,5.5;4,1;"..pages[3].."]"
	end
	if pages[4] then
		basic_form = basic_form.."button[1.75,7.5;4,1;"..pages[4].."]"
	end
	if pages[5] then
		basic_form = basic_form.."button[10.25,1.5;4,1;"..pages[5].."]"
	end
	if pages[6] then
		basic_form = basic_form.."button[10.25,3.5;4,1;"..pages[6].."]"
	end
    minetest.show_formspec(player:get_player_name(), "draconis:bestiary_main", basic_form)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "draconis:bestiary_main" then
		if fields.pg_ice_dragon then
			local text = {
				"The Ice Dragon is large flying reptile that is said to be found in \n",
				"cold mountainous areas. Similar to their fire breathing \n",
				"relative, they are rumored to make nests with various sources \n",
				"reporting conflicting information on the appearance of these \n",
				"structures. They are spotted far less requently than the Fire \n",
				"Dragon and are found almost exclusively in frigid mountains. \n",
				"Their attack patterns are similar to the Fire Dragon, but their \n",
				"icy breath is said to freeze living beings solid for period of \n",
				"time, giving them no chance of escape. Their biology is \n",
				"confusing, given that most creatures produce heat and require \n",
				"it to live. Beyond that, while fire breath is easily explained \n",
				"through science, the Ice Dragons ability to produce such icy \n",
				"breath should be impossible considering it's diet of \n",
				"exclusively meat."
			}
			local tex_light_blue = "draconis_ice_dragon_light_blue.png^draconis_ice_dragon_head_detail.png^draconis_ice_eyes_blue.png"
			local tex_sapphire = "draconis_ice_dragon_sapphire.png^draconis_ice_dragon_head_detail.png^draconis_ice_eyes_purple.png"
			local tex_slate = "draconis_ice_dragon_slate.png^draconis_ice_dragon_head_detail.png^draconis_ice_eyes_blue.png"
			local tex_white = "draconis_ice_dragon_white.png^draconis_ice_dragon_head_detail.png^draconis_ice_eyes_blue.png"
			local ice_dragon_form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
				"background[-0.7,-0.5;17.5,11.5;draconis_bestiary_bg.png]",
				"model[0.5,0;6,4;mob_mesh;draconis_ice_dragon.b3d;", tex_light_blue, ";-10,-130;false;false;510,510]",
				"model[0.5,2.25;6,4;mob_mesh;draconis_ice_dragon.b3d;", tex_sapphire, ";-10,-130;false;false;510,510]",
				"model[0.5,4.5;6,4;mob_mesh;draconis_ice_dragon.b3d;", tex_slate, ";-10,-130;false;false;510,510]",
				"model[0.5,6.75;6,4;mob_mesh;draconis_ice_dragon.b3d;", tex_white, ";-10,-130;false;false;510,510]",
				"label[9.25,0.5;", table.concat(text, ""), "]",
			}, "")
			minetest.show_formspec(player:get_player_name(), "draconis:bestiary_ice_dragon", ice_dragon_form)
		end
		if fields.pg_fire_dragon then
			local text = {
				"The Fire Dragon is large flying reptile that is said to to be \n",
				"found in warm climates and high mountains. Unlike most \n",
				"reptiles they are said to create large nests almost like a bird. \n",
				"The appearance of these nests greatly vary from sighting to \n",
				"sighting, with some claiming them to be a shallow burrow, \n",
				"and others saying they appear to be more like a scorched \n",
				"patch of earth littered with burnt logs. Some even say they \n",
				"don't make nests at all, or live in deep caverns underground. \n",
				"Though reports of their nesting behavior seems inconsistent, \n",
				"the reports of their violent destruction are all similar. Those \n",
				"who manage to survive their attacks say they fly overhead, \n",
				"burning those beneath them, and occasionally land to get \n",
				"closer to small targets. Brave souls who try to get close \n",
				"enough for an attack are flung back by the Dragons beating \n",
				"wings, making close quarter combat nearly impossible.",
			}
			local tex_black = "draconis_fire_dragon_black.png^draconis_fire_dragon_head_detail.png^draconis_fire_eyes_red.png"
			local tex_bronze = "draconis_fire_dragon_bronze.png^draconis_fire_dragon_head_detail.png^draconis_fire_eyes_green.png"
			local tex_green = "draconis_fire_dragon_green.png^draconis_fire_dragon_head_detail.png^draconis_fire_eyes_orange.png"
			local tex_red = "draconis_fire_dragon_red.png^draconis_fire_dragon_head_detail.png^draconis_fire_eyes_orange.png"
			local fire_dragon_form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
				"background[-0.7,-0.5;17.5,11.5;draconis_bestiary_bg.png]",
				"model[0.5,0;6,4;mob_mesh;draconis_fire_dragon.b3d;", tex_black, ";-10,-130;false;false;510,510]",
				"model[0.5,2.25;6,4;mob_mesh;draconis_fire_dragon.b3d;", tex_bronze, ";-10,-130;false;false;510,510]",
				"model[0.5,4.5;6,4;mob_mesh;draconis_fire_dragon.b3d;", tex_green, ";-10,-130;false;false;510,510]",
				"model[0.5,6.75;6,4;mob_mesh;draconis_fire_dragon.b3d;", tex_red, ";-10,-130;false;false;510,510]",
				"label[9.25,0.5;", table.concat(text, ""), "]",
			}, "")
			minetest.show_formspec(player:get_player_name(), "draconis:bestiary_fire_dragon", fire_dragon_form)
		end
		if fields.pg_ice_dragon_egg then
			local text = {
				"While the Fire Dragon Egg is rare thing to find, Ice Dragon Eggs \n",
				"are often put off as myths. Few of these supposed Ice Dragon \n",
				"Eggs exist, and are claimed be sceptics to be a dyed Fire \n",
				"Dragon Egg. Surely they do exist, seeing as the Ice Dragon \n",
				"builds similar nests to the Fire Dragon. In line with the \n",
				"mystery of the Ice Dragon's anatomy, how it incubates Eggs is \n",
				"also quite mysterious. Eggs require heat to incubate properly, \n",
				"and yet somehow the freezing Ice Dragon manages to hatch \n",
				"it's Eggs without issue."
			}
			local ice_dragon_egg_form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
				"background[-0.7,-0.5;17.5,11.5;draconis_bestiary_bg.png]",
				"image[2.5,0.75;2,2;draconis_ice_dragon_egg_light_blue.png]",
				"image[2.5,2.75;2,2;draconis_ice_dragon_egg_sapphire.png]",
				"image[2.5,4.75;2,2;draconis_ice_dragon_egg_slate.png]",
				"image[2.5,6.75;2,2;draconis_ice_dragon_egg_white.png]",
				"label[8.25,0.5;", table.concat(text, ""), "]",
			}, "")
			minetest.show_formspec(player:get_player_name(), "draconis:bestiary_ice_dragon_egg", ice_dragon_egg_form)
		end
		if fields.pg_fire_dragon_egg then
			local text = {
				"The Fire Dragon Egg is considered to be one of the most \n",
				"valuable items out there. Despite the fact no human could \n",
				"possibly incubate one, they are so sought after that wealthy \n",
				"lords will trade a Dragon's weight in gold for them. Though \n",
				"some attempt to hatch them, most choose to leave them on \n",
				"display as a symbol of wealth and power. Obtaining one is \n",
				"presumably difficult, seeing as where they're even found is a \n",
				"mystery. Those who have managed to obtain an Egg give \n",
				"conflicting reports of how they've done so. Some claim to \n",
				"have quietly raided a sleeping Dragons nest, while others \n",
				"make the bold and ridiculous claim that they killed a massive \n",
				"Dragon in a underground cavern and raided it's clutch."
			}
			local fire_dragon_egg_form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
				"background[-0.7,-0.5;17.5,11.5;draconis_bestiary_bg.png]",
				"image[2.5,0.75;2,2;draconis_fire_dragon_egg_black.png]",
				"image[2.5,2.75;2,2;draconis_fire_dragon_egg_bronze.png]",
				"image[2.5,4.75;2,2;draconis_fire_dragon_egg_green.png]",
				"image[2.5,6.75;2,2;draconis_fire_dragon_egg_red.png]",
				"label[8.25,0.5;", table.concat(text, ""), "]",
			}, "")
			minetest.show_formspec(player:get_player_name(), "draconis:bestiary_fire_dragon_egg", fire_dragon_egg_form)
		end
		if fields.pg_raising then
			local text = {
				"Raising Dragons is a long and difficult process, \n",
				"once they've been hatched they should \n",
				"immediately be fed. If they are not properly \n",
				"fed they can quickly starve to death, especially \n",
				"at young ages. They are not picky eaters and \n",
				"will gladly eat any form of raw flesh. Once \n",
				"they reach an age of 25 they will begin to form \n",
				"a louder roar and their horns will grow out, at \n",
				"an age of 50 their roars are fully developed \n",
				"and they can be ridden. It seems they stop \n",
				"growing at an age of about 100 but their \n",
				"fire/ice breathing stamina seems to increase \n",
				"beyond this age."
			}
			local raising_form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
				"background[-0.7,-0.5;17.5,11.5;draconis_bestiary_bg.png]",
				"item_image_button[2.5,0.75;2,2;draconis:dragon_flute;pg_flute;]",
				"item_image_button[2.5,4;2,2;draconis:summoning_gem;pg_gem;]",
				"item_image_button[2.5,7.25;2,2;draconis:growth_essence_ice;pg_essence;]",
				"label[9.25,0.5;", table.concat(text, ""), "]",
			}, "")
			minetest.show_formspec(player:get_player_name(), "draconis:bestiary_raising", raising_form)
		end
		if fields.pg_forge then
			local text = {
				"The Draconic Steel Forge is used to create \n",
				"Draconic Steel, a very powerful and hard to \n",
				"obtain metal that can only be forged with the \n",
				"extreme heat or cold of a Dragons breath. A \n",
				"specific mixture of blocks is required to create \n",
				"this forge. The images in the next page show \n",
				"the layout of the Scorched/Frozen Bricks and \n",
				"the Dragon Scale Bricks that form the outside \n",
				"of the forge. Once the outside of the forge is \n",
				"create the core Ice/Fire Draconic Steel Forge \n",
				"block must be placed in the center."
			}
			local forge_form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
				"background[-0.7,-0.5;17.5,11.5;draconis_bestiary_bg.png]",
				"image[10.5,0.5;4,4;draconis_bestiary_forge1_fg.png]",
				"tooltip[10.5,0.5;4,4;Scorched/Frozen Brick Layout]",
				"image[10.5,5;4,4;draconis_bestiary_forge2_fg.png]",
				"tooltip[10.5,5;4,4;Scaled Brick Layout]",
				"button[13.5,9.25;1.75,0.5;pg_forge_next;Next Page]",
				"label[0.5,0.5;", table.concat(text, ""), "]",
			}, "")
			minetest.show_formspec(player:get_player_name(), "draconis:bestiary_forge", forge_form)
		end
	end
	if formname == "draconis:bestiary_raising" then
		if fields.pg_flute then
			local text = {
				"The Dragon Flute is able to store Dragons and \n",
				"call down flying Dragons if the user owns the \n",
				"Dragon and the Flute is empty."
			}
			local flute_form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
				"background[-0.7,-0.5;17.5,11.5;draconis_bestiary_bg.png]",
				"image[2.5,1;3,3;draconis_dragon_flute.png]",
				"image[1,6;6,3.4;draconis_bestiary_flute_recipe_fg.png]",
				"label[9.25,0.5;", table.concat(text, ""), "]",
			}, "")
			minetest.show_formspec(player:get_player_name(), "draconis:bestiary_raising_flute", flute_form)
		end
		if fields.pg_gem then
			local text = {
				"The Summoning Gem can be paired with a \n",
				"tamed Dragon and be used to summon that \n",
				"Dragon from anywhere, with no limitations on \n",
				"distance."
			}
			local gem_form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
				"background[-0.7,-0.5;17.5,11.5;draconis_bestiary_bg.png]",
				"image[2.5,1;3,3;draconis_summoning_gem.png]",
				"image[1,6;6,3.4;draconis_bestiary_gem_recipe_fg.png]",
				"label[9.25,0.5;", table.concat(text, ""), "]",
			}, "")
			minetest.show_formspec(player:get_player_name(), "draconis:bestiary_raising_gem", gem_form)
		end
		if fields.pg_essence then
			local text = {
				"The Essence of Growth can be used to make a \n",
				"Dragon Grow slightly. They should be used \n",
				"sparingly as they do not satiate Dragons, and \n",
				"can cause them to starve if not fed after being \n",
				"grown. Ice Dragon Blood and Ice Dracolilies \n",
				"create Icy Essence of Growth, which is used on \n",
				"Ice Dragons. Fiery Essence of Growth is used \n",
				"on Fire Dragons, and created with a similar \n",
				"mixture to the Icy Essence, with Ice Dragon \n",
				"Blood being swapped for Fire Dragon Blood, \n",
				"and Icy Dracolilies being swapped for Fiery \n",
				"Dracolilies."
			}
			local essence_form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
				"background[-0.7,-0.5;17.5,11.5;draconis_bestiary_bg.png]",
				"image[2.5,1;3,3;draconis_growth_essence_ice.png]",
				"image[1,6;6,3.4;draconis_bestiary_essence_recipe_fg.png]",
				"label[9.25,0.5;", table.concat(text, ""), "]",
			}, "")
			minetest.show_formspec(player:get_player_name(), "draconis:bestiary_raising_essence", essence_form)
		end
	end
	if formname == "draconis:bestiary_forge" then
		if fields.pg_forge_next then
			local text = {
				"Once the Draconic Steel Forge is constructed \n",
				"you will need to insert Dragon Blood as fuel. \n",
				"The Dragon Blood you need corresponds to \n",
				"the type of forge. Once the fuel is inserted \n",
				"you will need to insert Steel Ingots. Once fuel \n",
				"and ingots have been inserted you can begin \n",
				"the process of forging. You will need to mount \n",
				"a Dragon and make it breath into the forge. As \n",
				"with the fuel, the type of Dragon you need \n",
				"corresponds to the type of forge. After about a \n",
				"minute of breathing you will have a single \n",
				"Ice/Fire-Forged Draconic Steel Ingot."
			}
			local forge_form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
				"background[-0.7,-0.5;17.5,11.5;draconis_bestiary_bg.png]",
				"image[9,1;6.2,8.8;draconis_bestiary_forge_form_fg.png]",
				"label[0.5,0.5;", table.concat(text, ""), "]"
			}, "")
			minetest.show_formspec(player:get_player_name(), "draconis:bestiary_forge_page2", forge_form)
		end
	end
end)

minetest.register_craftitem("draconis:bestiary", {
	description = "Bestiary",
	inventory_image = "draconis_bestiary.png",
	stack_max = 1,
	on_place = function(itemstack, player)
		local meta = itemstack:get_meta()
		local pages = minetest.deserialize(meta:get_string("pages"))
		if not pages
		or #pages < 1 then return end
		bestiary_formspec(player, meta)
	end,
	on_secondary_use = function(itemstack, player)
		local meta = itemstack:get_meta()
		local pages = minetest.deserialize(meta:get_string("pages"))
		if not pages
		or #pages < 1 then return end
		bestiary_formspec(player, meta)
	end
})

minetest.register_craftitem("draconis:manuscript", {
	description = "Manuscript",
	inventory_image = "draconis_manuscript.png",
	stack_max = 16
})

if minetest.get_modpath("dungeon_loot") then
	dungeon_loot.register({name = "draconis:manuscript", chance = 0.4, count = {1, 3}})
end

-----------
-- Blood --
-----------

minetest.register_craftitem("draconis:blood_fire_dragon", {
	description = "Fire Dragon Blood",
	inventory_image = "draconis_blood_fire.png",
	stack_max = 16,
	groups = {dragon_blood = 1}
})

minetest.register_craftitem("draconis:blood_ice_dragon", {
	description = "Ice Dragon Blood",
	inventory_image = "draconis_blood_ice.png",
	stack_max = 16,
	groups = {dragon_blood = 1}

})

-----------------------
-- Essence of Growth --
-----------------------

minetest.register_craftitem("draconis:growth_essence_fire", {
	description = "Fiery Essence of Growth",
	inventory_image = "draconis_growth_essence_fire.png",
	groups = {eatable = 1},
	on_use = minetest.item_eat(-20)
})

minetest.register_craftitem("draconis:growth_essence_ice", {
	description = "Icy Essence of Growth",
	inventory_image = "draconis_growth_essence_ice.png",
	groups = {eatable = 1},
	on_use = minetest.item_eat(-20)
})