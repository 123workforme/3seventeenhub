-- Cleanup previous instance
if _G._3seventeen_toh_cleanup then
    pcall(_G._3seventeen_toh_cleanup)
end
do
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
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "3seventeen | Tower of Hell",
    Icon = 0,
    LoadingTitle = "3seventeen Hub",
    LoadingSubtitle = "Tower of Hell",
    Theme = "Default",

    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "3seventeen",
        FileName = "TOH_Config"
    }
})

-- ═══════════════════════════════════════════════════════════
-- UTILITIES
-- ═══════════════════════════════════════════════════════════

local Conns = {}

local function getChar()
    return LocalPlayer.Character
end

local function getRoot()
    local char = getChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getTower()
    return workspace:FindFirstChild("tower")
end

local function getSections()
    local tower = getTower()
    if not tower then return {} end
    local sectionsFolder = tower:FindFirstChild("sections")
    if not sectionsFolder then return {} end

    local sections = {}
    for _, child in ipairs(sectionsFolder:GetChildren()) do
        if child:IsA("Model") and child:FindFirstChild("i") then
            local idx = child:FindFirstChild("i").Value
            local start = child:FindFirstChild("start")
            local stop = child:FindFirstChild("stop")
            table.insert(sections, {
                Model = child,
                Name = child.Name,
                Index = idx,
                Start = start,
                Stop = stop
            })
        end
    end
    table.sort(sections, function(a, b) return a.Index < b.Index end)
    return sections
end

local function getSectionNames()
    local sections = getSections()
    local names = {}
    for _, s in ipairs(sections) do
        if s.Name ~= "lobby" and s.Name ~= "finish" then
            table.insert(names, s.Name)
        end
    end
    return names
end

-- ═══════════════════════════════════════════════════════════
-- TELEPORT TO SECTION (incremental to avoid anti-cheat)
-- ═══════════════════════════════════════════════════════════

local TPing = false

local function tpToTop()
    if TPing then return end
    local root = getRoot()
    if not root then return end

    TPing = true
    Rayfield:Notify({
        Title = "Teleporting...",
        Content = "Climbing to the top!",
        Duration = 3
    })

    local sections = getSections()
    local myY = root.Position.Y

    for _, s in ipairs(sections) do
        if s.Start and s.Start.Position.Y > myY + 5 then
            root = getRoot()
            if not root then break end
            root.CFrame = s.Start.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.5)
        end
    end

    TPing = false
end

-- ═══════════════════════════════════════════════════════════
-- SPEED / JUMP BOOST
-- ═══════════════════════════════════════════════════════════

local SpeedEnabled = false
local SpeedValue = 22
local JumpEnabled = false
local JumpValue = 65

local function applyMovement()
    local hum = getHumanoid()
    if not hum then return end
    if SpeedEnabled then hum.WalkSpeed = SpeedValue end
    if JumpEnabled then hum.JumpPower = JumpValue end
end

local function resetMovement()
    local hum = getHumanoid()
    if not hum then return end
    if not SpeedEnabled then hum.WalkSpeed = 16 end
    if not JumpEnabled then hum.JumpPower = 50 end
end

-- ═══════════════════════════════════════════════════════════
-- LOW GRAVITY
-- ═══════════════════════════════════════════════════════════

local LowGravEnabled = false
local OriginalGravity = workspace.Gravity

local function setLowGrav(enabled)
    if enabled then
        OriginalGravity = workspace.Gravity
        workspace.Gravity = 80
    else
        workspace.Gravity = OriginalGravity or 196.2
    end
end

-- ═══════════════════════════════════════════════════════════
-- NO KILL BRICKS
-- ═══════════════════════════════════════════════════════════

local NoKillEnabled = false
local KillBrickConns = {}
local OriginalCanCollide = {}

local function isKillBrick(part)
    if not part:IsA("BasePart") then return false end
    local name = part.Name:lower()
    return name == "damage brick" or name == "killpart" or name == "killbrick"
        or name == "kill" or name == "damage" or name:find("kill")
