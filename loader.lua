--[[
    ===================================================================
    🧠 GREEDY BRAINROTS - UNIVERSAL MULTI-METHOD HUB (DELTA EXECUTOR)
    - Auto Plant: Tự động cầm Ungrown items trong balo & trồng vào Plot
    - Auto Buy: Quét BillboardGui & TextLabel trên sông (River/Waterfall)
    - Mặc định: BẬT TẤT CẢ ĐỘ HIẾM để bấm MUA là mua ngay lập tức!
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

-- ── Color Palette ──
local BG_DARK = Color3.fromRGB(18, 18, 26)
local CARD_BG = Color3.fromRGB(28, 28, 40)
local ACCENT_GREEN = Color3.fromRGB(0, 255, 170)
local ACCENT_BLUE = Color3.fromRGB(0, 150, 255)
local ACCENT_PURPLE = Color3.fromRGB(130, 80, 240)
local TEXT_WHITE = Color3.fromRGB(240, 240, 250)
local TEXT_MUTED = Color3.fromRGB(160, 160, 180)
local BTN_OFF = Color3.fromRGB(40, 40, 56)
local BTN_ON = Color3.fromRGB(0, 180, 100)

-- ── Data State ──
local AutoPlant = false
local AutoCollect = false
local AutoSell = false
local AutoBuy = false

-- Match Mode: "OR" (Thỏa mãn Rarity HOẶC Form), "AND" (Cả 2), "RARITY_ONLY", "FORM_ONLY"
local BuyMatchMode = "OR"

local RaritiesList = {
    "Common", "Rare",
    "Epic", "Legendary",
    "Mythical", "Godly",
    "Secret", "Divine",
    "OG", "Celestial",
    "Eternal", "Forbidden",
    "Unknown"
}

local FormsList = {
    "Normal", "Gold",
    "Diamond", "Galaxy",
    "Lava", "Radioactive",
    "Electrified", "Shadow",
    "Rainbow", "Hacker",
    "Angelic", "Corrupted",
    "Starfall", "Cosmic"
}

-- MẶC ĐỊNH: Bật TẤT CẢ các độ hiếm để bấm Auto Buy là tự mua được ngay!
local SelectedRarities = {}
for _, r in ipairs(RaritiesList) do 
    SelectedRarities[r] = true 
end

local SelectedForms = {}
for _, f in ipairs(FormsList) do SelectedForms[f] = false end
SelectedForms["Normal"] = true

-- ═══════════════════════════════════════════════════════════════════
-- 📱 MAIN HUB WINDOW
-- ═══════════════════════════════════════════════════════════════════

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 330, 0, 510)
MainFrame.Position = UDim2.new(0.5, -165, 0.4, -255)
MainFrame.BackgroundColor3 = BG_DARK
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = ACCENT_GREEN
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = CARD_BG
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleBarCorner = Instance.new("UICorner")
TitleBarCorner.CornerRadius = UDim.new(0, 12)
TitleBarCorner.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0.8, 0, 1, 0)
TitleText.Position = UDim2.new(0.04, 0, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "🧠 GREEDY BRAINROTS PRO (DELTA)"
TitleText.TextColor3 = ACCENT_GREEN
TitleText.TextSize = 13
TitleText.Font = Enum.Font.SourceSansBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 8)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = TEXT_WHITE
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 14
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Main Scroll Container
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -85)
Scroll.Position = UDim2.new(0, 10, 0, 50)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = ACCENT_GREEN
Scroll.CanvasSize = UDim2.new(0, 0, 0, 430)
Scroll.Parent = MainFrame

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 25)
StatusLabel.Position = UDim2.new(0, 10, 1, -30)
StatusLabel.BackgroundColor3 = CARD_BG
StatusLabel.Text = "Trạng thái: Sẵn sàng"
StatusLabel.TextColor3 = ACCENT_GREEN
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.Parent = MainFrame

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 6)
StatusCorner.Parent = StatusLabel

local function logStatus(msg)
    StatusLabel.Text = "Trạng thái: " .. msg
