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
-- FUNÇÃO DE TELEPORTE INTELIGENTE E RIGOROSO (Sem bugs de física)
-- =========================================================================
local function SmartTeleport(targetPos)
    local c, rt, hum = getChar()
    local vFolder = ws:FindFirstChild("Vehicles")
    local car = vFolder and vFolder:FindFirstChild(lp.Name) or ws:FindFirstChild(lp.Name)

    if car then
        -- Altura mínima de segurança (5 studs acima do chão)
        local finalPos = targetPos + Vector3.new(0, 5, 0)
        local destCFrame = CFrame.new(finalPos)
        local currentPivot = car:GetPivot()
        local delta = destCFrame * currentPivot:Inverse()

        local modelsToMove = {car}
        
        -- FILTRO RIGOROSO: Procura a charrete apenas nos modelos próximos, ignora peças soltas/lixo
        for _, obj in pairs(ws:GetChildren()) do
            if obj:IsA("Model") and obj ~= car and obj ~= c then
                if not obj:FindFirstChild("Humanoid") then -- Ignora outros jogadores
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

        -- Cria plataforma exata no chão do alvo (Topo da plataforma = targetPos)
        local plat = Instance.new("Part")
        plat.Size = Vector3.new(150, 5, 150)
        plat.Position = targetPos - Vector3.new(0, 2.5, 0)
        plat.Anchored = true
        plat.Transparency = 1 
        plat.Parent = ws

        -- 1. Congela a física e para toda a inércia
        for _, p in pairs(partsToMove) do
            p.Anchored = true
            p.Velocity = Vector3.zero
            p.RotVelocity = Vector3.zero
        end

        -- 2. Teleporta tudo diretamente para +5 metros
        for _, p in pairs(partsToMove) do
            p.CFrame = delta * p.CFrame
        end

        -- 3. Espera 0.5s para o mapa do jogo carregar em baixo de ti
        task.wait(0.5)

        -- 4. Descongela e zera inércia DE NOVO (Isto evita o "chute" do servidor)
        for _, p in pairs(partsToMove) do
            if p and p.Parent then
                p.Anchored = false
                p.Velocity = Vector3.zero
                p.RotVelocity = Vector3.zero
            end
        end
        
        -- Apaga plataforma ao fim de 3 segundos
        task.spawn(function()
            task.wait(3)
            if plat then plat:Destroy() end
        end)
    else
        -- REGRA PARA BONECO (Vai a pé, cai de 5m apenas)
        if rt then
            rt.Velocity, rt.AssemblyLinearVelocity = Vector3.zero, Vector3.zero
            rt.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
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
                SmartTeleport(pad.Parent.Position)
                
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
                SmartTeleport(t.Position)
                
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
