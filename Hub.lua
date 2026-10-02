local coreGui = game:GetService("CoreGui")
local plyrs = game:GetService("Players")
local uis = game:GetService("UserInputService")
local ts = game:GetService("TweenService")
local http = game:GetService("HttpService")
local lp = plyrs.LocalPlayer
local CURRENT_VERSION = "3.0"
local VERSION_URL = "https://raw.githubusercontent.com/Evollogic/drivingempire/main/version.txt"
local SCRIPT_URL = "https://raw.githubusercontent.com/Evollogic/drivingempire/main/Hub.lua"

local configName = "EmpireConfig.json"
local cfg = { delivery = false, deliveryMode = "Easy" }                 
if isfile and isfile(configName) then
    pcall(function()
        local data = http:JSONDecode(readfile(configName))
        if data and type(data) == "table" then
            if data.delivery ~= nil then cfg.delivery = data.delivery end
            if data.deliveryMode ~= nil then cfg.deliveryMode = data.deliveryMode end
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

-- ==========================================
-- SISTEMA DE NOTIFICAÇÃO (DEV MODE)
-- ==========================================
local notifFrame = Instance.new("Frame", sg)
notifFrame.Size = UDim2.new(0, 220, 0, 40)
notifFrame.Position = UDim2.new(0.5, -110, 0, -60)
notifFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
notifFrame.ZIndex = 10
Instance.new("UICorner", notifFrame).CornerRadius = UDim.new(0, 8)
local notifStroke = Instance.new("UIStroke", notifFrame)
notifStroke.Color = Color3.fromRGB(100, 255, 100)
notifStroke.Thickness = 2

local notifText = Instance.new("TextLabel", notifFrame)
notifText.Size = UDim2.new(1, 0, 1, 0)
notifText.BackgroundTransparency = 1
notifText.TextColor3 = Color3.fromRGB(255, 255, 255)
notifText.Font = Enum.Font.GothamBold
notifText.TextSize = 14
notifText.ZIndex = 11

local notifDebounce = false
local function ShowNotification(msg, color)
    if notifDebounce then return end
    task.spawn(function()
        notifDebounce = true
        notifText.Text = msg
        notifStroke.Color = color
        ts:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -110, 0, 30)}):Play()
        task.wait(2.5)
        ts:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, -110, 0, -60)}):Play()
        task.wait(0.4)
        notifDebounce = false
    end)
end

-- ==========================================
-- BOTAO FLUTUANTE (HAMBÚRGUER)
-- ==========================================
local openBall = Instance.new("TextButton")                             
openBall.Size = UDim2.new(0, 45, 0, 45)
openBall.Position = UDim2.new(0, 10, 0.5, -22)
openBall.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
openBall.BackgroundTransparency = 0.2
openBall.Text = "🍔" -- Emoji Hambúrguer
openBall.TextSize = 25
openBall.BorderSizePixel = 0
openBall.Visible = true
openBall.Parent = sg
Instance.new("UICorner", openBall).CornerRadius = UDim.new(1, 0)
local ballStroke = Instance.new("UIStroke", openBall)
ballStroke.Color = Color3.fromRGB(0, 255, 255)
ballStroke.Thickness = 2.5

-- ==========================================
-- JANELA PRINCIPAL (TEMA ESCURO FUTURISTA)
-- ==========================================
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 380)                              
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -190)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Visible = false
mainFrame.Parent = sg

local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 12)

-- EFEITO GLOW (NÉON ROTATIVO) NAS BORDAS
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Thickness = 2.5
mainStroke.Transparency = 0
local strokeGradient = Instance.new("UIGradient", mainStroke)
strokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(138, 43, 226)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 255))
})                                                                      
task.spawn(function()
    local rotacao = 0
    while task.wait(0.02) do
        rotacao = rotacao + 2
        if rotacao >= 360 then rotacao = 0 end
        strokeGradient.Rotation = rotacao
    end
end)                                                                    

-- BARRA SUPERIOR                                                       
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 35)
topBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
topBar.BackgroundTransparency = 0.5
topBar.BorderSizePixel = 0
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)
                                                                        
local titleFix = Instance.new("Frame", topBar)
titleFix.Size = UDim2.new(1, 0, 0, 10)
titleFix.Position = UDim2.new(0, 0, 1, -10)
titleFix.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
titleFix.BackgroundTransparency = 0.5
titleFix.BorderSizePixel = 0

local titleText = Instance.new("TextLabel", topBar)
titleText.Size = UDim2.new(1, -50, 1, 0)
titleText.Position = UDim2.new(0, 15, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Empire Hub v" .. CURRENT_VERSION
titleText.TextColor3 = Color3.fromRGB(0, 255, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 13
titleText.TextXAlignment = Enum.TextXAlignment.Left

local minBtn = Instance.new("TextButton", topBar)
minBtn.Size = UDim2.new(0, 30, 0, 25)
minBtn.Position = UDim2.new(1, -38, 0, 5)
minBtn.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
minBtn.Text = "X"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)
minBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)                                                                    

