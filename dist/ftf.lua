-- Cleanup previous instance
if _G._3seventeen_ftf_cleanup then
    pcall(_G._3seventeen_ftf_cleanup)
end

do
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:find("_3seventeen_") then pcall(game.Destroy, obj) end
    end
    for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
        if plr.Character then
            for _, obj in ipairs(plr.Character:GetDescendants()) do
                if obj.Name:find("_3seventeen_") then pcall(game.Destroy, obj) end
            end
        end
    end
    local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        for _, gui in ipairs(pg:GetChildren()) do
            if gui.Name == "Rayfield" then pcall(game.Destroy, gui) end
        end
    end
end

local tier = _G._3seventeen_tier or "free"
local isPaid = (tier == "paid")

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "3seventeen | Flee the Facility",
    Icon = 0,
    LoadingTitle = "3seventeen Hub",
    LoadingSubtitle = "Flee the Facility",
    Theme = "Default",

    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "3seventeen",
        FileName = "FTF_Config"
    }
})

-- ═══════════════════════════════════════════════════════════
-- UTILITIES
-- ═══════════════════════════════════════════════════════════

local Conns = {}
local ESPObjects = {}
local ComputerBillboards = {}

local function cleanup(tag)
    if Conns[tag] then
        for _, c in ipairs(Conns[tag]) do pcall(function() c:Disconnect() end) end
        Conns[tag] = nil
    end
end

local function addConn(tag, conn)
    if not Conns[tag] then Conns[tag] = {} end
    table.insert(Conns[tag], conn)
end

local function getMap()
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") then
            if child:FindFirstChild("ComputerTable") or child:FindFirstChild("ExitDoor") or child:FindFirstChild("FreezePod") then
                return child
            end
        end
    end
    return nil
end

local function getTempStats(plr)
    return plr:FindFirstChild("TempPlayerStatsModule")
end

local function isBeast(plr)
    local temp = getTempStats(plr)
    if temp then
        local val = temp:FindFirstChild("IsBeast")
        return val and val.Value == true
    end
    return false
end

local function getBeast()
    for _, plr in ipairs(Players:GetPlayers()) do
        if isBeast(plr) then return plr end
    end
    return nil
end

local function getLocalRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function distanceTo(pos)
    local root = getLocalRoot()
    if root then return (root.Position - pos).Magnitude end
    return math.huge
end

-- ═══════════════════════════════════════════════════════════
-- BEAST ESP
-- ═══════════════════════════════════════════════════════════

local BeastESPEnabled = false
local BeastHighlight = nil
local BeastBillboard = nil

local function clearBeastESP()
    if BeastHighlight then pcall(game.Destroy, BeastHighlight) end
    if BeastBillboard then pcall(game.Destroy, BeastBillboard) end
    BeastHighlight = nil
    BeastBillboard = nil
end

local function createBeastESP(beast)
    clearBeastESP()
    if not beast or not beast.Character then return end

    BeastHighlight = Instance.new("Highlight")
    BeastHighlight.Name = "_3seventeen_BeastHL"
    BeastHighlight.FillColor = Color3.fromRGB(255, 0, 0)
    BeastHighlight.OutlineColor = Color3.fromRGB(180, 0, 0)
    BeastHighlight.FillTransparency = 0.3
    BeastHighlight.OutlineTransparency = 0
    BeastHighlight.Adornee = beast.Character
    BeastHighlight.Parent = beast.Character

    local head = beast.Character:FindFirstChild("Head")
    if head then
        BeastBillboard = Instance.new("BillboardGui")
        BeastBillboard.Name = "_3seventeen_BeastBB"
        BeastBillboard.Adornee = head
        BeastBillboard.Size = UDim2.new(0, 200, 0, 50)
        BeastBillboard.StudsOffset = Vector3.new(0, 3, 0)
        BeastBillboard.AlwaysOnTop = true
        BeastBillboard.Parent = head

        local label = Instance.new("TextLabel")
        label.Name = "Info"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 50, 50)
        label.TextStrokeTransparency = 0.3
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.Text = "BEAST"
        label.Parent = BeastBillboard
    end
end

