--------------
-- Spawning --
--------------
--- Ver 1.0 --

local random = math.random

local find_node_height = 32

function draconis.spawn(name, biomes, nodes, min_time, max_time, min_rad, max_rad)
    if minetest.registered_entities[name] then
		for _,player in ipairs(minetest.get_connected_players()) do
			local mobs_amount = 0
			for _, entity in pairs(minetest.luaentities) do
				if entity.name == name then
					local ent_pos = entity.object:get_pos()
					if ent_pos and vector.distance(player:get_pos(), ent_pos) <= max_rad then
						mobs_amount = mobs_amount + 1
					end
				end
            end

            if mobs_amount >= 1 then
				return
			end

			local int = {-1,1}
			local pos = vector.floor(vector.add(player:get_pos(),0.5))

			local x,z

			--this is used to determine the axis buffer from the player
			local axis = math.random(0,1)

			--cast towards the direction
			if axis == 0 then --x
				x = pos.x + math.random(min_rad,max_rad)*int[math.random(1,2)]
				z = pos.z + math.random(-max_rad,max_rad)
			else --z
				z = pos.z + math.random(min_rad,max_rad)*int[math.random(1,2)]
				x = pos.x + math.random(-max_rad,max_rad)
			end

			local spawner = minetest.find_nodes_in_area_under_air(
				vector.new(x,pos.y-find_node_height,z),
                vector.new(x,pos.y+find_node_height,z), nodes)

            if #spawner > 0 then
                local mob_pos = spawner[1]

                local time = minetest.get_timeofday()
                if not time then return end
                time = time * 24000
				if time > max_time
                or time < min_time then
					return
                end

                if minetest.is_protected(mob_pos, "") then
					return
				end

				if mob_pos.y > 310
                or mob_pos.y < 1 then
					return
                end

                local biome_data = minetest.get_biome_data(mob_pos)
                if not biome_data then
                    return
                end

                local biome_name = minetest.get_biome_name(biome_data.biome)
                for i = 1, #biomes do
                    if biome_name == biomes[i] then
                        local mobdef = minetest.registered_entities[name]
                        mob_pos.y = mob_pos.y + math.abs(mobdef.collisionbox[2])
                        minetest.add_entity(mob_pos, name)
                        return
                    end
                end
			end
		end
	end
end

function draconis.register_spawn(def, interval, chance)
	local spawn_timer = 0
	if type(chance) ~= "number"
	or chance < 1 then
		chance = 1
	end
	minetest.register_globalstep(function(dtime)
		spawn_timer = spawn_timer + dtime
		if spawn_timer > interval then
            if random(1, chance) == 1 then
				draconis.spawn(
                    def.name,
                    def.biomes or {"grassland", "savanna"},
                    def.nodes or {"group:soil", "group:stone"},
					def.min_time or 0,
					def.max_time or 24000,
					def.min_rad or 24,
					def.max_rad or 256
				)
			end
			spawn_timer = 0
		end
	end)
end