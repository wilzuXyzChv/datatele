-- Wilzu Full GUI v1.1 (LocalScript) - Customized + Configurable
-- Gabungan GUI modern + fitur aktif (Auto Fish, Auto Farm, Teleport, Rejoin, Close)
-- EDIT CONFIG di bawah sesuai game kamu

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =========================
-- CONFIG — EDITABLE
-- =========================
local CONFIG = {
	-- RemoteEvent common names (game-specific). Isi nama sesuai struktur game-mu
	remoteEvents = {
		StartFishing = "StartFishing",   -- e.g. in ReplicatedStorage.RemoteEvents.StartFishing
		StopFishing  = "StopFishing",
		SellFish     = "SellFish",
		Rebirth      = "Rebirth",
		Heartbeat    = "Heartbeat",
		CollectNames = {"Collect", "CollectCrop", "Harvest", "CollectItem"} -- for AutoFarm lookup
	},

	-- AutoFish / AutoFarm timing (seconds)
	autoFish = {
		loopWaitMin = 2,
		loopWaitMax = 6,
		detectWait = 4,   -- waktu tunggu setelah start fishing untuk deteksi ikan
	},

	autoFarm = {
		searchRadius = 80,
		retryDelay = 2,
	},

	-- Deteksi threshold default (jika fungsi deteksiIkan mengembalikan nilai confidence)
	detectionThreshold = 0.9,

	-- Teleport locations: kamu bisa tambahkan nama => Vector3 atau mencari objek workspace
	teleportLocations = {
		Spawn = nil, -- nil = gunakan fallback mencari SpawnLocation / Spawn
		Shop  = nil, -- nil = cari model "Shop" / "Store" di workspace
		Ocean = nil, -- nil = cari "Ocean" / "Water" atau fallback position
		-- contoh custom: ["Island"] = Vector3.new(100, 10, -200)
	},
}

-- =========================
-- UTILITIES
-- =========================
local function safeCall(fn, ...)
	if type(fn) ~= "function" then return false end
	local ok, res = pcall(fn, ...)
	return ok, res
end

local function findRemoteEventByName(name)
	-- tries ReplicatedStorage.RemoteEvents.<name> or direct ReplicatedStorage.<name>
	local rv
	pcall(function()
		if ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild(name) then
			rv = ReplicatedStorage.RemoteEvents:FindFirstChild(name)
		elseif ReplicatedStorage:FindFirstChild(name) then
			rv = ReplicatedStorage:FindFirstChild(name)
		end
	end)
	return rv
end

local function fireRemoteIfExists(name, ...)
	local ev = findRemoteEventByName(name)
	if ev and ev.FireServer then
		pcall(function() ev:FireServer(...) end)
		return true
	end
	return false
end

-- =========================
-- GUI & UX (drag, hover, fade, autosave)
-- =========================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WilzuFullGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 340, 0, 220)
mainFrame.Position = UDim2.new(0.5, -170, 0.5, -110)
mainFrame.BackgroundColor3 = Color3.fromRGB(60,60,60)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.05
mainFrame.Parent = screenGui

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(150,150,150)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(210,210,210)),
}
gradient.Rotation = 30
gradient.Parent = mainFrame

local corner = Instance.new("UICorner", mainFrame)
corner.CornerRadius = UDim.new(0, 12)

local shadow = Instance.new("ImageLabel")
shadow.Image = "rbxassetid://1316045217"
shadow.ImageTransparency = 0.55
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10,10,118,118)
shadow.Size = UDim2.new(1, 24, 1, 24)
shadow.Position = UDim2.new(0, -12, 0, -12)
shadow.ZIndex = 0
shadow.BackgroundTransparency = 1
shadow.Parent = mainFrame

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 36)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundTransparency = 1
header.Text = "🩶 Wilzu Full Control v1.1"
header.TextColor3 = Color3.fromRGB(245,245,245)
header.Font = Enum.Font.GothamBold
header.TextSize = 16
header.TextXAlignment = Enum.TextXAlignment.Left
header.RichText = false
header.Parent = mainFrame
header.PaddingLeft = UDim.new(0, 10)
header.ZIndex = 2

-- helper create button
local function createButton(label, y)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9, 0, 0.16, 0)
	btn.Position = UDim2.new(0.05, 0, y, 0)
	btn.BackgroundColor3 = Color3.fromRGB(95,95,95)
	btn.TextColor3 = Color3.fromRGB(245,245,245)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 14
	btn.Text = label
	btn.AutoButtonColor = true
	btn.BorderSizePixel = 0
	btn.Parent = mainFrame

	local ucorner = Instance.new("UICorner", btn)
	ucorner.CornerRadius = UDim.new(0,8)
	local stroke = Instance.new("UIStroke", btn)
	stroke.Thickness = 1
	stroke.Transparency = 0.6

	btn.MouseEnter:Connect(function()
		pcall(function() TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(130,130,130)}):Play() end)
	end)
	btn.MouseLeave:Connect(function()
		pcall(function() TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(95,95,95)}):Play() end)
	end)
	return btn
