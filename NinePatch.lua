--[[
"Unrequited", a Löve 2D extension library
(C) Copyright 2016 William Dyce

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
local useful = require("unrequited/useful")

--[[------------------------------------------------------------
NINEPATCH CLASS
--]]------------------------------------------------------------

--[[------------------------------------------------------------
Initialisation
--]]

local NinePatch = Class
{
  init = function(self, args)
  	self.ne = args.northEast.img
  	self.ne_offx = args.northEast.offx 
  	self.ne_offy = args.northEast.offy
  	self.nw = args.northWest.img
  	self.nw_offx = args.northWest.offx 
  	self.nw_offy = args.northWest.offy
  	self.se = args.southEast.img
  	self.se_offx = args.southEast.offx 
  	self.se_offy = args.southEast.offy
  	self.sw = args.southWest.img
  	self.sw_offx = args.southWest.offx 
  	self.sw_offy = args.southWest.offy
  end,
}
  
  
--[[------------------------------------------------------------
Game loop
--]]
  
function NinePatch:draw(x, y, w, h)
	love.graphics.draw(self.nw, x, y, 0, 1, 1, self.nw_offx, self.nw_offy)
	love.graphics.draw(self.ne, x + w, y, 0, 1, 1, self.ne_offx, self.ne_offy)
	love.graphics.draw(self.sw, x, y + h, 0, 1, 1, self.sw_offx, self.sw_offy)
	love.graphics.draw(self.se, x + w, y + h, 0, 1, 1, self.se_offx, self.se_offy)
end

--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return NinePatch