-- ABAS (Em Inglês)
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Size = UDim2.new(1, 0, 0, 35)
tabContainer.Position = UDim2.new(0, 0, 0, 35)
tabContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
tabContainer.BackgroundTransparency = 0.5
tabContainer.BorderSizePixel = 0
                                                                        
local tabFarm = Instance.new("TextButton", tabContainer)
tabFarm.Size = UDim2.new(0.5, 0, 1, 0)
tabFarm.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
tabFarm.BackgroundTransparency = 0.2
tabFarm.Text = "Jobs"
tabFarm.TextColor3 = Color3.fromRGB(255, 255, 255)
tabFarm.Font = Enum.Font.GothamSemibold
tabFarm.TextSize = 13
tabFarm.BorderSizePixel = 0                                             

local tabConfig = Instance.new("TextButton", tabContainer)
tabConfig.Size = UDim2.new(0.5, 0, 1, 0)
tabConfig.Position = UDim2.new(0.5, 0, 0, 0)
tabConfig.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
tabConfig.BackgroundTransparency = 0.8
tabConfig.Text = "Settings"
tabConfig.TextColor3 = Color3.fromRGB(150, 150, 150)
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
farmPage.ScrollBarThickness = 2

local configPage = Instance.new("Frame", contentArea)
configPage.Size = UDim2.new(1, 0, 1, 0)
configPage.BackgroundTransparency = 1
configPage.Visible = false

tabFarm.MouseButton1Click:Connect(function()
    tabFarm.BackgroundColor3 = Color3.fromRGB(0, 150, 255); tabFarm.BackgroundTransparency = 0.2; tabFarm.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabConfig.BackgroundColor3 = Color3.fromRGB(20, 20, 25); tabConfig.BackgroundTransparency = 0.8; tabConfig.TextColor3 = Color3.fromRGB(150, 150, 150)
    farmPage.Visible = true; configPage.Visible = false
end)

tabConfig.MouseButton1Click:Connect(function()
    tabConfig.BackgroundColor3 = Color3.fromRGB(0, 150, 255); tabConfig.BackgroundTransparency = 0.2; tabConfig.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabFarm.BackgroundColor3 = Color3.fromRGB(20, 20, 25); tabFarm.BackgroundTransparency = 0.8; tabFarm.TextColor3 = Color3.fromRGB(150, 150, 150)
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
    btn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(0, 0, 0)
    btnStroke.Thickness = 1
    btnStroke.Transparency = 0.5
    return btn
end

-- ==========================================
-- BOTÕES DE FARM E MODO EM INGLÊS
-- ==========================================
local deliveryToggleBtn = createToggle("Auto Delivery", farmPage, 45)
getgenv().AutoFarmDelivery = cfg.delivery
getgenv().DeliveryInitialPosition = nil

getgenv().DeliveryMode = cfg.deliveryMode
local modeBtn = createToggle("Difficulty", farmPage, 35)
modeBtn.Text = "Mode: " .. cfg.deliveryMode
modeBtn.BackgroundColor3 = cfg.deliveryMode == "Easy" and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 100, 0)
modeBtn.Visible = cfg.delivery -- Começa invisível se Auto Delivery estiver OFF

modeBtn.MouseButton1Click:Connect(function()
    getgenv().DeliveryMode = getgenv().DeliveryMode == "Easy" and "Hard" or "Easy"
    cfg.deliveryMode = getgenv().DeliveryMode
    modeBtn.Text = "Mode: " .. cfg.deliveryMode
    modeBtn.BackgroundColor3 = cfg.deliveryMode == "Easy" and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 100, 0)
    saveCfg()
end)

local function getRoot() return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") end

local function updateDeliveryUI()
    if getgenv().AutoFarmDelivery then
        deliveryToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        deliveryToggleBtn.Text = "Auto Delivery: ON"
        modeBtn.Visible = true -- Aparece ao ligar
        local root = getRoot()
        if root then getgenv().DeliveryInitialPosition = root.CFrame end
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Evollogic/drivingempire/main/Works/Delivery.lua?t="..os.time()))() end)
    else
        deliveryToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
        deliveryToggleBtn.Text = "Auto Delivery: OFF"
        modeBtn.Visible = false -- Esconde ao desligar
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

-- ==========================================
-- TERMINAL DE DEBUG (DEV MODE INVISÍVEL)
-- ==========================================
getgenv().DevMode = false
local termFrame = Instance.new("Frame", sg)
termFrame.Size = UDim2.new(0, 300, 0, 250)
termFrame.Position = UDim2.new(1, -320, 0, 20)
termFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
termFrame.Visible = false
termFrame.Active = true
termFrame.Draggable = true
Instance.new("UICorner", termFrame).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", termFrame).Color = Color3.fromRGB(80, 80, 90)

local termScroll = Instance.new("ScrollingFrame", termFrame)
termScroll.Size = UDim2.new(1, -10, 1, -10)
termScroll.Position = UDim2.new(0, 5, 0, 5)
termScroll.BackgroundTransparency = 1
termScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
termScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local termList = Instance.new("UIListLayout", termScroll)

