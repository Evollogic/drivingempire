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
-- Apenas CARROS deslizam e caem perto do chão (+4). 
-- BONECOS a pé continuam com a queda antiga de +50 metros.
-- =========================================================================
local function SmartTeleport(targetPos, isDelivery)
    local c, rt, hum = getChar()
    local vFolder = ws:FindFirstChild("Vehicles")
    local car = vFolder and vFolder:FindFirstChild(lp.Name) or ws:FindFirstChild(lp.Name)

    if car then
        -- REGRA APENAS PARA CARRO (Mais perto do chão e deslizando)
        local finalPos = targetPos + Vector3.new(0, 4, 0)
        local approachPos = isDelivery and (finalPos + Vector3.new(50, 0, 0)) or finalPos
        
        local destCFrame = CFrame.new(approachPos)
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

        local plat = Instance.new("Part")
        plat.Size = Vector3.new(300, 10, 300)
        plat.Position = approachPos - Vector3.new(0, 7, 0)
        plat.Anchored = true
        plat.Transparency = 1 
        plat.Parent = ws

        for _, p in pairs(partsToMove) do
            estados[p] = p.Anchored
            p.Anchored = true
            p.Velocity, p.RotVelocity = Vector3.zero, Vector3.zero
        end

        for _, p in pairs(partsToMove) do
            p.CFrame = delta * p.CFrame
        end

        task.wait(0.3)

        if isDelivery then
            local finalDelta = CFrame.new(finalPos) * CFrame.new(approachPos):Inverse()
            for _, p in pairs(partsToMove) do
                p.CFrame = finalDelta * p.CFrame
            end
            task.wait(0.1)
        end

        for p, state in pairs(estados) do
            if p and p.Parent then
                p.Anchored = state
                p.Velocity, p.RotVelocity = Vector3.zero, Vector3.zero
            end
        end
        
        task.spawn(function()
            task.wait(0.5)
            if plat then plat:Destroy() end
        end)
    else
        -- REGRA PARA BONECO (Sem Carro) -> Mantém o teu script original de queda alta
        if rt then
            rt.Velocity, rt.AssemblyLinearVelocity = Vector3.zero, Vector3.zero
            if isDelivery then
                -- Cai 50m acima e ligeiramente de lado
                rt.CFrame = CFrame.new(targetPos + Vector3.new(10, 50, 10))
            else
                -- Cai reto 50m acima (no Job Pad)
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
                -- false = não precisa "deslizar" (só apanhar trabalho)
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
                -- true = avisa a função que isto é a zona de entrega (desliza o carro se estiver a usar um)
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
