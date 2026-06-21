-- MM2 Standalone Launcher (for direct execution via MCP/executor)
local tier = _G._3seventeen_tier or "free"
local isPaid = (tier == "paid")

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local MidnightGold = {
    TextColor = Color3.fromRGB(225, 220, 210),
    Background = Color3.fromRGB(16, 16, 20),
    Topbar = Color3.fromRGB(22, 22, 28),
    Shadow = Color3.fromRGB(10, 10, 14),
    NotificationBackground = Color3.fromRGB(20, 20, 26),
    NotificationActionsBackground = Color3.fromRGB(30, 30, 38),
    TabBackground = Color3.fromRGB(28, 28, 36),
    TabStroke = Color3.fromRGB(42, 42, 52),
    TabBackgroundSelected = Color3.fromRGB(212, 175, 85),
    TabTextColor = Color3.fromRGB(180, 175, 165),
    SelectedTabTextColor = Color3.fromRGB(16, 16, 20),
    ElementBackground = Color3.fromRGB(24, 24, 30),
    ElementBackgroundHover = Color3.fromRGB(32, 32, 40),
    SecondaryElementBackground = Color3.fromRGB(18, 18, 24),
    ElementStroke = Color3.fromRGB(44, 44, 54),
    SecondaryElementStroke = Color3.fromRGB(36, 36, 46),
    SliderBackground = Color3.fromRGB(42, 42, 52),
    SliderProgress = Color3.fromRGB(212, 175, 85),
    SliderStroke = Color3.fromRGB(232, 195, 105),
    ToggleBackground = Color3.fromRGB(22, 22, 28),
    ToggleEnabled = Color3.fromRGB(212, 175, 85),
    ToggleDisabled = Color3.fromRGB(80, 80, 90),
    ToggleEnabledStroke = Color3.fromRGB(232, 195, 105),
    ToggleDisabledStroke = Color3.fromRGB(100, 100, 110),
    ToggleEnabledOuterStroke = Color3.fromRGB(60, 58, 48),
    ToggleDisabledOuterStroke = Color3.fromRGB(50, 50, 58),
    DropdownSelected = Color3.fromRGB(32, 32, 40),
    DropdownUnselected = Color3.fromRGB(22, 22, 28),
    InputBackground = Color3.fromRGB(22, 22, 28),
    InputStroke = Color3.fromRGB(50, 50, 60),
    PlaceholderColor = Color3.fromRGB(140, 135, 125),
}

local Window = Rayfield:CreateWindow({
    Name = "3seventeen - MM2",
    Icon = "crown",
    LoadingTitle = "3seventeen",
    LoadingSubtitle = "mm2 module",
    Theme = MidnightGold,

    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = true,
    ConfigurationSaving = { Enabled = true, FolderName = "3seventeen", FileName = "3seventeen_mm2_cfg" },
    KeySystem = false,
})

-- Module body below (same as mm2.lua return function contents)
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local RS          = game:GetService("ReplicatedStorage")
local CoreGui     = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local Remotes  = RS:WaitForChild("Remotes")
local Gameplay = Remotes:WaitForChild("Gameplay")

local oldFolder = CoreGui:FindFirstChild("_3seventeen_MM2ESP")
if oldFolder then oldFolder:Destroy() end

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "_3seventeen_MM2ESP"
ESPFolder.Parent = CoreGui

local function getChar() return LocalPlayer.Character end
local function getHum() local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP() local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end

local PlayerData = {}
local MyRole = "None"

local function fetchPlayerData()
    local ok, data = pcall(function() return Gameplay.GetCurrentPlayerData:InvokeServer() end)
    if ok and data then
        PlayerData = data
        MyRole = PlayerData[LocalPlayer.Name] and PlayerData[LocalPlayer.Name].Role or "None"
    end
end

local refreshRoleESP, refreshInnoESP

Gameplay.PlayerDataChanged.OnClientEvent:Connect(function() fetchPlayerData() end)
task.spawn(fetchPlayerData)

Gameplay.RoundStart.OnClientEvent:Connect(function()
    task.wait(4)
    fetchPlayerData()
    if refreshRoleESP then refreshRoleESP() end
    if refreshInnoESP then refreshInnoESP() end
end)

