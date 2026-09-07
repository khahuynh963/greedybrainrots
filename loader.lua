--[[
    ===================================================================
    🧠 GREEDY BRAINROTS - ULTIMATE AUTO HUB (V27 FAST LOADER)
    ===================================================================
--]]
pcall(function()
    local container = (gethui and gethui()) or game:GetService("CoreGui")
    if container and container:FindFirstChild("GreedyBrainrotsGui") then
        container.GreedyBrainrotsGui:Destroy()
    end
    local pl = game:GetService("Players").LocalPlayer
    if pl and pl:FindFirstChild("PlayerGui") and pl.PlayerGui:FindFirstChild("GreedyBrainrotsGui") then
        pl.PlayerGui.GreedyBrainrotsGui:Destroy()
    end
end)

loadstring(game:HttpGet("https://raw.githubusercontent.com/khahuynh963/greedybrainrots/main/v27.lua?" .. math.random(1, 999999)))()
