-----------------
-- Fire Dragon --
-----------------

local creative = minetest.settings:get_bool("creative_mode")

minetest.register_entity("draconis:fire_eyes", {
    hp_max = 1,
    armor_groups = {immortal = 1},
    physical = false,
    collisionbox = {0, 0, 0, 0, 0, 0},
    visual = "mesh",
    mesh = "draconis_eyes.b3d",
    visual_size = {x = 1.01, y = 1.01},
    textures = {"draconis_fire_eyes_orange.png"},
    is_visible = true,
    makes_footstep_sound = false,
    glow = 11,
    blink_timer = 18,
    on_step = function(self, dtime)
        if not self.object:get_attach() then
            self.object:remove()
            return
        end
        if not self.color then return end
        self.object:set_armor_groups({immortal = 1})
        if self.object:get_attach()
        and self.object:get_attach():get_luaentity() then
            local parent = self.object:get_attach():get_luaentity()
            if parent.hp <= 0 then
                self.object:set_properties({textures = {"transparency.png"}})
                return
            end
            if parent.status ~= "sleeping" then
                self.blink_timer = self.blink_timer - dtime
                if parent.age < 25 then
                    self.object:set_properties(
                        {textures = {"draconis_fire_eyes_child_"..self.color..".png"}})
                else
                    self.object:set_properties(
                        {textures = {"draconis_fire_eyes_"..self.color..".png"}})
                end
                if self.blink_timer <= 0 then
                    local tex = self.object:get_properties().textures[1]
                    self.object:set_properties({textures = {"transparency.png"}})
                    minetest.after(0.25, function()
                        self.object:set_properties({textures = {tex}})
                        self.blink_timer = math.random(6, 18)
                    end)
                end
            else
                self.blink_timer = 18
                self.object:set_properties({textures = {"transparency.png"}})
            end
        end
    end
})

--------------
-- Behavior --
--------------

local function get_sounds(self)
    local age = self.age
    if age < 25 then
        self.sounds = self.child_sounds
    end
    if age < 50 then
        self.sounds = self.juvi_sounds
    end
    self.sounds = self.adult_sounds
end

