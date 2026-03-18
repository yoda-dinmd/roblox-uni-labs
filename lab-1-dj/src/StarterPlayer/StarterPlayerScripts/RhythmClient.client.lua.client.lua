-- RhythmClient.client.lua  (DJ HUD + per-pad controls)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local mouse = plr:GetMouse()
local controlEvent = ReplicatedStorage:WaitForChild("DJControlEvent")

local LOOP_ORDER = { "Drums", "Bass", "Synth", "FX" }

local gui = Instance.new("ScreenGui")
gui.Name = "DJHud"
gui.ResetOnSpawn = false
gui.Parent = plr:WaitForChild("PlayerGui")

local function makeLabel(text, y)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(0, 320, 0, 32)
	l.Position = UDim2.new(0.03, 0, y, 0)
	l.TextScaled = true
	l.BackgroundTransparency = 0.2
	l.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	l.TextColor3 = Color3.fromRGB(255, 255, 255)
	l.Font = Enum.Font.GothamBold
	local stroke = Instance.new("UIStroke", l)
	stroke.Thickness = 1
	l.Text = text
	l.Parent = gui
	return l
end

local bpmL = makeLabel("BPM: --", 0.06)

local openSettingsBtn = Instance.new("TextButton")
openSettingsBtn.Size = UDim2.new(0, 170, 0, 34)
openSettingsBtn.Position = UDim2.new(0.03, 0, 0.125, 0)
openSettingsBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
openSettingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openSettingsBtn.Font = Enum.Font.GothamBold
openSettingsBtn.TextSize = 14
openSettingsBtn.Text = "Open DJ Settings"
openSettingsBtn.Parent = gui

workspace:GetAttributeChangedSignal("BPM"):Connect(function()
	bpmL.Text = "BPM: " .. tostring(workspace:GetAttribute("BPM") or 0)
end)
bpmL.Text = "BPM: " .. tostring(workspace:GetAttribute("BPM") or 0)

local panel = Instance.new("Frame")
panel.Name = "LoopControl"
panel.Size = UDim2.new(0, 330, 0, 190)
panel.Position = UDim2.new(1, -350, 0.08, 0)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

local settingsPanel = Instance.new("Frame")
settingsPanel.Name = "DJSettings"
settingsPanel.Size = UDim2.new(0, 280, 0, 390)
settingsPanel.Position = UDim2.new(0.03, 0, 0.17, 0)
settingsPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
settingsPanel.BackgroundTransparency = 0.15
settingsPanel.BorderSizePixel = 0
settingsPanel.Visible = false
settingsPanel.Parent = gui

local settingsStroke = Instance.new("UIStroke")
settingsStroke.Thickness = 1
settingsStroke.Color = Color3.fromRGB(255, 255, 255)
settingsStroke.Transparency = 0.5
settingsStroke.Parent = settingsPanel

local settingsTitle = Instance.new("TextLabel")
settingsTitle.Size = UDim2.new(1, -45, 0, 28)
settingsTitle.Position = UDim2.new(0, 12, 0, 8)
settingsTitle.BackgroundTransparency = 1
settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
settingsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.TextSize = 18
settingsTitle.Text = "DJ Settings"
settingsTitle.Parent = settingsPanel

local settingsCloseBtn = Instance.new("TextButton")
settingsCloseBtn.Size = UDim2.new(0, 26, 0, 26)
settingsCloseBtn.Position = UDim2.new(1, -34, 0, 9)
settingsCloseBtn.BackgroundColor3 = Color3.fromRGB(66, 66, 76)
settingsCloseBtn.Text = "X"
settingsCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
settingsCloseBtn.Font = Enum.Font.GothamBold
settingsCloseBtn.TextSize = 14
settingsCloseBtn.Parent = settingsPanel

local autoMixBtn = Instance.new("TextButton")
autoMixBtn.Size = UDim2.new(1, -24, 0, 40)
autoMixBtn.Position = UDim2.new(0, 12, 0, 48)
autoMixBtn.BackgroundColor3 = Color3.fromRGB(58, 58, 70)
autoMixBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoMixBtn.Font = Enum.Font.GothamBold
autoMixBtn.TextSize = 16
autoMixBtn.Text = "Auto-Mix"
autoMixBtn.Parent = settingsPanel

local labelsBtn = Instance.new("TextButton")
labelsBtn.Size = UDim2.new(1, -24, 0, 40)
labelsBtn.Position = UDim2.new(0, 12, 0, 94)
labelsBtn.BackgroundColor3 = Color3.fromRGB(58, 58, 70)
labelsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
labelsBtn.Font = Enum.Font.GothamBold
labelsBtn.TextSize = 16
labelsBtn.Text = "Pad Labels"
labelsBtn.Parent = settingsPanel

