--[[
"Unrequited", a Löve 2D extension library
(C) Copyright 2016 William Dyce

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
local useful = require("unrequited/useful")

--[[------------------------------------------------------------
NINEPATCH CLASS
--]]------------------------------------------------------------

--[[------------------------------------------------------------
Initialisation
--]]

local NinePatch = Class
{
  init = function(self, args)
  	self.ne = args.northEast.img
  	self.ne_offx = args.northEast.offx
  	self.ne_offy = args.northEast.offy
  	self.nw = args.northWest.img
  	self.nw_offx = args.northWest.offx
  	self.nw_offy = args.northWest.offy
  	self.se = args.southEast.img
  	self.se_offx = args.southEast.offx
  	self.se_offy = args.southEast.offy
  	self.sw = args.southWest.img
  	self.sw_offx = args.southWest.offx
  	self.sw_offy = args.southWest.offy
  	self.line = args.line.img
  	self.line_offx = args.line.offx
  	self.line_offy = args.line.offy
  	self.line_w = self.line:getWidth()
  	self.line_h = self.line:getHeight()
  	self.line_quad = love.graphics.newQuad(0, 0, self.line_w, self.line_h, self.line_w, self.line_h)
  end,
}


--[[------------------------------------------------------------
Game loop
--]]

function NinePatch:draw(x, y, w, h)
	-- horizontal
	local line_x = 0
	local line_w = self.line_w
	while line_x <= w - line_w do
		love.graphics.draw(self.line, x + line_x, y, 0, 1, 1, self.line_offx, self.line_offy)
		love.graphics.draw(self.line, x + line_x, y + h, 0, 1, 1, self.line_offx, self.line_offy)
		line_x = line_x + line_w
	end
	if self.line.quad then
		local qx, qy, qw, qh = self.line.quad:getViewport()
		self.line.quad:setViewport(qx, qy, w - line_x, qh)
		love.graphics.draw(self.line, x + line_x, y, 0, 1, 1, self.line_offx, self.line_offy)
		love.graphics.draw(self.line, x + line_x, y + h, 0, 1, 1, self.line_offx, self.line_offy)
		self.line.quad:setViewport(qx, qy, qw, qh)
	else
		self.line_quad:setViewport(0, 0, line_w - line_x, self.line_h)
		love.graphics.draw(self.line, self.line_quad, x + line_x, y, 0, 1, 1, self.line_offx, self.line_offy)
		love.graphics.draw(self.line, self.line_quad, x + line_x, y + h, 0, 1, 1, self.line_offx, self.line_offy)
	end

	-- vertical
	local line_y = 0
	while line_y <= h - line_w do
		love.graphics.draw(self.line, x, y + line_y, math.pi/2, 1, 1, self.line_offx, self.line_offy)
		love.graphics.draw(self.line, x + w, y + line_y, math.pi/2, 1, 1, self.line_offx, self.line_offy)
		line_y = line_y + line_w
	end
	if self.line.quad then
		local qx, qy, qw, qh = self.line.quad:getViewport()
		self.line.quad:setViewport(qx, qy, h - line_y, qh)
		love.graphics.draw(self.line, x, y + line_y, math.pi/2, 1, 1, self.line_offx, self.line_offy)
		love.graphics.draw(self.line, x + w, y + line_y, math.pi/2, 1, 1, self.line_offx, self.line_offy)
		self.line.quad:setViewport(qx, qy, qw, qh)
	else
		self.line_quad:setViewport(0, 0, w - line_y, self.line_h)
		love.graphics.draw(self.line, x, y + line_y, math.pi/2, 1, 1, self.line_offx, self.line_offy)
		love.graphics.draw(self.line, x + w, y + line_y, math.pi/2, 1, 1, self.line_offx, self.line_offy)
	end

	-- corners
	love.graphics.draw(self.nw, x, y, 0, 1, 1, self.nw_offx, self.nw_offy)
	love.graphics.draw(self.ne, x + w, y, 0, 1, 1, self.ne_offx, self.ne_offy)
	love.graphics.draw(self.sw, x, y + h, 0, 1, 1, self.sw_offx, self.sw_offy)
	love.graphics.draw(self.se, x + w, y + h, 0, 1, 1, self.se_offx, self.se_offy)
end

--[[------------------------------------------------------------
EXPORT
--]]------------------------------------------------------------

return NinePatch
