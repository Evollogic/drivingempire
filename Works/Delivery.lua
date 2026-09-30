local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local lp = players.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

if getgenv().DeliveryLoop then pcall(task.cancel, getgenv().DeliveryLoop) end
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
    if r:IsA("RemoteEvent") then pcall(r.FireServer, r, ...)
    elseif r:IsA("RemoteFunction") then task.spawn(pcall, r.InvokeServer, r, ...) end
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
                pcall(function() conn.Function({UserInputType = Enum.UserInputType.Touch, UserInputState = estado}) end)
            end
        end
    end
end

-- =========================================================================
-- FUNÇÃO DE TELEPORTE HÍBRIDA (CARRO FÍSICO E A PÉ)
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
        -- REGRAS DO CARRO (FÍSICA REAL NO CHÃO)
        -- ==========================================
        local currentPivot = car:GetPivot()
        
        -- Descobre a direção ideal baseada de onde tu vens para evitar teleporte dentro de prédios
        local flatCurrent = Vector3.new(currentPivot.Position.X, 0, currentPivot.Position.Z)
        local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
        local dir = Vector3.new(1, 0, 0)
        if (flatCurrent - flatTarget).Magnitude > 1 then
            dir = (flatCurrent - flatTarget).Unit
        end
        
        local approachPosCenter = targetPos + (dir * 90) -- 90 metros de distância
        
        -- Usa Raycast para colar o carro ao chão real!
        local rayOrigin = approachPosCenter + Vector3.new(0, 300, 0)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {c, car} 
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local rayResult = ws:Raycast(rayOrigin, Vector3.new(0, -600, 0), raycastParams)
        local startPos = approachPosCenter + Vector3.new(0, 10, 0)
        if rayResult then 
            startPos = rayResult.Position + Vector3.new(0, 4, 0) -- Colado ao chão
        end
        
        local lookAt = Vector3.new(targetPos.X, startPos.Y, targetPos.Z)
        local destCFrame = CFrame.new(startPos, lookAt)
        local delta = destCFrame * currentPivot:Inverse()

        -- Captura TODAS as peças num raio GIGANTE (100 studs) para apanhar a charrete/vagão
        local partsToMove = {}
        local processed = {}
        local partsInRadius = ws:GetPartBoundsInRadius(currentPivot.Position, 100)
        
        for _, p in pairs(partsInRadius) do
            if p:IsA("BasePart") and not p.Anchored then
                local model = p:FindFirstAncestorWhichIsA("Model")
                if model and model:FindFirstChild("Humanoid") and model ~= c then
                    continue -- Ignora outros jogadores
                end
                if not processed[p] then
                    table.insert(partsToMove, p)
                    processed[p] = true
                end
            end
        end

        -- Teleporta tudo instantaneamente para o chão
        for _, p in pairs(partsToMove) do 
            p.Velocity, p.RotVelocity = Vector3.zero, Vector3.zero
            p.CFrame = delta * p.CFrame 
        end

        -- Espera o carro e a charrete assentarem na gravidade
        task.wait(1.5)

        -- Simula Condução Real (deixa o motor atuar para sofrer o relevo)
        simularBotao("Throttle", true)
        
        -- Monitoriza a viagem física até chegar ao destino
        local timeOut = 0
        while timeOut < 6 do
            local dist = (car:GetPivot().Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude
            if dist < 20 then break end
            timeOut = timeOut + task.wait(0.1)
        end

        -- Chegou à meta: Trava!
        simularBotao("Throttle", false)
        simularBotao("Brake", true)
        task.wait(1)
        simularBotao("Brake", false)
    else
        -- ==========================================
        -- REGRAS A PÉ (INTACTAS)
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
            if rayResult then startPos = rayResult.Position + Vector3.new(0, 3, 0) end
            
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
                if (rt.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude < 3.5 then break end
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
                if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" then pad = v break end
            end
            
            if pad then
                SmartTeleport(pad.Parent.Position, false)
                rWait(1, 1.5); fRem("RequestStartJobSession", "Delivery", "jobPad", mode)
                rWait(1, 1.5); fRem("AttemptDeliveryPickup")
                rWait(7, 16); getgenv().JobPhase = "Farming"
            else task.wait(2) end
            
        elseif getgenv().JobPhase == "Farming" then
            local t = ws:FindFirstChild("DeliveryTargetAnchor")
            if t and t.Parent == ws then
                SmartTeleport(t.Position, true)
                for i = 1, 2 do fRem("AttemptDeliveryComplete"); task.wait(0.5) end
                rWait(1, 5); fRem("AttemptDeliveryPickup")
                rWait(7, 16)
            else task.wait(1) end
        end
    end
end)