local function updateBeastESP()
    if not BeastESPEnabled then return end
    local beast = getBeast()
    if not beast or not beast.Character then
        clearBeastESP()
        return
    end

    if not BeastHighlight or BeastHighlight.Parent ~= beast.Character then
        createBeastESP(beast)
    end

    if BeastBillboard then
        local head = beast.Character:FindFirstChild("Head")
        if head then
            local dist = distanceTo(head.Position)
            local lbl = BeastBillboard:FindFirstChild("Info")
            if lbl then
                lbl.Text = string.format("BEAST [%dm]", math.floor(dist))
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- COMPUTER ESP
-- ═══════════════════════════════════════════════════════════

local ComputerESPEnabled = false

local function clearComputerESP()
    for _, obj in ipairs(ComputerBillboards) do
        pcall(game.Destroy, obj)
    end
    ComputerBillboards = {}
end

local function createComputerESP()
    clearComputerESP()
    local map = getMap()
    if not map then return end

    for _, child in ipairs(map:GetChildren()) do
        if child.Name == "ComputerTable" then
            local screen = child:FindFirstChild("Screen")
            if screen then
                local bb = Instance.new("BillboardGui")
                bb.Name = "_3seventeen_CompBB"
                bb.Adornee = screen
                bb.Size = UDim2.new(0, 150, 0, 40)
                bb.StudsOffset = Vector3.new(0, 4, 0)
                bb.AlwaysOnTop = true
                bb.Parent = screen

                local label = Instance.new("TextLabel")
                label.Name = "Info"
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.TextColor3 = Color3.fromRGB(100, 200, 255)
                label.TextStrokeTransparency = 0.3
                label.TextStrokeColor3 = Color3.new(0, 0, 0)
                label.Font = Enum.Font.GothamBold
                label.TextSize = 13
                label.Text = "PC"
                label.Parent = bb

                table.insert(ComputerBillboards, bb)
            end
        end
    end
end

local function getActiveHackers()
    local hackers = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        local temp = getTempStats(plr)
        if temp then
            local ae = temp:FindFirstChild("ActionEvent")
            local prog = temp:FindFirstChild("ActionProgress")
            if ae and ae.Value and prog and prog.Value > 0 then
                hackers[ae.Value] = {Player = plr.Name, Progress = prog.Value}
            end
        end
    end
    return hackers
end

local function updateComputerESP()
    if not ComputerESPEnabled then return end
    local map = getMap()
    if not map then return end

    local hackers = getActiveHackers()

    local idx = 0
    for _, child in ipairs(map:GetChildren()) do
        if child.Name == "ComputerTable" then
            idx = idx + 1
            local screen = child:FindFirstChild("Screen")
            if screen and ComputerBillboards[idx] then
                local lbl = ComputerBillboards[idx]:FindFirstChild("Info")
                if lbl then
                    local dist = distanceTo(screen.Position)
                    local isGreen = screen.BrickColor == BrickColor.new("Dark green")
                        or screen.BrickColor == BrickColor.new("Bright green")

                    local hackerInfo = nil
                    for _, trigger in ipairs(child:GetChildren()) do
                        if trigger.Name:find("ComputerTrigger") then
                            local ev = trigger:FindFirstChild("Event")
                            if ev and hackers[ev] then
                                hackerInfo = hackers[ev]
                                break
                            end
                        end
                    end

                    if isGreen and not hackerInfo then
                        lbl.Text = string.format("DONE [%dm]", math.floor(dist))
                        lbl.TextColor3 = Color3.fromRGB(100, 255, 100)
                    elseif hackerInfo then
                        local pct = math.floor(hackerInfo.Progress * 100)
                        lbl.Text = string.format("HACKING %d%% [%dm]", pct, math.floor(dist))
                        lbl.TextColor3 = Color3.fromRGB(255, 255, 0)
                    else
                        lbl.Text = string.format("PC [%dm]", math.floor(dist))
                        lbl.TextColor3 = Color3.fromRGB(100, 200, 255)
                    end
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- EXIT DOOR ESP
-- ═══════════════════════════════════════════════════════════

local ExitESPEnabled = false
local ExitHighlights = {}

local function clearExitESP()
    for _, obj in ipairs(ExitHighlights) do
        pcall(game.Destroy, obj)
    end
    ExitHighlights = {}
end

