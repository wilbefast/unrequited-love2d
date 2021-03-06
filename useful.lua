--[[
"Unrequited", a Löve 2D extension library
(C) Copyright 2013 William Dyce

All rights reserved. This program and the accompanying materials
are made available under the terms of the GNU Lesser General Public License
(LGPL) version 2.1 which accompanies this distribution, and is available at
http://www.gnu.org/licenses/lgpl-2.1.html

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
Lesser General Public License for more details.
--]]

local useful = { }

function useful.any(objects, f)
  for i, obj in ipairs(objects) do
    if f(obj, i) then
      return obj
    end
  end
  return nil
end

function useful.all(objects, f)
  for i, obj in ipairs(objects) do
    if not f(obj, i) then
      return false
    end
  end
  return true
end

-- map a set of functions to a set of objects
function useful.map(objects, ...)
  local args = useful.packArgs(...)
  local oi = 1
  -- for each object...
  while oi <= #objects do
    local obj = objects[oi]
    -- check if the object needs to be removed
    if obj.purge then
      if obj.onPurge then
        obj:onPurge()
        obj.onPurge = false
      end
      table.remove(objects, oi)
    else
      -- for each function...
      for fi, func in ipairs(args) do
        -- map function to object
        if type(func)=="function" then -- Make sure it's a function, because, the 1st arguement is an object
          func(obj, oi, objects)
        end
      end -- for fi, func in ipairs(arg)
      -- next object
      oi = oi + 1
    end -- if obj.purge
  end -- while oi <= #objects
end -- useful.map(objects, functions)

function useful.purge(objects)
  local i = 1
  while i <= #objects do
    local o = objects[i]
    if o.purge then
      if o.onPurge then
        o:onPurge()
        o.onPurge = false
      end
      table.remove(objects, i)
    else
      i = i + 1
    end
  end
end

function useful.removeWhere(objects, precond)
  local i = 1
  while i <= #objects do
    local o = objects[i]
    if precond(o) then
      table.remove(objects, i)
    else
      i = i + 1
    end
  end
end


-- Because Love2D implementation of args is different?
function useful.packArgs(a, ...)
  if a ~= nil then
    local ret = useful.packArgs(...)
    table.insert(ret,1,a)
    return ret
  else
    return {}
  end
end

-- trinary operator
function useful.tri(cond, a, b)
  if cond then
    return a
  else
    return b
  end
end

-- reduce the absolute value of something
function useful.absminus(v, minus)
  if v > 0 then
    return math.max(0, v - minus)
  else
    return math.min(0, v + minus)
  end
end

-- function missing from math
function useful.round(x, n)
  if n then
    -- round to nearest n
    return useful.round(x / n) * n
  else
    -- round to nearest integer
    local floor = math.floor(x)
    if (x - floor) < 0.5 then
      return floor
    else
      return math.ceil(x)
    end
  end
end

function useful.floor(x, n)
  if n then
    -- floor to nearest n
    return math.floor(x / n) * n
  else
    -- floor to nearest integer
    return math.floor(x)
  end
end

function useful.ceil(x, n)
  if n then
    -- ceil to nearest n
    return math.ceil(x / n) * n
  else
    -- ceil to nearest integer
    return math.ceil(x)
  end
end

-- sign of a number: -1, 0 or 1
function useful.sign(x)
  if x > 0 then
    return 1
  elseif x < 0 then
    return -1
  else
    return 0
  end
end

function useful.nonZeroSign(x)
  return (((x < 0) and -1) or 1)
end

-- square a number
function useful.sqr(x)
  return x*x
end

-- square distance between 2 points
function useful.dist2(x1, y1, x2, y2)
  local dx, dy = x1-x2, y1-y2
  return (dx*dx + dy*dy)
end

-- two-directional look-up
function useful.bind(table, a, b)
  table[a] = b
  table[b] = a
end

function useful.signedRand(value)
  value = (value or 1)
  local r = math.random()
  return useful.tri(r < 0.5, value*2*r, -value*2*(r-0.5))
end

function useful.iSignedRand(value)
  value = (value and math.floor(value + 0.5)) or 1
  local r = math.random()
  return (((r > 0.5) and value) or -value)
end

function useful.clamp(val, lower_bound, upper_bound)
  return math.max(lower_bound, math.min(upper_bound, val))
end

