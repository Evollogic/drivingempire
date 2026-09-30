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
-- Carros: Vai a +60m congelado (carrega mapa) -> desce a +5m congelado -> Descongela e cai 5m perfeitamente.
-- Bonecos: Cai direto de +40m.
-- =========================================================================
local function SmartTeleport(targetPos, isDelivery)
    local c, rt, hum = getChar()
    local vFolder = ws:FindFirstChild("Vehicles")
    local car = vFolder and vFolder:FindFirstChild(lp.Name) or ws:FindFirstChild(lp.Name)

    if car then
        local currentPivot = car:GetPivot()
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

        -- PASSO 1: Vai para o céu (+60m) para carregar o mapa sem risco de colisão
        local highPos = targetPos + Vector3.new(0, 60, 0)
        local deltaHigh = CFrame.new(highPos) * currentPivot:Inverse()
        for _, p in pairs(partsToMove) do
            p.CFrame = deltaHigh * p.CFrame
        end

        task.wait(0.5) -- Tempo para o Roblox processar e renderizar o chão lá em baixo

        -- PASSO 2: Desce congelado até mesmo acima da zona (+5m)
        local lowPos = targetPos + Vector3.new(0, 5, 0)
        local deltaLow = CFrame.new(lowPos) * CFrame.new(highPos):Inverse()
        for _, p in pairs(partsToMove) do
            p.CFrame = deltaLow * p.CFrame
        end

        task.wait(0.1) -- Estabiliza antes da queda

        -- PASSO 3: Solta a física (Queda mínima de 5 metros)! Aterra perfeito e ativa hitbox!
        for p, state in pairs(estados) do
            if p and p.Parent then
                p.Anchored = state
                p.Velocity = Vector3.zero
                p.RotVelocity = Vector3.zero
            end
        end
        
        -- A plataforma fica lá durante 10 segundos
        task.spawn(function()
            task.wait(10)
            if plat then plat:Destroy() end
        end)
    else
        -- REGRA PARA BONECO (Sem Carro) -> Cai de 40 metros
        if rt then
            rt.Velocity, rt.AssemblyLinearVelocity = Vector3.zero, Vector3.zero
            if isDelivery then
                rt.CFrame = CFrame.new(targetPos + Vector3.new(10, 40, 10))
            else
                rt.CFrame = CFrame.new(targetPos + Vector3.new(0, 40, 0))
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
