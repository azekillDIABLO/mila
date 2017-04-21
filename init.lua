--define a global mila table
mila = {}

--define the version of the engine
mila.version = "1.0"

--set little things, for deletion
clean = false
ent_num = 0

--define modpath, not local for other files
milapath = minetest.get_modpath("mila") 

--open the settings file (you can change things in it!!!)
dofile(milapath .."/settings.lua")

--open the misc files, for registering items, node, crafts
dofile(milapath .."/misc.lua")

-- ==================
-- General functions:

local cid_data = {}
minetest.after(0, function()
	for name, def in pairs(minetest.registered_nodes) do
		cid_data[minetest.get_content_id(name)] = {
			name = name,
			drops = def.drops,
			flammable = def.groups.flammable,
			on_blast = def.on_blast,
		}
	end
end)

local function calc_velocity(pos1, pos2, old_vel, power)
	-- Avoid errors caused by a vector of zero length
	if vector.equals(pos1, pos2) then
		return old_vel
	end

	local vel = vector.direction(pos1, pos2)
	vel = vector.normalize(vel)
	vel = vector.multiply(vel, power)

	-- Divide by distance
	local dist = vector.distance(pos1, pos2)
	dist = math.max(dist, 1)
	vel = vector.divide(vel, dist)

	-- Add old velocity
	vel = vector.add(vel, old_vel)

	-- randomize it a bit
	vel = vector.add(vel, {
		x = math.random() - 0.5,
		y = math.random() - 0.5,
		z = math.random() - 0.5,
	})

	-- Limit to terminal velocity
	dist = vector.length(vel)
	if dist > 250 then
		vel = vector.divide(vel, dist / 250)
	end
	return vel
end

local function entity_physics(pos, radius, drops)
	local objs = minetest.get_objects_inside_radius(pos, radius)
	for _, obj in pairs(objs) do
		local obj_pos = obj:getpos()
		local dist = math.max(1, vector.distance(pos, obj_pos))

		local damage = (4 / dist) * radius
		if obj:is_player() then
			-- currently the engine has no method to set
			-- player velocity. See #2960
			-- instead, we knock the player back 1.0 node, and slightly upwards
			local dir = vector.normalize(vector.subtract(obj_pos, pos))
			local moveoff = vector.multiply(dir, dist + 1.0)
			local newpos = vector.add(pos, moveoff)
			newpos = vector.add(newpos, {x = 0, y = 0.2, z = 0})
			obj:setpos(newpos)

			obj:set_hp(obj:get_hp() - damage)
		else
			local do_damage = true
			local do_knockback = true
			local entity_drops = {}
			local luaobj = obj:get_luaentity()
			local objdef = minetest.registered_entities[luaobj.name]

			if objdef and objdef.on_blast then
				do_damage, do_knockback, entity_drops = objdef.on_blast(luaobj, damage)
			end

			if do_knockback then
				local obj_vel = obj:getvelocity()
				obj:setvelocity(calc_velocity(pos, obj_pos,
						obj_vel, radius * 10))
			end
			if do_damage then
				if not obj:get_armor_groups().immortal then
					obj:punch(obj, 1.0, {
						full_punch_interval = 1.0,
						damage_groups = {fleshy = damage},
					}, nil)
				end
			end
			for _, item in pairs(entity_drops) do
				add_drop(drops, item)
			end
		end
	end
end

local function add_effects(pos, radius, drops)
	minetest.add_particle({
		pos = pos,
		velocity = vector.new(),
		acceleration = vector.new(),
		expirationtime = 0.4,
		size = radius * 10,
		collisiondetection = false,
		vertical = false,
		texture = "mila_fireball.png",
	})
	minetest.add_particlespawner({
		amount = 64,
		time = 0.5,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
		minvel = {x = -10, y = -10, z = -10},
		maxvel = {x = 10, y = 10, z = 10},
		minacc = vector.new(),
		maxacc = vector.new(),
		minexptime = 1,
		maxexptime = 2.5,
		minsize = radius * 3,
		maxsize = radius * 5,
		texture = "mila_boom.png",
	})

	-- we just dropped some items. Look at the items entities and pick
	-- one of them to use as texture
	local texture = "mila_fireball.png" --fallback texture
	local most = 0
	for name, stack in pairs(drops) do
		local count = stack:get_count()
		if count > most then
			most = count
			local def = minetest.registered_nodes[name]
			if def and def.tiles and def.tiles[1] then
				texture = def.tiles[1]
			end
		end
	end

	minetest.add_particlespawner({
		amount = 64,
		time = 0.1,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
		minvel = {x = -3, y = 0, z = -3},
		maxvel = {x = 3, y = 5,  z = 3},
		minacc = {x = 0, y = -10, z = 0},
		maxacc = {x = 0, y = -10, z = 0},
		minexptime = 0.8,
		maxexptime = 2.0,
		minsize = radius * 0.66,
		maxsize = radius * 2,
		texture = texture,
		collisiondetection = true,
	})
