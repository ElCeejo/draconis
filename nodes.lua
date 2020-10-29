-------------
--- Nodes ---
-------------
-- Ver 1.0 --


local SF = draconis.string_format

----------------------------
-- Scorched/Frozen Blocks --
----------------------------

local material_types = {"scorched", "frozen"}

for _, material in pairs(material_types) do

    local frozen = 0

    if material == "frozen" then
        frozen = 2
    end

minetest.register_node("draconis:"..material.."_stone", {
    description = SF(material).." Stone",
    tiles = {"draconis_"..material.."_stone.png"},
    groups = {cracky = 3, slippery = frozen, stone = 1},
    sounds = default.node_sound_stone_defaults()
})

minetest.register_node("draconis:"..material.."_stone_block", {
    description = SF(material).." Stone Block",
    tiles = {"draconis_"..material.."_stone_block.png"},
    groups = {cracky = 3},
    sounds = default.node_sound_stone_defaults()
})

minetest.register_node("draconis:"..material.."_stone_brick", {
    description = SF(material).." Stone Brick",
    tiles = {"draconis_"..material.."_stone_brick.png"},
    groups = {cracky = 3},
    sounds = default.node_sound_stone_defaults()
})

minetest.register_node("draconis:"..material.."_soil", {
    description = SF(material).." Soil",
    tiles = {"draconis_"..material.."_soil.png"},
    groups = {crumbly = 3, slippery = frozen, soil = 1},
    sounds = default.node_sound_dirt_defaults()
})

minetest.register_node("draconis:"..material.."_tree", {
    description = SF(material).." Tree",
    tiles = {
        "draconis_"..material.."_tree_top.png", "draconis_"..material.."_tree_top.png",
        "draconis_"..material.."_tree.png"
    },
    paramtype2 = "facedir",
    is_ground_content = false,
    groups = {
        tree = 1,
        choppy = 2,
        oddly_breakable_by_hand = 1,
        falling_node = 1
    },
    sounds = default.node_sound_wood_defaults(),
    on_place = minetest.rotate_node
})

minetest.register_node("draconis:"..material.."_wood", {
    description = SF(material).." Wood Planks",
    paramtype2 = "facedir",
    place_param2 = 0,
    tiles = {"draconis_"..material.."_wood_planks.png"},
    is_ground_content = false,
    groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, wood = 1},
    sounds = default.node_sound_wood_defaults()
})

minetest.register_craft({
	output = "draconis:"..material.."_stone_brick 4",
	recipe = {
		{"draconis:"..material.."_stone", "draconis:"..material.."_stone"},
		{"draconis:"..material.."_stone", "draconis:"..material.."_stone"},
	}
})

minetest.register_craft({
	output = "draconis:"..material.."_stone_block 9",
	recipe = {
		{"draconis:"..material.."_stone", "draconis:"..material.."_stone", "draconis:"..material.."_stone"},
		{"draconis:"..material.."_stone", "draconis:"..material.."_stone", "draconis:"..material.."_stone"},
		{"draconis:"..material.."_stone", "draconis:"..material.."_stone", "draconis:"..material.."_stone"},
	}
})

minetest.register_craft({
	output = "draconis:"..material.."_wood 4",
	recipe = {
		{"draconis:"..material.."_tree"},
	}
})
end

-------------------------
-- Dragon Scale Bricks --
-------------------------

local function infotext(str, format)
	if format then
		return minetest.colorize("#a9a9a9", SF(str))
	end
	return minetest.colorize("#a9a9a9", str)
end

for _, fire_color in pairs(draconis.fire_colors) do
    minetest.register_node("draconis:fire_scale_brick_"..fire_color, {
        description = "Fire Dragon Scale Brick \n" .. infotext(fire_color, true),
        tiles = {"draconis_fire_scale_brick_"..fire_color..".png"},
        groups = {cracky = 1, level = 1},
        sounds = default.node_sound_stone_defaults()
    })
end

for _, ice_color in pairs(draconis.ice_colors) do
    minetest.register_node("draconis:ice_scale_brick_"..ice_color, {
        description = "Ice Dragon Scale Brick \n" .. infotext(ice_color, true),
        tiles = {"draconis_ice_scale_brick_"..ice_color..".png"},
        groups = {cracky = 1, level = 1},
        sounds = default.node_sound_stone_defaults()
    })
end

-- Dracolillies --

