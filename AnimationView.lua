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
ANIMATIONVIEW CLASS
--]]------------------------------------------------------------

--[[------------------------------------------------------------
Initialisation
--]]

local AnimationView = Class
{
  init = function(self, anim, speed, frame, offx, offy, sizex, sizey)
    self.anim = anim
    self.speed = (speed or 0.0)
    
    self.frame = useful.clamp(frame or math.random(self.anim.n_frames), 
                              1, self.anim.n_frames)
    self.offx = (offx or 0)
    self.offy = (offy or 0)
    self.sizex = (sizex or 1)
    self.sizey = (sizey or 1)
    self.flipx = 1
    self.flipy = 1
  end,
}
  
  
--[[------------------------------------------------------------
Game loop
--]]
    
function AnimationView:draw(object, x, y, angle, sizex, sizey)
  x, y = (x or object.x), (y or object.y)
  sizex, sizey = (sizex or self.sizex)*self.flipx, (sizey or self.sizex)*self.flipy
  angle = (angle or self.angle)
  self.anim:draw(x, y, self.frame, sizex, sizey, self.offx, self.offy, angle)
end

function AnimationView:update(dt)
  self.frame = self.frame + self.speed*dt
  if self.frame >= self.anim.n_frames + 1 then
    self.frame = self.frame - self.anim.n_frames
    return true -- animation end
  end
  if self.frame < 1 then
    self.frame = self.frame + self.anim.n_frames
    return true -- animation end
  end
  return false -- animation continues
end

--[[------------------------------------------------------------
Mutators
--]]--

function AnimationView:seekRandom()
  self.frame = math.random(self.anim.n_frames)
end

function AnimationView:seekPercent(p)
  if p > 1 then p = 1 elseif p < 0 then p = 0 end
  self.frame = ((self.anim.n_frames-1) * p) + 1
end

function AnimationView:setAnimation(anim)
  if anim and (self.anim ~= anim) then
    self.anim = anim
    self.frame = 1
  end
end

--[[------------------------------------------------------------
Accessors
--]]--

function AnimationView:getAnimationProgress()
  return (self.frame-1) / self.anim.n_frames
end

--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return AnimationView