--[[
    ===================================================================
    🧠 GREEDY BRAINROTS - ULTIMATE AUTO HUB V28 (SUPREME RARITY & 24/7 LIGHTNING SHIELD)
    - V27.2 FIX CỰC KỲ QUAN TRỌNG:
      1. Sửa triệt để bug getGrowPadPrompts nhầm thùng rác (TrashCan) thành nút thu hoạch.
         -> Loại trừ tất cả prompt chứa từ khóa "trash", "bin", "sell", "buy", "collect" 
            và CHỈ gán nút Thu Hoạch khi tìm thấy đúng từ khóa Harvest/Take/Pick/Pad/Crop.
      2. Sửa thuật toán phát hiện độ hiếm detectToolRarity:
         -> Dùng khớp từ chính xác (%f[%a]word%f[%A]) tránh nhận nhầm "Uncommon" -> "Common",
            tránh nhận nhầm "Frog/Hedgehog/Catalog" -> "OG".
      3. Auto Trash tuyệt đối an toàn: CHỈ vứt đúng Tool trong Backpack có độ hiếm được tick chọn TRUE,
         KHÔNG BAO GIỜ đụng vào Tool đang cầm trên tay hoặc độ hiếm Unknown/Khác.
    ===================================================================
--]]

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Safe GUI Container Helper (delta/gethui/CoreGui/PlayerGui)
local function getGuiContainer()
    local container = nil
    pcall(function()
        if gethui then
            container = gethui()
        elseif syn and syn.protect_gui then
            local f = Instance.new("Folder")
            syn.protect_gui(f)
            f.Parent = game:GetService("CoreGui")
            container = f
        elseif game:GetService("CoreGui") then
            container = game:GetService("CoreGui")
        end
    end)
    if not container then
        pcall(function()
            container = LocalPlayer:WaitForChild("PlayerGui")
        end)
    end
    return container
end

-- Clear existing GUI
pcall(function()
    local targetContainer = getGuiContainer()
    if targetContainer and targetContainer:FindFirstChild("GreedyBrainrotsGui") then
        targetContainer.GreedyBrainrotsGui:Destroy()
    end
    if game:GetService("CoreGui"):FindFirstChild("GreedyBrainrotsGui") then
        game:GetService("CoreGui").GreedyBrainrotsGui:Destroy()
    end
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("GreedyBrainrotsGui") then
        LocalPlayer.PlayerGui.GreedyBrainrotsGui:Destroy()
    end
end)

-- ── State Variables ──
local AutoPlant = false
local LightningShield247 = true -- 🛡️ KHIÊN CHỐNG SÉT 24/7 (ĐỘC LẬP, BẢO VỆ NGAY CẢ KHI TẮT AUTOPLANT)
local AutoDodgeLightning = true
local DodgeSensitivityMode = "TIMED" -- Mặc định chế độ đếm giây TIMED để căn đúng ~2s
local AutoFood = true
local SelectedFoodIndex = 1

local DodgeLeadTimeIndex = 6 -- Mặc định vị trí số 6 là 2.0s
local ALL_DODGE_TIMES = {0.5, 0.8, 1.0, 1.2, 1.5, 2.0, 2.5, 3.0}

local GrowthWaitIndex = 4
local ALL_GROWTH_TIMES = {8, 10, 12, 15, 18, 20, 25, 30}

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

local AdminMode = "SERVER_HOP" 

local ALL_RARITIES = {
    "Common", "Rare", "Epic", "Legendary", "Mythical", 
    "Godly", "Secret", "Divine", "OG", "Celestial", 
    "Eternal", "Forbidden", "Unknown", "Supreme"
}

local ALL_FORMS = {
    "Normal", "Gold", "Diamond", "Galaxy", "Shadow", "Electrified", 
    "Starfall", "Rainbow", "Hacker", "Lava", "Cooked"
}

-- 🛒 Buy Rarities Map (Mặc định chọn các dòng hiếm)
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
    ["Unknown"]   = false,
    ["Supreme"]   = true
}

-- 🗑️ Trash Rarities Map (FIX STRICT: Mặc định tất cả FALSE, người dùng tự chọn chính xác)
local TrashRarities = {
    ["Common"]    = false,
    ["Rare"]      = false,
    ["Epic"]      = false,
    ["Legendary"] = false,
    ["Mythical"]  = false,
    ["Godly"]     = false,
    ["Secret"]    = false,
    ["Divine"]    = false,
    ["OG"]        = false,
    ["Celestial"] = false,
    ["Eternal"]   = false,
    ["Forbidden"] = false,
    ["Unknown"]   = false, -- KHÔNG BAO GIỜ VỨT UNKNOWN!
    ["Supreme"]   = false  -- KHÔNG BAO GIỜ VỨT SUPREME!
}

local SelectedForms = {}
for _, f in ipairs(ALL_FORMS) do SelectedForms[f] = true end

local FilterMode = "INDEPENDENT" -- Default: Lọc Độc Lập

local BuyDelay = 0.15
local TrashDelay = 0.5

local plantStartTime = 0

-- ═══════════════════════════════════════════════════════════
-- 🛡️ EXACT PLOT ENGINE FOR GREEDY BRAINROTS (PLOT_<USERID>)
-- ═══════════════════════════════════════════════════════════
local cachedMyPlot = nil

local function getMyPlot()
    if cachedMyPlot and cachedMyPlot.Parent then return cachedMyPlot end

    local myIdStr = tostring(LocalPlayer.UserId)
    local targetPlotName = "Plot_" .. myIdStr

    -- 1. Direct search inside Workspace.Plots.Tycoons
    pcall(function()
        local plotsFolder = workspace:FindFirstChild("Plots")
        if plotsFolder then
            local tycoons = plotsFolder:FindFirstChild("Tycoons") or plotsFolder:FindFirstChild("PlotSlots")
            if tycoons then
                local direct = tycoons:FindFirstChild(targetPlotName)
                if direct then
                    cachedMyPlot = direct
                    return direct
                end
                for _, child in pairs(tycoons:GetChildren()) do
                    if child.Name == targetPlotName or string.find(child.Name, myIdStr) then
                        cachedMyPlot = child
                        return child
                    end
                end
            end
        end
    end)

    if cachedMyPlot and cachedMyPlot.Parent then return cachedMyPlot end

    -- 2. Search anywhere in workspace for Plot_<myIdStr>
    pcall(function()
        for _, child in pairs(workspace:GetDescendants()) do
            if (child:IsA("Model") or child:IsA("Folder")) and child.Name == targetPlotName then
                cachedMyPlot = child
                return child
            end
        end
    end)

    if cachedMyPlot and cachedMyPlot.Parent then return cachedMyPlot end

    -- 3. Fallback scan by Player Name / Attributes / DisplayName
    local pName = string.lower(LocalPlayer.Name)
    local pDisp = string.lower(LocalPlayer.DisplayName)

    pcall(function()
        local plotsFolder = workspace:FindFirstChild("Plots") or workspace
        for _, child in pairs(plotsFolder:GetDescendants()) do
            if child:IsA("Model") or child:IsA("Folder") then
                local cName = string.lower(child.Name)
                if string.find(cName, pName) or string.find(cName, pDisp) then
                    cachedMyPlot = child
                    return child
                end
            end
        end
    end)

    return cachedMyPlot
end

local function isOtherPlayerPlot(container)
    if not container or container == workspace then return false end

    local myIdStr = tostring(LocalPlayer.UserId)
    local current = container

    while current and current ~= workspace do
        local cName = current.Name
        
        local plotUserId = string.match(cName, "^Plot_(%d+)")
        if plotUserId then
            if plotUserId ~= myIdStr then
                return true
            else
                return false
            end
        end

        local pName = string.lower(LocalPlayer.Name)
        local pDisp = string.lower(LocalPlayer.DisplayName)

        for _, otherP in pairs(Players:GetPlayers()) do
            if otherP ~= LocalPlayer then
                local oName = string.lower(otherP.Name)
                local oDisp = string.lower(otherP.DisplayName)
                local oId = tostring(otherP.UserId)

                local lowerCName = string.lower(cName)
                if string.find(lowerCName, oName) or string.find(lowerCName, oDisp) or (string.find(cName, "Plot_") and string.find(cName, oId)) then
                    return true
                end

                local hasOtherAttr = false
                pcall(function()
                    for attrName, val in pairs(current:GetAttributes()) do
                        local vStr = string.lower(tostring(val))
                        if vStr == oName or vStr == oDisp or vStr == oId then
                            hasOtherAttr = true
                            break
                        end
                    end
                end)
                if hasOtherAttr then return true end

                local hasOtherValue = false
                pcall(function()
                    for _, child in pairs(current:GetChildren()) do
                        if child:IsA("StringValue") and (string.lower(child.Value) == oName or string.lower(child.Value) == oDisp) then
                            hasOtherValue = true
                            break
                        elseif child:IsA("ObjectValue") and child.Value == otherP then
                            hasOtherValue = true
                            break
                        end
                    end
                end)
                if hasOtherValue then return true end
            end
        end

        current = current.Parent
    end

    return false
end

