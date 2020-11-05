local abs = math.abs

local function rotate_bone(self, bone, goal, interval)
    local pos, rot = self.object:get_bone_position(bone)
    local x_diff = abs(rot.x - goal.x)
    local y_diff = abs(rot.y - goal.y)
    local z_diff = abs(rot.z - goal.z)
    
    -- X Axis
    if rot.x < goal.x then
        rot.x = rot.x + interval
    end
    if rot.x > goal.x then
        rot.x = rot.x - interval
    end
    -- Y Axis
    if rot.y < goal.y then
        rot.y = rot.y + interval
    end
    if rot.y > goal.y then
        rot.y = rot.y - interval
    end
    -- Z Axis
    if rot.z < goal.z then
        rot.z = rot.z + interval 
    end
    if rot.z > goal.z then
        rot.z = rot.z - interval
    end
    self.object:set_bone_position(bone, pos, rot)
    if x_diff <= interval
    and y_diff <= interval
    and z_diff <= interval then
        return true
    end
end

local function move_bone(self, bone, goal, interval)
    local pos, rot = self.object:get_bone_position(bone)
    -- X Axis
    if pos.x < goal.x then
        pos.x = pos.x + interval
    end
    if pos.x > goal.x then
        pos.x = pos.x - interval
    end
    -- Y Axis
    if pos.y < goal.y then
        pos.y = pos.y + interval
    end
    if pos.y > goal.y then
        pos.y = pos.y - interval
    end
    -- Z Axis
    if pos.z < goal.z then
        pos.z = pos.z + interval 
    end
    if pos.z > goal.z then
        pos.z = pos.z - interval
    end
    self.object:set_bone_position(bone, pos, rot)
    if pos.x == goal.x
    and pos.y == goal.y
    and pos.z == goal.z then
        return true
    end
end

-- Walk Animation --

function draconis.animation_walk_wings(self)
    if not self.bone_anim["walk"] then
        self.bone_anim["walk"] = {init = nil, frame = 0}
    end
    if not self.bone_anim["walk"].init then
        local wing_r = rotate_bone(self, "Wing.R.1", {x = 130, y = -130, z = -30}, 1)
        local wing_l = rotate_bone(self, "Wing.L.1", {x = -170, y = -50, z = 30}, 1)
        if wing_r
        and wing_l then
            self.bone_anim["walk"].init = true
            self.bone_anim["walk"].frame = 1
        else
            self.bone_anim["walk"].init = nil
        end
    end
    local frame = self.bone_anim["walk"].frame
    if frame == 1 then -- Both Down
        local wing_r = rotate_bone(self, "Wing.R.1",  {x = 130, y = -130, z = -30}, 1)
        local wing_l = rotate_bone(self, "Wing.L.1",  {x = -170, y = -50, z = 30}, 1)
        rotate_bone(self, "Wing.R.2", {x = -80, y = 0, z = 0}, 1)
        rotate_bone(self, "Wing.L.2", {x = 80, y = 0, z = 0}, 1)
        if wing_r
        and wing_l then
            self.bone_anim["walk"].frame = 2
        end
    end
    if frame == 2 then -- Right Up
        local wing_r = rotate_bone(self, "Wing.R.1",  {x = 150, y = -130, z = -30}, 1)
        local wing_l = rotate_bone(self, "Wing.L.1",  {x = -150, y = -60, z = 30}, 1)
        rotate_bone(self, "Wing.R.2", {x = -60, y = 0, z = 0}, 1)
        rotate_bone(self, "Wing.L.2", {x = 80, y = 0, z = 0}, 1)
        if wing_r
        and wing_l then
            self.bone_anim["walk"].frame = 3
        end
    end
    if frame == 3 then -- Both Down
        local wing_r = rotate_bone(self, "Wing.R.1",  {x = 170, y = -130, z = -30}, 1)
        local wing_l = rotate_bone(self, "Wing.L.1",  {x = -130, y = -50, z = 30}, 1)
        rotate_bone(self, "Wing.R.2", {x = -80, y = 0, z = 0}, 1)
        rotate_bone(self, "Wing.L.2", {x = 80, y = 0, z = 0}, 1)
        if wing_r
        and wing_l then
            self.bone_anim["walk"].frame = 4
        end
    end
    if frame == 4 then -- Left Up
        local wing_r = rotate_bone(self, "Wing.R.1",  {x = 150, y = -120, z = -30}, 1)
        local wing_l = rotate_bone(self, "Wing.L.1",  {x = -150, y = -50, z = 30}, 1)
        rotate_bone(self, "Wing.R.2", {x = -80, y = 0, z = 0}, 1)
        rotate_bone(self, "Wing.L.2", {x = 60, y = 0, z = 0}, 1)
        if wing_r
        and wing_l then
            self.bone_anim["walk"].frame = 1
        end
    end
