local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local plyrs = game:GetService("Players")
local lp = plyrs.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

-- ==========================================
-- CONFIGURAÇÕES DA ENTREGA
-- ==========================================
if getgenv().DeliveryLoop then pcall(task.cancel, getgenv().DeliveryLoop) end
getgenv().DeliveryScriptRunning = false
getgenv().AutoFarmDelivery = true
getgenv().JobPhase = "Init" 
getgenv().DeliveryMode = getgenv().DeliveryMode or "Easy"

-- TEMPO DE ESPERA NA ÂNCORA (Para o jogo pagar o valor cheio e não bugar)
-- Você pode ajustar isso no seu Hub depois!
getgenv().DeliveryWaitTime = 12 

-- ==========================================
-- LOGS (Para monitoramento)
-- ==========================================
getgenv().DeliveryLogs = {}
local function addLog(msg)
    local timeStr = tostring(os.date("%X"))
    local logMsg = "[" .. timeStr .. "] " .. tostring(msg)
    print(logMsg)
    table.insert(getgenv().DeliveryLogs, logMsg)
end

local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("CopyLogUI") then CoreGui.CopyLogUI:Destroy() end
local sg = Instance.new("ScreenGui")
sg.Name = "CopyLogUI"
sg.Parent = CoreGui
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 150, 0, 40)
btn.Position = UDim2.new(0.5, -75, 0, 10)
btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.TextScaled = true
btn.Text = "📋 Copiar Logs"
btn.Parent = sg
btn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(table.concat(getgenv().DeliveryLogs, "\n"))
        btn.Text = "✅ Copiado!"
        task.wait(1.5)
        btn.Text = "📋 Copiar Logs"
    end
end)

-- ==========================================
-- FUNÇÕES PRINCIPAIS
-- ==========================================
local function fireRemote(name, ...)
    local remote = remotes:FindFirstChild(name)
    if not remote then return end
    if remote:IsA("RemoteEvent") then
        pcall(remote.FireServer, remote, ...)
    elseif remote:IsA("RemoteFunction") then
        task.spawn(pcall, remote.InvokeServer, remote, ...)
    end
end

local function getRoot()
    return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
end

local function teleportSafe(root, pos)
    root.Velocity = Vector3.zero
    root.AssemblyLinearVelocity = Vector3.zero
    root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) 
end

local function getJobPad()
    for _, v in pairs(ws:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" then
            return v
        end
    end
    return nil
end

-- ==========================================
-- LOOP DE 3 FASES (100% REMOTO NA COLETA)
-- ==========================================
addLog("Iniciando versão: Coleta Remota + Timer de Espera...")

getgenv().DeliveryLoop = task.spawn(function()
    while task.wait(0.8) do
        if not getgenv().AutoFarmDelivery then
            addLog("AutoFarm desligado.")
            break
        end

        local root = getRoot()
        if not root then continue end

        -- PASSO 1: INICIA O EXPEDIENTE (Apenas 1x)
        if getgenv().JobPhase == "Init" then
            addLog("[INIT] Iniciando expediente...")
            local jobPad = getJobPad()
            
            if jobPad then
                -- Opcional: Se o seu executor aceita fireproximityprompt de longe,
                -- você pode até apagar essa linha de teleportSafe abaixo no futuro!
                teleportSafe(root, jobPad.Parent.Position)
                task.wait(0.5)
                
                pcall(function() fireproximityprompt(jobPad) end)
                task.wait(0.5)
                
                fireRemote("SetDeliveryMode", getgenv().DeliveryMode)
                task.wait(0.5)
                fireRemote("RequestStartJobSession", "Delivery")
                
                task.wait(1)
                getgenv().JobPhase = "Pickup"
            end

        -- PASSO 2: PEGA A CAIXA (VIA DE LONGE)
        elseif getgenv().JobPhase == "Pickup" then
            addLog("[COLETA] Solicitando caixa via satélite (sem voltar)...")
            
            -- Não voltamos para a base! Apenas mandamos o sinal pro servidor.
            fireRemote("AttemptDeliveryPickup")
            
            task.wait(1.5) -- Tempo pro servidor processar e colocar a âncora no mapa
            getgenv().JobPhase = "Deliver"

        -- PASSO 3: ENTREGA A CAIXA (COM TIMER)
        elseif getgenv().JobPhase == "Deliver" then
            local target = ws:FindFirstChild("DeliveryTargetAnchor")
            
            if target and target.Parent == ws then
                addLog("[ENTREGA] Âncora encontrada. Teleportando...")
                teleportSafe(root, target.Position)
                
                -- Aguarda o tempo necessário para o jogo validar o trajeto/dinheiro
                addLog("[TIMER] Aguardando " .. getgenv().DeliveryWaitTime .. "s para burlar anti-cheat/ganhar máximo...")
                task.wait(getgenv().DeliveryWaitTime)
                
                fireRemote("AttemptDeliveryComplete")
                
                task.wait(0.8)
                getgenv().JobPhase = "Pickup" -- Pula direto pra pegar outra sem voltar!
            else
                addLog("[ENTREGA] Procurando âncora verde...")
            end
        end
    end
end)
