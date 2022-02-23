---------------
-- Mount API --
---------------

draconis.mounted_player_data = {}

local abs = math.abs

-------------------
-- Player Visual --
-------------------

minetest.register_entity("draconis:mounted_player_visual", {
    initial_properties = {
        mesh = "character.b3d",
        visual = "mesh",
        collisionbox = {0, 0, 0, 0, 1, 0},
        stepheight = 0,
        physical = false,
        collide_with_objects = false
    },
    on_activate = function(self, static)
        static = minetest.deserialize(static) or {}

        if not static.player then
            self.object:remove()
            return
        end

        self.player = static.player
        local player = minetest.get_player_by_name(self.player)

        if not player then
            self.object:remove()
            return
        end

        self.object:set_properties({
            textures = player:get_properties().textures,
            nametag = self.player
        })
        self.object:set_armor_groups({immortal = 1})
        self.object:set_yaw(player:get_look_horizontal())
    end,
    get_staticdata = function() return "" end,
    on_punch = function(self)
        minetest.after(0, function() draconis.detach(self.player) end)
        self.object:remove()
    end,
    on_step = function(self) self.object:set_velocity(vector.new()) end
})

function draconis.set_fake_player(self, player)
    if not player
    or not player:get_look_horizontal()
    or not player:is_player() then
        return
    end
    local player_name = player:get_player_name()
    if draconis.mounted_player_data[player_name]
    and draconis.mounted_player_data[player_name].fake_player
    and draconis.mounted_player_data[player_name].fake_player:get_pos() then
        draconis.unset_fake_player(player)
        return
    end
    local player_pos = player:get_pos()
    local fake_player = minetest.add_entity(
        player_pos,
        "draconis:mounted_player_visual",
        minetest.serialize({player = player_name})
    )
    -- Cache Player Data
    draconis.mounted_player_data[player_name] = {
        collision = table.copy(player:get_properties().collisionbox),
        textures = table.copy(player:get_properties().textures),
        visual_size = table.copy(player:get_properties().visual_size),
        mesh = player:get_properties().mesh,
        eye_offset_first = player:get_eye_offset().offset_first,
        eye_offset_third = player:get_eye_offset().offset_third,
        vertical = player:get_look_vertical(),
        horizontal = player:get_look_horizontal(),
        inventory = player:get_inventory():get_lists(),
        formspec = player:get_inventory_formspec(),
        hotbar = player:hud_get_hotbar_itemcount(),
		nametag = player:get_nametag_attributes(),
		dragon = self,
        fake_player = fake_player
    }
    -- Set Players Data
    player:set_properties({
        visual_size = {x = 0, y = 0, z = 0},
        textures = {}
    })
    player:set_nametag_attributes({text = " "})
    -- Attach Fake Player
    fake_player:set_attach(self.object, "Torso.2", {x = 0, y = 0.75, z = 0.075}, {x = 90, y = 0, z = 180})
    fake_player:set_animation({x = 81, y = 160}, 30, 0)
    local player_size = fake_player:get_properties().visual_size
    local dragon_size = self.object:get_properties().visual_size
    fake_player:set_properties({
        visual_size = {
            x = player_size.x / dragon_size.x,
            y = player_size.y / dragon_size.y
        },
        mesh = draconis.mounted_player_data[player_name].mesh,
        pointable = false
    })
end

function draconis.unset_fake_player(player)
    if not player
    or not player:get_look_horizontal()
    or not player:is_player() then
        return
    end
    local player_name = player:get_player_name()
    if not draconis.mounted_player_data[player_name]
    or not draconis.mounted_player_data[player_name].fake_player
    or not draconis.mounted_player_data[player_name].fake_player:get_pos() then
        return
    end
    -- Cache Player Data
    local data = draconis.mounted_player_data[player_name]
    local fake_player = data.fake_player
    -- Set Players Data
    player:set_properties({
        visual_size = data.visual_size,
        textures = data.textures
    })
    player:set_nametag_attributes(data.nametag)
    player:set_eye_offset(data.eye_offset_first, data.eye_offset_third)
    -- Unset Data
    draconis.mounted_player_data[player_name] = nil
    -- Remove Fake Player
    fake_player:remove()
