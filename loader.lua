-- loader.lua
-- Map PlaceId -> exploit/local raw URLs, then fetch & run appropriate scripts.
-- Usage (exploit): loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/loader.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PLACE_ID = game.PlaceId

-- ====== CONFIG: tambahkan mapping PlaceId => { exploit=..., local=... } ======
local games = {
    -- contoh format:
    -- [123456789] = { exploit = "https://raw.githubusercontent.com/YourUser/Repo/main/ExploitScript.lua",
    --                 local   = "https://raw.githubusercontent.com/YourUser/Repo/main/LocalScript.lua" },

    [12126484163267681] = { exploit = "https://raw.githubusercontent.com/MajestySkie/DIG/refs/heads/main/DigDigDig.lua", local = "https://raw.githubusercontent.com/MajestySkie/DIG/refs/heads/main/DigDigDig.lua" },
    [129827112113663]  = { exploit = "https://raw.githubusercontent.com/MajestySkie/Prospecting/refs/heads/main/Prsctng.lua", local = "https://raw.githubusercontent.com/MajestySkie/Prospecting/refs/heads/main/Prsctng.lua" },
    -- tambahkan entri kamu sendiri di sini...
}
-- ==========================================================================

local entry = games[PLACE_ID]

local function safeGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and type(res) == "string" and #res > 0 then
        return res
    else
        return nil, ("HttpGet gagal: %s (ok=%s)"):format(tostring(url), tostring(ok))
    end
end

if not entry then
    warn(("Loader: PlaceId %d tidak ada di daftar games.").format and (("Loader: PlaceId %d tidak ada di daftar games."):format(PLACE_ID)) or ("Loader: PlaceId "..tostring(PLACE_ID).." tidak ada di daftar games."))
    return
end

-- 1) jalankan exploit script (jika ada)
if entry.exploit and entry.exploit ~= "" then
    local exploitCode, err = safeGet(entry.exploit)
    if not exploitCode then
        warn("Loader: gagal ambil exploit script - ".. tostring(err))
    else
        local ok, e = pcall(function() loadstring(exploitCode)() end)
        if not ok then
            warn("Loader: gagal eksekusi exploit script: ".. tostring(e))
        else
            print("Loader: exploit script dijalankan.")
        end
    end
end

-- 2) deploy local script ke PlayerGui (coba) atau jalankan fallback loadstring
if entry.local and entry.local ~= "" then
    local localCode, err2 = safeGet(entry.local)
    if not localCode then
        warn("Loader: gagal ambil local script - ".. tostring(err2))
    else
        local function tryCreateLocalScript(code)
            if not LocalPlayer then return false, "No LocalPlayer" end
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if not pg then return false, "No PlayerGui" end

            -- hapus instance lama jika ada
            local existing = pg:FindFirstChild("AutoLocalScript")
            if existing then
                pcall(function() existing:Destroy() end)
            end

            local ls = Instance.new("LocalScript")
            ls.Name = "AutoLocalScript"
            -- beberapa exploit/mode mengijinkan set Source
            local sOk, sErr = pcall(function() ls.Source = code end)
            if not sOk then
                -- fallback wrapper yang mem-HttpGet isi (lebih stabil di beberapa exploit)
                ls.Source = ("local ok, code = pcall(function() return %q end)\nif ok and code then local f = loadstring(code) if f then f() end end"):format(code)
            end
            ls.Parent = pg
            return true
        end

        local ok, res = pcall(function() return tryCreateLocalScript(localCode) end)
        if ok and res then
            print("Loader: LocalScript dibuat di PlayerGui.")
        else
            -- fallback: coba jalankan local code langsung (beberapa exploit environment bisa menjalankan)
            local fOk, fErr = pcall(function() loadstring(localCode)() end)
            if fOk then
                print("Loader: Local script dijalankan via loadstring() fallback.")
            else
                warn("Loader: gagal deploy/jalankan local script: ".. tostring(fErr or res))
            end
        end
    end
end

print("Loader: selesai.")
