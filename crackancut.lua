--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// SETTINGS
local Settings = {
	ShowBox = false,
	ShowLine = false,
	ShowHealth = false,
	ShowSkeleton = false,
	AimbotEnabled = false,
	ShowFov = false,
	EnemyOnly = true,
	FovRadius = 220,
	Smoothness = 0.18,
	Enabled = true,
	ChamsGlow = false,
	SpeedEnabled = false,
	SpeedMultiplier = 2,
	JumpHeightEnabled = false,
	JumpHeightMultiplier = 2,
	NoClipEnabled = false,
	PhaseEnabled = false,
	PhaseDepth = 10
}

local ESPObjects = {}
local FovCircle
local NoClipConnection
local PhaseConnection

-- Lưu trữ giá trị gốc
local OriginalWalkSpeed = 16
local OriginalJumpPower = 50
local HumanoidConnections = {}

--// SAFE GUI PARENT
local function SafeParent()
	local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if pg then return pg end
	return game:GetService("CoreGui")
end

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "NolanESP_v1.8"
gui.ResetOnSpawn = false
gui.Parent = SafeParent()

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,260,0,520)
frame.Position = UDim2.new(0.05,0,0.35,0)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.BackgroundTransparency = 1
title.Text = "Nolan v1.0.43"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.TextColor3 = Color3.new(1,1,1)

local Scroll = Instance.new("ScrollingFrame", frame)
Scroll.Size = UDim2.new(1,0,1,-35)
Scroll.Position = UDim2.new(0,0,0,35)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 6
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize = UDim2.new(0,0,0,0)

--// HOTKEY
local menuVisible = true
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	
	if input.KeyCode == Enum.KeyCode.Insert then
		menuVisible = not menuVisible
		frame.Visible = menuVisible
	elseif input.KeyCode == Enum.KeyCode.N then
		Settings.NoClipEnabled = not Settings.NoClipEnabled
		UpdateNoClip()
	elseif input.KeyCode == Enum.KeyCode.P then
		Settings.PhaseEnabled = not Settings.PhaseEnabled
		UpdatePhase()
	end
end)

--// BUTTON / SLIDER
local currentY = 0
local function nextY()
	currentY += 40
	Scroll.CanvasSize = UDim2.new(0,0,0,currentY+10)
	return currentY
end

local function CreateButton(label, default, callback)
	local y = nextY()
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1,-20,0,30)
	btn.Position = UDim2.new(0,10,0,y)
	btn.BackgroundColor3 = default and Color3.fromRGB(255,20,0) or Color3.fromRGB(60,60,60)
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.SourceSans
	btn.TextSize = 14
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Text = label .. (default and " [ON]" or " [OFF]")
	btn.Parent = Scroll

	local state = default
	btn.MouseButton1Click:Connect(function()
		state = not state
		btn.BackgroundColor3 = state and Color3.fromRGB(255,20,0) or Color3.fromRGB(60,60,60)
		btn.Text = label .. (state and " [ON]" or " [OFF]")
		callback(state)
	end)
end

local function CreateSlider(label, default, min, max, callback)
	local y = nextY()
	local sliderLabel = Instance.new("TextLabel")
	sliderLabel.Size = UDim2.new(1,-20,0,20)
	sliderLabel.Position = UDim2.new(0,10,0,y)
	sliderLabel.BackgroundTransparency = 1
	sliderLabel.TextColor3 = Color3.new(1,1,1)
	sliderLabel.Font = Enum.Font.SourceSans
	sliderLabel.TextSize = 14
	sliderLabel.Text = label..": "..default
	sliderLabel.Parent = Scroll

	local slider = Instance.new("Frame")
	slider.Size = UDim2.new(1,-20,0,8)
	slider.Position = UDim2.new(0,10,0,y+20)
	slider.BackgroundColor3 = Color3.fromRGB(50,50,50)
	slider.BorderSizePixel = 0
	slider.Parent = Scroll

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
	fill.BackgroundColor3 = Color3.fromRGB(255,20,0)
	fill.BorderSizePixel = 0
	fill.Parent = slider

	local dragging = false
	slider.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then 
			dragging = true 
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then 
			dragging = false 
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local x = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
			fill.Size = UDim2.new(x, 0, 1, 0)
			local value = math.floor(min + (max - min) * x)
			sliderLabel.Text = label..": " .. value
			callback(value)
		end
	end)
