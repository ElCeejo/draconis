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
})

minetest.register_craftitem("draconis:draconic_steel_ingot_ice", {
	description = "Ice-Forged Draconic Steel Ingot",
	inventory_image = "draconis_ice_draconic_steel_ingot.png",
	stack_max = 8,
})

local fire_colors = {
	"black",
	"bronze",
	"green",
	"red"
}

local ice_colors = {
	"light_blue",
	"sapphire",
	"slate",
	"white"
}

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

minetest.register_craftitem("draconis:dragon_flute", {
	description = "Dragon Flute",
	inventory_image = "draconis_dragon_flute.png",
	stack_max = 1,
	on_place = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.above
		local under = minetest.get_node(pointed_thing.under)
		local node = minetest.registered_nodes[under.name]
		if node and node.on_rightclick then
			return node.on_rightclick(pointed_thing.under, under, placer, itemstack)
		end
		if pos
		and not minetest.is_protected(pos, placer:get_player_name()) then
			pos.y = pos.y + 3
			local mob = itemstack:get_meta():get_string("mob")
			local staticdata = itemstack:get_meta():get_string("staticdata")
			if mob ~= "" then
				minetest.add_entity(pos, mob, staticdata)
				itemstack:get_meta():set_string("mob", nil)
				itemstack:get_meta():set_string("staticdata", nil)
				itemstack:get_meta():set_string("description", "Dragon Flute")
			end
		end
		return itemstack
	end,
	on_secondary_use = function(itemstack, player)
		local mob = itemstack:get_meta():get_string("mob")
		if mob ~= "" then return end
		local name = player:get_player_name()
		local dir = player:get_look_dir()
		local pos = player:get_pos()
		pos.y = pos.y + player:get_properties().eye_height or 1.625
		pos = vector.add(pos, vector.multiply(dir, 1))
		local dest = vector.add(pos, vector.multiply(dir, 100))
		local ray = minetest.raycast(pos, dest, true, false)
		for pointed_thing in ray do
			if pointed_thing.type == "object" then
				local obj = pointed_thing.ref
				if obj:get_luaentity() then
					obj = obj:get_luaentity()
				else
					return
				end
				if obj.name == "draconis:fire_dragon"
				or obj.name == "draconis:ice_dragon" then
					if not obj.tamed then
						minetest.chat_send_player(name, "You do not own this Dragon")
					elseif obj.owner == name then
						mobkit.clear_queue_high(obj)
						if not obj.isonground then
							obj.order = mobkit.remember(obj, "order", "follow")
							draconis.hq_follow(obj, 22, player)
						end
					end
				end
			end
		end
	end
})

function draconis.capture_with_flute(self, clicker)
	if not clicker:is_player()
	or not clicker:get_inventory() then
		return false
	end
	local dragon = self.name
	local catcher = clicker:get_player_name()
	local flute = clicker:get_wielded_item()
	if flute:get_name() ~= "draconis:dragon_flute" then
		return false
	end
	if not self.tamed then
		return false
	end
	if self.owner ~= catcher then
		minetest.chat_send_player(catcher, "This Dragon is owned by @1"..self.owner)
		return false
	end
	if clicker:get_inventory():room_for_item("main", dragon) then
		local stack = clicker:get_wielded_item()
		local meta = stack:get_meta()
		if not meta:get_string("mob")
		or meta:get_string("mob") == "" then
			draconis.set_color_string(self)
			meta:set_string("mob", dragon)
			meta:set_string("staticdata", self:get_staticdata())
			local info = get_info_flute(self)
			meta:set_string("description", info)
			clicker:set_wielded_item(stack)
			self.object:remove()
			return stack
		else
			minetest.chat_send_player(catcher, "This Dragon Flute already contains a Dragon")
			return false
		end
	end
	return true
end

-------------------
-- Summoning Gem --
-------------------

