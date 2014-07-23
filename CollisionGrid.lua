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
local useful = require("unrequited/useful")

--[[------------------------------------------------------------
COLLISIONGRID CLASS
--]]------------------------------------------------------------

--[[------------------------------------------------------------
Initialisation
--]]

local CollisionGrid = Class
{
  init = function(self, tileClass, tilew, tileh, w, h)
  
    -- grab the size of the tiles
    self.tilew, self.tileh = tilew, tileh
  
    -- grab the size of the map
    if w and h then
      self.w, self.h = w, h
    else
      self.w = love.graphics.getWidth() / tilew
      self.h = love.graphics.getHeight() / tileh
    end

    -- create the collision map
    self.tiles = {}
    for col = 1, self.w do
      self.tiles[col] = {}
      for row = 1, self.h do
        local t = tileClass(col, row, self.tilew, self.tileh, self)
        t.col = col
        t.row = row
        t.x = (col - 1)*tilew
        t.y = (row - 1)*tileh
        t.w = tilew
        t.h = tileh
        t.grid = self
        self.tiles[col][row] = t
      end
    end

    -- create neighbourhood graph
    local directions8 = { "NW", "W", "N", "NE", "SW", "S", "E", "SE" }
    local directions4 = { "W", "N", "S", "E" }
    local directionsX = { "NW", "NE", "SW", "SE" }
    for col = 1, self.w do
      for row = 1, self.h do
        local t = self.tiles[col][row] 
        t.neighbours8 = self:getNeighbours8(t)
        t.neighbours4 = self:getNeighbours4(t)
        t.neighboursX = self:getNeighboursX(t)
        for i, dir in ipairs(directions8) do
          t[dir] = t.neighbours8[i]
        end
      end
    end
  end
}

--[[----------------------------------------------------------------------------
Map functions to all or part of the grid
--]]--

function CollisionGrid:mapRectangle(startCol, startRow, w, h, f)
  for col = startCol, startCol + w - 1 do
    for row = startRow, startRow + h - 1 do
      if self:validGridPos(col, row) then
        f(self.tiles[col][row], col, row)
      end
    end
  end
end

function CollisionGrid:map(f)
  for col = 1, self.w do
    for row = 1, self.h do
      f(self.tiles[col][row], col, row)
    end
  end
end

--[[----------------------------------------------------------------------------
Tile neighbours
--]]--

function CollisionGrid:getNeighbours8(t, centre)
  local result = {}
  function insertIfNotNil(t, value) if value then table.insert(t, value) end end
  insertIfNotNil(result, self:gridToTile(t.col-1, t.row-1, true))  -- NW
  insertIfNotNil(result, self:gridToTile(t.col-1, t.row, true))    -- W
  insertIfNotNil(result, self:gridToTile(t.col, t.row-1, true))    -- N
  insertIfNotNil(result, self:gridToTile(t.col+1, t.row-1, true))  -- NE
  insertIfNotNil(result, self:gridToTile(t.col-1, t.row+1, true))  -- SW
  insertIfNotNil(result, self:gridToTile(t.col, t.row+1, true))    -- S
  insertIfNotNil(result, self:gridToTile(t.col+1, t.row, true))    -- E
  insertIfNotNil(result, self:gridToTile(t.col+1, t.row+1, true))  -- SE
  if centre then
    insertIfNotNil(result, self:gridToTile(t.col, t.row, true))
  end
  return result
end

function CollisionGrid:getNeighbours4(t, centre)
  local result = {}
  function insertIfNotNil(t, value) if value then table.insert(t, value) end end
  insertIfNotNil(result, self:gridToTile(t.col-1, t.row, true))    -- W
  insertIfNotNil(result, self:gridToTile(t.col, t.row-1, true))    -- N
  insertIfNotNil(result, self:gridToTile(t.col, t.row+1, true))    -- S
  insertIfNotNil(result, self:gridToTile(t.col+1, t.row, true))    -- E
  if centre then
    insertIfNotNil(result, self:gridToTile(t.col, t.row, true))
  end
  return result
end

function CollisionGrid:getNeighboursX(t, centre)
  local result = {}
