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
local useful = require("useful")

--[[------------------------------------------------------------
TILESET CLASS
--]]------------------------------------------------------------

local TileSet = Class
{
  init = function(self, tileset)
  
    -- read the Tile.d exported Lua tileset object
    self.image = love.graphics.newImage(tileset.image)
    self.quadw = tileset.tilewidth
    self.quadh = tileset.tileheight
    -- ... number of tiles
    self.n_across = math.floor(tileset.imagewidth 
                          / tileset.tilewidth)
    self.n_down = math.floor(tileset.imageheight 
                          / tileset.tileheight)
    self.n_total = self.n_down*self.n_across
    -- ... first tile identifier
    self.first_id = tileset.firstgid
        
    -- create quads
    self.quads = {}
    for y = 1, self.n_down do
      for x = 1, self.n_across do
        table.insert(self.quads, love.graphics.newQuad(
          (x-1)*self.quadw, (y-1)*self.quadh, 
          self.quadw, self.quadh,
          tileset.imagewidth, tileset.imageheight))
      end
    end
  end
}

function TileSet:tryDraw(id, x, y)
  -- offset id and check if it's one of this tileset's
  id = id - self.first_id + 1
  if (id < 1) or (id > self.n_total) then
    return false -- fail!
  end
  -- draw using the appropriate quad and report success
  love.graphics.drawq(self.image, self.quads[id], 
      (x-1)*self.quadw, (y-1)*self.quadh)
  return true -- success!
end

--[[------------------------------------------------------------
IMAGEGRID CLASS
--]]------------------------------------------------------------

--[[------------------------------------------------------------
Initialisation
--]]

local ImageGrid = Class
{
  init = function(self, mapfile)
  
    -- grab the size of the tiles
    self.quadw = mapfile.tilewidth
    self.quadh = mapfile.tileheight
  
    -- grab the size of the map
    self.w = mapfile.width
    self.h = mapfile.height
    
    -- grab the tilesets
    self.tilesets = {}
    for t, tileset in ipairs(mapfile.tilesets) do
      -- create a new TileSet object
      table.insert(self.tilesets, TileSet(tileset))
    end

    -- create graphics layers
    self.layers = {}
    local z = 1
    -- ... for each layer
    for _, layer in ipairs(mapfile.layers) do
      
      --! GENERATE IMAGE GRID
      if layer.type == "tilelayer" then
        if layer.type == "tilelayer" then
          -- the mapfile stores tiles in [row, col] format
          local temp_layer = {}
          local data_i = 1
          for row = 1, self.h do
            temp_layer[row] = {}
            for col = 1, self.w do
              temp_layer[row][col] = layer.data[data_i]
              data_i = data_i + 1
            end
          end
            
          -- we want them in [x, y] format, so we transpose
          self.layers[z] = {}
          for x = 1, self.w do
            self.layers[z][x] = {}
            for y = 1, self.h do
              self.layers[z][x][y] = temp_layer[y][x]
            end
          end
          
          -- increment the layer counter
          z = z + 1
        end
      end
    end
  end
}

--[[------------------------------------------------------------
Game Loop
--]]

function ImageGrid:tryDraw(id, x, y)
  for _, tileset in ipairs(self.tilesets) do
    if tileset:tryDraw(id, x, y) then
      return true -- success!
    end
  end
  return false -- failure!
end


function ImageGrid:draw(view)
  local start_x = math.max(1, 
              math.floor(view.x / self.quadw))
  local end_x = math.min(self.w, 
              start_x + math.ceil(view.w / self.quadw))
  
  local start_y = math.max(1, 
              math.floor(view.y / self.quadh))
  local end_y = math.min(self.h, 
              start_y + math.ceil(view.h / self.quadh))
  
  for z, layer in ipairs(self.layers) do
    for x = start_x, end_x do
      for y = start_y, end_y do
        self:tryDraw(layer[x][y], x, y)
      end
    end
  end

    --TODO use sprite batches
end

--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return ImageGrid