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
-- FUNÇÃO DE TELEPORTE HÍBRIDA (CARRO E A PÉ)
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
        -- REGRAS DO CARRO
        local approachPos = targetPos + Vector3.new(100, 5, 0)
        local finalPos = targetPos + Vector3.new(0, 5, 0)
        
        local lookAt = Vector3.new(finalPos.X, approachPos.Y, finalPos.Z)
        local destCFrame = CFrame.new(approachPos, lookAt)
        local currentPivot = car:GetPivot()
        local delta = destCFrame * currentPivot:Inverse()

        local modelsToMove = {car}
        for _, obj in pairs(ws:GetChildren()) do
            if obj:IsA("Model") and obj ~= car and obj ~= c and not obj:FindFirstChild("Humanoid") then
                local pPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                if pPart and not pPart.Anchored and (pPart.Position - currentPivot.Position).Magnitude <= 35 then
                    table.insert(modelsToMove, obj)
                end
            end
        end

        local partsToMove = {}
        for _, model in pairs(modelsToMove) do
            for _, p in pairs(model:GetDescendants()) do
                if p:IsA("BasePart") and not p.Anchored then
                    table.insert(partsToMove, p)
                end
            end
        end

        local plat = Instance.new("Part", ws)
        plat.Size, plat.Position, plat.Anchored, plat.Transparency = Vector3.new(150, 5, 150), targetPos - Vector3.new(0, 2.5, 0), true, 1 

        local estadosColisao = {}
        for _, p in pairs(partsToMove) do
            estadosColisao[p] = p.CanCollide
            p.CanCollide = false
            p.Anchored = true
            p.Velocity, p.RotVelocity = Vector3.zero, Vector3.zero
        end

        for _, p in pairs(partsToMove) do p.CFrame = delta * p.CFrame end

        task.wait(1)

        -- Simula Condução
        simularBotao("Throttle", true)
        
        local frames = 150
        local stepVec = (finalPos - approachPos) / frames
        for i = 1, frames do
            for _, p in pairs(partsToMove) do p.CFrame = p.CFrame + stepVec end
            task.wait()
        end

        simularBotao("Throttle", false)
        simularBotao("Brake", true)
        task.wait(0.5)
        simularBotao("Brake", false)

        for _, p in pairs(partsToMove) do
            if p and p.Parent then
                p.Anchored = false
                if estadosColisao[p] ~= nil then p.CanCollide = estadosColisao[p] end
                p.Velocity, p.RotVelocity = Vector3.zero, Vector3.zero
            end
        end
        
        task.spawn(function() task.wait(5) if plat then plat:Destroy() end end)
    else
        -- REGRAS A PÉ
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
