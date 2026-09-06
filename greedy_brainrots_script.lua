--[[
    ===================================================================
    🧠 GREEDY BRAINROTS - NATIVE GUI (100% COMPATIBLE WITH DELTA)
    Không tải thư viện bên thứ 3 -> Đảm bảo chạy 100% trên Delta!
    ===================================================================
--]]

-- Safe Cleanup Old GUI
pcall(function()
    if game:GetService("CoreGui"):FindFirstChild("GreedyBrainrotsGui") then
        game:GetService("CoreGui").GreedyBrainrotsGui:Destroy()
    end
    if game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("GreedyBrainrotsGui") then
        game:GetService("Players").LocalPlayer.PlayerGui.GreedyBrainrotsGui:Destroy()
    end
end)

-- Create Native ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GreedyBrainrotsGui"
ScreenGui.ResetOnSpawn = false

local successParent, _ = pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not successParent then
    ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

-- Main Frame (Dark Neon Theme)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 310, 0, 370)
MainFrame.Position = UDim2.new(0.5, -155, 0.4, -185)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 255, 170)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Title Bar
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
Title.Text = "🧠 GREEDY BRAINROTS (DELTA HUB)"
Title.TextColor3 = Color3.fromRGB(0, 255, 170)
Title.TextSize = 13
Title.Font = Enum.Font.SourceSansBold
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = Title

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 8)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Title

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Variables
local AutoPlant = false
local AutoCollect = false
local AutoSell = false
local AutoBuyRarity = false
local SelectedRarity = "Mythic"
local PlantDelay = 0.3

local rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Godly"}
local currentIdx = 6

-- Helper function to create Toggle Button
local function createToggle(text, posY, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 42)
    btn.Position = UDim2.new(0.05, 0, 0, posY)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local state = defaultState
    local function updateVisual()
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
            btn.Text = text .. ": [ BẬT - ON ]"
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
            btn.Text = text .. ": [ TẮT - OFF ]"
            btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
    end
    updateVisual()

    btn.MouseButton1Click:Connect(function()
        state = not state
        updateVisual()
        callback(state)
    end)
end

-- Toggles
createToggle("🌱 Auto Plant (Trồng)", 55, false, function(v) AutoPlant = v end)
createToggle("💵 Auto Collect (Nhặt)", 105, false, function(v) AutoCollect = v end)
createToggle("💰 Auto Sell (Bán hết)", 155, false, function(v) AutoSell = v end)
createToggle("🛒 Auto Buy Rarity", 205, false, function(v) AutoBuyRarity = v end)

-- Dropdown Rarity Button (Bấm để đổi độ hiếm)
local RarityBtn = Instance.new("TextButton")
RarityBtn.Size = UDim2.new(0.9, 0, 0, 42)
RarityBtn.Position = UDim2.new(0.05, 0, 0, 255)
RarityBtn.BackgroundColor3 = Color3.fromRGB(90, 60, 180)
RarityBtn.Text = "🎯 Độ Hiếm Cần Mua: " .. SelectedRarity
RarityBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RarityBtn.Font = Enum.Font.SourceSansBold
RarityBtn.TextSize = 13
RarityBtn.Parent = MainFrame

local RarityCorner = Instance.new("UICorner")
RarityCorner.CornerRadius = UDim.new(0, 8)
RarityCorner.Parent = RarityBtn

RarityBtn.MouseButton1Click:Connect(function()
    currentIdx = (currentIdx % #rarities) + 1
    SelectedRarity = rarities[currentIdx]
    RarityBtn.Text = "🎯 Độ Hiếm Cần Mua: " .. SelectedRarity
end)

-- Anti AFK Button
local AntiAFKBtn = Instance.new("TextButton")
AntiAFKBtn.Size = UDim2.new(0.9, 0, 0, 42)
AntiAFKBtn.Position = UDim2.new(0.05, 0, 0, 305)
AntiAFKBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 210)
AntiAFKBtn.Text = "⚡ Kích hoạt Anti-AFK (Bật 1 lần)"
AntiAFKBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AntiAFKBtn.Font = Enum.Font.SourceSansBold
AntiAFKBtn.TextSize = 13
AntiAFKBtn.Parent = MainFrame

local AntiAFKCorner = Instance.new("UICorner")
AntiAFKCorner.CornerRadius = UDim.new(0, 8)
AntiAFKCorner.Parent = AntiAFKBtn

AntiAFKBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local vu = game:GetService("VirtualUser")
        game:GetService("Players").LocalPlayer.Idled:Connect(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end)
    AntiAFKBtn.Text = "✅ Đã bật Anti-AFK!"
    AntiAFKBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 80)
end)

-- ═══════════════════════════════════════════════════════════════════
-- 🔄 BACKGROUND LOGIC LOOPS
-- ═══════════════════════════════════════════════════════════════════

-- Loop 1: Auto Plant
task.spawn(function()
    while task.wait(PlantDelay) do
        if AutoPlant then
            pcall(function()
                local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") 
                   or game:GetService("ReplicatedStorage"):FindFirstChild("Events")
                   or game:GetService("ReplicatedStorage")
                local plantEvt = remotes:FindFirstChild("Plant") or remotes:FindFirstChild("PlantBrainrot") or remotes:FindFirstChild("PlantSeed")
                if plantEvt then
                    plantEvt:FireServer()
                else
                    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.05)
                    game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
                end
            end)
        end
    end
end)

-- Loop 2: Auto Buy by Rarity
task.spawn(function()
    while task.wait(0.5) do
        if AutoBuyRarity then
            pcall(function()
                local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") 
                   or game:GetService("ReplicatedStorage"):FindFirstChild("Events")
                   or game:GetService("ReplicatedStorage")
                local buyEvt = remotes:FindFirstChild("Buy") or remotes:FindFirstChild("BuyBrainrot") or remotes:FindFirstChild("Purchase")
                local shopItems = workspace:FindFirstChild("ShopItems") 
                   or workspace:FindFirstChild("Shop") 
                   or game:GetService("ReplicatedStorage"):FindFirstChild("Shop")

                if shopItems then
                    for _, item in pairs(shopItems:GetChildren()) do
                        local itemRarity = item:FindFirstChild("Rarity") and item.Rarity.Value or item.Name
                        if string.find(string.lower(tostring(itemRarity)), string.lower(SelectedRarity)) then
                            if buyEvt then
                                buyEvt:FireServer(item.Name or item)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Loop 3: Auto Collect & Auto Sell
task.spawn(function()
    while task.wait(1) do
        if AutoCollect then
            pcall(function()
                local player = game.Players.LocalPlayer
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local drops = workspace:FindFirstChild("Drops") or workspace:FindFirstChild("Collectibles")
                    if drops then
                        for _, drop in pairs(drops:GetChildren()) do
                            if drop:IsA("BasePart") then
                                drop.CFrame = player.Character.HumanoidRootPart.CFrame
                            end
                        end
                    end
                end
            end)
        end
        
        if AutoSell then
            pcall(function()
                local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") 
                   or game:GetService("ReplicatedStorage"):FindFirstChild("Events")
                   or game:GetService("ReplicatedStorage")
                local sellEvt = remotes:FindFirstChild("Sell") or remotes:FindFirstChild("SellAll")
                if sellEvt then
                    sellEvt:FireServer()
                end
            end)
        end
    end
end)