-- ═══════════════════════════════════════════════════════════
-- BRAINROT ITEM RARITY DATABASE MAP
-- ═══════════════════════════════════════════════════════════
local ITEM_RARITY_DATABASE = {
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
    ["la vacca saturno saturnita"]   = "Common",
    ["bombombini gusini"]            = "Common",
    ["cacto hipopotamo"]             = "Common",

    ["triplito tralaleritos"]        = "Rare",
    ["trippi troppi"]                = "Rare",
    ["bananita dolphinita"]          = "Rare",
    ["torrtuginni dragonfrutini"]    = "Rare",
    ["bobrito bandito"]              = "Rare",
    ["tigroligre frutonni"]          = "Rare",
    ["cappuccino assassino"]         = "Rare",
    ["1x1x1x1"]                      = "Rare",

    ["chicleteirina bicicleteirina"] = "Epic",
    ["chicleteira bicicleteira"]     = "Epic",
    ["pakrahmatmatina"]              = "Epic",

    ["orangutini ananassini"]        = "Legendary",
    ["la grande combinasion"]        = "Legendary",
}

-- 🎯 ULTRA RELIABLE & STRICT TOOL RARITY DETECTOR
local function detectToolRarity(tool)
    if not tool or not tool:IsA("Tool") then return "Unknown" end

    -- Hàm kiểm tra từ khớp chính xác bằng Word Boundary pattern (%f[%a]word%f[%A])
    local function matchRarityStrict(strInput)
        if not strInput or strInput == "" then return nil end
        local sLow = string.lower(tostring(strInput))

        -- Kiểm tra từ "uncommon" để không bao giờ khớp lầm thành "common"
        if string.find(sLow, "%f[%a]uncommon%f[%A]") then
            return "Common"
        end

        -- Kiểm tra độ hiếm từ cao xuống thấp bằng boundary match chuẩn
        local checkOrder = {
            "Forbidden", "Eternal", "Celestial", "Divine", "Secret", 
            "Godly", "Mythical", "Legendary", "Epic", "Rare", "Common"
        }

        for _, r in ipairs(checkOrder) do
            local rLow = string.lower(r)
            if string.find(sLow, "%f[%a]" .. rLow .. "%f[%A]") then
                return r
            end
        end

        -- Khớp chữ OG chính xác (tránh dính chữ frog, hedgehog, catalog...)
        if string.find(sLow, "%f[%a]og%f[%A]") then
            return "OG"
        end

        return nil
    end
    
    -- 1. Direct Attribute check (Độ tin cậy cao nhất trong Roblox)
    local foundRarity = nil
    pcall(function()
        local attr = tool:GetAttribute("Rarity") or tool:GetAttribute("Tier") or tool:GetAttribute("ItemRarity")
        if attr then
            foundRarity = matchRarityStrict(attr)
        end
    end)
    if foundRarity then return foundRarity end
    
    -- 2. Value Object check
    pcall(function()
        local rVal = tool:FindFirstChild("Rarity") or tool:FindFirstChild("Tier") or tool:FindFirstChild("RarityValue")
        if rVal and rVal:IsA("StringValue") then
            foundRarity = matchRarityStrict(rVal.Value)
        end
    end)
    if foundRarity then return foundRarity end

    -- 3. Tool Name & ToolTip Strict Check
    foundRarity = matchRarityStrict(tool.Name) or matchRarityStrict(tool.ToolTip or "")
    if foundRarity then return foundRarity end

    -- 4. Database Map Search
    local tName = string.lower(tool.Name)
    local tTip = string.lower(tool.ToolTip or "")

    for itemName, rarity in pairs(ITEM_RARITY_DATABASE) do
        if string.find(tName, itemName) or string.find(tTip, itemName) then
            return rarity
        end
    end

    -- 5. Search Descendants (Chỉ kiểm tra StringValue Rarity trực tiếp)
    pcall(function()
        for _, desc in pairs(tool:GetDescendants()) do
            if desc:IsA("StringValue") and string.lower(desc.Name) == "rarity" then
                foundRarity = matchRarityStrict(desc.Value)
                if foundRarity then break end
            end
        end
    end)

    return foundRarity or "Unknown"
end

local function optimizePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    pcall(function()
        prompt.MaxActivationDistance = 999999
        prompt.RequiresLineOfSight = false
        prompt.HoldDuration = 0
        prompt.Enabled = true
    end)
end

-- 🛡️ SAFE TRIGGER PROMPT (ABSOLUTE PLOT REJECTION)
local function triggerPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    
    if isOtherPlayerPlot(prompt.Parent) then
        return
    end

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
        task.wait(0.02)
        prompt:InputHoldEnd()
    end)
end

-- ═══════════════════════════════════════════════════════════
-- SMART TOUCH & MOUSE DRAGGABLE HELPER
-- ═══════════════════════════════════════════════════════════
local function makeDraggable(guiObject, handle)
    handle = handle or guiObject
    local dragging = false
    local dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- ANTI-BAN ENGINE
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
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local guiTargetContainer = getGuiContainer()
ScreenGui.Parent = guiTargetContainer

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    pcall(function()
        if ScreenGui and (not ScreenGui.Parent or not ScreenGui.Parent.Parent) then
            ScreenGui.Parent = getGuiContainer()
        end
    end)
end)

-- 🧠 Floating Toggle Icon Button
local ToggleIcon = Instance.new("TextButton")
ToggleIcon.Name = "ToggleIcon"
ToggleIcon.Size = UDim2.new(0, 48, 0, 48)
ToggleIcon.Position = UDim2.new(0, 10, 0.15, 0)
ToggleIcon.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
ToggleIcon.Text = "🧠"
ToggleIcon.TextSize = 24
ToggleIcon.Active = true
ToggleIcon.Visible = true
ToggleIcon.Parent = ScreenGui

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(1, 0)
IconCorner.Parent = ToggleIcon

local IconStroke = Instance.new("UIStroke")
IconStroke.Color = Color3.fromRGB(0, 255, 170)
IconStroke.Thickness = 2
IconStroke.Parent = ToggleIcon

makeDraggable(ToggleIcon)

-- Main Hub Frame (Modern Sleek HUD V28)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 330, 0, 500)
MainFrame.Position = UDim2.new(1, -345, 0.05, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 17, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 255, 170)
MainStroke.Thickness = 1.6
MainStroke.Parent = MainFrame

ToggleIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 46)
Header.BackgroundColor3 = Color3.fromRGB(20, 25, 36)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 14)
HeaderCorner.Parent = Header

makeDraggable(MainFrame, Header)

-- Header Title & Subtitle
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -76, 0, 22)
Title.Position = UDim2.new(0, 12, 0, 4)
Title.BackgroundTransparency = 1
Title.Text = "🧠 GREEDY BRAINROTS V28"
Title.TextColor3 = Color3.fromRGB(0, 255, 170)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -76, 0, 14)
SubTitle.Position = UDim2.new(0, 12, 0, 26)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "⚡ Supreme Rarity & Khiên Sét 24/7"
SubTitle.TextColor3 = Color3.fromRGB(140, 155, 180)
SubTitle.TextSize = 10
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = Header

local MiniBtn = Instance.new("TextButton")
MiniBtn.Name = "MiniBtn"
MiniBtn.Size = UDim2.new(0, 26, 0, 26)
MiniBtn.Position = UDim2.new(1, -60, 0, 10)
MiniBtn.BackgroundColor3 = Color3.fromRGB(40, 48, 68)
MiniBtn.Text = "−"
MiniBtn.TextColor3 = Color3.fromRGB(210, 225, 250)
MiniBtn.Font = Enum.Font.GothamBold
MiniBtn.TextSize = 15
MiniBtn.Parent = Header

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(0, 7)
MiniCorner.Parent = MiniBtn

MiniBtn.MouseButton1Click:Connect(function() 
    MainFrame.Visible = false 
end)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -30, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 65)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 7)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Modern Scrollable Body
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -84)
Scroll.Position = UDim2.new(0, 8, 0, 50)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 170)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 6)
Layout.Parent = Scroll

-- 🎨 Component 1: Section Header with glowing left pill
local function createSectionHeader(titleText, accentColor)
    local col = accentColor or Color3.fromRGB(0, 255, 170)

    local secFrame = Instance.new("Frame")
    secFrame.Size = UDim2.new(1, 0, 0, 28)
    secFrame.BackgroundTransparency = 1
    secFrame.Parent = Scroll

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 0, 16)
    bar.Position = UDim2.new(0, 2, 0.5, -8)
    bar.BackgroundColor3 = col
    bar.BorderSizePixel = 0
    bar.Parent = secFrame

    local bCorn = Instance.new("UICorner")
    bCorn.CornerRadius = UDim.new(1, 0)
    bCorn.Parent = bar

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -18, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = titleText
    lbl.TextColor3 = col
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = secFrame

    return secFrame
end

