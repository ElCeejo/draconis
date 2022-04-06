-----------
-- Craftitems --
-----------

-- Get Craft Items --

local ice_block = "default:ice"

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_items) do
		if name:match(":ice") and minetest.get_item_group(name, "slippery") > 0 then
			ice_block = name
            break
		end
	end
end)

-- Local Utilities --

local dragon_drops = {}

local function is_node_walkable(pos)
    local name = minetest.get_node(pos).name
    if not name then return false end
    local def = minetest.registered_nodes[name]
    return def and def.walkable
end

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

local function get_info_flute(self)
	local info = "Dragon Flute\n"..minetest.colorize("#a9a9a9", correct_name(self.name))
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


local function set_dragon_horn_info(self)
	local info = "Dragon Horn\n"..minetest.colorize("#a9a9a9", correct_name(self.name))
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
	local info = "Dragon Summoning Gem\n"..minetest.colorize("#a9a9a9", correct_name(self.name))
	if self.nametag ~= "" then
		info = info.."\n"..infotext(self.nametag)
	end
	if self.color then
		info = info.."\n"..infotext(self.color, true)
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
	stack_max = 8,
})

minetest.register_craftitem("draconis:draconic_steel_ingot_ice", {
	description = "Ice-Forged Draconic Steel Ingot",
	inventory_image = "draconis_draconic_steel_ingot_ice.png",
	stack_max = 8,
})

----------
-- Eggs --
----------

local dragon_eggs = {}

for color, hex in pairs(draconis.colors_fire) do
    minetest.register_node("draconis:egg_fire_" .. color, {
        description = "Fire Dragon Egg \n" .. infotext(color, true),
        drawtype = "mesh",
        paramtype = "light",
        sunlight_propagates = true,
        mesh = "draconis_egg.obj",
        inventory_image = "draconis_dragon_egg.png^[multiply:#" .. hex,
        tiles = {"draconis_dragon_egg_mesh.png^[multiply:#" .. hex},
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
            local burning = 0
            local burn_check = {
                vector.add(pos, {x = 1, y = -1, z = 0}),
                vector.add(pos, {x = 1, y = -1, z = 1}),
                vector.add(pos, {x = 0, y = -1, z = 1}),
                vector.add(pos, {x = -1, y = -1, z = 1}),
                vector.add(pos, {x = -1, y = -1, z = 0}),
                vector.add(pos, {x = -1, y = -1, z = -1}),
                vector.add(pos, {x = 0, y = -1, z = -1}),
                vector.add(pos, {x = 1, y = -1, z = -1})
            }
            for i = 1, #burn_check do
                local node = minetest.get_node(burn_check[i])
                local name = node.name
                if name:match("^draconis:fire_scale_block_") then
                    burning = burning + 1
                end
                if burning == 8 then
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
        activate_func = function(self, staticdata, dtime)
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
            self:memorize("progress", self.progress)
            for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 6)) do
                if obj and obj:is_player() then
                    minetest.after(1.5, function()
                        self.owner_name = self:memorize("owner_name", obj:get_player_name())
                    end)
                end
            end
            local node = minetest.get_node(pos)
            local name = node.name
            if minetest.get_node_group(name, "fire") > 0 then
                self.progress = self.progress + self.dtime
                if not self.hatching then
                    self.hatching = true
                    self.object:set_animation({x = 1, y = 40}, 30, 0)
                end
                if self.progress >= 1000 then
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
                end
            else
                self.progress = 0
                self.hatching = false
                self.object:set_animation({x = 0, y = 0}, 0, 0)
            end
        end,
        on_rightclick = function(self, clicker)
            local inv = clicker:get_inventory()
			if inv:room_for_item("main", {name = "draconis:egg_fire_" .. color}) then
				clicker:get_inventory():add_item("main", "draconis:egg_fire_" .. color)
			else
				local pos = self:get_pos("floor")
				pos.y = pos.y + 0.5
				minetest.add_item(pos, {name = "draconis:egg_fire_" .. color})
			end
        end
    })
end

-- Ice Eggs --