local function createExitESP()
    clearExitESP()
    local map = getMap()
    if not map then return end

    for _, child in ipairs(map:GetChildren()) do
        if child.Name == "ExitDoor" then
            local door = child:FindFirstChild("Door")
            local part = door and door:FindFirstChildWhichIsA("BasePart") or child:FindFirstChildWhichIsA("BasePart")
            if part then
                local bb = Instance.new("BillboardGui")
                bb.Name = "_3seventeen_ExitBB"
                bb.Adornee = part
                bb.Size = UDim2.new(0, 150, 0, 40)
                bb.StudsOffset = Vector3.new(0, 6, 0)
                bb.AlwaysOnTop = true
                bb.Parent = part

                local label = Instance.new("TextLabel")
                label.Name = "Info"
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.TextColor3 = Color3.fromRGB(0, 255, 100)
                label.TextStrokeTransparency = 0.3
                label.TextStrokeColor3 = Color3.new(0, 0, 0)
                label.Font = Enum.Font.GothamBold
                label.TextSize = 14
                label.Text = "EXIT"
                label.Parent = bb

                table.insert(ExitHighlights, bb)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- PLAYER ESP (Survivors)
-- ═══════════════════════════════════════════════════════════

local PlayerESPEnabled = false
local PlayerHighlights = {}

local function clearPlayerESP()
    for _, obj in pairs(PlayerHighlights) do
        pcall(game.Destroy, obj)
    end
    PlayerHighlights = {}
end

local function refreshPlayerESP()
    clearPlayerESP()
    if not PlayerESPEnabled then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local beast = isBeast(plr)
            local head = plr.Character:FindFirstChild("Head")
            if head then
                local bb = Instance.new("BillboardGui")
                bb.Name = "_3seventeen_PlayerBB"
                bb.Adornee = head
                bb.Size = UDim2.new(0, 150, 0, 40)
                bb.StudsOffset = Vector3.new(0, 2.5, 0)
                bb.AlwaysOnTop = true
                bb.Parent = head

                local label = Instance.new("TextLabel")
                label.Name = "Info"
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.TextStrokeTransparency = 0.3
                label.TextStrokeColor3 = Color3.new(0, 0, 0)
                label.Font = Enum.Font.GothamBold
                label.TextSize = 13
                label.Parent = bb

                if beast then
                    label.Text = "BEAST"
                    label.TextColor3 = Color3.fromRGB(255, 50, 50)
                else
                    local temp = getTempStats(plr)
                    local captured = temp and temp:FindFirstChild("Captured")
                    if captured and captured.Value then
                        label.Text = plr.Name .. " [CAPTURED]"
                        label.TextColor3 = Color3.fromRGB(255, 150, 0)
                    else
                        label.Text = plr.Name
                        label.TextColor3 = Color3.fromRGB(100, 200, 255)
                    end
                end

                PlayerHighlights[plr.Name] = bb
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- BEAST PROXIMITY ALERT
-- ═══════════════════════════════════════════════════════════

local ProximityEnabled = false
local ProximityThreshold = 50
local LastAlertTick = 0

local function checkProximity()
    if not ProximityEnabled then return end
    local beast = getBeast()
    if not beast or not beast.Character then return end
    local beastRoot = beast.Character:FindFirstChild("HumanoidRootPart")
    if not beastRoot then return end

    local dist = distanceTo(beastRoot.Position)
    if dist <= ProximityThreshold and (tick() - LastAlertTick) > 3 then
        LastAlertTick = tick()
        Rayfield:Notify({
            Title = "BEAST NEARBY!",
            Content = string.format("%s is %dm away!", beast.Name, math.floor(dist)),
            Duration = 2.5,
            Image = "rbxassetid://4483345998"
        })
    end
end

-- ═══════════════════════════════════════════════════════════
-- AUTO-TIMING (Minigame) + AUTO-HACK
-- ═══════════════════════════════════════════════════════════

local AutoTimingEnabled = false
local AutoTimingThread = nil

