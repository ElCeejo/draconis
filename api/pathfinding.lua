-----------------
-- Pathfinding --
-----------------
---- Ver 1.0 ----

-- Thanks to Oil_boi for base code

----------------------
-- Helper Functions --
----------------------

local function hitbox(self) return self.object:get_properties().collisionbox end

local function hitbox_index(self, pos)
	local width = self.object:get_properties().collisionbox[4]+1.75
	local pos1 = vector.new(pos.x - width, pos.y, pos.z - width)
	local pos2 = vector.new(pos.x + width, pos.y, pos.z + width)
	local walkable = {}
	for x = pos1.x, pos2.x do
		for y = pos1.y, pos2.y do
			for z = pos1.z, pos2.z do
				local npos = vector.new(x, y, z)
				local top = vector.new(npos.x, npos.y + 1, npos.z)
				if minetest.get_node(npos).walkable
				and minetest.get_node(top).walkable then
					table.insert(walkable, npos)
				end
			end
		end
	end
	return walkable
end

local function can_fit(self, pos)
	local box = hitbox_index(self, pos)
	if #box < 2 then return true end
    return false
end

local function new_line_of_sight(self, pos1, pos2, stepsize) -- From Mobs Redo

	if not pos1 or not pos2 then return end

	stepsize = stepsize or 1

	local stepv = vector.multiply(vector.direction(pos1, pos2), stepsize)

	local s, pos = minetest.line_of_sight(pos1, pos2, stepsize)

	if s == true then return true end

	local npos1 = {x = pos1.x, y = pos1.y, z = pos1.z}

	local r, pos = minetest.line_of_sight(npos1, pos2, stepsize)

	if r == true then return true end

	local nn = minetest.get_node(pos).name

	while minetest.registered_nodes[nn]
	and (minetest.registered_nodes[nn].walkable == false) do

		npos1 = vector.add(npos1, stepv)

		if vector.distance(npos1, pos2) < stepsize then return true end

		r, pos = minetest.line_of_sight(npos1, pos2, stepsize)

		if r == true then return true end

		nn = minetest.get_node(pos).name
	end
	return false
end

local function get_line(self, a, b)
    local steps = vector.distance(a, b)/4
    local nodes = {}

    for i = 0, steps do
        local c

        if steps > 0 then
            c = {
                x = a.x + (b.x - a.x) * (i / steps),
                y = a.y + (b.y - a.y) * (i / steps),
                z = a.z + (b.z - a.z) * (i / steps),
            }
        else
            c = a
        end
        table.insert(nodes, c)
	end
	if #nodes > 1 then
		for i = #nodes, 1, -1  do
			if not can_fit(self, nodes[i]) then
				local clear = draconis.find_clearance(self, nodes[i], nodes, math.abs(hitbox(self)[4])*2.25)
				if clear
				and can_fit(self, clear) then
					nodes[i] = clear
				end
			end
		end
	end
    return nodes
end

function draconis.find_clearance(self, pos, max)
	local dist = 0
	while dist < max do
		dist = dist + 1
		local area = minetest.find_nodes_in_area_under_air(
			vector.new(pos.x - dist, pos.y - 2, pos.z - dist),
			vector.new(pos.x + dist, pos.y + 2, pos.z + dist),
			draconis.walkable_nodes
		)
		for i = 1, #area do
			area[i].y = area[i].y + 1
			if can_fit(self, area[i]) then
				return area[i]
			end
		end
	end
end

function draconis.get_path(self, pos1, pos2)
	local path = minetest.find_path(pos1, pos2, self.view_range, 1, 1, "A*_noprefetch")
	if not path then return end
	for i = #path, 1, -1 do
		if not can_fit(self, path[i]) then
			local clear = draconis.find_clearance(self, path[i], math.abs(hitbox(self)[4])*2.25)
			if clear
			and can_fit(self, clear) then
				path[i] = clear
			end
		end
	end
	return path
end

-----------------
-- Pathfinding --
-----------------

local timer = 0

