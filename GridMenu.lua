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
GRIDMENU CLASS
--]]------------------------------------------------------------

local GridMenu = Class
{
	init = function(self, args)
		self.__open = 0
		self.options = {}
		self.x, self.y = 0, 0
		self.n_cols = 0
		self.n_rows = 0
		self.n_options = 0
	end
}

--[[------------------------------------------------------------
Add options
--]]--

function GridMenu:addOption(option)
	-- add the new option
	table.insert(self.options, option)
	option.menu = self
	self:forceNumberOfOptions(#self.options)
end

function GridMenu:forceNumberOfOptions(count)
	self:forceDimensions(math.ceil(count / self.n_rows), math.floor(math.sqrt(count)))
end

function GridMenu:forceDimensions(cols, rows)
	self.n_cols = cols
	self.n_rows = rows
	self.n_options = cols*rows
	for i, o in ipairs(self.options) do
		o.row = math.floor((i -1) / self.n_cols) + 1
		o.col = ((i - 1) % self.n_cols) + 1
		o.index = i
	end
end

--[[------------------------------------------------------------
Open and close
--]]--

function GridMenu:isOpened()
	return (self.__open == 1)
end

function GridMenu:isClosed()
	return (self.__open == 0)
end

function GridMenu:open(amount)
	self.__open = math.min(self.__open + amount, 1)
end

function GridMenu:close(amount)
	self.__open = math.max(self.__open - amount, 0)
	self.x, self.y = 0, 0
	self.__selection = nil
end

--[[------------------------------------------------------------
Modify selection
--]]--

function GridMenu:move(x, y, speed)
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

function GridMenu:setPosition(x, y)
	-- don't move if closed
	if self:isClosed() then
		return
	end
	-- reset cached selected
	self.__selection = nil
	-- move selection to new postion
	self.x, self.y = x, y
end


function GridMenu:getSelection(minimum_value, x, y)
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
    -- TODO
  end

	if true then
		return nil
	end

  if y > 0 then
    return self.options[#self.options]
  end


  -- return an best
  self.__selection = best_option
  return self.__selection
end

--[[------------------------------------------------------------
Draw
--]]--

function GridMenu:draw(x, y, context)
	x, y = (x or self.anchor_x), (y or self.anchor_y)
	-- don't draw if closed
	if self:isClosed() then
		return
	end
	-- get the current selection
	local selection = self:getSelection()
	-- draw each options
	for i, option in ipairs(self.options) do
		if i <= self.n_options then
			if option ~= selection then
				local offset_x, offset_y = option.col*self.__open, option.row*self.__open
				-- draw the option
				option:draw(x + offset_x, y + offset_y, false, self.__open, context, x, y)
			end
		end
	end
	if selection then
		local offset_x, offset_y = selection.col*self.__open, selection.row*self.__open
		-- draw the selection last so that it is always on top
		selection:draw(x + offset_x, y + offset_y, true, self.__open, context, x, y)
	end
end

--[[------------------------------------------------------------
Select with mouse
--]]--

function GridMenu:pick(x, y)
  -- TODO
  return nil
end



--[[------------------------------------------------------------
Export
--]]--

return GridMenu