local function fire_dragon_logic(self)

    if self.hp <= 0 then
        if self.driver then
            draconis.detach(minetest.get_player_by_name(self.driver))
            self.driver = nil
        else
            --mob_core.on_die(self)
            draconis.animate(self, "death")
            mobkit.clear_queue_high(self)
            mobkit.clear_queue_low(self)
            self.object:set_yaw(self.object:get_yaw())
        end
        return
    end

    if self.shoulder_mounted then
        local player = minetest.get_player_by_name(self.owner)
        if player:get_player_control().sneak == true
        or self.age > 4 then
            self.object:set_detach()
            self.shoulder_mounted = mobkit.remember(self, "shoulder_mounted", false)
            self.object:set_properties({
                physical = true,
                collide_with_objects = true
            })
        end
    end

    mobkit.remember(self, "idle_timer", self.idle_timer)

    if mobkit.timer(self, 1) then

        if not self.isonground
        and self.logic_state == "landed" then
            self.fall_distance = self.fall_distance + 1
        else
            self.fall_distance = 0
        end

        local pos = self.object:get_pos()
        local prty = mobkit.get_queue_priority(self)
        local player = mobkit.get_nearby_player(self)

        get_sounds(self)
        draconis.fire_vitals(self)
        draconis.handle_sounds(self)

        if self.shoulder_mounted then
            draconis.animate(self, "shoulder_idle")
            self.idle_timer = self.idle_timer + 1
            return
        end

        if self.tamed
        and not self.driver
        and (self.order == "stand"
        or (not self.fly_allowed
        and self.logic_state == "flying")) then
            if self.order == "stand" then
                if not self.isonground then
                    mobkit.clear_queue_high(self)
                    draconis.hq_land_and_wander(self, 0)
                else
                    draconis.hq_sleep(self, 11)
                    if self.status ~= "sleeping" then
                        draconis.animate(self, "stand")
                    end
                end
            end
            if not self.fly_allowed
            and self.logic_state == "flying" then
                mobkit.clear_queue_high(self)
                draconis.hq_land_and_wander(self, 0)
                self.logic_state = "landed"
                mobkit.remember(self, "logic", self.logic_state)
            end
            self.idle_timer = self.idle_timer + 1
            return
        end

        if prty < 20 then
            if self.driver then
                draconis.hq_mount_logic(self, 20)
                return
            end
        end

        if prty < 12
        and self.isinliquid then
            draconis.hq_aerial_wander(self, 0)
            return
        end

        if prty < 10
        and self.age > 24
        and self.owner_target
        and self.stance ~= "passive" then
            local target = self.owner_target
            if target
            and not mob_core.shared_owner(self, target) then
                if self.logic_state == "landed" then
                    draconis.hq_landed_attack(self, 10, target)
                else
                    draconis.hq_aerial_attack(self, 10, target)
                end
            end
        end

        if prty < 6
        and self.age > 24 then
            if not self.tamed
            or self.stance == "aggressive" then
                for _, mob in ipairs(draconis.mobkit_mobs) do
                    local target = mobkit.get_closest_entity(self, mob)
                    if target
                    and (draconis.get_line_of_sight(pos, target:get_pos()
                    or pos.y - target:get_pos() < 10))
                    and not mob_core.shared_owner(self, target) then
                        if self.logic_state == "landed" then
                            draconis.hq_landed_attack(self, 6, target)
                        else
                            draconis.hq_aerial_attack(self, 6, target)
                        end
                    end
                end
            end
        end

        if prty <= 5
        and self.order == "follow"
        and minetest.get_player_by_name(self.owner) then
            draconis.hq_follow(self, 5, minetest.get_player_by_name(self.owner))
        end

        if prty < 4
        and self.age > 24
        and player then
            if not self.tamed
            or (self.stance == "aggressive"
            and player:get_player_name() ~= self.owner) then
                if self.logic_state == "landed" then
                    draconis.hq_landed_attack(self, 4, player)
                elseif self.logic_state == "flying" then
                    draconis.hq_aerial_attack(self, 4, player)
                end
            end
        end

        if prty < 3 and self.isinliquid then
            self.flight_timer = mobkit.remember(self, "flight_timer", 30)
            mob_core.hq_takeoff_and_soar(self, 3)
        end

        if prty < 2 then
            if self.logic_state == "landed"
            and (math.random(64) == 1
            or (self.fall_distance > 2))
            and (not self.tamed or self.fly_allowed) then
                mob_core.hq_takeoff_and_soar(self, 2)
                self.logic_state = "flying"
                return
            elseif self.logic_state == "flying" and self.flight_timer < 1 then
                draconis.hq_land_and_wander(self, 2)
                self.logic_state = "landed"
            end
        end

        if prty < 1
        and self.idle_timer > 30 then
            draconis.hq_sleep(self, 11)
        end

        if mobkit.is_queue_empty_high(self) then
            self.idle_timer = self.idle_timer + 1
            if self.logic_state == "landed" then
                draconis.hq_wander(self, 0)
                if self.fall_distance > 2 then
                    draconis.hq_aerial_wander(self, 0)
                    self.logic_state = "flying"
                    return
                end
                if self.flight_timer <= 1 then
                    self.flight_timer = math.random(30, 60)
                    mobkit.remember(self, "flight_timer", self.flight_timer)
                end
            elseif self.logic_state == "flying" then
                draconis.hq_aerial_wander(self, 0)
                self.flight_timer = self.flight_timer - 1
                mobkit.remember(self, "flight_timer", self.flight_timer)
            end
        elseif prty >= 1 then
            self.idle_timer = 0
        end
        mobkit.remember(self, "logic_state", self.logic_state)
    end
end

----------------
-- Definition --
----------------

draconis.register_dragon("fire", {
    colors = {"black", "bronze", "green", "red", "gold"},
    logic = fire_dragon_logic
})

mob_core.register_spawn_egg("draconis:fire_dragon", "74271acc", "250b06d9")

local spawn_egg_def = minetest.registered_items["draconis:spawn_fire_dragon"]

spawn_egg_def.on_place = function(itemstack, _, pointed_thing)
    local mobdef = minetest.registered_entities["draconis:fire_dragon"]
    local spawn_offset = math.abs(mobdef.collisionbox[2])
    local pos = minetest.get_pointed_thing_position(pointed_thing, true)
    pos.y = pos.y + spawn_offset
    draconis.spawn_dragon(pos, "draconis:fire_dragon", false, math.random(5, 100))
    if not creative then
        itemstack:take_item()
        return itemstack
    end
end

minetest.register_craftitem("draconis:spawn_fire_dragon", spawn_egg_def)

if minetest.settings:get_bool("simple_spawning") then
    local spawn_rate = tonumber(minetest.settings:get("simple_spawn_rate")) or 512
    mob_core.register_spawn({
        name = "draconis:fire_dragon",
        nodes = draconis.warm_biome_nodes,
        min_light = 0,
        max_light = 15,
        min_height = 1,
        max_height = 31000,
        group = 0,
        optional = {
            biomes = draconis.warm_biomes,
        }
    }, spawn_rate, 4)
end