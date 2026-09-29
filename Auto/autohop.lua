local teleportService = game:GetService("TeleportService")
local plyrs = game:GetService("Players")
local lp = plyrs.LocalPlayer

local MAIN_GAME_ID = 3351674303 
local AFK_PLACE_ID = 99421106727783 -- ID exato da sala AFK

task.spawn(function()
    while task.wait(5) do
        pcall(function()
            local currentPlaceId = game.PlaceId
            
            -- Se estiver no ID da sala AFK ou fora do mapa principal, força o teletransporte
            if currentPlaceId == AFK_PLACE_ID or currentPlaceId ~= MAIN_GAME_ID then
                print("[Auto-Hop] Detetado fora do jogo principal (ID: " .. tostring(currentPlaceId) .. "). A regressar...")
                teleportService:Teleport(MAIN_GAME_ID, lp)
                task.wait(15) -- Aguarda para não causar flood no teletransporte
            else
                -- Se estivermos no jogo principal, verificamos se o aviso de AFK/Matchmaking apareceu no ecrã
                local playerGui = lp:WaitForChild("PlayerGui", 5)
                if playerGui then
                    local hud = playerGui:FindFirstChild("HUD")
                    if hud then
                        local afkBtn = hud:FindFirstChild("LeaveAFKServer", true)
                        local matchBtn = hud:FindFirstChild("LeaveMatchmakingServer", true)

                        if (afkBtn and afkBtn.Visible) or (matchBtn and matchBtn.Visible) then
                            print("[Auto-Hop] Aviso de inatividade/matchmaking detetado na interface. A reconectar...")
                            
                            -- Tenta clicar caso exista suporte no executor
                            if getconnections then
                                if afkBtn then for _, c in pairs(getconnections(afkBtn.MouseButton1Click)) do c:Fire() end end
                                if matchBtn then for _, c in pairs(getconnections(matchBtn.MouseButton1Click)) do c:Fire() end end
                            end
                            
                            task.wait(1)
                            -- Garante o teletransporte
                            teleportService:Teleport(MAIN_GAME_ID, lp)
                            task.wait(15)
                        end
                    end
                end
            end
        end)
    end
end)