for color, hex in pairs(draconis.colors_ice) do
    minetest.register_node("draconis:egg_ice_" .. color, {
        description = "Ice Dragon Egg \n" .. infotext(color, true),
        drawtype = "mesh",
        paramtype = "light",
        sunlight_propagates = true,
        mesh = "draconis_egg.obj",
        inventory_image = "draconis_ice_dragon_egg.png^[multiply:#" .. hex,
        tiles = {"draconis_ice_dragon_egg_mesh.png^[multiply:#" .. hex},
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
            local burning = 0
            local burn_check = {
                vector.add(pos, {x = 1, y = 0, z = 0}),
                vector.add(pos, {x = 1, y = 0, z = 1}),
                vector.add(pos, {x = 0, y = 0, z = 1}),
                vector.add(pos, {x = -1, y = 0, z = 1}),
                vector.add(pos, {x = -1, y = 0, z = 0}),
                vector.add(pos, {x = -1, y = 0, z = -1}),
                vector.add(pos, {x = 0, y = 0, z = -1}),
                vector.add(pos, {x = 1, y = 0, z = -1})
            }
            for i = 1, #burn_check do
                local node = minetest.get_node(burn_check[i])
                local name = node.name
                if name:match("^draconis:ice_scale_block_") then
                    burning = burning + 1
                end
                if burning == 8 then
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
        textures = {"draconis_dragon_egg_mesh.png^[multiply:#" .. hex},
        animations = {
            idle = {range = {x = 0, y = 0}, speed = 1, frame_blend = 0.3, loop = false},
            hatching = {range = {x = 70, y = 130}, speed = 15, frame_blend = 0.3, loop = true},
        },
        -- Function
        activate_func = function(self, staticdata, dtime)
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
            self:memorize("progress", self.progress)
            for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 6)) do
                if obj and obj:is_player() then
                    minetest.after(1.5, function()
                        self.owner_name = self:memorize("owner_name", obj:get_player_name())
                    end)
                end
            end
            local node = minetest.get_node(pos)
            local name = node.name
            if minetest.get_node_group(name, "water") > 0
            or (self.progress > 0 and name == ice_block) then
                if minetest.get_node_group(name, "water") > 0 then
                    minetest.set_node(pos, {name = ice_block})
                end
                self.progress = self.progress + self.dtime
                if not self.hatching then
                    self.hatching = true
                    self.object:set_animation({x = 1, y = 40}, 30, 0)
                end
                if self.progress >= 1000 then
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
                end
            else
                self.progress = 0
                self.hatching = false
                self.object:set_animation({x = 0, y = 0}, 0, 0)
            end
        end,
        on_rightclick = function(self, clicker)
            local inv = clicker:get_inventory()
			if inv:room_for_item("main", {name = "draconis:egg_ice_" .. color}) then
				clicker:get_inventory():add_item("main", "draconis:egg_ice_" .. color)
			else
				local pos = self:get_pos("floor")
				pos.y = pos.y + 0.5
				minetest.add_item(pos, {name = "draconis:egg_ice_" .. color})
			end
        end
    })
end

--------------------
-- Dragon Storage --
--------------------

local ceil = math.ceil

-- API --

local function find_dragon(a, b)
    local steps = ceil(vector.distance(a, b))
    local line = {}

    for i = 1, steps do
        local pos

        if steps > 0 then
            pos = {
                x = a.x + (b.x - a.x) * (i / steps),
                y = a.y + (b.y - a.y) * (i / steps),
                z = a.z + (b.z - a.z) * (i / steps)
            }
        else
            pos = a
        end
        if is_node_walkable(pos) then
            break
        end
        local objects = minetest.get_objects_in_area(vector.subtract(pos, 6), vector.add(pos, 6))
        for i = 1, #objects do
            if objects[i]
            and objects[i]:get_luaentity() then
                local object = objects[i]
                local ent = object:get_luaentity()
                if ent.name:match("^draconis:") then
                    return object, ent
                end
            end
        end
    end
end

local function get_pointed_dragon(player, range)
	local dir, pos = player:get_look_dir(), player:get_pos()
	pos.y = pos.y + player:get_properties().eye_height or 1.625
	pos = vector.add(pos, vector.multiply(dir, 1))
	local dist = 1
	local dest = vector.add(pos, vector.multiply(dir, range))
	local object, ent = find_dragon(pos, dest)
    if not ent
    or (ent.name ~= "draconis:ice_dragon"
    and ent.name ~= "draconis:fire_dragon")
    or not ent.owner
    or ent.owner ~= player:get_player_name()
    or ent.rider then
        ent = nil
    end
	return ent