end

-- Helper function to create Toggle Button
local function createToggle(parent, text, posY, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.Position = UDim2.new(0, 0, 0, posY)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local state = defaultState
    local function updateVisual()
        if state then
            btn.BackgroundColor3 = BTN_ON
            btn.Text = text .. ": [ BẬT - ON ]"
            btn.TextColor3 = TEXT_WHITE
        else
            btn.BackgroundColor3 = BTN_OFF
            btn.Text = text .. ": [ TẮT - OFF ]"
            btn.TextColor3 = TEXT_MUTED
        end
    end
    updateVisual()

    btn.MouseButton1Click:Connect(function()
        state = not state
        updateVisual()
        callback(state)
    end)
    return btn
end

-- Toggles
createToggle(Scroll, "🌱 Auto Plant (Trồng)", 0, false, function(v) AutoPlant = v end)
createToggle(Scroll, "💵 Auto Collect (Nhặt)", 48, false, function(v) AutoCollect = v end)
createToggle(Scroll, "💰 Auto Sell (Bán hết)", 96, false, function(v) AutoSell = v end)
createToggle(Scroll, "🛒 Auto Buy (Tự Động Mua)", 144, false, function(v) AutoBuy = v end)

-- Mode Button
local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(1, 0, 0, 42)
ModeBtn.Position = UDim2.new(0, 0, 0, 192)
ModeBtn.BackgroundColor3 = Color3.fromRGB(60, 45, 100)
ModeBtn.TextColor3 = TEXT_WHITE
ModeBtn.Font = Enum.Font.SourceSansBold
ModeBtn.TextSize = 13
ModeBtn.Parent = Scroll

local ModeCorner = Instance.new("UICorner")
ModeCorner.CornerRadius = UDim.new(0, 8)
ModeCorner.Parent = ModeBtn

local function updateModeText()
    if BuyMatchMode == "OR" then
        ModeBtn.Text = "⚙️ Đặt Lọc: [ HOẶC ] (Rarity HOẶC Form)"
    elseif BuyMatchMode == "AND" then
        ModeBtn.Text = "⚙️ Đặt Lọc: [ CẢ HAI ] (Độ Hiếm VÀ Form)"
    elseif BuyMatchMode == "RARITY_ONLY" then
        ModeBtn.Text = "⚙️ Đặt Lọc: [ Chỉ Độ Hiếm ]"
    else
        ModeBtn.Text = "⚙️ Đặt Lọc: [ Chỉ Dòng Form ]"
    end
end
updateModeText()

ModeBtn.MouseButton1Click:Connect(function()
    if BuyMatchMode == "OR" then BuyMatchMode = "AND"
    elseif BuyMatchMode == "AND" then BuyMatchMode = "RARITY_ONLY"
    elseif BuyMatchMode == "RARITY_ONLY" then BuyMatchMode = "FORM_ONLY"
    else BuyMatchMode = "OR" end
    updateModeText()
end)

-- Button: Open Buy Rarities Modal
local OpenRaritiesBtn = Instance.new("TextButton")
OpenRaritiesBtn.Size = UDim2.new(1, 0, 0, 42)
OpenRaritiesBtn.Position = UDim2.new(0, 0, 0, 240)
OpenRaritiesBtn.BackgroundColor3 = ACCENT_PURPLE
OpenRaritiesBtn.Text = "🎯 Buy Rarities (Chọn Độ Hiếm ➔)"
OpenRaritiesBtn.TextColor3 = TEXT_WHITE
OpenRaritiesBtn.Font = Enum.Font.SourceSansBold
OpenRaritiesBtn.TextSize = 14
OpenRaritiesBtn.Parent = Scroll

local OpenRaritiesCorner = Instance.new("UICorner")
OpenRaritiesCorner.CornerRadius = UDim.new(0, 8)
OpenRaritiesCorner.Parent = OpenRaritiesBtn

-- Button: Open Buy Forms Modal
local OpenFormsBtn = Instance.new("TextButton")
OpenFormsBtn.Size = UDim2.new(1, 0, 0, 42)
OpenFormsBtn.Position = UDim2.new(0, 0, 0, 288)
OpenFormsBtn.BackgroundColor3 = ACCENT_BLUE
OpenFormsBtn.Text = "✨ Buy Forms (Chọn Dòng Form ➔)"
OpenFormsBtn.TextColor3 = TEXT_WHITE
OpenFormsBtn.Font = Enum.Font.SourceSansBold
OpenFormsBtn.TextSize = 14
OpenFormsBtn.Parent = Scroll

local OpenFormsCorner = Instance.new("UICorner")
OpenFormsCorner.CornerRadius = UDim.new(0, 8)
OpenFormsCorner.Parent = OpenFormsBtn

-- Anti AFK Button
local AntiAFKBtn = Instance.new("TextButton")
AntiAFKBtn.Size = UDim2.new(1, 0, 0, 42)
AntiAFKBtn.Position = UDim2.new(0, 0, 0, 336)
AntiAFKBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 220)
AntiAFKBtn.Text = "⚡ Kích Hoạt Anti-AFK (Treo Đêm)"
AntiAFKBtn.TextColor3 = TEXT_WHITE
AntiAFKBtn.Font = Enum.Font.SourceSansBold
AntiAFKBtn.TextSize = 14
AntiAFKBtn.Parent = Scroll

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
    AntiAFKBtn.Text = "✅ Đã Bật Anti-AFK Thành Công!"
    AntiAFKBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 80)
