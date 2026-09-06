--[[
    🔍 GREEDY BRAINROTS - GAME SPY V3
    Tự động copy vào clipboard + hiển thị TextBox trên màn hình.
    Bấm nút [COPY] trên GUI -> rồi Ctrl+V dán kết quả!
--]]

local output = {}
local function log(msg)
    table.insert(output, msg)
    print(msg)
end

log("========== GREEDY BRAINROTS SPY ==========")
log("")

-- 1. Scan ReplicatedStorage
log("== REPLICATED STORAGE (Remotes) ==")
for _, child in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") or child:IsA("BindableEvent") then
        log("[" .. child.ClassName .. "] " .. child:GetFullName())
    end
end

log("")

-- 2. Scan Workspace top-level
log("== WORKSPACE TOP-LEVEL ==")
for _, child in pairs(workspace:GetChildren()) do
    local count = 0
    pcall(function() count = #child:GetChildren() end)
    log("[" .. child.ClassName .. "] " .. child.Name .. " (" .. count .. " children)")
end

log("")

-- 3. Deeper scan of important-looking folders
log("== WORKSPACE DEEPER SCAN ==")
for _, child in pairs(workspace:GetChildren()) do
    if child:IsA("Folder") or child:IsA("Model") then
        local cName = string.lower(child.Name)
        if string.find(cName, "plot") or string.find(cName, "shop") or string.find(cName, "sell") 
           or string.find(cName, "river") or string.find(cName, "water") or string.find(cName, "brainrot")
           or string.find(cName, "item") or string.find(cName, "drop") or string.find(cName, "coin")
           or string.find(cName, "spawn") or string.find(cName, "collect") or string.find(cName, "buy") then
            log("  >> [" .. child.ClassName .. "] " .. child.Name)
            for _, sub in pairs(child:GetChildren()) do
                log("     [" .. sub.ClassName .. "] " .. sub.Name)
            end
        end
    end
end

log("")

-- 4. Scan ProximityPrompts
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

-- 5. Scan Backpack
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

-- Auto copy to clipboard
pcall(function()
    if setclipboard then
        setclipboard(fullOutput)
        log("DA TU DONG COPY VAO CLIPBOARD! Hay Ctrl+V dan ket qua.")
    elseif toclipboard then
        toclipboard(fullOutput)
        log("DA TU DONG COPY VAO CLIPBOARD!")
    end
end)

-- Save to file
pcall(function()
    if writefile then
        writefile("GreedyBrainrotsSpy.txt", fullOutput)
    end
end)

-- Hook Remote Spy
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
                local line = "[REMOTE] " .. method .. " -> " .. self:GetFullName() .. " | Args: (" .. argsStr .. ")"
                print(line)
                table.insert(spyLines, line)
            end
            return oldNc(self, ...)
        end)
    end
end)

-- GUI with TextBox + Copy button
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
    frame.Size = UDim2.new(0.55, 0, 0.8, 0)
    frame.Position = UDim2.new(0.22, 0, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 255, 170)
    stroke.Thickness = 1.5
    stroke.Parent = frame

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.5, 0, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 2)
    title.BackgroundTransparency = 1
    title.Text = "🔍 SPY OUTPUT"
    title.TextColor3 = Color3.fromRGB(0, 255, 170)
    title.TextSize = 14
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    -- COPY button (green)
    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0, 120, 0, 26)
    copyBtn.Position = UDim2.new(0.5, -60, 0, 3)
    copyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    copyBtn.Text = "📋 COPY KET QUA"
    copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyBtn.Font = Enum.Font.SourceSansBold
    copyBtn.TextSize = 12
    copyBtn.Parent = frame

    local copyCorner = Instance.new("UICorner")
    copyCorner.CornerRadius = UDim.new(0, 6)
    copyCorner.Parent = copyBtn

    copyBtn.MouseButton1Click:Connect(function()
        local all = fullOutput
        if #spyLines > 0 then
            all = all .. "\n\n== REMOTE SPY LOG ==\n" .. table.concat(spyLines, "\n")
        end
        pcall(function()
            if setclipboard then setclipboard(all)
            elseif toclipboard then toclipboard(all) end
        end)
        copyBtn.Text = "✅ DA COPY!"
        copyBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 80)
        task.wait(2)
        copyBtn.Text = "📋 COPY KET QUA"
        copyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    end)

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -28, 0, 4)
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

    -- TextBox
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 1, -40)
    textBox.Position = UDim2.new(0, 10, 0, 35)
    textBox.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
    textBox.Text = fullOutput
    textBox.TextColor3 = Color3.fromRGB(200, 200, 220)
    textBox.TextSize = 11
    textBox.Font = Enum.Font.Code
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.TextYAlignment = Enum.TextYAlignment.Top
    textBox.TextWrapped = true
    textBox.MultiLine = true
    textBox.ClearTextOnFocus = false
    textBox.TextEditable = false
    textBox.Parent = frame

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 8)
    tbCorner.Parent = textBox
end)