end

local function capture(player, ent, tool_name)
	if not player:is_player()
	or not player:get_inventory() then
		return false
	end
	local stack = player:get_wielded_item()
	local meta = stack:get_meta()
	if not meta:get_string("staticdata")
	or meta:get_string("staticdata") == "" then
        if not ent.dragon_id then return end
		draconis.set_color_string(ent)
		meta:set_string("mob", ent.name)
        meta:set_string("dragon_id", ent.dragon_id)
		meta:set_string("staticdata", ent:get_staticdata())
		local info
		if tool_name == "dragon_horn" then
			meta:set_int("timestamp", os.time())
			info = set_dragon_horn_info(ent)
		else
			info = get_info_flute(ent)
		end
		meta:set_string("description", info)
		player:set_wielded_item(stack)
        draconis.dragons[ent.dragon_id].stored_in_item = true
		ent.object:remove()
		return stack
	else
		minetest.chat_send_player(player:get_player_name(), "This Dragon " .. correct_name(tool_name) .. " already contains a Dragon")
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

minetest.register_craftitem("draconis:dragon_horn", {
	description = "Dragon Horn",
	inventory_image = "draconis_dragon_horn.png",
	stack_max = 1,
    on_place = function(itemstack, player, pointed_thing)
		local meta = itemstack:get_meta()
		local pos = pointed_thing.above
		local under = minetest.get_node(pointed_thing.under)
		local node = minetest.registered_nodes[under.name]
		if node and node.on_rightclick then
			return node.on_rightclick(pointed_thing.under, under, player, itemstack)
		end
		if pos
		and not minetest.is_protected(pos, player:get_player_name()) then
			pos.y = pos.y + 3
			local mob = meta:get_string("mob")
			local staticdata = meta:get_string("staticdata")
			if staticdata ~= "" then
				local ent = minetest.add_entity(pos, mob, staticdata)
                if meta:get_string("dragon_id")
                and draconis.dragons[meta:get_string("dragon_id")] then
                    draconis.dragons[meta:get_string("dragon_id")].stored_in_item = false
                end
				meta:set_string("staticdata", nil)
				meta:set_string("description", "Dragon Horn")
				if meta:get_int("timestamp") then
					local time = meta:get_int("timestamp")
					local diff = os.time() - time
					ent:get_luaentity().time_in_horn = diff
					meta:set_int("timestamp", os.time())
				end
                return itemstack
			end
		end
	end,
    on_secondary_use = function(itemstack, player, pointed_thing)
		local meta = itemstack:get_meta()
		local mob = meta:get_string("mob")
        local id = meta:get_string("dragon_id")
        local staticdata = meta:get_string("staticdata")
        local ent = get_pointed_dragon(player, 80)
        if pointed_thing
        and pointed_thing.ref then
            ent = pointed_thing.ref:get_luaentity()
            if not ent.name:match("^draconis:") then
                ent = nil
            end
        end
        if (ent
        and ent.dragon_id
        and ent.dragon_id == id)
        or id == "" then
            if vector.distance(player:get_pos(), ent.object:get_pos()) < 7 then
                return capture(player, ent, "dragon_horn")
            else
                if not ent.touching_ground then
                    ent.order = ent:memorize("order", "follow")
                end
            end
            return itemstack
        end
		if staticdata == "" 
        and id ~= "" then
            if not draconis.dragons[id] then
                meta:set_string("mob", nil)
				meta:set_string("dragon_id", nil)
                meta:set_string("staticdata", nil)
				meta:set_string("description", "Dragon Horn")
                return itemstack
            end
            if mob ~= "" then
                local last_pos = draconis.dragons[id].last_pos
                local ent = get_dragon_by_id(id)
                if draconis.dragons[id].stored_in_item then return itemstack end
                if not ent then
                    table.insert(draconis.dragons[id].removal_queue, last_pos)
                    minetest.add_entity(player:get_pos(), mob, draconis.dragons[id].staticdata)
                else
                    ent.object:set_pos(player:get_pos())
                end
                minetest.chat_send_player(player:get_player_name(), "Teleporting Dragon")
            end
            return itemstack
        end
        return itemstack
	end
})

