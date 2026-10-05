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

logMsg("Motor V16: Chão invisível restaurado. Fim do limbo debaixo do mapa!")
task.wait(2)

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

local function SmartTeleport(targetPos)
    local c, rt, hum = getChar()
    local car = nil
    if hum and hum.SeatPart then
        local seatModel = hum.SeatPart:FindFirstAncestorWhichIsA("Model")
        if seatModel and seatModel ~= c then car = seatModel end
    end

    if car then
        local cPart = car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart", true)
        local allVehicleParts = cPart:GetConnectedParts(true)
        local destCFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
        
        for i = 1, 15 do
            car:PivotTo(destCFrame)
            for _, p in pairs(allVehicleParts) do
                p.AssemblyLinearVelocity = Vector3.zero
                p.AssemblyAngularVelocity = Vector3.zero
            end
            task.wait()
        end
        task.wait(0.5)
    else
        if rt and hum then
            -- CHÃO FALSO RESTAURADO: Evita cair no void enquanto o mapa não carrega.
            local tempFloor = Instance.new("Part")
            tempFloor.Anchored = true
            tempFloor.CanCollide = true
            tempFloor.Transparency = 1
            tempFloor.Size = Vector3.new(150, 2, 150)
            tempFloor.Position = Vector3.new(targetPos.X, targetPos.Y - 2, targetPos.Z)
            tempFloor.Parent = ws
            game:GetService("Debris"):AddItem(tempFloor, 5) -- Segura o boneco por 5s
            
            rt.Velocity = Vector3.zero
            rt.CFrame = CFrame.new(targetPos + Vector3.new(0, 6, 0))
            hum.PlatformStand = false
            hum.Sit = false
            task.wait(0.5)
        end
    end
end

getgenv().DeliveryLoop = task.spawn(function()
    while task.wait(0.2) do
        if not getgenv().AutoFarmDelivery then break end
        
        local targetAnchor = ws:FindFirstChild("DeliveryTargetAnchor")
        if targetAnchor and targetAnchor.Parent == ws then
            getgenv().JobPhase = "Farming"
        end
        
        if getgenv().JobPhase == "Init" then
            local modeStr = getgenv().DeliveryMode
            local mode = (modeStr == "Hard" or modeStr == "HighRisk") and "HighRisk" or "Safe"
            
            logMsg("🚀 Iniciando trabalho diretamente via Remotes...")
            fRem("RequestStartJobSession", "Delivery", "jobPad", mode)
            task.wait(0.5)
            fRem("AttemptDeliveryPickup")
            
            local startTime = tick()
            while tick() - startTime < 10 do
                if ws:FindFirstChild("DeliveryTargetAnchor") then
                    logMsg("✅ Alvo detectado no mapa! Iniciando entrega...")
                    break
                end
                task.wait(0.5)
            end
            
            getgenv().JobPhase = "Farming"
            
        elseif getgenv().JobPhase == "Farming" then
            local t = ws:FindFirstChild("DeliveryTargetAnchor")
            if t and t.Parent == ws then
                if t ~= getgenv().LastAnchor then
                    local c, rt = getChar()
                    local dist = rt and (rt.Position * Vector3.new(1,0,1) - t.Position * Vector3.new(1,0,1)).Magnitude or 999
                    
                    if dist > 55 then
                        SmartTeleport(t.Position) 
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
                        
                        task.spawn(function() task.wait(1.5); if getgenv().LastAnchor == t then getgenv().LastAnchor = nil end end)
                    else
                        logMsg("⏳ Aguardando confirmação... Distância: " .. math.floor(dist))
                        task.wait(1)
                    end
                end
            else
                task.wait(0.1)
            end
        end
    end
end)