local RoleSelect = Gameplay:FindFirstChild("RoleSelect")
if RoleSelect then
    RoleSelect.OnClientEvent:Connect(function()
        task.wait(1)
        fetchPlayerData()
        if refreshRoleESP then refreshRoleESP() end
        if refreshInnoESP then refreshInnoESP() end
    end)
end

local function getMurderer()
    for name, data in pairs(PlayerData) do
        if data.Role == "Murderer" then return Players:FindFirstChild(name) end
    end
end

local function getSheriff()
    for name, data in pairs(PlayerData) do
        if data.Role == "Sheriff" then return Players:FindFirstChild(name) end
    end
end


local function findGunDrop()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "GunDrop" and obj:IsA("BasePart") then return obj end
    end
end

-- TAB: INFO
local IT = Window:CreateTab("MM2 Info", "info")
IT:CreateSection("Role Revealer")

local RoleParagraph = IT:CreateParagraph({Title = "Current Roles", Content = "Waiting for round..."})

local RoleRevealEnabled = false
local function updateRoleParagraph()
    if not RoleRevealEnabled then return end
    local murderer, sheriff = "???", "???"
    local innocents = {}
    for name, data in pairs(PlayerData) do
        if data.Role == "Murderer" then murderer = name
        elseif data.Role == "Sheriff" then sheriff = name
        else table.insert(innocents, name) end
    end
    pcall(function()
        RoleParagraph:Set({Title = "Current Roles", Content = "Murderer: " .. murderer .. "\nSheriff: " .. sheriff .. "\nInnocents: " .. (#innocents > 0 and table.concat(innocents, ", ") or "None")})
    end)
end

Gameplay.PlayerDataChanged.OnClientEvent:Connect(updateRoleParagraph)

IT:CreateToggle({Name = "Auto Reveal Roles", CurrentValue = false, Flag = "mm2_rolereveal", Callback = function(v) RoleRevealEnabled = v; if v then updateRoleParagraph() end end})
IT:CreateDivider()
IT:CreateSection("Your Info")
IT:CreateButton({Name = "Show My Role", Callback = function() Rayfield:Notify({Title="Your Role", Content=MyRole, Duration=4, Image="user"}) end})

-- TAB: ESP
local ET = Window:CreateTab("MM2 ESP", "eye")
ET:CreateSection("Role ESP")

local function clearRoleESP()
    for _, ch in pairs(ESPFolder:GetChildren()) do if ch.Name:find("_role") then ch:Destroy() end end
end

local function createRoleHighlight(plr, role)
    if not plr or not plr.Character then return end
    local existing = ESPFolder:FindFirstChild(plr.Name .. "_role")
    if existing then existing:Destroy() end
    local color
    if role == "Murderer" then color = Color3.fromRGB(255, 40, 40)
    elseif role == "Sheriff" then color = Color3.fromRGB(40, 120, 255)
    elseif role == "Hero" then color = Color3.fromRGB(255, 180, 0)
    elseif role == "Innocent" then color = Color3.fromRGB(80, 255, 80)
    else return end
    local hl = Instance.new("Highlight"); hl.Name = plr.Name .. "_role"; hl.Adornee = plr.Character; hl.FillColor = color; hl.OutlineColor = color; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = ESPFolder
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local bb = Instance.new("BillboardGui"); bb.Name = plr.Name .. "_rolelbl"; bb.Adornee = hrp; bb.Size = UDim2.new(0, 200, 0, 30); bb.StudsOffset = Vector3.new(0, 4, 0); bb.AlwaysOnTop = true; bb.Parent = ESPFolder
        local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1; lbl.Text = role:upper() .. " - " .. plr.DisplayName; lbl.TextColor3 = color; lbl.TextStrokeTransparency = 0.3; lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); lbl.Font = Enum.Font.GothamBold; lbl.TextScaled = true; lbl.Parent = bb
    end
end

local RoleESPEnabled = false
refreshRoleESP = function()
    if not RoleESPEnabled then return end
    clearRoleESP()
    for name, data in pairs(PlayerData) do
        if (data.Role == "Murderer" or data.Role == "Sheriff" or data.Role == "Hero") and not data.Dead then
            local plr = Players:FindFirstChild(name)
            if plr and plr ~= LocalPlayer and plr.Character then createRoleHighlight(plr, data.Role) end
        end
    end
end

Gameplay.PlayerDataChanged.OnClientEvent:Connect(refreshRoleESP)
ET:CreateToggle({Name = "Murderer / Sheriff ESP", CurrentValue = false, Flag = "mm2_roleesp", Callback = function(v) RoleESPEnabled = v; if v then refreshRoleESP() else clearRoleESP() end end})

-- Innocent ESP (for murderers - shows all alive innocents in green)
local InnoESPEnabled = false
local function clearInnoESP()
    for _, ch in pairs(ESPFolder:GetChildren()) do if ch.Name:find("_inno") then ch:Destroy() end end
end

refreshInnoESP = function()
    if not InnoESPEnabled then return end
    clearInnoESP()
    for name, data in pairs(PlayerData) do
        if data.Role == "Innocent" and not data.Dead then
            local plr = Players:FindFirstChild(name)
            if plr and plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local hl = Instance.new("Highlight"); hl.Name = plr.Name .. "_inno"; hl.Adornee = plr.Character
                    hl.FillColor = Color3.fromRGB(80, 255, 80); hl.OutlineColor = Color3.fromRGB(80, 255, 80)
                    hl.FillTransparency = 0.7; hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = ESPFolder
                    local bb = Instance.new("BillboardGui"); bb.Name = plr.Name .. "_innolbl"; bb.Adornee = hrp
                    bb.Size = UDim2.new(0, 180, 0, 25); bb.StudsOffset = Vector3.new(0, 4, 0); bb.AlwaysOnTop = true; bb.Parent = ESPFolder
                    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
                    lbl.Text = plr.DisplayName; lbl.TextColor3 = Color3.fromRGB(80, 255, 80)
                    lbl.TextStrokeTransparency = 0.3; lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    lbl.Font = Enum.Font.GothamBold; lbl.TextScaled = true; lbl.Parent = bb
                end
            end
        end
    end
end

Gameplay.PlayerDataChanged.OnClientEvent:Connect(refreshInnoESP)
ET:CreateToggle({Name = "Innocent ESP (for Murderer)", CurrentValue = false, Flag = "mm2_innoesp", Callback = function(v) InnoESPEnabled = v; if v then refreshInnoESP() else clearInnoESP() end end})

local function onCharacterSpawned()
    task.wait(2)
    fetchPlayerData()
    refreshRoleESP()
    refreshInnoESP()
end
for _, plr in pairs(Players:GetPlayers()) do plr.CharacterAdded:Connect(onCharacterSpawned) end
Players.PlayerAdded:Connect(function(plr) plr.CharacterAdded:Connect(onCharacterSpawned) end)

ET:CreateDivider()
ET:CreateSection("Proximity Alert")

-- Murderer proximity warning (alerts when murderer is within range)
local ProxAlertEnabled = false
local ProxAlertDist = 40
local LastProxAlert = 0

ET:CreateToggle({Name = "Murderer Proximity Alert", CurrentValue = false, Flag = "mm2_proxalert", Callback = function(v)
    ProxAlertEnabled = v
    if v then
        task.spawn(function()
            while ProxAlertEnabled do
                if MyRole ~= "Murderer" then
                    local hrp = getHRP()
                    local m = getMurderer()
                    if hrp and m and m.Character then
                        local mHrp = m.Character:FindFirstChild("HumanoidRootPart")
                        if mHrp then
                            local dist = (hrp.Position - mHrp.Position).Magnitude
                            if dist < ProxAlertDist and tick() - LastProxAlert > 5 then
                                LastProxAlert = tick()
                                Rayfield:Notify({Title="DANGER", Content="Murderer is " .. math.floor(dist) .. " studs away!", Duration=3, Image="alert-triangle"})
                            end
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    end
end})
ET:CreateSlider({Name = "Alert Distance", Range = {15, 100}, Increment = 5, Suffix = " studs", CurrentValue = 40, Flag = "mm2_proxdist", Callback = function(v) ProxAlertDist = v end})

ET:CreateDivider()
ET:CreateSection("Item ESP")


local GunESPEnabled = false
ET:CreateToggle({Name = "Gun Drop ESP", CurrentValue = false, Flag = "mm2_gunesp", Callback = function(v)
    GunESPEnabled = v
    if v then
        task.spawn(function()
            while GunESPEnabled do
                local gun = findGunDrop()
                if gun and not ESPFolder:FindFirstChild("gundrop_esp") then
                    local bb = Instance.new("BillboardGui"); bb.Name = "gundrop_lbl"; bb.Adornee = gun; bb.Size = UDim2.new(0, 140, 0, 30); bb.StudsOffset = Vector3.new(0, 3, 0); bb.AlwaysOnTop = true; bb.Parent = ESPFolder
                    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1; lbl.Text = "GUN DROP"; lbl.TextColor3 = Color3.fromRGB(0, 255, 100); lbl.TextStrokeTransparency = 0.3; lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); lbl.Font = Enum.Font.GothamBold; lbl.TextScaled = true; lbl.Parent = bb
                    local sel = Instance.new("SelectionBox"); sel.Name = "gundrop_esp"; sel.Adornee = gun; sel.Color3 = Color3.fromRGB(0, 255, 100); sel.SurfaceColor3 = Color3.fromRGB(0, 255, 100); sel.SurfaceTransparency = 0.6; sel.LineThickness = 0.05; sel.Parent = ESPFolder
                elseif not gun then
                    for _, ch in pairs(ESPFolder:GetChildren()) do if ch.Name:find("^gundrop") then ch:Destroy() end end
                end
                task.wait(0.5)
            end
            for _, ch in pairs(ESPFolder:GetChildren()) do if ch.Name:find("^gundrop") then ch:Destroy() end end
        end)
    end
end})

-- TAB: COMBAT
local CT = Window:CreateTab("MM2 Combat", "crosshair")
CT:CreateSection("Silent Aim")

local GunBeamRemote = RS:WaitForChild("WeaponEvents"):WaitForChild("GunBeam")
local SilentAimEnabled = false

local function getSilentAimTarget()
    if MyRole == "Murderer" then
        local hrp = getHRP(); if not hrp then return nil end
        local best, bestDist = nil, math.huge
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local head = plr.Character:FindFirstChild("Head")
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if head and hum and hum.Health > 0 then
                    local d = (hrp.Position - head.Position).Magnitude
                    if d < bestDist then best = head; bestDist = d end
                end
            end
        end
        return best
    else
        local m = getMurderer()
        if m and m.Character then
            local head = m.Character:FindFirstChild("Head")
            local hum = m.Character:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then return head end
        end
    end
    return nil
end

if not _G._3seventeen_namecall then
    local OldNamecall
    OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and self == GunBeamRemote and _G._3seventeen_silentaim then
            local target = getSilentAimTarget()
            if target then
                return OldNamecall(self, CFrame.new(target.Position))
            end
        end
        return OldNamecall(self, ...)
    end))
    _G._3seventeen_namecall = true
