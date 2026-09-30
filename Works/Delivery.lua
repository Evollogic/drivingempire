local ws,rs,lp=game:GetService("Workspace"),game:GetService("ReplicatedStorage"),game:GetService("Players").LocalPlayer
local remotes=rs:WaitForChild("Remotes")

if getgenv().DeliveryLoop then pcall(task.cancel,getgenv().DeliveryLoop) end
getgenv().AutoFarmDelivery,getgenv().JobPhase=true,"Init"

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

local function getChar()
    local c = lp.Character
    return c, (c and c:FindFirstChild("HumanoidRootPart")), (c and c:FindFirstChild("Humanoid"))
end

-- =========================================================================
-- FUNÇÃO DE TELEPORTE (CORREÇÃO DA STATE MACHINE DO HUMANOID)
-- =========================================================================
local function SmartTeleport(targetPos, isDelivery)
    local c, rt, hum = getChar()
    local vFolder = ws:FindFirstChild("Vehicles")
    local car = vFolder and vFolder:FindFirstChild(lp.Name) or ws:FindFirstChild(lp.Name)

    if car then
        -- REGRAS DO CARRO MANTIDAS
        local approachPos = targetPos + Vector3.new(60, 5, 0)
        local finalPos = targetPos + Vector3.new(0, 5, 0)
        
        local currentPivot = car:GetPivot()
        local destCFrame = CFrame.new(approachPos)
        local delta = destCFrame * currentPivot:Inverse()

        local modelsToMove = {car}
        for _, obj in pairs(ws:GetChildren()) do
            if obj:IsA("Model") and obj ~= car and obj ~= c then
                if not obj:FindFirstChild("Humanoid") then
                    local pPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                    if pPart and not pPart.Anchored then
                        if (pPart.Position - currentPivot.Position).Magnitude <= 35 then
                            table.insert(modelsToMove, obj)
                        end
                    end
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

        local plat = Instance.new("Part")
        plat.Size = Vector3.new(150, 5, 150)
        plat.Position = targetPos - Vector3.new(0, 2.5, 0)
        plat.Anchored = true
        plat.Transparency = 1 
        plat.Parent = ws

        local estadosColisao = {}
        for _, p in pairs(partsToMove) do
            estadosColisao[p] = p.CanCollide
            p.CanCollide = false
            p.Anchored = true
            p.Velocity = Vector3.zero
            p.RotVelocity = Vector3.zero
        end

        for _, p in pairs(partsToMove) do
            p.CFrame = delta * p.CFrame
        end

        task.wait(1)

        local slideSteps = 20
        if isDelivery then
            for vez = 1, 3 do
                local stepIn = (finalPos - approachPos) / slideSteps
                for i = 1, slideSteps do
                    for _, p in pairs(partsToMove) do p.CFrame = p.CFrame + stepIn end
                    task.wait()
                end
                task.wait(0.3)
                
                if vez < 3 then
                    local stepOut = (approachPos - finalPos) / slideSteps
                    for i = 1, slideSteps do
                        for _, p in pairs(partsToMove) do p.CFrame = p.CFrame + stepOut end
                        task.wait()
                    end
                    task.wait(0.3)
                end
            end
        else
            local stepIn = (finalPos - approachPos) / slideSteps
            for i = 1, slideSteps do
                for _, p in pairs(partsToMove) do p.CFrame = p.CFrame + stepIn end
                task.wait()
            end
        end

        for _, p in pairs(partsToMove) do
            if p and p.Parent then
                p.Anchored = false
                if estadosColisao[p] ~= nil then p.CanCollide = estadosColisao[p] end
                p.Velocity = Vector3.zero
                p.RotVelocity = Vector3.zero
            end
        end
        
        task.spawn(function()
            task.wait(5)
            if plat then plat:Destroy() end
        end)
    else
        -- =====================================================================
        -- REGRAS DO BONECO (STATE MACHINE FIX & WALK)
        -- =====================================================================
        if rt and hum then
            local outOffset = Vector3.new(30, 0, 0)
            local approachPosCenter = targetPos + outOffset
            
            local rayOrigin = approachPosCenter + Vector3.new(0, 200, 0)
            local rayDirection = Vector3.new(0, -400, 0)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {c}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            
            local rayResult = ws:Raycast(rayOrigin, rayDirection, raycastParams)
            -- Mete 5 studs acima para garantir que ele "cai" no chão
            local startPos = approachPosCenter + Vector3.new(0, 10, 0)
            if rayResult then
                startPos = rayResult.Position + Vector3.new(0, 5, 0)
            end
            
            -- 1. Teleporta e para a velocidade
            rt.Velocity = Vector3.zero
            rt.CFrame = CFrame.new(startPos)
            
            -- 2. RESET DO ESTADO DO HUMANOID
            hum.PlatformStand = false
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.Freefall) -- Diz ao jogo que está a cair
            
            -- 3. Espera o boneco bater no chão de verdade
            task.wait(0.6)
            
            -- 4. FORÇA O ESTADO DE CORRIDA! Isto liga a animação das pernas.
            hum:ChangeState(Enum.HumanoidStateType.Running)
            
            local function ForceWalk(destination)
                hum:MoveTo(destination)
                local timeOut = 0
                while timeOut < 4 do -- Espera até 4 segundos para chegar
                    local dist = (rt.Position * Vector3.new(1,0,1) - destination * Vector3.new(1,0,1)).Magnitude
                    if dist < 3.5 then break end
                    timeOut = timeOut + task.wait(0.1)
                end
            end
            
            if isDelivery then
                for vez = 1, 3 do
                    ForceWalk(targetPos)
                    task.wait(0.3)
                    
                    if vez < 3 then
                        ForceWalk(startPos)
                        task.wait(0.3)
                    end
                end
            else
                ForceWalk(targetPos)
            end
        end
    end
end
-- =========================================================================

getgenv().DeliveryLoop=task.spawn(function()
    while task.wait(0.5) do
        if not getgenv().AutoFarmDelivery then break end
        
        if getgenv().JobPhase=="Init" then
            local mode = (getgenv().DeliveryMode == "Hard") and "HighRisk" or "Safe"
            local pad=nil
            for _,v in pairs(ws:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name=="JobPadPrompt" then
                    pad=v
                    break
                end
            end
            
            if pad then
                SmartTeleport(pad.Parent.Position, false)
                rWait(1, 1.5)
                fRem("RequestStartJobSession", "Delivery", "jobPad", mode)
                rWait(1, 1.5)
                fRem("AttemptDeliveryPickup")
                rWait(7, 16)
                getgenv().JobPhase="Farming"
            end
            
        elseif getgenv().JobPhase=="Farming" then
            local t = ws:FindFirstChild("DeliveryTargetAnchor")
            if t and t.Parent == ws then
                SmartTeleport(t.Position, true)
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