-- 🎨 Component 2: Modern Toggle Card with embedded Status Badge
local function createToggleButton(titleText, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = defaultState and Color3.fromRGB(18, 38, 30) or Color3.fromRGB(20, 25, 34)
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Parent = Scroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Color = defaultState and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(38, 46, 62)
    s.Thickness = 1.2
    s.Parent = btn

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -72, 1, 0)
    titleLbl.Position = UDim2.new(0, 10, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = titleText
    titleLbl.TextColor3 = defaultState and Color3.fromRGB(240, 255, 250) or Color3.fromRGB(180, 192, 210)
    titleLbl.Font = Enum.Font.GothamMedium
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = btn

    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0, 52, 0, 22)
    badge.Position = UDim2.new(1, -60, 0.5, -11)
    badge.BackgroundColor3 = defaultState and Color3.fromRGB(0, 200, 130) or Color3.fromRGB(35, 42, 56)
    badge.Parent = btn

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 6)
    badgeCorner.Parent = badge

    local badgeText = Instance.new("TextLabel")
    badgeText.Size = UDim2.new(1, 0, 1, 0)
    badgeText.BackgroundTransparency = 1
    badgeText.Text = defaultState and "BẬT" or "TẮT"
    badgeText.TextColor3 = defaultState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 142, 165)
    badgeText.Font = Enum.Font.GothamBold
    badgeText.TextSize = 10
    badgeText.Parent = badge

    local currentState = defaultState
    btn.MouseButton1Click:Connect(function()
        currentState = not currentState
        btn.BackgroundColor3 = currentState and Color3.fromRGB(18, 38, 30) or Color3.fromRGB(20, 25, 34)
        s.Color = currentState and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(38, 46, 62)
        titleLbl.TextColor3 = currentState and Color3.fromRGB(240, 255, 250) or Color3.fromRGB(180, 192, 210)
        badge.BackgroundColor3 = currentState and Color3.fromRGB(0, 200, 130) or Color3.fromRGB(35, 42, 56)
        badgeText.Text = currentState and "BẬT" or "TẮT"
        badgeText.TextColor3 = currentState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 142, 165)
        callback(currentState, btn, s)
    end)

    return btn
end

-- 🎨 Component 3: Modern Action/Setting Card with Value Badge
local function createActionButton(titleText, valueText, accentColor, callback)
    local col = accentColor or Color3.fromRGB(255, 190, 80)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(20, 25, 34)
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Parent = Scroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(38, 46, 62)
    s.Thickness = 1
    s.Parent = btn

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -20, 0, 18)
    titleLbl.Position = UDim2.new(0, 10, 0, 2)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = titleText
    titleLbl.TextColor3 = col
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = btn

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(1, -20, 0, 15)
    valLbl.Position = UDim2.new(0, 10, 0, 18)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = valueText
    valLbl.TextColor3 = Color3.fromRGB(180, 195, 215)
    valLbl.Font = Enum.Font.Gotham
    valLbl.TextSize = 10
    valLbl.TextXAlignment = Enum.TextXAlignment.Left
    valLbl.Parent = btn

    btn.MouseButton1Click:Connect(function()
        callback(btn, valLbl, s)
    end)

    return btn, valLbl
end

-- ═══════════════════════════════════════════════════════════
-- SECTION 1: 🛡️ BẢO VỆ & NÉ SÉT 24/7
-- ═══════════════════════════════════════════════════════════
createSectionHeader("🛡️ BẢO VỆ & NÉ SÉT 24/7", Color3.fromRGB(0, 255, 180))

-- 1. Khiên Chống Sét Độc Lập 24/7
createToggleButton("🛡️ Khiên Chống Sét 24/7 (Độc Lập)", LightningShield247, function(state)
    LightningShield247 = state
    setStatus(state and "Đã BẬT Khiên Chống Sét Độc Lập 24/7!" or "Đã TẮT Khiên Chống Sét 24/7!")
end)

-- 2. Auto Né Sét Cây
createToggleButton("⚡ Auto Né Sét Cây", AutoDodgeLightning, function(state)
    AutoDodgeLightning = state
    setStatus(state and "Đã BẬT Auto Né Sét Cây!" or "Đã TẮT Auto Né Sét Cây!")
end)

-- 3. Chế Độ Né Sét
local btnDodgeMode, lblDodgeMode = createActionButton("⚡ Chế Độ Né Sét", "Chế độ: [ " .. (DodgeSensitivityMode == "INSTANT" and "Siêu Nhạy Cảm (0ms)" or "Theo Giây Đếm Chờ Size") .. " ]", Color3.fromRGB(100, 220, 255), function(btn, lbl)
    if DodgeSensitivityMode == "INSTANT" then
        DodgeSensitivityMode = "TIMED"
        lbl.Text = "Chế độ: [ Theo Giây Đếm Chờ Size ]"
        lbl.TextColor3 = Color3.fromRGB(100, 220, 255)
    else
        DodgeSensitivityMode = "INSTANT"
        lbl.Text = "Chế độ: [ Siêu Nhạy Cảm (0ms) ]"
        lbl.TextColor3 = Color3.fromRGB(255, 200, 50)
    end
end)

-- 4. Căn Giờ Né Trước Sét
local btnDodgeTiming, lblDodgeTiming = createActionButton("⚡ Căn Giờ Né Trước Sét", "Thời gian né trước: [ ~" .. tostring(ALL_DODGE_TIMES[DodgeLeadTimeIndex]) .. " Giây ]", Color3.fromRGB(255, 220, 100), function(btn, lbl)
    DodgeLeadTimeIndex = DodgeLeadTimeIndex + 1
    if DodgeLeadTimeIndex > #ALL_DODGE_TIMES then DodgeLeadTimeIndex = 1 end
    lbl.Text = "Thời gian né trước: [ ~" .. tostring(ALL_DODGE_TIMES[DodgeLeadTimeIndex]) .. " Giây ]"
end)

-- 5. Anti-Ban & Quét Admin
createToggleButton("🛡️ Anti-Ban & Quét Admin", AntiBan, function(state)
    AntiBan = state
    setStatus(state and "Đã BẬT Anti-Ban & Admin Detector!" or "Đã TẮT Anti-Ban!")
end)

-- 6. Phản Ứng Khi Thấy Admin
local btnAdminMode, lblAdminMode = createActionButton("🚨 Phản Ứng Khi Thấy Admin", "Hành động: [ Đổi Server Khác ]", Color3.fromRGB(255, 140, 60), function(btn, lbl)
    if AdminMode == "SERVER_HOP" then
        AdminMode = "KICK_SELF"
        lbl.Text = "Hành động: [ Tự Ngắt Kết Nối ]"
    elseif AdminMode == "KICK_SELF" then
        AdminMode = "PAUSE_ALL"
        lbl.Text = "Hành động: [ Tạm Dừng Tất Cả ]"
    else
        AdminMode = "SERVER_HOP"
        lbl.Text = "Hành động: [ Đổi Server Khác ]"
    end
end)

-- ═══════════════════════════════════════════════════════════
-- SECTION 2: 🌱 TRỒNG & THU HOẠCH CÂY
-- ═══════════════════════════════════════════════════════════
createSectionHeader("🌱 TRỒNG & THU HOẠCH CÂY", Color3.fromRGB(0, 255, 140))

-- 7. Auto Né Sét & Thu Hoạch
createToggleButton("⚡🌾 Auto Né Sét & Thu Hoạch", AutoPlant, function(state)
    AutoPlant = state
    setStatus(state and "Đã BẬT Auto Né Sét & Thu Hoạch!" or "Đã TẮT Auto Thu Hoạch.")
end)

-- 8. Thời Gian Chờ Nuôi Cây
local btnGrowthTime, lblGrowthTime = createActionButton("⏱️ Thời Gian Chờ Nuôi Cây", "Nuôi size tối đa: [ " .. tostring(ALL_GROWTH_TIMES[GrowthWaitIndex]) .. " Giây ]", Color3.fromRGB(100, 255, 180), function(btn, lbl)
    GrowthWaitIndex = GrowthWaitIndex + 1
    if GrowthWaitIndex > #ALL_GROWTH_TIMES then GrowthWaitIndex = 1 end
    lbl.Text = "Nuôi size tối đa: [ " .. tostring(ALL_GROWTH_TIMES[GrowthWaitIndex]) .. " Giây ]"
end)

-- 9. Auto Chọn Đồ Ăn
createToggleButton("🍱 Auto Chọn Đồ Ăn (Food)", AutoFood, function(state)
    AutoFood = state
    setStatus(state and "Đã BẬT Auto Select Food!" or "Đã TẮT Auto Select Food.")
end)

-- 10. Loại Đồ Ăn Cho Cây
local btnFoodType, lblFoodType = createActionButton("🍕 Loại Đồ Ăn Cho Cây", "Đang chọn: [ " .. ALL_FOOD_DISPLAYS[SelectedFoodIndex] .. " ]", Color3.fromRGB(255, 180, 50), function(btn, lbl)
    SelectedFoodIndex = SelectedFoodIndex + 1
    if SelectedFoodIndex > #ALL_FOOD_TYPES then SelectedFoodIndex = 1 end
    lbl.Text = "Đang chọn: [ " .. ALL_FOOD_DISPLAYS[SelectedFoodIndex] .. " ]"
end)

