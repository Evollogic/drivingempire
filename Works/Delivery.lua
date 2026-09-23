local ws,rs,lp=game:GetService("Workspace"),game:GetService("ReplicatedStorage"),game:GetService("Players").LocalPlayer
local remotes=rs:WaitForChild("Remotes")

if getgenv().DeliveryLoop then pcall(task.cancel,getgenv().DeliveryLoop) end
getgenv().AutoFarmDelivery,getgenv().JobPhase=true,"Init"

local function fRem(n,...)
    local r=remotes:FindFirstChild(n)
    if not r then return end
    if r:IsA("RemoteEvent") then
        pcall(r.FireServer,r,...)
    elseif r:IsA("RemoteFunction") then
        task.spawn(pcall,r.InvokeServer,r,...)
    end
end

local function getChar()
    local c = lp.Character
    return c, (c and c:FindFirstChild("HumanoidRootPart")), (c and c:FindFirstChild("Humanoid"))
end

getgenv().DeliveryLoop=task.spawn(function()
    while task.wait(0.5) do
        if not getgenv().AutoFarmDelivery then break end

        if getgenv().JobPhase=="Init" then
            local mode = (getgenv().DeliveryMode == "Hard") and "HighRisk" or "Safe"
            local pad=nil
            for _,v in pairs(ws:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name=="JobPadPrompt" then
                    pad=v
                    break
                end
            end

            if pad then
                local c, rt, hum = getChar()
                if rt then
                    rt.Velocity,rt.AssemblyLinearVelocity=Vector3.zero,Vector3.zero
                    rt.CFrame=CFrame.new(pad.Parent.Position+Vector3.new(0,50,0))
                end
                task.wait(1)
                fRem("RequestStartJobSession", "Delivery", "jobPad", mode)
                task.wait(1)
                fRem("AttemptDeliveryPickup")
                
                -- 7 segundos de espera na primeira coleta
                task.wait(7)
                getgenv().JobPhase="Farming"
            end

        elseif getgenv().JobPhase=="Farming" then
            local t = ws:FindFirstChild("DeliveryTargetAnchor")
            if t and t.Parent == ws then
                local c, rt, hum = getChar()
                
                -- Vem do alto (+50 metros) e cai um pouco fora do centro (+10 no X e Z)
                if rt then
                    rt.Velocity, rt.AssemblyLinearVelocity = Vector3.zero, Vector3.zero
                    rt.CFrame = CFrame.new(t.Position + Vector3.new(10, 50, 10))
                end

                -- Fica forçando a entrega
                for i = 1, 2 do
                    fRem("AttemptDeliveryComplete")
                    task.wait(0.5)
                end
                
                -- 1 segundo de espera na entrega cravado
                task.wait(1)
                
                -- Pede a próxima caixa de longe
                fRem("AttemptDeliveryPickup")
                
                -- 7 segundos de espera na coleta da próxima caixa
                task.wait(7)
            end
        end
    end
end)
