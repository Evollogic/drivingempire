local teleportService = game:GetService("TeleportService")
local plyrs = game:GetService("Players")
local lp = plyrs.LocalPlayer

-- 1. Aguarda o jogo carregar totalmente (Essencial no servidor AFK para evitar falhas do TeleportService)
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local MAIN_GAME_ID = 3351674303 
local AFK_PLACE_ID = 99421106727783

-- 2. Notificação visual rápida para confirmar que o autohop arrancou
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "⚡ Auto-Hop Ativo",
        Text = "A monitorizar o servidor...",
        Duration = 3
    })
end)

task.spawn(function()
    while task.wait(5) do
        pcall(function()
            local currentPlaceId = game.PlaceId
            
            -- Se não estivermos no mapa principal, força o teletransporte
            if currentPlaceId == AFK_PLACE_ID or currentPlaceId ~= MAIN_GAME_ID then
                pcall(function()
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "🔄 Auto-Hop",
                        Text = "Servidor AFK/Erro detetado! A voltar para o mapa principal...",
                        Duration = 5
                    })
                end)
                
                print("[Auto-Hop] Forçando teletransporte para: " .. tostring(MAIN_GAME_ID))
                teleportService:Teleport(MAIN_GAME_ID)
                task.wait(15) -- Espera para não causar flood no teletransporte
            else
                -- Se estivermos no jogo principal, verificamos se a interface do jogo mostra o aviso
                local playerGui = lp:WaitForChild("PlayerGui", 5)
                if playerGui then
                    local hud = playerGui:FindFirstChild("HUD")
                    if hud then
                        local afkBtn = hud:FindFirstChild("LeaveAFKServer", true)
                        local matchBtn = hud:FindFirstChild("LeaveMatchmakingServer", true)

                        if (afkBtn and afkBtn.Visible) or (matchBtn and matchBtn.Visible) then
                            print("[Auto-Hop] Botão de inatividade detetado no ecrã. A clicar...")
                            
                            -- Tenta forçar o clique na interface se o executor suportar
                            if getconnections then
                                if afkBtn then for _, c in pairs(getconnections(afkBtn.MouseButton1Click)) do c:Fire() end end
                                if matchBtn then for _, c in pairs(getconnections(matchBtn.MouseButton1Click)) do c:Fire() end end
                            end
                            
                            task.wait(1)
                            teleportService:Teleport(MAIN_GAME_ID)
                            task.wait(15)
                        end
                    end
                end
            end
        end)
    end
end)
