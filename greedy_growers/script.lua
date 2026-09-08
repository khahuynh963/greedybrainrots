--[[
    ===================================================================
    🌾⚡ GREEDY GROWERS - ULTIMATE AUTO HUB V1.0
    Tự động chơi toàn diện cho tựa game Greedy Growers trên Roblox
    
    Tính năng chính:
    1. ⚡ Auto Né Sét Siêu Tốc (Căn giờ né trước 2s hoặc né ngay khi có sét)
    2. 🌱 Auto Nuôi Cây & Thu Hoạch Size Tối Đa
    3. 🌿 Auto Gieo Hạt Giống (Auto Plant & Equip Seed)
    4. 💰 Auto Collect Tiền Xu & Bán Nông Phẩm
    5. 🏃‍♂️ Tăng Tốc Độ Di Chuyển (Speed Boost, Inf Jump, Noclip)
    6. 🛡️ Anti-AFK Treo Máy 24/7 Xuyên Đêm
    ===================================================================
--]]

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ── Safe GUI Container Helper ──
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

-- Dọn dẹp GUI cũ nếu đang chạy
pcall(function()
    local c = getGuiContainer()
    if c and c:FindFirstChild("GreedyGrowersHubGui") then
        c.GreedyGrowersHubGui:Destroy()
    end
    if game:GetService("CoreGui"):FindFirstChild("GreedyGrowersHubGui") then
        game:GetService("CoreGui").GreedyGrowersHubGui:Destroy()
    end
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("GreedyGrowersHubGui") then
        LocalPlayer.PlayerGui.GreedyGrowersHubGui:Destroy()
    end
end)

-- ── Cấu hình & Biến Trạng Thái (States) ──
local AutoDodgeHarvest = false
local AutoPlantSeed = false
local AutoCollectCoins = false
local AutoSellCrops = false
local AntiAFK = true

local DodgeSensitivityMode = "TIMED" -- "TIMED" (Căn giờ) hoặc "INSTANT" (Né ngay lập tức)
local DodgeLeadTimeIndex = 4        -- Mặc định 2.0s
local ALL_DODGE_TIMES = {0.5, 0.8, 1.0, 1.5, 2.0, 2.5, 3.0}

local GrowthWaitIndex = 3           -- Mặc định 15s
local ALL_GROWTH_TIMES = {8, 10, 12, 15, 18, 20, 25, 30}

local SpeedBoostEnabled = false
local CustomWalkSpeed = 48
local InfJumpEnabled = false
local NoclipEnabled = false

local plantStartTime = 0

-- ── Hàm tối ưu ProximityPrompt ──
local function optimizePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    pcall(function()
        prompt.MaxActivationDistance = 999999
        prompt.RequiresLineOfSight = false
        prompt.HoldDuration = 0
        prompt.Enabled = true
    end)
end

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
        task.wait(0.02)
        prompt:InputHoldEnd()
    end)
end

-- ── Xác định Plot của người chơi ──
local cachedMyPlot = nil
local function getMyPlot()
    if cachedMyPlot and cachedMyPlot.Parent then return cachedMyPlot end

    local myIdStr = tostring(LocalPlayer.UserId)
    local pName = string.lower(LocalPlayer.Name)
    local pDisp = string.lower(LocalPlayer.DisplayName)

    -- 1. Tìm theo tên Plot_<UserId>
    pcall(function()
        local plotsFolder = workspace:FindFirstChild("Plots") or workspace:FindFirstChild("Farms") or workspace
        for _, child in pairs(plotsFolder:GetDescendants()) do
            if child:IsA("Model") or child:IsA("Folder") then
                local cLow = string.lower(child.Name)
                if string.find(cLow, myIdStr) or string.find(cLow, pName) or string.find(cLow, pDisp) then
                    cachedMyPlot = child
                    return child
                end
            end
        end
    end)

    return cachedMyPlot
end

