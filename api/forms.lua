---------------
-- Formspecs --
---------------

local ceil = math.ceil

local form_objref = {}

---------------------
-- Local Utilities --
---------------------

local function get_perc(n, max)
	return n / ceil(max) * 100
end

local function get_stat(self, stat, stat_max)
	local scale = self.growth_scale or 1
	stat = self[stat]
	stat_max = self[stat_max] * scale
	return get_perc(stat, stat_max)
end

local function get_rename_formspec(self)
	local tag = self.nametag or ""
	local form = {
		"size[8,4]",
		"field[0.5,1;7.5,0;name;" .. minetest.formspec_escape("Enter name:") .. ";" .. tag .. "]",
		"button_exit[2.5,3.5;3,1;mob_rename;" .. minetest.formspec_escape("Rename") .. "]"
	}
	return table.concat(form, "")
end

local function activate_nametag(self)
	self.nametag = self:recall("nametag") or nil
	if not self.nametag then return end
	self.object:set_properties({
		nametag = self.nametag,
		nametag_color = "#FFFFFF"
	})
end

local function correct_name(str)
	if str then
		if str:match(":") then str = str:split(":")[2] end
		return (string.gsub(" " .. str, "%W%l", string.upper):sub(2):gsub("_", " "))
	end
end

-----------------
-- Dragon Form --
-----------------

local function get_dragon_formspec(self)
	-- Stats
	local current_age = self.age or 100
	local health = get_stat(self, "hp", "max_health")
	local hunger = get_stat(self, "hunger", "max_hunger")
	local stamina = get_perc(self.flight_stamina, 900)
	local breath = get_perc(self.attack_stamina, 100)
	-- Visuals
	local frame_range = self.animations["stand"].range
	local frame_loop = frame_range.x .. "," ..  frame_range.y
	local texture = self:get_props().textures[1]
	local health_ind = "draconis_forms_health_bg.png^[lowpart:" .. health .. ":draconis_forms_health_fg.png"
	local hunger_ind = "draconis_forms_hunger_bg.png^[lowpart:" .. hunger .. ":draconis_forms_hunger_fg.png"
	local stamina_ind = "draconis_forms_stamina_bg.png^[lowpart:" .. stamina .. ":draconis_forms_stamina_fg.png"
	local breath_ind = "draconis_forms_breath_bg.png^[lowpart:" .. breath .. ":draconis_forms_breath_fg.png"
	-- Settings
	local fly_allowed = "Flight Allowed"
	local fly_image = "draconis_forms_flight_allowed.png"
	if not self.fly_allowed then
		fly_allowed = "Flight Not Allowed"
		fly_image = "draconis_forms_flight_disallowed.png"
	end
	local form = {
		"formspec_version[4]",
		"size[16,10]",
		--"no_prepend[]",
		"bgcolor[#000000;false]",
		"background[0,0;16,10;draconis_forms_bg_b.png]",
		"label[6.8,0.8;" .. correct_name(self.name) .. " (" .. correct_name(self.gender) .. ")]",
		"label[7,1.5;" .. current_age .." Days Old]",
		"button[6.75,8.75;2.6,0.5;btn_dragon_name;" .. (self.nametag or "Set Name") .. "]",
		"model[3,1.7;10,7;mob_mesh;" .. self.mesh .. ";" .. texture .. ";-10,-130;false;false;" .. frame_loop .. ";15]",
		"image[1.1,1.3;1,1;" .. health_ind .."]",
		"image[1.1,3.3;1,1;" .. hunger_ind .."]",
		"image[1.1,5.3;1,1;" .. stamina_ind .."]",
		"image[1.1,7.3;1,1;" .. breath_ind .."]",
		"tooltip[13.45,7.6;1.9,1.9;" .. correct_name(self.stance) .. "]",
		"image_button[13.45,7.6;1.9,1.9;draconis_forms_dragon_" .. self.stance .. ".png;btn_dragon_stance;;false;false;]",
		"tooltip[13.45,3.9;1.9,1.9;" .. correct_name(self.order) .. "]",
		"image_button[13.45,3.9;1.9,1.9;draconis_forms_dragon_" .. self.order .. ".png;btn_dragon_order;;false;false;]",
		"tooltip[13.45,0.3;1.9,1.9;" .. fly_allowed .. "]",
		"image_button[13.45,0.3;1.9,1.9;" .. fly_image .. ";btn_dragon_fly;;false;false;]"
	}
	if minetest.check_player_privs(self.owner, {draconis_admin = true}) then
		table.insert(form, "button[9.75,8.75;2.6,0.5;btn_customize;Customize]")
	end
	return table.concat(form, "")
end

draconis.dragon_api.show_formspec = function(self, player)
	minetest.show_formspec(player:get_player_name(), "draconis:dragon_forms", get_dragon_formspec(self))
	form_objref[player:get_player_name()] = self
end

