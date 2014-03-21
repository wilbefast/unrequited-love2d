--[[
"Unrequited", a Löve 2D extension library
(C) Copyright 2014 William Dyce

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

--[[------------------------------------------------------------
CONTROLLER CLASS
--]]------------------------------------------------------------

local __INSTANCES = {}

local Controller = Class
{
  init = function(self)
    self.buttons = {}
    self.axes = {}
    table.insert(__INSTANCES, self)
  end,
}

function Controller.updateAll(dt)
  for _, controller in ipairs(__INSTANCES) do
    controller:update(dt)
  end
end

function Controller:addAxis(name, fnegative, fpositive)
  local axis = {
    name = name, 
    __fnegative = fnegative, 
    __fpositive = fpositive, 
    position = 0
  } 
  self.axes[name] = axis
  self[name] = 0
end

function Controller:addButton(name, fpressed)
  local button = { 
    name = name,
    __fpressed = fpressed, 
    __pressed_prev = false, 
    pressed = false, 
    trigger = 0
  }
  self.buttons[name] = button
  self[name] = false
end

function Controller:update(dt)
  for _, axis in pairs(self.axes) do    
    axis.position = 0
    if axis.__fpositive() then
      axis.position = axis.position + 1
    end
    if axis.__fnegative() then
      axis.position = axis.position - 1
    end
    
    -- shortcut access
    self[axis.name] = axis.position
  end

  for _, button in pairs(self.buttons) do    
    button.__pressed_prev = button.pressed
    button.pressed = button.__fpressed()
    if button.pressed == button.__pressed_prev then
      button.trigger = 0
    elseif button.pressed then
      button.trigger = 1
    else    
      button.trigger = -1
    end

    -- shortcut access
    self[button.name] = (button.trigger == 1)
  end
end

-- useful default keyboard controller
local KEYBOARD = Controller()
KEYBOARD:addAxis("x", 
  function() return love.keyboard.isDown("left", "q", "a") end,
  function() return love.keyboard.isDown("right", "d") end)
KEYBOARD:addAxis("y", 
  function() return love.keyboard.isDown("up", "z", "w") end,
  function() return love.keyboard.isDown("down", "s") end)
Controller.KEYBOARD = KEYBOARD

--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return Controller