-- ── Tìm nút Gieo Hạt & Thu Hoạch trên Bệ Trồng (Grow Pad) ──
local function getFarmPrompts()
    local myPlot = getMyPlot()
    local plantPrompt = nil
    local harvestPrompt = nil
    local growPadPart = nil

    local excludeKeywords = {
        "place", "placement", "đặt", "trash", "bin", "dump", "sell", "buy", "purchase", "mua", 
        "collect money", "collect cash", "collect coin", "gom tiền", "store", "shop", "vendor",
        "like", "reward", "group", "gift", "daily", "spin", "wheel", "chest"
    }

    local candidatePrompts = {}

    -- Quét trong sân Plot
    if myPlot then
        for _, desc in pairs(myPlot:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                table.insert(candidatePrompts, desc)
            end
        end
    end

    -- Quét quanh nhân vật trong bán kính 25 studs (bệ đất ngay dưới chân)
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
        local pName = desc.Parent and string.lower(desc.Parent.Name) or ""

        local isExcluded = false
        for _, kw in ipairs(excludeKeywords) do
            if string.find(act, kw) or string.find(obj, kw) or string.find(pName, kw) then
                isExcluded = true
                break
            end
        end

        if not isExcluded then
            -- Nút Trồng cây (Plant)
            if string.find(act, "plant") or string.find(act, "sow") or string.find(act, "trồng") or string.find(obj, "plant") then
                if not plantPrompt then
                    plantPrompt = desc
                    growPadPart = desc.Parent
                end
            -- Nút Thu hoạch cây (Collect, Harvest, Pick, Take, Pull, Claim)
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

-- ── Bộ Phát Hiện Hiểm Họa Sấm Sét (Lightning Threat Deep Scan) ──
local function detectLightningThreat(growPadPart)
    local hasThreat = false
    local timeRemaining = nil

    local lightningKeywords = {
        "lightning", "strike", "thunder", "storm", "cloud", "bolt",
        "danger", "threat", "zap", "eclipse", "ghost", "__lightningaudio", "electric"
    }

    -- 1. Kiểm tra đối tượng âm thanh hoặc thời tiết sấm sét toàn cục
    pcall(function()
        if workspace:FindFirstChild("__LightningAudio") 
           or workspace:FindFirstChild("GreedyGrowersEclipse") 
           or workspace:FindFirstChild("LightningStorm")
           or workspace:FindFirstChild("StormCloud") then
            hasThreat = true
        end
    end)
    if hasThreat then return true, timeRemaining end

    -- 2. Quét vùng bệ đất & nhân vật
    local searchTargets = {}
    if growPadPart then
        table.insert(searchTargets, growPadPart)
        if growPadPart.Parent then table.insert(searchTargets, growPadPart.Parent) end
    end
    if cachedMyPlot then table.insert(searchTargets, cachedMyPlot) end
    if LocalPlayer.Character then table.insert(searchTargets, LocalPlayer.Character) end

    for _, targetArea in ipairs(searchTargets) do
        -- Kiểm tra Attributes
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

        -- Kiểm tra Chữ hiển thị & Đếm ngược giây
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
                       or desc:IsA("Sparkles") or desc:IsA("PointLight")
                       or (desc:IsA("Sound") and string.find(string.lower(desc.Name), "lightning")) then
                    hasThreat = true
                    break
                end
                if hasThreat then break end
            end
        end)
        if hasThreat then break end
    end

    -- 3. Quét vật thể sét rơi trong bán kính 50 studs quanh bệ đất
    if not hasThreat then
        pcall(function()
            local padPos = nil
            if growPadPart then
                padPos = growPadPart:IsA("BasePart") and growPadPart.Position 
                         or (growPadPart:IsA("Model") and growPadPart.PrimaryPart and growPadPart.PrimaryPart.Position)
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
                                local itemPos = item:IsA("BasePart") and item.Position 
                                                or (item:IsA("Model") and item.PrimaryPart and item.PrimaryPart.Position)
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
-- 🎨 GIAO DIỆN ĐIỀU KHIỂN (GREEDY GROWERS HUB UI)
-- ═══════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GreedyGrowersHubGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local targetContainer = getGuiContainer()
ScreenGui.Parent = targetContainer

-- Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 310, 0, 420)
MainFrame.Position = UDim2.new(0.5, -155, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local mfCorner = Instance.new("UICorner")
mfCorner.CornerRadius = UDim.new(0, 10)
mfCorner.Parent = MainFrame

local mfStroke = Instance.new("UIStroke")
mfStroke.Color = Color3.fromRGB(0, 255, 170)
mfStroke.Thickness = 1.8
mfStroke.Parent = MainFrame

-- Topbar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = Color3.fromRGB(22, 30, 38)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 10)
tbCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🌾⚡ GREEDY GROWERS HUB V1.0"
Title.TextColor3 = Color3.fromRGB(0, 255, 170)
Title.TextSize = 11
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -62, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 55)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
MinBtn.Font = Enum.Font.SourceSansBold
MinBtn.TextSize = 13
MinBtn.Parent = TopBar
local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = MinBtn

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -32, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(80, 25, 25)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 12
CloseBtn.Parent = TopBar
local clsCorner = Instance.new("UICorner")
clsCorner.CornerRadius = UDim.new(0, 6)
clsCorner.Parent = CloseBtn