end

local btnAutoFish = createButton("🎣 Auto Perfect Fish: OFF", 0.12)
local btnAutoFarm = createButton("🌾 Auto Farm: OFF", 0.32)
local btnTeleport  = createButton("🗺️ Teleport Menu", 0.52)
local btnRejoin    = createButton("🔁 Rejoin (Instant)", 0.72)
local btnClose     = createButton("❌ Close GUI", 0.88)

-- floating show button
local floatShow = Instance.new("TextButton")
floatShow.Size = UDim2.new(0,46,0,46)
floatShow.Position = UDim2.new(0.02, 0, 0.82, 0)
floatShow.Text = "🎣"
floatShow.Font = Enum.Font.GothamBold
floatShow.TextSize = 20
floatShow.BackgroundColor3 = Color3.fromRGB(90,90,90)
floatShow.TextColor3 = Color3.fromRGB(255,255,255)
floatShow.BorderSizePixel = 0
floatShow.Visible = false
floatShow.Parent = screenGui
local fcorner = Instance.new("UICorner", floatShow)
fcorner.CornerRadius = UDim.new(1, 0)

local toggleIcon = Instance.new("TextButton")
toggleIcon.Size = UDim2.new(0, 38, 0, 28)
toggleIcon.Position = UDim2.new(1, -46, 0, 6)
toggleIcon.Text = "—"
toggleIcon.Font = Enum.Font.GothamBold
toggleIcon.TextSize = 18
toggleIcon.BackgroundColor3 = Color3.fromRGB(85,85,85)
toggleIcon.TextColor3 = Color3.fromRGB(255,255,255)
toggleIcon.BorderSizePixel = 0
toggleIcon.Parent = mainFrame
local tcorner = Instance.new("UICorner", toggleIcon)
tcorner.CornerRadius = UDim.new(0,7)

local guiVisible = true
local function setVisibility(vis)
	if vis then
		mainFrame.Visible = true
		floatShow.Visible = false
		pcall(function() TweenService:Create(mainFrame, TweenInfo.new(0.35), {BackgroundTransparency = 0.05, Size = UDim2.new(0,340,0,220)}):Play() end)
	else
		pcall(function() TweenService:Create(mainFrame, TweenInfo.new(0.28), {BackgroundTransparency = 1, Size = UDim2.new(0,120,0,38)}):Play() end)
		delay(0.28, function()
			mainFrame.Visible = false
			floatShow.Visible = true
		end)
	end
	guiVisible = vis
end

toggleIcon.MouseButton1Click:Connect(function() setVisibility(false) end)
floatShow.MouseButton1Click:Connect(function() setVisibility(true) end)

-- Dragging & autosave position
local dragging, dragStart, startPos = false, nil, nil
header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
	end
end)
header.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(
			math.clamp(startPos.X.Scale,0,1),
			startPos.X.Offset + delta.X,
			math.clamp(startPos.Y.Scale,0,1),
			startPos.Y.Offset + delta.Y
		)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if dragging then
			dragging = false
			pcall(function() player:SetAttribute("WilzuSavedPos", mainFrame.Position) end)
		end
	end
end)
task.delay(0.6, function()
	local pos = player:GetAttribute("WilzuSavedPos")
	if pos and typeof(pos) == "UDim2" then mainFrame.Position = pos end
end)

-- =========================
-- FEATURES: AutoFish, AutoFarm, Teleport, Rejoin
-- =========================

-- Auto Fish
local autoFishEnabled = false
local function callStartFishingFallback()
	-- try various ways to start fishing
	local fired = false
	-- try your global functions
	if type(_G.mancingOtomatis) == "function" then
		pcall(_G.mancingOtomatis); fired = true
	elseif type(mancingOtomatis) == "function" then
		pcall(mancingOtomatis); fired = true
	end
	-- try firing remote events
	if not fired then
		fired = fireRemoteIfExists(CONFIG.remoteEvents.StartFishing)
	end
	return fired
end

local function callStopFishingFallback()
	if type(_G.StopFishing) == "function" then pcall(_G.StopFishing) end
	fireRemoteIfExists(CONFIG.remoteEvents.StopFishing)
end

