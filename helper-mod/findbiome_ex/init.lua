local S = minetest.get_translator("findbiome_ex")
local NS = function(s) return s end

findbiome = {}

local mod_biomeinfo = minetest.get_modpath("biomeinfo") ~= nil
local mg_name = minetest.get_mapgen_setting("mg_name")
local water_level = tonumber(minetest.get_mapgen_setting("water_level"))

-- Calculate the playable area of the world
local playable_limit_min, playable_limit_max
if minetest.get_mapgen_edges then
	-- Modern method by just asking Minetest
	playable_limit_min, playable_limit_max = minetest.get_mapgen_edges()
else
	-- Legacy method for older Minetest versions
	-- by calculating an estimate ourself
	-- (it's not perfect but close enough)
	local BLOCKSIZE = 16
	local mapgen_limit = tonumber(minetest.get_mapgen_setting("mapgen_limit"))
	local chunksize = tonumber(minetest.get_mapgen_setting("chunksize"))
	local limit_estimate = math.max(mapgen_limit - (chunksize + 1) * BLOCKSIZE, 0)
	playable_limit_min = vector.new(-limit_estimate, -limit_estimate, -limit_estimate)
	playable_limit_max = vector.new(limit_estimate, limit_estimate, limit_estimate)
end

-- Default parameters
---------------------

-- Resolution of search grid in nodes.
local DEFAULT_SEARCH_GRID_RESOLUTION = 64
-- Number of points checked in the square search grid (edge * edge).
local DEFAULT_CHECKED_POINTS = 128 * 128

-- End of parameters
--------------------

-- Direction table

local dirs = {
	{x = 0, y = 0, z = 1},
	{x = -1, y = 0, z = 0},
	{x = 0, y = 0, z = -1},
	{x = 1, y = 0, z = 0},
}

-- Returns true if pos is within the world boundaries
local function is_in_world(pos)
	return not (pos.x < playable_limit_min.x or pos.y < playable_limit_min.y or pos.z < playable_limit_min.z or
		pos.x > playable_limit_max.x or pos.y > playable_limit_max.y or pos.z > playable_limit_max.z)
end

-- Checks if pos is within the biome's boundaries. If it isn't, places pos inside the boundaries.
local function adjust_pos_to_biome_limits(pos, biome_id)
	local bpos = table.copy(pos)
	local biome_name = minetest.get_biome_name(biome_id)
	local biome = minetest.registered_biomes[biome_name]
	if not biome then
		minetest.log("error", "[findbiome] adjust_pos_to_biome_limits non-existing biome!")
		return bpos, true
	end
	local axes = {"y", "x", "z"}
	local out_of_bounds = false
	for a=1, #axes do
		local ax = axes[a]
		local min, max
		if biome[ax.."_min"] then
			min = biome[ax.."_min"]
		else
			min = playable_limit_min[ax]
		end
		if biome[ax.."_max"] then
			max = biome[ax.."_max"]
		else
			max = playable_limit_max[ax]
		end
		min = tonumber(min)
		max = tonumber(max)
		if bpos[ax] < min then
			out_of_bounds = true
			bpos[ax] = min
			if max-min > 16 then
				bpos[ax] = math.max(bpos[ax] + 8, playable_limit_min[ax])
			end
		end
		if bpos[ax] > max then
			out_of_bounds = true
			bpos[ax] = max
			if max-min > 16 then
				bpos[ax] = math.min(bpos[ax] - 8, playable_limit_max[ax])
			end
		end
	end
	return bpos, out_of_bounds
end

-- Find the special default biome
local function find_default_biome()
	local all_biomes = minetest.registered_biomes
	local biome_count = 0
	for b, biome in pairs(all_biomes) do
		biome_count = biome_count + 1
	end
	-- Trivial case: No biomes registered, default biome is everywhere.
	if biome_count == 0 then
		local y = minetest.get_spawn_level(0, 0)
		if not y then
			y = 0
		end
		return { x = 0, y = y, z = 0 }
	end
	local pos = {}
	-- Just check a lot of random positions
	-- It's a crappy algorithm but better than nothing.
	for i=1, 100 do
		pos.x = math.random(playable_limit_min.x, playable_limit_max.x)
		pos.y = math.random(playable_limit_min.y, playable_limit_max.y)
		pos.z = math.random(playable_limit_min.z, playable_limit_max.z)
		local biome_data = minetest.get_biome_data(pos)
		if biome_data and minetest.get_biome_name(biome_data.biome) == "default" then
			return pos
		end
	end
	return nil
end

function findbiome.find_biome(pos, biomes, res, checks)
	if not res then
		res = DEFAULT_SEARCH_GRID_RESOLUTION
	end
	if not checks then
		checks = DEFAULT_CHECKED_POINTS
	end

	pos = vector.round(pos)
	-- Pos: Starting point for biome checks. This also sets the y co-ordinate for all
	-- points checked, so the suitable biomes must be active at this y.

	-- Initial variables

	local edge_len = 1
	local edge_dist = 0
	local dir_step = 0
	local dir_ind = 1
	local success = false
	local spawn_pos
	local biome_ids

	-- Get next position on square search spiral
	local function next_pos()
		if edge_dist == edge_len then
			edge_dist = 0
			dir_ind = dir_ind + 1
			if dir_ind == 5 then
				dir_ind = 1
			end
			dir_step = dir_step + 1
			edge_len = math.floor(dir_step / 2) + 1
		end

		local dir = dirs[dir_ind]
		local move = vector.multiply(dir, res)

		edge_dist = edge_dist + 1

		return vector.add(pos, move)
	end

	-- Position search
	local function search()
		local attempt = 1
		while attempt < 3 do
			for iter = 1, checks do
				local biome_data = minetest.get_biome_data(pos)
				-- Sometimes biome_data is nil
				local biome = biome_data and biome_data.biome
				for id_ind = 1, #biome_ids do
					local biome_id = biome_ids[id_ind]
					pos = adjust_pos_to_biome_limits(pos, biome_id)
					local spos = table.copy(pos)
					if biome == biome_id then
						local good_spawn_height = pos.y <= water_level + 16 and pos.y >= water_level
						local spawn_y = minetest.get_spawn_level(spos.x, spos.z)
						if spawn_y then
							spawn_pos = {x = spos.x, y = spawn_y, z = spos.z}
						elseif not good_spawn_height then
							spawn_pos = {x = spos.x, y = spos.y, z = spos.z}
						elseif attempt >= 2 then
							spawn_pos = {x = spos.x, y = spos.y, z = spos.z}
						end
						if spawn_pos then
							local adjusted_pos, outside = adjust_pos_to_biome_limits(spawn_pos, biome_id)
							if is_in_world(spawn_pos) and not outside then
								return true
							end
						end
					end
				end

				pos = next_pos()
			end
			attempt = attempt + 1
		end
		return false
	end
	local function search_v6()
		if not mod_biomeinfo then return
			false
		end
		for iter = 1, checks do
			local found_biome = biomeinfo.get_v6_biome(pos)
			for i = 1, #biomes do
				local searched_biome = biomes[i]
				if found_biome == searched_biome then
					local spawn_y = minetest.get_spawn_level(pos.x, pos.z)
					if spawn_y then
						spawn_pos = {x = pos.x, y = spawn_y, z = pos.z}
						if is_in_world(spawn_pos) then
							return true
						end
					end
				end
			end

			pos = next_pos()
		end

		return false
	end

	if mg_name == "v6" then
		success = search_v6()
	else
		-- Table of suitable biomes
		biome_ids = {}
		for i=1, #biomes do
			local id = minetest.get_biome_id(biomes[i])
			if not id then
				return nil, false
			end
			table.insert(biome_ids, id)
		end
		success = search()
	end
	return spawn_pos, success

end

local mods_loaded = false
minetest.register_on_mods_loaded(function()
	mods_loaded = true
end)

function findbiome.list_biomes(param)
	local biomes = {}
	local b = 0
	if not mods_loaded then
		table.insert(biomes, NS("Wait until all mods have loaded!"))
		return false, biomes
	end
	if mg_name == "v6" then
		if not mod_biomeinfo then
			table.insert(biomes, NS("Not supported. The “biomeinfo” mod is required for v6 mapgen support!"))
			return false, biomes
		end
		biomes = biomeinfo.get_active_v6_biomes()
		b = #biomes
	else
		biomes = {}
		for k,v in pairs(minetest.registered_biomes) do
			local row = k .. "," .. core.registered_biomes[k].heat_point .. "," .. core.registered_biomes[k].humidity_point .. "," .. (core.registered_biomes[k].y_min or "") .. "," .. (core.registered_biomes[k].y_max or "")
			table.insert(biomes, row)
			b = b + 1
		end
	end
	if b == 0 then
		return true, biomes
	else
		table.sort(biomes)
		return true, biomes
	end
end

-- Register chat commands
do
	minetest.register_chatcommand("findbiome", {
		description = S("Find and teleport to biome"),
		params = S("<biome>"),
		privs = { debug = true, teleport = true },
		func = function(name, param)
			if not mods_loaded then
				return false
			end
			local player = minetest.get_player_by_name(name)
			if not player then
				return false, S("No player.")
			end
			local pos = player:get_pos()
			local invalid_biome = true
			if mg_name == "v6" then
				if not mod_biomeinfo then
					return false, S("Not supported. The “biomeinfo” mod is required for v6 mapgen support!")
				end
				local biomes = biomeinfo.get_active_v6_biomes()
				for b=1, #biomes do
					if param == biomes[b] then
						invalid_biome = false
						break
					end
				end
			else
				if param == "default" then
					local biome_pos = find_default_biome()
					if biome_pos then
						player:set_pos(biome_pos)
						return true, S("Biome found at @1.", minetest.pos_to_string(biome_pos))
					else
						return false, S("No biome found!")
					end
				end
				local id = minetest.get_biome_id(param)
				if id then
					invalid_biome = false
				end
			end
			if invalid_biome then
				return false, S("Biome does not exist!")
			end
			local biome_pos, success = findbiome.find_biome(pos, {param})
			if success then
				player:set_pos(biome_pos)
				return true, S("Biome found at @1.", minetest.pos_to_string(biome_pos))
			else
				return false, S("No biome found!")
			end
		end,
	})

	minetest.register_chatcommand("listbiomes", {
		description = S("List all biomes"),
		params = "",
		privs = { debug = true },
		func = function(name, param)
			local success, biomes = findbiome.list_biomes()
			-- Error checking before sending them in chat
			if success == false then -- send error message
				minetest.chat_send_player(name, S(biomes[1]))
				return false
			else -- it worked, send all biomes
				if #biomes == 0 then
					minetest.chat_send_player(name, S("No biomes."))
					return true
				else
					table.sort(biomes)
					for b=1, #biomes do
						minetest.chat_send_player(name, biomes[b])
					end
				end
				return true
			end
		end,
	})


	minetest.register_chatcommand("printbiomes", {
		description = S("Print all biomes to console"),
		params = "",
		privs = { debug = true },
		func = function(name, param)
			local success, biomes = findbiome.list_biomes()
			-- Error checking before sending them in chat
			if success == false then -- send error message
				print(S(biomes[1]))
				return false
			else -- it worked, send all biomes
				if #biomes == 0 then
					print(S("No biomes."))
					return true
				else
					table.sort(biomes)
					for b=1, #biomes do
						print(biomes[b])
					end
				end
				return true
			end
		end,
	})
end