end

function draconis.animation_walk_legs(self)
    if not self.bone_anim["walk_legs"] then
        self.bone_anim["walk_legs"] = {init = nil, frame = 1}
    end
    if not self.bone_anim["walk_legs"].init then
        local leg_r = rotate_bone(self, "Upper.Leg.R", {x = -75, y = 0, z = 0}, 1)
        local leg_l = rotate_bone(self, "Upper.Leg.L", {x = -105, y = 0, z = 0}, 1)
        if leg_r
        and leg_l then
            self.bone_anim["walk_legs"].init = true
            self.bone_anim["walk_legs"].frame = 1
        else
            self.bone_anim["walk_legs"].init = nil
        end
    end
    local frame = self.bone_anim["walk_legs"].frame
    if frame == 1 then -- Both Down
        local leg_r = rotate_bone(self, "Upper.Leg.R", {x = -75, y = 0, z = 0}, 1)
        local leg_l = rotate_bone(self, "Upper.Leg.L", {x = -105, y = 0, z = 0}, 1)
        if leg_r
        and leg_l then
            self.bone_anim["walk_legs"].frame = 2
        end
    end
    if frame == 2 then -- Both Down
        local leg_r = rotate_bone(self, "Upper.Leg.R", {x = -105, y = 0, z = 0}, 1)
        local leg_l = rotate_bone(self, "Upper.Leg.L", {x = -75, y = 0, z = 0}, 1)
        if leg_r
        and leg_l then
            self.bone_anim["walk_legs"].frame = 1
        end
    end
end


