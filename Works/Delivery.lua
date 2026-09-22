local rs = game:GetService("ReplicatedStorage")
local ws = game:GetService("Workspace")
local lp = game:GetService("Players").LocalPlayer
local remotes = rs:WaitForChild("Remotes")

local reqStart = remotes:FindFirstChild("RequestStartJobSession")
local setMode = remotes:FindFirstChild("SetDeliveryMode")
local attPickup = remotes:FindFirstChild("AttemptDeliveryPickup")
local attComplete = remotes:FindFirstChild("AttemptDeliveryComplete")

if getgenv().DeliveryScriptRunning then return end
getgenv().DeliveryScriptRunning = true
getgenv().DeliveryMode = getgenv().DeliveryMode or "Easy"

task.spawn(function()
    local plat = Instance.new("Part")
    plat.Size = Vector3.new(20, 2, 20)
    plat.Anchored = true
    plat.Transparency = 0.6
    plat.CanCollide = true
    -- Adicionado uma cor verdinha pra você VER a placa flutuando e te salvando
    plat.Material = Enum.Material.ForceField
    plat.Color = Color3.new(0, 1, 0)
    
    local function getRoot()
        local char = lp.Character
        if not char then return nil end
        
        -- Se estiver no carro, sai do carro antes de teleportar (evita bugar o mapa)
        local hum = char:FindFirstChild("Humanoid")
        if hum and hum.Sit then
            hum.Sit = false
            task.wait(0.1)
        end
        
        return char:FindFirstChild("HumanoidRootPart")
    end

    while task.wait(0.2) do
        if not getgenv().AutoFarmDelivery then
            plat.Parent = nil
            getgenv().DeliveryScriptRunning = false
            break
        end

        local root = getRoot()
        if not root then continue end

        plat.Parent = ws
        local target = ws:FindFirstChild("DeliveryTargetAnchor")

        if target then
            local pos = target.Position
            -- CORREÇÃO: Plataforma 5 studs ACIMA DO CHÃO
            plat.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
            
            root.Velocity = Vector3.new(0, 0, 0)
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            -- CORREÇÃO: Jogador 8 studs ACIMA DO CHÃO (Cai cravado na plataforma)
            root.CFrame = CFrame.new(pos + Vector3.new(0, 8, 0))

            if attComplete then pcall(function() attComplete:InvokeServer() end) end
        else
            local jobPad = nil
            for _, v in pairs(ws:GetDescendants()) do
                if v.Name == "JobPadPrompt" and v.Parent then
                    jobPad = v.Parent
                    break
                end
            end

            if jobPad then
                local pos = jobPad.Position
                -- CORREÇÃO: Plataforma 5 studs ACIMA do JobPad
                plat.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
                
                root.Velocity = Vector3.new(0, 0, 0)
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                -- CORREÇÃO: Jogador cai cravado na plataforma
                root.CFrame = CFrame.new(pos + Vector3.new(0, 8, 0))

                task.wait(0.5)

                if setMode then pcall(function() setMode:FireServer(getgenv().DeliveryMode) end) end

                for _, prompt in pairs(jobPad:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        prompt.MaxActivationDistance = 50
                        pcall(function() fireproximityprompt(prompt) end)
                    end
                end

                task.wait(0.5)
                if reqStart then pcall(function() reqStart:FireServer("Delivery", "jobPad", "Safe") end) end
                if attPickup then pcall(function() attPickup:InvokeServer() end) end
                task.wait(1.5)
            end
        end
    end
end)
