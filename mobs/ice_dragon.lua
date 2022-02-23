----------------
-- Ice Dragon --
----------------

local creative = minetest.settings:get_bool("creative_mode")

local function is_value_in_table(tbl, val)
    for _, v in pairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

local colors = {"light_blue", "sapphire", "slate", "white", "silver"}

creatura.register_mob("draconis:ice_dragon", {
    -- Stats
    max_health = 1000,
	max_hunger = 500,
    armor_groups = {fleshy = 50},
    damage = 20,
    speed = 24,
	tracking_range = 64,
    despawn_after = false,
	-- Entity Physics
	stepheight = 2.51,
	max_fall = 0,
    -- Visuals
    mesh = "draconis_ice_dragon.b3d",
	hitbox = {
		width = 2.5,
		height = 5
	},
    visual_size = {x = 30, y = 30},
	glow = 12,
	textures = {
		"draconis_ice_dragon_" .. colors[1] .. ".png^draconis_ice_dragon_head_detail.png^draconis_baked_in_shading.png",
		"draconis_ice_dragon_" .. colors[2] .. ".png^draconis_ice_dragon_head_detail.png^draconis_baked_in_shading.png",
		"draconis_ice_dragon_" .. colors[3] .. ".png^draconis_ice_dragon_head_detail.png^draconis_baked_in_shading.png",
		"draconis_ice_dragon_" .. colors[4] .. ".png^draconis_ice_dragon_head_detail.png^draconis_baked_in_shading.png",
		"draconis_ice_dragon_" .. colors[5] .. ".png^draconis_ice_dragon_head_detail.png^draconis_baked_in_shading.png"
	},
	child_textures = {
		"draconis_ice_dragon_" .. colors[1] .. ".png^draconis_baked_in_shading.png",
		"draconis_ice_dragon_" .. colors[2] .. ".png^draconis_baked_in_shading.png",
		"draconis_ice_dragon_" .. colors[3] .. ".png^draconis_baked_in_shading.png",
		"draconis_ice_dragon_" .. colors[4] .. ".png^draconis_baked_in_shading.png",
		"draconis_ice_dragon_" .. colors[5] .. ".png^draconis_baked_in_shading.png"
	},
	animations = {
		stand = {range = {x = 1, y = 60}, speed = 15, frame_blend = 0.3, loop = true},
		stand_fire = {range = {x = 70, y = 130}, speed = 15, frame_blend = 0.3, loop = true},
		punch = {range = {x = 140, y = 180}, speed = 30, frame_blend = 0.3, loop = false},
		wing_beat = {range = {x = 180, y = 220}, speed = 35, frame_blend = 0.3, loop = false},
		walk = {range = {x = 230, y = 260}, speed = 35, frame_blend = 0.3, loop = true},
		walk_fire = {range = {x = 270, y = 300}, speed = 35, frame_blend = 0.3, loop = true},
		sleep = {range = {x = 310, y = 370}, speed = 5, frame_blend = 1, prty = 2, loop = true},
		death = {range = {x = 380, y = 380}, speed = 1, frame_blend = 2, prty = 3, loop = true},
		takeoff = {range = {x = 390, y = 440}, speed = 25, frame_blend = 0.3, loop = true},
		fly_idle = {range = {x = 420, y = 450}, speed = 25, frame_blend = 0.3, loop = true},
		fly_idle_fire = {range = {x = 460, y = 490}, speed = 25, frame_blend = 0.3, loop = true},
		fly = {range = {x = 500, y = 530}, speed = 25, frame_blend = 0.3, loop = true},
		fly_fire = {range = {x = 540, y = 570}, speed = 25, frame_blend = 0.3, loop = true},
		shoulder_idle = {range = {x = 580, y = 620}, speed = 10, frame_blend = 0.6, loop = true}
	},
    -- Misc
	sounds = {
        random = {
			{
				name = "draconis_ice_dragon_random_1",
				gain = 1,
				distance = 64,
				length = 2
			},
			{
				name = "draconis_ice_dragon_random_2",
				gain = 1,
				distance = 64,
				length = 2.5
			},
			{
				name = "draconis_ice_dragon_random_3",
				gain = 1,
				distance = 64,
				length = 4
			}
		}
	},
	child_sounds = {
        random = {
			{
				name = "draconis_ice_dragon_child_1",
				gain = 1,
				distance = 8,
				length = 1
			},
			{
				name = "draconis_ice_dragon_child_2",
				gain = 1,
				distance = 8,
				length = 2
			}
		}
	},
    drops = {}, -- Set in on_activate
    follow = {
		"group:food_meat"
	},
	dynamic_anim_data = {
		yaw_factor = 0.15,
		swing_factor = 0.33,
		pivot_h = 0.5,
		pivot_v = 0.75,
		tail = {
			{ -- Segment 1
				pos = {
					x = 0,
					y = 0,
					z = 0
				},
				rot = {
					x = 180,
					y = 180,
					z = 1
				}
			},
			{ -- Segment 2
				pos = {
					x = 0,
					y = 1.1,
					z = 0
				},
				rot = {
					x = 0,
					y = 0,
					z = 1
				}
			},
			{ -- Segment 3
				pos = {
					x = 0,
					y = 1.3,
					z = 0
				},
				rot = {
					x = 0,
					y = 0,
					z = 1
				}
			}
		},
		head = {
			{ -- Segment 1
				pitch_offset = 20,
				bite_angle = -20,
				pitch_factor = 0.11,
				pos = {
					x = 0,
					y = 0.85,
					z = 0.036
				},
				rot = {
					x = 0,
					y = 0,
					z = 0
				}
			},
			{ -- Segment 2
				pitch_offset = -5,
				bite_angle = 10,
				pitch_factor = 0.33,
				pos = {
					x = 0,
					y = 0.39,
					z = 0
				},
				rot = {
					x = 0,
					y = 0,
					z = 0
				}
			},
			{ -- Head
				pitch_offset = -20,
				bite_angle = 5,
				pitch_factor = 0.44,
				pos = {
					x = 0,
					y = 0.41,
					z = 0
				},
				rot = {
					x = 0,
					y = 0,
					z = 0
				}
			}
		}
	},
    -- Function
	breath_attack = draconis.ice_breath,
	utility_stack = draconis.dragon_behavior,
    activate_func = function(self)
		draconis.activate(self)
    end,
    step_func = function(self, dtime, moveresult)
		draconis.step(self, dtime, moveresult)
    end,
    death_func = function(self)
		self:clear_action()
		self:animate("death")
		self:set_gravity(-9.8)
		local rot = self.object:get_rotation()
		if rot.x ~= 0
		or rot.z ~= 0 then
			self.object:set_rotation({x = 0, y = rot.y, z = 0})
		end
    end,
	on_rightclick = function(self, clicker)
		draconis.rightclick(self, clicker)
	end,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, direction, damage)
		creatura.basic_punch_func(self, puncher, time_from_last_punch, tool_capabilities, direction, damage)
		if not self.is_landed then
			self.flight_stamina = self:memorize("flight_stamina", self.flight_stamina - 10)
		end
		self.alert_timer = self:memorize("alert_timer", 15)
	end,
	deactivate_func = function(self)
		if not draconis.dragons[self.dragon_id] then return end
		local owner = draconis.dragons[self.dragon_id].owner
		if not owner then return end
		if not draconis.bonded_dragons then return end
		if draconis.bonded_dragons[owner]
		and is_value_in_table(draconis.bonded_dragons[owner], self.dragon_id) then
			for i = #draconis.bonded_dragons[owner], 1, -1 do
				if draconis.bonded_dragons[owner][i] == self.dragon_id then
					draconis.bonded_dragons[owner][i] = nil
				end
			end
		end
	end
})

creatura.register_spawn_egg("draconis:ice_dragon", "52c4dc" ,"218bab")

local spawn_egg_def = minetest.registered_items["draconis:spawn_ice_dragon"]

spawn_egg_def.on_place = function(itemstack, _, pointed_thing)
    local mobdef = minetest.registered_entities["draconis:ice_dragon"]
    local spawn_offset = math.abs(mobdef.collisionbox[2])
    local pos = minetest.get_pointed_thing_position(pointed_thing, true)
    pos.y = pos.y + spawn_offset
    draconis.spawn_dragon(pos, "draconis:ice_dragon", false, math.random(5, 100))
    if not creative then
        itemstack:take_item()
        return itemstack
    end
end

minetest.register_craftitem("draconis:spawn_ice_dragon", spawn_egg_def)