local function setupAutoTiming()
    if AutoTimingThread then
        pcall(task.cancel, AutoTimingThread)
        AutoTimingThread = nil
    end
    if not AutoTimingEnabled then return end

    AutoTimingThread = task.spawn(function()
        while AutoTimingEnabled do
            local temp = getTempStats(LocalPlayer)
            if temp then
                local actionProgress = temp:FindFirstChild("ActionProgress")
                local currentAnim = temp:FindFirstChild("CurrentAnimation")
                local isHacking = (actionProgress and actionProgress.Value > 0)
                    or (currentAnim and currentAnim.Value == "Typing")

                if isHacking then
                    RS.RemoteEvent:FireServer("SetPlayerMinigameResult", true)
                end
            end
            task.wait(0.1)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- SPEED BOOST
-- ═══════════════════════════════════════════════════════════

local SpeedEnabled = false
local SpeedValue = 20

local function applySpeed()
    if not SpeedEnabled then return end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = SpeedValue end
    end
end

local function resetSpeed()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local temp = getTempStats(LocalPlayer)
        local normal = 16
        if temp then
            local nws = temp:FindFirstChild("NormalWalkSpeed")
            if nws then normal = nws.Value end
        end
        if hum then hum.WalkSpeed = normal end
    end
end

-- ═══════════════════════════════════════════════════════════
-- FULL BRIGHT
-- ═══════════════════════════════════════════════════════════

local FullBrightEnabled = false
local OriginalLighting = {}

local function enableFullBright()
    OriginalLighting.Ambient = Lighting.Ambient
    OriginalLighting.Brightness = Lighting.Brightness
    OriginalLighting.FogEnd = Lighting.FogEnd
    OriginalLighting.GlobalShadows = Lighting.GlobalShadows

    Lighting.Ambient = Color3.fromRGB(200, 200, 200)
    Lighting.Brightness = 2
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false

    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("DepthOfFieldEffect") then
            effect.Enabled = false
        end
    end
end

local function disableFullBright()
    if OriginalLighting.Ambient then
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
    end

    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("DepthOfFieldEffect") then
            effect.Enabled = true
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- HIDING SPOT ESP (Closets/Lockers)
-- ═══════════════════════════════════════════════════════════

local HidingESPEnabled = false
local HidingBillboards = {}

local function clearHidingESP()
    for _, obj in ipairs(HidingBillboards) do
        pcall(game.Destroy, obj)
    end
    HidingBillboards = {}
end

local function getClosetCenter(closet)
    local total = Vector3.new(0, 0, 0)
    local count = 0
    for _, part in ipairs(closet:GetChildren()) do
        if part:IsA("BasePart") then
            total = total + part.Position
            count = count + 1
        end
    end
    if count > 0 then return total / count end
    return nil
end

local function isGlassBooth(model)
    local parts = model:GetChildren()
    if #parts < 8 then return false end
    local transparentCount = 0
    local totalParts = 0
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") then
            totalParts = totalParts + 1
            if part.Transparency >= 0.4 and part.Transparency <= 0.6 then
                transparentCount = transparentCount + 1
            end
        end
    end
    return totalParts >= 8 and transparentCount == totalParts
end

local function getAllClosets()
    local closets = {}
    local map = getMap()
    if not map then return closets end

    local CS = game:GetService("CollectionService")
    local tagged = CS:GetTagged("LOCKER")
    if #tagged > 0 then
        for _, obj in ipairs(tagged) do
            if obj:IsDescendantOf(map) then
                local pos = nil
                if obj:IsA("BasePart") then
                    pos = obj.Position
                elseif obj:IsA("Model") then
                    pos = getClosetCenter(obj)
                end
                if pos then
                    table.insert(closets, {Model = obj, Center = pos, Type = "Locker"})
                end
            end
        end
    end

    if #closets > 0 then return closets end

    local hidingNames = {Closet = true, Locker = true, HidingLocker = true, Vent = true, Cabinet = true, Wardrobe = true}

    for _, child in ipairs(map:GetChildren()) do
        if child:IsA("Model") then
            if hidingNames[child.Name] then
                local center = getClosetCenter(child)
                if center then
                    table.insert(closets, {Model = child, Center = center, Type = child.Name})
                end
            elseif child.Name == "Model" and isGlassBooth(child) then
                local center = getClosetCenter(child)
                if center then
                    table.insert(closets, {Model = child, Center = center, Type = "Booth"})
                end
            end
        end
    end

    local ventsFolder = map:FindFirstChild("Vents")
    if ventsFolder then
        for _, vent in ipairs(ventsFolder:GetChildren()) do
            if vent:IsA("Model") then
                local center = getClosetCenter(vent)
                if center then
                    table.insert(closets, {Model = vent, Center = center, Type = "Vent"})
                end
            end
        end
    end

    local mapFolder = map:FindFirstChild("Map")
    if mapFolder then
        for _, child in ipairs(mapFolder:GetChildren()) do
            if child:IsA("Model") then
                if hidingNames[child.Name] then
                    local center = getClosetCenter(child)
                    if center then
                        table.insert(closets, {Model = child, Center = center, Type = child.Name})
                    end
                elseif child.Name == "Model" and isGlassBooth(child) then
                    local center = getClosetCenter(child)
                    if center then
                        table.insert(closets, {Model = child, Center = center, Type = "Booth"})
                    end
                end
            end
        end
    end

    return closets
end

local function getNearestCloset()
    local closets = getAllClosets()
    local nearest, nearestDist = nil, math.huge
    local root = getLocalRoot()
    if not root then return nil end
    for _, data in ipairs(closets) do
        local dist = (root.Position - data.Center).Magnitude
        if dist < nearestDist then
            nearest = data
            nearestDist = dist
        end
    end
    return nearest
end

local function createHidingESP()
    clearHidingESP()
    local closets = getAllClosets()

    for _, data in ipairs(closets) do
        local part = data.Model:FindFirstChildWhichIsA("BasePart")
        if part then
            local bb = Instance.new("BillboardGui")
            bb.Name = "_3seventeen_HideBB"
            bb.Adornee = part
            bb.Size = UDim2.new(0, 130, 0, 35)
            bb.StudsOffset = Vector3.new(0, 4, 0)
            bb.AlwaysOnTop = true
            bb.Parent = part

            local label = Instance.new("TextLabel")
            label.Name = "Info"
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(200, 100, 255)
            label.TextStrokeTransparency = 0.3
            label.TextStrokeColor3 = Color3.new(0, 0, 0)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.Text = data.Type:upper()
            label.Parent = bb

            table.insert(HidingBillboards, bb)
        end
    end
end

local function updateHidingESP()
    if not HidingESPEnabled then return end
    for _, bb in ipairs(HidingBillboards) do
        if bb.Parent and bb.Adornee then
            local lbl = bb:FindFirstChild("Info")
            if lbl then
                local dist = distanceTo(bb.Adornee.Position)
                local typeName = lbl.Text:match("^(%a+)") or "HIDE"
                lbl.Text = string.format("%s [%dm]", typeName, math.floor(dist))
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- ANTI-SEER (TP to Closet on Detection)
-- ═══════════════════════════════════════════════════════════

local AntiSeerEnabled = false
local AntiSeerConns = {}
local SavedPosition = nil

local function stopAntiSeer()
    for _, conn in ipairs(AntiSeerConns) do
        pcall(function() conn:Disconnect() end)
    end
    AntiSeerConns = {}
end

local function tpToCloset()
    if isBeast(LocalPlayer) then return end

    local root = getLocalRoot()
    if not root then return end

    local nearest = getNearestCloset()
    if not nearest then
        Rayfield:Notify({
            Title = "Anti-Seer",
            Content = "No hiding spots found on this map!",
            Duration = 2
        })
        return
    end

    SavedPosition = root.CFrame
    root.CFrame = CFrame.new(nearest.Center)

    Rayfield:Notify({
        Title = "Anti-Seer",
        Content = string.format("Teleported to hiding spot! (%dm away)", math.floor((SavedPosition.Position - nearest.Center).Magnitude)),
        Duration = 2.5
    })
end

local function startAntiSeer()
    stopAntiSeer()

    local DetectedEvent = RS:FindFirstChild("DetectedEvent")
    if DetectedEvent then
        local conn = DetectedEvent.OnClientEvent:Connect(function(detected, ...)
            if not AntiSeerEnabled then return end
            if detected == true then
                tpToCloset()
            end
        end)
        table.insert(AntiSeerConns, conn)
    end

    local PowerActive = RS:FindFirstChild("PowerActive")
    local CurrentPower = RS:FindFirstChild("CurrentPower")
    if PowerActive and CurrentPower then
        local conn = PowerActive.Changed:Connect(function(active)
            if not AntiSeerEnabled then return end
            if active and CurrentPower.Value == "Seer" then
                tpToCloset()
            end
        end)
        table.insert(AntiSeerConns, conn)
    end
end

-- ═══════════════════════════════════════════════════════════
-- MAIN UPDATE LOOP
-- ═══════════════════════════════════════════════════════════

local HeartbeatConn = RunService.Heartbeat:Connect(function()
    updateBeastESP()
    updateComputerESP()
    updateHidingESP()
    checkProximity()
    if SpeedEnabled then applySpeed() end
end)

-- ═══════════════════════════════════════════════════════════
-- GAME STATE LISTENERS
-- ═══════════════════════════════════════════════════════════

local function refreshAllESP()
    clearBeastESP()
    clearComputerESP()
    clearExitESP()
    clearPlayerESP()
    clearHidingESP()

    if BeastESPEnabled then
        local beast = getBeast()
        if beast then createBeastESP(beast) end
    end
    if ComputerESPEnabled then createComputerESP() end
    if ExitESPEnabled then createExitESP() end
    if PlayerESPEnabled then refreshPlayerESP() end
    if HidingESPEnabled then createHidingESP() end
    if AutoTimingEnabled then setupAutoTiming() end
end

local IsGameActive = RS:FindFirstChild("IsGameActive")
if IsGameActive then
    IsGameActive.Changed:Connect(function(val)
        if val then
            task.wait(4)
            refreshAllESP()
        else
            clearBeastESP()
            clearComputerESP()
            clearExitESP()
            clearPlayerESP()
            clearHidingESP()
        end
    end)
end

local ComputersLeftVal = RS:FindFirstChild("ComputersLeft")
if ComputersLeftVal then
    local lastVal = ComputersLeftVal.Value
    ComputersLeftVal.Changed:Connect(function(newVal)
        if newVal > lastVal then
            task.wait(4)
            refreshAllESP()
        end
        lastVal = newVal
    end)
end

workspace.ChildAdded:Connect(function(child)
    if child:IsA("Folder") or child:IsA("Model") then
        task.wait(3)
        if child:FindFirstChild("ComputerTable") or child:FindFirstChild("ExitDoor") or child:FindFirstChild("FreezePod") then
            task.wait(2)
            refreshAllESP()
        end
    end
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if PlayerESPEnabled then refreshPlayerESP() end
        if BeastESPEnabled then
            local beast = getBeast()
            if beast then createBeastESP(beast) end
        end
    end)
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        plr.CharacterAdded:Connect(function()
            task.wait(1)
            if PlayerESPEnabled then refreshPlayerESP() end
            if BeastESPEnabled and isBeast(plr) then createBeastESP(plr) end
        end)
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if SpeedEnabled then applySpeed() end
    if AutoTimingEnabled then setupAutoTiming() end
end)

