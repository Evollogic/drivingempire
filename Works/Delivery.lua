local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local plyrs = game:GetService("Players")
local lp = plyrs.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

if getgenv().DeliveryScriptRunning then return end
getgenv().DeliveryScriptRunning = true

task.spawn(function()
    local function getRoot()
        return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    end

    local plat = Instance.new("Part")
    plat.Size = Vector3.new(40, 5, 40)
    plat.Anchored = true
    -- Deixei 0.5 (meio transparente) para você VER que está seguro em cima dela
    plat.Transparency = 0.5 
    plat.CanCollide = true
    plat.Name = "SafePlat"

    while task.wait(1) do
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
            local startPos = target.Position
            
            -- PLATAFORMA MUITO ALTO (10 studs acima do chão)
            plat.CFrame = CFrame.new(startPos + Vector3.new(0, 10, 0))

            while target and target.Parent == ws and (target.Position - startPos).Magnitude < 2 and getgenv().AutoFarmDelivery do
                local currentRoot = getRoot()
                if currentRoot then
                    currentRoot.Velocity = Vector3.new(0, 0, 0)
                    currentRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    -- JOGADOR CAINDO DIRETO NA PLATAFORMA (14 studs acima do chão)
                    currentRoot.CFrame = CFrame.new(startPos + Vector3.new(0, 14, 0))
                end
                task.wait(0.5)
            end
        else
            local jobPad = nil
            for _, v in pairs(ws:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" then
                    if v.Parent and v.Parent:IsA("BasePart") then
                        jobPad = v.Parent
                        break
                    end
                end
            end

            if jobPad then
                local padPos = jobPad.Position
                
                -- PLATAFORMA MUITO ALTO (10 studs acima do JobPad)
                plat.CFrame = CFrame.new(padPos + Vector3.new(0, 10, 0))
                
                root.Velocity = Vector3.new(0, 0, 0)
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                -- JOGADOR SEGURO NO AR (14 studs acima)
                root.CFrame = CFrame.new(padPos + Vector3.new(0, 14, 0))

                task.wait(1)

                if fireproximityprompt then
                    for _, prompt in pairs(jobPad:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") then
                            -- Força o alcance do botão pra 100, assim você ativa mesmo estando alto
                            prompt.MaxActivationDistance = 100 
                            pcall(function() fireproximityprompt(prompt) end)
                        end
                    end
                end

                task.wait(1)

                local startRemote = remotes:FindFirstChild("RequestStartJobSession")
                if startRemote then
                    pcall(function() startRemote:InvokeServer("Delivery", "jobPad", "Safe") end)
                    pcall(function() startRemote:FireServer("Delivery", "jobPad", "Safe") end)
                end

                task.wait(1)

                local pickupRemote = remotes:FindFirstChild("AttemptDeliveryPickup")
                if pickupRemote then
                    pcall(function() pickupRemote:InvokeServer() end)
                    pcall(function() pickupRemote:FireServer() end)
                end

                task.wait(3)
            end
        end
    end
end)
