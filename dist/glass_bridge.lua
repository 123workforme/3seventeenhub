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
    Name = "3seventeen - Glass Bridge",
    Icon = "crown",
    LoadingTitle = "3seventeen",
    LoadingSubtitle = "glass bridge module",
    Theme = MidnightGold,

    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = true,
    ConfigurationSaving = { Enabled = true, FolderName = "3seventeen", FileName = "3seventeen_gb_cfg" },
    KeySystem = false,
})

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local RS           = game:GetService("ReplicatedStorage")
local CoreGui      = game:GetService("CoreGui")
local Lighting     = game:GetService("Lighting")
local LocalPlayer  = Players.LocalPlayer
local Terrain      = workspace.Terrain

---------------------------------------------------------------
-- CLEANUP (destroy old instances if re-executing)
---------------------------------------------------------------
for _, name in pairs({"_3seventeen_ESP", "_3seventeen_Beams"}) do
    local old = CoreGui:FindFirstChild(name)
    if old then old:Destroy() end
end

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "_3seventeen_ESP"
ESPFolder.Parent = CoreGui

---------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------
local function getChar()  return LocalPlayer.Character end
local function getHum()   local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP()   local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end

local function teleport(cframe)
    local hrp = getHRP()
    if not hrp then return false end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.CFrame = cframe
    task.wait(0.1)
    hrp.AssemblyLinearVelocity = Vector3.zero
    return true
end

local SegmentsCache = nil
local function getSegmentsSorted()
    if SegmentsCache then return SegmentsCache end
    local segFolder = workspace:FindFirstChild("segmentSystem")
    if not segFolder then return {} end
    local segsFolder = segFolder:FindFirstChild("Segments")
    if not segsFolder then return {} end

    local segs = segsFolder:GetChildren()
    table.sort(segs, function(a, b)
        local na = tonumber(a.Name:match("Segment(%d+)")) or 0
        local nb = tonumber(b.Name:match("Segment(%d+)")) or 0
        return na < nb
    end)
    SegmentsCache = segs
    return segs
end

local function getSafePart(segment)
    local folder = segment:FindFirstChild("Folder")
    if not folder then return nil end
    for _, part in pairs(folder:GetChildren()) do
        if part:IsA("BasePart") and not part:FindFirstChild("breakable") then
            return part
        end
    end
    return nil
end

local function getBreakablePart(segment)
    local folder = segment:FindFirstChild("Folder")
    if not folder then return nil end
    for _, part in pairs(folder:GetChildren()) do
        if part:IsA("BasePart") and part:FindFirstChild("breakable") then
            return part
        end
    end
    return nil
end

local function getClosestSegIdx()
    local hrp = getHRP()
    if not hrp then return 1 end
    local sorted = getSegmentsSorted()
    local best, bestDist = 1, math.huge
    for i, seg in ipairs(sorted) do
        local s = getSafePart(seg)
        if s then
            local d = (hrp.Position - s.Position).Magnitude
            if d < bestDist then best, bestDist = i, d end
        end
    end
    return best
end

local function claimFinishReward()
    pcall(function()
        local remotes = RS:FindFirstChild("Remotes")
        if remotes then
            local fr = remotes:FindFirstChild("FinishRewardClaimed")
            if fr then fr:FireServer() end
            local cr = remotes:FindFirstChild("ClaimReward")
            if cr then cr:FireServer() end
        end
    end)
end

---------------------------------------------------------------
-- TAB: BRIDGE
---------------------------------------------------------------
local BridgeTab = Window:CreateTab("Bridge", "eye")

BridgeTab:CreateSection("Safe Glass ESP")

BridgeTab:CreateToggle({
    Name = "Show Safe Panels",
    CurrentValue = false,
    Flag = "gb_safeesp",
    Callback = function(on)
        for _, c in pairs(ESPFolder:GetChildren()) do
            if c.Name:find("_seg") then c:Destroy() end
        end
        if not on then return end

        for _, seg in pairs(getSegmentsSorted()) do
            local safe = getSafePart(seg)
            local bad  = getBreakablePart(seg)

            if safe then
                local box = Instance.new("SelectionBox")
                box.Name = seg.Name .. "_seg_safe"
                box.Adornee = safe
                box.Color3 = Color3.fromRGB(0, 255, 80)
                box.SurfaceColor3 = Color3.fromRGB(0, 255, 80)
                box.SurfaceTransparency = 0.7
                box.LineThickness = 0.04
                box.Parent = ESPFolder
            end

            if bad then
                local box = Instance.new("SelectionBox")
                box.Name = seg.Name .. "_seg_bad"
                box.Adornee = bad
                box.Color3 = Color3.fromRGB(255, 40, 40)
                box.SurfaceColor3 = Color3.fromRGB(255, 40, 40)
                box.SurfaceTransparency = 0.85
                box.LineThickness = 0.02
                box.Parent = ESPFolder
            end
        end
    end,
})

