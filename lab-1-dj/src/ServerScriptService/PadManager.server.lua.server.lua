-- PadManager.server.lua
-- Spawns/uses a grid in front of SpawnLocation and toggles loops on touch (quantized next bar).

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local InsertService = game:GetService("InsertService")

-- ===== Grid placement =====
local ROWS, COLS  = 3, 3              -- keep your existing grid
local SPACING     = 8
local PAD_SIZE    = Vector3.new(8, 1, 8)
local FORWARD_OFFSET = 30
local DEFAULT_PAD_COLOR = Color3.fromRGB(230, 230, 230)

local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
local spawnPos = spawn and spawn.Position or Vector3.new(0, 0, 0)
local BASE_POS = spawnPos + Vector3.new(0, 0, FORWARD_OFFSET)
local GRID_Y   = spawnPos.Y + 0.1

local function ensureFloor()
	local floorFolder = workspace:FindFirstChild("DJFloor")
	if not floorFolder then
		floorFolder = Instance.new("Folder")
		floorFolder.Name = "DJFloor"
		floorFolder.Parent = workspace
	end

	local floor = floorFolder:FindFirstChild("Runway")
	if not floor then
		floor = Instance.new("Part")
		floor.Name = "Runway"
		floor.Anchored = true
		floor.Material = Enum.Material.Concrete
		floor.Color = Color3.fromRGB(72, 72, 76)
		floor.Parent = floorFolder
	end

	local gridWidth = (COLS - 1) * SPACING + PAD_SIZE.X
	local gridDepth = (ROWS - 1) * SPACING + PAD_SIZE.Z
	local centerX = spawnPos.X + (gridWidth - PAD_SIZE.X) * 0.5
	local centerZ = spawnPos.Z + FORWARD_OFFSET + (gridDepth - PAD_SIZE.Z) * 0.5
	local floorTopY = GRID_Y - (PAD_SIZE.Y * 0.5)

	floor.Size = Vector3.new(math.max(70, gridWidth + 20), 1, math.max(90, FORWARD_OFFSET + gridDepth + 20))
	floor.Position = Vector3.new(centerX, floorTopY - 0.5, centerZ)
	floor.CanCollide = true
	floor.CanTouch = true
end

ensureFloor()

-- ===== Pads folder =====
local PadsFolder = workspace:FindFirstChild("Pads")
if not PadsFolder then
	PadsFolder = Instance.new("Folder")
	PadsFolder.Name = "Pads"
	PadsFolder.Parent = workspace
end

local function makePad(pos: Vector3, nameSuffix: string?)
	local p = Instance.new("Part")
	p.Size = PAD_SIZE
	p.Anchored = true
	p.CanCollide = true
	p.CanTouch = true
	p.Material = Enum.Material.Neon
	p.Color = DEFAULT_PAD_COLOR
	p.Transparency = 0.2
	p.Position = Vector3.new(pos.X, GRID_Y, pos.Z)
	p.Name = nameSuffix and ("Pad_"..nameSuffix) or "Pad"
	p.Parent = PadsFolder
	return p
end

-- Build grid if empty
if #PadsFolder:GetChildren() == 0 then
	for r = 1, ROWS do
		for c = 1, COLS do
			local pos = BASE_POS + Vector3.new((c-1)*SPACING, 0, (r-1)*SPACING)
			makePad(pos)
		end
	end
end

-- ===== Map the first 2x2 pads to loops (Drums/Bass/Synth/FX). Others remain inert. =====
local LOOP_ORDER = { "Drums", "Bass", "Synth", "FX" }
local LOOP_COLORS = {
	Drums = Color3.fromRGB(230, 60, 60),
	Bass = Color3.fromRGB(60, 130, 255),
	Synth = Color3.fromRGB(80, 220, 110),
	FX = Color3.fromRGB(170, 95, 255),
}
local TRAP_ORDER = { "Lightning", "Explosion", "Piano" }

local SFX_IDS = {
	Lightning = "rbxassetid://117922524763696",
	Explosion = "rbxassetid://139771888058836",
	Piano = "rbxassetid://7803690013",
}
local PIANO_MODEL_ID = 304149009

local function playSfx(parent: Instance, soundId: string, volume: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 5)
end

local function getCharacterFromHit(hit: BasePart)
	local model = hit:FindFirstAncestorOfClass("Model")
	if not model then
		return nil, nil
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then
		return nil, nil
	end
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return nil, nil
	end
	return model, hum
end

local function triggerLightning(character: Model, hum: Humanoid)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return
	end

	playSfx(hrp, SFX_IDS.Lightning, 1)

	local bolt = Instance.new("Part")
	bolt.Anchored = true
	bolt.CanCollide = false
	bolt.Material = Enum.Material.Neon
	bolt.Color = Color3.fromRGB(255, 255, 180)
	bolt.Size = Vector3.new(1, 26, 1)
	bolt.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 13, 0))
	bolt.Parent = workspace
	Debris:AddItem(bolt, 0.18)

	hum:TakeDamage(8)
