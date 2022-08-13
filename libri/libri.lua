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

local pages = {
	{ -- Home
		{ -- Main Page
			element_type = "label",
			font_size = 24,
			offset = {x = 1.5, y = 1.5},
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
			offset = {x = 1.5, y = 1.5},
			file = "draconis_libri_dragon1.txt"
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
			text = "draconis_libri_icon_prev.png;btn_last;;true;false"
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
			offset = {x = 10, y = 5},
			file = "draconis_libri_dragon2.txt"
		}
	},
	{ -- Dragons Page 2
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
			text = "draconis_libri_icon_prev.png;btn_last;;true;false"
		},
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
			offset = {x = 1.5, y = 5},
			file = "draconis_libri_dragon3.txt"
		},
		{ -- Combat Text
			element_type = "label",
			font_size = 24,
			offset = {x = 10, y = 1.5},
			file = "draconis_libri_dragon4.txt"
		}
	},
	{ -- Dragons Page 3
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
			text = "draconis_libri_icon_prev.png;btn_last;;true;false"
		},
		{ -- Hatching Text
			element_type = "label",
			font_size = 24,
			offset = {x = 1.5, y = 1.5},
			file = "draconis_libri_dragon5.txt"
		},
		{ -- Raising Text
			element_type = "label",
			font_size = 24,
			offset = {x = 10, y = 1.5},
			file = "draconis_libri_dragon6.txt"
		}
	},
	-- Chapter 2
	{ -- Wyverns Page 1
		{ -- Next Page
			unlock_key = "draconic_steel",
			element_type = "image_button",
			font_size = 24,
			offset = {x = 15, y = 9},
			size = {x = 1, y = 1},
			text = "draconis_libri_icon_next.png;btn_next;;true;false"
		},
		{ -- Last Page
			unlock_key = "dragons",
			element_type = "image_button",
			font_size = 24,
			offset = {x = 1, y = 9},
			size = {x = 1, y = 1},
			text = "draconis_libri_icon_prev.png;btn_last;;true;false"
		},
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
			offset = {x = 3.5, y = 1.5},
			file = "draconis_libri_wyvern1.txt"
		},
		{ -- Wyvern Text 2
			element_type = "label",
			font_size = 24,
			offset = {x = 10, y = 5},
			file = "draconis_libri_wyvern2.txt"
		}
	},
	-- Chapter 3
	{ -- Steel Page 1
		{ -- Main Page
			element_type = "label",
			font_size = 24,
			offset = {x = 1.5, y = 1.5},
			file = "draconis_libri_steel1.txt"
		},
		{ -- Page 2
			element_type = "label",
			font_size = 24,
			offset = {x = 10, y = 1.5},
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
			text = "draconis_libri_icon_prev.png;btn_last;;true;false"
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
			offset = {x = 10, y = 0.5},
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
			text = "draconis_libri_icon_prev.png;btn_last;;true;false"
		}
	},
	{ -- Steel Page 1
		{ -- Main Page
			element_type = "label",
			font_size = 24,
			offset = {x = 1.5, y = 1},
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
			text = "draconis_libri_icon_prev.png;btn_last;;true;false"
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

local function get_page(key, meta)
	local form = table.copy(libri_bg)
	local chapters = minetest.deserialize(meta:get_string("chapters")) or {}
	local page = pages[key]
	for _, element in ipairs(page) do
		local offset_x = element.offset.x
		local offset_y = element.offset.y
		-- Add text
		if element.element_type == "label" then
			if element.font_size then
				table.insert(form, "style_type[label;font_size=" .. element.font_size .. "]")
			end
			if element.file then
				local filename = minetest.get_modpath("draconis") .. "/libri/" .. element.file
				local file = io.open(filename)
				if file then
					local i = 0
					for line in file:lines() do
						i = i + 1
						local center_offset = 0
						local max_line = (element.max_line or 30)
						if string.len(line) < max_line then
							center_offset = (max_line - string.len(line)) * (element.font_size or 16) / 3 * 0.011
						end
						local align_x = offset_x + center_offset
						local align_y = offset_y + spacing * i
						table.insert(form, "label[" .. align_x .. "," .. align_y .. ";" .. color("#000000", line .. "\n") .. "]")
					end
					file:close()
				end
			else
				local line = element.text
				table.insert(form, "label[" .. offset_x .. "," .. offset_y .. ";" .. color("#000000", line .. "\n") .. "]")
			end
		else
			-- Add Images/Interaction
			local render_element = false
			if element.unlock_key
			and #chapters > 0 then
				for _, chapter in ipairs(chapters) do
					if chapter
					and chapter == element.unlock_key then
						render_element = true
						break
					end
				end
			elseif not element.unlock_key then
				render_element = true
			end
			if render_element then
				local offset = element.offset.x .. "," .. element.offset.y
				local size = element.size.x .. "," .. element.size.y
				table.insert(form, element.element_type .. "[" .. offset .. ";" .. size .. ";" .. element.text .. "]")
			end
		end
	end
	return table.concat(form, "")
end

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
		minetest.show_formspec(player:get_player_name(), "draconis:libri_page_1", get_page(1, meta))
	end,
	on_secondary_use = function(itemstack, player)
		local meta = itemstack:get_meta()
		local desc = meta:get_string("description")
		if desc:find("Bestiary") then
			meta:set_string("description", "Libri Draconis")
			meta:set_string("pages", nil)
		end
		minetest.show_formspec(player:get_player_name(), "draconis:libri_page_1", get_page(1, meta))
	end
})

--------------------
-- Receive Fields --
--------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local playername = player:get_player_name()
	for i = 1, #pages do
		if formname == "draconis:libri_page_" .. i then
			if fields.btn_next
			and pages[i + 1] then
				minetest.show_formspec(playername,
					"draconis:libri_page_" .. i + 1, get_page(i + 1, player:get_wielded_item():get_meta()))
			elseif fields.btn_last
			and pages[i - 1] then
				minetest.show_formspec(playername,
					"draconis:libri_page_" .. i - 1, get_page(i - 1, player:get_wielded_item():get_meta()))
			end
		end
	end
	if fields.btn_dragons then
		minetest.show_formspec(playername, "draconis:libri_page_" .. 2, get_page(2, player:get_wielded_item():get_meta()))
	end
	if fields.btn_wyverns then
		minetest.show_formspec(playername, "draconis:libri_page_" .. 5, get_page(5, player:get_wielded_item():get_meta()))
	end
	if fields.btn_draconic_steel then
		minetest.show_formspec(playername, "draconis:libri_page_" .. 6, get_page(6, player:get_wielded_item():get_meta()))
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
