local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local plyrs = game:GetService("Players")
local lp = plyrs.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

if getgenv().DeliveryScriptRunning then return end
getgenv().DeliveryScriptRunning = true
getgenv().DeliveryMode = getgenv().DeliveryMode or "Easy"

task.spawn(function()
    -- CRIA UM PISO GIGANTESCO PARA VOCÊ NÃO CAIR
    local plat = Instance.new("Part")
    plat.Size = Vector3.new(100, 5, 100)
    plat.Anchored = true
    plat.CanCollide = true
    plat.Transparency = 0.5
    plat.Material = Enum.Material.Neon
    plat.Color = Color3.new(1, 0.5, 0) -- Piso laranja
    plat.Name = "AntiVoidFloor"

    local function getRoot()
        local char = lp.Character
        if not char then return nil end
        
        local hum = char:FindFirstChild("Humanoid")
        if hum and hum.Sit then
            hum.Sit = false
            task.wait(0.2)
        end
        
        -- Garante que o boneco não está com nenhum bug de voo dos scripts anteriores
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.Anchored = false
            local bv = root:FindFirstChild("AntiFall_Delivery")
            if bv then bv:Destroy() end
        end
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = true end
        end
        
        return root
    end

    while task.wait(0.5) do
        if not getgenv().AutoFarmDelivery then
            plat.Parent = nil
            getgenv().DeliveryScriptRunning = false
            break
        end

        local root = getRoot()
        if not root then continue end
        plat.Parent = ws

        local target = ws:FindFirstChild("DeliveryTargetAnchor")

        if target and target.Parent == ws then
            -- ==============================================
            -- 1. ENTREGANDO O PACOTE
            -- ==============================================
            local pos = target.Position
            
            -- Piso vai pra baixo da entrega
            plat.CFrame = CFrame.new(pos.X, pos.Y - 2, pos.Z)
            
            -- Boneco vai pra cima da entrega (Pisando firme no piso)
            root.Velocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
            
            task.wait(0.5) -- Pausa pro servidor registrar sua presença

            local complete = remotes:FindFirstChild("AttemptDeliveryComplete")
            if complete then pcall(function() complete:InvokeServer() end) end

        else
            -- ==============================================
            -- 2. PEGANDO O TRABALHO
            -- ==============================================
            local jobPad = nil
            for _, v in pairs(ws:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" and v.Parent then
                    jobPad = v.Parent
                    break
                end
            end

            if jobPad then
                local padPos = jobPad.Parent.Position
                
                -- Piso gigante vai exatamente pra baixo da prancheta
                plat.CFrame = CFrame.new(padPos.X, padPos.Y - 3, padPos.Z)
                
                -- Boneco teleporta em pé na prancheta
                root.Velocity = Vector3.zero
                root.AssemblyLinearVelocity = Vector3.zero
                root.CFrame = CFrame.new(padPos.X, padPos.Y + 3, padPos.Z)

                -- TEMPO CRÍTICO: Espera 1 segundo pro servidor ver que você parou de andar
                -- Isso é o que impede o servidor de negar o cargo de delivery!
                task.wait(1) 

                -- 1. Aciona o botão da prancheta
                pcall(function() fireproximityprompt(jobPad) end)
                task.wait(0.5)

                -- 2. Envia o pedido de iniciar
                local reqStart = remotes:FindFirstChild("RequestStartJobSession")
                if reqStart then pcall(function() reqStart:FireServer("Delivery") end) end
                task.wait(0.5)

                -- 3. Escolhe a dificuldade
                local setMode = remotes:FindFirstChild("SetDeliveryMode")
                if setMode then pcall(function() setMode:FireServer(getgenv().DeliveryMode) end) end
                task.wait(0.5)

                -- 4. Pega o pacote físico
                local pickup = remotes:FindFirstChild("AttemptDeliveryPickup")
                if pickup then pcall(function() pickup:InvokeServer() end) end

                -- Aguarda 2.5s pro pacote nascer nas suas costas e o alvo spawnar no mapa
                task.wait(2.5)
            end
        end
    end
end)
