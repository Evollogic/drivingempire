local plyrs = game:GetService("Players")
local lp = plyrs.LocalPlayer
local rs = game:GetService("RunService")

local uiParent = lp:WaitForChild("PlayerGui")

for _, v in pairs(uiParent:GetChildren()) do
    if v.Name == "DevClickerUI" then v:Destroy() end
end

local sg = Instance.new("ScreenGui")
sg.Name = "DevClickerUI"
sg.Parent = uiParent

local allLogs = {}

local mainFrame = Instance.new("Frame", sg)
mainFrame.Size = UDim2.new(0, 200, 0, 140)
mainFrame.Position = UDim2.new(0.5, -450, 0.5, -50)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.Active = true
mainFrame.Draggable = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", mainFrame).Color = Color3.fromRGB(0, 255, 255)

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "3D Monitor Bruto"
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
termFrame.Size = UDim2.new(0, 500, 0, 400)
termFrame.Position = UDim2.new(0.5, -200, 0.5, -100)
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
termTitle.Text = "📟 Logs de Força Bruta"
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

logMsg("Monitor V3: Modo Força Bruta Ativado (Spamming liberado)")

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

local isMonitoring = false
local monitorLoop = nil

-- Função de varredura bruta (Cuspir tudo sem filtro)
local function scanBruteForce()
    local char = lp.Character
    if not char then logMsg("⏳ Aguardando Character...") return end
    
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    local bbg = head:FindFirstChild("CharacterBillboard")
    if not bbg then 
        logMsg("⚠️ CharacterBillboard NÃO ESTÁ na cabeça no momento.") 
        return 
    end
    
    logMsg("--- 🔍 VARREDURA DO BILLBOARD ---")
    local itensEncontrados = 0
    
    for _, desc in pairs(bbg:GetDescendants()) do
        if desc:IsA("Frame") or desc:IsA("ImageLabel") then
            -- Exemplo de saida: "🔳 FillBar | {0.5, 0}, {1, 0} | Vis: true"
            logMsg("🔳 " .. desc.Name .. " | " .. tostring(desc.Size) .. " | Vis: " .. tostring(desc.Visible))
            itensEncontrados = itensEncontrados + 1
        elseif desc:IsA("TextLabel") then
            logMsg("💬 " .. desc.Name .. " | Texto: " .. desc.Text)
            itensEncontrados = itensEncontrados + 1
        end
    end
    
    if itensEncontrados == 0 then
        logMsg("⚠️ O Billboard foi encontrado, mas está totalmente VAZIO!")
    end
end

monitorBtn.MouseButton1Click:Connect(function()
    isMonitoring = not isMonitoring

    if isMonitoring then
        monitorBtn.Text = "STOP MONITOR"
        monitorBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        logMsg("🟢 MODO FORÇA BRUTA LIGADO! Varrendo a cada 1.5s...")
        
        monitorLoop = task.spawn(function()
            while isMonitoring do
                scanBruteForce()
                task.wait(1.5)
            end
        end)
    else
        monitorBtn.Text = "START MONITOR"
        monitorBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
        logMsg("🔴 Monitoramento Parado.")
        if monitorLoop then task.cancel(monitorLoop) end
    end
end)
