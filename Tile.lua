--[[
(C) Copyright 2013 
William Dyce, Maxime Ailloud, Alex Averbrugghe, Julien Deville

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
TILE CLASS
--]]------------------------------------------------------------

--[[------------------------------------------------------------
Initialisation
--]]

local Tile = Class
{
}

-- types
Tile.TYPE = {}

Tile.TYPE.EMPTY = 1
Tile.TYPE[1] = "EMPTY"

Tile.TYPE.WALL = 2
Tile.TYPE[2] = "WALL"

Tile.TYPE.ONESIDED = 3
Tile.TYPE[3] = "ONESIDED"

Tile.init = function(self, type)
  self.type = (type or Tile.TYPE.EMPTY)
end

--[[------------------------------------------------------------
Accessors
--]]

function Tile:isWall()
  return (self.type == Tile.TYPE.WALL) --FIXME
end

--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return Tile