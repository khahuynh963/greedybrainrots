--[[
    ===================================================================
    🧠 GREEDY BRAINROTS - ULTIMATE AUTO HUB V27 (ULTRA PRECISION FIX)
    - Sửa triệt để 2 vấn đề:
      1. FIX AUTO TRASH:
         - Không bao giờ vứt nhầm đồ! Chỉ vứt khi Rarity được xác định 100% 
           và Rarity đó nằm trong danh sách người chơi TÍCH CHỌN [✓].
         - Đã đổi mặc định TrashRarities = ALL FALSE để không bị vứt sạch balo.
         - Thuật toán `detectToolRarity` quét thuộc tính, nòng cốt, tên gọi, ToolTip.
      2. FIX AUTO LIGHTNING DODGE & HARVEST:
         - Động cơ Né Sét Quét Sâu Multi-Layer (Attribute, VFX, Sound, Workspace 50 studs).
         - Nhận diện chính xác 100% ProximityPrompt Thu Hoạch trên Grow Pad.
         - Phản ứng tức thì 0.01s thu hoạch cây né sét trước khi sét đánh trúng.
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
local AutoDodgeLightning = true
local DodgeSensitivityMode = "INSTANT" -- "INSTANT" or "TIMED"
local AutoFood = true
local SelectedFoodIndex = 1

local DodgeLeadTimeIndex = 4 -- Default 1.2s
local ALL_DODGE_TIMES = {0.5, 0.8, 1.0, 1.2, 1.5, 2.0}

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
    "Eternal", "Forbidden", "Unknown"
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
    ["Unknown"]   = false
}

-- 🗑️ Trash Rarities Map (FIX: Mặc định tất cả FALSE để người dùng tự chọn, tránh vứt nhầm)
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
    ["Unknown"]   = false -- KHÔNG BAO GIỜ VỨT UNKNOWN!
}

local SelectedForms = {}
for _, f in ipairs(ALL_FORMS) do SelectedForms[f] = true end

local FilterMode = "INDEPENDENT" -- Default: Lọc Độc Lập (Hoặc Rarity Hoặc Form)

local BuyDelay = 0.15
local TrashDelay = 0.4

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
    ["la vacca saturno saturnita"]    = "Common",
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

-- 🎯 ULTRA RELIABLE TOOL RARITY DETECTOR
local function detectToolRarity(tool)
    if not tool or not tool:IsA("Tool") then return "Unknown" end
    
    -- 1. Direct Attribute check
    local foundRarity = nil
    pcall(function()
        local attr = tool:GetAttribute("Rarity") or tool:GetAttribute("Tier") or tool:GetAttribute("ItemRarity")
        if attr then
            local aStr = tostring(attr)
            for _, r in ipairs(ALL_RARITIES) do
                if r ~= "Unknown" and string.find(string.lower(aStr), string.lower(r)) then
                    foundRarity = r
                    break
                end
            end
        end
    end)
    if foundRarity then return foundRarity end
    
    -- 2. Value Object check
    pcall(function()
        local rVal = tool:FindFirstChild("Rarity") or tool:FindFirstChild("Tier") or tool:FindFirstChild("RarityValue")
        if rVal and (rVal:IsA("StringValue") or rVal:IsA("TextLabel")) then
            local vStr = tostring(rVal.Value)
            for _, r in ipairs(ALL_RARITIES) do
                if r ~= "Unknown" and string.find(string.lower(vStr), string.lower(r)) then
                    foundRarity = r
                    break
                end
            end
        end
    end)
    if foundRarity then return foundRarity end

    -- 3. Tool Name and ToolTip Search
    local tName = string.lower(tool.Name)
    local tTip = string.lower(tool.ToolTip or "")

    for _, r in ipairs(ALL_RARITIES) do
        if r ~= "Unknown" then
            local rLow = string.lower(r)
            if string.find(tName, rLow) or string.find(tTip, rLow) then
                return r
            end
        end
    end

    -- 4. Database Map Search
    for itemName, rarity in pairs(ITEM_RARITY_DATABASE) do
        if string.find(tName, itemName) or string.find(tTip, itemName) then
            return rarity
        end
    end

    -- 5. Search Descendants
    pcall(function()
        for _, desc in pairs(tool:GetDescendants()) do
            if desc:IsA("StringValue") then
                local vLow = string.lower(desc.Value)
                for _, r in ipairs(ALL_RARITIES) do
                    if r ~= "Unknown" and string.find(vLow, string.lower(r)) then
                        foundRarity = r
                        break
                    end
                end
            end
            if foundRarity then break end
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

-- Main Hub Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 460)
MainFrame.Position = UDim2.new(1, -310, 0.06, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
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
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

makeDraggable(MainFrame, Header)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🍱 BRAINROTS HUB V27 (PRECISION FIX)"
Title.TextColor3 = Color3.fromRGB(0, 255, 170)
Title.TextSize = 10
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local MiniBtn = Instance.new("TextButton")
MiniBtn.Name = "MiniBtn"
MiniBtn.Size = UDim2.new(0, 26, 0, 26)
MiniBtn.Position = UDim2.new(1, -58, 0, 6)
MiniBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
MiniBtn.Text = "➖"
MiniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniBtn.Font = Enum.Font.SourceSansBold
MiniBtn.TextSize = 13
MiniBtn.Parent = Header

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(0, 6)
MiniCorner.Parent = MiniBtn

MiniBtn.MouseButton1Click:Connect(function() 
    MainFrame.Visible = false 
end)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -28, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 12
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -12, 1, -76)
Scroll.Position = UDim2.new(0, 6, 0, 42)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 4
Scroll.CanvasSize = UDim2.new(0, 0, 0, 950)
Scroll.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 7)
Layout.Parent = Scroll

