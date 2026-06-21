local GITHUB_BASE = "https://raw.githubusercontent.com/123workforme/3seventeenhub/main/dist/"
local VERSION = "2.1.0"

local GameRegistry = {
    [142823291]        = { Name = "Murder Mystery 2",      File = "mm2.lua" },
    [893973440]        = { Name = "Flee the Facility",     File = "ftf.lua" },
    [5765078590]       = { Name = "Tower of Hell",         File = "toh.lua" },
    [9791603388]       = { Name = "Underground War",       File = "uw.lua" },
    [133237691504819]  = { Name = "Guess My Game",         File = "gmg.lua" },
    [16993432698]      = { Name = "Glass Bridge",          File = "glass_bridge.lua" },
}

local CurrentPlaceId = game.PlaceId
local DetectedGame = GameRegistry[CurrentPlaceId]

if not _G._3seventeen_tier then
    _G._3seventeen_tier = "free"
end

if not DetectedGame then
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    local Window = Rayfield:CreateWindow({
        Name = "3seventeen",
        Icon = "crown",
        LoadingTitle = "3seventeen",
        LoadingSubtitle = "v" .. VERSION,
        DisableBuildWarnings = true,
        KeySystem = false,
    })

    local Tab = Window:CreateTab("Home", "home")
    Tab:CreateParagraph({
        Title = "Unsupported Game",
        Content = "This game is not yet supported.\nPlace ID: " .. tostring(CurrentPlaceId)
            .. "\n\nSupported games:\n- Murder Mystery 2\n- Flee the Facility\n- Tower of Hell\n- Underground War\n- Guess My Game\n- Glass Bridge"
    })

    Tab:CreateParagraph({
        Title = "Status",
        Content = (_G._3seventeen_tier == "paid") and "Premium: Active" or "Free Tier"
    })

    Rayfield:Notify({
        Title = "3seventeen",
        Content = "Game not supported. Join a supported game to use scripts.",
        Duration = 5,
    })
    return
end

local moduleUrl = GITHUB_BASE .. DetectedGame.File

local ok, err = pcall(function()
    local source = game:HttpGet(moduleUrl)
    if not source or #source < 50 then
        error("Empty or invalid response from server")
    end
    local fn = loadstring(source)
    if fn then
        fn()
    else
        error("Failed to parse module source")
    end
end)

if not ok then
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    local Window = Rayfield:CreateWindow({
        Name = "3seventeen",
        Icon = "crown",
        LoadingTitle = "3seventeen",
        LoadingSubtitle = "error",
        DisableBuildWarnings = true,
        KeySystem = false,
    })

    local Tab = Window:CreateTab("Error", "alert-triangle")
    Tab:CreateParagraph({
        Title = "Failed to Load",
        Content = "Could not load " .. DetectedGame.Name .. " module.\n\nError: " .. tostring(err)
            .. "\n\nTry rejoining or check your internet connection."
    })

    Rayfield:Notify({
        Title = "Load Failed",
        Content = tostring(err),
        Duration = 8,
    })
end
