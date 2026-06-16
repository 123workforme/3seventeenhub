-- Underground War Standalone (3seventeen)
-- Cleanup previous execution
if _G._3seventeen_uw_cleanup then
    pcall(_G._3seventeen_uw_cleanup)
end

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
    Name = "3seventeen - Underground War",
    Icon = "crosshair",
    LoadingTitle = "3seventeen",
    LoadingSubtitle = "underground war",
    Theme = MidnightGold,
    ScriptID = "sid_hq5cz7d0mmat",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = true,
    ConfigurationSaving = { Enabled = true, FolderName = "3seventeen", FileName = "3seventeen_uw_cfg" },
    KeySystem = false,
})

-- Services
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local UIS = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ShotTarget = RS.Events.Remote.ShotTarget

-- State
local aimbotEnabled = false
local aimbotFOV = 200
local triggerBotEnabled = false
local triggerBotCooldown = 1.5
local espEnabled = false
local killAuraEnabled = false
local speedEnabled = false
local noclipEnabled = false
local speedValue = 32
local aimbotActive = false
local lastFireTime = 0

local connections = {}
local espObjects = {}

-- Utilities
local function addConn(tag, conn)
    connections[tag] = connections[tag] or {}
    table.insert(connections[tag], conn)
end

local function cleanupTag(tag)
    if connections[tag] then
        for _, conn in ipairs(connections[tag]) do
            pcall(function() conn:Disconnect() end)
        end
        connections[tag] = nil
    end
end

local function getLocalRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getEnemyTeamColor()
    local myColor = LocalPlayer.TeamColor
    if myColor == BrickColor.new("Cyan") then
        return BrickColor.new("Persimmon")
    else
        return BrickColor.new("Cyan")
    end
end

local function isEnemy(player)
    if not player or player == LocalPlayer then return false end
    return player.TeamColor ~= LocalPlayer.TeamColor
end

local function isVisible(targetPart)
    local root = getLocalRoot()
    if not root or not targetPart then return false end
    local char = LocalPlayer.Character

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local origin = Camera.CFrame.Position
    local dir = (targetPart.Position - origin)
    local result = workspace:Raycast(origin, dir, rayParams)

    if result and result.Instance then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return false
end

local function getClosestVisibleEnemy()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closest, closestAngle = nil, aimbotFOV

    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) then
            local char = plr.Character
            if char then
                local head = char:FindFirstChild("Head")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if head and hum and hum.Health > 0 then
                    local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
                    if onScreen then
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if screenDist < closestAngle then
                            if isVisible(head) then
                                closest = head
                                closestAngle = screenDist
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

------------------------------------------------------------
-- AIMBOT (Instant Snap + Namecall Hook + Triggerbot)
------------------------------------------------------------

-- Namecall hook: ensures any ShotTarget fire goes to the locked target
local lockedTarget = nil

if not _G._3seventeen_uw_namecall then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and self == ShotTarget and aimbotEnabled and lockedTarget then
            local args = {...}
            local weaponType = args[2]
            if weaponType == "Sniper" or weaponType == "Rocket" then
                args[1] = lockedTarget.Position
                return oldNamecall(self, unpack(args))
            end
        end
        return oldNamecall(self, ...)
    end))
    _G._3seventeen_uw_namecall = true
end

local function startAimbot()
    cleanupTag("aimbot")

    -- Right click = lock on
    addConn("aimbot", UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            aimbotActive = true
        end
    end))

    addConn("aimbot", UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            aimbotActive = false
            lockedTarget = nil
        end
    end))

    -- Instant camera snap every render frame
    addConn("aimbot", RunService.RenderStepped:Connect(function()
        if not aimbotEnabled or not aimbotActive then
            lockedTarget = nil
            return
        end

        local target = getClosestVisibleEnemy()
        if not target then
            lockedTarget = nil
            return
        end

        lockedTarget = target
        local camPos = Camera.CFrame.Position
        Camera.CFrame = CFrame.lookAt(camPos, target.Position)
    end))
end

