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
mainFrame.Draggable = true -- bisa digeser
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

--== Isi GUI ==--
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 180, 0, 50)
button.Position = UDim2.new(0.5, -90, 0.5, -25)
button.BackgroundColor3 = Color3.fromRGB(90, 70, 255)
button.Text = "tekan me"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextSize = 20
button.Font = Enum.Font.GothamBold
button.AutoButtonColor = false
button.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 12)
btnCorner.Parent = button

local btnGradient = Instance.new("UIGradient")
btnGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 70, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 100, 255))
}
btnGradient.Rotation = 45
btnGradient.Parent = button

--== Text Box Key ==--
local keyTextBox = Instance.new("TextBox")
keyTextBox.Size = UDim2.new(0, 180, 0, 30)
keyTextBox.Position = UDim2.new(0.5, -90, 0.2, -15)
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

--== Key Validation ==--
local validKey = "wilzu23" -- Ganti dengan key yang valid
local hasKey = false

local function validateKey()
	if keyTextBox.Text == validKey then
		hasKey = true
		keyTextBox:Destroy()
		print("Key Valid!")
		-- Tambahin fungsi setelah key valid di sini
	else
		print("Key Invalid!")
	end
end

keyTextBox.FocusLost:Connect(validateKey)

--== Auto Perfect Fish It ==--
local fishingService = game:GetService("ReplicatedStorage"):WaitForChild("FishingService")

local function autoPerfectFish()
	if not hasKey then return end -- Cek apakah key valid
	
	local mouse = player:GetMouse()
	local buttonDown = false
	
	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessedEvent then
			buttonDown = true
			while buttonDown and hasKey do
				fishingService.PerfectCatch:FireServer()
				wait(0.05) -- Sesuaikan delay jika perlu
			end
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			buttonDown = false
		end
	end)
end

autoPerfectFish()

--== Animasi Button ==--
local function tween(obj, info, props)
	TweenService:Create(obj, info, props):Play()
end

button.MouseEnter:Connect(function()
	tween(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, 190, 0, 55)
	})
end)

button.MouseLeave:Connect(function()
	tween(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, 180, 0, 50)
	})
end)

button.MouseButton1Click:Connect(function()
	print("Tombol modern ditekan!")
end)

--== Fitur Hide/Show ==--
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
			BackgroundTransparency = 0.05
		})
		isHidden = false
	end
end)
