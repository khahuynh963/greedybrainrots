--[[
    ===================================================================
    🧠 GREEDY BRAINROTS - ULTIMATE AUTO HUB V9
    BỔ SUNG TÍNH NĂNG:
    - ➖ Nút Thu Nhỏ (Minimize) trên Thanh Tiêu Đề
    - 🧠 Nút Tròn Bấm Thu Nhỏ / Mở Nhanh Động (Floating Open/Close Icon)
    - Cho phép di chuyển (Draggable) nút mở nhanh bất cứ đâu trên màn hình
    - Bảo toàn đầy đủ tất cả tính năng Auto Plant, Auto Buy, Auto Trash, Anti-AFK
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
local AutoTrash = false
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

-- 🗑️ Trash Rarities Map (Low-tier Common/Rare/Epic ON for trashing by default!)
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
local TrashDelay = 0.25

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

-- Helper to detect tool rarity
local function detectToolRarity(tool)
    if not tool or not tool:IsA("Tool") then return "Unknown" end
    
    local attr = tool:GetAttribute("Rarity") or tool:GetAttribute("Tier")
    if attr then return tostring(attr) end
    
    local rVal = tool:FindFirstChild("Rarity") or tool:FindFirstChild("Tier")
    if rVal and rVal:IsA("StringValue") then return rVal.Value end

    local tName = string.lower(tool.Name)
    for _, r in ipairs(ALL_RARITIES) do
        if r ~= "Unknown" and string.find(tName, string.lower(r)) then
            return r
        end
    end

    if string.find(tName, "ungrown") then
        return "Common"
    end

    return "Unknown"
end

-- ── GUI Creation ──
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GreedyBrainrotsGui"
ScreenGui.ResetOnSpawn = false

pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- 🧠 Floating Toggle Icon Button (For Mini / Restore)
local ToggleIcon = Instance.new("TextButton")
ToggleIcon.Name = "ToggleIcon"
ToggleIcon.Size = UDim2.new(0, 50, 0, 50)
ToggleIcon.Position = UDim2.new(0, 15, 0.4, 0)
ToggleIcon.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
ToggleIcon.Text = "🧠"
ToggleIcon.TextSize = 24
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
MainFrame.Size = UDim2.new(0, 330, 0, 480)
MainFrame.Position = UDim2.new(0.5, -165, 0.35, -240)
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

-- Connect Floating Icon to Toggle MainFrame
ToggleIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

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
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🧠 GREEDY BRAINROTS HUB V9"
Title.TextColor3 = Color3.fromRGB(0, 255, 170)
Title.TextSize = 13
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- ➖ Minimize Button
local MiniBtn = Instance.new("TextButton")
MiniBtn.Size = UDim2.new(0, 26, 0, 26)
MiniBtn.Position = UDim2.new(1, -62, 0, 7)
MiniBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 85)
MiniBtn.Text = "➖"
MiniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniBtn.Font = Enum.Font.SourceSansBold
MiniBtn.TextSize = 11
MiniBtn.Parent = Header

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(0, 6)
MiniCorner.Parent = MiniBtn

MiniBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- ❌ Close Button
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
Scroll.CanvasSize = UDim2.new(0, 0, 0, 560)
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

-- 4. Open Buy Rarities Modal Button
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

-- 5. Open Buy Forms Modal Button
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

-- 6. Filter Mode Toggle Button
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

-- 7. Auto Trash Button (Vứt Rác Theo Lọc)
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

-- 8. Open Trash Rarities Modal Button
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

-- 9. Auto Collect Button
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

-- 10. Auto Sell Button
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

-- 11. Anti-AFK Button
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

-- ═══════════════════════════════════════════════════════════
-- CORE AUTOMATION LOOPS
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

                                -- 1. Check Attributes
                                local attrRarity = model:GetAttribute("Rarity") or searchContainer:GetAttribute("Rarity")
                                local attrForm = model:GetAttribute("Form") or searchContainer:GetAttribute("Form")
                                
                                if attrRarity then detectedRarity = tostring(attrRarity) end
                                if attrForm then detectedForm = tostring(attrForm) end

                                -- 2. Scan TextLabels in BillboardGui / SurfaceGui / Model
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

-- 3. Auto Trash Loop (Vứt rác hạt giống chưa phát triển theo lọc Độ Hiếm)
task.spawn(function()
    while true do
        task.wait(TrashDelay)
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
                    local targetRarity = "Common"

                    if char then
                        local equipped = char:FindFirstChildOfClass("Tool")
                        if equipped and string.find(equipped.Name, "Ungrown") then
                            local r = detectToolRarity(equipped)
                            if TrashRarities[r] == true then
                                targetTool = equipped
                                targetRarity = r
                            end
                        end
                    end

                    if not targetTool and bp then
                        for _, tool in pairs(bp:GetChildren()) do
                            if tool:IsA("Tool") and string.find(tool.Name, "Ungrown") then
                                local r = detectToolRarity(tool)
                                if TrashRarities[r] == true then
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
                for _, prompt in pairs(workspace:GetDescendants()) do
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

setStatus("Đã khởi tạo V9 - Hỗ trợ Nút Thu Nhỏ Đóng/Mở Nhanh!")