------------------------------------------------------------
-- TRIGGERBOT (Auto-fire ShotTarget at visible enemies)
------------------------------------------------------------
local function startTriggerBot()
    cleanupTag("triggerbot")

    addConn("triggerbot", RunService.Heartbeat:Connect(function()
        if not triggerBotEnabled then return end
        if tick() - lastFireTime < triggerBotCooldown then return end

        local target = getClosestVisibleEnemy()
        if not target then return end

        lastFireTime = tick()
        ShotTarget:FireServer(target.Position, "Sniper")
    end))
end

------------------------------------------------------------
-- ENEMY ESP
------------------------------------------------------------
local function clearESP()
    for _, obj in pairs(espObjects) do
        pcall(function() obj:Destroy() end)
    end
    espObjects = {}
end

local function createESPForPlayer(plr)
    if not isEnemy(plr) then return end
    local char = plr.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    local key = plr.Name

    if espObjects[key] then
        pcall(function() espObjects[key]:Destroy() end)
    end

    local bb = Instance.new("BillboardGui")
    bb.Name = "_3seventeen_uw_esp"
    bb.Adornee = head
    bb.Size = UDim2.new(0, 120, 0, 40)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head

    local label = Instance.new("TextLabel")
    label.Name = "Info"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextStrokeTransparency = 0.4
    label.TextColor3 = plr.TeamColor == BrickColor.new("Persimmon")
        and Color3.fromRGB(255, 80, 80)
        or Color3.fromRGB(80, 180, 255)
    label.Text = plr.Name
    label.Parent = bb

    local highlight = Instance.new("Highlight")
    highlight.Name = "_3seventeen_uw_hl"
    highlight.FillColor = label.TextColor3
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = label.TextColor3
    highlight.OutlineTransparency = 0.3
    highlight.Parent = char

    espObjects[key] = bb
    espObjects[key .. "_hl"] = highlight
end

local function refreshESP()
    clearESP()
    if not espEnabled then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        createESPForPlayer(plr)
    end
end

local function startESPUpdater()
    cleanupTag("esp_updater")

    addConn("esp_updater", RunService.Heartbeat:Connect(function()
        if not espEnabled then return end
        local root = getLocalRoot()
        if not root then return end

        for _, plr in ipairs(Players:GetPlayers()) do
            if isEnemy(plr) then
                local key = plr.Name
                local bb = espObjects[key]
                if bb and bb.Parent then
                    local char = plr.Character
                    local head = char and char:FindFirstChild("Head")
                    if head then
                        local dist = math.floor((head.Position - root.Position).Magnitude)
                        local lbl = bb:FindFirstChild("Info")
                        if lbl then
                            lbl.Text = plr.Name .. " [" .. dist .. "m]"
                        end
                    end
                else
                    createESPForPlayer(plr)
                end
            end
        end
    end))

    addConn("esp_updater", Players.PlayerAdded:Connect(function(plr)
        task.wait(2)
        if espEnabled then createESPForPlayer(plr) end
    end))

    addConn("esp_updater", Players.PlayerRemoving:Connect(function(plr)
        local key = plr.Name
        if espObjects[key] then
            pcall(function() espObjects[key]:Destroy() end)
            espObjects[key] = nil
        end
        if espObjects[key .. "_hl"] then
            pcall(function() espObjects[key .. "_hl"]:Destroy() end)
            espObjects[key .. "_hl"] = nil
        end
    end))
end

------------------------------------------------------------
-- SWORD KILL AURA
------------------------------------------------------------
local function startKillAura()
    cleanupTag("kill_aura")
    addConn("kill_aura", RunService.Heartbeat:Connect(function()
        if not killAuraEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        local sword = char:FindFirstChild("Sword")
        if not sword then return end
        local handle = sword:FindFirstChild("Handle")
        if not handle then return end

        local root = getLocalRoot()
        if not root then return end

        for _, plr in ipairs(Players:GetPlayers()) do
            if isEnemy(plr) then
                local eChar = plr.Character
                if eChar then
                    local eTorso = eChar:FindFirstChild("Torso") or eChar:FindFirstChild("HumanoidRootPart")
                    local eHum = eChar:FindFirstChildOfClass("Humanoid")
                    if eTorso and eHum and eHum.Health > 0 then
                        local dist = (eTorso.Position - root.Position).Magnitude
                        if dist <= 15 then
                            firetouchinterest(handle, eTorso, 0)
                            task.defer(function()
                                firetouchinterest(handle, eTorso, 1)
                            end)
                        end
                    end
                end
            end
        end
    end))
