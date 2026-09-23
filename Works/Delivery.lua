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

-- Cria o botão na tela
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("CopyLogUI") then
    CoreGui.CopyLogUI:Destroy()
end

local sg = Instance.new("ScreenGui")
sg.Name = "CopyLogUI"
sg.Parent = CoreGui

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 150, 0, 40)
btn.Position = UDim2.new(0.5, -75, 0, 10) -- Fica no topo da tela
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
        local allLogs = table.concat(getgenv().DeliveryLogs, "\n")
        setclipboard(allLogs)
        btn.Text = "✅ Copiado!"
        task.wait(1.5)
        btn.Text = "📋 Copiar Logs"
    else
        btn.Text = "❌ Erro: Sem setclipboard"
    end
end)

-- ==========================================
-- SCRIPT DE DELIVERY
-- ==========================================
if getgenv().DeliveryScriptRunning then return end
getgenv().DeliveryScriptRunning = true
getgenv().DeliveryMode = getgenv().DeliveryMode or "Easy"

addLog("Iniciando script de Delivery...")

local function fireRemote(name, ...)
    local remote = remotes:FindFirstChild(name)
    if not remote then 
        addLog("[ERRO] Remote NÃO encontrado: " .. name)
        return 
    end

    if remote:IsA("RemoteEvent") then
        addLog("[OK] FireServer -> " .. name)
        pcall(remote.FireServer, remote, ...)
    elseif remote:IsA("RemoteFunction") then
        addLog("[OK] InvokeServer -> " .. name)
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
            addLog("AutoFarmDelivery desligado, parando loop.")
            break
        end

        local root = getRoot()
        if not root then continue end

        local target = ws:FindFirstChild("DeliveryTargetAnchor")
        
        if target and target.Parent == ws then
            addLog("[STATUS] Alvo de entrega encontrado! Finalizando...")
            root.Velocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = CFrame.new(target.Position + Vector3.new(0, 5, 0))
            task.wait(0.5)
            fireRemote("AttemptDeliveryComplete")
        else
            addLog("[STATUS] Sem caixa. Procurando JobPadPrompt...")
            local jobPad = nil
            for _, v in pairs(ws:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" then
                    jobPad = v
                    break
                end
            end

            if jobPad then
                addLog("[STATUS] JobPad encontrado. Teleportando...")
                local padPos = jobPad.Parent.Position
                root.Velocity = Vector3.zero
                root.AssemblyLinearVelocity = Vector3.zero
                root.CFrame = CFrame.new(padPos + Vector3.new(0, 5, 0))
                task.wait(1)
                
                addLog("[STATUS] Ativando ProximityPrompt da prancheta...")
                local s, e = pcall(function() fireproximityprompt(jobPad) end)
                if not s then addLog("[ERRO] Falha no fireproximityprompt: " .. tostring(e)) end
                task.wait(0.5)
                
                addLog("[STATUS] Solicitando o trabalho ao servidor...")
                fireRemote("SetDeliveryMode", getgenv().DeliveryMode)
                task.wait(0.5)
                fireRemote("RequestStartJobSession", "Delivery")
                task.wait(0.5)
                fireRemote("AttemptDeliveryPickup")
                task.wait(2)
            else
                addLog("[AVISO] Nenhum JobPadPrompt encontrado no Workspace!")
            end
        end
    end
end)
