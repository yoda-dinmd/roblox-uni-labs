local Timer = {}; Timer.__index = Timer
function Timer.new(seconds) return setmetatable({t=seconds}, Timer) end
function Timer:tick(dt) self.t = math.max(0, self.t - dt) end
function Timer:done() return self.t <= 0 end
function Timer:value() return self.t end
return Timer
