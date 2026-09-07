--[[
    ===================================================================
    ⚡ ULTIMATE SPEED BOOSTER HUB (ROBLOX)
    - Hỗ trợ tăng tốc độ di chuyển (WalkSpeed) & CFrame Speed Multiplier
    - Khắc phục triệt để anti-speed của game (Heartbeat enforcement)
    - Tự động duy trì khi Respawn / Đổi nhân vật
    - Giao diện (GUI) đẹp mắt, kéo thả mượt mà
    ===================================================================
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Safe GUI Container Helper
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

-- Clear old GUI instance if running again
pcall(function()
    local c = getGuiContainer()
    if c and c:FindFirstChild("SpeedBoosterGui") then
        c.SpeedBoosterGui:Destroy()
    end
end)

-- Variables
local SpeedEnabled = false
local TargetSpeed = 50 -- Speed mặc định khi bật
local UseCFrameBoost = false
local CFrameMultiplier = 1.5

-- 🏃 Speed Enforcement Engine (Lock WalkSpeed liên tục)
RunService.Stepped:Connect(function()
    if not SpeedEnabled then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    
    if humanoid then
        -- Ép WalkSpeed liên tục tránh bị game reset
        if humanoid.WalkSpeed ~= TargetSpeed then
            humanoid.WalkSpeed = TargetSpeed
        end
    end
    
    -- CFrame Boost (Dành cho game chặn WalkSpeed hoặc giới hạn tốc độ)
    if UseCFrameBoost and rootPart and humanoid and humanoid.MoveDirection.Magnitude > 0 then
        rootPart.CFrame = rootPart.CFrame + (humanoid.MoveDirection * (CFrameMultiplier * 0.2))
    end
end)

-- Re-apply on spawn
LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    task.wait(0.5)
    if SpeedEnabled and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").WalkSpeed = TargetSpeed
    end
end)

-- 🎨 Create UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpeedBoosterGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = getGuiContainer()

-- ⚡ Floating Icon
local ToggleIcon = Instance.new("TextButton")
ToggleIcon.Name = "ToggleIcon"
ToggleIcon.Size = UDim2.new(0, 48, 0, 48)
ToggleIcon.Position = UDim2.new(0, 10, 0.3, 0)
ToggleIcon.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
ToggleIcon.Text = "⚡"
ToggleIcon.TextSize = 24
ToggleIcon.Parent = ScreenGui

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(1, 0)
IconCorner.Parent = ToggleIcon

local IconStroke = Instance.new("UIStroke")
IconStroke.Color = Color3.fromRGB(0, 230, 255)
IconStroke.Thickness = 2
IconStroke.Parent = ToggleIcon

-- Draggable Function
local function makeDraggable(guiObject, handle)
    handle = handle or guiObject
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
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
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
makeDraggable(ToggleIcon)

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 260, 0, 320)
MainFrame.Position = UDim2.new(0.5, -130, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 230, 255)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

ToggleIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 36)
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 10)
HeaderCorner.Parent = Header

makeDraggable(MainFrame, Header)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ SPEED BOOSTER PRO"
Title.TextColor3 = Color3.fromRGB(0, 230, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 12
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Layout Content
local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, -16, 1, -48)
Container.Position = UDim2.new(0, 8, 0, 42)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 8)
Layout.Parent = Container

-- 1. Main Toggle Button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 0, 36)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
ToggleBtn.Text = "🚀 BẬT TĂNG TỐC: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 13
ToggleBtn.Parent = Container

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(50, 50, 70)
ToggleStroke.Parent = ToggleBtn

ToggleBtn.MouseButton1Click:Connect(function()
    SpeedEnabled = not SpeedEnabled
    if SpeedEnabled then
        ToggleBtn.Text = "🚀 BẬT TĂNG TỐC: ON"
        ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 170)
        ToggleStroke.Color = Color3.fromRGB(0, 255, 170)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = TargetSpeed
        end
    else
        ToggleBtn.Text = "🚀 BẬT TĂNG TỐC: OFF"
        ToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
        ToggleStroke.Color = Color3.fromRGB(50, 50, 70)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
        end
    end
