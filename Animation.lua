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

local fudge = nil

--[[------------------------------------------------------------
ANIMATION CLASS
--]]------------------------------------------------------------

--[[------------------------------------------------------------
Initialisation
--]]

local Animation = Class
{
  init = function(self, img, w, h, n_frames, offx, offy, scalex, scaley, ox, oy)
  
    if type(img) == "table" then
      if not fudge then
        fudge = require("fudge/src/fudge")
      end
      self.fudge = img
      img = self.fudge.img
    end

    -- remember frame number to prevent array out-of-bounds
    self.n_frames = (n_frames or 1)
    
    -- mirroring
    self.scalex, self.scaley = (scalex or 1), (scaley or 1)
  
    -- store reference to image
    self.img = img

    -- create quads
    offx, offy = (offx or 0), (offy or 0)
    if self.fudge then
      local qx, qy = self.fudge.quad:getViewport()
      offx, offy = offx + qx, offy + qy
    end
    self.quads= {}
    for i = 1, n_frames do
      self.quads[i] = love.graphics.newQuad(offx + (i-1)*w, offy, 
          w, h, img:getWidth(), img:getHeight())
    end
    
    -- frame size can be useful for lookup even if anim no longer needs it
    self.frame_w, self.frame_h = w, h

    -- not all animation have the centre in the same place
    self.ox, self.oy = ox, oy
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
  ox = (ox or self.ox)
  oy = (oy or self.oy)

  if self.fudge then
    fudge.current.batch:add(self.quads[subimage], x, y, angle or self.angle or 0,
        scalex, scaley, ox, oy)
  else
    love.graphics.draw(self.img, self.quads[subimage], x, y, angle or self.angle or 0,
        scalex, scaley, ox, oy)
  end
end


--[[------------------------------------------------------------
Query
--]]
  
function Animation:frameAtPercent(p)
  if p > 1 then p = 1 elseif p < 0 then p = 0 end
  return (((self.n_frames-1) * p) + 1)
end


--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return Animation