-- Floating Icon (Khi thu nhỏ)
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Size = UDim2.new(0, 48, 0, 48)
FloatingBtn.Position = UDim2.new(0, 20, 0.4, 0)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(20, 30, 35)
FloatingBtn.Text = "🌾⚡"
FloatingBtn.TextSize = 22
FloatingBtn.Visible = false
FloatingBtn.Parent = ScreenGui
local fltCorner = Instance.new("UICorner")
fltCorner.CornerRadius = UDim.new(1, 0)
fltCorner.Parent = FloatingBtn
local fltStroke = Instance.new("UIStroke")
fltStroke.Color = Color3.fromRGB(0, 255, 170)
fltStroke.Thickness = 2
fltStroke.Parent = FloatingBtn

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatingBtn.Visible = true
end)

FloatingBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    FloatingBtn.Visible = false
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Status Bar
local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(1, -20, 0, 26)
StatusFrame.Position = UDim2.new(0, 10, 0, 44)
StatusFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
StatusFrame.BorderSizePixel = 0
StatusFrame.Parent = MainFrame
local sfCorner = Instance.new("UICorner")
sfCorner.CornerRadius = UDim.new(0, 6)
sfCorner.Parent = StatusFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -12, 1, 0)
StatusLabel.Position = UDim2.new(0, 6, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Trạng thái: Sẵn sàng."
StatusLabel.TextColor3 = Color3.fromRGB(170, 180, 200)
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusFrame

local function setStatus(msg)
    pcall(function() StatusLabel.Text = msg end)
end

-- Scroll Content
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -80)
Scroll.Position = UDim2.new(0, 10, 0, 75)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 170)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 7)
Layout.Parent = Scroll

-- Hàm tạo Nút Bật/Tắt đẹp mắt
local function createToggle(title, defaultOn, onToggle)
    local isOn = defaultOn
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 32)
    btn.BackgroundColor3 = isOn and Color3.fromRGB(20, 50, 40) or Color3.fromRGB(28, 35, 45)
    btn.Text = title .. ": " .. (isOn and "ON" or "OFF")
    btn.TextColor3 = isOn and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(200, 205, 220)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 11
    btn.Parent = Scroll

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = btn

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = isOn and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(45, 55, 70)
    bStroke.Thickness = 1.2
    bStroke.Parent = btn

    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        btn.BackgroundColor3 = isOn and Color3.fromRGB(20, 50, 40) or Color3.fromRGB(28, 35, 45)
        btn.Text = title .. ": " .. (isOn and "ON" or "OFF")
        btn.TextColor3 = isOn and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(200, 205, 220)
        bStroke.Color = isOn and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(45, 55, 70)
        pcall(onToggle, isOn)
    end)
    return btn
end

-- ── 1. TÍNH NĂNG THU HOẠCH & NÉ SÉT ──
createToggle("⚡🌾 Auto Né Sét & Thu Hoạch", false, function(val)
    AutoDodgeHarvest = val
    if not val then
        setStatus("Đã tắt Auto Né Sét.")
    end
end)