end

CT:CreateToggle({Name = isPaid and "Silent Aim" or "Silent Aim [PRO]", CurrentValue = false, Flag = "mm2_silentaim", Callback = function(v)
    if not isPaid then Rayfield:Notify({Title="Premium Only", Content="Silent Aim requires a premium key.", Duration=3}) return end
    SilentAimEnabled = v
    _G._3seventeen_silentaim = v
    if v then
        Rayfield:Notify({Title="Silent Aim ON", Content="Intercepts gun remote directly\nWorks in any view, no snap", Duration=3, Image="crosshair"})
    end
end})

CT:CreateParagraph({Title = "How it works", Content = "Hooks the GunBeam remote at the network level.\nClick anywhere - bullet hits the murderer (as Sheriff/Hero)\nor nearest player (as Murderer).\nNo camera snap, works in any view."})

CT:CreateDivider()
CT:CreateSection("God Mode")

local GodModeEnabled = false
local GodModeConns = {}

local function applyGodMode(hum)
    if not hum then return end
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    local conn = hum.HealthChanged:Connect(function(newHealth)
        if GodModeEnabled and newHealth < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end
    end)
    table.insert(GodModeConns, conn)
end

CT:CreateToggle({Name = isPaid and "God Mode (Anti-Death)" or "God Mode [PRO]", CurrentValue = false, Flag = "mm2_godmode", Callback = function(v)
    if not isPaid then Rayfield:Notify({Title="Premium Only", Content="God Mode requires a premium key.", Duration=3}) return end
    GodModeEnabled = v
    if v then
        local hum = getHum()
        applyGodMode(hum)
        local charConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
            if not GodModeEnabled then return end
            task.wait(1)
            local newHum = newChar:FindFirstChildOfClass("Humanoid")
            applyGodMode(newHum)
        end)
        table.insert(GodModeConns, charConn)
        Rayfield:Notify({Title="God Mode ON", Content="Anti-death active\nHealth resets on hit", Duration=3, Image="shield"})
    else
        for _, conn in pairs(GodModeConns) do pcall(function() conn:Disconnect() end) end
        GodModeConns = {}
        local hum = getHum()
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end
    end
end})

