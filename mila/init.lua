--define a global mila table

mila = {}

--register some basic things. (here the move. needs some improvements)
function mila:mila_step(self,dtime)

   --find entities
   local entitylist = minetest.get_objects_inside_radius(5 or self.view_range)
   if not entitylist then return end -- no players in range, stand still.
   
   -- list players and mobs
   local moblist = {}
   local playerlist = {}
   for _,entity in pairs(entitylist) do
      if entity:is_player() then
         playerlist = playerlist + entity
      elseif entity.mobengine and entity.mobengine == "milamob" then
         moblist = moblist + entity
      end
   end

   -- if player found, choose one
   local playerobj = nil
   if playerlist then
      playerobj = playerlist[math.random(1,#playerlist)]
   end
   
   
   -- move towards player if exists
   if playerobj then
      local playerposition = playerobject:getpos()
      local mobposition = self:getpos() -- .... it should be self I think. else try self.ref:getpos()
      local direction = vector.direction(playerposition,mobposition)
      local displacement = vector.distance(playerposition,mobposition)
      self:setvector({
         x=self.speed*direction.x/displacement,
         y=self.speed*direction.y/displacement,
         z=self.speed*direction.z/displacement
         })
   end
end
--register the first function (add).

function mila:add_entity(name,def)
   local luae = minetest.register_entity(name, {
      mesh = def.mesh,
      textures = def.textures,
      hp_max = def.hp_max,
      speed = def.speed, -- register speed per entity, not globally
      view_range = def.view_range,
      on_step = mila.mila_step
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
  			minetest.add_entity(pointed_thing.under, name)
  		end
  	end,
	})
end
