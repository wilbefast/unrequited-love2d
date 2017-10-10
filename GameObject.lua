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

local Class = require("unrequited/Class")
local Vector = require("unrequited/Vector")

local useful = require("unrequited/useful")
local scaling = require("unrequited/scaling")

--[[------------------------------------------------------------
GAMEOBJECT CLASS
--]]------------------------------------------------------------

--[[------------------------------------------------------------
Initialisation
--]]

-- container
local __UPDATE_LIST = { }
local __DRAW_LIST = { }
local __COLLISION_LIST = { }
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

function GameObject:isType(...)
  for i, typename in ipairs({...}) do
    if self.type == __TYPE[typename] then
      return true
    end
  end
  return false
end

--[[------------------------------------------------------------
CONTAINER
--]]------------------------------------------------------------

--[[----------------------------------------------------------------------------
Load from file
--]]--

function GameObject.loadFromObject(lua)
  if not lua.objects then
    error("Method 'loadFromObject' needs to be overriden")
  end
	for typename, instances in pairs(lua.objects) do
		local ftypeObject = loadstring("return " .. typename)
		if ftypeObject then
			local typeObject = ftypeObject()
			if typeObject and typeObject.loadFromObject then
				for _, parameters in ipairs(instances) do
					typeObject.loadFromObject(parameters)
				end
			end
		end
	end
end

function GameObject.loadFromFile(filename)
  local fimport, err = love.filesystem.load( filename )
  if err then
    return err
  end
  GameObject.loadFromObject(fimport())
end

--[[------------------------------------------------------------
Modification
--]]--

function GameObject.purgeAll()
	useful.map(__UPDATE_LIST,
		function(object)
			object.purge = true
      if object.onPurge then
        object:onPurge()
      end
		end)
  useful.map(__NEW_INSTANCES,
    function(object)
      object.purge = true
      if object.onPurge then
        object:onPurge()
      end
    end)
  __UPDATE_LIST = {}
  __COLLISION_LIST = {}
  __DRAW_LIST = {}
  __NEW_INSTANCES = {}
  __NEXT_ID = 1
end

