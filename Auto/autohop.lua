local teleportService = game:GetService("TeleportService")
local plyrs = game:GetService("Players")
local lp = plyrs.LocalPlayer

local MAIN_GAME_ID = 3351674303 

task.spawn(function()
    while task.wait(5) do
        pcall(function()
            local currentPlaceId = game.PlaceId
            
            -- Se não estivermos no mapa principal, forçamos o teleporte imediatamente
            if currentPlaceId ~= MAIN_GAME_ID then
                print("[Auto-Hop] Detectado fora do jogo principal (ID: " .. tostring(currentPlaceId) .. "). Retornando...")
                teleportService:Teleport(MAIN_GAME_ID, lp)
                task.wait(15) -- Aguarda para não causar flood no teleporte
            else
                -- Se estivermos no jogo principal, verificamos se a tela de AFK/Matchmaking apareceu
                local playerGui = lp:WaitForChild("PlayerGui", 5)
                if playerGui then
                    local hud = playerGui:FindFirstChild("HUD")
                    if hud then
                        local afkBtn = hud:FindFirstChild("LeaveAFKServer", true)
                        local matchBtn = hud:FindFirstChild("LeaveMatchmakingServer", true)

                        if (afkBtn and afkBtn.Visible) or (matchBtn and matchBtn.Visible) then
                            print("[Auto-Hop] Aviso de inatividade/matchmaking detectado na interface. Reconectando...")
                            
                            -- Tenta clicar caso exista suporte no executor
                            if getconnections then
                                if afkBtn then for _, c in pairs(getconnections(afkBtn.MouseButton1Click)) do c:Fire() end end
                                if matchBtn then for _, c in pairs(getconnections(matchBtn.MouseButton1Click)) do c:Fire() end end
                            end
                            
                            task.wait(1)
                            -- Garante o teleporte
                            teleportService:Teleport(MAIN_GAME_ID, lp)
                            task.wait(15)
                        end
                    end
                end
            end
        end)
    end
end)