local trapsBtn = Instance.new("TextButton")
trapsBtn.Size = UDim2.new(1, -24, 0, 40)
trapsBtn.Position = UDim2.new(0, 12, 0, 140)
trapsBtn.BackgroundColor3 = Color3.fromRGB(58, 58, 70)
trapsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
trapsBtn.Font = Enum.Font.GothamBold
trapsBtn.TextSize = 16
trapsBtn.Text = "Traps"
trapsBtn.Parent = settingsPanel

local randomizeBtn = Instance.new("TextButton")
randomizeBtn.Size = UDim2.new(1, -24, 0, 40)
randomizeBtn.Position = UDim2.new(0, 12, 0, 186)
randomizeBtn.BackgroundColor3 = Color3.fromRGB(90, 120, 200)
randomizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
randomizeBtn.Font = Enum.Font.GothamBold
randomizeBtn.TextSize = 16
randomizeBtn.Text = "Randomize + Traps"
randomizeBtn.Parent = settingsPanel

local resetLayoutBtn = Instance.new("TextButton")
resetLayoutBtn.Size = UDim2.new(1, -24, 0, 40)
resetLayoutBtn.Position = UDim2.new(0, 12, 0, 232)
resetLayoutBtn.BackgroundColor3 = Color3.fromRGB(70, 100, 150)
resetLayoutBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetLayoutBtn.Font = Enum.Font.GothamBold
resetLayoutBtn.TextSize = 16
resetLayoutBtn.Text = "Reset Initial Layout"
resetLayoutBtn.Parent = settingsPanel

local bpmTitle = Instance.new("TextLabel")
bpmTitle.Size = UDim2.new(1, -24, 0, 24)
bpmTitle.Position = UDim2.new(0, 12, 0, 286)
bpmTitle.BackgroundTransparency = 1
bpmTitle.TextXAlignment = Enum.TextXAlignment.Left
bpmTitle.TextColor3 = Color3.fromRGB(225, 225, 225)
bpmTitle.Font = Enum.Font.Gotham
bpmTitle.TextSize = 16
bpmTitle.Text = "BPM"
bpmTitle.Parent = settingsPanel

local bpmMinusBtn = Instance.new("TextButton")
bpmMinusBtn.Size = UDim2.new(0, 44, 0, 38)
bpmMinusBtn.Position = UDim2.new(0, 12, 0, 316)
bpmMinusBtn.BackgroundColor3 = Color3.fromRGB(58, 58, 70)
bpmMinusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
bpmMinusBtn.Font = Enum.Font.GothamBold
bpmMinusBtn.TextSize = 20
bpmMinusBtn.Text = "-"
bpmMinusBtn.Parent = settingsPanel

local bpmValueLabel = Instance.new("TextLabel")
bpmValueLabel.Size = UDim2.new(0, 110, 0, 38)
bpmValueLabel.Position = UDim2.new(0, 64, 0, 316)
bpmValueLabel.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
bpmValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
bpmValueLabel.Font = Enum.Font.GothamBold
bpmValueLabel.TextSize = 20
bpmValueLabel.Text = "100"
bpmValueLabel.Parent = settingsPanel

local bpmPlusBtn = Instance.new("TextButton")
bpmPlusBtn.Size = UDim2.new(0, 44, 0, 38)
bpmPlusBtn.Position = UDim2.new(0, 182, 0, 316)
bpmPlusBtn.BackgroundColor3 = Color3.fromRGB(58, 58, 70)
bpmPlusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
bpmPlusBtn.Font = Enum.Font.GothamBold
bpmPlusBtn.TextSize = 20
bpmPlusBtn.Text = "+"
bpmPlusBtn.Parent = settingsPanel

local panelStroke = Instance.new("UIStroke")
panelStroke.Thickness = 1
panelStroke.Color = Color3.fromRGB(255, 255, 255)
panelStroke.Transparency = 0.5
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -56, 0, 34)
title.Position = UDim2.new(0, 14, 0, 8)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.Text = "Loop Control"
title.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(66, 66, 76)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = panel

