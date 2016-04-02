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
  init = function(self, args)
  
  
    -- offset of the animation strip within the image
    local strip_offx, strip_offy = (args.strip_offx or 0), (args.strip_offy or 0)

    -- remember frame number to prevent array out-of-bounds
    self.n_frames = (args.n_frames or 1)

    -- reference the image differently depending on whether or not we're reading from a sprite batch
    local frame_w, frame_h
    if args.fudge then
      -- grab the sprite packer if we haven't already
      if not fudge then
        fudge = require("fudge")
      end
      self.fudge = args.fudge
      self.img = args.fudge.img
      local quad_x, quad_y, quad_w, quad_h = self.fudge.quad:getViewport()
      strip_offx, strip_offy = strip_offx + quad_x, strip_offy + quad_y
      frame_w, frame_h = (args.frame_w or (quad_w / self.n_frames)), 
        (args.frame_h or quad_h)
    else
      self.img = args.img
      frame_w, frame_h = (args.frame_w or (args.img:getWidth() / self.n_frames)), 
        (args.frame_w or args.img:getHeight())
    end
    
    -- mirroring
    self.scale_x, self.scale_y = (args.scale_x or 1), (args.scale_y or 1)

    self.quads= {}
    for i = 1, self.n_frames do
      self.quads[i] = love.graphics.newQuad(strip_offx + (i-1)*frame_w, strip_offy, 
          frame_w, frame_h, self.img:getWidth(), self.img:getHeight())
    end
    
    -- frame size can be useful for lookup even if anim no longer needs it
    self.frame_w, self.frame_h = frame_w, frame_h

    -- not all animation have the centre in the same place
    self.frame_offx, self.frame_offy = args.frame_offx, args.frame_offy
  end,
}
  
  
--[[------------------------------------------------------------
Game loop
--]]
  
function Animation:draw(x, y, subimage, scale_x, scale_y, frame_offx, frame_offy, angle)
  if subimage then
    subimage = math.min(self.n_frames, math.floor(subimage))
  else
    subimage = 1
  end  
  
  scale_x = (scale_x or self.scale_x)
  scale_y = (scale_y or self.scale_y)
  frame_offx = (frame_offx or self.frame_offx)
  frame_offy = (frame_offy or self.frame_offy)

  if self.fudge then
    fudge.current.batch:add(self.quads[subimage], x, y, angle or self.angle or 0,
        scale_x, scale_y, frame_offx, frame_offy)
  else
    love.graphics.draw(self.img, self.quads[subimage], x, y, angle or self.angle or 0,
        scale_x, scale_y, frame_offx, frame_offy)
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