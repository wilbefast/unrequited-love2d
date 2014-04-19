--[[
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
ParticleSystem GAMEOBJECT
--]]------------------------------------------------------------

--[[------------------------------------------------------------
Includes
--]]--

local Class = require("hump/class")
local Vector = require("hump/vector-light")

local GameObject = require("unrequited/GameObject")
local log = require("unrequited/log")
local scaling = require("unrequited/scaling")
local useful = require("unrequited/useful")

--[[------------------------------------------------------------
Initialisation
--]]--

local ParticleSystem = Class
{
  type = GameObject.newType("ParticleSystem"),

  init = function(self, x, y, image, max)
    self.particles = love.graphics.newParticleSystem(image, max)
    self.particles:setSpread(2*math.pi)
    GameObject.init(self, x, y)
  end,
}
ParticleSystem:include(GameObject)

--[[------------------------------------------------------------
Game loop
--]]--

function ParticleSystem:update(dt)
  self.particles:update(dt)
  GameObject.update(self, dt)
  self.particles:moveTo(self.x, self.y)
end

function ParticleSystem:draw()
  love.graphics.draw(self.particles, 0, 0)
end


--[[------------------------------------------------------------
Export
--]]--

return ParticleSystem