local function attemptDetectFish()
	-- prefer user-provided deteksiIkan that returns (bool, loc) or returns confidence number
	if type(deteksiIkan) == "function" then
		local ok, a, b = pcall(deteksiIkan)
		if ok then
			if type(a) == "boolean" then return a, b end
			if type(a) == "number" then return (a >= CONFIG.detectionThreshold), b end
		end
	end
	if _G and type(_G.deteksiIkan) == "function" then
		local ok, a, b = pcall(_G.deteksiIkan)
		if ok then
			if type(a) == "boolean" then return a, b end
			if type(a) == "number" then return (a >= CONFIG.detectionThreshold), b end
		end
	end
	-- fallback: always true sometimes (safe) - we return false to avoid spam
	return false, nil
end

local function doTapFallback()
	if type(tapLayarOtomatis) == "function" then pcall(tapLayarOtomatis)
	elseif _G and type(_G.tapLayarOtomatis) == "function" then pcall(_G.tapLayarOtomatis)
	else
		-- best-effort: try call space input (may not work)
		pcall(function()
			-- This is not reliable in Roblox; left as last-resort marker
		end)
	end
end

local autoFishThread
local function startAutoFish()
	if autoFishEnabled then return end
	autoFishEnabled = true
	btnAutoFish.Text = "🎣 Auto Perfect Fish: ON"
	autoFishThread = spawn(function()
		while autoFishEnabled do
			-- start fishing
			pcall(callStartFishingFallback)
			wait(CONFIG.autoFish.detectWait)

			-- detect fish
			local detected, loc = attemptDetectFish()
			if detected then
				doTapFallback()
				-- optionally sell after a while if sell available
			else
				-- try quick retry
				pcall(callStopFishingFallback)
				wait(1)
			end

			wait(math.random(CONFIG.autoFish.loopWaitMin, CONFIG.autoFish.loopWaitMax))
		end
	end)
end

local function stopAutoFish()
	autoFishEnabled = false
	btnAutoFish.Text = "🎣 Auto Perfect Fish: OFF"
end

btnAutoFish.MouseButton1Click:Connect(function()
	if not autoFishEnabled then startAutoFish() else stopAutoFish() end
end)

-- Auto Farm
local autoFarmEnabled = false
local function tryFireCollects()
	for _,n in ipairs(CONFIG.remoteEvents.CollectNames) do
		if fireRemoteIfExists(n) then return true end
	end
	return false
end

local function findNearestHarvestable(radius)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local best, bestD = nil, radius or CONFIG.autoFarm.searchRadius
	for _,obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") or (obj:IsA("Model") and obj.PrimaryPart) then
			local pos = obj:IsA("BasePart") and obj.Position or (obj.PrimaryPart and obj.PrimaryPart.Position)
			if pos then
				local d = (pos - hrp.Position).Magnitude
				if d < bestD then
					local name = obj.Name:lower()
					if string.find(name, "crop") or string.find(name, "plant") or string.find(name, "tree") or string.find(name, "harvest") or string.find(name, "farm") then
						bestD = d
						best = obj
					end
				end
			end
		end
	end
	return best
end

local autoFarmThread
local function startAutoFarm()
	if autoFarmEnabled then return end
	autoFarmEnabled = true
	btnAutoFarm.Text = "🌾 Auto Farm: ON"
	autoFarmThread = spawn(function()
		while autoFarmEnabled do
			-- try direct event
			if tryFireCollects() then wait(1); continue end

			local target = findNearestHarvestable(CONFIG.autoFarm.searchRadius)
			if target and player.Character and player.Character:FindFirstChild("Humanoid") then
				local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
				local hrp = player.Character:FindFirstChild("HumanoidRootPart")
				if humanoid and hrp then
					local dest = (target:IsA("Model") and target.PrimaryPart and target.PrimaryPart.Position) or (target.Position)
					if dest then
						pcall(function() humanoid:MoveTo(dest) end)
						local reached = humanoid.MoveToFinished:Wait()
						wait(0.4)
						-- try ProximityPrompt
						for _,d in ipairs(target:GetDescendants()) do
							if d:IsA("ProximityPrompt") then
								pcall(function() d:InputHoldBegin() end)
								wait(0.25)
								pcall(function() d:InputHoldEnd() end)
							end
						end
					end
				end
			else
				wait(CONFIG.autoFarm.retryDelay)
			end
			wait(0.5)
		end
	end)
end

local function stopAutoFarm()
	autoFarmEnabled = false
	btnAutoFarm.Text = "🌾 Auto Farm: OFF"
end

btnAutoFarm.MouseButton1Click:Connect(function()
	if not autoFarmEnabled then startAutoFarm() else stopAutoFarm() end
end)