end

local function rand_pos(center, pos, radius)
	local def
	local reg_nodes = minetest.registered_nodes
	local i = 0
	repeat
		-- Give up and use the center if this takes too long
		if i > 4 then
			pos.x, pos.z = center.x, center.z
			break
		end
		pos.x = center.x + math.random(-radius, radius)
		pos.z = center.z + math.random(-radius, radius)
		def = reg_nodes[minetest.get_node(pos).name]
		i = i + 1
	until def and not def.walkable
end

local function eject_drops(drops, pos, radius)
	local drop_pos = vector.new(pos)
	for _, item in pairs(drops) do
		local count = math.min(item:get_count(), item:get_stack_max())
		while count > 0 do
			local take = math.max(1,math.min(radius * radius,
					count,
					item:get_stack_max()))
			rand_pos(pos, drop_pos, radius)
			local dropitem = ItemStack(item)
			dropitem:set_count(take)
			local obj = minetest.add_item(drop_pos, dropitem)
			if obj then
				obj:get_luaentity().collect = true
				obj:setacceleration({x = 0, y = -10, z = 0})
				obj:setvelocity({x = math.random(-3, 3),
						y = math.random(0, 10),
						z = math.random(-3, 3)})
			end
			count = count - take
		end
	end
end

function mila_boom(pos, mob, power)
	minetest.sound_play("mila_boom", {pos = pos, gain = 1.5, max_hear_distance = 2*64})
	local drops, radius = explode(mob, power, ignore_protection, ignore_on_blast)
	-- append entity drops
	local damage_radius = power
	entity_physics(pos, damage_radius, drops)
	eject_drops(drops, pos, radius)
	add_effects(pos, power, drops)
end

-- loss probabilities array (one in X will be lost)
local loss_prob = {}

loss_prob["default:cobble"] = 3
loss_prob["default:dirt"] = 4

local function add_drop(drops, item)
	item = ItemStack(item)
	local name = item:get_name()
	if loss_prob[name] ~= nil and math.random(1, loss_prob[name]) == 1 then
		return
	end

	local drop = drops[name]
	if drop == nil then
		drops[name] = item
	else
		drop:set_count(drop:get_count() + item:get_count())
	end
end

