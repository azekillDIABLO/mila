--API for mila

-- ==================
-- General functions:
-- ==================

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
	local group = minetest.registered_nodes[node.name].groups
	
	if distance > 1.5 then	
		if groups == "liquid" then
			mob:setvelocity({
				x=mobe.speed*0.7*direction.x,
				y=mobe.speed*0.7*direction.y+1.5, 	-- the mob floats but swim towards you, even if slowed
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
	local group = minetest.registered_nodes[node.name].groups
	if groups == "liquid" then
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
	local group = minetest.registered_nodes[node.name].groups
	if groups == "liquid" then
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

function kill_ent(self)
	local mobe = self.object
	local mobposition = mobe:getpos()
	
	minetest.add_particlespawner({
		amount = 35,
		time = 1,
		minpos = {x = mobposition.x-0.5, y = mobposition.y-1, z = mobposition.z-0.5},
		maxpos = {x = mobposition.x+0.5, y = mobposition.y, z = mobposition.z+0.5},
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
	--additem needs improvment :s
	mobe:remove()
	minetest.debug("M.I.L.A "..mila.version..": Deleted/Killed/Eliminated an entity!")
	ent_num = ent_num-1
	return
end


-- ========
-- Activity
-- ========

--checks and actions for every entity
local mila_act = function(self,dtime)
	self.stepcounter = self.stepcounter + dtime
	self.hitcounter = self.hitcounter + dtime
	if self.stepcounter > mila.globalcounter then
		self.stepcounter = 0
	else
		return
	end
	
	local mobe = self.object
	local mobposition = mobe:getpos()
	local mobname = self.name
	local hp = mobe:get_hp()
	local L_hp = hp/self.hp_max*205 --I seriously love maths
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
		mobe:remove()
		minetest.debug("M.I.L.A "..mila.version..": Deleted an entity!")
		ent_num = ent_num-1
	end
	
	--prevent mob overhaul
	if ent_num > mila.maxhandled then
		mobe:remove()
		minetest.debug("M.I.L.A "..mila.version..": Deleted an entity!")
		ent_num = ent_num-1
	end
	
	--play a random sound
	do_sounds_random(self)
	
	--kill on death [ xD why me? ]
	if hp < 1 then
		kill_ent(self)
	end

--##KILL EVIL MONSTERS IF PEACEFUL IS ACTIVED
	if mila.peaceful == true then
		if self.status == "hostile" or self.status == "shooter" then
			kill_ent(self)
		end
	end
	
--##HOSTILE CODE (melee)
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

--##SHOOTER CODE (ranged)
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
			--shoot arrow
			look_to_player(self.object, self.target)

			if self.hitcounter > self.attack_speed then
				minetest.add_entity(mobposition, self.arrow)
				minetest.debug("M.I.L.A " ..mila.version..": A mob is shooting!")
				self.hitcounter = 0
			end
		elseif self.target then
			move_to_player(self.object, self.target)
		else
			move_random(self)
		end

--##ARROW CODE (well you know what is an arrow)
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
			kill_ent(self)
	
		elseif self.target and vector.distance(mobposition, self.target:getpos()) > self.range then 
			kill_ent(self)
	
		elseif not self.target then 
			kill_ent(self)
	
		end
		--remove if stuck or moving too slowly
		if self.speed < 0.2 and self.speed > -0.2 then
			kill_ent(self)
	
		end

--##BOMBER CODE (ranged Michael Bay's style)
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
				local blastpower = self.damage*0.8
				tnt.boom(mobposition, {radius = blastpower, damage_radius = blastpower*1.5})
			elseif mila.break_blocks == false then
				local hptarget = self.target:get_hp()
				simulate_tnt(self.object, self.target)
				self.target:set_hp(hptarget - self.damage)
				minetest.sound_play("mila_explode", {pos = pos, gain = 1.5, max_hear_distance = 2*64})
			end
			kill_ent(self)
	
		elseif self.target then
			move_to_player(self.object, self.target)
		else
			move_random(self)
		end
		
--##FIREBALL CODE (boom)
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
				local blastpower = self.damage*0.8
				tnt.boom(mobposition, {radius = blastpower, damage_radius = blastpower*1.5})
			elseif mila.break_blocks == false then
				local hptarget = self.target:get_hp()
				simulate_tnt(self.object, self.target)
				self.target:set_hp(hptarget - self.damage)
				minetest.sound_play("mila_boom", {pos = pos, gain = 1.5, max_hear_distance = 2*64})
			end
			kill_ent(self)
	
		elseif self.target and vector.distance(mobposition, self.target:getpos()) > self.range then 
			kill_ent(self)
	
		elseif not self.target then 
			kill_ent(self)
	
		end
		--remove if stuck or moving too slowly
		if self.speed < 0.2 and self.speed > -0.2 then
			kill_ent(self)
	
		end

--##MISSILE CODE (target aquired)
	elseif self.status == "missile" then
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
			kill_ent(self)
		end	
		if self.target and vector.distance(mobposition, self.target:getpos()) < 4 then 
			minetest.debug("M.I.L.A " ..mila.version..": A fireball is hitting target!")
			if mila.break_blocks == true then
				local blastpower = self.damage*0.8
				tnt.boom(mobposition, {radius = blastpower, damage_radius = blastpower*1.5})
			elseif mila.break_blocks == false then
				local hptarget = self.target:get_hp()
				simulate_tnt(self.object, self.target)
				self.target:set_hp(hptarget - self.damage)
				minetest.sound_play("mila_boom", {pos = pos, gain = 1.5, max_hear_distance = 2*64})
			end
			kill_ent(self)
	
		elseif self.target and vector.distance(mobposition, self.target:getpos()) > self.range then 
			kill_ent(self)
	
		elseif not self.target then 
			kill_ent(self)
	
		end
		--remove if stuck or moving too slowly
		if self.speed < 0.2 and self.speed > -0.2 then
			kill_ent(self)
	
		end

--##PASSIVE CODE
	elseif self.status == "passive" then
		move_random(self)

--##RE CODE (Rotating Entity)
	elseif self.status == "re" then
		local look_at = mobe:getyaw()
		self.object:setyaw(look_at+0.5)	 -- it is very useful for doing tests, powerups or objects on a pedestal.		 
		self.object:setvelocity({x=0,y=-self.gravity,z=0}) --(honesty it's just for fun)
	end
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
			kill_ent(self)
	
		end	
	end
end

local mila_bleed = function(self)
	local mobe = self.object
	local mobposition = mobe:getpos()
	local hp = mobe:get_hp()
	
	minetest.sound_play("mila_hit", {pos = pos, gain = 4, max_hear_distance = 25})
	
	--kill on death [ xD why me? ]
	if hp < 1 then
		kill_ent(self)
	end

	if mila.bleed_type == 1 then
		minetest.add_particlespawner({
			amount = 13,
			time = 0.2,
			minpos = {x = mobposition.x-0.5, y = mobposition.y-0.5, z = mobposition.z-0.5},
			maxpos = {x = mobposition.x+0.5, y = mobposition.y+0.5, z = mobposition.z+0.5},
			collisiondetection = true,
			collision_removal = true,
			minvel = {x = -1, y = -3, z = -1},
			maxvel = {x = 1,  y = -3,  z = 1},
			minexptime = 1,
			maxexptime = 4,
			minsize = 4,
			maxsize = 4,
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
			collisiondetection = true,
			collision_removal = true,
			minvel = {x = -4, y = -4, z = -4},
			maxvel = {x = 4,  y = 10,  z = 4},
			minacc = {x = -10, y = -3, z = -10},
			maxacc = {x = 10, y = -5, z = 10},
			minexptime = 1,
			maxexptime = 1,
			minsize = 3,
			maxsize = 4,
			texture = "mila_blood.png",
		})
	elseif mila.bleed_type == 4 then
	end
end

--register the function to register entities
function mila:add_entity(name,def)
	minetest.register_entity(name, {
		physical = def.physical or true,					--if false or nil, monster will ghost trough any blocks
		collide_with_objects = def.collide_with_objects,	--if false, monster will ghost trough any objects
		gravity = def.gravity or 2,
		damage = def.damage or 1,
		attack_speed = def.attack_speed or 0.7,
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
		hitcounter = 0,
	})
end

function mila:add_egg(name,params)
	if mila.egg == true then
		minetest.register_craftitem(name, {
			description = params.description,
			inventory_image = params.inventory_image,
			wield_image = params.wield_image or params.inventory_image,
			wield_scale = {x = 1, y = 1, z = 1},
			on_place = function(itemstack, placer, pointed_thing)
			if ent_num < mila.maxhandled then
				if pointed_thing.type == "node" then
					pointed_thing.under.y = pointed_thing.under.y + 2.5
					minetest.add_entity(pointed_thing.under, name)
				end
				if not minetest.setting_getbool("creative_mode") then
					itemstack:take_item(1) --remove 1 from inventory
				end
				return itemstack
			end
			end,
		})
	end
end

function mila:add_spawn(mobname, params)
	if mila.spawning == true then
		minetest.register_abm({ 
			nodenames = params.nodenames or {"default:dirt_with_grass"},
			neighbors = params.neighbors or {"air"},
			interval = params.interval or 300,
			chance = params.chance or 1000, 
			min_light = params.min_light or 0,
			max_light = params.max_light or 7,
			action = function(pos, node, active_object_count, active_object_count_wider)
				--prevent lag by stopping entity spawn if reached a certain number
				if ent_num < mila.maxhandled then
					local node_light = minetest.get_node_light(pos, timeofday)
					print(node_light)
					--if node_light > min_light and node_light < max_light then
						minetest.add_entity(pos, mobname)
						minetest.debug("M.I.L.A " ..mila.version..": a " ..mobname.. " is spawning!")
					--end
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

--set the /mila_count command

minetest.register_chatcommand("mila_count", {
	params = "",
	privs = {interact=true},
	description = "Counts the number of M.I.L.A entities!",
	func = function(name, player)
		minetest.debug("M.I.L.A " ..mila.version..": There are " ..ent_num.. " M.I.L.A entities!")
		minetest.chat_send_all("M.I.L.A " ..mila.version..": There are " ..ent_num.. " M.I.L.A entities!")
	end,
})

minetest.debug("M.I.L.A " ..mila.version..": API perfectly loaded!")