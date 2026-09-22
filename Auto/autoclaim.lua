local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

if not remotes then return end
local playRewards = remotes:WaitForChild("PlayRewards", 10)
if not playRewards then return end

while true do
    -- Intervalo dinâmico entre checagens (ex: entre 8 e 16 segundos)
    local waitInterval = math.random(80, 160) / 10
    task.wait(waitInterval)

    pcall(function()
        for id = 1, 9 do
            playRewards:FireServer(id, false)
            -- Pequeno atraso humano entre cada tentativa de clique
            task.wait(math.random(15, 45) / 100)
        end
    end)
end