-- 11. Nút Thu Hoạch Tất Cả Ngay Lập Tức
local btnHarvestNow = Instance.new("TextButton")
btnHarvestNow.Size = UDim2.new(1, 0, 0, 36)
btnHarvestNow.BackgroundColor3 = Color3.fromRGB(0, 140, 180)
btnHarvestNow.AutoButtonColor = false
btnHarvestNow.Text = "🌾 THU HOẠCH CÂY NGAY LẬP TỨC!"
btnHarvestNow.TextColor3 = Color3.fromRGB(255, 255, 255)
btnHarvestNow.Font = Enum.Font.GothamBold
btnHarvestNow.TextSize = 12
btnHarvestNow.Parent = Scroll
local hnCorner = Instance.new("UICorner")
hnCorner.CornerRadius = UDim.new(0, 8)
hnCorner.Parent = btnHarvestNow

-- ═══════════════════════════════════════════════════════════
-- SECTION 3: 🛒 MUA TỰ ĐỘNG (BĂNG CHUYỀN)
-- ═══════════════════════════════════════════════════════════
createSectionHeader("🛒 MUA TỰ ĐỘNG BĂNG CHUYỀN", Color3.fromRGB(0, 180, 255))

-- 12. Auto Buy
createToggleButton("🛒 Auto Buy (Theo Bộ Lọc)", AutoBuy, function(state)
    AutoBuy = state
    setStatus(state and "Đã BẬT Auto Buy theo bộ lọc!" or "Đã TẮT Auto Buy.")
end)

-- 13. Auto Buy ALL
createToggleButton("⚡ Auto Buy ALL (Mua TẤT CẢ)", AutoBuyAll, function(state)
    AutoBuyAll = state
    setStatus(state and "Đã BẬT Auto Buy ALL (Mua hết)!" or "Đã TẮT Auto Buy ALL.")
end)

-- 14. Chế Độ Lọc Mua
local btnMode, lblMode = createActionButton("🔀 Chế Độ Lọc Mua", "Hiện tại: [ " .. (FilterMode == "INDEPENDENT" and "LỌC ĐỘC LẬP (Rarity HOẶC Form)" or FilterMode) .. " ]", Color3.fromRGB(0, 255, 170), function(btn, lbl)
    if FilterMode == "INDEPENDENT" then
        FilterMode = "BOTH"
        lbl.Text = "Hiện tại: [ KHỚP CẢ HAI (Rarity + Form) ]"
        lbl.TextColor3 = Color3.fromRGB(255, 200, 100)
    elseif FilterMode == "BOTH" then
        FilterMode = "RARITY_ONLY"
        lbl.Text = "Hiện tại: [ Chỉ Độ Hiếm ]"
        lbl.TextColor3 = Color3.fromRGB(255, 200, 100)
    elseif FilterMode == "RARITY_ONLY" then
        FilterMode = "FORM_ONLY"
        lbl.Text = "Hiện tại: [ Chỉ Dòng Form ]"
        lbl.TextColor3 = Color3.fromRGB(180, 120, 255)
    else
        FilterMode = "INDEPENDENT"
        lbl.Text = "Hiện tại: [ LỌC ĐỘC LẬP (Rarity HOẶC Form) ]"
        lbl.TextColor3 = Color3.fromRGB(0, 255, 170)
    end
end)

-- 15. Chọn Độ Hiếm Mua (Có Supreme)
local btnRarities = Instance.new("TextButton")
btnRarities.Size = UDim2.new(1, 0, 0, 36)
btnRarities.BackgroundColor3 = Color3.fromRGB(22, 28, 40)
btnRarities.AutoButtonColor = false
btnRarities.Text = "🎯 Chọn Độ Hiếm Mua (Có Supreme)..."
btnRarities.TextColor3 = Color3.fromRGB(255, 200, 100)
btnRarities.Font = Enum.Font.GothamBold
btnRarities.TextSize = 11
btnRarities.Parent = Scroll
local rCorner = Instance.new("UICorner")
rCorner.CornerRadius = UDim.new(0, 8)
rCorner.Parent = btnRarities
local rStroke = Instance.new("UIStroke")
rStroke.Color = Color3.fromRGB(50, 60, 80)
rStroke.Parent = btnRarities

-- 16. Chọn Dòng Form Mua
local btnForms = Instance.new("TextButton")
btnForms.Size = UDim2.new(1, 0, 0, 36)
btnForms.BackgroundColor3 = Color3.fromRGB(22, 28, 40)
btnForms.AutoButtonColor = false
btnForms.Text = "⚡ Chọn Dòng Form Mua (Buy Forms)..."
btnForms.TextColor3 = Color3.fromRGB(190, 130, 255)
btnForms.Font = Enum.Font.GothamBold
btnForms.TextSize = 11
btnForms.Parent = Scroll
local fCorner = Instance.new("UICorner")
fCorner.CornerRadius = UDim.new(0, 8)
fCorner.Parent = btnForms
local fStroke = Instance.new("UIStroke")
fStroke.Color = Color3.fromRGB(50, 60, 80)
fStroke.Parent = btnForms

-- ═══════════════════════════════════════════════════════════
-- SECTION 4: 🗑️ QUẢN LÝ TÚI ĐỒ & BÁN HÀNG
-- ═══════════════════════════════════════════════════════════
createSectionHeader("🗑️ QUẢN LÝ TÚI ĐỒ & BÁN HÀNG", Color3.fromRGB(255, 90, 130))

-- 17. Auto Trash
createToggleButton("🗑️ Auto Trash (Vứt Rác Theo Lọc)", AutoTrash, function(state)
    AutoTrash = state
    setStatus(state and "Đã BẬT Auto Trash!" or "Đã TẮT Auto Trash.")
end)

-- 18. Chọn Độ Hiếm Vứt Rác
local btnTrashRarities = Instance.new("TextButton")
btnTrashRarities.Size = UDim2.new(1, 0, 0, 36)
btnTrashRarities.BackgroundColor3 = Color3.fromRGB(30, 22, 30)
btnTrashRarities.AutoButtonColor = false
btnTrashRarities.Text = "🗑️ Chọn Độ Hiếm Vứt Rác (Trash Rarities)..."
btnTrashRarities.TextColor3 = Color3.fromRGB(255, 120, 160)
btnTrashRarities.Font = Enum.Font.GothamBold
btnTrashRarities.TextSize = 11
btnTrashRarities.Parent = Scroll
local trCorner = Instance.new("UICorner")
trCorner.CornerRadius = UDim.new(0, 8)
trCorner.Parent = btnTrashRarities
local trStroke = Instance.new("UIStroke")
trStroke.Color = Color3.fromRGB(65, 40, 55)
trStroke.Parent = btnTrashRarities

-- 19. Auto Collect
createToggleButton("💵 Auto Collect (Gom Tiền)", AutoCollect, function(state)
    AutoCollect = state
    setStatus(state and "Đã BẬT Auto Collect gom tiền!" or "Đã TẮT Auto Collect.")
end)

-- 20. Auto Sell
createToggleButton("💰 Auto Sell (Bán Hết)", AutoSell, function(state)
    AutoSell = state
    setStatus(state and "Đã BẬT Auto Sell bán hết!" or "Đã TẮT Auto Sell.")
end)

-- ═══════════════════════════════════════════════════════════
-- SECTION 5: ⚙️ TIỆN ÍCH HỆ THỐNG
-- ═══════════════════════════════════════════════════════════
createSectionHeader("⚙️ TIỆN ÍCH HỆ THỐNG", Color3.fromRGB(0, 200, 255))

-- 21. Anti-AFK
createToggleButton("🛡️ Anti-AFK (Chống Văng 24/7)", AntiAFK, function(state)
    AntiAFK = state
    setStatus(state and "Đã BẬT Anti-AFK chống văng game!" or "Đã TẮT Anti-AFK.")
end)