local volumeLabel = Instance.new("TextLabel")
volumeLabel.Size = UDim2.new(1, -28, 0, 24)
volumeLabel.Position = UDim2.new(0, 14, 0, 54)
volumeLabel.BackgroundTransparency = 1
volumeLabel.TextXAlignment = Enum.TextXAlignment.Left
volumeLabel.TextColor3 = Color3.fromRGB(225, 225, 225)
volumeLabel.Font = Enum.Font.Gotham
volumeLabel.TextSize = 17
volumeLabel.Text = "Volume"
volumeLabel.Parent = panel

local sliderTrack = Instance.new("Frame")
sliderTrack.Size = UDim2.new(1, -28, 0, 12)
sliderTrack.Position = UDim2.new(0, 14, 0, 84)
sliderTrack.BackgroundColor3 = Color3.fromRGB(65, 65, 72)
sliderTrack.BorderSizePixel = 0
sliderTrack.Parent = panel

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.8, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(80, 170, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderTrack

local sliderKnob = Instance.new("Frame")
sliderKnob.Size = UDim2.new(0, 14, 0, 20)
sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
sliderKnob.Position = UDim2.new(0.8, 0, 0.5, 0)
sliderKnob.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
sliderKnob.BorderSizePixel = 0
sliderKnob.Parent = sliderTrack

local sliderButton = Instance.new("TextButton")
sliderButton.Size = UDim2.new(1, 0, 1, 0)
sliderButton.BackgroundTransparency = 1
sliderButton.Text = ""
sliderButton.Parent = sliderTrack

local soloButton = Instance.new("TextButton")
soloButton.Size = UDim2.new(1, -28, 0, 46)
soloButton.Position = UDim2.new(0, 14, 0, 120)
soloButton.BackgroundColor3 = Color3.fromRGB(58, 58, 70)
soloButton.TextColor3 = Color3.fromRGB(255, 255, 255)
soloButton.Font = Enum.Font.GothamBold
soloButton.TextSize = 18
soloButton.Text = "Solo"
soloButton.Parent = panel

local selectedLoop: string? = nil
local draggingSlider = false

local function clamp01(v: number): number
	return math.clamp(v, 0, 1)
end

local function loopVolume(loopName: string): number
	return clamp01(workspace:GetAttribute("LoopVolume_" .. loopName) or 0.8)
end

local function refreshControlPanel()
	if not selectedLoop then
		return
	end
	title.Text = string.format("%s Control", selectedLoop)

	local vol = loopVolume(selectedLoop)
	volumeLabel.Text = string.format("Volume: %d%%", math.floor(vol * 100 + 0.5))
	sliderFill.Size = UDim2.new(vol, 0, 1, 0)
	sliderKnob.Position = UDim2.new(vol, 0, 0.5, 0)

	local soloLoop = workspace:GetAttribute("SoloLoop")
	if soloLoop == selectedLoop then
		soloButton.Text = "Solo ON (click to clear)"
		soloButton.BackgroundColor3 = Color3.fromRGB(255, 170, 60)
	elseif soloLoop == "" or soloLoop == nil then
		soloButton.Text = "Solo THIS Loop"
		soloButton.BackgroundColor3 = Color3.fromRGB(58, 58, 70)
	else
		soloButton.Text = string.format("Solo THIS Loop (now: %s)", tostring(soloLoop))
		soloButton.BackgroundColor3 = Color3.fromRGB(85, 85, 98)
	end
end

local function refreshSettingsPanel()
	local bpm = math.floor((workspace:GetAttribute("BPM") or 100) + 0.5)
	bpmValueLabel.Text = tostring(bpm)

	local autoMix = workspace:GetAttribute("AutoMix") == true
	if autoMix then
		autoMixBtn.Text = "Auto-Mix: ON"
		autoMixBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 60)
	else
		autoMixBtn.Text = "Auto-Mix: OFF"
		autoMixBtn.BackgroundColor3 = Color3.fromRGB(58, 58, 70)
	end

	local showLabels = workspace:GetAttribute("ShowPadLabels") == true
	if showLabels then
		labelsBtn.Text = "Pad Labels: ON"
		labelsBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 60)
	else
		labelsBtn.Text = "Pad Labels: OFF"
		labelsBtn.BackgroundColor3 = Color3.fromRGB(58, 58, 70)
	end

	local trapsEnabled = workspace:GetAttribute("TrapsEnabled") ~= false
	local trapsOnPads = workspace:GetAttribute("TrapsOnPads") == true
	trapsBtn.Visible = trapsOnPads
	if trapsOnPads and trapsEnabled then
		trapsBtn.Text = "Traps: ON"
		trapsBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 60)
	elseif trapsOnPads then
		trapsBtn.Text = "Traps: OFF"
		trapsBtn.BackgroundColor3 = Color3.fromRGB(58, 58, 70)
	else
		trapsBtn.Text = "Traps"
		trapsBtn.BackgroundColor3 = Color3.fromRGB(58, 58, 70)
	end
