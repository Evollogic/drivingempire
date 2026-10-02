local ts = game:GetService("TweenService")
local coreGui = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or game:GetService("Players").LocalPlayer.PlayerGui

if coreGui:FindFirstChild("DrivingEmpireHub") then
    coreGui.DrivingEmpireHub:Destroy()
end

getgenv().AutoFarmDelivery = false
getgenv().DeliveryMode = "Safe" 
getgenv().DevMode = false

-- =========================================================================
-- MAIN UI STRUCTURE
-- =========================================================================
local sg = Instance.new("ScreenGui", coreGui)
sg.Name = "DrivingEmpireHub"
sg.ResetOnSpawn = false

-- TOP NOTIFICATION SYSTEM
local notifFrame = Instance.new("Frame", sg)
notifFrame.Size = UDim2.new(0, 260, 0, 45)
notifFrame.Position = UDim2.new(0.5, -130, 0, -60) -- Hidden above screen
notifFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
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
notifText.TextSize = 15
notifText.ZIndex = 11

local notifDebounce = false
local function ShowNotification(msg, color)
    if notifDebounce then return end
    task.spawn(function()
        notifDebounce = true
        notifText.Text = msg
        notifStroke.Color = color
        -- Slide down
        ts:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -130, 0, 30)}):Play()
        task.wait(2.5)
        -- Slide up
        ts:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, -130, 0, -60)}):Play()
        task.wait(0.4)
        notifDebounce = false
    end)
end

-- 🍔 Floating Hamburger Button
local burgerBtn = Instance.new("TextButton", sg)
burgerBtn.Size = UDim2.new(0, 50, 0, 50)
burgerBtn.Position = UDim2.new(1, -70, 0, 20)
burgerBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
burgerBtn.Text = "🍔"
burgerBtn.TextSize = 28
burgerBtn.Draggable = true
burgerBtn.Active = true
Instance.new("UICorner", burgerBtn).CornerRadius = UDim.new(1, 0)
local burgerStroke = Instance.new("UIStroke", burgerBtn)
burgerStroke.Color = Color3.fromRGB(60, 150, 255)
burgerStroke.Thickness = 2

-- Main Hub
local hub = Instance.new("Frame", sg)
hub.Size = UDim2.new(0, 320, 0, 0)
hub.Position = UDim2.new(1, -400, 0, 20)
hub.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
hub.ClipsDescendants = true
hub.Active = true
hub.Draggable = true
Instance.new("UICorner", hub).CornerRadius = UDim.new(0, 8)
local hubStroke = Instance.new("UIStroke", hub)
hubStroke.Color = Color3.fromRGB(50, 50, 60)
hubStroke.Thickness = 1.5

local title = Instance.new("TextLabel", hub)
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = " 🚗 Driving Empire Hub"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 16
local titlePadding = Instance.new("UIPadding", title)
titlePadding.PaddingLeft = UDim.new(0, 15)

local div = Instance.new("Frame", hub)
div.Size = UDim2.new(1, 0, 0, 1)
div.Position = UDim2.new(0, 0, 0, 40)
div.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
div.BorderSizePixel = 0

local options = Instance.new("Frame", hub)
options.Size = UDim2.new(1, -30, 1, -60)
options.Position = UDim2.new(0, 15, 0, 55)
options.BackgroundTransparency = 1

local listLayout = Instance.new("UIListLayout", options)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)

-- =========================================================================
-- BUTTON CREATOR FUNCTION
-- =========================================================================
local function createButton(parent, text, color)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.Text = text
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    btn.MouseEnter:Connect(function()
        ts:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(color.R*1.2, color.G*1.2, color.B*1.2)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        ts:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
    end)
    
    return btn
end

-- =========================================================================
-- HUB ELEMENTS
-- =========================================================================
local btnAutoDelivery = createButton(options, "Auto Delivery: OFF", Color3.fromRGB(180, 50, 50))
btnAutoDelivery.LayoutOrder = 1

local diffContainer = Instance.new("Frame", options)
diffContainer.Size = UDim2.new(1, 0, 0, 0)
diffContainer.BackgroundTransparency = 1
diffContainer.ClipsDescendants = true
diffContainer.LayoutOrder = 2

local diffList = Instance.new("UIListLayout", diffContainer)
diffList.FillDirection = Enum.FillDirection.Horizontal
diffList.HorizontalAlignment = Enum.HorizontalAlignment.SpaceBetween

local btnEasy = createButton(diffContainer, "Easy", Color3.fromRGB(50, 150, 80))
btnEasy.Size = UDim2.new(0.48, 0, 0, 35)

local btnHard = createButton(diffContainer, "Hard", Color3.fromRGB(50, 50, 60))
btnHard.Size = UDim2.new(0.48, 0, 0, 35)

-- =========================================================================
-- DEBUG TERMINAL (HIDDEN DEV MODE)
-- =========================================================================
local termFrame = Instance.new("Frame", sg)
termFrame.Size = UDim2.new(0, 350, 0, 300)
termFrame.Position = UDim2.new(1, -760, 0, 20)
termFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
termFrame.Visible = false
termFrame.Active = true
termFrame.Draggable = true
Instance.new("UICorner", termFrame).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", termFrame).Color = Color3.fromRGB(80, 80, 90)

