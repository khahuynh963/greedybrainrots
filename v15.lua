--[[
    ===================================================================
    🧠 GREEDY BRAINROTS - ULTIMATE AUTO HUB V15 (MY PLOT FILTER & AUTO FOOD FIX)
    - Nhận Diện Chính Xác Plot / Sân Của Bạn (My Plot Filter): Chỉ trồng cây trên 
      ô đất (Grow Pad) thuộc về BẠN, khắc phục triệt để lỗi "Grow pad belongs to another player"!
    - Tự Động Chọn Đồ Ăn (Auto Select Food): Tự động chọn thức ăn khi bảng "SELECT FOOD / FEED" 
      xuất hiện và tự đóng popup (Basic Free, None, Better, Premium, Super, Magic).
    - Tự Động Thu Hoạch Né Sét (Auto Dodge Lightning & Harvest): Thu hoạch cây 
      trước khi sét đánh trúng làm chết cây!
    - Thu Hoạch Tối Ưu (Auto Harvest Optimal Size): Tự động thu hoạch khi cây 
      đạt kích thước tối đa / sẵn sàng thu hoạch.
    - Nút Harvest Tức Thời (Instant Harvest All): Thu hoạch toàn bộ cây trồng trong 1 click.
    - Tích hợp Từ Điển Nhận Diện Độ Hiếm Tất Cả Cây (Item Database Map V12).
    ===================================================================
--]]

-- Clear existing GUI
pcall(function()
    if game:GetService("CoreGui"):FindFirstChild("GreedyBrainrotsGui") then
        game:GetService("CoreGui").GreedyBrainrotsGui:Destroy()
    end
    local pl = game:GetService("Players").LocalPlayer
    if pl and pl:FindFirstChild("PlayerGui") and pl.PlayerGui:FindFirstChild("GreedyBrainrotsGui") then
        pl.PlayerGui.GreedyBrainrotsGui:Destroy()
    end
end)

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- ── State Variables ──
local AutoPlant = false
local AutoDodgeLightning = true  -- Default ON: Auto harvest before lightning strike
local AutoHarvestMax = false     -- Default OFF: Auto harvest when plant reaches max size
local AutoFood = true            -- Default ON: Auto Select Food when popup opens
local SelectedFoodIndex = 1      -- Default: 1 = Basic (+37% Luck Free)
local ALL_FOOD_TYPES = {"Basic", "None", "Better", "Premium", "Super", "Magic"}
local ALL_FOOD_DISPLAYS = {
    "Basic (+37% Luck Free)",
    "None (Free)",
    "Better (+73% Luck $)",
    "Premium (+115% Luck $)",
    "Super (+168% Luck $)",
    "Magic (+250% Luck $)"
}

local AutoBuy = false
local AutoBuyAll = false
local AutoTrash = false
local AutoCollect = false
local AutoSell = false
local AntiAFK = true
local AntiBan = true

-- Admin Reaction Mode: "SERVER_HOP", "KICK_SELF", "PAUSE_ALL"
local AdminMode = "SERVER_HOP" 

local ALL_RARITIES = {
    "Common", "Rare", "Epic", "Legendary", "Mythical", 
    "Godly", "Secret", "Divine", "OG", "Celestial", 
    "Eternal", "Forbidden", "Unknown"
}

local ALL_FORMS = {
    "Normal", "Gold", "Diamond", "Galaxy", "Shadow", "Electrified", 
    "Starfall", "Rainbow", "Hacker", "Lava", "Cooked"
}

-- 🛒 Buy Rarities Map (High-tier ON, Low-tier OFF by default)
local SelectedRarities = {
    ["Common"]    = false,
    ["Rare"]      = false,
    ["Epic"]      = false,
    ["Legendary"] = false,
    ["Mythical"]  = true,
    ["Godly"]     = true,
    ["Secret"]    = true,
    ["Divine"]    = true,
    ["OG"]        = true,
    ["Celestial"] = true,
    ["Eternal"]   = true,
    ["Forbidden"] = true,
    ["Unknown"]   = false
}

-- 🗑️ Trash Rarities Map (Low-tier Common/Rare/Epic ON for trashing by default)
local TrashRarities = {
    ["Common"]    = true,
    ["Rare"]      = true,
    ["Epic"]      = true,
    ["Legendary"] = false,
    ["Mythical"]  = false,
    ["Godly"]     = false,
    ["Secret"]    = false,
    ["Divine"]    = false,
    ["OG"]        = false,
    ["Celestial"] = false,
    ["Eternal"]   = false,
    ["Forbidden"] = false,
    ["Unknown"]   = false
}

-- All Forms enabled by default
local SelectedForms = {}
for _, f in ipairs(ALL_FORMS) do SelectedForms[f] = true end

-- Default Filter Mode: RARITY_ONLY
local FilterMode = "RARITY_ONLY" 

local PlantDelay = 0.2
local BuyDelay = 0.15
local TrashDelay = 0.3

-- ═══════════════════════════════════════════════════════════
-- MY PLOT FINDER UTILITY (Lọc chính xác Plot của chính bạn)
-- ═══════════════════════════════════════════════════════════
local cachedMyPlot = nil

