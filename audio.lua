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

local useful = require("unrequited/useful")

local audio = { filenames = {} }

-- the "normal" volume of the current music, between 0 and 1
local _music_base_volume = 1      
-- the global multiplier of the music volumes
local _music_global_volume = 1    
-- the global multiplier of the sound volumes
local _sound_global_volume = 1    


--[[---------------------------------------------------------------------------
LOADING
--]]--

local _getFilename = function(filepath)
  local last_slash = string.find(filepath, "/[^/]*$")
  if last_slash then
  	return (string.sub(filepath, last_slash + 1) or filepath)
  else
  	return filepath
  end
end

function audio:load(filepath, type)
  local filepath = ("assets/audio/" .. filepath .. ".ogg")
  return love.audio.newSource(filepath, type)
end

function audio:load_sound(filepath, volume, n_sources)
  n_sources = (n_sources or 1)
  local filename = _getFilename(filepath)
  self[filename] = {}
  for i = 1, n_sources do 
    local new_source = self:load(filepath, "static") 
    new_source:setVolume(volume or 1)
    self[filename][i] = new_source
  end
end

function audio:load_sounds(base_filepath, n_files, volume, n_sources)
  n_sources = (n_sources or 1)
  local base_filename = _getFilename(base_filepath)
  local filenames = {}
  for f = 1, n_files do
    local filepath = (base_filepath .. "_" .. tostring(f))
    self:load_sound(filepath, volume, n_sources)
    table.insert(filenames, _getFilename(filepath))
  end
  self.filenames[base_filename] = filenames
end


function audio:load_music(filepath)
  self[_getFilename(filepath)] = self:load(filepath, "stream")
end


--[[---------------------------------------------------------------------------
PLAYING
--]]--

function audio:play_music(name, volume, loop)
  _music_base_volume = (volume or 1)
	volume = _music_base_volume * _music_global_volume
  if loop == nil then loop = true end
  local new_music = self[name]
  if (self.music and self.music:isStopped()) or (new_music ~= self.music) then
    if self.music then
      self.music:stop()
    end
    new_music:setLooping(loop)
    if not self.mute and not self.mute_music then
      new_music:play()
    end
    self.music = new_music
  end
  self.music:setVolume(volume)
end

function audio:play_sound(name, pitch_shift, x, y, fixed_pitch)
  if not name then 
    return 
  end

  if self.filenames[name] then
    return self:play_sound(useful.randIn(self.filenames[name]))
  end

  local sources = self[name]
  if not sources then
    print("Missing sound", name)
    return
  end
  for _, src in ipairs(sources) do
    if src:isStopped() then
      
      -- shift the pitch
      if pitch_shift and (pitch_shift ~= 0) then
        src:setPitch(1 + useful.signedRand(pitch_shift))
      elseif fixed_pitch then
        src:setPitch(fixed_pitch)
      end
      
      -- use 3D sound
      if x and y then
        src:setPosition(x, y, 0)
      end
      
      if not self.mute and not self.mute_sound then
        src:play()
        src:setVolume(src:getVolume() * _sound_global_volume)
      end
      
      return src
    end
  end
end


--[[---------------------------------------------------------------------------
VOLUME
--]]--

function audio:set_sound_volume(v)
	_sound_global_volume = v
end

function audio:set_music_volume(v)
  _music_global_volume = v
	if self.music then
		self.music:setVolume(_music_base_volume * _music_global_volume)
	end
end

function audio:toggle_music()
  if not self.music then
    return
  elseif self.music:isPaused() then
    self.music:resume()
  else
    self.music:pause()
  end
end


--[[---------------------------------------------------------------------------
PLAYLISTS
--]]--

function audio:add_to_playlist(filename, volume)
  self:load_music(filename)
  if not self.playlist then 
    self.playlist = {} 
  end
  table.insert(self.playlist, { name = filename, volume = volume })
end


--[[---------------------------------------------------------------------------
ACTIVE WAIT
--]]--

function audio:update(dt)
  if (not self.music) or self.music:isStopped() then
    if self.playlist then
      local song = useful.randIn(self.playlist)
      self:play_music(song.name, song.volume, false)
    end
  end
end

--[[---------------------------------------------------------------------------
EXPORT
--]]--
return audio