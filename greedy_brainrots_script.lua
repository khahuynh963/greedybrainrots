--[[
    ===================================================================
    🧠 GREEDY BRAINROTS - ULTIMATE AUTO HUB V7 (CHUẨN BỘ LỌC ĐỘ HIẾM)
    - Sửa lỗi lọc: Mặc định TẮT các độ hiếm thấp (Common, Rare, Epic, Legendary)
    - Chỉ mua đúng Độ Hiếm được TÍCH CHỌN trong bảng "Chọn Độ Hiếm (Buy Rarities)"
    - Nhận diện chuẩn xác TextLabel chứa độ hiếm trên đầu thuyền
    - Nếu không nhận diện được độ hiếm, chỉ mua khi người dùng bật "Unknown"
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
local LocalPlayer = Players.LocalPlayer

-- ── State Variables ──
local AutoPlant = false
local AutoBuy = false
local AutoBuyAll = false
local AutoCollect = false
local AutoSell = false
local AntiAFK = false

local ALL_RARITIES = {
    "Common", "Rare", "Epic", "Legendary", "Mythical", 
    "Godly", "Secret", "Divine", "OG", "Celestial", 
    "Eternal", "Forbidden", "Unknown"
}

local ALL_FORMS = {
    "Normal", "Gold", "Diamond", "Galaxy", "Shadow", "Electrified", 
    "Starfall", "Rainbow", "Hacker", "Lava", "Cooked"
}

-- High-tier rarities enabled by default, LOW-tier (Common, Rare, Epic, Legendary, Unknown) OFF by default!
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

-- All Forms enabled by default
local SelectedForms = {}
for _, f in ipairs(ALL_FORMS) do SelectedForms[f] = true end

-- Default Filter Mode: RARITY_ONLY
local FilterMode = "RARITY_ONLY" 

local PlantDelay = 0.2
local BuyDelay = 0.15

-- Helper function to make ProximityPrompt instant and infinite range
local function optimizePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    pcall(function()
        prompt.MaxActivationDistance = 999999
        prompt.RequiresLineOfSight = false
        prompt.HoldDuration = 0
    end)
end

-- Helper function to trigger ProximityPrompt with maximum compatibility on Delta
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

-- ── GUI Creation ──
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GreedyBrainrotsGui"
ScreenGui.ResetOnSpawn = false

pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 330, 0, 440)
MainFrame.Position = UDim2.new(0.5, -165, 0.35, -220)
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

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 14)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🧠 GREEDY BRAINROTS HUB V7"
Title.TextColor3 = Color3.fromRGB(0, 255, 170)
Title.TextSize = 14
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -32, 0, 7)
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

-- Content Scroll
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -85)
Scroll.Position = UDim2.new(0, 8, 0, 46)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 4
Scroll.CanvasSize = UDim2.new(0, 0, 0, 480)
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

-- 1. Auto Plant Button
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

-- 2. Auto Buy Button (Theo Lọc)
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

-- 3. Auto Buy ALL Button (Mua tất cả không cần lọc)
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

-- 4. Open Rarities Modal Button
local btnRarities = Instance.new("TextButton")
btnRarities.Size = UDim2.new(1, 0, 0, 34)
btnRarities.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
btnRarities.Text = "🎯 Chọn Độ Hiếm (Buy Rarities)..."
btnRarities.TextColor3 = Color3.fromRGB(255, 200, 100)
btnRarities.Font = Enum.Font.SourceSansBold
btnRarities.TextSize = 13
btnRarities.Parent = Scroll
local rCorner = Instance.new("UICorner")
rCorner.CornerRadius = UDim.new(0, 8)
rCorner.Parent = btnRarities

-- 5. Open Forms Modal Button
local btnForms = Instance.new("TextButton")
btnForms.Size = UDim2.new(1, 0, 0, 34)
btnForms.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
btnForms.Text = "⚡ Chọn Dòng Form (Buy Forms)..."
btnForms.TextColor3 = Color3.fromRGB(180, 120, 255)
btnForms.Font = Enum.Font.SourceSansBold
btnForms.TextSize = 13
btnForms.Parent = Scroll
local fCorner = Instance.new("UICorner")
fCorner.CornerRadius = UDim.new(0, 8)
fCorner.Parent = btnForms

-- 6. Filter Mode Toggle Button
local btnMode = Instance.new("TextButton")
btnMode.Size = UDim2.new(1, 0, 0, 34)
btnMode.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
btnMode.Text = "🔀 Chế Độ Lọc: [ Chỉ Độ Hiếm ]"
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
        btnMode.Text = "🔀 Chế Độ Lọc: [ Chỉ Dòng Form ]"
        btnMode.TextColor3 = Color3.fromRGB(180, 120, 255)
    elseif FilterMode == "FORM_ONLY" then
        FilterMode = "BOTH"
        btnMode.Text = "🔀 Chế Độ Lọc: [ CẢ HAI (Rarity + Form) ]"
        btnMode.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        FilterMode = "RARITY_ONLY"
        btnMode.Text = "🔀 Chế Độ Lọc: [ Chỉ Độ Hiếm ]"
        btnMode.TextColor3 = Color3.fromRGB(255, 200, 100)
    end