end

local function triggerExplosion(character: Model, hum: Humanoid)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return
	end

	local beforeHealth = hum.Health
	playSfx(hrp, SFX_IDS.Explosion, 1)

	local ex = Instance.new("Explosion")
	ex.Position = hrp.Position
	ex.BlastRadius = 10
	ex.BlastPressure = 55000
	ex.DestroyJointRadiusPercent = 0
	ex.ExplosionType = Enum.ExplosionType.NoCraters
	ex.Parent = workspace

	task.delay(0.06, function()
		if hum and hum.Parent then
			hum.Health = math.max(hum.Health, beforeHealth)
		end
	end)
end

local function createPianoPart(position: Vector3): BasePart
	local piano = Instance.new("Part")
	piano.Size = Vector3.new(6, 3, 4)
	piano.Material = Enum.Material.SmoothPlastic
	piano.Color = Color3.fromRGB(20, 20, 20)
	piano.Name = "FallingPiano"
	piano.Position = position
	piano.Parent = workspace
	return piano
end

local function spawnPiano(position: Vector3): (Instance, BasePart)
	local ok, assetModel = pcall(function()
		return InsertService:LoadAsset(PIANO_MODEL_ID)
	end)
	if ok and assetModel then
		assetModel.Parent = workspace
		local piano = assetModel:FindFirstChildWhichIsA("BasePart", true)
		if piano then
			local model = piano:FindFirstAncestorOfClass("Model")
			if model then
				model:PivotTo(CFrame.new(position))
				for _, desc in ipairs(model:GetDescendants()) do
					if desc:IsA("BasePart") then
						desc.Anchored = false
					end
				end
				Debris:AddItem(model, 8)
				return model, piano
			end
		end
		assetModel:Destroy()
	end

	local fallback = createPianoPart(position)
	fallback.Anchored = false
	Debris:AddItem(fallback, 8)
	return fallback, fallback
end

local function shatterPiano(container: Instance, impactPos: Vector3)
	if container and container.Parent then
		for _, desc in ipairs(container:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Transparency = 1
				desc.CanCollide = false
				desc.CanTouch = false
			end
		end
	end

	for _ = 1, 14 do
		local chunk = Instance.new("Part")
		chunk.Size = Vector3.new(0.5, 0.35, 0.5)
		chunk.Material = Enum.Material.Slate
		chunk.Color = Color3.fromRGB(35, 35, 35)
		chunk.Position = impactPos + Vector3.new(0, 0.4, 0)
		chunk.Parent = workspace
		chunk.AssemblyLinearVelocity = Vector3.new(
			math.random(-18, 18),
			math.random(8, 20),
			math.random(-18, 18)
		)
		chunk.AssemblyAngularVelocity = Vector3.new(
			math.random(-16, 16),
			math.random(-16, 16),
			math.random(-16, 16)
		)
		Debris:AddItem(chunk, 2.2)
	end

	local burst = Instance.new("Part")
	burst.Size = Vector3.new(1, 1, 1)
	burst.Anchored = true
	burst.CanCollide = false
	burst.CanTouch = false
	burst.Transparency = 1
	burst.Position = impactPos + Vector3.new(0, 0.4, 0)
	burst.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(80, 80, 80))
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Lifetime = NumberRange.new(0.45, 0.7)
	emitter.Speed = NumberRange.new(6, 12)
	emitter.SpreadAngle = Vector2.new(360, 360)
	emitter.Rate = 0
	emitter.Parent = burst
	emitter:Emit(26)
	Debris:AddItem(burst, 1)
end

local function triggerPiano(character: Model, hum: Humanoid)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return
	end

	local dropPos = hrp.Position + Vector3.new(0, 30, 0)
	local pianoContainer, pianoPart = spawnPiano(dropPos)
	local impactHandled = false

	local conn
	conn = pianoPart.Touched:Connect(function(hit)
		if impactHandled then
			return
		end
		if not hit.CanCollide then
			return
		end

		local hitModel = hit:FindFirstAncestorOfClass("Model")
		if hitModel == character then
			-- Wait until piano lands on world/prop surface to play impact audio.
			return
		end

		impactHandled = true
		playSfx(pianoPart, SFX_IDS.Piano, 0.45)
		shatterPiano(pianoContainer, pianoPart.Position)

		local regionPos = pianoPart.Position
		if (hrp.Position - regionPos).Magnitude <= 10 then
			hum:TakeDamage(12)
		end

		if conn then
			conn:Disconnect()
		end
	end)
	task.delay(3, function()
		if not impactHandled and conn then
			conn:Disconnect()
		end
	end)
