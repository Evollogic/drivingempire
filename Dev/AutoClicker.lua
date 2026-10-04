local coreGui = game:GetService("CoreGui")
local uis = game:GetService("UserInputService")
local vim = game:GetService("VirtualInputManager")

-- Limpa a GUI se ela já estiver aberta
for _, v in pairs(coreGui:GetChildren()) do
    if v.Name == "DevClickerUI" then v:Destroy() end
end

local sg = Instance.new("ScreenGui")
sg.Name = "DevClickerUI"
sg.Parent = coreGui

-- =========================================================================
-- FUNÇÃO PARA ENVIAR MENSAGENS PARA O DEV LOG DO HUB
-- =========================================================================
local function logMsg(msg)
    if getgenv().LogMsg then
        getgenv().LogMsg("AutoClicker: " .. tostring(msg))
    else
        print("AutoClicker: " .. tostring(msg))
    end
end

-- =========================================================================
-- OBJETO LOCAL 1: O Painel Principal
-- =========================================================================
local mainFrame = Instance.new("Frame", sg)
mainFrame.Size = UDim2.new(0, 200, 0, 100)
mainFrame.Position = UDim2.new(0.5, -100, 0.5, -50)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.Active = true 
mainFrame.Draggable = true 
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", mainFrame).Color = Color3.fromRGB(0, 255, 255)

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Dev AutoClicker"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14

-- =========================================================================
-- OBJETO LOCAL 2: O Botão de Ligar/Desligar
-- =========================================================================
local toggleBtn = Instance.new("TextButton", mainFrame)
toggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
toggleBtn.Position = UDim2.new(0.1, 0, 0.4, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
toggleBtn.Text = "AUTO CLICK: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 12
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

-- =========================================================================
-- LÓGICA DO CLIQUE AUTOMÁTICO COM LOGS
-- =========================================================================
local isClicking = false

toggleBtn.MouseButton1Click:Connect(function()
    isClicking = not isClicking

    if isClicking then
        toggleBtn.Text = "AUTO CLICK: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) 
        
        logMsg("🟢 Ligado! Iniciando cliques...")
        
        task.spawn(function()
            while isClicking do
                -- Pega a posição atual do mouse na tela
                local mousePos = uis:GetMouseLocation()
                
                -- Simula Pressionar o botão
                vim:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
                task.wait(0.01)
                -- Simula Soltar o botão
                vim:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
                
                -- Imprime no terminal de logs do Hub a posição exata do clique
                logMsg("🖱️ Clique em -> X: " .. math.floor(mousePos.X) .. " | Y: " .. math.floor(mousePos.Y))
                
                -- Velocidade do Auto Click (0.5s para você conseguir ler os logs sem travar a tela)
                task.wait(0.5) 
            end
        end)
    else
        toggleBtn.Text = "AUTO CLICK: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50) 
        logMsg("🔴 Desligado!")
    end
end)