local function getMyPlot()
    if cachedMyPlot and cachedMyPlot.Parent then return cachedMyPlot end
    
    local pName = string.lower(LocalPlayer.Name)
    local pDisp = string.lower(LocalPlayer.DisplayName)
    
    local searchContainers = {
        workspace:FindFirstChild("Plots"),
        workspace:FindFirstChild("Bases"),
        workspace:FindFirstChild("PlotsContainer"),
        workspace
    }

    for _, container in ipairs(searchContainers) do
        if container then
            for _, child in pairs(container:GetChildren()) do
                local cName = string.lower(child.Name)
                if string.find(cName, pName) or string.find(cName, pDisp) then
                    cachedMyPlot = child
                    return child
                end
                
                pcall(function()
                    for attrName, val in pairs(child:GetAttributes()) do
                        local vStr = string.lower(tostring(val))
                        if vStr == pName or vStr == pDisp or vStr == tostring(LocalPlayer.UserId) then
                            cachedMyPlot = child
                            return child
                        end
                    end
                end)
                
                for _, desc in pairs(child:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Text ~= "" then
                        local txt = string.lower(desc.Text)
                        if string.find(txt, pName) or string.find(txt, pDisp) then
                            cachedMyPlot = child
                            return child
                        end
                    end
                    if desc:IsA("StringValue") or desc:IsA("ObjectValue") then
                        if tostring(desc.Value) == LocalPlayer.Name or desc.Value == LocalPlayer then
                            cachedMyPlot = child
                            return child
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════
-- BRAINROT ITEM RARITY DATABASE MAP
-- ═══════════════════════════════════════════════════════════
local ITEM_RARITY_DATABASE = {
    -- Common Tiers
    ["fluri flura"]                  = "Common",
    ["chillin chili"]                = "Common",
    ["gangster footera"]             = "Common",
    ["boneca ambalabu"]              = "Common",
    ["bombardiro crocodilo"]         = "Common",
    ["glorbo fruttodrillo"]          = "Common",
    ["ta ta ta ta sahur"]            = "Common",
    ["lerulerulerule"]               = "Common",
    ["garamararam"]                  = "Common",
    ["ballerino lololo"]             = "Common",
    ["tung sahur"]                   = "Common",
    ["pipi potato"]                  = "Common",
    ["ballerina cappuccina"]         = "Common",
    ["frigo camelo"]                 = "Common",
    ["job job job sahur"]            = "Common",
    ["brr brr patapim"]              = "Common",
    ["talpa di fero"]                = "Common",
    ["burbaloni luliloli"]           = "Common",
    ["brri brri bicus dicus bombicus"]= "Common",
    ["pot hotspot"]                  = "Common",
    ["dragon cannelloni"]            = "Common",
    ["tric trac barabum"]            = "Common",
    ["six seven"]                    = "Common",
    ["tralalero tralala"]            = "Common",
    ["strawberry elephant"]          = "Common",
    ["girafa celeste"]               = "Common",
    ["noo my examen"]                = "Common",
    ["ganganzelli trulala"]          = "Common",
    ["matteo"]                       = "Common",
    ["los tralaleritos"]             = "Common",
    ["pandaccini bananini"]          = "Common",
    ["pipi kiwi"]                    = "Common",
    ["tim cheese"]                   = "Common",
    ["tirilikalika tirilikalako"]    = "Common",
    ["zibra zubra zibralini"]        = "Common",
    ["banana dancana"]               = "Common",
    ["cavallo virtuoso"]             = "Common",
    ["la vacca saturno saturnita"]    = "Common",
    ["bombombini gusini"]            = "Common",
    ["cacto hipopotamo"]             = "Common",

    -- Rare Tiers
    ["triplito tralaleritos"]        = "Rare",
    ["trippi troppi"]                = "Rare",
    ["bananita dolphinita"]          = "Rare",
    ["torrtuginni dragonfrutini"]    = "Rare",
    ["bobrito bandito"]              = "Rare",
    ["tigroligre frutonni"]          = "Rare",
    ["cappuccino assassino"]         = "Rare",
    ["1x1x1x1"]                      = "Rare",

    -- Epic Tiers
    ["chicleteirina bicicleteirina"] = "Epic",
    ["chicleteira bicicleteira"]     = "Epic",
    ["pakrahmatmatina"]              = "Epic",

    -- Legendary Tiers
    ["orangutini ananassini"]        = "Legendary",
    ["la grande combinasion"]        = "Legendary",
}

-- Safe Tool Rarity Detection using Database Map
local function detectToolRarity(tool)
    if not tool or not tool:IsA("Tool") then return "Unknown" end
    
    -- 1. Check Attributes
    local attr = tool:GetAttribute("Rarity") or tool:GetAttribute("Tier")
    if attr then return tostring(attr) end
    
    -- 2. Check StringValue children
    local rVal = tool:FindFirstChild("Rarity") or tool:FindFirstChild("Tier")
    if rVal and rVal:IsA("StringValue") then return rVal.Value end

    -- 3. Check explicit Rarity words in Tool Name
    local tName = string.lower(tool.Name)
    for _, r in ipairs(ALL_RARITIES) do
        if r ~= "Unknown" and string.find(tName, string.lower(r)) then
            return r
        end
    end

    -- 4. Database Lookup by base item name
    for itemName, rarity in pairs(ITEM_RARITY_DATABASE) do
        if string.find(tName, itemName) then
            return rarity
        end
    end

    return "Unknown"
end

-- Helper function to make ProximityPrompt instant and infinite range
local function optimizePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    pcall(function()
        prompt.MaxActivationDistance = 999999
        prompt.RequiresLineOfSight = false
        prompt.HoldDuration = 0
    end)
end

-- Helper function to trigger ProximityPrompt with humanlike micro-jitter
local function triggerPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    optimizePrompt(prompt)

    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt, 0)
            fireproximityprompt(prompt, 100)
            fireproximityprompt(prompt)
        end
    end)
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.01)
        prompt:InputHoldEnd()
    end)
end

-- ═══════════════════════════════════════════════════════════
-- ANTI-BAN & ADMIN DETECTION ENGINE
-- ═══════════════════════════════════════════════════════════
local AdminKeywords = {"admin", "mod", "owner", "creator", "dev", "staff"}

local function isPlayerAdmin(player)
    if not player or player == LocalPlayer then return false end
    
    local pName = string.lower(player.Name)
    local pDisp = string.lower(player.DisplayName)
    for _, kw in ipairs(AdminKeywords) do
        if string.find(pName, kw) or string.find(pDisp, kw) then
            return true
        end
    end

    return false
end

-- Server Hop Utility
local function serverHop()
    pcall(function()
        local placeId = game.PlaceId
        local servers = {}
        local req = request or http_request or (syn and syn.request)
        
        if req then
            local res = req({
                Url = "https://games.roblox.com/v1/places/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100",
                Method = "GET"
            })
            if res and res.StatusCode == 200 then
                local body = HttpService:JSONDecode(res.Body)
                if body and body.data then
                    for _, s in ipairs(body.data) do
                        if s.id ~= game.JobId and s.playing < s.maxPlayers then
                            table.insert(servers, s.id)
                        end
                    end
                end
            end
        end

        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(placeId, servers[math.random(1, #servers)], LocalPlayer)
        else
            TeleportService:Teleport(placeId, LocalPlayer)
        end
    end)
end

-- ── GUI Creation ──
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GreedyBrainrotsGui"
ScreenGui.ResetOnSpawn = false

pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- 🧠 Floating Toggle Icon Button
local ToggleIcon = Instance.new("TextButton")
ToggleIcon.Name = "ToggleIcon"
ToggleIcon.Size = UDim2.new(0, 52, 0, 52)
ToggleIcon.Position = UDim2.new(0, 15, 0.4, 0)
ToggleIcon.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
ToggleIcon.Text = "🧠"
ToggleIcon.TextSize = 26
ToggleIcon.Active = true
ToggleIcon.Draggable = true
ToggleIcon.Parent = ScreenGui

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(1, 0)
IconCorner.Parent = ToggleIcon

local IconStroke = Instance.new("UIStroke")
IconStroke.Color = Color3.fromRGB(0, 255, 170)
IconStroke.Thickness = 2
IconStroke.Parent = ToggleIcon

-- Main Hub Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 330, 0, 560)
MainFrame.Position = UDim2.new(0.5, -165, 0.35, -280)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 255, 170)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

ToggleIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 14)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -75, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🍱 BRAINROTS HUB V15 (MY PLOT FILTER FIX)"
Title.TextColor3 = Color3.fromRGB(0, 255, 170)
Title.TextSize = 12
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- ➖ Minimize Button
local MiniBtn = Instance.new("TextButton")
MiniBtn.Name = "MiniBtn"
MiniBtn.Size = UDim2.new(0, 28, 0, 28)
MiniBtn.Position = UDim2.new(1, -64, 0, 7)
MiniBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
MiniBtn.Text = "➖"
MiniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniBtn.Font = Enum.Font.SourceSansBold
MiniBtn.TextSize = 14
MiniBtn.Parent = Header

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(0, 6)
MiniCorner.Parent = MiniBtn

