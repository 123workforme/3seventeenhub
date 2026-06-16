-- Guess My Game Standalone (3seventeen)
if _G._3seventeen_gmg_cleanup then
    pcall(_G._3seventeen_gmg_cleanup)
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
    Name = "3seventeen - Guess My Game",
    Icon = "brain",
    LoadingTitle = "3seventeen",
    LoadingSubtitle = "guess my game",
    Theme = MidnightGold,
    ScriptID = "sid_hq5cz7d0mmat",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = true,
    ConfigurationSaving = { Enabled = true, FolderName = "3seventeen", FileName = "3seventeen_gmg_cfg" },
    KeySystem = false,
})

-- Services
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Remotes = RS.Remotes

-- Build image -> name lookup from GameModeModule
local GameModeModule = require(RS.GameModeModule)
local imageToName = {}
for _, char in ipairs(GameModeModule.Characters) do
    imageToName[char.imageId] = char.name
end

-- State
local autoRevealEnabled = true
local answerDisplayEnabled = true
local currentAnswer = nil
local myTableIndex = nil
local connections = {}

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

------------------------------------------------------------
-- ANSWER DETECTION
------------------------------------------------------------
local function getMyTableIndex()
    local states = Remotes.GetAllTableStates:InvokeServer()
    for _, state in ipairs(states) do
        if state.player1 == LocalPlayer.Name or state.player2 == LocalPlayer.Name then
            return state.tableIndex
        end
    end
    return nil
end

local function scanBoardForAnswer(tableIndex)
    local tableName = "Table_" .. tableIndex
    local duelTables = workspace:FindFirstChild("DuelTables")
    if not duelTables then return nil end
    local tbl = duelTables:FindFirstChild(tableName)
    if not tbl then return nil end

    -- Determine which seat we're in, then read the OPPONENT's board
    local states = Remotes.GetAllTableStates:InvokeServer()
    local mySeat = nil
    for _, state in ipairs(states) do
        if state.tableIndex == tableIndex then
            if state.player1 == LocalPlayer.Name then
                mySeat = 1
            elseif state.player2 == LocalPlayer.Name then
                mySeat = 2
            end
            break
        end
    end

    if not mySeat then return nil end

    -- Opponent's board is the opposite one
    local opponentBoard = (mySeat == 1) and "Board2Grid" or "Board1Grid"
    local grid = tbl:FindFirstChild(opponentBoard)
    if not grid then return nil end

    for _, desc in ipairs(grid:GetDescendants()) do
        if desc:IsA("ImageLabel") and desc.Name == "CharacterImage" then
            local img = desc.Image
            if img and img ~= "" and imageToName[img] then
                return imageToName[img]
            end
        end
    end

    return nil
end

local function detectAndShowAnswer()
    myTableIndex = getMyTableIndex()
    if not myTableIndex then
        currentAnswer = nil
        return
    end

    currentAnswer = scanBoardForAnswer(myTableIndex)
    if currentAnswer and answerDisplayEnabled then
        Rayfield:Notify({
            Title = "ANSWER",
            Content = currentAnswer,
            Duration = 15,
        })
    end
end

------------------------------------------------------------
-- CLIENT-SIDE TILE REVEAL
------------------------------------------------------------
local function revealAllTiles()
    if not myTableIndex then
        myTableIndex = getMyTableIndex()
    end
    if not myTableIndex then return end

    local tableName = "Table_" .. myTableIndex
    local duelTables = workspace:FindFirstChild("DuelTables")
    if not duelTables then return end
    local tbl = duelTables:FindFirstChild(tableName)
    if not tbl then return end

    -- Determine opponent's board
    local states = Remotes.GetAllTableStates:InvokeServer()
    local mySeat = nil
    for _, state in ipairs(states) do
        if state.tableIndex == myTableIndex then
            if state.player1 == LocalPlayer.Name then
                mySeat = 1
            elseif state.player2 == LocalPlayer.Name then
                mySeat = 2
            end
            break
        end
    end
    if not mySeat then return end

    local opponentBoard = (mySeat == 1) and "Board2Grid" or "Board1Grid"
    local grid = tbl:FindFirstChild(opponentBoard)
    if not grid then return end

    for _, desc in ipairs(grid:GetDescendants()) do
        if desc:IsA("Decal") and desc.Name == "QMarkDecal" then
            desc.Transparency = 1
        end
        if desc:IsA("ImageLabel") and desc.Name == "CharacterImage" then
            desc.Visible = true
        end
    end
