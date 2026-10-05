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

logMsg("Motor V24: Trava Suprema ativada! Se a barra sair de 0%, TUDO é cancelado até dar 100%.")
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

local function AguardarColeta()
    local isVis = false
    local pct = 0
    local checkTimer = tick()
    
    while tick() - checkTimer < 2.5 do
        isVis, pct = lerPreenchimentoBarra()
        if isVis then break end
        task.wait(0.2)
    end
    
    if isVis then
        logMsg("⏳ Barra detectada! Congelando boneco...")
        local _, rt, hum = getChar()
        if hum and rt then hum:MoveTo(rt.Position) end
        
        local startTime = tick()
        local tempoUltimoLog = 0
        
        while tick() - startTime < 25 do
            local vis, p = lerPreenchimentoBarra()
            local perc = math.floor(p * 100)
            
            if tick() - tempoUltimoLog >= 1.0 then
                if p > 0 then logMsg("📊 Progresso do Produto: " .. perc .. "%") end
                tempoUltimoLog = tick()
            end
            
            if p >= 0.99 or not vis then
                logMsg("✅ Coleta/Entrega 100% concluída!")
                break
            end
            task.wait(0.1)
        end
    end
end

local function CaminharAteAlvo(targetPos, breakDist)
    local c, rt, hum = getChar()
    if not (rt and hum) then return end
    
    local flatCurrent = Vector3.new(rt.Position.X, 0, rt.Position.Z)
    local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
    local dir = Vector3.new(1, 0, 0)
    if (flatCurrent - flatTarget).Magnitude > 1 then dir = (flatCurrent - flatTarget).Unit end
    
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
    
    -- Pausa de segurança pra física do jogo sincronizar e evitar rubberband pesado
    task.wait(0.5)
    
    hum.PlatformStand = false; hum.Sit = false; hum:ChangeState(Enum.HumanoidStateType.Running)
    hum:MoveTo(targetPos)
    
    local timeOut = 0
    while timeOut < 120 do 
        c, rt, hum = getChar()
        if not (rt and hum) then break end
        if rt.Position.Y - targetPos.Y < -15 then break end
        
        -- TRAVA SUPREMA 1: Se a barra saiu de 0% no meio da caminhada, CANCELA TUDO e congela!
        local vis, pct = lerPreenchimentoBarra()
        if vis and pct > 0 then
            logMsg("🛑 TRAVA DE MOVIMENTO: O jogo iniciou a coleta de longe (" .. math.floor(pct*100) .. "%). Congelando!")
            rt.Velocity = Vector3.zero
            hum:MoveTo(rt.Position)
            break
        end
        
        local distAtual = (rt.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude
        if distAtual <= breakDist then 
            break 
        end
        
        timeOut = timeOut + 1
        task.wait(0.1)
    end
end

getgenv().DeliveryLoop = task.spawn(function()
    while task.wait(0.2) do
        if not getgenv().AutoFarmDelivery then break end
        
        -- TRAVA SUPREMA 2: Proteção total do loop principal.
        -- Se a barra estiver em andamento, o script ignora teleportes, distâncias e apenas assiste.
        local vM, pM = lerPreenchimentoBarra()
        if vM and pM > 0 and pM < 0.99 then
            logMsg("🛑 TRAVA MÁXIMA: Coleta em andamento (" .. math.floor(pM*100) .. "%). Bloqueando teleportes!")
            local c, rt, hum = getChar()
            if rt and hum then 
                rt.Velocity = Vector3.zero
                hum:MoveTo(rt.Position) 
            end
            
            while true do
                task.wait(0.5)
                local v, p = lerPreenchimentoBarra()
                if not v or p >= 0.99 then break end
                logMsg("📊 Enchendo: " .. math.floor(p*100) .. "%")
            end
            logMsg("✅ 100% Atingido! Retomando script...")
            task.wait(1)
            -- Como o script esperou, na próxima linha ele naturalmente já processa o fim da entrega
        end
        
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
                
                if dist > 15 then
                    logMsg("🚶 Caminhando para o pad...")
                    CaminharAteAlvo(padPos, 10)
                else
                    logMsg("📍 Distância aceita no Pad! Iniciando...")
                    if hum then hum:MoveTo(rt.Position) end
                    
                    fRem("RequestStartJobSession", "Delivery", "jobPad", mode)
                    task.wait(1.5)
                    getgenv().JobPhase = "Farming"
                end
            else
                task.wait(2)
            end
            
        elseif getgenv().JobPhase == "Farming" then
            local t = ws:FindFirstChild("DeliveryTargetAnchor")
            if t and t.Parent == ws then
                if t ~= getgenv().LastAnchor then
                    local c, rt, hum = getChar()
                    local dist = rt and (rt.Position * Vector3.new(1,0,1) - t.Position * Vector3.new(1,0,1)).Magnitude or 999
                    
                    if dist > 85 then
                        logMsg("🚶 Caminhando até o destino (Distância: " .. math.floor(dist) .. ")...")
                        CaminharAteAlvo(t.Position, 80)
                    end
                    
                    c, rt, hum = getChar()
                    dist = rt and (rt.Position * Vector3.new(1,0,1) - t.Position * Vector3.new(1,0,1)).Magnitude or 999
                    
                    -- Se ele já está perto o suficiente E NÃO ESTÁ PRESO NA TRAVA SUPREMA
                    local isVis, isPct = lerPreenchimentoBarra()
                    if dist <= 85 and not (isVis and isPct > 0 and isPct < 0.99) then
                        logMsg("🎯 Ponto validado! Disparando...")
                        if hum then hum:MoveTo(rt.Position) end
                        
                        fRem("AttemptDeliveryComplete")
                        task.wait(0.2)
                        fRem("AttemptDeliveryPickup")
                        
                        AguardarColeta()
                        
                        getgenv().LastAnchor = t
                        local tempoCasa = math.random(30, 50) / 10
                        logMsg("📦 Concluído! Aguardando " .. tempoCasa .. "s para a próxima...")
                        task.wait(tempoCasa)
                        
                        task.spawn(function() task.wait(1.5); if getgenv().LastAnchor == t then getgenv().LastAnchor = nil end end)
                    end
                end
            else
                task.wait(0.1)
            end
        end
    end
end)