minetest.register_node("draconis:dracolily_fire", {
    description = "Fiery Dracolily",
    drawtype = "plantlike",
    waving = 1,
    tiles = {"draconis_dracolily_fire.png"},
    inventory_image = "draconis_dracolily_fire.png",
    sunlight_propagates = true,
    paramtype = "light",
    walkable = false,
    buildable_to = true,
    stack_max = 99,
    groups = {snappy = 3, flower = 1, flora = 1, attached_node = 1},
    sounds = default.node_sound_leaves_defaults(),
    selection_box = {
        type = "fixed",
        fixed = {-0.15, -0.5, -0.15, 0.15, 0.2, 0.15},
    }
})

minetest.register_node("draconis:dracolily_ice", {
    description = "Icy Dracolily",
    drawtype = "plantlike",
    waving = 1,
    tiles = {"draconis_dracolily_ice.png"},
    inventory_image = "draconis_dracolily_ice.png",
    sunlight_propagates = true,
    paramtype = "light",
    walkable = false,
    buildable_to = true,
    stack_max = 99,
    groups = {snappy = 3, flower = 1, flora = 1, attached_node = 1},
    sounds = default.node_sound_leaves_defaults(),
    selection_box = {
        type = "fixed",
        fixed = {-0.15, -0.5, -0.15, 0.15, 0.2, 0.15},
    }
})

-------------
-- Lectern --
-------------

local function lectern_pages_formspec(meta, show_pages)
    local pages = {
        "pg_ice_dragon;Ice Dragon",
        "pg_fire_dragon;Fire Dragon",
        "pg_ice_dragon_egg;Ice Dragon Eggs",
        "pg_fire_dragon_egg;Fire Dragon Eggs",
        "pg_raising;Raising Dragons",
        "pg_forge;Draconic Steel Forge"
    }
    local inactive_form = {
        "formspec_version[3]",
        "size[11,9]",
        "background[-0.75,-1;12.5,10;draconis_lectern_bg.png]",
        "list[current_player;main;0.65,5;8,1;]",
        "list[context;book;2.75,1.5;1,1;]",
        "list[context;pages;2.75,3.5;1,1;]",
        "listring[current_player;main]",
        "listring[context;book]",
        "listring[current_player;main]",
        "listring[context;pages]",
        "listring[current_player;main]"
    }
    local active_form = {
        "formspec_version[3]",
        "size[11,9]",
        "background[-0.75,-1;12.5,10;draconis_lectern_bg.png]",
        "list[current_player;main;0.65,5;8,1;]",
        "list[context;book;2.75,1.5;1,1;]",
        "list[context;pages;2.75,3.5;1,1;]",
        "listring[current_player;main]",
        "listring[context;book]",
        "listring[current_player;main]",
        "listring[context;pages]",
        "listring[current_player;main]",
        "button[5.75,1.5;2.5,0.8;"..pages[math.random(1, 6)].."]",
        "button[5.75,2.5;2.5,0.8;"..pages[math.random(1, 6)].."]",
        "button[5.75,3.5;2.5,0.8;"..pages[math.random(1, 6)].."]"
    }
    if show_pages then
        meta:set_string("formspec", table.concat(active_form, ""))
    else
        meta:set_string("formspec", table.concat(inactive_form, ""))
    end
end

minetest.register_entity("draconis:book_ent", {
	visual = "sprite",
	visual_size = {x=0.75, y=0.75},
	collisionbox = {0},
	physical = false,
	textures = {"draconis_book_ent.png"},
	on_activate = function(self)
		local pos = self.object:get_pos()
		local pos_under = {x=pos.x, y=pos.y-1, z=pos.z}
		if minetest.get_node(pos_under).name ~= "draconis:lectern" then
			self.object:remove()
		end
	end
})

