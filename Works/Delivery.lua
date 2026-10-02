local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local lp = players.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

if getgenv().DeliveryLoop then
    pcall(task.cancel, getgenv().DeliveryLoop)
end

getgenv().AutoFarmDelivery, getgenv().JobPhase = true, "Init"

-- =========================================================================
-- SISTEMA DE LOGS (SOMENTE CONSOLE F9)
-- =========================================================================
local function logMsg(msg)
    print(os.date("%H:%M:%S") .. " | " .. tostring(msg))
end

logMsg("Script carregado. Aguardando eventos...")

-- =========================================================================
-- FUNÇÕES DE SUPORTE
-- =========================================================================
local function rWait(min, max)
    task.wait(math.random(min * 10, max * 10) / 10)
end

local function fRem(n,...)
    local r = remotes:FindFirstChild(n)
    if not r then return end
    if r:IsA("RemoteEvent") then
        pcall(r.FireServer, r, ...)
    elseif r:IsA("RemoteFunction") then
        task.spawn(pcall, r.InvokeServer, r, ...)
    end
end

local function getChar()
    local c = lp.Character
    return c, (c and c:FindFirstChild("HumanoidRootPart")), (c and c:FindFirstChild("Humanoid"))
end

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
                pcall(function()
                    conn.Function({UserInputType = Enum.UserInputType.Touch, UserInputState = estado})
                end)
            end
        end
    end
end

-- =========================================================================
-- FUNÇÃO DE TELEPORTE SMART COM FORCE-HOLD E NOCLIP
-- =========================================================================
local function SmartTeleport(targetPos, isDelivery)
    logMsg("--- INICIANDO SMART TELEPORT ---")
    logMsg("Alvo Pos: " .. tostring(targetPos))

    local c, rt, hum = getChar()
    local car = nil

    if hum and hum.SeatPart then
        local seatModel = hum.SeatPart:FindFirstAncestorWhichIsA("Model")
        if seatModel and seatModel ~= c then
            car = seatModel
        end
    end

    if car then
        logMsg("Modo: VEÍCULO. Carro detectado: " .. car.Name)
        local cPart = car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart", true)
        local allVehicleParts = cPart:GetConnectedParts(true)
        local currentPivot = car:GetPivot()

        local flatCurrent = Vector3.new(currentPivot.Position.X, 0, currentPivot.Position.Z)
        local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
        local dir = Vector3.new(1, 0, 0)

        local dist = (flatCurrent - flatTarget).Magnitude
        logMsg("Distância 2D até o alvo: " .. string.format("%.2f", dist))

        if dist > 1 then
            dir = (flatCurrent - flatTarget).Unit
        end

        local startPos = Vector3.new(targetPos.X + (dir.X * 80), targetPos.Y + 5, targetPos.Z + (dir.Z * 80))
        local lookAt = Vector3.new(targetPos.X, startPos.Y, targetPos.Z)
        local destCFrame = CFrame.new(startPos, lookAt)

        logMsg("Calculado Destino CFrame: " .. tostring(startPos))

        local estadosColisao = {}

        logMsg("Aplicando Ghost Mode no Veículo...")
        for _, p in pairs(allVehicleParts) do
            estadosColisao[p] = p.CanCollide
            local n = p.Name:lower()
            if not (n:match("wheel") or n:match("tire") or n:match("rim") or n:match("suspension") or n:match("whl")) then
                p.CanCollide = false
            end
        end

        logMsg("Aplicando Force-Hold (Zerando inércia por 15 frames)...")
        for i = 1, 15 do
            car:PivotTo(destCFrame)
            for _, p in pairs(allVehicleParts) do
                p.AssemblyLinearVelocity = Vector3.zero
                p.AssemblyAngularVelocity = Vector3.zero
            end
            task.wait()
        end

        logMsg("Force-Hold concluído. Física estabilizada.")

        simularBotao("Left", false)
        simularBotao("Right", false)
        simularBotao("Throttle", true)

        local timeOut = 0
        while timeOut < 6 do
            local currentDist = (cPart.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude
            if currentDist < 15 then
                logMsg("Chegou no alvo de condução (Dist < 15). Trava acionada.")
                break
            end
            timeOut = timeOut + task.wait(0.1)
        end

        simularBotao("Throttle", false)
        simularBotao("Brake", true)
        task.wait(0.8)
        simularBotao("Brake", false)

        logMsg("Restaurando colisões normais...")
        for _, p in pairs(allVehicleParts) do
            if estadosColisao[p] ~= nil then
                p.CanCollide = estadosColisao[p]
            end
        end
        logMsg("--- FIM DO TELEPORTE (VEÍCULO) ---")
    else
        logMsg("Modo: A PÉ. Calculando Raycast...")
        if rt and hum then
            local outOffset = Vector3.new(30, 0, 0)
            local approachPosCenter = targetPos + outOffset

            local rayOrigin = approachPosCenter + Vector3.new(0, 200, 0)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {c}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            local rayResult = ws:Raycast(rayOrigin, Vector3.new(0, -400, 0), raycastParams)

            local startPos = approachPosCenter + Vector3.new(0, 10, 0)
            if rayResult then
                startPos = rayResult.Position + Vector3.new(0, 3, 0)
                logMsg("Raycast acertou: " .. rayResult.Instance.Name .. " em " .. tostring(rayResult.Position))
            else
                logMsg("AVISO: Raycast falhou em encontrar chão! Usando fallback Y+10.")
            end

            rt.Velocity = Vector3.zero
            rt.CFrame = CFrame.new(startPos)
            hum.PlatformStand = false
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.Freefall)

            -- Inicia o Noclip (Sem colisão para não travar em cercas/objetos)
            logMsg("Ativando Noclip (Ghost Mode) para o personagem...")
            local noclipConnection = runService.Stepped:Connect(function()
                if c then
                    for _, v in pairs(c:GetDescendants()) do
                        if v:IsA("BasePart") then
                            v.CanCollide = false
                        end
                    end
                end
            end)

            task.wait(0.6)
            hum:ChangeState(Enum.HumanoidStateType.Running)
            hum:MoveTo(targetPos)

            local timeOut = 0
            while timeOut < 4 do
                if (rt.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude < 3.5 then
                    break
                end
                timeOut = timeOut + task.wait(0.1)
            end
            
            -- Desativa o Noclip quando chegar no destino
            if noclipConnection then
                noclipConnection:Disconnect()
                logMsg("Noclip desativado.")
            end
            
            logMsg("--- FIM DO TELEPORTE (A PÉ) ---")
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
                if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" then
                    pad = v
                    break
                end
            end
            if pad then
                logMsg("Iniciando nova rota (" .. mode .. ")")
                SmartTeleport(pad.Parent.Position, false)
                rWait(1, 1.5); fRem("RequestStartJobSession", "Delivery", "jobPad", mode)
                rWait(1, 1.5); fRem("AttemptDeliveryPickup")
                rWait(7, 16); getgenv().JobPhase = "Farming"
            else
                task.wait(2)
            end
        elseif getgenv().JobPhase == "Farming" then
            local t = ws:FindFirstChild("DeliveryTargetAnchor")
            if t and t.Parent == ws then
                SmartTeleport(t.Position, true)
                for i = 1, 2 do
                    fRem("AttemptDeliveryComplete"); task.wait(0.5)
                end
                rWait(1, 5); fRem("AttemptDeliveryPickup")
                rWait(7, 16)
            else
                task.wait(1)
            end
        end
    end
end)