end

local function disableKillBricks()
    local tower = getTower()
    if not tower then return end

    for _, desc in ipairs(tower:GetDescendants()) do
        if isKillBrick(desc) then
            OriginalCanCollide[desc] = desc.CanCollide
            desc.CanCollide = false
            desc.Transparency = 0.7
        end
    end

    local conn = tower.DescendantAdded:Connect(function(desc)
        if not NoKillEnabled then return end
        task.wait(0.1)
        if isKillBrick(desc) then
            OriginalCanCollide[desc] = desc.CanCollide
            desc.CanCollide = false
            desc.Transparency = 0.7
        end
    end)
    table.insert(KillBrickConns, conn)
end

local function enableKillBricks()
    for _, conn in ipairs(KillBrickConns) do
        pcall(function() conn:Disconnect() end)
    end
    KillBrickConns = {}

    for part, collide in pairs(OriginalCanCollide) do
        if part and part.Parent then
            part.CanCollide = collide
            part.Transparency = 0
        end
    end
    OriginalCanCollide = {}
end

-- ═══════════════════════════════════════════════════════════
-- NOCLIP
-- ═══════════════════════════════════════════════════════════

local NoclipEnabled = false

local function doNoclip()
    if not NoclipEnabled then return end
    local char = getChar()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- SECTION ESP
-- ═══════════════════════════════════════════════════════════

local SectionESPEnabled = false
local SectionBillboards = {}

local function clearSectionESP()
    for _, obj in ipairs(SectionBillboards) do
        pcall(game.Destroy, obj)
    end
    SectionBillboards = {}
end

local function createSectionESP()
    clearSectionESP()
    if not SectionESPEnabled then return end

    local sections = getSections()
    for _, s in ipairs(sections) do
        if s.Name ~= "lobby" and s.Start then
            local bb = Instance.new("BillboardGui")
            bb.Name = "_3seventeen_SectionBB"
            bb.Adornee = s.Start
            bb.Size = UDim2.new(0, 200, 0, 40)
            bb.StudsOffset = Vector3.new(0, 5, 0)
            bb.AlwaysOnTop = true
            bb.Parent = s.Start

            local label = Instance.new("TextLabel")
            label.Name = "Info"
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamBold
            label.TextSize = 14
            label.TextStrokeTransparency = 0.3
            label.TextStrokeColor3 = Color3.new(0, 0, 0)
            label.Parent = bb

            if s.Name == "finish" then
                label.TextColor3 = Color3.fromRGB(255, 215, 0)
                label.Text = "FINISH"
            else
                label.TextColor3 = Color3.fromRGB(100, 200, 255)
                label.Text = string.format("[%d] %s", s.Index - 1, s.Name)
            end

            table.insert(SectionBillboards, bb)
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- MAIN LOOP
-- ═══════════════════════════════════════════════════════════

local HeartbeatConn = RunService.Heartbeat:Connect(function()
    if SpeedEnabled or JumpEnabled then applyMovement() end
    if NoclipEnabled then doNoclip() end
end)

-- Refresh on respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if SpeedEnabled or JumpEnabled then applyMovement() end
    if NoKillEnabled then disableKillBricks() end
    if SectionESPEnabled then createSectionESP() end
end)

-- Refresh ESP when tower rebuilds
workspace.ChildAdded:Connect(function(child)
    if child.Name == "tower" then
        task.wait(3)
        if SectionESPEnabled then createSectionESP() end
        if NoKillEnabled then disableKillBricks() end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- UI TABS
-- ═══════════════════════════════════════════════════════════

local MovementTab = Window:CreateTab("Movement", "zap")
local TeleportTab = Window:CreateTab("Teleport", "map-pin")
local VisualTab = Window:CreateTab("Visual", "eye")
local MiscTab = Window:CreateTab("Misc", "settings")

-- ── Movement Tab ──

MovementTab:CreateToggle({
    Name = "Speed Boost",
    CurrentValue = false,
    Flag = "toh_speed",
    Callback = function(v)
        SpeedEnabled = v
        if v then applyMovement() else resetMovement() end
    end
})

MovementTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 50},
    Increment = 1,
    Suffix = "",
    CurrentValue = 22,
    Flag = "toh_speed_val",
    Callback = function(v)
        SpeedValue = v
        if SpeedEnabled then applyMovement() end
    end
})