end

--// TOGGLE & SLIDER
CreateButton("Chams Glow", Settings.ChamsGlow, function(v) 
	Settings.ChamsGlow = v 
	for player, esp in pairs(ESPObjects) do
		if esp and esp.Highlight then
			esp.Highlight.Enabled = v
		end
	end
end)
CreateButton("ESP Line", Settings.ShowLine, function(v) Settings.ShowLine = v end)
CreateButton("ESP Box", Settings.ShowBox, function(v) Settings.ShowBox = v end)
CreateButton("Health Bar", Settings.ShowHealth, function(v) Settings.ShowHealth = v end)
CreateButton("Skeleton", Settings.ShowSkeleton, function(v) Settings.ShowSkeleton = v end)
CreateButton("Enemy Only", Settings.EnemyOnly, function(v) Settings.EnemyOnly = v end)
CreateButton("Aimbot", Settings.AimbotEnabled, function(v) Settings.AimbotEnabled = v end)
CreateButton("Show FOV", Settings.ShowFov, function(v) Settings.ShowFov = v end)

CreateButton("Speed Hack", Settings.SpeedEnabled, function(v) 
	Settings.SpeedEnabled = v 
	UpdateSpeed()
end)

CreateButton("Jump Height", Settings.JumpHeightEnabled, function(v) 
	Settings.JumpHeightEnabled = v 
	UpdateJumpHeight()
end)

CreateButton("NoClip (N)", Settings.NoClipEnabled, function(v) 
	Settings.NoClipEnabled = v 
	UpdateNoClip()
end)

CreateButton("Go underground (P)", Settings.PhaseEnabled, function(v) 
	Settings.PhaseEnabled = v 
	UpdatePhase()
end)

CreateSlider("FOV Radius", Settings.FovRadius, 50, 500, function(v) Settings.FovRadius = v end)
CreateSlider("Smoothness", Settings.Smoothness, 0.01, 0.5, function(v) Settings.Smoothness = v end)
CreateSlider("Speed Multiplier", Settings.SpeedMultiplier, 1, 1000, function(v) 
	Settings.SpeedMultiplier = v 
	UpdateSpeed()
end)
CreateSlider("Jump Multiplier", Settings.JumpHeightMultiplier, 1, 10, function(v) 
	Settings.JumpHeightMultiplier = v 
	UpdateJumpHeight()
end)
CreateSlider("Depth", Settings.PhaseDepth, 1, 50, function(v) 
	Settings.PhaseDepth = v 
	UpdatePhase()
end)

CreateButton("❌ Exit Script", false, function()
	Settings.Enabled = false
	
	-- Reset movement hacks
	ResetMovementHacks()
	
	-- Remove ESP
	for player, esp in pairs(ESPObjects) do
		RemoveESP(player)
	end
	
	if FovCircle then 
		FovCircle:Remove() 
	end
	gui:Destroy()
	print("[✅] Nolan ESP destroyed")
end)

--// HELPER FUNCTIONS
local function HealthColor(hp)
	if hp > 0.75 then return Color3.fromRGB(0, 255, 0)
	elseif hp > 0.5 then return Color3.fromRGB(255, 255, 0)
	elseif hp > 0.25 then return Color3.fromRGB(255, 165, 0)
	else return Color3.fromRGB(255, 0, 0)
	end
end

local function DetectRig(char)
	if char:FindFirstChild("UpperTorso") then return "R15"
	elseif char:FindFirstChild("Torso") then return "R6"
	else return "Unknown"
	end
end