end)

-- ═══════════════════════════════════════════════════════════════════
-- 📊 SUB-MODALS (Rarities & Forms)
-- ═══════════════════════════════════════════════════════════════════

local RaritiesModal = Instance.new("Frame")
RaritiesModal.Name = "RaritiesModal"
RaritiesModal.Size = UDim2.new(0, 340, 0, 440)
RaritiesModal.Position = UDim2.new(0.5, -170, 0.4, -220)
RaritiesModal.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
RaritiesModal.BorderSizePixel = 0
RaritiesModal.Visible = false
RaritiesModal.Active = true
RaritiesModal.Draggable = true
RaritiesModal.Parent = ScreenGui

local RModalCorner = Instance.new("UICorner")
RModalCorner.CornerRadius = UDim.new(0, 12)
RModalCorner.Parent = RaritiesModal

local RModalStroke = Instance.new("UIStroke")
RModalStroke.Color = ACCENT_PURPLE
RModalStroke.Thickness = 1.5
RModalStroke.Parent = RaritiesModal

local RTitle = Instance.new("TextLabel")
RTitle.Size = UDim2.new(1, -40, 0, 45)
RTitle.Position = UDim2.new(0, 15, 0, 0)
RTitle.BackgroundTransparency = 1
RTitle.Text = "Buy Rarities"
RTitle.TextColor3 = TEXT_WHITE
RTitle.TextSize = 16
RTitle.Font = Enum.Font.SourceSansBold
RTitle.TextXAlignment = Enum.TextXAlignment.Left
RTitle.Parent = RaritiesModal

local RClose = Instance.new("TextButton")
RClose.Size = UDim2.new(0, 28, 0, 28)
RClose.Position = UDim2.new(1, -34, 0, 8)
RClose.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
RClose.Text = "✕"
RClose.TextColor3 = TEXT_WHITE
RClose.Font = Enum.Font.SourceSansBold
RClose.TextSize = 14
RClose.Parent = RaritiesModal

local RCloseCorner = Instance.new("UICorner")
RCloseCorner.CornerRadius = UDim.new(0, 6)
RCloseCorner.Parent = RClose

RClose.MouseButton1Click:Connect(function() RaritiesModal.Visible = false end)

local RSelectAllBtn = Instance.new("TextButton")
RSelectAllBtn.Size = UDim2.new(0.45, 0, 0, 32)
RSelectAllBtn.Position = UDim2.new(0.04, 0, 0, 45)
RSelectAllBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
RSelectAllBtn.Text = "Select All"
RSelectAllBtn.TextColor3 = ACCENT_GREEN
RSelectAllBtn.Font = Enum.Font.SourceSansBold
RSelectAllBtn.TextSize = 13
RSelectAllBtn.Parent = RaritiesModal

