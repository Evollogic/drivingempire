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

-- =========================================================================
-- SIMULADOR DE BOTÕES (VIRTUAL INPUT)
-- =========================================================================
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
-- FUNÇÃO DE TELEPORTE HÍBRIDA (ALTURA SEGURA DO ALVO)
-- =========================================================================
local function SmartTeleport(targetPos, isDelivery)
    local c, rt, hum = getChar()
    local car = nil
    
    if hum and hum.SeatPart then
        local seatModel = hum.SeatPart:FindFirstAncestorWhichIsA("Model")
        if seatModel and seatModel ~= c then
            car = seatModel
        end
    end

    if car then
        -- ==========================================
        -- REGRAS DO CARRO (SEM VOAR PARA O CÉU)
        -- ==========================================
        local cPart = car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart", true)
        local allVehicleParts = cPart:GetConnectedParts(true)
        local currentPivot = car:GetPivot()
        
        -- Calcula a direção horizontal exata até ao alvo
        local flatCurrent = Vector3.new(currentPivot.Position.X, 0, currentPivot.Position.Z)
        local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
        local dir = Vector3.new(1, 0, 0)
        if (flatCurrent - flatTarget).Magnitude > 1 then
            dir = (flatCurrent - flatTarget).Unit
        end
        
        -- POSIÇÃO SEGURA: Usa a mesma altura (Y) do alvo de entrega, afastado 80 metros
        local startPos = Vector3.new(targetPos.X + (dir.X * 80), targetPos.Y + 4, targetPos.Z + (dir.Z * 80))
        local lookAt = Vector3.new(targetPos.X, startPos.Y, targetPos.Z)
        local destCFrame = CFrame.new(startPos, lookAt)
        
        -- GHOST MODE: Desativa colisão da lataria, mantendo as rodas ativas no chão
        local estadosColisao = {}
        for _, p in pairs(allVehicleParts) do
            estadosColisao[p] = p.CanCollide
            local n = p.Name:lower()
            if not (n:match("wheel") or n:match("tire") or n:match("rim") or n:match("suspension")) then
                p.CanCollide = false
            end
            -- Para a inércia do carro para não voar rodopiando
            p.AssemblyLinearVelocity = Vector3.zero
            p.AssemblyAngularVelocity = Vector3.zero
        end
        
        -- FIX DO BUG DO CÉU: Move o carro inteiro como um bloco rígido (não quebra as constraints)
        car:PivotTo(destCFrame)
        
        task.wait(0.5)
        
        -- Condução automática em linha reta
        simularBotao("Left", false)
        simularBotao("Right", false)
        simularBotao("Throttle", true)
        
        local timeOut = 0
        while timeOut < 6 do
            local dist = (cPart.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude
            if dist < 15 then break end
            timeOut = timeOut + task.wait(0.1)
        end
        
        -- Chegou ao centro: Trava!
        simularBotao("Throttle", false)
        simularBotao("Brake", true)
        task.wait(0.8)
        simularBotao("Brake", false)
        
        -- Restaura a colisão normal
        for _, p in pairs(allVehicleParts) do
            if estadosColisao[p] ~= nil then
                p.CanCollide = estadosColisao[p]
            end
            p.AssemblyLinearVelocity = Vector3.zero
            p.AssemblyAngularVelocity = Vector3.zero
        end
    else
        -- ==========================================
        -- REGRAS A PÉ (FUNCIONANDO 100%)
        -- ==========================================
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
