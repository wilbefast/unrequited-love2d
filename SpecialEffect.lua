--[[
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

local Class      = require("hump/class")
local GameObject = require("GameObject")
local Animation = require("Animation")
local AnimationView = require("AnimationView")

--[[------------------------------------------------------------
SPECIAL EFFECT CLASS
--]]------------------------------------------------------------

--[[------------------------------------------------------------
Constructor
--]]

local SpecialEffect = Class
{
  type  =  GameObject.TYPE["SPECIALEFFECT"],
  
  init = function(self, x, y, anim, speed, follow)
    self.offx, self.offy = -anim.frame_w/2, -anim.frame_h/2
      GameObject.init(self, 
          x + self.offx, y + self.offy, 0, 0)
    self.view = AnimationView(anim, speed, 1)
    self.follow = follow
  end,
}
SpecialEffect:include(GameObject)

--[[------------------------------------------------------------
Game loop
--]]

function SpecialEffect:update(dt, level, view)
  if self.follow then
    self.x, self.y = 
    self.follow:centreX() + self.offx, 
    self.follow:centreY() + self.offy
    
  end
  if self.view:update(dt, level, view) then
    -- destroy at the end of the animation
    self.purge = true
  end
end

function SpecialEffect:draw(view)
  self.view:draw(self)
end


--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return SpecialEffect