function useful.randIn(table)
  return table[math.random(#table)]
end

function useful.lerp(a, b, amount)
  useful.clamp(amount, 0, 1)
  return ((1-amount)*a + amount*b)
end

function useful.printf(text, x, y, angle, maxwidth)

  maxwidth = (maxwidth or 0)/(SCALE_MIN or 1)

  love.graphics.push()
    love.graphics.scale(SCALE_MIN, SCALE_MIN)
    love.graphics.translate(x, y)
    if angle then
      love.graphics.rotate(angle)
    end
    love.graphics.printf(text, -maxwidth*0.5, 0, maxwidth, "center")
  love.graphics.pop()
end

function useful.getBackgroundColorWithAlpha(a)
  local r, g, b = love.graphics.getBackgroundColor()
  return r, g, b, a
end

function useful.dot(x1, y1, x2, y2)
  return x1*x2 + y1*y2
end

function useful.dist2(x1, y1, x2, y2)
  local dx, dy = x2-x1, y2-y1
  return dx*dx + dy*dy
end

function useful.lineCircleCollision(x1, y1, x2, y2, cx, cy, cr)
  -- project the circle centre onto the line
  local toCircleX, toCircleY = cx-x1, cy-y1
  local alongLineX, alongLineY = x2-x1, y2-y1
  local projlength = useful.dot(toCircleX, toCircleY, alongLineX, alongLineY)
                    /useful.dot(alongLineX, alongLineY, alongLineX, alongLineY)

  -- projection is 'before' the segment ?
  if projlength < 0 then
    return (useful.dist2(x1, y1, cx, cy) < cr*cr)
  -- projection is 'after' the segment ?
  elseif projlength > 1 then
    return (useful.dist2(x2, y2, cx, cy) < cr*cr)
  end

  -- projection is somewhere on the segment
  local projx, projy = x1 + alongLineX*projlength, y1 + alongLineY*projlength

  -- calculate the distance for the projection to the centre of the circle
  local projToCircle2 = useful.dist2(x1, y1, cx, cy) - useful.dist2(x1, y1, projx, projy)

  -- true if the radius is larger than this distance
  return (projToCircle2 < cr*cr)
end

function useful.lineBoxCollision(x1, y1, x2, y2, bx, by, bw, bh)
  -- TODO
  print("'lineBoxCollision' is not implemented")
  return false
end

function useful.bindWhite(a)
  love.graphics.setColor(1, 1, 1, a or 1)
end

function useful.bindBlack(a)
  love.graphics.setColor(0, 0, 0, a or 1)
end

function useful.recordGIF(key)
  if (not key) or love.keyboard.isDown(key) then
    __kev__snum = (__kev__snum or 0) + 1
    love.filesystem.createDirectory("GIF")
    love.graphics.captureScreenshot(string.format("GIF/%04d",__kev__snum)..".png")
  end
end

useful.canvasStack = {}

function useful.pushCanvas(newCanvas)
  table.insert(useful.canvasStack, love.graphics.getCanvas())
  love.graphics.push()
  love.graphics.origin()
  love.graphics.setCanvas(newCanvas)
end

function useful.popCanvas()
  local n = #useful.canvasStack
  if n > 0 then
    local oldCanvas = useful.canvasStack[n]
    table.remove(useful.canvasStack, n)
    love.graphics.pop()
    love.graphics.setCanvas(oldCanvas)
  else
    love.graphics.pop()
    love.graphics.setCanvas()
  end
end

function useful.getTimestamp()
  return os.date("%x_%X"):gsub("[/:]", "-")
end

function useful.copyTable(t)
  local result = {}
  for k, v in pairs(t) do
    result[k] = v
  end
  return result
end

local __fill = 0
local __line = 1
local __dashfill = 2
local __dashline = 3

function useful.oval(mode, ox, oy, w, h)
  if mode == "fill" then mode = __fill
  elseif mode == "line" then mode = __line
  elseif mode == "dashfill" then mode = __dashfill
  elseif mode == "dashline" then mode = __dashline
  else
    print("invalid mode '" .. mode .. "' passed to useful.oval")
    return
  end

  if (w <= 0) or (h <= 0) then
    print("invalid size " .. w .. "x" .. h .. " passed to useful.oval")
    print(debug.traceback())
    return
  end

  local dash = false
  local angle_step = math.pi/math.min(w, h)/2
  local px, py
  for angle = 0, math.pi*2 + angle_step, angle_step do
    angle = math.min(angle, math.pi*2)
    local x, y = ox + math.cos(angle)*w, oy + math.sin(angle)*h
    if px and py then
      if mode == __fill then
        love.graphics.polygon("fill", ox, oy, px, py, x, y)
      elseif mode == __line then
        love.graphics.line(px, py, x, y)
      else
        dash = (not dash)
        if dash then
          if mode == __dashfill then
            love.graphics.polygon("fill", ox, oy, px, py, x, y)
          elseif mode == __dashline then
            love.graphics.line(px, py, x, y)
          end
        end
      end
    end
    px, py = x, y
  end
end

function useful.anySuchThat(table, predicate)
  for i, v in ipairs(table) do
    if predicate(v) then
      return true
    end
  end
  return false
end

function useful.arc(mode, ox, oy, w, h, start_angle, amount)
  if mode == "fill" then mode = __fill
  elseif mode == "line" then mode = __line
  elseif mode == "dashline" then mode = __dashline
  else
    print("invalid mode '" .. mode .. "' passed to useful.arc")
    return
  end
  if amount < -1 then amount = -1 end
  if amount > 1 then amount = 1 end
  local angle_step = math.pi/math.max(w, h)
  local end_angle = start_angle + math.pi*2*amount

  local dash = false

  local px, py
  for angle = start_angle, end_angle, angle_step do
    local x, y = ox + math.cos(angle)*w, oy + math.sin(angle)*h
    if px and py then
      if mode == __fill then
        love.graphics.polygon("fill", ox, oy, px, py, x, y)
      elseif mode == __line then
        love.graphics.line(px, py, x, y)
      else
        dash = (not dash)
        if dash then
          if mode == __dashfill then
            love.graphics.polygon("fill", ox, oy, px, py, x, y)
          elseif mode == __dashline then
            love.graphics.line(px, py, x, y)
          end
        end
      end
    end
    px, py = x, y
  end
end

function useful.shuffle(t)
  for i = #t, 2, -1 do
    local j = math.random(1, i)
    local swap = t[i]
    t[i] = t[j]
    t[j] = swap
  end
  return t
end

function useful.shuffled_ipairs(t, f)
  local indices = {}
  for i = 1, #t do
    indices[i] = i
  end
  useful.shuffle(indices)
  for i = 1, #indices do
    if f(t[indices[i]]) then
      return
    end
  end
end

function useful.deck()
  local cards = {}
  local discards = {}
  function draw()
    if #cards == 0 then
      cards = discards
      useful.shuffle(discards)
      discards = {}
    end
    local card = cards[#cards]
    table.remove(cards)
    table.insert(discards, card)
    return card
  end
  function shuffle()
    useful.shuffle(cards)
  end
  function stack(card)
    table.insert(cards, 1, card)
  end
  function bury(card)
    table.insert(cards, card)
  end
  function lose(card)
    table.insert(cards, math.ceil(math.random() * #cards), card)
  end
  function count()
    return #cards
  end

  return {
    draw = draw,
    stack = stack,
    bury = bury,
    lose = lose,
    shuffle = shuffle,
    count = count
  }
end

function useful.hsl(hue, saturation, lightness, alpha)
  alpha = alpha or 1
  if hue < 0 or hue > 360 then
      return 0, 0, 0, alpha
  end
  if saturation < 0 or saturation > 1 then
      return 0, 0, 0, alpha
  end
  if lightness < 0 or lightness > 1 then
      return 0, 0, 0, alpha
  end
  local chroma = (1 - math.abs(2 * lightness - 1)) * saturation
  local h = hue/60
  local x =(1 - math.abs(h % 2 - 1)) * chroma
  local r, g, b = 0, 0, 0
  if h < 1 then
      r,g,b=chroma,x,0
  elseif h < 2 then
      r,b,g=x,chroma,0
  elseif h < 3 then
      r,g,b=0,chroma,x
  elseif h < 4 then
      r,g,b=0,x,chroma
  elseif h < 5 then
      r,g,b=x,0,chroma
  else
      r,g,b=chroma,0,x
  end
  local m = lightness - chroma/2
  return (r+m), (g+m), (b+m), alpha
end

function useful.ktemp(temperature)

  temperature = temperature*0.01

  local r, g, b

  if temperature <= 66 then
    r = 255
  else
    r = temperature - 60
    r = 329.698727466 * math.pow(r, -0.1332047592)
    if r < 0 then
      r = 0
    elseif r > 255 then
      r = 255
    end
  end

  if temperature <= 66 then
    g = temperature
    g = 99.4708025861 * math.log(g) - 161.1195681661
    if g < 0 then
      g = 0
    elseif g > 255 then
      g = 255
    end
  else
    g = temperature - 60
    g = 288.1221695283 * math.pow(g, -0.0755148492)
    if g < 0 then
      g = 0
    elseif g > 255 then
      g = 255
    end
  end

  if temperature >= 66 then
    b = 255
  else
    if temperature <= 19 then
      b = 0
    else
      b = temperature - 10
      b = 138.5177312231 * math.log(b) - 305.0447927307
      if b < 0 then
        b = 0
      elseif b > 255 then
        b = 255
      end
    end
  end

  return r/255, g/255, b/255
end

useful.format_time = function(time, h_sep, m_sep, s_sep)
  h_sep = h_sep or ":"
  m_sep = m_sep or ":"
  s_sep = s_sep or ""
  local hours = math.floor(time/60/60)
  time = time - hours*60*60
  local minutes = math.floor(time/60)
  time = time - minutes*60
  local seconds = math.floor(time)
  if hours > 0 then
    return string.format("%02d%s%02f%s%02d%s", hours, h_sep, minutes, m_sep, seconds, s_sep)
  elseif minutes > 0 then
    return string.format("%02d%s%02d%s", minutes, m_sep, seconds, s_sep)
  else
    return string.format("%02d%s", seconds, s_sep)
  end
end

return useful