end

local function triggerTrap(trapName: string, character: Model, hum: Humanoid)
	if trapName == "Lightning" then
		triggerLightning(character, hum)
	elseif trapName == "Explosion" then
		triggerExplosion(character, hum)
	elseif trapName == "Piano" then
		triggerPiano(character, hum)
	end
end

local function shuffledCopy<T>(arr: {T}): {T}
	local out = {}
	for i = 1, #arr do
		out[i] = arr[i]
	end
	for i = #out, 2, -1 do
		local j = math.random(1, i)
		out[i], out[j] = out[j], out[i]
	end
	return out
end

local function ensurePadLabel(pad: BasePart): TextLabel
	local billboard = pad:FindFirstChild("PadLabelGui")
	if not billboard then
		billboard = Instance.new("SurfaceGui")
		billboard.Name = "PadLabelGui"
		billboard.Face = Enum.NormalId.Top
		billboard.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		billboard.PixelsPerStud = 24
		billboard.LightInfluence = 1
		billboard.CanvasSize = Vector2.new(220, 70)
		billboard.Parent = pad
	end

	local text = billboard:FindFirstChild("Text")
	if not text then
		text = Instance.new("TextLabel")
		text.Name = "Text"
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		text.BackgroundTransparency = 0.4
		text.TextColor3 = Color3.fromRGB(255, 255, 255)
		text.TextScaled = true
		text.Font = Enum.Font.GothamBold
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1
		stroke.Parent = text
		text.Parent = billboard
	end

	return text
end

local function refreshPadLabels(padList)
	local show = workspace:GetAttribute("ShowPadLabels") == true
	for _, pad in ipairs(padList) do
		if pad:IsA("BasePart") then
			local billboard = pad:FindFirstChild("PadLabelGui")
			local textLabel = billboard and billboard:FindFirstChild("Text")
			local loopName = pad:GetAttribute("Loop")
			local trapName = pad:GetAttribute("Trap")
			if billboard and textLabel and textLabel:IsA("TextLabel") then
				billboard.Enabled = show and (loopName ~= nil or trapName ~= nil)
				if loopName then
					textLabel.Text = tostring(loopName)
				elseif trapName then
					textLabel.Text = tostring(trapName)
				else
					textLabel.Text = ""
				end
			end
		end
	end
end

local pads = PadsFolder:GetChildren()
table.sort(pads, function(a, b)
	if a.Position.Z == b.Position.Z then
		return a.Position.X < b.Position.X
	end
	return a.Position.Z < b.Position.Z
end)
local initialPositions = {}
for idx, pad in ipairs(pads) do
	if pad:IsA("BasePart") then
		initialPositions[idx] = pad.Position
		pad:SetAttribute("Loop", nil)
		pad:SetAttribute("Trap", nil)
		pad.Name = "Pad"
		pad.Color = DEFAULT_PAD_COLOR
		ensurePadLabel(pad)
	end
end

local function clearRolesAndVisuals()
	for _, pad in ipairs(pads) do
		if pad:IsA("BasePart") then
			pad:SetAttribute("Loop", nil)
			pad:SetAttribute("Trap", nil)
			pad.Name = "Pad"
			pad.Color = DEFAULT_PAD_COLOR
		end
	end
end

