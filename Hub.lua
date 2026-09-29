local coreGui = game:GetService("CoreGui")
local plyrs = game:GetService("Players")
local uis = game:GetService("UserInputService")
local ts = game:GetService("TweenService")
local http = game:GetService("HttpService")
local lp = plyrs.LocalPlayer

local CURRENT_VERSION = "2.5"
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

-- BOTAO FLUTUANTE
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

-- JANELA PRINCIPAL
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 380)
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -190)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Visible = false
mainFrame.Parent = sg

-- Borda Arredondada Suave
local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 12)

-- Borda Colorida (Stroke) em toda a interface
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(50, 150, 255)
mainStroke.Thickness = 2
mainStroke.Transparency = 0.3

-- BARRA SUPERIOR
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 35)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
topBar.BorderSizePixel = 0
topBar.Active = false 
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)

local titleFix = Instance.new("Frame", topBar)
titleFix.Size = UDim2.new(1, 0, 0, 10)
titleFix.Position = UDim2.new(0, 0, 1, -10)
titleFix.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
titleFix.BorderSizePixel = 0
titleFix.Active = false

local titleText = Instance.new("TextLabel", topBar)
titleText.Size = UDim2.new(1, -50, 1, 0)
titleText.Position = UDim2.new(0, 15, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Empire Hub v" .. CURRENT_VERSION
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 13
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Active = false

local minBtn = Instance.new("TextButton", topBar)
minBtn.Size = UDim2.new(0, 30, 0, 25)
minBtn.Position = UDim2.new(1, -38, 0, 5)
minBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
minBtn.Text = "X"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

minBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false; openBall.Visible = true end)
openBall.MouseButton1Click:Connect(function() mainFrame.Visible = true; openBall.Visible = false end)

-- ABAS
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Size = UDim2.new(1, 0, 0, 35)
tabContainer.Position = UDim2.new(0, 0, 0, 35)
tabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
tabContainer.BorderSizePixel = 0
tabContainer.Active = false

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
contentArea.Active = false

local farmPage = Instance.new("ScrollingFrame", contentArea)
farmPage.Size = UDim2.new(1, 0, 1, 0)
farmPage.BackgroundTransparency = 1
farmPage.ScrollBarThickness = 2
farmPage.Active = false

local configPage = Instance.new("Frame", contentArea)
configPage.Size = UDim2.new(1, 0, 1, 0)
configPage.BackgroundTransparency = 1
configPage.Visible = false
configPage.Active = false

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

-- SISTEMA DE ARRASTAR CORRIGIDO (Fluido e preciso)
local function makeDraggable(gui, dragHandle)
    dragHandle = dragHandle or gui
    local dragging
    local dragInput
    local dragStart
    local startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    uis.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Atrela o arrasto tanto ao fundo da janela quanto à barra superior
makeDraggable(mainFrame, mainFrame)
makeDraggable(mainFrame, topBar)
makeDraggable(openBall)

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
