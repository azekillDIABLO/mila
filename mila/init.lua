--define a global mila table

mila = {}

--define the version of the engine

local version = 0.3

--##register some basic things##

--set_animation

set_animation = function(self, type)

	if not self.animation then
		return
	end

	self.animation.current = self.animation.current or ""

	if type == "stand"
	and self.animation.current ~= "stand" then

		if self.animation.stand_start
		and self.animation.stand_end
		and self.animation.speed_normal then

			self.object:set_animation({
				x = self.animation.stand_start,
				y = self.animation.stand_end},
				self.animation.speed_normal, 0)

			self.animation.current = "stand"
		end

	elseif type == "walk"
	and self.animation.current ~= "walk" then

		if self.animation.walk_start
		and self.animation.walk_end
		and self.animation.speed_normal then

			self.object:set_animation({
				x = self.animation.walk_start,
				y = self.animation.walk_end},
				self.animation.speed_normal, 0)

			self.animation.current = "walk"
		end

	elseif type == "run"
	and self.animation.current ~= "run" then

		if self.animation.run_start
		and self.animation.run_end
		and self.animation.speed_run then

			self.object:set_animation({
				x = self.animation.run_start,
				y = self.animation.run_end},
				self.animation.speed_run, 0)

			self.animation.current = "run"
		end

	elseif type == "punch"
	and self.animation.current ~= "punch" then

		if self.animation.punch_start
		and self.animation.punch_end
		and self.animation.speed_normal then

			self.object:set_animation({
				x = self.animation.punch_start,
				y = self.animation.punch_end},
				self.animation.speed_normal, 0)

			self.animation.current = "punch"
		end
	end
end

--checks and actions for every entity
local mila_step = function(self,dtime)
	local mobe = self.object
	local mobposition = mobe:getpos()

	if mobe:get_hp() < 1 then
		mobe:remove()
	return
	end

	--find entities
	local entitylist = minetest.get_objects_inside_radius(mobposition, self.view_range)
	if not entitylist then return end -- no players in range, stand still.
	
	-- list players and mobs
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
	
	
	-- move towards player if exists
	if playerobj then
		local playerposition = playerobj:getpos()
		local direction = vector.direction(mobposition,playerposition)
		local displacement = vector.distance(playerposition,mobposition)
		self.object:setvelocity({
			x=self.speed*direction.x/displacement,
			y=self.speed*direction.y/displacement+self.fall_speed, -- fall_speed must be negative
			z=self.speed*direction.z/displacement
			})
	else
		self.object:setvelocity({x=0,y=self.fall_speed,z=0})
	end
end

--register the first function (add).

function mila:add_entity(name,def)
	minetest.register_entity(name, {
		physical = true,
		collide_with_objects = true, 
		mesh = def.mesh,
		textures = def.textures,
		collisionbox = def.collisionbox,
		visual_size = def.visual_size,
		visual = def.visual or "mesh",
		rotate = math.rad(def.rotate or 0),
		hp_max = def.hp_max or 10,
		speed = def.speed or 1,
		view_range = def.view_range or 5,
		fall_speed = def.fall_speed or -2,
		on_step = mila_step,
		animation = {def.animation}
	})
end

--register the egg function


local egg = 1 --say if egg or no (1 to activate)

function mila:add_egg(name,params)

	if egg == 1 then
		params.wield_image = params.wield_image.. "^mila_egg_spawn.png"
	end

	minetest.register_craftitem(name, {
		description = params.description,
		inventory_image = params.inventory_image,
		wield_image = params.wield_image,
		wield_scale = {x = 1, y = 1, z = 1.5},
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type == "node" then
				pointed_thing.under.y = pointed_thing.under.y + 1
				local luao = minetest.add_entity(pointed_thing.under, name)
				local luae = luao:get_luaentity()
				luao:set_hp(luae.hp_max)
			end
		end,
	})
end

--say that every little thing is gonna be allright

print("M.I.L.A" ..version..": Everything is OK and running. Have Fun!")
print("M.I.L.A" ..version..": Remember to report any bug on forum!")
