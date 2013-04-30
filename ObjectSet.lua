--[[
(C) Copyright 2013 
William Dyce, Maxime Ailloud, Alex Verbrugghe, Julien Deville

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
OBJECTSET CLASS
--]]------------------------------------------------------------

--[[------------------------------------------------------------
Initialisation
--]]

local ObjectSet = Class
{
}

--[[------------------------------------------------------------
Objects
--]]

function ObjectSet:getObject(type, i)
  i = (i or 1)
  local objects = self.object_types[type] 
  if objects and (i <= #objects) then
    return (self.object_types[type][i])
  else
    return nil
  end
end

function ObjectSet:countObject(type)
  return #(self.object_types[type])
end

function ObjectSet:addObject(object)
  -- are there other objects of this type?
  if (not self.object_types[object.type]) then
    self.object_types[object.type] = {}
  end
  table.insert(self.object_types[object.type], object) 
end

--[[------------------------------------------------------------
Game loop
--]]

function ObjectSet:update(dt, view)
  
  -- update objects
  -- ...for each type of object
  for type, objects_of_type in pairs(self.object_types) do
    -- ...for each object
    useful.map(objects_of_type,
      function(object)
        -- ...update the object
        object:update(dt, self, view)
        -- ...check collisions with other object
        -- ...... for each other type of object
        for othertype, objects_of_othertype 
            in pairs(self.object_types) do
          if object:collidesType(othertype) then
            -- ...... for each object of this other type
            useful.map(objects_of_othertype,
                function(otherobject)
                  -- check collisions between objects
                  if object:isColliding(otherobject) then
                    object:eventCollision(otherobject, self)
                  end
                end)
          end
        end  
    end)
  end
end

function ObjectSet:draw(view)
  -- draw the tiles
  self.imagegrid:draw(view)
  
  -- draw the collideable grid if in debug mode
  if DEBUG then
    self.collisiongrid:draw(view)
  end
  
  -- for each type of object
  for t, object_type in pairs(self.object_types) do
    -- for each object
    useful.map(object_type,
      function(object)
        -- if the object is in view...
        if object:isColliding(view) then
          -- ...draw the object
          object:draw()
        end
    end)
  end
end

--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return ObjectSet