BridgeTab:CreateToggle({
    Name = "Show Path Beams (Green Lines)",
    CurrentValue = false,
    Flag = "gb_beams",
    Callback = function(on)
        local old = CoreGui:FindFirstChild("_3seventeen_Beams")
        if old then old:Destroy() end
        if not on then return end

        local beamFolder = Instance.new("Folder")
        beamFolder.Name = "_3seventeen_Beams"
        beamFolder.Parent = CoreGui

        local sorted = getSegmentsSorted()
        for i = 1, #sorted - 1 do
            local cur = getSafePart(sorted[i])
            local nxt = getSafePart(sorted[i + 1])
            if cur and nxt then
                local att0 = Instance.new("Attachment")
                att0.WorldPosition = cur.Position + Vector3.new(0, 1.5, 0)
                att0.Parent = Terrain

                local att1 = Instance.new("Attachment")
                att1.WorldPosition = nxt.Position + Vector3.new(0, 1.5, 0)
                att1.Parent = Terrain

                local beam = Instance.new("Beam")
                beam.Attachment0 = att0
                beam.Attachment1 = att1
                beam.Color = ColorSequence.new(Color3.fromRGB(0, 255, 100))
                beam.Transparency = NumberSequence.new(0.3)
                beam.Width0 = 0.6
                beam.Width1 = 0.6
                beam.FaceCamera = true
                beam.Parent = beamFolder

                att0.Parent = beamFolder
                att1.Parent = beamFolder
            end
        end
    end,
})

BridgeTab:CreateDivider()
BridgeTab:CreateSection("Auto Walk")

local AutoWalkEnabled = false
local AutoWalkConn = nil

BridgeTab:CreateToggle({
    Name = isPaid and "Auto Walk Safe Path" or "Auto Walk [PRO]",
    CurrentValue = false,
    Flag = "gb_autowalk",
    Callback = function(on)
        if not isPaid then Rayfield:Notify({Title="Premium Only", Content="Auto Walk requires a premium key.", Duration=3}) return end
        AutoWalkEnabled = on
        if on then
            local sorted = getSegmentsSorted()
            local idx = getClosestSegIdx()

            AutoWalkConn = RunService.Heartbeat:Connect(function()
                if not AutoWalkEnabled then return end
                local hum, hrp = getHum(), getHRP()
                if not hum or not hrp then return end

                if idx > #sorted then
                    AutoWalkEnabled = false
                    Rayfield:Notify({Title = "Done", Content = "Bridge complete!", Duration = 3, Image = "check-circle"})
                    return
                end

                local target = getSafePart(sorted[idx])
                if not target then idx = idx + 1; return end

                local goal = target.Position + Vector3.new(0, 2, 0)
                local dist = (hrp.Position - goal).Magnitude

                if dist < 5 then
                    idx = idx + 1
                else
                    hum:MoveTo(Vector3.new(goal.X, hrp.Position.Y, goal.Z))
                    if math.abs(hrp.Position.X - goal.X) > 5 and dist < 20 then
                        if hum.FloorMaterial ~= Enum.Material.Air then
                            hum:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                    end
                end
            end)
        else
            if AutoWalkConn then AutoWalkConn:Disconnect(); AutoWalkConn = nil end
        end
    end,
})

BridgeTab:CreateDivider()
BridgeTab:CreateSection("Teleports")

BridgeTab:CreateButton({
    Name = "TP to Next Safe Panel",
    Callback = function()
        local sorted = getSegmentsSorted()
        local idx = getClosestSegIdx()
        if idx < #sorted then
            local nxt = getSafePart(sorted[idx + 1])
            if nxt then
                teleport(CFrame.new(nxt.Position + Vector3.new(0, 3, 0)))
                Rayfield:Notify({Title = "TP", Content = sorted[idx + 1].Name, Duration = 1.5, Image = "navigation"})
            end
        end
    end,
})