MiniBtn.MouseButton1Click:Connect(function() 
    MainFrame.Visible = false 
end)

-- ❌ Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -32, 0, 7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 13
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Content Scroll
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -85)
Scroll.Position = UDim2.new(0, 8, 0, 46)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 4
Scroll.CanvasSize = UDim2.new(0, 0, 0, 840)
Scroll.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 8)
Layout.Parent = Scroll

-- Button Generator Utility
local function createToggleButton(text, color, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220, 220, 240)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.Parent = Scroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(45, 45, 60)
    s.Thickness = 1
    s.Parent = btn

    btn.MouseButton1Click:Connect(function()
        onClick(btn, s)
    end)
    return btn
end

-- 1. Anti-Ban & Admin Detector Toggle Button
createToggleButton("🛡️ Anti-Ban & Admin Detector: ON", Color3.fromRGB(0, 255, 170), function(btn, stroke)
    AntiBan = not AntiBan
    if AntiBan then
        btn.Text = "🛡️ Anti-Ban & Admin Detector: ON"
        btn.TextColor3 = Color3.fromRGB(0, 255, 170)
        stroke.Color = Color3.fromRGB(0, 255, 170)
    else
        btn.Text = "🛡️ Anti-Ban & Admin Detector: OFF"
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        stroke.Color = Color3.fromRGB(45, 45, 60)
    end
end)

-- 2. Admin Reaction Mode Button
local btnAdminMode = Instance.new("TextButton")
btnAdminMode.Size = UDim2.new(1, 0, 0, 34)
btnAdminMode.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
btnAdminMode.Text = "🚨 Khi Thấy Admin: [ Đổi Server Khác ]"
btnAdminMode.TextColor3 = Color3.fromRGB(255, 170, 0)
btnAdminMode.Font = Enum.Font.SourceSansBold
btnAdminMode.TextSize = 12
btnAdminMode.Parent = Scroll
local amCorner = Instance.new("UICorner")
amCorner.CornerRadius = UDim.new(0, 8)
amCorner.Parent = btnAdminMode

btnAdminMode.MouseButton1Click:Connect(function()
    if AdminMode == "SERVER_HOP" then
        AdminMode = "KICK_SELF"
        btnAdminMode.Text = "🚨 Khi Thấy Admin: [ Tự Ngắt Kết Nối ]"
        btnAdminMode.TextColor3 = Color3.fromRGB(255, 80, 80)
    elseif AdminMode == "KICK_SELF" then
        AdminMode = "PAUSE_ALL"
        btnAdminMode.Text = "🚨 Khi Thấy Admin: [ Tạm Dừng Tất Cả ]"
        btnAdminMode.TextColor3 = Color3.fromRGB(255, 220, 0)
    else
        AdminMode = "SERVER_HOP"
        btnAdminMode.Text = "🚨 Khi Thấy Admin: [ Đổi Server Khác ]"
        btnAdminMode.TextColor3 = Color3.fromRGB(255, 170, 0)
    end
end)

-- 3. Auto Plant Button
createToggleButton("🌱 Auto Plant (Trồng cây): OFF", Color3.fromRGB(0, 255, 170), function(btn, stroke)
    AutoPlant = not AutoPlant
    if AutoPlant then
        btn.Text = "🌱 Auto Plant (Trồng cây): ON"
        btn.TextColor3 = Color3.fromRGB(0, 255, 170)
        stroke.Color = Color3.fromRGB(0, 255, 170)
    else
        btn.Text = "🌱 Auto Plant (Trồng cây): OFF"
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        stroke.Color = Color3.fromRGB(45, 45, 60)
    end
end)

-- 🍱 4. Auto Select Food Toggle (Mặc định ON)
createToggleButton("🍱 Auto Select Food (Tự Chọn Đồ Ăn): ON", Color3.fromRGB(255, 180, 0), function(btn, stroke)
    AutoFood = not AutoFood
    if AutoFood then
        btn.Text = "🍱 Auto Select Food (Tự Chọn Đồ Ăn): ON"
        btn.TextColor3 = Color3.fromRGB(255, 180, 0)
        stroke.Color = Color3.fromRGB(255, 180, 0)
    else
        btn.Text = "🍱 Auto Select Food (Tự Chọn Đồ Ăn): OFF"
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        stroke.Color = Color3.fromRGB(45, 45, 60)
    end
end)

-- 🍱 5. Food Choice Selector Button
local btnFoodType = Instance.new("TextButton")
btnFoodType.Size = UDim2.new(1, 0, 0, 34)
btnFoodType.BackgroundColor3 = Color3.fromRGB(45, 35, 20)
btnFoodType.Text = "🍕 Chọn Đồ Ăn: [ Basic (+37% Luck Free) ]"
btnFoodType.TextColor3 = Color3.fromRGB(255, 220, 100)
btnFoodType.Font = Enum.Font.SourceSansBold
btnFoodType.TextSize = 12
btnFoodType.Parent = Scroll
local ftCorner = Instance.new("UICorner")
ftCorner.CornerRadius = UDim.new(0, 8)
ftCorner.Parent = btnFoodType

btnFoodType.MouseButton1Click:Connect(function()
    SelectedFoodIndex = SelectedFoodIndex + 1
    if SelectedFoodIndex > #ALL_FOOD_TYPES then
        SelectedFoodIndex = 1
    end
    btnFoodType.Text = "🍕 Chọn Đồ Ăn: [ " .. ALL_FOOD_DISPLAYS[SelectedFoodIndex] .. " ]"
end)

