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
local Vector = require("unrequited/Vector")

local useful = require("unrequited/useful")
local scaling = require("unrequited/scaling")
local log = require("unrequited/log")

--[[------------------------------------------------------------
RADIALMENU CLASS
--]]------------------------------------------------------------

local RadialMenu = Class
{
	init = function(self, radius, anchor_x, anchor_y)
		self.__open = 0
		self.radius = (radius or 48)
		self.options = {}
		self.anchor_x, self.anchor_y = anchor_x, anchor_y
		self.x, self.y = 0, 0
	end
}
RadialMenu.menuType = RadialMenu

--[[------------------------------------------------------------
Add options
--]]--

function RadialMenu:addOption(option, angle)
	-- add the new option
	table.insert(self.options, option)
	if not angle then
		-- calculate angle between options
		angle = math.pi*2/#self.options
		-- change positions of previous options
		for i, o in ipairs(self.options) do
			o.angle = angle*(i - 0.75)
			o.x = math.cos(o.angle)*self.radius
			o.y = math.sin(o.angle)*self.radius
		end
	else
		option.x = math.cos(angle)*self.radius
		option.y = math.sin(angle)*self.radius
		option.angle = angle
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
	self.__selection = nil
end

--[[------------------------------------------------------------
Modify selection
--]]--

function RadialMenu:move(x, y, speed)
	-- don't move if closed
	if self:isClosed() then
		return
	end
	-- reset cached selected
	self.__selection = nil
	-- move the selection
	local move = ((((x ~= 0) or (y ~= 0)) and 7) or 1)*speed
	self.x = useful.lerp(self.x, x, move)
	self.y = useful.lerp(self.y, y, move)
end

function RadialMenu:setPosition(x, y)
	-- don't move if closed
	if self:isClosed() then
		return
	end
	-- reset cached selected
	self.__selection = nil
	-- move selection to new postion
	self.x, self.y = x, y
end

function RadialMenu:getSelection(minimum_value, x, y)
	x, y = x or self.x, y or self.y
	-- only one option? Then it's always selected
	if #self.options == 1 then
		return self.options[1]
	end
	-- do we have a cached result?
	if self.__selection then
		return self.__selection
	end
	-- get the best candidate
	local best_option, best_value = nil, (minimum_value or 0.5)
	for i, option in ipairs(self.options) do
		local value = Vector.dot(x, y, option.x/self.radius, option.y/self.radius)
  	if value > best_value then
  		best_option, best_value = option, value
  	end
  end
  -- return an best
  self.__selection = best_option
  return self.__selection
end

--[[------------------------------------------------------------
Draw
--]]--

function RadialMenu:draw(x, y, context)
	x, y = (x or self.anchor_x), (y or self.anchor_y)
	-- don't draw if closed
	if self:isClosed() then
		return
	end
	-- get the current selection
	local selection = self:getSelection()
	-- draw each options
	for i, option in ipairs(self.options) do
		if option ~= selection then
			local offset_x, offset_y = option.x*self.__open, option.y*self.__open
			-- draw the option
			option:draw(x + offset_x, y + offset_y, false, self.__open, context, x, y)
		end
	end
	if selection then
		local offset_x, offset_y = selection.x*self.__open, selection.y*self.__open
		-- draw the selection last so that it is always on top
		selection:draw(x + offset_x, y + offset_y, true, self.__open, context, x, y)
	end
end

--[[------------------------------------------------------------
Select with mouse
--]]--

function RadialMenu:pick(x, y)
	local dx, dy = x - self.anchor_x, y - self.anchor_y
	local len2 = Vector.len2(dx, dy)
	if len2 <= self.radius*self.radius*4 then
		local len = math.sqrt(len2)
		return self:getSelection(0.85, dx/len, dy/len)
	else
		return nil
	end
end



--[[------------------------------------------------------------
Export
--]]--

return RadialMenu