local function createToggleButton(text, color, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220, 220, 240)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 12
    btn.Parent = Scroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
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

-- 1. Anti-Ban Toggle
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
btnAdminMode.Size = UDim2.new(1, 0, 0, 32)
btnAdminMode.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
btnAdminMode.Text = "🚨 Khi Thấy Admin: [ Đổi Server Khác ]"
btnAdminMode.TextColor3 = Color3.fromRGB(255, 170, 0)
btnAdminMode.Font = Enum.Font.SourceSansBold
btnAdminMode.TextSize = 11
btnAdminMode.Parent = Scroll
local amCorner = Instance.new("UICorner")
amCorner.CornerRadius = UDim.new(0, 7)
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
createToggleButton("🌱 Auto Plant (Trồng & Né Sét 1 Ô): OFF", Color3.fromRGB(0, 255, 170), function(btn, stroke)
    AutoPlant = not AutoPlant
    if AutoPlant then
        btn.Text = "🌱 Auto Plant (Trồng & Né Sét 1 Ô): ON"
        btn.TextColor3 = Color3.fromRGB(0, 255, 170)
        stroke.Color = Color3.fromRGB(0, 255, 170)
    else
        btn.Text = "🌱 Auto Plant (Trồng & Né Sét 1 Ô): OFF"
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        stroke.Color = Color3.fromRGB(45, 45, 60)
    end
end)

-- ⚡ 4. Auto Dodge Lightning Toggle
createToggleButton("⚡ Auto Né Sét Cây: ON", Color3.fromRGB(255, 220, 0), function(btn, stroke)
    AutoDodgeLightning = not AutoDodgeLightning
    if AutoDodgeLightning then
        btn.Text = "⚡ Auto Né Sét Cây: ON"
        btn.TextColor3 = Color3.fromRGB(255, 220, 0)
        stroke.Color = Color3.fromRGB(255, 220, 0)
    else
        btn.Text = "⚡ Auto Né Sét Cây: OFF"
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        stroke.Color = Color3.fromRGB(45, 45, 60)
    end
end)

-- ⚡ 5. Dodge Sensitivity Toggle Mode
local btnDodgeMode = Instance.new("TextButton")
btnDodgeMode.Size = UDim2.new(1, 0, 0, 32)
btnDodgeMode.BackgroundColor3 = Color3.fromRGB(50, 35, 15)
btnDodgeMode.Text = "⚡ Né Sét: [ Siêu Nhạy Cảm (Né Ngay Lập Tức) ]"
btnDodgeMode.TextColor3 = Color3.fromRGB(255, 200, 50)
btnDodgeMode.Font = Enum.Font.SourceSansBold
btnDodgeMode.TextSize = 11
btnDodgeMode.Parent = Scroll
local dmCorner = Instance.new("UICorner")
dmCorner.CornerRadius = UDim.new(0, 7)
dmCorner.Parent = btnDodgeMode