-- ⚡ 6. Auto Dodge Lightning & Harvest (Tự Thu Hoạch Né Sét)
createToggleButton("⚡ Auto Harvest Né Sét (Tránh Sét Đánh): ON", Color3.fromRGB(255, 220, 0), function(btn, stroke)
    AutoDodgeLightning = not AutoDodgeLightning
    if AutoDodgeLightning then
        btn.Text = "⚡ Auto Harvest Né Sét (Tránh Sét Đánh): ON"
        btn.TextColor3 = Color3.fromRGB(255, 220, 0)
        stroke.Color = Color3.fromRGB(255, 220, 0)
    else
        btn.Text = "⚡ Auto Harvest Né Sét (Tránh Sét Đánh): OFF"
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        stroke.Color = Color3.fromRGB(45, 45, 60)
    end
end)

-- 🌽 7. Auto Harvest Optimal Size (Thu Hoạch Tối Ưu)
createToggleButton("🌽 Auto Harvest Tối Ưu (Đạt Size): OFF", Color3.fromRGB(0, 220, 130), function(btn, stroke)
    AutoHarvestMax = not AutoHarvestMax
    if AutoHarvestMax then
        btn.Text = "🌽 Auto Harvest Tối Ưu (Đạt Size): ON"
        btn.TextColor3 = Color3.fromRGB(0, 220, 130)
        stroke.Color = Color3.fromRGB(0, 220, 130)
    else
        btn.Text = "🌽 Auto Harvest Tối Ưu (Đạt Size): OFF"
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        stroke.Color = Color3.fromRGB(45, 45, 60)
    end
end)

-- 🌾 8. Instant Harvest All Button (Thu Hoạch Tức Thời All Cây)
local btnHarvestNow = Instance.new("TextButton")
btnHarvestNow.Size = UDim2.new(1, 0, 0, 34)
btnHarvestNow.BackgroundColor3 = Color3.fromRGB(0, 120, 180)
btnHarvestNow.Text = "🌾 Harvest Tất Cả Cây Ngay Lập Tức!"
btnHarvestNow.TextColor3 = Color3.fromRGB(255, 255, 255)
btnHarvestNow.Font = Enum.Font.SourceSansBold
btnHarvestNow.TextSize = 13
btnHarvestNow.Parent = Scroll
local hnCorner = Instance.new("UICorner")
hnCorner.CornerRadius = UDim.new(0, 8)
hnCorner.Parent = btnHarvestNow

-- 9. Auto Buy Button (Theo Lọc)
createToggleButton("🛒 Auto Buy (Mua theo lọc): OFF", Color3.fromRGB(0, 150, 255), function(btn, stroke)
    AutoBuy = not AutoBuy
    if AutoBuy then
        btn.Text = "🛒 Auto Buy (Mua theo lọc): ON"
        btn.TextColor3 = Color3.fromRGB(0, 150, 255)
        stroke.Color = Color3.fromRGB(0, 150, 255)
    else
        btn.Text = "🛒 Auto Buy (Mua theo lọc): OFF"
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        stroke.Color = Color3.fromRGB(45, 45, 60)
    end
end)

-- 10. Auto Buy ALL Button (Mua tất cả không cần lọc)
createToggleButton("⚡ Auto Buy ALL (Mua TẤT CẢ): OFF", Color3.fromRGB(255, 170, 0), function(btn, stroke)
    AutoBuyAll = not AutoBuyAll
    if AutoBuyAll then
        btn.Text = "⚡ Auto Buy ALL (Mua TẤT CẢ): ON"
        btn.TextColor3 = Color3.fromRGB(255, 170, 0)
        stroke.Color = Color3.fromRGB(255, 170, 0)
    else
        btn.Text = "⚡ Auto Buy ALL (Mua TẤT CẢ): OFF"
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        stroke.Color = Color3.fromRGB(45, 45, 60)
    end
end)

-- 11. Open Buy Rarities Modal Button
local btnRarities = Instance.new("TextButton")
btnRarities.Size = UDim2.new(1, 0, 0, 34)
btnRarities.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
btnRarities.Text = "🎯 Chọn Độ Hiếm Mua (Buy Rarities)..."
btnRarities.TextColor3 = Color3.fromRGB(255, 200, 100)
btnRarities.Font = Enum.Font.SourceSansBold
btnRarities.TextSize = 13
btnRarities.Parent = Scroll
local rCorner = Instance.new("UICorner")
rCorner.CornerRadius = UDim.new(0, 8)
rCorner.Parent = btnRarities

-- 12. Open Buy Forms Modal Button
local btnForms = Instance.new("TextButton")
btnForms.Size = UDim2.new(1, 0, 0, 34)
btnForms.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
btnForms.Text = "⚡ Chọn Dòng Form Mua (Buy Forms)..."
btnForms.TextColor3 = Color3.fromRGB(180, 120, 255)
btnForms.Font = Enum.Font.SourceSansBold
btnForms.TextSize = 13
btnForms.Parent = Scroll
local fCorner = Instance.new("UICorner")
fCorner.CornerRadius = UDim.new(0, 8)
fCorner.Parent = btnForms

-- 13. Filter Mode Toggle Button
local btnMode = Instance.new("TextButton")
btnMode.Size = UDim2.new(1, 0, 0, 34)
btnMode.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
btnMode.Text = "🔀 Chế Độ Lọc Mua: [ Chỉ Độ Hiếm ]"
btnMode.TextColor3 = Color3.fromRGB(255, 200, 100)
btnMode.Font = Enum.Font.SourceSansBold
btnMode.TextSize = 12
btnMode.Parent = Scroll
local mCorner = Instance.new("UICorner")
mCorner.CornerRadius = UDim.new(0, 8)
mCorner.Parent = btnMode

btnMode.MouseButton1Click:Connect(function()
    if FilterMode == "RARITY_ONLY" then
        FilterMode = "FORM_ONLY"
        btnMode.Text = "🔀 Chế Độ Lọc Mua: [ Chỉ Dòng Form ]"
        btnMode.TextColor3 = Color3.fromRGB(180, 120, 255)
    elseif FilterMode == "FORM_ONLY" then
        FilterMode = "BOTH"
        btnMode.Text = "🔀 Chế Độ Lọc Mua: [ CẢ HAI (Rarity + Form) ]"
        btnMode.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        FilterMode = "RARITY_ONLY"
        btnMode.Text = "🔀 Chế Độ Lọc Mua: [ Chỉ Độ Hiếm ]"
        btnMode.TextColor3 = Color3.fromRGB(255, 200, 100)
    end
end)

-- 14. Auto Trash Button (Vứt Rác Theo Lọc)
createToggleButton("🗑️ Auto Trash (Vứt rác theo lọc): OFF", Color3.fromRGB(255, 80, 120), function(btn, stroke)
    AutoTrash = not AutoTrash
    if AutoTrash then
        btn.Text = "🗑️ Auto Trash (Vứt rác theo lọc): ON"
        btn.TextColor3 = Color3.fromRGB(255, 80, 120)
        stroke.Color = Color3.fromRGB(255, 80, 120)
    else
        btn.Text = "🗑️ Auto Trash (Vứt rác theo lọc): OFF"
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        stroke.Color = Color3.fromRGB(45, 45, 60)
    end
end)

