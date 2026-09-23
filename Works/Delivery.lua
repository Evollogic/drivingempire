local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local lp = game:GetService("Players").LocalPlayer
local remotes = rs:WaitForChild("Remotes")

-- Limpa versões antigas
if getgenv().DeliveryLoop then pcall(task.cancel, getgenv().DeliveryLoop) end
getgenv().DeliveryScriptRunning = false
getgenv().AutoFarmDelivery = true
getgenv().JobPhase = "Init" 
getgenv().DeliveryMode = getgenv().DeliveryMode or "Easy"

-- ==========================================
-- TEMPO DE DESCARGA (AJUSTE AQUI)
-- ==========================================
getgenv().TempoDescarga = 2 -- Segundos que ele fica na âncora descarregando

-- LOGS
getgenv().DeliveryLogs = {}
local function addLog(msg)
    local logMsg = "[" .. tostring(os.date("%X")) .. "] " .. tostring(msg)
    print(logMsg)
    table.insert(getgenv().DeliveryLogs, logMsg)
end

local function fireRemote(name, ...)
    local remote = remotes:FindFirstChild(name)
    if not remote then return end
    if remote:IsA("RemoteEvent") then
        pcall(remote.FireServer, remote, ...)
    elseif remote:IsA("RemoteFunction") then
        task.spawn(pcall, remote.InvokeServer, remote, ...)
    end
end

local function teleportSafe(pos)
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.Velocity = Vector3.zero
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end
end

addLog("Iniciando Delivery Direto (Só Tempo de Descarga)...")

getgenv().DeliveryLoop = task.spawn(function()
    while task.wait(0.5) do
        if not getgenv().AutoFarmDelivery then break end
        
        -- PASSO 1: INICIA O TRABALHO (UMA VEZ SÓ NA VIDA)
        if getgenv().JobPhase == "Init" then
            local jobPad = nil
            for _, v in pairs(ws:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" then
                    jobPad = v
                    break
                end
            end
            
            if jobPad then
                addLog("[INIT] Configurando o expediente 1x...")
                teleportSafe(jobPad.Parent.Position)
                task.wait(1)
                
                pcall(function() fireproximityprompt(jobPad) end)
                task.wait(0.5)
                
                fireRemote("SetDeliveryMode", getgenv().DeliveryMode)
                task.wait(0.5)
                fireRemote("RequestStartJobSession", "Delivery")
                task.wait(0.5)
                fireRemote("AttemptDeliveryPickup") -- Pega a 1ª caixa
                
                task.wait(1.5)
                getgenv().JobPhase = "Farming"
            end

        -- PASSO 2: LOOP INFINITO NAS ÂNCORAS
        elseif getgenv().JobPhase == "Farming" then
            local target = ws:FindFirstChild("DeliveryTargetAnchor")
            
            if target and target.Parent == ws then
                addLog("[ENTREGA] Âncora achada! Teleportando...")
                teleportSafe(target.Position)
                
                -- Fica parado descarregando a caixa
                addLog("[DESCARGA] Descarregando pacote por " .. tostring(getgenv().TempoDescarga) .. "s...")
                task.wait(getgenv().TempoDescarga)
                
                -- Termina a entrega
                fireRemote("AttemptDeliveryComplete")
                addLog("[ENTREGA] Dinheiro no bolso!")
                
                -- Aguarda a âncora velha sumir e a nova aparecer sozinha
                task.wait(1.5)
            end
        end
    end
end)
