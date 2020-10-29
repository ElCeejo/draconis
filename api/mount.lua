-------------
--- Mount ---
-------------
-- Ver 1.0 --

local dragon_mount_data = {}

local mount_refs = {}

local mesh = "character.b3d"

if minetest.get_modpath("3d_armor") then
    mesh = "3d_armor_character.b3d"
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
    get_staticdata = function(self) return "" end,
    on_punch = function(self)
        minetest.after(0, function() draconis.detach(self.player) end)
        self.object:remove()
    end,
    on_step = function(self) self.object:set_velocity(vector.new()) end
})

----------------------
-- Helper Functions --
----------------------

local function get_dragon_by_id(id)
    for _, ent in pairs(minetest.luaentities) do
        if ent.dragon_id
        and ent.dragon_id == id then
            return ent.object
        end
    end
end

local function clear_hud(name)
	local player = minetest.get_player_by_name(name)
	if player then
		if dragon_mount_data[player:get_player_name()] and
			dragon_mount_data[player:get_player_name()].hud then
			player:hud_remove(dragon_mount_data[player:get_player_name()]
								  .hud)
			dragon_mount_data[player:get_player_name()].hud = nil
			dragon_mount_data[player:get_player_name()] = nil
		end
	end
end

local force_loaded = {}

local function forceload_area(pos)
    local pos1 = vector.new(pos.x - 2, pos.y - 2, pos.z - 2)
    local pos2 = vector.new(pos.x + 2, pos.y + 2, pos.z + 2)
    for x = pos1.x, pos2.x do
        for y = pos1.y, pos2.y do
            for z = pos1.z, pos2.z do
                local ipos = vector.new(x, y, z)
                minetest.forceload_block(ipos, true)
                table.insert(force_loaded, ipos)
            end
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
    entity.driver = player
    if default.player_attached ~= nil then default.player_attached[name] = true end
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
        if ent.driver
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

function draconis.attach(object, player)
    local name = player:get_player_name()
    if not default.player_attached[name] then
        minetest.after(0, function() attach(name, object) end)
    end
end

function draconis.detach(player)
    local name = player:get_player_name()
    if default.player_attached[name] then
        minetest.after(0, function() detach(name) end)
    end
end

---------------------------
-- Attachment Management --
---------------------------

local function reattach(name, dtime)
    local player = minetest.get_player_by_name(name)
    local fail_timer = 3
	if mount_refs[name]
    and mount_refs[name].dragon_id then
        for _, ent in pairs(minetest.luaentities) do
            if ent.dragon_id
            and ent.dragon_id == id then
                local dragon = ent.object
                if not player:get_attach() then
                    fail_timer = fail_timer - dtime
                    local last_pos = draconis.bonded_dragons[name].last_pos
                    local pos = {x=math.floor(last_pos.x), y=math.floor(last_pos.y), z=math.floor(last_pos.z)}
                    draconis.forceload(pos)
                    if fail_timer <= 0
                    or ent.hp <= 0 then
                        minetest.after(0, function() detach(name) end)
                        return
                    end
                    if dragon then
                        player:set_pos(last_pos)
                        minetest.after(0, function() attach(name, dragon:get_luaentity()) end)
                    end
                else
                    if dragon
                    and dragon:get_pos() then
                        player:set_pos(dragon:get_pos())
                    end
                end
                if dragon
                and dragon:get_pos()
                and not mount_refs[name].ent.object
                or not mount_refs[name].ent.object:get_pos() then
                    attach_visual(name, dragon:get_luaentity())
                end
            end
        end
    end
end

local fl_timer = 2

minetest.register_globalstep(function(dtime)
	for _,plyr in ipairs(minetest.get_connected_players()) do
		local name = plyr:get_player_name()
		reattach(name, dtime)
    end
    fl_timer = fl_timer - dtime
    if fl_timer <= 0 then
        if #force_loaded < 1 then
            for i = 1, #force_loaded do
                minetest.forceload_free_block(force_loaded[i], true)
                table.remove(force_loaded, i)
            end
        end
        fl_timer = 2
    end
end)

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



local function round(x) -- Round number up
	return x + 0.5 - (x + 0.5) % 1
end


