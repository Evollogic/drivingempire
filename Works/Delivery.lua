local rs = game:GetService("ReplicatedStorage")
local ws = game:GetService("Workspace")
local plyrs = game:GetService("Players")
local lp = plyrs.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

local reqStart = remotes:FindFirstChild("RequestStartJobSession")
local setMode = remotes:FindFirstChild("SetDeliveryMode")
local attPickup = remotes:FindFirstChild("AttemptDeliveryPickup")
local attComplete = remotes:FindFirstChild("AttemptDeliveryComplete")

if getgenv().DeliveryScriptRunning then return end
getgenv().DeliveryScriptRunning = true
getgenv().DeliveryMode = getgenv().DeliveryMode or "Easy"

-- Função para restaurar a física quando você DESLIGAR o farm
local function restorePhysics()
    local char = lp.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then root.Anchored = false end
    
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("BasePart") then
            v.CanCollide = true
        end
    end
end

local function getRoot()
    local char = lp.Character
    if not char then return nil end
    
    -- Ejetar do carro se estiver sentado
    local hum = char:FindFirstChild("Humanoid")
    if hum and hum.Sit then
        hum.Sit = false
        task.wait(0.1)
    end
    return char:FindFirstChild("HumanoidRootPart")
end

task.spawn(function()
    while task.wait(0.2) do
        -- Se desligou o farm, devolve a física ao jogador e para o script
        if not getgenv().AutoFarmDelivery then
            restorePhysics()
            getgenv().DeliveryScriptRunning = false
            break
        end

        local root = getRoot()
        if not root then continue end

        local target = ws:FindFirstChild("DeliveryTargetAnchor")

        if target and target.Parent == ws then
            -- TEM ENTREGA: Congela o jogador no ar exatamente no local
            local pos = target.Position
            
            -- Desliga colisões (Modo Fantasma)
            for _, v in pairs(lp.Character:GetChildren()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
            
            -- Congela o personagem no ar (NUNCA MAIS CAI NO VOID)
            root.Velocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
            root.Anchored = true
            root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)

            if attComplete then pcall(function() attComplete:InvokeServer() end) end

        else
            -- PROCURAR JOB PAD PARA INICIAR
            local jobPad = nil
            for _, v in pairs(ws:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" and v.Parent then
                    jobPad = v.Parent
                    break
                end
            end

            if jobPad then
                local pos = jobPad.Position
                
                -- Desliga colisões (Modo Fantasma)
                for _, v in pairs(lp.Character:GetChildren()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end

                -- Congela o personagem no ar acima da prancheta
                root.Velocity = Vector3.zero
                root.AssemblyLinearVelocity = Vector3.zero
                root.Anchored = true
                root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)

                task.wait(0.2)

                if setMode then pcall(function() setMode:FireServer(getgenv().DeliveryMode) end) end

                for _, prompt in pairs(jobPad:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        prompt.MaxActivationDistance = 50
                        pcall(function() fireproximityprompt(prompt) end)
                    end
                end

                task.wait(0.2)
                
                if reqStart then pcall(function() reqStart:FireServer("Delivery", "jobPad", "Safe") end) end
                if attPickup then pcall(function() attPickup:InvokeServer() end) end
                
                task.wait(1.5)
            end
        end
    end
end)
