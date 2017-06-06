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
		self.default_col = args.default_col or -1
		self.default_row = args.default_row or -1
		self.col = self.default_col
		self.row = self.default_row
	end
}
GridMenu.menuType = GridMenu

--[[------------------------------------------------------------
Add options
--]]--

function GridMenu:addOption(option)
	-- add the new option
	table.insert(self.options, option)
	local count = #self.options
	option.menu = self

	local rows = math.max(1, math.floor(math.sqrt(count)))
	local cols = math.ceil(count / rows)
	self.n_cols = cols
	self.n_rows = rows
	self.col, self.row = self.default_col, self.default_row
	self.x, self.y = self.col/self.n_cols, self.row/self.n_rows
	self.__selection = nil
	for i, o in ipairs(self.options) do
		o.col = ((i - 1) % cols) + 1
		o.row = math.floor((i -1) / cols) + 1
		o.index = i
		o.x = (o.col - cols/2)/cols
		o.y = (o.row - rows/2)/rows
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
	self.col, self.row = self.default_col, self.default_row
	self.x, self.y = self.col/self.n_cols, self.row/self.n_rows
	self.__selection = nil
end

--[[------------------------------------------------------------
Modify selection
--]]--

function GridMenu:move(dx, dy, dt)
	-- don't move if closed
	if self:isClosed() then
		return
	end
	-- move
	dt = dt or 0.1
	return self:setPosition(self.x + dx*dt, self.y + dy*dt)
end

function GridMenu:setPosition(x, y)
	-- don't move if closed
	if self:isClosed() then
		return
	end
	-- out of bounds
	local out_of_bounds_x = 0
	if x < 0 then
		out_of_bounds_x = -1
		x = 0
	elseif x > 1 then
		out_of_bounds_x = 1
		x = 1
	end
	local out_of_bounds_y = 0
	if y < 0 then
		out_of_bounds_y = -1
		y = 0
	elseif y > 1 then
		out_of_bounds_y = 1
		y = 1
	end

	-- move
	self.x, self.y = x, y
	self.col = useful.round(self.x * (self.n_cols - 1)) + 1
	self.row = useful.round(self.y * (self.n_rows - 1)) + 1
	-- reset cached selected
	local index = (self.row - 1)*self.n_cols + self.col
	if index > 0 and index <= #self.options then
		self.__selection = self.options[index]
	else
		self.__selection = nil
	end

	-- return out of bounds result
	return out_of_bounds_x, out_of_bounds_y
end


function GridMenu:getSelection()
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
		if option ~= selection then
			local offset_x, offset_y = option.col*self.__open, option.row*self.__open
			-- draw the option
			option:draw(x + offset_x, y + offset_y, false, self.__open, context, x, y)
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