function draconis.animation_fly(self)
    if not self.bone_anim["fly"] then
        self.bone_anim["fly"] = {init = nil, frame = 1}
    end
    if not self.bone_anim["fly"].init then
        local wing_r = rotate_bone(self, "Wing.R.1", {x = 90, y = -60, z = 0}, 3)
        local wing_l = rotate_bone(self, "Wing.L.1", {x = -90, y = -120, z = 0}, 3)
        rotate_bone(self, "Wing.R.2", {x = -20, y = 0, z = 20}, 2)
        rotate_bone(self, "Wing.L.2", {x = 20, y = 0, z = 20}, 2)
        rotate_bone(self, "Upper.Leg.R", {x = -140, y = 0, z = 0}, 1)
        rotate_bone(self, "Upper.Leg.L", {x = -140, y = 0, z = 0}, 1)
        move_bone(self, "Torso.1", {x = 0, y = 0.85, z = -1.4}, 0.005)
        if wing_r
        and wing_l then
            self.bone_anim["fly"].init = true
            self.bone_anim["fly"].frame = 1
        else
            self.bone_anim["fly"].init = nil
        end
    end
    local frame = self.bone_anim["fly"].frame
    local vel = self.object:get_velocity()
    rotate_bone(self, "Torso.1", {x = -90 + vel.y, y = 180, z = 0}, 0.5)
    if frame == 1 then
        local wing_r = rotate_bone(self, "Wing.R.1", {x = 90, y = -60, z = 0}, 3)
        local wing_l = rotate_bone(self, "Wing.L.1", {x = -90, y = -120, z = 0}, 3)
        rotate_bone(self, "Wing.R.2", {x = -20, y = 0, z = 20}, 3)
        rotate_bone(self, "Wing.L.2", {x = 20, y = 0, z = 20}, 3)
        rotate_bone(self, "Upper.Leg.R", {x = -150, y = 0, z = 0}, 1)
        rotate_bone(self, "Upper.Leg.L", {x = -150, y = 0, z = 0}, 1)
        move_bone(self, "Torso.1", {x = 0, y = 1.05, z = -1.4}, 0.005)
        if wing_r
        and wing_l then
            mobkit.make_sound(self, "flap")
            self.bone_anim["fly"].frame = 2
        end
    end
    if frame == 2 then
        local wing_r = rotate_bone(self, "Wing.R.1", {x = 90, y = -90, z = 0}, 3)
        local wing_l = rotate_bone(self, "Wing.L.1", {x = -90, y = -90, z = 0}, 3)
        rotate_bone(self, "Wing.R.2", {x = -20, y = 0, z = -20}, 2)
        rotate_bone(self, "Wing.L.2", {x = 20, y = 0, z = -20}, 2)
        rotate_bone(self, "Upper.Leg.R", {x = -150, y = 0, z = 0}, 1)
        rotate_bone(self, "Upper.Leg.L", {x = -150, y = 0, z = 0}, 1)
        move_bone(self, "Torso.1", {x = 0, y = 0.85, z = -1.4}, 0.005)
        if wing_r
        and wing_l then
            self.bone_anim["fly"].frame = 3
        end
    end
    if frame == 3 then
        local wing_r = rotate_bone(self, "Wing.R.1", {x = 90, y = -120, z = 0}, 3)
        local wing_l = rotate_bone(self, "Wing.L.1", {x = -90, y = -60, z = 0}, 3)
        rotate_bone(self, "Wing.R.2", {x = -20, y = 0, z = 0}, 2)
        rotate_bone(self, "Wing.L.2", {x = 20, y = 0, z = 0}, 2)
        rotate_bone(self, "Upper.Leg.R", {x = -150, y = 0, z = 0}, 1)
        rotate_bone(self, "Upper.Leg.L", {x = -150, y = 0, z = 0}, 1)
        move_bone(self, "Torso.1", {x = 0, y = 0.85, z = -1.4}, 0.005)
        if wing_r
        and wing_l then
            self.bone_anim["fly"].frame = 1
        end
    end
end