minetest.register_craftitem("draconis:dragon_flute", {
	description = "Dragon Flute",
	inventory_image = "draconis_dragon_flute.png",
	stack_max = 1,
    on_place = function(itemstack, player, pointed_thing)
		local meta = itemstack:get_meta()
		local pos = pointed_thing.above
		local under = minetest.get_node(pointed_thing.under)
		local node = minetest.registered_nodes[under.name]
		if node and node.on_rightclick then
			return node.on_rightclick(pointed_thing.under, under, player, itemstack)
		end
		if pos
		and not minetest.is_protected(pos, player:get_player_name()) then
			pos.y = pos.y + 3
			local mob = meta:get_string("mob")
			local staticdata = meta:get_string("staticdata")
			if mob ~= "" then
				local ent = minetest.add_entity(pos, mob, staticdata)
                if meta:get_string("dragon_id")
                and draconis.dragons[meta:get_string("dragon_id")] then
                    draconis.dragons[meta:get_string("dragon_id")].stored_in_item = false
                end
				meta:set_string("mob", nil)
                meta:set_string("dragon_id", nil)
				meta:set_string("staticdata", nil)
				meta:set_string("description", "Dragon Flute")
                return itemstack
			end
		end
	end,
    on_secondary_use = function(itemstack, player, pointed_thing)
		local meta = itemstack:get_meta()
		local mob = meta:get_string("mob")
		if mob ~= "" then return end
		local ent = get_pointed_dragon(player, 40)
        if pointed_thing
        and pointed_thing.ref then
            ent = pointed_thing.ref:get_luaentity()
            if not ent.name:match("^draconis:") then
                ent = nil
            end
        end
		if not ent then
			return
		end
		if vector.distance(player:get_pos(), ent.object:get_pos()) < 14 then
			return capture(player, ent, "flute")
		else
			if not ent.touching_ground then
				ent.order = ent:memorize("order", "follow")
			end
		end
	end
})

-----------
-- Tools --
-----------

-- Dragonbone --

minetest.register_tool("draconis:pick_dragonbone", {
    description = "Dragonbone Pickaxe",
    inventory_image = "draconis_dragonbone_pick.png",
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

minetest.register_tool("draconis:shovel_dragonbone", {
    description = "Dragonbone Shovel",
    inventory_image = "draconis_dragonbone_shovel.png",
    wield_image = "draconis_dragonbone_shovel.png",
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

minetest.register_tool("draconis:axe_dragonbone", {
    description = "Dragonbone Axe",
    inventory_image = "draconis_dragonbone_axe.png",
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

minetest.register_tool("draconis:sword_dragonbone", {
    description = "Dragonbone Sword",
    inventory_image = "draconis_dragonbone_sword.png",
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

-- Draconic Steel --

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
                uses=100,
                maxlevel=3},
			crumbly = {
                times={[1]=0.5, [2]=0.25, [3]=0.2},
                uses=100,
                maxlevel=3
            },
        },
        damage_groups = {fleshy = 35}
    },
    range = 6,
    sound = {breaks = "default_tool_breaks"},
    groups = {pickaxe = 1}
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
                uses = 100,
                maxlevel = 3
            }
        },
        damage_groups = {fleshy = 30}
    },
    range = 6,
    sound = {breaks = "default_tool_breaks"},
    groups = {shovel = 1}
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
                uses = 100,
                maxlevel = 3
            }
        },
        damage_groups = {fleshy = 55}
    },
    range = 6,
    sound = {breaks = "default_tool_breaks"},
    groups = {axe = 1}
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
                uses = 100,
                maxlevel = 3
            }
        },
        damage_groups = {fleshy = 60}
    },
    range = 6,
    sound = {breaks = "default_tool_breaks"},
    groups = {sword = 1}
})
end

--------------
-- libri --
--------------

