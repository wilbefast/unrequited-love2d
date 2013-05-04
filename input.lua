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

local input = 
{
  x = 0,
  y = 0
}

function input:update(dt)
  self.x, self.y = 0, 0
  if love.keyboard.isDown("left", "q", "a") then
    self.x = self.x - 1 
  end
  if love.keyboard.isDown("right", "d") then
    self.x = self.x + 1 
  end
  if love.keyboard.isDown("up", "z", "w") then
    self.y = self.y - 1 
  end
  if love.keyboard.isDown("down", "s") then 
    self.y = self.y + 1 
  end
end


return input