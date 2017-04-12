--define a global mila table
mila = {}

--define the version of the engine
mila.version = "0.8"

--set little things, for deletion
clean = false
ent_num = 0

--define modpath
milapath = minetest.get_modpath("mila") --not local for other files

--open the settings file (you can change things in it!!!)
dofile(milapath .."/settings.lua")

--open the misc files, for registering items, node, abms
dofile(milapath .."/misc.lua")

-- ==================
-- General functions:

local function move_to_player(mob, player)
	local mobposition = mob:getpos()
	local mobe = mob:get_luaentity()
	local playerposition = player:getpos()

	local direction = vector.direction(mobposition,playerposition)
	local distance = vector.distance(mobposition,playerposition)
	if distance > 1.5 then
		mob:setvelocity({
			x=mobe.speed*direction.x,
			y=mobe.speed*direction.y - mobe.gravity, 	-- fall_speed must be negative to make 
			z=mobe.speed*direction.z			-- the mob fall in the right direction
		})
	end
end

local function look_to_player(mob, player)
	local mobposition = mob:getpos()
	local mobe = mob:get_luaentity()
	local playerposition = player:getpos()

	local direction = vector.direction(mobposition,playerposition)
	local distance = vector.distance(mobposition,playerposition)
	mob:setvelocity({
		x=0.01*direction.x,
		y=0.01*direction.y - mobe.gravity, 	-- fall_speed must be negative to make 
		z=0.01*direction.z				-- the mob fall in the right direction
	})
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

local function explode(pos, radius, ignore_protection, ignore_on_blast)
	pos = vector.round(pos)
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

local function move_random(self)
	local random = math.random(1, 20)
	local vel = self.object:getvelocity()
	if not self.gravity == 0 then
		if random < 5 then -- set a new course
			self.object:setvelocity({
				x=math.random(-self.speed, self.speed),
				y=-self.gravity,
				z=math.random(-self.speed, self.speed)
			})
		elseif random < 10 then -- slow down
			self.object:setvelocity({
				x = vel.x*0.8,
				y = vel.y,
				z = vel.z*0.8,
			})
		else
			self.object:setvelocity({
				x = vel.x,
				y = -self.gravity,
				z = vel.z,
			})
		end
	elseif self.gravity == 0 then
		if random < 5 then -- set a new course
			self.object:setvelocity({
				x=math.random(-self.speed, self.speed),
				y=math.random(-self.speed, self.speed),
				z=math.random(-self.speed, self.speed)
			})
		elseif random < 10 then -- slow down
			self.object:setvelocity({
				x = vel.x*0.8,
				y = vel.y*0.8,
				z = vel.z*0.8,
			})
		else
			self.object:setvelocity({
				x = vel.x,
				y = vel.y,
				z = vel.z,
			})
		end
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
	
	--add health bar
	mobe:set_nametag_attributes({
		color = {a=205, r=95, g=L_hp, b=5}, --goes from a greenish color to dark red
		text = "[" .. mobname .."] ".. hp .."/".. self.hp_max,
	})
	
	--delete with /mila_clean command
	if clean == true then
		mobe:set_hp(0)
		mobe:remove()
		ent_num = ent_num-1
		--set_hp to 0, then force death.
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
		elseif not self.target then 
			mobe:remove()
			ent_num = ent_num-1
		end
--##BOMBER CODE === BUGGED
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
			--wip explosion
			local boompos = {x=mobposition.x,y=mobposition.y,z=mobposition.z}
			explode(boompos, 3, self.object)--blow up
			self.object:setvelocity({x=0,y=-self.gravity,z=0})
			mobe:remove()
		elseif self.target then
			move_to_player(self.object, self.target)
		else
			move_random(self)
		end
--##PASSIVE CODE
	elseif self.status == "passive" then
		move_random(self)

--##RE CODE (Rotating Entity)
	elseif self.status == "re" then
		local look_at = mobe:getyaw()
		self.object:setyaw(look_at+0.05)				 -- it's does like the item code :D
		self.object:setvelocity({x=0,y=-self.gravity,z=0}) 	 -- it remains very useful for doing tests, powerups or objects on a pedestal.
	end
end

--first things we need to do with the entity

local mila_first = function(self,dtime)
	local mobe = self.object
	local mobposition = mobe:getpos()
	--add a counter to prevent entity overload
	ent_num = ent_num+1
	
	--##ARROW CODE
	if self.status == "arrow" then
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
		end	
	end
end

--bleed and other on punch

if bleed_type == 1 then
	minetest.debug("M.I.L.A " ..version..": Realistic Blood Actived!")
elseif bleed_type == 2 then
	minetest.debug("M.I.L.A " ..version..": Blood Trail Actived!")
elseif bleed_type == 3 then
	minetest.debug("M.I.L.A " ..version..": Massive Butchery Actived!")
elseif bleed_type == 4 then
	minetest.debug("M.I.L.A " ..version..": Blood Splashes Disabled!")
end

local mila_bleed = function(self)
	local mobe = self.object
	local mobposition = mobe:getpos()
	local hp = mobe:get_hp()
	--remove if dead (engine handling help, for odd health amount, and set_hp() function) also add some death effect
	if hp < 1 then
		minetest.add_particlespawner({
			amount = 25,
			time = 0.1,
			minpos = {x = mobposition.x-0.5, y = mobposition.y-0.5, z = mobposition.z-0.5},
			maxpos = {x = mobposition.x+0.5, y = mobposition.y+0.5, z = mobposition.z+0.5},
			collisiondetection = false,
			minvel = {x = -0.5, y = -0.6, z = -0.5},
			maxvel = {x = 0.5,  y = 0.6,  z = 0.5},
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
			minpos = {x = mobposition.x-0.5, y = mobposition.y-0.5, z = mobposition.z-0.5},
			maxpos = {x = mobposition.x+0.5, y = mobposition.y+1.5, z = mobposition.z+0.5},
			collisiondetection = true,
			minvel = {x = -2, y = -2, z = -2},
			maxvel = {x = 2,  y = -1,  z = 2},
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
		gravity = def.gravity or 11,
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

function mila:add_egg(name,params)
	if mila.egg == true then
		minetest.debug("M.I.L.A " ..mila.version..": Eggs are actived!")
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
	else
		minetest.debug("M.I.L.A " ..mila.version..": Eggs are not actived!")
	end
end

--register spawning functions

function mila:add_spawn(mobname, params)
	if mila.spawning == true then
	minetest.debug("M.I.L.A " ..mila.version..": Spawning is actived!")
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
		--little delay to be sure...
		minetest.after(1.6, function()
			clean = false -- get back to normal to make entities spawn again
			ent_num = 0
		end)
	end,
})

--say that every little thing is gonna be allright
minetest.debug("M.I.L.A " ..mila.version..": Everything is OK and running. Have Fun!")
minetest.debug("M.I.L.A " ..mila.version..": Remember to report any bug on forum...")
minetest.debug("M.I.L.A " ..mila.version..": I'm a (great) mod from azekill_DIABLO!")
