local coreGui = game:GetService("CoreGui")
local plyrs = game:GetService("Players")
local uis = game:GetService("UserInputService")
local ts = game:GetService("TweenService")
local http = game:GetService("HttpService")
local teleportService = game:GetService("TeleportService")
local lp = plyrs.LocalPlayer

local CURRENT_VERSION = "2.1"
local VERSION_URL = "https://raw.githubusercontent.com/Evollogic/drivingempire/main/version.txt"
local SCRIPT_URL = "https://raw.githubusercontent.com/Evollogic/drivingempire/main/Hub.lua"

local configName = "EmpireConfig.json"
local cfg = { delivery = false, deliveryMode = "Easy", autoHop = false }

if isfile and isfile(configName) then
    pcall(function()
        local data = http:JSONDecode(readfile(configName))
        if data and type(data) == "table" then
            if data.delivery ~= nil then cfg.delivery = data.delivery end
            if data.deliveryMode ~= nil then cfg.deliveryMode = data.deliveryMode end
            if data.autoHop ~= nil then cfg.autoHop = data.autoHop end
        end
    end)
end

local function saveCfg()
    if writefile then pcall(function() writefile(configName, http:JSONEncode(cfg)) end) end
end

for _, v in pairs(coreGui:GetChildren()) do if v.Name == "PremiumHub" then v:Destroy() end end
local playerGui = lp:WaitForChild("PlayerGui")
for _, v in pairs(playerGui:GetChildren()) do if v.Name == "PremiumHub" then v:Destroy() end end

local sg = Instance.new("ScreenGui")
sg.Name = "PremiumHub"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
pcall(function() sg.Parent = coreGui end)
if not sg.Parent then sg.Parent = playerGui end

local openBall = Instance.new("TextButton")
openBall.Size = UDim2.new(0, 45, 0, 45)
openBall.Position = UDim2.new(0, 10, 0.5, -22)
openBall.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
openBall.Text = "E"
openBall.TextColor3 = Color3.fromRGB(50, 150, 255)
openBall.Font = Enum.Font.GothamBlack
openBall.TextSize = 20
openBall.BorderSizePixel = 0
openBall.Visible = true
openBall.Parent = sg
Instance.new("UICorner", openBall).CornerRadius = UDim.new(1, 0)
local ballStroke = Instance.new("UIStroke", openBall)
ballStroke.Color = Color3.fromRGB(50, 150, 255)
ballStroke.Thickness = 2

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 380)
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -190)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Visible = false
mainFrame.Parent = sg
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 35)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)
local titleFix = Instance.new("Frame", topBar)
titleFix.Size = UDim2.new(1, 0, 0, 8)
titleFix.Position = UDim2.new(0, 0, 1, -8)
titleFix.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
titleFix.BorderSizePixel = 0

local titleText = Instance.new("TextLabel", topBar)
titleText.Size = UDim2.new(1, -50, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Empire Hub v" .. CURRENT_VERSION
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 13
titleText.TextXAlignment = Enum.TextXAlignment.Left

local minBtn = Instance.new("TextButton", topBar)
minBtn.Size = UDim2.new(0, 30, 0, 25)
minBtn.Position = UDim2.new(1, -38, 0, 5)
minBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
minBtn.Text = "X"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 4)

minBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false; openBall.Visible = true end)
openBall.MouseButton1Click:Connect(function() mainFrame.Visible = true; openBall.Visible = false end)

local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Size = UDim2.new(1, 0, 0, 35)
tabContainer.Position = UDim2.new(0, 0, 0, 35)
tabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
tabContainer.BorderSizePixel = 0

local tabFarm = Instance.new("TextButton", tabContainer)
tabFarm.Size = UDim2.new(0.5, 0, 1, 0)
tabFarm.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
tabFarm.Text = "Trabalhos"
tabFarm.TextColor3 = Color3.fromRGB(255, 255, 255)
tabFarm.Font = Enum.Font.GothamSemibold
tabFarm.TextSize = 13
tabFarm.BorderSizePixel = 0

