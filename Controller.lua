--[[
"Unrequited", a Löve 2D extension library
(C) Copyleft 2014 William Dyce

All lefts reserved. This program and the accompanying materials
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

function Controller:addAxis(name, fpositive, fnegative)
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
    name_pressed = name .. "_pressed",
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
    if axis.__fnegative then
      axis.position = ((axis.__fpositive() and 1) or 0) - ((axis.__fnegative() and 1) or 0)
    else
      axis.position = axis.__fpositive()
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
    self[button.name_pressed] = button.pressed
  end
end

--[[------------------------------------------------------------
Input events
--]]--

function Controller.keypressed(key, uni)
  -- override me!
end

function Controller.keyreleased(key, uni)
  -- override me!
end

function Controller.mousepressed(x, y, button)
  -- override me!
end

function Controller.mousereleased(x, y, button)
  -- override me!
end

function Controller.joystickpressed(joystick, button)
  -- override me!
end

function Controller.joystickreleased(joystick, button)
  -- override me!
end

function Controller.gamepadpressed(joystick, button)
  -- override me!
end

function Controller.gamepadreleased(joystick, button)
  -- override me!
end

--[[------------------------------------------------------------
Generic joystick controller
--]]--

local __Joystick = Class
{
  init = function(self, joystick)
    Controller.init(self)

    -- add each axis
    for i = 1, joystick:getAxisCount() do
      self:addAxis("axis" .. i, function() return joystick:getAxis(i) end)
    end

    -- add each hat
    for i = 1, joystick:getHatCount() do
      self:addAxis("hat" .. tostring(i), function() return joystick:getHat(i) end)
    end

    -- add each button
    for i = 1, joystick:getButtonCount() do
      self:addButton("button" .. tostring(i), function() return joystick:isDown(i) end)
    end
  end,
}
__Joystick:include(Controller)
Controller.Joystick = __Joystick


--[[------------------------------------------------------------
Gamepad controller
--]]--

local __Gamepad = Class
{
  axis_names =
  {
    "leftx", "lefty", "leftx", "lefty", "triggerleft", "triggerleft"
  },

  button_names =
  {
    "a", "b", "x", "y", "back", "guide", "start", "leftstick", "leftstick", 
    "leftshoulder", "leftshoulder", "dpup", "dpdown", "dpleft", "dpleft"
  },

  gamepad = true,

  init = function(self, joystick)
    Controller.init(self)

    -- save this mapping
    Controller.Gamepad[joystick] = self

    -- add each axis
    for _, name in ipairs(self.axis_names) do
      self:addAxis(name, function() return joystick:getGamepadAxis(name) end)
    end

    -- add each button
    for _, name in ipairs(self.button_names) do
      self:addButton(name, function() return joystick:isGamepadDown(name) end)
    end
  end,
}
__Gamepad:include(Controller)
Controller.Gamepad = __Gamepad



--[[------------------------------------------------------------
Default keyboard controls
--]]--

local KEYBOARD = Controller()
KEYBOARD:addAxis("leftx", 
  function() return love.keyboard.isDown("right", "d") end,
  function() return love.keyboard.isDown("left", "q", "a") end)
KEYBOARD:addAxis("lefty", 
  function() return love.keyboard.isDown("down", "s") end,
  function() return love.keyboard.isDown("up", "z", "w") end)
KEYBOARD.keyboard = true
Controller.KEYBOARD = KEYBOARD

local KEYBOARD_LEFT = Controller()
KEYBOARD_LEFT:addAxis("leftx", 
  function() return love.keyboard.isDown("d") end,
  function() return love.keyboard.isDown("q", "a") end)
KEYBOARD_LEFT:addAxis("lefty", 
  function() return love.keyboard.isDown("s") end,
  function() return love.keyboard.isDown("z", "w") end)
KEYBOARD_LEFT.keyboard = true
Controller.KEYBOARD_LEFT = KEYBOARD_LEFT

local KEYBOARD_RIGHT = Controller()
KEYBOARD_RIGHT:addAxis("leftx", 
  function() return love.keyboard.isDown("right") end,
  function() return love.keyboard.isDown("left") end)
KEYBOARD_RIGHT:addAxis("lefty", 
  function() return love.keyboard.isDown("down") end,
  function() return love.keyboard.isDown("up") end)
KEYBOARD_RIGHT.keyboard = true
Controller.KEYBOARD_RIGHT = KEYBOARD_RIGHT

--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return Controller