function insertIfNotNil(t, value) if value then table.insert(t, value) end end
  insertIfNotNil(result, self:gridToTile(t.col-1, t.row-1, true))    -- NW
  insertIfNotNil(result, self:gridToTile(t.col+1, t.row-1, true))    -- NE
  insertIfNotNil(result, self:gridToTile(t.col-1, t.row+1, true))    -- SW
  insertIfNotNil(result, self:gridToTile(t.col+1, t.row+1, true))    -- SE
  if centre then
    insertIfNotNil(result, self:gridToTile(t.col, t.row, true))
  end
  return result
end

--[[------------------------------------------------------------
Game loop
--]]--

function CollisionGrid:draw(view) 

  local start_col, start_row, end_col, end_row = 1, 1, self.w, self.h
  if view then
    start_col = math.max(1, math.floor(view.x / self.tilew))
    end_col = math.min(self.w, 
                start_col + math.ceil(view.w / self.tilew))
    
    start_row = math.max(1, math.floor(view.y / self.tileh))
    end_row = math.min(self.h, 
                start_row + math.ceil(view.h / self.tileh))
  end

  -- draw tile background images
  -- ... for each column ...
  for col = start_col, end_col do
    -- ... for each row ...
    for row = start_row, end_row do
      local tile = self.tiles[col][row]
			if tile.draw then
				tile:draw(col, row)
      end
    end
  end

    --TODO use sprite batches
end

--[[----------------------------------------------------------------------------
Accessors
--]]--

function CollisionGrid:gridToTile(col, row, lap_around)

  if lap_around then
    while col < 1 do col = col + self.w end
    while row < 1 do row = row + self.h end
    while col > self.w do col = col - self.w end
    while row > self.h do row = row - self.h end
    return self.tiles[col][row]
  else
    if self:validGridPos(col, row) then
      return self.tiles[col][row]
    else
      return nil --FIXME return default tile
    end
  end
end

function CollisionGrid:pixelToTile(x, y)
  return self:gridToTile(math.floor(x / self.tilew) + 1,
                         math.floor(y / self.tileh) + 1)
end

function CollisionGrid:centrePixel()
  return self.w*self.tilew/2, self.h*self.tileh/2
end

--[[----------------------------------------------------------------------------
Conversion
--]]--

function CollisionGrid:pixelToGrid(x, y)
  return math.floor(x / self.tilew) + 1, math.floor(y / self.tileh) +1
end

function CollisionGrid:gridToPixel(col, row)
  return (col-1) * self.tilew, (row-1) * self.tileh
end


--[[----------------------------------------------------------------------------
Avoid array out-of-bounds exceptions
--]]--

function CollisionGrid:validGridPos(col, row)
  return (col >= 1 
      and row >= 1
      and col <= self.w 
      and row <= self.h) 
end

function CollisionGrid:validPixelPos(x, y)
  return (x >= 0
      and y >= 0
      and x <= self.size.x*self.tilew
      and y <= self.size.y*self.tileh)
end


--[[----------------------------------------------------------------------------
Basic collision tests
--]]--

function CollisionGrid:gridCollision(col, row, object)
  type = (type or Tile.TYPE.WALL)
  return (self:gridToTile(col, row).type == type)
end

function CollisionGrid:pixelCollision(x, y, object)
  local tile = self:pixelToTile(x, y)
	if not tile then
		return true
	elseif object and object.canEnterTile then
		return object:canEnterTile(tile)
	else
		return tile:canBeEntered()
	end
end

--[[----------------------------------------------------------------------------
GameObject collision tests
--]]--

function CollisionGrid:objectCollision(object, x, y)
  -- x & y are optional: leave them out to test the object where it actually is
  x = (x or go.x)
  y = (y or go.y)
  
  -- rectangle collision mask, origin is at the top-left
  return (self:pixelCollision(x, y, object) 
      or  self:pixelCollision(x + object.w, y, object) 
      or  self:pixelCollision(x, y + object.h, object)
      or  self:pixelCollision(x + object.w, y + object.h, object))
end

function CollisionGrid:collision_next(go, dt)
  return self:collision(go, go.x + go.dx*dt, go.y + go.dy*dt)
end


--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return CollisionGrid