local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local lp = players.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

if getgenv().DeliveryLoop then
    pcall(task.cancel, getgenv().DeliveryLoop)
end

getgenv().AutoFarmDelivery, getgenv().JobPhase = true, "Init"

-- =========================================================================
-- SISTEMA DE DEBUG UI (LOGS NA TELA)
-- =========================================================================
local coreGui = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or lp.PlayerGui
if coreGui:FindFirstChild("DeliveryDebug") then
    coreGui.DeliveryDebug:Destroy()
end

local sg = Instance.new("ScreenGui", coreGui)
sg.Name = "DeliveryDebug"

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 350, 0, 450)
main.Position = UDim2.new(1, -360, 0.5, -225)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(100, 100, 100)
main.Active = true
main.Draggable = true

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = " Terminal de Debug - Delivery"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.Code

local scroll = Instance.new("ScrollingFrame", main)
scroll.Size = UDim2.new(1, -10, 1, -80)
scroll.Position = UDim2.new(0, 5, 0, 35)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
scroll.ScrollBarThickness = 6

local list = Instance.new("UIListLayout", scroll)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 2)

local copyBtn = Instance.new("TextButton", main)
copyBtn.Size = UDim2.new(1, -10, 0, 35)
copyBtn.Position = UDim2.new(0, 5, 1, -40)
copyBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.Font = Enum.Font.Code
copyBtn.Text = "COPIAR TODOS OS LOGS"

local allLogs = {}

local function logMsg(msg)
    local t = os.date("%H:%M:%S") .. " | " .. tostring(msg)
    table.insert(allLogs, t)
    
    local txt = Instance.new("TextLabel", scroll)
    txt.Size = UDim2.new(1, 0, 0, 0)
    txt.AutomaticSize = Enum.AutomaticSize.Y
    txt.BackgroundTransparency = 1
    txt.TextColor3 = Color3.fromRGB(200, 200, 200)
    txt.TextSize = 12
    txt.Font = Enum.Font.Code
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextWrapped = true
    txt.Text = t
    
    scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteWindowSize.Y + 9999)
    print(t)
end

copyBtn.MouseButton1Click:Connect(function()
    local str = table.concat(allLogs, "\n")
    if setclipboard then
        setclipboard(str)
        copyBtn.Text = "COPIADO PARA A ÁREA DE TRANSFERÊNCIA!"
        copyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
        task.wait(2)
        copyBtn.Text = "COPIAR TODOS OS LOGS"
        copyBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
    else
        copyBtn.Text = "ERRO: setclipboard INEXISTENTE"
        copyBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        task.wait(2)
        copyBtn.Text = "COPIAR TODOS OS LOGS"
        copyBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
    end
end)

logMsg("Interface carregada. Aguardando eventos...")

-- =========================================================================
-- FUNÇÕES DE SUPORTE
-- =========================================================================
local function rWait(min, max)
    task.wait(math.random(min * 10, max * 10) / 10)
end

local function fRem(n,...)
    local r = remotes:FindFirstChild(n)
    if not r then return end
    if r:IsA("RemoteEvent") then
        pcall(r.FireServer, r, ...)
    elseif r:IsA("RemoteFunction") then
        task.spawn(pcall, r.InvokeServer, r, ...)
    end
end

local function getChar()
    local c = lp.Character
    return c, (c and c:FindFirstChild("HumanoidRootPart")), (c and c:FindFirstChild("Humanoid"))
end

local function simularBotao(nomeBotao, pressionar)
    local btn = lp.PlayerGui:FindFirstChild(nomeBotao, true)
    if btn then
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local centroX = btn.AbsolutePosition.X + (btn.AbsoluteSize.X / 2)
            local centroY = btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y / 2)
            vim:SendMouseButtonEvent(centroX, centroY, 0, pressionar, game, 0)
        end)
        if getconnections then
            local estado = pressionar and Enum.UserInputState.Begin or Enum.UserInputState.End
            for _, conn in pairs(getconnections(pressionar and btn.InputBegan or btn.InputEnded)) do
                pcall(function()
                    conn.Function({UserInputType = Enum.UserInputType.Touch, UserInputState = estado})
                end)
            end
        end
    end
end

