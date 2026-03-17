local RNG = {}
local rng = Random.new()
function RNG.choice(t)
	return t[rng:NextInteger(1, #t)]
end
function RNG.float(min,max)
	return rng:NextNumber(min,max)
end
return RNG
