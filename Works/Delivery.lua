local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local plyrs = game:GetService("Players")
local lp = plyrs.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

-- ==========================================
-- DESTRÓI VERSÕES ANTIGAS DO SCRIPT
-- ==========================================
if getgenv().DeliveryLoop then
    pcall(task.cancel, getgenv().DeliveryLoop)
end
getgenv().AutoFarmDelivery = true
getgenv().JobPhase = "Pickup" 
getgenv().DeliveryMode = getgenv().DeliveryMode or "Easy"

-- ==========================================
-- SISTEMA DE LOGS UI
-- ==========================================
getgenv().DeliveryLogs = {}
local function addLog(msg)
    local timeStr = tostring(os.date("%X"))
    local logMsg = "[" .. timeStr .. "] " .. tostring(msg)
    print(logMsg)
    table.insert(getgenv().DeliveryLogs, logMsg)
end

local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("CopyLogUI") then
    CoreGui.CopyLogUI:Destroy()
end

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
-- SCRIPT DE DELIVERY CORRIGIDO
-- ==========================================
addLog("Iniciando NOVO script (Anti-Queda e Loop Fix)...")

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
    local char = lp.Character
    if not char then return nil end
    local hum = char:FindFirstChild("Humanoid")
    if hum and hum.Sit then
        hum.Sit = false
        task.wait(0.2)
    end
    return char:FindFirstChild("HumanoidRootPart")
end

-- Função segura de teleporte (Congela o boneco no ar)
local function teleportSafe(root, pos)
    root.Velocity = Vector3.zero
    root.AssemblyLinearVelocity = Vector3.zero
    root.CFrame = CFrame.new(pos + Vector3.new(0, 10, 0)) -- Mais alto pra garantir
    root.Anchored = true -- Congela no ar
end

getgenv().DeliveryLoop = task.spawn(function()
    while task.wait(1) do
        if not getgenv().AutoFarmDelivery then
            addLog("AutoFarm desligado.")
            break
        end

        local root = getRoot()
        if not root then continue end

        if getgenv().JobPhase == "Pickup" then
            addLog("[FASE 1] Procurando prancheta...")
            local jobPad = nil
            for _, v in pairs(ws:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" then
                    jobPad = v
                    break
                end
            end

            if jobPad then
                addLog("[FASE 1] Teleportando e ancorando no ar...")
                teleportSafe(root, jobPad.Parent.Position)
                task.wait(1)
                
                pcall(function() fireproximityprompt(jobPad) end)
                task.wait(0.5)
                
                fireRemote("SetDeliveryMode", getgenv().DeliveryMode)
                task.wait(0.5)
                fireRemote("RequestStartJobSession", "Delivery")
                task.wait(0.5)
                fireRemote("AttemptDeliveryPickup")
                
                task.wait(2)
                root.Anchored = false -- Descongela
                addLog("[FASE 1] Trabalho pego! Mudando pra Fase 2.")
                
                getgenv().JobPhase = "Deliver"
            else
                addLog("[ERRO] Prancheta não encontrada.")
            end

        elseif getgenv().JobPhase == "Deliver" then
            local target = ws:FindFirstChild("DeliveryTargetAnchor")
            
            if target and target.Parent == ws then
                addLog("[FASE 2] Alvo encontrado. Teleportando...")
                teleportSafe(root, target.Position)
                task.wait(1)
                
                fireRemote("AttemptDeliveryComplete")
                task.wait(1)
                
                root.Anchored = false -- Descongela
                addLog("[FASE 2] Entrega concluída! Retornando pra Fase 1.")
                getgenv().JobPhase = "Pickup"
            else
                addLog("[FASE 2] Aguardando o alvo (a âncora verde) spawnar...")
            end
        end
    end
end)