minetest.register_craftitem("draconis:summoning_gem", {
	description = "Dragon Summoning Gem",
	inventory_image = "draconis_summoning_gem.png",
	stack_max = 1,
	on_secondary_use = function(itemstack, player, pointed_thing)
		local name = player:get_player_name()
		if pointed_thing.type == "object"
		and itemstack:get_meta():get_string("id") == "" then
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
					itemstack:get_meta():set_string("id", dragon_id)
					local info = get_info_gem(ent)
					itemstack:get_meta():set_string("description", info)
					return itemstack
				end
			end
		elseif itemstack:get_meta():get_string("id") ~= "" then
			local last_pos = draconis.bonded_dragons[player:get_player_name()].last_pos
			local pos = {x=math.floor(last_pos.x), y=math.floor(last_pos.y), z=math.floor(last_pos.z)}
			draconis.forceload(pos)
			for _, ent in pairs(minetest.luaentities) do
				if ent.dragon_id
				and ent.dragon_id == itemstack:get_meta():get_string("id") then
					minetest.chat_send_player(name, "Dragon teleported from: "..minetest.pos_to_string(pos))
					local ppos = player:get_pos()
					ppos.y = ppos.y + 3
					ent.object:set_pos(player:get_pos())
					return
				end
			end
			minetest.chat_send_player(name, "Could not be teleported. Last seen at: "
														..minetest.pos_to_string(pos)..
														"\n Try again a couple more times.")
		end
	end,
	on_place = function(itemstack, player, pointed_thing)
		local name = player:get_player_name()
		if pointed_thing.type == "object"
		and not itemstack:get_meta():get_string("id") then
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
					itemstack:get_meta():set_string("id", dragon_id)
					local info = get_info_gem(ent)
					itemstack:get_meta():set_string("description", info)
				end
			end
		elseif itemstack:get_meta():get_string("id") ~= "" then
			local last_pos = draconis.bonded_dragons[player:get_player_name()].last_pos
			local pos = {x=math.floor(last_pos.x), y=math.floor(last_pos.y), z=math.floor(last_pos.z)}
			draconis.forceload(pos)
			for _, ent in pairs(minetest.luaentities) do
				if ent.dragon_id
				and ent.dragon_id == itemstack:get_meta():get_string("id") then
					minetest.chat_send_player(name, "Dragon teleported from: "..minetest.pos_to_string(pos))
					local ppos = player:get_pos()
					ppos.y = ppos.y + 3
					ent.object:set_pos(player:get_pos())
					return
				end
			end
			minetest.chat_send_player(name, "Could not be teleported. Last seen at: "
														..minetest.pos_to_string(pos)..
														"\n Try again a couple more times.")
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
				"The Fire Dragon is a mythical creature said to \n",
				"live in large patches of scorched terrain \n",
				"littered with shimmering treasure in cold, \n",
				"snowy biomes. They fly through the skies near \n",
				"these roosts in search of prey. Once they find \n",
				"prey they will begin to attack with their ice \n",
				"breath and sharp claws. While the individuals \n",
				"seen near these roosts are usually very large \n",
				"animals, the ones rumored to live in large \n",
				"caverns underground are truly massive. Their \n",
				"breath is freezing cold, leaving any terrain it's \n",
				"path frozen solid and any creatures in a solid \n",
				"block of ice."
			}
			local ice_dragon_form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
				"background[-0.7,-0.5;17.5,11.5;draconis_bestiary_bg.png]",
				"image[0.5,0.75;5.85,1.6;draconis_ice_dragon_form_1.png]",
				"image[0.5,2.75;5.85,1.6;draconis_ice_dragon_form_2.png]",
				"image[0.5,4.75;5.85,1.6;draconis_ice_dragon_form_3.png]",
				"image[0.5,6.75;5.85,1.6;draconis_ice_dragon_form_4.png]",
				"label[9.25,0.5;", table.concat(text, ""), "]",
			}, "")
			minetest.show_formspec(player:get_player_name(), "draconis:bestiary_ice_dragon", ice_dragon_form)
		end
		if fields.pg_fire_dragon then
			local text = {
				"The Fire Dragon is a mythical creature said to \n",
				"live in large patches of scorched terrain \n",
				"littered with golden treasure in warm biomes. \n",
				"They fly through the skies near these roosts in \n",
				"search of prey. Once they find prey they will \n",
				"begin to attack with their fire breath and sharp \n",
				"claws. While the individuals seen near these \n",
				"roosts are usually very large animals, the ones \n",
				"rumored to live in large caverns underground \n",
				"are truly massive. Their breath is scorches \n",
				"everything in it's path, leaving terrain a \n",
				"charred mess and piles of ash where living \n",
				"creatures once stood."
			}
			local fire_dragon_form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
				"background[-0.7,-0.5;17.5,11.5;draconis_bestiary_bg.png]",
				"image[0.5,0.75;5.85,1.6;draconis_fire_dragon_form_1.png]",
				"image[0.5,2.75;5.85,1.6;draconis_fire_dragon_form_2.png]",
				"image[0.5,4.75;5.85,1.6;draconis_fire_dragon_form_3.png]",
				"image[0.5,6.75;5.85,1.6;draconis_fire_dragon_form_4.png]",
				"label[9.25,0.5;", table.concat(text, ""), "]",
			}, "")
			minetest.show_formspec(player:get_player_name(), "draconis:bestiary_fire_dragon", fire_dragon_form)
		end
		if fields.pg_ice_dragon_egg then
			local text = {
				"Ice Dragon Eggs are among the rarest things in the \n",
				"world, rarer than even Fire Dragon Eggs. As with Fire \n",
				"Dragon Eggs, obtaining one requires killing a large \n",
				"Dragon. In the case of Ice Dragons, it may take more \n",
				"than one person to kill, as any assisting animals will \n",
				"be quickly frozen and killed. Ice Dragon Eggs are not \n",
				"often seen in markets, as most people don't dare \n",
				"do often don't come back. There are many theories \n",
				"on how to hatch an Ice Dragon Egg, most of them \n",
				"claiming that ice or water is involved."
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
				"Fire Dragon Eggs are incredibly rare to find. \n",
				"Obtaining one requires killing a large Dragon, which \n",
				"are very rarely found, and even more rarely slain. \n",
				"Most Dragon Eggs are sold in shops for high prices to \n",
				"rich men who want something to place on their in \n",
				"their home as a status symbol. However, it is said \n",
				"that with prolonged exposure to extreme heat, they \n",
				"will can be hatched. As of yet, nobody has \n",
				"attempted to do so."
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