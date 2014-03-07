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
  init = function(self, img, w, h, n_frames, offx, offy, flip_x, flip_y)
  
    -- remember frame number to prevent array out-of-bounds
    self.n_frames = (n_frames or 1)
    
    -- flipping
    self.flip_x, self.flip_y = (flip_x or false), (flip_y or false)
  
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
  
function Animation:draw(x, y, subimage, flip_x, flip_y, ox, oy, angle)
  if subimage then
    subimage = math.min(self.n_frames, math.floor(subimage))
  else
    subimage = 1
  end  
  
  flip_x = (flip_x or self.flip_x)
  flip_y = (flip_y or self.flip_y)
  love.graphics.draw(self.img, self.quads[subimage], x, y, angle or self.angle or 0,
      useful.tri(flip_x, -1, 1), 
      useful.tri(flip_y, -1, 1),
      ox, oy)
end


--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return Animation