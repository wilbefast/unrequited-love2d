--[[
Copyright (c) 2012-2013 Matthias Richter

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]--

local sqrt, cos, sin = math.sqrt, math.cos, math.sin

local function str(x,y)
	return "("..tonumber(x)..","..tonumber(y)..")"
end

local function mul(s, x,y)
	return s*x, s*y
end

local function div(s, x,y)
	return x/s, y/s
end

local function add(x1,y1, x2,y2)
	return x1+x2, y1+y2
end

local function sub(x1,y1, x2,y2)
	return x1-x2, y1-y2
end

local function permul(x1,y1, x2,y2)
	return x1*x2, y1*y2
end

local function dot(x1,y1, x2,y2)
	return x1*x2 + y1*y2
end

local function det(x1,y1, x2,y2)
	return x1*y2 - y1*x2
end

local function eq(x1,y1, x2,y2)
	return x1 == x2 and y1 == y2
end

local function lt(x1,y1, x2,y2)
	return x1 < x2 or (x1 == x2 and y1 < y2)
end

local function le(x1,y1, x2,y2)
	return x1 <= x2 and y1 <= y2
end

local function len2(x,y)
	return x*x + y*y
end

local function len(x,y)
	return sqrt(x*x + y*y)
end

local function dist(x1,y1, x2,y2)
	return len(x1-x2, y1-y2)
end

local function obj_dist(a, b)
	return len(a.x-b.x, a.y-b.y)
end

local function dist2(x1,y1, x2,y2)
	return len2(x1-x2, y1-y2)
end

local function obj_dist2(a, b)
	return len2(a.x-b.x, a.y-b.y)
end

local function closer_than(x1, y1, x2, y2, dist)
	return dist*dist > len2(x1-x2, y1-y2)
end

local function obj_closer_than(a, b, dist)
	return dist*dist > len2(a.x-b.x, a.y-b.y)
end

local function further_than(x1, y1, x2, y2, dist)
	return dist*dist < len2(x1-x2, y1-y2)
end

local function obj_further_than(a, b, dist)
	return dist*dist < len2(a.x-b.x, a.y-b.y)
end

local function normalise(x,y)
	local l = len(x,y)
	if l > 0 then
		x, y = x/l, y/l
	end
	return x,y,l
end

local function rotate(phi, x,y)
	local c, s = cos(phi), sin(phi)
	return c*x - s*y, s*x + c*y
end

local function perpendicular(x,y)
	return -y, x
end

local function project(x,y, u,v)
	local s = (x*u + y*v) / (u*u + v*v)
	return s*u, s*v
end

local function mirror(x,y, u,v)
	local s = 2 * (x*u + y*v) / (u*u + v*v)
	return s*u - x, s*v - y
end


-- the module
return {
	str = str,

	-- arithmetic
	mul    = mul,
	div    = div,
	add    = add,
	sub    = sub,
	permul = permul,
	dot    = dot,
	det    = det,
	cross  = det,

	-- relation
	eq = eq,
	lt = lt,
	le = le,

	-- misc operations
	len2          = len2,
	len           = len,
	dist          = dist,
	dist2         = dist2,
	normalise     = normalise,
	rotate        = rotate,
	perpendicular = perpendicular,
	project       = project,
	mirror        = mirror,
	closer_than   = closer_than,
	further_than 	= further_than,

	-- operations on tables
	obj_dist      		= obj_dist,
	obj_dist2		 			= obj_dist2,
	obj_closer_than 	= obj_closer_than,
	obj_further_than 	= obj_further_than
}
