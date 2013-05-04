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


local scaling = 
{ 
  DEFAULT_W = 1280,
  DEFAULT_H = 720,
  SCALE_X = 1, 
  SCALE_Y = 1, 
  SCALE_MIN = 1, 
  SCALE_MAX = 1
}

function scaling:draw(img, x, y, rot, sx, sy)
  x, y, rot, sx, sy = (x or 0), (y or 0), (rot or 0), (sx or 1), (sy or 1)
  love.graphics.draw(img, x*self.SCALE_MIN + self.DEFAULT_W*(self.SCALE_X-self.SCALE_MIN)/2, 
                          y*self.SCALE_MIN + self.DEFAULT_H*(self.SCALE_Y-self.SCALE_MIN)/2, 
                          rot, 
                          sx*self.SCALE_MIN, 
                          sy*self.SCALE_MIN)
end

function scaling:drawq(img, quad, x, y, rot, sx, sy)
  x, y, rot, sx, sy = (x or 0), (y or 0), (rot or 0), (sx or 1), (sy or 1)
  love.graphics.drawq(img, quad, x*self.SCALE_MIN,
                                  y*self.SCALE_MIN,
                                  rot, 
                                  sx*self.SCALE_MIN, 
                                  sy*self.SCALE_MIN)
end

function scaling:rectangle(mode, x, y, w, h)
  love.graphics.rectangle(mode, x*self.SCALE_MIN,
                                y*self.SCALE_MIN,
                                w*self.SCALE_MIN, 
                                h*self.SCALE_MIN)
end

function scaling:print(string, x, y)
  love.graphics.print(string, 
      x*self.SCALE_MIN, y*self.SCALE_MIN)    
end

function scaling:setup(desired_w, desired_h, fullscreen)
  self.DEFAULT_W, self.DEFAULT_H = desired_w, desired_h
  -- get and sort the available screen modes from best to worst
  local modes = love.graphics.getModes()
  table.sort(modes, function(a, b) 
    return ((a.width*a.height > b.width*b.height) 
          and (a.width <= desired_w) and a.height <= desired_h) end)
       
  -- try each mode from best to worst
  for i, m in ipairs(modes) do
    
    if DEBUG then
      m = modes[#modes - 1]
    end
    
    -- try to set the resolution
    local success = love.graphics.setMode(m.width, m.height, fullscreen)
    if success then
      self.SCALE_X, self.SCALE_Y = m.width/desired_w, m.height/desired_h
      self.SCALE_MIN, self.SCALE_MAX = math.min(self.SCALE_X, self.SCALE_Y), 
                                      math.max(self.SCALE_X, self.SCALE_Y)
      return true -- success!
    
    end
  end
  return false -- failure!
end



return scaling;