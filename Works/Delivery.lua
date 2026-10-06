local plyrs = game:GetService("Players")
local lp = plyrs.LocalPlayer
local rs = game:GetService("RunService")
local ws = game:GetService("Workspace")
local rep = game:GetService("ReplicatedStorage")
local remotes = rep:WaitForChild("Remotes")
local pfs = game:GetService("PathfindingService")

repeat task.wait(0.5) until game:IsLoaded()
repeat task.wait(0.5) until lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")

local function logMsg(msg)
    if getgenv().LogMsg then getgenv().LogMsg(msg) else print("Delivery: " .. tostring(msg)) end
end

logMsg("Motor V40: Pad OBRIGATÓRIO! Atalho fantasma removido. Física anti-queda da V39 mantida.")
task.wait(6)

pcall(function() ws.FallenPartsDestroyHeight = -50000 end)

if getgenv().DeliveryLoop then pcall(task.cancel, getgenv().DeliveryLoop) end
if getgenv().NoclipLoop then getgenv().NoclipLoop:Disconnect() end
if getgenv().AntiSeatLoop then getgenv().AntiSeatLoop:Disconnect() end
if getgenv().AntiAfkConnection then getgenv().AntiAfkConnection:Disconnect() end
if getgenv().AntiAfkLoop then pcall(task.cancel, getgenv().AntiAfkLoop) end
if getgenv().AntiVoidLoop then getgenv().AntiVoidLoop:Disconnect() end

getgenv().AutoFarmDelivery = true
getgenv().JobPhase = "Init" 
getgenv().LastAnchor = nil
getgenv().NoAnchorTicks = 0
local badTargets = {}

local vu = game:GetService("VirtualUser")
local vim = game:GetService("VirtualInputManager")

getgenv().AntiAfkConnection = lp.Idled:Connect(function()
    if getgenv().AutoFarmDelivery then
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end
end)

getgenv().AntiAfkLoop = task.spawn(function()
    while task.wait(480) do
        if getgenv().AutoFarmDelivery then
            vim:SendKeyEvent(true, Enum.KeyCode.F15, false, game)
            task.wait(0.1)
            vim:SendKeyEvent(false, Enum.KeyCode.F15, false, game)
        end
    end
end)

getgenv().AntiSeatLoop = game:GetService("RunService").Heartbeat:Connect(function()
    if not getgenv().AutoFarmDelivery then return end
    local c = lp.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        local rt = c:FindFirstChild("HumanoidRootPart")
        if hum and rt then
            if hum.Sit then
                local seatPart = hum.SeatPart
                if seatPart and not seatPart:IsA("VehicleSeat") then
                    if seatPart:FindFirstChild("SeatWeld") then seatPart.SeatWeld:Destroy() end
                    hum.Sit = false
                    rt.CFrame = rt.CFrame + Vector3.new(0, 5, 0)
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end
    end
end)