-- 15. Open Trash Rarities Modal Button
local btnTrashRarities = Instance.new("TextButton")
btnTrashRarities.Size = UDim2.new(1, 0, 0, 34)
btnTrashRarities.BackgroundColor3 = Color3.fromRGB(50, 30, 42)
btnTrashRarities.Text = "🗑️ Chọn Độ Hiếm Vứt Rác (Trash Rarities)..."
btnTrashRarities.TextColor3 = Color3.fromRGB(255, 120, 160)
btnTrashRarities.Font = Enum.Font.SourceSansBold
btnTrashRarities.TextSize = 13
btnTrashRarities.Parent = Scroll
local trCorner = Instance.new("UICorner")
trCorner.CornerRadius = UDim.new(0, 8)
trCorner.Parent = btnTrashRarities

-- 16. Auto Collect Button
createToggleButton("💵 Auto Collect (Gom Tiền): OFF", Color3.fromRGB(255, 220, 0), function(btn, stroke)
    AutoCollect = not AutoCollect
    if AutoCollect then
        btn.Text = "💵 Auto Collect (Gom Tiền): ON"
        btn.TextColor3 = Color3.fromRGB(255, 220, 0)
        stroke.Color = Color3.fromRGB(255, 220, 0)
    else
        btn.Text = "💵 Auto Collect (Gom Tiền): OFF"
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        stroke.Color = Color3.fromRGB(45, 45, 60)
    end
end)

-- 17. Auto Sell Button
createToggleButton("💰 Auto Sell (Bán Hết): OFF", Color3.fromRGB(255, 100, 100), function(btn, stroke)
    AutoSell = not AutoSell
    if AutoSell then
        btn.Text = "💰 Auto Sell (Bán Hết): ON"
        btn.TextColor3 = Color3.fromRGB(255, 100, 100)
        stroke.Color = Color3.fromRGB(255, 100, 100)
    else
        btn.Text = "💰 Auto Sell (Bán Hết): OFF"
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        stroke.Color = Color3.fromRGB(45, 45, 60)
    end
end)

-- 18. Anti-AFK Button
createToggleButton("🛡️ Anti-AFK (Chống Văng): ON", Color3.fromRGB(0, 200, 255), function(btn, stroke)
    AntiAFK = not AntiAFK
    if AntiAFK then
        btn.Text = "🛡️ Anti-AFK (Chống Văng): ON"
        btn.TextColor3 = Color3.fromRGB(0, 200, 255)
        stroke.Color = Color3.fromRGB(0, 200, 255)
    else
        btn.Text = "🛡️ Anti-AFK (Chống Văng): OFF"
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        stroke.Color = Color3.fromRGB(45, 45, 60)
    end
end)

-- Status Footer Bar
local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(1, 0, 0, 32)
StatusFrame.Position = UDim2.new(0, 0, 1, -32)
StatusFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
StatusFrame.BorderSizePixel = 0
StatusFrame.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -16, 1, 0)
StatusLabel.Position = UDim2.new(0, 8, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Trạng thái: Sẵn sàng."
StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusFrame

local function setStatus(txt)
    StatusLabel.Text = "Trạng thái: " .. txt
end

-- ═══════════════════════════════════════════════════════════
-- MODAL MAKER UTIL FOR RARITIES, FORMS & TRASH
-- ═══════════════════════════════════════════════════════════
local function createSelectionModal(titleText, itemsTable, selectedMap)
    local ModalFrame = Instance.new("Frame")
    ModalFrame.Size = UDim2.new(0, 290, 0, 360)
    ModalFrame.Position = UDim2.new(0.5, -145, 0.5, -180)
    ModalFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    ModalFrame.Active = true
    ModalFrame.Draggable = true
    ModalFrame.Visible = false
    ModalFrame.Parent = ScreenGui

    local mCorner = Instance.new("UICorner")
    mCorner.CornerRadius = UDim.new(0, 12)
    mCorner.Parent = ModalFrame

    local mStroke = Instance.new("UIStroke")
    mStroke.Color = Color3.fromRGB(0, 255, 170)
    mStroke.Thickness = 1.5
    mStroke.Parent = ModalFrame

    -- Modal Header
    local mHeader = Instance.new("Frame")
    mHeader.Size = UDim2.new(1, 0, 0, 36)
    mHeader.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
    mHeader.Parent = ModalFrame

    local mTitle = Instance.new("TextLabel")
    mTitle.Size = UDim2.new(1, -40, 1, 0)
    mTitle.Position = UDim2.new(0, 10, 0, 0)
    mTitle.BackgroundTransparency = 1
    mTitle.Text = titleText
    mTitle.TextColor3 = Color3.fromRGB(0, 255, 170)
    mTitle.TextSize = 13
    mTitle.Font = Enum.Font.SourceSansBold
    mTitle.TextXAlignment = Enum.TextXAlignment.Left
    mTitle.Parent = mHeader

    local mClose = Instance.new("TextButton")
    mClose.Size = UDim2.new(0, 24, 0, 24)
    mClose.Position = UDim2.new(1, -28, 0, 6)
    mClose.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    mClose.Text = "X"
    mClose.TextColor3 = Color3.fromRGB(255, 255, 255)
    mClose.Font = Enum.Font.SourceSansBold
    mClose.TextSize = 11
    mClose.Parent = mHeader
    local mcCorner = Instance.new("UICorner")
    mcCorner.CornerRadius = UDim.new(0, 6)
    mcCorner.Parent = mClose
    mClose.MouseButton1Click:Connect(function() ModalFrame.Visible = false end)

    -- Quick Select Buttons (Select All / Deselect All)
    local SelectAllBtn = Instance.new("TextButton")
    SelectAllBtn.Size = UDim2.new(0.46, 0, 0, 26)
    SelectAllBtn.Position = UDim2.new(0.03, 0, 0, 42)
    SelectAllBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
    SelectAllBtn.Text = "✓ Chọn Tất Cả"
    SelectAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SelectAllBtn.Font = Enum.Font.SourceSansBold
    SelectAllBtn.TextSize = 11
    SelectAllBtn.Parent = ModalFrame
    local saCorner = Instance.new("UICorner")
    saCorner.CornerRadius = UDim.new(0, 6)
    saCorner.Parent = SelectAllBtn

    local DeselectAllBtn = Instance.new("TextButton")
    DeselectAllBtn.Size = UDim2.new(0.46, 0, 0, 26)
    DeselectAllBtn.Position = UDim2.new(0.51, 0, 0, 42)
    DeselectAllBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    DeselectAllBtn.Text = "✗ Bỏ Chọn Tất Cả"
    DeselectAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    DeselectAllBtn.Font = Enum.Font.SourceSansBold
    DeselectAllBtn.TextSize = 11
    DeselectAllBtn.Parent = ModalFrame
    local daCorner = Instance.new("UICorner")
    daCorner.CornerRadius = UDim.new(0, 6)
    daCorner.Parent = DeselectAllBtn

    -- Item Scroll
    local mScroll = Instance.new("ScrollingFrame")
    mScroll.Size = UDim2.new(1, -16, 1, -80)
    mScroll.Position = UDim2.new(0, 8, 0, 74)
    mScroll.BackgroundTransparency = 1
    mScroll.ScrollBarThickness = 4
    mScroll.CanvasSize = UDim2.new(0, 0, 0, #itemsTable * 34)
    mScroll.Parent = ModalFrame

    local mLayout = Instance.new("UIListLayout")
    mLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mLayout.Padding = UDim.new(0, 4)
    mLayout.Parent = mScroll

    local itemButtons = {}

    for _, name in ipairs(itemsTable) do
        local isSel = selectedMap[name]
        local ibtn = Instance.new("TextButton")
        ibtn.Size = UDim2.new(1, 0, 0, 30)
        ibtn.BackgroundColor3 = isSel and Color3.fromRGB(0, 160, 100) or Color3.fromRGB(32, 32, 46)
        ibtn.Text = (isSel and "[✓] " or "[ ] ") .. name
        ibtn.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 200)
        ibtn.Font = Enum.Font.SourceSansBold
        ibtn.TextSize = 12
        ibtn.Parent = mScroll

        local ic = Instance.new("UICorner")
        ic.CornerRadius = UDim.new(0, 6)
        ic.Parent = ibtn

        table.insert(itemButtons, {btn = ibtn, name = name})

        ibtn.MouseButton1Click:Connect(function()
            selectedMap[name] = not selectedMap[name]
            local nowSel = selectedMap[name]
            ibtn.BackgroundColor3 = nowSel and Color3.fromRGB(0, 160, 100) or Color3.fromRGB(32, 32, 46)
            ibtn.Text = (nowSel and "[✓] " or "[ ] ") .. name
            ibtn.TextColor3 = nowSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 200)
        end)
    end

    SelectAllBtn.MouseButton1Click:Connect(function()
        for _, item in ipairs(itemButtons) do
            selectedMap[item.name] = true
            item.btn.BackgroundColor3 = Color3.fromRGB(0, 160, 100)
            item.btn.Text = "[✓] " .. item.name
            item.btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end)

    DeselectAllBtn.MouseButton1Click:Connect(function()
        for _, item in ipairs(itemButtons) do
            selectedMap[item.name] = false
            item.btn.BackgroundColor3 = Color3.fromRGB(32, 32, 46)
            item.btn.Text = "[ ] " .. item.name
            item.btn.TextColor3 = Color3.fromRGB(180, 180, 200)
        end
    end)

    return ModalFrame