local libri_text = {
    ["pg_dragons"] = {
        [1] = {
            offset_x = 2.25,
            offset_y = 4,
            text = {
                "Dragons are large flying ",
                "reptiles straight from legend. ",
                "They're perfectly suited for ",
                "killing, with armor protecting ",
                "their underside and back, ",
                "massive, muscular wings ",
                "capable of pushing even other ",
                "dragons back and crushing ",
                "hoardes of enemies at once, ",
                "and elemental ranged attacks ",
                "capable of wiping out armies ",
                "and even melting castles. They ",
                "are also highly intelligent, ",
                "making them capable of ",
                "imprinting on a Player if raised ",
                "from a young age. A tamed ",
                "Dragon, ridden by a skilled ",
                "rider, can bring entire empires ",
                "to their knees."
            }
        },
        [2] = {
            offset_x = 10.5,
            offset_y = 0.5,
            text = {
                "The 2 known variations of ",
                "Dragons are built similarly and ",
                "behave mostly the same. The ",
                "key differences are in color, ",
                "head ornamentation, and their ",
                "elemental breath. Fire Dragons ",
                "range in color from Black to ",
                "Gold, and have 3 horns, with ",
                "the lower 2 horns being very ",
                "short. Ice Dragons color ranges ",
                "from White to Sapphire, and ",
                "also have 3 horns, but the ",
                "lower 2 are noticable longer ",
                "than those of the Fire Dragon. ",
                "Fire Dragons breath has more ",
                "destructive potential in inland ",
                "combat, capable of destroying ",
                "wood structures quickly and ",
                "disintegrating foliage cover. ",
                "Ice Dragons have more ",
                "potential at sea, where they ",
                "can stop ships by freezing ",
                "water at the surface, also ",
                "preventing those on the ship ",
                "from jumping into water for ",
                "cover."
            }
        }
    },
    ["pg_dragon_loot"] = {
        [1] = {
            offset_x = 2.25,
            offset_y = 5,
            text = {
                "Dragon Bones are a valuable ",
                "resource with a variety of uses. ",
                "The bones are hollow, making ",
                "them perfect for Dragon ",
                "storage items. They also have ",
                "incredibly high iron content, ",
                "resulting in the dark color. This ",
                "makes them excellent for the ",
                "blades of weapons, being ",
                "lightweight yet highly ",
                "resiliant. They're also a ",
                "common choice for the hilt of ",
                "Draconic Steel weapons."
            }
        },
        [2] = {
            offset_x = 10.5,
            offset_y = 0.5,
            text = {
                "Dragon Scales are very tough ",
                "and somewhat resistant to ",
                "Dragon's elemental breath. ",
                "When crafted into blocks and ",
                "fused with Stone Bricks made ",
                "from Dragon damaged stone, ",
                "they can be used to create a ",
                "Draconic Steel Forge."
            }
        }
    },
    ["pg_dragon_eggs"] = {
        [1] = {
            offset_x = 2.25,
            offset_y = 5,
            text = {
                "Dragon Eggs are much ",
                "different from the eggs of any ",
                "other animal. They feel like ",
                "they're made of solid stone, ",
                "and their temperature feels ",
                "extremely hot or cold ",
                "depending on the Dragon ",
                "variant. Hatching these Eggs is ",
                "a mystery, and many theories ",
                "for how it's done have been ",
                "passed around. Some say it ",
                "involves shed scales, others ",
                "say it involves surrounding ",
                "them entirely with flammable ",
                "material and lighting it on fire, ",
                "and some even say blood ",
                "magic is involved."
            }
        },
        [2] = {
            offset_x = 10.5,
            offset_y = 0.5,
            text = {
                "While hatching these Eggs is ",
                "certainly possible and has ",
                "been done by Dragon Riders ",
                "relatively often, many only ",
                "keep these Eggs as decoration. ",
                "However, even after decades ",
                "of being on a pedestal or shelf, ",
                "Dragon Eggs can still be ",
                "hatched. An embryo surviving  ",
                "that long shouldn't be ",
                "possible, but as with the ",
                "Dragons themselves, these ",
                "Eggs seem to ignore the known ",
                "laws of biology."
            }
        }
    },
    ["pg_dragon_nests"] = {
        offset_x = 2.5,
        offset_y = 5,
        text = {
            "Dragon Nests are large stone ",
            "structures found in relatively ",
            "flat areas. These Nests have ",
            "large stalagmites and are often ",
            "littered with shiny metals. ",
            "Only Males build nests (how ",
            "they do so is unknown) and ",
            "use them mainly to store shiny ",
            "metal as a form of display to ",
            "Females. Though Dragons have ",
            "no dimorphism between ",
            "genders, you can tell their ",
            "gender based on how much ",
            "metal is in the nest. Males will ",
            "have large amounts of it to use ",
            "as display, while Females only ",
            "have metal that's been left by ",
            "past mates."
        }
    },
    ["pg_draconic_steel"] = {
        [1] = {
            offset_x = 2.5,
            offset_y = 6,
            text = {
                "The Draconic Steel Forge is ",
                "expensive but well worth it. ",
                "Draconic Steel is immensely ",
                "powerful and versatile, Though ",
                "It's especially useful for swords. ",
                "It's incredibly lightweight, but ",
                "holds an edge better than any ",
                "other metal, and is sharp ",
                "enough to slice through a full ",
                "suit of diamond armor."
            }
        },
        [2] = {
            offset_x = 10.5,
            offset_y = 5,
            text = {
                "The frame of the forge is ",
                "crafted with Dragon scale ",
                "reinforced brick. Once the ",
                "frame is constructed the core ",
                "must be placed at the center ",
                "and you can then begin forging."
            }
        },
        [3] = {
            offset_x = 10.5,
            offset_y = 7,
            text = {
                "The process itself involves ",
                "ordinary Steel Ingots along with ",
                "wood to form high and low ",
                "carbon metals that meld ",
                "together under the ",
                "temperature of a Dragon's ",
                "breath."
            }
        }
    },
}

