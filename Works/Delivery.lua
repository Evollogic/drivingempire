local ws,rs,lp=game:GetService("Workspace"),game:GetService("ReplicatedStorage"),game:GetService("Players").LocalPlayer
local remotes=rs:WaitForChild("Remotes")

if getgenv().DeliveryLoop then pcall(task.cancel,getgenv().DeliveryLoop) end
getgenv().AutoFarmDelivery,getgenv().JobPhase=true,"Init"

-- Função de Randomização para evitar Anti-Cheat (ex: 7.4s, 14.2s, 3.1s)
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
-- FUNÇÃO DE TELEPORTE INTELIGENTE (CARRO + CHARRETE ou APENAS BONECO)
-- =========================================================================
local function SmartTeleport(targetPos)
    local c, rt, hum = getChar()
    local vFolder = ws:FindFirstChild("Vehicles")
    local car = vFolder and vFolder:FindFirstChild(lp.Name) or ws:FindFirstChild(lp.Name)

    if car then
        -- TEM CARRO: Aplica as Regras do Raio Curto e Plataforma Anti-Void
        local destCFrame = CFrame.new(targetPos)
        local currentPivot = car:GetPivot()
        local delta = destCFrame * currentPivot:Inverse()

        local partsToMove = {}
        local estados = {}

        -- Raio Curto (35 studs) de CAPTURA (O teleporte viaja para o mapa todo)
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

        -- Cria plataforma de segurança (totalmente invisível para o farm)
        local plat = Instance.new("Part")
        plat.Size = Vector3.new(300, 10, 300)
        plat.Position = targetPos - Vector3.new(0, 10, 0)
        plat.Anchored = true
        plat.Transparency = 1 
        plat.Parent = ws

        -- Congela Física
        for _, p in pairs(partsToMove) do
            estados[p] = p.Anchored
            p.Anchored = true
            p.Velocity, p.RotVelocity = Vector3.zero, Vector3.zero
        end

        -- Teleporta Tudo Junto
        for _, p in pairs(partsToMove) do
            p.CFrame = delta * p.CFrame
        end

        -- TEMPO DE CÉU BEM BAIXO (0.25 segundos para o mapa renderizar)
        task.wait(0.25)

        -- Descongela Física
        for p, state in pairs(estados) do
            if p and p.Parent then
                p.Anchored = state
                p.Velocity, p.RotVelocity = Vector3.zero, Vector3.zero
            end
        end
        
        -- Apaga plataforma limpadamente após o carro assentar
        task.spawn(function()
            task.wait(0.5)
            if plat then plat:Destroy() end
        end)
    else
        -- SEM CARRO: Regra antiga, teleporta só o boneco
        if rt then
            rt.Velocity, rt.AssemblyLinearVelocity = Vector3.zero, Vector3.zero
            rt.CFrame = CFrame.new(targetPos)
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
                -- Teleporta com offset de +15 para cima (reduzido de 50 para evitar capotamento)
                SmartTeleport(pad.Parent.Position + Vector3.new(0, 15, 0))
                
                rWait(1, 1.5)
                fRem("RequestStartJobSession", "Delivery", "jobPad", mode)
                rWait(1, 1.5)
                fRem("AttemptDeliveryPickup")
                
                -- Coleta inicial aleatória (7 a 16 segundos)
                rWait(7, 16)
                getgenv().JobPhase="Farming"
            end
            
        elseif getgenv().JobPhase=="Farming" then
            local t = ws:FindFirstChild("DeliveryTargetAnchor")
            
            if t and t.Parent == ws then
                -- Vai para o DeliveryTargetAnchor (usando +15 no eixo Y)
                SmartTeleport(t.Position + Vector3.new(10, 15, 10))
                
                -- Fica forçando a entrega
                for i = 1, 2 do
                    fRem("AttemptDeliveryComplete")
                    task.wait(0.5)
                end
                
                -- Entrega aleatória (1 a 5 segundos)
                rWait(1, 5)

                -- Pede a próxima caixa de longe
                fRem("AttemptDeliveryPickup")

                -- Coleta da próxima caixa aleatória (7 a 16 segundos)
                rWait(7, 16)
            end
        end
    end
end)
