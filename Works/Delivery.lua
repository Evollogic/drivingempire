local plyrs = game:GetService("Players")
local lp = plyrs.LocalPlayer
local rs = game:GetService("RunService")
local ws = game:GetService("Workspace")
local rep = game:GetService("ReplicatedStorage")
local remotes = rep:WaitForChild("Remotes")

repeat task.wait(0.5) until game:IsLoaded()
repeat task.wait(0.5) until lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")

local function logMsg(msg)
    if getgenv().LogMsg then getgenv().LogMsg(msg) else print("Delivery: " .. tostring(msg)) end
end

logMsg("Motor V26: Caminhada até o centro exato! Trava Suprema mantida.")
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
-- MOTOR ÚNICO: CAMINHA PRO CENTRO EXATO + TRAVA SUPREMA
-- =========================================================================
local function MoverParaCentro(targetPos, isPad, anchorRef)
    local c, rt, hum = getChar()
    if not (rt and hum) then return end
    
    local flatCurrent = Vector3.new(rt.Position.X, 0, rt.Position.Z)
    local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
    local distInicial = (flatCurrent - flatTarget).Magnitude
    
    -- Teleporta para as proximidades se estiver muito longe (> 45 studs)
    if distInicial > 45 then
        local dir = (flatCurrent - flatTarget).Unit
        local charOffset = math.random(35, 45)
        local startPos = Vector3.new(targetPos.X + (dir.X * charOffset), targetPos.Y + 3.5, targetPos.Z + (dir.Z * charOffset))
        
        local tempFloor = Instance.new("Part")
        tempFloor.Anchored = true; tempFloor.CanCollide = true; tempFloor.Transparency = 1
        tempFloor.Size = Vector3.new(200, 2, 200)
        tempFloor.Position = Vector3.new(targetPos.X, targetPos.Y - 2, targetPos.Z)
        tempFloor.Parent = ws
        game:GetService("Debris"):AddItem(tempFloor, 15)
        
        rt.Velocity = Vector3.zero
        rt.CFrame = CFrame.new(startPos)
        task.wait(0.5) -- Pausa de segurança pra física do jogo
    end
    
    hum.PlatformStand = false; hum.Sit = false; hum:ChangeState(Enum.HumanoidStateType.Running)
    logMsg("🚶 Indo exatamente para o centro...")
    
    local timeOut = 0
    local noCentro = false
    
    while timeOut < 150 do
        c, rt, hum = getChar()
        if not (rt and hum) then break end
        if rt.Position.Y - targetPos.Y < -15 then break end
        
        -- LÓGICA DA ROTA (Coletas e Entregas)
        if not isPad and anchorRef then
            if anchorRef.Parent ~= ws then
                logMsg("✅ Alvo sumiu! Ação confirmada pelo jogo.")
                break
            end
            
            fRem("AttemptDeliveryComplete")
            fRem("AttemptDeliveryPickup")
            
            -- TRAVA SUPREMA: Começou a encher? Para onde estiver!
            local vis, pct = lerPreenchimentoBarra()
            if vis and pct > 0 then
                logMsg("🛑 Trava Suprema: Fill em " .. math.floor(pct*100) .. "%. Congelando no lugar!")
                rt.Velocity = Vector3.zero
                hum:MoveTo(rt.Position)
                
                local tempoUltimoLog = tick()
                while anchorRef.Parent == ws do
                    local v, p = lerPreenchimentoBarra()
                    if not v or p >= 0.99 then break end
                    if tick() - tempoUltimoLog >= 1.0 then
                        logMsg("📊 Progresso: " .. math.floor(p*100) .. "%")
                        tempoUltimoLog = tick()
                    end
                    task.wait(0.1)
                end
                logMsg("✅ Coleta/Entrega 100% concluída!")
                break
            end
        end
        
        local distAtual = (rt.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude
        
        -- CAMINHA ATÉ O CENTRO EXATO (3.5 studs)
        if distAtual <= 3.5 then
            if not noCentro then
                logMsg("🎯 Chegou exatamente no centro do alvo!")
                noCentro = true
                rt.Velocity = Vector3.zero
                hum:MoveTo(rt.Position) -- Fica estátua no meio
            end
            
            if isPad then 
                break -- Se for o Pad, libera pra apertar o botão e vazar
            end
        else
            noCentro = false
            hum:MoveTo(targetPos) -- Continua empurrando pro meio
        end
        
        timeOut = timeOut + 1
        task.wait(0.1)
    end
end

-- =========================================================================
-- LOOP PRINCIPAL DO FARM
-- =========================================================================
getgenv().DeliveryLoop = task.spawn(function()
    while task.wait(0.2) do
        if not getgenv().AutoFarmDelivery then break end
        
        if ws:FindFirstChild("DeliveryTargetAnchor") then
            getgenv().JobPhase = "Farming"
        end
        
        if getgenv().JobPhase == "Init" then
            local modeStr = getgenv().DeliveryMode
            local mode = (modeStr == "Hard" or modeStr == "HighRisk") and "HighRisk" or "Safe"
            local pad = nil
            
            for _,v in pairs(ws:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" then pad = v; break end
            end
            
            if pad then
                MoverParaCentro(pad.Parent.Position, true, nil)
                logMsg("🚀 Iniciando trabalho no Pad...")
                fRem("RequestStartJobSession", "Delivery", "jobPad", mode)
                task.wait(1.5)
                getgenv().JobPhase = "Farming"
            else
                task.wait(2)
            end
            
        elseif getgenv().JobPhase == "Farming" then
            local t = ws:FindFirstChild("DeliveryTargetAnchor")
            if t and t.Parent == ws then
                if t ~= getgenv().LastAnchor then
                    
                    MoverParaCentro(t.Position, false, t)
                    
                    getgenv().LastAnchor = t
                    local tempoCasa = math.random(30, 50) / 10
                    logMsg("📦 Partindo para a próxima rota em " .. tempoCasa .. "s...")
                    task.wait(tempoCasa)
                    
                    task.spawn(function() task.wait(1.5); if getgenv().LastAnchor == t then getgenv().LastAnchor = nil end end)
                end
            else
                task.wait(0.1)
            end
        end
    end
end)
