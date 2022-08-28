------------
-- Mapgen --
------------

--------------
-- Settings --
--------------

local nest_spawning = minetest.settings:get("nest_spawning") or true

local cavern_spawning = minetest.settings:get("cavern_spawning") or false

local nest_spawn_rate = tonumber(minetest.settings:get("nest_spawn_rate")) or 64

local cavern_spawn_rate = tonumber(minetest.settings:get("cavern_spawn_rate")) or 64

---------------------
-- Local Variables --
---------------------

local random = math.random

local c_scorched_stone = minetest.get_content_id("draconis:stone_scorched")
local c_frozen_stone = minetest.get_content_id("draconis:stone_frozen")
local c_scorched_soil = minetest.get_content_id("draconis:soil_scorched")
local c_frozen_soil = minetest.get_content_id("draconis:soil_frozen")
local c_bones_fire = minetest.get_content_id("draconis:bone_pile_scorched")
local c_bones_ice = minetest.get_content_id("draconis:bone_pile_frozen")

local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")

local c_gold = c_air
if minetest.registered_nodes["default:goldblock"] then
	c_gold = minetest.get_content_id("default:goldblock")
end
local c_steel = c_air
if minetest.registered_nodes["default:steelblock"] then
	c_steel = minetest.get_content_id("default:steelblock")
end

local np_nest = {
	offset = 0,
	scale = 1,
	spread = {x=30, y=30, z=30},
	seed = -40901,
	octaves = 3,
	persist = 0.67
}

local walkable_nodes = {}

minetest.register_on_mods_loaded(function()
	for name in pairs(minetest.registered_nodes) do
		if name ~= "air" and name ~= "ignore" then
			if minetest.registered_nodes[name].walkable then
				table.insert(walkable_nodes, name)
			end
		end
	end
end)

---------------------
-- Local Utilities --
---------------------

local function get_nearest_player(pos)
	local closest_player
	local dist
	for _, player in pairs(minetest.get_connected_players()) do
		local player_pos = player:get_pos()
		if player_pos
		and (not dist
		or dist > vector.distance(pos, player_pos)) then
			dist = vector.distance(pos, player_pos)
			closest_player = player
		end
	end
	return dist or 100, closest_player
end

local function is_cold_biome(pos)
	local data = minetest.get_biome_data(pos)
	return data.heat < 45 and data.humidity < 75
end

local function is_warm_biome(pos)
	local data = minetest.get_biome_data(pos)
	return data.heat > 60 and data.humidity < 80
end

------------------
-- VM Functions --
------------------

-- Nests --