local RSelectCorner = Instance.new("UICorner")
RSelectCorner.CornerRadius = UDim.new(0, 6)
RSelectCorner.Parent = RSelectAllBtn

local RDeselectAllBtn = Instance.new("TextButton")
RDeselectAllBtn.Size = UDim2.new(0.45, 0, 0, 32)
RDeselectAllBtn.Position = UDim2.new(0.51, 0, 0, 45)
RDeselectAllBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
RDeselectAllBtn.Text = "Deselect All"
RDeselectAllBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
RDeselectAllBtn.Font = Enum.Font.SourceSansBold
RDeselectAllBtn.TextSize = 13
RDeselectAllBtn.Parent = RaritiesModal

local RDeselectCorner = Instance.new("UICorner")
RDeselectCorner.CornerRadius = UDim.new(0, 6)
RDeselectCorner.Parent = RDeselectAllBtn

local RScroll = Instance.new("ScrollingFrame")
RScroll.Size = UDim2.new(1, -20, 1, -90)
RScroll.Position = UDim2.new(0, 10, 0, 85)
RScroll.BackgroundTransparency = 1
RScroll.BorderSizePixel = 0
RScroll.ScrollBarThickness = 4
RScroll.ScrollBarImageColor3 = ACCENT_PURPLE
RScroll.CanvasSize = UDim2.new(0, 0, 0, 320)
RScroll.Parent = RaritiesModal

local RarityButtonsMap = {}
local function createRarityGrid()
    for _, btn in pairs(RarityButtonsMap) do btn:Destroy() end
    RarityButtonsMap = {}

    for idx, rName in ipairs(RaritiesList) do
        local col = (idx - 1) % 2
        local row = math.floor((idx - 1) / 2)

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.47, 0, 0, 38)
        btn.Position = UDim2.new(col * 0.52, 0, 0, row * 44)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 13
        btn.Parent = RScroll

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn

        local function updateBtnVisual()
            if SelectedRarities[rName] then
                btn.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
                btn.Text = "✓ " .. rName
                btn.TextColor3 = TEXT_WHITE
            else
                btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
                btn.Text = "  " .. rName
                btn.TextColor3 = TEXT_MUTED
            end
        end
        updateBtnVisual()

        btn.MouseButton1Click:Connect(function()
            SelectedRarities[rName] = not SelectedRarities[rName]
            updateBtnVisual()
        end)
        RarityButtonsMap[rName] = btn
    end
end
createRarityGrid()

RSelectAllBtn.MouseButton1Click:Connect(function()
    for _, rName in ipairs(RaritiesList) do SelectedRarities[rName] = true end
    createRarityGrid()
end)

RDeselectAllBtn.MouseButton1Click:Connect(function()
    for _, rName in ipairs(RaritiesList) do SelectedRarities[rName] = false end
    createRarityGrid()
end)

OpenRaritiesBtn.MouseButton1Click:Connect(function()
    RaritiesModal.Visible = true
    FormsModal.Visible = false
end)

-- Forms Modal
local FormsModal = Instance.new("Frame")
FormsModal.Name = "FormsModal"
FormsModal.Size = UDim2.new(0, 340, 0, 440)
FormsModal.Position = UDim2.new(0.5, -170, 0.4, -220)
FormsModal.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
FormsModal.BorderSizePixel = 0
FormsModal.Visible = false
FormsModal.Active = true
FormsModal.Draggable = true
FormsModal.Parent = ScreenGui

local FModalCorner = Instance.new("UICorner")
FModalCorner.CornerRadius = UDim.new(0, 12)
FModalCorner.Parent = FormsModal

local FModalStroke = Instance.new("UIStroke")
FModalStroke.Color = ACCENT_BLUE
FModalStroke.Thickness = 1.5
FModalStroke.Parent = FormsModal

