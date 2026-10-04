local coreGui = game:GetService("CoreGui")
local uis = game:GetService("UserInputService")
local vim = game:GetService("VirtualInputManager")

-- Limpa a GUI se ela já estiver aberta na tela (para não duplicar quando você testar)
for _, v in pairs(coreGui:GetChildren()) do
    if v.Name == "DevClickerUI" then v:Destroy() end
end

local sg = Instance.new("ScreenGui")
sg.Name = "DevClickerUI"
sg.Parent = coreGui

-- =========================================================================
-- OBJETO LOCAL 1: O Painel Principal (A base da GUI)
-- =========================================================================
local mainFrame = Instance.new("Frame", sg)
mainFrame.Size = UDim2.new(0, 200, 0, 100)
mainFrame.Position = UDim2.new(0.5, -100, 0.5, -50)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.Active = true -- Permite interação
mainFrame.Draggable = true -- Deixa a janela arrastável pelo mouse/dedo
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
-- LÓGICA DO CLIQUE AUTOMÁTICO
-- =========================================================================
local isClicking = false

toggleBtn.MouseButton1Click:Connect(function()
    -- Inverte o estado atual (Se for false vira true, se for true vira false)
    isClicking = not isClicking

    if isClicking then
        toggleBtn.Text = "AUTO CLICK: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Fica vermelho pra indicar que tá rodando
        
        task.spawn(function()
            while isClicking do
                -- Pega a posição atual do mouse na tela
                local mousePos = uis:GetMouseLocation()
                
                -- Simula Pressionar o botão do mouse
                vim:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
                task.wait(0.01)
                -- Simula Soltar o botão do mouse
                vim:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
                
                -- Velocidade do Auto Click (0.1 = 10 cliques por segundo)
                task.wait(0.1) 
            end
        end)
    else
        toggleBtn.Text = "AUTO CLICK: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- Fica verde indicando que parou
    end
end)
