local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

--== GUI Container ==--
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ModernDraggableUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

--== Frame Utama ==--
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 200)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

--== Shadow ==--
local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.Position = UDim2.new(0, -10, 0, -10)
shadow.Image = "rbxassetid://1316045217"
shadow.ImageTransparency = 0.4
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.Parent = mainFrame

--== UI Corner ==--
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

--== Judul Bar ==--
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Text = "wilzu vip 3.0.0"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 15, 0, 0)
title.Size = UDim2.new(1, -50, 1, 0)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

--== Tombol Hide ==--
local hideButton = Instance.new("TextButton")
hideButton.Size = UDim2.new(0, 35, 0, 35)
hideButton.Position = UDim2.new(1, -40, 0, 0)
hideButton.BackgroundTransparency = 1
hideButton.Text = "−"
hideButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hideButton.Font = Enum.Font.GothamBold
hideButton.TextSize = 22
hideButton.Parent = titleBar

--== Input Key ==--
local keyTextBox = Instance.new("TextBox")
keyTextBox.Size = UDim2.new(0, 180, 0, 30)
keyTextBox.Position = UDim2.new(0.5, -90, 0.5, -15)
keyTextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
keyTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
keyTextBox.Font = Enum.Font.Gotham
keyTextBox.TextSize = 16
keyTextBox.PlaceholderText = "Masukkan Key"
keyTextBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
keyTextBox.BorderSizePixel = 0
keyTextBox.Parent = mainFrame

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 8)
keyCorner.Parent = keyTextBox

--== Variabel Validasi ==--
local validKey = "wilzu23"
local hasKey = false
local autoOn = false

--== Tombol Auto Perfect (awal: disembunyikan) ==--
local autoButton = Instance.new("TextButton")
autoButton.Size = UDim2.new(0, 200, 0, 50)
autoButton.Position = UDim2.new(0.5, -100, 0.5, -25)
autoButton.BackgroundColor3 = Color3.fromRGB(90, 70, 255)
autoButton.Text = "Auto Perfect: OFF"
autoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
autoButton.TextSize = 18
autoButton.Font = Enum.Font.GothamBold
autoButton.Visible = false
autoButton.Parent = mainFrame

local autoCorner = Instance.new("UICorner")
autoCorner.CornerRadius = UDim.new(0, 12)
autoCorner.Parent = autoButton

local btnGradient = Instance.new("UIGradient")
btnGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 70, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 100, 255))
}
btnGradient.Rotation = 45
btnGradient.Parent = autoButton

--== Tween helper ==--
local function tween(obj, info, props)
	TweenService:Create(obj, info, props):Play()
end

--== Validasi Key ==--
local function validateKey()
	if keyTextBox.Text == validKey then
		hasKey = true
		print("✅ Key Valid!")
		tween(keyTextBox, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {Transparency = 1})
		wait(0.3)
		keyTextBox:Destroy()
		autoButton.Visible = true
	else
		print("❌ Key Invalid!")
	end
end

keyTextBox.FocusLost:Connect(validateKey)

--== Sistem Auto Perfect Fish It ==--
local fishingService = game:GetService("ReplicatedStorage"):WaitForChild("FishingService")

autoButton.MouseButton1Click:Connect(function()
	if not hasKey then return end
	autoOn = not autoOn
	autoButton.Text = autoOn and "Auto Perfect: ON" or "Auto Perfect: OFF"
	print("Auto Perfect:", autoOn)

	task.spawn(function()
		while autoOn and hasKey do
			fishingService.PerfectCatch:FireServer()
			wait(0.05)
		end
	end)
end)

--== Hover Animation Tombol ==--
autoButton.MouseEnter:Connect(function()
	tween(autoButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 210, 0, 55)})
end)
autoButton.MouseLeave:Connect(function()
	tween(autoButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 200, 0, 50)})
end)

--== Hide/Show GUI ==--
local isHidden = false
local tweenTime = 0.3

hideButton.MouseButton1Click:Connect(function()
	if not isHidden then
		isHidden = true
		tween(mainFrame, TweenInfo.new(tweenTime, Enum.EasingStyle.Sine), {
			Position = mainFrame.Position + UDim2.new(0, 0, 0, 250),
			BackgroundTransparency = 1
		})
		wait(tweenTime)
		mainFrame.Visible = false
	else
		mainFrame.Visible = true
		tween(mainFrame, TweenInfo.new(tweenTime, Enum.EasingStyle.Sine), {
			Position = UDim2.new(0.5, -150, 0.5, -100),
			BackgroundTransparency = 0
		})
		isHidden = false
	end
end)
