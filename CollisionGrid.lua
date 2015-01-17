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
  init = function(self, tileClass, tilew, tileh, w, h, x, y)
  
    self.x, self.y = x or 0, y or 0

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
        t.x = self.x + (col - 1)*tilew
        t.y = self.y + (row - 1)*tileh
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
Export to file
--]]--

function CollisionGrid:toString(tile_tostring)
  local result = ""
  local indent, newline = "   ", "\n"

  result = result .. "{" .. newline
    result = result .. indent .. "x = " .. self.x .. "," .. newline
    result = result .. indent .. "y = " .. self.x .. "," .. newline
    result = result .. indent .. "tilew = " .. self.tilew .. "," .. newline
    result = result .. indent .. "tileh = " .. self.tileh .. "," .. newline
    result = result .. indent .. "w = " .. self.w .. "," .. newline
    result = result .. indent .. "h = " .. self.h .. "," .. newline
    result = result .. indent .. "tiles = {"
      for col = 1, self.w do
        result = result .. newline .. indent .. indent .. "{"
        for row = 1, self.h do
          local tile = self.tiles[col][row]
          local string = (tile_tostring and tile_tostring(tile)) or tile:toString()
          result = result .. string .. ((row < self.h) and "," or "")
        end
        result = result .. "}" .. ((col < self.w) and "," or "")
      end
    result = result .. newline .. indent .. "}"
  result = result .. newline .. "}"

  return result
end

function CollisionGrid:saveToFile(filename, tile_toString)
  -- open file, error check
  local file, err = io.open(filename, "wb")
  if err then 
    return err 
  end
  file:write("return " .. self:toString(tile_toString))
  -- all done, clean up
  file:close()
end

--[[----------------------------------------------------------------------------
Restore from file
--]]--

function CollisionGrid:loadFromObject(object, tileClass)
  self:init(tileClass, object.tilew, object.tileh, object.w, object.h)
  for col = 1, self.w do
    for row = 1, self.h do
      self.tiles[col][row]:import(object.tiles[col][row])
    end
  end
end

function CollisionGrid:loadFromFile(filename, tileClass)
  local fimport, err = loadfile(filename)
  if err then 
    return err 
  end
  self:loadFromObject(fimport())
end


--[[----------------------------------------------------------------------------
Tile neighbours
--]]--

function __insertIfNotNil(t, value) table.insert(t, value or false)  end

function CollisionGrid:getNeighbours8(t, centre, lap)
  local result = {}
  __insertIfNotNil(result, self:gridToTile(t.col-1, t.row-1, lap))  -- NW
  __insertIfNotNil(result, self:gridToTile(t.col-1, t.row, lap))    -- W
  __insertIfNotNil(result, self:gridToTile(t.col, t.row-1, lap))    -- N
  __insertIfNotNil(result, self:gridToTile(t.col+1, t.row-1, lap))  -- NE
  __insertIfNotNil(result, self:gridToTile(t.col-1, t.row+1, lap))  -- SW
  __insertIfNotNil(result, self:gridToTile(t.col, t.row+1, lap))    -- S
  __insertIfNotNil(result, self:gridToTile(t.col+1, t.row, lap))    -- E
  __insertIfNotNil(result, self:gridToTile(t.col+1, t.row+1, lap))  -- SE
  if centre then
    __insertIfNotNil(result, self:gridToTile(t.col, t.row, lap))
  end
  return result
end

function CollisionGrid:getNeighbours4(t, centre, lap)
  local result = {}
  __insertIfNotNil(result, self:gridToTile(t.col-1, t.row, lap))    -- W
  __insertIfNotNil(result, self:gridToTile(t.col, t.row-1, lap))    -- N
  __insertIfNotNil(result, self:gridToTile(t.col, t.row+1, lap))    -- S
  __insertIfNotNil(result, self:gridToTile(t.col+1, t.row, lap))    -- E
  if centre then
    __insertIfNotNil(result, self:gridToTile(t.col, t.row, lap))
  end
  return result
