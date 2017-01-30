--define a global mila table

mila = {} --not local for other files

--define the version of the engine

version = 0.7 --not local for other files

--set little things, for deletion

clean = false
--WIP ::::  removelua = 0

--define modpath

milapath = minetest.get_modpath("mila") --not local for other files

--open the settings file (you can change things in it!!!)

dofile(milapath .."/settings.lua")

--open the misc files, for registering items, node, abms

dofile(milapath .."/misc.lua")

--checks and actions for every entity
local mila_act = function(self,dtime)
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
		removelua = removelua + 1
		mobe:set_hp(0)
		mobe:remove()
		--count the removed, then kill
	end
--##HOSTILE CODE
	if self.status == "hostile" then
	--find entities
	local entitylist = minetest.get_objects_inside_radius(mobposition, self.view_range)
	if not entitylist then return end -- no players in range, stand still.
	--list players and mobs
	local moblist = {}
	local playerlist = {}
		for _,entity in pairs(entitylist) do
			if entity:is_player() then
				playerlist[#playerlist+1] = entity
			elseif entity.mobengine and entity.mobengine == "milamob" then
				-- need to add check that it is not its own self
				moblist[#moblist+1] = entity
			end
		end
		-- if player found, choose one
	local playerobj = nil
		if #playerlist > 0 then
			playerobj = playerlist[math.random(1,#playerlist)]	
		end
	-- move towards player if exists, if not, move around
	local random = math.random(1, 20)
	if playerobj then
		local playerposition = playerobj:getpos()
		local direction = vector.direction(mobposition,playerposition)
		self.object:setvelocity({
			x=self.speed*direction.x,
			y=self.speed*direction.y-self.gravity, -- fall_speed must be negative
			z=self.speed*direction.z
			})
	elseif random == 1 then
		mobe:setvelocity({x=math.random(-self.speed, self.speed),y=-self.gravity,z=math.random(-self.speed, self.speed)})
	end
	--attacking
	local targetlist = minetest.get_objects_inside_radius(mobposition, self.range)
	--list players and mobs
	local target_moblist = {}
	local target_playerlist = {}
		for _,entity in pairs(targetlist) do
			if entity:is_player() then
				target_playerlist[#target_playerlist+1] = entity
			elseif entity.mobengine and entity.mobengine == "milamob" then
				-- need to add check that it is not its own self
				target_moblist[#target_moblist+1] = entity
			end
		end
		-- if player found, choose one
	local target_playerobj = nil
		if #target_playerlist > 0 then
			target_playerobj = target_playerlist[math.random(1,#target_playerlist)]	
			if target_playerobj then 
				local hptarget = target_playerobj:get_hp()
				minetest.after(1, function()
				target_playerobj:set_hp(hptarget - self.damage)
				print("M.I.L.A " ..version..": A mob is attacking!")
				self.object:setvelocity({x=0,y=-self.gravity,z=0})
				end)
			end
		else return end
	--end this
	end
--##PASSIVE CODE
	if self.status == "passive" then
	local random = math.random(1, 40)
	if random == 1 then
		self.object:setvelocity({x=math.random(-self.speed, self.speed),y=-self.gravity,z=math.random(-self.speed, self.speed)})
		--[[minetest.sound_play(self.sounds,{
				pos = mobposition,
				gain = 3.0, -- default
				max_hear_distance = 52, -- default, uses an euclidean metric
				loop = not true, -- only sounds connected to objects can be looped
				print(self.sounds)
			})]]
		end
	end
--##RE CODE (Rotating Entity)
if self.status == "re" then
	local look_at = mobe:getyaw()
	self.object:setyaw(look_at+0.05)				 -- it's does like the item code :D
	self.object:setvelocity({x=0,y=-self.gravity,z=0}) 	 -- it remains very useful for doing tests, powerups...
	end
	
--##SPAWNING FUNCTIONS
	minetest.register_abm({ 
		nodenames = {"default:dirt_with_grass"},
		neighbors = {"air"}, 
		interval = 1,
		chance = 1, 
		action = function(pos, node, active_object_count, active_object_count_wider)
			minetest.add_entity(pos, mobe)
		end,
	})
end

--first things we need to do with the entity

local mila_first = function(self,dtime)
	local mobe = self.object
	--nope
end
--bleed and other on punch

if bleed_type == 1 then
	print("M.I.L.A " ..version..": Realistic Blood Actived!")
elseif bleed_type == 2 then
	print("M.I.L.A " ..version..": Blood Trail Actived!")
elseif bleed_type == 3 then
	print("M.I.L.A " ..version..": Massive Butchery Actived!")
elseif bleed_type == 4 then
	print("M.I.L.A " ..version..": Blood Splashes Disabled!")
end

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
		print("M.I.L.A "..version..": Deleted an entity!")
	return end
	if bleed_type == 1 then
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
	elseif bleed_type == 2 then
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
	elseif bleed_type == 3 then
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
	elseif bleed_type == 4 then
	return
	end
end

--register the first function (add).
function mila:add_entity(name,def)
	minetest.register_entity(name, {
		physical = def.physical,					--if false, monster will ghost trough any blocks
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
	})
end

--register the egg function

if egg == true then
	print("M.I.L.A " ..version..": Eggs are actived!")
else
	print("M.I.L.A " ..version..": Eggs are not actived!")
end

if egg == true then
	function mila:add_egg(name,params)
		minetest.register_craftitem(name, {
			description = params.description,
			inventory_image = params.inventory_image,
			wield_image = params.wield_image or params.inventory_image,
			wield_scale = {x = 1, y = 1, z = 1.5},
			on_place = function(itemstack, placer, pointed_thing)
				if pointed_thing.type == "node" then
					pointed_thing.under.y = pointed_thing.under.y + 2.5
					minetest.add_entity(pointed_thing.under, name)
				end
			end,
		})
	end
end

--set the /mila_clean command

core.register_chatcommand("mila_clean", {
	params = "",
	privs = {},
	description = "Clean the map from M.I.L.A entities!",
	func = function(name, player)
		clean = true
		print("M.I.L.A " ..version..": Cleaned all M.I.L.A entities!")
		--little delay to be sure...
		minetest.after(1.6, function()
			clean = false -- get back to normal to make entities spawn again
			--WIP :::: removelua = 0 --set count to nil
		end)
	end,
})

--say that every little thing is gonna be allright
print("M.I.L.A " ..version..": Everything is OK and running. Have Fun!")
print("M.I.L.A " ..version..": Remember to report any bug on forum...")
print("M.I.L.A " ..version..": I'm a (great) mod from azekill_DIABLO!")