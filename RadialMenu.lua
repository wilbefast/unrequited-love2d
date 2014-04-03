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
local Vector = require("hump/vector-light")

local useful = require("unrequited/useful")
local scaling = require("unrequited/scaling")
local log = require("unrequited/log")

--[[------------------------------------------------------------
RADIALMENU CLASS
--]]------------------------------------------------------------

local RadialMenu = Class
{
	init = function(self, radius)
		self.__open = 0
		self.radius = (radius or 48)
		self.options = {}
	end
}

--[[------------------------------------------------------------
Add options
--]]--

function RadialMenu:addOption(option)
	-- add the new option
	table.insert(self.options, option)
	-- calculate angle between options
	local angle = math.pi*2/#self.options
	-- change positions of previous options
	for i, option in ipairs(self.options) do
		local option_angle = angle*i
		option.x = math.cos(option_angle)*self.radius
		option.y = math.sin(option_angle)*self.radius
	end
end

--[[------------------------------------------------------------
Open and close
--]]--

function RadialMenu:isOpened()
	return (self.__open == 1)
end

function RadialMenu:isClosed()
	return (self.__open == 0)
end

function RadialMenu:open(amount)
	self.__open = math.min(self.__open + amount, 1)
end

function RadialMenu:close(amount)
	self.__open = math.max(self.__open - amount, 0)
	self.x, self.y = 0, 0
end

--[[------------------------------------------------------------
Modify selection
--]]--

function RadialMenu:move(x, y, speed)
	-- don't move if closed
	if self:isClosed() then
		return
	end
	-- move the selection
	local move = ((((x ~= 0) or (y ~= 0)) and 7) or 1)*speed
	self.x = useful.lerp(self.x, x, move)
	self.y = useful.lerp(self.y, y, move)
end

function RadialMenu:getSelection(minimum_value)
	-- return nothing until open
	if (not self:isOpened()) then
		return
	end
	-- get the best candidate
	local best_option, best_value = nil, (minimum_value or 0.1)
	for i, option in ipairs(self.options) do
		local value = Vector.dot(self.x, self.y, option.x, option.y)
  	if value > best_value then
  		best_option, best_value = option, value
  	end
  end
  -- return an index
  return best_option
end

--[[------------------------------------------------------------
Draw
--]]--

function RadialMenu:draw(x, y)
	-- don't draw if closed
	if self:isClosed() then
		return
	end
	-- get the current selection
	local selection = self:getSelection()
	-- draw each options
	for i, option in ipairs(self.options) do
		local offset_x, offset_y = option.x*self.__open, option.y*self.__open
		-- draw selected ?
		if option == selection then
			scaling:circle("fill", x + offset_x, y + offset_y, 30)
		-- draw unselected ?
		else
			scaling:circle("line", x + offset_x, y + offset_y, 30)
		end
	end
end


--[[------------------------------------------------------------
Export
--]]--

return RadialMenu