-- Local API --

local function get_info_text(data)
    local info_text = {}
    for i = 1, #data.text do
        local str = data.text[i]
        local center_offset = 0
        if string.len(str) < 30 then
            center_offset = (30 - string.len(str)) * 0.05
        end
        table.insert(info_text, "label[" .. data.offset_x + center_offset .. "," .. data.offset_y + i * 0.25 .. ";" .. minetest.colorize("#000000", data.text[i] .. "\n") .. "]")
    end
    return table.concat(info_text, "")
end

-- Global API --

function draconis.contains_libri(inventory)
    return inventory and inventory:contains_item("main", ItemStack("draconis:libri_draconis"))
end

local function contains_item(inventory, item)
    return inventory and inventory:contains_item("main", ItemStack(item))
end

function draconis.get_libri(inventory)
    local list = inventory:get_list("main")
    for i = 1, inventory:get_size("main") do
        local stack = list[i]
        if stack:get_name()
        and stack:get_name() == "draconis:libri_draconis" then
            return stack, i
        end
    end
end

function draconis.add_page(inv, page)
    local libri, list_i = draconis.get_libri(inv)
    local pages = minetest.deserialize(libri:get_meta():get_string("pages")) or {}
    if #pages > 0 then
        local add_page = true
        for i = 1, #pages do
            if pages[i].name == page.name then
                add_page = false
                break
            end
        end
        if add_page then
            table.insert(pages, page)
            libri:get_meta():set_string("pages", minetest.serialize(pages))
            inv:set_stack("main", list_i, libri)
            return true
        end
    else
        table.insert(pages, page)
        libri:get_meta():set_string("pages", minetest.serialize(pages))
        inv:set_stack("main", list_i, libri)
        return true
    end
end

local function libri_formspec(player, meta)
    local basic_form = table.concat({
        "formspec_version[3]",
        "size[16,10]",
        "background[-0.7,-0.5;17.5,11.5;draconis_libri_bg.png]"
	}, "")
	local pages = minetest.deserialize(meta:get_string("pages"))
	if pages[1] then
		basic_form = basic_form.."button[1.75,1.5;4,1;".. pages[1].form .."]"
	end
	if pages[2] then
		basic_form = basic_form.."button[1.75,3.5;4,1;".. pages[2].form .."]"
	end
	if pages[3] then
		basic_form = basic_form.."button[1.75,5.5;4,1;".. pages[3].form .."]"
	end
	if pages[4] then
		basic_form = basic_form.."button[1.75,7.5;4,1;".. pages[4].form .."]"
	end
	if pages[5] then
		basic_form = basic_form.."button[10.25,1.5;4,1;".. pages[5].form .."]"
	end
	if pages[6] then
		basic_form = basic_form.."button[10.25,3.5;4,1;".. pages[6].form .."]"
	end
    minetest.show_formspec(player:get_player_name(), "draconis:libri_main", basic_form)
