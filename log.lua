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

local useful = require("unrequited/useful")

--[[---------------------------------------------------------------------------
DEBUG CONSOLE
--]]---------------------------------------------------------------------------

local log = { "", "", "", "", "", "", "", "", "", "" }

log.cycle = { " |", " /", " --", " \\", " |", " /", " --", " \\"}
log.cycle_i = 1

log.font = love.graphics.newFont(14)

function log:write(...)
	-- build the new log
	local args = useful.packArgs(...)
	local message = nil
	for _, a in ipairs(args) do
		-- convert to string
		if type(a) ~= "string" then
			a = tostring(a)
		end
		message = (message and (message .. ", " .. a)) or a
	end

	if message then
		-- shift previous logs towards the end
		for i = #self, 2, -1 do
			self[i] = self[i-1]
		end
		-- add the new log to the beginning

		self[1] = message .. self.cycle[self.cycle_i]
	else
		print(debug.traceback())
	end
end

function log:draw(x, y, w)
	x, y, w = x or 16, y or 16, w or 256
	local h = 16 + 32*#self
	-- draw background
	love.graphics.setColor(0, 0, 0, 128)
	love.graphics.rectangle("fill", x, y, w, h)
	-- draw outline
	love.graphics.setColor(255, 255, 255)
	love.graphics.setLineWidth(1)
	love.graphics.rectangle("line", x, y, w, h)
	-- draw text
	love.graphics.setFont(self.font)
	for i = 1, #self do
		love.graphics.printf(self[i], x + 16, y + 16 + 32*(i-1), w)
	end

	-- cycle
	self.cycle_i = self.cycle_i + 1
	if self.cycle_i > #self.cycle then 
		self.cycle_i = 1
	end
end

return log