local FTitle = Instance.new("TextLabel")
FTitle.Size = UDim2.new(1, -40, 0, 45)
FTitle.Position = UDim2.new(0, 15, 0, 0)
FTitle.BackgroundTransparency = 1
FTitle.Text = "Buy Forms"
FTitle.TextColor3 = TEXT_WHITE
FTitle.TextSize = 16
FTitle.Font = Enum.Font.SourceSansBold
FTitle.TextXAlignment = Enum.TextXAlignment.Left
FTitle.Parent = FormsModal

local FClose = Instance.new("TextButton")
FClose.Size = UDim2.new(0, 28, 0, 28)
FClose.Position = UDim2.new(1, -34, 0, 8)
FClose.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
FClose.Text = "✕"
FClose.TextColor3 = TEXT_WHITE
FClose.Font = Enum.Font.SourceSansBold
FClose.TextSize = 14
FClose.Parent = FormsModal

local FCloseCorner = Instance.new("UICorner")
FCloseCorner.CornerRadius = UDim.new(0, 6)
FCloseCorner.Parent = FClose

FClose.MouseButton1Click:Connect(function() FormsModal.Visible = false end)

local FSelectAllBtn = Instance.new("TextButton")
FSelectAllBtn.Size = UDim2.new(0.45, 0, 0, 32)
FSelectAllBtn.Position = UDim2.new(0.04, 0, 0, 45)
FSelectAllBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
FSelectAllBtn.Text = "Select All"
FSelectAllBtn.TextColor3 = ACCENT_GREEN
FSelectAllBtn.Font = Enum.Font.SourceSansBold
FSelectAllBtn.TextSize = 13
FSelectAllBtn.Parent = FormsModal

local FSelectCorner = Instance.new("UICorner")
FSelectCorner.CornerRadius = UDim.new(0, 6)
FSelectCorner.Parent = FSelectAllBtn

local FDeselectAllBtn = Instance.new("TextButton")
FDeselectAllBtn.Size = UDim2.new(0.45, 0, 0, 32)
FDeselectAllBtn.Position = UDim2.new(0.51, 0, 0, 45)
FDeselectAllBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
FDeselectAllBtn.Text = "Deselect All"
FDeselectAllBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
FDeselectAllBtn.Font = Enum.Font.SourceSansBold
FDeselectAllBtn.TextSize = 13
FDeselectAllBtn.Parent = FormsModal

local FDeselectCorner = Instance.new("UICorner")
FDeselectCorner.CornerRadius = UDim.new(0, 6)
FDeselectCorner.Parent = FDeselectAllBtn

local FScroll = Instance.new("ScrollingFrame")
FScroll.Size = UDim2.new(1, -20, 1, -90)
FScroll.Position = UDim2.new(0, 10, 0, 85)
FScroll.BackgroundTransparency = 1
FScroll.BorderSizePixel = 0
FScroll.ScrollBarThickness = 4
FScroll.ScrollBarImageColor3 = ACCENT_BLUE
FScroll.CanvasSize = UDim2.new(0, 0, 0, 340)
FScroll.Parent = FormsModal

local FormButtonsMap = {}
local function createFormGrid()
    for _, btn in pairs(FormButtonsMap) do btn:Destroy() end
    FormButtonsMap = {}

    for idx, fName in ipairs(FormsList) do
        local col = (idx - 1) % 2
        local row = math.floor((idx - 1) / 2)

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.47, 0, 0, 38)
        btn.Position = UDim2.new(col * 0.52, 0, 0, row * 44)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 13
        btn.Parent = FScroll

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn

        local function updateBtnVisual()
            if SelectedForms[fName] then
                btn.BackgroundColor3 = Color3.fromRGB(0, 120, 220)
                btn.Text = "✓ " .. fName
                btn.TextColor3 = TEXT_WHITE
            else
                btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
                btn.Text = "  " .. fName
                btn.TextColor3 = TEXT_MUTED
            end
        end
        updateBtnVisual()

        btn.MouseButton1Click:Connect(function()
            SelectedForms[fName] = not SelectedForms[fName]
            updateBtnVisual()
        end)
        FormButtonsMap[fName] = btn
    end
