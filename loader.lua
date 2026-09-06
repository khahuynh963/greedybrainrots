--[[
    ===================================================================
    🧠 GREEDY BRAINROTS - ULTIMATE AUTO HUB (V11 FAST LOADER)
    ===================================================================
--]]
pcall(function()
    if game:GetService("CoreGui"):FindFirstChild("GreedyBrainrotsGui") then
        game:GetService("CoreGui").GreedyBrainrotsGui:Destroy()
    end
    local pl = game:GetService("Players").LocalPlayer
    if pl and pl:FindFirstChild("PlayerGui") and pl.PlayerGui:FindFirstChild("GreedyBrainrotsGui") then
        pl.PlayerGui.GreedyBrainrotsGui:Destroy()
    end
end)

loadstring(game:HttpGet("https://raw.githubusercontent.com/khahuynh963/greedybrainrots/main/v11.lua?" .. math.random(1, 999999)))()