end

local raritiesModal = createSelectionModal("🎯 Chọn Độ Hiếm Mua (Buy Rarities)", ALL_RARITIES, SelectedRarities)
local formsModal = createSelectionModal("⚡ Chọn Dòng Form Mua (Buy Forms)", ALL_FORMS, SelectedForms)
local trashModal = createSelectionModal("🗑️ Chọn Độ Hiếm Vứt Rác (Trash Rarities)", ALL_RARITIES, TrashRarities)

btnRarities.MouseButton1Click:Connect(function() raritiesModal.Visible = not raritiesModal.Visible end)
btnForms.MouseButton1Click:Connect(function() formsModal.Visible = not formsModal.Visible end)
btnTrashRarities.MouseButton1Click:Connect(function() trashModal.Visible = not trashModal.Visible end)

-- Instant Harvest All Event
btnHarvestNow.MouseButton1Click:Connect(function()
    setStatus("🌾 Đang thu hoạch toàn bộ cây...")
    local count = 0
    local myPlot = getMyPlot()
    local searchArea = myPlot and myPlot:GetDescendants() or workspace:GetDescendants()

    for _, prompt in pairs(searchArea) do
        if prompt:IsA("ProximityPrompt") then
            local act = string.lower(prompt.ActionText or "")
            local obj = string.lower(prompt.ObjectText or "")
            if string.find(act, "harvest") or string.find(act, "collect") or string.find(act, "pick") or string.find(act, "take") or string.find(act, "grab") or (string.find(obj, "grow pad") and act ~= "plant" and act ~= "buy") then
                triggerPrompt(prompt)
                count = count + 1
            end
        end
    end
    setStatus("🌾 Đã thu hoạch xong (" .. count .. " cây)!")
end)

-- ═══════════════════════════════════════════════════════════
-- CORE AUTOMATION LOOPS WITH LIGHTNING PROTECTION & ANTI-BAN
-- ═══════════════════════════════════════════════════════════

-- 0. Anti-Ban Admin Detector Loop (Continuous Scan)
task.spawn(function()
    while true do
        task.wait(2)
        if AntiBan then
            pcall(function()
                for _, player in pairs(Players:GetPlayers()) do
                    if isPlayerAdmin(player) then
                        setStatus("🚨 PHÁT HIỆN ADMIN: " .. player.Name .. "!")
                        
                        if AdminMode == "SERVER_HOP" then
                            setStatus("🌐 Đang đổi Server khác để né Admin...")
                            task.wait(1)
                            serverHop()
                        elseif AdminMode == "KICK_SELF" then
                            setStatus("🚪 Đang tự ngắt kết nối...")
                            task.wait(1)
                            LocalPlayer:Kick("🛡️ Anti-Ban: Đã ngắt kết nối an toàn vì phát hiện Admin (" .. player.Name .. ") vào server.")
                        elseif AdminMode == "PAUSE_ALL" then
                            AutoPlant = false
                            AutoBuy = false
                            AutoBuyAll = false
                            AutoTrash = false
                            AutoCollect = false
                            AutoSell = false
                            setStatus("🛑 Đã tạm dừng tất cả Auto do phát hiện Admin!")
                        end
                        break
                    end
                end
            end)
        end
    end
end)

-- Detect Admin joining in real-time
Players.PlayerAdded:Connect(function(player)
    if AntiBan then
        task.wait(1)
        if isPlayerAdmin(player) then
            setStatus("🚨 ADMIN VỪA VÀO SERVER: " .. player.Name .. "!")
            if AdminMode == "SERVER_HOP" then
                serverHop()
            elseif AdminMode == "KICK_SELF" then
                LocalPlayer:Kick("🛡️ Anti-Ban: Phát hiện Admin (" .. player.Name .. ") vừa tham gia server.")
            elseif AdminMode == "PAUSE_ALL" then
                AutoPlant = false
                AutoBuy = false
                AutoBuyAll = false
                AutoTrash = false
                AutoCollect = false
                AutoSell = false
            end
        end
    end
end)