end

minetest.register_craftitem("draconis:libri_draconis", {
	description = "Libri Draconis",
	inventory_image = "draconis_libri_draconis.png",
	stack_max = 1,
	on_place = function(itemstack, player)
		local meta = itemstack:get_meta()
		local pages = minetest.deserialize(meta:get_string("pages"))
        local desc = meta:get_string("description")
        if desc:find("Bestiary") then
            meta:set_string("description", "Libri Draconis")
            meta:set_string("pages", nil)
            pages = minetest.deserialize(meta:get_string("pages"))
        end
		if not pages
		or #pages < 1 then return end
		libri_formspec(player, meta)
	end,
	on_secondary_use = function(itemstack, player)
		local meta = itemstack:get_meta()
		local pages = minetest.deserialize(meta:get_string("pages"))
        local desc = meta:get_string("description")
        if desc:find("Bestiary") then
            meta:set_string("description", "Libri Draconis")
            meta:set_string("pages", nil)
            pages = minetest.deserialize(meta:get_string("pages"))
        end
		if not pages
		or #pages < 1 then return end
		libri_formspec(player, meta)
	end
})

minetest.register_alias_force("draconis:bestiary", "draconis:libri_draconis")
minetest.register_alias_force("draconis:lectern", "draconis:log_scorched") -- We do a little trolling

minetest.register_globalstep(function(dtime)
    for _, player in pairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local inv = minetest.get_inventory({type = "player", name = player:get_player_name()})
        if draconis.contains_libri(inv) then
            local libri, iter = draconis.get_libri(inv)
            for i = 1, #dragon_drops do
                if contains_item(inv, dragon_drops[i]) then
                    if draconis.add_page(inv, {name = "dragon_loot", form = "pg_dragon_loot;Dragon Loot"}) then
                        break
                    end
                end
            end
            for i = 1, #dragon_eggs do
                if contains_item(inv, dragon_eggs[i]) then
                    if draconis.add_page(inv, {name = "dragon_eggs", form = "pg_dragon_eggs;Dragon Eggs"}) then
                        break
                    end
                end
            end
        end
    end
end)

