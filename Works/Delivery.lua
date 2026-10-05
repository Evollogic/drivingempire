local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local lp = players.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

-- =========================================================================
-- IMUNIDADE AO VOID (Desativa a morte por queda do próprio Roblox)
-- =========================================================================
pcall(function()
    ws.FallenPartsDestroyHeight = -50000
end)

if getgenv().DeliveryLoop then
    pcall(task.cancel, getgenv().DeliveryLoop)
end
if getgenv().NoclipLoop then
    getgenv().NoclipLoop:Disconnect()
end
if getgenv().AntiSeatLoop then
    getgenv().AntiSeatLoop:Disconnect()
end
if getgenv().AntiAfkConnection then
    getgenv().AntiAfkConnection:Disconnect()
end
if getgenv().AntiAfkLoop then
    pcall(task.cancel, getgenv().AntiAfkLoop)
end
if getgenv().AntiVoidLoop then
    getgenv().AntiVoidLoop:Disconnect()
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

logMsg("Motor Corrigido: Colisão do chão mantida, sem paraquedas!")

-- =========================================================================
-- SISTEMA ANTI-AFK SUPREMO
-- =========================================================================
local vu = game:GetService("VirtualUser")
local vim = game:GetService("VirtualInputManager")

getgenv().AntiAfkConnection = lp.Idled:Connect(function()
    if getgenv().AutoFarmDelivery then
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
        logMsg("⚠️ Anti-AFK (Roblox): Simulando toque para evitar desconexão padrão.")
    end
end)

getgenv().AntiAfkLoop = task.spawn(function()
    while task.wait(480) do
        if getgenv().AutoFarmDelivery then
            vim:SendKeyEvent(true, Enum.KeyCode.F15, false, game)
            task.wait(0.1)
            vim:SendKeyEvent(false, Enum.KeyCode.F15, false, game)
            logMsg("🛡️ Anti-AFK (Jogo): Tecla fantasma (F15) simulada para manter ativo.")
        end
    end
end)

