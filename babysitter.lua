local _coroutines = {}

local _add = function(c)
	table.insert(_coroutines, c)
end

local _clear = function()
	_coroutines = {}
end

local _isBusy = function()
	return (#_coroutines > 0)
end

local _update = function(dt)
	local i = 1
	while i <= #_coroutines do
		local c = _coroutines[i]
		coroutine.resume(c, dt)
		if coroutine.status(c) == "dead" then
			table.remove(_coroutines, i)
		else
			i = i + 1
		end
	end
end

local _activeWaitThen = function(duration, progress, f)
  babysitter.add(coroutine.create(function(dt)
    local t = 0
		local interrupt = false
    while not interrupt and t < duration do
      t = t + dt
      interrupt = progress(t / duration)
      coroutine.yield()
    end
    f()
  end))
end

local _waitThen = function(duration, f)
	babysitter.add(coroutine.create(function(dt)
   	local t = 0
   	while t < duration do
   		t = t + dt
   		coroutine.yield()
   	end
   	f()
 	end))
end

local _nextFrame = function(f)
	babysitter.add(coroutine.create(function()
 		coroutine.yield()
   	f()
 	end))
end

local _periodically = function(period, f)
	babysitter.add(coroutine.create(function(dt)
		local interrupt = false
		while not interrupt and _coroutines do
	   	local t = 0
	   	while t < period do
	   		t = t + dt
	   		coroutine.yield()
	   	end
	   	interrupt = f()
   	end
 	end))
end

return {
	add = _add,
	update = _update,
	clear = _clear,
	isBusy = _isBusy,
  activeWaitThen = _activeWaitThen,
	waitThen = _waitThen,
	nextFrame = _nextFrame,
	periodically = _periodically
}
