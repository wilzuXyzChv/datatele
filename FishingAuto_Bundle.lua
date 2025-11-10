-- FishingAuto_Bundle.lua
-- Bundle loader: fetch Exploit + Local scripts from GitHub and start them.
-- Usage (exploit): loadstring(game:HttpGet("https://raw.githubusercontent.com/wilzuXyzChv/datatele/main/FishingAuto_Bundle.lua"))()

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- EDIT: ganti jika perlu (tetap gunakan raw.githubusercontent.com path)
local BASE_RAW = "https://raw.githubusercontent.com/wilzuXyzChv/datatele/main/"
local EXPLOIT_PATH = BASE_RAW .. "FishingAuto_Exploit.lua"
local LOCAL_PATH   = BASE_RAW .. "FishingAuto_Local.lua"

local function safeGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res and #res > 0 then
        return res
    else
        return nil, ("HttpGet failed for %s (ok=%s)"):format(url, tostring(ok))
    end
end

-- fetch both scripts
local exploitCode, errE = safeGet(EXPLOIT_PATH)
local localCode,   errL = safeGet(LOCAL_PATH)

if not exploitCode then
    warn("Bundle: gagal ambil Exploit script: ".. tostring(errE))
else
    -- run exploit script in current environment (expected)
    local ok, e = pcall(function() loadstring(exploitCode)() end)
    if not ok then
        warn("Bundle: gagal load/exploit script: ".. tostring(e))
    else
        print("Bundle: Exploit script dijalankan.")
    end
end

if not localCode then
    warn("Bundle: gagal ambil Local script: ".. tostring(errL))
else
    -- Try to create a LocalScript instance in PlayerGui (preferred)
    local function tryCreateLocalScriptInstance(code)
        local ok, result = pcall(function()
            if not LocalPlayer then return false, "No LocalPlayer" end
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if not pg then return false, "No PlayerGui" end

            -- if already exist, update it
            local existing = pg:FindFirstChild("FishingAuto_Local_Instance")
            if existing then
                -- replace Source if possible
                if existing:IsA("LocalScript") then
                    -- Some exploit environments allow setting Source directly
                    pcall(function() existing:Destroy() end)
                else
                    existing:Destroy()
                end
            end

            local ls = Instance.new("LocalScript")
            ls.Name = "FishingAuto_Local_Instance"
            -- try set Source (works in many exploits)
            local sOk, sErr = pcall(function() ls.Source = code end)
            if not sOk then
                -- fallback: set as ModuleScript wrapper that runs the code
                pcall(function()
                    ls.Source = ("local f = loadstring(%q) if f then f() end"):format(code)
                end)
            end
            ls.Parent = pg
            return true
        end)
        return ok and result or (ok == false and result) or false
    end

    local created, reason = pcall(function() return tryCreateLocalScriptInstance(localCode) end)
    if created and reason then
        print("Bundle: LocalScript instance dibuat di PlayerGui.")
    else
        -- fallback: attempt to simply run Local code in current env
        local ok, e = pcall(function() loadstring(localCode)() end)
        if ok then
            print("Bundle: Local script dijalankan via loadstring() (fallback).")
        else
            warn("Bundle: gagal mengeksekusi Local script (fallback): ".. tostring(e))
        end
    end
end

print("Bundle: selesai. Jika ada masalah cek output.")