local function generate_fire_dragon_nest(minp, maxp, vm, area, data)
	local gender = "male"

	if random(2) < 2 then
		gender = "female"
	end

	local min_y = minp.y
	local max_y = maxp.y

	local min_x = minp.x
	local max_x = maxp.x
	local min_z = minp.z
	local max_z = maxp.z

	local center_x = math.floor((min_x + max_x) / 2)
	local center_y = math.floor((min_y + max_y) / 2)
	local center_z = math.floor((min_z + max_z) / 2)
	local pos = {
		x = center_x,
		y = center_y,
		z = center_z
	}

	local surface = false -- y of above surface node
	for y = max_y, 2, -1 do
		local vi = area:index(center_x, y, center_z)
		if data[vi] ~= c_air then -- if node solid
			break
		elseif data[vi] == c_air
		and data[area:index(center_x, y - 1, center_z)] ~= c_air
		and data[area:index(center_x, y - 1, center_z)] ~= c_ignore then
			surface = y
			break
		end
	end

	if not surface
	or surface - 6 < min_y then return end

	center_y = surface

	local sidelen = max_x - min_x + 1
	local chulens = {x = sidelen, y = sidelen, z = sidelen}
	local minposxyz = {x = min_x, y = min_y, z = min_z}

	local nvals_nest = minetest.get_perlin_map(np_nest, chulens):get3dMap_flat(minposxyz)

	local nixyz = 1
	for z = min_z, max_z do
		for y = min_y, max_y do
			local vi = area:index(min_x, y, z)
			for x = min_x, max_x do
				local noise = (nvals_nest[nixyz] + 1) * 7.88
				local height = math.abs(y - center_y)
				local dist_slope = (noise - height) * 0.77
				local distance = vector.distance({x = x, y = y, z = z}, {x = center_x, y = center_y, z = center_z}) - dist_slope
				-- Create Nest
				if distance < 15 - (height * 0.66)
				and distance > 4 + ((y - center_y) * 2) then
					data[vi] = c_scorched_stone
				elseif distance < 15 - (height * 0.66)
				and distance < 4 + ((y - center_y) * 2)
				and data[vi] ~= c_scorched_stone then
					data[vi] = c_air
				end
				-- Create platform to stop floating Nests
				if distance < 15 - (height * 0.33)
				and distance > 4 + ((y - center_y) * 1.5)
				and y < center_y then
					data[vi] = c_scorched_stone
				end
				-- Create Scorched Soil around nest
				if distance > 13 - (height * 0.66)
				and distance < 19 - (height * 0.66)
				and data[vi] ~= c_air
				and random(8) < 2 then
					data[vi] = c_scorched_soil
				end
				local bi = area:index(x, y - 1, z)
				-- Create scattered loot
				local loot_chance = 30
				if gender == "male" then
					loot_chance = 12
				end
				if data[bi] == c_scorched_stone
				and data[vi] == c_air then
					if random(loot_chance) < 2 then
						data[vi] = c_gold
					elseif random(24) < 2 then
						data[vi] = c_bones_fire
					end
				end
				-- Create stone pillars
				if data[bi] == c_scorched_stone
				and data[vi] == c_air
				and random(80) < 2 then
					local pillar_height = random(4, 6)
					for i = -1, pillar_height do
						local pil_i = area:index(x, y + i, z)
						data[pil_i] = c_scorched_stone
					end
				end
				nixyz = nixyz + 1
				vi = vi + 1
			end
		end
	end

	minetest.after(0.2, function()
		minetest.add_node({x = center_x, y = center_y, z = center_z}, {name = "creatura:spawn_node"})
		local meta = minetest.get_meta({x = center_x, y = center_y, z = center_z})
		meta:set_string("mob", "draconis:fire_dragon")
		meta:set_string("gender", gender)
		local _, closest_player = get_nearest_player(pos)
		if closest_player then
			local name = closest_player:get_player_name()
			local inv = minetest.get_inventory({type = "player", name = name})
			if draconis.contains_libri(inv) then
				draconis.add_page(inv, "dragons")
			end
		end
	end)
end