local function destroy(drops, npos, cid, c_air, c_fire, on_blast_queue, ignore_protection, ignore_on_blast)
	if not ignore_protection and minetest.is_protected(npos, "") then
		return cid
	end

	local def = cid_data[cid]

	if not def then
		return c_air
	elseif not ignore_on_blast and def.on_blast then
		on_blast_queue[#on_blast_queue + 1] = {pos = vector.new(npos), on_blast = def.on_blast}
		return cid
	elseif def.flammable then
		return c_fire
	else
		local node_drops = minetest.get_node_drops(def.name, "")
		for _, item in pairs(node_drops) do
			add_drop(drops, item)
		end
		return c_air
	end
end

function explode(mob, radius, ignore_protection, ignore_on_blast)
	local mobposition = mob:getpos()
	pos = vector.round(mobposition)
	-- scan for adjacent TNT nodes first, and enlarge the explosion
	local vm1 = VoxelManip()
	local p1 = vector.subtract(pos, 2)
	local p2 = vector.add(pos, 2)
	local minp, maxp = vm1:read_from_map(p1, p2)
	local a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local data = vm1:get_data()
	local count = 0
	local c_tnt = minetest.get_content_id("tnt:tnt")
	local c_tnt_burning = minetest.get_content_id("tnt:tnt_burning")
	local c_tnt_boom = minetest.get_content_id("tnt:boom")
	local c_air = minetest.get_content_id("air")

	for z = pos.z - 2, pos.z + 2 do
	for y = pos.y - 2, pos.y + 2 do
		local vi = a:index(pos.x - 2, y, z)
		for x = pos.x - 2, pos.x + 2 do
			local cid = data[vi]
			if cid == c_tnt or cid == c_tnt_boom or cid == c_tnt_burning then
				count = count + 1
				data[vi] = c_air
			end
			vi = vi + 1
		end
	end
	end

	vm1:set_data(data)
	vm1:write_to_map()

	-- recalculate new radius
	radius = math.floor(radius * math.pow(count, 1/3))

	-- perform the explosion
	local vm = VoxelManip()
	local pr = PseudoRandom(os.time())
	p1 = vector.subtract(pos, radius)
	p2 = vector.add(pos, radius)
	minp, maxp = vm:read_from_map(p1, p2)
	a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	data = vm:get_data()

	local drops = {}
	local on_blast_queue = {}

	local c_fire = minetest.get_content_id("fire:basic_flame")
	for z = -radius, radius do
	for y = -radius, radius do
	local vi = a:index(pos.x + (-radius), pos.y + y, pos.z + z)
	for x = -radius, radius do
		local r = vector.length(vector.new(x, y, z))
		if (radius * radius) / (r * r) >= (pr:next(80, 125) / 100) then
			local cid = data[vi]
			local p = {x = pos.x + x, y = pos.y + y, z = pos.z + z}
			if cid ~= c_air then
				data[vi] = destroy(drops, p, cid, c_air, c_fire,
					on_blast_queue, ignore_protection,
					ignore_on_blast)
			end
		end
		vi = vi + 1
	end
	end
	end

	vm:set_data(data)
	vm:write_to_map()
	vm:update_map()
	vm:update_liquids()

	-- call check_single_for_falling for everything within 1.5x blast radius
	for y = -radius * 1.5, radius * 1.5 do
	for z = -radius * 1.5, radius * 1.5 do
	for x = -radius * 1.5, radius * 1.5 do
		local rad = {x = x, y = y, z = z}
		local s = vector.add(pos, rad)
		local r = vector.length(rad)
		if r / radius < 1.4 then
			minetest.check_single_for_falling(s)
		end
	end
	end
	end

	for _, queued_data in pairs(on_blast_queue) do
		local dist = math.max(1, vector.distance(queued_data.pos, pos))
		local intensity = (radius * radius) / (dist * dist)
		local node_drops = queued_data.on_blast(queued_data.pos, intensity)
		if node_drops then
			for _, item in pairs(node_drops) do
				add_drop(drops, item)
			end
		end
	end

	return drops, radius
end

----------------------------------------------------------

local function simulate_tnt(mob, player)
	local mobposition = mob:getpos()
	local mobe = mob:get_luaentity()
	local playerposition = player:getpos()	
	local direction = vector.direction(mobposition,playerposition)
	local distance = vector.distance(mobposition,playerposition)
	
	if distance > 1.5 then		
		minetest.add_particle({
			pos = mobposition,
			velocity = {x = 0, y = 0, z = 0},
			acceleration = {x = 0, y = 0, z = 0},
			expirationtime = 2,
			size = 30,
			collisiondetection = false,
			vertical = false,
			texture = "mila_fireball.png",
		})
		minetest.add_particlespawner({
			amount = 64,
			time = 0.5,
			minpos = {x = mobposition.x-1, y = mobposition.y-1, z = mobposition.z-1},
			maxpos = {x = mobposition.x+1, y = mobposition.y+1, z = mobposition.z+1},
			minvel = {x = -10, y = -10, z = -10},
			maxvel = {x = 10, y = 10, z = 10},
			minacc = {x = -10, y = -10, z = -10},
			maxacc = {x = 10, y = -10, z = 10},
			minexptime = 1,
			maxexptime = 2.5,
			minsize = 5,
			maxsize = 8,
			texture = "mila_boom.png",
		})
	end
end

local function find_entities(mob, range)
		--find entities
		local pos = mob:getpos()
		local entitylist = minetest.get_objects_inside_radius(pos, range)
		if not entitylist then return end

		--list players and mobs
		local moblist = {}
		local playerlist = {}

		for _,entity in pairs(entitylist) do
			if entity:is_player() then
				playerlist[#playerlist+1] = entity
			elseif entity.mobengine and entity.mobengine == "milamob" then
				if entity ~= mob then
					moblist[#moblist+1] = entity
				end
			end
		end

		return moblist, playerlist
end

local function move_to_player(mob, player)
	local mobposition = mob:getpos()
	local mobe = mob:get_luaentity()
	local playerposition = player:getpos()	
	local node = minetest.get_node(mobposition)
	local direction = vector.direction(mobposition,playerposition)
	local distance = vector.distance(mobposition,playerposition)
	
	if distance > 1.5 then
		if node.name == "default:water_source" or node.name == "default:river_water_source" or node.name == "default:water_flowing" or node.name == "default:river_water_flowing" then
			mob:setvelocity({
				x=mobe.speed*0.7*direction.x,
				y=mobe.speed*0.7*direction.y+1, 	-- the mob floats but swim towards you, even if slowed
				z=mobe.speed*0.7*direction.z			
			})
		else
			mob:setvelocity({
				x=mobe.speed*direction.x,
				y=-mobe.gravity, 	-- fall_speed must be negative to make 
				z=mobe.speed*direction.z			-- the mob fall in the right direction
			})
		end
	end
end

local function look_to_player(mob, player)
	local mobposition = mob:getpos()
	local mobe = mob:get_luaentity()
	local playerposition = player:getpos()
	local node = minetest.get_node(mobposition)

	local direction = vector.direction(mobposition,playerposition)
	local distance = vector.distance(mobposition,playerposition)
	if node.name == "default:water_source" or node.name == "default:river_water_source" or node.name == "default:water_flowing" or node.name == "default:river_water_flowing" then
		mob:setvelocity({
			x=0.01*direction.x,
			y=2, 	-- the mob floats but swim towards you, even if slowed
			z=0.01*direction.z			
		})
	else
		mob:setvelocity({
			x=0.01*direction.x,
			y=-mobe.gravity, 	-- fall_speed must be negative to make 
			z=0.01*direction.z			-- the mob fall in the right direction
		})
	end
end


local function move_random(self)
	local random = math.random(1, 20)
	local vel = self.object:getvelocity()
	local mob = self.object
	local pos = mob:getpos()	
	local node = minetest.get_node(pos)
	
	--hackiest way ever to know if in water
	if node.name == "default:water_source" or node.name == "default:river_water_source" or node.name == "default:water_flowing" or node.name == "default:river_water_flowing" then
		--move randomly (swimming)
		if random < 5 then -- set a new course
			self.object:setvelocity({
				x=math.random(-self.speed, self.speed),
				y=math.random(1, self.speed),
				z=math.random(-self.speed, self.speed)
			})
		elseif random < 10 then -- slow down
			self.object:setvelocity({
				x = vel.x/3,
				y = 1,
				z = vel.z/3,
			})
		else
			self.object:setvelocity({
				x = vel.x,
				y = 1,
				z = vel.z,
			})
		end
	else
		--move randomly and fall
		if random < 5 then -- set a new course
			self.object:setvelocity({
				x=math.random(-self.speed, self.speed),
				y=math.random(-self.speed, self.speed)-self.gravity,
				z=math.random(-self.speed, self.speed)
			})
		elseif random < 10 then -- slow down
			self.object:setvelocity({
				x = vel.x/3,
				y = vel.y/3-self.gravity,
				z = vel.z/3,
			})
		else
			self.object:setvelocity({
				x = vel.x,
				y = vel.y-self.gravity,
				z = vel.z,
			})
		end
	end
end

local function do_sounds_random(self)
	local random = math.random(1, 20)
	local mob = self.object
	local pos = mob:getpos()
	if random < 3 then -- play sounds for mob
		minetest.sound_play(self.sounds, {pos = pos, gain = 1.8, max_hear_distance = 30})	
	end
end

-- ==========================
-- Activity

--checks and actions for every entity
local mila_act = function(self,dtime)
	self.stepcounter = self.stepcounter + dtime
	if self.stepcounter > mila.globalcounter then
		self.stepcounter = 0
	else
		return
	end

	local mobe = self.object
	local mobposition = mobe:getpos()
	local mobname = self.name
	local hp = mobe:get_hp()
	local L_hp = hp/self.hp_max*205 --I seriousely love maths
	local hpi = self.hp_max/5
	
	if mila.nametag == 1 then --add health in coloured numbers and mob name
		mobe:set_nametag_attributes({
			color = {a=255, r=95, g=L_hp, b=5}, --goes from a greenish color to dark red
			text = "[" .. mobname .."] ".. hp .."/".. self.hp_max,
		})
	elseif mila.nametag == 2 then --add coloured health bar 
		if hp == self.hp_max then
			mobe:set_nametag_attributes({ --green
				color = {a=255, r=25, g=255, b=5}, 
				text = "_____",
			})
		elseif hp > hpi*4 then
			mobe:set_nametag_attributes({ --dark green
				color = {a=255, r=75, g=185, b=5}, 
				text = "____",
			})
		elseif hp > hpi*3 then
			mobe:set_nametag_attributes({ --yellow
				color = {a=255, r=115, g=115, b=5}, 
				text = "___",
			})
		elseif hp > hpi*2 then
			mobe:set_nametag_attributes({ --orange
				color = {a=255, r=185, g=75, b=5}, 
				text = "__",
			})
		elseif hp > hpi*1 then
			mobe:set_nametag_attributes({ --red
				color = {a=255, r=255, g=25, b=5}, 
				text = "_",
			})
		end
	elseif mila.nametag == 3 then --add colored shape
		mobe:set_nametag_attributes({
			color = {a=255, r=95, g=L_hp, b=5}, --goes from a greenish color to dark red
			text = "#",
		}) 
	elseif mila.nametag == 4 then --disable nametag
		mobe:set_nametag_attributes({
			color = {a=0, r=0, g=0, b=0}, 
			text = "",
		})
	end
	
	--delete with /mila_clean command
	if clean == true then
		mobe:set_hp(0)
		mobe:remove()
		ent_num = ent_num-1
		--set_hp to 0, then force death; just to be sure.
	end
	
	--prevent mob overhaul
	if ent_num > mila.maxhandled*1.7 then
		mobe:set_hp(0)
		mobe:remove()
		ent_num = ent_num-1
		--set_hp to 0, then force death; just to be sure.
	end
	
	--play a random sound
	do_sounds_random(self)
	
--##MAKE MOB PASSIVE IF PEACEFUL IS ACTIVED
	if mila.peaceful == true then
		if self.status == "hostile" or self.status == "shooter" then
			mobe:set_hp(0)
			mobe:remove()
			ent_num = ent_num-1
		end
	end
	
--##HOSTILE CODE
	if self.status == "hostile" then
		-- check for a target
		if self.target and vector.distance(mobposition, self.target:getpos()) > self.range then
			-- previously acquired target now out of range
			self.target = nil
		end

		if not self.target then

			local playerlist = nil
			local moblist = nil
			moblist, playerlist  = find_entities(self.object, self.view_range)

			-- if players found, choose one
			if playerlist and #playerlist > 0 then
				self.target = playerlist[math.random(1,#playerlist)]	
			end
		end

		if self.target and vector.distance(mobposition, self.target:getpos()) < self.range then 
			minetest.debug("M.I.L.A " ..mila.version..": A mob is attacking!")

			local hptarget = self.target:get_hp()

			self.target:set_hp(hptarget - self.damage)
			self.object:setvelocity({x=0,y=-self.gravity,z=0})
		elseif self.target then
			move_to_player(self.object, self.target)
		else
			move_random(self)
		end
--##SHOOTER CODE
	elseif self.status == "shooter" then
		-- check for a target
		if self.target and vector.distance(mobposition, self.target:getpos()) > self.range then
			-- previously acquired target now out of range
			self.target = nil
		end

		if not self.target then

			local playerlist = nil
			local moblist = nil
			moblist, playerlist  = find_entities(self.object, self.view_range)

			-- if players found, choose one
			if playerlist and #playerlist > 0 then
				self.target = playerlist[math.random(1,#playerlist)]	
			end
		end

		if self.target and vector.distance(mobposition, self.target:getpos()) < self.range then 
			minetest.debug("M.I.L.A " ..mila.version..": A mob is shooting!")
			--shoot arrow
			look_to_player(self.object, self.target)
			minetest.add_entity(mobposition, self.arrow)
		elseif self.target then
			move_to_player(self.object, self.target)
		else
			move_random(self)
		end
--##ARROW CODE
	elseif self.status == "arrow" then
		-- check for a target
		if self.target and vector.distance(mobposition, self.target:getpos()) > self.range then
			-- previously acquired target now out of range
			self.target = nil			
		end

		if not self.target then
		
			local playerlist = nil
			local moblist = nil
			moblist, playerlist  = find_entities(self.object, self.range)

			-- if players found, choose one
			if playerlist and #playerlist > 0 then
				self.target = playerlist[math.random(1,#playerlist)]	
			end
		end
		if self.target and vector.distance(mobposition, self.target:getpos()) < 2 then 
			minetest.debug("M.I.L.A " ..mila.version..": A arrow is hitting target!")
			local hptarget = self.target:get_hp()
			self.target:set_hp(hptarget - self.damage)
			mobe:remove()
			ent_num = ent_num-1
		elseif self.target and vector.distance(mobposition, self.target:getpos()) > self.range then 
			mobe:remove()
			ent_num = ent_num-1
		elseif not self.target then 
			mobe:remove()
			ent_num = ent_num-1
		end
--##BOMBER CODE
	elseif self.status == "bomber" then

		-- check for a target
		if self.target and vector.distance(mobposition, self.target:getpos()) > self.range then
			-- previously acquired target now out of range
			self.target = nil
		end

		if not self.target then

			local playerlist = nil
			local moblist = nil
			moblist, playerlist  = find_entities(self.object, self.view_range)

			-- if players found, choose one
			if playerlist and #playerlist > 0 then
				self.target = playerlist[math.random(1,#playerlist)]	
			end
		end

		if self.target and vector.distance(mobposition, self.target:getpos()) < self.range then 
			minetest.debug("M.I.L.A " ..mila.version..": A mob is exploding!")
			--explosion system, now really working :)
			if mila.break_blocks == true then
				minetest.set_node(mobposition, {name="tnt:tnt_burning"})
				local blastpower = self.damage/3
				mila_boom(mobposition, self.object, blastpower)--blow up (we still have some TNT projections)
			elseif mila.break_blocks == false then
				local hptarget = self.target:get_hp()
				simulate_tnt(self.object, self.target)
				self.target:set_hp(hptarget - self.damage)
				minetest.sound_play("mila_boom", {pos = pos, gain = 1.5, max_hear_distance = 2*64})
			end
			mobe:remove()
			ent_num = ent_num-1
		elseif self.target then
			move_to_player(self.object, self.target)
		else
			move_random(self)
		end
--##FIREBALL CODE
	elseif self.status == "fireball" then
		-- check for a target
		if self.target and vector.distance(mobposition, self.target:getpos()) > self.range then
			-- previously acquired target now out of range
			self.target = nil			
		end

		if not self.target then
		
			local playerlist = nil
			local moblist = nil
			moblist, playerlist  = find_entities(self.object, self.range)

			-- if players found, choose one
			if playerlist and #playerlist > 0 then
				self.target = playerlist[math.random(1,#playerlist)]	
			end
		end
		if self.target and vector.distance(mobposition, self.target:getpos()) < 4 then 
			minetest.debug("M.I.L.A " ..mila.version..": A fireball is hitting target!")
			if mila.break_blocks == true then
				--explosion system, now really working :)
				minetest.set_node(mobposition, {name="tnt:tnt_burning"})
				local blastpower = self.damage/3
				mila_boom(mobposition, self.object, blastpower)--blow up (we still have some TNT projections)
			elseif mila.break_blocks == false then
				local hptarget = self.target:get_hp()
				simulate_tnt(self.object, self.target)
				self.target:set_hp(hptarget - self.damage)
				minetest.sound_play("mila_boom", {pos = pos, gain = 1.5, max_hear_distance = 2*64})
			end
			mobe:remove()
			ent_num = ent_num-1
		elseif self.target and vector.distance(mobposition, self.target:getpos()) > self.range then 
			mobe:remove()
			ent_num = ent_num-1
		elseif not self.target then 
			mobe:remove()
			ent_num = ent_num-1
		end
--##PASSIVE CODE
	elseif self.status == "passive" then
		move_random(self)
--##RE CODE (Rotating Entity)
	elseif self.status == "re" then
		local look_at = mobe:getyaw()
		self.object:setyaw(look_at+0.5)	 -- it is very useful for doing tests, powerups or objects on a pedestal.		 
		self.object:setvelocity({x=0,y=-self.gravity,z=0}) 
	end
end

--debug info

if mila.nametag == 1 then --add health in coloured numbers and mob name
	minetest.debug("M.I.L.A " ..mila.version..": Nametag with mob name and health in numbers actived!")
elseif mila.nametag == 2 then --add coloured health bar 
	minetest.debug("M.I.L.A " ..mila.version..": Nametag with coloured healthbar activated!")
elseif mila.nametag == 3 then --add colored shape
	minetest.debug("M.I.L.A " ..mila.version..": Nametag with color indicator activated!")
elseif mila.nametag == 4 then --disable nametag
	minetest.debug("M.I.L.A " ..mila.version..": Nametag disabled!")
end

if mila.break_blocks == false then 
	minetest.debug("M.I.L.A " ..mila.version..": Mob explosions can't destroy blocks!")
elseif mila.break_blocks == true then 
	minetest.debug("M.I.L.A " ..mila.version..": Mob explosions can destroy blocks!")
end

if mila.peaceful == true then
	minetest.debug("M.I.L.A " ..mila.version..": Only peaceful mobs can spawn!")
elseif mila.peaceful == false then
	minetest.debug("M.I.L.A " ..mila.version..": All type of mobs can spawn!")
end

--first things we need to do with the entity

local mila_first = function(self,dtime)
	local mobe = self.object
	local mobposition = mobe:getpos()
	--add a counter to prevent entity overload
	ent_num = ent_num+1
	
	--##ARROW & FIREBALL CODE
	if self.status == "arrow" or self.status == "fireball" then
		-- check for a target
		if self.target and vector.distance(mobposition, self.target:getpos()) > self.range then
			-- previously acquired target now out of range
			self.target = nil			
		end

		if not self.target then
		
			local playerlist = nil
			local moblist = nil
			moblist, playerlist  = find_entities(self.object, self.range)

			-- if players found, choose one
			if playerlist and #playerlist > 0 then
				self.target = playerlist[math.random(1,#playerlist)]	
			end
		end
		if self.target then
			move_to_player(self.object, self.target)
		else
			mobe:remove()
			ent_num = ent_num-1
		end	
	end
end

--bleed and other on punch

if bleed_type == 1 then
	minetest.debug("M.I.L.A " ..mila.version..": Realistic Blood Actived!")
elseif bleed_type == 2 then
	minetest.debug("M.I.L.A " ..mila.version..": Blood Trail Actived!")
elseif bleed_type == 3 then
	minetest.debug("M.I.L.A " ..mila.version..": Massive Butchery Actived!")
elseif bleed_type == 4 then
	minetest.debug("M.I.L.A " ..mila.version..": Blood Splashes Disabled!")
end

local mila_bleed = function(self)
	local mobe = self.object
	local mobposition = mobe:getpos()
	local hp = mobe:get_hp()
	
	minetest.sound_play("mila_hit", {pos = pos, gain = 4, max_hear_distance = 25})
	
	--remove if dead (engine handling help, for odd health amount, and set_hp() function) also add some death effect
	if hp < 1 then
		minetest.add_particlespawner({
			amount = 25,
			time = 0.1,
			minpos = {x = mobposition.x-0.5, y = mobposition.y-0.5, z = mobposition.z-0.5},
			maxpos = {x = mobposition.x+0.5, y = mobposition.y+0.5, z = mobposition.z+0.5},
			collisiondetection = false,
			minvel = {x = -0.5, y = -0.5, z = -0.5},
			maxvel = {x = 0.5,  y = 0.5,  z = 0.5},
			minacc = {x = 0, y = 1, z = 0},
			maxacc = {x = 0, y = 1, z = 0},
			minexptime = 1,
			maxexptime = 4,
			minsize = 3,
			maxsize = 4,
			texture = "mila_boom.png",
		})
		--drop items
		minetest.add_item({x = mobposition.x + math.random(-0.5, 0.5), y = mobposition.y + math.random(-0.5, 0.5), z = mobposition.z + math.random(-0.5, 0.5)}, self.drops)
		mobe:remove()
		minetest.debug("M.I.L.A "..mila.version..": Deleted an entity!")
		ent_num = ent_num-1
		return
	end

	if mila.bleed_type == 1 then
		minetest.add_particlespawner({
			amount = 10,
			time = 0.2,
			minpos = {x = mobposition.x-0.5, y = mobposition.y-0.5, z = mobposition.z-0.5},
			maxpos = {x = mobposition.x+0.5, y = mobposition.y+0.5, z = mobposition.z+0.5},
			collisiondetection = true,
			minvel = {x = -1, y = -3, z = -1},
			maxvel = {x = 1,  y = -3,  z = 1},
			minexptime = 1,
			maxexptime = 4,
			minsize = 1,
			maxsize = 2,
			texture = "mila_blood.png",
		})
	elseif mila.bleed_type == 2 then
		minetest.add_particlespawner({
			amount = 10,
			time = 0.2,
			minpos = mobposition,
			maxpos = mobposition,
			collisiondetection = true,
			minvel = {x = 0, y = -3, z = 0},
			maxvel = {x = 0,  y = -3,  z = 0},
			minexptime = 2,
			maxexptime = 4,
			minsize = 1,
			maxsize = 2,
			texture = "mila_blood.png",
		})
	elseif mila.bleed_type == 3 then
		minetest.add_particlespawner({
			amount = 170,
			time = 0.001,
			minpos = {x = mobposition.x, y = mobposition.y, z = mobposition.z},
			maxpos = {x = mobposition.x, y = mobposition.y, z = mobposition.z},
			collisiondetection = false,
			minvel = {x = -4, y = -4, z = -4},
			maxvel = {x = 4,  y = 4,  z = 4},
			minacc = {x = 0, y = -10, z = 0},
			maxacc = {x = 0, y = -10, z = 0},
			minexptime = 1,
			maxexptime = 1,
			minsize = 3,
			maxsize = 4,
			texture = "mila_blood.png",
		})
	elseif mila.bleed_type == 4 then
	end
end

--register the first function (add).
function mila:add_entity(name,def)
	minetest.register_entity(name, {
		physical = def.physical or true,					--if false or nil, monster will ghost trough any blocks
		collide_with_objects = def.collide_with_objects,	--if false, monster will ghost trough any objects
		gravity = def.gravity or 2,
		damage = def.damage or 1,
		range = def.range or 1,
		mesh = def.mesh,
		status = def.status or "re",					--"passive" for animals; "hostile" for ennemies; "re" for rotating entities.
		makes_footstep_sound = def.makes_footstep_sounds,
		textures = def.textures,
		sounds = def.sounds,
		stepheight = def.stepheight or 2,				--at least 2 if you want the mob pass over blocks!
		collisionbox = def.collisionbox or {-0.5, -0.5, -0.5,  0.5, 0.5, 0.5},
		visual_size = def.visual_size or {x=1, y=1},
		visual = def.visual or "mesh",
		rotate = def.rotate or 0,					--#DEPRECATED >>> replace with automatic_face_movement_dir 
		automatic_face_movement_dir = def.automatic_face_movement_dir or -90,	--replaces rotate (^what a stupid name)
		hp_max = def.hp_max or 1,
		drops = def.drops or "mila:steak 4",
		sounds = def.sounds,					--sounds played randomly
		arrow = def.arrow,					--arrow for shooter mobs
		speed = def.speed or 4,				--'2' is very slow and '8' is fast (maybe ;P)
		view_range = def.view_range or 5,		--put to '0' to make a blind mob.
		on_step = mila_act,					--the heart of the engine
		on_activate = mila_first, 				--first things we need to do
		on_punch = mila_bleed,					--works :]
		stepcounter = 0,
	})
end

--register the egg function

if mila.egg == true then
	minetest.debug("M.I.L.A " ..mila.version..": Eggs are actived!")
elseif mila.egg == false then
	minetest.debug("M.I.L.A " ..mila.version..": Eggs are not actived!")
end

function mila:add_egg(name,params)
	if mila.egg == true then
		minetest.register_craftitem(name, {
			description = params.description,
			inventory_image = params.inventory_image,
			wield_image = params.wield_image or params.inventory_image,
			wield_scale = {x = 1, y = 1, z = 1.5},
			on_place = function(itemstack, placer, pointed_thing)
				if pointed_thing.type == "node" then
					if ent_num < mila.maxhandled then
					pointed_thing.under.y = pointed_thing.under.y + 2.5
					minetest.add_entity(pointed_thing.under, name)
					end
				end
					itemstack:take_item(1) --remove 1 from inventory
				return itemstack
			end,
		})
	end
end

--register spawning functions

if mila.spawning == true then
	minetest.debug("M.I.L.A " ..mila.version..": Spawning is actived!")
elseif mila.spawning == false then
	minetest.debug("M.I.L.A " ..mila.version..": Spawning is not actived!")
end

function mila:add_spawn(mobname, params)
	if mila.spawning == true then
		minetest.register_abm({ 
			nodenames = params.nodenames or {"default:dirt_with_grass"},
			neighbors = params.neighbors or {"air"},
			interval = params.interval or 300,
			chance = params.chance or 1000, 
			action = function(pos, node, active_object_count, active_object_count_wider)
				--prevent lag by stopping entity spawn if reached a certain number
				if ent_num < mila.maxhandled then
					minetest.add_entity(pos, mobname)
					minetest.debug("M.I.L.A " ..mila.version..": a " ..mobname.. " is spawning!")
				end
			end,
		})
	end
end


--set the /mila_clean command

minetest.register_chatcommand("mila_clean", {
	params = "",
	privs = {server=true},
	description = "Clean the map from M.I.L.A entities!",
	func = function(name, player)
		clean = true
		minetest.debug("M.I.L.A " ..mila.version..": Cleaned " ..ent_num.. " M.I.L.A entities!")
		minetest.chat_send_all("M.I.L.A " ..mila.version..": Cleaned " ..ent_num.. " M.I.L.A entities!")
		--little delay to be sure...
		minetest.after(1.6, function()
			clean = false -- get back to normal to make entities spawn again
			ent_num = 0
		end)
	end,
})

--open the mob files, for registering the entities
--loaded at the end to be sure every function is
--registered and ready to be used by this file :
dofile(milapath .."/mob.lua")

--say that every little thing is gonna be allright 
minetest.debug("M.I.L.A " ..mila.version..": Everything is OK and running. Have Fun!")
minetest.debug("M.I.L.A " ..mila.version..": Remember to report any bug on forum...")
minetest.debug("M.I.L.A " ..mila.version..": I'm a (great) mod from azekill_DIABLO!")
