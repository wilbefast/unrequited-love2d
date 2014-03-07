--[[
"Unrequited", a Löve 2D extension library
(C) Copyright 2013 William Dyce

All rights reserved. This program and the accompanying materials
are made available under the terms of the GNU Lesser General Public License
(LGPL) version 2.1 which accompanies this distribution, and is available at
http://www.gnu.org/licenses/lgpl-2.1.html

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
Lesser General Public License for more details.
--]]

--[[------------------------------------------------------------
IMPORTS
--]]------------------------------------------------------------

local Class = require("hump/class")

--[[------------------------------------------------------------
GAMEOBJECT CLASS
--]]------------------------------------------------------------

--[[------------------------------------------------------------
Initialisation
--]]

local GameObject = Class
{
  -- container
  INSTANCES = { },
  NEW_INSTANCES = { },
      
  -- identifiers
  NEXT_ID = 1,
  
  -- type
  TYPE = { },
      
  -- constructor
  init = function(self, x, y, w, h)
    -- save attributes
    self.w        = (w or 0)
    self.h        = (h or 0)
    self.x        = x
    self.y        = y
    self.prevx    = self.x
    self.prevy    = self.y
    
    table.insert(GameObject.NEW_INSTANCES, self) 
    
    -- assign identifier
    self.id = GameObject.NEXT_ID
    GameObject.NEXT_ID = GameObject.NEXT_ID + 1
    self.name = self:typename() .. '(' .. tostring(self.id) .. ')'
    
  end,
  
  -- default attribute values
  dx = 0,
  dy = 0
}

--[[------------------------------------------------------------
TYPES
--]]------------------------------------------------------------

function GameObject.TYPE.new(typename)
  local type_index = #(GameObject.TYPE) + 1
  useful.bind(GameObject.TYPE, typename, type_index)
  return type_index
end


function GameObject:typename()
  return GameObject.TYPE[self.type]
end

function GameObject:isType(typename)
  return (self.type == GameObject.TYPE[typename])
end

--[[------------------------------------------------------------
CONTAINER
--]]------------------------------------------------------------