local function get_customize_formspec(self)
	local texture = self.object:get_properties().textures[1]
	local frame_range = self.animations["stand"].range
	local frame_loop = frame_range.x .. "," ..  frame_range.y
	local form
	if self.name == "draconis:fire_dragon" then
		form = {
			"formspec_version[4]",
			"size[12,6]",
			"dropdown[0.5,1.1;3,0.6;drp_wing;Orange,Purple,Red,Yellow;1]",
			"label[1.1,0.8;Wing Color]",
			"dropdown[4.5,1.1;3,0.6;drp_eyes;Orange,Red,Green;1]",
			"label[5.1,0.8;Eye Color]",
			"dropdown[8.5,1.1;3,0.6;drp_body;Black,Bronze,Green,Red,Gold;1]",
			"label[9.1,0.8;Body Color]",
			"model[1.5,1.7;10,7;mob_mesh;" .. self.mesh .. ";" .. texture .. ";-10,-130;false;false;" .. frame_loop .. ";15]"
		}
	elseif self.name == "draconis:ice_dragon" then
		form = {
			"formspec_version[4]",
			"size[12,6]",
			"dropdown[0.5,1.1;3,0.6;drp_wing;Dark Blue,Purple;1]",
			"label[1.1,0.8;Wing Color]",
			"dropdown[4.5,1.1;3,0.6;drp_eyes;Blue,Purple;1]",
			"label[5.1,0.8;Eye Color]",
			"dropdown[8.5,1.1;3,0.6;drp_body;Light Blue,Sapphire,Slate,White,Silver;1]",
			"label[9.1,0.8;Body Color]",
			"model[1.5,1.7;10,7;mob_mesh;" .. self.mesh .. ";" .. texture .. ";-10,-130;false;false;" .. frame_loop .. ";15]"
		}
	end
	return table.concat(form, "")
end
-----------------
-- Wyvern Form --
-----------------

local function get_wyvern_formspec(self)
	-- Stats
	local health = get_stat(self, "hp", "max_health")
	local hunger = get_stat(self, "hunger", "max_hunger")
	local stamina = get_perc(self.flight_stamina, 900)
	-- Visuals
	local frame_range = self.animations["stand"].range
	local frame_loop = frame_range.x .. "," ..  frame_range.y
	local texture = self:get_props().textures[1]
	local health_ind = "draconis_forms_health_bg.png^[lowpart:" .. health .. ":draconis_forms_health_fg.png"
	local hunger_ind = "draconis_forms_hunger_bg.png^[lowpart:" .. hunger .. ":draconis_forms_hunger_fg.png"
	local stamina_ind = "draconis_forms_stamina_bg.png^[lowpart:" .. stamina .. ":draconis_forms_stamina_fg.png"
	-- Settings
	local fly_allowed = "Flight Allowed"
	local fly_image = "draconis_forms_flight_allowed.png"
	if not self.fly_allowed then
		fly_allowed = "Flight Not Allowed"
		fly_image = "draconis_forms_flight_disallowed.png"
	end
	local form = {
		"formspec_version[4]",
		"size[16,10]",
		--"no_prepend[]",
		"bgcolor[#000000;false]",
		"background[0,0;16,10;draconis_forms_bg_b.png]",
		"label[6.8,0.8;" .. correct_name(self.name) .. "]",
		"button[6.75,8.75;2.6,0.5;btn_dragon_name;" .. (self.nametag or "Set Name") .. "]",
		"model[3,1.7;10,7;mob_mesh;" .. self.mesh .. ";" .. texture .. ";-10,-130;false;false;" .. frame_loop .. ";15]",
		"image[1.1,1.3;1,1;" .. health_ind .."]",
		"image[1.1,3.3;1,1;" .. hunger_ind .."]",
		"image[1.1,5.3;1,1;" .. stamina_ind .."]",
		"tooltip[13.45,7.6;1.9,1.9;" .. correct_name(self.stance) .. "]",
		"image_button[13.45,7.6;1.9,1.9;draconis_forms_dragon_" .. self.stance .. ".png;btn_dragon_stance;;false;false;]",
		"tooltip[13.45,3.9;1.9,1.9;" .. correct_name(self.order) .. "]",
		"image_button[13.45,3.9;1.9,1.9;draconis_forms_dragon_" .. self.order .. ".png;btn_dragon_order;;false;false;]",
		"tooltip[13.45,0.3;1.9,1.9;" .. fly_allowed .. "]",
		"image_button[13.45,0.3;1.9,1.9;" .. fly_image .. ";btn_dragon_fly;;false;false;]"
	}
	return table.concat(form, "")
end

draconis.wyvern_api.show_formspec = function(self, player)
	minetest.show_formspec(player:get_player_name(), "draconis:wyvern_forms", get_wyvern_formspec(self))
	form_objref[player:get_player_name()] = self
end

