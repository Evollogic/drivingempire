local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local plyrs = game:GetService("Players")
local lp = plyrs.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

-- ==========================================
-- SISTEMA DE LOGS E BOTÃO DE COPIAR
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

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0, 8)
uicorner.Parent = btn

btn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(table.concat(getgenv().DeliveryLogs, "\n"))
        btn.Text = "✅ Copiado!"
        task.wait(1.5)
        btn.Text = "📋 Copiar Logs"
    end
end)

-- ==========================================
-- SCRIPT DE DELIVERY
-- ==========================================
if getgenv().DeliveryScriptRunning then return end
getgenv().DeliveryScriptRunning = true
getgenv().DeliveryMode = getgenv().DeliveryMode or "Easy"

-- Força o script a começar pegando o trabalho, ignorando âncoras falsas
getgenv().JobPhase = "Pickup" 

addLog("Iniciando script de Delivery (Com Máquina de Estados)...")

local function fireRemote(name, ...)
    local remote = remotes:FindFirstChild(name)
    if not remote then 
        addLog("[ERRO] Remote NÃO encontrado: " .. name)
        return 
    end

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

task.spawn(function()
    while task.wait(1) do
        if not getgenv().AutoFarmDelivery then
            getgenv().DeliveryScriptRunning = false
            addLog("AutoFarm desligado.")
            break
        end

        local root = getRoot()
        if not root then continue end

        if getgenv().JobPhase == "Pickup" then
            addLog("[FASE 1] Procurando prancheta de trabalho...")
            local jobPad = nil
            for _, v in pairs(ws:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" then
                    jobPad = v
                    break
                end
            end

            if jobPad then
                addLog("[FASE 1] Prancheta encontrada. Pegando trabalho...")
                local padPos = jobPad.Parent.Position
                root.Velocity = Vector3.zero
                root.AssemblyLinearVelocity = Vector3.zero
                root.CFrame = CFrame.new(padPos + Vector3.new(0, 5, 0))
                task.wait(1)
                
                pcall(function() fireproximityprompt(jobPad) end)
                task.wait(0.5)
                
                fireRemote("SetDeliveryMode", getgenv().DeliveryMode)
                task.wait(0.5)
                fireRemote("RequestStartJobSession", "Delivery")
                task.wait(0.5)
                fireRemote("AttemptDeliveryPickup")
                
                addLog("[FASE 1] Trabalho solicitado. Mudando para Fase de Entrega.")
                task.wait(2)
                
                -- Agora sim ele tem permissão para procurar o alvo
                getgenv().JobPhase = "Deliver"
            else
                addLog("[ERRO] Nenhuma prancheta encontrada no mapa.")
            end

        elseif getgenv().JobPhase == "Deliver" then
            local target = ws:FindFirstChild("DeliveryTargetAnchor")
            
            if target and target.Parent == ws then
                addLog("[FASE 2] Alvo encontrado. Realizando entrega...")
                root.Velocity = Vector3.zero
                root.AssemblyLinearVelocity = Vector3.zero
                root.CFrame = CFrame.new(target.Position + Vector3.new(0, 5, 0))
                task.wait(1)
                
                fireRemote("AttemptDeliveryComplete")
                task.wait(1)
                
                addLog("[FASE 2] Entrega finalizada. Retornando para buscar mais.")
                -- Volta para a fase 1 para pegar a próxima caixa
                getgenv().JobPhase = "Pickup"
            else
                addLog("[FASE 2] Aguardando o alvo de entrega aparecer...")
            end
        end
    end
end)