-- =========================================================================
-- FUNÇÃO DE TELEPORTE SMART
-- =========================================================================
local function SmartTeleport(targetPos, isDelivery)
    logMsg("--- INICIANDO SMART TELEPORT ---")
    logMsg("Alvo Pos: " .. tostring(targetPos))
    
    local c, rt, hum = getChar()
    local car = nil
    
    if hum and hum.SeatPart then
        local seatModel = hum.SeatPart:FindFirstAncestorWhichIsA("Model")
        if seatModel and seatModel ~= c then
            car = seatModel
        end
    end

    if car then
        logMsg("Modo: VEÍCULO. Carro detectado: " .. car.Name)
        local cPart = car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart", true)
        local allVehicleParts = cPart:GetConnectedParts(true)
        local currentPivot = car:GetPivot()
        
        local flatCurrent = Vector3.new(currentPivot.Position.X, 0, currentPivot.Position.Z)
        local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
        local dir = Vector3.new(1, 0, 0)
        
        local dist = (flatCurrent - flatTarget).Magnitude
        logMsg("Distância 2D até o alvo: " .. string.format("%.2f", dist))
        
        if dist > 1 then
            dir = (flatCurrent - flatTarget).Unit
        end
        
        -- Adicionado +5 de margem para as rodas não nascerem dentro do asfalto
        local startPos = Vector3.new(targetPos.X + (dir.X * 80), targetPos.Y + 5, targetPos.Z + (dir.Z * 80))
        local lookAt = Vector3.new(targetPos.X, startPos.Y, targetPos.Z)
        local destCFrame = CFrame.new(startPos, lookAt)
        
        logMsg("Calculado Destino CFrame: " .. tostring(startPos))
        
        local estadosColisao = {}
        
        logMsg("Aplicando Ghost Mode e anulando velocidades...")
        for _, p in pairs(allVehicleParts) do
            estadosColisao[p] = p.CanCollide
            local n = p.Name:lower()
            -- Proteção expandida para rodas
            if not (n:match("wheel") or n:match("tire") or n:match("rim") or n:match("suspension") or n:match("whl")) then
                p.CanCollide = false
            end
            p.AssemblyLinearVelocity = Vector3.zero
            p.AssemblyAngularVelocity = Vector3.zero
        end
        
        logMsg("Executando PivotTo (Sem Anchored)...")
        car:PivotTo(destCFrame)
        
        -- Pausa mínima para o servidor registrar o teleporte antes de ligar o motor
        task.wait(0.2)
        
        -- Mata qualquer inércia residual após o teleporte
        for _, p in pairs(allVehicleParts) do
            p.AssemblyLinearVelocity = Vector3.zero
            p.AssemblyAngularVelocity = Vector3.zero
        end
        
        logMsg("Física estável. Iniciando condução...")
        
        simularBotao("Left", false)
        simularBotao("Right", false)
        simularBotao("Throttle", true)
        
        local timeOut = 0
        while timeOut < 6 do
            local currentDist = (cPart.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude
            if currentDist < 15 then 
                logMsg("Chegou no alvo de condução (Dist < 15). Trava acionada.")
                break 
            end
            timeOut = timeOut + task.wait(0.1)
        end
        
        simularBotao("Throttle", false)
        simularBotao("Brake", true)
        task.wait(0.8)
        simularBotao("Brake", false)
        
        logMsg("Restaurando colisões normais...")
        for _, p in pairs(allVehicleParts) do
            if estadosColisao[p] ~= nil then
                p.CanCollide = estadosColisao[p]
            end
        end
        logMsg("--- FIM DO TELEPORTE (VEÍCULO) ---")
    else
        logMsg("Modo: A PÉ. Calculando Raycast...")
        if rt and hum then
            local outOffset = Vector3.new(30, 0, 0)
            local approachPosCenter = targetPos + outOffset
            
            local rayOrigin = approachPosCenter + Vector3.new(0, 200, 0)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {c}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            local rayResult = ws:Raycast(rayOrigin, Vector3.new(0, -400, 0), raycastParams)
            
            local startPos = approachPosCenter + Vector3.new(0, 10, 0)
            if rayResult then
                startPos = rayResult.Position + Vector3.new(0, 3, 0)
                logMsg("Raycast acertou: " .. rayResult.Instance.Name .. " em " .. tostring(rayResult.Position))
            else
                logMsg("AVISO: Raycast falhou em encontrar chão! Usando fallback Y+10.")
            end
            
            rt.Velocity = Vector3.zero
            rt.CFrame = CFrame.new(startPos)
            hum.PlatformStand = false
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
            
            task.wait(0.6)
            hum:ChangeState(Enum.HumanoidStateType.Running)
            hum:MoveTo(targetPos)
            
            local timeOut = 0
            while timeOut < 4 do
                if (rt.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude < 3.5 then
                    break
                end
                timeOut = timeOut + task.wait(0.1)
            end
            logMsg("--- FIM DO TELEPORTE (A PÉ) ---")
        end
    end
end

-- =========================================================================
-- LOOP DA ENTREGA
-- =========================================================================
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
                logMsg("Iniciando nova rota (" .. mode .. ")")
                SmartTeleport(pad.Parent.Position, false)
                rWait(1, 1.5); fRem("RequestStartJobSession", "Delivery", "jobPad", mode)
                rWait(1, 1.5); fRem("AttemptDeliveryPickup")
                rWait(7, 16); getgenv().JobPhase = "Farming"
            else
                task.wait(2)
            end
        elseif getgenv().JobPhase == "Farming" then
            local t = ws:FindFirstChild("DeliveryTargetAnchor")
            if t and t.Parent == ws then
                SmartTeleport(t.Position, true)
                for i = 1, 2 do
                    fRem("AttemptDeliveryComplete"); task.wait(0.5)
                end
                rWait(1, 5); fRem("AttemptDeliveryPickup")
                rWait(7, 16)
            else
                task.wait(1)
            end
        end
    end
end)