end

------------------------------------------------------------
-- EVENT LISTENERS
------------------------------------------------------------
local function setupListeners()
    cleanupTag("listeners")

    -- Listen for TileRevealStart (new round at our table)
    addConn("listeners", Remotes.TileRevealStart.OnClientEvent:Connect(function(data)
        task.wait(1)
        detectAndShowAnswer()
        if autoRevealEnabled then
            task.wait(0.5)
            revealAllTiles()
        end
    end))

    -- Listen for GuessPhaseStart (time to guess)
    addConn("listeners", Remotes.GuessPhaseStart.OnClientEvent:Connect(function(data)
        if not data or not data.isGuesser then return end

        task.wait(0.5)
        if not currentAnswer then
            detectAndShowAnswer()
        end
        if currentAnswer and answerDisplayEnabled then
            Rayfield:Notify({
                Title = "GUESS NOW",
                Content = currentAnswer,
                Duration = 10,
            })
        end
    end))

    -- Listen for MatchEnd (round over, reset)
    addConn("listeners", Remotes.MatchEnd.OnClientEvent:Connect(function(data)
        currentAnswer = nil
    end))

    -- Listen for RevealPhaseStart
    addConn("listeners", Remotes.RevealPhaseStart.OnClientEvent:Connect(function(data)
        task.wait(0.5)
        if not currentAnswer then
            detectAndShowAnswer()
        end
        if autoRevealEnabled then
            revealAllTiles()
        end
    end))

    -- Re-detect on table state changes
    addConn("listeners", Remotes.TableStateUpdate.OnClientEvent:Connect(function(data)
        if data and data.state == "InMatch" then
            if data.player1 == LocalPlayer.Name or data.player2 == LocalPlayer.Name then
                myTableIndex = data.tableIndex
                task.wait(2)
                detectAndShowAnswer()
                if autoRevealEnabled then
                    task.wait(0.5)
                    revealAllTiles()
                end
            end
        end
    end))
end

------------------------------------------------------------
-- UI SETUP
------------------------------------------------------------
local MainTab = Window:CreateTab("Main", "zap")
local MiscTab = Window:CreateTab("Misc", "settings")

MainTab:CreateToggle({
    Name = "Show Answer (Auto-Detect)",
    CurrentValue = true,
    Flag = "ShowAnswer",
    Callback = function(val)
        answerDisplayEnabled = val
    end,
})

MainTab:CreateToggle({
    Name = "Auto-Reveal Tiles (Client-Side)",
    CurrentValue = true,
    Flag = "AutoReveal",
    Callback = function(val)
        autoRevealEnabled = val
    end,
})

MainTab:CreateButton({
    Name = "Detect Answer Now",
    Callback = function()
        detectAndShowAnswer()
        if currentAnswer then
            Rayfield:Notify({
                Title = "Answer Found",
                Content = currentAnswer,
                Duration = 10,
            })
        else
            Rayfield:Notify({
                Title = "No Answer",
                Content = "Sit at a table and start a match first",
                Duration = 4,
            })
        end
    end,
})

MainTab:CreateButton({
    Name = "Reveal All Tiles Now",
    Callback = function()
        revealAllTiles()
    end,
})

-- Misc Tab
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
-- INIT
------------------------------------------------------------
setupListeners()

-- Try to detect answer immediately if already at a table
task.spawn(function()
    task.wait(1)
    detectAndShowAnswer()
    if autoRevealEnabled and myTableIndex then
        revealAllTiles()
    end
end)

------------------------------------------------------------
-- CLEANUP
------------------------------------------------------------
_G._3seventeen_gmg_cleanup = function()
    for tag, conns in pairs(connections) do
        for _, conn in ipairs(conns) do
            pcall(function() conn:Disconnect() end)
        end
    end
    connections = {}
    pcall(function() Rayfield:Destroy() end)
end

Rayfield:Notify({
    Title = "3seventeen",
    Content = "Guess My Game loaded — sit at a table to start",
    Duration = 4,
})