function draconis.find_path(self, tpos)
	if not mobkit.is_alive(self) then return end
	if not timer then
		timer = 0
	end
	local dtime = self.dtime
	local acute_pos = mobkit.get_stand_pos(self)
	if tpos then

		local direct_sight = new_line_of_sight(self, acute_pos, tpos, 0.5)
		local is_stuck = draconis.is_stuck(self)

		local height_diff
		if self.object:get_pos().y > tpos.y then
			height_diff = math.abs(self.object:get_pos().y-tpos.y)
		elseif self.object:get_pos().y <= tpos.y then
			height_diff = math.abs(tpos.y-self.object:get_pos().y)
		end

		if self.path_data and height_diff > self.view_range/2 then
			self.path_data = get_line(self, acute_pos, tpos)
			return
		end

		local direct_line = get_line(self, acute_pos, tpos)

		if direct_sight
		and not is_stuck then
			timer = timer - dtime
			if timer < 0 then
				timer = 0.5
				self.path_data = direct_line
			end
		end


		if direct_sight
		and is_stuck then
			if not self.path_data then
				self.path_data = direct_line
			end
		end

		if height_diff <= self.view_range/2 then
			local follow_pos = vector.floor(vector.add(tpos, 0.5))

			if (not self.old_path_pos
			or (self.old_path_pos
			and not vector.equals(acute_pos,self.old_path_pos)))
			and (not self.old_follow_pos
			or (self.old_follow_pos
			and vector.distance(self.old_follow_pos,follow_pos) > 2)) then

				--if a player tries to hide in a node
				if minetest.registered_nodes[minetest.get_node(follow_pos).name].walkable then
					follow_pos.y = follow_pos.y + 1
				end

				--if a player tries to stand off the side of a node
				if not minetest.registered_nodes[minetest.get_node(vector.new(follow_pos.x,follow_pos.y-1,follow_pos.z)).name].walkable then
					local min = vector.subtract(follow_pos,1)
					local max = vector.add(follow_pos,1)

					local index_table = minetest.find_nodes_in_area_under_air(min, max, draconis.walkable_nodes)
					--optimize this as much as possible
					for _,i_pos in pairs(index_table) do
						if minetest.registered_nodes[minetest.get_node(i_pos).name].walkable then
							follow_pos = vector.new(i_pos.x,i_pos.y+1,i_pos.z)
							break
						end
					end
				end

				local path = draconis.get_path(self, acute_pos, follow_pos)

				if path then
					self.path_data = path

					--remove the first element of the list
					--shift whole list down
					for i = 2,#self.path_data do
						self.path_data[i-1] = self.path_data[i]
					end
					self.path_data[#self.path_data] = nil

					--cut corners (go diagonal)
					if self.path_data and #self.path_data >= 3 then
						local number = 3
						for _ = 3, #self.path_data do
							local pos1 = self.path_data[number-2]
							local pos2 = self.path_data[number]

							--print(number)
							--check if diagonal and has direct line of sight
							if pos1 and pos2 and pos1.x ~= pos2.x and pos1.z ~= pos2.z and pos1.y == pos2.y then
								local pos3 = vector.divide(vector.add(pos1,pos2),2)
								pos3.y = pos3.y - 1
								local can_cut,_ = minetest.line_of_sight(pos1, pos2)
								if can_cut then
									if minetest.registered_nodes[minetest.get_node(pos3).name].walkable == true then
										--shift whole list down
										--print("removing"..number-1)
										for z = number-1,#self.path_data do
											self.path_data[z-1] = self.path_data[z]
										end
										self.path_data[#self.path_data] = nil
										number = number + 2
									else
										number = number + 1
									end
								else
									number = number + 1
								end
								if number > #self.path_data then
									break
								end
							else
								number = number + 1
							end
						end
						--if self.path_data and #self.path_data <= 2 then
						--	self.path_data = nil
						--end
					end
				end
				self.old_path_pos = acute_pos
				self.old_follow_pos = follow_pos
			end
		end
	elseif not tpos and self.path_data then
		self.path_data = nil
		self.old_path_pos = nil
		self.old_follow_pos = nil
	end

	--this is the real time path deletion as it goes along it
	if self.isinliquid then
		self.path_data = nil
	end

	if self.path_data and #self.path_data > 0 then
		if vector.distance(acute_pos, self.path_data[1]) <= hitbox(self)[4] then
			for i = 2, #self.path_data do
				self.path_data[i-1] = self.path_data[i]
			end
			self.path_data[#self.path_data] = nil
			--if #self.path_data == 0 then
			--	self.path_data = nil
			--end
		end
	end
end