local termTitle = title:Clone()
termTitle.Parent = termFrame
termTitle.Text = " 📟 Terminal (Logs)"
termTitle.TextColor3 = Color3.fromRGB(100, 255, 100)

local termScroll = Instance.new("ScrollingFrame", termFrame)
termScroll.Size = UDim2.new(1, -20, 1, -50)
termScroll.Position = UDim2.new(0, 10, 0, 40)
termScroll.BackgroundTransparency = 1
termScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
termScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
termScroll.ScrollBarThickness = 4
local termList = Instance.new("UIListLayout", termScroll)
termList.Padding = UDim.new(0, 2)

getgenv().LogMsg = function(msg)
    if not getgenv().DevMode then return end
    local t = os.date("%H:%M:%S") .. " | " .. tostring(msg)
    local txt = Instance.new("TextLabel", termScroll)
    txt.Size = UDim2.new(1, 0, 0, 0)
    txt.AutomaticSize = Enum.AutomaticSize.Y
    txt.BackgroundTransparency = 1
    txt.TextColor3 = Color3.fromRGB(180, 180, 180)
    txt.TextSize = 12
    txt.Font = Enum.Font.Code
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextWrapped = true
    txt.Text = t
    termScroll.CanvasPosition = Vector2.new(0, termScroll.AbsoluteWindowSize.Y + 9999)
end

-- =========================================================================
-- MENU AND BUTTON LOGIC
-- =========================================================================
local isHubOpen = false
local devClickCount = 0
local lastClickTime = 0

burgerBtn.MouseButton1Click:Connect(function()
    -- 1. Main Menu Open/Close Logic
    isHubOpen = not isHubOpen
    if isHubOpen then
        ts:Create(hub, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 320, 0, 180)}):Play()
        burgerStroke.Color = Color3.fromRGB(100, 255, 100)
    else
        ts:Create(hub, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, 320, 0, 0)}):Play()
        burgerStroke.Color = Color3.fromRGB(60, 150, 255)
    end

    -- 2. Easter Egg Logic and Dynamic Animation
    local currentTime = tick()
    if currentTime - lastClickTime > 1.2 then
        devClickCount = 0 
    end
    lastClickTime = currentTime
    devClickCount = devClickCount + 1

    -- "Jump" and tilt animation on every click
    local tilt = (devClickCount % 2 == 0) and 15 or -15
    if devClickCount == 5 then tilt = 360 end -- Full spin on 5th click

    ts:Create(burgerBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, 45, 0, 45), Rotation = tilt}):Play()
    task.wait(0.1)
    ts:Create(burgerBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, 50, 0, 50), Rotation = (devClickCount == 5 and 0 or tilt)}):Play()
    
    if devClickCount < 5 then
        task.wait(0.1)
        ts:Create(burgerBtn, TweenInfo.new(0.1), {Rotation = 0}):Play()
    end

    if devClickCount >= 5 then
        devClickCount = 0
        getgenv().DevMode = not getgenv().DevMode
        termFrame.Visible = getgenv().DevMode
        
        if getgenv().DevMode then
            ShowNotification("🐛 Dev Mode ENABLED!", Color3.fromRGB(100, 255, 100))
            getgenv().LogMsg("Developer Mode ENABLED!")
        else
            ShowNotification("❌ Dev Mode DISABLED!", Color3.fromRGB(255, 100, 100))
        end
    end
end)

btnAutoDelivery.MouseButton1Click:Connect(function()
    getgenv().AutoFarmDelivery = not getgenv().AutoFarmDelivery
    if getgenv().AutoFarmDelivery then
        btnAutoDelivery.Text = "Auto Delivery: ON"
        ts:Create(btnAutoDelivery, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 180, 80)}):Play()
        ts:Create(diffContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 35)}):Play()
        getgenv().LogMsg("Auto Delivery STARTED.")
        pcall(function() loadfile("Works/Delivery.lua")() end)
    else
        btnAutoDelivery.Text = "Auto Delivery: OFF"
        ts:Create(btnAutoDelivery, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(180, 50, 50)}):Play()
        ts:Create(diffContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 0)}):Play()
        getgenv().LogMsg("Auto Delivery STOPPED.")
    end
end)

local function updateDiffColors()
    btnEasy.BackgroundColor3 = getgenv().DeliveryMode == "Safe" and Color3.fromRGB(50, 150, 80) or Color3.fromRGB(50, 50, 60)
    btnHard.BackgroundColor3 = getgenv().DeliveryMode == "HighRisk" and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(50, 50, 60)
end

btnEasy.MouseButton1Click:Connect(function()
    getgenv().DeliveryMode = "Safe"
    updateDiffColors()
    getgenv().LogMsg("Difficulty changed to: EASY (Safe)")
end)

btnHard.MouseButton1Click:Connect(function()
    getgenv().DeliveryMode = "HighRisk"
    updateDiffColors()
    getgenv().LogMsg("Difficulty changed to: HARD (HighRisk)")
end)
