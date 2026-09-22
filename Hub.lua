local coreGui = game:GetService("CoreGui")
local plyrs = game:GetService("Players")
local uis = game:GetService("UserInputService")
local ts = game:GetService("TweenService")
local lp = plyrs.LocalPlayer

-- ==========================================
-- SISTEMA DE AUTO-UPDATE (GITHUB)
-- ==========================================
local CURRENT_VERSION = "1.0" -- Mude isso quando subir uma nova versão no GitHub
local VERSION_URL = "https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPOSITORIO/main/version.txt"
local SCRIPT_URL = "https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPOSITORIO/main/Hub.lua"

local function checkForUpdates()
    -- Tenta pegar a versão no GitHub
    local success, latestVersion = pcall(function()
        return game:HttpGet(VERSION_URL)
    end)

    if success and latestVersion and latestVersion ~= "" and string.match(latestVersion, "%d+%.%d+") then
        latestVersion = latestVersion:gsub("%s+", "") -- Remove espaços/quebras de linha
        
        if latestVersion ~= CURRENT_VERSION then
            -- Limpa as GUIs antigas
            for _, v in pairs(coreGui:GetChildren()) do
                if v.Name == "PremiumHub" or v.Name == "UpdateHub" then v:Destroy() end
            end
            
            -- TELA DE CARREGAMENTO DO UPDATE
            local updateGui = Instance.new("ScreenGui")
            updateGui.Name = "UpdateHub"
            pcall(function() updateGui.Parent = coreGui end)
            if not updateGui.Parent then updateGui.Parent = lp:WaitForChild("PlayerGui") end
            
            local updateFrame = Instance.new("Frame")
            updateFrame.Size = UDim2.new(0, 300, 0, 150)
            updateFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
            updateFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            updateFrame.BorderSizePixel = 0
            updateFrame.Parent = updateGui
            Instance.new("UICorner", updateFrame).CornerRadius = UDim.new(0, 10)
            
            local updateTitle = Instance.new("TextLabel")
            updateTitle.Size = UDim2.new(1, 0, 0, 40)
            updateTitle.BackgroundTransparency = 1
            updateTitle.Text = "Atualização Encontrada!"
            updateTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            updateTitle.Font = Enum.Font.GothamBold
            updateTitle.TextSize = 18
            updateTitle.Parent = updateFrame
            
            local updateStatus = Instance.new("TextLabel")
            updateStatus.Size = UDim2.new(1, 0, 0, 30)
            updateStatus.Position = UDim2.new(0, 0, 0.4, 0)
            updateStatus.BackgroundTransparency = 1
            updateStatus.Text = "Baixando versão " .. latestVersion .. "..."
            updateStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
            updateStatus.Font = Enum.Font.Gotham
            updateStatus.TextSize = 14
            updateStatus.Parent = updateFrame
            
            local barBG = Instance.new("Frame")
            barBG.Size = UDim2.new(0.8, 0, 0, 10)
            barBG.Position = UDim2.new(0.1, 0, 0.7, 0)
            barBG.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            barBG.Parent = updateFrame
            Instance.new("UICorner", barBG).CornerRadius = UDim.new(1, 0)
            
            local barFill = Instance.new("Frame")
            barFill.Size = UDim2.new(0, 0, 1, 0)
            barFill.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
            barFill.Parent = barBG
            Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)
            
            -- Anima a barra simulando download
            ts:Create(barFill, TweenInfo.new(2, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)}):Play()
            task.wait(2)
            
            -- Baixa e substitui o arquivo
            local successDownload, newScript = pcall(function()
                return game:HttpGet(SCRIPT_URL)
            end)
            
            if successDownload and newScript then
                updateStatus.Text = "Instalando..."
                task.wait(0.5)
                
                if writefile then
                    writefile("Hub.lua", newScript)
                end
                
                updateGui:Destroy()
                
                -- Executa o novo script e encerra esse
                loadstring(newScript)()
                return true -- Sinaliza que atualizou
            else
                updateStatus.Text = "Erro no Download! Iniciando versão atual."
                updateStatus.TextColor3 = Color3.fromRGB(255, 50, 50)
                task.wait(2)
                updateGui:Destroy()
            end
        end
    end
    return false -- Não precisou atualizar
end

-- Se atualizou, ele interrompe a execução do restante do código antigo
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
pcall(function() sg.Parent = coreGui end)
if not sg.Parent then sg.Parent = playerGui end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 300)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = sg
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 8)
titleFix.Position = UDim2.new(0, 0, 1, -8)
titleFix.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -10, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Empire Hub - Multi Trabalhos v" .. CURRENT_VERSION
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 14
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 120, 1, -35)
sidebar.Position = UDim2.new(0, 0, 0, 35)
sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 5)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Parent = sidebar
local tabPadding = Instance.new("UIPadding")
tabPadding.PaddingTop = UDim.new(0, 10)
tabPadding.Parent = sidebar

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -120, 1, -35)
contentArea.Position = UDim2.new(0, 120, 0, 35)
contentArea.BackgroundTransparency = 1
contentArea.Parent = mainFrame

