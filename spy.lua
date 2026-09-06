--[[
    🔍 GREEDY BRAINROTS - GAME SPY (Khám phá cấu trúc game)
    Chạy script này trong Delta Executor rồi mở Console (F9)
    để xem danh sách Remotes, Prompts, và cấu trúc Workspace.
    Copy output gửi lại cho dev để viết script chuẩn!
--]]

local output = {}
local function log(msg)
    table.insert(output, msg)
    print(msg)
end

log("========== 🔍 GREEDY BRAINROTS SPY ==========")
log("")

-- 1. Scan ReplicatedStorage
log("── 📦 REPLICATED STORAGE (Tất cả Remotes) ──")
for _, child in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") or child:IsA("BindableEvent") then
        log("  [" .. child.ClassName .. "] " .. child:GetFullName())
    end
end

log("")

-- 2. Scan Workspace top-level children
log("── 🗺️ WORKSPACE TOP-LEVEL CHILDREN ──")
for _, child in pairs(workspace:GetChildren()) do
    local desc = child.ClassName
    local count = 0
    pcall(function() count = #child:GetChildren() end)
    log("  [" .. desc .. "] " .. child.Name .. " (children: " .. count .. ")")
end

log("")

-- 3. Scan ProximityPrompts
log("── 🎯 ALL PROXIMITY PROMPTS ──")
local promptCount = 0
for _, prompt in pairs(workspace:GetDescendants()) do
    if prompt:IsA("ProximityPrompt") then
        promptCount = promptCount + 1
        local parentName = prompt.Parent and prompt.Parent.Name or "nil"
        local grandName = prompt.Parent and prompt.Parent.Parent and prompt.Parent.Parent.Name or "nil"
        log("  Prompt #" .. promptCount .. ": Parent=" .. parentName .. " | GrandParent=" .. grandName .. " | Action='" .. prompt.ActionText .. "' | Object='" .. prompt.ObjectText .. "' | MaxDistance=" .. prompt.MaxActivationDistance)
    end
end
if promptCount == 0 then log("  (Không tìm thấy ProximityPrompt nào!)") end

log("")

-- 4. Scan Player Backpack (Tools)
log("── 🎒 PLAYER BACKPACK (Tools / Items) ──")
local player = game.Players.LocalPlayer
if player then
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, item in pairs(bp:GetChildren()) do
            log("  [" .. item.ClassName .. "] " .. item.Name)
        end
    end
    if player.Character then
        for _, item in pairs(player.Character:GetChildren()) do
            if item:IsA("Tool") then
                log("  [Equipped] " .. item.Name)
            end
        end
    end
end

log("")

-- 5. Scan ClickDetectors
log("── 🖱️ ALL CLICK DETECTORS ──")
local cdCount = 0
for _, cd in pairs(workspace:GetDescendants()) do
    if cd:IsA("ClickDetector") then
        cdCount = cdCount + 1
        log("  ClickDetector #" .. cdCount .. ": Parent=" .. cd.Parent.Name .. " | Path=" .. cd:GetFullName())
    end
end
if cdCount == 0 then log("  (Không tìm thấy ClickDetector nào!)") end

log("")

-- 6. Hook RemoteEvent FireServer (Spy on what the game sends)
log("── 🕵️ HOOKING REMOTE SPY (Theo dõi các lệnh game gửi đi) ──")
log("  Hãy thủ công bấm TRỒNG / MUA / BÁN 1 lần trong game.")
log("  Khi bạn bấm, tên Remote sẽ hiện ra ở Console (F9).")
log("")

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" then
        local args = {...}
        local argsStr = ""
        for i, v in ipairs(args) do
            argsStr = argsStr .. tostring(v) .. ", "
        end
        print("🕵️ [REMOTE SPY] " .. method .. " -> " .. self:GetFullName() .. " | Args: (" .. argsStr .. ")")
    end
    return oldNamecall(self, ...)
end)

log("========== ✅ SPY HOÀN TẤT. MỞ CONSOLE (F9) ĐỂ XEM KẾT QUẢ ==========")
log("Hãy thử bấm MUA 1 con, TRỒNG 1 con, BÁN 1 lần trong game.")
log("Sau đó chụp ảnh hoặc copy output từ Console gửi lại cho dev!")

-- Display in a GUI too
pcall(function()
    local sg = Instance.new("ScreenGui")
    sg.Name = "SpyOutputGui"
    sg.ResetOnSpawn = false
    pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not sg.Parent then sg.Parent = player.PlayerGui end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.5, 0, 0.7, 0)
    frame.Position = UDim2.new(0.25, 0, 0.15, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -40)
    scroll.Position = UDim2.new(0, 10, 0, 35)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, #output * 18)
    scroll.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "🔍 SPY OUTPUT (Copy gửi cho dev!)"
    title.TextColor3 = Color3.fromRGB(0, 255, 170)
    title.TextSize = 14
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -28, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 12
    closeBtn.Parent = frame
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    for i, line in ipairs(output) do
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 16)
        lbl.Position = UDim2.new(0, 0, 0, (i - 1) * 17)
        lbl.BackgroundTransparency = 1
        lbl.Text = line
        lbl.TextColor3 = Color3.fromRGB(200, 200, 220)
        lbl.TextSize = 11
        lbl.Font = Enum.Font.Code
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextWrapped = true
        lbl.Parent = scroll
    end
end)