function draconis.movement_anim(self)
    if not self._anim then return end
    if self._anim:find("stand") then
        rotate_bone(self, "Torso.1", {x = -90, y = 180, z = 0}, 0.5)
        rotate_bone(self, "Wing.R.1", {x = 150, y = -130, z = -30}, 1)
        rotate_bone(self, "Wing.R.2", {x = -80, y = 0, z = 0}, 1)
        rotate_bone(self, "Wing.R.F1", {x = 40, y = 20, z = -50}, 1)
        rotate_bone(self, "Wing.R.F2", {x = 60, y = 20, z = -50}, 1)
        rotate_bone(self, "Wing.R.F3", {x = 80, y = 20, z = -50}, 1)
        -- Left Wing
        rotate_bone(self, "Wing.L.1", {x = -150, y = -50, z = 30}, 1)
        rotate_bone(self, "Wing.L.2", {x = 80, y = 0, z = 0}, 1)
        rotate_bone(self, "Wing.L.F1", {x = -40, y = -20, z = -50}, 1)
        rotate_bone(self, "Wing.L.F2", {x = -60, y = -20, z = -50}, 1)
        rotate_bone(self, "Wing.L.F3", {x = -80, y = -20, z = -50}, 1)
        rotate_bone(self, "Upper.Leg.R", {x = -90, y = 0, z = 0}, 1)
        rotate_bone(self, "Lower.Leg.R", {x = 5, y = 0, z = 0}, 1)
        rotate_bone(self, "Foot.R", {x = 85, y = 0, z = 0}, 2)
        rotate_bone(self, "Upper.Leg.L", {x = -90, y = 0, z = 0}, 1)
        rotate_bone(self, "Lower.Leg.L", {x = 5, y = 0, z = 0}, 1)
        rotate_bone(self, "Foot.L", {x = 85, y = 0, z = 0}, 2)
    end
    if self._anim:find("fly") then
        draconis.animation_fly(self)
        -- Right Wing
        rotate_bone(self, "Wing.R.F1", {x = 35, y = 0, z = 0}, 1)
        rotate_bone(self, "Wing.R.F2", {x = 65, y = 0, z = 0}, 1)
        rotate_bone(self, "Wing.R.F3", {x = 95, y = 0, z = 0}, 1)
        -- Left Wing
        rotate_bone(self, "Wing.L.F1", {x = -35, y = 0, z = 0}, 1)
        rotate_bone(self, "Wing.L.F2", {x = -65, y = 0, z = 0}, 1)
        rotate_bone(self, "Wing.L.F3", {x = -95, y = 0, z = 0}, 1)
    end
    if self._anim:find("walk") then
        rotate_bone(self, "Torso.1", {x = -90, y = 180, z = 0}, 0.5)
        draconis.animation_walk_wings(self)
        draconis.animation_walk_legs(self)
        rotate_bone(self, "Wing.R.F1", {x = 40, y = 20, z = -50}, 1)
        rotate_bone(self, "Wing.R.F2", {x = 60, y = 20, z = -50}, 1)
        rotate_bone(self, "Wing.R.F3", {x = 80, y = 20, z = -50}, 1)
        rotate_bone(self, "Wing.L.F1", {x = -40, y = -20, z = -50}, 1)
        rotate_bone(self, "Wing.L.F2", {x = -60, y = -20, z = -50}, 1)
        rotate_bone(self, "Wing.L.F3", {x = -80, y = -20, z = -50}, 1)
    end
end

-- Idle Animation --

local function get_turning(self)
    local dir = minetest.yaw_to_dir(self.object:get_yaw())
    local last_dir = self.last_dir
    if last_dir.x > 0 then
        if dir.x < last_dir.x
        and dir.z > last_dir.z then
            return 1
        elseif dir.x > last_dir.x
        and dir.z < last_dir.z then
            return 2
        end
    elseif last_dir.x < 0 then
        if dir.x < last_dir.x
        and dir.z > last_dir.z then
            return 2
        elseif dir.x > last_dir.x
        and dir.z < last_dir.z then
            return 1
        end
    end
    return 0
end

