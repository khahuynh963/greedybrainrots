--[[
    🔍 GREEDY BRAINROTS - GAME SPY V5
    Tự động ghi file vào Shared Picture/Misc Folder của LDPlayer
    File sẽ xuất hiện NGAY LẬP TỨC tại D:\Documents\XuanZhi9\Pictures\GreedyBrainrotsSpy.txt trên máy Windows!
--]]

local output = {}
local function log(msg)
    table.insert(output, msg)
    print(msg)
end

log("========== GREEDY BRAINROTS SPY V5 ==========")
log("")

-- 1. Scan ReplicatedStorage
log("== REPLICATED STORAGE (Remotes) ==")
for _, child in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") or child:IsA("BindableEvent") then
        log("[" .. child.ClassName .. "] " .. child:GetFullName())
    end
end

log("")

-- 2. Workspace top-level
log("== WORKSPACE TOP-LEVEL ==")
for _, child in pairs(workspace:GetChildren()) do
    local count = 0
    pcall(function() count = #child:GetChildren() end)
    log("[" .. child.ClassName .. "] " .. child.Name .. " (" .. count .. " children)")
end

log("")

-- 3. Deeper scan of Workspace
log("== WORKSPACE DEEPER SCAN ==")
for _, child in pairs(workspace:GetChildren()) do
    if child:IsA("Folder") or child:IsA("Model") then
        local cName = string.lower(child.Name)
        if string.find(cName, "plot") or string.find(cName, "shop") or string.find(cName, "sell")
           or string.find(cName, "river") or string.find(cName, "water") or string.find(cName, "brainrot")
           or string.find(cName, "item") or string.find(cName, "drop") or string.find(cName, "coin")
           or string.find(cName, "spawn") or string.find(cName, "collect") or string.find(cName, "buy")
           or string.find(cName, "conveyor") or string.find(cName, "zone") or string.find(cName, "pad") then
            log(">> [" .. child.ClassName .. "] " .. child.Name)
            for _, sub in pairs(child:GetChildren()) do
                log("   [" .. sub.ClassName .. "] " .. sub.Name)
                pcall(function()
                    for _, sub2 in pairs(sub:GetChildren()) do
                        if sub2:IsA("RemoteEvent") or sub2:IsA("ProximityPrompt") or sub2:IsA("ClickDetector") or sub2:IsA("StringValue") or sub2:IsA("ObjectValue") then
                            log("      [" .. sub2.ClassName .. "] " .. sub2.Name .. " (" .. sub2:GetFullName() .. ")")
                        end
                    end
                end)
            end
        end
    end
end

log("")

-- 4. ProximityPrompts
log("== PROXIMITY PROMPTS ==")
local promptCount = 0
for _, prompt in pairs(workspace:GetDescendants()) do
    if prompt:IsA("ProximityPrompt") then
        promptCount = promptCount + 1
        local parentName = prompt.Parent and prompt.Parent.Name or "nil"
        local grandName = prompt.Parent and prompt.Parent.Parent and prompt.Parent.Parent.Name or "nil"
        log("#" .. promptCount .. " Parent=" .. parentName .. " Grand=" .. grandName .. " Action='" .. prompt.ActionText .. "' Object='" .. prompt.ObjectText .. "'")
    end
end
if promptCount == 0 then log("(Khong co ProximityPrompt)") end

log("")

-- 5. Backpack
log("== PLAYER BACKPACK ==")
local player = game.Players.LocalPlayer
if player then
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, item in pairs(bp:GetChildren()) do
            log("[" .. item.ClassName .. "] " .. item.Name)
        end
    end
    if player.Character then
        for _, item in pairs(player.Character:GetChildren()) do
            if item:IsA("Tool") then log("[Equipped] " .. item.Name) end
        end
    end
end

log("")

-- 6. ClickDetectors
log("== CLICK DETECTORS ==")
local cdCount = 0
for _, cd in pairs(workspace:GetDescendants()) do
    if cd:IsA("ClickDetector") then
        cdCount = cdCount + 1
        log("#" .. cdCount .. " " .. cd:GetFullName())
    end
end
if cdCount == 0 then log("(Khong co ClickDetector)") end

log("")
log("== SPY XONG ==")

local fullOutput = table.concat(output, "\n")

-- ═══════════════════════════════════════════════════════════
-- DỮ LIỆU ĐƯỢC GHI VÀO TẤT CẢ CÁC ĐƯỜNG DẪN BAO GỒM SHARED FOLDER
-- ═══════════════════════════════════════════════════════════

local pathsToTry = {
    -- LDPlayer Shared Folders (xuất hiện thẳng trên Windows D:\Documents\XuanZhi9\Pictures)
    "/sdcard/Pictures/GreedyBrainrotsSpy.txt",
    "/storage/emulated/0/Pictures/GreedyBrainrotsSpy.txt",
    "/sdcard/Misc/GreedyBrainrotsSpy.txt",
    "/storage/emulated/0/Misc/GreedyBrainrotsSpy.txt",
    "/sdcard/Download/GreedyBrainrotsSpy.txt",
    "/storage/emulated/0/Download/GreedyBrainrotsSpy.txt",
    "GreedyBrainrotsSpy.txt"
}

local function saveToFile(content)
    for _, p in ipairs(pathsToTry) do
        pcall(function() writefile(p, content) end)
    end
end

saveToFile(fullOutput)

-- ═══════════════════════════════════════════════════════════
-- HOOK REMOTE SPY (Ghi nhận real-time khi bấm MUA/TRỒNG/BÁN)
-- ═══════════════════════════════════════════════════════════

local spyLines = {}

pcall(function()
    if hookmetamethod then
        local oldNc
        oldNc = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                local args = {...}
                local argsStr = ""
                for i, v in ipairs(args) do argsStr = argsStr .. tostring(v) .. ", " end
                local line = "[REMOTE SPY] " .. method .. " -> " .. self:GetFullName() .. " | Args: (" .. argsStr .. ")"
                print(line)
                table.insert(spyLines, line)
                
                -- Ghi nhận cập nhật real-time vào Shared Pictures
                local updatedContent = fullOutput .. "\n\n== REMOTE SPY REAL-TIME LOG ==\n" .. table.concat(spyLines, "\n")
                saveToFile(updatedContent)
            end
            return oldNc(self, ...)
        end)
    end
end)

