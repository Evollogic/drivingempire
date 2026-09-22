local coreGui = game:GetService("CoreGui")
local plyrs = game:GetService("Players")
local uis = game:GetService("UserInputService")
local ts = game:GetService("TweenService")
local lp = plyrs.LocalPlayer

-- ==========================================
-- SISTEMA DE AUTO-UPDATE (GITHUB)
-- ==========================================
local CURRENT_VERSION = "1.6" 
local VERSION_URL = "https://raw.githubusercontent.com/Evollogic/drivingempire/main/version.txt"
local SCRIPT_URL = "https://raw.githubusercontent.com/Evollogic/drivingempire/main/Hub.lua"

local function checkForUpdates()
    local success, latestVersion = pcall(function() return game:HttpGet(VERSION_URL) end)
    if success and latestVersion and string.match(latestVersion, "%d+%.%d+") then
        latestVersion = latestVersion:gsub("%s+", "")
        if latestVersion ~= CURRENT_VERSION then
            for _, v in pairs(coreGui:GetChildren()) do
                if v.Name == "PremiumHub" or v.Name == "UpdateHub" then v:Destroy() end
            end
            
            local updateGui = Instance.new("ScreenGui")
            updateGui.Name = "UpdateHub"
            updateGui.IgnoreGuiInset = true
            pcall(function() updateGui.Parent = coreGui end)
            if not updateGui.Parent then updateGui.Parent = lp:WaitForChild("PlayerGui") end
            
            local updateFrame = Instance.new("Frame")
            updateFrame.Size = UDim2.new(0, 250, 0, 120)
            updateFrame.Position = UDim2.new(0.5, -125, 0.5, -60)
            updateFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            updateFrame.BorderSizePixel = 0
            updateFrame.Parent = updateGui
            Instance.new("UICorner", updateFrame).CornerRadius = UDim.new(0, 10)
            
            local updateTitle = Instance.new("TextLabel")
            updateTitle.Size = UDim2.new(1, 0, 0, 30)
            updateTitle.BackgroundTransparency = 1
            updateTitle.Text = "Atualizando Hub..."
            updateTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            updateTitle.Font = Enum.Font.GothamBold
            updateTitle.TextSize = 16
            updateTitle.Parent = updateFrame
            
            local barBG = Instance.new("Frame")
            barBG.Size = UDim2.new(0.8, 0, 0, 8)
            barBG.Position = UDim2.new(0.1, 0, 0.6, 0)
            barBG.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            barBG.Parent = updateFrame
            Instance.new("UICorner", barBG).CornerRadius = UDim.new(1, 0)
            
            local barFill = Instance.new("Frame")
            barFill.Size = UDim2.new(0, 0, 1, 0)
            barFill.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
            barFill.Parent = barBG
            Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)
            
            ts:Create(barFill, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)}):Play()
            task.wait(1.5)
            
            local successDownload, newScript = pcall(function() return game:HttpGet(SCRIPT_URL) end)
            if successDownload and newScript then
                if writefile then writefile("Hub.lua", newScript) end
                updateGui:Destroy()
                loadstring(newScript)()
                return true
            else
                updateGui:Destroy()
            end
        end
    end
    return false
end

if checkForUpdates() then return end

-- ==========================================
-- LIMPEZA E CRIAÇÃO DA GUI
-- ==========================================
for _, v in pairs(coreGui:GetChildren()) do
    if v.Name == "PremiumHub" then v:Destroy() end
end
local playerGui = lp:FindFirstChild("PlayerGui")
if playerGui then
    for _, v in pairs(playerGui:GetChildren()) do
        if v.Name == "PremiumHub" then v:Destroy() end
    end
end

local sg = Instance.new("ScreenGui")
sg.Name = "PremiumHub"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
pcall(function() sg.Parent = coreGui end)
if not sg.Parent then sg.Parent = playerGui end

-- ==========================================
-- BOLINHA FLUTUANTE (MINIMIZADO)
-- ==========================================
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

local ballCorner = Instance.new("UICorner")
ballCorner.CornerRadius = UDim.new(1, 0)
ballCorner.Parent = openBall

local ballStroke = Instance.new("UIStroke")
ballStroke.Color = Color3.fromRGB(50, 150, 255)
ballStroke.Thickness = 2
ballStroke.Parent = openBall

-- ==========================================
-- JANELA PRINCIPAL (RETÂNGULO EM PÉ)
-- ==========================================
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 230, 0, 360)
mainFrame.Position = UDim2.new(0.5, -115, 0.5, -180)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Visible = false 
mainFrame.Parent = sg
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 35)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 8)
titleFix.Position = UDim2.new(0, 0, 1, -8)
titleFix.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
titleFix.BorderSizePixel = 0
titleFix.Parent = topBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -40, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Empire Hub v" .. CURRENT_VERSION
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 14
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = topBar

-- Botão Minimizar
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -35, 0, 2)
minBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 18
minBtn.Parent = topBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

minBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    openBall.Visible = true
end)

openBall.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    openBall.Visible = false
end)

-- Abas (Topo)
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, 0, 0, 35)
tabContainer.Position = UDim2.new(0, 0, 0, 35)
tabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
tabContainer.BorderSizePixel = 0
tabContainer.Parent = mainFrame

