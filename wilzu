-- Script Fish It! Roblox untuk Delta Executor
-- Dibuat oleh Danxy-AI, Tools V8.4

-- KONFIGURASI
local autoRebirth = true  -- Otomatis Rebirth? (true/false)
local autoFish = true     -- Otomatis Mancing? (true/false)
local sellInterval = 5     -- Interval penjualan ikan (detik)
local requiredKey = "wilzu22" -- Key yang dibutuhkan untuk menjalankan script

-- FUNGSI UNTUK MEMERIKSA KEY
local function checkKey()
    local input = game:GetService("UserInputService")
    local gui = Instance.new("ScreenGui")
    gui.Parent = game.Players.LocalPlayer.PlayerGui
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.5, 0, 0.3, 0)
    frame.Position = UDim2.new(0.25, 0, 0.35, 0)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.Parent = gui
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.8, 0, 0.3, 0)
    textBox.Position = UDim2.new(0.1, 0, 0.1, 0)
    textBox.PlaceholderText = "Masukkan Key Anda"
    textBox.Parent = frame
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.8, 0, 0.3, 0)
    button.Position = UDim2.new(0.1, 0, 0.5, 0)
    button.Text = "Verifikasi"
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    button.Parent = frame

    button.MouseButton1Click:Connect(function()
        if textBox.Text == requiredKey then
            gui:Destroy()
            print("Key Benar, Script Dimulai!")
            return true
        else
            textBox.Text = ""
            textBox.PlaceholderText = "Key Salah, Coba Lagi!"
            return false
        end
    end)

    repeat wait() until gui:FindFirstChild("Frame") == nil
end

-- Fungsi Utama
local function jualIkan()
    game:GetService("ReplicatedStorage").RemoteEvents.SellFish:FireServer()
    print("Ikan berhasil dijual!")
end

local function rebirth()
    game:GetService("ReplicatedStorage").RemoteEvents.Rebirth:FireServer()
    print("Rebirth berhasil dilakukan!")
end

local function mancingOtomatis()
    while autoFish do
        game:GetService("ReplicatedStorage").RemoteEvents.StartFishing:FireServer()
        wait(5) -- Sesuaikan dengan waktu yang dibutuhkan untuk mancing
        game:GetService("ReplicatedStorage").RemoteEvents.StopFishing:FireServer()
        wait(1)
    end
end

-- CEK KEY SEBELUM MENJALANKAN SCRIPT
if checkKey() then
    -- Loop Utama
    while true do
        wait(sellInterval)
        jualIkan()

        if autoRebirth then
            rebirth()
        end
    end

    -- Aktifkan Mancing Otomatis
    if autoFish then
        mancingOtomatis()
    end

    print("Script Fish It! Dimulai oleh Danxy-AI, Tools V8.4")
else
    print("Key Salah, Script Tidak Dijalankan!")
end