end

------------------------------------------------------------
-- SPEED BOOST
------------------------------------------------------------
local function applySpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = speedEnabled and speedValue or 16
    end
end

local function startSpeedLoop()
    cleanupTag("speed")
    addConn("speed", RunService.Heartbeat:Connect(function()
        if speedEnabled then applySpeed() end
    end))
    addConn("speed", LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if speedEnabled then applySpeed() end
    end))
end

------------------------------------------------------------
-- NOCLIP
------------------------------------------------------------
local function startNoclip()
    cleanupTag("noclip")
    addConn("noclip", RunService.Stepped:Connect(function()
        if not noclipEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end))
end

------------------------------------------------------------
-- UI SETUP
------------------------------------------------------------
local CombatTab = Window:CreateTab("Combat", "swords")
local VisualsTab = Window:CreateTab("Visuals", "eye")
local MovementTab = Window:CreateTab("Movement", "zap")
local MiscTab = Window:CreateTab("Misc", "settings")

-- Combat Tab
CombatTab:CreateToggle({
    Name = isPaid and "Aimbot (Hold Right Click)" or "Aimbot [PRO]",
    CurrentValue = false,
    Flag = "Aimbot",
    Callback = function(val)
        if not isPaid then Rayfield:Notify({Title="Premium Only", Content="Aimbot requires a premium key.", Duration=3}) return end
        aimbotEnabled = val
        if val then
            Rayfield:Notify({
                Title = "Aimbot",
                Content = "Hold Right Click to snap onto visible enemies. Also hooks shot remote.",
                Duration = 4,
            })
        end
    end,
})

CombatTab:CreateSlider({
    Name = "Aimbot FOV (Screen Pixels)",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 200,
    Flag = "AimbotFOV",
    Callback = function(val)
        aimbotFOV = val
    end,
})

CombatTab:CreateToggle({
    Name = isPaid and "Triggerbot (Auto-Fire at Visible Enemies)" or "Triggerbot [PRO]",
    CurrentValue = false,
    Flag = "TriggerBot",
    Callback = function(val)
        if not isPaid then Rayfield:Notify({Title="Premium Only", Content="Triggerbot requires a premium key.", Duration=3}) return end
        triggerBotEnabled = val
        if val then
            Rayfield:Notify({
                Title = "Triggerbot",
                Content = "Auto-fires sniper at any visible enemy. No need to click.",
                Duration = 4,
            })
        end
    end,
})

CombatTab:CreateSlider({
    Name = "Triggerbot Fire Rate (seconds)",
    Range = {0.5, 3},
    Increment = 0.1,
    CurrentValue = 1.5,
    Flag = "TriggerRate",
    Callback = function(val)
        triggerBotCooldown = val
    end,
})

CombatTab:CreateToggle({
    Name = isPaid and "Sword Kill Aura" or "Sword Kill Aura [PRO]",
    CurrentValue = false,
    Flag = "KillAura",
    Callback = function(val)
        if not isPaid then Rayfield:Notify({Title="Premium Only", Content="Kill Aura requires a premium key.", Duration=3}) return end
        killAuraEnabled = val
        if val then
            Rayfield:Notify({
                Title = "Kill Aura",
                Content = "Equip your Sword to auto-hit nearby enemies",
                Duration = 3,
            })
        end
    end,
})

-- Visuals Tab
VisualsTab:CreateToggle({
    Name = "Enemy ESP",
    CurrentValue = false,
    Flag = "EnemyESP",
    Callback = function(val)
        espEnabled = val
        if val then
            refreshESP()
        else
            clearESP()
        end
    end,
})

-- Movement Tab
MovementTab:CreateToggle({
    Name = "Speed Boost",
    CurrentValue = false,
    Flag = "SpeedBoost",
    Callback = function(val)
        speedEnabled = val
        if not val then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end
        end
    end,
})

MovementTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 80},
    Increment = 2,
    CurrentValue = 32,
    Flag = "WalkSpeedSlider",
    Callback = function(val)
        speedValue = val
        if speedEnabled then applySpeed() end
    end,
})

MovementTab:CreateToggle({
    Name = "Noclip (Phase through walls/dirt)",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(val)
        noclipEnabled = val
    end,
})

-- Misc Tab
local savedWaypoints = {}

MiscTab:CreateButton({
    Name = "Set Waypoint",
    Callback = function()
        local root = getLocalRoot()
        if not root then
            Rayfield:Notify({Title = "Waypoint", Content = "No character found", Duration = 2})
            return
        end
        local pos = root.CFrame
        local name = "WP " .. #savedWaypoints + 1
        table.insert(savedWaypoints, {Name = name, CFrame = pos})
        Rayfield:Notify({
            Title = "Waypoint Set",
            Content = name .. " saved at your current position",
            Duration = 3,
        })
    end,
})

MiscTab:CreateButton({
    Name = "TP to Last Waypoint",
    Callback = function()
        if #savedWaypoints == 0 then
            Rayfield:Notify({Title = "Waypoint", Content = "No waypoints saved yet", Duration = 2})
            return
        end
        local root = getLocalRoot()
        if not root then return end
        local wp = savedWaypoints[#savedWaypoints]
        root.CFrame = wp.CFrame
        Rayfield:Notify({Title = "Teleported", Content = "Moved to " .. wp.Name, Duration = 2})
    end,
})

MiscTab:CreateButton({
    Name = "TP to Waypoint 1",
    Callback = function()
        if not savedWaypoints[1] then
            Rayfield:Notify({Title = "Waypoint", Content = "Waypoint 1 not set", Duration = 2})
            return
        end
        local root = getLocalRoot()
        if not root then return end
        root.CFrame = savedWaypoints[1].CFrame
        Rayfield:Notify({Title = "Teleported", Content = "Moved to " .. savedWaypoints[1].Name, Duration = 2})
    end,
})

MiscTab:CreateButton({
    Name = "TP to Waypoint 2",
    Callback = function()
        if not savedWaypoints[2] then
            Rayfield:Notify({Title = "Waypoint", Content = "Waypoint 2 not set", Duration = 2})
            return
        end
        local root = getLocalRoot()
        if not root then return end
        root.CFrame = savedWaypoints[2].CFrame
        Rayfield:Notify({Title = "Teleported", Content = "Moved to " .. savedWaypoints[2].Name, Duration = 2})
    end,
})

MiscTab:CreateButton({
    Name = "TP to Waypoint 3",
    Callback = function()
        if not savedWaypoints[3] then
            Rayfield:Notify({Title = "Waypoint", Content = "Waypoint 3 not set", Duration = 2})
            return
        end
        local root = getLocalRoot()
        if not root then return end
        root.CFrame = savedWaypoints[3].CFrame
        Rayfield:Notify({Title = "Teleported", Content = "Moved to " .. savedWaypoints[3].Name, Duration = 2})
    end,
})

MiscTab:CreateButton({
    Name = "Clear All Waypoints",
    Callback = function()
        savedWaypoints = {}
        Rayfield:Notify({Title = "Waypoints", Content = "All waypoints cleared", Duration = 2})
    end,
})

MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
    end,
})

MiscTab:CreateButton({
    Name = "Rejoin (New Server)",
    Callback = function()
        TeleportService:Teleport(game.PlaceId)
    end,
})

------------------------------------------------------------
-- INIT SYSTEMS
------------------------------------------------------------
startAimbot()
startTriggerBot()
startESPUpdater()
startKillAura()
startSpeedLoop()
startNoclip()

------------------------------------------------------------
-- CLEANUP FUNCTION
------------------------------------------------------------
_G._3seventeen_uw_cleanup = function()
    for tag, conns in pairs(connections) do
        for _, conn in ipairs(conns) do
            pcall(function() conn:Disconnect() end)
        end
    end
    connections = {}
    clearESP()
    pcall(function() Rayfield:Destroy() end)
end

Rayfield:Notify({
    Title = "3seventeen",
    Content = "Underground War loaded successfully",
    Duration = 4,
})
