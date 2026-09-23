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
        
        -- Sai do carro imediatamente
        local hum = char:FindFirstChild("Humanoid")
        if hum and hum.Sit then
            hum.Sit = false
            task.wait(0.2)
        end
        return char:FindFirstChild("HumanoidRootPart")
    end

    -- Função que limpa tudo quando você desliga o farm
    local function cleanUp()
        local root = getRoot()
        if root then
            local bv = root:FindFirstChild("AntiFall_Delivery")
            if bv then bv:Destroy() end
        end
        if lp.Character then
            for _, v in pairs(lp.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = true end
            end
        end
    end

    while task.wait(0.3) do
        if not getgenv().AutoFarmDelivery then
            cleanUp()
            getgenv().DeliveryScriptRunning = false
            break
        end

        local root = getRoot()
        if not root then continue end
        local char = lp.Character

        -- ==============================================
        -- 1. NOCLIP: ATRAVESSAR TUDO
        -- ==============================================
        -- Desliga a colisão de todas as partes do seu corpo.
        -- Se o jogo te jogar no meio da terra, você não buga, você atravessa.
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end

        -- ==============================================
        -- 2. BODYVELOCITY: FORÇA ANTI-GRAVIDADE (VOO INVISÍVEL)
        -- ==============================================
        -- Substitui a plataforma. Segura o jogador congelado no ar.
        local bv = root:FindFirstChild("AntiFall_Delivery")
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = "AntiFall_Delivery"
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9) -- Força infinita
            bv.Velocity = Vector3.new(0, 0, 0) -- Velocidade zero = Flutuar parado
            bv.Parent = root
        end

        local target = ws:FindFirstChild("DeliveryTargetAnchor")

        if target and target.Parent == ws then
            local pos = target.Position
            
            -- Teleporta você DEZ metros (10 studs) acima do alvo. Totalmente imune ao chão.
            root.CFrame = CFrame.new(pos.X, pos.Y + 10, pos.Z)
            
            local complete = remotes:FindFirstChild("AttemptDeliveryComplete")
            if complete then
                pcall(function() complete:InvokeServer() end)
                pcall(function() complete:FireServer() end)
            end
        else
            local jobPad = nil
            for _, v in pairs(ws:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" and v.Parent then
                    jobPad = v.Parent
                    break
                end
            end

            if jobPad then
                local pos = jobPad.Position
                
                -- Fica DEZ metros acima da prancheta
                root.CFrame = CFrame.new(pos.X, pos.Y + 10, pos.Z)
                
                task.wait(0.4)

                -- Envia Dificuldade
                local setMode = remotes:FindFirstChild("SetDeliveryMode")
                if setMode then
                    pcall(function() setMode:FireServer(getgenv().DeliveryMode) end)
                end

                -- Aciona o Prompt de longe (o max activation já está burlado pra 50)
                for _, prompt in pairs(jobPad:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        prompt.MaxActivationDistance = 50
                        pcall(function() fireproximityprompt(prompt) end)
                    end
                end

                task.wait(0.4)

                -- Inicia Serviço
                local startRemote = remotes:FindFirstChild("RequestStartJobSession")
                if startRemote then
                    pcall(function() startRemote:InvokeServer("Delivery", "jobPad", "Safe") end)
                    pcall(function() startRemote:FireServer("Delivery", "jobPad", "Safe") end)
                end

                task.wait(0.4)

                -- Pega pacote
                local pickupRemote = remotes:FindFirstChild("AttemptDeliveryPickup")
                if pickupRemote then
                    pcall(function() pickupRemote:InvokeServer() end)
                    pcall(function() pickupRemote:FireServer() end)
                end
                
                task.wait(1.5)
            end
        end
    end
end)
