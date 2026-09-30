local ws,rs,lp=game:GetService("Workspace"),game:GetService("ReplicatedStorage"),game:GetService("Players").LocalPlayer
local remotes=rs:WaitForChild("Remotes")
local PathfindingService = game:GetService("PathfindingService")

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

local function SmartTeleport(targetPos)
    local c, rt, hum = getChar()
    local vFolder = ws:FindFirstChild("Vehicles")
    local car = vFolder and vFolder:FindFirstChild(lp.Name) or ws:FindFirstChild(lp.Name)

    if car then
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

        task.wait(1) -- Tempo extra para carregar mapa do carro

        local slideSteps = 30
        local stepVec = (finalPos - approachPos) / slideSteps
        
        for i = 1, slideSteps do
            for _, p in pairs(partsToMove) do
                p.CFrame = p.CFrame + stepVec
            end
            task.wait() 
        end

        for _, p in pairs(partsToMove) do
            if p and p.Parent then
                p.Anchored = false
                if estadosColisao[p] ~= nil then
                    p.CanCollide = estadosColisao[p]
                end
                p.Velocity = Vector3.zero
                p.RotVelocity = Vector3.zero
            end
        end
        
        task.spawn(function()
            task.wait(5)
            if plat then plat:Destroy() end
        end)
    else
        if rt and hum then
            rt.Velocity, rt.AssemblyLinearVelocity = Vector3.zero, Vector3.zero
            
            local offsetHorizontal = targetPos + Vector3.new(30, 0, 0)
            local rayOrigin = offsetHorizontal + Vector3.new(0, 200, 0)
            local rayDirection = Vector3.new(0, -400, 0)
            
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {c}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            
            -- FORÇA O BONECO A FICAR NO AR ENQUANTO O CHÃO NÃO CARREGA
            rt.CFrame = CFrame.new(rayOrigin)
            rt.Anchored = true
            
            local rayResult = nil
            local timeout = 5 -- Espera até 5 segundos o mapa renderizar
            local startTime = tick()
            
            while tick() - startTime < timeout do
                rayResult = ws:Raycast(rayOrigin, rayDirection, raycastParams)
                if rayResult then break end
                task.wait(0.2)
            end
            
            local spawnNoChao = offsetHorizontal + Vector3.new(0, 5, 0)
            if rayResult then
                spawnNoChao = rayResult.Position + Vector3.new(0, 3, 0)
            end
            
            rt.CFrame = CFrame.new(spawnNoChao)
            rt.Anchored = false -- Solta o boneco
            task.wait(0.2)
            
            local path = PathfindingService:CreatePath({
                AgentRadius = 2,
                AgentHeight = 5,
                AgentCanJump = true
            })
            
            local success, _ = pcall(function()
                path:ComputeAsync(rt.Position, targetPos)
            end)
            
            if success and path.Status == Enum.PathStatus.Success then
                local waypoints = path:GetWaypoints()
                for _, waypoint in ipairs(waypoints) do
                    if waypoint.Action == Enum.PathWaypointAction.Jump then
                        hum.Jump = true
                    end
                    hum:MoveTo(waypoint.Position)
                    
                    local timeOut = 0
                    while timeOut < 2 do
                        local dist = (rt.Position * Vector3.new(1,0,1) - waypoint.Position * Vector3.new(1,0,1)).Magnitude
                        if dist < 2.5 then break end
                        timeOut = timeOut + task.wait()
                    end
                end
            else
                hum:MoveTo(targetPos)
                task.wait(2)
            end
        end
    end
end

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
