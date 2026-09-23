local coreGui = game:GetService("CoreGui")
local plyrs = game:GetService("Players")
local uis = game:GetService("UserInputService")
local ts = game:GetService("TweenService")
local http = game:GetService("HttpService")
local lp = plyrs.LocalPlayer

local CURRENT_VERSION = "1.9"
local VERSION_URL = "https://raw.githubusercontent.com/Evollogic/drivingempire/main/version.txt"
local SCRIPT_URL = "https://raw.githubusercontent.com/Evollogic/drivingempire/main/Hub.lua"

local function checkForUpdates()
    if getgenv().UpdatingHub then return false end
    local urlAntiCache = VERSION_URL .. "?t=" .. tostring(os.time())
    local success, latestVersion = pcall(function() return game:HttpGet(urlAntiCache) end)

    if success and latestVersion then
        latestVersion = string.match(latestVersion, "%d+%.%d+")
        if latestVersion and latestVersion ~= CURRENT_VERSION then
            getgenv().UpdatingHub = true

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

            local scriptAntiCache = SCRIPT_URL .. "?t=" .. tostring(os.time())
            local successDownload, newScript = pcall(function() return game:HttpGet(scriptAntiCache) end)
            if successDownload and newScript then
                if writefile then writefile("Hub.lua", newScript) end
                updateGui:Destroy()
                getgenv().UpdatingHub = false
                loadstring(newScript)()
                return true
            else
                getgenv().UpdatingHub = false
                updateGui:Destroy()
            end
        end
    end
    return false
end

if checkForUpdates() then return end

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
    if writefile then
        pcall(function()
            writefile(configName, http:JSONEncode(cfg))
        end)
    end
end

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

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 340)
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -170)
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
titleText.Size = UDim2.new(1, -50, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Empire Hub v" .. CURRENT_VERSION
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 13
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = topBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 25)
minBtn.Position = UDim2.new(1, -38, 0, 5)
minBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
minBtn.Text = "X"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
minBtn.Parent = topBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 4)

minBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    openBall.Visible = true
end)

openBall.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    openBall.Visible = false
end)

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

local function createToggle(name, parent, sizeY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, sizeY or 45)
    btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btn.Text = name .. ": DESLIGADO"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

getgenv().DeliveryMode = cfg.deliveryMode
local modeBtn = createToggle("Dificuldade", farmPage, 35)
modeBtn.Text = "Modo: " .. cfg.deliveryMode
modeBtn.BackgroundColor3 = cfg.deliveryMode == "Easy" and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 100, 50)

modeBtn.MouseButton1Click:Connect(function()
    if getgenv().DeliveryMode == "Easy" then
        getgenv().DeliveryMode = "Hard"
        modeBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
    else
        getgenv().DeliveryMode = "Easy"
        modeBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    end
    cfg.deliveryMode = getgenv().DeliveryMode
    modeBtn.Text = "Modo: " .. cfg.deliveryMode
    saveCfg()
end)

local deliveryToggleBtn = createToggle("Entregador", farmPage, 45) 
getgenv().AutoFarmDelivery = cfg.delivery
getgenv().DeliveryInitialPosition = nil

local function getRoot()
    return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
end

local function updateDeliveryUI()
    if getgenv().AutoFarmDelivery then
        deliveryToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        deliveryToggleBtn.Text = "Entregador: LIGADO"

        local root = getRoot()
        if root then getgenv().DeliveryInitialPosition = root.CFrame end

        pcall(function()
            local url = "https://raw.githubusercontent.com/Evollogic/drivingempire/main/Works/Delivery.lua?t=" .. tostring(os.time())
            loadstring(game:HttpGet(url))()
        end)
    else
        deliveryToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        deliveryToggleBtn.Text = "Entregador: DESLIGADO"

        local root = getRoot()
        if root and getgenv().DeliveryInitialPosition then
            root.Velocity = Vector3.new(0,0,0)
            root.AssemblyLinearVelocity = Vector3.new(0,0,0)
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

if getgenv().AutoFarmDelivery then
    task.spawn(function()
        if not lp.Character then lp.CharacterAdded:Wait() end
        task.wait(1)
        updateDeliveryUI()
    end)
end

-- ==========================================
-- ARRASTAR TELA (CORRIGIDO PARA MOBILE)
-- ==========================================
local function makeDraggable(dragPoint, dragTarget)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    dragPoint.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = dragTarget.AbsolutePosition
        end
    end)

    uis.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local screenSize = sg.AbsoluteSize
            local objSize = dragTarget.AbsoluteSize
            
            -- Clamps impedem que saia da tela
            local newX = math.clamp(startPos.X + delta.X, 0, screenSize.X - objSize.X)
            local newY = math.clamp(startPos.Y + delta.Y, 0, screenSize.Y - objSize.Y)
            
            dragTarget.Position = UDim2.new(0, newX, 0, newY)
        end
    end)

    uis.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

makeDraggable(mainFrame, mainFrame)
makeDraggable(topBar, mainFrame)
makeDraggable(openBall, openBall)

task.spawn(function()
    if not getgenv().AutoClaimRunning then
        getgenv().AutoClaimRunning = true
        pcall(function()
            local url = "https://raw.githubusercontent.com/Evollogic/drivingempire/main/Auto/autoclaim.lua?t=" .. tostring(os.time())
            loadstring(game:HttpGet(url))()
        end)
    end
end)