minetest.register_node("draconis:lectern", {
	description = "Lectern",
	tiles = {"draconis_lectern.png",},
	paramtype2 = "facedir",
	groups = {cracky = 2, tubedevice = 1, tubedevice_receiver = 1},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
    drawtype = "mesh",
    mesh = "draconis_lectern.obj",

	on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        lectern_pages_formspec(meta, false)
        local inv = meta:get_inventory()
        inv:set_size("book", 1)
        inv:set_size("pages", 1)
    end,

	can_dig = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("book") and inv:is_empty("pages")
	end,

	allow_metadata_inventory_put = function(pos, listname, _, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end
		if listname == "book" then
			return stack:get_name() == "draconis:bestiary" and stack:get_count() or 0
		end
		if listname == "pages" then
			return stack:get_name() == "draconis:manuscript" and stack:get_count() or 0
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

		local stack = inv:get_stack("book", 1)
        if stack:get_name() == "draconis:bestiary" then
            local num = #minetest.get_objects_inside_radius(pos, 0.9)
            if num == 0 then
                minetest.add_entity({x=pos.x, y=pos.y+0.85, z=pos.z}, "draconis:book_ent")
            end
            local pages = inv:get_stack("pages", 1)
            if pages:get_name() == "draconis:manuscript"
            and pages:get_count() >= 2 then
                lectern_pages_formspec(meta, true)
            end
		end
	end,

	on_metadata_inventory_take = function(pos)
		local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()

        local pages = inv:get_stack("pages", 1)
        if pages:get_name() ~= "draconis:manuscript" then
            lectern_pages_formspec(meta, false)
        end

		local stack = inv:get_stack("book", 1)
        if stack:get_name() ~= "draconis:bestiary" then
            lectern_pages_formspec(meta, false)
            for _, obj in pairs(minetest.get_objects_inside_radius(pos, 1)) do
                if obj and obj:get_luaentity()
                and obj:get_luaentity().name == "draconis:book_ent" then
                    obj:remove()
                    break
                end
            end
		end
    end,

    on_receive_fields = function(pos, _, fields)

        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()

        local stack = inv:get_stack("book", 1)
        if stack:get_name() ~= "draconis:bestiary" then
            return
		end

		local pages = inv:get_stack("pages", 1)
        if pages:get_name() ~= "draconis:manuscript"
        or pages:get_count() < 2 then
            return
        end

        if fields.quit then return end

        local stack_meta = stack:get_meta()
        local stack_pages = minetest.deserialize(stack_meta:get_string("pages")) or {}
        local desc = stack_meta:get_string("description")
        if desc == "" then
            desc = "Bestiary"
        end

        if fields.pg_ice_dragon
        and not draconis.find_value_in_table(stack_pages,"pg_ice_dragon;Ice Dragon") then
            table.insert(stack_pages, "pg_ice_dragon;Ice Dragon")
            stack_meta:set_string("description", desc.."\n"..minetest.colorize("#a9a9a9", "Ice Dragon"))
        end

        if fields.pg_fire_dragon
        and not draconis.find_value_in_table(stack_pages, "pg_fire_dragon;Fire Dragon") then
            table.insert(stack_pages, "pg_fire_dragon;Fire Dragon")
            stack_meta:set_string("description", desc.."\n"..minetest.colorize("#a9a9a9", "Fire Dragon"))
        end

        if fields.pg_ice_dragon_egg
        and not draconis.find_value_in_table(stack_pages, "pg_ice_dragon_egg;Ice Dragon Eggs") then
            table.insert(stack_pages, "pg_ice_dragon_egg;Ice Dragon Eggs")
            stack_meta:set_string("description", desc.."\n"..minetest.colorize("#a9a9a9", "Ice Dragon Eggs"))
        end

        if fields.pg_fire_dragon_egg
        and not draconis.find_value_in_table(stack_pages, "pg_fire_dragon_egg;Fire Dragon Eggs") then
            table.insert(stack_pages, "pg_fire_dragon_egg;Fire Dragon Eggs")
            stack_meta:set_string("description", desc.."\n"..minetest.colorize("#a9a9a9", "Fire Dragon Eggs"))
        end

        if fields.pg_raising
        and not draconis.find_value_in_table(stack_pages, "pg_raising;Raising Dragons") then
            table.insert(stack_pages, "pg_raising;Raising Dragons")
            stack_meta:set_string("description", desc.."\n"..minetest.colorize("#a9a9a9", "Raising Dragons"))
        end

        if fields.pg_forge
        and not draconis.find_value_in_table(stack_pages, "pg_forge;Draconic Steel Forge") then
            table.insert(stack_pages, "pg_forge;Draconic Steel Forge")
            stack_meta:set_string("description", desc.."\n"..minetest.colorize("#a9a9a9", "Draconic Steel Forge"))
        end

        stack_meta:set_string("pages", minetest.serialize(stack_pages))
        inv:set_stack("book", 1, stack)
        pages:take_item(2)
        inv:set_stack("pages", 1, pages)
        if pages:get_count() < 2 then
            lectern_pages_formspec(meta, false)
        end
        return stack, pages
    end,


	on_blast = function(pos)
		local drops = {}
		default.get_inventory_drops(pos, "book", drops)
		default.get_inventory_drops(pos, "pages", drops)
		table.insert(drops, "draconis:lectern")
		minetest.remove_node(pos)
		return drops
    end,

    on_destruct = function(pos)
        for _, obj in pairs(minetest.get_objects_inside_radius(pos, 1)) do
            if obj and obj:get_luaentity()
            and obj:get_luaentity().name == "draconis:book_ent" then
                obj:remove()
                break
            end
        end
    end
})