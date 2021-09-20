-------------
--- Mount ---
-------------
-- Ver 1.0 --

----------
-- Math --
----------

local abs = math.abs
local atan2 = math.atan2
local sin = math.sin
local cos = math.cos
local deg = math.deg
local function diff(a, b) -- Get difference between 2 angles
    return atan2(sin(b - a), cos(b - a))
end
local function round(x) -- Round to nearest multiple of 0.5
	return x + 0.5 - (x + 0.5) % 1
end

--------------
-- Settings --
--------------

draconis.attached = {}

local dragon_mount_data = {}

local mount_refs = {}

local mesh = "character.b3d"

if minetest.get_modpath("3d_armor") then
    mesh = "3d_armor_character.b3d"
end

local function lerp(a, b, w)
    return a + (b - a) * w
end

minetest.register_entity("draconis:mounted_player_visual", {
    initial_properties = {
        mesh = mesh,
        visual = "mesh",
        collisionbox = {0, 0, 0, 0, 0, 0},
        stepheight = 1,
        physical = true,
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

----------------------
-- Helper Functions --
----------------------

local function clear_hud(name)
	local player = minetest.get_player_by_name(name)
	if player then
		if dragon_mount_data[player:get_player_name()] and
            dragon_mount_data[player:get_player_name()].hud then
            player:hud_set_flags({wielditem = true})
			player:hud_remove(dragon_mount_data[player:get_player_name()]
								  .hud)
			dragon_mount_data[player:get_player_name()].hud = nil
			dragon_mount_data[player:get_player_name()] = nil
		end
	end
end

--------------------
-- Main Functions --
--------------------

local function attach_visual(name, entity)
    local player = minetest.get_player_by_name(name)
    if not player then return end
	if mount_refs[name] ~= nil then return end
	if not entity.dragon_id then return end
    mount_refs[name] = {
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
		nametag = player:get_nametag_attributes().text,
		dragon_id = entity.dragon_id,
        ent = minetest.add_entity(player:get_pos(),
                                  "draconis:mounted_player_visual",
                                  minetest.serialize({player = name})):get_luaentity()
    }
    player:set_properties({
        collisionbox = {-0.4, 0, -0.4, 0.4, 0.45, 0.4},
        visual_size = {x = 0, y = 0, z = 0},
        mesh = mesh,
        textures = {"transparency.png"}
    })
    player:set_nametag_attributes({text = " "})
    mount_refs[name].ent.object:set_attach(entity.object, "Torso.2",
                                           {x = 0, y = 0.75, z = 0.15},
                                           {x = 90, y = 0, z = 180})
    mount_refs[name].ent.object:set_animation({x = 81, y = 160}, 30, 0)
    local visual_size = mount_refs[name].ent.object:get_properties().visual_size
    local ent_visual_size = entity.object:get_properties().visual_size
    mount_refs[name].ent.object:set_properties(
        {
            visual_size = {
                x = visual_size.x / ent_visual_size.x,
                y = visual_size.y / ent_visual_size.y
            },
            pointable = false
        })
end

local function attach(name, entity)
    local player = minetest.get_player_by_name(name)
    if not player then return end
	if player:get_attach() then return end
	if not entity or not entity.object:get_pos() then return end
    dragon_mount_data[name] = {hud = nil}
    entity.driver = mobkit.remember(entity, "driver", name)
    if default.player_attached ~= nil then default.player_attached[name] = true end
    draconis.attached[name] = entity.dragon_id
    player:set_attach(entity.object, "Torso.2", {x = 0, y = 0, z = 0},
                      {x = 0, y = 0, z = 0})
    player:set_eye_offset({
        x = 0,
        y = 60 * entity.growth_scale,
        z = -160 * entity.growth_scale
    }, {x = 0, y = 0, z = 0})
    attach_visual(name, entity)
    player:set_look_horizontal(entity.object:get_yaw() or 0)
    local driver_mount_data = dragon_mount_data[name]
    if not dragon_mount_data.hud then
        player:hud_set_flags({wielditem = false})
        driver_mount_data.hud = player:hud_add(
                                    {
                hud_elem_type = "image",
                position = {x = 0, y = 1},
                text = "draconis_forge_formspec_fire_bg.png^[lowpart:" ..
                    (entity.breath_meter) ..
                    ":draconis_forge_formspec_fire_fg.png",
                scale = {x = 3, y = 3},
                alignment = {x = 1, y = -1},
                offset = {x = 0, y = -5}
            })
    end
end

local function detach_visual(name)
    local player = minetest.get_player_by_name(name)
    if not player then return end
    if not mount_refs[name] then return end
    local props = mount_refs[name]
    player:set_properties({visual_size = {x = 0, y = 0}})
    player:set_eye_offset(props.eye_offset_first, props.eye_offset_third)
    player:set_physics_override({speed = 1, jump = 1, gravity = 1, sneak = true})
    player:set_look_vertical(props.vertical)
    player:set_look_horizontal(props.horizontal)
    player:set_properties({
        collisionbox = props.collision,
        mesh = props.mesh,
        textures = props.textures,
        visual_size = props.visual_size
    })
    mount_refs[name] = nil
    draconis.attached[name] = nil
    minetest.after(0.6, function()
        player:set_nametag_attributes({text = props.nametag})
        player:set_properties({visual_size = {x = 1, y = 1}})
        props.ent.object:set_detach()
        props.ent.object:remove()
    end)
end

local function detach(name)
    local player = minetest.get_player_by_name(name)
    if not player then return end
    if player:get_attach() then
        local parent = player:get_attach()
        local ent = parent:get_luaentity()
        if ent
        and ent.driver
        and ent.driver == player then
            ent.driver = nil
            mobkit.clear_queue_high(ent)
            ent.status = mobkit.remember(ent, "status", "")
        end
        player:set_detach()
    end
    clear_hud(name)
    detach_visual(name)
    player:set_properties({visual_size = {x = 1, y = 1}, pointable = true})
    default.player_set_animation(player, "stand", 30)
    default.player_attached[name] = false
    local pos = player:get_pos()
    minetest.after(0.1, function() player:set_pos(pos) end)
end

function draconis.mount(self, clicker)
    if not self.driver and self.child == false then
        draconis.detach(clicker)
        mobkit.clear_queue_high(self)
        self.status = mobkit.remember(self, "status", "ridden")
        draconis.attach(self, clicker)
        return false
    else
        return true
    end
end

function draconis.attach(entity, player)
    if not player
    or not player:get_player_name() then return end
    local name = player:get_player_name()
    if not default.player_attached[name] then
        minetest.after(0, function() attach(name, entity) end)
    end
end

function draconis.detach(player)
    if not player
    or not player:get_player_name() then return end
    local name = player:get_player_name()
    if default.player_attached[name] then
        minetest.after(0, function() detach(name) end)
    end
end

function draconis.reattach(self)
    if self.driver and minetest.get_player_by_name(self.driver) then
        local driver = minetest.get_player_by_name(self.driver)
        local pos = self.object:get_pos()
        draconis.detach(driver)
        if self.owner
        and pos then
            draconis.dragons[self.dragon_id] = {owner = self.owner, last_pos = pos}
        end
        draconis.load_dragon(draconis.attached[self.driver])
        minetest.after(4, function()
            driver:set_pos(pos)
        end)
    end
end

---------------------------
-- Attachment Management --
---------------------------

minetest.register_on_leaveplayer(function(player)
	minetest.after(0, clear_hud, player:get_player_name())
    draconis.detach(player)
end)

minetest.register_on_shutdown(function()
    local players = minetest.get_connected_players()
    for i = 1, #players do
		minetest.after(0, clear_hud, players[i]:get_player_name())
        draconis.detach(players[i])
    end
end)

minetest.register_on_dieplayer(function(player)
	minetest.after(0, clear_hud, player:get_player_name())
    draconis.detach(player)
    return true
end)

function draconis.hq_mount_logic(self, prty)
    local jump_meter = 0
    local tvel = 0
    local last_pos = {}
    local mount_state = "ground"
    local anim = "stand"
    local timer = 0.25
    local view_point = 3
    local view_pressed = false
    local safe_pos = self.object:get_pos()
    local eye_offset = {
        x = 0,
        y = 60 * self.growth_scale,
        z = -160 * self.growth_scale
    }
    local func = function(self)
        if not (self.driver) then
            return true
        elseif self.driver
        and (not minetest.get_player_by_name(self.driver)
        or not minetest.get_player_by_name(self.driver):get_attach()) then
            if minetest.get_player_by_name(self.driver) then
                draconis.detach(minetest.get_player_by_name(self.driver))
            end
            self.driver = nil
            mobkit.forget(self, "driver")
            return true
        end

        local y = 0
        local pos = self.object:get_pos()
        local driver = minetest.get_player_by_name(self.driver)

        local look_dir = driver:get_look_dir()

        local ping = vector.distance(pos, driver:get_pos())

        if vector.distance(pos, safe_pos) > 32
        and vector.distance(pos, safe_pos) > ping then
            self.object:set_pos(safe_pos)
        else
            safe_pos = pos
        end

        if timer <= 0 then
            last_pos = pos
            timer = 0.1
        end

        local ctrl = driver:get_player_control()
        local tyaw = driver:get_look_horizontal() or 0
        local yaw = self.object:get_yaw()
        local rot = self.object:get_rotation()
        local cur_vel = self.object:get_velocity()
        local look_to = minetest.dir_to_yaw(driver:get_look_dir())
        self:move_head(look_to, look_dir.y)

        if cur_vel.y < -24 then
            cur_vel.y = -24 -- stops front flips
        end

        local pitch = rot.x + ((cur_vel.y * 0.041) - rot.x) * 0.25

		self.object:set_rotation({x = pitch, y = rot.y, z = rot.z})

        if ctrl.RMB then
            draconis.play_sound(self, "random")
        end

		if mount_state == "ground" then
            if self.isonground then
                self.object:set_yaw(yaw)
            end
		else
			mob_core.tilt_to_yaw(self, tyaw, 2)
		end

        if dragon_mount_data[driver:get_player_name()] and dragon_mount_data[driver:get_player_name()].hud then
		    local hud = dragon_mount_data[driver:get_player_name()].hud
            local meter_percentage = (self.breath_meter / self.breath_meter_max) * 100
            driver:hud_change(hud, "text", "draconis_forge_formspec_fire_bg.png^[lowpart:" .. meter_percentage .. ":draconis_forge_formspec_fire_fg.png")
        end

        if ctrl.left and ctrl.right then
			if not view_pressed then
				local mount_ref = mount_refs[driver:get_player_name()]
                if view_point == 3 then
                    view_point = 1
                    mount_ref.ent.object:set_properties(
						{textures = {"transparency.png"}
                    })
                    driver:set_eye_offset({
                        x = 0,
                        y = 82 * self.growth_scale,
                        z = 1 * self.growth_scale
                    }, {x = 0, y = 0, z = 0})
                    driver:hud_set_flags({wielditem = true})
                    view_pressed = true
                    eye_offset = {
                        x = 0,
                        y = 82 * self.growth_scale,
                        z = 1 * self.growth_scale
                    }
                    return
                end
                if view_point == 1 then
                    view_point = 2
                    mount_ref.ent.object:set_properties({
                        textures = mount_ref.textures
                    })
                    driver:set_eye_offset({
                        x = 45 * self.growth_scale,
                        y = 80 * self.growth_scale,
                        z = -110 * self.growth_scale
                    }, {x = 0, y = 0, z = 0})
                    driver:hud_set_flags({wielditem = false})
                    view_pressed = true
                    eye_offset = {
                        x = 45 * self.growth_scale,
                        y = 80 * self.growth_scale,
                        z = -110 * self.growth_scale
                    }
                    return
                end
                if view_point == 2 then
                    view_point = 3
                    mount_ref.ent.object:set_properties({
                        textures = mount_ref.textures
                    })
                    driver:set_eye_offset({
                        x = 0,
                        y = 80 * self.growth_scale,
                        z = -160 * self.growth_scale
                    }, {x = 0, y = 0, z = 0})
                    driver:hud_set_flags({wielditem = false})
                    view_pressed = true
                    eye_offset = {
                        x = 0,
                        y = 80 * self.growth_scale,
                        z = -160 * self.growth_scale
                    }
                    return
                end
            end
        else
            view_pressed = false
        end

        if mount_state == "ground" then

            -- Move Forward
            if ctrl.up then
                tvel = lerp(tvel, 13, 0.1)
                mobkit.turn2yaw(self, tyaw, 4)
            else
                anim = "stand"
            end

            -- Jump
            if ctrl.jump then
                if self.isonground then
                    y = (self.jump_height) + 4
                end
                jump_meter = jump_meter + self.dtime
                if jump_meter > 0.5 then -- Takeoff
                    self.object:add_velocity({x = 0, y = 12, z =0})
                    mount_state = "flight"
                end
            else
                jump_meter = 0
                y = cur_vel.y
            end

			if ctrl.LMB then
                local from = pos
                from.y = from.y + (self.height + (6 * self.growth_scale))
				local pointed_at = vector.add(from, vector.multiply(look_dir, 64))
                pointed_at.y = pointed_at.y + 2
                if self.name == "draconis:fire_dragon" then
                    draconis.fire_breath(self, pointed_at, self.view_range)
                elseif self.name == "draconis:ice_dragon" then
                    draconis.ice_breath(self, pointed_at, self.view_range)
                end
            end

            if round(tvel) > 0 then
                anim = "walk"
            end
        end

        if mount_state == "flight" then

            if self.isinliquid then
                mount_state = "ground"
                return
            end

            self.object:set_acceleration({x = 0, y = 0, z = 0})

            if ctrl.up then
                tvel = lerp(tvel, 32, 0.1)
                y = look_dir.y * 24
            elseif ctrl.jump then
                y = 14
            elseif ctrl.down then
                y = -14
                pos.y = pos.y - 1
                timer = timer - self.dtime
                if timer <= 0 and last_pos and last_pos.y == pos.y then
                    mount_state = "ground"
                end
            end

            -- Stand

			if ctrl.LMB then
                local from = pos
                from.y = from.y + (self.height + (6 * self.growth_scale))
				local pointed_at = vector.add(from, vector.multiply(look_dir, 64))
                pointed_at.y = pointed_at.y + 2
                if self.name == "draconis:fire_dragon" then
                    draconis.fire_breath(self, pointed_at, self.view_range)
                elseif self.name == "draconis:ice_dragon" then
                    draconis.ice_breath(self, pointed_at, self.view_range)
                end
            end

            if round(tvel) <= 0.5 then
                anim = "fly_idle"
            else
                anim = "fly"
            end
        end

        if ctrl.LMB then
            anim = anim .. "_fire"
        end
        draconis.animate(self, anim)
        anim = nil

        -- Velocity Control

        if mount_state == "flight"
        and (not ctrl.up
        and not ctrl.jump
        and not ctrl.down) then
            y = 0
        end

        if tvel ~= 0
        and not ctrl.up then
            tvel = lerp(tvel, 0, 0.1)
        end

        if round(tvel) > 0 then
            tvel = tvel - (ping * 0.5)
        end

        local vel = vector.multiply(minetest.yaw_to_dir(yaw), tvel)
        vel.y = y

        local yaw_diff = diff(yaw, self._tyaw)

        if view_point ~= 1 then
            yaw_diff = 0
        end

        if mount_state == "flight"
        and abs(yaw_diff) > math.pi then
            draconis.set_velocity(self, vel)
        else
            self.object:set_velocity(vel)
        end

        driver:set_eye_offset({
            x = eye_offset.x + deg(rot.z * self.growth_scale),
            y = eye_offset.y - abs(deg(rot.z * self.growth_scale)),
            z = eye_offset.z - ((deg(rot.x * self.growth_scale) - abs(deg(rot.z * self.growth_scale))) - (abs(deg(yaw_diff)) * 0.33)),
        }, {x = 0, y = 0, z = 0})

        if ctrl.sneak then
            draconis.attached[self.driver] = nil
            self.driver = mobkit.forget(self, "driver")
            draconis.detach(driver)
            return true
        end
    end
    mobkit.queue_high(self, func, prty)
end