function GameObject.flushCreatedObjects(oblique)
  for _, new_object in pairs(__NEW_INSTANCES) do

    if not new_object.purge then

      -- add to update list
      table.insert(__UPDATE_LIST, new_object)

      -- add to draw list
      if new_object.draw then
        local inserted = false
        local new_object_layer = (new_object.layer or (oblique and new_object.y) or 0)
        local oi = 1
        while (not inserted) and (oi <= (#__DRAW_LIST)) do
          local object = __DRAW_LIST[oi]
          local object_layer = (object.layer or (oblique and object.y) or 0)
          if (object_layer > new_object_layer) then
            -- add to the correct position in the list
            table.insert(__DRAW_LIST, oi, new_object)
            inserted = true
          end
          oi = oi + 1
        end
        if not inserted then
          -- default (add to the end)
          table.insert(__DRAW_LIST, new_object)
        end
      end

      -- add to collision list
      local _nullf = (function() end)
      if
        (new_object.w and new_object.h)
        or new_object.r
        or new_object.eventCollision
      then
        table.insert(__COLLISION_LIST, new_object)
        if not new_object.eventCollision then
          new_object.eventCollision = _nullf
        end
      end

    end

  end
  __NEW_INSTANCES = { }
end

function GameObject.updateAll(dt, view)
  -- oblique viewing angle ?
  local oblique = (view and view.oblique) or GameObject.view_oblique
  -- add new objects
  GameObject.flushCreatedObjects(oblique)

  -- update objects
  -- ...for each object
  useful.map(__UPDATE_LIST,
    function(object)
      -- ...update the object
      object:update(dt, level, view)
  end)

  -- calculate collisions
  useful.map(__COLLISION_LIST,
  	function(object)
	    -- ...check collisions with other objects
	    useful.map(__COLLISION_LIST,
        function(otherobject)
          -- check collisions between objects
          if object:isColliding(otherobject) then
            object:eventCollision(otherobject, dt)
          end
      	end)
	  end)

  -- resort draw list
	if oblique then
  	local oi = 1
  	while oi <= (#__DRAW_LIST) do
    	local obj = __DRAW_LIST[oi]
      local obj_layer = (obj.layer or obj.y)
    	if oi > 1 then
      	local prev = __DRAW_LIST[oi-1]
        local prev_layer = (prev.layer or prev.y)
      	if (prev_layer > obj_layer) then
        	__DRAW_LIST[oi] = prev
        	__DRAW_LIST[oi - 1] = obj
      	end
    	end
    	oi = oi + 1
  	end
	end
end

function GameObject.drawAll(view)
  -- oblique viewing angle ?
  local oblique = (view and view.oblique) or 1
	-- for each object
  useful.map(__DRAW_LIST,
    function(object)
      -- if the object is in view...
      if not object.purge and ((not view) or (not (view.x and view.y and view.w and view.h)) or object:isColliding(view)) then
        -- ...draw the object
        object:draw(object.x, object.y*oblique, view)
      end
  end)
end

function GameObject.mapToAll(f, suchThat)
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and ((not suchThat) or suchThat(object)) then
      local result = f(object, i)
      if result then
        return result
      end
    end
  end
end

function GameObject.mapToType(typename, f, suchThat)
  local t = __TYPE[typename]
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and (object.type == t) then
      if (not suchThat) or suchThat(object) then
        local result = f(object, i)
        if result then
          return result
        end
      end
    end
  end
end

function GameObject.mapToPair(f)
  for i = 1, #__UPDATE_LIST do
    for j = i+1, (#__UPDATE_LIST)-1 do
      local object1, object2 = __UPDATE_LIST[i], __UPDATE_LIST[j]
      if( not object1.purge) and (not object2.purge) then
        local result = f(i, j)
        if result then
          return result
        end
      end
    end
  end
end

function GameObject.mapToTypePair(typename1, typename2, f)
  local t1, t2 = __TYPE[typename1], __TYPE[typename2]
  for i = 1, #__UPDATE_LIST do
    local object1 = __UPDATE_LIST[i]
    if not object1.purge and (object1.type == t1) then
      for j = i+1, (#__UPDATE_LIST) do
        local object2 = __UPDATE_LIST[j]
        if not object2.purge and (object2.type == t2) then
          local result = f(object1, object2)
          if result then
            return result
          end
        end
      end
    end
  end
end

function GameObject.mapWithinRadius(x, y, radius, f, suchThat)
  local radius2 = radius*radius
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and ((not suchThat) or suchThat(object)) then
      local distance2 = Vector.dist2(x, y, object.x, object.y)
      if distance2 <= radius2 then
        local result = f(object, distance2)
        if result then
          return result
        end
      end
    end
  end
end

function GameObject.mapToTypeWithinRadius(typename, x, y, radius, f, suchThat)
  local t = __TYPE[typename]
  local radius2 = radius*radius
  for i, object in ipairs(__UPDATE_LIST) do
    if  not object.purge and (object.type == t) then
      if (not suchThat) or suchThat(object) then
        local distance2 = Vector.dist2(x, y, object.x, object.y)
        if distance2 <= radius2 then
          local result = f(object, distance2)
          if result then
            return result
          end
        end
      end
    end
  end
end

function GameObject.mapCollidingRadius(x, y, radius, f, suchThat)
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and ((not suchThat) or suchThat(object)) then
      local distance = Vector.dist(x, y, object.x, object.y)
      if distance - object.r <= radius then
        local result = f(object, distance)
        if result then
          return result
        end
      end
    end
  end
end


--[[------------------------------------------------------------
Query
--]]--

--[[--
get list
--]]--

function GameObject.getSuchThat(predicate)
  local result = {}
  for i, object in ipairs(__UPDATE_LIST) do
    if  not object.purge and predicate(object) then
      table.insert(result, object)
    end
  end
  return result
end

function GameObject.getOfTypeSuchThat(typename, predicate)
  local result = {}
  local t = __TYPE[typename]
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and (object.type == t) and ((not predicate) or predicate(object)) then
      table.insert(result, object)
    end
  end
  return result
end

--[[--
count
--]]--


function GameObject.countSuchThat(predicate)
  local count = 0
  for i, object in ipairs(__UPDATE_LIST) do
    if  not object.purge and predicate(object) then
      count = count + 1
    end
  end
  return count
end

function GameObject.countOfType(typename)
  local t = __TYPE[typename]
  local count = 0
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and (object.type == t) then
      count = count + 1
    end
  end
  return count
end


function GameObject.countOfTypeSuchThat(typename, predicate)
  local t = __TYPE[typename]
  local count = 0
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and (object.type == t) and ((not predicate) or predicate(object)) then
      count = count + 1
    end
  end
  return count
end

--[[--
check predicate
--]]--

function GameObject.trueForAny(predicate)
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and not predicate(object) then
      return true
    end
  end
  return false
end

function GameObject.trueForAnyOfType(typename, predicate)
  local t = __TYPE[typename]
  for i, object in ipairs(__UPDATE_LIST) do
    if  not object.purge and (object.type == t) and predicate(object) then
      return true
    end
  end
  return false
end

function GameObject.trueForAll(predicate)
	for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and not predicate(object) then
      return false
    end
  end
  return true
end

function GameObject.trueForAllOfType(typename, predicate)
  local t = __TYPE[typename]
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and (object.type == t) and (not predicate(object)) then
      return false
    end
  end
  return true
end


--[[--
find matching
--]]--

function GameObject.getObjectOfType(typename, index)
  if (not index) or (index < 1) then
    index = 1
  end
  local count = 0
  local t = __TYPE[typename]
  for i, object in ipairs(__UPDATE_LIST) do
    if  not object.purge and (object.type == t) then
      count = count + 1
      if count == index then
        return object
      end
    end
  end
  return nil
end

function GameObject.getFirstSuchThat(predicate)
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and predicate(object) then
      return object
    end
  end
  return nil
end

function GameObject.getFirstOfTypeSuchThat(typename, predicate)
  local t = __TYPE[typename]
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and (object.type == t) and predicate(object) then
      return object
    end
  end
  return nil
end

--[[--
find min/max
--]]--

function GameObject.getMost(evaluator)
  local best, best_value = nil, -math.huge
  for i, object in ipairs(__UPDATE_LIST) do
    local value = evaluator(object)
    if not object.purge then
      if value > best_value then
        best, best_value = object, value
      end
    end
  end
  return best, best_value
end

function GameObject.getMostOfType(typename, evaluator)
  local t = __TYPE[typename]
  local best, best_value = nil, -math.huge
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and (object.type == t) then
      local value = evaluator(object)
      if value > best_value then
        best, best_value = object, value
      end
    end
  end
  return best, best_value
end

function GameObject.getLeast(evaluator)
  local best, best_value = nil, math.huge
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge then
      local value = evaluator(object)
      if value < best_value then
        best, best_value = object, value
      end
    end
  end
  return best, best_value
end

function GameObject.getLeastOfType(typename, evaluator)
  local t = __TYPE[typename]
  local best, best_value = nil, math.huge
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and (object.type == t) then
      local value = evaluator(object)
      if value < best_value then
        best, best_value = object, value
      end
    end
  end
  return best, best_value
end

--[[--
find nearest/furthest
--]]--

function GameObject.getNearest(x, y, suchThat)
  local nearest, nearest_distance2 = nil, math.huge
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and ((not suchThat) or suchThat(object)) then
      local distance2 = Vector.dist2(x, y, object.x, object.y)
      if distance2 < nearest_distance2 then
        nearest, nearest_distance2 = object, distance2
      end
    end
  end
  return nearest, nearest_distance2
end

function GameObject.getFurthest(x, y, suchThat)
  local furthest, furthest_distance2 = nil, math.huge
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and ((not suchThat) or suchThat(object)) then
      local distance2 = Vector.dist2(x, y, object.x, object.y)
      if distance2 > nearest_distance2 then
        furthest, furthest_distance2 = object, distance2
      end
    end
  end
  return furthest, furthest_distance2
end

function GameObject.getNearestOfType(typename, x, y, suchThat)
  local t = __TYPE[typename]
  local nearest, nearest_distance2 = nil, math.huge
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and (object.type == t) then
      if (not suchThat) or suchThat(object) then
        local distance2 = Vector.dist2(x, y, object.x, object.y)
        if distance2 < nearest_distance2 then
          nearest, nearest_distance2 = object, distance2
        end
      end
    end
  end
  return nearest, nearest_distance2
end

function GameObject.getNearestToCollideOfType(typename, x, y, suchThat)
  local t = __TYPE[typename]
  local nearest, nearest_distance = nil, math.huge
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and (object.type == t) then
      if (not suchThat) or suchThat(object) then
        local toMe_x, toMe_y, dist = Vector.normalise(x - object.x, y - object.y)
        dist = dist - (object.r or object.w or 0)
        if dist < nearest_distance then
          nearest, nearest_distance = object, dist
        end
      end
    end
  end
  return nearest, nearest_distance
end

function GameObject.getFurthestOfType(typename, x, y, suchThat)
  local t = __TYPE[typename]
  local furthest, furthest_distance2 = nil, math.huge
  for i, object in ipairs(__UPDATE_LIST) do
    if not object.purge and (object.type == t) then
      if (not suchThat) or suchThat(object) then
        local distance2 = Vector.dist2(x, y, object.x, object.y)
        if distance2 > nearest_distance2 then
          furthest, furthest_distance2 = object, distance2
        end
      end
    end
  end
  return furthest, furthest_distance2
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
  while collisiongrid:objectCollision(self, self.x, self.y, type)
  and (not max or i < max)  do
    self.x = self.x + dx
    self.y = self.y + dy
    i = i + 1
  end
end

function GameObject:snap_to_collision(dx, dy, collisiongrid, max, type)
  if dx == 0 and dy == 0 then
    return
  end
  local i = 0
  while not collisiongrid:objectCollision(self, self.x + dx, self.y + dy, type)
        and (not max or i < max)  do
    self.x = self.x + dx
    self.y = self.y + dy
    i = i + 1
  end
end

function GameObject:isColliding(other)
  -- no self collisions
  if self == other then
    return false
  end

  -- circle-circle collisions ?
  if self.r and other.r then
    return (Vector.dist2(self.x, self.y, other.x, other.y) < useful.sqr(self.r + other.r))

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
  if self.r  then
    local dx, dy = self.x - x, self.y - y
    return (dx*dx + dy*dy < self.r*self.r)
  elseif self.w and self.h then
    return (x >= self.x and x <= self.x + self.w
          and y >= self.y and y <= self.y + self.h)
  else
    return false
  end
end

--[[--
collision queries
--]]--

function  GameObject.lineCast(x1, y1, x2, y2, f)
  for i, object in ipairs(__COLLISION_LIST) do
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
  for i, object in ipairs(__COLLISION_LIST) do
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

--[[--
Snap
--]]--

function  GameObject:snapInsideBoundary(bx, by, bw, bh)
  local w, h = self.r or self.w*0.5 or 0, self.r or self.w*0.5 or 0
  self.x = math.max(bx + w, math.min(self.x, bx + bw - w))
  self.y = math.max(by + h, math.min(self.y, by + bh - h))
end

function  GameObject:isInsideBoundary(bx, by, bw, bh)
  local w, h = self.r or self.w*0.5 or 0, self.r or self.w*0.5 or 0
  if self.x + w > bx + bw then
    return false
  elseif self.x - w < bx then
    return false
  elseif self.y + h > by + bh then
    return false
  elseif self.y - h > by then
    return false
  else
    return true
  end
end

--[[------------------------------------------------------------
Physics
--]]

function GameObject:accelerateTowards(x, y, speed)
  speed = (speed or 1)
  local ddx, ddy = Vector.normalise(x - self.x, y - self.y)
  self.dx, self.dy = self.dx + ddx*speed, self.dy + ddy*speed
end

function GameObject:accelerateAwayFrom(x, y, speed)
  speed = (speed or 1)
  local ddx, ddy = Vector.normalise(x - self.x, y - self.y)
  self.dx, self.dy = self.dx - ddx*speed, self.dy - ddy*speed
end


function GameObject:accelerateTowardsObject(o, speed)
  speed = (speed or 1)
  local ddx, ddy = Vector.normalise(o.x - self.x, o.y - self.y)
  self.dx, self.dy = self.dx + ddx*speed, self.dy + ddy*speed
end

function GameObject:accelerateAwayFromObject(o, speed)
  speed = (speed or 1)
  local ddx, ddy = Vector.normalise(o.x - self.x, o.y - self.y)
  self.dx, self.dy = self.dx - ddx*speed, self.dy - ddy*speed
end

function GameObject:springTowards(x, y, springConstant)
  springConstant = (springConstant or 1)
  local ddx, ddy = x - self.x, y - self.y
  self.dx, self.dy = self.dx + ddx*springConstant, self.dy + ddy*springConstant
end

function GameObject:springAwayFrom(x, y, springConstant)
  springConstant = (springConstant or 1)
  local ddx, ddy = x - self.x, y - self.y
  if math.abs(ddx) < 1 then ddx = useful.sign(ddx)*1 end
  if math.abs(ddy) < 1 then ddy = useful.sign(ddy)*1 end
  self.dx, self.dy = self.dx - springConstant/ddx, self.dy - springConstant/ddy
end

function GameObject:springTowardsObject(o, springConstant)
  springConstant = (springConstant or 1)
  local ddx, ddy = o.x - self.x, o.y - self.y
  self.dx, self.dy = self.dx + ddx*springConstant, self.dy + ddy*springConstant
end

function GameObject:springAwayFromObject(o, springConstant)
  springConstant = (springConstant or 1)
  local ddx, ddy = o.x - self.x, o.y - self.y
  if math.abs(ddx) < 1 then ddx = useful.sign(ddx)*1 end
  if math.abs(ddy) < 1 then ddy = useful.sign(ddy)*1 end
  self.dx, self.dy = self.dx - springConstant/ddx, self.dy - springConstant/ddy
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
  if fisix.FRICTION and ((self.dx ~= 0) or (self.dy ~= 0)) then

    local normed_dx, normed_dy, original_speed = Vector.normalise(self.dx, self.dy)
    local new_speed = original_speed / (math.pow(fisix.FRICTION, dt))
    self.dx, self.dy = normed_dx*new_speed, normed_dy*new_speed
  end

  -- terminal velocity
  local abs_dx, abs_dy = math.abs(self.dx), math.abs(self.dy)
  if (self.dx ~= 0) and fisix.MAX_DX and (abs_dx > fisix.MAX_DX) then
    self.dx = fisix.MAX_DX*useful.sign(self.dx)
  end
  if (self.dy ~= 0) and fisix.MAX_DY and (abs_dy > fisix.MAX_DY) then
    self.dy = fisix.MAX_DY*useful.sign(self.dy)
  end
  if fisix.MAX_SPEED then
    local speed2 = Vector.len(self.dx, self.dy)
    if speed2 > fisix.MAX_SPEED*fisix.MAX_SPEED then
      local dx, dy = Vector.normalise(self.dx, self.dy)
      self.dx, self.dy = dx*fisix.MAX_SPEED, dy*fisix.MAX_SPEED
    end
  end

  -- clamp less than epsilon inertia to 0
  if math.abs(self.dx) < 0.01 then self.dx = 0 end
  if math.abs(self.dy) < 0.01 then self.dy = 0 end

  if self.COLLISIONGRID then

    local w, h = self.w or self.r or 0, self.h or self.r or 0

    local collisiongrid = self.COLLISIONGRID
    -- check if we're on the ground
    if fisix.GRAVITY then
      self.airborne =
        ((not collisiongrid:pixelCollision(self.x, self.y + h + 1, collide_type)
        and (not collisiongrid:pixelCollision(self.x + w, self.y + h + 1, collide_type))))
      if not self.airborne and self.dy > 0 then
        if collisiongrid:objectCollision(self, self.x, self.y, collide_type) then
          self:snap_from_collision(0, -1, collisiongrid, math.abs(self.dy), collide_type)
        end
        self.dy = 0
      end
    end


    -- move HORIZONTALLY FIRST
    if self.dx ~= 0 then
      local move_x = self.dx * dt
      local new_x = self.x + move_x
      self.prevx = self.x
      -- is new x in collision ?
      if collisiongrid:objectCollision(self, new_x, self.y) then
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
      if collisiongrid:objectCollision(self, self.x, new_y) then
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

function GameObject:debugDraw()
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
        target.x - target.w*0.5, target.y - target.h*0.5, target.w, target.h)
    end

  end
}

--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return GameObject
