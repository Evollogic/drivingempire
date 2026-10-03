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
if getgenv().AntiSeatLoop then
    getgenv().AntiSeatLoop:Disconnect()
end

getgenv().AutoFarmDelivery = true
getgenv().JobPhase = "Init"
getgenv().LastAnchor = nil

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

logMsg("Anti-Fling & Anti-Sit Engine loaded. Waiting for events...")

-- =========================================================================
-- SISTEMA ANTI-SENTADA E ANTI-TRAVA (EMERGÊNCIA)
-- =========================================================================
local stuckTick = 0
getgenv().AntiSeatLoop = game:GetService("RunService").Heartbeat:Connect(function()
    if not getgenv().AutoFarmDelivery then return end
    local c = lp.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then
            if hum.Sit then
                local seatPart = hum.SeatPart
                local isDrivingCar = false
                if seatPart then
                    local model = seatPart:FindFirstAncestorWhichIsA("Model")
                    if model and model ~= c then
                        isDrivingCar = true
                    end
                end

                if not isDrivingCar then
                    hum.Sit = false
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                    stuckTick = stuckTick + 1
                    if stuckTick > 120 then
                        logMsg("WARNING: Character stuck sitting! Forcing emergency reset...")
                        hum.Health = 0
                        stuckTick = 0
                    end
                else
                    stuckTick = 0
                end
            else
                stuckTick = 0
            end
        end
    end
end)

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
    local waitTime = math.random(min * 100, max * 100) / 100
    task.wait(waitTime)
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

        local carOffset = math.random(85, 100)
        local startPos = Vector3.new(targetPos.X + (dir.X * carOffset), targetPos.Y + 5, targetPos.Z + (dir.Z * carOffset))
        local lookAt = Vector3.new(targetPos.X, startPos.Y, targetPos.Z)
        local destCFrame = CFrame.new(startPos, lookAt)

        logMsg("Calculated Destination CFrame (Offset: " .. carOffset .. "): " .. tostring(startPos))

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
        logMsg("Mode: ON FOOT. Creating invisible floor...")
        if rt and hum then
            local charOffset = math.random(35, 45)
            local startPos = Vector3.new(targetPos.X + charOffset, targetPos.Y + 3.5, targetPos.Z)

            local tempFloor = Instance.new("Part")
            tempFloor.Name = "DeliveryGhostFloor"
            tempFloor.Anchored = true
            tempFloor.CanCollide = true
            tempFloor.Transparency = 1
            tempFloor.Size = Vector3.new(200, 2, 200)
            tempFloor.Position = Vector3.new(targetPos.X, targetPos.Y - 1, targetPos.Z)
            tempFloor.Parent = ws

            logMsg("Invisible floor created matching target exact Y: " .. tostring(targetPos.Y))

            rt.Velocity = Vector3.zero
            rt.CFrame = CFrame.new(startPos)
            hum.PlatformStand = false
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.Freefall)

            task.wait(0.2)
            hum:ChangeState(Enum.HumanoidStateType.Running)
            hum:MoveTo(targetPos)

            local timeOut = 0
            while timeOut < 4 do
                if (rt.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude < 4.5 then
                    break
                end
                timeOut = timeOut + task.wait(0.1)
            end
            
            tempFloor:Destroy()
            logMsg("--- END TELEPORT (ON FOOT) ---")
        end
    end
end

-- =========================================================================
-- LOOP DA ENTREGA
-- =========================================================================
getgenv().DeliveryLoop = task.spawn(function()
    while task.wait(0.2) do
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
                logMsg("Moving to center to start route (" .. mode .. ")...")
                SmartTeleport(pad.Parent.Position, false)
                
                fRem("RequestStartJobSession", "Delivery", "jobPad", mode)
                task.wait(0.5)
                fRem("AttemptDeliveryPickup")
                
                -- TEMPO DE COLETA REAL (Entre 9 e 12 segundos)
                local selectedWait = math.random(90, 120) / 10
                logMsg("Arrived at center. Collection timer STARTED: " .. selectedWait .. "s")
                
                local startTime = tick()
                task.wait(selectedWait)
                local endTime = tick()
                local timePassed = endTime - startTime
                
                logMsg("✅ Timer FINISHED! Time passed: " .. string.format("%.2f", timePassed) .. " seconds")
                
                getgenv().JobPhase = "Farming"
            else
                task.wait(2)
            end
            
        elseif getgenv().JobPhase == "Farming" then
            local t = ws:FindFirstChild("DeliveryTargetAnchor")
            if t and t.Parent == ws then
                if t ~= getgenv().LastAnchor then
                    SmartTeleport(t.Position, true)
                    
                    fRem("AttemptDeliveryComplete")
                    task.wait(0.2)
                    fRem("AttemptDeliveryComplete")
                    task.wait(0.3)
                    
                    fRem("AttemptDeliveryPickup")
                    getgenv().LastAnchor = t
                    
                    task.spawn(function()
                        task.wait(2.0)
                        if getgenv().LastAnchor == t then
                            getgenv().LastAnchor = nil
                        end
                    end)
                end
            else
                task.wait(0.1)
            end
        end
    end
end)