end

function CollisionGrid:getNeighboursX(t, centre, lap)
  local result = {}
  __insertIfNotNil(result, self:gridToTile(t.col-1, t.row-1, lap))    -- NW
  __insertIfNotNil(result, self:gridToTile(t.col+1, t.row-1, lap))    -- NE
  __insertIfNotNil(result, self:gridToTile(t.col-1, t.row+1, lap))    -- SW
  __insertIfNotNil(result, self:gridToTile(t.col+1, t.row+1, lap))    -- SE
  if centre then
    __insertIfNotNil(result, self:gridToTile(t.col, t.row, lap))
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
  return self:gridToTile(math.floor((x - self.x) / self.tilew) + 1,
                         math.floor((y - self.y) / self.tileh) + 1)
end

function CollisionGrid:centrePixel()
  return self.w*self.tilew/2, self.h*self.tileh/2
end

--[[----------------------------------------------------------------------------
Conversion
--]]--

function CollisionGrid:pixelToGrid(x, y)
  return math.floor(x / self.tilew) + 1, math.floor(y / self.tileh) + 1
end

function CollisionGrid:gridToPixel(col, row)
  return (col-0.5) * self.tilew, (row-0.5) * self.tileh
end

function CollisionGrid:snapPixelToGrid(x, y)
  return (math.floor(x / self.tilew) + 0.5) * self.tilew,
          (math.floor(y / self.tileh) + 0.5) * self.tileh
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
  local tile = self:gridToTile(col, row)
  if not tile then
    return true
  elseif object and object.canEnterTile then
    return not object:canEnterTile(tile)
  else
    return not tile:canBeEntered()
  end
end

function CollisionGrid:pixelCollision(x, y, object)
  local col, row = self:pixelToGrid(x, y, object)
  return self:gridCollision(col, row, object)
end

--[[----------------------------------------------------------------------------
GameObject collision tests
--]]--

function CollisionGrid:objectCollision(object, x, y)
  -- x & y are optional: leave them out to test the object where it actually is
  x = (x or go.x)
  y = (y or go.y)
  local w, h = object.w or object.r or 0, object.h or object.r or 0
  
  -- rectangle collision mask, origin is at the top-left
  return (self:pixelCollision(x, y, object) 
      or  self:pixelCollision(x + w, y, object) 
      or  self:pixelCollision(x, y + h, object)
      or  self:pixelCollision(x + w, y + h, object))
end

function CollisionGrid:objectCollisionNext(go, dt)
  return self:objectCollision(go, go.x + go.dx*dt, go.y + go.dy*dt)
end

--[[----------------------------------------------------------------------------
Pathing
--]]--

local __estimatePathCost = function(startTile, endTile)
  return Vector.len(startTile.col, startTile.row, endTile.col, endTile.row)
end

local __setPathStatePrevious = function(pathState, previousPathState)
  pathState.previousPathState = previousPathState
  pathState.currentCost = previousPathState.currentCost + 1
end

local __createPathState = function(currentTile, goalTile, previousPathState)
  local pathState = {
    currentTile = currentTile,
    goalTile = goalTile,
    opened = false,
    closed = false,
  }
  if previousPathState then
    __setPathStatePrevious(pathState, previousPathState)
  else
    pathState.currentCost = 0
  end
  pathState.remainingCostEstimate = __estimatePathCost(pathState.currentTile, pathState.goalTile)
  pathState.totalCostEstimate = pathState.currentCost + pathState.remainingCostEstimate
  return pathState
end