-- ── 2. NÚT CHẾ ĐỘ NÉ (TIMED / INSTANT) ──
local btnDodgeMode = Instance.new("TextButton")
btnDodgeMode.Size = UDim2.new(1, -4, 0, 30)
btnDodgeMode.BackgroundColor3 = Color3.fromRGB(20, 35, 50)
btnDodgeMode.Text = "⚡ Né Sét: [ Theo Giây Đếm Chờ Size (~2s) ]"
btnDodgeMode.TextColor3 = Color3.fromRGB(100, 220, 255)
btnDodgeMode.Font = Enum.Font.SourceSansBold
btnDodgeMode.TextSize = 11
btnDodgeMode.Parent = Scroll
local dmCorner = Instance.new("UICorner")
dmCorner.CornerRadius = UDim.new(0, 6)
dmCorner.Parent = btnDodgeMode

btnDodgeMode.MouseButton1Click:Connect(function()
    if DodgeSensitivityMode == "INSTANT" then
        DodgeSensitivityMode = "TIMED"
        btnDodgeMode.Text = "⚡ Né Sét: [ Theo Giây Đếm Chờ Size (~2s) ]"
        btnDodgeMode.TextColor3 = Color3.fromRGB(100, 220, 255)
        btnDodgeMode.BackgroundColor3 = Color3.fromRGB(20, 35, 50)
    else
        DodgeSensitivityMode = "INSTANT"
        btnDodgeMode.Text = "⚡ Né Sét: [ Siêu Nhạy Cảm (Né Ngay Lập Tức) ]"
        btnDodgeMode.TextColor3 = Color3.fromRGB(255, 200, 50)
        btnDodgeMode.BackgroundColor3 = Color3.fromRGB(50, 35, 15)
    end
end)

-- ── 3. CHỌN MỐC THỜI GIAN NÉ ĐÓN ĐẦU ──
local btnDodgeTiming = Instance.new("TextButton")
btnDodgeTiming.Size = UDim2.new(1, -4, 0, 30)
btnDodgeTiming.BackgroundColor3 = Color3.fromRGB(35, 40, 25)
btnDodgeTiming.Text = "⚡ Thu Hoạch Trước Khi Sét Đánh: [ ~" .. tostring(ALL_DODGE_TIMES[DodgeLeadTimeIndex]) .. " Giây ]"
btnDodgeTiming.TextColor3 = Color3.fromRGB(255, 220, 100)
btnDodgeTiming.Font = Enum.Font.SourceSansBold
btnDodgeTiming.TextSize = 11
btnDodgeTiming.Parent = Scroll
local dtCorner = Instance.new("UICorner")
dtCorner.CornerRadius = UDim.new(0, 6)
dtCorner.Parent = btnDodgeTiming

btnDodgeTiming.MouseButton1Click:Connect(function()
    DodgeLeadTimeIndex = DodgeLeadTimeIndex + 1
    if DodgeLeadTimeIndex > #ALL_DODGE_TIMES then DodgeLeadTimeIndex = 1 end
    btnDodgeTiming.Text = "⚡ Thu Hoạch Trước Khi Sét Đánh: [ ~" .. tostring(ALL_DODGE_TIMES[DodgeLeadTimeIndex]) .. " Giây ]"
end)

-- ── 4. THỜI GIAN NUÔI CÂY KHI TRỜI QUANG ──
local btnGrowthTime = Instance.new("TextButton")
btnGrowthTime.Size = UDim2.new(1, -4, 0, 30)
btnGrowthTime.BackgroundColor3 = Color3.fromRGB(20, 45, 30)
btnGrowthTime.Text = "⏱️ Thời Gian Chờ Cây Lớn: [ " .. tostring(ALL_GROWTH_TIMES[GrowthWaitIndex]) .. " Giây ]"
btnGrowthTime.TextColor3 = Color3.fromRGB(100, 255, 180)
btnGrowthTime.Font = Enum.Font.SourceSansBold
btnGrowthTime.TextSize = 11
btnGrowthTime.Parent = Scroll
local gtCorner = Instance.new("UICorner")
gtCorner.CornerRadius = UDim.new(0, 6)
gtCorner.Parent = btnGrowthTime

btnGrowthTime.MouseButton1Click:Connect(function()
    GrowthWaitIndex = GrowthWaitIndex + 1
    if GrowthWaitIndex > #ALL_GROWTH_TIMES then GrowthWaitIndex = 1 end
    btnGrowthTime.Text = "⏱️ Thời Gian Chờ Cây Lớn: [ " .. tostring(ALL_GROWTH_TIMES[GrowthWaitIndex]) .. " Giây ]"
end)

