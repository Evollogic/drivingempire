local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[Auto-Hop] Sistema iniciado. Checando status de AFK a cada 10 segundos...")

task.spawn(function()
    while task.wait(10) do
        -- O pcall previne que o script quebre se o jogo estiver carregando ou sem a interface
        local success, err = pcall(function()
            local restartUI = playerGui:FindFirstChild("ServerRestartNotification")
            
            if restartUI then
                local banner = restartUI:FindFirstChild("BannerHolder")
                
                -- Se o painel existir e estiver visível, executa o teletransporte
                if banner and banner.Visible then
                    print("[Auto-Hop] Tela de servidor AFK detectada! Reconectando...")
                    TeleportService:Teleport(game.PlaceId, player)
                    
                    -- Aguarda um tempo maior para dar tempo do teletransporte acontecer
                    task.wait(15) 
                end
            end
        end)

        if not success then
            warn("[Auto-Hop] Falha silenciosa na verificação: " .. tostring(err))
        end
    end
end)
