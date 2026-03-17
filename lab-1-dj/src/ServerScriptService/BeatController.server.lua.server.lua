-- BeatController.server.lua  (DJ Loop Station)
-- Master tempo, bar-quantized loop toggles, smooth crossfades.

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- === TEMPO ===
local BPM = 100                  -- master tempo (change as you like)
local BASE_LOOP_BPM = 100        -- source loop tempo for playback scaling
local BEATS_PER_BAR = 4          -- 4/4
local BEAT = 60 / BPM
local BAR = BEAT * BEATS_PER_BAR
local FADE_TIME = 0.35           -- crossfade seconds
local TARGET_VOLUME = 0.8

-- Optional feature: Auto-DJ toggles one random loop every N bars.
local AUTO_MIX = true
local AUTO_MIX_EVERY_BARS = 8
local rng = Random.new()

-- Expose BPM for HUD
workspace:SetAttribute("BPM", BPM)
workspace:SetAttribute("AutoMix", AUTO_MIX)
workspace:SetAttribute("ShowPadLabels", false)
workspace:SetAttribute("TrapsEnabled", true)

-- === LOOPS SOURCE ===
-- Put Sound objects in Workspace/Music with names: Drums, Bass, Synth, FX
local LOOPS_FOLDER = workspace:FindFirstChild("Music")
if not LOOPS_FOLDER then
	LOOPS_FOLDER = Instance.new("Folder")
	LOOPS_FOLDER.Name = "Music"
	LOOPS_FOLDER.Parent = workspace
end

local LOOP_ORDER = { "Drums", "Bass", "Synth", "FX" }
local LOOP_SOUND_IDS = {
	Drums = "rbxassetid://130726160965077",
	Bass = "rbxassetid://114997894803304",
	Synth = "rbxassetid://81829302724743",
	FX = "rbxassetid://132098621388273",
}
local loops = {}      -- name -> Sound
local active = {}     -- name -> bool
local targetVolume = {} -- name -> number (0..1)
local toggleQueue = {} -- name -> "on" | "off" applied next bar
local soloLoop: string? = nil

local CONTROL_EVENT_NAME = "DJControlEvent"
local controlEvent = ReplicatedStorage:FindFirstChild(CONTROL_EVENT_NAME)
if not controlEvent then
	controlEvent = Instance.new("RemoteEvent")
	controlEvent.Name = CONTROL_EVENT_NAME
	controlEvent.Parent = ReplicatedStorage
end

for _, name in ipairs(LOOP_ORDER) do
	local s = LOOPS_FOLDER:FindFirstChild(name)
	if not s then
		s = Instance.new("Sound")
		s.Name = name
		s.Parent = LOOPS_FOLDER
	end
	s.SoundId = LOOP_SOUND_IDS[name] or s.SoundId
	s.Looped = true
	s.Volume = 0
	s.Playing = true  -- play silently so phases align
	loops[name] = s
	active[name] = false
	targetVolume[name] = TARGET_VOLUME
	workspace:SetAttribute("Loop_"..name, false) -- for HUD/pad tint
	workspace:SetAttribute("LoopVolume_"..name, TARGET_VOLUME)
end
workspace:SetAttribute("SoloLoop", "")

local function getEffectiveVolume(name: string): number
	if not active[name] then
		return 0
	end
	if soloLoop and soloLoop ~= name then
		return 0
	end
	return targetVolume[name] or TARGET_VOLUME
end

local function crossfade(sound: Sound, vol: number)
	TweenService:Create(sound, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Volume = vol}):Play()
end

local function refreshMix()
	for name, sound in pairs(loops) do
		crossfade(sound, getEffectiveVolume(name))
	end
end

local function restartAllLoops()
	for _, sound in pairs(loops) do
		if not sound.Playing then
			sound:Play()
		end
		pcall(function()
			sound.TimePosition = 0
		end)
	end
end

local function applyPlaybackSpeedFromBPM()
	local speed = math.clamp(BPM / BASE_LOOP_BPM, 0.5, 2)
	workspace:SetAttribute("PlaybackSpeed", speed)
	for _, sound in pairs(loops) do
		sound.PlaybackSpeed = speed
	end
end

applyPlaybackSpeedFromBPM()

local function applyQueued()
	for name, cmd in pairs(toggleQueue) do
		local s = loops[name]
		if s then
			if cmd == "on" then
				active[name] = true
				crossfade(s, getEffectiveVolume(name))
				workspace:SetAttribute("Loop_"..name, true)
			else
				active[name] = false
				crossfade(s, 0.0)
				workspace:SetAttribute("Loop_"..name, false)
			end
		end
		toggleQueue[name] = nil
	end
