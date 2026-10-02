local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local lp = players.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

if getgenv().DeliveryLoop then
    pcall(task.cancel, getgenv().DeliveryLoop)
end
if getgenv().NoclipLoop then
    getgenv().NoclipLoop:Disconnect()
end

getgenv().AutoFarmDelivery = true
getgenv().JobPhase = "Init"

-- =========================================================================
-- INTEGRAÇÃO COM OS LOGS DO HUB
-- =========================================================================
local function logMsg(msg)
    if getgenv().LogMsg then
        getgenv().LogMsg(msg)
    else
        print("Delivery: " .. tostring(msg))
    end
end

logMsg("Anti-Fling Engine loaded. Waiting for events...")

-- =========================================================================
-- SISTEMA NOCLIP CONTÍNUO (GHOST MODE)
-- =========================================================================
getgenv().NoclipLoop = game:GetService("RunService").Stepped:Connect(function()
    if not getgenv().AutoFarmDelivery then return end
    local c = lp.Character
    if c then
        for _, p in pairs(c:GetChildren()) do
            if p:IsA("BasePart") and (p.Name == "Torso" or p.Name == "UpperTorso" or p.Name == "LowerTorso" or p.Name == "Head") then
                p.CanCollide = false
            end
        end
    end
end)

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
-- FUNÇÃO DE TELEPORTE SMART COM FORCE-HOLD
-- =========================================================================
local function SmartTeleport(targetPos, isDelivery)
    logMsg("--- STARTING SMART TELEPORT ---")
    logMsg("Target Pos: " .. tostring(targetPos))

    local c, rt, hum = getChar()
    local car = nil

    if hum and hum.SeatPart then
        local seatModel = hum.SeatPart:FindFirstAncestorWhichIsA("Model")
        if seatModel and seatModel ~= c then
            car = seatModel
        end
    end

    if car then
        logMsg("Mode: VEHICLE. Car detected: " .. car.Name)
        local cPart = car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart", true)
        local allVehicleParts = cPart:GetConnectedParts(true)
        local currentPivot = car:GetPivot()

        local flatCurrent = Vector3.new(currentPivot.Position.X, 0, currentPivot.Position.Z)
        local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
        local dir = Vector3.new(1, 0, 0)

        local dist = (flatCurrent - flatTarget).Magnitude
        logMsg("2D Distance to target: " .. string.format("%.2f", dist))

        if dist > 1 then
            dir = (flatCurrent - flatTarget).Unit
        end

        local startPos = Vector3.new(targetPos.X + (dir.X * 25), targetPos.Y + 5, targetPos.Z + (dir.Z * 25))
        local lookAt = Vector3.new(targetPos.X, startPos.Y, targetPos.Z)
        local destCFrame = CFrame.new(startPos, lookAt)

        logMsg("Calculated Destination CFrame: " .. tostring(startPos))

        local estadosColisao = {}

        logMsg("Applying Ghost Mode...")
        for _, p in pairs(allVehicleParts) do
            estadosColisao[p] = p.CanCollide
            local n = p.Name:lower()
            if not (n:match("wheel") or n:match("tire") or n:match("rim") or n:match("suspension") or n:match("whl")) then
                p.CanCollide = false
            end
        end

        logMsg("Applying Force-Hold (Zeroing inertia for 15 frames)...")
        for i = 1, 15 do
            car:PivotTo(destCFrame)
            for _, p in pairs(allVehicleParts) do
                p.AssemblyLinearVelocity = Vector3.zero
                p.AssemblyAngularVelocity = Vector3.zero
            end
            task.wait()
        end

        logMsg("Force-Hold complete. Physics stabilized.")

        simularBotao("Left", false)
        simularBotao("Right", false)
        simularBotao("Throttle", true)

        local timeOut = 0
        while timeOut < 6 do
            for _, p in pairs(allVehicleParts) do
                local n = p.Name:lower()
                if not (n:match("wheel") or n:match("tire") or n:match("rim") or n:match("suspension") or n:match("whl")) then
                    p.CanCollide = false
                end
            end

            local currentDist = (cPart.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude
            if currentDist < 15 then
                logMsg("Reached driving target (Dist < 15). Lock activated.")
                break
            end
            timeOut = timeOut + task.wait(0.1)
        end

        simularBotao("Throttle", false)
        simularBotao("Brake", true)
        task.wait(0.8)
        simularBotao("Brake", false)

        logMsg("Restoring normal collisions...")
        for _, p in pairs(allVehicleParts) do
            if estadosColisao[p] ~= nil then
                p.CanCollide = estadosColisao[p]
            end
        end
        logMsg("--- END TELEPORT (VEHICLE) ---")
    else
        logMsg("Mode: ON FOOT. Calculating Raycast...")
        if rt and hum then
            local outOffset = Vector3.new(3, 0, 0)
            local approachPosCenter = targetPos + outOffset

            local rayOrigin = approachPosCenter + Vector3.new(0, 200, 0)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {c}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            local rayResult = ws:Raycast(rayOrigin, Vector3.new(0, -400, 0), raycastParams)

            local startPos = approachPosCenter + Vector3.new(0, 10, 0)
            if rayResult then
                startPos = rayResult.Position + Vector3.new(0, 3, 0)
                logMsg("Raycast hit: " .. rayResult.Instance.Name .. " at " .. tostring(rayResult.Position))
            else
                logMsg("WARNING: Raycast failed to find floor! Using fallback Y+10.")
            end

            rt.Velocity = Vector3.zero
            rt.CFrame = CFrame.new(startPos)
            hum.PlatformStand = false
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.Freefall)

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
            logMsg("--- END TELEPORT (ON FOOT) ---")
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
            local modeStr = getgenv().DeliveryMode
            local mode = (modeStr == "Hard" or modeStr == "HighRisk") and "HighRisk" or "Safe"

            local pad = nil
            for _,v in pairs(ws:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" then
                    pad = v
                    break
                end
            end
            if pad then
                logMsg("Starting new route (" .. mode .. ")")
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
                
                -- ENTREGA EXPRESSA (Máximo de 1 segundo de intervalo)
                fRem("AttemptDeliveryComplete")
                task.wait(0.2)
                fRem("AttemptDeliveryComplete") -- Dispara de novo por garantia
                task.wait(0.3)
                
                -- Coleta a próxima caixa
                fRem("AttemptDeliveryPickup")
                task.wait(0.5) 
            else
                task.wait(1)
            end
        end
    end
end)