end

local function setSelectedLoop(loopName: string)
	selectedLoop = loopName
	panel.Visible = true
	refreshControlPanel()
end

local function setSliderByScreenX(screenX: number, fireServer: boolean)
	if not selectedLoop then
		return
	end
	local left = sliderTrack.AbsolutePosition.X
	local width = sliderTrack.AbsoluteSize.X
	if width <= 0 then
		return
	end
	local alpha = clamp01((screenX - left) / width)
	volumeLabel.Text = string.format("Volume: %d%%", math.floor(alpha * 100 + 0.5))
	sliderFill.Size = UDim2.new(alpha, 0, 1, 0)
	sliderKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
	if fireServer then
		controlEvent:FireServer("SetVolume", selectedLoop, alpha)
	end
end

closeBtn.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

openSettingsBtn.MouseButton1Click:Connect(function()
	settingsPanel.Visible = not settingsPanel.Visible
	refreshSettingsPanel()
end)

settingsCloseBtn.MouseButton1Click:Connect(function()
	settingsPanel.Visible = false
end)

autoMixBtn.MouseButton1Click:Connect(function()
	local nextValue = not (workspace:GetAttribute("AutoMix") == true)
	controlEvent:FireServer("SetAutoMix", nil, nextValue and 1 or 0)
end)

labelsBtn.MouseButton1Click:Connect(function()
	local nextValue = not (workspace:GetAttribute("ShowPadLabels") == true)
	controlEvent:FireServer("SetShowPadLabels", nil, nextValue and 1 or 0)
end)

trapsBtn.MouseButton1Click:Connect(function()
	local nextValue = workspace:GetAttribute("TrapsEnabled") == false
	controlEvent:FireServer("SetTrapsEnabled", nil, nextValue and 1 or 0)
end)

randomizeBtn.MouseButton1Click:Connect(function()
	controlEvent:FireServer("RandomizeWithTraps", nil, 1)
end)

resetLayoutBtn.MouseButton1Click:Connect(function()
	controlEvent:FireServer("ResetInitialLayout", nil, 1)
end)

bpmMinusBtn.MouseButton1Click:Connect(function()
	local bpm = math.floor((workspace:GetAttribute("BPM") or 100) + 0.5)
	local nextBpm = math.clamp(bpm - 5, 60, 180)
	controlEvent:FireServer("SetBPM", nil, nextBpm)
end)

bpmPlusBtn.MouseButton1Click:Connect(function()
	local bpm = math.floor((workspace:GetAttribute("BPM") or 100) + 0.5)
	local nextBpm = math.clamp(bpm + 5, 60, 180)
	controlEvent:FireServer("SetBPM", nil, nextBpm)
end)

soloButton.MouseButton1Click:Connect(function()
	if not selectedLoop then
		return
	end
	controlEvent:FireServer("ToggleSolo", selectedLoop)
end)

sliderButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSlider = true
		setSliderByScreenX(input.Position.X, true)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
		setSliderByScreenX(input.Position.X, true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSlider = false
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	local target = mouse.Target
	if not target or not target:IsA("BasePart") then
		return
	end
	local padsFolder = workspace:FindFirstChild("Pads")
	if not padsFolder or not target:IsDescendantOf(padsFolder) then
		return
	end

	local loopName = target:GetAttribute("Loop")
	if type(loopName) == "string" and table.find(LOOP_ORDER, loopName) then
		setSelectedLoop(loopName)
	end
end)

workspace:GetAttributeChangedSignal("SoloLoop"):Connect(refreshControlPanel)
workspace:GetAttributeChangedSignal("AutoMix"):Connect(refreshSettingsPanel)
workspace:GetAttributeChangedSignal("BPM"):Connect(refreshSettingsPanel)
workspace:GetAttributeChangedSignal("ShowPadLabels"):Connect(refreshSettingsPanel)
workspace:GetAttributeChangedSignal("TrapsEnabled"):Connect(refreshSettingsPanel)
workspace:GetAttributeChangedSignal("TrapsOnPads"):Connect(refreshSettingsPanel)
for _, name in ipairs(LOOP_ORDER) do
	workspace:GetAttributeChangedSignal("LoopVolume_" .. name):Connect(refreshControlPanel)
end

refreshSettingsPanel()