-- Teleport Menu (editable) - create on demand
local teleportMenuOpen = false
local teleportFrame
local function createTeleportMenu()
	if teleportFrame then teleportFrame:Destroy() end
	teleportFrame = Instance.new("Frame", screenGui)
	teleportFrame.Size = UDim2.new(0, 240, 0, 170)
	teleportFrame.Position = UDim2.new(0.5, -120, 0.5, -85)
	teleportFrame.AnchorPoint = Vector2.new(0.5,0.5)
	teleportFrame.BackgroundColor3 = Color3.fromRGB(85,85,85)
	local c = Instance.new("UICorner", teleportFrame); c.CornerRadius = UDim.new(0,10)

	local ttitle = Instance.new("TextLabel", teleportFrame)
	ttitle.Size = UDim2.new(1,0,0,30); ttitle.Position = UDim2.new(0,0,0,0)
	ttitle.BackgroundTransparency = 1; ttitle.Text = "Teleport Menu"; ttitle.Font = Enum.Font.GothamBold; ttitle.TextSize = 16; ttitle.TextColor3 = Color3.fromRGB(245,245,245)

	local function addTpButton(text, callback, i)
		local b = Instance.new("TextButton", teleportFrame)
		b.Size = UDim2.new(0.9,0,0,30)
		b.Position = UDim2.new(0.05,0,0, 36 + (i-1) * 36)
		b.Text = text; b.Font = Enum.Font.Gotham; b.TextSize = 14
		b.BackgroundColor3 = Color3.fromRGB(95,95,95); b.TextColor3 = Color3.fromRGB(245,245,245)
		local u = Instance.new("UICorner", b); u.CornerRadius = UDim.new(0,8)
		b.MouseButton1Click:Connect(function() pcall(callback) end)
	end

	local i = 1
	-- Spawn
	addTpButton("Spawn", function()
		local spawnPart = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChild("Spawn")
		if spawnPart and spawnPart:IsA("BasePart") then
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				player.Character.HumanoidRootPart.CFrame = spawnPart.CFrame + Vector3.new(0,3,0)
			end
		else
			warn("Spawn not found")
		end
	end, i); i = i + 1

	-- Shop
	addTpButton("Shop", function()
		local shop = workspace:FindFirstChild("Shop") or workspace:FindFirstChild("Store")
		if shop then
			local pos
			if shop:IsA("Model") and shop.PrimaryPart then pos = shop.PrimaryPart.Position
			elseif shop:IsA("BasePart") then pos = shop.Position end
			if pos and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				player.Character.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0,3,0))
			end
		else
			warn("Shop not found")
		end
	end, i); i = i + 1

	-- Ocean
	addTpButton("Ocean", function()
		local ocean = workspace:FindFirstChild("Ocean") or workspace:FindFirstChild("Water")
		if ocean and ocean:IsA("BasePart") then
			player.Character.HumanoidRootPart.CFrame = ocean.CFrame + Vector3.new(0,3,0)
		else
			-- fallback pos example
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				player.Character.HumanoidRootPart.CFrame = CFrame.new(0,50,200)
			end
		end
	end, i); i = i + 1

	-- custom from CONFIG.teleportLocations
	for name, pos in pairs(CONFIG.teleportLocations) do
		if pos and typeof(pos) == "Vector3" then
			addTpButton(name, function()
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					player.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
				end
			end, i); i = i + 1
		end
	end

	local closeT = Instance.new("TextButton", teleportFrame)
	closeT.Size = UDim2.new(0.9,0,0,30); closeT.Position = UDim2.new(0.05,0,0, 36 + (i-1) * 36)
	closeT.Text = "Close"; closeT.Font = Enum.Font.Gotham; closeT.TextSize = 14
	closeT.BackgroundColor3 = Color3.fromRGB(120,40,40); closeT.TextColor3 = Color3.fromRGB(255,255,255)
	local uc = Instance.new("UICorner", closeT); uc.CornerRadius = UDim.new(0,8)
	closeT.MouseButton1Click:Connect(function() if teleportFrame then teleportFrame:Destroy(); teleportFrame = nil end; teleportMenuOpen = false end)
end

btnTeleport.MouseButton1Click:Connect(function()
	if teleportMenuOpen then
		if teleportFrame then teleportFrame:Destroy() end
		teleportMenuOpen = false
	else
		createTeleportMenu(); teleportMenuOpen = true
	end
end)

-- Rejoin (instant teleport to same placeId)
btnRejoin.MouseButton1Click:Connect(function()
	pcall(function() TweenService:Create(btnRejoin, TweenInfo.new(0.12), {Rotation = 5}):Play() end)
	pcall(function()
		local placeId = game.PlaceId
		TeleportService:Teleport(placeId, player)
	end)
end)

-- Close GUI & stop loops
btnClose.MouseButton1Click:Connect(function()
	autoFishEnabled = false
	autoFarmEnabled = false
	pcall(function() screenGui:Destroy() end)
end)

-- =========================
-- END: init print & keep-alive
-- =========================
print("✅ Wilzu Full GUI v1.1 loaded. Edit CONFIG at top to adapt to your game (remote event names, teleport locations, delays).")

RunService.Heartbeat:Connect(function() end)