MovementTab:CreateToggle({
    Name = "Jump Boost",
    CurrentValue = false,
    Flag = "toh_jump",
    Callback = function(v)
        JumpEnabled = v
        if v then applyMovement() else resetMovement() end
    end
})

MovementTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 120},
    Increment = 5,
    Suffix = "",
    CurrentValue = 65,
    Flag = "toh_jump_val",
    Callback = function(v)
        JumpValue = v
        if JumpEnabled then applyMovement() end
    end
})

MovementTab:CreateToggle({
    Name = "Low Gravity",
    CurrentValue = false,
    Flag = "toh_lowgrav",
    Callback = function(v)
        LowGravEnabled = v
        setLowGrav(v)
    end
})

MovementTab:CreateToggle({
    Name = isPaid and "Noclip" or "Noclip [PRO]",
    CurrentValue = false,
    Flag = "toh_noclip",
    Callback = function(v)
        if not isPaid then Rayfield:Notify({Title="Premium Only", Content="Noclip requires a premium key.", Duration=3}) return end
        NoclipEnabled = v
        if not v then
            local char = getChar()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
})

MovementTab:CreateToggle({
    Name = isPaid and "No Kill Bricks" or "No Kill Bricks [PRO]",
    CurrentValue = false,
    Flag = "toh_nokill",
    Callback = function(v)
        if not isPaid then Rayfield:Notify({Title="Premium Only", Content="No Kill Bricks requires a premium key.", Duration=3}) return end
        NoKillEnabled = v
        if v then
            disableKillBricks()
        else
            enableKillBricks()
        end
    end
})

-- ── Teleport Tab ──

TeleportTab:CreateButton({
    Name = isPaid and "TP to Top (Chain)" or "TP to Top [PRO]",
    Callback = function()
        if not isPaid then Rayfield:Notify({Title="Premium Only", Content="TP to Top requires a premium key.", Duration=3}) return end
        tpToTop()
    end
})

TeleportTab:CreateButton({
    Name = isPaid and "TP to Next Section Above" or "TP to Next Section [PRO]",
    Callback = function()
        if not isPaid then Rayfield:Notify({Title="Premium Only", Content="Section TP requires a premium key.", Duration=3}) return end
        local root = getRoot()
        if not root then return end
        local myY = root.Position.Y
        local sections = getSections()
        for _, s in ipairs(sections) do
            if s.Start and s.Start.Position.Y > myY + 5 then
                root.CFrame = s.Start.CFrame + Vector3.new(0, 3, 0)
                Rayfield:Notify({
                    Title = "Teleported",
                    Content = "TP'd to: " .. s.Name,
                    Duration = 2
                })
                return
            end
        end
    end
})

-- ── Visual Tab ──

VisualTab:CreateToggle({
    Name = "Section ESP",
    CurrentValue = false,
    Flag = "toh_section_esp",
    Callback = function(v)
        SectionESPEnabled = v
        if v then createSectionESP() else clearSectionESP() end
    end
})

-- ── Misc Tab ──

MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

-- ═══════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════

_G._3seventeen_toh_cleanup = function()
    pcall(function() HeartbeatConn:Disconnect() end)
    clearSectionESP()
    enableKillBricks()
    setLowGrav(false)
end

Rayfield:Notify({
    Title = "3seventeen | ToH",
    Content = "Loaded! Tower of Hell script active.",
    Duration = 4,
    Image = "rbxassetid://4483345998"
})