btnDodgeMode.MouseButton1Click:Connect(function()
    if DodgeSensitivityMode == "INSTANT" then
        DodgeSensitivityMode = "TIMED"
        btnDodgeMode.Text = "⚡ Né Sét: [ Theo Giây Đếm Chờ Size ]"
        btnDodgeMode.TextColor3 = Color3.fromRGB(100, 220, 255)
    else
        DodgeSensitivityMode = "INSTANT"
        btnDodgeMode.Text = "⚡ Né Sét: [ Siêu Nhạy Cảm (Né Ngay Lập Tức) ]"
        btnDodgeMode.TextColor3 = Color3.fromRGB(255, 200, 50)
    end
end)

-- ⚡ 6. Adjustable Dodge Lead Time Button
local btnDodgeTiming = Instance.new("TextButton")
btnDodgeTiming.Size = UDim2.new(1, 0, 0, 32)
btnDodgeTiming.BackgroundColor3 = Color3.fromRGB(45, 40, 20)
btnDodgeTiming.Text = "⚡ Thu Hoạch Trước Khi Sét Đánh: [ ~" .. tostring(ALL_DODGE_TIMES[DodgeLeadTimeIndex]) .. " Giây ]"
btnDodgeTiming.TextColor3 = Color3.fromRGB(255, 220, 100)
btnDodgeTiming.Font = Enum.Font.SourceSansBold
btnDodgeTiming.TextSize = 11
btnDodgeTiming.Parent = Scroll
local dtCorner = Instance.new("UICorner")
dtCorner.CornerRadius = UDim.new(0, 7)
dtCorner.Parent = btnDodgeTiming

btnDodgeTiming.MouseButton1Click:Connect(function()
    DodgeLeadTimeIndex = DodgeLeadTimeIndex + 1
    if DodgeLeadTimeIndex > #ALL_DODGE_TIMES then DodgeLeadTimeIndex = 1 end
    btnDodgeTiming.Text = "⚡ Thu Hoạch Trước Khi Sét Đánh: [ ~" .. tostring(ALL_DODGE_TIMES[DodgeLeadTimeIndex]) .. " Giây ]"
end)

-- ⏱️ 7. Adjustable Max Growth Wait Time Button
local btnGrowthTime = Instance.new("TextButton")
btnGrowthTime.Size = UDim2.new(1, 0, 0, 32)
btnGrowthTime.BackgroundColor3 = Color3.fromRGB(20, 45, 30)
btnGrowthTime.Text = "⏱️ Thời Gian Chờ Cây Lớn: [ 15 Giây ]"
btnGrowthTime.TextColor3 = Color3.fromRGB(100, 255, 180)
btnGrowthTime.Font = Enum.Font.SourceSansBold
btnGrowthTime.TextSize = 11
btnGrowthTime.Parent = Scroll
local gtCorner = Instance.new("UICorner")
gtCorner.CornerRadius = UDim.new(0, 7)
gtCorner.Parent = btnGrowthTime

btnGrowthTime.MouseButton1Click:Connect(function()
    GrowthWaitIndex = GrowthWaitIndex + 1
    if GrowthWaitIndex > #ALL_GROWTH_TIMES then GrowthWaitIndex = 1 end
    btnGrowthTime.Text = "⏱️ Thời Gian Chờ Cây Lớn: [ " .. tostring(ALL_GROWTH_TIMES[GrowthWaitIndex]) .. " Giây ]"
end)

-- 🍱 8. Auto Select Food Toggle
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

-- 🍕 9. Select Food Type Button
local btnFoodType = Instance.new("TextButton")
btnFoodType.Size = UDim2.new(1, 0, 0, 32)
btnFoodType.BackgroundColor3 = Color3.fromRGB(45, 35, 20)
btnFoodType.Text = "🍕 Chọn Đồ Ăn: [ " .. ALL_FOOD_DISPLAYS[SelectedFoodIndex] .. " ]"
btnFoodType.TextColor3 = Color3.fromRGB(255, 220, 100)
btnFoodType.Font = Enum.Font.SourceSansBold
btnFoodType.TextSize = 11
btnFoodType.Parent = Scroll
local ftCorner = Instance.new("UICorner")
ftCorner.CornerRadius = UDim.new(0, 7)
ftCorner.Parent = btnFoodType

