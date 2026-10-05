local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local lp = players.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

-- =========================================================================
-- TRAVA DE INICIALIZAÇÃO (AGUARDA MAPA)
-- =========================================================================
repeat task.wait(0.5) until game:IsLoaded()
repeat task.wait(0.5) until lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")

local function logMsg(msg)
    if getgenv().LogMsg then getgenv().LogMsg(msg) else print("Delivery: " .. tostring(msg)) end
end

logMsg("Motor V12: Iniciando delay de 6s para carregar mapa...")
task.wait(6)
logMsg("Caminhada OBRIGATÓRIA no Pad, Teleporte DIRETO na Casa.")

-- =========================================================================
-- IMUNIDADE AO VOID E LIMPEZA
-- =========================================================================
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

-- =========================================================================
-- ANTI-AFK & ANTI-SENTADA & NOCLIP
-- =========================================================================
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
                if seatPart and not seatPart:IsA("VehicleSeat") then
                    if seatPart:FindFirstChild("SeatWeld") then seatPart.SeatWeld:Destroy() end
                    hum.Sit = false
                    stuckTick = stuckTick + 1
                    if stuckTick > 120 then
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
    if r:IsA("RemoteEvent") then pcall(r.FireServer, r, ...)
    elseif r:IsA("RemoteFunction") then task.spawn(pcall, r.InvokeServer, r, ...) end
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
                pcall(function() conn.Function({UserInputType = Enum.UserInputType.Touch, UserInputState = estado}) end)
            end
        end
    end
end

local function lerPreenchimentoBarra()
    local c = lp.Character
    if not c then return 0 end
    local head = c:FindFirstChild("Head")
    if not head then return 0 end
    local bbg = head:FindFirstChild("CharacterBillboard")
    if not bbg then return 0 end
    local packageBar = bbg:FindFirstChild("PackageBarFrame", true)
    if packageBar and packageBar.Visible then
        for _, child in pairs(packageBar:GetChildren()) do
            if child:IsA("Frame") or child:IsA("ImageLabel") then
                return child.Size.X.Scale
            end
        end
    end
    return 0
end

