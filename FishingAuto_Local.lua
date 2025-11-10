-- FishingAuto_Local.lua
-- LocalScript untuk StarterPlayerScripts
-- Deteksi bobber berdasarkan perubahan posisi Y (vertical velocity).
-- Menyertakan activation key (GUI + chat). REQUIRED_KEY="" untuk non-aktif.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- ======= CONFIG =======
local REQUIRED_KEY = "wilzuvTx7899"    -- isi key; kosongkan "" untuk menonaktifkan mekanisme key
local BOBBER_NAME_PATTERNS = {"bobber", "float", "fishingbobber"} -- lowercase substrings untuk mencocokkan nama part
local SEARCH_RADIUS = 80          -- stud
local VEL_THRESHOLD = -1.2        -- vertical velocity ambang (negatif = turun)
local MIN_DIP_DURATION = 0.06     -- durasi drop minimal (detik)
local PROMPT_DURATION = 3         -- waktu tunggu konfirmasi (detik)
local CONFIRM_KEY = Enum.KeyCode.W
-- =======================

-- UI kecil untuk notifikasi + key input
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FishingAutoPromptGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 420, 0, 56)
label.Position = UDim2.new(0.5, -210, 0.12, 0)
label.BackgroundTransparency = 0.25
label.BackgroundColor3 = Color3.fromRGB(20,20,20)
label.TextColor3 = Color3.fromRGB(255,255,255)
label.TextScaled = true
label.Visible = false
label.Font = Enum.Font.SourceSansBold
label.Parent = screenGui

-- Key input UI (destroy setelah valid)
local keyValid = (REQUIRED_KEY == "")
local keyFrame, keyBox
if REQUIRED_KEY ~= "" then
    keyFrame = Instance.new("Frame")
    keyFrame.Size = UDim2.new(0, 360, 0, 48)
    keyFrame.Position = UDim2.new(0.5, -180, 0.05, 0)
    keyFrame.BackgroundTransparency = 0.25
    keyFrame.Parent = screenGui

    keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(1, -10, 1, -10)
    keyBox.Position = UDim2.new(0, 5, 0, 5)
    keyBox.ClearTextOnFocus = false
    keyBox.PlaceholderText = "Masukkan key untuk mengaktifkan skrip"
    keyBox.Text = ""
    keyBox.Parent = keyFrame
end

-- Chat command /setkey <key>
player.Chatted:Connect(function(msg)
    if REQUIRED_KEY == "" then return end
    local prefix, arg = msg:match("^(%S+)%s*(.*)")
    if prefix and prefix:lower() == "/setkey" then
        if arg == REQUIRED_KEY then
            keyValid = true
            if keyFrame and keyFrame.Parent then keyFrame:Destroy() end
            warn("Key benar via chat. FishingAuto diaktifkan.")
        else
            warn("Key chat salah.")
        end
    end
end)

if keyBox then
    keyBox.FocusLost:Connect(function(enterPressed)
        if REQUIRED_KEY == "" then return end
        if keyBox.Text == REQUIRED_KEY then
            keyValid = true
            keyFrame:Destroy()
            warn("Key benar — FishingAuto diaktifkan.")
        else
            keyBox.Text = ""
            warn("Key salah.")
        end
    end)
end

-- helper: cocokkan nama bobber
local function nameMatches(name)
    if not name then return false end
    local n = name:lower()
    for _, pat in ipairs(BOBBER_NAME_PATTERNS) do
        if n:find(pat) then return true end
    end
    return false
end

-- cari bobber terdekat dari player (berdasarkan nama pattern)
local function findBobber()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local best, bestDist = nil, math.huge
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and nameMatches(obj.Name) then
            local ok, pos = pcall(function() return obj.Position end)
            if ok then
                local d = (pos - root.Position).Magnitude
                if d < bestDist and d <= SEARCH_RADIUS then
                    bestDist = d
                    best = obj
                end
            end
        end
    end
    return best
end

-- coba Activate() tool milik player (jika ada)
local function tryActivateTool()
    local tool
    if player.Character then
        for _, v in pairs(player.Character:GetChildren()) do
            if v:IsA("Tool") then tool = v break end
        end
    end
    if not tool then
        local bp = player:FindFirstChildOfClass("Backpack")
        if bp then
            for _, v in pairs(bp:GetChildren()) do
                if v:IsA("Tool") then tool = v break end
            end
        end
    end
    if tool then
        pcall(function() tool:Activate() end)
    end
end

-- monitor per-bobber: deteksi "dip" lalu prompt konfirmasi
local function monitorBobber(bobber)
    if not bobber then return end
    local lastY = bobber.Position.Y
    local dipStart = nil
    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        if not bobber or not bobber.Parent then conn:Disconnect(); return end
        local curY = bobber.Position.Y
        local vy = (curY - lastY) / dt
        lastY = curY

        if vy <= VEL_THRESHOLD then
            if not dipStart then dipStart = tick() end
            if tick() - dipStart >= MIN_DIP_DURATION then
                conn:Disconnect()
                -- cek apakah script diaktifkan via key
                if not keyValid then
                    warn("Ikan terdeteksi tapi script belum diaktifkan (masukkan key).")
                    return
                end

                label.Text = "Ikan terdeteksi! Tekan '"..CONFIRM_KEY.Name.."' untuk konfirmasi ("..PROMPT_DURATION.."s)"
                label.Visible = true
                local confirmed = false
                local started = tick()

                local inputConn
                inputConn = UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then return end
                    if input.KeyCode == CONFIRM_KEY then confirmed = true end
                end)

                while tick() - started < PROMPT_DURATION and not confirmed do
                    RunService.RenderStepped:Wait()
                end

                inputConn:Disconnect()
                label.Visible = false

                if confirmed then
                    tryActivateTool()
                    warn("Konfirmasi diterima — mencoba Activate() tool.")
                else
                    warn("Tidak ada konfirmasi — melepas ikan.")
                end

                wait(0.25)
                if bobber and bobber.Parent then
                    monitorBobber(bobber)
                end
                return
            end
        else
            dipStart = nil
        end
    end)
end

-- main loop: cari bobber dan start monitor
spawn(function()
    while true do
        local bob = findBobber()
        if bob then
            monitorBobber(bob)
            wait(0.35)
            repeat wait(0.25) until not (bob and bob.Parent)
        else
            wait(0.7)
        end
    end
end)