end

----------------
-- Attachment --
----------------

local function set_hud(player, def)
    local hud = {
        hud_elem_type = "image",
        position = def.position,
        text = def.text,
        scale = {x = 3, y = 3},
        alignment = {x = 1, y = -1},
        offset = {x = 0, y = -5}
    }
    return player:hud_add(hud)
end

function draconis.attach_player(self, player)
    if not player
    or not player:get_look_horizontal()
    or not player:is_player() then
        return
    end
    local scale = self.growth_scale
    -- Attach Player
    player:set_attach(self.object, "Torso.2", {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
    -- Set Players Eye Offset
    player:set_eye_offset({
        x = 0,
        y = 60 * scale,
        z = -160 * scale
    }, {x = 0, y = 0, z = 0}) -- 3rd person eye offset is limited to 15 on each axis (Fix this, devs.)
    player:set_look_horizontal(self.object:get_yaw() or 0)
    -- Set Fake Player (Using a fake player and changing 1st person eye offset works around the above issue)
    draconis.set_fake_player(self, player)
    -- Set Dragon Data
    self.rider = player
    -- Set HUD
    local data = draconis.mounted_player_data[player:get_player_name()]
    if not data.huds then
        local health = self.hp / math.ceil(self.max_health * self.growth_scale) * 100
        local hunger = self.hunger / math.ceil(self.max_hunger * self.growth_scale) * 100
        local stamina = self.flight_stamina / 900 * 100
        local breath = self.attack_stamina / 100 * 100
        player:hud_set_flags({wielditem = false})
        draconis.mounted_player_data[player:get_player_name()].huds = {
            ["health"] = set_hud(player, {
                text = "draconis_forms_health_bg.png^[lowpart:" .. health .. ":draconis_forms_health_fg.png",
                position = {x = 0, y = 0.7}
            }),
            ["hunger"] = set_hud(player, {
                text = "draconis_forms_hunger_bg.png^[lowpart:" .. hunger .. ":draconis_forms_hunger_fg.png",
                position = {x = 0, y = 0.8}
            }),
            ["stamina"] = set_hud(player, {
                text = "draconis_forms_stamina_bg.png^[lowpart:" .. stamina .. ":draconis_forms_stamina_fg.png",
                position = {x = 0, y = 0.9}
            }),
            ["breath"] = set_hud(player, {
                text = "draconis_forms_breath_bg.png^[lowpart:" .. breath .. ":draconis_forms_breath_fg.png",
                position = {x = 0, y = 1}
            })
        }
    end
end

function draconis.detach_player(self, player)
    if not player
    or not player:get_look_horizontal()
    or not player:is_player() then
        return
    end
    local player_name = player:get_player_name()
    local data = draconis.mounted_player_data[player_name]
    -- Attach Player
    player:set_detach()
    -- Set HUD
    player:hud_set_flags({wielditem = true})
    player:hud_remove(data.huds["health"])
    player:hud_remove(data.huds["hunger"])
    player:hud_remove(data.huds["stamina"])
    player:hud_remove(data.huds["breath"])
    -- Set Fake Player (Using a fake player and changing 1st person eye offset works around the above issue)
    draconis.unset_fake_player(player)
    -- Set Dragon Data
    self.rider = nil
end

--------------
-- Settings --
--------------

local function menu_form()
    local formspec = {
        "size[6,3.476]",
        "real_coordinates[true]",
        "button[0.25,1.3;2.3,0.8;btn_view_point;Change View Point]",
        --"button[2.25,1.3;1.6,0.8;btn_pitch_fly;Crystal Bond]",
        "button[3.5,1.3;2.3,0.8;btn_pitch_toggle;Toggle Pitch Flight]",
    }
    return table.concat(formspec, "")
end

minetest.register_chatcommand("dragon_mount_settings", {
    privs = {
        interact = true,
    },
    func = function(name)
        minetest.show_formspec(name, "draconis:dragon_mount_settings", menu_form())
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    if formname == "draconis:dragon_mount_settings" then
        if fields.btn_view_point then
            draconis.aux_key_setting[name] = "pov"
            minetest.chat_send_player(name, "Sprint key now changes point of view")
        end
        if fields.btn_pitch_toggle then
            draconis.aux_key_setting[name] = "vert_method"
            minetest.chat_send_player(name, "Sprint key now changes vertical movement method")
        end
    end
end)

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    if not draconis.aux_key_setting[name] then
        draconis.aux_key_setting[name] = "pov"
    end
end)

-------------------
-- Data Handling --
-------------------

minetest.register_on_leaveplayer(function(player)
    draconis.unset_fake_player(player)
end)

--------------
-- Behavior --
--------------

creatura.register_utility("draconis:mount", function(self)
    local is_landed = true
    local jump_held = 0
    local view_held = false
    local view_point = 3
    --local initial_age = self.age
    self:halt()
    local func = function(self)
        local player = self.rider
        if not player
        or not player:get_look_horizontal() then
            return true
        end

        local player_name = player:get_player_name()
        local control = player:get_player_control()

        local look_dir = player:get_look_dir()
        local look_yaw = minetest.dir_to_yaw(look_dir)

        local rot = self.object:get_rotation()
        local scale = self.growth_scale
        local player_data = draconis.mounted_player_data[player_name]

        if not player_data then return true end

        --[[if self.age ~= initial_age then
            local fake_props = player_data.fake_player:get_properties()
            local dragon_size = self.object:get_properties().visual_size
            fake_props.visual_size = {
                x = fake_props.visual_size.x / dragon_size.x,
                y = fake_props.visual_size.y / dragon_size.y
            }
            player_data.fake_player:set_properties(fake_props)
        end]]

        local health = self.hp / math.ceil(self.max_health * self.growth_scale) * 100
        local hunger = self.hunger / math.ceil(self.max_hunger * self.growth_scale) * 100
        local stamina = self.flight_stamina / 900 * 100
        local breath = self.attack_stamina / 100 * 100
        local hud_data = player_data.huds
        if hud_data["health"] then
            player:hud_change(
                player_data.huds["health"],
                "text",
                "draconis_forms_health_bg.png^[lowpart:" .. health .. ":draconis_forms_health_fg.png"
            )
        end
        if hud_data["hunger"] then
            player:hud_change(
                player_data.huds["hunger"],
                "text",
                "draconis_forms_hunger_bg.png^[lowpart:" .. hunger .. ":draconis_forms_hunger_fg.png"
            )
        end
        if hud_data["stamina"] then
            player:hud_change(
                player_data.huds["stamina"],
                "text",
                "draconis_forms_stamina_bg.png^[lowpart:" .. stamina .. ":draconis_forms_stamina_fg.png"
            )
        end
        if hud_data["breath"] then
            player:hud_change(
                player_data.huds["breath"],
                "text",
                "draconis_forms_breath_bg.png^[lowpart:" .. breath .. ":draconis_forms_breath_fg.png"
            )
        end

        draconis.mounted_player_data[player_name].huds = player_data.huds

        local player_props = player:get_properties()

        if player_props.visual_size.x ~= 0 then
            player:set_properties({
                visual_size = {x = 0, y = 0, z = 0},
                textures = {}
            })
        end

        if control.aux1 then
            if draconis.aux_key_setting[player_name] == "pov" then
                if not view_held then
                    if view_point == 3 then
                        view_point = 1
                        player_data.fake_player:set_properties({
                            textures = {}
                        })
                        player:set_eye_offset({
                            x = 0,
                            y = 82 * scale,
                            z = 1 * scale
                        }, {x = 0, y = 0, z = 0})
                        player:hud_set_flags({wielditem = true})
                    elseif view_point == 1 then
                        view_point = 2
                        player_data.fake_player:set_properties({
                            textures = player_data.textures
                        })
                        player:set_eye_offset({
                            x = 45 * scale,
                            y = 80 * scale,
                            z = -110 * scale
                        }, {x = 0, y = 0, z = 0})
                        player:hud_set_flags({wielditem = false})
                    elseif view_point == 2 then
                        view_point = 3
                        player_data.fake_player:set_properties({
                            textures = player_data.textures
                        })
                        player:set_eye_offset({
                            x = 0,
                            y = 80 * scale,
                            z = -160 * scale
                        }, {x = 0, y = 0, z = 0})
                        player:hud_set_flags({wielditem = false})
                    end
                    view_held = true
                end
            else
                view_held = true
                if self.pitch_fly then
                    self.pitch_fly = self:memorize("pitch_fly", false)
                else
                    self.pitch_fly = self:memorize("pitch_fly", true)
                end
            end
        else
            view_held = false
        end

        local anim

        if is_landed then
            self:set_gravity(-9.8)
            anim = "stand"
            if control.up then
                self:set_forward_velocity(12)
                self:turn_to(look_yaw, 4)
                anim = "walk"
            end

            if control.jump then
                if self.touching_ground then
                    self.object:add_velocity({x = 0, y = 4, z =0})
                end
                jump_held = jump_held + self.dtime
                if jump_held > 0.5 then
                    self.object:add_velocity({x = 0, y = 12, z =0})
                    is_landed = false
                end
            else
                jump_held = 0
            end
        else
            self:set_gravity(0)
            anim = "fly_idle"
            if control.up then
                if self.pitch_fly then
                    self:set_vertical_velocity(12 * look_dir.y)
                end
                self:set_forward_velocity(24)
                self:tilt_to(look_yaw, 5)
                rot = self.object:get_rotation()
                local vel = self.object:get_velocity()
                local pitch = rot.x + ((vel.y * 0.041) - rot.x) * 0.25
                self.object:set_rotation({x = pitch, y = rot.y, z = rot.z})
                anim = "fly"
            else
                local vel_len = vector.length(self.object:get_velocity())
                if abs(vel_len) < 0.5 then
                    vel_len = 0
                end
                if abs(rot.z) > 0.01 then
                    self:tilt_to(look_yaw, 5)
                end
                if abs(rot.x) > 0.01 then
                    rot = self.object:get_rotation()
                    local vel = self.object:get_velocity()
                    local pitch = rot.x + ((vel.y * 0.041) - rot.x) * 0.25
                    self.object:set_rotation({x = pitch, y = rot.y, z = rot.z})
                end
                self:set_vertical_velocity(0)
                self:set_forward_velocity(vel_len * 0.5)
            end

            if not self.pitch_fly then
                if control.jump then
                    self:set_vertical_velocity(12)
                elseif control.down then
                    self:set_vertical_velocity(-12)
                else
                    self:set_vertical_velocity(0)
                end
            end


            if self.touching_ground then
                is_landed = true
            end
        end

        if control.RMB then
            local start = self.object:get_pos()
            local offset = player:get_eye_offset()
            local eye_correction = vector.multiply({x = look_dir.x, y = 0, z= look_dir.z}, offset.z * 0.125)
            start = vector.add(start, eye_correction)
            start.y = start.y + (offset.y * 0.125)
            local tpos = vector.add(start, vector.multiply(look_dir, 64))
            local head_dir = vector.direction(start, tpos)
            look_dir.y = head_dir.y
            self:breath_attack(tpos)
            anim = anim .. "_fire"
        end

        self:move_head(look_yaw, look_dir.y)

        if anim then
            self:animate(anim)
        end

        if control.sneak
        or player:get_player_name() ~= self.owner then
            draconis.detach_player(self, player)
            return true
        end
    end
    self:set_utility(func)
end)
