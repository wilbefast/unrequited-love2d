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
local vector = require("hump/vector-light")

local useful = require("unrequited/useful")
local scaling = require("unrequited/scaling")

--[[------------------------------------------------------------
GAMEOBJECT CLASS
--]]------------------------------------------------------------

--[[------------------------------------------------------------
Initialisation
--]]

-- container
local __INSTANCES = { }
local __NEW_INSTANCES = { }
    
-- identifiers
local __NEXT_ID = 1

-- type
local __TYPE = { }

local GameObject = Class
{

      
  -- constructor
  init = function(self, x, y, w_or_r, optional_h)
    -- save attributes
    if optional_h then
      self.w = (w_or_r or 0)
      self.h = optional_h
    else
      self.r = (w_or_r or 0)
    end
    self.x        = x
    self.y        = y
    self.prevx    = self.x
    self.prevy    = self.y
    
    table.insert(__NEW_INSTANCES, self) 
    
    -- assign identifier
    self.id = __NEXT_ID
    __NEXT_ID = __NEXT_ID + 1

    -- assign type if one was not specified
    self.type = (self.type or __TYPE["Undefined"])
    self.name = self:typename() .. '(' .. tostring(self.id) .. ')'
    
  end,
  
  -- default attribute values
  dx = 0,
  dy = 0
}

--[[------------------------------------------------------------
TYPES
--]]------------------------------------------------------------

function GameObject.newType(typename)
  local type_index = #(__TYPE) + 1
  useful.bind(__TYPE, typename, type_index)
  return type_index
end
GameObject.newType("Undefined")


function GameObject:typename()
  return __TYPE[self.type]
end

function GameObject:isType(typename)
  return (self.type == __TYPE[typename])
end

--[[------------------------------------------------------------
CONTAINER
--]]------------------------------------------------------------

--[[------------------------------------------------------------
Modification
--]]--

function GameObject.purgeAll()
	useful.map(__INSTANCES, 
		function(object)
			object.purge = true
		end)
  __INSTANCES = {}
  __NEXT_ID = 1
end