local function assignLoopPadsFixed()
	for i = 1, math.min(4, #pads) do
		local pad = pads[i]
		if pad and pad:IsA("BasePart") then
			pad:SetAttribute("Loop", LOOP_ORDER[i])
			pad.Name = "Pad_" .. LOOP_ORDER[i]
		end
	end
end

local function assignTrapsFixed()
	local trapStart = 5
	for i = trapStart, math.min(trapStart + #TRAP_ORDER - 1, #pads) do
		local trapName = TRAP_ORDER[i - trapStart + 1]
		local pad = pads[i]
		if pad and pad:IsA("BasePart") then
			pad:SetAttribute("Trap", trapName)
			pad.Name = "Pad_" .. trapName
		end
	end
end

local function applyPositionsFromList(positionList)
	for i, pad in ipairs(pads) do
		if pad:IsA("BasePart") and positionList[i] then
			local pos = positionList[i]
			pad.Position = Vector3.new(pos.X, GRID_Y, pos.Z)
		end
	end
end

local function randomizePadPositions()
	local shuffled = shuffledCopy(initialPositions)
	applyPositionsFromList(shuffled)
end

local function applyInitialLayoutNoTraps()
	applyPositionsFromList(initialPositions)
	clearRolesAndVisuals()
	assignLoopPadsFixed()
	workspace:SetAttribute("ShowPadLabels", true)
	workspace:SetAttribute("TrapsOnPads", false)
	refreshPadLabels(pads)
	workspace:SetAttribute("TrapsEnabled", false)
end

local function applyRandomizedLayoutWithTraps()
	randomizePadPositions()
	clearRolesAndVisuals()
	assignLoopPadsFixed()
	assignTrapsFixed()
	workspace:SetAttribute("ShowPadLabels", false)
	workspace:SetAttribute("TrapsOnPads", true)
	refreshPadLabels(pads)
	workspace:SetAttribute("TrapsEnabled", true)
end

applyInitialLayoutNoTraps()
workspace:SetAttribute("ShowPadLabels", true)

refreshPadLabels(pads)
workspace:GetAttributeChangedSignal("ShowPadLabels"):Connect(function()
	refreshPadLabels(pads)
end)

_G.PadLayout = _G.PadLayout or {}
function _G.PadLayout.RandomizeWithTraps()
	applyRandomizedLayoutWithTraps()
end

function _G.PadLayout.ResetInitialLayout()
	applyInitialLayoutNoTraps()
end

-- Visual state: tint pads when their loop is active
local function bindActiveTint(pad: Part, loopName: string)
	local attr = "Loop_"..loopName
	local activeColor = LOOP_COLORS[loopName] or Color3.fromRGB(0,255,170)
	local lastState = false

	local function burst()
		local att = Instance.new("Attachment")
		att.Parent = pad
		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(activeColor)
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Lifetime = NumberRange.new(0.25, 0.45)
		emitter.Rate = 0
		emitter.Speed = NumberRange.new(5, 9)
		emitter.SpreadAngle = Vector2.new(360, 360)
		emitter.Parent = att
		emitter:Emit(24)
		Debris:AddItem(att, 1)
	end

	local function update()
		local on = workspace:GetAttribute(attr)
		pad.Color = on and activeColor or Color3.fromRGB(230,230,230)
		if on and not lastState then
			burst()
		end
		lastState = on and true or false
	end
	workspace:GetAttributeChangedSignal(attr):Connect(update)
	update()

	task.spawn(function()
		while pad.Parent do
			if workspace:GetAttribute(attr) then
				local bpm = workspace:GetAttribute("BPM") or 100
				local beat = 60 / math.max(1, bpm)
				local grow = TweenService:Create(
					pad,
					TweenInfo.new(beat * 0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{ Size = PAD_SIZE + Vector3.new(0, 0.25, 0), Transparency = 0.05 }
				)
				grow:Play()
				grow.Completed:Wait()

				local shrink = TweenService:Create(
					pad,
					TweenInfo.new(beat * 0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
					{ Size = PAD_SIZE, Transparency = 0.2 }
				)
				shrink:Play()
				shrink.Completed:Wait()
			else
				if pad.Size ~= PAD_SIZE then
					pad.Size = PAD_SIZE
				end
				if pad.Transparency ~= 0.2 then
					pad.Transparency = 0.2
				end
				task.wait(0.2)
			end
		end
	end)
end

for _, pad in ipairs(pads) do
	local loopName = pad:GetAttribute("Loop")
	if loopName then
		local cooldownUntil = 0
		bindActiveTint(pad, loopName)
		pad.Touched:Connect(function(hit)
			if os.clock() < cooldownUntil then
				return
			end
			local model = hit:FindFirstAncestorOfClass("Model")
			local hum = model and model:FindFirstChildOfClass("Humanoid")
			if not hum then return end
			cooldownUntil = os.clock() + 0.3
			if _G.DJ and _G.DJ.RequestToggle then
				_G.DJ.RequestToggle(loopName) -- queues toggle for next bar
				-- quick tap flash
				local old = pad.Color
				pad.Color = Color3.fromRGB(255,230,0)
				task.delay(0.12, function() if pad and pad.Parent then pad.Color = old end end)
			end
		end)
	end

	local trapName = pad:GetAttribute("Trap")
	local cooldownUntil = 0
	local touchedBy = {}
	pad.Touched:Connect(function(hit)
		local dynamicTrapName = pad:GetAttribute("Trap")
		if type(dynamicTrapName) ~= "string" then
			return
		end
		if workspace:GetAttribute("TrapsEnabled") == false then
			return
		end
		if os.clock() < cooldownUntil then
			return
		end
		local character, hum = getCharacterFromHit(hit)
		if not character or not hum then
			return
		end
		local perCharacterKey = character:GetFullName()
		if touchedBy[perCharacterKey] and os.clock() - touchedBy[perCharacterKey] < 1.5 then
			return
		end
		touchedBy[perCharacterKey] = os.clock()
		cooldownUntil = os.clock() + 0.7

		local old = pad.Color
		pad.Color = Color3.fromRGB(255, 255, 255)
		task.delay(0.12, function()
			if pad and pad.Parent then
				pad.Color = old
			end
		end)

		triggerTrap(dynamicTrapName, character, hum)
	end)
end