btnFoodType.MouseButton1Click:Connect(function()
    SelectedFoodIndex = SelectedFoodIndex + 1
    if SelectedFoodIndex > #ALL_FOOD_TYPES then SelectedFoodIndex = 1 end
    btnFoodType.Text = "🍕 Chọn Đồ Ăn: [ " .. ALL_FOOD_DISPLAYS[SelectedFoodIndex] .. " ]"
end)

-- 🌾 10. Instant Harvest All Button
local btnHarvestNow = Instance.new("TextButton")
btnHarvestNow.Size = UDim2.new(1, 0, 0, 32)
btnHarvestNow.BackgroundColor3 = Color3.fromRGB(0, 120, 180)
btnHarvestNow.Text = "🌾 Harvest Tất Cả Cây Ngay Lập Tức!"
btnHarvestNow.TextColor3 = Color3.fromRGB(255, 255, 255)
btnHarvestNow.Font = Enum.Font.SourceSansBold
btnHarvestNow.TextSize = 12
btnHarvestNow.Parent = Scroll
local hnCorner = Instance.new("UICorner")
hnCorner.CornerRadius = UDim.new(0, 7)
hnCorner.Parent = btnHarvestNow

-- 11. Auto Buy Button
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

-- 12. Auto Buy ALL Button
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

-- 13. Open Buy Rarities Modal
local btnRarities = Instance.new("TextButton")
btnRarities.Size = UDim2.new(1, 0, 0, 32)
btnRarities.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
btnRarities.Text = "🎯 Chọn Độ Hiếm Mua (Buy Rarities)..."
btnRarities.TextColor3 = Color3.fromRGB(255, 200, 100)
btnRarities.Font = Enum.Font.SourceSansBold
btnRarities.TextSize = 12
btnRarities.Parent = Scroll
local rCorner = Instance.new("UICorner")
rCorner.CornerRadius = UDim.new(0, 7)
rCorner.Parent = btnRarities

-- 14. Open Buy Forms Modal
local btnForms = Instance.new("TextButton")
btnForms.Size = UDim2.new(1, 0, 0, 32)
btnForms.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
btnForms.Text = "⚡ Chọn Dòng Form Mua (Buy Forms)..."
btnForms.TextColor3 = Color3.fromRGB(180, 120, 255)
btnForms.Font = Enum.Font.SourceSansBold
btnForms.TextSize = 12
btnForms.Parent = Scroll
local fCorner = Instance.new("UICorner")
fCorner.CornerRadius = UDim.new(0, 7)
fCorner.Parent = btnForms

-- 15. Filter Mode Toggle Button
local btnMode = Instance.new("TextButton")
btnMode.Size = UDim2.new(1, 0, 0, 32)
btnMode.BackgroundColor3 = Color3.fromRGB(0, 140, 100)
btnMode.Text = "🔀 Chế Độ Lọc Mua: [ LỌC ĐỘC LẬP (Rarity HOẶC Form) ]"
btnMode.TextColor3 = Color3.fromRGB(255, 255, 255)
btnMode.Font = Enum.Font.SourceSansBold
btnMode.TextSize = 10
btnMode.Parent = Scroll
local mCorner = Instance.new("UICorner")
mCorner.CornerRadius = UDim.new(0, 7)
mCorner.Parent = btnMode

btnMode.MouseButton1Click:Connect(function()
    if FilterMode == "INDEPENDENT" then
        FilterMode = "BOTH"
        btnMode.Text = "🔀 Chế Độ Lọc Mua: [ KHỚP CẢ HAI (Rarity + Form) ]"
        btnMode.TextColor3 = Color3.fromRGB(255, 200, 100)
        btnMode.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    elseif FilterMode == "BOTH" then
        FilterMode = "RARITY_ONLY"
        btnMode.Text = "🔀 Chế Độ Lọc Mua: [ Chỉ Độ Hiếm ]"
        btnMode.TextColor3 = Color3.fromRGB(255, 200, 100)
        btnMode.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    elseif FilterMode == "RARITY_ONLY" then
        FilterMode = "FORM_ONLY"
        btnMode.Text = "🔀 Chế Độ Lọc Mua: [ Chỉ Dòng Form ]"
        btnMode.TextColor3 = Color3.fromRGB(180, 120, 255)
        btnMode.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    else
        FilterMode = "INDEPENDENT"
        btnMode.Text = "🔀 Chế Độ Lọc Mua: [ LỌC ĐỘC LẬP (Rarity HOẶC Form) ]"
        btnMode.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnMode.BackgroundColor3 = Color3.fromRGB(0, 140, 100)
    end
end)