CT:CreateParagraph({Title = "Note", Content = "Prevents your character from dying.\nServer still marks you dead in data,\nbut character stays alive on screen.\nMay not work against all kill methods."})

CT:CreateDivider()
CT:CreateSection("Teleport")
CT:CreateButton({Name = isPaid and "TP Behind Murderer" or "TP Behind Murderer [PRO]", Callback = function() if not isPaid then Rayfield:Notify({Title="Premium Only", Content="Requires premium key.", Duration=3}) return end; local m = getMurderer(); if m and m.Character then local tH = m.Character:FindFirstChild("HumanoidRootPart"); local mH = getHRP(); if tH and mH then mH.CFrame = tH.CFrame * CFrame.new(0, 0, 5) end else Rayfield:Notify({Title="Error", Content="Murderer not found", Duration=2, Image="alert-circle"}) end end})
CT:CreateButton({Name = isPaid and "TP Behind Sheriff" or "TP Behind Sheriff [PRO]", Callback = function() if not isPaid then Rayfield:Notify({Title="Premium Only", Content="Requires premium key.", Duration=3}) return end; local s = getSheriff(); if s and s.Character then local tH = s.Character:FindFirstChild("HumanoidRootPart"); local mH = getHRP(); if tH and mH then mH.CFrame = tH.CFrame * CFrame.new(0, 0, 5) end else Rayfield:Notify({Title="Error", Content="Sheriff not found", Duration=2, Image="alert-circle"}) end end})