end

-- Optional light re-sync each bar (commented to avoid clicks on some assets)
-- local function resync()
--     for _, s in pairs(loops) do s.TimePosition = 0 end
-- end

-- Bar clock
local acc = 0
local barCount = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc >= BAR then
		acc -= BAR
		barCount += 1
		-- resync()
		if AUTO_MIX and barCount % AUTO_MIX_EVERY_BARS == 0 then
			local name = LOOP_ORDER[rng:NextInteger(1, #LOOP_ORDER)]
			if name then
				toggleQueue[name] = active[name] and "off" or "on"
			end
		end
		applyQueued()
	end
end)

-- === PUBLIC API for server-side callers (PadManager will use this) ===
_G.DJ = _G.DJ or {}
function _G.DJ.RequestToggle(loopName: string)
	if not loops[loopName] then return end
	toggleQueue[loopName] = active[loopName] and "off" or "on"
end

function _G.DJ.SetLoopVolume(loopName: string, volume: number)
	if not loops[loopName] then return end
	targetVolume[loopName] = math.clamp(volume, 0, 1)
	workspace:SetAttribute("LoopVolume_"..loopName, targetVolume[loopName])
	refreshMix()
end

function _G.DJ.ToggleSolo(loopName: string)
	if not loops[loopName] then return end
	if soloLoop == loopName then
		soloLoop = nil
	else
		soloLoop = loopName
	end
	workspace:SetAttribute("SoloLoop", soloLoop or "")
	refreshMix()
end

function _G.DJ.SetAutoMix(enabled: boolean)
	AUTO_MIX = enabled and true or false
	workspace:SetAttribute("AutoMix", AUTO_MIX)
end

function _G.DJ.SetShowPadLabels(enabled: boolean)
	workspace:SetAttribute("ShowPadLabels", enabled and true or false)
end

function _G.DJ.SetTrapsEnabled(enabled: boolean)
	workspace:SetAttribute("TrapsEnabled", enabled and true or false)
end

-- Allow other scripts to tweak tempo at runtime (optional)
function _G.DJ.SetBPM(newBPM: number, shouldResync: boolean?)
	BPM = math.clamp(math.floor(newBPM + 0.5), 60, 180)
	workspace:SetAttribute("BPM", BPM)
	-- recompute beat/bar lengths
	BEAT = 60 / BPM
	BAR = BEAT * BEATS_PER_BAR
	applyPlaybackSpeedFromBPM()
	if shouldResync then
		restartAllLoops()
	end
end

function _G.DJ.SetFadeTime(newFade: number)
	FADE_TIME = math.clamp(newFade, 0.05, 1.5)
end

local function isPlayerNearLoopPad(player: Player, loopName: string): boolean
	local character = player.Character
	if not character then
		return false
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end
	local padsFolder = workspace:FindFirstChild("Pads")
	if not padsFolder then
		return false
	end
	for _, child in ipairs(padsFolder:GetChildren()) do
		if child:IsA("BasePart") and child:GetAttribute("Loop") == loopName then
			if (child.Position - hrp.Position).Magnitude <= 24 then
				return true
			end
		end
	end
	return false
end

controlEvent.OnServerEvent:Connect(function(player: Player, action: string, loopName: string?, value: number?)
	if type(action) ~= "string" then
		return
	end

	if action == "SetVolume" then
		if type(loopName) ~= "string" then
			return
		end
		if not loops[loopName] then
			return
		end
		if not isPlayerNearLoopPad(player, loopName) then
			return
		end
		if type(value) ~= "number" then
			return
		end
		_G.DJ.SetLoopVolume(loopName, value)
	elseif action == "ToggleSolo" then
		if type(loopName) ~= "string" then
			return
		end
		if not loops[loopName] then
			return
		end
		if not isPlayerNearLoopPad(player, loopName) then
			return
		end
		_G.DJ.ToggleSolo(loopName)
	elseif action == "SetAutoMix" then
		_G.DJ.SetAutoMix(value == 1)
	elseif action == "SetBPM" then
		if type(value) ~= "number" then
			return
		end
		_G.DJ.SetBPM(value, true)
	elseif action == "SetShowPadLabels" then
		_G.DJ.SetShowPadLabels(value == 1)
	elseif action == "SetTrapsEnabled" then
		_G.DJ.SetTrapsEnabled(value == 1)
	end
end)
