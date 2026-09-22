local rs = game:GetService("ReplicatedStorage")
local ws = game:GetService("Workspace")
local plyrs = game:GetService("Players")

local lp = plyrs.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

local function getRoot()
    return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
end

local plat = ws:FindFirstChild("CriminalSafePlat")
if not plat then
    plat = Instance.new("Part")
    plat.Name = "CriminalSafePlat"
    plat.Size = Vector3.new(40, 5, 40)
    plat.Anchored = true
    plat.Transparency = 1
    plat.CanCollide = true
    plat.Parent = ws
end

while task.wait(1) do
    if not getgenv().AutoFarmCriminal then break end
    
    local root = getRoot()
    if not root then continue end

    -- Sistema Básico do Criminoso (Procura os dropoffs/ATMs no mapa para completar)
    local criminalDropoff = nil
    local gameFolder = ws:FindFirstChild("Game")
    if gameFolder and gameFolder:FindFirstChild("Jobs") then
        local dropSpawners = gameFolder.Jobs:FindFirstChild("CriminalDropOffSpawners")
        if dropSpawners then
            for _, spawner in pairs(dropSpawners:GetChildren()) do
                if spawner:FindFirstChild("CriminalDropOffPoint") then
                    criminalDropoff = spawner
                    break
                end
            end
        end
    end

    if criminalDropoff then
        plat.CFrame = criminalDropoff.CFrame + Vector3.new(0, -3, 0)
        root.Velocity = Vector3.new(0, 0, 0)
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        root.CFrame = criminalDropoff.CFrame + Vector3.new(0, 3, 0)
        
        task.wait(1)
        
        local completeRemote = remotes:FindFirstChild("AttemptCriminalJobComplete")
        if completeRemote then
            pcall(function() completeRemote:InvokeServer() end)
            pcall(function() completeRemote:FireServer() end)
        end
        task.wait(2)
    else
        -- Se não tiver dropoff, tenta iniciar a sessão do crime
        local startRemote = remotes:FindFirstChild("RequestStartJobSession")
        if startRemote then
            pcall(function() startRemote:InvokeServer("Criminal", "jobPad", "Safe") end)
            pcall(function() startRemote:FireServer("Criminal", "jobPad", "Safe") end)
        end
    end
end