local function generate_ice_dragon_nest(minp, maxp, vm, area, data)
	local gender = "male"

	if random(2) < 2 then
		gender = "female"
	end

	local min_y = minp.y
	local max_y = maxp.y

	local min_x = minp.x
	local max_x = maxp.x
	local min_z = minp.z
	local max_z = maxp.z

	local center_x = math.floor((min_x + max_x) / 2)
	local center_y = math.floor((min_y + max_y) / 2)
	local center_z = math.floor((min_z + max_z) / 2)
	local pos = {
		x = center_x,
		y = center_y,
		z = center_z
	}

	local surface = false -- y of above surface node
	for y = max_y, 2, -1 do
		local vi = area:index(center_x, y, center_z)
		if data[vi] ~= c_air then -- if node solid
			break
		elseif data[vi] == c_air
		and data[area:index(center_x, y - 1, center_z)] ~= c_air
		and data[area:index(center_x, y - 1, center_z)] ~= c_ignore then
			surface = y
			break
		end
	end

	if not surface
	or surface - 6 < min_y then return end

	center_y = surface

	local sidelen = max_x - min_x + 1
	local chulens = {x = sidelen, y = sidelen, z = sidelen}
	local minposxyz = {x = min_x, y = min_y, z = min_z}

	local nvals_nest = minetest.get_perlin_map(np_nest, chulens):get3dMap_flat(minposxyz)

	local nixyz = 1
	for z = min_z, max_z do
		for y = min_y, max_y do
			local vi = area:index(min_x, y, z)
			for x = min_x, max_x do
				local noise = (nvals_nest[nixyz] + 1) * 7.88
				local height = math.abs(y - center_y)
				local dist_slope = (noise - height) * 0.77
				local distance = vector.distance({x = x, y = y, z = z}, {x = center_x, y = center_y, z = center_z}) - dist_slope
				-- Create Nest
				if distance < 15 - (height * 0.66)
				and distance > 4 + ((y - center_y) * 2) then
					data[vi] = c_frozen_stone
				elseif distance < 15 - (height * 0.66)
				and distance < 4 + ((y - center_y) * 2)
				and data[vi] ~= c_frozen_stone then
					data[vi] = c_air
				end
				-- Create platform to stop floating Nests
				if distance < 15 - (height * 0.33)
				and distance > 4 + ((y - center_y) * 1.5)
				and y < center_y then
					data[vi] = c_frozen_stone
				end
				-- Create Scorched Soil around nest
				if distance > 13 - (height * 0.66)
				and distance < 19 - (height * 0.66)
				and data[vi] ~= c_air
				and random(8) < 2 then
					data[vi] = c_frozen_soil
				end
				local bi = area:index(x, y - 1, z)
				-- Create scattered loot
				local loot_chance = 30
				if gender == "male" then
					loot_chance = 12
				end
				if data[bi] == c_frozen_stone
				and data[vi] == c_air then
					if random(loot_chance) < 2 then
						data[vi] = c_steel
					elseif random(24) < 2 then
						data[vi] = c_bones_ice
					end
				end
				-- Create stone pillars
				if data[bi] == c_frozen_stone
				and data[vi] == c_air
				and random(80) < 2 then
					local pillar_height = random(4, 6)
					for i = -1, pillar_height do
						local pil_i = area:index(x, y + i, z)
						data[pil_i] = c_frozen_stone
					end
				end
				nixyz = nixyz + 1
				vi = vi + 1
			end
		end
	end

	minetest.after(0.2, function()
		minetest.add_node({x = center_x, y = center_y, z = center_z}, {name = "creatura:spawn_node"})
		local meta = minetest.get_meta({x = center_x, y = center_y, z = center_z})
		meta:set_string("mob", "draconis:ice_dragon")
		meta:set_string("gender", gender)
		local _, closest_player = get_nearest_player(pos)
		if closest_player then
			local name = closest_player:get_player_name()
			local inv = minetest.get_inventory({type = "player", name = name})
			if draconis.contains_libri(inv) then
				draconis.add_page(inv, "dragons")
			end
		end
	end)
end

-- Nests --