end)

-- 7. Auto Collect Button
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

-- 8. Auto Sell Button
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

-- 9. Anti-AFK Button
createToggleButton("🛡️ Anti-AFK (Chống Văng): OFF", Color3.fromRGB(0, 200, 255), function(btn, stroke)
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
-- MODAL MAKER UTIL FOR RARITIES & FORMS
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

local raritiesModal = createSelectionModal("🎯 Chọn Độ Hiếm (Buy Rarities)", ALL_RARITIES, SelectedRarities)
local formsModal = createSelectionModal("⚡ Chọn Dòng Form (Buy Forms)", ALL_FORMS, SelectedForms)

btnRarities.MouseButton1Click:Connect(function() raritiesModal.Visible = not raritiesModal.Visible end)
btnForms.MouseButton1Click:Connect(function() formsModal.Visible = not formsModal.Visible end)

-- ═══════════════════════════════════════════════════════════
-- CORE AUTOMATION LOOPS (Precision Filter System)
-- ═══════════════════════════════════════════════════════════

-- 1. Auto Plant Loop (Equip Ungrown + Trigger Plant Prompt)
task.spawn(function()
    while true do
        task.wait(PlantDelay)
        if AutoPlant then
            pcall(function()
                setStatus("Đang Auto Plant (Trồng)...")
                local char = LocalPlayer.Character
                local bp = LocalPlayer:FindFirstChild("Backpack")
                
                -- Equip Ungrown Tool from Backpack
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

                -- Trigger Plant ProximityPrompt on GrowPads
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and (prompt.ActionText == "Plant" or prompt.ObjectText == "Grow Pad") then
                        triggerPrompt(prompt)
                    end
                end
            end)
        end
    end
end)

-- 2. Auto Buy Loop (Strict Filter Detection)
task.spawn(function()
    while true do
        task.wait(BuyDelay)
        if AutoBuy or AutoBuyAll then
            pcall(function()
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and (prompt.ActionText == "Buy" or (prompt.Parent and prompt.Parent.Name == "ConveyorBrainrot")) then
                        
                        -- Mode: Auto Buy ALL (Instant Buy without filter)
                        if AutoBuyAll then
                            setStatus("⚡ Mua Tất Cả (Auto Buy ALL)...")
                            triggerPrompt(prompt)
                        
                        -- Mode: Auto Buy (Strict Filter)
                        elseif AutoBuy then
                            local model = prompt.Parent
                            local detectedRarity = nil
                            local detectedForm = "Normal"

                            if model then
                                local searchContainer = model.Parent or model

                                -- 1. Check Attributes on model and parent
                                local attrRarity = model:GetAttribute("Rarity") or searchContainer:GetAttribute("Rarity")
                                local attrForm = model:GetAttribute("Form") or searchContainer:GetAttribute("Form")
                                
                                if attrRarity then detectedRarity = tostring(attrRarity) end
                                if attrForm then detectedForm = tostring(attrForm) end

                                -- 2. Scan TextLabels in BillboardGui / SurfaceGui / Model
                                for _, desc in pairs(searchContainer:GetDescendants()) do
                                    if desc:IsA("TextLabel") and desc.Text ~= "" then
                                        local txt = string.lower(desc.Text)
                                        -- Match Rarity exact words
                                        for _, rName in ipairs(ALL_RARITIES) do
                                            if rName ~= "Unknown" then
                                                if string.find(txt, string.lower(rName)) then
                                                    detectedRarity = rName
                                                end
                                            end
                                        end
                                        -- Match Form exact words
                                        for _, fName in ipairs(ALL_FORMS) do
                                            if fName ~= "Normal" then
                                                if string.find(txt, string.lower(fName)) then
                                                    detectedForm = fName
                                                end
                                            end
                                        end
                                    end
                                end

                                -- 3. Fallback: Search Model Name
                                if not detectedRarity then
                                    local fullN = string.lower(model:GetFullName())
                                    for _, rName in ipairs(ALL_RARITIES) do
                                        if rName ~= "Unknown" and string.find(fullN, string.lower(rName)) then
                                            detectedRarity = rName
                                        end
                                    end
                                end
                            end

                            -- Final fallback: If still undetected, assign "Unknown"
                            local finalRarity = detectedRarity or "Unknown"
                            local finalForm = detectedForm or "Normal"

                            -- Check match against User Selection
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

-- 3. Auto Sell & Collect Loop
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
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and (prompt.ActionText == "Claim" or prompt.ActionText == "Collect") then
                        triggerPrompt(prompt)
                    end
                end
            end)
        end
    end
end)

-- 4. Anti-AFK Protection
LocalPlayer.Idled:Connect(function()
    if AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end
end)

setStatus("Đã cập nhật V7 chuẩn lọc Độ Hiếm!")
