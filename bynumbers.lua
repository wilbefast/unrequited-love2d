--[[
"By Number", a sprite palette utility
(C) Copyright 2015 William Dyce

All rights reserved. This program and the accompanying materials
are made available under the terms of the GNU Lesser General Public License
(LGPL) version 2.1 which accompanies this distribution, and is available at
http://www.gnu.org/licenses/lgpl-2.1.html

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
Lesser General Public License for more details.
--]]

local _split = function(str, sep)
  local sep, fields = sep or ":", {}
  local pattern = string.format("([^%s]+)", sep)
  str:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

local _colourToString = function(r, g, b, a)
	return string.char(r, g, b, a)
end

local _stringToColour = function(str)
	return string.byte(str, 1, 4)
end

local _palettes = {}

local _addPalette = function(path)

	local parts = _split(path, "/")
	local filename = parts[#parts]
	local name = _split(filename, ".")[1]

	local img = love.graphics.newImage(path):getData()
	local colours = {}
	img:mapPixel(function(x, y, r, g, b, a)
		local hash = _colourToString(r, g, b, a)
		table.insert(colours, hash)
		colours[hash] = #colours
		return r, g, b, a
	end)


	_palettes[name] = colours
end


local _paint = function(args)
	local images = args.images or args
	local fail_r = args.fail_r
	local fail_g = args.fail_g
	local fail_b = args.fail_b
	local fail_a = args.fail_a
	local log = args.log
	local exists = {}
	for palette_name, palette in pairs(_palettes) do
		for _, image in ipairs(images) do
			exists[image.name] = true
			if string.find(image.name, palette_name) then
				for other_palette_name, other_palette in pairs(_palettes) do
					if (other_palette ~= palette) then
						local new_image_name = string.gsub(image.name, palette_name, other_palette_name)
						if not exists[new_image_name] then
							if log then
								log:write("generating", new_image_name)
							end
							local w, h = image.tex:getDimensions()
							local new_image_data = love.image.newImageData(w, h)
							new_image_data:paste(image.tex:getData(), 0, 0, 0, 0, w, h)
							new_image_data:mapPixel(function(x, y, r, g, b, a)
								if a == 0 then
									return r, g, b, a
								else
									local hash = _colourToString(r, g, b, a)
									local index = palette[hash]
									if not index then
										return fail_r or r, fail_g or g, fail_b or b, fail_a or a
									end
									local other_hash = other_palette[index]
									if not other_hash then
										return fail_r or r, fail_g or g, fail_b or b, fail_a or a
									end
									return _stringToColour(other_hash)
								end
							end)
							table.insert(images, { 
								name = new_image_name,
								tex = love.graphics.newImage(new_image_data)
							})
						end
					end
				end
			end
		end
	end
end


return {
	paint = _paint,
	addPalette = _addPalette
}