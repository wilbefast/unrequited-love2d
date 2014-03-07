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

--[[---------------------------------------------------------------------------
DEBUG CONSOLE
--]]---------------------------------------------------------------------------

local log = { "", "", "", "", "", "", "", "", "", "" }

log.font = love.graphics.newFont(14)

function log:write(message)

	if type(message) ~= "string" then
		message = tostring(message)
	end

	-- shift right
	for i = #self, 2, -1 do
		self[i] = self[i-1]
	end
	-- add to beginning
	self[1] = message
end

function log:draw()
	love.graphics.setColor(255, 255, 255)
	love.graphics.setLineWidth(1)
		love.graphics.rectangle("line", 16, 16, 256, 32*#self + 16)
		love.graphics.setFont(self.font)
		for i = 1, #self do
			love.graphics.printf(self[i], 32, 32*i, 256)
		end
end

return log