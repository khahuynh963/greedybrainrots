--[[
    ===================================================================
    🌾⚡ GREEDY GROWERS - FAST LOADER V1.0
    ===================================================================
--]]
pcall(function()
    local container = (gethui and gethui()) or game:GetService("CoreGui")
    if container and container:FindFirstChild("GreedyGrowersHubGui") then
        container.GreedyGrowersHubGui:Destroy()
    end
    local pl = game:GetService("Players").LocalPlayer
    if pl and pl:FindFirstChild("PlayerGui") and pl.PlayerGui:FindFirstChild("GreedyGrowersHubGui") then
        pl.PlayerGui.GreedyGrowersHubGui:Destroy()
    end
end)

loadstring(game:HttpGet("https://raw.githubusercontent.com/khahuynh963/greedybrainrots/main/greedy_growers/script.lua?" .. math.random(1, 999999)))()
