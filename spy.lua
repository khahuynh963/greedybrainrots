--[[
    🔍 GREEDY BRAINROTS - GAME SPY V2
    Tự động lưu output vào file + hiển thị trên màn hình game.
    Delta Executor hỗ trợ writefile -> output sẽ được lưu tại:
      workspace/GreedyBrainrotsSpy.txt (trong thư mục Delta)
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

-- 2. Scan Workspace top-level children
log("== WORKSPACE TOP-LEVEL ==")
for _, child in pairs(workspace:GetChildren()) do
    local count = 0
    pcall(function() count = #child:GetChildren() end)
    log("[" .. child.ClassName .. "] " .. child.Name .. " (" .. count .. " children)")
end

log("")

-- 3. Scan ProximityPrompts
log("== PROXIMITY PROMPTS ==")
local promptCount = 0
for _, prompt in pairs(workspace:GetDescendants()) do
    if prompt:IsA("ProximityPrompt") then
        promptCount = promptCount + 1
        local parentName = prompt.Parent and prompt.Parent.Name or "nil"
        local grandName = prompt.Parent and prompt.Parent.Parent and prompt.Parent.Parent.Name or "nil"
        log("#" .. promptCount .. " Parent=" .. parentName .. " Grand=" .. grandName .. " Action='" .. prompt.ActionText .. "' Object='" .. prompt.ObjectText .. "' Dist=" .. prompt.MaxActivationDistance)
    end
end
if promptCount == 0 then log("(Khong tim thay ProximityPrompt nao)") end

log("")

-- 4. Scan Player Backpack
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
            if item:IsA("Tool") then
                log("[Equipped] " .. item.Name)
            end
        end
    end
end

log("")

-- 5. ClickDetectors
log("== CLICK DETECTORS ==")
local cdCount = 0
for _, cd in pairs(workspace:GetDescendants()) do
    if cd:IsA("ClickDetector") then
        cdCount = cdCount + 1
        log("#" .. cdCount .. " Parent=" .. cd.Parent.Name .. " Path=" .. cd:GetFullName())
    end
end
if cdCount == 0 then log("(Khong tim thay ClickDetector nao)") end

log("")
log("== SPY HOAN TAT ==")
log("Bay gio hay thu bam MUA / TRONG / BAN 1 lan trong game.")
log("Ten Remote se hien ra o Console (F9).")

-- Save to file
local fullOutput = table.concat(output, "\n")

pcall(function()
    if writefile then
        writefile("GreedyBrainrotsSpy.txt", fullOutput)
        log("DA LUU FILE: GreedyBrainrotsSpy.txt (trong thu muc Delta Executor)")
    end
end)

-- Hook Remote Spy
pcall(function()
    if hookmetamethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                local args = {...}
                local argsStr = ""
                for i, v in ipairs(args) do
                    argsStr = argsStr .. tostring(v) .. ", "
                end
                local spyLine = "[REMOTE SPY] " .. method .. " -> " .. self:GetFullName() .. " | Args: (" .. argsStr .. ")"
                print(spyLine)
                -- Append to file
                pcall(function()
                    if appendfile then
                        appendfile("GreedyBrainrotsSpy.txt", "\n" .. spyLine)
                    elseif writefile and readfile then
                        local existing = readfile("GreedyBrainrotsSpy.txt")
                        writefile("GreedyBrainrotsSpy.txt", existing .. "\n" .. spyLine)
                    end
                end)
            end
            return oldNamecall(self, ...)
        end)
    end
end)

-- Show Copy-able TextBox on screen
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
    frame.Size = UDim2.new(0.55, 0, 0.75, 0)
    frame.Position = UDim2.new(0.22, 0, 0.12, 0)
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

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 35)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔍 SPY OUTPUT - Bam Ctrl+A roi Ctrl+C de copy!"
    title.TextColor3 = Color3.fromRGB(0, 255, 170)
    title.TextSize = 13
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -32, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 12
    closeBtn.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    -- TextBox cho phep select & copy
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 1, -45)
    textBox.Position = UDim2.new(0, 10, 0, 38)
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