-- TAB: COLLECT
local ColT = Window:CreateTab("MM2 Collect", "coins")
ColT:CreateSection("Gun")
ColT:CreateButton({Name = "Teleport to Gun Drop", Callback = function() local hrp = getHRP(); if not hrp then return end; local gun = findGunDrop(); if gun then hrp.CFrame = gun.CFrame + Vector3.new(0, 3, 0); Rayfield:Notify({Title="Gun Drop", Content="Teleported", Duration=2, Image="crosshair"}) else Rayfield:Notify({Title="Not Found", Content="No gun drop", Duration=2, Image="alert-circle"}) end end})

local AutoGrabEnabled = false
ColT:CreateToggle({Name = isPaid and "Auto Grab Gun" or "Auto Grab Gun [PRO]", CurrentValue = false, Flag = "mm2_autograb", Callback = function(v)
    if not isPaid then Rayfield:Notify({Title="Premium Only", Content="Auto Grab requires a premium key.", Duration=3}) return end
    AutoGrabEnabled = v
    if v then task.spawn(function() while AutoGrabEnabled do local hrp = getHRP(); if hrp then local hasGun = false; local bp = LocalPlayer:FindFirstChild("Backpack"); local char = getChar(); if bp then for _, t in pairs(bp:GetChildren()) do if t:IsA("Tool") and t.Name:find("Gun") then hasGun = true; break end end end; if not hasGun and char then for _, t in pairs(char:GetChildren()) do if t:IsA("Tool") and t.Name:find("Gun") then hasGun = true; break end end end; if not hasGun then local gun = findGunDrop(); if gun then hrp.CFrame = gun.CFrame + Vector3.new(0, 3, 0) end end end; task.wait(0.3) end end) end
end})

-- TAB: MOVEMENT
local MovT = Window:CreateTab("MM2 Movement", "zap")
MovT:CreateSection("Speed")

local MM2SpeedEnabled, MM2SpeedVal = false, 20
local MM2SpeedConn = nil
MovT:CreateToggle({Name = "Speed Boost", CurrentValue = false, Flag = "mm2_speed", Callback = function(v)
    MM2SpeedEnabled = v
    if v then MM2SpeedConn = RunService.Heartbeat:Connect(function() local hum = getHum(); if hum then hum.WalkSpeed = MM2SpeedVal end end)
    else if MM2SpeedConn then MM2SpeedConn:Disconnect(); MM2SpeedConn = nil end; local hum = getHum(); if hum then hum.WalkSpeed = 16 end end
end})
MovT:CreateSlider({Name = "Speed Value", Range = {16, 80}, Increment = 2, Suffix = " studs/s", CurrentValue = 20, Flag = "mm2_speed_val", Callback = function(v) MM2SpeedVal = v end})