function draconis.animation_sleep(self)
    if not self.bone_anim["sleep"] then
        self.bone_anim["sleep"] = {init = nil, frame = 1}
    end
    if not self.bone_anim["sleep"].init then
        move_bone(self, "Torso.1", {x = 0, y = 0.1, z = -1.4}, 0.02)
        rotate_bone(self, "Torso.2", {x = -4, y = 0, z = 0}, 0.1)
        -- Right Leg
        rotate_bone(self, "Upper.Leg.R", {x = -30, y = 0, z = 0}, 2)
        rotate_bone(self, "Lower.Leg.R", {x = 25, y = 0, z = 0}, 1)
        rotate_bone(self, "Foot.R", {x = 5, y = 0, z = 0}, 2)
        -- Left Leg
        rotate_bone(self, "Upper.Leg.L", {x = -30, y = 0, z = 0}, 2)
        rotate_bone(self, "Lower.Leg.L", {x = 25, y = 0, z = 0}, 1)
        rotate_bone(self, "Foot.L", {x = 5, y = 0, z = 0}, 2)
        -- Neck
        rotate_bone(self, "Neck.1", {x = -20, y = 0, z = 20}, 1)
        rotate_bone(self, "Neck.2", {x = 10, y = 0, z = 20}, 1)
        rotate_bone(self, "Neck.3", {x = 0, y = 0, z = 20}, 1)
        rotate_bone(self, "Head", {x = -10, y = 30, z = 0}, 1)
        -- Tail
        rotate_bone(self, "Tail.1", {x = -20, y = 0, z = 185}, 1)
        rotate_bone(self, "Tail.2", {x = 5, y = 0, z = -30}, 1)
        rotate_bone(self, "Tail.3", {x = 0, y = 0, z = -30}, 1)
        rotate_bone(self, "Tail.4", {x = 0, y = 0, z = -20}, 1)
        -- Right Wing
        rotate_bone(self, "Wing.R.1", {x = 90, y = -100, z = 0}, 1)
        rotate_bone(self, "Wing.R.2", {x = -60, y = 0, z = 0}, 1)
        rotate_bone(self, "Wing.R.F1", {x = 80, y = 0, z = 0}, 1)
        rotate_bone(self, "Wing.R.F2", {x = 100, y = 0, z = 0}, 1)
        rotate_bone(self, "Wing.R.F3", {x = 120, y = 0, z = 0}, 1)
        -- Left Wing
        rotate_bone(self, "Wing.L.1", {x = -90, y = -80, z = 0}, 1)
        rotate_bone(self, "Wing.L.2", {x = 60, y = 0, z = 0}, 1)
        rotate_bone(self, "Wing.L.F1", {x = -80, y = 0, z = 0}, 1)
        rotate_bone(self, "Wing.L.F2", {x = -100, y = 0, z = 0}, 1)
        rotate_bone(self, "Wing.L.F3", {x = -120, y = 0, z = 0}, 1)
        minetest.after(3, function()
            self.bone_anim["sleep"].init = true
        end)
    end
    local frame = self.bone_anim["sleep"].frame
    if self.bone_anim["sleep"].init then
        if frame == 1 then
            move_bone(self, "Torso.1", {x = 0, y = 0.1, z = -1.4}, 0.02)
            local torso_2 = rotate_bone(self, "Torso.2", {x = -4, y = 0, z = 0}, 0.02)
            -- Right Leg
            rotate_bone(self, "Upper.Leg.R", {x = -30, y = 0, z = 0}, 2)
            rotate_bone(self, "Lower.Leg.R", {x = 25, y = 0, z = 0}, 1)
            rotate_bone(self, "Foot.R", {x = 5, y = 0, z = 0}, 2)
            -- Left Leg
            rotate_bone(self, "Upper.Leg.L", {x = -30, y = 0, z = 0}, 2)
            rotate_bone(self, "Lower.Leg.L", {x = 25, y = 0, z = 0}, 1)
            rotate_bone(self, "Foot.L", {x = 5, y = 0, z = 0}, 2)
            -- Neck
            rotate_bone(self, "Neck.1", {x = -20, y = 0, z = 20}, 1)
            rotate_bone(self, "Neck.2", {x = 10, y = 0, z = 20}, 1)
            rotate_bone(self, "Neck.3", {x = 0, y = 0, z = 20}, 1)
            rotate_bone(self, "Head", {x = -10, y = 30, z = 0}, 1)
            -- Tail
            rotate_bone(self, "Tail.1", {x = -20, y = 0, z = 185}, 1)
            rotate_bone(self, "Tail.2", {x = 5, y = 0, z = -30}, 1)
            rotate_bone(self, "Tail.3", {x = 0, y = 0, z = -30}, 1)
            rotate_bone(self, "Tail.4", {x = 0, y = 0, z = -20}, 1)
            -- Right Wing
            rotate_bone(self, "Wing.R.1", {x = 90, y = -100, z = 0}, 1)
            rotate_bone(self, "Wing.R.2", {x = -60, y = 0, z = 0}, 1)
            rotate_bone(self, "Wing.R.F1", {x = 80, y = 0, z = 0}, 1)
            rotate_bone(self, "Wing.R.F2", {x = 100, y = 0, z = 0}, 1)
            rotate_bone(self, "Wing.R.F3", {x = 120, y = 0, z = 0}, 1)
            -- Left Wing
            rotate_bone(self, "Wing.L.1", {x = -90, y = -80, z = 0}, 1)
            rotate_bone(self, "Wing.L.2", {x = 60, y = 0, z = 0}, 1)
            rotate_bone(self, "Wing.L.F1", {x = -80, y = 0, z = 0}, 1)
            rotate_bone(self, "Wing.L.F2", {x = -100, y = 0, z = 0}, 1)
            rotate_bone(self, "Wing.L.F3", {x = -120, y = 0, z = 0}, 1)
            if torso_2 then
                self.bone_anim["sleep"].frame = 2
            end
        end
        if frame == 2 then
            move_bone(self, "Torso.1", {x = 0, y = 0.1, z = -1.4}, 0.02)
            local torso_2 = rotate_bone(self, "Torso.2", {x = -7, y = 0, z = 0}, 0.01)
            -- Right Leg
            rotate_bone(self, "Upper.Leg.R", {x = -30, y = 0, z = 0}, 0.01)
            rotate_bone(self, "Lower.Leg.R", {x = 25, y = 0, z = 0}, 0.01)
            rotate_bone(self, "Foot.R", {x = 25, y = 0, z = 0}, 0.01)
            -- Left Leg
            rotate_bone(self, "Upper.Leg.L", {x = -30, y = 0, z = 0}, 0.01)
            rotate_bone(self, "Lower.Leg.L", {x = 25, y = 0, z = 0}, 0.01)
            rotate_bone(self, "Foot.L", {x = 25, y = 0, z = 0}, 0.01)
            -- Neck
            rotate_bone(self, "Neck.1", {x = -20, y = 20, z = 0}, 0.01)
            rotate_bone(self, "Neck.2", {x = 10, y = 20, z = 0}, 0.01)
            rotate_bone(self, "Neck.3", {x = 0, y = 20, z = 0}, 0.01)
            rotate_bone(self, "Head", {x = -10, y = 30, z = 0}, 0.01)
            -- Tail
            rotate_bone(self, "Tail.1", {x = -20, y = 160, z = 0}, 0.01)
            rotate_bone(self, "Tail.2", {x = 5, y = -30, z = 0}, 0.01)
            rotate_bone(self, "Tail.3", {x = 0, y = -30, z = 0}, 0.01)
            rotate_bone(self, "Tail.4", {x = 0, y = -20, z = 0}, 0.01)
            -- Right Wing
            rotate_bone(self, "Wing.R.1", {x = 90, y = -100, z = 0}, 0.01)
            rotate_bone(self, "Wing.R.2", {x = -60, y = 0, z = 0}, 0.01)
            rotate_bone(self, "Wing.R.F1", {x = 80, y = 0, z = 0}, 0.01)
            rotate_bone(self, "Wing.R.F2", {x = 100, y = 0, z = 0}, 0.01)
            rotate_bone(self, "Wing.R.F3", {x = 120, y = 0, z = 0}, 0.01)
            -- Left Wing
            rotate_bone(self, "Wing.L.1", {x = -90, y = -50, z = 0}, 0.01)
            rotate_bone(self, "Wing.L.2", {x = 60, y = 0, z = 0}, 0.01)
            rotate_bone(self, "Wing.L.F1", {x = -80, y = 0, z = 0}, 0.01)
            rotate_bone(self, "Wing.L.F2", {x = -100, y = 0, z = 0}, 0.01)
            rotate_bone(self, "Wing.L.F3", {x = -120, y = 0, z = 0}, 0.01)
            if torso_2 then
                self.bone_anim["sleep"].frame = 1
            end
        end
    end
