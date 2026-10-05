local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local lp = players.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

repeat task.wait(0.5) until game:IsLoaded()
repeat task.wait(0.5) until lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")

local function logMsg(msg)
    if getgenv().LogMsg then getgenv().LogMsg(msg) else print("Delivery: " .. tostring(msg)) end
end

logMsg("Motor V13: Leitura Corrigida (Focando no elemento 'Fill'). Delay de 6s rodando...")
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
        if hum and rt and hum.Sit then
            local seatPart = hum.SeatPart
            if seatPart and not seatPart:IsA("VehicleSeat") then
                if seatPart:FindFirstChild("SeatWeld") then seatPart.SeatWeld:Destroy() end
                hum.Sit = false
                rt.CFrame = rt.CFrame + Vector3.new(0, 5, 0)
                hum:ChangeState(Enum.HumanoidStateType.Running)
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
                        p.CanCollide = false
                    end
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

-- =========================================================================
-- LEITURA CORRIGIDA GRAÇAS AO SEU LOG (AGORA LÊ O 'Fill')
-- =========================================================================
local function lerPreenchimentoBarra()
    local c = lp.Character
    if not c then return 0 end
    local head = c:FindFirstChild("Head")
    if not head then return 0 end
    local bbg = head:FindFirstChild("CharacterBillboard")
    if not bbg then return 0 end
    
    local packageBar = bbg:FindFirstChild("PackageBarFrame", true)
    if packageBar and packageBar.Visible then
        local fill = packageBar:FindFirstChild("Fill", true)
        if fill and fill:IsA("Frame") then
            return fill.Size.X.Scale
        end
    end
    return 0
end

local function SmartTeleport(targetPos, isDelivery)
    local c, rt, hum = getChar()
    if rt and hum then
        if isDelivery then
            rt.Velocity = Vector3.zero
            rt.CFrame = CFrame.new(targetPos + Vector3.new(0, 4, 0))
            hum.PlatformStand = false
            hum.Sit = false
            task.wait(0.5)
        else
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
                if (rt.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude < 4.0 then break end
                timeOut = timeOut + 1
                task.wait(0.1)
            end
        end
    end
end

getgenv().DeliveryLoop = task.spawn(function()
    while task.wait(0.2) do
        if not getgenv().AutoFarmDelivery then break end
        
        if getgenv().JobPhase == "Init" then
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
                local chegouNoCentro = (dist <= 4)
                
                if not chegouNoCentro then
                    logMsg("🚶 Caminhando de longe para o centro do pad...")
                    SmartTeleport(padPos, false) 
                    local waitLimit = 0
                    repeat
                        c, rt, hum = getChar()
                        if rt and hum then
                            dist = (rt.Position * Vector3.new(1,0,1) - padPos * Vector3.new(1,0,1)).Magnitude
                            if dist <= 4 then chegouNoCentro = true else hum:MoveTo(padPos) end
                        end
                        waitLimit = waitLimit + 1
                        task.wait(0.5)
                    until chegouNoCentro or waitLimit >= 30
                end

                if chegouNoCentro then
                    logMsg("📍 Chegou no Pad! Iniciando trabalho...")
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
                            logMsg("📊 Progresso real: " .. porcentagem .. "%")
                            tempoUltimoLog = tick()
                            if porcentagem == 0 and hum and rt then
                                hum:MoveTo(padPos + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2)))
                            end
                        end

                        if preenchimento >= 0.99 then
                            if hum then hum:MoveTo(rt.Position) end
                            logMsg("✅ Bolsa 100% cheia! Esperando delay...")
                            break
                        end
                        task.wait(0.1)
                    end
                    
                    local delaySeguranca = math.random(10, 30) / 10
                    task.wait(delaySeguranca)
                    getgenv().JobPhase = "Farming"
                else
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
                        SmartTeleport(t.Position, true) 
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
                        task.wait(math.random(50, 70) / 10)
                        task.spawn(function() task.wait(1.5); if getgenv().LastAnchor == t then getgenv().LastAnchor = nil end end)
                    else
                        task.wait(1)
                    end
                end
            else
                task.wait(0.1)
            end
        end
    end
end)