function GameObject.updateAll(dt, ysort, view)
    -- add new objects
  for _, object in pairs(__NEW_INSTANCES) do
    table.insert(__INSTANCES, object)
  end
  __NEW_INSTANCES = { }

  -- update objects
  -- ...for each object
  useful.map(__INSTANCES,
    function(object)
      -- ...update the object
      object:update(dt, level, view)
      -- ...check collisions with other objects
      useful.map(__INSTANCES,
          function(otherobject)
            -- check collisions between objects
            if object:isColliding(otherobject) then
              object:eventCollision(otherobject, dt)
            end
          end) 
  end)

	if ysort then
  	local oi = 1
  	while oi <= (#__INSTANCES) do
    	local obj = __INSTANCES[oi]
    	if oi > 1 then
      	local prev = __INSTANCES[oi-1]
      	if (prev.y > obj.y) then
        	__INSTANCES[oi] = prev
        	__INSTANCES[oi - 1] = obj
      	end
    	end
    	oi = oi + 1
  	end
	end
end

function GameObject.drawAll(view)
	-- for each object
  useful.map(__INSTANCES,
    function(object)
      -- if the object is in view...
      if (not view) or object:isColliding(view) then
        -- ...draw the object
        object:draw(view)
      end
  end)
end

function GameObject.mapToAll(f)
  for i, object in ipairs(__INSTANCES) do
    f(object, i)
  end
end

function GameObject.mapToType(typename, f)
  local t = __TYPE[typename]
  for i, object in ipairs(__INSTANCES) do
    if (object.type == t) then
      f(object, i)
    end
  end
end

--[[------------------------------------------------------------
Query
--]]--

--[[--
count
--]]--

function GameObject.countSuchThat(predicate)
  local count = 0
  for i, object in ipairs(__INSTANCES) do
    if predicate(object) then
      count = count + 1 
    end
  end
  return count
end

function GameObject.countOfTypeSuchThat(typename, predicate)
  local t = __TYPE[typename]
  local count = 0
  for i, object in ipairs(__INSTANCES) do
    if (object.type == t) and predicate(object) then
      count = count + 1 
    end
  end
  return count
end

--[[--
check predicate
--]]--

function GameObject.trueForAny(predicate)
  for i, object in ipairs(__INSTANCES) do
    if not predicate(object) then
      return true
    end
  end
  return false
end

function GameObject.trueForAnyOfType(typename, predicate)
  local t = __TYPE[typename]
  for i, object in ipairs(__INSTANCES) do
    if (object.type == t) and predicate(object) then
      return true
    end
  end
  return false
end

function GameObject.trueForAll(predicate)
	for i, object in ipairs(__INSTANCES) do
    if not predicate(object) then
      return false
    end
  end
  return true
end

function GameObject.trueForAllOfType(typename, predicate)
  local t = __TYPE[typename]
  for i, object in ipairs(__INSTANCES) do
    if (object.type == t) and (not predicate(object)) then
      return false
    end
  end
  return true
end


--[[--
find
--]]--

function GameObject.getObjectOfType(typename, index)
  if (not index) or (index < 1) then
    index = 1
  end
  local count = 0
  local t = __TYPE[typename]
  for i, object in ipairs(__INSTANCES) do
    if (object.type == t) then
      count = count + 1
      if count == index then
        return object
      end
    end
  end
  return nil
end

function GameObject.getFirstSuchThat(predicate)
  for i, object in ipairs(__INSTANCES) do
    if predicate(object) then
      return object
    end
  end
  return nil
end

function GameObject.getFirstOfTypeSuchThat(typename, predicate)
  local t = __TYPE[typename]
  for i, object in ipairs(__INSTANCES) do
    if (object.type == t) and predicate(object) then
      return object
    end
  end
  return nil
end

--[[------------------------------------------------------------
METHODS
--]]------------------------------------------------------------

--[[----------------------------------------------------------------------------
Collisions
--]]--

--[[--
instance collisions
--]]--

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

function GameObject:isColliding(other)
  -- no self collisions
  if self == other then
    return false
  end

  -- circle-circle collisions ?
  if self.r and other.r then
    return (vector.dist(self.x, self.y, other.x, other.y) < self.r + other.r)

  -- box-box collisions ?
  elseif self.w and self.h and other.w and other.h then
    local result = true

  	-- move origin to centre of object
    self.x, self.y, other.x, other.y = self.x - self.w/2, self.y - self.h/2, other.x - other.w/2, other.y - other.h/2

    -- horizontally seperate ? 
    local v1x = (other.x + other.w) - self.x
    local v2x = (self.x + self.w) - other.x
    if useful.sign(v1x) ~= useful.sign(v2x) then
      result = false --! don't return here as we need to move back the origin
    end
    -- vertically seperate ?
    local v1y = (self.y + self.h) - other.y
    local v2y = (other.y + other.h) - self.y
    if useful.sign(v1y) ~= useful.sign(v2y) then
      result = false --! don't return here as we need to move back the origin
    end
    
  	-- move origin back to top-left corner
    self.x, self.y, other.x, other.y = self.x + self.w/2, self.y + self.h/2, other.x + other.w/2, other.y + other.h/2
    
  	-- all done
  	return result
  end
end

function GameObject:isCollidingPoint(x, y)
  return (x >= self.x and x <= self.x + self.w
        and y >= self.y and y <= self.y + self.h)
end

--[[--
collision queries
--]]--

function  GameObject.lineCast(x1, y1, x2, y2, f)
  for i, object in ipairs(__INSTANCES) do
    if not object.purge then
      if object.r then
        if useful.lineCircleCollision(x1, y1, x2, y2, object.x, object.y, object.r) then
          f(object)
        end
      else
        -- TODO
      end
    end
  end
end

function  GameObject.lineCastForType(typename, x1, y1, x2, y2, f)
  local t = __TYPE[typename]
  for i, object in ipairs(__INSTANCES) do
    if (object.type == t) and (not object.purge) then
      if object.r then
        if useful.lineCircleCollision(x1, y1, x2, y2, object.x, object.y, object.r) then
          f(object)
        end
      else
        -- TODO
      end
    end
  end
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
    if target.r then
      scaling:circle("line",
        target.x, target.y, target.r)
    elseif target.w and target.h then
      scaling:rectangle("line", 
        target.x, target.y, target.w, target.h)
    end
    
  end
}

--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return GameObject