end

function draconis.animation_body_idle(self)
    if not self.bone_anim["idle"] then
        self.bone_anim["idle"] = {init = nil, frame = 1, neck_angle = 0}
    end
    if not self.bone_anim["neck"] then
        self.bone_anim["neck"] = {pitch = 0.2, angle = 0}
    end
    local frame = self.bone_anim["idle"].frame
    local angle = self.bone_anim["idle"].angle
    if not self._anim:find("fly") then
        move_bone(self, "Torso.1", {x = 0, y = 0.85, z = -1.4}, 0.02)
    end
    local dir = get_turning(self)
    if dir == 1 then
        self.bone_anim["neck"].angle = -5
        local neck_1 = rotate_bone(self, "Neck.1", {x = 12, y = 0, z = -5}, 1)
        local neck_2 = rotate_bone(self, "Neck.2", {x = -7, y = 0, z = -5}, 1)
        local neck_3 = rotate_bone(self, "Neck.3", {x = -12, y = 0, z = -5}, 1)
    elseif dir == 2 then
        self.bone_anim["neck"].angle = 5
        local neck_1 = rotate_bone(self, "Neck.1", {x = 12, y = 0, z = 5}, 1)
        local neck_2 = rotate_bone(self, "Neck.2", {x = -7, y = 0, z = 5}, 1)
        local neck_3 = rotate_bone(self, "Neck.3", {x = -12, y = 0, z = 5}, 1)
    else
        self.bone_anim["neck"].angle = 0
        local neck_1 = rotate_bone(self, "Neck.1", {x = 12, y = 0, z = 0}, 0.25)
        local neck_2 = rotate_bone(self, "Neck.2", {x = -7, y = 0, z = 0}, 0.25)
        local neck_3 = rotate_bone(self, "Neck.3", {x = -12, y = 0, z = 0}, 0.25)
    end
    if frame == 1 then
        local torso_2 = rotate_bone(self, "Torso.2", {x = -1, y = 0, z = 0}, 0.05)
        if torso_2 then
            self.bone_anim["idle"].frame = 2
        end
    end
    if frame == 2 then
        local torso_2 = rotate_bone(self, "Torso.2", {x = -3, y = 0, z = 0}, 0.05)
        if torso_2 then
            self.bone_anim["idle"].frame = 1
        end
    end