-- ═══════════════════════════════════════════════════════════
-- UI TABS
-- ═══════════════════════════════════════════════════════════

local ESPTab = Window:CreateTab("ESP", "eye")
local GameplayTab = Window:CreateTab("Gameplay", "zap")
local MiscTab = Window:CreateTab("Misc", "settings")

-- ── ESP Tab ──

local ESPSection = ESPTab:CreateSection("ESP Controls")

ESPTab:CreateToggle({
    Name = "Beast ESP",
    CurrentValue = false,
    Flag = "ftf_beast_esp",
    Callback = function(v)
        BeastESPEnabled = v
        if v then
            local beast = getBeast()
            if beast then createBeastESP(beast) end
        else
            clearBeastESP()
        end
    end
})

ESPTab:CreateToggle({
    Name = "Computer ESP",
    CurrentValue = false,
    Flag = "ftf_computer_esp",
    Callback = function(v)
        ComputerESPEnabled = v
        if v then
            createComputerESP()
        else
            clearComputerESP()
        end
    end
})

ESPTab:CreateToggle({
    Name = "Exit Door ESP",
    CurrentValue = false,
    Flag = "ftf_exit_esp",
    Callback = function(v)
        ExitESPEnabled = v
        if v then
            createExitESP()
        else
            clearExitESP()
        end
    end
})

