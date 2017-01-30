--define a global mila table
mila = {}

--define the version of the engine
mila.version = "0.7.1"

--set little things, for deletion
clean = false
--WIP ::::  removelua = 0

--define modpath
milapath = minetest.get_modpath("mila") --not local for other files

--open the settings file (you can change things in it!!!)
dofile(milapath .."/settings.lua")

--open the misc files, for registering items, node, abms
dofile(milapath .."/misc.lua")

-- =======================
-- General functions

local function move_to_player(mob, player)
	local mobposition = mob:getpos()
	local mobe = mob:get_luaentity()
	local playerposition = player:getpos()

	local direction = vector.direction(mobposition,playerposition)
	local distance = vector.distance(mobposition,playerposition)
	if distance > 1 then
		mob:setvelocity({
			x=mobe.speed*direction.x,
			y=mobe.speed*direction.y - mobe.gravity, -- fall_speed must be negative
			z=mobe.speed*direction.z
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

local function move_random(self)
	local random = math.random(1, 20)
	local vel = self.object:getvelocity()
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
		local removelua = (removelua or 0) + 1
		mobe:set_hp(0)
		mobe:remove()
		--count the removed, then kill
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

--##PASSIVE CODE
	elseif self.status == "passive" then
		move_random(self)

--##RE CODE (Rotating Entity)
	elseif self.status == "re" then
		local look_at = mobe:getyaw()
		self.object:setyaw(look_at+0.05)				 -- it's does like the item code :D
		self.object:setvelocity({x=0,y=-self.gravity,z=0}) 	 -- it remains very useful for doing tests, powerups...
	end
	
end

--first things we need to do with the entity

local mila_first = function(self,dtime)
	local mobe = self.object
	--nope
end

--bleed and other on punch

local mila_bleed = function(self)
	local mobe = self.object
	local mobposition = mobe:getpos()
	local hp = mobe:get_hp()
	--remove if dead (engine handling help, for odd health amount, and set_hp() function) also add some death effect
	if hp < 1 then
		minetest.add_particlespawner({
			amount = 25,
			time = 4,
			minpos = {x = mobposition.x-0.1, y = mobposition.y-0.5, z = mobposition.z-0.1},
			maxpos = {x = mobposition.x+0.1, y = mobposition.y+0.5, z = mobposition.z+0.1},
			collisiondetection = false,
			minvel = {x = 0.2, y = 0.6, z = -0.2},
			maxvel = {x = 0.2,  y = 0.6,  z = -0.2},
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
		return
	end

	if mila.bleed_type == 1 then
		minetest.debug("M.I.L.A " ..mila.version..": Realistic Blood Actived!")
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
		minetest.debug("M.I.L.A " ..mila.version..": Blood Trail Actived!")
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
		minetest.debug("M.I.L.A " ..mila.version..": Massive Butchery Actived!")
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
		minetest.debug("M.I.L.A " ..mila.version..": Blood Splashes Disabled!")
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
		speed = def.speed or 4,					-- '2' is very slow and '8' is fast (maybe ;P)
		view_range = def.view_range or 5,			--put to '0' to make a blind mob.
		on_step = mila_act,						--the heart of the engine
		--on_activate = mila_first, 					--first things we need to do
		on_punch = mila_bleed,						--works :]
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
					local tpos = pointed_thing.under.y + 1

					local mob = minetest.add_entity(tpos, name)
					if mob then
						mob:setvelocity({x=0, y=-5, z=0})
					else
						mob.remove()
					end
					itemstack:take_item(1)
					return itemstack
				end
			end,
		})
	else
		minetest.debug("M.I.L.A " ..mila.version..": Eggs are not actived!")
	end
end

--##SPAWNING FUNCTIONS
function mila:add_spawn(mobname)
	minetest.register_abm({ 
		nodenames = {"default:dirt_with_grass"},
		neighbors = {"air"}, 
		interval = 5,
		chance = 1500, 
		action = function(pos, node, active_object_count, active_object_count_wider)
			minetest.add_entity(pos, mobname)
		end,
	})
end

--set the /mila_clean command

core.register_chatcommand("mila_clean", {
	params = "",
	privs = {},
	description = "Clean the map from M.I.L.A entities!",
	func = function(name, player)
		clean = true
		minetest.debug("M.I.L.A " ..mila.version..": Cleaned all M.I.L.A entities!")
		--little delay to be sure...
		minetest.after(1.6, function()
			clean = false -- get back to normal to make entities spawn again
			--WIP :::: removelua = 0 --set count to nil
		end)
	end,
})

--say that every little thing is gonna be allright
minetest.debug("M.I.L.A " ..mila.version..": Everything is OK and running. Have Fun!")
minetest.debug("M.I.L.A " ..mila.version..": Remember to report any bug on forum...")
minetest.debug("M.I.L.A " ..mila.version..": I'm a (great) mod from azekill_DIABLO!")