local tabFarm = Instance.new("TextButton")
tabFarm.Size = UDim2.new(0.5, 0, 1, 0)
tabFarm.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
tabFarm.Text = "Trabalhos"
tabFarm.TextColor3 = Color3.fromRGB(255, 255, 255)
tabFarm.Font = Enum.Font.GothamSemibold
tabFarm.TextSize = 13
tabFarm.BorderSizePixel = 0
tabFarm.Parent = tabContainer

local tabConfig = Instance.new("TextButton")
tabConfig.Size = UDim2.new(0.5, 0, 1, 0)
tabConfig.Position = UDim2.new(0.5, 0, 0, 0)
tabConfig.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
tabConfig.Text = "Configs"
tabConfig.TextColor3 = Color3.fromRGB(200, 200, 200)
tabConfig.Font = Enum.Font.GothamSemibold
tabConfig.TextSize = 13
tabConfig.BorderSizePixel = 0
tabConfig.Parent = tabContainer

-- Área de Conteúdo
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, 0, 1, -70)
contentArea.Position = UDim2.new(0, 0, 0, 70)
contentArea.BackgroundTransparency = 1
contentArea.Parent = mainFrame

local farmPage = Instance.new("ScrollingFrame")
farmPage.Size = UDim2.new(1, 0, 1, 0)
farmPage.BackgroundTransparency = 1
farmPage.ScrollBarThickness = 4
farmPage.Parent = contentArea

local configPage = Instance.new("Frame")
configPage.Size = UDim2.new(1, 0, 1, 0)
configPage.BackgroundTransparency = 1
configPage.Visible = false
configPage.Parent = contentArea

tabFarm.MouseButton1Click:Connect(function()
    tabFarm.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
    tabFarm.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabConfig.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    tabConfig.TextColor3 = Color3.fromRGB(200, 200, 200)
    farmPage.Visible = true
    configPage.Visible = false
end)

tabConfig.MouseButton1Click:Connect(function()
    tabConfig.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
    tabConfig.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabFarm.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    tabFarm.TextColor3 = Color3.fromRGB(200, 200, 200)
    configPage.Visible = true
    farmPage.Visible = false
end)

local farmLayout = Instance.new("UIListLayout")
farmLayout.Padding = UDim.new(0, 10)
farmLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
farmLayout.Parent = farmPage
local farmPadding = Instance.new("UIPadding")
farmPadding.PaddingTop = UDim.new(0, 15)
farmPadding.Parent = farmPage

-- ==========================================
-- BOTÕES DE TRABALHO
-- ==========================================
local function createToggle(name, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 45)
    btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btn.Text = name .. ": DESLIGADO"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local deliveryToggleBtn = createToggle("Entregador", farmPage)

getgenv().AutoFarmDelivery = false
getgenv().DeliveryInitialPosition = nil
local function getRoot() return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") end

deliveryToggleBtn.MouseButton1Click:Connect(function()
    getgenv().AutoFarmDelivery = not getgenv().AutoFarmDelivery
    local root = getRoot()
    
    if getgenv().AutoFarmDelivery then
        deliveryToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        deliveryToggleBtn.Text = "Entregador: LIGADO"
        if root then getgenv().DeliveryInitialPosition = root.CFrame end
        pcall(function() 
            local url = "https://raw.githubusercontent.com/Evollogic/drivingempire/main/Works/Delivery.lua"
            loadstring(game:HttpGet(url))()
        end)
    else
        deliveryToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        deliveryToggleBtn.Text = "Entregador: DESLIGADO"
        if root and getgenv().DeliveryInitialPosition then
            root.Velocity = Vector3.new(0,0,0)
            root.AssemblyLinearVelocity = Vector3.new(0,0,0)
            root.CFrame = getgenv().DeliveryInitialPosition
        end
    end
end)

-- ==========================================
-- SISTEMA DE ARRASTAR COM BLOQUEIO DE TELA
-- ==========================================
local function makeDraggable(topbarObject, objectToMove)
    local dragging, dragInput, dragStart, startPos
    
    topbarObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = objectToMove.AbsolutePosition
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    
    topbarObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    uis.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local screenSize = sg.AbsoluteSize
            local objSize = objectToMove.AbsoluteSize
            
            local newX = startPos.X + delta.X
            local newY = startPos.Y + delta.Y
            
            newX = math.clamp(newX, 0, screenSize.X - objSize.X)
            newY = math.clamp(newY, 0, screenSize.Y - objSize.Y)
            
            objectToMove.Position = UDim2.new(0, newX, 0, newY)
        end
    end)
end

makeDraggable(topBar, mainFrame)
makeDraggable(openBall, openBall)

-- ==========================================
-- AUTO CLAIM BACKGROUND
-- ==========================================
task.spawn(function()
    if not getgenv().AutoClaimRunning then
        getgenv().AutoClaimRunning = true
        pcall(function()
            local url = "https://raw.githubusercontent.com/Evollogic/drivingempire/main/Auto/autoclaim.lua"
            loadstring(game:HttpGet(url))()
        end)
    end
end)