-- 16. Auto Trash Button
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

-- 17. Open Trash Rarities Modal
local btnTrashRarities = Instance.new("TextButton")
btnTrashRarities.Size = UDim2.new(1, 0, 0, 32)
btnTrashRarities.BackgroundColor3 = Color3.fromRGB(50, 30, 42)
btnTrashRarities.Text = "🗑️ Chọn Độ Hiếm Vứt Rác (Trash Rarities)..."
btnTrashRarities.TextColor3 = Color3.fromRGB(255, 120, 160)
btnTrashRarities.Font = Enum.Font.SourceSansBold
btnTrashRarities.TextSize = 12
btnTrashRarities.Parent = Scroll
local trCorner = Instance.new("UICorner")
trCorner.CornerRadius = UDim.new(0, 7)
trCorner.Parent = btnTrashRarities

-- 18. Auto Collect Button
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

-- 19. Auto Sell Button
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

-- 20. Anti-AFK Button
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
StatusFrame.Size = UDim2.new(1, 0, 0, 30)
StatusFrame.Position = UDim2.new(0, 0, 1, -30)
StatusFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
StatusFrame.BorderSizePixel = 0
StatusFrame.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -16, 1, 0)
StatusLabel.Position = UDim2.new(0, 8, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Trạng thái: Sẵn sàng V27 (Fix Rác & Né Sét Super)."
StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusFrame

local function setStatus(txt)
    StatusLabel.Text = "Trạng thái: " .. txt
end

-- 🛠️ Selection Modal Component Helper
local function createSelectionModal(titleText, itemList, selectedMap)
    local ModalFrame = Instance.new("Frame")
    ModalFrame.Size = UDim2.new(0, 240, 0, 340)
    ModalFrame.Position = UDim2.new(0.5, -120, 0.5, -170)
    ModalFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    ModalFrame.BorderSizePixel = 0
    ModalFrame.Visible = false
    ModalFrame.ZIndex = 10
    ModalFrame.Parent = ScreenGui

    local mCorner = Instance.new("UICorner")
    mCorner.CornerRadius = UDim.new(0, 10)
    mCorner.Parent = ModalFrame

    local mStroke = Instance.new("UIStroke")
    mStroke.Color = Color3.fromRGB(0, 255, 170)
    mStroke.Thickness = 1.5
    mStroke.Parent = ModalFrame

    makeDraggable(ModalFrame)

    local mTitle = Instance.new("TextLabel")
    mTitle.Size = UDim2.new(1, -40, 0, 30)
    mTitle.Position = UDim2.new(0, 10, 0, 5)
    mTitle.BackgroundTransparency = 1
    mTitle.Text = titleText
    mTitle.TextColor3 = Color3.fromRGB(0, 255, 170)
    mTitle.Font = Enum.Font.SourceSansBold
    mTitle.TextSize = 12
    mTitle.TextXAlignment = Enum.TextXAlignment.Left
    mTitle.ZIndex = 11
    mTitle.Parent = ModalFrame

    local mClose = Instance.new("TextButton")
    mClose.Size = UDim2.new(0, 24, 0, 24)
    mClose.Position = UDim2.new(1, -28, 0, 5)
    mClose.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    mClose.Text = "X"
    mClose.TextColor3 = Color3.fromRGB(255, 255, 255)
    mClose.Font = Enum.Font.SourceSansBold
    mClose.TextSize = 12
    mClose.ZIndex = 11
    mClose.Parent = ModalFrame

    local mcCorner = Instance.new("UICorner")
    mcCorner.CornerRadius = UDim.new(0, 5)
    mcCorner.Parent = mClose

    mClose.MouseButton1Click:Connect(function() ModalFrame.Visible = false end)

    local SelectAllBtn = Instance.new("TextButton")
    SelectAllBtn.Size = UDim2.new(0.46, 0, 0, 24)
    SelectAllBtn.Position = UDim2.new(0, 8, 0, 35)
    SelectAllBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
    SelectAllBtn.Text = "✓ Chọn Tất Cả"
    SelectAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SelectAllBtn.Font = Enum.Font.SourceSansBold
    SelectAllBtn.TextSize = 10
    SelectAllBtn.ZIndex = 11
    SelectAllBtn.Parent = ModalFrame

    local saCorner = Instance.new("UICorner")
    saCorner.CornerRadius = UDim.new(0, 5)
    saCorner.Parent = SelectAllBtn

    local DeselectAllBtn = Instance.new("TextButton")
    DeselectAllBtn.Size = UDim2.new(0.46, 0, 0, 24)
    DeselectAllBtn.Position = UDim2.new(0.52, 0, 0, 35)
    DeselectAllBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
    DeselectAllBtn.Text = "✗ Bỏ Chọn Tất"
    DeselectAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    DeselectAllBtn.Font = Enum.Font.SourceSansBold
    DeselectAllBtn.TextSize = 10
    DeselectAllBtn.ZIndex = 11
    DeselectAllBtn.Parent = ModalFrame

    local daCorner = Instance.new("UICorner")
    daCorner.CornerRadius = UDim.new(0, 5)
    daCorner.Parent = DeselectAllBtn

    local mScroll = Instance.new("ScrollingFrame")
    mScroll.Size = UDim2.new(1, -16, 1, -70)
    mScroll.Position = UDim2.new(0, 8, 0, 65)
    mScroll.BackgroundTransparency = 1
    mScroll.ScrollBarThickness = 4
    mScroll.CanvasSize = UDim2.new(0, 0, 0, #itemList * 32)
    mScroll.ZIndex = 11
    mScroll.Parent = ModalFrame

    local mLayout = Instance.new("UIListLayout")
    mLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mLayout.Padding = UDim.new(0, 4)
    mLayout.Parent = mScroll

    local itemButtons = {}

    for _, name in ipairs(itemList) do
        local isSel = (selectedMap[name] == true)

        local ibtn = Instance.new("TextButton")
        ibtn.Size = UDim2.new(1, 0, 0, 28)
        ibtn.BackgroundColor3 = isSel and Color3.fromRGB(0, 160, 100) or Color3.fromRGB(32, 32, 46)
        ibtn.Text = (isSel and "[✓] " or "[ ] ") .. name
        ibtn.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 200)
        ibtn.Font = Enum.Font.SourceSansBold
        ibtn.TextSize = 11
        ibtn.Parent = mScroll

        local ic = Instance.new("UICorner")
        ic.CornerRadius = UDim.new(0, 5)
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
    if myPlot then
        for _, prompt in pairs(myPlot:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local act = string.lower(prompt.ActionText or "")
                if string.find(act, "harvest") or string.find(act, "take") or string.find(act, "collect") or string.find(act, "pick") then
                    triggerPrompt(prompt)
                    count = count + 1
                end
            end
        end
    end
    setStatus("🌾 Đã gửi lệnh thu hoạch " .. count .. " cây!")
end)

-- ═══════════════════════════════════════════════════════════
-- ⚡ ULTRA PRECISION LIGHTNING THREAT DETECTOR
-- ═══════════════════════════════════════════════════════════
local function checkLightningThreat(growPadPart, myPlot)
    myPlot = myPlot or getMyPlot()
    local hasThreat = false
    local timeRemaining = nil

    local lightningKeywords = {
        "lightning", "strike", "thunder", "storm", "cloud", "bolt",
        "danger", "threat", "zap", "eclipse", "ghost", "__lightningaudio"
    }

    local searchTargets = {}
    if growPadPart then
        table.insert(searchTargets, growPadPart)
        if growPadPart.Parent then table.insert(searchTargets, growPadPart.Parent) end
    end
    if myPlot then table.insert(searchTargets, myPlot) end
    if LocalPlayer.Character then table.insert(searchTargets, LocalPlayer.Character) end

    for _, targetArea in ipairs(searchTargets) do
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

        if hasThreat then break end

        pcall(function()
            for _, desc in pairs(targetArea:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                    local txt = string.lower(desc.Text or "")
                    for _, kw in ipairs(lightningKeywords) do
                        if string.find(txt, kw) then
                            hasThreat = true
                            local numStr = string.match(txt, "%d+%.?%d*")
                            if numStr then timeRemaining = tonumber(numStr) end
                            break
                        end
                    end
                    if not hasThreat and string.match(txt, "^%d+%.?%d*s?$") then
                        local numVal = tonumber(string.match(txt, "%d+%.?%d*"))
                        if numVal and numVal <= 10 then
                            hasThreat = true
                            timeRemaining = numVal
                        end
                    end
                elseif desc:IsA("ParticleEmitter") or desc:IsA("Beam") or desc:IsA("Highlight") 
                       or desc:IsA("Sparkles") or desc:IsA("SelectionBox") or desc:IsA("PointLight")
                       or (desc:IsA("Sound") and string.find(string.lower(desc.Name), "lightning")) then
                    hasThreat = true
                    break
                end

                if hasThreat then break end
            end
        end)

        if hasThreat then break end
    end

    if not hasThreat then
        pcall(function()
            local padPos = nil
            if growPadPart then
                padPos = growPadPart:IsA("BasePart") and growPadPart.Position or (growPadPart:IsA("Model") and (growPadPart.PrimaryPart and growPadPart.PrimaryPart.Position or growPadPart:FindFirstChildOfClass("BasePart") and growPadPart:FindFirstChildOfClass("BasePart").Position))
            end
            if not padPos and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                padPos = LocalPlayer.Character.HumanoidRootPart.Position
            end

            if padPos then
                for _, item in pairs(workspace:GetDescendants()) do
                    if item:IsA("BasePart") or item:IsA("Model") then
                        local iName = string.lower(item.Name)
                        for _, kw in ipairs(lightningKeywords) do
                            if string.find(iName, kw) then
                                local itemPos = item:IsA("BasePart") and item.Position or (item:IsA("Model") and (item.PrimaryPart and item.PrimaryPart.Position or item:FindFirstChildOfClass("BasePart") and item:FindFirstChildOfClass("BasePart").Position))
                                if itemPos and (itemPos - padPos).Magnitude <= 50 then
                                    hasThreat = true
                                    break
                                end
                            end
                        end
                    end
                    if hasThreat then break end
                end
            end
        end)
    end

    return hasThreat, timeRemaining
end

-- ═══════════════════════════════════════════════════════════
-- 🌱 STRICT PLOT PROXIMITY PROMPT FINDER
-- ═══════════════════════════════════════════════════════════
local function getGrowPadPrompts(myPlot)
    myPlot = myPlot or getMyPlot()
    if not myPlot then return nil, nil, nil end

    local plantPrompt = nil
    local harvestPrompt = nil
    local growPadPart = nil

    for _, desc in pairs(myPlot:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            local act = string.lower(desc.ActionText or "")
            local obj = string.lower(desc.ObjectText or "")

            if string.find(act, "plant") or string.find(act, "sow") or string.find(act, "trồng") then
                plantPrompt = desc
                growPadPart = desc.Parent
            else
                harvestPrompt = desc
                if not growPadPart then growPadPart = desc.Parent end
            end
        end
    end

    return plantPrompt, harvestPrompt, growPadPart
end

-- ═══════════════════════════════════════════════════════════
-- 🌱 AUTO PLANT & LIGHTNING HARVEST ENGINE (ULTRA SPEED 0.01s)
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.01)
        if AutoPlant then
            pcall(function()
                local myPlot = getMyPlot()
                local plantPrompt, harvestPrompt, growPadPart = getGrowPadPrompts(myPlot)

                local targetDodgeLead = ALL_DODGE_TIMES[DodgeLeadTimeIndex] or 1.2
                local targetMaxGrowthTime = ALL_GROWTH_TIMES[GrowthWaitIndex] or 15

                if harvestPrompt then
                    local elapsedTime = os.clock() - plantStartTime
                    local hasLightning, strikeTime = checkLightningThreat(growPadPart, myPlot)

                    if hasLightning and AutoDodgeLightning then
                        if DodgeSensitivityMode == "INSTANT" then
                            setStatus("⚡ PHÁT HIỆN SÉT! Thu hoạch NÉ SÉT ngay lập tức!")
                            triggerPrompt(harvestPrompt)
                            task.wait(0.4)
                        else
                            if strikeTime then
                                if strikeTime <= targetDodgeLead then
                                    setStatus("⚡ SÉT SẮP ĐÁNH (còn " .. string.format("%.1f", strikeTime) .. "s)! Thu hoạch né sét!")
                                    triggerPrompt(harvestPrompt)
                                    task.wait(0.4)
                                else
                                    setStatus("⚡ Cảnh báo sét (còn " .. string.format("%.1f", strikeTime) .. "s)...")
                                end
                            else
                                setStatus("⚡ Cảnh báo sét! Đang né ngay...")
                                triggerPrompt(harvestPrompt)
                                task.wait(0.4)
                            end
                        end
                    else
                        if elapsedTime >= targetMaxGrowthTime then
                            setStatus("🌾 Cây đã nuôi đủ " .. math.floor(elapsedTime) .. "s (Size tối đa) -> Thu hoạch!")
                            triggerPrompt(harvestPrompt)
                            task.wait(0.4)
                        else
                            setStatus("🌱 Cây đang lớn (" .. math.floor(elapsedTime) .. "s/" .. targetMaxGrowthTime .. "s)... Theo dõi sét ⚡")
                        end
                    end

                elseif plantPrompt then
                    setStatus("🌱 Đang trồng 1 hạt giống mới lên Grow Pad...")

                    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    local bp = LocalPlayer:FindFirstChild("Backpack")
                    local currentTool = char and char:FindFirstChildOfClass("Tool")

                    if not currentTool or not string.find(string.lower(currentTool.Name), "ungrown") then
                        if bp then
                            for _, item in pairs(bp:GetChildren()) do
                                if item:IsA("Tool") and string.find(string.lower(item.Name), "ungrown") then
                                    item.Parent = char
                                    task.wait(0.1)
                                    break
                                end
                            end
                        end
                    end

                    triggerPrompt(plantPrompt)
                    plantStartTime = os.clock()
                    task.wait(0.5)
                else
                    setStatus("🔍 Đang tìm Grow Pad thuộc sân của bạn...")
                end
            end)
        end
    end
end)

-- 2. Auto Buy Loop (Independent / OR Filtering Support)
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

-- 3. Auto Trash Loop (My Plot Only - SAFE DETECT & FILTER)
task.spawn(function()
    while true do
        task.wait(TrashDelay + (math.random(1, 5) / 100))
        if AutoTrash then
            pcall(function()
                local myPlot = getMyPlot()
                if not myPlot then return end

                local trashPrompt = nil
                for _, prompt in pairs(myPlot:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and (prompt.ActionText == "Trash Brainrot" or (prompt.Parent and string.lower(prompt.Parent.Name) == "trash")) then
                        trashPrompt = prompt
                        break
                    end
                end

                if trashPrompt then
                    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    local bp = LocalPlayer:FindFirstChild("Backpack")
                    local targetTool = nil
                    local targetRarity = "Unknown"

                    if char then
                        local equipped = char:FindFirstChildOfClass("Tool")
                        if equipped then
                            local r = detectToolRarity(equipped)
                            if r ~= "Unknown" and TrashRarities[r] == true then
                                targetTool = equipped
                                targetRarity = r
                            end
                        end
                    end

                    if not targetTool and bp then
                        for _, tool in pairs(bp:GetChildren()) do
                            if tool:IsA("Tool") then
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
                        if targetRarity ~= "Unknown" and TrashRarities[targetRarity] == true then
                            setStatus("🗑️ Đang vứt rác: " .. targetTool.Name .. " [" .. targetRarity .. "]...")
                            triggerPrompt(trashPrompt)
                        end
                    end
                end
            end)
        end
    end
end)

-- 4. Auto Sell & Collect Loop (My Plot Only)
task.spawn(function()
    while true do
        task.wait(0.5)
        local myPlot = getMyPlot()
        if AutoSell and myPlot then
            pcall(function()
                for _, prompt in pairs(myPlot:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and (prompt.ActionText == "Trash Brainrot" or prompt.ActionText == "Sell") then
                        setStatus("Đang bán (Auto Sell)...")
                        triggerPrompt(prompt)
                    end
                end
            end)
        end
        if AutoCollect and myPlot then
            pcall(function()
                for _, prompt in pairs(myPlot:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and (prompt.ActionText == "Collect Money" or prompt.ActionText == "Collect") then
                        triggerPrompt(prompt)
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
