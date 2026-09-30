local ws,rs,lp=game:GetService("Workspace"),game:GetService("ReplicatedStorage"),game:GetService("Players").LocalPlayer
local remotes=rs:WaitForChild("Remotes")

if getgenv().DeliveryLoop then pcall(task.cancel,getgenv().DeliveryLoop) end
getgenv().AutoFarmDelivery,getgenv().JobPhase=true,"Init"

-- Função de Randomização
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
-- FUNÇÃO DE TELEPORTE INTELIGENTE
-- Carros: Aparece a +60 e faz uma "Queda Controlada" (deslizando reto) até +3.
-- Bonecos: Queda normal de +60.
-- =========================================================================
local function SmartTeleport(targetPos, isDelivery)
    local c, rt, hum = getChar()
    local vFolder = ws:FindFirstChild("Vehicles")
    local car = vFolder and vFolder:FindFirstChild(lp.Name) or ws:FindFirstChild(lp.Name)

    if car then
        local startHeight = 60
        local endHeight = 3
        local fallDistance = startHeight - endHeight
        
        -- Posição inicial no céu
        local finalPos = targetPos + Vector3.new(0, startHeight, 0)
        
        local destCFrame = CFrame.new(finalPos)
        local currentPivot = car:GetPivot()
        local delta = destCFrame * currentPivot:Inverse()

        local partsToMove = {}
        local estados = {}

        -- Captura Carro + Charrete (Raio de 35)
        for _, p in pairs(ws:GetDescendants()) do
            if p:IsA("BasePart") and not p.Anchored then
                local dist = (p.Position - currentPivot.Position).Magnitude
                if dist <= 35 then
                    local model = p:FindFirstAncestorWhichIsA("Model")
                    local isOther = false
                    if model and model:FindFirstChild("Humanoid") and model ~= c then
                        isOther = true
                    end
                    if not isOther then
                        table.insert(partsToMove, p)
                    end
                end
            end
        end

        -- Cria plataforma plana gigante no chão para receber o carro
        local plat = Instance.new("Part")
        plat.Size = Vector3.new(150, 4, 150)
        plat.Position = targetPos - Vector3.new(0, 2, 0)
        plat.Anchored = true
        plat.Transparency = 1 
        plat.Parent = ws

        -- Congela Física
        for _, p in pairs(partsToMove) do
            estados[p] = p.Anchored
            p.Anchored = true
            p.Velocity, p.RotVelocity = Vector3.zero, Vector3.zero
        end

        -- 1. Teleporta para o céu (+60)
        for _, p in pairs(partsToMove) do
            p.CFrame = delta * p.CFrame
        end

        -- Espera um bocadinho para o mapa renderizar lá em baixo
        task.wait(0.3)

        -- 2. QUEDA CONTROLADA (Deslizando em linha reta para baixo)
        -- Descemos o carro suavemente ao longo de 35 passos
        local steps = 35
        local dropPerStep = fallDistance / steps
        for i = 1, steps do
            for _, p in pairs(partsToMove) do
                p.CFrame = p.CFrame - Vector3.new(0, dropPerStep, 0)
            end
            task.wait() -- Pausa de 1 frame para criar o efeito visual de deslize
        end

        -- 3. Descongela Física (agora vão pousar suavemente na plataforma)
        for p, state in pairs(estados) do
            if p and p.Parent then
                p.Anchored = state
                p.Velocity, p.RotVelocity = Vector3.zero, Vector3.zero
            end
        end
        
        -- A plataforma fica lá durante 10 segundos!
        task.spawn(function()
            task.wait(10)
            if plat then plat:Destroy() end
        end)
    else
        -- REGRA PARA BONECO (Sem Carro) cai direto de +60
        if rt then
            rt.Velocity, rt.AssemblyLinearVelocity = Vector3.zero, Vector3.zero
            if isDelivery then
                rt.CFrame = CFrame.new(targetPos + Vector3.new(10, 60, 10))
            else
                rt.CFrame = CFrame.new(targetPos + Vector3.new(0, 60, 0))
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