getgenv().LogMsg = function(msg)
    if not getgenv().DevMode then return end
    local txt = Instance.new("TextLabel", termScroll)
    txt.Size = UDim2.new(1, 0, 0, 0)
    txt.AutomaticSize = Enum.AutomaticSize.Y
    txt.BackgroundTransparency = 1
    txt.TextColor3 = Color3.fromRGB(180, 180, 180)
    txt.TextSize = 12
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextWrapped = true
    txt.Text = os.date("%H:%M:%S") .. " | " .. tostring(msg)
    termScroll.CanvasPosition = Vector2.new(0, termScroll.AbsoluteWindowSize.Y + 9999)
end

-- ==========================================
-- SISTEMA ABSOLUTO DE ARRASTO E CLIQUES
-- ==========================================
local ballDragging = false
local ballDragStart = nil
local ballStartPos = nil

local hubDragging = false
local hubDragStart = nil
local hubStartPos = nil

local devClickCount = 0
local lastClickTime = 0

-- Função de captura para o Hub
local function onHubInputBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        hubDragging = true
        hubDragStart = input.Position
        hubStartPos = mainFrame.Position
    end
end

topBar.InputBegan:Connect(onHubInputBegan)

local function createDragBorder(size, pos)
    local border = Instance.new("TextButton", mainFrame)
    border.Size = size
    border.Position = pos
    border.BackgroundTransparency = 1
    border.Text = ""
    border.ZIndex = 100
    border.InputBegan:Connect(onHubInputBegan)
end

createDragBorder(UDim2.new(1, 30, 0, 20), UDim2.new(0, -15, 0, -15))
createDragBorder(UDim2.new(1, 30, 0, 20), UDim2.new(0, -15, 1, -5))
createDragBorder(UDim2.new(0, 20, 1, -30), UDim2.new(0, -15, 0, 15))
createDragBorder(UDim2.new(0, 20, 1, -30), UDim2.new(1, -5, 0, 15))     

-- Iniciar arrasto da bolinha
openBall.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        ballDragging = true
        ballDragStart = input.Position
        ballStartPos = openBall.Position
    end
end)

uis.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if ballDragging then
            local delta = input.Position - ballDragStart
            openBall.Position = UDim2.new(ballStartPos.X.Scale, ballStartPos.X.Offset + delta.X, ballStartPos.Y.Scale, ballStartPos.Y.Offset + delta.Y)
        end
        if hubDragging then
            local delta = input.Position - hubDragStart
            mainFrame.Position = UDim2.new(hubStartPos.X.Scale, hubStartPos.X.Offset + delta.X, hubStartPos.Y.Scale, hubStartPos.Y.Offset + delta.Y)
        end
    end
end)                                                                    

uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if ballDragging then
            ballDragging = false
            local delta = input.Position - ballDragStart
            
            -- Detecta CLIQUE no Hambúrguer
            if delta.Magnitude < 5 then
                local currentTime = tick()
                if currentTime - lastClickTime > 1.2 then devClickCount = 0 end
                lastClickTime = currentTime
                devClickCount = devClickCount + 1

                -- Animação de Rotação
                local tilt = (devClickCount % 2 == 0) and 15 or -15
                if devClickCount == 5 then tilt = 360 end
                ts:Create(openBall, TweenInfo.new(0.1), {Rotation = tilt}):Play()
                
                task.spawn(function()
                    task.wait(0.1)
                    if devClickCount < 5 then ts:Create(openBall, TweenInfo.new(0.1), {Rotation = 0}):Play() end
                end)

                -- Lógica dos 5 Cliques
                if devClickCount >= 5 then
                    devClickCount = 0
                    getgenv().DevMode = not getgenv().DevMode
                    termFrame.Visible = getgenv().DevMode
                    
                    if getgenv().DevMode then
                        ShowNotification("🐛 Dev Mode ENABLED!", Color3.fromRGB(100, 255, 100))
                    else
                        ShowNotification("❌ Dev Mode DISABLED!", Color3.fromRGB(255, 100, 100))
                    end
                    ts:Create(openBall, TweenInfo.new(0.1), {Rotation = 0}):Play()
                else
                    -- Primeiro clique normal: Abre/Fecha o Menu
                    mainFrame.Visible = not mainFrame.Visible
                end
            end
        end
        if hubDragging then hubDragging = false end
    end
end)

-- CHAMADAS DOS SCRIPTS AUTOMÁTICOS
task.spawn(function()
    if not getgenv().AutoClaimRunning then
        getgenv().AutoClaimRunning = true
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Evollogic/drivingempire/main/Auto/autoclaim.lua?t="..os.time()))() end)
    end
end)

task.spawn(function()
    if not getgenv().AutoHopRunning then
        getgenv().AutoHopRunning = true
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Evollogic/drivingempire/main/Auto/autohop.lua?t="..os.time()))() end)
    end
end)
