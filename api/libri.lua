-----------
-- Libri --
-----------

local color = minetest.colorize

local spacing = 0.5

local libri_bg = {
	"formspec_version[3]",
	"size[16,10]",
	"background[-0.7,-0.5;17.5,11.5;draconis_libri_bg.png]",
}

local libri_drp_font_scale = "dropdown[17,0;0.75,0.5;drp_font_scale;0.25,0.5,0.75,1;1]"

local pages = {
	{ -- Home
		{ -- Main Page
			element_type = "label",
			font_size = 24,
			offset = {x = 0, y = 1.5},
			file = "draconis_libri_home.txt"
		},
		{ -- Next Page
			unlock_key = "dragons",
			element_type = "image_button",
			font_size = 24,
			offset = {x = 15, y = 9},
			size = {x = 1, y = 1},
			text = "draconis_libri_icon_next.png;btn_next;;true;false"
		},
		{ -- Chapter 1
			unlock_key = "dragons",
			element_type = "button",
			font_size = 24,
			offset = {x = 10.5, y = 1.5},
			size = {x = 4, y = 1},
			text = "btn_dragons;Chapter 1: Dragons"
		},
		{ -- Chapter 2
			unlock_key = "wyverns",
			element_type = "button",
			font_size = 24,
			offset = {x = 10.5, y = 3.5},
			size = {x = 4, y = 1},
			text = "btn_wyverns;Chapter 2: Wyverns"
		},
		{ -- Chapter 3
			unlock_key = "draconic_steel",
			element_type = "button",
			font_size = 24,
			offset = {x = 10.5, y = 5.5},
			size = {x = 4, y = 1},
			text = "btn_draconic_steel;Chapter 3: Draconic Steel"
		}
	},
	-- Chapter 1
	{ -- Dragons Page 1
		{ -- Main Page
			element_type = "label",
			font_size = 24,
			offset = {x = 0, y = 1.5},
			file = "draconis_libri_dragon1.txt"
		},
		{ -- Fire Dragon
			element_type = "image",
			font_size = 24,
			offset = {x = 8, y = 1},
			size = {x = 8, y = 4},
			text = "draconis_libri_img_fire_dragon.png"
		},
		{ -- Fire Dragon Text
			element_type = "label",
			font_size = 24,
			offset = {x = 8, y = 5},
			file = "draconis_libri_dragon2.txt"
		},
		{ -- Next Page
			element_type = "image_button",
			font_size = 24,
			offset = {x = 15, y = 9},
			size = {x = 1, y = 1},
			text = "draconis_libri_icon_next.png;btn_next;;true;false"
		},
		{ -- Last Page
			element_type = "image_button",
			font_size = 24,
			offset = {x = 1, y = 9},
			size = {x = 1, y = 1},
			text = "draconis_libri_icon_last.png;btn_last;;true;false"
		}
	},
	{ -- Dragons Page 2
		{ -- Ice Dragon
			element_type = "image",
			font_size = 24,
			offset = {x = 0.5, y = 1},
			size = {x = 7, y = 3.5},
			text = "draconis_libri_img_ice_dragon.png"
		},
		{ -- Ice Dragon Text
			element_type = "label",
			font_size = 24,
			offset = {x = 0, y = 5},
			file = "draconis_libri_dragon3.txt"
		},
		{ -- Combat Text
			element_type = "label",
			font_size = 24,
			offset = {x = 8, y = 1.5},
			file = "draconis_libri_dragon4.txt"
		},
		{ -- Next Page
			element_type = "image_button",
			font_size = 24,
			offset = {x = 15, y = 9},
			size = {x = 1, y = 1},
			text = "draconis_libri_icon_next.png;btn_next;;true;false"
		},
		{ -- Last Page
			element_type = "image_button",
			font_size = 24,
			offset = {x = 1, y = 9},
			size = {x = 1, y = 1},
			text = "draconis_libri_icon_last.png;btn_last;;true;false"
		}
	},
	{ -- Dragons Page 3
		{ -- Hatching Text
			element_type = "label",
			font_size = 24,
			offset = {x = 0, y = 1.5},
			file = "draconis_libri_dragon5.txt"
		},
		{ -- Raising Text
			element_type = "label",
			font_size = 24,
			offset = {x = 8, y = 1.5},
			file = "draconis_libri_dragon6.txt"
		},
		{ -- Next Page
			unlock_key = "wyverns",
			element_type = "image_button",
			font_size = 24,
			offset = {x = 15, y = 9},
			size = {x = 1, y = 1},
			text = "draconis_libri_icon_next.png;btn_next;;true;false"
		},
		{ -- Last Page
			element_type = "image_button",
			font_size = 24,
			offset = {x = 1, y = 9},
			size = {x = 1, y = 1},
			text = "draconis_libri_icon_last.png;btn_last;;true;false"
		}
	},
	-- Chapter 2
	{ -- Wyverns Page 1
		{ -- Jungle Wyvern
			element_type = "image",
			font_size = 24,
			offset = {x = 8, y = 1},
			size = {x = 8, y = 4},
			text = "draconis_libri_img_jungle_wyvern.png"
		},
		{ -- Wyvern Text 1
			element_type = "label",
			font_size = 24,
			offset = {x = 0, y = 1.5},
			file = "draconis_libri_wyvern1.txt"
		},
		{ -- Wyvern Text 2
			element_type = "label",
			font_size = 24,
			offset = {x = 8, y = 5},
			file = "draconis_libri_wyvern2.txt"
		},
		{ -- Next Page
			unlock_key = "draconic_steel",
			element_type = "image_button",
			font_size = 24,
			offset = {x = 15, y = 9},
			size = {x = 1, y = 1},
			text = "draconis_libri_icon_next.png;btn_next;;true;false"
		},
		{ -- Last Page
			element_type = "image_button",
			font_size = 24,
			offset = {x = 1, y = 9},
			size = {x = 1, y = 1},
			text = "draconis_libri_icon_last.png;btn_last;;true;false"
		}
	},
	-- Chapter 3
	{ -- Steel Page 1
		{ -- Main Page
			element_type = "label",
			font_size = 24,
			offset = {x = 0, y = 1.5},
			file = "draconis_libri_steel1.txt"
		},
		{ -- Page 2
			element_type = "label",
			font_size = 24,
			offset = {x = 8, y = 1.5},
			file = "draconis_libri_steel2.txt"
		},
		{ -- Next Page
			element_type = "image_button",
			offset = {x = 15, y = 9},
			size = {x = 1, y = 1},
			text = "draconis_libri_icon_next.png;btn_next;;true;false"
		},
		{ -- Last Page
			unlock_key = "wyverns",
			element_type = "image_button",
			offset = {x = 1, y = 9},
			size = {x = 1, y = 1},
			text = "draconis_libri_icon_last.png;btn_last;;true;false"
		}
	},
	{ -- Steel Page 2
		{ -- Forge Instructions
			element_type = "image",
			offset = {x = 1.5, y = 0.5},
			size = {x = 5, y = 10},
			text = "draconis_libri_img_forge_instructions.png"
		},
		{ -- Forge Label
			element_type = "label",
			font_size = 24,
			offset = {x = 2, y = 0.5},
			text = "Constructing a Forge:"
		},
		{ -- Page 2
			element_type = "label",
			font_size = 24,
			offset = {x = 8, y = 0.5},
			file = "draconis_libri_steel3.txt"
		},
		{ -- Crucible Instructions
			element_type = "image",
			offset = {x = 10.5, y = 6.5},
			size = {x = 4, y = 2.5},
			text = "draconis_libri_img_crucible_craft.png"
		},
		{ -- Next Page
			element_type = "image_button",
			offset = {x = 15, y = 9},
			size = {x = 1, y = 1},
			text = "draconis_libri_icon_next.png;btn_next;;true;false"
		},
		{ -- Last Page
			element_type = "image_button",
			offset = {x = 1, y = 9},
			size = {x = 1, y = 1},
			text = "draconis_libri_icon_last.png;btn_last;;true;false"
		}
	},
	{ -- Steel Page 3
		{ -- Main Page
			element_type = "label",
			font_size = 24,
			offset = {x = 0, y = 1},
			file = "draconis_libri_steel4.txt"
		},
		{ -- Forge Label
			element_type = "label",
			font_size = 24,
			offset = {x = 11.5, y = 5.5},
			text = "Fire Forge:"
		},
		{ -- Fire Forge Instructions
			element_type = "image",
			offset = {x = 10.5, y = 6.5},
			size = {x = 4.5, y = 2.5},
			text = "draconis_libri_img_forge_demo.png"
		},
		{ -- Forge Label
			element_type = "label",
			font_size = 24,
			offset = {x = 11.5, y = 0.5},
			text = "Ice Forge:"
		},
		{ -- Ice Forge Instructions
			element_type = "image",
			offset = {x = 10.5, y = 2.5},
			size = {x = 4.5, y = 2.5},
			text = "draconis_libri_img_ice_forge_demo.png"
		},
		{ -- Last Page
			element_type = "image_button",
			offset = {x = 1, y = 9},
			size = {x = 1, y = 1},
			text = "draconis_libri_icon_last.png;btn_last;;true;false"
		}
	}
}

