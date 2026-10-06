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
    local prefix = "[V35-DEBUG] "
    if getgenv().LogMsg then
        getgenv().LogMsg(prefix .. msg)
    else
        print(prefix .. tostring(msg))
    end
end

logMsg("Iniciando Motor V35: Fix Crítico - Forçando início do trabalho!")

pcall(function() ws.FallenPartsDestroyHeight = -50000 end)

if getgenv().DeliveryLoop then pcall(task.cancel, getgenv().DeliveryLoop) end
if getgenv().NoclipLoop then getgenv().NoclipLoop:Disconnect() end
if getgenv().AntiSeatLoop then getgenv().AntiSeatLoop:Disconnect() end
if getgenv().AntiAfkConnection then getgenv().AntiAfkConnection:Disconnect() end
if getgenv().AntiAfkLoop then pcall(task.cancel, getgenv().AntiAfkLoop) end

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

getgenv().AntiSeatLoop = rs.Heartbeat:Connect(function()
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

getgenv().NoclipLoop = rs.Stepped:Connect(function()
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

local function NavegarComPathfinder(targetPos, isPad, anchorRef)
    local c, rt, hum = getChar()
    if not (rt and hum) then return end

    local flatCurrent = Vector3.new(rt.Position.X, 0, rt.Position.Z)
    local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
    local distInicial = (flatCurrent - flatTarget).Magnitude

    if distInicial > 45 then
        logMsg("Distância alta (" .. math.floor(distInicial) .. "m). Iniciando aterrissagem via Raycast...")
        local dir = (flatCurrent - flatTarget).Unit
        local charOffset = 35
        
        local skyPos = Vector3.new(targetPos.X + (dir.X * charOffset), targetPos.Y + 100, targetPos.Z + (dir.Z * charOffset))
        
        rt.Velocity = Vector3.zero
        rt.CFrame = CFrame.new(skyPos)
        rt.Anchored = true 
        
        task.wait(1.5)
        
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {c}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local hit = ws:Raycast(rt.Position, Vector3.new(0, -200, 0), params)
        
        if hit then
            rt.CFrame = CFrame.new(hit.Position + Vector3.new(0, 4, 0))
        end

        rt.Anchored = false
        task.wait(0.2)
    end

    hum.PlatformStand = false
    hum.Sit = false
    hum:ChangeState(Enum.HumanoidStateType.Running)

    local path = pfs:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
    local success, err = pcall(function() path:ComputeAsync(rt.Position, targetPos) end)

    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        for i, wp in ipairs(waypoints) do
            c, rt, hum = getChar()
            if not (rt and hum) then return end
            
            if rt.Position.Y < -50 then return end

            if not isPad and anchorRef then
                if anchorRef.Parent ~= ws then return end
                local distToTarget = (rt.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude
                if distToTarget <= 8 then
                    fRem("AttemptDeliveryComplete")
                    fRem("AttemptDeliveryPickup")
                    local vis, pct = lerPreenchimentoBarra()
                    if vis and pct > 0 then
                        rt.Velocity = Vector3.zero
                        hum:MoveTo(rt.Position)
                        local timeoutColeta = 0
                        while anchorRef.Parent == ws and timeoutColeta < 50 do
                            local v, p = lerPreenchimentoBarra()
                            if not v or p >= 0.99 then break end
                            task.wait(0.1)
                            timeoutColeta = timeoutColeta + 1
                        end
                        return
                    end
                end
            end

            if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
            hum:MoveTo(wp.Position)
            
            local moveOut = 0
            while moveOut < 40 do
                c, rt, hum = getChar()
                if not (rt and hum) then break end
                local distWp = (rt.Position * Vector3.new(1,0,1) - wp.Position * Vector3.new(1,0,1)).Magnitude
                if distWp <= 3.5 then break end
                moveOut = moveOut + 1
                task.wait(0.1)
            end
        end
        if rt then rt.Velocity = Vector3.zero; hum:MoveTo(rt.Position) end
    else
        local timeOut = 0
        while timeOut < 150 do
            c, rt, hum = getChar()
            if not (rt and hum) then break end
            
            if not isPad and anchorRef then
                if anchorRef.Parent ~= ws then return end
                local distToTarget = (rt.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude
                if distToTarget <= 6 then
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
                        return
                    end
                end
            end

            local distAtual = (rt.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude
            if distAtual <= 3.5 then hum:MoveTo(rt.Position); break
            else hum:MoveTo(targetPos) end
            
            timeOut = timeOut + 1
            task.wait(0.1)
        end
    end
end

getgenv().DeliveryLoop = task.spawn(function()
    while task.wait(0.2) do
        if not getgenv().AutoFarmDelivery then break end
        
        if ws:FindFirstChild("DeliveryTargetAnchor") then getgenv().JobPhase = "Farming" end

        if getgenv().JobPhase == "Init" then
            local modeStr = getgenv().DeliveryMode
            local mode = (modeStr == "Hard" or modeStr == "HighRisk") and "HighRisk" or "Safe"
            local pad = nil
            
            -- Tenta achar o Pad, mas não trava o script se não achar
            for _,v in pairs(ws:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" then pad = v; break end
            end
            
            if pad then
                local padPos = pad.Parent.Position
                local c, rt, hum = getChar()
                local dist = rt and (rt.Position * Vector3.new(1,0,1) - padPos * Vector3.new(1,0,1)).Magnitude or 999
                
                if dist > 6 then
                    NavegarComPathfinder(padPos, true, nil)
                end
                
                c, rt, hum = getChar()
                if hum and rt then hum:MoveTo(rt.Position) end
            end
            
            -- ESTA É A CORREÇÃO: Dispara a requisição do job independente de achar o Pad!
            logMsg("Enviando requisição de início do Job para o servidor...")
            fRem("RequestStartJobSession", "Delivery", "jobPad", mode)
            task.wait(0.5)
            fRem("AttemptDeliveryPickup")
            getgenv().JobPhase = "Farming"
            task.wait(1.5)

        elseif getgenv().JobPhase == "Farming" then
            local t = ws:FindFirstChild("DeliveryTargetAnchor")
            if t and t.Parent == ws then
                if t ~= getgenv().LastAnchor then
                    logMsg("Novo Anchor detectado. Iniciando perseguição...")
                    NavegarComPathfinder(t.Position, false, t)
                    getgenv().LastAnchor = t
                    local tempoCasa = math.random(30, 50) / 10
                    task.wait(tempoCasa)
                    task.spawn(function()
                        task.wait(1.5)
                        if getgenv().LastAnchor == t then getgenv().LastAnchor = nil end
                    end)
                end
            else
                -- Se estivemos em Farming mas o TargetAnchor sumiu, voltamos pro Init para forçar pegar pacote novo
                getgenv().JobPhase = "Init"
                task.wait(0.1)
            end
        end
    end
end)
