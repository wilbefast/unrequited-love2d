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
ANIMATION CLASS
--]]------------------------------------------------------------

--[[------------------------------------------------------------
Initialisation
--]]

local Animation = Class
{
  init = function(self, img, w, h, n_frames, offx, offy, scalex, scaley)
  
    -- remember frame number to prevent array out-of-bounds
    self.n_frames = (n_frames or 1)
    
    -- mirroring
    self.scalex, self.scaley = (scalex or 1), (scaley or 1)
  
    -- store reference to image
    self.img = img

    -- create quads
    offx, offy = (offx or 0), (offy or 0)
    self.quads= {}
    for i = 1, n_frames do
      self.quads[i] = love.graphics.newQuad(offx + (i-1)*w, offy, 
          w, h, img:getWidth(), img:getHeight())
    end
    
    -- frame size can be useful for lookup even if anim no longer needs it
    self.frame_w, self.frame_h = w, h
  end,
}
  
  
--[[------------------------------------------------------------
Game loop
--]]
  
function Animation:draw(x, y, subimage, scalex, scaley, ox, oy, angle)
  if subimage then
    subimage = math.min(self.n_frames, math.floor(subimage))
  else
    subimage = 1
  end  
  
  scalex = (scalex or self.scalex)
  scaley = (scaley or self.scaley)
  love.graphics.draw(self.img, self.quads[subimage], x, y, angle or self.angle or 0,
      scalex, scaley, ox, oy)
end


--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return Animation