ESPTab:CreateToggle({
    Name = "Player ESP (Survivors)",
    CurrentValue = false,
    Flag = "ftf_player_esp",
    Callback = function(v)
        PlayerESPEnabled = v
        if v then
            refreshPlayerESP()
        else
            clearPlayerESP()
        end
    end
})

ESPTab:CreateToggle({
    Name = "Hiding Spot ESP (Closets)",
    CurrentValue = false,
    Flag = "ftf_hiding_esp",
    Callback = function(v)
        HidingESPEnabled = v
        if v then
            createHidingESP()
        else
            clearHidingESP()
        end
    end
})

-- ── Gameplay Tab ──

local GPSection = GameplayTab:CreateSection("Gameplay")

GameplayTab:CreateToggle({
    Name = isPaid and "Anti-Seer (TP to Closet)" or "Anti-Seer [PRO]",
    CurrentValue = false,
    Flag = "ftf_antiseer",
    Callback = function(v)
        if not isPaid then Rayfield:Notify({Title="Premium Only", Content="Anti-Seer requires a premium key.", Duration=3}) return end
        AntiSeerEnabled = v
        if v then
            startAntiSeer()
            Rayfield:Notify({
                Title = "Anti-Seer",
                Content = "Will TP you to nearest closet when Seer activates",
                Duration = 3
            })
        else
            stopAntiSeer()
        end
    end
})