local function GetBones(char, rig)
	local bones = {}
	if rig == "R6" then
		local t = char:FindFirstChild("Torso")
		local h = char:FindFirstChild("Head")
		local la = char:FindFirstChild("Left Arm")
		local ra = char:FindFirstChild("Right Arm")
		local ll = char:FindFirstChild("Left Leg")
		local rl = char:FindFirstChild("Right Leg")
		if h and t then table.insert(bones, {h, t}) end
		if t and la then table.insert(bones, {t, la}) end
		if t and ra then table.insert(bones, {t, ra}) end
		if t and ll then table.insert(bones, {t, ll}) end
		if t and rl then table.insert(bones, {t, rl}) end
	elseif rig == "R15" then
		local upper = char:FindFirstChild("UpperTorso")
		local lower = char:FindFirstChild("LowerTorso")
		local h = char:FindFirstChild("Head")
		if h and upper then table.insert(bones, {h, upper}) end
		if upper and lower then table.insert(bones, {upper, lower}) end
		
		local leftArm = char:FindFirstChild("LeftUpperArm")
		local rightArm = char:FindFirstChild("RightUpperArm")
		local leftLeg = char:FindFirstChild("LeftUpperLeg")
		local rightLeg = char:FindFirstChild("RightUpperLeg")
		
		if upper and leftArm then table.insert(bones, {upper, leftArm}) end
		if upper and rightArm then table.insert(bones, {upper, rightArm}) end
		if lower and leftLeg then table.insert(bones, {lower, leftLeg}) end
		if lower and rightLeg then table.insert(bones, {lower, rightLeg}) end
	end
	return bones
end

--// CREATE HIGHLIGHT FOR CHAMS
local function CreateChams(char)
	local highlight = Instance.new("Highlight")
	highlight.Adornee = char
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = Color3.fromRGB(0, 0, 0)
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
	highlight.OutlineTransparency = 0
	highlight.Parent = char
	highlight.Enabled = false
	
	return highlight
end

--// MOVEMENT HACKS FUNCTIONS (IMPROVED)
local function GetHumanoid()
	if not LocalPlayer.Character then return nil end
	return LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart()
	if not LocalPlayer.Character then return nil end
	return LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Torso")
end

local function UpdateSpeed()
	local humanoid = GetHumanoid()
	if not humanoid then return end
	
	if Settings.SpeedEnabled then
		-- Kiểm tra và lưu giá trị gốc
		if not OriginalWalkSpeed then
			OriginalWalkSpeed = humanoid.WalkSpeed
		end
		
		-- Áp dụng multiplier nhưng không vượt quá giới hạn an toàn
		local newSpeed = OriginalWalkSpeed * Settings.SpeedMultiplier
		if newSpeed > 1000 then
			newSpeed = 1000 -- Giới hạn tốc độ tối đa
		end
		humanoid.WalkSpeed = newSpeed
	else
		-- Reset về giá trị gốc hoặc mặc định
		humanoid.WalkSpeed = OriginalWalkSpeed or 16
	end
end

local function UpdateJumpHeight()
	local humanoid = GetHumanoid()
	if not humanoid then return end
	
	if Settings.JumpHeightEnabled then
		-- Kiểm tra và lưu giá trị gốc
		if not OriginalJumpPower then
			OriginalJumpPower = humanoid.JumpPower
		end
		
		-- Áp dụng multiplier nhưng không vượt quá giới hạn an toàn
		local newJump = OriginalJumpPower * Settings.JumpHeightMultiplier
		if newJump > 100 then
			newJump = 100 -- Giới hạn jump tối đa
		end
		humanoid.JumpPower = newJump
	else
		-- Reset về giá trị gốc hoặc mặc định
		humanoid.JumpPower = OriginalJumpPower or 50
	end
end

local function ResetMovementHacks()
	local humanoid = GetHumanoid()
	if humanoid then
		humanoid.WalkSpeed = OriginalWalkSpeed or 16
		humanoid.JumpPower = OriginalJumpPower or 50
	end
	
	if NoClipConnection then
		NoClipConnection:Disconnect()
		NoClipConnection = nil
	end
	
	if PhaseConnection then
		PhaseConnection:Disconnect()
		PhaseConnection = nil
	end