-- =========================================================================
-- SISTEMA ANTI-SENTADA SEM RESET DE VIDA
-- =========================================================================
local stuckTick = 0
getgenv().AntiSeatLoop = game:GetService("RunService").Heartbeat:Connect(function()
    if not getgenv().AutoFarmDelivery then return end
    local c = lp.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        local rt = c:FindFirstChild("HumanoidRootPart")
        if hum and rt then
            if hum.Sit then
                local seatPart = hum.SeatPart
                local isDrivingCar = false
                
                if seatPart and seatPart:IsA("VehicleSeat") then
                    isDrivingCar = true
                end

                if not isDrivingCar then
                    if seatPart then
                        local weld = seatPart:FindFirstChild("SeatWeld")
                        if weld then weld:Destroy() end
                    end
                    
                    hum.Sit = false
                    
                    stuckTick = stuckTick + 1
                    if stuckTick > 120 then
                        logMsg("⚠️ Personagem preso! Forçando teleporte vertical para soltar...")
                        rt.CFrame = rt.CFrame + Vector3.new(0, 5, 0)
                        hum:ChangeState(Enum.HumanoidStateType.Running)
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
-- SISTEMA NOCLIP SEGURO (MANTÉM COLISÃO NO CHÃO)
-- =========================================================================
getgenv().NoclipLoop = game:GetService("RunService").Stepped:Connect(function()
    if not getgenv().AutoFarmDelivery then return end
    local c = lp.Character
    if c then
        -- Apenas o Tronco e a Cabeça perdem colisão para não travar em cercas.
        -- HumanoidRootPart, Pernas e Pés MANTÊM colisão para você não cair do mapa.
        for _, p in pairs(c:GetChildren()) do
            if p:IsA("BasePart") then
                local n = p.Name
                if n ~= "HumanoidRootPart" and not n:match("Leg") and not n:match("Foot") then
                    p.CanCollide = false
                end
            end
        end
        
        -- Noclip do carro mantido nas partes de cima
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum and hum.SeatPart then
            local car = hum.SeatPart:FindFirstAncestorWhichIsA("Model")
            if car and car ~= c then
                for _, p in pairs(car:GetDescendants()) do
                    if p:IsA("BasePart") then
                        local n = p.Name:lower()
                        if not (n:match("wheel") or n:match("tire") or n:match("rim") or n:match("suspension") or n:match("whl")) then
                            p.CanCollide = false
                        end
                    end
                end
            end
        end
    end
end)

-- =========================================================================
-- FUNÇÕES DE SUPORTE
-- =========================================================================
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
            local vimCentro = game:GetService("VirtualInputManager")
            local centroX = btn.AbsolutePosition.X + (btn.AbsoluteSize.X / 2)
            local centroY = btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y / 2)
            vimCentro:SendMouseButtonEvent(centroX, centroY, 0, pressionar, game, 0)
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
-- FUNÇÃO DE TELEPORTE SMART
-- =========================================================================
local function SmartTeleport(targetPos, isDelivery)
    logMsg("--- STARTING SMART TELEPORT ---")
    
    local c, rt, hum = getChar()
    local car = nil

    if hum and hum.SeatPart then
        local seatModel = hum.SeatPart:FindFirstAncestorWhichIsA("Model")
        if seatModel and seatModel ~= c then
            car = seatModel
        end
    end

    if car then
        local cPart = car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart", true)
        local allVehicleParts = cPart:GetConnectedParts(true)
        local currentPivot = car:GetPivot()

        local flatCurrent = Vector3.new(currentPivot.Position.X, 0, currentPivot.Position.Z)
        local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
        local dir = Vector3.new(1, 0, 0)

        if (flatCurrent - flatTarget).Magnitude > 1 then
            dir = (flatCurrent - flatTarget).Unit
        end

        local carOffset = math.random(85, 100)
        local startPos = Vector3.new(targetPos.X + (dir.X * carOffset), targetPos.Y + 10, targetPos.Z + (dir.Z * carOffset))
        local lookAt = Vector3.new(targetPos.X, startPos.Y, targetPos.Z)
        local destCFrame = CFrame.new(startPos, lookAt)

        for i = 1, 15 do
            car:PivotTo(destCFrame)
            for _, p in pairs(allVehicleParts) do
                p.AssemblyLinearVelocity = Vector3.zero
                p.AssemblyAngularVelocity = Vector3.zero
            end
            task.wait()
        end

        simularBotao("Left", false)
        simularBotao("Right", false)
        simularBotao("Throttle", true)

        local timeOut = 0
        while timeOut < 6 do
            local currentDist = (cPart.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude
            if currentDist < 15 then
                break
            end
            timeOut = timeOut + task.wait(0.1)
        end

        simularBotao("Throttle", false)
        simularBotao("Brake", true)
        task.wait(0.8)
        simularBotao("Brake", false)

        logMsg("--- END TELEPORT (VEHICLE) ---")
    else
        if rt and hum then
            local charOffset = math.random(35, 45)
            -- Removemos a altura extra e colocamos exatamente na mesma altura do target
            local startPos = Vector3.new(targetPos.X + charOffset, targetPos.Y + 1, targetPos.Z)

            rt.Velocity = Vector3.zero
            rt.CFrame = CFrame.new(startPos)
            hum.PlatformStand = false
            hum.Sit = false
            
            -- REMOVIDO o Freefall e o Jump para evitar acionar o paraquedas!
            hum:ChangeState(Enum.HumanoidStateType.Running)
            
            task.wait(0.2)
            hum:MoveTo(targetPos)

            local timeOut = 0
            while timeOut < 4 do
                if (rt.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude < 4.5 then
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
                local padPos = pad.Parent.Position
                logMsg("Moving to center to start route (" .. mode .. ")...")
                SmartTeleport(padPos, false)
                
                local chegouNoCentro = false
                local waitLimit = 0
                
                logMsg("Verifying physical arrival at the center pad...")
                while waitLimit < 40 do
                    local c, rt, hum = getChar()
                    if rt and (rt.Position * Vector3.new(1,0,1) - padPos * Vector3.new(1,0,1)).Magnitude < 25 then
                        chegouNoCentro = true
                        break
                    end
                    waitLimit = waitLimit + 1
                    task.wait(0.25)
                end
                
                if chegouNoCentro then
                    logMsg("Arrival confirmed. Requesting job and starting collection timer.")
                    
                    fRem("RequestStartJobSession", "Delivery", "jobPad", mode)
                    task.wait(0.5)
                    fRem("AttemptDeliveryPickup")
                    
                    local selectedWait = math.random(90, 120) / 10
                    logMsg("Collection timer STARTED: " .. selectedWait .. "s")
                    
                    local startTime = tick()
                    task.wait(selectedWait)
                    local endTime = tick()
                    
                    logMsg("✅ Timer FINISHED! Time passed: " .. string.format("%.2f", (endTime - startTime)) .. "s")
                    
                    getgenv().JobPhase = "Farming"
                else
                    logMsg("⚠️ Warning: Failed to reach the center pad in time. Retrying...")
                    task.wait(2)
                end
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
                    
                    local tempoCasa = math.random(50, 70) / 10
                    logMsg("📦 Delivered! Waiting " .. tempoCasa .. "s before moving to next house...")
                    task.wait(tempoCasa)
                    
                    task.spawn(function()
                        task.wait(1.5)
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
