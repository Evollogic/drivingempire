local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local plyrs = game:GetService("Players")
local lp = plyrs.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

-- ==========================================
-- DESTRÓI VERSÕES ANTIGAS
-- ==========================================
if getgenv().DeliveryLoop then
    pcall(task.cancel, getgenv().DeliveryLoop)
end
getgenv().DeliveryScriptRunning = false
getgenv().AutoFarmDelivery = true
getgenv().JobPhase = "Init" 
getgenv().DeliveryMode = getgenv().DeliveryMode or "Easy"

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
-- FUNÇÕES PRINCIPAIS (Sem frescura no Humanoid)
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
    local char = lp.Character
    if not char then return nil end
    -- Removida QUALQUER alteração de Humanoid (nada de Sit = false)
    return char:FindFirstChild("HumanoidRootPart")
end

local function teleportSafe(root, pos)
    root.Velocity = Vector3.zero
    root.AssemblyLinearVelocity = Vector3.zero
    -- Teleporta apenas 3 studs acima do alvo (o boneco toca o chão)
    -- E não usa mais Anchored!
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
-- LOOP DE 3 FASES
-- ==========================================
addLog("Iniciando versão limpa (Sem Anchored e Sem Humanoid)...")

getgenv().DeliveryLoop = task.spawn(function()
    while task.wait(0.8) do
        if not getgenv().AutoFarmDelivery then
            addLog("AutoFarm desligado.")
            break
        end

        local root = getRoot()
        if not root then continue end

        if getgenv().JobPhase == "Init" then
            addLog("[INIT] Indo iniciar trabalho...")
            local jobPad = getJobPad()
            
            if jobPad then
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

        elseif getgenv().JobPhase == "Pickup" then
            addLog("[COLETA] Pegando a caixa...")
            local jobPad = getJobPad()
            
            if jobPad then
                teleportSafe(root, jobPad.Parent.Position)
                task.wait(0.5)
                
                fireRemote("AttemptDeliveryPickup")
                
                task.wait(1.5)
                getgenv().JobPhase = "Deliver"
            end

        elseif getgenv().JobPhase == "Deliver" then
            local target = ws:FindFirstChild("DeliveryTargetAnchor")
            
            if target and target.Parent == ws then
                addLog("[ENTREGA] Alvo na mira...")
                teleportSafe(root, target.Position)
                task.wait(0.5)
                
                fireRemote("AttemptDeliveryComplete")
                
                task.wait(0.8)
                getgenv().JobPhase = "Pickup"
            else
                addLog("[ENTREGA] Procurando âncora verde...")
            end
        end
    end
end)