-- Display notification GUI on screen
pcall(function()
    if game:GetService("CoreGui"):FindFirstChild("SpyOutputGui") then
        game:GetService("CoreGui").SpyOutputGui:Destroy()
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "SpyOutputGui"
    sg.ResetOnSpawn = false
    pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not sg.Parent then sg.Parent = player.PlayerGui end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 360, 0, 130)
    frame.Position = UDim2.new(0.5, -180, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 255, 170)
    stroke.Thickness = 2
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "🔍 SPY V5 - READY FOR DEV!"
    title.TextColor3 = Color3.fromRGB(0, 255, 170)
    title.TextSize = 15
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local info1 = Instance.new("TextLabel")
    info1.Size = UDim2.new(1, -20, 0, 22)
    info1.Position = UDim2.new(0, 10, 0, 35)
    info1.BackgroundTransparency = 1
    info1.Text = "✅ File tu dong luu qua Windows Shared Folder!"
    info1.TextColor3 = Color3.fromRGB(200, 200, 220)
    info1.TextSize = 13
    info1.Font = Enum.Font.SourceSans
    info1.TextXAlignment = Enum.TextXAlignment.Left
    info1.Parent = frame

    local info2 = Instance.new("TextLabel")
    info2.Size = UDim2.new(1, -20, 0, 22)
    info2.Position = UDim2.new(0, 10, 0, 60)
    info2.BackgroundTransparency = 1
    info2.Text = "👉 BAM THU MUA / TRONG / BAN 1 LAN TRONG GAME"
    info2.TextColor3 = Color3.fromRGB(255, 200, 100)
    info2.TextSize = 12
    info2.Font = Enum.Font.SourceSansBold
    info2.TextXAlignment = Enum.TextXAlignment.Left
    info2.Parent = frame

    local info3 = Instance.new("TextLabel")
    info3.Size = UDim2.new(1, -20, 0, 22)
    info3.Position = UDim2.new(0, 10, 0, 85)
    info3.BackgroundTransparency = 1
    info3.Text = "Roi bao cho dev biet de doc file!"
    info3.TextColor3 = Color3.fromRGB(0, 255, 170)
    info3.TextSize = 12
    info3.Font = Enum.Font.SourceSans
    info3.TextXAlignment = Enum.TextXAlignment.Left
    info3.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -28, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 12
    closeBtn.Parent = frame

    local clCorner = Instance.new("UICorner")
    clCorner.CornerRadius = UDim.new(0, 6)
    clCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
end)
