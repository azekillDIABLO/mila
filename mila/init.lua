--define a global mila table

mila = {}

--register some basic things. (here the move. needs some improvements)
local mila_step = function(self,dtime)
   local mobe = self.object
   local mobposition = mobe:getpos()

   if mobe:get_hp() < 1 then
   	mobe:remove()
	return
   end

   --find entities
   local entitylist = minetest.get_objects_inside_radius(mobposition, self.view_range or 5)
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
         y=self.speed*direction.y/displacement,
         z=self.speed*direction.z/displacement
         })
	self.object:set_animation({x=0,y=10},10,0)
   else
      self.object:setvelocity({x=0,y=0,z=0})
   end
end

--register the first function (add).

function mila:add_entity(name,def)
   minetest.register_entity(name, {
      mesh = def.mesh,
      textures = def.textures,
      hp_max = def.hp_max,
      speed = def.speed,
      view_range = def.view_range,
      on_step = mila_step
   })
end

--register the egg function



function mila:add_egg(name,description,image)
  minetest.register_craftitem(name, {
  	description = description,
  	inventory_image = image,
  	wield_image = image,
  	wield_scale = {x = 1, y = 1, z = 0.5},
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