local last_form = {}

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "draconis:libri_main" then
		if fields.pg_dragons then
			local form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
				"background[-0.7,-0.5;17.5,11.5;draconis_libri_bg.png]",
				"image[0.5,1;6,2.6;draconis_libri_img_fire_dragon.png]",
                "image[8.5,6.5;7.2,3.2;draconis_libri_img_ice_dragon.png]",
                "image_button[0,9;1,1;draconis_libri_icon_prev.png;btn_last;;true;false]",
                get_info_text(libri_text["pg_dragons"][1]),
                get_info_text(libri_text["pg_dragons"][2]),
			}, "")
			minetest.show_formspec(player:get_player_name(), "draconis:libri_dragon", form)
            last_form[player:get_player_name()] = "draconis:libri_main"
		end
        if fields.pg_dragon_loot then
			local form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
				"background[-0.7,-0.5;17.5,11.5;draconis_libri_bg.png]",
				"item_image[2.75,1.75;2.5,2.5;draconis:dragon_bone]",
                "item_image[10.75,3.25;2.5,2.5;draconis:scales_fire_dragon_red]",
                "item_image[10.75,6.25;2.5,2.5;draconis:scales_ice_dragon_sapphire]",
                "image_button[0,9;1,1;draconis_libri_icon_prev.png;btn_last;;true;false]",
                get_info_text(libri_text["pg_dragon_loot"][1]),
                get_info_text(libri_text["pg_dragon_loot"][2]),
			}, "")
			minetest.show_formspec(player:get_player_name(), "draconis:libri_dragon", form)
            last_form[player:get_player_name()] = "draconis:libri_main"
		end
        if fields.pg_dragon_eggs then
			local form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
				"background[-0.7,-0.5;17.5,11.5;draconis_libri_bg.png]",
				"image[1.25,0.25;5,5;draconis_libri_img_fire_eggs.png]",
                "image[9.75,5.25;5,5;draconis_libri_img_ice_eggs.png]",
                "image_button[0,9;1,1;draconis_libri_icon_prev.png;btn_last;;true;false]",
                get_info_text(libri_text["pg_dragon_eggs"][1]),
                get_info_text(libri_text["pg_dragon_eggs"][2]),
			}, "")
			minetest.show_formspec(player:get_player_name(), "draconis:libri_dragon", form)
            last_form[player:get_player_name()] = "draconis:libri_main"
		end
        if fields.pg_dragon_nests then
			local form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
				"background[-0.7,-0.5;17.5,11.5;draconis_libri_bg.png]",
				"image[0.25,0.25;7.75,5;draconis_libri_img_fire_nest.png]",
                "image[8.25,0.25;7.75,5;draconis_libri_img_ice_nest.png]",
                "image_button[0,9;1,1;draconis_libri_icon_prev.png;btn_last;;true;false]",
                get_info_text(libri_text["pg_dragon_nests"]),
			}, "")
			minetest.show_formspec(player:get_player_name(), "draconis:libri_dragon", form)
            last_form[player:get_player_name()] = "draconis:libri_main"
		end
        if fields.pg_draconic_steel then
			local form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
				"background[-0.7,-0.5;17.5,11.5;draconis_libri_bg.png]",
                "item_image[1.75,0.75;4.5,4.5;draconis:sword_fire_draconic_steel]",
				"image[10.25,0.25;4,4;draconis_libri_img_forge.png]",
                "image_button[0,9;1,1;draconis_libri_icon_prev.png;btn_last;;true;false]",
                get_info_text(libri_text["pg_draconic_steel"][1]),
                get_info_text(libri_text["pg_draconic_steel"][2]),
                get_info_text(libri_text["pg_draconic_steel"][3]),
			}, "")
			minetest.show_formspec(player:get_player_name(), "draconis:libri_dragon", form)
            last_form[player:get_player_name()] = "draconis:libri_main"
		end
	end
    if formname:match("^draconis:libri_") then
        if fields.btn_last
        and last_form[player:get_player_name()] then
            if last_form[player:get_player_name()] == "draconis:libri_main"
            and player:get_wielded_item():get_name() == "draconis:libri_draconis" then
                libri_formspec(player, player:get_wielded_item():get_meta())
            end
        end

        if fields.quit or fields.key_enter then
            last_form[player:get_player_name()] = nil
        end
    end
end)

minetest.register_on_craft(function(itemstack, player, old_craft_grid)
    local inv = minetest.get_inventory({type = "player", name = player:get_player_name()})
	if (itemstack:get_name():match("^draconis:fire_scale_block_")
    or itemstack:get_name():match("^draconis:ice_scale_block_"))
    and draconis.contains_libri(inv) then
        draconis.add_page(inv, {name = "draconic_steel", form = "pg_draconic_steel;Draconic Steel"})
        return itemstack
	end
end)

--------------
-- Crafting --
--------------

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

for color in pairs(draconis.colors_fire) do
    minetest.register_craft({
        output = "draconis:fire_scale_block_" .. color,
        recipe = {
            {"draconis:scales_fire_dragon_" .. color, "draconis:scales_fire_dragon_" .. color, "draconis:scales_fire_dragon_" .. color},
            {"draconis:scales_fire_dragon_" .. color, "draconis:scales_fire_dragon_" .. color, "draconis:scales_fire_dragon_" .. color},
            {"draconis:scales_fire_dragon_" .. color, "draconis:scales_fire_dragon_" .. color, "draconis:scales_fire_dragon_" .. color},
        }
    })
end

for color in pairs(draconis.colors_ice) do
    minetest.register_craft({
        output = "draconis:ice_scale_block_" .. color,
        recipe = {
            {"draconis:scales_ice_dragon_" .. color, "draconis:scales_ice_dragon_" .. color, "draconis:scales_ice_dragon_" .. color},
            {"draconis:scales_ice_dragon_" .. color, "draconis:scales_ice_dragon_" .. color, "draconis:scales_ice_dragon_" .. color},
            {"draconis:scales_ice_dragon_" .. color, "draconis:scales_ice_dragon_" .. color, "draconis:scales_ice_dragon_" .. color},
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
