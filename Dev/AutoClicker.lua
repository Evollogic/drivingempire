local coreGui = game:GetService("CoreGui")
local plyrs = game:GetService("Players")
local uis = game:GetService("UserInputService")
local lp = plyrs.LocalPlayer

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
title.Text = "GUI Inspector (Spy)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14

local toggleBtn = Instance.new("TextButton", mainFrame)
toggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
toggleBtn.Position = UDim2.new(0.1, 0, 0, 35)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
toggleBtn.Text = "SPY MODE: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 12
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

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
termTitle.Text = "📟 Inspector Logs"
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

logMsg("Inspector GUI loaded. Turn ON and click a button!")

termCopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(table.concat(allLogs, "\n"))
        termCopyBtn.Text = "OK!"
        task.wait(1)
        termCopyBtn.Text = "COPY"
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

local isSpying = false

toggleBtn.MouseButton1Click:Connect(function()
    isSpying = not isSpying

    if isSpying then
        toggleBtn.Text = "SPY MODE: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        logMsg("🟢 Modo Espião LIGADO! Pegando TODOS os elementos visuais...")
    else
        toggleBtn.Text = "SPY MODE: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        logMsg("🔴 Modo Espião DESLIGADO!")
    end
end)

uis.InputBegan:Connect(function(input, gameProcessed)
    if not isSpying then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local pos = input.Position
        local guisDetectadas = lp.PlayerGui:GetGuiObjectsAtPosition(pos.X, pos.Y)

        if #guisDetectadas > 0 then
            logMsg("------ CLIQUE DETECTADO ------")
            local layersExibidas = 0

            for _, alvo in ipairs(guisDetectadas) do
                -- Ignora o nosso próprio menu para não poluir
                if not alvo:FindFirstAncestor("DevClickerUI") then
                    layersExibidas = layersExibidas + 1
                    -- Mostra se é Frame, ImageLabel, TextLabel, etc.
                    logMsg("[" .. layersExibidas .. "] 🔎 " .. alvo.Name .. " (" .. alvo.ClassName .. ")")
                    logMsg("📁 " .. alvo:GetFullName())
                    
                    -- LIMITE REMOVIDO: Agora ele vai mostrar tudo, mesmo que tenha 10 frames sobrepostos!
                end
            end
        end
    end
end)