end

function draconis.animation_roar(self)
    local head = rotate_bone(self, "Head", {x = -25, y = 0, z = 0}, 0.1)
    local jaw = rotate_bone(self, "Jaw", {x = -35, y = 0, z = 0}, 3)
    if head
    and jaw then
        self.bone_anim["roar"].init = nil
    end
end

function draconis.animation_tail(self)
    if not self.bone_anim["tail"] then
        self.bone_anim["tail"] = {init = true, frame = 1}
    end
    local pos, rot = self.object:get_bone_position("Tail.1")
    local frame = self.bone_anim["tail"].frame
    if self._anim:find("fly") then
        local dir = get_turning(self)
        if dir == 1 then
            local Tail1 = rotate_bone(self, "Tail.1", {x = -5, y = 0, z = 190}, 2)
            local Tail2 = rotate_bone(self, "Tail.2", {x = -5, y = 0, z = 20}, 2)
            local Tail3 = rotate_bone(self, "Tail.3", {x = -5, y = 0, z = 20}, 3)
            local Tail4 = rotate_bone(self, "Tail.4", {x = -5, y = 0, z = 20}, 3)
        elseif dir == 2 then
            local Tail1 = rotate_bone(self, "Tail.1", {x = -5, y = 0, z = 170}, 2)
            local Tail2 = rotate_bone(self, "Tail.2", {x = -5, y = 0, z = -20}, 2)
            local Tail3 = rotate_bone(self, "Tail.3", {x = -5, y = 0, z = -20}, 3)
            local Tail4 = rotate_bone(self, "Tail.4", {x = -5, y = 0, z = -20}, 3)
        else
            local Tail1 = rotate_bone(self, "Tail.1", {x = -5, y = 0, z = 180}, 2)
            local Tail2 = rotate_bone(self, "Tail.2", {x = -5, y = 0, z = 0}, 1)
            local Tail3 = rotate_bone(self, "Tail.3", {x = -5, y = 0, z = 0}, 1)
            local Tail4 = rotate_bone(self, "Tail.4", {x = -5, y = 0, z = 0}, 1)
        end
        self.bone_anim["tail"].speed = 1
        self.bone_anim["tail"].frame = 0
    else
        self.bone_anim["tail"].speed = 0.25
        if frame == 0 then
            self.bone_anim["tail"].frame = 1
        end
    end
    local speed = self.bone_anim["tail"].speed
    if frame == 1 then
        local Tail1 = rotate_bone(self, "Tail.1", {x = -20, y = 0, z = 185}, speed)
        local Tail2 = rotate_bone(self, "Tail.2", {x = 5, y = 0, z = 10}, speed)
        local Tail3 = rotate_bone(self, "Tail.3", {x = 5, y = 0, z = 10}, speed)
        local Tail4 = rotate_bone(self, "Tail.4", {x = 5, y = 0, z = 5}, speed)
        if Tail1 then
            self.bone_anim["tail"].frame = 2
        end
    end
    if frame == 2 then
        local Tail1 = rotate_bone(self, "Tail.1", {x = -20, y = 0, z = 180}, speed)
        local Tail2 = rotate_bone(self, "Tail.2", {x = 5, y = 0, z = 5}, speed)
        local Tail3 = rotate_bone(self, "Tail.3", {x = 5, y = 0, z = 7.5}, speed)
        local Tail4 = rotate_bone(self, "Tail.4", {x = 5, y = 0, z = 5}, speed)
        if Tail1 then
            self.bone_anim["tail"].frame = 3
        end
    end
    if frame == 3 then
        local Tail1 = rotate_bone(self, "Tail.1", {x = -20, y = 0, z = 175}, speed)
        local Tail2 = rotate_bone(self, "Tail.2", {x = 5, y = 0, z = -10}, speed)
        local Tail3 = rotate_bone(self, "Tail.3", {x = 5, y = 0, z = -10}, speed)
        local Tail4 = rotate_bone(self, "Tail.4", {x = 5, y = 0, z = -5}, speed)
        if Tail1 then
            self.bone_anim["tail"].frame = 4
        end
    end
    if frame == 4 then
        local Tail1 = rotate_bone(self, "Tail.1", {x = -20, y = 0, z = 180}, speed)
        local Tail2 = rotate_bone(self, "Tail.2", {x = 5, y = 0, z = -5}, speed)
        local Tail3 = rotate_bone(self, "Tail.3", {x = 5, y = 0, z = -7.5}, speed)
        local Tail4 = rotate_bone(self, "Tail.4", {x = 5, y = 0, z = -5}, speed)
        if Tail1 then
            self.bone_anim["tail"].frame = 1
        end
    end