----------------
-- Get Fields --
----------------

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = player:get_player_name()
	if not form_objref[name] or not form_objref[name].object then
		return
	end
	local ent = form_objref[name]
	if formname == "draconis:dragon_forms" then
		if fields.btn_dragon_stance then
			if not ent.object then return end
			if ent.stance == "neutral" then
				ent.stance = ent:memorize("stance", "aggressive")
			elseif ent.stance == "aggressive" then
				ent.stance = ent:memorize("stance", "passive")
			elseif ent.stance == "passive" then
				ent.stance = ent:memorize("stance", "neutral")
			end
			ent:show_formspec(player)
		end
		if fields.btn_dragon_order then
			if not ent.object then return end
			if ent.order == "wander" then
				ent.order = ent:memorize("order", "follow")
			elseif ent.order == "follow" then
				ent.order = ent:memorize("order", "stay")
			elseif ent.order == "stay" then
				ent.order = ent:memorize("order", "wander")
			else
				ent.order = ent:memorize("order", "stay")
			end
			ent:show_formspec(player)
		end
		if fields.btn_dragon_fly then
			if not ent.object then return end
			if ent.fly_allowed then
				ent.fly_allowed = ent:memorize("fly_allowed", false)
			else
				ent.fly_allowed = ent:memorize("fly_allowed", true)
			end
			ent:show_formspec(player)
		end
		if fields.btn_dragon_name then
			minetest.show_formspec(name, "draconis:set_name", get_rename_formspec(ent))
		end
		if fields.btn_customize then
			minetest.show_formspec(name, "draconis:customize", get_customize_formspec(ent))
		end
		if fields.quit or fields.key_enter then
			form_objref[name] = nil
		end
	end
	if formname == "draconis:wyvern_forms" then
		if fields.btn_dragon_stance then
			if not ent.object then return end
			if ent.stance == "neutral" then
				ent.stance = ent:memorize("stance", "aggressive")
			elseif ent.stance == "aggressive" then
				ent.stance = ent:memorize("stance", "passive")
			elseif ent.stance == "passive" then
				ent.stance = ent:memorize("stance", "neutral")
			end
			ent:show_formspec(player)
		end
		if fields.btn_dragon_order then
			if not ent.object then return end
			if ent.order == "wander" then
				ent.order = ent:memorize("order", "follow")
			elseif ent.order == "follow" then
				ent.order = ent:memorize("order", "stay")
			elseif ent.order == "stay" then
				ent.order = ent:memorize("order", "wander")
			else
				ent.order = ent:memorize("order", "stay")
			end
			ent:show_formspec(player)
		end
		if fields.btn_dragon_fly then
			if not ent.object then return end
			if ent.fly_allowed then
				ent.fly_allowed = ent:memorize("fly_allowed", false)
			else
				ent.fly_allowed = ent:memorize("fly_allowed", true)
			end
			ent:show_formspec(player)
		end
		if fields.btn_dragon_name then
			minetest.show_formspec(name, "draconis:set_name", get_rename_formspec(ent))
		end
		if fields.quit or fields.key_enter then
			form_objref[name] = nil
		end
	end
	if formname == "draconis:set_name" and fields.name then
		if string.len(fields.name) > 64 then
			fields.name = string.sub(fields.name, 1, 64)
		end
		ent.nametag = ent:memorize("nametag", fields.name)
		activate_nametag(form_objref[name])
		if fields.quit or fields.key_enter then
			form_objref[name] = nil
		end
	end
	if formname == "draconis:customize" then
		local type = "ice"
		if ent.name == "draconis:fire_dragon" then
			type = "fire"
		end
		local wings = {
			ice = {
				["Dark Blue"] = "#07084f",
				["Purple"] = "#a724ff"
			},
			fire = {
				["Red"] = "#d20000",
				["Orange"] = "#d92e00",
				["Yellow"] = "#edad00",
				["Purple"] = "#a724ff"
			}
		}
		local eyes = {
			ice = {
				["Blue"] = "blue",
				["Purple"] = "purple"
			},
			fire = {
				["Red"] = "red",
				["Orange"] = "orange",
				["Green"] = "green"
			}
		}
		local body = {
			ice = {
				["Light Blue"] = 1,
				["Sapphire"] = 2,
				["Slate"] = 3,
				["White"] = 4,
				["Silver"] = 5
			},
			fire = {
				["Black"] = 1,
				["Bronze"] = 2,
				["Green"] = 3,
				["Red"] = 4,
				["Gold"] = 5
			}
		}
		if fields.drp_wing
		and wings[type][fields.drp_wing] then
			ent.wing_overlay = "(draconis_wing_fade.png^[multiply:" .. wings[type][fields.drp_wing] .. ")"
			ent:memorize("wing_overlay", ent.wing_overlay)
			draconis.generate_texture(ent, true)
		end
		if fields.drp_eyes
		and eyes[type][fields.drp_eyes] then
			ent.eye_color = eyes[type][fields.drp_eyes]
			ent:memorize("eye_color", ent.eye_color)
		end
		if fields.drp_body
		and body[type][fields.drp_body] then
			ent.texture_no = body[type][fields.drp_body]
			draconis.set_color_string(ent)
			draconis.generate_texture(ent, true)
		end
		ent:update_emission(true)
		minetest.show_formspec(name, "draconis:customize", get_customize_formspec(ent))
		if fields.quit or fields.key_enter then
			form_objref[name] = nil
		end
	end
end)