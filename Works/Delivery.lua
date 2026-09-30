local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local lp = players.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

if getgenv().DeliveryLoop then pcall(task.cancel, getgenv().DeliveryLoop) end
getgenv().AutoFarmDelivery, getgenv().JobPhase = true, "Init"

-- =========================================================================
-- INTERFACE DE LOG (UI LOGGER)
-- =========================================================================
local coreGui = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or lp:WaitForChild("PlayerGui")
if coreGui:FindFirstChild("DeliveryLogger") then
    coreGui.DeliveryLogger:Destroy()
end

local sg = Instance.new("ScreenGui", coreGui)
sg.Name = "DeliveryLogger"

local logFrame = Instance.new("Frame", sg)
logFrame.Size = UDim2.new(0, 350, 0, 250)
logFrame.Position = UDim2.new(1, -360, 0, 10)
logFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
logFrame.BorderSizePixel = 0
logFrame.Active = true
logFrame.Draggable = true

local UICorner = Instance.new("UICorner", logFrame)
UICorner.CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel", logFrame)
title.Size = UDim2.new(1, -100, 0, 30)
title.BackgroundTransparency = 1
title.Text = " 📜 Logs de Condução Mobile"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left

local copyBtn = Instance.new("TextButton", logFrame)
copyBtn.Size = UDim2.new(0, 90, 0, 20)
copyBtn.Position = UDim2.new(1, -95, 0, 5)
copyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.Text = "COPIAR LOG"
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 10
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 4)

local scroll = Instance.new("ScrollingFrame", logFrame)
scroll.Size = UDim2.new(1, -10, 1, -40)
scroll.Position = UDim2.new(0, 5, 0, 35)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local uiList = Instance.new("UIListLayout", scroll)
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding = UDim.new(0, 2)

local fullLogText = ""
local logCount = 0

local function addLog(msg)
    local timeStr = os.date("%H:%M:%S")
    local finalMsg = "[" .. timeStr .. "] " .. msg
    fullLogText = fullLogText .. finalMsg .. "\n"
    logCount = logCount + 1
    
    local txt = Instance.new("TextLabel", scroll)
    txt.Size = UDim2.new(1, 0, 0, 16)
    txt.BackgroundTransparency = 1
    txt.Text = finalMsg
    txt.TextColor3 = Color3.fromRGB(200, 200, 200)
    txt.Font = Enum.Font.Code
    txt.TextSize = 11
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.LayoutOrder = logCount
    
    scroll.CanvasSize = UDim2.new(0, 0, 0, logCount * 18)
    scroll.CanvasPosition = Vector2.new(0, scroll.CanvasSize.Y.Offset)
end

copyBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then
            setclipboard(fullLogText)
            copyBtn.Text = "COPIADO!"
            task.wait(1.5)
            copyBtn.Text = "COPIAR LOG"
        end
    end)
end)

addLog("Sistema de Logs Iniciado!")

-- =========================================================================
-- ESPIÃO DE INTERFACE MOBILE (UI SPY)
-- =========================================================================
local function monitorarBotao(obj)
    if obj:IsA("GuiButton") or obj:IsA("ImageButton") or obj:IsA("TextButton") then
        obj.InputBegan:Connect(function(input)
            -- Filtra para registar apenas toques na tela do telemóvel ou cliques
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                local pai = obj.Parent and obj.Parent.Name or "N/A"
                addLog("🕹️️ TOCOU NO BOTÃO: " .. obj.Name .. " (Pasta: " .. pai .. ")")
            end
        end)
    end
end

-- Monitora todos os botões que já existem na tela
for _, obj in pairs(lp.PlayerGui:GetDescendants()) do
    monitorarBotao(obj)
end

-- Se o jogo criar o botão do acelerador SÓ quando entras no carro, isto apanha-o!
lp.PlayerGui.DescendantAdded:Connect(function(obj)
    monitorarBotao(obj)
end)

-- =========================================================================
-- LOOP DA ENTREGA (SÓ COMO SUPORTE)
-- =========================================================================
local function rWait(min, max)
    task.wait(math.random(min * 10, max * 10) / 10)
end

local function fRem(n,...)
    local r=remotes:FindFirstChild(n)
    if not r then return end
    if r:IsA("RemoteEvent") then
        pcall(r.FireServer,r,...)
    elseif r:IsA("RemoteFunction") then
        task.spawn(pcall,r.InvokeServer,r,...)
    end
end

getgenv().DeliveryLoop = task.spawn(function()
    while task.wait(0.5) do
        if not getgenv().AutoFarmDelivery then break end
        
        if getgenv().JobPhase == "Init" then
            local mode = (getgenv().DeliveryMode == "Hard") and "HighRisk" or "Safe"
            local pad = nil
            for _,v in pairs(ws:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" then
                    pad = v
                    break
                end
            end
            
            if pad then
                rWait(1, 1.5)
                fRem("RequestStartJobSession", "Delivery", "jobPad", mode)
                rWait(1, 1.5)
                fRem("AttemptDeliveryPickup")
                rWait(7, 16)
                getgenv().JobPhase = "Farming"
            end
            
        elseif getgenv().JobPhase == "Farming" then
            local t = ws:FindFirstChild("DeliveryTargetAnchor")
            if t and t.Parent == ws then
                for i = 1, 2 do
                    fRem("AttemptDeliveryComplete")
                    task.wait(0.5)
                end
                rWait(1, 5)
                fRem("AttemptDeliveryPickup")
                rWait(7, 16)
            end
        end
    end
end)