end

function draconis.idle_anim(self)
    if not self._anim then return end
    if self._anim == "sleep" then
        draconis.animation_sleep(self)
        return
    end
    draconis.animation_body_idle(self)
    draconis.animation_tail(self)
    if self._anim:find("fire") then
        local pitch = self.bone_anim["neck"].pitch or 0.2
        local angle = self.bone_anim["neck"].angle or 0
        rotate_bone(self, "Neck.1", {x = pitch/3, y = 0, z = 0}, 0.5)
        rotate_bone(self, "Neck.2", {x = pitch/3, y = 0, z = 0}, 0.5)
        rotate_bone(self, "Neck.3", {x = pitch/3, y = 0, z = 0}, 0.5)
        rotate_bone(self, "Head", {x = 3, y = 0, z = 0}, 1)
        rotate_bone(self, "Jaw", {x = -45, y = 0, z = 0}, 1)
    else
        if self.bone_anim["roar"]
        and self.bone_anim["roar"].init then
            draconis.animation_roar(self)
        elseif self.bone_anim["bite"]
        and self.bone_anim["bite"].init then
            draconis.animation_bite(self)
        else
            rotate_bone(self, "Head", {x = -30, y = 0, z = 0}, 1)
            rotate_bone(self, "Jaw", {x = 0, y = 0, z = 0}, 1)
        end
    end
end