---------
-- API --
---------

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

function draconis.add_page(inv, chapter)
    local libri, list_i = draconis.get_libri(inv)
    local chapters = minetest.deserialize(libri:get_meta():get_string("chapters")) or {}
    if #chapters > 0 then
        for i = 1, #chapters do
			if chapters[i] == chapter then
				return
			end
        end
    end
	table.insert(chapters, chapter)
	libri:get_meta():set_string("chapters", minetest.serialize(chapters))
	inv:set_stack("main", list_i, libri)
	return true
end

local function render_element(def, meta, playername)
	local chapters = (meta and minetest.deserialize(meta:get_string("chapters"))) or {}
	local offset_x = def.offset.x
	local offset_y = def.offset.y
	local form = ""
	-- Add text
	if def.element_type == "label" then
		local font_size_x = (draconis.libri_font_size[playername] or 1)
		local font_size = (def.font_size or 16) * font_size_x
		if def.file then
			local filename = minetest.get_modpath("draconis") .. "/libri/" .. def.file
			local file = io.open(filename)
			if file then
				local i = 0
				local full_text = ""
				for line in file:lines() do
					full_text = full_text .. line .. "\n"
				end
				local total_offset = (offset_x + (0.35 - 0.35 * font_size_x)) .. "," .. offset_y
				form = form .. "hypertext[" .. total_offset .. ";8,9;text;<global color=#000000 size=".. font_size .. " halign=center>" .. full_text .. "]"
				file:close()
			end
		else
			form = form .. "style_type[label;font_size=" .. font_size .. "]"
			local line = def.text
			form = form .. "label[" .. offset_x .. "," .. offset_y .. ";" .. color("#000000", line .. "\n") .. "]"
		end
	else
		-- Add Images/Interaction
		local render_element = false
		if def.unlock_key
		and #chapters > 0 then
			for _, chapter in ipairs(chapters) do
				if chapter
				and chapter == def.unlock_key then
					render_element = true
					break
				end
			end
		elseif not def.unlock_key then
			render_element = true
		end
		if render_element then
			local offset = def.offset.x .. "," .. def.offset.y
			local size = def.size.x .. "," .. def.size.y
			form = form .. def.element_type .. "[" .. offset .. ";" .. size .. ";" .. def.text .. "]"
		end
	end
	return form