-- ── 5. AUTO GIEO HẠT GIỐNG (AUTO PLANT SEED) ──
createToggle("🌱 Auto Gieo Hạt Giống (Auto Plant)", false, function(val)
    AutoPlantSeed = val
end)

-- ── 6. AUTO NHẶT TIỀN (AUTO COLLECT COINS) ──
createToggle("💵 Auto Nhặt Tiền Rơi (Collect Money)", false, function(val)
    AutoCollectCoins = val
end)

-- ── 7. AUTO BÁN NÔNG PHẨM (AUTO SELL) ──
createToggle("💰 Auto Bán Cây Đầy Balo (Auto Sell)", false, function(val)
    AutoSellCrops = val
end)

-- ── 8. TĂNG TỐC ĐỘ CHẠY (WALKSPEED BOOST) ──
createToggle("🏃‍♂️ Bật Tốc Độ Chạy Cao (WalkSpeed 48)", false, function(val)
    SpeedBoostEnabled = val
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = val and CustomWalkSpeed or 16
    end
end)

-- ── 9. NHẢY KHÔNG GIỚI HẠN (INFINITE JUMP) ──
createToggle("🦘 Nhảy Vô Hạn (Infinite Jump)", false, function(val)
    InfJumpEnabled = val
end)

-- ── 10. THU HOẠCH NGAY LẬP TỨC ──
local btnHarvestInstantly = Instance.new("TextButton")
btnHarvestInstantly.Size = UDim2.new(1, -4, 0, 32)
btnHarvestInstantly.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
btnHarvestInstantly.Text = "🌾 THU HOẠCH NGAY BỆ CÂY NÀY!"
btnHarvestInstantly.TextColor3 = Color3.fromRGB(255, 255, 255)
btnHarvestInstantly.Font = Enum.Font.SourceSansBold
btnHarvestInstantly.TextSize = 11
btnHarvestInstantly.Parent = Scroll
local hInstCorner = Instance.new("UICorner")
hInstCorner.CornerRadius = UDim.new(0, 6)
hInstCorner.Parent = btnHarvestInstantly

btnHarvestInstantly.MouseButton1Click:Connect(function()
    local _, harvestPrompt = getFarmPrompts()
    if harvestPrompt then
        triggerPrompt(harvestPrompt)
        setStatus("🌾 Đã giật thu hoạch cây thành công!")
    else
        setStatus("⚠️ Không tìm thấy cây nào trên bệ!")
    end
end)

-- ═══════════════════════════════════════════════════════════
-- ⚙️ ĐỘNG CƠ XỬ LÝ NỀN (BACKGROUND LOOPS)
-- ═══════════════════════════════════════════════════════════

