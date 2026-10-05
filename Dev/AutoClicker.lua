local coreGui = game:GetService("CoreGui")
local plyrs = game:GetService("Players")
local lp = plyrs.LocalPlayer
local rs = game:GetService("RunService")

for _, v in pairs(coreGui:GetChildren()) do
    if v.Name == "DevClickerUI" then v:Destroy() end
end

local sg = Instance.new("ScreenGui")
sg.Name = "DevClickerUI"
sg.Parent = coreGui

local allLogs = {}

local mainFrame = Instance.new("Frame", sg)
mainFrame.Size = UDim2.new(0, 200, 0, 140)
mainFrame.Position = UDim2.new(0.5, -350, 0.5, -50)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.Active = true
mainFrame.Draggable = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", mainFrame).Color = Color3.fromRGB(0, 255, 255)

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "3D Telemetry Monitor"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14

local monitorBtn = Instance.new("TextButton", mainFrame)
monitorBtn.Size = UDim2.new(0.8, 0, 0, 40)
monitorBtn.Position = UDim2.new(0.1, 0, 0, 35)
monitorBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
monitorBtn.Text = "START MONITOR"
monitorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
monitorBtn.Font = Enum.Font.GothamBold
monitorBtn.TextSize = 12
Instance.new("UICorner", monitorBtn).CornerRadius = UDim.new(0, 6)

local logToggleBtn = Instance.new("TextButton", mainFrame)
logToggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
logToggleBtn.Position = UDim2.new(0.1, 0, 0, 85)
logToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
logToggleBtn.Text = "HIDE LOGS"
logToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
logToggleBtn.Font = Enum.Font.GothamBold
logToggleBtn.TextSize = 12
Instance.new("UICorner", logToggleBtn).CornerRadius = UDim.new(0, 6)

local termFrame = Instance.new("Frame", sg)
termFrame.Size = UDim2.new(0, 350, 0, 300)
termFrame.Position = UDim2.new(0.5, -100, 0.5, -50)
termFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
termFrame.Visible = true
termFrame.Active = true
termFrame.Draggable = true
Instance.new("UICorner", termFrame).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", termFrame).Color = Color3.fromRGB(80, 80, 90)

local termTop = Instance.new("Frame", termFrame)
termTop.Size = UDim2.new(1, 0, 0, 35)
termTop.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
termTop.BorderSizePixel = 0
Instance.new("UICorner", termTop).CornerRadius = UDim.new(0, 6)

local termTitle = Instance.new("TextLabel", termTop)
termTitle.Size = UDim2.new(0.5, 0, 1, 0)
termTitle.Position = UDim2.new(0, 10, 0, 0)
termTitle.BackgroundTransparency = 1
termTitle.Text = "📟 Live Telemetry Logs"
termTitle.TextColor3 = Color3.fromRGB(100, 255, 100)
termTitle.Font = Enum.Font.GothamBold
termTitle.TextSize = 14
termTitle.TextXAlignment = Enum.TextXAlignment.Left

local termCopyBtn = Instance.new("TextButton", termTop)
termCopyBtn.Size = UDim2.new(0, 60, 0, 25)
termCopyBtn.Position = UDim2.new(1, -105, 0, 5)
termCopyBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
termCopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
termCopyBtn.Font = Enum.Font.GothamBold
termCopyBtn.TextSize = 12
termCopyBtn.Text = "COPY"
Instance.new("UICorner", termCopyBtn).CornerRadius = UDim.new(0, 4)

local termCloseBtn = Instance.new("TextButton", termTop)
termCloseBtn.Size = UDim2.new(0, 30, 0, 25)
termCloseBtn.Position = UDim2.new(1, -35, 0, 5)
termCloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
termCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
termCloseBtn.Font = Enum.Font.GothamBold
termCloseBtn.TextSize = 12
termCloseBtn.Text = "X"
Instance.new("UICorner", termCloseBtn).CornerRadius = UDim.new(0, 4)

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

logMsg("Monitor de Alta Frequência Carregado.")

termCopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(table.concat(allLogs, "\n"))
        termCopyBtn.Text = "OK!"
        task.wait(1)
        termCopyBtn.Text = "COPY"
    else
        logMsg("❌ Erro: Executor não suporta setclipboard.")
    end
end)

logToggleBtn.MouseButton1Click:Connect(function()
    termFrame.Visible = not termFrame.Visible
    if termFrame.Visible then
        logToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
        logToggleBtn.Text = "HIDE LOGS"
    else
        logToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        logToggleBtn.Text = "SHOW LOGS"
    end
end)

termCloseBtn.MouseButton1Click:Connect(function()
    termFrame.Visible = false
    logToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    logToggleBtn.Text = "SHOW LOGS"
end)

-- =========================================================================
-- SISTEMA DE MONITORAMENTO EM TEMPO REAL
-- =========================================================================
local isMonitoring = false
local monitorLoop = nil

local lastState = {
    barVisible = nil,
    barFill = nil,
    money = nil,
    job = nil,
    bbgFound = nil
}

local function scanHead()
    local char = lp.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    local bbg = head:FindFirstChild("CharacterBillboard")
    
    if not bbg then
        if lastState.bbgFound ~= false then
            logMsg("⚠️ Billboard não encontrado na cabeça.")
            lastState.bbgFound = false
        end
        return
    end

    if lastState.bbgFound ~= true then
        logMsg("✅ Billboard rastreado com sucesso! Iniciando leitura.")
        lastState.bbgFound = true
    end

    local currentState = {
        barVisible = false,
        barFill = "N/A",
        money = "",
        job = ""
    }

    -- Procura o container da barra
    local packageBar = bbg:FindFirstChild("PackageBarFrame", true)
    if packageBar then
        currentState.barVisible = packageBar.Visible
        
        -- Se estiver visível, tenta achar a barrinha que preenche dentro dele
        if currentState.barVisible then
            for _, child in pairs(packageBar:GetChildren()) do
                if child:IsA("Frame") or child:IsA("ImageLabel") then
                    -- Grava o tamanho X (ex: 0.50 significa 50% cheio)
                    currentState.barFill = string.format("%.2f", child.Size.X.Scale)
                end
            end
        end
    end

    -- Procura os textos
    for _, child in pairs(bbg:GetChildren()) do
        if child.Name == "CriminalCharacterTextLabel" and child:IsA("TextLabel") then
            if child.Text:match("%$") then
                currentState.money = child.Text
            end
        elseif child.Name == "JobTextLabel" and child:IsA("TextLabel") then
            currentState.job = child.Text:gsub("<[^>]+>", "")
        end
    end

    -- Compara com o último estado para logar só o que mudou
    if currentState.barVisible ~= lastState.barVisible then
        logMsg("📊 PackageBarFrame Visível: " .. tostring(currentState.barVisible))
        lastState.barVisible = currentState.barVisible
    end

    -- Se a barra mudou mais de 0.05 (5%) de preenchimento, avisa no log
    if currentState.barFill ~= "N/A" and currentState.barFill ~= lastState.barFill then
        logMsg("📈 Barra Preenchimento: " .. currentState.barFill)
        lastState.barFill = currentState.barFill
    end

    if currentState.money ~= lastState.money then
        logMsg("💰 Dinheiro: " .. currentState.money)
        lastState.money = currentState.money
    end

    if currentState.job ~= lastState.job then
        logMsg("💼 Profissão/Nível: " .. currentState.job)
        lastState.job = currentState.job
    end
end

monitorBtn.MouseButton1Click:Connect(function()
    isMonitoring = not isMonitoring

    if isMonitoring then
        monitorBtn.Text = "STOP MONITOR"
        monitorBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        logMsg("🟢 Monitoramento Iniciado! Lendo cabeça 10x por segundo...")
        
        monitorLoop = task.spawn(function()
            while isMonitoring do
                scanHead()
                task.wait(0.1) -- Alta frequência
            end
        end)
    else
        monitorBtn.Text = "START MONITOR"
        monitorBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
        logMsg("🔴 Monitoramento Parado.")
        if monitorLoop then task.cancel(monitorLoop) end
    end
end)