-- 🍱 AUTO SELECT FOOD ENGINE (Runs every 0.1s)
task.spawn(function()
    while true do
        task.wait(0.1)
        pcall(function()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if not playerGui then return end

            local targetFoodName = ALL_FOOD_TYPES[SelectedFoodIndex] or "Basic"
            
            for _, gui in pairs(playerGui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Enabled then
                    local isFoodWindow = false
                    for _, desc in pairs(gui:GetDescendants()) do
                        if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and desc.Text ~= "" then
                            local txt = string.upper(desc.Text)
                            if string.find(txt, "SELECT FOOD") or string.find(txt, "FEED ") then
                                isFoodWindow = true
                                break
                            end
                        end
                    end

                    if isFoodWindow then
                        local targetBtn = nil
                        local fallbackBtn = nil
                        local targetLower = string.lower(targetFoodName)

                        for _, desc in pairs(gui:GetDescendants()) do
                            if desc:IsA("TextButton") or desc:IsA("ImageButton") then
                                local btnText = ""
                                pcall(function() btnText = string.lower(desc.Text) end)
                                local btnName = string.lower(desc.Name)

                                if string.find(btnText, targetLower) or string.find(btnName, targetLower) then
                                    targetBtn = desc
                                    break
                                end

                                if string.find(btnText, "basic") or string.find(btnName, "basic") or string.find(btnText, "none") or string.find(btnName, "none") then
                                    fallbackBtn = desc
                                end
                            end
                        end

                        local btnToClick = targetBtn or fallbackBtn
                        if btnToClick then
                            setStatus("🍱 Đang tự động chọn thức ăn: " .. targetFoodName .. "...")
                            pcall(function()
                                if firesignal then firesignal(btnToClick.MouseButton1Click) end
                            end)
                            pcall(function()
                                if getconnections then
                                    for _, conn in pairs(getconnections(btnToClick.MouseButton1Click)) do
                                        conn:Fire()
                                    end
                                end
                            end)
                            pcall(function()
                                local VirtualInputManager = game:GetService("VirtualInputManager")
                                if btnToClick.AbsolutePosition and btnToClick.AbsoluteSize then
                                    local pos = btnToClick.AbsolutePosition + (btnToClick.AbsoluteSize / 2)
                                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y + 36, 0, true, game, 1)
                                    task.wait(0.02)
                                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y + 36, 0, false, game, 1)
                                end
                            end)
                            task.wait(0.3)
                        end
                    end
                end
            end
        end)
    end
end)

-- ⚡ LIGHTNING DODGE & OPTIMAL HARVEST ENGINE (High-Speed Protection Loop - 0.05s)
local lightningKeywords = {
    "lightning", "thunder", "strike", "cloud", "bolt", 
    "warning", "danger", "beam", "electric", "flash", "spark", "fire"
}

local function isLightningThreat(object)
    if not object then return false end
    
    local oName = string.lower(object.Name)
    for _, kw in ipairs(lightningKeywords) do
        if string.find(oName, kw) then
            return true
        end
    end
    
    pcall(function()
        for attrName, val in pairs(object:GetAttributes()) do
            local aLow = string.lower(tostring(attrName))
            for _, kw in ipairs(lightningKeywords) do
                if string.find(aLow, kw) then return true end
            end
        end
    end)

    pcall(function()
        for _, child in pairs(object:GetChildren()) do
            if child:IsA("ParticleEmitter") or child:IsA("Beam") or child:IsA("Highlight") or child:IsA("PointLight") then
                local cName = string.lower(child.Name)
                for _, kw in ipairs(lightningKeywords) do
                    if string.find(cName, kw) then return true end
                end
            end
        end
    end)

    return false
end