BridgeTab:CreateButton({
    Name = isPaid and "TP to End" or "TP to End [PRO]",
    Callback = function()
        if not isPaid then Rayfield:Notify({Title="Premium Only", Content="TP to End requires a premium key.", Duration=3}) return end
        local sorted = getSegmentsSorted()
        if #sorted > 0 then
            local s = getSafePart(sorted[#sorted]) or sorted[#sorted]:FindFirstChild("Center")
            if s then
                teleport(CFrame.new(s.Position + Vector3.new(0, 3, 0)))
                Rayfield:Notify({Title = "End", Content = sorted[#sorted].Name, Duration = 2, Image = "flag"})
            end
        end
    end,
})

local SkipAmt = 5
BridgeTab:CreateSlider({
    Name = "Skip Amount", Range = {1, 20}, Increment = 1,
    Suffix = " panels", CurrentValue = 5, Flag = "gb_skip",
    Callback = function(v) SkipAmt = v end,
})

BridgeTab:CreateButton({
    Name = "Skip Forward",
    Callback = function()
        local sorted = getSegmentsSorted()
        local idx = math.min(getClosestSegIdx() + SkipAmt, #sorted)
        local s = getSafePart(sorted[idx])
        if s then
            teleport(CFrame.new(s.Position + Vector3.new(0, 3, 0)))
            Rayfield:Notify({Title = "Skipped", Content = sorted[idx].Name, Duration = 2, Image = "fast-forward"})
        end
    end,
})

BridgeTab:CreateSlider({
    Name = "Segment Picker", Range = {1, 54}, Increment = 1,
    Suffix = "", CurrentValue = 1, Flag = "gb_segpick",
    Callback = function(v)
        local segsFolder = workspace:FindFirstChild("segmentSystem")
        if not segsFolder then return end
        local sf = segsFolder:FindFirstChild("Segments")
        if not sf then return end
        local seg = sf:FindFirstChild("Segment" .. v)
        if seg then
            local s = getSafePart(seg) or seg:FindFirstChild("Center")
            if s then teleport(CFrame.new(s.Position + Vector3.new(0, 3, 0))) end
        end
    end,
})

---------------------------------------------------------------
-- TAB: PLAYER
---------------------------------------------------------------
local PlayerTab = Window:CreateTab("Player", "user")

PlayerTab:CreateSection("Movement")

local SpeedVal = 16
local SpeedConn = nil

PlayerTab:CreateToggle({
    Name = "Speed Hack", CurrentValue = false, Flag = "gb_speed",
    Callback = function(on)
        if on then
            SpeedConn = RunService.Heartbeat:Connect(function()
                local h = getHum(); if h then h.WalkSpeed = SpeedVal end
            end)
        else
            if SpeedConn then SpeedConn:Disconnect(); SpeedConn = nil end
            local h = getHum(); if h then h.WalkSpeed = 16 end
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "Walk Speed", Range = {16, 200}, Increment = 2,
    Suffix = "", CurrentValue = 16, Flag = "gb_speed_val",
    Callback = function(v) SpeedVal = v end,
})

local JumpVal = 50
local JumpConn = nil

PlayerTab:CreateToggle({
    Name = "Jump Power Hack", CurrentValue = false, Flag = "gb_jump",
    Callback = function(on)
        if on then
            JumpConn = RunService.Heartbeat:Connect(function()
                local h = getHum()
                if h then h.UseJumpPower = true; h.JumpPower = JumpVal end
            end)
        else
            if JumpConn then JumpConn:Disconnect(); JumpConn = nil end
            local h = getHum(); if h then h.JumpPower = 50 end
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "Jump Power", Range = {50, 300}, Increment = 5,
    Suffix = "", CurrentValue = 50, Flag = "gb_jump_val",
    Callback = function(v) JumpVal = v end,
})

PlayerTab:CreateDivider()
PlayerTab:CreateSection("Utility")

local InfJump = false
PlayerTab:CreateToggle({
    Name = "Infinite Jump", CurrentValue = false, Flag = "gb_infjump",
    Callback = function(on) InfJump = on end,
})
UIS.JumpRequest:Connect(function()
    if InfJump then local h = getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

local NoclipConn = nil
PlayerTab:CreateToggle({
    Name = "Noclip", CurrentValue = false, Flag = "gb_noclip",
    Callback = function(on)
        if on then
            NoclipConn = RunService.Stepped:Connect(function()
                local c = getChar(); if not c then return end
                for _, p in pairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end)
        else
            if NoclipConn then NoclipConn:Disconnect(); NoclipConn = nil end
        end
    end,
})

local AntiPushConn = nil
PlayerTab:CreateToggle({
    Name = "Anti-Push", CurrentValue = false, Flag = "gb_antipush",
    Callback = function(on)
        if on then
            AntiPushConn = RunService.Heartbeat:Connect(function()
                local hrp = getHRP()
                if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0) end
            end)
        else
            if AntiPushConn then AntiPushConn:Disconnect(); AntiPushConn = nil end
        end
    end,
})

local AntiVoidConn = nil
local LastSafe = nil
PlayerTab:CreateToggle({
    Name = "Anti-Void", CurrentValue = false, Flag = "gb_antivoid",
    Callback = function(on)
        if on then
            AntiVoidConn = RunService.Heartbeat:Connect(function()
                local hrp = getHRP(); if not hrp then return end
                if hrp.Position.Y > -50 then
                    LastSafe = hrp.CFrame
                elseif LastSafe then
                    hrp.CFrame = LastSafe
                end
            end)
        else
            if AntiVoidConn then AntiVoidConn:Disconnect(); AntiVoidConn = nil end
        end
    end,
})

---------------------------------------------------------------
-- TAB: FARM
---------------------------------------------------------------
local FarmTab = Window:CreateTab("Auto Farm", "dollar-sign")

FarmTab:CreateSection("Finish Line Farm")

local FarmEnabled = false
local FarmDelay = 6

FarmTab:CreateSlider({
    Name = "Loop Delay", Range = {2, 20}, Increment = 1,
    Suffix = "s", CurrentValue = 6, Flag = "gb_farm_delay",
    Callback = function(v) FarmDelay = v end,
})

FarmTab:CreateToggle({
    Name = isPaid and "Start Auto Farm" or "Auto Farm [PRO]", CurrentValue = false, Flag = "gb_farm",
    Callback = function(on)
        if not isPaid then Rayfield:Notify({Title="Premium Only", Content="Auto Farm requires a premium key.", Duration=3}) return end
        FarmEnabled = on
        if on then
            Rayfield:Notify({Title = "Farm ON", Content = "Looping finish for cash", Duration = 3, Image = "dollar-sign"})
            task.spawn(function()
                while FarmEnabled do
                    local hrp = getHRP()
                    if not hrp then task.wait(3) continue end

                    teleport(CFrame.new(-746.47, -4, -513.49))
                    task.wait(0.8)

                    local finish = workspace:FindFirstChild("Finish")
                    if finish then
                        local chest = finish:FindFirstChild("Chest")
                        if chest then
                            teleport(CFrame.new(chest.Position))
                            task.wait(0.3)
                        end
                    end

                    claimFinishReward()
                    task.wait(1)

                    local char = getChar()
                    if char then
                        local ff = char:FindFirstChildOfClass("ForceField")
                        while ff and ff.Parent and FarmEnabled do
                            task.wait(0.5)
                            ff = char:FindFirstChildOfClass("ForceField")
                        end
                    end

                    task.wait(FarmDelay)
                end
            end)
        else
            Rayfield:Notify({Title = "Farm OFF", Content = "Stopped", Duration = 2, Image = "x"})
        end
    end,
})

FarmTab:CreateDivider()
FarmTab:CreateSection("Manual")

FarmTab:CreateButton({
    Name = "TP to Finish (Once)",
    Callback = function()
        teleport(CFrame.new(-746.47, -4, -513.49))
        Rayfield:Notify({Title = "Finish", Content = "At end zone", Duration = 2, Image = "flag"})
    end,
})

FarmTab:CreateButton({
    Name = "Claim Reward Now",
    Callback = function()
        claimFinishReward()
        Rayfield:Notify({Title = "Claimed", Content = "Rewards fired", Duration = 2, Image = "check"})
    end,
})

---------------------------------------------------------------
-- TAB: MISC
---------------------------------------------------------------
local MiscTab = Window:CreateTab("Misc", "settings")

MiscTab:CreateSection("Push")

MiscTab:CreateButton({
    Name = "Push Nearest Player",
    Callback = function()
        local remotes = RS:FindFirstChild("Remotes")
        local push = remotes and remotes:FindFirstChild("PushPlayer")
        if not push then return end
        local hrp = getHRP(); if not hrp then return end

        local best, bestDist = nil, 30
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local ohrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if ohrp then
                    local d = (hrp.Position - ohrp.Position).Magnitude
                    if d < bestDist then best, bestDist = plr, d end
                end
            end
        end
        if best then
            pcall(function() push:InvokeServer(best) end)
            Rayfield:Notify({Title = "Pushed", Content = best.DisplayName, Duration = 2, Image = "zap"})
        end
    end,
})

local AutoPush = false
MiscTab:CreateToggle({
    Name = isPaid and "Auto Push Nearby" or "Auto Push [PRO]", CurrentValue = false, Flag = "gb_autopush",
    Callback = function(on)
        if not isPaid then Rayfield:Notify({Title="Premium Only", Content="Auto Push requires a premium key.", Duration=3}) return end
        AutoPush = on
        if on then
            task.spawn(function()
                while AutoPush do
                    local remotes = RS:FindFirstChild("Remotes")
                    local push = remotes and remotes:FindFirstChild("PushPlayer")
                    local hrp = getHRP()
                    if push and hrp then
                        for _, plr in pairs(Players:GetPlayers()) do
                            if plr ~= LocalPlayer and plr.Character then
                                local ohrp = plr.Character:FindFirstChild("HumanoidRootPart")
                                if ohrp and (hrp.Position - ohrp.Position).Magnitude < 12 then
                                    pcall(function() push:InvokeServer(plr) end)
                                end
                            end
                        end
                    end
                    task.wait(1.5)
                end
            end)
        end
    end,
})

MiscTab:CreateDivider()
MiscTab:CreateSection("Visuals")

MiscTab:CreateButton({
    Name = "Fullbright",
    Callback = function()
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        for _, fx in pairs(Lighting:GetChildren()) do
            if fx:IsA("PostEffect") then fx.Enabled = false end
        end
        Rayfield:Notify({Title = "Fullbright", Content = "Done", Duration = 2, Image = "sun"})
    end,
})

local PlayerESPConn = nil
MiscTab:CreateToggle({
    Name = "Player ESP", CurrentValue = false, Flag = "gb_pesp",
    Callback = function(on)
        for _, c in pairs(ESPFolder:GetChildren()) do
            if c.Name:find("_plr") then c:Destroy() end
        end
        if on then
            PlayerESPConn = RunService.Heartbeat:Connect(function()
                for _, c in pairs(ESPFolder:GetChildren()) do
                    if c.Name:find("_plr") then c:Destroy() end
                end
                local myHRP = getHRP()
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local ohrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        if ohrp then
                            local dist = myHRP and math.floor((myHRP.Position - ohrp.Position).Magnitude) or 0
                            local bb = Instance.new("BillboardGui")
                            bb.Name = plr.Name .. "_plr"
                            bb.Adornee = ohrp
                            bb.Size = UDim2.new(0, 160, 0, 30)
                            bb.StudsOffset = Vector3.new(0, 4, 0)
                            bb.AlwaysOnTop = true
                            bb.Parent = ESPFolder

                            local lbl = Instance.new("TextLabel")
                            lbl.Size = UDim2.new(1, 0, 1, 0)
                            lbl.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                            lbl.BackgroundTransparency = 0.35
                            lbl.Text = plr.DisplayName .. " [" .. dist .. "]"
                            lbl.TextColor3 = Color3.fromRGB(170, 230, 255)
                            lbl.Font = Enum.Font.GothamBold
                            lbl.TextScaled = true
                            lbl.Parent = bb

                            Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 6)
                        end
                    end
                end
            end)
        else
            if PlayerESPConn then PlayerESPConn:Disconnect(); PlayerESPConn = nil end
        end
    end,
})

MiscTab:CreateDivider()
MiscTab:CreateSection("Info")

local ls = LocalPlayer:FindFirstChild("leaderstats")
local cp = LocalPlayer:FindFirstChild("Checkpoint")
MiscTab:CreateParagraph({
    Title = "Stats",
    Content = "Wins: " .. (ls and ls:FindFirstChild("Wins") and tostring(ls.Wins.Value) or "?")
        .. " | Cash: " .. (ls and ls:FindFirstChild("Cash") and tostring(ls.Cash.Value) or "?")
        .. " | CP: " .. (cp and tostring(cp.Value) or "0")
})

MiscTab:CreateButton({
    Name = "TP to Lobby",
    Callback = function()
        local lobby = workspace:FindFirstChild("Lobby")
        if lobby then
            local sp = lobby:FindFirstChildWhichIsA("SpawnLocation", true)
            local target = sp or lobby:FindFirstChildWhichIsA("BasePart")
            if target then teleport(target.CFrame + Vector3.new(0, 4, 0)) end
            Rayfield:Notify({Title = "Lobby", Content = "Back to spawn", Duration = 2, Image = "home"})
        end
    end,
})

---------------------------------------------------------------
Rayfield:Notify({
    Title = "Glass Bridge Loaded",
    Content = "ESP, autowalk, farm, teleports, speed",
    Duration = 4,
    Image = "shield",
})