function GameObject.purgeAll()
	useful.map(GameObject.INSTANCES, 
		function(object)
			object.purge = true
		end
  GameObject.INSTANCES = {}
  GameObject.NEXT_ID = 1
end

function GameObject.countSuchThat(predicate)
	local count = 0
	useful.map(GameObject.INSTANCES, 
		function(object)
			if predicate(object) then
				count = count + 1
		end
	return count
end

function GameObject.updateAll(dt, ysort, view)
    -- add new objects
  for _, object in pairs(GameObject.NEW_INSTANCES) do
    table.insert(GameObject.INSTANCES, object)
  end
  GameObject.NEW_INSTANCES = { }

  -- update objects
  -- ...for each object
  useful.map(GameObject.INSTANCES,
    function(object)
      -- ...update the object
      object:update(dt, level, view)
      -- ...check collisions with other objects
      useful.map(GameObject.INSTANCES,
          function(otherobject)
            -- check collisions between objects
            if object:isColliding(otherobject) then
              object:eventCollision(otherobject, dt)
            end
          end) 
  end)

	if ysort then
  	local oi = 1
  	while oi <= (#GameObject.INSTANCES) do
    	local obj = GameObject.INSTANCES[oi]
    	if oi > 1 then
      	local prev = GameObject.INSTANCES[oi-1]
      	if (prev.y > obj.y) then
        	GameObject.INSTANCES[oi] = prev
        	GameObject.INSTANCES[oi - 1] = obj
      	end
    	end
    	oi = oi + 1
  	end
	end
end

function GameObject.drawAll(view)
	-- for each object
  useful.map(GameObject.INSTANCES,
    function(object)
      -- if the object is in view...
      if (not view) or object:isColliding(view) then
        -- ...draw the object
        object:draw(view)
      end
  end)
end

function GameObject.mapToAll(f)
	-- for each object
  useful.map(GameObject.INSTANCES, f)
end

function GameObject.trueForAny(predicate)
	useful.map(GameObject.INSTANCE,
		function(object)
			if predicate(object) then
				return true
		end
  return false
end

function GameObject.trueForAll(predicate)
	useful.map(GameObject.INSTANCE,
		function(object)
			if not predicate(object) then
				return false
		end
	return true
end



--[[------------------------------------------------------------
METHODS
--]]------------------------------------------------------------

--[[----------------------------------------------------------------------------
Collisions
--]]

function GameObject:centreOn(x, y)
  self.x, self.y = x - self.w/2, y - self.h/2
end

function GameObject:centreX()
  return self.x + self.w/2
end

function GameObject:centreY()
  return self.y + self.h/2
end

function GameObject:snap_from_collision(dx, dy, collisiongrid, max, type)
  local i = 0
  while collisiongrid:collision(self, self.x, self.y, type) 
  and (not max or i < max)  do
    self.x = self.x + dx
    self.y = self.y + dy
    i = i + 1
  end
end

function GameObject:snap_to_collision(dx, dy, collisiongrid, max, type)
  local i = 0
  while not collisiongrid:collision(self, self.x + dx, self.y + dy, type) 
        and (not max or i < max)  do
    self.x = self.x + dx
    self.y = self.y + dy
    i = i + 1
  end
end

function GameObject:eventCollision(other, dt)
  -- override me!
end

function GameObject:collidesType(type)
  -- override me!
  return false
end

function GameObject:isColliding(other)
  -- no self collisions
  if self == other then
    return false
  end

  local result = true

	-- move origin to centre of object
  self.x, self.y, other.x, other.y = self.x - self.w/2, self.y - self.h/2, other.x - other.w/2, other.y - other.h/2

  -- horizontally seperate ? 
  local v1x = (other.x + other.w) - self.x
  local v2x = (self.x + self.w) - other.x
  if useful.sign(v1x) ~= useful.sign(v2x) then
    result = false
  end
  -- vertically seperate ?
  local v1y = (self.y + self.h) - other.y
  local v2y = (other.y + other.h) - self.y
  if useful.sign(v1y) ~= useful.sign(v2y) then
    result = false
  end
  
	-- move origin back to top-left corner
  self.x, self.y, other.x, other.y = self.x + self.w/2, self.y + self.h/2, other.x + other.w/2, other.y + other.h/2
  
	-- all done
	return result
end

function GameObject:isCollidingPoint(x, y)
  return (x >= self.x and x <= self.x + self.w
        and y >= self.y and y <= self.y + self.h)
end

--[[------------------------------------------------------------
Game loop
--]]

function GameObject:update(dt)
  
  -- object may have several fisix settings
  local fisix = (self.fisix or self)
  
  -- gravity
  if fisix.GRAVITY and self.airborne then
    self.dy = self.dy + fisix.GRAVITY*dt
  end

  -- friction
  if (self.dx ~= 0) and fisix.FRICTION_X and (fisix.FRICTION_X ~= 0) then
    self.dx = self.dx / (math.pow(fisix.FRICTION_X, dt))
  end
  if (self.dy ~= 0) and fisix.FRICTION_Y and (fisix.FRICTION_Y ~= 0) then
    self.dy = self.dy / (math.pow(fisix.FRICTION_Y, dt))
  end
  
  -- terminal velocity
  local abs_dx, abs_dy = math.abs(self.dx), math.abs(self.dy)
  if (self.dx ~= 0) and fisix.MAX_DX and (abs_dx > fisix.MAX_DX) then
    self.dx = fisix.MAX_DX*useful.sign(self.dx)
  end
  if (self.dy ~= 0) and fisix.MAX_DY and (abs_dy > fisix.MAX_DY) then
    self.dy = fisix.MAX_DY*useful.sign(self.dy)
  end
  
  -- clamp less than epsilon inertia to 0
  if math.abs(self.dx) < 0.01 then self.dx = 0 end
  if math.abs(self.dy) < 0.01 then self.dy = 0 end
  
  
  if GameObject.COLLISIONGRID then
    local collisiongrid = GameObject.COLLISIONGRID
    -- check if we're on the ground
    self.airborne = 
      ((not collisiongrid:pixelCollision(self.x, self.y + self.h + 1, collide_type)
      and (not collisiongrid:pixelCollision(self.x + self.w, self.y + self.h + 1, collide_type))))
    if not self.airborne and self.dy > 0 then
      if collisiongrid:collision(self, collide_type) then
        self:snap_from_collision(0, -1, collisiongrid, math.abs(self.dy), collide_type)
      end
      self.dy = 0
    end
    
    -- move HORIZONTALLY FIRST
    if self.dx ~= 0 then
      local move_x = self.dx * dt
      local new_x = self.x + move_x
      self.prevx = self.x
      -- is new x in collision ?
      if collisiongrid:collision(self, new_x, self.y) then
        -- move as far as possible towards new position
        self:snap_to_collision(useful.sign(self.dx), 0, 
                          collisiongrid, math.abs(self.dx))
        self.dx = 0
      else
        -- if not move to new position
        self.x = new_x
      end
    end
    
    -- move the object VERTICALLY SECOND
    if self.dy ~= 0 then
      local move_y = self.dy*dt
      local new_y = self.y + move_y
      self.prevy = self.y
      -- is new y position free ?
      if collisiongrid:collision(self, self.x, new_y) then
        -- if not move as far as possible
        self:snap_to_collision(0, useful.sign(self.dy), collisiongrid, math.abs(self.dy))
        self.dy = 0
      else
        -- if so move to new position
        self.y = new_y
      end
    end
  else -- not self.COLLISIONGRID
    self.x = self.x + self.dx*dt
    self.y = self.y + self.dy*dt
  end
end

function GameObject:draw()
  if DEBUG then
    self.DEBUG_VIEW:draw(self)
  end
end

GameObject.DEBUG_VIEW = 
{
  draw = function(self, target)
    scaling:rectangle("line", 
        target.x, target.y, target.w, target.h)
  end
}

--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return GameObject