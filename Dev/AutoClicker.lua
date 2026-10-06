local plyrs = game:GetService("Players")
local lp = plyrs.LocalPlayer
local uiParent = lp:WaitForChild("PlayerGui")

for _, v in pairs(uiParent:GetChildren()) do
    if v.Name == "DevClickerUI" then v:Destroy() end
end

local sg = Instance.new("ScreenGui")
sg.Name = "DevClickerUI"
sg.Parent = uiParent

local allLogs = {}
local termFrame = Instance.new("Frame", sg)
termFrame.Size = UDim2.new(0, 500, 0, 400)
termFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
termFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
termFrame.Active = true
termFrame.Draggable = true
Instance.new("UICorner", termFrame).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", termFrame).Color = Color3.fromRGB(80, 80, 90)

local termTop = Instance.new("Frame", termFrame)
termTop.Size = UDim2.new(1, 0, 0, 35)
termTop.BackgroundColor3 = Color3.fromRGB(20, 20, 25)

local termTitle = Instance.new("TextLabel", termTop)
termTitle.Size = UDim2.new(0.5, 0, 1, 0)
termTitle.Position = UDim2.new(0, 10, 0, 0)
termTitle.BackgroundTransparency = 1
termTitle.Text = "📟 Modo Dev - Tracker de Mudanças"
termTitle.TextColor3 = Color3.fromRGB(100, 255, 100)
termTitle.Font = Enum.Font.GothamBold
termTitle.TextSize = 14
termTitle.TextXAlignment = Enum.TextXAlignment.Left

local monitorBtn = Instance.new("TextButton", termTop)
monitorBtn.Size = UDim2.new(0, 100, 0, 25)
monitorBtn.Position = UDim2.new(1, -170, 0, 5)
monitorBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
monitorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
monitorBtn.Font = Enum.Font.GothamBold
monitorBtn.TextSize = 12
monitorBtn.Text = "START SCAN"
Instance.new("UICorner", monitorBtn).CornerRadius = UDim.new(0, 4)

local termCopyBtn = Instance.new("TextButton", termTop)
termCopyBtn.Size = UDim2.new(0, 60, 0, 25)
termCopyBtn.Position = UDim2.new(1, -65, 0, 5)
termCopyBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
termCopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
termCopyBtn.Font = Enum.Font.GothamBold
termCopyBtn.TextSize = 12
termCopyBtn.Text = "COPY"
Instance.new("UICorner", termCopyBtn).CornerRadius = UDim.new(0, 4)

local termScroll = Instance.new("ScrollingFrame", termFrame)
termScroll.Size = UDim2.new(1, -10, 1, -45)
termScroll.Position = UDim2.new(0, 5, 0, 40)
termScroll.BackgroundTransparency = 1
termScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
termScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
termScroll.ScrollBarThickness = 4
local termList = Instance.new("UIListLayout", termScroll)

local function logMsg(msg)
    local t = os.date("%H:%M:%S") .. " | " .. tostring(msg)
    table.insert(allLogs, t)

    local txt = Instance.new("TextLabel", termScroll)
    txt.Size = UDim2.new(1, 0, 0, 0)
    txt.AutomaticSize = Enum.AutomaticSize.Y
    txt.BackgroundTransparency = 1
    txt.TextColor3 = Color3.fromRGB(180, 180, 180)
    txt.TextSize = 12
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextWrapped = true
    txt.Text = t

    termScroll.CanvasPosition = Vector2.new(0, termScroll.AbsoluteWindowSize.Y + 9999)
end

logMsg("Painel DEV Tracker. Ele vai gravar apenas as MUDANÇAS na UI.")

termCopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(table.concat(allLogs, "\n"))
        termCopyBtn.Text = "OK!"
        task.wait(1)
        termCopyBtn.Text = "COPY"
    end
end)

local isMonitoring = false
local monitorLoop = nil
local previousStates = {}
local isFirstScan = true

local function scanChanges()
    local char = lp.Character
    if not char then return end

    local head = char:FindFirstChild("Head")
    if not head then return end

    local bbg = head:FindFirstChild("CharacterBillboard")
    if not bbg then
        if not isFirstScan then logMsg("⚠️ CharacterBillboard desapareceu.") end
        return
    end

    local changesFound = 0

    for _, desc in pairs(bbg:GetDescendants()) do
        local stateStr = nil
        local displayStr = nil

        if desc:IsA("Frame") or desc:IsA("ImageLabel") then
            stateStr = tostring(desc.Visible) .. "|" .. tostring(desc.Size)
            displayStr = "Visível: " .. tostring(desc.Visible) .. " | Size: " .. tostring(desc.Size)
        elseif desc:IsA("TextLabel") then
            stateStr = tostring(desc.Visible) .. "|" .. tostring(desc.Text)
            displayStr = "Visível: " .. tostring(desc.Visible) .. " | Texto: '" .. desc.Text .. "'"
        end

        if stateStr then
            if isFirstScan then
                previousStates[desc] = stateStr
            else
                local oldState = previousStates[desc]
                if oldState ~= stateStr then
                    logMsg("🔄 " .. desc.Name .. " alterou -> " .. displayStr)
                    previousStates[desc] = stateStr
                    changesFound = changesFound + 1
                end
            end
        end
    end

    if isFirstScan then
        logMsg("✅ Estado base capturado! Agora vá pegar ou cancelar o serviço.")
        isFirstScan = false
    elseif changesFound > 0 then
        logMsg("--- ☝️ Ação detectada (" .. changesFound .. " elementos mudaram) ---")
    end
end

monitorBtn.MouseButton1Click:Connect(function()
    isMonitoring = not isMonitoring
    if isMonitoring then
        monitorBtn.Text = "STOP SCAN"
        monitorBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        previousStates = {}
        isFirstScan = true
        logMsg("🟢 Iniciando scanner de mudanças (0.5s)...")
        monitorLoop = task.spawn(function()
            while isMonitoring do
                scanChanges()
                task.wait(0.5) -- Mais rápido para pegar o momento exato
            end
        end)
    else
        monitorBtn.Text = "START SCAN"
        monitorBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
        logMsg("🔴 Scan parado.")
        if monitorLoop then task.cancel(monitorLoop) end
    end
end)