-- Status Footer Bar
local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(1, 0, 0, 32)
StatusFrame.Position = UDim2.new(0, 0, 1, -32)
StatusFrame.BackgroundColor3 = Color3.fromRGB(10, 13, 19)
StatusFrame.BorderSizePixel = 0
StatusFrame.Parent = MainFrame

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 7, 0, 7)
StatusDot.Position = UDim2.new(0, 10, 0.5, -3)
StatusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
StatusDot.BorderSizePixel = 0
StatusDot.Parent = StatusFrame

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = StatusDot

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -28, 1, 0)
StatusLabel.Position = UDim2.new(0, 24, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Sẵn sàng V28 (Supreme & Khiên Sét 24/7)."
StatusLabel.TextColor3 = Color3.fromRGB(200, 215, 235)
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusFrame

local function setStatus(txt)
    StatusLabel.Text = txt
end

-- 🛠️ Selection Modal Component Helper (Modern Sleek Card)
local function createSelectionModal(titleText, itemList, selectedMap)
    local ModalFrame = Instance.new("Frame")
    ModalFrame.Size = UDim2.new(0, 280, 0, 420)
    ModalFrame.Position = UDim2.new(0.5, -140, 0.5, -210)
    ModalFrame.BackgroundColor3 = Color3.fromRGB(14, 17, 24)
    ModalFrame.BorderSizePixel = 0
    ModalFrame.Visible = false
    ModalFrame.ZIndex = 100
    ModalFrame.Parent = ScreenGui

    local mCorner = Instance.new("UICorner")
    mCorner.CornerRadius = UDim.new(0, 12)
    mCorner.Parent = ModalFrame

    local mStroke = Instance.new("UIStroke")
    mStroke.Color = Color3.fromRGB(0, 255, 170)
    mStroke.Thickness = 1.5
    mStroke.Parent = ModalFrame

    makeDraggable(ModalFrame)

    local mTitle = Instance.new("TextLabel")
    mTitle.Size = UDim2.new(1, -40, 0, 32)
    mTitle.Position = UDim2.new(0, 12, 0, 6)
    mTitle.BackgroundTransparency = 1
    mTitle.Text = titleText
    mTitle.TextColor3 = Color3.fromRGB(0, 255, 170)
    mTitle.Font = Enum.Font.GothamBold
    mTitle.TextSize = 12
    mTitle.TextXAlignment = Enum.TextXAlignment.Left
    mTitle.ZIndex = 105
    mTitle.Parent = ModalFrame

    local mClose = Instance.new("TextButton")
    mClose.Size = UDim2.new(0, 26, 0, 26)
    mClose.Position = UDim2.new(1, -32, 0, 8)
    mClose.BackgroundColor3 = Color3.fromRGB(200, 50, 65)
    mClose.Text = "✕"
    mClose.TextColor3 = Color3.fromRGB(255, 255, 255)
    mClose.Font = Enum.Font.GothamBold
    mClose.TextSize = 12
    mClose.ZIndex = 105
    mClose.Parent = ModalFrame

    local mcCorner = Instance.new("UICorner")
    mcCorner.CornerRadius = UDim.new(0, 6)
    mcCorner.Parent = mClose

    mClose.MouseButton1Click:Connect(function() ModalFrame.Visible = false end)

    local SelectAllBtn = Instance.new("TextButton")
    SelectAllBtn.Size = UDim2.new(0.47, 0, 0, 26)
    SelectAllBtn.Position = UDim2.new(0, 8, 0, 42)
    SelectAllBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 100)
    SelectAllBtn.Text = "✓ Chọn Tất Cả"
    SelectAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SelectAllBtn.Font = Enum.Font.GothamBold
    SelectAllBtn.TextSize = 10
    SelectAllBtn.ZIndex = 105
    SelectAllBtn.Parent = ModalFrame

    local saCorner = Instance.new("UICorner")
    saCorner.CornerRadius = UDim.new(0, 6)
    saCorner.Parent = SelectAllBtn

    local DeselectAllBtn = Instance.new("TextButton")
    DeselectAllBtn.Size = UDim2.new(0.47, 0, 0, 26)
    DeselectAllBtn.Position = UDim2.new(0.53, -8, 0, 42)
    DeselectAllBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 50)
    DeselectAllBtn.Text = "✗ Bỏ Chọn Tất"
    DeselectAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    DeselectAllBtn.Font = Enum.Font.GothamBold
    DeselectAllBtn.TextSize = 10
    DeselectAllBtn.ZIndex = 105
    DeselectAllBtn.Parent = ModalFrame

    local daCorner = Instance.new("UICorner")
    daCorner.CornerRadius = UDim.new(0, 6)
    daCorner.Parent = DeselectAllBtn

    local mScroll = Instance.new("ScrollingFrame")
    mScroll.Size = UDim2.new(1, -16, 1, -80)
    mScroll.Position = UDim2.new(0, 8, 0, 74)
    mScroll.BackgroundTransparency = 1
    mScroll.ScrollBarThickness = 3
    mScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 170)
    mScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    mScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    mScroll.ZIndex = 102
    mScroll.Parent = ModalFrame

    local mLayout = Instance.new("UIListLayout")
    mLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mLayout.Padding = UDim.new(0, 4)
    mLayout.Parent = mScroll

    local itemButtons = {}

    for _, name in ipairs(itemList) do
        local isSel = (selectedMap[name] == true)

        local ibtn = Instance.new("TextButton")
        ibtn.Size = UDim2.new(1, -4, 0, 30)
        ibtn.BackgroundColor3 = isSel and Color3.fromRGB(18, 42, 32) or Color3.fromRGB(20, 25, 34)
        ibtn.Text = (isSel and " [✓] " or " [  ] ") .. name
        ibtn.TextColor3 = isSel and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(170, 180, 200)
        ibtn.Font = Enum.Font.GothamBold
        ibtn.TextSize = 11
        ibtn.TextXAlignment = Enum.TextXAlignment.Left
        ibtn.ZIndex = 105
        ibtn.Parent = mScroll

        local ic = Instance.new("UICorner")
        ic.CornerRadius = UDim.new(0, 6)
        ic.Parent = ibtn

        local is_stroke = Instance.new("UIStroke")
        is_stroke.Color = isSel and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(35, 42, 56)
        is_stroke.Thickness = 1
        is_stroke.Parent = ibtn

        table.insert(itemButtons, {btn = ibtn, name = name, stroke = is_stroke})

        ibtn.MouseButton1Click:Connect(function()
            selectedMap[name] = not selectedMap[name]
            local nowSel = selectedMap[name]
            ibtn.BackgroundColor3 = nowSel and Color3.fromRGB(18, 42, 32) or Color3.fromRGB(20, 25, 34)
            ibtn.Text = (nowSel and " [✓] " or " [  ] ") .. name
            ibtn.TextColor3 = nowSel and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(170, 180, 200)
            is_stroke.Color = nowSel and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(35, 42, 56)
        end)
    end

    SelectAllBtn.MouseButton1Click:Connect(function()
        for _, item in ipairs(itemButtons) do
            selectedMap[item.name] = true
            item.btn.BackgroundColor3 = Color3.fromRGB(18, 42, 32)
            item.btn.Text = " [✓] " .. item.name
            item.btn.TextColor3 = Color3.fromRGB(0, 255, 170)
            item.stroke.Color = Color3.fromRGB(0, 255, 170)
        end
    end)

    DeselectAllBtn.MouseButton1Click:Connect(function()
        for _, item in ipairs(itemButtons) do
            selectedMap[item.name] = false
            item.btn.BackgroundColor3 = Color3.fromRGB(20, 25, 34)
            item.btn.Text = " [  ] " .. item.name
            item.btn.TextColor3 = Color3.fromRGB(170, 180, 200)
            item.stroke.Color = Color3.fromRGB(35, 42, 56)
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
    if myPlot then
        for _, prompt in pairs(myPlot:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local act = string.lower(prompt.ActionText or "")
                local pName = prompt.Parent and string.lower(prompt.Parent.Name) or ""
                
                -- Loại trừ tuyệt đối các nút vứt/bán/mua/quà tặng/đặt pet/gom tiền
                local isExcluded = false
                local excludeList = {"place", "placement", "đặt", "trash", "bin", "sell", "buy", "purchase", "collect money", "collect cash", "gom tiền", "like", "reward", "group", "gift", "daily", "spin", "wheel", "chest"}
                for _, kw in ipairs(excludeList) do
                    if string.find(act, kw) or string.find(pName, kw) then
                        isExcluded = true
                        break
                    end
                end
                
                if not isExcluded and (string.find(act, "collect") or string.find(act, "pull") or string.find(act, "nhổ") or string.find(act, "harvest") or string.find(act, "take") or string.find(act, "pick") or string.find(act, "thu hoạch")) and not string.find(act, "place") and not string.find(act, "money") and not string.find(act, "cash") then
                    triggerPrompt(prompt)
                    count = count + 1
                end
            end
        end
    end
    setStatus("🌾 Đã gửi lệnh thu hoạch " .. count .. " cây!")
end)

-- ═══════════════════════════════════════════════════════════
-- ⚡ ULTRA PRECISION LIGHTNING THREAT DETECTOR (ACCOUNT & PLOT ISOLATED)
-- ═══════════════════════════════════════════════════════════

-- Kiểm tra vật thể có thuộc Plot hoặc Character của người chơi khác không
local function isOtherPlayerPlot(instance)
    if not instance or instance == workspace then return false end
    local myIdStr = tostring(LocalPlayer.UserId)
    local myName = string.lower(LocalPlayer.Name)
    local myDisp = string.lower(LocalPlayer.DisplayName)

    -- 1. Nếu nằm trong Character của người chơi khác -> 100% của người khác
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= LocalPlayer and otherPlayer.Character then
            if instance:IsDescendantOf(otherPlayer.Character) then
                return true
            end
        end
    end

    -- 2. Kiểm tra chuỗi tên các cấp cha
    local cur = instance
    while cur and cur ~= workspace do
        local cName = string.lower(cur.Name)

        -- Nếu tên chứa thông tin của chính mình -> Thuộc về mình
        if string.find(cName, myIdStr) or string.find(cName, myName) or string.find(cName, myDisp) then
            return false
        end

        -- Nếu tên chứa thông tin của người chơi khác
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            if otherPlayer ~= LocalPlayer then
                local oName = string.lower(otherPlayer.Name)
                local oDisp = string.lower(otherPlayer.DisplayName)
                local oId = tostring(otherPlayer.UserId)

                if (string.find(cName, oName) or string.find(cName, oDisp) or string.find(cName, oId)) then
                    return true
                end
            end
        end

        -- Format Plot_<Id> hoặc Tycoon_<Id>
        local plotUserId = string.match(cName, "plot_?(%d+)") or string.match(cName, "tycoon_?(%d+)")
        if plotUserId and plotUserId ~= myIdStr and #plotUserId >= 4 then
            return true
        end

        cur = cur.Parent
    end
    return false
end

-- Hàm lấy tọa độ 3D của âm thanh trong không gian
local function getSoundWorldPosition(sound)
    if not sound then return nil end
    local p = sound.Parent
    if not p then return nil end
    if p:IsA("BasePart") then
        return p.Position
    elseif p:IsA("Attachment") then
        return p.WorldPosition
    elseif p:IsA("Model") then
        if p.PrimaryPart then return p.PrimaryPart.Position end
        local bp = p:FindFirstChildWhichIsA("BasePart")
        if bp then return bp.Position end
    end
    local ancestorPart = p:FindFirstAncestorWhichIsA("BasePart")
    if ancestorPart then
        return ancestorPart.Position
    end
    return nil
end

-- Xác Định Tiếng Sét Nào Của Tài Khoản Hiện Tại Đang Dùng (Account & Plot Audio Filter)
local function isSoundBelongToMyAccount(sound, padPos, cropStartTime)
    if not sound or not sound:IsA("Sound") or not sound.IsPlaying then return false end

    -- A. Nếu âm thanh nằm trong Character hoặc PlayerGui của chính tài khoản mình -> 100% của mình
    if (LocalPlayer.Character and sound:IsDescendantOf(LocalPlayer.Character)) or
       (LocalPlayer:FindFirstChild("PlayerGui") and sound:IsDescendantOf(LocalPlayer.PlayerGui)) then
        return true
    end

    -- B. Nếu âm thanh nằm trong Character của người chơi khác -> Bỏ qua
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= LocalPlayer and otherPlayer.Character and sound:IsDescendantOf(otherPlayer.Character) then
            return false
        end
    end

    -- C. Nếu âm thanh nằm trong Plot của người chơi khác -> Bỏ qua
    if isOtherPlayerPlot(sound) then
        return false
    end

    -- D. Nếu là âm thanh 3D có vị trí trong không gian:
    local sPos = getSoundWorldPosition(sound)
    if sPos and padPos then
        local horizontalDist = math.sqrt((sPos.X - padPos.X)^2 + (sPos.Z - padPos.Z)^2)
        -- Nếu vị trí âm thanh cách xa hơn 15 studs -> Tiếng sét của người khác! Bỏ qua!
        if horizontalDist > 15 then
            return false
        end
        -- Nếu vị trí nằm sát bệ cây của mình (<= 15 studs) -> Tiếng sét đánh vào bệ mình!
        return true
    end

    -- E. Kiểm tra thời điểm phát âm thanh: Nếu âm thanh phát trước khi gieo hạt này -> Âm thanh cũ còn sót lại, bỏ qua
    if cropStartTime and cropStartTime > 0 then
        if sound.TimePosition and sound.TimePosition > (os.clock() - cropStartTime + 0.25) then
            return false
        end
    end

    -- F. Âm thanh 2D không có tọa độ (toàn server): Kiểm tra Attribute xem có chỉ định tài khoản mình không
    local targetAttr = sound:GetAttribute("Target") or sound:GetAttribute("Player") or sound:GetAttribute("UserId")
    if targetAttr then
        local tStr = string.lower(tostring(targetAttr))
        if tStr == string.lower(LocalPlayer.Name) or tStr == tostring(LocalPlayer.UserId) then
            return true
        else
            return false
        end
    end

    -- Âm thanh 2D chung chung của server đông người -> Bỏ qua để tránh báo động giả!
    return false
end

local function checkLightningThreat(growPadPart, myPlot, cropStartTime)
    myPlot = myPlot or getMyPlot()
    local hasThreat = false
    local timeRemaining = nil

    local lightningKeywords = {
        "lightning", "strike", "thunder", "storm", "cloud", "bolt",
        "danger", "threat", "zap", "electric", "shock"
    }

    local padPos = nil
    if growPadPart then
        padPos = growPadPart:IsA("BasePart") and growPadPart.Position or (growPadPart:IsA("Model") and (growPadPart.PrimaryPart and growPadPart.PrimaryPart.Position or growPadPart:FindFirstChildOfClass("BasePart") and growPadPart:FindFirstChildOfClass("BasePart").Position))
    end
    if not padPos and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        padPos = LocalPlayer.Character.HumanoidRootPart.Position
    end
    if not padPos then return false, nil end

    -- 1. Kiểm tra TRỰC TIẾP trên GrowPad và Cây của tài khoản mình (Không duyệt bừa Parent chung như Plots)
    local searchTargets = {}
    if growPadPart then
        table.insert(searchTargets, growPadPart)
        if growPadPart.Parent and growPadPart.Parent:IsA("Model") and growPadPart.Parent ~= workspace and not isOtherPlayerPlot(growPadPart.Parent) then
            local pName = string.lower(growPadPart.Parent.Name)
            if not string.find(pName, "plots") and not string.find(pName, "farms") and not string.find(pName, "tycoons") then
                table.insert(searchTargets, growPadPart.Parent)
            end
        end
    end

    for _, targetArea in ipairs(searchTargets) do
        -- A. Kiểm tra Attributes trên bệ/cây của mình
        pcall(function()
            for attrName, val in pairs(targetArea:GetAttributes()) do
                local aLow = string.lower(tostring(attrName))
                for _, kw in ipairs(lightningKeywords) do
                    if string.find(aLow, kw) then
                        hasThreat = true
                        if type(val) == "number" then timeRemaining = val end
                        break
                    end
                end
            end
        end)
        if hasThreat then return true, timeRemaining end

        -- B. Kiểm tra Descendants trên bệ/cây của mình
        pcall(function()
            for _, desc in pairs(targetArea:GetDescendants()) do
                local dName = string.lower(desc.Name)
                local isLightningName = false
                for _, kw in ipairs(lightningKeywords) do
                    if string.find(dName, kw) then
                        isLightningName = true
                        break
                    end
                end

                if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                    local txt = string.lower(desc.Text or "")
                    if isLightningName then
                        hasThreat = true
                        local numStr = string.match(txt, "%d+%.?%d*")
                        if numStr then timeRemaining = tonumber(numStr) end
                        break
                    else
                        for _, kw in ipairs(lightningKeywords) do
                            if string.find(txt, kw) then
                                hasThreat = true
                                local numStr = string.match(txt, "%d+%.?%d*")
                                if numStr then timeRemaining = tonumber(numStr) end
                                break
                            end
                        end
                    end
                -- BẮT BUỘC: Hạt/Hiệu ứng phát sáng phải có tên chứa từ khóa Sét (tránh nhầm hạt phát sáng của cây)
                elseif (desc:IsA("ParticleEmitter") or desc:IsA("Beam") or desc:IsA("Highlight") or desc:IsA("Sparkles")) and isLightningName then
                    hasThreat = true
                    break
                -- KIỂM TRA ÂM THANH: Phải xác định tiếng sét thuộc tài khoản của mình
                elseif desc:IsA("Sound") and isLightningName and isSoundBelongToMyAccount(desc, padPos, cropStartTime) then
                    hasThreat = true
                    break
                end
            end
        end)
        if hasThreat then return true, timeRemaining end
    end

    -- 2. Quét vật thể Sét / Mây Sét lơ lửng ngay TRÊN ĐẦU BỆ CÂY của mình (Khoảng cách ngang X-Z <= 15 studs)
    pcall(function()
        for _, obj in pairs(workspace:GetChildren()) do
            if (obj:IsA("BasePart") or obj:IsA("Model")) and not isOtherPlayerPlot(obj) then
                local oName = string.lower(obj.Name)
                local matchesKeyword = false
                for _, kw in ipairs(lightningKeywords) do
                    if string.find(oName, kw) then
                        matchesKeyword = true
                        break
                    end
                end

                if matchesKeyword then
                    local oPos = obj:IsA("BasePart") and obj.Position or (obj.PrimaryPart and obj.PrimaryPart.Position or (obj:FindFirstChildWhichIsA("BasePart") and obj:FindFirstChildWhichIsA("BasePart").Position))
                    if oPos then
                        local horizontalDist = math.sqrt((oPos.X - padPos.X)^2 + (oPos.Z - padPos.Z)^2)
                        local verticalDist = oPos.Y - padPos.Y

                        -- Chỉ báo động nếu mây/sét nằm ngay trên đầu bệ cây của mình (ngang <= 15 studs, cao từ -2 đến 45 studs)
                        if horizontalDist <= 15 and verticalDist >= -2 and verticalDist <= 45 then
                            hasThreat = true
                            for _, textObj in pairs(obj:GetDescendants()) do
                                if textObj:IsA("TextLabel") and textObj.Text ~= "" then
                                    local numStr = string.match(textObj.Text, "%d+%.?%d*")
                                    if numStr then
                                        local n = tonumber(numStr)
                                        if n and n <= 10 then timeRemaining = n end
                                    end
                                end
                            end
                            break
                        end
                    end
                end
            end
        end
    end)
    if hasThreat then return true, timeRemaining end

    -- 3. Quét các âm thanh sét đang phát trong Workspace / SoundService định vị theo bệ cây của mình
    pcall(function()
        for _, snd in pairs(workspace:GetDescendants()) do
            if snd:IsA("Sound") and snd.IsPlaying then
                local sName = string.lower(snd.Name)
                local isLightningSnd = false
                for _, kw in ipairs(lightningKeywords) do
                    if string.find(sName, kw) then
                        isLightningSnd = true
                        break
                    end
                end
                if isLightningSnd and isSoundBelongToMyAccount(snd, padPos, cropStartTime) then
                    hasThreat = true
                    break
                end
            end
        end
    end)

    return hasThreat, timeRemaining
end

-- ═══════════════════════════════════════════════════════════
-- 🌱 STRICT & SAFE PLOT PROXIMITY PROMPT FINDER (FIX LOẠI TRỪ TRASH)
-- ═══════════════════════════════════════════════════════════
local function getGrowPadPrompts(myPlot)
    myPlot = myPlot or getMyPlot()
    if not myPlot then return nil, nil, nil end

    local plantPrompt = nil
    local harvestPrompt = nil
    local growPadPart = nil

    -- Từ khóa LOẠI TRỪ tuyệt đối (Nút thu hoạch KHÔNG THỂ là các nút này)
    local excludeKeywords = {
        "place", "placement", "đặt", "trash", "bin", "dump", "sell", "buy", "purchase", "mua", 
        "collect money", "collect cash", "collect coin", "gom tiền", "store", "shop", "vendor",
        "like", "reward", "group", "gift", "daily", "spin", "wheel", "chest"
    }

    local candidatePrompts = {}

    -- 1. Ưu tiên quét trong myPlot
    if myPlot then
        for _, desc in pairs(myPlot:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                table.insert(candidatePrompts, desc)
            end
        end
    end

    -- 2. Quét thêm các prompt trong bán kính 25 studs quanh nhân vật (chính là bệ cây bạn đang đứng)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _, prompt in pairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local pPart = prompt.Parent
                local pPos = pPart and (pPart:IsA("BasePart") and pPart.Position or (pPart:IsA("Model") and pPart.PrimaryPart and pPart.PrimaryPart.Position))
                if pPos and (pPos - hrp.Position).Magnitude <= 25 then
                    local alreadyIn = false
                    for _, cp in ipairs(candidatePrompts) do
                        if cp == prompt then alreadyIn = true break end
                    end
                    if not alreadyIn then
                        table.insert(candidatePrompts, prompt)
                    end
                end
            end
        end
    end

    for _, desc in ipairs(candidatePrompts) do
        local act = string.lower(desc.ActionText or "")
        local obj = string.lower(desc.ObjectText or "")
        local parentName = desc.Parent and string.lower(desc.Parent.Name) or ""

        -- Kiểm tra xem prompt hoặc tên parent có chứa từ khóa loại trừ không
        local isExcluded = false
        for _, kw in ipairs(excludeKeywords) do
            if string.find(act, kw) or string.find(obj, kw) or string.find(parentName, kw) then
                isExcluded = true
                break
            end
        end

        if not isExcluded then
            if string.find(act, "plant") or string.find(act, "sow") or string.find(act, "trồng") then
                if not plantPrompt then
                    plantPrompt = desc
                    growPadPart = desc.Parent
                end
            elseif (string.find(act, "collect") or string.find(act, "harvest") or string.find(act, "pull")
                   or string.find(act, "take") or string.find(act, "pick") or string.find(act, "nhổ")
                   or string.find(act, "thu hoạch") or string.find(act, "claim") or string.find(act, "gặt"))
                   and not string.find(act, "place") and not string.find(act, "money") and not string.find(act, "cash") then
                if not harvestPrompt then
                    harvestPrompt = desc
                    growPadPart = desc.Parent
                end
            end
        end
    end

    return plantPrompt, harvestPrompt, growPadPart
end

-- ═══════════════════════════════════════════════════════════
-- 🛡️ KHIÊN CHỐNG SÉT ĐỘC LẬP 24/7 (STANDALONE LIGHTNING SHIELD)
-- ═══════════════════════════════════════════════════════════
local lastThreatDetectedTime = 0

-- 1. Hook DescendantAdded: Bắt sự kiện tạo sét 0ms + Xóa hitbox va chạm
pcall(function()
    workspace.DescendantAdded:Connect(function(desc)
        if not LightningShield247 and not AutoDodgeLightning then return end
        pcall(function()
            local name = string.lower(desc.Name)
            local isLightningVFX = false
            for _, kw in ipairs(lightningKeywords) do
                if string.find(name, kw) then
                    isLightningVFX = true
                    break
                end
            end
            if isLightningVFX or name == "__lightningaudio" or name == "ghoststrikefx" or name == "greedybrainrotseclipse" then
                -- Vô hiệu hóa hitbox va chạm sét cục bộ
                if desc:IsA("BasePart") then
                    desc.CanTouch = false
                    desc.CanCollide = false
                    local tt = desc:FindFirstChildOfClass("TouchTransmitter")
                    if tt then tt:Destroy() end
                elseif desc:IsA("Model") then
                    for _, p in ipairs(desc:GetDescendants()) do
                        if p:IsA("BasePart") then
                            p.CanTouch = false
                            p.CanCollide = false
                            local tt = p:FindFirstChildOfClass("TouchTransmitter")
                            if tt then tt:Destroy() end
                        end
                    end
                end

                -- Kiểm tra vị trí nếu nhắm vào Grow Pad của mình
                local myPlot = getMyPlot()
                local _, harvestPrompt, growPadPart = getGrowPadPrompts(myPlot)
                if harvestPrompt and growPadPart then
                    local padPos = growPadPart:IsA("BasePart") and growPadPart.Position or (growPadPart:IsA("Model") and (growPadPart.PrimaryPart and growPadPart.PrimaryPart.Position or growPadPart:FindFirstChildWhichIsA("BasePart") and growPadPart:FindFirstChildWhichIsA("BasePart").Position))
                    local isNearPad = true
                    if padPos and (desc:IsA("BasePart") or (desc:IsA("Model") and desc.PrimaryPart)) then
                        local dPos = desc:IsA("BasePart") and desc.Position or desc.PrimaryPart.Position
                        local horizontalDist = math.sqrt((dPos.X - padPos.X)^2 + (dPos.Z - padPos.Z)^2)
                        if horizontalDist > 25 then
                            isNearPad = false
                        end
                    end

                    if isNearPad then
                        lastThreatDetectedTime = os.clock()
                        setStatus("🛡️ [KHIÊN 24/7] BẮT SÉT TỨC THÌ (0ms)! Thu hoạch Brainrot vào Túi Đồ an toàn!")
                        triggerPrompt(harvestPrompt)
                    end
                end
            end
        end)
    end)
end)

-- 2. Luồng bảo vệ độc lập 24/7 (Kể cả khi TẮT Auto Thu Hoạch / AutoPlant)
task.spawn(function()
    while true do
        task.wait(0.01)
        if LightningShield247 and not AutoPlant then
            pcall(function()
                local myPlot = getMyPlot()
                local _, harvestPrompt, growPadPart = getGrowPadPrompts(myPlot)
                if harvestPrompt then
                    local hasLightning, strikeTime = checkLightningThreat(growPadPart, myPlot, 0)
                    local recentEventThreat = (os.clock() - lastThreatDetectedTime) < 1.5

                    if hasLightning or recentEventThreat then
                        local info = strikeTime and (" (còn " .. string.format("%.1f", strikeTime) .. "s)") or ""
                        setStatus("🛡️ [KHIÊN 24/7] SÉT ĐANG NHẮM VÀO BỆ CÂY" .. info .. "! Đã thu hoạch vào Túi Đồ an toàn 100%!")
                        triggerPrompt(harvestPrompt)
                        task.wait(0.5)
                    end
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- ⚡🌾 AUTO NÉ SÉT & THU HOẠCH ENGINE (HARVEST-ONLY)
-- ═══════════════════════════════════════════════════════════
local plantStartTime = 0

task.spawn(function()
    while true do
        task.wait(0.01)
        if AutoPlant then
            pcall(function()
                local myPlot = getMyPlot()
                local _, harvestPrompt, growPadPart = getGrowPadPrompts(myPlot)

                local targetDodgeLead = ALL_DODGE_TIMES[DodgeLeadTimeIndex] or 2.0
                local targetMaxGrowthTime = ALL_GROWTH_TIMES[GrowthWaitIndex] or 15

                if harvestPrompt then
                    if plantStartTime == 0 then
                        plantStartTime = os.clock()
                    end

                    local elapsedTime = os.clock() - plantStartTime
                    local minSafetyGrowthTime = 1.0 -- Thời gian an toàn tối thiểu tránh giật cây ngay khi vừa nảy mầm
                    local hasLightning, strikeTime = checkLightningThreat(growPadPart, myPlot, plantStartTime)

                    if hasLightning and AutoDodgeLightning then
                        if strikeTime and strikeTime > targetDodgeLead then
                            setStatus("⚡ SÉT CỦA BẠN (còn " .. string.format("%.1f", strikeTime) .. "s)... Chờ né trước " .. targetDodgeLead .. "s")
                        elseif elapsedTime < minSafetyGrowthTime and (not strikeTime or strikeTime > 0.8) then
                            -- Vừa gieo mầm dưới 1s: Chờ cây ổn định, chưa vội giật nếu sét chưa đếm ngược khẩn cấp
                            setStatus("🌱 Cây vừa gieo (" .. string.format("%.1f", elapsedTime) .. "s)... Đang rà soát sét ⚡")
                        else
                            -- Nếu có số đếm <= targetDodgeLead hoặc phát hiện âm thanh/mây sét -> Thu hoạch né ngay!
                            local info = strikeTime and (" (còn " .. string.format("%.1f", strikeTime) .. "s)") or ""
                            setStatus("⚡ PHÁT HIỆN SÉT ĐÁNH VÀO CÂY BẠN" .. info .. "! Thu hoạch NÉ SÉT ngay!")
                            triggerPrompt(harvestPrompt)
                            plantStartTime = 0
                            task.wait(0.5)
                        end
                    else
                        if elapsedTime >= targetMaxGrowthTime then
                            setStatus("🌾 Cây đã nuôi đủ " .. math.floor(elapsedTime) .. "s -> Thu hoạch!")
                            triggerPrompt(harvestPrompt)
                            plantStartTime = 0
                            task.wait(0.5)
                        else
                            setStatus("🌱 Đang nuôi cây lớn (" .. math.floor(elapsedTime) .. "s/" .. targetMaxGrowthTime .. "s)... Theo dõi sét ⚡")
                        end
                    end
                else
                    plantStartTime = 0
                    setStatus("⏳ Chờ bạn trồng cây... (Auto Né Sét & Thu Hoạch đang ON)")
                    task.wait(0.2)
                end
            end)
        end
    end
end)

-- 2. Auto Buy Loop
task.spawn(function()
    while true do
        task.wait(BuyDelay)
        if AutoBuy or AutoBuyAll then
            pcall(function()
                local myPlot = getMyPlot()
                if not myPlot then return end

                local conveyorPrompts = {}
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local act = string.lower(prompt.ActionText or "")
                        local obj = string.lower(prompt.ObjectText or "")
                        if string.find(act, "buy") or string.find(act, "purchase") or string.find(obj, "buy") or string.find(act, "mua") then
                            if not isOtherPlayerPlot(prompt.Parent) then
                                table.insert(conveyorPrompts, prompt)
                            end
                        end
                    end
                end

                for _, prompt in ipairs(conveyorPrompts) do
                    if AutoBuyAll then
                        setStatus("⚡ Buy ALL: Đang mua vật phẩm...")
                        triggerPrompt(prompt)
                    else
                        local model = prompt.Parent
                        while model and not model:IsA("Model") and model ~= workspace do
                            model = model.Parent
                        end

                        if model and model:IsA("Model") then
                            local detectedRarity = nil
                            local detectedForm = nil

                            pcall(function()
                                for attrName, val in pairs(model:GetAttributes()) do
                                    local aStr = tostring(val)
                                    for _, rName in ipairs(ALL_RARITIES) do
                                        if rName ~= "Unknown" and string.find(string.lower(aStr), string.lower(rName)) then
                                            detectedRarity = rName
                                        end
                                    end
                                    for _, fName in ipairs(ALL_FORMS) do
                                        if fName ~= "Normal" and string.find(string.lower(aStr), string.lower(fName)) then
                                            detectedForm = fName
                                        end
                                    end
                                end
                            end)

                            if not detectedRarity or not detectedForm then
                                for _, desc in pairs(model:GetDescendants()) do
                                    if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("StringValue") then
                                        local txt = string.lower(desc:IsA("StringValue") and desc.Value or desc.Text)
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
                            end

                            local finalRarity = detectedRarity or "Unknown"
                            local finalForm = detectedForm or "Normal"

                            local rarityMatched = (SelectedRarities[finalRarity] == true)
                            local formMatched = (SelectedForms[finalForm] == true)

                            local shouldBuy = false
                            if FilterMode == "INDEPENDENT" then
                                shouldBuy = rarityMatched or formMatched
                            elseif FilterMode == "BOTH" then
                                shouldBuy = rarityMatched and formMatched
                            elseif FilterMode == "RARITY_ONLY" then
                                shouldBuy = rarityMatched
                            elseif FilterMode == "FORM_ONLY" then
                                shouldBuy = formMatched
                            end

                            if shouldBuy then
                                setStatus("🛒 Đang mua: [" .. finalRarity .. "] " .. finalForm .. "...")
                                triggerPrompt(prompt)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- 3. Auto Trash Loop (My Plot Only - ULTRA SAFE: CHỈ VỨT ĐÚNG TOOL TRONG BACKPACK ĐƯỢC CHỌN TRUE)
task.spawn(function()
    while true do
        task.wait(TrashDelay + (math.random(5, 15) / 100))
        if AutoTrash then
            pcall(function()
                -- Kiểm tra xem có Rarity nào được chọn TRUE không, nếu không thì BỎ QUA HOÀN TOÀN!
                local anyTrashEnabled = false
                for _, v in pairs(TrashRarities) do
                    if v == true then anyTrashEnabled = true; break end
                end
                if not anyTrashEnabled then return end

                local myPlot = getMyPlot()
                if not myPlot then return end

                local char = LocalPlayer.Character
                if not char then return end
                local bp = LocalPlayer:FindFirstChild("Backpack")
                if not bp then return end

                -- Tìm Trash Prompt trong Plot chính xác
                local trashPrompt = nil
                for _, prompt in pairs(myPlot:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local act = string.lower(prompt.ActionText or "")
                        local pName = prompt.Parent and string.lower(prompt.Parent.Name) or ""
                        if string.find(act, "trash") or string.find(pName, "trash") or string.find(pName, "bin") then
                            trashPrompt = prompt
                            break
                        end
                    end
                end
                if not trashPrompt then return end

                -- CHỈ quét trong Backpack (KHÔNG bao giờ quét tool đang cầm trên tay)
                local targetTool = nil
                local targetRarity = nil

                for _, tool in pairs(bp:GetChildren()) do
                    if tool:IsA("Tool") then
                        local r = detectToolRarity(tool)
                        -- CHỈ vứt khi độ hiếm khác Unknown VÀ được tích TRUE trong TrashRarities
                        if r ~= "Unknown" and TrashRarities[r] == true then
                            targetTool = tool
                            targetRarity = r
                            break
                        end
                    end
                end

                -- Nếu không có Tool nào thỏa điều kiện lọc → BỎ QUA!
                if not targetTool or not targetRarity then return end

                -- Lưu lại Tool đang cầm (nếu có)
                local previousEquipped = char:FindFirstChildOfClass("Tool")

                -- Equip đúng Tool cần vứt từ Backpack sang Character
                targetTool.Parent = char
                task.wait(0.2)

                -- Kiểm tra chắc chắn Tool đã được equip đúng
                if targetTool and targetTool.Parent == char then
                    setStatus("🗑️ Đang vứt rác: " .. targetTool.Name .. " [" .. targetRarity .. "]")
                    
                    -- Kích hoạt prompt vứt rác an toàn
                    pcall(function()
                        if fireproximityprompt then
                            fireproximityprompt(trashPrompt)
                        end
                    end)
                    pcall(function()
                        trashPrompt:InputHoldBegin()
                        task.wait(0.05)
                        trashPrompt:InputHoldEnd()
                    end)
                    task.wait(0.3)
                end

                -- Trả lại Tool trước đó cho người chơi (nếu có)
                if previousEquipped and previousEquipped.Parent then
                    pcall(function()
                        previousEquipped.Parent = char
                    end)
                end
            end)
        end
    end
end)

-- 4. Auto Collect Money Loop (CHỈ gom tiền, tuyệt đối không đụng nút vứt rác)
task.spawn(function()
    while true do
        task.wait(0.5)
        local myPlot = getMyPlot()
        if AutoCollect and myPlot then
            pcall(function()
                for _, prompt in pairs(myPlot:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local act = string.lower(prompt.ActionText or "")
                        if string.find(act, "collect money") or string.find(act, "collect cash") or string.find(act, "gom tiền") then
                            triggerPrompt(prompt)
                        end
                    end
                end
            end)
        end
    end
end)

-- 5. DUAL-LAYER ANTI-AFK ENGINE
LocalPlayer.Idled:Connect(function()
    if AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end
end)

task.spawn(function()
    while true do
        task.wait(180)
        if AntiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(100, 100))
            end)
        end
    end
end)