local tabConfig = Instance.new("TextButton", tabContainer)
tabConfig.Size = UDim2.new(0.5, 0, 1, 0)
tabConfig.Position = UDim2.new(0.5, 0, 0, 0)
tabConfig.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
tabConfig.Text = "Configs"
tabConfig.TextColor3 = Color3.fromRGB(200, 200, 200)
tabConfig.Font = Enum.Font.GothamSemibold
tabConfig.TextSize = 13
tabConfig.BorderSizePixel = 0

local contentArea = Instance.new("Frame", mainFrame)
contentArea.Size = UDim2.new(1, 0, 1, -70)
contentArea.Position = UDim2.new(0, 0, 0, 70)
contentArea.BackgroundTransparency = 1

local farmPage = Instance.new("ScrollingFrame", contentArea)
farmPage.Size = UDim2.new(1, 0, 1, 0)
farmPage.BackgroundTransparency = 1
farmPage.ScrollBarThickness = 4

local configPage = Instance.new("Frame", contentArea)
configPage.Size = UDim2.new(1, 0, 1, 0)
configPage.BackgroundTransparency = 1
configPage.Visible = false

tabFarm.MouseButton1Click:Connect(function()
    tabFarm.BackgroundColor3 = Color3.fromRGB(50, 100, 200); tabFarm.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabConfig.BackgroundColor3 = Color3.fromRGB(30, 30, 35); tabConfig.TextColor3 = Color3.fromRGB(200, 200, 200)
    farmPage.Visible = true; configPage.Visible = false
end)

tabConfig.MouseButton1Click:Connect(function()
    tabConfig.BackgroundColor3 = Color3.fromRGB(50, 100, 200); tabConfig.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabFarm.BackgroundColor3 = Color3.fromRGB(30, 30, 35); tabFarm.TextColor3 = Color3.fromRGB(200, 200, 200)
    configPage.Visible = true; farmPage.Visible = false
end)

local farmLayout = Instance.new("UIListLayout", farmPage)
farmLayout.Padding = UDim.new(0, 10)
farmLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local farmPadding = Instance.new("UIPadding", farmPage)
farmPadding.PaddingTop = UDim.new(0, 15)

local function createToggle(name, parent, sizeY)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0.9, 0, 0, sizeY or 45)
    btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btn.Text = name .. ": DESLIGADO"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

-- MODO DE DIFICULDADE
getgenv().DeliveryMode = cfg.deliveryMode
local modeBtn = createToggle("Dificuldade", farmPage, 35)
modeBtn.Text = "Modo: " .. cfg.deliveryMode
modeBtn.BackgroundColor3 = cfg.deliveryMode == "Easy" and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 100, 50)
modeBtn.MouseButton1Click:Connect(function()
    getgenv().DeliveryMode = getgenv().DeliveryMode == "Easy" and "Hard" or "Easy"
    cfg.deliveryMode = getgenv().DeliveryMode
    modeBtn.Text = "Modo: " .. cfg.deliveryMode
    modeBtn.BackgroundColor3 = cfg.deliveryMode == "Easy" and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 100, 50)
    saveCfg()
end)

-- TOGGLE ENTREGADOR
local deliveryToggleBtn = createToggle("Entregador", farmPage, 45)
getgenv().AutoFarmDelivery = cfg.delivery
getgenv().DeliveryInitialPosition = nil

local function getRoot() return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") end

local function updateDeliveryUI()
    if getgenv().AutoFarmDelivery then
        deliveryToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        deliveryToggleBtn.Text = "Entregador: LIGADO"
        local root = getRoot()
        if root then getgenv().DeliveryInitialPosition = root.CFrame end
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Evollogic/drivingempire/main/Works/Delivery.lua?t="..os.time()))() end)
    else
        deliveryToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        deliveryToggleBtn.Text = "Entregador: DESLIGADO"
        local root = getRoot()
        if root and getgenv().DeliveryInitialPosition then
            root.Velocity, root.AssemblyLinearVelocity = Vector3.new(0,0,0), Vector3.new(0,0,0)
            root.CFrame = getgenv().DeliveryInitialPosition
        end
    end