GameplayTab:CreateButton({
    Name = "TP Back (After Anti-Seer)",
    Callback = function()
        if SavedPosition then
            local root = getLocalRoot()
            if root then
                root.CFrame = SavedPosition
                Rayfield:Notify({
                    Title = "Teleported Back",
                    Content = "Returned to previous position",
                    Duration = 2
                })
            end
            SavedPosition = nil
        else
            Rayfield:Notify({
                Title = "No Saved Position",
                Content = "Anti-Seer hasn't teleported you yet",
                Duration = 2
            })
        end
    end
})

GameplayTab:CreateToggle({
    Name = "Beast Proximity Alert",
    CurrentValue = false,
    Flag = "ftf_proximity",
    Callback = function(v)
        ProximityEnabled = v
    end
})

GameplayTab:CreateSlider({
    Name = "Alert Distance (studs)",
    Range = {20, 150},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = 50,
    Flag = "ftf_alert_dist",
    Callback = function(v)
        ProximityThreshold = v
    end
})

GameplayTab:CreateToggle({
    Name = isPaid and "Auto-Timing (Hack Minigame)" or "Auto-Timing [PRO]",
    CurrentValue = false,
    Flag = "ftf_autotiming",
    Callback = function(v)
        if not isPaid then Rayfield:Notify({Title="Premium Only", Content="Auto-Timing requires a premium key.", Duration=3}) return end
        AutoTimingEnabled = v
        if v then
            setupAutoTiming()
            Rayfield:Notify({
                Title = "Auto-Timing",
                Content = "Auto-passes every timing check while hacking",
                Duration = 3
            })
        else
            setupAutoTiming()
        end
    end
})

GameplayTab:CreateToggle({
    Name = "Speed Boost",
    CurrentValue = false,
    Flag = "ftf_speed",
    Callback = function(v)
        SpeedEnabled = v
        if v then
            applySpeed()
        else
            resetSpeed()
        end
    end
})

GameplayTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 40},
    Increment = 1,
    Suffix = "",
    CurrentValue = 20,
    Flag = "ftf_speed_val",
    Callback = function(v)
        SpeedValue = v
        if SpeedEnabled then applySpeed() end
    end
})

-- ── Misc Tab ──

local MiscSection = MiscTab:CreateSection("Visual")

MiscTab:CreateToggle({
    Name = "Full Bright",
    CurrentValue = false,
    Flag = "ftf_fullbright",
    Callback = function(v)
        FullBrightEnabled = v
        if v then
            enableFullBright()
        else
            disableFullBright()
        end
    end
})

MiscTab:CreateSection("Server")

MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

MiscTab:CreateSection("Info")

MiscTab:CreateParagraph({
    Title = "Game Status",
    Content = "Computers Left: " .. tostring(RS.ComputersLeft.Value) .. "\nStatus: " .. RS.GameStatus.Value
})

-- Auto-refresh game info
task.spawn(function()
    while task.wait(3) do
        if RS:FindFirstChild("ComputersLeft") and RS:FindFirstChild("GameStatus") then
            -- Update the paragraph if possible (Rayfield limitation - create notification instead)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════

_G._3seventeen_ftf_cleanup = function()
    pcall(function() HeartbeatConn:Disconnect() end)
    clearBeastESP()
    clearComputerESP()
    clearExitESP()
    clearPlayerESP()
    clearHidingESP()
    stopAntiSeer()
    if AutoTimingThread then pcall(task.cancel, AutoTimingThread) end
end

Rayfield:Notify({
    Title = "3seventeen | FTF",
    Content = "Loaded! Flee the Facility script active.",
    Duration = 4,
    Image = "rbxassetid://4483345998"
})

-- If a round is already active, set up ESP
if IsGameActive and IsGameActive.Value then
    task.wait(1)
    refreshAllESP()
end
