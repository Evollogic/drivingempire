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
-- Carros: Teleporte baixo (+3) em cima de uma plataforma plana que dura 10s.
-- Bonecos: Queda normal (+50).
-- =========================================================================
local function SmartTeleport(targetPos, isDelivery)
    local c, rt, hum = getChar()
    local vFolder = ws:FindFirstChild("Vehicles")
    local car = vFolder and vFolder:FindFirstChild(lp.Name) or ws:FindFirstChild(lp.Name)

    if car then
        -- FINAL POS: Muito perto do chão
        local finalPos = targetPos + Vector3.new(0, 3, 0)
        
        local destCFrame = CFrame.new(finalPos)
        local currentPivot = car:GetPivot()
        local delta = destCFrame * currentPivot:Inverse()

        local partsToMove = {}
        local estados = {}

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

        -- Cria plataforma plana gigante para evitar o relevo do mapa
        local plat = Instance.new("Part")
        plat.Size = Vector3.new(150, 4, 150)
        plat.Position = targetPos - Vector3.new(0, 2, 0) -- Fica exatamente sob os pneus
        plat.Anchored = true
        plat.Transparency = 1 
        plat.Parent = ws

        -- Congela Física
        for _, p in pairs(partsToMove) do
            estados[p] = p.Anchored
            p.Anchored = true
            p.Velocity, p.RotVelocity = Vector3.zero, Vector3.zero
        end

        -- Teleporta tudo (Carro + Charrete) para cima da plataforma
        for _, p in pairs(partsToMove) do
            p.CFrame = delta * p.CFrame
        end

        -- Tempo rápido para carregar o mapa (0.3s)
        task.wait(0.3)

        -- Descongela Física (agora vão pousar suavemente na plataforma invisível)
        for p, state in pairs(estados) do
            if p and p.Parent then
                p.Anchored = state
                p.Velocity, p.RotVelocity = Vector3.zero, Vector3.zero
            end
        end
        
        -- O SEGREDO: A plataforma fica lá durante 10 segundos!
        -- Assim o carro fica 100% parado sem rolar com o relevo durante a entrega.
        task.spawn(function()
            task.wait(10)
            if plat then plat:Destroy() end
        end)
    else
        -- REGRA PARA BONECO (Sem Carro)
        if rt then
            rt.Velocity, rt.AssemblyLinearVelocity = Vector3.zero, Vector3.zero
            if isDelivery then
                rt.CFrame = CFrame.new(targetPos + Vector3.new(10, 50, 10))
            else
                rt.CFrame = CFrame.new(targetPos + Vector3.new(0, 50, 0))
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
