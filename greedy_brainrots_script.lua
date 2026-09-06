--[[
    ===================================================================
    🧠 GREEDY BRAINROTS - FULL AUTO HUB (Rayfield UI V2)
    ===================================================================
--]]

local Rayfield
local success, err = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    warn("Failed to load Rayfield UI library, trying fallback link...")
    success, err = pcall(function()
        Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
    end)
end

if not Rayfield then
    error("Could not load Rayfield UI library. Check your executor or internet connection!")
    return
end

local Window = Rayfield:CreateWindow({
   Name = "Greedy Brainrots Pro Hub 🧠🌱",
   LoadingTitle = "Đang khởi tạo Auto Script...",
   LoadingSubtitle = "by Antigravity AI Assistant",
   ConfigurationSaving = {
      Enabled = false
   },
   Discord = {
      Enabled = false
   },
   KeySystem = false
})

-- ── Tabs ──
local MainTab = Window:CreateTab("Auto Farm & Plant 🌱", 4483362458)
local ShopTab = Window:CreateTab("Auto Mua theo Rarity 🛒", 4483362458)
local SettingsTab = Window:CreateTab("Cài Đặt ⚙️", 4483362458)

-- ── Variables ──
local AutoPlant = false
local AutoCollect = false
local AutoSell = false
local AutoBuyRarity = false
local SelectedRarities = {"Mythic", "Secret", "Godly"}
local PlantDelay = 0.3
local BuyDelay = 0.5

local AllRarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Godly"}

-- ── Main Tab Controls ──
MainTab:CreateToggle({
   Name = "🌱 Auto Trồng Brainrots (Auto Plant)",
   CurrentValue = false,
   Flag = "AutoPlant",
   Callback = function(Value)
      AutoPlant = Value
   end,
})

MainTab:CreateToggle({
   Name = "💵 Auto Nhặt Tiền & Brainrots (Auto Collect)",
   CurrentValue = false,
   Flag = "AutoCollect",
   Callback = function(Value)
      AutoCollect = Value
   end,
})

MainTab:CreateToggle({
   Name = "💰 Auto Bán Tất Cả (Auto Sell)",
   CurrentValue = false,
   Flag = "AutoSell",
   Callback = function(Value)
      AutoSell = Value
   end,
})

MainTab:CreateSlider({
   Name = "⏱️ Delay Trồng (Giây)",
   Range = {0.1, 2.0},
   Increment = 0.1,
   Suffix = "s",
   CurrentValue = 0.3,
   Flag = "PlantDelay",
   Callback = function(Value)
      PlantDelay = Value
   end,
})

-- ── Shop Tab Controls ──
ShopTab:CreateToggle({
   Name = "🛒 Auto Mua Brainrots theo Độ Hiếm Selected",
   CurrentValue = false,
   Flag = "AutoBuyRarity",
   Callback = function(Value)
      AutoBuyRarity = Value
   end,
})

local rarityOptionKey = "CurrentOption"
pcall(function()
    ShopTab:CreateDropdown({
       Name = "🎯 Chọn Các Độ Hiếm Cần Mua",
       Options = AllRarities,
       CurrentOption = {"Mythic", "Secret", "Godly"},
       MultipleOptions = true,
       Flag = "SelectedRarities",
       Callback = function(Options)
          if type(Options) == "table" then
             SelectedRarities = Options
          else
             SelectedRarities = {Options}
          end
       end,
    })
end)

ShopTab:CreateSlider({
   Name = "⏱️ Delay Quét Shop Mua (Giây)",
   Range = {0.1, 3.0},
   Increment = 0.1,
   Suffix = "s",
   CurrentValue = 0.5,
   Flag = "BuyDelay",
   Callback = function(Value)
      BuyDelay = Value
   end,
})

-- ── Settings Tab ──
SettingsTab:CreateButton({
   Name = "⚡ Anti-AFK (Chống văng khi cày đêm)",
   Callback = function()
      local VirtualUser = game:GetService("VirtualUser")
      game:GetService("Players").LocalPlayer.Idled:Connect(function()
         VirtualUser:CaptureController()
         VirtualUser:ClickButton2(Vector2.new())
         Rayfield:Notify({
            Title = "Anti-AFK",
            Content = "Đã tự động tương tác để tránh bị kick AFK!",
            Duration = 3,
         })
      end)
      Rayfield:Notify({
         Title = "Anti-AFK Enabled",
         Content = "Đã kích hoạt chống AFK thành công!",
         Duration = 4,
      })
   end,
})

-- ═══════════════════════════════════════════════════════════════════
-- 🔄 BACKGROUND LOGIC LOOPS
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
            
            -- Gọi Remote Event Trồng cây / Plant
            local plantEvent = remotes:FindFirstChild("Plant") or remotes:FindFirstChild("PlantBrainrot") or remotes:FindFirstChild("PlantSeed")
            if plantEvent then
               plantEvent:FireServer()
            else
               -- Virtual press key E nếu dùng Prompt tương tác
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

            local buyEvent = remotes:FindFirstChild("Buy") or remotes:FindFirstChild("BuyBrainrot") or remotes:FindFirstChild("Purchase")
            
            -- Lấy danh sách Brainrots trên kệ shop / river
            local shopItems = workspace:FindFirstChild("ShopItems") 
               or workspace:FindFirstChild("Shop") 
               or game:GetService("ReplicatedStorage"):FindFirstChild("Shop")

            if shopItems then
               for _, item in pairs(shopItems:GetChildren()) do
                  local itemRarity = item:FindFirstChild("Rarity") and item.Rarity.Value or item.Name
                  for _, selected in pairs(SelectedRarities) do
                     if string.find(string.lower(itemRarity), string.lower(selected)) then
                        if buyEvent then
                           buyEvent:FireServer(item.Name or item)
                        end
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
               -- Teleport nhặt các drops / Brainrots trôi nổi
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
            local sellEvent = remotes:FindFirstChild("Sell") or remotes:FindFirstChild("SellAll")
            if sellEvent then
               sellEvent:FireServer()
            end
         end)
      end
   end
end)

Rayfield:Notify({
   Title = "Greedy Brainrots Auto Loaded!",
   Content = "Chúc bạn cày game vui vẻ!",
   Duration = 5,
})