end)

-- 2. Speed Value Label
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, 0, 0, 20)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Tốc độ hiện tại: 50"
SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedLabel.Font = Enum.Font.SourceSansBold
SpeedLabel.TextSize = 12
SpeedLabel.Parent = Container

-- Quick Preset Buttons Frame
local PresetFrame = Instance.new("Frame")
PresetFrame.Size = UDim2.new(1, 0, 0, 32)
PresetFrame.BackgroundTransparency = 1
PresetFrame.Parent = Container

local PresetLayout = Instance.new("UIListLayout")
PresetLayout.FillDirection = Enum.FillDirection.Horizontal
PresetLayout.Padding = UDim.new(0, 5)
PresetLayout.Parent = PresetFrame

local presets = {30, 50, 100, 200}
for _, spd in ipairs(presets) do
    local pBtn = Instance.new("TextButton")
    pBtn.Size = UDim2.new(0.23, 0, 1, 0)
    pBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    pBtn.Text = tostring(spd)
    pBtn.TextColor3 = Color3.fromRGB(0, 230, 255)
    pBtn.Font = Enum.Font.SourceSansBold
    pBtn.TextSize = 12
    pBtn.Parent = PresetFrame

    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = UDim.new(0, 4)
    pCorner.Parent = pBtn

    pBtn.MouseButton1Click:Connect(function()
        TargetSpeed = spd
        SpeedLabel.Text = "Tốc độ hiện tại: " .. tostring(TargetSpeed)
        if SpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = TargetSpeed
        end
    end)
end

-- 3. CFrame Teleport Step Boost Toggle (Bypass Anti-Speed)
local CFrameBtn = Instance.new("TextButton")
CFrameBtn.Size = UDim2.new(1, 0, 0, 32)
CFrameBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
CFrameBtn.Text = "🌀 CFrame Boost (Bypass Anti-Speed): OFF"
CFrameBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
CFrameBtn.Font = Enum.Font.SourceSansBold
CFrameBtn.TextSize = 10
CFrameBtn.Parent = Container

local CFCorner = Instance.new("UICorner")
CFCorner.CornerRadius = UDim.new(0, 6)
CFCorner.Parent = CFrameBtn

CFrameBtn.MouseButton1Click:Connect(function()
    UseCFrameBoost = not UseCFrameBoost
    if UseCFrameBoost then
        CFrameBtn.Text = "🌀 CFrame Boost (Bypass Anti-Speed): ON"
        CFrameBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
    else
        CFrameBtn.Text = "🌀 CFrame Boost (Bypass Anti-Speed): OFF"
        CFrameBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
    end
end)

-- Reset Speed Button
local ResetBtn = Instance.new("TextButton")
ResetBtn.Size = UDim2.new(1, 0, 0, 30)
ResetBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
ResetBtn.Text = "🔄 Trở về tốc độ mặc định (16)"
ResetBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
ResetBtn.Font = Enum.Font.SourceSansBold
ResetBtn.TextSize = 11
ResetBtn.Parent = Container

local ResetCorner = Instance.new("UICorner")
ResetCorner.CornerRadius = UDim.new(0, 6)
ResetCorner.Parent = ResetBtn

ResetBtn.MouseButton1Click:Connect(function()
    SpeedEnabled = false
    UseCFrameBoost = false
    TargetSpeed = 16
    SpeedLabel.Text = "Tốc độ hiện tại: 16"
    ToggleBtn.Text = "🚀 BẬT TĂNG TỐC: OFF"
    ToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
    ToggleStroke.Color = Color3.fromRGB(50, 50, 70)
    CFrameBtn.Text = "🌀 CFrame Boost (Bypass Anti-Speed): OFF"
    CFrameBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
    end
end)