end

--// NOCLIP IMPROVED
local function UpdateNoClip()
	if NoClipConnection then
		NoClipConnection:Disconnect()
		NoClipConnection = nil
	end
	
	if Settings.NoClipEnabled then
		NoClipConnection = RunService.Stepped:Connect(function()
			if LocalPlayer.Character then
				for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
						-- Thêm physics override để tránh giật
						if part:FindFirstChildOfClass("BodyVelocity") then
							part:FindFirstChildOfClass("BodyVelocity"):Destroy()
						end
					end
				end
			end
		end)
	else
		-- Re-enable collision
		if LocalPlayer.Character then
			for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
		end
	end
end

--// ĐỘN THỔ (PHASE) FUNCTION
local function UpdatePhase()
	if PhaseConnection then
		PhaseConnection:Disconnect()
		PhaseConnection = nil
	end
	
	if Settings.PhaseEnabled then
		PhaseConnection = RunService.Stepped:Connect(function()
			local rootPart = GetRootPart()
			if not rootPart then return end
			
			-- Di chuyển nhân vật xuống dưới đất
			local currentPosition = rootPart.Position
			local newPosition = Vector3.new(
				currentPosition.X,
				currentPosition.Y - Settings.PhaseDepth,
				currentPosition.Z
			)
			
			-- Sử dụng CFrame để tránh physics conflict
			rootPart.CFrame = CFrame.new(newPosition)
			
			-- Đảm bảo không bị collision
			for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
					part.Massless = true -- Giúp di chuyển mượt hơn
				end
			end
		end)
	else
		-- Đưa nhân vật trở lại mặt đất an toàn
		local rootPart = GetRootPart()
		if rootPart then
			-- Tìm vị trí mặt đất gần nhất
			local rayOrigin = rootPart.Position + Vector3.new(0, 10, 0)
			local rayDirection = Vector3.new(0, -50, 0)
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
			raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
			
			local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
			if rayResult then
				rootPart.CFrame = CFrame.new(rayResult.Position + Vector3.new(0, 3, 0))
			end
			
			-- Khôi phục collision
			for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
					part.Massless = false
				end
			end
		end
	end
end

--// CHARACTER SETUP (IMPROVED)
local function SetupCharacter()
	task.wait(1) -- Chờ character load hoàn toàn
	
	local humanoid = GetHumanoid()
	if humanoid then
		-- Reset giá trị gốc
		OriginalWalkSpeed = humanoid.WalkSpeed
		OriginalJumpPower = humanoid.JumpPower
		
		-- Xóa connections cũ
		if HumanoidConnections[humanoid] then
			for _, conn in pairs(HumanoidConnections[humanoid]) do
				conn:Disconnect()
			end
		end
		HumanoidConnections[humanoid] = {}
		
		-- Theo dõi thay đổi để tránh bị game reset
		table.insert(HumanoidConnections[humanoid], humanoid.Changed:Connect(function()
			task.wait(0.1)
			if Settings.SpeedEnabled then
				UpdateSpeed()
			end
			if Settings.JumpHeightEnabled then
				UpdateJumpHeight()
			end
		end))
		
		-- Áp dụng lại settings
		if Settings.SpeedEnabled then
			UpdateSpeed()
		end
		if Settings.JumpHeightEnabled then
			UpdateJumpHeight()
		end
	end
	
	-- Áp dụng noclip và phase nếu đang bật
	if Settings.NoClipEnabled then
		UpdateNoClip()
	end
	if Settings.PhaseEnabled then
		UpdatePhase()
	end
end

--// ESP IMPROVED - FIXED LAG AND VISIBILITY
local lastEspCleanup = 0
local espCleanupInterval = 1 -- Cleanup mỗi giây