getgenv().NoclipLoop = game:GetService("RunService").Stepped:Connect(function()
    if not getgenv().AutoFarmDelivery then return end
    local c = lp.Character
    if c then
        for _, p in pairs(c:GetChildren()) do
            if p:IsA("BasePart") then
                local n = p.Name
                if n ~= "HumanoidRootPart" and not n:match("Leg") and not n:match("Foot") then
                    p.CanCollide = false
                end
            end
        end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum and hum.SeatPart then
            local car = hum.SeatPart:FindFirstAncestorWhichIsA("Model")
            if car and car ~= c then
                for _, p in pairs(car:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end
    end
end)

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

local function lerPreenchimentoBarra()
    local c = lp.Character
    if not c then return false, 0 end
    local head = c:FindFirstChild("Head")
    if not head then return false, 0 end
    local bbg = head:FindFirstChild("CharacterBillboard")
    if not bbg then return false, 0 end

    local packageBar = bbg:FindFirstChild("PackageBarFrame", true)
    if packageBar and packageBar.Visible then
        local fill = packageBar:FindFirstChild("Fill", true)
        if fill and fill:IsA("Frame") then
            return true, fill.Size.X.Scale
        end
        return true, 0
    end
    return false, 0
end

-- =========================================================================
-- SISTEMA DE RAIO-X BLINDADO (IDENTIFICA O TERRAIN)
-- =========================================================================
local function ScanGroundRaycast(startPos)
    local rayOrigin = Vector3.new(startPos.X, startPos.Y + 800, startPos.Z)
    local rayDirection = Vector3.new(0, -1600, 0)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true

    local ignoreList = {}
    local c = lp.Character
    if c then table.insert(ignoreList, c) end
    raycastParams.FilterDescendantsInstances = ignoreList

    local result = nil
    for i = 1, 10 do
        result = ws:Raycast(rayOrigin, rayDirection, raycastParams)
        if result and result.Instance then
            if result.Instance.CanCollide and (result.Instance:IsA("Terrain") or result.Instance.Transparency < 1) then
                return result.Position, result.Instance
            else
                table.insert(ignoreList, result.Instance)
                raycastParams.FilterDescendantsInstances = ignoreList
            end
        else
            break
        end
    end

    return nil, nil
end

-- =========================================================================
-- MOTOR NAVEGADOR COM PATHFINDER NATIVO E GANCHO NO CÉU
-- =========================================================================
local function NavegarComPathfinder(targetPos, isPad, anchorRef)
    local c, rt, hum = getChar()
    if not (rt and hum) then return false end

    local flatCurrent = Vector3.new(rt.Position.X, 0, rt.Position.Z)
    local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
    local distInicial = (flatCurrent - flatTarget).Magnitude

    if distInicial > 45 then
        local dir = (flatCurrent - flatTarget).Unit
        local charOffset = math.random(35, 45)
        local safeSpotFlat = Vector3.new(targetPos.X + (dir.X * charOffset), targetPos.Y, targetPos.Z + (dir.Z * charOffset))

        logMsg("[V40-DEBUG] Distância de " .. math.floor(distInicial) .. "m. Ancorando no céu para carregar mapa...")

        rt.Velocity = Vector3.zero
        rt.CFrame = CFrame.new(safeSpotFlat + Vector3.new(0, 300, 0))
        rt.Anchored = true
        task.wait(1.5)

        local chaoPos, chaoPart = ScanGroundRaycast(safeSpotFlat)

        if chaoPos then
            logMsg("[V40-DEBUG] ✅ Chão SÓLIDO encontrado: [" .. chaoPart.Name .. "] na altura " .. math.floor(chaoPos.Y))
            rt.CFrame = CFrame.new(chaoPos + Vector3.new(0, 4, 0))
        else
            logMsg("[V40-DEBUG] ⚠ Chão não renderizou. Usando ponte gigante de emergência...")
            local tempFloor = Instance.new("Part")
            tempFloor.Anchored = true; tempFloor.CanCollide = true; tempFloor.Transparency = 1
            tempFloor.Size = Vector3.new(400, 5, 400)
            tempFloor.Position = Vector3.new(safeSpotFlat.X, targetPos.Y - 2.5, safeSpotFlat.Z)
            tempFloor.Parent = ws
            game:GetService("Debris"):AddItem(tempFloor, 15)

            rt.CFrame = CFrame.new(safeSpotFlat + Vector3.new(0, 5, 0))
        end

        task.wait(0.2)
        rt.Anchored = false
        task.wait(0.3)
    end

    hum.PlatformStand = false; hum.Sit = false; hum:ChangeState(Enum.HumanoidStateType.Running)

    local path = pfs:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true
    })

    c, rt, hum = getChar()
    local success, err = pcall(function()
        path:ComputeAsync(rt.Position, targetPos)
    end)

    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()

        for i, wp in ipairs(waypoints) do
            c, rt, hum = getChar()
            if not (rt and hum) then return false end
            if rt.Position.Y - targetPos.Y < -40 then return false end

            if not isPad and anchorRef then
                if anchorRef.Parent ~= ws then return true end

                local distToTarget = (rt.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude
                if distToTarget <= 8 then
                    fRem("AttemptDeliveryComplete")
                    fRem("AttemptDeliveryPickup")

                    local vis, pct = lerPreenchimentoBarra()
                    if vis and pct > 0 then
                        logMsg("🛑 Zona de Coleta alcançada! Fill em " .. math.floor(pct*100) .. "%. Congelando no waypoint!")
                        rt.Velocity = Vector3.zero
                        hum:MoveTo(rt.Position)

                        local tempoUltimoLog = tick()
                        while anchorRef.Parent == ws do
                            local v, p = lerPreenchimentoBarra()
                            if not v or p >= 0.99 then break end
                            task.wait(0.1)
                        end
                        logMsg("✅ Coleta 100% concluída!")
                        return true
                    end
                end
            end

            if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
            hum:MoveTo(wp.Position)

            local moveOut = 0
            while moveOut < 40 do
                c, rt, hum = getChar()
                if not (rt and hum) then break end
                if (rt.Position * Vector3.new(1,0,1) - wp.Position * Vector3.new(1,0,1)).Magnitude <= 3.5 then break end
                moveOut = moveOut + 1
                task.wait(0.1)
            end
        end

        c, rt, hum = getChar()
        if hum and rt then rt.Velocity = Vector3.zero; hum:MoveTo(rt.Position) end
        return true

    else
        logMsg("⚠️ Caminho normal bloqueado ou falhou. Teleportando acima do alvo e caindo...")
        c, rt, hum = getChar()
        if not (rt and hum) then return false end

        rt.Velocity = Vector3.zero
        rt.CFrame = CFrame.new(targetPos + Vector3.new(0, 300, 0))
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.Freefall)

        local fallTimeout = 0
        while fallTimeout < 80 do 
            c, rt, hum = getChar()
            if not (rt and hum) then return false end
            
            if not isPad and anchorRef then
                if anchorRef.Parent ~= ws then return true end
                
                local distFlat = (rt.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude
                local distY = math.abs(rt.Position.Y - targetPos.Y)
                
                if distFlat <= 15 and distY <= 15 then
                    fRem("AttemptDeliveryComplete")
                    fRem("AttemptDeliveryPickup")

                    local vis, pct = lerPreenchimentoBarra()
                    if vis and pct > 0 then
                        rt.Velocity = Vector3.zero
                        hum:MoveTo(rt.Position)
                        while anchorRef.Parent == ws do
                            local v, p = lerPreenchimentoBarra()
                            if not v or p >= 0.99 then break end
                            task.wait(0.1)
                        end
                        return true
                    end
                end
            end
            fallTimeout = fallTimeout + 1
            task.wait(0.1)
        end
        return false
    end
end

-- =========================================================================
-- LOOP PRINCIPAL DO FARM
-- =========================================================================
getgenv().DeliveryLoop = task.spawn(function()
    while task.wait(0.2) do
        if not getgenv().AutoFarmDelivery then break end

        -- VERIFICAÇÃO DE MORTE E AFK/DESPAWN
        local charC, charRt, charHum = getChar()
        
        if not charC or not charHum or not charRt then
            logMsg("💀 ALERTA: Personagem não encontrado! Motivo: AFK, Despawn ou Carregando.")
            task.wait(2)
            continue
        end

        if charHum.Health <= 0 then
            logMsg("💀 ALERTA: O Bot MORREU! Motivo: Vida zerada (Foi esmagado, atropelado ou deu Reset).")
            getgenv().JobPhase = "Init" 
            task.wait(5)
            continue
        end

        if charRt.Position.Y < -500 then
            logMsg("💀 ALERTA: O Bot MORREU! Motivo: Caiu no Void (Abaixo do mapa).")
            getgenv().JobPhase = "Init"
            task.wait(5)
            continue
        end

        if getgenv().JobPhase == "Init" then
            getgenv().NoAnchorTicks = 0
            local modeStr = getgenv().DeliveryMode
            local mode = (modeStr == "Hard" or modeStr == "HighRisk") and "HighRisk" or "Safe"
            local pad = nil

            for _,v in pairs(ws:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" then pad = v; break end
            end

            if pad then
                local padPos = pad.Parent.Position
                local c, rt, hum = getChar()
                local dist = rt and (rt.Position * Vector3.new(1,0,1) - padPos * Vector3.new(1,0,1)).Magnitude or 999

                if dist > 6 then
                    logMsg("🚶 Caminhando para o pad (Iniciando trabalho)...")
                    NavegarComPathfinder(padPos, true, nil)
                end

                c, rt, hum = getChar()
                if hum and rt then hum:MoveTo(rt.Position) end

                logMsg("📍 No Pad! Assinando o trabalho...")
                fRem("RequestStartJobSession", "Delivery", "jobPad", mode)
                task.wait(0.5)
                fRem("AttemptDeliveryPickup")

                getgenv().JobPhase = "Farming"
                task.wait(1.5)
            else
                task.wait(2)
            end

        elseif getgenv().JobPhase == "Farming" then
            local t = ws:FindFirstChild("DeliveryTargetAnchor")

            if not t or t.Parent ~= ws then
                getgenv().NoAnchorTicks = getgenv().NoAnchorTicks + 1
                
                if getgenv().NoAnchorTicks > 8 then 
                    logMsg("⚠️ Rota/Alvo não encontrados! Bot perdeu o serviço. Ativando o serviço de novo...")
                    getgenv().JobPhase = "Init"
                    getgenv().NoAnchorTicks = 0
                end
                
                getgenv().LastAnchor = nil
                task.wait(0.5)
                continue
            end

            getgenv().NoAnchorTicks = 0

            if badTargets[t] and (tick() - badTargets[t] < 10) then
                task.wait(0.5)
                continue
            end

            if t ~= getgenv().LastAnchor then
                logMsg("[V40-DEBUG] Despachando para a entrega...")
                getgenv().LastAnchor = t

                local sucesso = NavegarComPathfinder(t.Position, false, t)

                if sucesso then
                    local tempoCasa = math.random(30, 50) / 10
                    logMsg("📦 Sucesso! Próximo em " .. tempoCasa .. "s...")
                    task.wait(tempoCasa)
                else
                    logMsg("⚠️ Caminhada falhou ou travou. Resetando alvo...")
                    badTargets[t] = tick()
                    getgenv().LastAnchor = nil
                    task.wait(2)
                end
            end
        end
    end
end)