task.spawn(function()
    while true do
        task.wait(0.05)
        if AutoDodgeLightning or AutoHarvestMax then
            pcall(function()
                local myPlot = getMyPlot()
                local searchArea = myPlot and myPlot:GetDescendants() or workspace:GetDescendants()

                for _, prompt in pairs(searchArea) do
                    if prompt:IsA("ProximityPrompt") then
                        local actText = string.lower(prompt.ActionText or "")
                        local objText = string.lower(prompt.ObjectText or "")
                        
                        local isHarvestPrompt = string.find(actText, "harvest") 
                            or string.find(actText, "collect") 
                            or string.find(actText, "pick") 
                            or string.find(actText, "take")
                            or string.find(actText, "grab")
                            or (string.find(objText, "grow pad") and actText ~= "plant" and actText ~= "buy")
                        
                        if isHarvestPrompt then
                            local parentPad = prompt.Parent
                            local hasLightning = false
                            
                            if AutoDodgeLightning and parentPad then
                                if isLightningThreat(parentPad) or isLightningThreat(parentPad.Parent) then
                                    hasLightning = true
                                end
                                
                                if not hasLightning and parentPad:IsA("BasePart") then
                                    for _, item in pairs(workspace:GetChildren()) do
                                        if isLightningThreat(item) and item:IsA("BasePart") then
                                            if (item.Position - parentPad.Position).Magnitude <= 25 then
                                                hasLightning = true
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                            
                            if hasLightning then
                                setStatus("⚡ SÉT ĐÁNH! Tự động thu hoạch né sét tức thì!")
                                triggerPrompt(prompt)
                            elseif AutoHarvestMax then
                                triggerPrompt(prompt)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- 1. Auto Plant Loop (ONLY PLANT ON YOUR OWN PLOT)
task.spawn(function()
    while true do
        task.wait(PlantDelay + (math.random(1, 5) / 100))
        if AutoPlant then
            pcall(function()
                setStatus("Đang Auto Plant (Trồng trên ô đất của bạn)...")
                local char = LocalPlayer.Character
                local bp = LocalPlayer:FindFirstChild("Backpack")
                
                local currentTool = char and char:FindFirstChildOfClass("Tool")
                if not currentTool or not string.find(currentTool.Name, "Ungrown") then
                    if bp then
                        for _, item in pairs(bp:GetChildren()) do
                            if item:IsA("Tool") and string.find(item.Name, "Ungrown") then
                                item.Parent = char
                                break
                            end
                        end
                    end
                end

                local myPlot = getMyPlot()
                local promptList = {}

                if myPlot then
                    for _, p in pairs(myPlot:GetDescendants()) do
                        if p:IsA("ProximityPrompt") and (p.ActionText == "Plant" or p.ObjectText == "Grow Pad") then
                            table.insert(promptList, p)
                        end
                    end
                else
                    -- Fallback: Filter out prompts inside other players' plots
                    for _, p in pairs(workspace:GetDescendants()) do
                        if p:IsA("ProximityPrompt") and (p.ActionText == "Plant" or p.ObjectText == "Grow Pad") then
                            local isOther = false
                            pcall(function()
                                local anc = p:FindFirstAncestorOfClass("Model") or p:FindFirstAncestorOfClass("Folder")
                                if anc then
                                    local aName = string.lower(anc.Name)
                                    for _, otherP in pairs(Players:GetPlayers()) do
                                        if otherP ~= LocalPlayer then
                                            local oName = string.lower(otherP.Name)
                                            local oDisp = string.lower(otherP.DisplayName)
                                            if string.find(aName, oName) or string.find(aName, oDisp) then
                                                isOther = true
                                                break
                                            end
                                        end
                                    end
                                end
                            end)
                            if not isOther then
                                table.insert(promptList, p)
                            end
                        end
                    end
                end

                for _, prompt in ipairs(promptList) do
                    triggerPrompt(prompt)
                end
            end)
        end
    end
end)

-- 2. Auto Buy Loop
task.spawn(function()
    while true do
        task.wait(BuyDelay + (math.random(1, 5) / 100))
        if AutoBuy or AutoBuyAll then
            pcall(function()
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and (prompt.ActionText == "Buy" or (prompt.Parent and prompt.Parent.Name == "ConveyorBrainrot")) then
                        
                        if AutoBuyAll then
                            setStatus("⚡ Mua Tất Cả (Auto Buy ALL)...")
                            triggerPrompt(prompt)
                        elseif AutoBuy then
                            local model = prompt.Parent
                            local detectedRarity = nil
                            local detectedForm = "Normal"

                            if model then
                                local searchContainer = model.Parent or model

                                local attrRarity = model:GetAttribute("Rarity") or searchContainer:GetAttribute("Rarity")
                                local attrForm = model:GetAttribute("Form") or searchContainer:GetAttribute("Form")
                                
                                if attrRarity then detectedRarity = tostring(attrRarity) end
                                if attrForm then detectedForm = tostring(attrForm) end

                                for _, desc in pairs(searchContainer:GetDescendants()) do
                                    if desc:IsA("TextLabel") and desc.Text ~= "" then
                                        local txt = string.lower(desc.Text)
                                        for _, rName in ipairs(ALL_RARITIES) do
                                            if rName ~= "Unknown" and string.find(txt, string.lower(rName)) then
                                                detectedRarity = rName
                                            end
                                        end
                                        for _, fName in ipairs(ALL_FORMS) do
                                            if fName ~= "Normal" and string.find(txt, string.lower(fName)) then
                                                detectedForm = fName
                                            end
                                        end
                                    end
                                end

                                if not detectedRarity then
                                    local fullN = string.lower(model:GetFullName())
                                    for _, rName in ipairs(ALL_RARITIES) do
                                        if rName ~= "Unknown" and string.find(fullN, string.lower(rName)) then
                                            detectedRarity = rName
                                        end
                                    end
                                end
                            end

                            local finalRarity = detectedRarity or "Unknown"
                            local finalForm = detectedForm or "Normal"

                            local rarityMatched = (SelectedRarities[finalRarity] == true)
                            local formMatched = (SelectedForms[finalForm] == true)

                            local shouldBuy = false
                            if FilterMode == "BOTH" then
                                shouldBuy = rarityMatched and formMatched
                            elseif FilterMode == "RARITY_ONLY" then
                                shouldBuy = rarityMatched
                            elseif FilterMode == "FORM_ONLY" then
                                shouldBuy = formMatched
                            end

                            if shouldBuy then
                                setStatus("🛒 Đang mua: [" .. finalRarity .. "] " .. finalForm .. "...")
                                triggerPrompt(prompt)
                            else
                                setStatus("🔍 Đã bỏ qua: [" .. finalRarity .. "] " .. finalForm .. " (Không khớp bộ lọc)")
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- 3. Auto Trash Loop (Vứt rác hạt giống chưa phát triển - CHUẨN XÁC VỚI DATABASE)
task.spawn(function()
    while true do
        task.wait(TrashDelay + (math.random(1, 5) / 100))
        if AutoTrash then
            pcall(function()
                local trashPrompt = nil
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and (prompt.ActionText == "Trash Brainrot" or (prompt.Parent and string.lower(prompt.Parent.Name) == "trash")) then
                        trashPrompt = prompt
                        break
                    end
                end

                if trashPrompt then
                    local char = LocalPlayer.Character
                    local bp = LocalPlayer:FindFirstChild("Backpack")
                    local targetTool = nil
                    local targetRarity = "Unknown"

                    if char then
                        local equipped = char:FindFirstChildOfClass("Tool")
                        if equipped and string.find(equipped.Name, "Ungrown") then
                            local r = detectToolRarity(equipped)
                            if r ~= "Unknown" and TrashRarities[r] == true then
                                targetTool = equipped
                                targetRarity = r
                            end
                        end
                    end

                    if not targetTool and bp then
                        for _, tool in pairs(bp:GetChildren()) do
                            if tool:IsA("Tool") and string.find(tool.Name, "Ungrown") then
                                local r = detectToolRarity(tool)
                                if r ~= "Unknown" and TrashRarities[r] == true then
                                    tool.Parent = char
                                    targetTool = tool
                                    targetRarity = r
                                    break
                                end
                            end
                        end
                    end

                    if targetTool and char and targetTool.Parent == char then
                        setStatus("🗑️ Đang vứt rác: " .. targetTool.Name .. " [" .. targetRarity .. "]...")
                        triggerPrompt(trashPrompt)
                    end
                end
            end)
        end
    end
end)

-- 4. Auto Sell & Collect Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if AutoSell then
            pcall(function()
                setStatus("Đang bán (Auto Sell)...")
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and (prompt.ActionText == "Trash Brainrot" or prompt.ActionText == "Sell") then
                        triggerPrompt(prompt)
                    end
                end
            end)
        end
        if AutoCollect then
            pcall(function()
                local myPlot = getMyPlot()
                local searchArea = myPlot and myPlot:GetDescendants() or workspace:GetDescendants()
                for _, prompt in pairs(searchArea) do
                    if prompt:IsA("ProximityPrompt") and (prompt.ActionText == "Claim" or prompt.ActionText == "Collect") then
                        triggerPrompt(prompt)
                    end
                end
            end)
        end
    end
end)

-- 5. Anti-AFK Protection
LocalPlayer.Idled:Connect(function()
    if AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end
end)

setStatus("Đã khởi tạo V15 - Đã lọc chính xác Plot của bạn!")