local function generate_fire_dragon_cavern(minp, maxp, vm, area, data)
	local gender = "male"

	if random(2) < 2 then
		gender = "female"
	end

	local min_y = minp.y
	local max_y = maxp.y

	local min_x = minp.x
	local max_x = maxp.x
	local min_z = minp.z
	local max_z = maxp.z

	local center_x = math.floor((min_x + max_x) / 2)
	local center_y = math.floor((min_y + max_y) / 2)
	local center_z = math.floor((min_z + max_z) / 2)
	local pos = {
		x = center_x,
		y = center_y,
		z = center_z
	}

	local sidelen = max_x - min_x + 1
	local chulens = {x = sidelen, y = sidelen, z = sidelen}
	local minposxyz = {x = min_x, y = min_y, z = min_z}

	local nvals_nest = minetest.get_perlin_map(np_nest, chulens):get3dMap_flat(minposxyz)

	local nixyz = 1
	for z = min_z, max_z do
		for y = min_y, max_y do
			local vi = area:index(min_x, y, z)
			for x = min_x, max_x do
				local noise = (nvals_nest[nixyz] + 1) * 3.33
				local height = math.abs(y - center_y)
				local distance = vector.distance({x = x, y = y, z = z}, {x = center_x, y = center_y, z = center_z}) - noise
				-- Create Nest
				if distance < 33 + (4 - ((height * 0.15) * (height * 0.4))) then
					data[vi] = c_scorched_stone
					if distance < 29 + (4 - (height * 0.15) * (height * 0.4)) then
						data[vi] = c_air
					end
				end
				-- Create Stalactites
				local bi = area:index(x, y - 1, z)
				if y > center_y
				and data[vi] == c_scorched_stone
				and data[bi] == c_air then
					if random(18) == 1 then
						local len = random(3, 6)
						for i = 1, len do
							data[area:index(x, y - i, z)] = c_scorched_stone
						end
					end
				end
				-- Create scattered loot
				local loot_chance = 30
				if gender == "male" then
					loot_chance = 12
				end
				if data[bi] == c_scorched_stone
				and data[vi] == c_air then
					if random(loot_chance) < 2 then
						data[vi] = c_gold
					elseif random(24) < 2 then
						data[vi] = c_bones_fire
					end
				end
				nixyz = nixyz + 1
				vi = vi + 1
			end
		end
	end

	minetest.after(0.2, function()
		minetest.add_node({x = center_x, y = center_y, z = center_z}, {name = "creatura:spawn_node"})
		local meta = minetest.get_meta({x = center_x, y = center_y, z = center_z})
		meta:set_string("mob", "draconis:fire_dragon")
		meta:set_string("gender", gender)
		local _, closest_player = get_nearest_player(pos)
		if closest_player then
			local name = closest_player:get_player_name()
			local inv = minetest.get_inventory({type = "player", name = name})
			if draconis.contains_libri(inv) then
				draconis.add_page(inv, "dragons")
			end
		end
	end)
end

local function generate_ice_dragon_cavern(minp, maxp, vm, area, data)
	local gender = "male"

	if random(2) < 2 then
		gender = "female"
	end

	local min_y = minp.y
	local max_y = maxp.y

	local min_x = minp.x
	local max_x = maxp.x
	local min_z = minp.z
	local max_z = maxp.z

	local center_x = math.floor((min_x + max_x) / 2)
	local center_y = math.floor((min_y + max_y) / 2)
	local center_z = math.floor((min_z + max_z) / 2)
	local pos = {
		x = center_x,
		y = center_y,
		z = center_z
	}

	local sidelen = max_x - min_x + 1
	local chulens = {x = sidelen, y = sidelen, z = sidelen}
	local minposxyz = {x = min_x, y = min_y, z = min_z}

	local nvals_nest = minetest.get_perlin_map(np_nest, chulens):get3dMap_flat(minposxyz)

	local nixyz = 1
	for z = min_z, max_z do
		for y = min_y, max_y do
			local vi = area:index(min_x, y, z)
			for x = min_x, max_x do
				local noise = (nvals_nest[nixyz] + 1) * 3.33
				local height = math.abs(y - center_y)
				local distance = vector.distance({x = x, y = y, z = z}, {x = center_x, y = center_y, z = center_z}) - noise
				-- Create Nest
				if distance < 33 + (4 - ((height * 0.15) * (height * 0.4))) then
					data[vi] = c_frozen_stone
					if distance < 29 + (4 - (height * 0.15) * (height * 0.4)) then
						data[vi] = c_air
					end
				end
				-- Create Stalactites
				local bi = area:index(x, y - 1, z)
				if y > center_y
				and data[vi] == c_frozen_stone
				and data[bi] == c_air then
					if random(18) < 3 then
						local len = random(3, 6)
						for i = 1, len do
							data[area:index(x, y - i, z)] = c_frozen_stone
						end
					end
				end
				-- Create scattered loot
				local loot_chance = 30
				if gender == "male" then
					loot_chance = 12
				end
				if data[bi] == c_frozen_stone
				and data[vi] == c_air then
					if random(loot_chance) < 2 then
						data[vi] = c_steel
					elseif random(24) < 2 then
						data[vi] = c_bones_ice
					end
				end
				nixyz = nixyz + 1
				vi = vi + 1
			end
		end
	end

	minetest.after(0.2, function()
		minetest.add_node({x = center_x, y = center_y, z = center_z}, {name = "creatura:spawn_node"})
		local meta = minetest.get_meta({x = center_x, y = center_y, z = center_z})
		meta:set_string("mob", "draconis:ice_dragon")
		meta:set_string("gender", gender)
		local _, closest_player = get_nearest_player(pos)
		if closest_player then
			local name = closest_player:get_player_name()
			local inv = minetest.get_inventory({type = "player", name = name})
			if draconis.contains_libri(inv) then
				draconis.add_page(inv, "dragons")
			end
		end
	end)
