local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local plyrs = game:GetService("Players")
local lp = plyrs.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

if getgenv().DeliveryScriptRunning then return end
getgenv().DeliveryScriptRunning = true
getgenv().DeliveryMode = getgenv().DeliveryMode or "Easy"

task.spawn(function()
    local function getRoot()
        local char = lp.Character
        if not char then return nil end
        -- Remove do carro para não bugar teleporte
        local hum = char:FindFirstChild("Humanoid")
        if hum and hum.Sit then
            hum.Sit = false
            task.wait(0.2)
        end
        return char:FindFirstChild("HumanoidRootPart")
    end

    -- Cria a Plataforma Plana (Vermelha para você ver que está funcionando)
    local plat = Instance.new("Part")
    plat.Size = Vector3.new(40, 2, 40)
    plat.Anchored = true
    plat.Transparency = 0.5
    plat.CanCollide = true
    plat.Material = Enum.Material.Neon
    plat.Color = Color3.new(1, 0, 0)
    plat.Name = "SafePlat"

    while task.wait(0.5) do
        if not getgenv().AutoFarmDelivery then
            plat.Parent = nil
            getgenv().DeliveryScriptRunning = false
            break
        end

        plat.Parent = ws
        local root = getRoot()
        if not root then continue end

        local target = ws:FindFirstChild("DeliveryTargetAnchor")

        if target and target.Parent == ws then
            -- ==============================================
            -- 1. FAZENDO A ENTREGA
            -- ==============================================
            local pos = target.Position
            -- Plataforma 2 studs acima do chão, sem inclinação
            plat.CFrame = CFrame.new(pos.X, pos.Y + 2, pos.Z)
            
            -- Jogador 5 studs acima (cai em pé na plataforma)
            root.Velocity = Vector3.new(0, 0, 0)
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            root.CFrame = CFrame.new(pos.X, pos.Y + 5, pos.Z)

            -- Finaliza a entrega
            local complete = remotes:FindFirstChild("AttemptDeliveryComplete")
            if complete then
                pcall(function() complete:InvokeServer() end)
                pcall(function() complete:FireServer() end)
            end
        else
            -- ==============================================
            -- 2. INICIANDO O SERVIÇO NA PRANCHETA
            -- ==============================================
            local jobPad = nil
            for _, v in pairs(ws:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" and v.Parent then
                    jobPad = v.Parent
                    break
                end
            end

            if jobPad then
                local pos = jobPad.Position
                
                -- Plataforma 2 studs acima do chão
                plat.CFrame = CFrame.new(pos.X, pos.Y + 2, pos.Z)
                
                -- Jogador cai em pé na plataforma
                root.Velocity = Vector3.new(0, 0, 0)
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                root.CFrame = CFrame.new(pos.X, pos.Y + 5, pos.Z)

                -- Pausa pro jogo carregar sua posição
                task.wait(0.5)

                -- 2.1 Manda a dificuldade (Easy/Hard)
                local setMode = remotes:FindFirstChild("SetDeliveryMode")
                if setMode then
                    pcall(function() setMode:FireServer(getgenv().DeliveryMode) end)
                end

                -- 2.2 Aciona a prancheta
                for _, prompt in pairs(jobPad:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        prompt.MaxActivationDistance = 50
                        pcall(function() fireproximityprompt(prompt) end)
                    end
                end

                task.wait(0.5)

                -- 2.3 Começa a sessão
                local startRemote = remotes:FindFirstChild("RequestStartJobSession")
                if startRemote then
                    pcall(function() startRemote:InvokeServer("Delivery", "jobPad", "Safe") end)
                    pcall(function() startRemote:FireServer("Delivery", "jobPad", "Safe") end)
                end

                task.wait(0.5)

                -- 2.4 Pega o pacote
                local pickupRemote = remotes:FindFirstChild("AttemptDeliveryPickup")
                if pickupRemote then
                    pcall(function() pickupRemote:InvokeServer() end)
                    pcall(function() pickupRemote:FireServer() end)
                end
                
                -- Pausa pro alvo da entrega aparecer no mapa
                task.wait(2)
            end
        end
    end
end)
