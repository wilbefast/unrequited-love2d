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


local scaling = 
{ 
  DEFAULT_W = 1280, -- should be overwritten by setup
  DEFAULT_H = 720,  -- should be overwritten by setup
  SCALE_X = 1, 
  SCALE_Y = 1, 
  SCALE_MIN = 1, 
  SCALE_MAX = 1
}

function scaling:draw(img, quad, x, y, rot, sx, sy)
  x, y, rot, sx, sy = (x or 0), (y or 0), (rot or 0), (sx or 1), (sy or 1)
  love.graphics.draw(img, quad, x*self.SCALE_MIN + self.DEFAULT_W*(self.SCALE_X-self.SCALE_MIN)/2, 
                          y*self.SCALE_MIN + self.DEFAULT_H*(self.SCALE_Y-self.SCALE_MIN)/2, 
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

function scaling:normalisedRectangle(mode, x, y, w, h)
  love.graphics.rectangle(mode, self.DEFAULT_W*x*self.SCALE_MIN,
                                self.DEFAULT_H*y*self.SCALE_MIN,
                                self.DEFAULT_W*w*self.SCALE_MIN, 
                                self.DEFAULT_H*h*self.SCALE_MIN)
end

function scaling:circle(mode, x, y, r)
  love.graphics.circle(mode, x*self.SCALE_MIN,
                                y*self.SCALE_MIN,
                                r*self.SCALE_MIN)
end
function scaling:normalisedCircle(mode, x, y, r)
  love.graphics.circle(mode, x*self.DEFAULT_W*self.SCALE_MIN,
                                self.DEFAULT_H*y*self.SCALE_MIN,
                                self.DEFAULT_W*r*self.SCALE_MIN)
end

function scaling:line(x1, y1, x2, y2)
  love.graphics.line(x1*self.SCALE_MIN, y1*self.SCALE_MIN,
                     x2*self.SCALE_MIN, y2*self.SCALE_MIN)
end

function scaling:print(string, x, y, angle, maxwidth, align)
  love.graphics.push()
    love.graphics.scale(self.SCALE_MIN, self.SCALE_MIN)
    love.graphics.translate(x, y)
    if angle then
      love.graphics.rotate(angle)
    end
    if maxwidth and align then
      love.graphics.printf(string, 0, 0, maxwidth, align)
    else
      love.graphics.print(string, 0, 0)
    end
  love.graphics.pop()
end

function scaling:setup(desired_w, desired_h, fullscreen)
  self.DEFAULT_W, self.DEFAULT_H = desired_w, desired_h
  -- get and sort the available screen modes from best to worst
  local modes = love.window.getFullscreenModes()
  table.sort(modes, function(a, b) 
    return ((a.width*a.height > b.width*b.height) 
          and (a.width <= desired_w) and a.height <= desired_h) end)
       
  -- try each mode from best to worst
  for i, m in ipairs(modes) do
    
    if LOW_RESOLUTION then
      if #modes > 1 then
        m = modes[#modes - 1] -- lowest first
      else
        m = { width = 640, height = 480 } -- fallback
      end
    end
    
    -- try to set the resolution
    local success = love.window.setMode(m.width, m.height, { fullscreen = fullscreen })
    if success then
      self.SCALE_X, self.SCALE_Y = m.width/desired_w, m.height/desired_h
      self.SCALE_MIN, self.SCALE_MAX = math.min(self.SCALE_X, self.SCALE_Y), 
                                      math.max(self.SCALE_X, self.SCALE_Y)
      return true -- success!
    
    end
  end
  return false -- failure!
end

function scaling:getMousePosition()
  local x, y = love.mouse.getPosition()
  return x / scaling.SCALE_MIN, y / scaling.SCALE_MIN
end

return scaling;