end

--------------
-- Spawning --
--------------

creatura.register_on_spawn("draconis:fire_dragon", function(self, pos)
	self.nest_pos = pos
	self:memorize("nest_pos", self.nest_pos)
end)

creatura.register_on_spawn("draconis:ice_dragon", function(self, pos)
	self.nest_pos = pos
	self:memorize("nest_pos", self.nest_pos)
end)

----------------
-- Generation --
----------------

local function average(tbl)
	local sum = 0
	for _,v in pairs(tbl) do -- Get the sum of all numbers in t
	  sum = sum + v
	end
	return sum / #tbl
end

minetest.register_on_generated(function(minp, maxp)
	local min_y, max_y = minp.y, maxp.y
	local min_x, max_x = minp.x, maxp.x
	local min_z, max_z = minp.z, maxp.z

	local center_x = math.floor((min_x + max_x) / 2)
	local center_y = math.floor((min_y + max_y) / 2)
	local center_z = math.floor((min_z + max_z) / 2)

	local pos = {x = center_x, y = center_y, z = center_z}

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
	local data = vm:get_data()

	if nest_spawning
	and random(nest_spawn_rate) < 2 then

		local heights = {}

		for z = min_z + 8, max_z - 7, 8 do
			for x = min_x + 8, max_x - 7, 8 do
				for y = min_y, max_y do
					local vi = area:index(x, y, z)
					local vi_name = minetest.get_name_from_content_id(data[vi])
					if not creatura.get_node_def(vi_name).walkable then
						table.insert(heights, y)
						break
					end
				end
			end
		end

		local avg_height = average(heights)

		if avg_height > 4 then

			pos.y = avg_height

			local heightmap = minetest.get_mapgen_object("heightmap")

			if heightmap
			and #heightmap > 0 then
				pos.y = heightmap[math.floor(#heightmap / 2)]
			end

			if is_cold_biome(pos) then
				generate_ice_dragon_nest(minp, maxp, vm, area, data)
				vm:set_data(data)
				vm:set_lighting({day = 0, night = 0})
				vm:calc_lighting()
				vm:update_liquids()
				vm:write_to_map()
			elseif is_warm_biome(pos) then
				generate_fire_dragon_nest(minp, maxp, vm, area, data)
				vm:set_data(data)
				vm:set_lighting({day = 0, night = 0})
				vm:calc_lighting()
				vm:update_liquids()
				vm:write_to_map()
			end
		end
	elseif cavern_spawning
	and random(cavern_spawn_rate) < 2
	and max_y < 0 then
		if is_cold_biome(pos) then
			generate_ice_dragon_cavern(minp, maxp, vm, area, data)
			vm:set_data(data)
			vm:set_lighting({day = 0, night = 0})
			vm:calc_lighting()
			vm:update_liquids()
			vm:write_to_map()
		elseif is_warm_biome(pos) then
			generate_fire_dragon_cavern(minp, maxp, vm, area, data)
			vm:set_data(data)
			vm:set_lighting({day = 0, night = 0})
			vm:calc_lighting()
			vm:update_liquids()
			vm:write_to_map()
		end
	end
end)