-- 1. Vòng lặp Auto Né Sét & Thu Hoạch
task.spawn(function()
    while true do
        task.wait(0.01)
        if AutoDodgeHarvest then
            pcall(function()
                local plantPrompt, harvestPrompt, growPadPart = getFarmPrompts()
                local targetDodgeLead = ALL_DODGE_TIMES[DodgeLeadTimeIndex] or 2.0
                local targetMaxGrowthTime = ALL_GROWTH_TIMES[GrowthWaitIndex] or 15

                if harvestPrompt then
                    if plantStartTime == 0 then
                        plantStartTime = os.clock()
                    end

                    local elapsedTime = os.clock() - plantStartTime
                    local hasLightning, strikeTime = detectLightningThreat(growPadPart)

                    if hasLightning then
                        if DodgeSensitivityMode == "TIMED" and strikeTime and strikeTime > targetDodgeLead then
                            setStatus("⚡ SÉT SẮP ĐÁNH (còn " .. string.format("%.1f", strikeTime) .. "s)... Chờ thu hoạch trước " .. targetDodgeLead .. "s")
                        else
                            local info = strikeTime and (" (còn " .. string.format("%.1f", strikeTime) .. "s)") or ""
                            setStatus("⚡ PHÁT HIỆN SÉT" .. info .. "! Thu hoạch NÉ SÉT ngay lập tức!")
                            triggerPrompt(harvestPrompt)
                            plantStartTime = 0
                            task.wait(0.4)
                        end
                    else
                        if elapsedTime >= targetMaxGrowthTime then
                            setStatus("🌾 Cây đã nuôi đủ " .. math.floor(elapsedTime) .. "s -> Thu hoạch Size tối đa!")
                            triggerPrompt(harvestPrompt)
                            plantStartTime = 0
                            task.wait(0.4)
                        else
                            setStatus("🌱 Cây đang lớn (" .. math.floor(elapsedTime) .. "s/" .. targetMaxGrowthTime .. "s)... Theo dõi sét ⚡")
                        end
                    end
                elseif AutoPlantSeed and plantPrompt then
                    -- Tự động tìm hạt giống trong Balo và gieo xuống bệ
                    plantStartTime = 0
                    local char = LocalPlayer.Character
                    local bp = LocalPlayer:FindFirstChild("Backpack")
                    local curTool = char and char:FindFirstChildOfClass("Tool")

                    local isSeed = function(t)
                        if not t then return false end
                        local n = string.lower(t.Name)
                        return string.find(n, "seed") or string.find(n, "hạt") or string.find(n, "ungrown")
                    end

                    if not isSeed(curTool) and bp then
                        for _, item in pairs(bp:GetChildren()) do
                            if item:IsA("Tool") and isSeed(item) then
                                item.Parent = char
                                task.wait(0.15)
                                break
                            end
                        end
                    end

                    setStatus("🌱 Đang gieo 1 hạt giống mới lên bệ...")
                    triggerPrompt(plantPrompt)
                    task.wait(0.5)
                else
                    plantStartTime = 0
                    setStatus("⏳ Chờ bạn trồng cây... (Auto Né Sét & Thu Hoạch đang ON)")
                    task.wait(0.3)
                end
            end)
        end
    end
end)

-- 2. Vòng lặp Gom Tiền Xu (Auto Collect Coins)
task.spawn(function()
    while true do
        task.wait(0.5)
        if AutoCollectCoins then
            pcall(function()
                local myPlot = getMyPlot()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")

                -- Thu tiền từ ProximityPrompts trong plot
                if myPlot then
                    for _, prompt in pairs(myPlot:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") then
                            local act = string.lower(prompt.ActionText or "")
                            if string.find(act, "collect") and (string.find(act, "money") or string.find(act, "cash") or string.find(act, "coin")) then
                                triggerPrompt(prompt)
                            end
                        end
                    end
                end

                -- Hút coin vật lý trong workspace
                if hrp then
                    for _, part in pairs(workspace:GetDescendants()) do
                        if part:IsA("BasePart") and (string.find(string.lower(part.Name), "coin") or string.find(string.lower(part.Name), "cash")) then
                            if (part.Position - hrp.Position).Magnitude <= 40 then
                                if firetouchinterest then
                                    firetouchinterest(hrp, part, 0)
                                    task.wait(0.01)
                                    firetouchinterest(hrp, part, 1)
                                else
                                    part.CFrame = hrp.CFrame
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- 3. Vòng lặp Bán Nông Phẩm (Auto Sell)
task.spawn(function()
    while true do
        task.wait(1.5)
        if AutoSellCrops then
            pcall(function()
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local act = string.lower(prompt.ActionText or "")
                        local obj = string.lower(prompt.ObjectText or "")
                        if string.find(act, "sell") or string.find(obj, "sell") or string.find(act, "bán") then
                            triggerPrompt(prompt)
                        end
                    end
                end
            end)
        end
    end
end)

-- 4. Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if InfJumpEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- 5. Giữ Tốc Độ Chạy (WalkSpeed Guard)
RunService.Stepped:Connect(function()
    if SpeedBoostEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= CustomWalkSpeed then
            hum.WalkSpeed = CustomWalkSpeed
        end
    end
end)

-- 6. Anti-AFK Treo Máy 24/7
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

-- ── Kéo Thả Giao Diện (Make Draggable) ──
local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

setStatus("Đã khởi tạo Greedy Growers Hub thành công!")
