local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local lp = players.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

if getgenv().DeliveryLoop then pcall(task.cancel, getgenv().DeliveryLoop) end
if getgenv().NoclipLoop then getgenv().NoclipLoop:Disconnect() end

getgenv().JobPhase = "Init"

-- Log function connected to Hub
local function logMsg(msg)
    if getgenv().LogMsg then getgenv().LogMsg(msg) else print("Delivery: " .. tostring(msg)) end
end

-- =========================================================================
-- CONTINUOUS NOCLIP SYSTEM (GHOST MODE)
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
-- SUPPORT FUNCTIONS
-- =========================================================================
local function rWait(min, max) task.wait(math.random(min * 10, max * 10) / 10) end

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

local function simulateButton(buttonName, press)
    local btn = lp.PlayerGui:FindFirstChild(buttonName, true)
    if btn then
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local centerX = btn.AbsolutePosition.X + (btn.AbsoluteSize.X / 2)
            local centerY = btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y / 2)
            vim:SendMouseButtonEvent(centerX, centerY, 0, press, game, 0)
        end)
        if getconnections then
            local state = press and Enum.UserInputState.Begin or Enum.UserInputState.End
            for _, conn in pairs(getconnections(press and btn.InputBegan or btn.InputEnded)) do
                pcall(function() conn.Function({UserInputType = Enum.UserInputType.Touch, UserInputState = state}) end)
            end
        end
    end
end

-- =========================================================================
-- SMART TELEPORT WITH FORCE-HOLD
-- =========================================================================
local function SmartTeleport(targetPos, isDelivery)
    logMsg("Target Pos: " .. tostring(targetPos))

    local c, rt, hum = getChar()
    local car = nil

    if hum and hum.SeatPart then
        local seatModel = hum.SeatPart:FindFirstAncestorWhichIsA("Model")
        if seatModel and seatModel ~= c then car = seatModel end
    end

    if car then
        logMsg("VEHICLE Mode. Ghost Mode Applied.")
        local cPart = car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart", true)
        local allVehicleParts = cPart:GetConnectedParts(true)
        local currentPivot = car:GetPivot()

        local flatCurrent = Vector3.new(currentPivot.Position.X, 0, currentPivot.Position.Z)
        local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
        local dist = (flatCurrent - flatTarget).Magnitude
        local dir = (dist > 1) and (flatCurrent - flatTarget).Unit or Vector3.new(1, 0, 0)

        local startPos = Vector3.new(targetPos.X + (dir.X * 25), targetPos.Y + 5, targetPos.Z + (dir.Z * 25))
        local destCFrame = CFrame.new(startPos, Vector3.new(targetPos.X, startPos.Y, targetPos.Z))

        local collisionStates = {}
        for _, p in pairs(allVehicleParts) do
            collisionStates[p] = p.CanCollide
            local n = p.Name:lower()
            if not (n:match("wheel") or n:match("tire") or n:match("rim") or n:match("suspension") or n:match("whl")) then
                p.CanCollide = false
            end
        end

        for i = 1, 15 do
            car:PivotTo(destCFrame)
            for _, p in pairs(allVehicleParts) do
                p.AssemblyLinearVelocity = Vector3.zero
                p.AssemblyAngularVelocity = Vector3.zero
            end
            task.wait()
        end

        simulateButton("Left", false)
        simulateButton("Right", false)
        simulateButton("Throttle", true)

        local timeOut = 0
        while timeOut < 6 do
            for _, p in pairs(allVehicleParts) do
                local n = p.Name:lower()
                if not (n:match("wheel") or n:match("tire") or n:match("rim") or n:match("suspension") or n:match("whl")) then
                    p.CanCollide = false
                end
            end
            if (cPart.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude < 15 then break end
            timeOut = timeOut + task.wait(0.1)
        end

        simulateButton("Throttle", false)
        simulateButton("Brake", true)
        task.wait(0.8)
        simulateButton("Brake", false)

        for _, p in pairs(allVehicleParts) do
            if collisionStates[p] ~= nil then p.CanCollide = collisionStates[p] end
        end
    else
        logMsg("ON FOOT Mode.")
        if rt and hum then
            local approachPosCenter = targetPos + Vector3.new(3, 0, 0)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {c}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            local rayResult = ws:Raycast(approachPosCenter + Vector3.new(0, 200, 0), Vector3.new(0, -400, 0), raycastParams)

            local startPos = rayResult and (rayResult.Position + Vector3.new(0, 3, 0)) or (approachPosCenter + Vector3.new(0, 10, 0))

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
                if (rt.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude < 3.5 then break end
                timeOut = timeOut + task.wait(0.1)
            end
        end
    end
end

-- =========================================================================
-- DELIVERY LOOP
-- =========================================================================
getgenv().DeliveryLoop = task.spawn(function()
    while task.wait(0.5) do
        if not getgenv().AutoFarmDelivery then continue end

        if getgenv().JobPhase == "Init" then
            local mode = getgenv().DeliveryMode or "Safe"
            local pad = nil
            for _,v in pairs(ws:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" then pad = v; break end
            end
            if pad then
                logMsg("Route started: " .. mode)
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
                for i = 1, 2 do fRem("AttemptDeliveryComplete"); task.wait(0.5) end
                rWait(1, 5); fRem("AttemptDeliveryPickup")
                rWait(7, 16)
            else
                task.wait(1)
            end
        end
    end
end)