end

deliveryToggleBtn.MouseButton1Click:Connect(function()
    getgenv().AutoFarmDelivery = not getgenv().AutoFarmDelivery
    cfg.delivery = getgenv().AutoFarmDelivery
    saveCfg()
    updateDeliveryUI()
end)
if getgenv().AutoFarmDelivery then task.spawn(function() if not lp.Character then lp.CharacterAdded:Wait() end task.wait(1) updateDeliveryUI() end) end

-- TOGGLE AUTO-HOP (AGORA FUNCIONAL)
local autoHopToggleBtn = createToggle("Auto-Hop (Sair AFK)", farmPage, 45)
getgenv().AutoHopState = cfg.autoHop

local function updateHopUI()
    if getgenv().AutoHopState then
        autoHopToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        autoHopToggleBtn.Text = "Auto-Hop: LIGADO"
    else
        autoHopToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        autoHopToggleBtn.Text = "Auto-Hop: DESLIGADO"
    end
end

autoHopToggleBtn.MouseButton1Click:Connect(function()
    getgenv().AutoHopState = not getgenv().AutoHopState
    cfg.autoHop = getgenv().AutoHopState
    saveCfg()
    updateHopUI()
end)
updateHopUI()

-- SISTEMA DE ARRASTAR
local function makeDraggable(dragPoint, dragTarget)
    local dragging, dragStart, startPos = false, nil, nil
    dragPoint.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = dragTarget.AbsolutePosition
        end
    end)
    uis.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            dragTarget.Position = UDim2.new(0, math.clamp(startPos.X + delta.X, 0, sg.AbsoluteSize.X - dragTarget.AbsoluteSize.X), 0, math.clamp(startPos.Y + delta.Y, 0, sg.AbsoluteSize.Y - dragTarget.AbsoluteSize.Y))
        end
    end)
    uis.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end
makeDraggable(mainFrame, mainFrame); makeDraggable(topBar, mainFrame); makeDraggable(openBall, openBall)

-- BACKGROUND TASKS
task.spawn(function()
    if not getgenv().AutoClaimRunning then
        getgenv().AutoClaimRunning = true
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Evollogic/drivingempire/main/Auto/autoclaim.lua?t="..os.time()))() end)
    end
end)

-- NOVO SISTEMA DE AUTO-HOP (PRECISO E SEM LOOP INFINITO)
task.spawn(function()
    while task.wait(5) do
        if getgenv().AutoHopState then
            pcall(function()
                local gui = lp.PlayerGui:FindFirstChild("HUD")
                if gui then
                    -- Busca os botões exatos em qualquer lugar dentro do HUD usando busca recursiva
                    local afkBtn = gui:FindFirstChild("LeaveAFKServer", true)
                    local matchBtn = gui:FindFirstChild("LeaveMatchmakingServer", true)
                    
                    -- Verifica se pelo menos um deles foi encontrado e está visível na tela
                    if (afkBtn and afkBtn.Visible) or (matchBtn and matchBtn.Visible) then
                        print("[Auto-Hop] Tela de AFK verificada com sucesso! Reconectando...")
                        
                        -- Tenta acionar o clique do botão nativamente (se o executor suportar)
                        if getconnections then
                            if afkBtn then for _, c in pairs(getconnections(afkBtn.MouseButton1Click)) do c:Fire() end end
                            if matchBtn then for _, c in pairs(getconnections(matchBtn.MouseButton1Click)) do c:Fire() end end
                        end
                        
                        task.wait(1)
                        
                        -- Força o teleporte pelo serviço principal como garantia
                        teleportService:Teleport(game.PlaceId, lp)
                        task.wait(15) 
                    end
                end
            end)
        end
    end
end)
