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
  if self.DRY_RUN then
    return nil
  end
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
  if n_files <= 1 then
    return audio:load_sound(base_filepath, volume, n_sources)
  end
  if self.DRY_RUN then
    return nil
  end
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


function audio:load_music(args)
  if self.DRY_RUN then
    return nil
  end
  local filepath = args.filepath
  local id = args.id or _getFilename(filepath)
  local result = {
    stream = self:load(filepath, "stream"),
    volume = args.volume or 1,
    followed_by = args.followed_by or nil,
    loop = (args.loop == nil and true) or false
  }
  self[id] = result
  return result
end


--[[---------------------------------------------------------------------------
PLAYING
--]]--

function audio:stop_music()
  if self.music then
    self.music.stream:stop()
  end
end

function audio:play_music(id, volume, loop)
  if self.DRY_RUN then
    return
  end
  local new_music = self[id]
  volume = (volume or new_music.volume or 1) * _music_global_volume
  if loop == nil then
    loop = not new_music.followed_by and new_music.loop
  end
  if (self.music and not self.music.stream:isPlaying()) or (new_music ~= self.music) then
    if self.music then
      self.music.stream:stop()
    end
    new_music.stream:setLooping(loop)
    if not self.mute and not self.mute_music then
      new_music.stream:play()
    end
    self.music = new_music
  end
  self.music.stream:setVolume(volume)
end

function audio:is_playing_music(id)
  if not self.music then
    return false
  elseif not id then
    return self.music and self.music.stream:isPlaying()
  else
    local music = self[id]
    if not music then
      return false
    else
      return self.music == music
    end
  end
end

function audio:play_sound(name, pitch_shift, x, y, fixed_pitch)
  if self.DRY_RUN then
    return
  end

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
    if not src:isPlaying() then

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

function audio:get_sound_volume()
	return _sound_global_volume
end

function audio:set_music_volume(v)
  _music_global_volume = v
	if self.music then
		self.music.stream:setVolume(self.music.volume * _music_global_volume)
	end
end

function audio:get_music_volume()
	return _music_global_volume
end

function audio:toggle_music()
  if not self.music then
    return
  elseif self.music.stream:isPaused() then
    self.music.stream:play()
  else
    self.music.stream:pause()
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
  if (not self.music) or (not self.music.stream:isPlaying()) then
    if self.music and self.music.followed_by then
      self:play_music(self.music.followed_by)
    elseif self.playlist then
      local song = useful.randIn(self.playlist)
      self:play_music(song.name, song.volume, false)
    end
  end
end

--[[---------------------------------------------------------------------------
EXPORT
--]]--
return audio
