--[[
    ===================================================================
    🧠 GREEDY BRAINROTS - DELTA EXECUTOR COMPATIBLE HUB (Orion UI)
    Tối ưu hóa 100% cho Delta Executor (Android & Windows)
    ===================================================================
--]]

-- Tải thư viện Orion UI (Siêu mượt & tương thích tốt nhất với Delta)
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

local Window = OrionLib:MakeWindow({
    Name = "Greedy Brainrots Pro 🧠🌱 (Delta)",
    HidePremium = true,
    SaveConfig = false,
    IntroText = "Greedy Brainrots Hub",
    ConfigFolder = "GreedyBrainrots"
})

-- ── Variables ──
local AutoPlant = false
local AutoCollect = false
local AutoSell = false
local AutoBuyRarity = false
local SelectedRarity = "Mythic"
local PlantDelay = 0.3
local BuyDelay = 0.5

-- ── Tabs ──
local MainTab = Window:MakeTab({
    Name = "Auto Farm 🌱",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false
})

local ShopTab = Window:MakeTab({
    Name = "Auto Buy Rarity 🛒",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false
})

local SettingsTab = Window:MakeTab({
    Name = "Cài Đặt ⚙️",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false
})

-- ── Main Tab ──
MainTab:AddToggle({
    Name = "🌱 Auto Plant (Tự động Trồng)",
    Default = false,
    Callback = function(Value)
        AutoPlant = Value
    end    
})

MainTab:AddToggle({
    Name = "💵 Auto Collect (Tự động Nhặt)",
    Default = false,
    Callback = function(Value)
        AutoCollect = Value
    end    
})

MainTab:AddToggle({
    Name = "💰 Auto Sell (Tự động Bán)",
    Default = false,
    Callback = function(Value)
        AutoSell = Value
    end    
})

MainTab:AddSlider({
    Name = "⏱️ Tốc độ trồng (Delay giây)",
    Min = 0.1,
    Max = 2.0,
    Default = 0.3,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 0.1,
    ValueName = "s",
    Callback = function(Value)
        PlantDelay = Value
    end    
})

-- ── Shop Tab ──
ShopTab:AddToggle({
    Name = "🛒 Auto Buy theo Độ Hiếm",
    Default = false,
    Callback = function(Value)
        AutoBuyRarity = Value
    end    
})

ShopTab:AddDropdown({
    Name = "🎯 Chọn Độ Hiếm Cần Mua",
    Default = "Mythic",
    Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Godly"},
    Callback = function(Value)
        SelectedRarity = Value
    end    
})

-- ── Settings Tab ──
SettingsTab:AddButton({
    Name = "⚡ Kích hoạt Anti-AFK (Chống văng khi treo máy)",
    Callback = function()
        local vu = game:GetService("VirtualUser")
        game:GetService("Players").LocalPlayer.Idled:Connect(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
        OrionLib:MakeNotification({
            Name = "Anti-AFK Enabled",
            Content = "Đã bật chống AFK thành công!",
            Image = "rbxassetid://4483362458",
            Time = 5
        })
    end    
})

-- ═══════════════════════════════════════════════════════════════════
-- 🔄 BACKGROUND LOGIC LOOPS (Optimized for Delta Luau Environment)
-- ═══════════════════════════════════════════════════════════════════

-- Loop 1: Auto Plant
task.spawn(function()
    while task.wait(PlantDelay) do
        if AutoPlant then
            pcall(function()
                local player = game.Players.LocalPlayer
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
    while task.wait(BuyDelay) do
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

-- Initialize Orion UI
OrionLib:Init()