local function CleanupStaleESP()
	local currentTime = tick()
	if currentTime - lastEspCleanup < espCleanupInterval then
		return
	end
	lastEspCleanup = currentTime
	
	-- Ẩn ESP cho players không tồn tại hoặc không có character
	for player, esp in pairs(ESPObjects) do
		if not player or not player.Parent or player == LocalPlayer then
			RemoveESP(player)
		elseif not player.Character then
			for _, drawing in pairs(esp) do
				if typeof(drawing) == "Drawing" then
					drawing.Visible = false
				end
			end
			if esp.Highlight then
				esp.Highlight.Enabled = false
			end
		end
	end
end

--// DRAWING ESP (OPTIMIZED)
local function CreateESP(player)
	if player == LocalPlayer then return end
	if ESPObjects[player] then return end
	
	local box = Drawing.new("Square")
	box.Visible = false
	box.Filled = false
	box.Thickness = 1
	box.ZIndex = 1
	
	local line = Drawing.new("Line")
	line.Visible = false
	line.Thickness = 1
	line.ZIndex = 1
	
	local hb_bg = Drawing.new("Square")
	hb_bg.Visible = false
	hb_bg.Filled = true
	hb_bg.ZIndex = 1
	
	local hb_fg = Drawing.new("Square")
	hb_fg.Visible = false
	hb_fg.Filled = true
	hb_fg.ZIndex = 1
	
	local hb_smooth = Drawing.new("Square")
	hb_smooth.Visible = false
	hb_smooth.Filled = true
	hb_smooth.Transparency = 0.4
	hb_smooth.ZIndex = 1
	
	local skeleton = {}
	for i = 1, 12 do
		local bone = Drawing.new("Line")
		bone.Visible = false
		bone.Color = Color3.fromRGB(255, 255, 255)
		bone.Thickness = 1
		bone.ZIndex = 1
		table.insert(skeleton, bone)
	end
	
	ESPObjects[player] = {
		box = box,
		line = line, 
		hb_bg = hb_bg,
		hb_fg = hb_fg,
		hb_smooth = hb_smooth,
		skeleton = skeleton,
		healthSmooth = 1,
		rig = "Unknown",
		Highlight = nil,
		lastUpdate = 0
	}

	-- Character events với cleanup tốt hơn
	local function setupCharacterEvents(char)
		if not char or not char.Parent then
			RemoveESP(player)
			return
		end
		
		task.wait(0.5)
		
		if Settings.ChamsGlow then
			ESPObjects[player].Highlight = CreateChams(char)
		end
		
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				RemoveESP(player)
			end)
		end
	end

	player.CharacterAdded:Connect(setupCharacterEvents)
	player.CharacterRemoving:Connect(function()
		RemoveESP(player)
	end)
	
	if player.Character then
		setupCharacterEvents(player.Character)
	end
end

local function RemoveESP(player)
	if not ESPObjects[player] then return end
	
	local esp = ESPObjects[player]
	
	if esp.box then esp.box:Remove() end
	if esp.line then esp.line:Remove() end
	if esp.hb_bg then esp.hb_bg:Remove() end
	if esp.hb_fg then esp.hb_fg:Remove() end
	if esp.hb_smooth then esp.hb_smooth:Remove() end
	
	if esp.skeleton then
		for _, bone in ipairs(esp.skeleton) do
			bone:Remove()
		end
	end
	
	if esp.Highlight then
		esp.Highlight:Destroy()
	end
	
	ESPObjects[player] = nil
end

-- INITIALIZE ESP
for _, player in ipairs(Players:GetPlayers()) do
	if player ~= LocalPlayer then
		CreateESP(player)
	end
end

Players.PlayerAdded:Connect(function(player)
	if player ~= LocalPlayer then
		CreateESP(player)
	end
end)

Players.PlayerRemoving:Connect(RemoveESP)

-- Setup local player với hệ thống movement improved
LocalPlayer.CharacterAdded:Connect(SetupCharacter)
if LocalPlayer.Character then
	SetupCharacter()
end

-- FOV CIRCLE
FovCircle = Drawing.new("Circle")
FovCircle.Thickness = 1
FovCircle.Filled = false
FovCircle.Color = Color3.fromRGB(173, 255, 47)
FovCircle.Visible = false
FovCircle.Radius = Settings.FovRadius

