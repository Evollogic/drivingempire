local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local plyrs = game:GetService("Players")
local lp = plyrs.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

if getgenv().DeliveryScriptRunning then return end
getgenv().DeliveryScriptRunning = true
getgenv().DeliveryMode = getgenv().DeliveryMode or "Easy"

-- ========================================================
-- O MEU ERRO ESTAVA AQUI: Essa função agora garante que
-- o comando certo (FireServer ou InvokeServer) seja usado!
-- ========================================================
local function fireRemote(name, ...)
    local remote = remotes:FindFirstChild(name)
    if not remote then return end
    
    if remote:IsA("RemoteEvent") then
        pcall(function() remote:FireServer(...) end)
    elseif remote:IsA("RemoteFunction") then
        pcall(function() remote:InvokeServer(...) end)
    end
end

local function getRoot()
    local char = lp.Character
    if not char then return nil end
    local hum = char:FindFirstChild("Humanoid")
    if hum and hum.Sit then
        hum.Sit = false
        task.wait(0.2)
    end
    return char:FindFirstChild("HumanoidRootPart")
end

task.spawn(function()
    while task.wait(0.5) do
        if not getgenv().AutoFarmDelivery then
            getgenv().DeliveryScriptRunning = false
            break
        end

        local root = getRoot()
        if not root then continue end

        local target = ws:FindFirstChild("DeliveryTargetAnchor")

        if target and target.Parent == ws then
            -- 1. FINALIZA ENTREGA
            root.Velocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = CFrame.new(target.Position + Vector3.new(0, 5, 0))
            task.wait(0.5)
            fireRemote("AttemptDeliveryComplete")
        else
            -- 2. PEGA O TRABALHO
            local jobPad = nil
            for _, v in pairs(ws:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" then
                    jobPad = v
                    break
                end
            end

            if jobPad then
                local padPos = jobPad.Parent.Position
                
                -- Teleporta pra prancheta
                root.Velocity = Vector3.zero
                root.AssemblyLinearVelocity = Vector3.zero
                root.CFrame = CFrame.new(padPos + Vector3.new(0, 5, 0))
                
                task.wait(1) -- Tempo pro servidor registrar
                
                -- Aciona a prancheta
                pcall(function() fireproximityprompt(jobPad) end)
                task.wait(0.5)
                
                -- Envia as ordens com a correção definitiva
                fireRemote("SetDeliveryMode", getgenv().DeliveryMode)
                task.wait(0.5)
                
                fireRemote("RequestStartJobSession", "Delivery")
                task.wait(0.5)
                
                fireRemote("AttemptDeliveryPickup")
                
                task.wait(2) -- Aguarda a caixa aparecer nas costas
            end
        end
    end
end)