end
createFormGrid()

FSelectAllBtn.MouseButton1Click:Connect(function()
    for _, fName in ipairs(FormsList) do SelectedForms[fName] = true end
    createFormGrid()
end)

FDeselectAllBtn.MouseButton1Click:Connect(function()
    for _, fName in ipairs(FormsList) do SelectedForms[fName] = false end
    createFormGrid()
end)

OpenFormsBtn.MouseButton1Click:Connect(function()
    FormsModal.Visible = true
    RaritiesModal.Visible = false
end)

-- ═══════════════════════════════════════════════════════════════════
-- 🛠️ ROBLOX INTERACTION ENGINE (GREEDY BRAINROTS SPECIFIC)
-- ═══════════════════════════════════════════════════════════════════

local function triggerPrompt(obj)
    if not obj then return false end
    local prompt = obj:IsA("ProximityPrompt") and obj or obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        pcall(function()
            if fireproximityprompt then
                fireproximityprompt(prompt)
            else
                prompt.InputHoldBegin:Fire()
                task.wait(prompt.HoldDuration or 0.1)
                prompt.InputHoldEnd:Fire()
            end
        end)
        return true
    end
    return false
end

-- Extraction of full text labels / names of item
local function getItemText(item)
    local fullText = string.lower(item.Name)

    pcall(function()
        if item:FindFirstChild("Rarity") then
            fullText = fullText .. " " .. string.lower(tostring(item.Rarity.Value))
        end
        if item:FindFirstChild("Form") then
            fullText = fullText .. " " .. string.lower(tostring(item.Form.Value))
        elseif item:FindFirstChild("Mutation") then
            fullText = fullText .. " " .. string.lower(tostring(item.Mutation.Value))
        end

        -- Check all BillboardGui text labels (e.g., "Bananita Dolphinita", "Epic", "$73.44K/s")
        for _, desc in pairs(item:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                if desc.Text and #desc.Text > 0 then
                    fullText = fullText .. " " .. string.lower(desc.Text)
                end
            elseif desc:IsA("StringValue") then
                fullText = fullText .. " " .. string.lower(tostring(desc.Value))
            end
        end
    end)

    return fullText
end

local function checkItemMatches(item)
    local fullText = getItemText(item)

    local rarityMatched = false
    for rName, isSelected in pairs(SelectedRarities) do
        if isSelected then
            if string.find(fullText, string.lower(rName)) then
                rarityMatched = true
                break
            end
        end
    end

    local formMatched = false
    for fName, isSelected in pairs(SelectedForms) do
        if isSelected then
            if string.find(fullText, string.lower(fName)) then
                formMatched = true
                break
            end
        end
    end

    if BuyMatchMode == "OR" then
        return rarityMatched or formMatched
    elseif BuyMatchMode == "AND" then
        return rarityMatched and formMatched
    elseif BuyMatchMode == "RARITY_ONLY" then
        return rarityMatched
    elseif BuyMatchMode == "FORM_ONLY" then
        return formMatched
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════════
-- 🔄 BACKGROUND LOGIC LOOPS
-- ═══════════════════════════════════════════════════════════════════

-- Loop 1: Auto Plant (Equip Ungrown Tools & Fire Prompts)
task.spawn(function()
    while task.wait(0.2) do
        if AutoPlant then
            pcall(function()
                logStatus("Đang thực hiện Auto Plant...")
                local player = game.Players.LocalPlayer
                
                -- 1. Equip any Ungrown tools in Backpack
                local backpack = player:FindFirstChild("Backpack")
                if backpack then
                    for _, tool in pairs(backpack:GetChildren()) do
                        if tool:IsA("Tool") then
                            local tName = string.lower(tool.Name)
                            if string.find(tName, "ungrown") or string.find(tName, "seed") or string.find(tName, "brainrot") then
                                if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                                    player.Character.Humanoid:EquipTool(tool)
                                    task.wait(0.05)
                                    tool:Activate()
                                    logStatus("Đã trồng tool: " .. tool.Name)
                                end
                            end
                        end
                    end
                end

                -- 2. Activate tool currently equipped
                if player.Character then
                    local equippedTool = player.Character:FindFirstChildOfClass("Tool")
                    if equippedTool then
                        equippedTool:Activate()
                    end
                end

                -- 3. Fire Prompts on Plot / Soil
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local pName = string.lower(prompt.Parent.Name .. " " .. prompt.ActionText .. " " .. prompt.ObjectText)
                        if string.find(pName, "plant") or string.find(pName, "trồng") or string.find(pName, "seed") or string.find(pName, "plot") then
                            triggerPrompt(prompt)
                        end
                    end
                end
            end)
        end
    end
end)

-- Loop 2: Auto Buy (Scanning Floating Brainrots on River & Shop Prompts)
task.spawn(function()
    while task.wait(0.2) do
        if AutoBuy then
            pcall(function()
                logStatus("Đang quét sông / shop mua...")
                local player = game.Players.LocalPlayer

                -- Scan all ProximityPrompts in workspace (river, waterfall, shop pads)
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local itemModel = prompt.Parent
                        -- Move up to top model if parent is a part inside model
                        if itemModel and itemModel.Parent and itemModel.Parent ~= workspace and itemModel.Parent:IsA("Model") then
                            itemModel = itemModel.Parent
                        end

                        if itemModel and checkItemMatches(itemModel) then
                            triggerPrompt(prompt)
                            logStatus("Đã mua: " .. itemModel.Name)
                        end
                    end
                end

                -- Direct Remote Fallback
                local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") 
                   or game:GetService("ReplicatedStorage"):FindFirstChild("Events")
                   or game:GetService("ReplicatedStorage")
                local buyEvt = remotes:FindFirstChild("Buy") or remotes:FindFirstChild("BuyBrainrot") or remotes:FindFirstChild("Purchase")
                
                local shopItems = workspace:FindFirstChild("ShopItems") or workspace:FindFirstChild("Shop")
                if shopItems and buyEvt then
                    for _, item in pairs(shopItems:GetChildren()) do
                        if checkItemMatches(item) then
                            buyEvt:FireServer(item.Name or item)
                        end
                    end
                end
            end)
        end
    end
end)

-- Loop 3: Auto Collect & Auto Sell
task.spawn(function()
    while task.wait(0.6) do
        if AutoCollect then
            pcall(function()
                logStatus("Đang gom nhặt tiền / items...")
                local player = game.Players.LocalPlayer
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("BasePart") and (string.find(string.lower(obj.Name), "coin") or string.find(string.lower(obj.Name), "drop") or string.find(string.lower(obj.Name), "collect")) then
                            if firetouchinterest then
                                firetouchinterest(player.Character.HumanoidRootPart, obj, 0)
                                task.wait(0.01)
                                firetouchinterest(player.Character.HumanoidRootPart, obj, 1)
                            else
                                obj.CFrame = player.Character.HumanoidRootPart.CFrame
                            end
                        end
                    end
                end
            end)
        end
        
        if AutoSell then
            pcall(function()
                logStatus("Đang thực hiện Auto Sell...")
                -- Trigger Sell Prompt if present
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local pName = string.lower(prompt.Parent.Name .. " " .. prompt.ActionText)
                        if string.find(pName, "sell") or string.find(pName, "bán") then
                            triggerPrompt(prompt)
                        end
                    end
                end

                -- Teleport to SELL zone if present
                local sellZone = workspace:FindFirstChild("SellZone") or workspace:FindFirstChild("Sell")
                local player = game.Players.LocalPlayer
                if sellZone and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local targetPart = sellZone:IsA("BasePart") and sellZone or sellZone:FindFirstChildWhichIsA("BasePart")
                    if targetPart then
                        player.Character.HumanoidRootPart.CFrame = targetPart.CFrame
                    end
                end

                -- Fire Sell Remotes
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

logStatus("Đã tải xong Hub! Hãy bật tính năng.")