function draconis.hq_mount_logic(self, prty)
    local base_speed = minetest.registered_entities[self.name].mount_speed
    local sprint_speed = minetest.registered_entities[self.name].mount_speed_sprint
    local y = 0
    local tvel = 0
    local jump_meter = 0
    local last_pos = {}
    local mount_state = "ground"
    local anim = "stand"
    local timer = 0.25
    local view_point = 3
    local view_pressed = false
    local force_timer = 4
    local init_yaw = 0

    local set_vel = {}
    local func = function(self)
        if not self.driver then return true end
        local pos = mobkit.get_stand_pos(self)
        

        if timer <= 0 then
            last_pos = pos
            timer = 0.25
        end

        local ctrl = self.driver:get_player_control()
        local tyaw = self.driver:get_look_horizontal() or 0
        local yaw = self.object:get_yaw()
        local cur_vel = self.object:get_velocity()

        if math.abs(tyaw - yaw) > 0.1 then self.object:set_yaw(tyaw) end
        local vel = vector.multiply(minetest.yaw_to_dir(yaw), tvel)
        vel.y = y

        self.object:set_velocity(vel)

        if dragon_mount_data[self.driver:get_player_name()]
        and dragon_mount_data[self.driver:get_player_name()].hud then
		    local hud = dragon_mount_data[self.driver:get_player_name()].hud
            self.driver:hud_change(hud, "text", "draconis_forge_formspec_fire_bg.png^[lowpart:" ..
            (self.breath_meter/self.breath_meter_max*100) ..
            ":draconis_forge_formspec_fire_fg.png")
        end

        if ctrl.left and ctrl.right then
			if not view_pressed then
				local mount_ref = mount_refs[self.driver:get_player_name()]
                if view_point == 3 then
                    view_point = 1
                    self.driver:set_eye_offset({
                        x = 0,
                        y = 42 * self.growth_scale,
                        z = 1 * self.growth_scale
                    }, {x = 0, y = 0, z = 0})
                    mount_ref.ent.object:set_properties(
						{textures = {"transparency.png"}
					})
                    view_pressed = true
                    return
                end
                if view_point == 1 then
                    view_point = 2
                    self.driver:set_eye_offset({
                        x = 45 * self.growth_scale,
                        y = 60 * self.growth_scale,
                        z = -110 * self.growth_scale
                    }, {x = 0, y = 0, z = 0})
                    mount_ref.ent.object:set_properties({
                        textures = mount_ref.textures
                    })
                    view_pressed = true
                    return
                end
                if view_point == 2 then
                    view_point = 3
                    self.driver:set_eye_offset({
                        x = 0,
                        y = 60 * self.growth_scale,
                        z = -160 * self.growth_scale
                    }, {x = 0, y = 0, z = 0})
					mount_ref.ent.object:set_properties({
						textures = mount_ref.textures
					})
                    view_pressed = true
                    return
                end
            end
        else
            view_pressed = false
        end

        if mount_state == "ground" then

            -- Move Forward
            if ctrl.up then
                if ctrl.aux1 then
                    tvel = sprint_speed/3
                else
                    tvel = base_speed/3
                end
            else
                if ctrl.LMB then
                    anim = "stand_fire"
                else
                    anim = "stand"
                end
            end

            -- Jump
            if ctrl.jump then
                if self.isonground then
                    y = (self.jump_height) + 4
                end
                jump_meter = jump_meter + self.dtime
                if jump_meter > 0.5 then -- Takeoff
                    y = 6
                    mount_state = "flight"
                end
            else
                jump_meter = 0
                y = cur_vel.y
            end

			if ctrl.LMB then
				local pointed_at = vector.add(self.driver:get_pos(), vector.multiply(self.driver:get_look_dir(), 64))
                if self.name == "draconis:fire_dragon" then
                    draconis.fire_breath(self, pointed_at, self.view_range)
                elseif self.name == "draconis:ice_dragon" then
                    draconis.ice_breath(self, pointed_at, self.view_range)
                end
            end

            if tvel > 0 then
                if ctrl.LMB then
                    anim = "walk_fire"
                else
                    anim = "walk"
                end
            end
        end

        if mount_state == "flight" then

            force_timer = force_timer - self.dtime

            if force_timer <= 0 then
                forceload_area(self.object:get_pos())
                force_timer = 4
            end

            if ctrl.up then
                if ctrl.aux1 then
                    tvel = sprint_speed
                else
                    tvel = base_speed
                end
            end

            -- Height Control

            if ctrl.down then
                if ctrl.aux1 then
                    y = -sprint_speed
                else
                    y = -base_speed
                end
                pos.y = pos.y - 1
                timer = timer - self.dtime
                if timer <= 0 and last_pos and last_pos.y == pos.y then
                    mount_state = "ground"
                end
            elseif ctrl.jump then
                if ctrl.aux1 then
                    y = sprint_speed
                else
                    y = base_speed
                end
            elseif not ctrl.jump and not ctrl.down then
                y = 0
            end

            if self.object:get_acceleration().y < 0 then
                self.object:set_acceleration({x = 0, y = 0, z = 0}) -- Defy Gravity
            end

            -- stand

			if ctrl.LMB then
				local pointed_at = vector.add(self.driver:get_pos(), vector.multiply(self.driver:get_look_dir(), 64))
                if self.name == "draconis:fire_dragon" then
                    draconis.fire_breath(self, pointed_at, self.view_range)
                elseif self.name == "draconis:ice_dragon" then
                    draconis.ice_breath(self, pointed_at, self.view_range)
                end
            end

            if tvel == 0 then
                if ctrl.LMB then
                    anim = "fly_idle_fire"
                else
                    anim = "fly_idle"
                end
            else
                if ctrl.LMB then
                    anim = "fly_fire"
                else
                    anim = "fly"
                end
            end
        end

        mobkit.animate(self, anim)

        -- Velocity Control

        if tvel ~= 0 and not ctrl.up then tvel = 0 end

        if not ctrl.down and not ctrl.jump then
            if mount_state == "ground" then
                y = cur_vel.y
            else
                y = 0
            end
        end

        if ctrl.sneak then
            mobkit.clear_queue_low(self)
            mobkit.clear_queue_high(self)
            draconis.detach(self.driver)
        end
    end
    mobkit.queue_high(self, func, prty)
end