-- =========================================================================
-- FUNÇÃO DE TELEPORTE SMART SEPARADA (INICIO vs CASA)
-- =========================================================================
local function SmartTeleport(targetPos, isDelivery)
    local c, rt, hum = getChar()
    local car = nil
    if hum and hum.SeatPart then
        local seatModel = hum.SeatPart:FindFirstAncestorWhichIsA("Model")
        if seatModel and seatModel ~= c then car = seatModel end
    end

    if car then
        local cPart = car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart", true)
        local allVehicleParts = cPart:GetConnectedParts(true)
        local currentPivot = car:GetPivot()
        
        local flatCurrent = Vector3.new(currentPivot.Position.X, 0, currentPivot.Position.Z)
        local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
        local dir = Vector3.new(1, 0, 0)
        if (flatCurrent - flatTarget).Magnitude > 1 then dir = (flatCurrent - flatTarget).Unit end
        
        local carOffset = math.random(85, 100)
        local startPos = Vector3.new(targetPos.X + (dir.X * carOffset), targetPos.Y + 10, targetPos.Z + (dir.Z * carOffset))
        local destCFrame = CFrame.new(startPos, Vector3.new(targetPos.X, startPos.Y, targetPos.Z))
        
        for i = 1, 15 do
            car:PivotTo(destCFrame)
            for _, p in pairs(allVehicleParts) do
                p.AssemblyLinearVelocity = Vector3.zero; p.AssemblyAngularVelocity = Vector3.zero
            end
            task.wait()
        end
        
        simularBotao("Left", false); simularBotao("Right", false); simularBotao("Throttle", true)
        local timeOut = 0
        while timeOut < 6 do
            if (cPart.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude < 20 then break end
            timeOut = timeOut + task.wait(0.1)
        end
        simularBotao("Throttle", false); simularBotao("Brake", true); task.wait(0.8); simularBotao("Brake", false)
    else
        if rt and hum then
            if isDelivery then
                -- LÓGICA DA CASA: Teleporte DIRETO para não bugar a distância.
                rt.Velocity = Vector3.zero
                rt.CFrame = CFrame.new(targetPos + Vector3.new(0, 4, 0))
                hum.PlatformStand = false
                hum.Sit = false
                task.wait(0.5)
            else
                -- LÓGICA DO INÍCIO (PAD): Cai a 40 metros e VAI ANDANDO até o centro.
                local flatCurrent = Vector3.new(rt.Position.X, 0, rt.Position.Z)
                local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
                local dir = Vector3.new(1, 0, 0)
                if (flatCurrent - flatTarget).Magnitude > 1 then dir = (flatCurrent - flatTarget).Unit end
                
                local charOffset = math.random(35, 45)
                local startPos = Vector3.new(targetPos.X + (dir.X * charOffset), targetPos.Y + 3.5, targetPos.Z + (dir.Z * charOffset))
                
                local tempFloor = Instance.new("Part")
                tempFloor.Anchored = true; tempFloor.CanCollide = true; tempFloor.Transparency = 1
                tempFloor.Size = Vector3.new(150, 2, 150)
                tempFloor.Position = Vector3.new(targetPos.X, targetPos.Y - 1.5, targetPos.Z)
                tempFloor.Parent = ws
                
                game:GetService("Debris"):AddItem(tempFloor, 15)
                
                rt.Velocity = Vector3.zero
                rt.CFrame = CFrame.new(startPos)
                hum.PlatformStand = false; hum.Sit = false; hum:ChangeState(Enum.HumanoidStateType.Running)
                task.wait(0.2)
                
                hum:MoveTo(targetPos)
                
                local timeOut = 0
                while timeOut < 100 do 
                    if rt.Position.Y - targetPos.Y < -15 then break end
                    if (rt.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude < 4.0 then
                        break
                    end
                    timeOut = timeOut + 1
                    task.wait(0.1)
                end
            end
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
                    pad = v; break
                end
            end
            
            if pad then
                local padPos = pad.Parent.Position
                local c, rt, hum = getChar()
                local dist = rt and (rt.Position * Vector3.new(1,0,1) - padPos * Vector3.new(1,0,1)).Magnitude or 999
                
                local isCar = (hum and hum.SeatPart ~= nil)
                local distMinima = isCar and 25 or 4 
                local chegouNoCentro = (dist <= distMinima)
                
                if not chegouNoCentro then
                    logMsg("🚶 Caminhando de longe para o centro do pad (" .. mode .. ")...")
                    SmartTeleport(padPos, false) -- FALSE = Vai teleportar longe e caminhar.
                    
                    local waitLimit = 0
                    repeat
                        c, rt, hum = getChar()
                        if rt and hum then
                            isCar = (hum.SeatPart ~= nil)
                            distMinima = isCar and 25 or 4
                            dist = (rt.Position * Vector3.new(1,0,1) - padPos * Vector3.new(1,0,1)).Magnitude
                            
                            if dist <= distMinima then
                                chegouNoCentro = true
                            else
                                if not isCar then hum:MoveTo(padPos) end
                            end
                        end
                        waitLimit = waitLimit + 1
                        task.wait(0.5)
                    until chegouNoCentro or waitLimit >= 30
                end

                if chegouNoCentro then
                    logMsg("📍 Chegou no Pad! Iniciando e aguardando a barrinha...")
                    fRem("RequestStartJobSession", "Delivery", "jobPad", mode)
                    task.wait(0.5)
                    fRem("AttemptDeliveryPickup")
                    
                    local startTime = tick()
                    local maxEspera = 25
                    local tempoUltimoLog = 0
                    
                    while tick() - startTime < maxEspera do
                        local preenchimento = lerPreenchimentoBarra()
                        local porcentagem = math.floor(preenchimento * 100)
                        
                        if tick() - tempoUltimoLog >= 1.0 then
                            logMsg("📊 Progresso do pacote: " .. porcentagem .. "%")
                            tempoUltimoLog = tick()
                            
                            if porcentagem == 0 and not isCar and hum and rt then
                                local offset = Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
                                hum:MoveTo(padPos + offset)
                            end
                        end

                        if preenchimento >= 0.99 then
                            if hum then hum:MoveTo(rt.Position) end
                            logMsg("✅ Barra chegou em 100%! Esperando delay de segurança...")
                            break
                        end
                        task.wait(0.1)
                    end
                    
                    local delaySeguranca = math.random(10, 30) / 10
                    logMsg("⏱️ Aguardando " .. delaySeguranca .. "s extras para fechar a bolsa...")
                    task.wait(delaySeguranca)
                    
                    getgenv().JobPhase = "Farming"
                else
                    logMsg("⚠️ O boneco não conseguiu chegar no pad. Tentando de novo...")
                    task.wait(1)
                end
            else
                task.wait(2)
            end
            
        elseif getgenv().JobPhase == "Farming" then
            local t = ws:FindFirstChild("DeliveryTargetAnchor")
            if t and t.Parent == ws then
                if t ~= getgenv().LastAnchor then
                    local c, rt = getChar()
                    local dist = rt and (rt.Position * Vector3.new(1,0,1) - t.Position * Vector3.new(1,0,1)).Magnitude or 999
                    
                    if dist > 55 then
                        SmartTeleport(t.Position, true) -- TRUE = Vai teleportar DIRETO pra casa.
                        task.wait(0.5)
                    end
                    
                    c, rt = getChar()
                    dist = rt and (rt.Position * Vector3.new(1,0,1) - t.Position * Vector3.new(1,0,1)).Magnitude or 999
                    
                    if dist < 85 then
                        fRem("AttemptDeliveryComplete")
                        task.wait(0.2)
                        fRem("AttemptDeliveryComplete")
                        task.wait(0.3)
                        fRem("AttemptDeliveryPickup")
                        
                        getgenv().LastAnchor = t
                        local tempoCasa = math.random(50, 70) / 10
                        logMsg("📦 Pacote entregue! Aguardando " .. tempoCasa .. "s...")
                        task.wait(tempoCasa)
                        
                        task.spawn(function()
                            task.wait(1.5)
                            if getgenv().LastAnchor == t then getgenv().LastAnchor = nil end
                        end)
                    else
                        logMsg("⏳ Aguardando confirmação da entrega... Distância atual: " .. math.floor(dist))
                        task.wait(1)
                    end
                end
            else
                task.wait(0.1)
            end
        end
    end
end)