-- GET CLOSEST ENEMY
local function GetClosestEnemy()
	local closest = nil
	local shortest = Settings.FovRadius
	local mousePos = UserInputService:GetMouseLocation()
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		if not player.Character then continue end
		
		local character = player.Character
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local head = character:FindFirstChild("Head")
		
		if not humanoid or humanoid.Health <= 0 or not head then continue end
		
		if Settings.EnemyOnly then
			if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
				continue
			end
		end
		
		local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
		if onScreen then
			local distance = (Vector2.new(headPos.X, headPos.Y) - mousePos).Magnitude
			if distance < shortest then
				shortest = distance
				closest = head
			end
		end
	end
	
	return closest
end

-- MAIN LOOP (OPTIMIZED)
local lastUpdateTime = 0
local updateInterval = 0.033 -- ~30 FPS

RunService.RenderStepped:Connect(function(deltaTime)
	if not Settings.Enabled then return end

	local currentTime = tick()
	
	-- Update FOV Circle
	FovCircle.Radius = Settings.FovRadius
	FovCircle.Position = UserInputService:GetMouseLocation()
	FovCircle.Visible = Settings.ShowFov

	-- Liên tục cập nhật speed và jump với bảo vệ
	if Settings.SpeedEnabled then
		UpdateSpeed()
	end
	
	if Settings.JumpHeightEnabled then
		UpdateJumpHeight()
	end

	-- Cleanup ESP định kỳ
	CleanupStaleESP()

	-- Update ESP với performance optimization
	if currentTime - lastUpdateTime >= updateInterval then
		for player, esp in pairs(ESPObjects) do
			if not player or player == LocalPlayer or not player.Parent then
				RemoveESP(player)
				continue
			end

			local character = player.Character
			if not character then
				for _, drawing in pairs(esp) do
					if typeof(drawing) == "Drawing" then
						drawing.Visible = false
					end
				end
				if esp.Highlight then
					esp.Highlight.Enabled = false
				end
				continue
			end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local head = character:FindFirstChild("Head")
			local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
			
			if not humanoid or humanoid.Health <= 0 or not head or not rootPart then
				for _, drawing in pairs(esp) do
					if typeof(drawing) == "Drawing" then
						drawing.Visible = false
					end
				end
				if esp.Highlight then
					esp.Highlight.Enabled = false
				end
				continue
			end

			-- Team check
			if Settings.EnemyOnly then
				if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
					for _, drawing in pairs(esp) do
						if typeof(drawing) == "Drawing" then
							drawing.Visible = false
						end
					end
					if esp.Highlight then
						esp.Highlight.Enabled = false
					end
					continue
				end
			end

			-- Detect rig
			if esp.rig == "Unknown" then
				esp.rig = DetectRig(character)
			end

			-- Calculate position với kiểm tra onScreen chính xác
			local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
			local rootPos, rootOnScreen = Camera:WorldToViewportPoint(rootPart.Position)
			
			if not headOnScreen or not rootOnScreen then
				for _, drawing in pairs(esp) do
					if typeof(drawing) == "Drawing" then
						drawing.Visible = false
					end
				end
				if esp.Highlight then
					esp.Highlight.Enabled = false
				end
				continue
			end

			-- Chỉ hiển thị ESP khi player trong tầm nhìn
			local distance = (headPos - rootPos).Magnitude
			if distance > 1000 then -- Nếu quá xa, ẩn ESP
				for _, drawing in pairs(esp) do
					if typeof(drawing) == "Drawing" then
						drawing.Visible = false
					end
				end
				continue
			end

			local height = math.abs(headPos.Y - rootPos.Y) + 10
			local width = height * 0.6
			local boxY = math.min(headPos.Y, rootPos.Y) - 5
			local boxX = rootPos.X - width / 2

			-- Box ESP
			esp.box.Visible = Settings.ShowBox
			if Settings.ShowBox then
				esp.box.Position = Vector2.new(boxX, boxY)
				esp.box.Size = Vector2.new(width, height)
				esp.box.Color = Color3.fromRGB(255, 255, 255)
			end

			-- Line ESP
			esp.line.Visible = Settings.ShowLine
			if Settings.ShowLine then
				-- esp.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                esp.line.From = Vector2.new(Camera.ViewportSize.X / 2)
				esp.line.To = Vector2.new(rootPos.X, rootPos.Y)
				esp.line.Color = Color3.fromRGB(255, 155, 255)
			end

			-- Health Bar
			if Settings.ShowHealth then
				local health = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
				esp.healthSmooth = esp.healthSmooth + (health - esp.healthSmooth) * math.clamp(5 * deltaTime, 0, 1)
				
				local barWidth = 3
				local barX = boxX - 6
				
				esp.hb_bg.Visible = true
				esp.hb_bg.Position = Vector2.new(barX, boxY)
				esp.hb_bg.Size = Vector2.new(barWidth, height)
				esp.hb_bg.Color = Color3.fromRGB(50, 50, 50)
				
				local smoothHeight = height * esp.healthSmooth
				local smoothY = boxY + (height - smoothHeight)
				esp.hb_smooth.Visible = true
				esp.hb_smooth.Position = Vector2.new(barX, smoothY)
				esp.hb_smooth.Size = Vector2.new(barWidth, smoothHeight)
				esp.hb_smooth.Color = Color3.fromRGB(100, 100, 100)
				
				local actualHeight = height * health
				local actualY = boxY + (height - actualHeight)
				esp.hb_fg.Visible = true
				esp.hb_fg.Position = Vector2.new(barX, actualY)
				esp.hb_fg.Size = Vector2.new(barWidth, actualHeight)
				esp.hb_fg.Color = HealthColor(health)
			else
				esp.hb_bg.Visible = false
				esp.hb_fg.Visible = false
				esp.hb_smooth.Visible = false
			end

			-- Skeleton ESP
			if Settings.ShowSkeleton then
				local bones = GetBones(character, esp.rig)
				for i, bone in ipairs(esp.skeleton) do
					local bonePair = bones[i]
					if bonePair and bonePair[1] and bonePair[2] then
						local pos1, vis1 = Camera:WorldToViewportPoint(bonePair[1].Position)
						local pos2, vis2 = Camera:WorldToViewportPoint(bonePair[2].Position)
						
						if vis1 and vis2 then
							bone.Visible = true
							bone.From = Vector2.new(pos1.X, pos1.Y)
							bone.To = Vector2.new(pos2.X, pos2.Y)
						else
							bone.Visible = false
						end
					else
						bone.Visible = false
					end
				end
			else
				for _, bone in ipairs(esp.skeleton) do
					bone.Visible = false
				end
			end

			-- Chams Glow
			if esp.Highlight then
				esp.Highlight.Enabled = Settings.ChamsGlow
				if Settings.ChamsGlow then
					local time = tick()
					local r = math.sin(time * 3) * 0.5 + 0.5
					local g = math.sin(time * 3 + 2) * 0.5 + 0.5
					local b = math.sin(time * 3 + 4) * 0.5 + 0.5
					esp.Highlight.OutlineColor = Color3.new(r, g, b)
				end
			elseif Settings.ChamsGlow then
				esp.Highlight = CreateChams(character)
			end
		end
		
		lastUpdateTime = currentTime
	end

	-- AIMBOT
	local aimbotActive = Settings.AimbotEnabled and (
		UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or
		UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	)
	
	if aimbotActive then
		local target = GetClosestEnemy()
		if target then
			local currentCF = Camera.CFrame
			local direction = (target.Position - currentCF.Position).Unit
			local goalCF = CFrame.new(currentCF.Position, currentCF.Position + direction)
			Camera.CFrame = currentCF:Lerp(goalCF, 1 - Settings.Smoothness)
		end
	end
end)

print("[✅] Nolan ESP loaded successfully!")