local frames = {}
local function createTab(name, isDefault)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.BackgroundColor3 = isDefault and Color3.fromRGB(50, 100, 200) or Color3.fromRGB(40, 40, 45)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.Parent = sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = isDefault
    page.Parent = contentArea
    frames[btn] = page

    btn.MouseButton1Click:Connect(function()
        for b, f in pairs(frames) do
            b.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            f.Visible = false
        end
        btn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        page.Visible = true
    end)
    return page
end

local farmPage = createTab("Auto Farm", true)
local configPage = createTab("Configurações", false)

local subTabBar = Instance.new("Frame")
subTabBar.Size = UDim2.new(1, 0, 0, 35)
subTabBar.BackgroundTransparency = 1
subTabBar.Parent = farmPage

local subTabLayout = Instance.new("UIListLayout")
subTabLayout.FillDirection = Enum.FillDirection.Horizontal
subTabLayout.Padding = UDim.new(0, 10)
subTabLayout.SortOrder = Enum.SortOrder.LayoutOrder
subTabLayout.Parent = subTabBar
local subTabPadding = Instance.new("UIPadding")
subTabPadding.PaddingLeft = UDim.new(0, 10)
subTabPadding.PaddingTop = UDim.new(0, 5)
subTabPadding.Parent = subTabBar

local farmContentArea = Instance.new("Frame")
farmContentArea.Size = UDim2.new(1, 0, 1, -40)
farmContentArea.Position = UDim2.new(0, 0, 0, 40)
farmContentArea.BackgroundTransparency = 1
farmContentArea.Parent = farmPage

local subFrames = {}
local function createSubTab(name, isDefault)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 0, 25)
    btn.BackgroundColor3 = isDefault and Color3.fromRGB(80, 80, 90) or Color3.fromRGB(40, 40, 45)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.Parent = subTabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, -20, 1, -20)
    page.Position = UDim2.new(0, 10, 0, 10)
    page.BackgroundTransparency = 1
    page.Visible = isDefault
    page.Parent = farmContentArea
    subFrames[btn] = page

    btn.MouseButton1Click:Connect(function()
        for b, f in pairs(subFrames) do
            b.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            f.Visible = false
        end
        btn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
        page.Visible = true
    end)
    return page
end

local deliveryPage = createSubTab("Entregador", true)
local criminalPage = createSubTab("Criminoso", false)

local deliveryToggleBtn = Instance.new("TextButton")
deliveryToggleBtn.Size = UDim2.new(0, 220, 0, 40)
deliveryToggleBtn.Position = UDim2.new(0, 10, 0, 10)
deliveryToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
deliveryToggleBtn.Text = "Entregador: DESLIGADO"
deliveryToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
deliveryToggleBtn.Font = Enum.Font.GothamBold
deliveryToggleBtn.TextSize = 14
deliveryToggleBtn.Parent = deliveryPage
Instance.new("UICorner", deliveryToggleBtn).CornerRadius = UDim.new(0, 6)

-- ==========================================
-- LÓGICA DO BOTÃO E POSIÇÃO INICIAL
-- ==========================================
getgenv().AutoFarmDelivery = false
getgenv().DeliveryInitialPosition = nil

local function getRoot()
    return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
end

deliveryToggleBtn.MouseButton1Click:Connect(function()
    getgenv().AutoFarmDelivery = not getgenv().AutoFarmDelivery
    local root = getRoot()
    
    if getgenv().AutoFarmDelivery then
        deliveryToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        deliveryToggleBtn.Text = "Entregador: LIGADO"
        
        -- Salva a posição inicial quando o Farm é LIGADO
        if root then
            getgenv().DeliveryInitialPosition = root.CFrame
        end
        
        pcall(function()
            if isfile and isfile("Works/Delivery.lua") then
                loadstring(readfile("Works/Delivery.lua"))()
            else
                warn("[ERROR] O arquivo Works/Delivery.lua não foi encontrado!")
            end
        end)
    else
        deliveryToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        deliveryToggleBtn.Text = "Entregador: DESLIGADO"
        
        -- Retorna o personagem para a posição inicial quando DESLIGADO
        if root and getgenv().DeliveryInitialPosition then
            root.Velocity = Vector3.new(0, 0, 0)
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            root.CFrame = getgenv().DeliveryInitialPosition
        end
    end
end)

-- Sistema de Arrastar Janela
local dragging, dragInput, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
uis.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ==========================================
-- AUTO EXECUÇÃO DE ARQUIVOS (AUTOCLAIM)
-- ==========================================
task.spawn(function()
    pcall(function()
        if isfile and isfile("Auto/autoclaim.lua") then
            if not getgenv().AutoClaimRunning then
                getgenv().AutoClaimRunning = true
                loadstring(readfile("Auto/autoclaim.lua"))()
            end
        end
    end)
end)