MovT:CreateDivider()
MovT:CreateSection("Teleport")
MovT:CreateButton({Name = "TP to Lobby", Callback = function() local hrp = getHRP(); if not hrp then return end; local lobby = workspace:FindFirstChild("RegularLobby"); if lobby then for _, sp in pairs(lobby:GetDescendants()) do if sp:IsA("SpawnLocation") then hrp.CFrame = sp.CFrame + Vector3.new(0, 5, 0); Rayfield:Notify({Title="Teleported", Content="Back to lobby", Duration=2, Image="home"}); return end end end end})

-- TAB: MISC
local MiscT = Window:CreateTab("MM2 Misc", "star")
MiscT:CreateSection("Info")
MiscT:CreateButton({Name = "Show All Player Roles", Callback = function() local lines = {}; for name, data in pairs(PlayerData) do table.insert(lines, name .. ": " .. (data.Role or "?") .. (data.Dead and " (DEAD)" or "")) end; Rayfield:Notify({Title = "Player Roles", Content = #lines > 0 and table.concat(lines, "\n") or "No round data", Duration = 8, Image = "users"}) end})

MiscT:CreateDivider()
MiscT:CreateSection("Fake Trade")

local FakeTradeItem = "Icewing"
local FakeTradeGodlies = {"Icewing","ChromaDarkbringer","ChromaLightbringer","Eternal","Eternal2","Eternal3","Eternal4","ElderwoodScythe","Harvester","Darkbringer","Lightbringer","Fang","FangChroma","Heat","HeatChroma","Luger","LugerChroma","Saw","SawChroma","Laser","LaserChroma","Shark","SharkChroma","Prismatic","Handsaw","Tides","TidesChroma","Slasher","SlasherChroma","Gemstone","GemstoneChroma","Nightblade","Virtual","Pixel","Bioblade","Deathshard","DeathshardChroma","Flames","Hallow","Hallowgun","HallowsBlade","Hallowscythe","Sugar","Candy","Nebula","Celestial","Clockwork","Spider","Pumpking","Ghostblade","Bauble","BaubleChroma","Blizzard","BlizzardChroma","Amerilaser","BattleAxe","BattleAxe2","Batwing","Blaster","Bloom","Boneblade","BonebladeChroma","Candleflame","CandleflameChroma","Chill","Constellation","ConstellationChroma","Cookieblade","Darkshot","Darksword","Dartbringer","Eggblade","ElderwoodGun","ElderwoodKnife","ElderwoodKnifeChroma","Emptybringer","EmptybringerChroma","EternalCane","Flora","FlowerwoodGun","FlowerwoodKnife","Frostbite","Frostsaber","GingerLuger","Gingerblade","GingerbladeChroma","Gingerscope","Gingerscythe_Ancient","Gingerscythe_Godly","GreenLuger","HeartWand","HeartWandChroma","Heartblade","IceDragon","IceHammer_Ancient","IceShard","Icebeam","Iceblaster","Icebreaker","Iceflake","Icepiercer","Jinglegun","Logchopper","Lugercane","Makeshift","Minty","NikKnife","Ocean_G","Pearl_G","Pearl_K","Peppermint","Phantom2022","Plasmabeam","Plasmablade","Rainbow_G","Rainbow_K","Raygun","RaygunChroma","RedLuger","Reaver_Ancient","Reaver_Godly","Sakura_K","Scythe","SeerChroma","SharkSeeker","SnowDagger","SnowDaggerChroma","Snowcannon","SnowcannonChroma","Snowflake","Snowstorm","SnowstormChroma","Spider","SunsetGun","SunsetGunChroma","SunsetKnife","SunsetKnifeChroma","Sweet","SweetChroma","SwirlyAxe","SwirlyBlade","SwirlyGun","SwirlyGunChroma","Synthwave_Ancient","TheSeer","TravelerAxe","TravelerGun","TravelerGunChroma","Treat","TreatChroma","TreeGun2023","TreeGun2023Chroma","TreeKnife2023","TreeKnife2023Chroma","Turkey2023","UFOKnife","UFOKnifeChroma","VampireAxe","VampireGun","VampireGunChroma","VampiresEdge","Watergun","WatergunChroma","Waves_K","WintersEdge","WraithGun","WraithKnife","XenoGun","XenoKnife","Xmas","ZombieBat","BigKill","AmericaSword","Blossom_G","Gingermint_G","Gingermint_K","Sorry"}

MiscT:CreateDropdown({
    Name = "Select Weapon",
    Options = FakeTradeGodlies,
    CurrentOption = {"Icewing"},
    MultipleOptions = false,
    Flag = "mm2_faketrade_item",
    Callback = function(v) FakeTradeItem = v[1] end
})

MiscT:CreateButton({Name = isPaid and "Trigger Fake Trade" or "Trigger Fake Trade [PRO]", Callback = function()
    if not isPaid then Rayfield:Notify({Title="Premium Only", Content="Fake Trade requires a premium key.", Duration=3}) return end
    task.spawn(function()
        local ok, err = pcall(function()
            local BoxModule = require(RS:WaitForChild("Modules"):WaitForChild("BoxModule"))
            BoxModule.OpenBox("KnifeBox5", FakeTradeItem)
        end)
        if not ok then
            task.wait(0.5)
        end
        task.wait(0.5)
        if _G.NewItem then
            _G.NewItem(FakeTradeItem, "You Got...", nil, "Weapons")
        else
            local ItemPopup = require(RS:WaitForChild("ClientServices"):WaitForChild("ItemPopupService"))
            ItemPopup:AddNewItem(FakeTradeItem, "Weapons", 1)
        end
    end)
end})

MiscT:CreateDivider()
MiscT:CreateSection("Server")
MiscT:CreateButton({Name = "Rejoin Server", Callback = function()
    local TS = game:GetService("TeleportService")
    TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end})

MiscT:CreateDivider()
MiscT:CreateSection("Fun")
local SpinEnabled, SpinConn = false, nil
MiscT:CreateToggle({Name = "Spin Character", CurrentValue = false, Flag = "mm2_spin", Callback = function(v)
    SpinEnabled = v
    if v then SpinConn = RunService.Heartbeat:Connect(function() local hrp = getHRP(); if hrp then hrp.AssemblyAngularVelocity = Vector3.new(0, 30, 0) end end)
    else if SpinConn then SpinConn:Disconnect(); SpinConn = nil end; local hrp = getHRP(); if hrp then hrp.AssemblyAngularVelocity = Vector3.zero end end
end})

-- Kill feed notifications
Gameplay.KillEvent.OnClientEvent:Connect(function(...)
    local args = {...}
    local victim = tostring(args[1] or "someone")
    Rayfield:Notify({Title="Kill", Content=victim .. " was eliminated", Duration=3, Image="skull"})
end)

-- Map loading notification
local function detectMapName()
    local knownNonMaps = {RegularLobby=true, EffectLoader=true, ServerStatus=true, PetContainer=true, WeaponDisplays=true, GameSettings=true, ThrowingKnife=true}
    local playerNames = {}
    for _, p in pairs(Players:GetPlayers()) do playerNames[p.Name] = true end
    for _, child in pairs(workspace:GetChildren()) do
        if child:IsA("Model") and not knownNonMaps[child.Name] and not playerNames[child.Name] then
            if child:FindFirstChild("Spawns") or child:FindFirstChild("CoinContainer") then
                return child.Name
            end
        end
    end
    return nil
end

Gameplay.LoadingMap.OnClientEvent:Connect(function(...)
    task.wait(3)
    local mapName = detectMapName() or "Unknown"
    Rayfield:Notify({Title="New Map", Content=mapName, Duration=4, Image="map"})
end)

-- Clear on round end
Gameplay.RoundEndFade.OnClientEvent:Connect(function()
    clearRoleESP()
    clearInnoESP()
    for _, ch in pairs(ESPFolder:GetChildren()) do if ch.Name:find("^gundrop") then ch:Destroy() end end
end)

Rayfield:Notify({Title="MM2 Loaded", Content="Murder Mystery 2 features active", Duration=4, Image="eye"})
