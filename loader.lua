-- simple_pair_loader.lua
-- Jalankan exploit script lalu deploy LocalScript dari 2 raw URL yang kamu punya.
-- Usage: loadstring(game:HttpGet("<raw loader url>"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local EXPLOIT_URL = "https://raw.githubusercontent.com/wilzuXyzChv/datatele/refs/heads/main/FishingAuto_Exploit.lua"
local LOCAL_URL   = "https://raw.githubusercontent.com/wilzuXyzChv/datatele/refs/heads/main/FishingAuto_Local.lua"

local function safeGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and type(res) == "string" and #res > 0 then
        return res
    end
    return nil, ("HttpGet failed: %s"):format(tostring(url))
end

-- 1) ambil & jalankan exploit script
do
    local code, err = safeGet(EXPLOIT_URL)
    if not code then
        warn("Loader: gagal ambil Exploit -> ".. tostring(err))
    else
        local ok, e = pcall(function() loadstring(code)() end)
        if ok then
            print("Loader: Exploit script dijalankan.")
        else
            warn("Loader: Exploit script error -> ".. tostring(e))
        end
    end
end

-- 2) ambil & deploy Local script ke PlayerGui (coba buat LocalScript)
do
    local code, err = safeGet(LOCAL_URL)
    if not code then
        warn("Loader: gagal ambil Local -> ".. tostring(err))
    else
        local function tryCreateLocal(codeStr)
            if not LocalPlayer then return false, "No LocalPlayer" end
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if not pg then return false, "No PlayerGui" end

            local existing = pg:FindFirstChild("FishingAuto_Local_Instance")
            if existing then
                pcall(function() existing:Destroy() end)
            end

            local ls = Instance.new("LocalScript")
            ls.Name = "FishingAuto_Local_Instance"

            local sOk, sErr = pcall(function() ls.Source = codeStr end)
            if not sOk then
                -- fallback: embed code in a small loader wrapper
                ls.Source = ("local f = loadstring(%q) if f then f() end"):format(codeStr)
            end

            ls.Parent = pg
            return true
        end

        local ok, res = pcall(function() return tryCreateLocal(code) end)
        if ok and res then
            print("Loader: LocalScript dibuat di PlayerGui.")
        else
            -- fallback: jalankan langsung (beberapa exploit environment mengizinkan)
            local fOk, fErr = pcall(function() loadstring(code)() end)
            if fOk then
                print("Loader: Local script dijalankan via loadstring() fallback.")
            else
                warn("Loader: gagal deploy/jalankan local script -> ".. tostring(fErr or res))
            end
        end
    end
end

print("Loader: selesai.")