local __expandPathState = function(pathState, allStates, openStates, object)
  for _, neighbourTile in ipairs(pathState.currentTile.neighbours4) do
    if neighbourTile and ((neighbourTile.isPathable and neighbourTile:isPathable(object)) or neighbourTile:canBeEntered(object)) then

      -- find or create the neighbour state
      local neighbourState = allStates[neighbourTile]
      if not neighbourState then
        neighbourState = __createPathState(neighbourTile, pathState.goalTile, pathState)
        allStates[neighbourTile] = neighbourState
      end

      -- do nothing if the state is closed
      if not neighbourState.closed then
        if not neighbourState.opened then
          -- always open states that have not yet been opened and create a link
          __setPathStatePrevious(neighbourState, pathState)
          neighbourState.opened = true
          table.insert(openStates, neighbourState)
        else
          -- create a link with already open states provided the cost would be improved
          if pathState.currentCost < neighbourState.currentCost then
            __setPathStatePrevious(neighbourState, pathState)
          end
        end
      end
    end
  end
end

function CollisionGrid:gridPath(startcol, startrow, endcol, endrow, object)

  local startTile = self:gridToTile(startcol, startrow)
  local endTile = self:gridToTile(endcol, endrow)
  if not startTile or not endTile then
    return {}
  end

  local startState = __createPathState(startTile, endTile)

  local openStates = { startState }
  local allStates = { startTile = startState}

  local fallback = nil

  while (#openStates > 0) do
    -- expand from the open state that is currently cheapest
    local state = table.remove(openStates)
    -- have we reached the end?
    if state.currentTile == endTile then
      local path = { }
      -- read back and return the result
      while state do
        table.insert(path, 0, state.currentTile)
        state = state.previousPathState
      end
      return path
    end

    -- try to expand each neighbour
    __expandPathState(state, allStates, openStates, object)

    -- remember to close the state now that all connections have been expanded
    state.closed = true

    -- keep the best closed state, just in case the target is inaccessible
    if not fallback or __estimatePathCost(state.currentTile, endTile)
    < __estimatePathCost(fallback.currentTile, endTile) then
      fallback_plan = state
    end

    -- sort the lowest cost states the the end of the table, they will be popped first
    table.sort(openStates, function(a, b) return (a.totalCostEstimate > b.totalCostEstimate) end)
  end

  -- fail!
  local path = { }
  if fallback then
    local state = fallback
    while state do
      table.insert(path, 0, state.currentTile)
      state = state.previousPathState
    end
  end
  return path
end

function CollisionGrid:pixelPath(startx, starty, endx, endy, object)
  local gridPath = self:gridPath(startcol, startrow, endcol, endrow, object)
  local pixelPath = {}
  for _, tile in ipairs(gridPath) do
    table.insert(pixelPath, { x = tile.x + tile.w*0.5, y = tile.y + tile.h*0.5 })
  end

  return pixelPath
end

function CollisionGrid:gridRayCollision(startcol, startrow, endcol, endrow, object)
  -- http://en.wikipedia.org/wiki/Bresenham's_line_algorithm
  local dx = math.abs(endcol - startcol)
  local dy = math.abs(endrow - startrow)
  local sx = ((startcol < endcol) and 1) or -1
  local sy = ((startrow < endrow) and 1) or -1
  local err = dx - dy

  while (startcol ~= endcol) or (startrow ~= endrow) do
    if self:gridCollision(startcol, startrow, object) then
      -- the way is shut (it was made by those who are dead)
      return { col = startcol, row = startrow }
    end
    local err2 = 2*err;
    --  move horizontally
    if err2 > -dy then
      err = err - dy
      startcol = startcol + sx
    end
    -- move vertically
    if err2 < dx then
      err = err + dx
      startrow = startrow + sy
    end
  end
  -- made it - the way is clear!
  return nil
end

function CollisionGrid:pixelRayCollision(startx, starty, endx, endy, object)
  local startcol, startrow = self:pixelToGrid(startx, starty)
  local endcol, endrow = self:pixelToGrid(endx, endy)
  return self:gridRayCollision(startcol, startrow, endcol, endrow, object)
end

--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return CollisionGrid