end

local function get_page(key, meta, playername)
	local form = table.copy(libri_bg)
	local chapters = minetest.deserialize(meta:get_string("chapters")) or {}
	local page = pages[key]
	for _, element in ipairs(page) do
		if type(element) == "table" then
			local element_rendered = render_element(element, meta, playername)
			table.insert(form, element_rendered)
		else
			table.insert(form, element)
		end
	end
	table.insert(form, "style[drp_font_scale;noclip=true]")
	table.insert(form, libri_drp_font_scale)
	table.insert(form, "style[drp_font_scale;noclip=true]")
	return table.concat(form, "")
end

---------------
-- Craftitem --
---------------

minetest.register_craftitem("draconis:libri_draconis", {
	description = "Libri Draconis",
	inventory_image = "draconis_libri_draconis.png",
	stack_max = 1,
	on_place = function(itemstack, player)
		local meta = itemstack:get_meta()
		local desc = meta:get_string("description")
		if desc:find("Bestiary") then
			meta:set_string("description", "Libri Draconis")
			meta:set_string("pages", nil)
		end
		local name = player:get_player_name()
		minetest.show_formspec(name, "draconis:libri_page_1", get_page(1, meta, name))
	end,
	on_secondary_use = function(itemstack, player)
		local meta = itemstack:get_meta()
		local desc = meta:get_string("description")
		if desc:find("Bestiary") then
			meta:set_string("description", "Libri Draconis")
			meta:set_string("pages", nil)
		end
		local name = player:get_player_name()
		minetest.show_formspec(name, "draconis:libri_page_1", get_page(1, meta, name))
	end
})

--------------------
-- Receive Fields --
--------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local plyr_name = player:get_player_name()
	local meta = player:get_wielded_item():get_meta()
	local page_no
	for i = 1, #pages do
		if formname == "draconis:libri_page_" .. i then
			page_no = i
			if fields.btn_next
			and pages[i + 1] then
				minetest.show_formspec(plyr_name,
					"draconis:libri_page_" .. i + 1, get_page(i + 1, meta, plyr_name))
				return true
			elseif fields.btn_last
			and pages[i - 1] then
				minetest.show_formspec(plyr_name,
					"draconis:libri_page_" .. i - 1, get_page(i - 1, meta, plyr_name))
				return true
			end
		end
	end
	if fields.btn_dragons then
		minetest.show_formspec(plyr_name, "draconis:libri_page_" .. 2, get_page(2, meta, plyr_name))
		return true
	end
	if fields.btn_wyverns then
		minetest.show_formspec(plyr_name, "draconis:libri_page_" .. 5, get_page(5, meta, plyr_name))
		return true
	end
	if fields.btn_draconic_steel then
		minetest.show_formspec(plyr_name, "draconis:libri_page_" .. 6, get_page(6, meta, plyr_name))
		return true
	end
	if fields.drp_font_scale
	and page_no then
		draconis.libri_font_size[plyr_name] = fields.drp_font_scale
		minetest.show_formspec(plyr_name, "draconis:libri_page_" .. page_no, get_page(page_no, meta, plyr_name))
		return true
	end
end)

minetest.register_globalstep(function()
    for _, player in pairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local inv = minetest.get_inventory({type = "player", name = name})
        if draconis.contains_libri(inv) then
			if contains_item(inv, "draconis:dragonstone_block_fire")
			or contains_item(inv, "draconis:dragonstone_block_ice") then
				draconis.add_page(inv, "draconic_steel")
			end
        end
    end
end)
